"""D1b step 1: check research evidence records (claude/research-agent-proposal.md, sections 3 and 3b).

Reads every research/evidence/v3/**/*.json file (each a JSON list of records) and sorts the
records into "usable" and "set aside". A record that breaks a rule is set aside with its
reasons; nothing is deleted or edited (owner decision 15: never throw data away).

Record kinds:
  evidence  (no "kind" field)  one source's raw counts for one item and method
  mechanic                     a stated rule about how skill/stats change results
  check                        the Checker agent's verdict on another record

A record's ID is "<path relative to the evidence folder>#<position in the list, from 0>",
e.g. "midnight/2026-11-01-ores.json#3". Check records point at other records by that ID.

Usage:
  python3 tools/evidence_check.py [FOLDER] [--json] [--strict]
FOLDER defaults to research/evidence/v3. --json prints the full report as JSON.
--strict exits with status 1 when anything was set aside (normal runs always exit 0).
"""
import json
import math
import re
import sys
from pathlib import Path

DEFAULT_FOLDER = Path('research/evidence/v3')

METHODS = {'Disenchant', 'Mill', 'Prospect', 'Smelt', 'Craft', 'Exchange', 'Open'}
METRICS = {'skill', 'resourcefulness', 'multicraft', 'specPoints', 'gear', 'other'}
STAT_KEYS = {'resourcefulness', 'multicraft', 'specPoints', 'gearBonusSkill'}
CHECK_RESULTS = {'confirmed', 'mismatch'}

EVIDENCE_REQUIRED = {'method', 'input', 'inputPerCast', 'casts', 'outputs', 'source', 'lineage',
                     'observedDate', 'patch', 'stale'}
IDENTITY_FIELDS = {'recipeID', 'expansionID', 'inputQualityRank', 'inputRarity', 'inputClassID'}
SCOPE_FIELDS = IDENTITY_FIELDS | {'referenceContextID', 'referenceConditions'}
REFERENCE_CONDITION_FIELDS = {'skill', 'baseSkill', 'effectiveSkill', 'bonusSkill',
                              'resourcefulness', 'multicraft', 'specPoints', 'gearBonusSkill'}
EVIDENCE_OPTIONAL = {'skill', 'minimumSkill', 'stats', 'notes'} | SCOPE_FIELDS
FIELD_NAMES = {'dropChance', 'expectedQuantity', 'minQuantity', 'maxQuantity'}
OUTPUT_KEYS = {'item', 'castsWithDrop', 'totalQuantity', 'averageQuantity', 'min', 'max', 'chance',
               'rankIDs', 'rankSource', 'fieldConfidence', 'notes'}
MECHANIC_REQUIRED = {'kind', 'profession', 'metric', 'effect', 'appliesTo', 'source', 'patch'}
MECHANIC_OPTIONAL = {'numbers', 'notes'}
CHECK_REQUIRED = {'kind', 'recordId', 'result', 'saw'}
CHECK_OPTIONAL = {'source', 'notes'}

GEAR_KEY = re.compile(r'^gear:\d+:\d+(:(armor|weapon))?$')
DATE = re.compile(r'^\d{4}(-(0[1-9]|1[0-2])(-(0[1-9]|[12]\d|3[01]))?)?$')
PATCH = re.compile(r'^\d+\.\d+(\.\d+)?[a-z]?$')
RECORD_ID = re.compile(r'^[^#]+\.json#\d+$')


def whole(value, minimum=0):
    """A whole number (not a bool) of at least `minimum`."""
    return isinstance(value, int) and not isinstance(value, bool) and value >= minimum


def number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def text(value):
    return isinstance(value, str) and value.strip() != ''


def https(value):
    return isinstance(value, str) and value.startswith('https://') and len(value) > len('https://')


def check_keys(record, required, optional, reasons, where=''):
    missing = sorted(required - record.keys())
    unknown = sorted(record.keys() - required - optional)
    if missing:
        reasons.append(f'{where}missing field(s): {", ".join(missing)}')
    if unknown:
        reasons.append(f'{where}unknown field(s) (typo?): {", ".join(unknown)}')


