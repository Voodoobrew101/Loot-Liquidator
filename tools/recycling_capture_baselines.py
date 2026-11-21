"""Preserve reviewed empirical contexts and a separate declared zero-profile prior."""
import argparse
import json
from pathlib import Path

from capture_observations import lua
from validate_craft_export import REVIEW_ROOT, compile_baselines, reviewed_legacy_capture


def zero_profile_prior(cohorts, review):
    """One source aggregate, never fourteen independent studies or target casts."""
    operation_ids, contexts, histogram = set(), [], {}
    study_ids, builds = set(), set()
    for cohort in cohorts:
        context = cohort['referenceContext']
        assert context['specialization'] == 'none' and context['bonusSkill'] == 0
        assert 21 <= context['effectiveSkill'] <= 35
        assert cohort['recipeSpellID'] == 1229930 and cohort['method'] == 'Recycle'
        assert len(cohort['nominalInputs']) == 1
        assert cohort['nominalInputs'][0]['itemID'] == 245807 and cohort['nominalInputs'][0]['quantity'] == 5
        assert cohort['nominalInputs'][0]['qualityRank'] == 1
        assert len(cohort['materials']) == 1 and cohort['materials'][0]['outputItemID'] == 243581
        ids = cohort['sourceRecordIDs']
        assert len(ids) == cohort['operations'] and len(set(ids)) == len(ids)
        assert not operation_ids.intersection(ids), 'Overlapping capture strata cannot supply additional source operations'
        operation_ids.update(ids)
        contexts.append(cohort['referenceContextID'])
        study_ids.add(cohort['studyID']); builds.add(cohort['patchBuild'])
        for quantity, count in cohort['materials'][0]['quantityHistogramIncludingZero'].items():
            histogram[quantity] = histogram.get(quantity, 0) + count
    assert len(study_ids) == 1 and builds == {'70783'}
    assert len(operation_ids) == sum(histogram.values()) == 200
    units = sum(int(quantity) * count for quantity, count in histogram.items())
    assert units == 421
    def material(item_id, mean):
        return {'id': item_id,
            'expectedQuantity': {'value': mean, 'status': 'modeled', 'confidence': 0,
                'modelConfidenceCap': 0, 'samples': 0, 'sampleSizeKnown': False,
                'workingEstimate': True, 'sourceClaimIDs': ['normalized-recycling-source:70783:' + str(item_id)],
                'derivation': {'formula': '421 source units / 200 source operations' if mean else 'declared unobserved target-rank zero prior',
                    'observedTargetOperations': 0, 'observedSourceOperations': 200}},
            **{field: {'status': 'unknown', 'confidence': 0, 'samples': 0,
                       'sampleSizeKnown': False, 'inferenceBlocked': True}
               for field in ('dropChance', 'minQuantity', 'maxQuantity')}}
    return {'recordID': 'modeled:recycling:70783:zero-profile', 'studyID': next(iter(study_ids)),
        'sourceKey': 'itemdb', 'sourceKind': 'source-normalized-capture-prior',
        'source': 'Reviewed 200-cast Recycling source; declared zero-profile reference',
        'method': 'Recycle', 'profession': 'Engineering', 'recipeID': 1229930,
        'inputItemID': 245807, 'inputQualityRank': 1, 'inputCount': 5, 'expansionID': 11,
        'clientVersion': '12.1.5', 'patchStartBuild': 70961, 'patchBuild': '70783',
        'referenceContextID': 'normalized-source:recycling:70783:zero',
        'referenceApplicability': 'unverified-reference', 'fixedReference': True,
        'samples': 0, 'sampleSizeKnown': False, 'observedOperations': 0,
        'observedSourceOperations': 200, 'sourceUnits': units, 'sourceHistogram': histogram,
        'sourceContextIDs': sorted(contexts), 'sourceRecordIDs': sorted(operation_ids),
        'sourceSHA256': [page['sha256'] for page in review['pages']],
        'sourceReferenceOnly': True, 'currentPatchApplicabilityConfidence': 0,
        'sourceQuantityBasis': 'gross-input', 'baselineProfileAssumed': True, 'baselineProfileConfidence': 0,
        'baselineProfile': {'skill': 0, 'preSpecializationSkill': 0, 'specialization': 'none',
                            'specializationPoints': {}, 'learnedSpecializations': {}, 'stats': {}},
        'normalizationAssumptions': [
            'Observed quantity is modeled invariant across the source skill21-35 strata and the zero profile.',
            'Source operations had no specialization and zero captured native stats; omitted stats are not new observations.',
            'All zero-profile units use the verified lowest Evercore rank; the sibling zero is modeled, never observed.',
            'Transfer from source70783 to current12.1.5 is unverified; no current-build casts, hit chance or range are claimed.'],
        'nativeBinding': {'build': 70961, 'clientVersion': '12.1.5', 'inputQualityRank': 1,
                          'familyID': 579, 'rankItemIDs': [243581, 243582]},
        'materials': [material(243581, units / len(operation_ids)), material(243582, 0)]}


