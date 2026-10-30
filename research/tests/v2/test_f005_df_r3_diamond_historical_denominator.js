'use strict';
// F005 independent regression: historical R3 ore totals are NOT per-cast current-Retail E/P.
// Run: node --test research/tests/v2/test_f005_df_r3_diamond_historical_denominator.js
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { test } = require('node:test');
const root = path.resolve(__dirname, '../../..');
const read = p => JSON.parse(fs.readFileSync(path.join(root, p), 'utf8'));
const evidencePath = 'research/evidence/v2/2026-10-30T0928Z-F004-df-r3-ore-591-diamond-cohort.json';
const reviewPath = 'research/evidence/v2/source-reviews/2026-10-30T0928Z-F004-df-r3-ore-591-diamond-cohort-source-review.json';
const submissionPath = 'research/coordination/v2/submissions/evidence-researcher/2026-10-30T0928Z-F004-df-r3-ore-591-diamond-cohort-submission.json';
const source = read(evidencePath), review = read(reviewPath), submission = read(submissionPath);
const clone = x => JSON.parse(JSON.stringify(x));
function problems(e, r, u) {
  const out = [], fail = (key, condition) => { if (!condition) out.push(key); };
  const [sv, dr] = e.cohorts || [];
  fail('historical-epoch', e.source?.publicationDate === '2023-01-22' && e.source?.gameMode === 'HISTORICAL_DRAGONFLIGHT_RETAIL');
  fail('family-count', e.cohorts?.length === 2 && e.source?.sourceFamilyID === 'reddit-10i63zb-original-poster-r3-ore-prospecting');
  fail('serevite-identity', sv?.inputItemID === 190396 && sv?.inputQualityRank === 3);
  fail('serevite-raw-counts', sv?.reportedOreUnits === 400000 && sv?.reportedIllimitedDiamondCount === 591);
  fail('serevite-rate', Number(sv?.reportedRatePer1000Ore) === 1000 * sv?.reportedIllimitedDiamondCount / sv?.reportedOreUnits);
  fail('serevite-cast-unknown', sv?.completedCasts === null && sv?.zeroOutputCasts === null && sv?.refundedOreUnits === null && sv?.netConsumedOreUnits === null);
  fail('serevite-rank-unknown', sv?.reportedDiamondOutputRank === null && sv?.reportedDiamondOutputItemID === null);
  fail('serevite-economics-null', sv?.dropChancePerCast === null && sv?.unconditionalExpectedQuantityPerCast === null);
  fail('serevite-preview', sv?.confidence === 0 && sv?.economicUse === 'PREVIEW_ONLY' && sv?.normalizedVerified === false);
  fail('draconium-identity', dr?.inputItemID === 190311 && dr?.inputQualityRank === 3);
  fail('draconium-approximate', dr?.reportedOreUnitsApprox === 30000 && dr?.reportedDiamondRatePer1000OreApprox === 3.6 && dr?.reportedDiamondOutputCount === null);
  fail('draconium-cast-unknown', dr?.completedCasts === null && dr?.zeroOutputCasts === null && dr?.refundedOreUnits === null);
  fail('draconium-rank-unknown', dr?.reportedDiamondOutputRank === null && dr?.reportedDiamondOutputItemID === null);
  fail('draconium-economics-null', dr?.dropChancePerCast === null && dr?.unconditionalExpectedQuantityPerCast === null);
  fail('draconium-preview', dr?.confidence === 0 && dr?.economicUse === 'PREVIEW_ONLY' && dr?.normalizedVerified === false);
  fail('no-rank-matched-priority', e.exactOutputRankMatchedKeys?.length === 0 && e.directInputOverlap?.length === 1);
  fail('same-author-not-independent', r.events?.[0]?.independence === 'ONE_AUTHOR_TWO_COHORTS_NOT_TWO_INDEPENDENT_STUDIES');
  fail('no-independent-holdout', r.safeguards?.independentlyValidatedStudyFamilies === 0);
  fail('crosscheck-20k', e.otherPrimaryContext?.reportedDiamonds === 29 && e.otherPrimaryContext?.reportedR3SereviteOre === 20000 && 1000 * 29 / 20000 === 1.45);
  fail('counterfactual-not-measurement', e.sourceInterpretation?.sensitivityOnly?.includes('NOT stored E') && e.sourceInterpretation?.diamondFamilyRankUnresolved === true);
  fail('no-promotion', u.exactDeltas?.confidencePromotions === 0 && u.exactDeltas?.economicPromotions === 0 && u.exactDeltas?.newVerifiedExpectedQuantityCells === 0);
  fail('unchanged-preview', u.exactDeltas?.workingPreviewCoverageBefore === '4072/4072' && u.exactDeltas?.workingPreviewCoverageAfter === '4072/4072');
  return out;
}
test('original historical evidence retains all 22 isolation and arithmetic invariants', () => {
  assert.deepEqual(problems(source, review, submission), []);
});
const mutations = [
  ['fabricated completed casts', e => { e.cohorts[0].completedCasts = 80000; }],
  ['invented zero-output casts', e => { e.cohorts[0].zeroOutputCasts = 79409; }],
  ['assumed zero refunds', e => { e.cohorts[0].refundedOreUnits = 0; }],
  ['wrong reported diamond total', e => { e.cohorts[0].reportedIllimitedDiamondCount = 590; }],
  ['wrong reported denominator', e => { e.cohorts[0].reportedOreUnits = 399999; }],
  ['rank-3 input mislabelled', e => { e.cohorts[0].inputQualityRank = 2; }],
  ['diamond output rank invented', e => { e.cohorts[0].reportedDiamondOutputRank = 3; }],
  ['derived E promoted', e => { e.cohorts[0].unconditionalExpectedQuantityPerCast = 0.0073875; }],
  ['derived P promoted', e => { e.cohorts[0].dropChancePerCast = 0.0073875; }],
  ['positive confidence assigned', e => { e.cohorts[0].confidence = 60; }],
  ['live economic eligibility', e => { e.cohorts[0].economicUse = 'LIVE'; }],
  ['verification flag changed', e => { e.cohorts[0].normalizedVerified = true; }],
  ['approximate Draconium total invented', e => { e.cohorts[1].reportedDiamondOutputCount = 108; }],
  ['Draconium output rank invented', e => { e.cohorts[1].reportedDiamondOutputItemID = 192869; }],
  ['Draconium E invented', e => { e.cohorts[1].unconditionalExpectedQuantityPerCast = 0.018; }],
  ['historical study relabelled current', e => { e.source.gameMode = 'CURRENT_RETAIL'; }],
  ['unverified rank-specific priority claimed', e => { e.exactOutputRankMatchedKeys = ['tsm:prospect:190311:192869:L1280']; }]
];
for (const [name, mutate] of mutations) {
  test('rejects ' + name, () => {
    const changed = clone(source);
    mutate(changed);
    assert.notDeepEqual(problems(changed, review, submission), []);
  });
}
test('rejects treating same-author cohorts as independent holdouts', () => {
  const changed = clone(review);
  changed.events[0].independence = 'TWO_INDEPENDENT_STUDIES';
  assert.ok(problems(source, changed, submission).includes('same-author-not-independent'));
});
test('rejects promotion declared in evidence submission', () => {
  const changed = clone(submission);
  changed.exactDeltas.newVerifiedExpectedQuantityCells = 1;
  assert.ok(problems(source, review, changed).includes('no-promotion'));
});
