"use strict";
// F005 independent adversarial acceptance test for the F003 Dragonflight milling
// decision-sensitivity proposal. All fixtures are SYNTHETIC. No real casts.
// Run: node research/tests/v2/test_f005_df_milling_raw_context_and_universe.js
const assert = require("node:assert/strict");
const model = require("../../tools/models_v2/df_milling_decision_sensitivity_v1.js");
const base = {
  inputItemID: 191469, outputItemIDs: [198412,198413,198414],
  patchBuild: "12.0.0", studyFamilyID: "SYNTHETIC_NOT_REAL_STUDY",
  nominalInputUnits: 5,
  professionContext: {
    skill: 1, specialization: "NONE", gear: "NONE",
    resourcefulness: 0, unlocks: "NONE", recipeSpellID: 382981
  },
  gameMode: "RETAIL",
  actualObservationEpoch: "2026-10-29T20:00:00Z",
  inputQualityRank: 1,
  outputQualityRanks: {"198412":1,"198413":1,"198414":1},
  directReagents: [{itemID:191469,quantity:5}],
  minimumRecipeSkill: 1,
  outputUniverseVerified: true
};
const event = outputs => ({castID:"SYNTHETIC_CAST_1",status:"COMPLETED",refundedInputUnits:0,outputs});
const complete = [event({"198412":1,"198413":0,"198414":0})];
const raw = context => model.summarizeCasts({context,sourceType:"RAW_CURRENT_RETAIL",events:complete});
const partial = {...base,outputItemIDs:[198412],outputQualityRanks:{"198412":1},outputUniverseVerified:false};
let passed=0,failed=0;const cases=[];
function check(name,fn) {
  try {fn();passed++;cases.push({name,result:"PASS"});}
  catch(e){failed++;cases.push({name,result:"FAIL",detail:e.message});}
}
function rejectRaw(name,context) {
  check(name,()=>assert.throws(()=>raw(context),"incomplete RAW context must be rejected, not represented as a current-Retail observation"));
}
check("model v1.0.2 self-test remains 41/41",()=>{assert.equal(model.MODEL_ID,"df-milling-decision-sensitivity-v1.0.2");assert.equal(model.selfTest().passed,41);});
check("synthetic fully typed RAW-shaped control retains PREVIEW_ONLY",()=>{
  const r=raw(base);
  assert.equal(r.completedCasts,1);
  assert.equal(r.economicUse,"PREVIEW_ONLY");
  assert.equal(r.normalizedVerified,false);
  assert.ok(r.outputs.every(x=>x.confidence===0));
  // Independent negative tests: the author self-test alone is insufficient.
  // Keep these within the existing 16-case native CI gate.
  const invalidRecipeIDs=["banana","382981",382981.5,0,-1,null,NaN,Infinity,Number.MAX_SAFE_INTEGER+1];
  for(const recipeSpellID of invalidRecipeIDs){
    assert.throws(()=>raw({...base,professionContext:{...base.professionContext,recipeSpellID}}),
      /RAW_RECIPE_SPELL_ID_POSITIVE_INTEGER_REQUIRED/,
      "RAW recipeSpellID must be a positive safe integer: "+String(recipeSpellID));
  }
  const synthetic=model.summarizeCasts({
    context:{...base,patchBuild:"SYNTHETIC",professionContext:{...base.professionContext,recipeSpellID:"UNKNOWN"}},
    sourceType:"SYNTHETIC",events:complete
  });
  assert.equal(synthetic.completedCasts,1);
  assert.equal(synthetic.economicUse,"PREVIEW_ONLY");
  assert.equal(synthetic.normalizedVerified,false);
  assert.ok(synthetic.outputs.every(x=>x.confidence===0));
});
{const {gameMode,...c}=base;rejectRaw("RAW missing gameMode",c);}
{const {actualObservationEpoch,...c}=base;rejectRaw("RAW missing actual observation epoch",c);}
{const {inputQualityRank,...c}=base;rejectRaw("RAW missing input quality rank",c);}
{const {outputQualityRanks,...c}=base;rejectRaw("RAW missing output quality ranks",c);}
{const {directReagents,...c}=base;rejectRaw("RAW missing direct reagent vector",c);}
{const {minimumRecipeSkill,...c}=base;rejectRaw("RAW missing minimum eligible recipe skill",c);}
rejectRaw("RAW malformed profession skill accepted",{
  ...base,professionContext:{...base.professionContext,skill:"banana"}
});
rejectRaw("RAW malformed resourcefulness accepted",{
  ...base,professionContext:{...base.professionContext,resourcefulness:"banana"}
});
check("RAW incomplete output universe must not look zero-inclusive",()=>{
  assert.throws(()=>model.summarizeCasts({
    context:partial,sourceType:"RAW_CURRENT_RETAIL",
    events:[event({"198412":1})]
  }));
});
const decisionArgs = (context,outputs,prices)=>({
  context,outputs,prices,inputUnitValue:1,auctionCut:0,
  refundsPerCast:[0,0],priceEpoch:"SYNTHETIC_NOT_REAL_PRICE"
});
const output=(id,amount)=>({
  outputItemID:id,unconditionalEInterval:[amount,amount],provenance:"SYNTHETIC"
});
check("decision cannot declare dominance from unverified partial output universe",()=>{
  assert.throws(()=>model.decisionSensitivity(decisionArgs(
    partial,[output(198412,1)],{"198412":1}
  )));
});
check("missing per-cast zero entries rejected",()=>{
  assert.throws(()=>model.summarizeCasts({
    context:base,sourceType:"SYNTHETIC",
    events:[event({"198412":1})]
  }));
});
check("frozen historical TSM rate unit remains ambiguous and preview-only",()=>{
  const r=model.historicalRateScenarios({
    rate:0.1,reportedUnit:"UNKNOWN",nominalInputUnits:5,
    sourceLineage:"SYNTHETIC_FROZEN_TSM_UNIT_TEST"
  });
  assert.equal(r.scenarios.length,2);
  assert.deepEqual(r.scenarios.map(x=>x.conditionalEPerCast),[0.5,0.1]);
  assert.equal(r.currentRetailE,null);
  assert.equal(r.economicUse,"PREVIEW_ONLY");
});
check("omitted co-output is rejected; full-universe sensitivity can flip decision",()=>{
  assert.throws(()=>model.decisionSensitivity(decisionArgs(
    partial,[output(198412,1)],{"198412":1}
  )));
  const low=model.decisionSensitivity(decisionArgs(
    base,[output(198412,1),output(198413,0),output(198414,0)],
    {"198412":1,"198413":10,"198414":1}
  ));
  const high=model.decisionSensitivity(decisionArgs(
    base,[output(198412,1),output(198413,10),output(198414,0)],
    {"198412":1,"198413":10,"198414":1}
  ));
  assert.equal(low.decision,"ALTERNATIVE_DOMINATES_UNDER_ASSUMPTIONS");
  assert.equal(high.decision,"PROCESS_DOMINATES_UNDER_ASSUMPTIONS");
  assert.deepEqual(low.marginInterval,[-4,-4]);
  assert.deepEqual(high.marginInterval,[96,96]);
  assert.equal(low.economicUse,"PREVIEW_ONLY");
  assert.equal(high.normalizedVerified,false);
});
check("explicitly complete output universe still computes unconditional E without P multiplier",()=>{
  const r=model.summarizeCasts({context:base,sourceType:"SYNTHETIC",events:complete});
  assert.equal(r.outputs[0].observedUnconditionalE,1);
  assert.equal(r.outputs[0].observedDropChance,1);
  assert.equal(r.outputs[1].observedUnconditionalE,0);
  assert.equal(r.completedCasts,1);
});
console.log(JSON.stringify({
  suite:"F005_DF_MILLING_RAW_CONTEXT_AND_UNIVERSE",
  subjectModelID:model.MODEL_ID,syntheticOnly:true,actualRetailCasts:0,
  passed,failed,cases
}));
if(failed)process.exitCode=1;
