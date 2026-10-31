#!/usr/bin/env python3
"""D1c: bring the research team's v3 results into ItemDB, counted once.

The five research agents (branch implementation/five-agent-completion) record evidence in
their own v3 format under research/v3/ and compute estimates with their own
research/v3/tools/build_estimates.py. This tool:

  1. --refresh  copies the inputs that calculator needs (evidence, corrections, conditions,
                rate changes and the calculator itself) from their branch into a pinned
                snapshot, database/research/v3-snapshot/, and records the commit in
                database/research/v3-snapshot/SNAPSHOT.json. Their files are never edited.
  2. (default)  runs THEIR calculator on that snapshot, unchanged, with two kinds of rows
                left out of the counts (still used to match item names to IDs):
                  * reference values (sourceKind tsm-table / compiled-research / reference):
                    TSM's old table is not used for yields (owner decision 3), and the
                    compiled research rows are already in ItemDB;
                  * imported/gamedata-disenchant.jsonl: the addon's own old disenchant tables,
                    which already ship as the "Legacy" source.
                So every number comes from real studies only, and nothing is counted twice.
                Then it writes database/research-v3-baselines.lua: ordinary "itemdb" records
                whose fields carry the weighted cast counts, so the addon's own counting math
                (LL:CountsEstimate / LL:RateConfidence) sets the confidence.

Each record says supersedesResearch=true: tools/compile_itemdb.lua then drops the older
research rows ("research:..." records from database/research/itemdb.lua) for the same method
and input, because v3 already contains the studies behind them (it imported them). Those rows
stay in the source file and are listed in ItemDB.buildReport.researchSuperseded.

Left out, with the reason in the report (nothing is deleted from the research data):
  * conditional drops (need a specialization unlock or skill; the addon can't tell yet);
  * "family:<name>" inputs or outputs (quality rank unknown: no item ID to price or match);
  * inputs whose batch size (inputs per cast) the records don't state.
Samples are not known to be at the minimum skill, so, like tools/evidence_to_baselines.py,
they count at NOT_BASELINE_FACTOR until scaling rules exist (owner decision 16).

Usage:
  python3 tools/research_v3_to_baselines.py --refresh [GIT-REF]   # new snapshot, then build
  python3 tools/research_v3_to_baselines.py                       # build from the snapshot
  python3 tools/research_v3_to_baselines.py --check               # fail if the output is stale
  python3 tools/research_v3_to_baselines.py SNAPSHOT OUT          # other folders (tests)
"""
import importlib.util
import json
import subprocess
import sys
sys.dont_write_bytecode = True  # never leave cache files in the repo or snapshot
import tarfile
import io
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from evidence_to_baselines import lua, rate_confidence, NOT_BASELINE_FACTOR  # noqa: E402

DEFAULT_REF = 'origin/implementation/five-agent-completion'
DEFAULT_SNAPSHOT = Path('database/research/v3-snapshot')
DEFAULT_OUTPUT = Path('database/research-v3-baselines.lua')
SNAPSHOT_PATHS = ['research/v3/evidence', 'research/v3/corrections.jsonl', 'research/v3/conditions.jsonl',
                  'research/v3/rate-changes.jsonl', 'research/v3/tools/build_estimates.py']
SUPPORTED = {'Mill': 'Inscription', 'Prospect': 'Jewelcrafting', 'Disenchant': 'Enchanting', 'Smelt': 'Mining'}
EXPANSIONS = {'classic': 0, 'the burning crusade': 1, 'burning crusade': 1, 'wrath of the lich king': 2,
              'cataclysm': 3, 'mists of pandaria': 4, 'warlords of draenor': 5, 'legion': 6,
              'battle for azeroth': 7, 'shadowlands': 8, 'dragonflight': 9, 'the war within': 10, 'midnight': 11}
QUALITIES = {'common': 1, 'uncommon': 2, 'rare': 3, 'epic': 4}
LEGACY_COPY = 'imported/gamedata-disenchant.jsonl'


# ---- 1. snapshot
def refresh(ref, snapshot):
    commit = subprocess.check_output(['git', 'rev-parse', ref], text=True).strip()
    when = subprocess.check_output(['git', 'show', '-s', '--format=%cI', commit], text=True).strip()
    data = subprocess.check_output(['git', 'archive', commit] + SNAPSHOT_PATHS)
    target = snapshot / 'research' / 'v3'
    if target.exists():
        for path in sorted(target.rglob('*'), reverse=True):
            path.unlink() if path.is_file() else path.rmdir()
    snapshot.mkdir(parents=True, exist_ok=True)
    with tarfile.open(fileobj=io.BytesIO(data)) as tar:
        for member in tar.getmembers():
            name = Path(member.name)
            if member.isfile() and '..' not in name.parts and not name.is_absolute():
                out = snapshot / name
                out.parent.mkdir(parents=True, exist_ok=True)
                out.write_bytes(tar.extractfile(member).read())
    (snapshot / 'SNAPSHOT.json').write_text(json.dumps(
        {'branch': ref.replace('origin/', ''), 'commit': commit, 'committed': when,
         'paths': SNAPSHOT_PATHS, 'note': 'Pinned copy of the research team files. Never edit; '
                                          'refresh with tools/research_v3_to_baselines.py --refresh'},
        indent=1) + '\n')
    return commit