def check_common(record, reasons):
    if not https(record.get('source')):
        reasons.append('source must be a link starting with https://')
    patch = record.get('patch')
    if patch is not None and not (isinstance(patch, str) and PATCH.match(patch)):
        reasons.append('patch must look like "12.0.5" or be null')


def check_output(output, casts, index, reasons):
    where = f'outputs[{index}]: '
    if not isinstance(output, dict):
        reasons.append(where + 'must be an object')
        return
    check_keys(output, {'item'}, OUTPUT_KEYS - {'item'}, reasons, where)
    if not whole(output.get('item'), 1):
        reasons.append(where + 'item must be a positive whole number (item ID)')
    has_counts = 'castsWithDrop' in output
    has_chance = 'chance' in output
    if has_counts and has_chance:
        reasons.append(where + 'give castsWithDrop or chance, not both')
    elif has_counts:
        drops = output['castsWithDrop']
        if casts is None:
            reasons.append(where + 'castsWithDrop needs casts (the number of casts counted)')
        elif not whole(drops):
            reasons.append(where + 'castsWithDrop must be a whole number, 0 or more')
        elif whole(casts, 1) and drops > casts:
            reasons.append(where + 'castsWithDrop is larger than casts')
    elif has_chance:
        chance = output['chance']
        if not (number(chance) and 0 <= chance <= 1):
            reasons.append(where + 'chance must be between 0 and 1 (0.18 means 18%)')
    has_total, has_average = 'totalQuantity' in output, 'averageQuantity' in output
    if not (has_counts or has_chance or has_total or has_average):
        reasons.append(where + 'needs castsWithDrop, chance, totalQuantity, or an explicitly published averageQuantity')
    if has_total and has_average:
        reasons.append(where + 'give totalQuantity or averageQuantity, not both')
    if has_total:
        total = output['totalQuantity']
        if not whole(total):
            reasons.append(where + 'totalQuantity must be a whole number, 0 or more')
        if not whole(casts, 1):
            reasons.append(where + 'totalQuantity needs casts (completed operations, not input units)')
        if whole(total) and has_counts and whole(output['castsWithDrop']) and total < output['castsWithDrop']:
            reasons.append(where + 'totalQuantity is smaller than castsWithDrop')
    if has_average and not (number(output['averageQuantity']) and output['averageQuantity'] >= 0):
        reasons.append(where + 'averageQuantity must be a finite number, 0 or more, explicitly stated per completed operation')
    if 'rankIDs' in output:
        ranks = output['rankIDs']
        if not (isinstance(ranks, list) and 2 <= len(ranks) <= 5
                and all(whole(item, 1) for item in ranks) and len(set(ranks)) == len(ranks)):
            reasons.append(where + 'rankIDs must contain 2 to 5 distinct positive item IDs for one complete output family')
        elif output.get('item') not in ranks:
            reasons.append(where + 'item must be included in rankIDs')
        if not https(output.get('rankSource')):
            reasons.append(where + 'rankIDs needs rankSource, an https:// link proving the complete family mapping')
    elif 'rankSource' in output:
        reasons.append(where + 'rankSource needs rankIDs')
    if 'fieldConfidence' in output:
        confidence = output['fieldConfidence']
        if not isinstance(confidence, dict):
            reasons.append(where + 'fieldConfidence must be an object of independent field quality scores')
        else:
            check_keys(confidence, set(), FIELD_NAMES, reasons, where + 'fieldConfidence: ')
            for name, value in confidence.items():
                if not (number(value) and 0 <= value <= 100):
                    reasons.append(where + f'fieldConfidence: {name} must be a finite number between 0 and 100')
    if 'notes' in output and not isinstance(output['notes'], str):
        reasons.append(where + 'notes must be text')
    lo, hi = output.get('min'), output.get('max')
    for name, value in (('min', lo), ('max', hi)):
        if value is not None and not whole(value, 1):
            reasons.append(where + f'{name} must be a whole number, 1 or more, or left out')
    if whole(lo, 1) and whole(hi, 1) and lo > hi:
        reasons.append(where + 'min is larger than max')


