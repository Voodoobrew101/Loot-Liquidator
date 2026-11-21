"""Consume explicit, scoped backlog reviews; raw observations remain immutable.

The catalogue is research data, pinned by the normal build snapshot. Numerical
admissions are explicit field priors with unknown current-profile sample size;
original reported counts stay in provenance. A changed row expires only the
models which cite that row, not every review of the source page.
"""
from collections import Counter
from copy import deepcopy
from hashlib import sha256
import json
import math
from pathlib import Path

CATALOGUE = Path('research/v3/evidence/master/backlog-catalogue-20261120')
ROOT = Path(__file__).resolve().parent.parent
FIELDS = ('expectedQuantity', 'dropChance', 'minQuantity', 'maxQuantity')
METHODS = {'Disenchant': 'Enchanting', 'Mill': 'Inscription', 'Prospect': 'Jewelcrafting',
           'Smelt': 'Mining', 'Recycle': 'Engineering', 'Unravel': 'Tailoring',
           'Crush': 'Jewelcrafting', 'Thaumaturgy': 'Alchemy', 'Use': None}
TERMINAL = {'ADMITTED', 'ADMITTED_MODEL_PRIOR', 'ALREADY_REPRESENTED', 'METADATA_REFERENCE',
            'REJECTED_CURRENT_NUMERICAL_USE', 'REJECTED_CURRENT_USE', 'MIXED_CATALOGUED'}


def canonical_hash(value):
    value = {k: v for k, v in value.items() if not k.startswith('_')} if isinstance(value, dict) else value
    return sha256(json.dumps(value,
                            sort_keys=True, ensure_ascii=False, separators=(',', ':'),
                            allow_nan=False).encode()).hexdigest()


def number(value, *, maximum=None):
    return type(value) in (int, float) and math.isfinite(value) and value >= 0 and (maximum is None or value <= maximum)


def identity(value):
    return type(value) is int and 0 < value <= 2**53 - 1


def relative_path(root, relative):
    if not isinstance(relative, str) or not relative:
        raise ValueError('Reviewed source path is missing')
    relative = relative.replace('\\', '/')
    if len(relative)>1 and relative[1]==':':
        raise ValueError('Reviewed source path must be relative')
    result = (Path(root) / relative).resolve()
    if not result.is_relative_to(Path(root).resolve()):
        raise ValueError('Reviewed source path leaves its pinned snapshot')
    return result


def read_json(path):
    return json.loads(Path(path).read_text(encoding='utf-8-sig'))


def source_rows(snapshot, refs, effective=None, cache=None):
    """Validate physical immutable rows, plus the effective correction layer."""
    checked = []
    cache = {} if cache is None else cache
    for ref in refs:
        source_root = ROOT if ref.get('sourceRoot') == 'repository' else snapshot
        path = relative_path(source_root, ref['sourceFile'])
        if not path.is_file():
            return None, 'reviewed source file is missing'
        if path not in cache:
            cache[path] = path.read_text(encoding='utf-8-sig').splitlines()
        lines = cache[path]
        if 'jsonPointer' in ref:
            pointer = ref['jsonPointer']
            if not isinstance(pointer, str) or (pointer and not pointer.startswith('/')):
                raise ValueError('Invalid reviewed source JSON pointer')
            parsed_key = (path, 'parsed-json')
            if parsed_key not in cache:
                cache[parsed_key] = json.loads('\n'.join(lines))
            row = cache[parsed_key]
            try:
                for key in pointer.split('/')[1:] if pointer else []:
                    key = key.replace('~1', '/').replace('~0', '~')
                    row = row[int(key)] if isinstance(row, list) else row[key]
            except (IndexError, KeyError, TypeError, ValueError):
                return None, 'reviewed source JSON pointer changed'
            candidates = [row]
        elif ref.get('line'):
            line = ref['line']
            if type(line) is not int or line < 1 or line > len(lines):
                return None, 'reviewed source locator changed'
            candidates = [json.loads(lines[line - 1])]
        else:
            candidates = [json.loads(line) for line in lines if line.strip()]
            candidates = [r for r in candidates if r.get('id') == ref.get('sourceRecordID')]
        if len(candidates) != 1 or canonical_hash(candidates[0]) != ref['rawSHA256']:
            return None, 'reviewed source row changed'
        row = candidates[0]
        if not isinstance(row, dict):
            raise ValueError('A reviewed source proof must select an evidence object')
        record_id = ref.get('sourceRecordID', row.get('id'))
        if ref.get('sourceRecordID') and row.get('id') != ref['sourceRecordID']:
            return None, 'reviewed source record identity changed'
        if ref.get('effectiveSHA256') and effective is not None:
            current = effective.get((ref['sourceFile'], record_id))
            if current is None or canonical_hash(current) != ref['effectiveSHA256']:
                return None, 'reviewed source correction layer changed'
        checked.append(dict(ref, sourceRecordID=record_id, sourceStudyKey=row.get('studyKey'),
                            sourceURL=row.get('originalSource') or (row.get('source') or {}).get('url')))
    if not checked:
        raise ValueError('A reviewed numerical admission requires exact source rows')
    return checked, None


