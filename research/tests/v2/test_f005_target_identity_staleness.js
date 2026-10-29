"use strict";
// F005 independent adversarial regression: research-preview target identity.
// Synthetic fixtures only; no WoW observations or economic promotion.
// Run: node research/tests/v2/test_f005_target_identity_staleness.js
const assert=require("node:assert/strict");
const {applyWorkingEstimates,validateWorkingEstimates}=require("../../tools/working_estimates.js");
const FIELDS=["dropChance","yieldMin","yieldMax","expectedQuantity"];
function make(){
  const r={recordID:"synthetic-nonpool",method:"Mill",expansionID:11,
    inputItemID:3001,outputItemID:5001,inputQualityRank:1,outputQualityRank:1,
    recipeSpellID:111,inputCountPerOperation:5,
    reagents:[{itemID:3001,quantity:5},{itemID:9001,quantity:1}],
    mappingConfidence:60,conditionsConfidence:60,
    conditions:{gameMode:"Retail",patchWindow:"12.0.5",
      effectiveSkill:50,operationVariant:"MILL",
      operationStats:{resourcefulnessPct:0},
      eligibilityStatus:"REQUIRES_LEARNED_RECIPE",
      baselineStatus:"UNVERIFIED",sourceContext:"CLEAN"}};
  for(const f of FIELDS)r[f]={value:null,status:"unknown",confidence:0,
    blockers:[],sourceClaimIDs:[]};
  applyWorkingEstimates([r]);
  return r;
}
const cases=[];let passed=0,failed=0;
function check(name,fn){
  try{fn();passed++;cases.push({name,result:"PASS"});}
  catch(e){failed++;cases.push({name,result:"FAIL",detail:e.message});}
}
function mustReject(name,mutate){
  check(name,()=>{
    const r=make();mutate(r);
    const errors=validateWorkingEstimates([r]);
    assert.ok(errors.length>0,
      "stale preview accepted after source mutation: "+name);
  });
}
check("unchanged preview remains valid",()=>{
  const r=make();
  assert.deepEqual(validateWorkingEstimates([r]),[]);
  assert.equal(r.workingEstimate.economicUse,"PREVIEW_ONLY");
  assert.equal(r.workingEstimate.normalizedVerified,false);
  assert.equal(r.workingEstimate.confidence,0);
});
mustReject("patch epoch mutation",r=>{r.conditions.patchWindow="12.0.6";});
mustReject("input rank mutation",r=>{r.inputQualityRank=2;});
mustReject("output rank mutation",r=>{r.outputQualityRank=2;});
mustReject("recipe identity mutation",r=>{r.recipeSpellID=222;});
mustReject("direct reagent vector mutation",r=>{r.reagents[1].quantity=2;});
mustReject("method mutation",r=>{r.method="Prospect";});
mustReject("effective skill mutation",r=>{r.conditions.effectiveSkill=100;});
mustReject("profession stat mutation",r=>{r.conditions.operationStats.resourcefulnessPct=20;});
mustReject("output identity mutation",r=>{r.outputItemID=5002;});
mustReject("input identity mutation",r=>{r.inputItemID=3002;r.reagents[0].itemID=3002;});
console.log(JSON.stringify({suite:"F005_TARGET_IDENTITY_STALENESS",
  syntheticOnly:true,passed,failed,cases}));
if(failed)process.exitCode=1;
module.exports={passed,failed,cases};