def compile_capture():
    review = json.loads((REVIEW_ROOT / 'coverage-review.json').read_text())
    reviewed_legacy_capture()  # Verify original bytes before deriving any rate.
    pages = [json.loads((REVIEW_ROOT / p['file']).read_text()) for p in review['pages']]
    staged = compile_baselines(pages)
    cohorts = [b for b in staged['baselines'] if b['method'] == 'Recycle']
    assert sum(b['operations'] for b in cohorts) == 200
    rows = []
    for b in cohorts:
        c = b['referenceContext']
        assert c['specialization'] == 'none' and c['bonusSkill'] == 0 and c['applyConcentration'] is False
        conditions = {k: c[k] for k in ('baseSkill', 'bonusSkill', 'effectiveSkill', 'specialization')}
        stats = c['operationStats']
        assert stats and all(s.get(k) == 0 for s in stats for k in ('bonusStatValue', 'ratingPct', 'bonusRatingPct'))
        conditions.update(zeroOperationStats=True, operationStatCount=len(stats))
        conditions['inputQuality'] = c['inputIdentity'][0]['qualityRank']
        materials = []
        for m in b['materials']:
            materials.append({'id': m['outputItemID'],
                'expectedQuantity': {'value': m['expectedQuantity']['value'], 'status': 'measured', 'sampleOperations': b['operations']},
                'dropChance': {'value': m['dropChance']['value'], 'status': 'measured', 'sampleOperations': b['operations']},
                'minQuantity': {'value': m['yieldMin']['value'], 'status': 'observed', 'sampleOperations': b['operations']},
                'maxQuantity': {'value': m['yieldMax']['value'], 'status': 'observed', 'sampleOperations': b['operations']},
                'boundsBasis': 'observed-positive-range-not-guaranteed',
                'quantityCounts': m['quantityHistogramIncludingZero']})
            for key in ('expectedQuantity', 'dropChance', 'minQuantity', 'maxQuantity'):
                materials[-1][key]['confidence'] = 0  # Unscored, not an invented confidence percentage.
        rows.append({'recordID': 'capture:recycling:' + b['referenceContextID'], 'studyID': b['studyID'],
            'sourceKey': 'itemdb', 'sourceKind': 'reviewed-player-empirical-cohort',
            'source': REVIEW_ROOT.relative_to(Path(__file__).resolve().parents[1]).as_posix(),
            'sourceSHA256': [p['sha256'] for p in review['pages']], 'sourceRecordIDs': b['sourceRecordIDs'],
            'method': 'Recycle', 'profession': 'Engineering', 'recipeID': 1229930, 'inputItemID': 245807,
            'inputCount': 5, 'expansionID': 11, 'patchBuild': b['patchBuild'], 'targetBuild': b['patchBuild'],
            'referenceConditions': conditions, 'referenceContextID': b['referenceContextID'],
            'measuredOperationStats': stats,
            'observedOperations': b['operations'], 'samples': b['operations'], 'provisional': True,
            'baselineStatus': 'Measured player cohort at the stated skill and stats; observed ranges are not guarantees',
            'materials': materials})
    original = pages[0]['studies'][review['studyID']]
    coverage = {review['studyID']: {'method': 'Recycle', 'recipeID': 1229930,
        'coverageOperationID': original['coverageOperationID'], 'coverageReason': original['coverageReason'],
        'operations': {op: True for op in review['operationIDs']}}}
    return {'schemaVersion': 1, 'processing': rows, 'modeledBaselines': [zero_profile_prior(cohorts, review)],
            'coverageReviews': coverage}, staged


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    compiled, staged = compile_capture()
    outputs = {Path('database/recycling-capture-baselines.lua'):
        '-- Generated by tools/recycling_capture_baselines.py; measured contexts and a separate declared zero-profile prior.\nreturn ' + lua(compiled) + '\n',
        REVIEW_ROOT / 'restored-baselines.json': json.dumps(staged, indent=2) + '\n'}
    for path, text in outputs.items():
        if args.check: assert path.read_text(encoding='utf-8') == text, str(path) + ' is out of date'
        else: path.write_text(text, encoding='utf-8', newline='\n')
    print('PASS: 200 reviewed Recycling casts compiled into', len(compiled['processing']), 'exact-context cohorts')


if __name__ == '__main__': main()
