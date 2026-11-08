"""Validate complete addon JSON export pages and stage empirical baselines.

No weights, skill coefficients, confidence scores or mechanics approvals are
inferred. This is structural validation of measurements, not scientific review.
"""
from __future__ import annotations
import argparse
import collections
import json
import math
import hashlib
import functools
import base64
import binascii
import zlib
from pathlib import Path

SCHEMA = 'loot-liquidator.cast-log/1'
METHODS = {'Disenchant', 'Mill', 'Prospect', 'Smelt', 'Craft', 'Recycle', 'Research', 'Unravel', 'Thaumaturgy'}
SALVAGE_BATCHES = {('Recycle', 1229930): 5, ('Craft', 1280394): 1}
REVIEW_ROOT = Path(__file__).resolve().parents[1] / 'research/integration/measured-captures/2026-11-07-recycling-200-casts'


def require(value, message):
    if not value:
        raise ValueError(message)


def integer(value, minimum=1):
    return type(value) is int and value >= minimum


def vector(items, allow_zero=False):
    require(isinstance(items, list), 'Item vectors must be JSON arrays, including empty outputs')
    out = {}
    for item in items:
        require(isinstance(item, dict) and integer(item.get('itemID')) and
                integer(item.get('quantity'), 0 if allow_zero else 1), 'Invalid item identity or quantity')
        require(item['itemID'] not in out, 'Duplicate item in vector')
        out[item['itemID']] = item['quantity']
    return out


def unpack_transfer(page):
    if not isinstance(page, dict) or page.get('schemaVersion') != 'loot-liquidator.cast-transfer/1':
        return page
    require(page.get('encoding') == 'zlib-base64', 'Unsupported compact export encoding')
    size = page.get('uncompressedBytes')
    require(integer(size) and size <= 16777216, 'Invalid compact export length')
    payload = page.get('payload')
    require(isinstance(payload, str) and len(payload) <= 65536, 'Invalid compact export payload')
    try:
        compressed = base64.b64decode(payload, validate=True)
        decoder = zlib.decompressobj()
        raw = decoder.decompress(compressed, size + 1)
        require(len(raw) == size and decoder.eof and not decoder.unconsumed_tail and not decoder.unused_data,
                'Damaged compact export length or trailing data')
        inner = json.loads(raw.decode('utf-8'))
    except (ValueError, binascii.Error, zlib.error, UnicodeError) as exc:
        raise ValueError('Damaged compact export: ' + str(exc)) from exc
    require(isinstance(inner, dict) and inner.get('schemaVersion') == SCHEMA, 'Invalid compact research data')
    return inner


