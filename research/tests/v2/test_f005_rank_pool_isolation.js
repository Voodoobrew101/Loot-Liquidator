"use strict";
// Independent F005 cross-rank pool isolation: intentionally fails on unsafe pooling.
// Run: node research/tests/v2/test_f005_rank_pool_isolation.js
const assert = require("node:assert/strict");
const { applyWorkingEstimates, validateWorkingEstimates } =
  require("../../tools/working_estimates.js");
const FIELDS = ["dropChance", "yieldMin", "yieldMax", "expectedQuantity"];
function record(id, output, overrides = {}) {
  const input = 3001;
  const r = {
    recordID: id, method: "Mill", expansionID: 11,
    inputItemID: input, outputItemID: output,
    inputQualityRank: overrides.inputRank ?? 1,
    outputQualityRank: overrides.outputRank ?? 1,
    recipeSpellID: overrides.recipe ?? 111,
    inputCountPerOperation: 5,
    reagents: [{itemID: input, quantity: 5},
      ...(overrides.extraReagent ? [{itemID: overrides.extraReagent, quantity: 1}] : [])],
    outputFamilyID: overrides.family,
    mappingConfidence: 60, conditionsConfidence: 60,
    conditions: {
      gameMode: overrides.gameMode ?? "Retail",
      patchWindow: overrides.patch ?? "12.0.5",
      effectiveSkill: 50,
      operationVariant: "MILL",
      operationStats: {resourcefulnessPct: overrides.resourcefulness ?? 0},
      eligibilityStatus: "REQUIRES_LEARNED_RECIPE",
      baselineStatus: "UNVERIFIED",
      sourceContext: "RANK_UNRESOLVED"
    }
  };
  for (const f of FIELDS) r[f] = {
    value: null, status: "unknown", confidence: 0,
    blockers: ["RANK_ALLOCATION_UNRESOLVED"], sourceClaimIDs: []
  };
  return r;
}
let passed = 0, failed = 0, cases = [];
function check(name, fn) {
  try { fn(); passed++; cases.push({name, result: "PASS"}); }
  catch (e) { failed++; cases.push({name, result: "FAIL", detail: e.message}); }
}
function pool(a,b) {
  const rows = [a,b], report = applyWorkingEstimates(rows);
  assert.deepEqual(validateWorkingEstimates(rows), []);
  return {rows,report};
}
function separate(a,b) {
  const x = pool(a,b);
  assert.equal(x.report.unresolvedRankPools, 2,
    "distinct operation contexts must not share a rank allocation pool");
  assert.notEqual(a.workingEstimate.allocation.poolID, b.workingEstimate.allocation.poolID);
  assert.equal(a.workingEstimate.allocation.allocationShare, 1);
  assert.equal(b.workingEstimate.allocation.allocationShare, 1);
}
check("same-family ranks share one preview pool", () => {
  const a=record("a",5001,{family:"pigment",outputRank:1});
  const b=record("b",5002,{family:"pigment",outputRank:2});
  const x=pool(a,b);
  assert.equal(x.report.unresolvedRankPools,1);
  assert.equal(a.workingEstimate.expectedQuantity+b.workingEstimate.expectedQuantity,1);
});
check("distinct canonical output families split pools", () =>
  separate(record("a",5001,{family:"pigment"}),record("b",5002,{family:"gem"})));
check("different recipe spells split pools", () =>
  separate(record("a",5001,{family:"pigment"}),record("b",5002,{family:"pigment",recipe:222})));
check("different patch epochs split pools", () =>
  separate(record("a",5001,{family:"pigment"}),record("b",5002,{family:"pigment",patch:"12.0.6"})));
check("different input ranks split pools", () =>
  separate(record("a",5001,{family:"pigment"}),record("b",5002,{family:"pigment",inputRank:2})));
check("different optional profession stats split pools", () =>
  separate(record("a",5001,{family:"pigment"}),record("b",5002,{family:"pigment",resourcefulness:20})));
check("different game modes MUST split pools", () =>
  separate(record("a",5001,{family:"pigment"}),record("b",5002,{family:"pigment",gameMode:"Classic"})));
check("different direct reagent vectors MUST split pools", () =>
  separate(record("a",5001,{family:"pigment"}),record("b",5002,{family:"pigment",extraReagent:9001})));
check("stale game mode change MUST invalidate pool ancestry", () => {
  const a=record("a",5001,{family:"pigment"}),b=record("b",5002,{family:"pigment"});
  pool(a,b); b.conditions.gameMode="Classic";
  assert.ok(validateWorkingEstimates([a,b]).length>0,
    "pool validator accepted stale game-mode membership");
});
check("stale reagent change MUST invalidate pool ancestry", () => {
  const a=record("a",5001,{family:"pigment"}),b=record("b",5002,{family:"pigment"});
  pool(a,b); b.reagents.push({itemID:9001,quantity:1});
  assert.ok(validateWorkingEstimates([a,b]).length>0,
    "pool validator accepted stale reagent-vector membership");
});
check("tampered pool member IDs MUST be rejected", () => {
  const a=record("a",5001,{family:"pigment"}),b=record("b",5002,{family:"pigment"});
  pool(a,b); b.workingEstimate.allocation.memberRecordIDs=["a","not-a-record"];
  assert.ok(validateWorkingEstimates([a,b]).length>0,
    "pool validator accepted forged membership provenance");
});
check("all provisional rank allocations remain economically isolated", () => {
  const a=record("a",5001,{family:"pigment"}),b=record("b",5002,{family:"pigment"});
  pool(a,b);
  for(const r of [a,b]) {
    const w=r.workingEstimate;
    assert.equal(w.confidence,0);
    assert.equal(w.economicUse,"PREVIEW_ONLY");
    assert.equal(w.normalizedVerified,false);
    assert.equal(w.allocation.physicalUpperBound,false);
  }
});
console.log(JSON.stringify({suite:"F005_RANK_POOL_ISOLATION",passed,failed,cases}));
if (failed) process.exitCode=1;
module.exports={passed,failed,cases};