# ---- 2. run their calculator on real studies only
def load_calculator(snapshot):
    path = snapshot / 'research' / 'v3' / 'tools' / 'build_estimates.py'
    spec = importlib.util.spec_from_file_location('ll_research_v3_build_estimates', path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def is_counted(row, module):
    if row.get('sourceKind') in module.REFERENCE_KINDS:
        return False
    return not str(row.get('_file', '')).replace('\\', '/').endswith(LEGACY_COPY)


def gear_key(text):
    """'gear:<expansion>:<quality>:<kind>' with names or numbers -> the addon's numeric key."""
    parts = text.split(':')
    if len(parts) != 4 or parts[3] not in ('armor', 'weapon'):
        return None
    exp, quality = parts[1].strip().lower(), parts[2].strip().lower()
    exp = int(exp) if exp.isdigit() else EXPANSIONS.get(exp)
    quality = int(quality) if quality.isdigit() else QUALITIES.get(quality)
    if exp is None or quality is None:
        return None
    return f'gear:{exp}:{quality}:{parts[3]}'


def batch_sizes(rows, module, names):
    """Most common inputs-per-cast stated for each (method, input) by counted study rows."""
    seen = defaultdict(Counter)
    for r in rows:
        if r.get('type') != 'drop' or not isinstance(module.num(r.get('inputsPerCast')), (int, float)):
            continue
        key = module.key_of(r, names)
        if key:
            seen[(key[0], key[1])][r['inputsPerCast']] += 1
    # Their calculator groups by input only, so studies of different operations (e.g.
    # 5-herb milling and 20-herb mass milling) are blended. Such inputs are left out.
    return {k: (c.most_common(1)[0][0] if len(c) == 1 else 'mixed') for k, c in seen.items()}


def counts(estimate):
    """Weighted (drops, casts) behind their chance, from their own beta parameters."""
    a, b = estimate['simulation']['chanceBeta']
    return max(a - 0.5, 0.0), max(a + b - 1.0, 0.0)


def build(snapshot):
    module = load_calculator(snapshot)
    rows = module.load()
    # Their published run (all rows) only supplies the amount range per cast (e.g. 1-2 gems),
    # which reference rows often state and studies rarely do. A range is not a yield figure.
    published, _ = module.build(rows)
    ranges = {(e['method'], e['input'], e['outputItemID']): (e['range'], e['rangeSource']) for e in published}
    names = module.name_maps(rows)            # learn names from every row ...
    counted = [r for r in rows if is_counted(r, module)]
    module.name_maps = lambda _rows: names    # ... but count real studies only
    results, unplaced = module.build(counted)
    for e in results:
        e['range'], e['rangeSource'] = ranges.get((e['method'], e['input'], e['outputItemID']),
                                                  (e['range'], e['rangeSource']))
    batches = batch_sizes(counted, module, names)
    notes = Counter()
    groups = defaultdict(list)
    for e in results:
        if e['method'] not in SUPPORTED:
            notes['method not built into ItemDB yet'] += 1
            continue
        if e['conditional']:
            notes['conditional drop (needs an unlock the addon cannot check yet)'] += 1
            continue
        if not isinstance(e['outputItemID'], int):
            notes['output rank unknown (family:<name>)'] += 1
            continue
        if e['input'].startswith('family:'):
            notes['input rank unknown (family:<name>)'] += 1
            continue
        if e['input'].startswith('gear:'):
            key = gear_key(e['input'])
            if not key:
                notes['gear group not recognised'] += 1
                continue
            per_cast = 1
        else:
            key = e['input']
            per_cast = 1 if e['method'] == 'Disenchant' else batches.get((e['method'], e['input']))
            if per_cast is None:
                notes['batch size (inputs per cast) not stated'] += 1
                continue
            if per_cast == 'mixed':
                notes['studies mix batch sizes (e.g. milling and mass milling)'] += 1
                continue
        if e['studies'] == 0:
            notes['no real study (starting guess only)'] += 1
            continue
        groups[(e['method'], key, per_cast)].append(e)
    records = []
    for (method, key, per_cast), estimates in sorted(groups.items(), key=lambda kv: (kv[0][0], kv[0][1])):
        by_output = {}
        for e in estimates:   # a gear group written two ways (names / numbers) adds up
            by_output.setdefault(e['outputItemID'], []).append(e)
        materials = [material(item, es) for item, es in sorted(by_output.items())]
        record_id = f'evidence:v3:{method}:{key}:x{per_cast}'
        row = {
            'recordID': record_id, 'studyID': record_id, 'sourceKey': 'itemdb', 'method': method,
            'profession': SUPPORTED[method], 'inputCount': per_cast, 'provisional': True,
            'supersedesResearch': True,
            'samples': round(max(m['_casts'] for m in materials), 4),
            'source': 'research team v3 (research/v3 on implementation/five-agent-completion)',
            'baselineStatus': 'real studies only; samples not known to be at minimum skill count at half weight (no scaling rules yet)',
            'materials': [{k: v for k, v in m.items() if not k.startswith('_')} for m in materials],
        }
        if key.startswith('gear:'):
            row['gearKey'] = key
        else:
            row['inputItemID'] = int(key)
        records.append(row)
    return records, notes, len(rows), len(counted), unplaced


def field(value, confidence, samples, status):
    if value is None:
        return {'status': 'unknown', 'confidence': 0}
    return {'value': value, 'status': status, 'confidence': confidence, 'samples': samples}


def material(item, estimates):
    drops = casts = qty = qty_casts = 0.0
    chance_measured = average_measured = range_observed = True
    lo = hi = None
    for e in estimates:
        lo = e['range'][0] if lo is None else min(lo, e['range'][0])
        hi = e['range'][1] if hi is None else max(hi, e['range'][1])
    mid = (lo + hi) / 2
    for e in estimates:
        d, n = counts(e)
        if e['chanceSource'] == 'estimated':
            # Their chance = average / middle of the range; redo it with the published range
            # (their own rule, strategy S5). n is already their halved count for a derived chance.
            d = min(1.0, e['average'] / mid) * n
        drops += d * NOT_BASELINE_FACTOR
        casts += n * NOT_BASELINE_FACTOR
        nq = (e['studyCasts'] if e['averageSource'] == 'measured' else n) * NOT_BASELINE_FACTOR
        qty += e['average'] * nq
        qty_casts += nq
        chance_measured &= e['chanceSource'] == 'measured'
        average_measured &= e['averageSource'] == 'measured'
        range_observed &= e['rangeSource'] == 'observed'
    chance = min(1.0, drops / casts) if casts > 0 else None
    average = qty / qty_casts if qty_casts > 0 else None
    # The addon refuses an average outside chance x min .. chance x max; then it fills the
    # average from the chance itself (at half confidence) instead. Allow for rounding.
    if average is not None and chance is not None:
        if chance * lo * (1 - 1e-3) - 1e-6 <= average <= chance * hi * (1 + 1e-3) + 1e-6:
            average = min(max(average, chance * lo), chance * hi)
        else:
            average = None
    confidence = rate_confidence(drops, casts)
    if not chance_measured:
        confidence //= 2   # a chance worked out from an average: half confidence (their S5, our C1b)
    casts_r = round(casts, 4)
    return {
        'id': item, '_casts': casts,
        'dropChance': field(None if chance is None else round(chance, 6), confidence, casts_r,
                            'measured' if chance_measured else 'provisional'),
        'expectedQuantity': field(None if average is None else round(average, 6), confidence, round(qty_casts, 4),
                                  'measured' if average_measured else 'provisional'),
        'minQuantity': field(lo, confidence, casts_r, 'measured' if range_observed else 'provisional'),
        'maxQuantity': field(hi, confidence, casts_r, 'measured' if range_observed else 'provisional'),
    }


def render(records, snapshot):
    info = json.loads((snapshot / 'SNAPSHOT.json').read_text())
    lines = [
        '-- Generated by tools/research_v3_to_baselines.py from the research team\'s v3 snapshot. Never hand-edit.',
        f"-- Source: {info['branch']} @ {info['commit'][:12]} ({info['committed']}); real studies only.",
        'return {schemaVersion=1,processing={',
    ]
    lines += [lua(r) + ',' for r in records]
    lines.append('}}')
    return '\n'.join(lines) + '\n'


def summary(records, notes, total, counted, unplaced):
    inputs = Counter(r['method'] for r in records)
    lines = [f'RESEARCH V3 BASELINES: {len(records)} input record(s) '
             f'({", ".join(f"{m} {n}" for m, n in sorted(inputs.items()))}), '
             f'{sum(len(r["materials"]) for r in records)} materials, from {counted} of {total} rows '
             f'(reference values and re-imported old addon tables not counted; {unplaced} unplaced)']
    for why, n in sorted(notes.items()):
        lines.append(f'  left out: {n} estimate(s): {why}')
    return '\n'.join(lines)


def main(argv):
    args = [a for a in argv if not a.startswith('--')]
    if '--refresh' in argv:
        ref = args[0] if args else DEFAULT_REF
        commit = refresh(ref, DEFAULT_SNAPSHOT)
        print(f'Snapshot refreshed from {ref} @ {commit[:12]}')
        args = []
    snapshot = Path(args[0]) if args else DEFAULT_SNAPSHOT
    output = Path(args[1]) if len(args) > 1 else DEFAULT_OUTPUT
    records, notes, total, counted, unplaced = build(snapshot)
    text = render(records, snapshot)
    if '--check' in argv:
        if not output.exists() or output.read_text() != text:
            print(f'{output} is out of date: run python3 tools/research_v3_to_baselines.py')
            return 1
        print(summary(records, notes, total, counted, unplaced).splitlines()[0])
        return 0
    output.write_text(text)
    print(summary(records, notes, total, counted, unplaced))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