def field_value(spec, name):
    value = spec.get('value')
    if not number(value, maximum=1 if name == 'dropChance' else None):
        raise ValueError('Invalid reviewed source field ' + name)
    derivation = spec.get('derivation')
    if not isinstance(derivation, dict) or not derivation.get('kind'):
        raise ValueError('Reviewed source field requires a dimensioned derivation')
    kind = derivation['kind']
    if kind in {'ratio', 'source-table-fraction', 'positive-event-ratio'}:
        numerator, denominator = derivation.get('numerator'), derivation.get('denominator')
        if not number(numerator) or not number(denominator) or denominator <= 0:
            raise ValueError('Invalid reviewed source ratio')
        if not math.isclose(value, numerator / denominator, rel_tol=1e-10, abs_tol=1e-12):
            raise ValueError('Reviewed source ratio does not reproduce its value')
        if name == 'expectedQuantity' and derivation.get('denominatorMeaning') == 'positive-material-events':
            raise ValueError('Conditional positive-event quantity is not unconditional EV')
    elif kind == 'uniform-positive-stack-reference':
        p, lo, hi = derivation.get('sourceFraction'), derivation.get('lower'), derivation.get('upper')
        if not number(p, maximum=1) or not identity(lo) or not identity(hi) or lo > hi:
            raise ValueError('Invalid positive-stack reference derivation')
        if name != 'expectedQuantity' or not math.isclose(value, p * (lo + hi) / 2, rel_tol=1e-10, abs_tol=1e-12):
            raise ValueError('Reviewed positive-stack model does not reproduce its mean')
    elif kind not in {'explicit-source-value', 'explicit-complete-zero', 'reviewed-model-formula'}:
        raise ValueError('Unknown reviewed numerical derivation ' + str(kind))
    support = spec.get('sourceSupportConfidence', 20)
    cap = spec.get('modelConfidenceCap', 0)
    if not number(support, maximum=20) or support <= 0 or not number(cap, maximum=20):
        raise ValueError('Reviewed source support and model confidence must remain explicit and capped')
    if name in {'minQuantity', 'maxQuantity'} and not identity(value):
        raise ValueError('A positive conditional stack bound must be a whole positive unit')
    return {'value': value, 'status': 'historical', 'confidence': support,
            'modelConfidenceCap': cap, 'samples': 0, 'sampleSizeKnown': False,
            'independentConfidence': True, 'confidenceBasis': 'Reviewed source support; model applicability scored separately',
            'derivation': deepcopy(derivation)}


def unknown():
    return {'status': 'unknown', 'confidence': 0, 'inferenceBlocked': True,
            'samples': 0, 'sampleSizeKnown': False}


