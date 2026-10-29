"use strict";
// Independent F005 positive-support and donor-context acceptance regression.
// Run: node research/tests/v2/test_f005_pmf_positive_support.js
const assert = require("node:assert/strict");
const {forward,inverseHistogram,buildProposal} =
  require("../../tools/models_v2/tww_milling_context_sensitivity_v1.js");
const {applyWorkingEstimates} = require("../../tools/working_estimates.js");
const fields=["dropChance","yieldMin","yieldMax","expectedQuantity"];
let passed=0,failed=0;
function check(name,fn){try{fn();passed++;console.log("PASS "+name);}
  catch(e){failed++;console.error("FAIL "+name+": "+e.message);}}
function record(id,{e=null,recipe=111,patch="12.0.5",extra=null}={}){
  const inputItemID=id==="donor"?3001:3002;
  const r={recordID:id,method:"Smelt",expansionID:11,inputItemID,
    outputItemID:5000,inputQualityRank:1,outputQualityRank:1,
    recipeSpellID:recipe,inputCountPerOperation:5,
    reagents:[{itemID:inputItemID,quantity:5}],
    mappingConfidence:60,conditionsConfidence:60,
    conditions:{gameMode:"Retail",patchWindow:patch,effectiveSkill:50,
      operationStats:{resourcefulnessPct:0.25},operationVariant:"SMELT",
      eligibilityStatus:"REQUIRES_LEARNED_RECIPE",baselineStatus:"UNVERIFIED",
      sourceContext:"SAME_CONTROLLED_COHORT"}};
  if(extra!==null)r.reagents.push({itemID:extra,quantity:1});
  for(const f of fields)r[f]={value:f==="expectedQuantity"?e:null,
    status:f==="expectedQuantity"&&e!==null?"measured":"unknown",
    confidence:f==="expectedQuantity"&&e!==null?80:0,
    blockers:[],sourceClaimIDs:[id]};
  return r;
}
function transferred(a={},b={}){
  const donor=record("donor",{e:4,...a}),target=record("target",b);
  applyWorkingEstimates([donor,target]);
  return target.workingEstimate;
}
check("same typed context donor remains preview-only",()=>{
  const w=transferred();
  assert.equal(w.expectedQuantity,4);
  assert.deepEqual(w.sourceRecordIDs,["donor"]);
  assert.equal(w.confidence,0);
  assert.equal(w.economicUse,"PREVIEW_ONLY");
  assert.equal(w.normalizedVerified,false);
});
check("different patch does not donate",()=>{
  assert.deepEqual(transferred({patch:"12.0.5"},{patch:"12.0.0"}).sourceRecordIDs,[]);
});
check("different recipe does not donate",()=>{
  assert.deepEqual(transferred({recipe:111},{recipe:222}).sourceRecordIDs,[]);
});
check("different extra reagent does not donate",()=>{
  assert.deepEqual(transferred({extra:8001},{extra:8002}).sourceRecordIDs,[]);
});
check("unknown recipe does not donate",()=>{
  assert.deepEqual(transferred({recipe:null},{recipe:null}).sourceRecordIDs,[]);
});
check("forward positive support excludes zero-probability lower row",()=>{
  const x=forward({hitProbability:0.6,positiveYieldPMF:[
    {quantity:1,probability:0},{quantity:2,probability:1}]});
  assert.equal(x.yieldMin,2);
  assert.equal(x.yieldMax,2);
  assert.equal(x.expectedQuantity,1.2);
});
check("forward positive support excludes zero-probability upper row",()=>{
  const x=forward({hitProbability:0.6,positiveYieldPMF:[
    {quantity:2,probability:1},{quantity:99,probability:0}]});
  assert.equal(x.yieldMin,2);
  assert.equal(x.yieldMax,2);
});
check("adding zero-mass PMF rows does not alter forward result",()=>{
  const base=forward({hitProbability:0.5,positiveYieldPMF:[
    {quantity:2,probability:1}]});
  const padded=forward({hitProbability:0.5,positiveYieldPMF:[
    {quantity:1,probability:0},{quantity:2,probability:1},
    {quantity:100,probability:0}]});
  for(const f of fields)assert.equal(padded[f],base[f],f);
});
check("inverse ignores zero-count positive outcomes",()=>{
  const x=inverseHistogram({completedCasts:4,histogram:{"0":2,"1":0,"2":2,"99":0}});
  assert.equal(x.dropChance,0.5);
  assert.equal(x.expectedQuantity,1);
  assert.equal(x.yieldMin,2);
  assert.equal(x.yieldMax,2);
});
check("forward zero-hit conditional support is not applicable",()=>{
  const x=forward({hitProbability:0,positiveYieldPMF:[{quantity:2,probability:1}]});
  assert.equal(x.dropChance,0);assert.equal(x.expectedQuantity,0);
  assert.equal(x.yieldMin,null);assert.equal(x.yieldMax,null);
  assert.equal(x.conditionalYieldApplicable,false);
});
check("positive model remains preview-only with no independent holdout",()=>{
  const x=forward({hitProbability:0.5,positiveYieldPMF:[{quantity:2,probability:1}]});
  assert.equal(x.economicUse,"PREVIEW_ONLY");
  assert.equal(x.normalizedVerified,false);assert.equal(x.confidence,0);
  assert.equal(buildProposal().source.independentHoldout,"NONE");
});
check("non-normalized PMF is rejected",()=>{
  assert.throws(()=>forward({hitProbability:0.5,
    positiveYieldPMF:[{quantity:2,probability:0.5}]}),/PMF_NOT_NORMALIZED/);
});
console.log("F005 POSITIVE SUPPORT: "+passed+" passed; "+failed+" failed.");
if(failed)process.exitCode=1;
