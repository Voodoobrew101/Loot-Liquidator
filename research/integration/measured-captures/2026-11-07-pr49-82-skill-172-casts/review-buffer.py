"""Reproduce the owner's buffered sensitivity sample; never waive source gaps.

The old ledger retained only the first operation ID per failing recipe, not its
timestamp or a full event list. The ID/time relationship below is an empirical
fit to this capture, NOT a documented client GUID contract. Its reconstructed
bounds select a provisional analysis window, not certified complete coverage.
"""
import collections
import copy
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parents[3] / 'tools'))
from validate_craft_export import validate, compile_baselines

raw = (ROOT / 'export-page-1.json').read_bytes()
source_hash = hashlib.sha256(raw).hexdigest()
assert source_hash == '922e2037cf269633349d836abbc8404fd0bf792502a8142fc52b4e5951c30160'
source = json.loads(raw)
records, contexts, studies = validate([source])
assert len(records) == 172 and len(studies) == 1
study_id, study = next(iter(studies.items()))
assert not study.get('truncated') and not study.get('globalCoverageGap')

# Choose by event identity/time only. Never inspect rank to select exclusions.
anchors = [(r['operationID'], r['startedAt']) for r in records]
anchors += [(x['operationID'], x['context']['observed']) for x in source['diagnostics']]
prefixes = {op.rsplit('-', 1)[0].rsplit('-', 1)[0] for op, _ in anchors}
assert len(prefixes) == 1
def observed_clock_word(op):
    return int(op.rsplit('-', 1)[1], 16) & 0x7fffff
offsets = [at - observed_clock_word(op) for op, at in anchors]
low, high = min(offsets), max(offsets)
assert len(anchors) == 222 and (low, high) == (1786773553, 1786773554)
gap_bounds = {
    key: {'operationID': gap['operationID'], 'inferredStartBounds':
          [observed_clock_word(gap['operationID']) + low,
           observed_clock_word(gap['operationID']) + high]}
    for key, gap in study['coverageGaps'].items()
}
first = min(gap['inferredStartBounds'][0] for gap in gap_bounds.values())
last = max([gap['inferredStartBounds'][1] for gap in gap_bounds.values()] +
           [x['at'] for x in source['diagnostics']])
ordered = sorted(records, key=lambda r: (r['startedAt'], r['endedAt'], r['operationID']))

def select(buffer):
    before = [r for r in ordered if r['endedAt'] < first]
    during = [r for r in ordered if r['startedAt'] <= last and r['endedAt'] >= first]
    after = [r for r in ordered if r['startedAt'] > last]
    excluded = {r['operationID'] for r in before[-buffer:] + during + after[:buffer]}
    kept = [r for r in ordered if r['operationID'] not in excluded]
    counts = collections.Counter()
    for r in kept:
        for output in r['outputs']:
            counts[str(output['itemID'])] += output['quantity']
    return kept, excluded, dict(sorted(counts.items()))

kept, excluded, counts = select(4)
assert len(kept) == 162 and len(excluded) == 10
assert counts == {'243602': 139, '243603': 23}
derived = copy.deepcopy(source)
derived['records'] = kept
derived['retainedRecords'] = len(kept)
derived['researchReview'] = {
    'status': 'PROVISIONAL_BUFFERED_OBSERVATIONS',
    'sourceDecodedSHA256': source_hash,
    'coverageComplete': False,
    'sourceCoverageFlagsPreserved': True,
    'runtimePromotion': False,
}
validate([derived])
strict = compile_baselines([derived])
assert not strict['baselines']
assert derived['studies'] == source['studies']
assert derived['contexts'] == source['contexts']
assert derived['diagnostics'] == source['diagnostics']
source_by_id = {r['operationID']: r for r in records}
assert all(r == source_by_id[r['operationID']] for r in kept)
assert excluded.isdisjoint(r['operationID'] for r in kept)
assert len(excluded) + len(kept) == len(records)

review = {
    'schemaVersion': 'loot-liquidator.buffered-observation-review/1',
    'artifactStatus': 'RESEARCH_ONLY_NOT_SHIPPED',
    'automaticMechanicsPromotion': False,
    'sourceDecodedSHA256': source_hash,
    'studyID': study_id,
    'ownerRequest': 'Remove 3 or 4 casts before and after the errors.',
    'bufferCastsOnEachSide': 4,
    'selectionUsesOutputQuality': False,
    'timingBasis': {
        'status': 'INFERRED_FROM_THIS_CAPTURE_NOT_NATIVE_ERROR_TIMESTAMPS',
        'anchorCount': len(anchors),
        'observedOffsetRange': [low, high],
        'inferredGapBounds': gap_bounds,
        'retainedDiagnosticCount': len(source['diagnostics']),
        'retainedDiagnosticTimeRange': [min(x['at'] for x in source['diagnostics']),
                                        max(x['at'] for x in source['diagnostics'])],
        'combinedExcludedEventWindow': [first, last],
        'limitation': 'Client operation-ID clock relationship is inferred from 222 timestamped observations, not an official API guarantee. The evicted diagnostic and any additional evicted failures cannot be reconstructed with certainty.',
    },
    'sourceRecords': len(records),
    'retainedRecords': len(kept),
    'excludedRecordOrdinalsOneBased': [i for i, r in enumerate(ordered, 1) if r['operationID'] in excluded],
    'excludedOperationIDs': [r['operationID'] for r in ordered if r['operationID'] in excluded],
    'retainedOperationIDs': [r['operationID'] for r in kept],
    'retainedOutputs': counts,
    'sensitivity': [{'bufferCastsOnEachSide': b, 'retainedRecords': len(select(b)[0]),
                     'retainedOutputs': select(b)[2]} for b in (3, 4)],
    'usableFor': ['Descriptive output counts', 'Sensitivity analysis',
                  'Comparison against independent clean measured cohorts'],
    'completeAttemptDenominatorVerified': False,
    'strictBaselineCohorts': len(strict['baselines']),
    'sourceCoverageFlagsPreserved': True,
    'runtimePromotion': False,
    'moreCastsRequiredByThisReview': False,
}
(ROOT / 'buffer-review.json').write_text(json.dumps(review, indent=2, ensure_ascii=True) + '\n', encoding='utf-8')
# Preserve membership once instead of committing another copy of every context
# and diagnostic. A caller can request a standalone derived export if needed.
if len(sys.argv) == 2:
    Path(sys.argv[1]).write_text(json.dumps(derived, ensure_ascii=True) + '\n', encoding='utf-8')
assert hashlib.sha256((ROOT / 'export-page-1.json').read_bytes()).hexdigest() == source_hash
print(json.dumps({k: review[k] for k in ('retainedRecords', 'excludedRecordOrdinalsOneBased',
                                       'retainedOutputs', 'strictBaselineCohorts')}))