def model_record(spec, provenance, revision):
    method = spec['method']
    if method not in METHODS or not spec.get('recordID', '').startswith('evidence:reviewed-backlog:'):
        raise ValueError('Invalid reviewed backlog record identity/method')
    if not identity(spec.get('inputCount')):
        raise ValueError('Reviewed source input basis must be an explicit whole unit')
    if not identity(spec.get('inputItemID')) and not isinstance(spec.get('gearKey'), str):
        raise ValueError('Reviewed source input identity is unresolved')
    if not spec.get('assumptions') or not isinstance(spec.get('baselineProfile'), dict):
        raise ValueError('Reviewed source model requires an explicit profile and assumptions')
    if type(spec.get('expansionID')) is not int or not 0 <= spec['expansionID'] <= 11:
        raise ValueError('Reviewed source expansion identity is unresolved')
    if spec.get('sourceQuantityBasis', 'gross-input') not in {'gross-input', 'net-input', 'operation', 'nominal-stock-budget'}:
        raise ValueError('Unknown reviewed quantity input basis')
    materials = []
    seen = set()
    for item in spec['materials']:
        if not identity(item.get('id')) or item['id'] in seen:
            raise ValueError('Reviewed output item identity is unresolved/duplicated')
        seen.add(item['id'])
        material = {'id': item['id']}
        if item.get('economicPolicy') is not None:
            if item['economicPolicy'] != 'nontradable':
                raise ValueError('Unsupported reviewed material economic policy')
            material['economicPolicy'] = 'nontradable'
        for name in FIELDS:
            material[name] = field_value(item[name], name) if name in item else unknown()
        if not any('value' in material[name] for name in FIELDS):
            raise ValueError('Reviewed processing record has no admitted numerical fields')
        if item.get('rankIDs'):
            ids = item['rankIDs']
            if not isinstance(ids, list) or not all(identity(i) for i in ids) or item['id'] not in ids or len(set(ids)) != len(ids):
                raise ValueError('Invalid reviewed alternative output rank pool')
            material['rankIDs'] = deepcopy(ids)
        materials.append(material)
    proof = {'kind': 'REVIEWED_BACKLOG_FIELDS', 'policy': revision, 'sourceRows': provenance,
             'sourceKey': spec['sourceKey'], 'sourceStudyKey': spec['sourceStudyKey'],
             'reportedObservationCounts': deepcopy(spec.get('reportedObservationCounts', {})),
             'assumptions': deepcopy(spec['assumptions']), 'observedSamplesAdded': 0}
    record = {key: deepcopy(spec[key]) for key in (
        'recordID', 'method', 'inputCount', 'inputItemID', 'gearKey', 'expansionID', 'recipeID',
        'inputQualityRank', 'inputRarity', 'inputClassID', 'baselineProfile', 'baselineProfileAssumed',
        'referenceConditions', 'sourceQuantityBasis', 'requiresSourceNormalization', 'sourceEpoch',
        'quantityBasis', 'operationUnverified', 'baselineProfileConfidence', 'reviewedQualityProjection',
        'reviewedQualityZeroShares', 'isDisenchantCategory', 'categoryReferenceOnly',
        'categoryAssumption', 'namedOutputs', 'unknownOutputs', 'useReferenceOnly',
        'reviewedEffectOverrides', 'reviewedDisenchantProjection') if key in spec}
    record.update(profession=spec.get('profession') or METHODS[method],
                  studyID=spec['sourceStudyKey'], sourceKey='itemdb', source=spec.get('sourceTitle', 'Reviewed source catalogue'),
                  sourceURL=spec['sourceURL'], sourceEvidence=provenance,
                  reviewedPublishedPrior=proof, reviewedBacklogModel=True,
                  samples=0, sampleSizeKnown=False, provisional=True, fieldSpecificEvidence=True,
                  fixedReference=True, supersedesResearch=False,
                  referenceContextID=spec.get('referenceContextID', 'reviewed-backlog:' + spec['sourceStudyKey']),
                  baselineProfileConfidence=spec.get('baselineProfileConfidence', 0),
                  baselineStatus='Reviewed source fields with explicit source profile and units', materials=materials)
    return record


def catalogue_policies(snapshot):
    from source_catalogue_registry import catalogue_paths
    policies = []
    for folder in catalogue_paths(snapshot):
        policy = read_json(Path(snapshot) / folder / 'admitted-models.json')
        if policy.get('schemaVersion') != 1 or not isinstance(policy.get('models'), list) or not isinstance(policy.get('facts', []), list):
            raise ValueError('Unsupported reviewed source catalogue model schema')
        policies.append(policy)
    return policies


def preserve_reviewed_backlog(rows, records, notes, snapshot, *, proof_rows=None):
    policies = catalogue_policies(snapshot)
    effective = {(r.get('_file'), r.get('id')): r for r in (rows if proof_rows is None else proof_rows)}
    existing = {r['recordID'] for r in records}
    admitted = []
    cache = {}
    for spec, revision in ((spec, policy['revision']) for policy in policies for spec in policy['models']):
        if spec['recordID'] in existing:
            raise ValueError('Duplicated reviewed source model ' + spec['recordID'])
        proof, reason = source_rows(snapshot, spec['sourceRows'] + spec.get('supersedesSourceFields', []), effective, cache)
        if reason:
            notes['reviewed backlog model held: ' + reason] += 1
            continue
        record = model_record(spec, proof, revision)
        records.append(record)
        existing.add(record['recordID'])
        admitted.append(record)
        notes['+reviewed backlog source fields admitted without invented observed samples'] += 1
    return admitted