def validate(pages):
    pages = [unpack_transfer(page) for page in pages]
    require(pages, 'No export pages supplied')
    records, contexts, studies, page_numbers = [], {}, {}, set()
    def finite_tree(value):
        if isinstance(value, float):
            require(math.isfinite(value), 'Nonfinite measurements are invalid')
        elif isinstance(value, dict):
            for child in value.values(): finite_tree(child)
        elif isinstance(value, list):
            for child in value: finite_tree(child)
    finite_tree(pages)
    first = pages[0]
    for page in pages:
        require(page.get('schemaVersion') == SCHEMA and page.get('artifactStatus') == 'RESEARCH_ONLY_NOT_SHIPPED',
                'Unsupported observation schema or production artifact')
        require(page.get('registryContract') == 'profession-mechanics/0.2' and
                page.get('automaticMechanicsPromotion') is False, 'Missing non-promotion contract')
        require(integer(page.get('page')) and integer(page.get('pages')) and
                page['pages'] == first['pages'] and page.get('retainedRecords') == first.get('retainedRecords'),
                'Export pages are inconsistent; repeat export after recording stops')
        require(page['page'] not in page_numbers, 'Duplicate export page')
        page_numbers.add(page['page'])
        require(isinstance(page.get('records'), list), 'Records must be an array')
        records.extend(page['records'])
        for target, field in ((contexts, 'contexts'), (studies, 'studies')):
            for key, value in page.get(field, {}).items():
                require(key not in target or target[key] == value, f'Conflicting {field} identity')
                target[key] = value
    require(page_numbers == set(range(1, first['pages'] + 1)) and len(records) == first['retainedRecords'],
            'All pages from the same export are required before calculating baselines')
    ids = set()
    for r in records:
        require(r.get('schemaVersion') == SCHEMA and r.get('method') in METHODS and integer(r.get('recipeID')),
                'Missing operation method/recipe identity')
        require(isinstance(r.get('operationID'), str) and r['operationID'] and r['operationID'] not in ids,
                'Duplicate or missing operation ID')
        ids.add(r['operationID'])
        require(r.get('successful') is True and r.get('outputCoverage') in ('complete', 'unresolved'),
                'Unconfirmed cast or missing coverage')
        context = contexts.get(r.get('contextID'))
        study = studies.get(r.get('studyID'))
        require(context and study and r.get('character') == context.get('character') == study.get('character') and
                r.get('build') == study.get('build'), 'Unknown or mismatched context/study identity')
        require(context.get('simulated') is False and context.get('profileKind') == 'measured',
                'Manual simulation cannot be exported as a measured sample')
        require(context.get('recipeID') == r['recipeID'] and context.get('method') == r['method'],
                'Context recipe/method identity disagrees with operation')
        provenance = r.get('provenance', {})
        require(provenance.get('sampleKind') == 'RAW_CAST_LOG' and
                provenance.get('numericTransformValidated') is False and
                provenance.get('applyPolicy') == 'NO_NUMERIC_TRANSFORM' and
                provenance.get('independentReview') == 'PENDING', 'Observation has an unsafe mechanics approval')
        inputs, outputs = vector(r['inputs'], allow_zero=True), vector(r['outputs'])
        require(inputs, 'Missing input identity')
        require('nominalInputs' in r or all(q > 0 for q in inputs.values()),
                'Zero consumption needs nominal inputs and verified returns')
        if not outputs and r['outputCoverage'] == 'complete':
            require(r.get('zeroEvidence') == 'operator-confirmed-empty' and integer(r.get('confirmedAt'), 0),
                    'Empty outputs are unresolved unless explicitly confirmed')
        if 'nominalInputs' in r:
            nominal = vector(r['nominalInputs'])
            returned = collections.Counter()
            seen_returns = {}
            for result in r.get('resultMetadata', []):
                refunds = result.get('resourcesReturned', [])
                if refunds:
                    operation_id = result.get('operationID')
                    require(integer(operation_id), 'Uncorrelated resource return')
                    require(operation_id not in seen_returns or seen_returns[operation_id] == refunds,
                            'Conflicting resource returns')
                    if operation_id in seen_returns: continue
                    seen_returns[operation_id] = refunds
                for refund in result.get('resourcesReturned', []):
                    require(integer(refund.get('quantity')) and integer(refund.get('reagent', {}).get('itemID')),
                            'Invalid reported input return')
                    returned[refund['reagent']['itemID']] += refund['quantity']
            require(inputs.keys() == nominal.keys() and not (returned.keys() - nominal.keys()) and
                    all(inputs[item] == qty - returned[item] for item, qty in nominal.items()),
                    'Nominal consumption/net inputs/refunds disagree')
    # Version3 verified salvage separates per-cast typed receipts while reconciling a
    # consecutive sequence against one inventory delta. Every member must be
    # present, and the receipts, individual vectors and shared delta must agree.
    batches = collections.defaultdict(list)
    result_operations = set()
    for r in records:
        if r.get('attribution') != 'cast-result-batch-bag':
            continue
        batch_size = SALVAGE_BATCHES.get((r['method'], r['recipeID']))
        require(batch_size is not None and r.get('captureVersion') == 3,
                'Unsupported batch reconciliation operation')
        evidence = r.get('bagReconciliation', {})
        batch_id = evidence.get('id')
        require(isinstance(batch_id, str) and batch_id and integer(evidence.get('operations')),
                'Invalid salvage reconciliation membership')
        typed = collections.Counter()
        operation = None
        receipts = r.get('resultMetadata')
        require(isinstance(receipts, list) and receipts, 'Missing salvage result receipts')
        for receipt in receipts:
            require(integer(receipt.get('operationID')) and integer(receipt.get('itemID')) and
                    integer(receipt.get('quantity')) and isinstance(receipt.get('itemGUID'), str) and receipt['itemGUID'],
                    'Invalid salvage result receipt')
            require(operation is None or operation == receipt['operationID'], 'Multiple salvage result operations')
            operation = receipt['operationID']
            typed[receipt['itemID']] += receipt['quantity']
        require(operation not in result_operations, 'Duplicate salvage result operation')
        result_operations.add(operation)
        require(dict(typed) == vector(r['outputs']), 'salvage receipts and outputs disagree')
        nominal = vector(r.get('nominalInputs'))
        require(len(nominal) == 1 and next(iter(nominal.values())) == batch_size, 'Invalid nominal salvage batch')
        target = r.get('salvageTarget', {})
        require(target.get('itemID') in nominal and target.get('quantity') == batch_size and
                isinstance(target.get('itemGUID'), str) and target['itemGUID'] and
                target['itemGUID'] == r.get('allocationItemGUID') and
                target.get('eligibilitySource') == 'C_TradeSkillUI.GetSalvagableItemIDs',
                'Missing verified salvage target')
        batches[(r['studyID'], r['method'], r['recipeID'], batch_id)].append(r)
    for (_, _, _, batch_id), members in batches.items():
        evidence = members[0]['bagReconciliation']
        require(len(members) == evidence['operations'] and batch_id in {r['operationID'] for r in members},
                'Missing salvage reconciliation casts')
        total_inputs, total_outputs = collections.Counter(), collections.Counter()
        for r in members:
            require(r['bagReconciliation'] == evidence, 'Conflicting salvage reconciliation evidence')
            total_inputs.update(vector(r['inputs'], allow_zero=True))
            total_outputs.update(vector(r['outputs']))
        require({i: n for i, n in total_inputs.items() if n} == vector(evidence.get('inputs')) and
                dict(total_outputs) == vector(evidence.get('outputs')), 'salvage batch inventory totals disagree')
    return records, contexts, studies


