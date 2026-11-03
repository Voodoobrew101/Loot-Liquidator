"use strict";
// F005 independent test: source denominator and rank blockers must not become copied E/P.
// Synthetic fixtures only. Run: node research/tests/v2/test_f005_blocked_evidence_cast_basis.js
const assert=require("node:assert/strict");
const {applyWorkingEstimates,validateWorkingEstimates}=require("../../tools/working_estimates.js");
const FIELDS=["dropChance","yieldMin","yieldMax","expectedQuantity"];
function record(id="synthetic-cast-basis",inputID=3001){
  const r={recordID:id,method:"Mill",expansionID:11,
    inputItemID:inputID,outputItemID:5001,inputQualityRank:1,outputQualityRank:1,
    recipeSpellID:111,inputCountPerOperation:5,
    reagents:[{itemID:inputID,quantity:5}],mappingConfidence:99,conditionsConfidence:99,
    conditions:{gameMode:"Retail",patchWindow:"12.0.5",effectiveSkill:50,
      operationVariant:"MILL",operationStats:{resourcefulnessPct:0},
      eligibilityStatus:"REQUIRES_LEARNED_RECIPE",baselineStatus:"UNVERIFIED",
      sourceContext:"CLEAN",quantityBasis:"ACTUAL_COMPLETED_CASTS"}};
  for(const [i,f] of FIELDS.entries())r[f]={
    value:[0.5,1,1,0.5][i],status:"measured",confidence:99,
    sourceClaimIDs:["synthetic-original-study"],blockers:[]};
  return r;
}
let passed=0,failed=0;const cases=[];
function check(name,fn){
  try{fn();passed++;cases.push({name,result:"PASS"});}
  catch(e){failed++;cases.push({name,result:"FAIL",detail:e.message});}
}
function mustQuarantine(name,mutate,field="expectedQuantity"){
  check(name,()=>{
    const r=record();mutate(r);
    let rejected=false;
    try{applyWorkingEstimates([r]);rejected=validateWorkingEstimates([r]).length>0;}
    catch(_e){rejected=true;}
    const w=r.workingEstimate;
    const quarantined=!!w&&w.fieldStatus[field]!=="COPIED_EVIDENCE"&&
      w.fieldConfidence[field]===0&&w.confidence===0;
    assert.ok(rejected||quarantined,
      "cast-inapplicable source copied as confidence-bearing evidence: "+field);
    if(w){assert.equal(w.economicUse,"PREVIEW_ONLY");assert.equal(w.normalizedVerified,false);}
  });
}
check("control: actual completed-cast source remains copied preview",()=>{
  const r=record();applyWorkingEstimates([r]);
  assert.deepEqual(validateWorkingEstimates([r]),[]);
  assert.equal(r.workingEstimate.fieldStatus.expectedQuantity,"COPIED_EVIDENCE");
  assert.equal(r.workingEstimate.fieldConfidence.expectedQuantity,99);
  assert.equal(r.workingEstimate.economicUse,"PREVIEW_ONLY");
});
mustQuarantine("gross-input E blocker",r=>r.expectedQuantity.blockers=["GROSS_INPUT"]);
mustQuarantine("not-actual-cast E blocker",r=>r.expectedQuantity.blockers=["NOT_ACTUAL_CAST"]);
mustQuarantine("rank-specific E blocker",r=>r.expectedQuantity.blockers=["RANK_SPECIFIC_TSM_FAMILY_RATE_NOT_MEASURED"]);
mustQuarantine("rank-or-gross-input E blocker",r=>r.expectedQuantity.blockers=["BATCH014_RANK_OR_GROSS_INPUT_EQUIVALENT_NOT_EXACT_CAST_E"]);
mustQuarantine("gross-input occurrence denominator blocker",r=>r.dropChance.blockers=["GROSS_INPUT"],"dropChance");
mustQuarantine("quantity basis explicitly not actual casts",r=>r.conditions.quantityBasis="GROSS_INPUT_NOT_ACTUAL_CAST");
mustQuarantine("gross-input-equivalent quantity basis",r=>r.conditions.quantityBasis="GROSS_INPUT_EQUIVALENT");
mustQuarantine("proxy E with blocked rank ancestry",r=>{
  r.expectedQuantity.status="proxy";r.expectedQuantity.confidence=70;
  r.expectedQuantity.blockers=["RANK_SPECIFIC_TSM_FAMILY_RATE_NOT_MEASURED"];
});
check("control: null blocked E remains provisional and confidence-zero",()=>{
  const r=record();r.expectedQuantity.value=null;r.expectedQuantity.status="unknown";
  r.expectedQuantity.confidence=0;r.expectedQuantity.blockers=["GROSS_INPUT"];
  applyWorkingEstimates([r]);assert.deepEqual(validateWorkingEstimates([r]),[]);
  assert.equal(r.workingEstimate.fieldConfidence.expectedQuantity,0);
  assert.equal(r.workingEstimate.confidence,0);
});
check("control: blocked donor E is not transferred to another input",()=>{
  const donor=record("donor",3001),target=record("target",3002);
  donor.expectedQuantity.blockers=["GROSS_INPUT"];
  for(const f of ["dropChance","expectedQuantity"]){
    target[f].value=null;target[f].status="unknown";target[f].confidence=0;
  }
  applyWorkingEstimates([donor,target]);
  assert.deepEqual(target.workingEstimate.sourceRecordIDs,[]);
  assert.equal(target.workingEstimate.fieldConfidence.expectedQuantity,0);
});
check("control: source blocker drift invalidates built preview",()=>{
  const r=record();applyWorkingEstimates([r]);
  r.expectedQuantity.blockers=["GROSS_INPUT"];
  assert.ok(validateWorkingEstimates([r]).length>0);
});
console.log(JSON.stringify({suite:"F005_BLOCKED_EVIDENCE_CAST_BASIS",syntheticOnly:true,passed,failed,cases}));
if(failed)process.exitCode=1;
module.exports={passed,failed,cases};