def apply_reviewed_field_replacements(rows, snapshot, notes, *, proof_rows=None):
    """Replace a cohort field only after verifying its actual replacement.

    Raw observations and unrelated fields remain intact. Changed replacement
    proofs expire locally instead of deleting a still usable old baseline.
    """
    policies = catalogue_policies(snapshot)
    if not policies:
        return rows
    effective = {(r.get('_file'), r.get('id')): r for r in (rows if proof_rows is None else proof_rows)}
    masks, cache = {}, {}
    for spec, revision in ((spec, policy['revision']) for policy in policies for spec in policy.get('models', [])):
        if not spec.get('supersedesSourceFields'):
            continue
        proof, reason = source_rows(snapshot, spec['sourceRows'], effective, cache)
        if reason:
            notes['reviewed field replacement expired: ' + reason] += 1
            continue
        replacement = model_record(spec, proof, revision)
        available = {field for material in replacement['materials'] for field in FIELDS
                     if 'value' in material[field]}
        pending = []
        for ref in spec['supersedesSourceFields']:
            fields = ref.get('fields')
            if not fields or not set(fields) <= available:
                raise ValueError('Reviewed field replacement lacks its replacement value')
            checked, reason = source_rows(snapshot, [ref], effective, cache)
            if reason:
                break
            key = (ref['sourceFile'], checked[0]['sourceRecordID'])
            if key not in effective:
                raise ValueError('Reviewed replacement does not identify a current source row')
            pending.append((key, fields))
        if reason:
            notes['reviewed field replacement expired: ' + reason] += 1
            continue
        for key, fields in pending:
            masks.setdefault(key, set()).update(fields)
    fact_index = {fact['factID']: fact for policy in policies for fact in policy.get('facts', [])}
    for exclusion in (item for policy in policies for item in policy.get('sourceFieldExclusions', [])):
        fields = exclusion.get('fields')
        fact_ids = exclusion.get('factIDs')
        if (not isinstance(fields, list) or not fields or not set(fields) <= set(FIELDS)
                or not isinstance(fact_ids, list) or not fact_ids or not all(identity in fact_index for identity in fact_ids)
                or not isinstance(exclusion.get('reason'), str) or len(exclusion['reason'].strip()) < 20
                or not exclusion.get('futureEvidenceTrigger')):
            raise ValueError('Current-field exclusion requires exact fields, retained source facts and a precise reason/trigger')
        refs = exclusion.get('sourceRows', [])
        fact_refs = [ref for identity in fact_ids for ref in fact_index[identity].get('sourceRows', [])]
        _, reason = source_rows(snapshot, refs + fact_refs, effective, cache)
        if reason:
            notes['reviewed current-field exclusion expired: ' + reason] += 1
            continue
        for ref in refs:
            key = (ref['sourceFile'], ref.get('sourceRecordID'))
            if key not in effective:
                raise ValueError('Current-field exclusion must identify an ordinary source row')
            masks.setdefault(key, set()).update(fields)
            notes['+nontransferable current fields retained as source facts'] += len(fields)
    result = []
    for row in rows:
        fields = masks.get((row.get('_file'), row.get('id')))
        if fields:
            row = dict(row, _reviewedSupersededFields=sorted(fields))
            notes['+reviewed source fields replaced without duplicate cohort weight'] += len(fields)
        result.append(row)
    return result


def reviewed_context_facts(snapshot, effective_rows=None):
    result = {'schemaVersion': 1, 'facts': []}
    policies = catalogue_policies(snapshot)
    if not policies:
        return result
    facts = [fact for policy in policies for fact in policy.get('facts', [])]
    if effective_rows is None and any(ref.get('effectiveSHA256') for fact in facts for ref in fact.get('sourceRows', [])):
        from research_v3_to_baselines import load_calculator
        effective_rows = load_calculator(snapshot).load_reviewed_source_rows()
    effective = None if effective_rows is None else {(r.get('_file'), r.get('id')): r for r in effective_rows}
    seen = set()
    cache = {}
    for fact in facts:
        if not isinstance(fact.get('factID'), str) or fact['factID'] in seen:
            raise ValueError('Duplicate reviewed context fact identity')
        proof, reason = source_rows(snapshot, fact['sourceRows'], effective=effective, cache=cache)
        if reason:
            continue
        if fact.get('confidence0to100') != 0 or not number(fact.get('sourceSupportConfidence', 20), maximum=20):
            raise ValueError('Reviewed historical context facts must preserve zero current-profile confidence')
        if 'value' in fact and not number(fact['value']):
            raise ValueError('Invalid reviewed source fact value')
        if not fact.get('unit') or not fact.get('metric'):
            raise ValueError('Reviewed source fact requires explicit unit and metric')
        copied = deepcopy(fact)
        copied['sourceRows'] = proof
        result['facts'].append(copied)
        seen.add(fact['factID'])
    result['facts'].sort(key=lambda r: r['factID'])
    return result
