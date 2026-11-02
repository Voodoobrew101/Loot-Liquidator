#!/usr/bin/env python3
"""D1b step 2: turn checked research evidence into baseline counts for ItemDB.

Reads every record under research/evidence/v3 (through tools/evidence_check.py,
so broken records are already set aside with a reason) and writes
database/evidence-baselines.lua, which tools/compile_itemdb.lua appends to
ItemDB as ordinary "itemdb" source records. Nobody types a final number:
drop chance = weighted drops / weighted casts, and every field carries the
weighted cast count, so the addon's own counting math (LL:CountsEstimate)
sets the confidence.

How records are combined, per method + input + inputs-per-cast:
  * Copies of the same data count once: per lineage, the record with the
    most casts is kept (reposts share a lineage).
  * Stale (pre-hotfix / outdated) data counts at STALE_FACTOR (0.25), like
    the addon.
  * The baseline is "what a player at the minimum skill gets" (owner decision
    16). Until scaling rules exist (D1b step 3), a sample is only counted at
    full weight when it says it was done at the minimum skill with no
    optional bonuses. Unknown skill, or skill/stats above the minimum, counts
    at NOT_BASELINE_FACTOR (0.5): weaker, never thrown away (decision 15).
  * A published percentage with no sample size counts as a guess worth
    GUESS_CASTS (20) casts, like the addon's LL:EvidenceCasts.
  * A record the Checker marked "mismatch" is left out (its counts do not
    match its own link). It stays in its file; only this build skips it.
  * An output a record does not list is "not reported" by that record, so
    that record adds no casts for it. List outputs you counted zero of with
    castsWithDrop 0.

Usage:
  python3 tools/evidence_to_baselines.py            # write the file, print a report
  python3 tools/evidence_to_baselines.py --check    # fail if the file is out of date
  python3 tools/evidence_to_baselines.py FOLDER OUT # other folder / output (tests)
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import evidence_check  # noqa: E402

DEFAULT_OUTPUT = Path('database/evidence-baselines.lua')
SUPPORTED = {'Mill': 'Inscription', 'Prospect': 'Jewelcrafting', 'Disenchant': 'Enchanting', 'Smelt': 'Mining'}
STALE_FACTOR = 0.25        # same as Database.lua
NOT_BASELINE_FACTOR = 0.5  # unknown skill, or skill/stats above the minimum
GUESS_CASTS = 20           # LL.PRIOR_CASTS: a percentage without a sample size
CONFIDENCE_BAND = 0.05     # LL.CONFIDENCE_BAND


# ---- confidence: an exact port of LL:BetaCDF / LL:RateConfidence (Database.lua)
def _beta_continued_fraction(x, a, b):
    qab, qap, qam = a + b, a + 1, a - 1
    c, d = 1.0, 1 - qab * x / qap
    d = 1 / (d if abs(d) >= 1e-30 else 1e-30)
    h = d
    for m in range(1, 201):
        m2 = 2 * m
        aa = m * (b - m) * x / ((qam + m2) * (a + m2))
        d = 1 + aa * d
        d = d if abs(d) >= 1e-30 else 1e-30
        c = 1 + aa / c
        c = c if abs(c) >= 1e-30 else 1e-30
        d = 1 / d
        h *= d * c
        aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2))
        d = 1 + aa * d
        d = d if abs(d) >= 1e-30 else 1e-30
        c = 1 + aa / c
        c = c if abs(c) >= 1e-30 else 1e-30
        d = 1 / d
        delta = d * c
        h *= delta
        if abs(delta - 1) < 3e-12:
            break
    return h


def beta_cdf(x, a, b):
    if x <= 0:
        return 0.0
    if x >= 1:
        return 1.0
    front = math.exp(math.lgamma(a + b) - math.lgamma(a) - math.lgamma(b) + a * math.log(x) + b * math.log(1 - x))
    if x < (a + 1) / (a + b + 2):
        return front * _beta_continued_fraction(x, a, b) / a
    return 1 - front * _beta_continued_fraction(1 - x, b, a) / b


def rate_confidence(drops, casts, band=CONFIDENCE_BAND):
    if casts <= 0:
        return 0
    drops = min(drops, casts)
    a, b = drops + 0.5, casts - drops + 0.5
    mean = drops / casts
    p = beta_cdf(min(1, mean + band), a, b) - beta_cdf(max(0, mean - band), a, b)
    return max(0, min(100, math.floor(p * 100 + 0.5)))


# ---- combining records
def at_baseline(record):
    """True only when the source says the casts were at the minimum skill with no bonuses."""
    skill, minimum = record.get('skill'), record.get('minimumSkill')
    if skill is None or minimum is None or skill != minimum:
        return False
    stats = record.get('stats') or {}
    return all(not value for value in stats.values())


def record_weight(record):
    weight = STALE_FACTOR if record['stale'] else 1.0
    return weight if at_baseline(record) else weight * NOT_BASELINE_FACTOR


def group_key(record):
    return (record['method'], str(record['input']), record['inputPerCast'])


def build(report):
    """Returns (records for ItemDB, notes for the report)."""
    notes = {'used': 0, 'skipped': [], 'duplicates': 0, 'mismatch': 0, 'confirmed': 0}
    verdicts = {}
    for entry in report['usable']:
        if entry['kind'] == 'check':
            verdicts.setdefault(entry['record']['recordId'], set()).add(entry['record']['result'])
    groups = {}
    for entry in report['usable']:
        if entry['kind'] != 'evidence':
            continue
        record = entry['record']
        found = verdicts.get(entry['id'], set())
        if 'mismatch' in found:
            notes['mismatch'] += 1
            notes['skipped'].append((entry['id'], 'the Checker found a mismatch with its link'))
            continue
        if 'confirmed' in found:
            notes['confirmed'] += 1
        if record['method'] not in SUPPORTED:
            notes['skipped'].append((entry['id'], f"method {record['method']} is not built into ItemDB yet (kept)"))
            continue
        if isinstance(record['input'], str) and not record['input'].endswith((':armor', ':weapon')):
            notes['skipped'].append((entry['id'], 'gear key needs :armor or :weapon for ItemDB (kept)'))
            continue
        lineages = groups.setdefault(group_key(record), {})
        best = lineages.get(record['lineage'])
        size = record['casts'] if record['casts'] is not None else GUESS_CASTS
        if best is not None:
            notes['duplicates'] += 1
            if (best[2]['casts'] if best[2]['casts'] is not None else GUESS_CASTS) >= size:
                continue
        lineages[record['lineage']] = (entry['id'], size, record)
    records = []
    for (method, input_key, per_cast), lineages in sorted(groups.items()):
        chosen = [lineages[name] for name in sorted(lineages)]
        notes['used'] += len(chosen)
        outputs = {}
        for record_id, size, record in chosen:
            weight = record_weight(record)
            for out in record['outputs']:
                acc = outputs.setdefault(out['item'], {'casts': 0.0, 'drops': 0.0, 'qtyCasts': 0.0,
                                                        'qty': 0.0, 'lo': None, 'hi': None, 'real': False})
                casts = size * weight
                drops = (out['castsWithDrop'] if 'castsWithDrop' in out else out['chance'] * size) * weight
                acc['casts'] += casts
                acc['drops'] += drops
                acc['real'] = acc['real'] or record['casts'] is not None
                if out.get('totalQuantity') is not None and record['casts'] is not None:
                    acc['qtyCasts'] += casts
                    acc['qty'] += out['totalQuantity'] * weight
                for side, pick in (('lo', min), ('hi', max)):
                    value = out.get('min' if side == 'lo' else 'max')
                    if value is not None:
                        acc[side] = value if acc[side] is None else pick(acc[side], value)
        materials = []
        for item, acc in sorted(outputs.items()):
            materials.append(material(item, acc))
        study = f"evidence:{method}:{input_key}:x{per_cast}"
        row = {
            'recordID': study, 'studyID': study, 'sourceKey': 'itemdb', 'method': method,
            'profession': SUPPORTED[method], 'inputCount': per_cast, 'provisional': True,
            'samples': round(max(acc['casts'] for acc in outputs.values()), 4),
            'source': '; '.join(sorted({r['source'] for _, _, r in chosen})),
            'evidenceRecordIDs': [record_id for record_id, _, _ in chosen],
            'baselineStatus': 'minimum-skill counts; samples not known to be at minimum skill count at half weight (no scaling rules yet)',
            'materials': materials,
        }
        minimums = {r.get('minimumSkill') for _, _, r in chosen} - {None}
        if len(minimums) == 1:
            row['evidenceMinimumSkill'] = minimums.pop()
        if input_key.startswith('gear:'):
            row['gearKey'] = input_key
        else:
            row['inputItemID'] = int(input_key)
        records.append(row)
    return records, notes


def field(value, confidence, samples, status='measured'):
    if value is None:
        return {'status': 'unknown', 'confidence': 0}
    return {'value': value, 'status': status, 'confidence': confidence, 'samples': samples}


def material(item, acc):
    casts = round(acc['casts'], 4)
    chance = min(1.0, acc['drops'] / acc['casts']) if acc['casts'] > 0 else None
    status = 'measured' if acc['real'] else 'provisional'
    confidence = rate_confidence(acc['drops'], acc['casts'])
    average = acc['qty'] / acc['qtyCasts'] if acc['qtyCasts'] > 0 else None
    lo, hi = acc['lo'], acc['hi']
    # The addon refuses an average outside chance x min .. chance x max. Counts
    # from different subsets can disagree; keep the chance and let the addon
    # fill the average from it (at half confidence) instead.
    if average is not None and chance is not None:
        if average == 0 and chance > 0:
            average = None
        elif lo is not None and hi is not None and not (chance * lo - 1e-9 <= average <= chance * hi + 1e-9):
            average = None
    chance_r = None if chance is None else round(chance, 6)
    average_r = None if average is None else round(average, 6)
    return {
        'id': item,
        'dropChance': field(chance_r, confidence, casts, status),
        'expectedQuantity': field(average_r, confidence, round(acc['qtyCasts'], 4), status),
        'minQuantity': field(lo, confidence, casts, status),
        'maxQuantity': field(hi, confidence, casts, status),
    }


# ---- writing Lua
def lua(value):
    if value is True or value is False:
        return 'true' if value else 'false'
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        return repr(value)
    if isinstance(value, str):
        return '"' + value.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'
    if isinstance(value, list):
        return '{' + ','.join(lua(v) for v in value) + '}'
    if isinstance(value, dict):
        return '{' + ','.join(f'{k}={lua(value[k])}' for k in sorted(value)) + '}'
    raise TypeError(f'cannot write {type(value).__name__} to Lua')


def render(records):
    lines = [
        '-- Generated by tools/evidence_to_baselines.py from research/evidence/v3. Never hand-edit.',
        '-- Baseline counts per item (owner decision 16); tools/compile_itemdb.lua appends them to ItemDB.',
        'return {schemaVersion=1,processing={',
    ]
    lines += [lua(r) + ',' for r in records]
    lines.append('}}')
    return '\n'.join(lines) + '\n'


def summary(report, records, notes):
    lines = [f"EVIDENCE BASELINES: {len(records)} item record(s) from {notes['used']} evidence record(s); "
             f"{notes['duplicates']} duplicate lineage(s) counted once, {notes['confirmed']} checked OK, "
             f"{notes['mismatch']} left out after a mismatch, {len(report['setAside'])} set aside by the checker"]
    for record_id, why in notes['skipped']:
        lines.append(f'  skipped {record_id}: {why}')
    for r in records:
        parts = [f"{m['id']} {m['dropChance'].get('value')} ({m['dropChance']['confidence']}%)" for m in r['materials']]
        lines.append(f"  {r['recordID']} ({r['samples']} weighted casts): " + ', '.join(parts))
    return '\n'.join(lines)


def main(argv):
    args = [a for a in argv if not a.startswith('--')]
    folder = Path(args[0]) if args else evidence_check.DEFAULT_FOLDER
    output = Path(args[1]) if len(args) > 1 else DEFAULT_OUTPUT
    report = evidence_check.check_folder(folder)
    records, notes = build(report)
    text = render(records)
    if '--check' in argv:
        current = output.read_text() if output.exists() else None
        if current != text:
            print(f'{output} is out of date: run python3 tools/evidence_to_baselines.py')
            return 1
        print(summary(report, records, notes).splitlines()[0])
        return 0
    output.write_text(text)
    print(summary(report, records, notes))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