def check_evidence(record):
    reasons = []
    check_keys(record, EVIDENCE_REQUIRED, EVIDENCE_OPTIONAL, reasons)
    check_common(record, reasons)
    method = record.get('method')
    if method not in METHODS:
        reasons.append(f'method must be one of: {", ".join(sorted(METHODS))}')
    item = record.get('input')
    if isinstance(item, str):
        if not GEAR_KEY.match(item):
            reasons.append('input must be an item ID or a gear key like "gear:9:4:armor"')
        elif method != 'Disenchant':
            reasons.append('gear keys are only for Disenchant')
    elif not whole(item, 1):
        reasons.append('input must be a positive whole number (item ID)')
    if not whole(record.get('inputPerCast'), 1):
        reasons.append('inputPerCast must be a whole number, 1 or more')
    for name in IDENTITY_FIELDS:
        if name not in record:
            continue
        value = record[name]
        if not whole(value, 0 if name in {'expansionID', 'inputRarity', 'inputClassID'} else 1):
            reasons.append(f'{name} must be a whole number in its identity scope')
        elif name == 'inputQualityRank' and value > 5:
            reasons.append('inputQualityRank must be between 1 and 5')
        elif name == 'inputRarity' and value > 8:
            reasons.append('inputRarity must be between 0 and 8')
    if 'referenceContextID' in record and not (text(record['referenceContextID']) and len(record['referenceContextID']) <= 256):
        reasons.append('referenceContextID must be non-empty text of at most 256 characters')
    if 'referenceConditions' in record:
        conditions = record['referenceConditions']
        if not isinstance(conditions, dict):
            reasons.append('referenceConditions must be an object of known numeric player conditions')
        else:
            check_keys(conditions, set(), REFERENCE_CONDITION_FIELDS, reasons, 'referenceConditions: ')
            for key, value in conditions.items():
                if not (number(value) and value >= 0):
                    reasons.append(f'referenceConditions: {key} must be a finite number, 0 or more')
    casts = record.get('casts')
    if casts is not None and not whole(casts, 1):
        reasons.append('casts must be a whole number above 0, or null when no sample size is given')
    outputs = record.get('outputs')
    if not isinstance(outputs, list) or not outputs:
        reasons.append('outputs must be a non-empty list')
    else:
        seen = set()
        family_members = set()
        for index, output in enumerate(outputs):
            check_output(output, casts, index, reasons)
            item_id = output.get('item') if isinstance(output, dict) else None
            if whole(item_id, 1):
                if item_id in seen:
                    reasons.append(f'outputs[{index}]: item {item_id} is listed twice')
                if item_id in family_members:
                    reasons.append(f'outputs[{index}]: output overlaps a previously listed complete rank family')
                ranks = output.get('rankIDs')
                if isinstance(ranks, list) and all(whole(item, 1) for item in ranks):
                    if set(ranks) & (seen | family_members):
                        reasons.append(f'outputs[{index}]: complete rank family overlaps another output; report its total once')
                    family_members.update(ranks)
                seen.add(item_id)
    if not text(record.get('lineage')):
        reasons.append('lineage must name the original data (same value for reposts)')
    date = record.get('observedDate')
    if date is not None and not (isinstance(date, str) and DATE.match(date)):
        reasons.append('observedDate must look like "2025", "2025-08" or "2025-08-14", or be null')
    if not isinstance(record.get('stale'), bool):
        reasons.append('stale must be true or false')
    skill, minimum = record.get('skill'), record.get('minimumSkill')
    for name, value in (('skill', skill), ('minimumSkill', minimum)):
        if value is not None and not whole(value):
            reasons.append(f'{name} must be a whole number or null')
    if whole(skill) and whole(minimum) and skill < minimum:
        reasons.append('skill is below minimumSkill (that cast would be impossible)')
    stats = record.get('stats')
    if stats is not None:
        if not isinstance(stats, dict):
            reasons.append('stats must be an object or null')
        else:
            check_keys(stats, set(), STAT_KEYS, reasons, 'stats: ')
            for key, value in stats.items():
                if value is not None and not (number(value) and value >= 0):
                    reasons.append(f'stats: {key} must be a number, 0 or more, or null')
    if 'notes' in record and not isinstance(record['notes'], str):
        reasons.append('notes must be text')
    return reasons