def observation_signature(record, context):
    return json.dumps({'record': {k: v for k, v in record.items() if k != 'contextID'},
                       'context': context}, sort_keys=True, ensure_ascii=True)


@functools.lru_cache(maxsize=1)
def reviewed_legacy_capture():
    """An explicit, hash-bound review of the owner's preserved 200-cast capture.

    Legacy bounded diagnostics cannot reconstruct arbitrary old study coverage.
    This review admits only the exact reviewed observations, never new records
    appended to a censored study or other legacy exports.
    """
    path = REVIEW_ROOT / 'coverage-review.json'
    if not path.exists(): return {}, {}
    review = json.loads(path.read_text())
    pages = []
    for source in review['pages']:
        raw = (REVIEW_ROOT / source['file']).read_bytes()
        require(hashlib.sha256(raw).hexdigest() == source['sha256'], 'Reviewed capture page checksum changed')
        pages.append(json.loads(raw))
    records, contexts, studies = validate(pages)
    selected = {r['operationID']: observation_signature(r, contexts[r['contextID']])
                for r in records if r['operationID'] in review['operationIDs']}
    require(len(selected) == len(review['operationIDs']) == 200, 'Reviewed capture membership changed')
    return selected, {review['studyID']: studies[review['studyID']]}


def coverage_reason(study_id, study, method, recipe, cohort, contexts):
    if study.get('truncated') or study.get('globalCoverageGap'):
        return 'Study capture was truncated or session coverage is unknown'
    if not study.get('censored'): return None
    if study.get('coverageVersion') == 2:
        gaps = study.get('coverageGaps')
        if not isinstance(gaps, dict) or not gaps:
            return 'Missing recipe coverage ledger'
        if f'{method}:{recipe}' in gaps:
            return 'Recipe capture has unresolved coverage gaps'
        return None
    reviewed, original_studies = reviewed_legacy_capture()
    original = original_studies.get(study_id)
    fields = ('censored', 'truncated', 'coverageReason', 'coverageOperationID')
    if original and all(study.get(k) == original.get(k) for k in fields) and all(
            reviewed.get(r['operationID']) == observation_signature(r, contexts[r['contextID']]) for r in cohort):
        return None
    return 'Legacy study has unscoped coverage gaps'


