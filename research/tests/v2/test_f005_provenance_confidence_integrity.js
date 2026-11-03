"use strict";
// F005 independent preview provenance and confidence-integrity regression.
// Synthetic fixtures ONLY; this suite does not establish in-game behavior.
// Run: node research/tests/v2/test_f005_provenance_confidence_integrity.js
const assert=require("node:assert/strict");
const {applyWorkingEstimates,validateWorkingEstimates}=require("../../tools/working_estimates.js");
const FIELDS=["dropChance","yieldMin","yieldMax","expectedQuantity"];
function record(known=false){
  const r={recordID:"synthetic-integrity",method:"Mill",expansionID:11,
    inputItemID:3001,outputItemID:5001,inputQualityRank:1,outputQualityRank:1,
    recipeSpellID:111,inputCountPerOperation:5,
    reagents:[{itemID:3001,quantity:5}],mappingConfidence:70,conditionsConfidence:70,
    conditions:{gameMode:"Retail",patchWindow:"12.0.5",effectiveSkill:50,
      operationVariant:"MILL",operationStats:{resourcefulnessPct:0},
      eligibilityStatus:"REQUIRES_LEARNED_RECIPE",baselineStatus:"UNVERIFIED",
      sourceContext:"CLEAN"}};
  for(let i=0;i<FIELDS.length;i++)r[FIELDS[i]]={
    value:known?[0.5,1,1,0.5][i]:null,status:known?"measured":"unknown",
    confidence:known?60:0,sourceClaimIDs:known?["synthetic-source"]:[],blockers:[]};
  applyWorkingEstimates([r]);return r;
}
const cases=[];let passed=0,failed=0;
function check(name,fn){
  try{fn();passed++;cases.push({name,result:"PASS"});}
  catch(e){failed++;cases.push({name,result:"FAIL",detail:e.message});}
}
function reject(name,known,mutate){
  check(name,()=>{
    const r=record(known);mutate(r);
    const errors=validateWorkingEstimates([r]);
    assert.ok(errors.length>0,"validator accepted provenance/confidence mutation: "+name);
  });
}
check("untouched measured source validates",()=>assert.deepEqual(validateWorkingEstimates([record(true)]),[]));
check("untouched unknown source remains confidence-zero preview",()=>{
  const r=record(false);
  assert.deepEqual(validateWorkingEstimates([r]),[]);
  assert.equal(r.workingEstimate.confidence,0);
  assert.equal(r.workingEstimate.economicUse,"PREVIEW_ONLY");
  assert.equal(r.workingEstimate.normalizedVerified,false);
});
reject("reject copied-evidence confidence inflation",true,r=>{
  r.workingEstimate.confidence=99;
  r.workingEstimate.fieldConfidence.dropChance=99;
});
reject("reject source evidence confidence drift",true,r=>{
  r.dropChance.confidence=5;
});
reject("reject source claim lineage drift",true,r=>{
  r.dropChance.sourceClaimIDs=["replaced-study"];
});
reject("reject erased fallback assumptions plus confidence inflation",false,r=>{
  r.workingEstimate.assumptions=[];
  r.workingEstimate.confidence=99;
});
reject("reject false copied-evidence fieldStatus on imputation",false,r=>{
  r.workingEstimate.fieldStatus.expectedQuantity="COPIED_EVIDENCE";
});
reject("reject untracked working numeric replacement of copied evidence",true,r=>{
  r.workingEstimate.dropChance=0.25;
  r.workingEstimate.expectedQuantity=0.25;
  r.workingEstimate.fieldConfidence.dropChance=0;
  r.workingEstimate.fieldConfidence.expectedQuantity=0;
});
reject("reject false policy-prior label on copied evidence",true,r=>{
  r.workingEstimate.fieldStatus.dropChance="POLICY_PRIOR";
});
reject("reject fabricated verified working status",true,r=>{
  r.workingEstimate.status="VERIFIED_MEASURED";
});
reject("control: stale source patch must be rejected",true,r=>{
  r.conditions.patchWindow="12.0.6";
});
reject("control: economicUse escalation must be rejected",true,r=>{
  r.workingEstimate.economicUse="LIVE";
});
console.log(JSON.stringify({suite:"F005_PROVENANCE_CONFIDENCE_INTEGRITY",
  syntheticOnly:true,passed,failed,cases}));
if(failed)process.exitCode=1;
module.exports={passed,failed,cases};
