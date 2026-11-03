"use strict";
// Independent F005 post-repair model/ancestry regression.
// 609 deterministic assertions, including 150 independent PMF perturbations.
// Run: node research/tests/v2/test_f005_postrepair_metamorphic.js
const assert = require("node:assert/strict");
const {forward,inverseHistogram,ratioSensitivity,buildProposal} =
  require("../../tools/models_v2/tww_milling_context_sensitivity_v1.js");
const {applyWorkingEstimates,validateWorkingEstimates} =
  require("../../tools/working_estimates.js");
let checks = 0;
function check(ok,label) { assert.ok(ok,label); checks++; }
function near(a,b) { return Math.abs(a-b) <= 1e-9*Math.max(1,Math.abs(a),Math.abs(b)); }
for (let i=1; i<=150; i++) {
  const p=(i%100+1)/101, lo=1+i%7, hi=lo+1+i%5, weight=(i%19+1)/20;
  const pmf=[{quantity:lo,probability:weight},{quantity:hi,probability:1-weight}];
  const base=forward({hitProbability:p,positiveYieldPMF:pmf});
  const padded=forward({hitProbability:p,positiveYieldPMF:[
    {quantity:900+i,probability:0},...pmf,{quantity:1000+i,probability:0}]});
  check(base.yieldMin===lo && base.yieldMax===hi && base.dropChance===p,
    "positive support "+i);
  check(["dropChance","yieldMin","yieldMax","expectedQuantity"].every(
    f=>Object.is(base[f],padded[f])),"zero-mass padding "+i);
  check(near(base.expectedQuantity,p*(weight*lo+(1-weight)*hi)),
    "zero-inclusive expectation "+i);
  check(base.economicUse==="PREVIEW_ONLY" && base.normalizedVerified===false &&
    base.confidence===0,"economic isolation "+i);
}
const zero=forward({hitProbability:0,positiveYieldPMF:[{quantity:500,probability:1}]});
check(zero.yieldMin===null && zero.yieldMax===null &&
  zero.expectedQuantity===0 && zero.conditionalYieldApplicable===false,
  "zero-hit conditional support is inapplicable");
const hist=inverseHistogram({completedCasts:5,
  histogram:{"0":2,"1":1,"3":2,"99":0}});
check(hist.dropChance===0.6 && hist.yieldMin===1 && hist.yieldMax===3 &&
  near(hist.expectedQuantity,1.4),"zero-inclusive actual-cast histogram");
const proposal=buildProposal();
check(proposal.records.length===12 && proposal.records.every(r=>
  r.confidence===0 && r.economicUse==="PREVIEW_ONLY" &&
  r.normalizedVerified===false &&
  Object.values(r.currentRetailEconomicFields).every(v=>v===null)),
  "all 12 historical/conditional contexts remain preview only");
check(proposal.source.independentHoldout==="NONE",
  "historical source family is not an independent holdout");
check(near(ratioSensitivity({perHerb:1.15,denominatorBasis:"NET",
  refundFraction:0.2}).expectedQuantity,9.2),
  "net-input Resourcefulness sensitivity not treated as gross casts");
function record(id,input,e) {
  const r={recordID:id,method:"Smelt",expansionID:11,inputItemID:input,
    outputItemID:5000,inputQualityRank:1,outputQualityRank:1,
    recipeSpellID:111,inputCountPerOperation:5,
    reagents:[{itemID:input,quantity:5}],
    mappingConfidence:60,conditionsConfidence:60,
    conditions:{gameMode:"Retail",patchWindow:"12.0.5",effectiveSkill:50,
      operationStats:{resourcefulnessPct:0.25},operationVariant:"SMELT",
      eligibilityStatus:"REQUIRES_LEARNED_RECIPE",baselineStatus:"UNVERIFIED",
      sourceContext:"COHORT"}};
  for (const f of ["dropChance","yieldMin","yieldMax","expectedQuantity"]) {
    const v=f==="expectedQuantity"?e:null;
    r[f]={value:v,status:v===null?"unknown":"measured",
      confidence:v===null?0:80,blockers:[],sourceClaimIDs:[id]};
  }
  return r;
}
const donor=record("donor",3001,4),target=record("target",3002,null);
const rows=[donor,target]; applyWorkingEstimates(rows);
check(validateWorkingEstimates(rows).length===0 &&
  target.workingEstimate.sourceRecordIDs[0]==="donor" &&
  target.workingEstimate.confidence===0,
  "compatible donor is traceable and confidence zero");
target.conditions.patchWindow="12.0.0";
check(validateWorkingEstimates(rows).some(x=>
  x.startsWith("WORKING_DONOR_CONTEXT_OR_EVIDENCE_MISMATCH")),
  "changing target patch invalidates stale donor ancestry");
target.conditions.patchWindow="12.0.5";
donor.expectedQuantity.blockers=["GROSS_INPUT_NOT_ACTUAL_CAST"];
check(validateWorkingEstimates(rows).some(x=>
  x.startsWith("WORKING_DONOR_CONTEXT_OR_EVIDENCE_MISMATCH")),
  "changing source denominator status invalidates stale donor ancestry");
donor.expectedQuantity.blockers=[];
target.workingEstimate.sourceRecordIDs=["missing-donor"];
check(validateWorkingEstimates(rows).some(x=>
  x.startsWith("WORKING_DONOR_ID_UNRESOLVED")),
  "missing source ID invalidates donor ancestry");
assert.equal(checks,609);
console.log("PASS F005 postrepair metamorphic: "+checks+" assertions");
