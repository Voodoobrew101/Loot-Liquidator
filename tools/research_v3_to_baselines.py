#!/usr/bin/env python3
"""D1c: bring the research team's v3 results into ItemDB, counted once.

The five research agents (branch implementation/five-agent-completion) record evidence in
their own v3 format under research/v3/ and compute estimates with their own
research/v3/tools/build_estimates.py. This tool:

  1. --refresh  copies the inputs that calculator needs (evidence, corrections, conditions,
                rate changes and the calculator itself) from their branch into a pinned
                snapshot, database/research/v3-snapshot/, and records the commit in
                database/research/v3-snapshot/SNAPSHOT.json. Their files are never edited.
  2. (default)  uses the snapshot's identity and scope rules to calculate each field from its
                own evidence. Two kinds of rows stay out of the counts:
                  * reference values (sourceKind tsm-table / compiled-research / reference):
                    TSM's old table is not used for yields (owner decision 3), and the
                    compiled research rows are already in ItemDB;
                  * imported/gamedata-disenchant.jsonl: the addon's own old disenchant tables,
                    which already ship as the "Legacy" source.
                In-memory identity corrections preserve the snapshot. Output records carry
                separate weighted sample counts for occurrence, mean, and observed bounds.
                Published estimates without denominators can remain provisional with zero
                observed samples. Per-cast occurrence and bounds require their own batch size;
                supported mean units can be converted across known batch sizes.

Each record says supersedesResearch=true so tools/compile_itemdb.lua can suppress duplicate
older research for fields covered by v3. Older rows stay in the source file.

Left out, with the reason in the report (nothing is deleted from the research data):
  * conditional drops (need a specialization unlock or skill; the addon can't tell yet);
  * inputs without an unambiguous ItemDB identity;
  * output families that lack a verified item list or overlap an existing exact-rank result.
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
import math
import subprocess
import sys
sys.dont_write_bytecode = True  # never leave cache files in the repo or snapshot
import tarfile
import io
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from evidence_to_baselines import lua, quality_score, rate_confidence, NOT_BASELINE_FACTOR  # noqa: E402
from research_v3_evidence import build_field_support  # noqa: E402
from research_v3_reference_ranges import preserve_reference_range  # noqa: E402
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
IDENTITY_CORRECTION = 'same-output-token/1 (S21: equal totals do not identify a material)'
PROVISIONAL_SUPPORT_SCORE = 20


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


# ---- 2. load the pinned identity and scope rules
def normalized_text(value):
    return value.strip().casefold() if isinstance(value, str) else ''


def replacement_scope_matches(left, right):
    if (left.get('type'), left.get('method')) != (right.get('type'), right.get('method')):
        return False
    for side in ('input', 'output'):
        left_id, right_id = (row.get(side + 'ItemID') for row in (left, right))
        left_rank, right_rank = (row.get(side + 'Rank') for row in (left, right))
        if left_rank is not None and right_rank is not None and left_rank != right_rank:
            return False
        if left_id is not None and right_id is not None:
            if left_id != right_id:
                return False
        else:
            names = [normalized_text(row.get(side + 'Name')) for row in (left, right)]
            if names[0] and names[0] == names[1]:
                continue
            if side != 'input' or not left.get('gearGroup') or left.get('gearGroup') != right.get('gearGroup'):
                return False
    return True


def original_source(row):
    source = row.get('source')
    return row.get('originalSource') or (source.get('url') if isinstance(source, dict) else None)


def same_replacement_source(left, right, module):
    sources = [original_source(row) for row in (left, right)]
    if not all(isinstance(source, str) and source for source in sources) or module.source_key(left) != module.source_key(right):
        return False
    authors = [normalized_text(source.get('author')) for source in (left.get('source'), right.get('source'))
               if isinstance(source, dict)]
    return len(authors) < 2 or not all(authors) or authors[0] == authors[1]


def resolve_replacements(rows, module, notes):
    by_id = defaultdict(list)
    for row in rows:
        if isinstance(row.get('id'), str):
            by_id[row['id']].append(row)
    removed, held = set(), set()
    for replacement in rows:
        target = replacement.get('replaces')
        if not isinstance(target, str) or not target:
            continue
        candidates = [row for row in by_id[target] if row is not replacement]
        declared_file = replacement.get('replacesFile')
        if isinstance(declared_file, str) and declared_file:
            candidates = [row for row in candidates if row['_file'] == declared_file.replace('\\', '/')]
            if not candidates:
                held.add(id(replacement))
                notes['replacement names an unavailable source file'] += 1
                continue
        if len(candidates) == 1:
            candidate = candidates[0]
            old_input, new_input = candidate.get('inputItemID'), replacement.get('inputItemID')
            if (candidate.get('method') != replacement.get('method')
                    or (old_input is not None and new_input is not None and old_input != new_input)):
                held.add(id(replacement))
                notes['replacement method or input does not match source'] += 1
            else:
                removed.add(id(candidate))
        elif len(candidates) > 1:
            scoped = [row for row in candidates if replacement_scope_matches(row, replacement)]
            matched = [row for row in scoped if same_replacement_source(row, replacement, module)]
            if len(matched) == 1:
                removed.add(id(matched[0]))
                notes['+replacement resolved by source and item scope'] += 1
            else:
                held.update(id(row) for row in (matched or scoped))
                held.add(id(replacement))
                notes['ambiguous evidence replacement held'] += 1
    return [row for row in rows if id(row) not in removed and id(row) not in held]


def load_calculator(snapshot):
    snapshot = Path(snapshot).resolve()
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
    module.evidence_load_notes = Counter()

    def scoped_load():
        rows = []
        notes = Counter()
        for evidence_path in sorted((snapshot / 'research' / 'v3' / 'evidence').rglob('*.jsonl')):
            if not evidence_path.is_file():
                continue
            relative = evidence_path.relative_to(snapshot).as_posix()
            with evidence_path.open(encoding='utf-8') as stream:
                for line in stream:
                    if not line.strip():
                        continue
                    try:
                        row = json.loads(line)
                    except json.JSONDecodeError:
                        row = None
                    if isinstance(row, dict):
                        rows.append(dict(row, _file=relative))
                    else:
                        notes['malformed evidence row'] += 1
        scoped = resolve_replacements(rows, module, notes)
        module.evidence_load_notes = notes
        return module.apply_corrections(scoped)

    module.load = scoped_load
    if hasattr(module, 'study_vectors') and hasattr(module, 'study_identity'):
        original_vectors = module.study_vectors
        original_identity = module.study_identity
        cohort_aliases = {}

        def linked_vectors(rows):
            result = original_vectors(rows)
            vectors = result[0]
            # A refresh can label a cohort while older transcriptions still
            # use its numeric fingerprint. Link only an unambiguous match of
            # source, input rank, casts and the calculator's whole-study vector.
            # Distinct explicit cohort keys must remain independent.
            def fingerprint(row):
                return (module.source_key(row), row.get('method'),
                        json.dumps(row.get('inputItemID') or row.get('inputName') or row.get('gearGroup'), sort_keys=True),
                        row.get('inputRank'),
                        module.num(row.get('casts')), vectors[module.study_ref(row)])

            labelled = defaultdict(set)
            for row in rows:
                if module.is_study_row(row) and row.get('cohortKey'):
                    labelled[fingerprint(row)].add(row['cohortKey'])
            cohort_aliases.clear()
            for row in rows:
                if module.is_study_row(row) and not row.get('cohortKey'):
                    matches = labelled.get(fingerprint(row), ())
                    if len(matches) == 1:
                        cohort_aliases[id(row)] = ('cohort', next(iter(matches)))
            return result

        def linked_identity(row, vectors):
            return cohort_aliases.get(id(row)) or original_identity(row, vectors)

        module.study_vectors = linked_vectors
        module.study_identity = linked_identity
    # S21: the pinned estimator's same_output accepts ANY nonzero row. An exact
    # Diamond ID can then suppress a different, rank-unknown Amber output with
    # the same total. Correct identity only, retaining the estimator's cohort
    # dedupe, units, counts and math. Keep raw evidence and snapshot bytes intact.
    # Output aliases must already be resolved by sourced identity normalization;
    # equal quantities alone cannot establish that differently named outputs match.
    if hasattr(module, 'same_output'):
        def same_output_identity(row, other, ids):
            return (module.item_token(row, 'outputItemID', 'outputName', ids)
                    == module.item_token(other, 'outputItemID', 'outputName', ids))
        module.same_output = same_output_identity
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


def supported_bound(value):
    return type(value) in (int, float) and 1 <= value <= 2**53 - 1 and value % 1 == 0


def reference_ranges(rows, module, names):
    """Original positive bounds by exact operation, usable as a provisional range only."""
    ranges = defaultdict(dict)
    for r in rows:
        if r.get('type') != 'drop' or r.get('sourceKind') not in module.REFERENCE_KINDS:
            continue
        key = module.key_of(r, names)
        batch = module.row_unit(r) if key else None
        if not key or not supported_bound(batch):
            continue
        bounds = ranges[(*key, int(batch))]
        for raw, field_name, select in (('minSeen', 'minQuantity', min), ('maxSeen', 'maxQuantity', max)):
            value = r.get(raw)
            if supported_bound(value):
                bounds[field_name] = select(bounds.get(field_name, value), value)
    return ranges


def retail_admission(rows):
    """Quarantine reviewed cohorts before any numeric/range use; never edit evidence.

    Classic mirror URLs alone do not identify a Classic observation. Exclusions
    require a reviewed identity; renamed copies sharing its studyKey stay excluded.
    """
    path = Path(__file__).resolve().parent.parent / 'database/research/retail-admission.json'
    policy = json.loads(path.read_text())
    # A malformed policy must not silently turn a reviewed hold into admission.
    # This validates policy structure, not the wider research row schema.
    if not isinstance(policy, dict) or type(policy.get('version')) is not int or policy['version'] != 1:
        raise ValueError('Unsupported Retail admission policy version')
    if not isinstance(policy.get('exclusions'), list):
        raise ValueError('Retail admission exclusions must be a list')
    for rule in policy['exclusions']:
        if not isinstance(rule, dict):
            raise ValueError('Retail admission exclusion must be an object')
        for key in ('recordIDs', 'studyKeys'):
            values = rule.get(key)
            if not isinstance(values, list) or any(not isinstance(value, str) or not value.strip() for value in values):
                raise ValueError('Retail admission ' + key + ' must be a list of nonempty strings')
        if not rule['recordIDs'] and not rule['studyKeys']:
            raise ValueError('Retail admission exclusion needs at least one identity')
        for key in ('reason', 'review'):
            if not isinstance(rule.get(key), str) or not rule[key].strip():
                raise ValueError('Retail admission exclusion needs nonempty ' + key)
    admitted, excluded = [], Counter()
    for row in rows:
        match = next((rule for rule in policy['exclusions']
                      if row.get('id') in rule['recordIDs']
                      or row.get('studyKey') in rule['studyKeys']), None)
        if match:
            excluded['Retail admission: ' + match['reason']] += 1
        else:
            admitted.append(row)
    return admitted, excluded


def build(snapshot):
    module = load_calculator(snapshot)
    rows = resolve_ranked_outputs(preserve_reference_range(module.load()))
    total = len(rows)
    rows, admission_notes = retail_admission(rows)
    names = module.name_maps(rows)
    counted = [r for r in rows if is_counted(r, module)]
    families = load_families()
    for name, ids in families.items():
        if len(ids) == 1:
            names.setdefault(name, ids[0])
    ranges = reference_ranges(rows, module, names)
    results, evidence_notes, unplaced = build_field_support(module, counted, names)
    notes = module.evidence_load_notes + admission_notes + evidence_notes
    groups = defaultdict(list)
    known_outputs = defaultdict(set)
    for e in results:
        if isinstance(e['outputItemID'], int) and supported_bound(e['inputsPerCast']) and not e['conditional']:
            known_outputs[(e['method'], e['input'], int(e['inputsPerCast']))].add(e['outputItemID'])
    for e in results:
        if e['method'] not in SUPPORTED:
            notes['method not built into ItemDB yet'] += 1
            continue
        if e['conditional']:
            notes['conditional drop (needs an unlock the addon cannot check yet)'] += 1
            continue
        per_cast = e['inputsPerCast']
        if not supported_bound(per_cast):
            notes['batch size (inputs per cast) not stated'] += 1
            continue
        scope = (e['method'], e['input'], e['outputItemID'], int(per_cast))
        e['referenceRanges'] = ranges.get(scope, {})
        if not isinstance(e['outputItemID'], int):
            ids = families.get(str(e['outputItemID']).replace('family:', '', 1).strip().lower())
            if ids and len(ids) == 1:
                e['outputItemID'] = ids[0]
            elif ids and known_outputs[(e['method'], e['input'], int(per_cast))] & set(ids):
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
        else:
            key = e['input']
        groups[(e['method'], key, int(per_cast))].append(e)
    records = []
    for (method, key, per_cast), estimates in sorted(groups.items()):
        by_output = {}
        for e in estimates:   # a gear group written two ways (names / numbers) adds up
            by_output.setdefault(e['outputItemID'], []).append(e)
        materials = [material(item, es) for item, es in sorted(by_output.items())]
        for m in materials:
            if 'heldDropChance' in m:
                notes['+expected quantity kept; conflicting occurrence held'] += 1
            if 'heldExpectedQuantity' in m:
                notes['+occurrence kept; conflicting expected quantity held'] += 1
            if m.get('samplingVariation'):
                notes['+occurrence and quantity retained within sample variation tolerance'] += 1
        record_id = f'evidence:v3:{method}:{key}:x{per_cast}'
        row = {
            'recordID': record_id, 'studyID': record_id, 'sourceKey': 'itemdb', 'method': method,
            'profession': SUPPORTED[method], 'inputCount': per_cast, 'provisional': True,
            'supersedesResearch': True, 'fieldSpecificEvidence': True,
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
    return records, notes, total, len(counted), unplaced


def unknown(*, block_inference=False):
    result = {'status': 'unknown', 'confidence': 0}
    if block_inference:
        result['inferenceBlocked'] = True
    return result


def numeric_field(estimates, name):
    support = [e['fieldSupport'][name] for e in estimates if name in e['fieldSupport']]
    if not support:
        return unknown()
    counted = [f for f in support if f['casts'] > 0]
    casts = sum(f['casts'] for f in counted)
    effective_casts = casts * NOT_BASELINE_FACTOR
    reported_casts = 0
    if counted:
        numerator = 'hits' if name == 'dropChance' else 'total'
        total = sum(f[numerator] for f in counted)
        value = total / casts
        confidence = (rate_confidence(total * NOT_BASELINE_FACTOR, effective_casts)
                      if name == 'dropChance' else quality_score(effective_casts))
    else:
        values = [f['value'] for f in support]
        if not math.isclose(min(values), max(values), abs_tol=1e-9):
            return unknown(block_inference=True)
        value, confidence = values[0], PROVISIONAL_SUPPORT_SCORE
        reported_casts = max(f.get('reportedCasts', 0) for f in support)
        if reported_casts:
            confidence = max(1, quality_score(reported_casts * NOT_BASELINE_FACTOR) // 2)
    result = {'value': value, 'confidence': confidence, 'samples': round(effective_casts, 4),
              'sampleSizeKnown': bool(counted),
              'status': 'measured' if counted and all(f['status'] == 'measured' for f in counted) else 'provisional'}
    if name == 'expectedQuantity':
        result.update(independentConfidence=True, confidenceBasis='Ordinal expected quantity source support')
        if reported_casts:
            result.update(reportedCasts=reported_casts, confidenceBasis='Ordinal source support for a reported mean')
    return result


def bound_field(estimates, name, select):
    support = [e['fieldSupport'][name] for e in estimates if name in e['fieldSupport']]
    if support:
        chosen = select(support, key=lambda f: f['value'])
        casts = chosen['casts'] * NOT_BASELINE_FACTOR
        return {'value': chosen['value'], 'status': chosen['status'], 'samples': round(casts, 4),
                'sampleSizeKnown': casts > 0, 'confidence': quality_score(casts) if casts > 0 else PROVISIONAL_SUPPORT_SCORE}
    references = [e['referenceRanges'][name] for e in estimates if name in e.get('referenceRanges', {})]
    if references:
        return {'value': select(references), 'status': 'provisional', 'samples': 0, 'sampleSizeKnown': False,
                'confidence': PROVISIONAL_SUPPORT_SCORE}
    return unknown()


def counted_cohorts(estimates, name):
    return {cohort for estimate in estimates
            for cohort in estimate['fieldSupport'].get(name, {}).get('_countedCohorts', ())}


def sampling_compatible(occurrence, quantity, boundary, estimates):
    """A bounded diagnostic for slightly different estimates from different cast pools."""
    if occurrence['status'] != 'measured' or quantity['status'] != 'measured':
        return False
    p, q = occurrence['value'], quantity['value'] / boundary
    n_p, n_q = occurrence['samples'], quantity['samples']
    if not (0 < p <= 1 and 0 < q <= 1 and min(n_p, n_q) >= 2):
        return False
    p_cohorts = counted_cohorts(estimates, 'dropChance')
    q_cohorts = counted_cohorts(estimates, 'expectedQuantity')
    if not p_cohorts or not q_cohorts or p_cohorts == q_cohorts:
        return False
    # Compare on the occurrence scale. The Bernoulli proxy and fixed caps
    # avoid interpreting a small discrepancy as a proof of a common population.
    error = math.sqrt(p * (1 - p) / n_p + q * (1 - q) / n_q)
    return abs(p - q) <= min(0.01, 0.1 * max(p, q), 2 * error) + 1e-9


def support_strength(field):
    if field['sampleSizeKnown']:
        return 2, field['samples'], field['status'] == 'measured'
    return 1, field.get('reportedCasts', 0), False


def material(item, estimates):
    occurrence = numeric_field(estimates, 'dropChance')
    quantity = numeric_field(estimates, 'expectedQuantity')
    lower = bound_field(estimates, 'minQuantity', min)
    upper = bound_field(estimates, 'maxQuantity', max)
    p, e, lo, hi = (field.get('value') for field in (occurrence, quantity, lower, upper))
    if lo is not None and hi is not None and lo > hi:
        if lower['status'] == upper['status']:
            lower = upper = unknown()
        elif lower['status'] == 'measured':
            upper = unknown()
        else:
            lower = unknown()
        lo, hi = lower.get('value'), upper.get('value')
    out = {'id': item, 'dropChance': occurrence, 'expectedQuantity': quantity,
           'minQuantity': lower, 'maxQuantity': upper}
    if estimates[0].get('rankIDs'):
        out['rankIDs'] = estimates[0]['rankIDs']
    if p is not None and e is not None:
        boundary = None
        if e + 1e-9 < p * (lo or 1):
            boundary = lo or 1
        elif hi is not None and e > p * hi + 1e-9:
            boundary = hi
        zero_conflict = (p == 0) != (e == 0)
        if not zero_conflict and boundary is not None and sampling_compatible(occurrence, quantity, boundary, estimates):
            out['samplingVariation'] = True
            boundary = None
        if (zero_conflict or boundary is not None) and support_strength(occurrence) > support_strength(quantity):
            out['heldExpectedQuantity'] = quantity
            out['expectedQuantity'] = unknown(block_inference=True)
        elif zero_conflict or boundary is not None:
            out['heldDropChance'] = occurrence
            out['dropChance'] = unknown(block_inference=True)
    if p is None and e is not None:
        out['dropChance']['inferenceBlocked'] = True
    if e is None and p != 0 and (lo is None or hi is None):
        out['expectedQuantity']['inferenceBlocked'] = True
    out['_casts'] = max(occurrence.get('samples', 0), quantity.get('samples', 0),
                        lower.get('samples', 0), upper.get('samples', 0))
    return out


def render(records, snapshot, tokens=(), no_disenchant=()):
    info = json.loads((snapshot / 'SNAPSHOT.json').read_text())
    lines = [
        '-- Generated by tools/research_v3_to_baselines.py from the research team\'s v3 snapshot. Never hand-edit.',
        f"-- Source: {info['branch']} @ {info['commit'][:12]} ({info['committed']}); real studies only.",
        f'-- Import identity correction: {IDENTITY_CORRECTION}.',
        'return {schemaVersion=1,sourceRevision=' + lua(info['commit'])
        + ',sourceBranch=' + lua(info['branch']) + ',processing={',
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
        if not output.exists() or output.read_text(encoding='utf-8') != text:
            print(f'{output} is out of date: run python3 tools/research_v3_to_baselines.py')
            return 1
        print(summary(records, notes, total, counted, unplaced).splitlines()[0])
        print(research_v3_tokens.summary(tokens, token_notes, conflicts).splitlines()[0])
        print(research_v3_no_disenchant.summary(no_de, no_de_notes).splitlines()[0])
        return 0
    output.write_text(text, encoding='utf-8', newline='\n')
    print(summary(records, notes, total, counted, unplaced))
    print(research_v3_tokens.summary(tokens, token_notes, conflicts))
    print(research_v3_no_disenchant.summary(no_de, no_de_notes))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