def compile_baselines(pages):
    records, contexts, studies = validate(pages)
    grouped = collections.defaultdict(list)
    for r in records:
        key = (r['studyID'], r['contextID'], r['recipeID'])
        grouped[key].append(r)
    result, excluded = [], []
    for (study_id, context_id, recipe), cohort in sorted(grouped.items()):
        study = studies[study_id]
        reason = coverage_reason(study_id, study, cohort[0]['method'], recipe, cohort, contexts)
        if any(r['outputCoverage'] != 'complete' for r in cohort): reason = 'Unresolved output coverage'
        nominal = cohort[0].get('nominalInputs', cohort[0]['inputs'])
        if any(r.get('nominalInputs', r['inputs']) != nominal for r in cohort):
            reason = 'Unlike input batches or variants'
        if reason:
            excluded.append({'studyID': study_id, 'contextID': context_id, 'recipeID': recipe, 'reason': reason})
            continue
        n = len(cohort)
        output_ids = sorted({m['itemID'] for r in cohort for m in r['outputs']})
        context = contexts[context_id]
        source_ids = [r['operationID'] for r in cohort]
        materials = []
        for item in output_ids:
            item_facts = next(m for r in cohort for m in r['outputs'] if m['itemID'] == item)
            quantities = [next((m['quantity'] for m in r['outputs'] if m['itemID'] == item), 0) for r in cohort]
            positive = [q for q in quantities if q > 0]
            histogram = dict(sorted(collections.Counter(map(str, quantities)).items()))
            def field(value, basis):
                return {'value': value, 'status': 'measured', 'confidence': None,
                        'sampleOperations': n, 'sourceClaimIDs': source_ids, 'basis': basis}
            materials.append({'outputItemID': item,
                              'outputQualityRank': item_facts.get('qualityRank'),
                              'outputRarity': item_facts.get('rarity'),
                              'expectedQuantity': field(sum(quantities) / n, 'UNCONDITIONAL_PER_OPERATION'),
                              'dropChance': field(len(positive) / n, 'OPERATIONS_WITH_OUTPUT_DIVIDED_BY_ALL_COMPLETED'),
                              'yieldMin': field(min(positive), 'OBSERVED_POSITIVE_RANGE_NOT_GUARANTEED'),
                              'yieldMax': field(max(positive), 'OBSERVED_POSITIVE_RANGE_NOT_GUARANTEED'),
                              'quantityHistogramIncludingZero': histogram})
        blockers = ['INDEPENDENT_REVIEW_PENDING', 'NOT_A_VERIFIED_MINIMUM_SKILL_BASELINE']
        for key in ('effectiveSkill', 'specialization', 'skillLineID', 'operationStats'):
            if key not in context:
                blockers.append('UNKNOWN_' + key.upper())
        result.append({'recordType': 'EMPIRICAL_BASELINE', 'status': 'AWAITING_REVIEW',
                       'studyID': study_id, 'referenceContextID': context_id, 'recipeSpellID': recipe,
                       'method': cohort[0]['method'], 'patchBuild': cohort[0]['build'],
                       'referenceContext': context, 'nominalInputs': nominal,
                       'expectedInputsConsumed': [{'itemID': item,
                           'expectedQuantity': sum(vector(r['inputs'], True)[item] for r in cohort) / n}
                           for item in vector(nominal)],
                       'operations': n, 'materials': materials, 'sourceRecordIDs': source_ids,
                       'completeZeroOperations': sum(not r['outputs'] for r in cohort), 'blockers': blockers,
                       'numericTransformValidated': False, 'applyPolicy': 'NO_NUMERIC_TRANSFORM'})
    return {'schemaVersion': 'loot-liquidator.empirical-baselines/1',
            'artifactStatus': 'RESEARCH_ONLY_NOT_SHIPPED', 'registryContract': 'profession-mechanics/0.2',
            'baselines': result, 'excludedCohorts': excluded, 'mechanicRules': [],
            'automaticMechanicsPromotion': False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('pages', nargs='+', type=Path)
    parser.add_argument('--output', type=Path, help='Optional staged JSON file outside the installable addon')
    args = parser.parse_args()
    try:
        pages = [json.loads(p.read_text()) for p in args.pages]
        compiled = compile_baselines(pages)
        if args.output:
            addon = Path(__file__).resolve().parents[1] / 'LootLiquidator'
            require(args.output.suffix == '.json' and not args.output.resolve().is_relative_to(addon),
                    'Staged JSON must stay outside the installable addon')
            args.output.write_text(json.dumps(compiled, indent=2, allow_nan=False) + '\n')
        print(json.dumps({'validatedRecords': sum(len(p['records']) for p in pages),
                          'baselineCohorts': len(compiled['baselines']),
                          'excludedCohorts': len(compiled['excludedCohorts']), 'approvedMechanics': 0}))
    except (ValueError, KeyError, TypeError, OSError) as exc:
        parser.exit(1, f'Invalid craft export: {exc}\n')


if __name__ == '__main__':
    main()
