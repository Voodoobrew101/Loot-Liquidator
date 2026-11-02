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

C4b3 (owner, session 15): the same run also builds ItemDB's gear-token reward lists from the v3
"token" records (tools/research_v3_tokens.py), written as tokenRewards in the same output file, so
updating ItemDB always updates the token lists too.

D1c4: it also collects the v3 "noDisenchant" records (tools/research_v3_no_disenchant.py) as
noDisenchant; the compiler adds them to ItemDB.restrictions without removing any game-file entry.

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
import research_v3_tokens  # noqa: E402  C4b3: token reward lists ride along with every refresh
import research_v3_no_disenchant  # noqa: E402  D1c4: no-disenchant flags ride along too

DEFAULT_REF = 'origin/implementation/five-agent-completion'
DEFAULT_SNAPSHOT = Path('database/research/v3-snapshot')
DEFAULT_OUTPUT = Path('database/research-v3-baselines.lua')
FAMILIES_FILE = Path(__file__).resolve().parent.parent / 'database' / 'research' / 'rank-families.json'
SNAPSHOT_PATHS = ['research/v3/evidence', 'research/v3/corrections.jsonl', 'research/v3/conditions.jsonl',
                  'research/v3/rate-changes.jsonl', 'research/v3/tools']
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


# ---- 1b. rank-unknown names (D1c2)
def load_families(path=None):
    """lower-case name -> list of item IDs that carry it (database/research/rank-families.json)."""
    data = json.loads(Path(path or FAMILIES_FILE).read_text())
    return {name.strip().lower(): list(entry['ids']) for name, entry in data['families'].items()}


def resolve_ranked_outputs(rows, path=None):
    """D1c6: fix gem identity from sourced name/rank mappings, never from ID order.

    Some v3 studies swapped Ysemerald/Neltharite IDs; other copies omit the ID.
    Resolve both before the calculator groups and deduplicates studies. Only
    explicitly verified ranks are eligible; no counts or on-disk evidence change.
    """
    families = json.loads(Path(path or FAMILIES_FILE).read_text())['families']
    ranked = {(name.strip().lower(), rank): item
              for name, entry in families.items() if entry.get('source', '').startswith('https://')
              for rank, item in entry.get('verifiedRanks', {}).items() if item in entry['ids']}
    resolved = []
    for row in rows:
        key = ((row.get('outputName') or '').strip().lower(), str(row.get('outputRank')))
        item = ranked.get(key)
        resolved.append(dict(row, outputItemID=item) if item is not None else row)
    return resolved


