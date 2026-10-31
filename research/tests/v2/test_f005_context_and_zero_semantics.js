"use strict";
// F005 independent acceptance regression. Deliberately fails on unsafe context
// transfers until the owning engineer/model author fixes the subject code.
// Run: node research/tests/v2/test_f005_context_and_zero_semantics.js
const assert = require("node:assert/strict");
const { applyWorkingEstimates } = require("../../tools/working_estimates.js");
const { forward, inverseHistogram, buildProposal } =
  require("../../tools/models_v2/tww_milling_context_sensitivity_v1.js");

const fields = ["dropChance", "yieldMin", "yieldMax", "expectedQuantity"];
function make(id, { recipeSpellID = 111, e = null, skill = 50,
                    reagentTwo = null, outputRank = 1 } = {}) {
  const r = {
    recordID: id, method: "Smelt", expansionID: 11,
    inputItemID: id === "donor" ? 3001 : 3002,
    outputItemID: 5000, inputQualityRank: 1, outputQualityRank: outputRank,
    recipeSpellID, inputCountPerOperation: 5,
    reagents: [{itemID: id === "donor" ? 3001 : 3002, quantity: 5}],
    mappingConfidence: 65, conditionsConfidence: 60,
    conditions: {
      gameMode: "Retail", patchWindow: "CURRENT", effectiveSkill: skill,
      operationVariant: "SMELT", eligibilityStatus: "REQUIRES_LEARNED_RECIPE",
      baselineStatus: "UNVERIFIED"
    }
  };
  if (reagentTwo !== null) r.reagents.push({itemID: reagentTwo, quantity: 1});
  for (const f of fields) {
    const value = f === "expectedQuantity" ? e : null;
    r[f] = {value, status: value === null ? "unknown" : "measured",
            confidence: value === null ? 0 : 80,
            blockers: [], sourceClaimIDs: [id]};
  }
  return r;
}
function estimate(donorOptions = {}, targetOptions = {}) {
  const donor = make("donor", {e: 100, ...donorOptions});
  const target = make("target", {e: null, ...targetOptions});
  applyWorkingEstimates([donor, target]);
  return {donor, target};
}
let failures = 0;
function check(name, test) {
  try { test(); console.log("PASS " + name); }
  catch (error) { failures++; console.error("FAIL " + name + ": " + error.message); }
}

check("same-context transfer remains a confidence-zero preview", () => {
  const {target} = estimate();
  assert.equal(target.workingEstimate.expectedQuantity, 100);
  assert.deepEqual(target.workingEstimate.sourceRecordIDs, ["donor"]);
  assert.equal(target.workingEstimate.confidence, 0);
  assert.equal(target.workingEstimate.economicUse, "PREVIEW_ONLY");
  assert.equal(target.workingEstimate.normalizedVerified, false);
});
check("different recipe spell must not donate an E prior", () => {
  const {target} = estimate({recipeSpellID: 111}, {recipeSpellID: 222});
  assert.ok(!target.workingEstimate.sourceRecordIDs.includes("donor"),
            "incompatible recipe donor leaked into target");
});
check("different effective skill must not donate an E prior", () => {
  const {target} = estimate({skill: 50}, {skill: 100});
  assert.ok(!target.workingEstimate.sourceRecordIDs.includes("donor"),
            "skill-incompatible donor leaked into target");
});
check("different full reagent vector must not donate an E prior", () => {
  const {target} = estimate({reagentTwo: 8001}, {reagentTwo: 8002});
  assert.ok(!target.workingEstimate.sourceRecordIDs.includes("donor"),
            "reagent-incompatible donor leaked into target");
});
check("different output quality rank must not donate an E prior", () => {
  const {target} = estimate({outputRank: 1}, {outputRank: 2});
  assert.ok(!target.workingEstimate.sourceRecordIDs.includes("donor"),
            "rank-incompatible donor leaked into target");
});
check("contradictory evidence must not be used as a donor", () => {
  const donor = make("donor", {e: 100});
  donor.expectedQuantity.status = "contradictory";
  const target = make("target");
  applyWorkingEstimates([donor, target]);
  assert.ok(!target.workingEstimate.sourceRecordIDs.includes("donor"));
  assert.equal(target.workingEstimate.fieldConfidence.expectedQuantity, 0);
});
check("zero-hit forward model uses not-applicable positive bounds", () => {
  const result = forward({hitProbability: 0,
                          positiveYieldPMF: [{quantity: 2, probability: 1}]});
  assert.equal(result.expectedQuantity, 0);
  assert.equal(result.dropChance, 0);
  assert.equal(result.yieldMin, null,
               "P=0 must not claim a positive conditional minimum");
  assert.equal(result.yieldMax, null,
               "P=0 must not claim a positive conditional maximum");
});
check("zero-inclusive histogram inverse retains zero semantics", () => {
  const result = inverseHistogram({completedCasts: 4, histogram: {"0": 4}});
  assert.equal(result.dropChance, 0);
  assert.equal(result.expectedQuantity, 0);
  assert.equal(result.yieldMin, null);
  assert.equal(result.yieldMax, null);
});
check("historical model has no independent family holdout", () => {
  const proposal = buildProposal();
  assert.equal(proposal.source.independentHoldout, "NONE");
  assert.ok(proposal.records.every(r =>
    r.economicUse === "PREVIEW_ONLY" && r.normalizedVerified === false &&
    r.confidence === 0 &&
    fields.every(f => r.currentRetailEconomicFields[f] === null)));
});
if (failures) {
  console.error("F005 ACCEPTANCE FAIL: " + failures +
                " independent boundary checks failed; do not promote.");
  process.exitCode = 1;
} else console.log("F005 ACCEPTANCE PASS: all independent boundary checks passed.");