def check_mechanic(record):
    reasons = []
    check_keys(record, MECHANIC_REQUIRED, MECHANIC_OPTIONAL, reasons)
    check_common(record, reasons)
    for name in ('profession', 'effect', 'appliesTo'):
        if not text(record.get(name)):
            reasons.append(f'{name} must be non-empty text')
    if record.get('metric') not in METRICS:
        reasons.append(f'metric must be one of: {", ".join(sorted(METRICS))}')
    numbers = record.get('numbers')
    if numbers is not None:
        if not isinstance(numbers, dict):
            reasons.append('numbers must be an object or left out')
        else:
            for key, value in numbers.items():
                if value is not None and not number(value):
                    reasons.append(f'numbers: {key} must be a number or null (only numbers the source states)')
    return reasons


def check_check(record):
    reasons = []
    check_keys(record, CHECK_REQUIRED, CHECK_OPTIONAL, reasons)
    if not (isinstance(record.get('recordId'), str) and RECORD_ID.match(record['recordId'])):
        reasons.append('recordId must look like "midnight/2026-11-01-ores.json#3"')
    if record.get('result') not in CHECK_RESULTS:
        reasons.append('result must be "confirmed" or "mismatch"')
    if not text(record.get('saw')):
        reasons.append('saw must say briefly what the page showed')
    if 'source' in record and not https(record['source']):
        reasons.append('source must be a link starting with https://')
    return reasons


def check_record(record):
    """Return (kind, reasons). An empty reasons list means the record is usable."""
    if not isinstance(record, dict):
        return 'unknown', ['each record must be a JSON object']
    kind = record.get('kind', 'evidence')
    if kind == 'evidence':
        record = {k: v for k, v in record.items() if k != 'kind'}
        return kind, check_evidence(record)
    if kind == 'mechanic':
        return kind, check_mechanic(record)
    if kind == 'check':
        return kind, check_check(record)
    return 'unknown', ['kind must be "mechanic", "check", or left out for evidence']


def check_folder(folder=DEFAULT_FOLDER):
    """Check every .json file under `folder`. Returns a report dict."""
    folder = Path(folder)
    report = {'folder': str(folder), 'files': 0, 'usable': [], 'setAside': []}
    if not folder.is_dir():
        return report
    for path in sorted(folder.rglob('*.json')):
        report['files'] += 1
        name = path.relative_to(folder).as_posix()
        try:
            records = json.loads(path.read_text(encoding='utf-8-sig'))
        except (ValueError, UnicodeDecodeError) as error:
            report['setAside'].append({'id': name, 'kind': 'file', 'reasons': [f'not valid JSON: {error}']})
            continue
        if not isinstance(records, list):
            report['setAside'].append({'id': name, 'kind': 'file', 'reasons': ['file must hold a JSON list of records']})
            continue
        for index, record in enumerate(records):
            kind, reasons = check_record(record)
            entry = {'id': f'{name}#{index}', 'kind': kind}
            if reasons:
                entry['reasons'] = reasons
                report['setAside'].append(entry)
            else:
                entry['record'] = record
                report['usable'].append(entry)
    usable_ids = {entry['id'] for entry in report['usable']}
    for entry in report['usable']:
        if entry['kind'] == 'check' and entry['record']['recordId'] not in usable_ids:
            entry['warning'] = 'points at a record that is missing or set aside'
    return report


def summary(report):
    kinds = {}
    for entry in report['usable']:
        kinds[entry['kind']] = kinds.get(entry['kind'], 0) + 1
    lines = [f"EVIDENCE CHECK: {report['files']} file(s), {len(report['usable'])} usable "
             f"({', '.join(f'{n} {k}' for k, n in sorted(kinds.items())) or 'none'}), "
             f"{len(report['setAside'])} set aside"]
    for entry in report['setAside']:
        lines.append(f"  set aside {entry['id']}: " + '; '.join(entry['reasons']))
    for entry in report['usable']:
        if 'warning' in entry:
            lines.append(f"  warning {entry['id']}: {entry['warning']}")
    return '\n'.join(lines)


def main(argv):
    args = [a for a in argv if not a.startswith('--')]
    report = check_folder(Path(args[0]) if args else DEFAULT_FOLDER)
    print(json.dumps(report, indent=2) if '--json' in argv else summary(report))
    return 1 if '--strict' in argv and report['setAside'] else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