# ---- 2. run their calculator on real studies only
def load_calculator(snapshot):
    path = snapshot / 'research' / 'v3' / 'tools' / 'build_estimates.py'
    spec = importlib.util.spec_from_file_location('ll_research_v3_build_estimates', path)
    module = importlib.util.module_from_spec(spec)
    # The current research calculator imports its sibling source_keys module.
    # Resolve it from this exact snapshot, never from another loaded snapshot
    # or the caller's checkout. Older snapshots need no sibling and still load.
    old_path = sys.path[:]
    old_source_keys = sys.modules.pop('source_keys', None)
    sys.path.insert(0, str(path.parent.resolve()))
    try:
        spec.loader.exec_module(module)
    finally:
        sys.path[:] = old_path
        sys.modules.pop('source_keys', None)
        if old_source_keys is not None:
            sys.modules['source_keys'] = old_source_keys
    # D1c5: the research calculator's file-scoped corrections use POSIX paths.
    # Normalize its in-memory rows BEFORE applying them, without editing the
    # snapshot or changing the calculator's math. This also keeps provenance
    # and ordering byte-identical when ItemDB is rebuilt on Windows.
    original_corrections = module.apply_corrections

    def portable_corrections(rows):
        return original_corrections([
            dict(row, _file=str(row.get('_file', '')).replace('\\', '/')) for row in rows
        ])

    module.apply_corrections = portable_corrections
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
    rows = resolve_ranked_outputs(module.load())
    # Their published run (all rows) only supplies the amount range per cast (e.g. 1-2 gems),
    # which reference rows often state and studies rarely do. A range is not a yield figure.
    published, _ = module.build(rows)
    ranges = {(e['method'], e['input'], e['outputItemID']): (e['range'], e['rangeSource']) for e in published}
    names = module.name_maps(rows)            # learn names from every row ...
    counted = [r for r in rows if is_counted(r, module)]
    families = load_families()
    for name, ids in families.items():        # D1c2: a name that is one single, unranked item
        if len(ids) == 1:
            names.setdefault(name, ids[0])
    module.name_maps = lambda _rows: names    # ... but count real studies only
    results, unplaced = module.build(counted)
    for e in results:
        e['range'], e['rangeSource'] = ranges.get((e['method'], e['input'], e['outputItemID']),
                                                  (e['range'], e['rangeSource']))
    batches = batch_sizes(counted, module, names)
    notes = Counter()
    groups = defaultdict(list)
    # D1c2: which items each (method, input) already has rank-specific figures for.
    known_outputs = defaultdict(set)
    for e in results:
        if isinstance(e['outputItemID'], int) and e['studies'] > 0 and not e['conditional']:
            known_outputs[(e['method'], e['input'])].add(e['outputItemID'])
    for e in results:
        if e['method'] not in SUPPORTED:
            notes['method not built into ItemDB yet'] += 1
            continue
        if e['conditional']:
            notes['conditional drop (needs an unlock the addon cannot check yet)'] += 1
            continue
        if not isinstance(e['outputItemID'], int):
            ids = families.get(str(e['outputItemID']).replace('family:', '', 1).strip().lower())
            if ids and len(ids) == 1:
                e['outputItemID'] = ids[0]
            elif ids and known_outputs[(e['method'], e['input'])] & set(ids):
                notes['rank unknown, but this input already has figures for the ranks'] += 1
                continue
            elif ids:   # D1c2: priced at the cheapest rank that has a price (runtime)
                e['rankIDs'] = ids
                e['outputItemID'] = ids[0]
                notes['+rank unknown: added, priced at the cheapest rank'] += 1
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
    rank_ids = estimates[0].get('rankIDs')
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
    # A precise occurrence count does not measure the average stack. Match
    # the runtime's half-confidence policy for a mean derived from a range.
    quantity_confidence = confidence if average_measured else confidence // 2
    # Serialize a consistent probability/mean pair. Independently rounding
    # 2/41 and 4/41 to six places made a fixed two-unit yield contradict
    # its probability and caused the runtime validator to reject all ItemDB.
    # Keep extra precision and constrain only serialization roundoff; source
    # counts and the earlier treatment of genuinely inconsistent means stay.
    chance = None if chance is None else round(chance, 12)
    if average is not None:
        average = round(average, 12)
        if chance is not None:
            average = min(max(average, chance * lo), chance * hi)
    casts_r = round(casts, 4)
    extra = {'rankIDs': rank_ids} if rank_ids else {}
    return {
        **extra,
        'id': item, '_casts': casts,
        'dropChance': field(chance, confidence, casts_r,
                            'measured' if chance_measured else 'provisional'),
        'expectedQuantity': field(average, quantity_confidence, round(qty_casts, 4),
                                  'measured' if average_measured else 'provisional'),
        'minQuantity': field(lo, confidence, casts_r, 'measured' if range_observed else 'provisional'),
        'maxQuantity': field(hi, confidence, casts_r, 'measured' if range_observed else 'provisional'),
    }


def render(records, snapshot, tokens=(), no_disenchant=()):
    info = json.loads((snapshot / 'SNAPSHOT.json').read_text())
    lines = [
        '-- Generated by tools/research_v3_to_baselines.py from the research team\'s v3 snapshot. Never hand-edit.',
        f"-- Source: {info['branch']} @ {info['commit'][:12]} ({info['committed']}); real studies only.",
        'return {schemaVersion=1,processing={',
    ]
    lines += [lua(r) + ',' for r in records]
    lines.append('},tokenRewards={')
    lines += [lua(t) + ',' for t in tokens]
    lines.append('},noDisenchant={')
    lines += [lua(n) + ',' for n in no_disenchant]
    lines.append('}}')
    return '\n'.join(lines) + '\n'


def summary(records, notes, total, counted, unplaced):
    inputs = Counter(r['method'] for r in records)
    lines = [f'RESEARCH V3 BASELINES: {len(records)} input record(s) '
             f'({", ".join(f"{m} {n}" for m, n in sorted(inputs.items()))}), '
             f'{sum(len(r["materials"]) for r in records)} materials, from {counted} of {total} rows '
             f'(reference values and re-imported old addon tables not counted; {unplaced} unplaced)']
    for why, n in sorted(notes.items()):
        if why.startswith('+'):
            lines.append(f'  added: {n} estimate(s): {why[1:]}')
        else:
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
    revision = json.loads((snapshot / 'SNAPSHOT.json').read_text())['commit']
    tokens, token_notes, conflicts = research_v3_tokens.build_tokens(snapshot, revision)
    no_de, no_de_notes = research_v3_no_disenchant.build_no_disenchant(snapshot)
    text = render(records, snapshot, tokens, no_de)
    if '--check' in argv:
        if not output.exists() or output.read_text() != text:
            print(f'{output} is out of date: run python3 tools/research_v3_to_baselines.py')
            return 1
        print(summary(records, notes, total, counted, unplaced).splitlines()[0])
        print(research_v3_tokens.summary(tokens, token_notes, conflicts).splitlines()[0])
        print(research_v3_no_disenchant.summary(no_de, no_de_notes).splitlines()[0])
        return 0
    output.write_text(text)
    print(summary(records, notes, total, counted, unplaced))
    print(research_v3_tokens.summary(tokens, token_notes, conflicts))
    print(research_v3_no_disenchant.summary(no_de, no_de_notes))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
