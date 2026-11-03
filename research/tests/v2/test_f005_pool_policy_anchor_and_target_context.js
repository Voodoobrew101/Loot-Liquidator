"use strict";
// F005 independent adversarial follow-up. Synthetic records are not WoW evidence.
// Run: node research/tests/v2/test_f005_pool_policy_anchor_and_target_context.js
const assert=require("node:assert/strict");
const {applyWorkingEstimates,validateWorkingEstimates}=require("../../tools/working_estimates.js");
const FIELDS=["dropChance","yieldMin","yieldMax","expectedQuantity"];
function record(id,output,opts={}) {
  const r={recordID:id,method:"Mill",expansionID:11,inputItemID:3001,outputItemID:output,
    inputQualityRank:1,outputQualityRank:opts.rank??1,recipeSpellID:111,
    inputCountPerOperation:5,reagents:opts.reagents??[{itemID:3001,quantity:5}],
    outputFamilyID:"pigment",mappingConfidence:60,conditionsConfidence:60,
    conditions:{gameMode:opts.mode??"Retail",patchWindow:"12.0.5",effectiveSkill:50,
      operationVariant:"MILL",operationStats:{resourcefulnessPct:0},
      eligibilityStatus:"REQUIRES_LEARNED_RECIPE",baselineStatus:"UNVERIFIED",
      sourceContext:opts.clean?"CLEAN":"RANK_UNRESOLVED"}};
  for(const f of FIELDS)r[f]={value:null,status:"unknown",confidence:0,
    blockers:opts.clean?[]:["RANK_ALLOCATION_UNRESOLVED"],sourceClaimIDs:[]};
  return r;
}
function pair(options={}) {
  const rows=[record("a",5001,options),record("b",5002,{...options,rank:2})];
  applyWorkingEstimates(rows);return rows;
}
const cases=[];let passed=0,failed=0;
function check(name,fn){try{fn();passed++;cases.push({name,result:"PASS"});}
  catch(e){failed++;cases.push({name,result:"FAIL",detail:e.message});}}
check("unchanged pool validates",()=>assert.deepEqual(validateWorkingEstimates(pair()),[]));
check("game-mode separation",()=>{
  const rows=[record("a",5001),record("b",5002,{mode:"Classic",rank:2})];
  applyWorkingEstimates(rows);
  assert.notEqual(rows[0].workingEstimate.allocation.poolID,
    rows[1].workingEstimate.allocation.poolID);
});
check("canonical reagent ordering does not split identical pools",()=>{
  const reagents=[{itemID:3001,quantity:5},{itemID:9001,quantity:1}];
  const rows=[record("a",5001,{reagents}),record("b",5002,{rank:2,reagents:[...reagents].reverse()})];
  applyWorkingEstimates(rows);
  assert.equal(rows[0].workingEstimate.allocation.poolID,
    rows[1].workingEstimate.allocation.poolID);
});
check("member ancestry tamper rejected",()=>{
  const rows=pair();rows[0].workingEstimate.allocation.memberRecordIDs=["a","forged"];
  assert.ok(validateWorkingEstimates(rows).some(x=>x.includes("MEMBER_ANCESTRY")));
});
check("legitimate nondefault pool policy validates with explicit options",()=>{
  const rows=[record("a",5001),record("b",5002,{rank:2})];
  const options={unresolvedRankPoolExpectedQuantity:2};
  applyWorkingEstimates(rows,options);
  assert.deepEqual(validateWorkingEstimates(rows,options),[]);
});
check("policy anchor MUST reject self-consistent forged pool E",()=>{
  const rows=pair();
  for(const r of rows){
    r.workingEstimate.allocation.poolExpectedQuantity=2;
    r.workingEstimate.expectedQuantity=1;
    r.workingEstimate.dropChance=1;
  }
  assert.ok(validateWorkingEstimates(rows).length>0,
    "pool target and all member E/P doubled from configured default 1 to 2 without detection");
});
check("stale nonpool targetContext patch MUST be rejected",()=>{
  const r=record("solo",5001,{clean:true});
  applyWorkingEstimates([r]);
  assert.equal(r.workingEstimate.targetContext.patchWindow,"12.0.5");
  r.conditions.patchWindow="12.0.6";
  assert.ok(validateWorkingEstimates([r]).length>0,
    "source patch changed but working targetContext still claims 12.0.5");
});
check("all synthetic estimates remain economically isolated",()=>{
  for(const r of pair()){
    assert.equal(r.workingEstimate.confidence,0);
    assert.equal(r.workingEstimate.economicUse,"PREVIEW_ONLY");
    assert.equal(r.workingEstimate.normalizedVerified,false);
  }
});
console.log(JSON.stringify({suite:"F005_POOL_POLICY_ANCHOR_TARGET_CONTEXT",passed,failed,cases}));
if(failed)process.exitCode=1;
module.exports={passed,failed,cases};
