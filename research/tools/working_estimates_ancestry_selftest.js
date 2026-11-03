"use strict";
// Completion-engineer-owned preflight; independent F005 review remains separate.
const assert = require("node:assert/strict");
const {applyWorkingEstimates,validateWorkingEstimates} = require("./working_estimates.js");
const fields = ["dropChance","yieldMin","yieldMax","expectedQuantity"];
function record(id,inputItemID,e,recipe=111) {
  const r={recordID:id,method:"Smelt",expansionID:11,inputItemID,
    outputItemID:5000,inputQualityRank:1,outputQualityRank:1,
    recipeSpellID:recipe,inputCountPerOperation:5,
    reagents:[{itemID:inputItemID,quantity:5}],
    mappingConfidence:60,conditionsConfidence:60,
    conditions:{gameMode:"Retail",patchWindow:"12.0.5",effectiveSkill:50,
      operationStats:{resourcefulnessPct:0.25},operationVariant:"SMELT",
      eligibilityStatus:"REQUIRES_LEARNED_RECIPE",baselineStatus:"UNVERIFIED",
      sourceContext:"SAME_CONTROLLED_COHORT"}};
  for(const f of fields)r[f]={value:f==="expectedQuantity"?e:null,
    status:f==="expectedQuantity"&&e!==null?"measured":"unknown",
    confidence:f==="expectedQuantity"&&e!==null?80:0,
    blockers:[],sourceClaimIDs:[id]};
  return r;
}
function setup(){
  const donor=record("donor",3001,4);
  const target=record("target",3002,null);
  const wrong=record("wrong-recipe",3003,9,222);
  const rows=[donor,target,wrong];
  applyWorkingEstimates(rows);
  assert.deepEqual(target.workingEstimate.sourceRecordIDs,["donor"]);
  assert.deepEqual(validateWorkingEstimates(rows),[]);
  return {donor,target,wrong,rows};
}
function rejected(name,mutate,code){
  const x=setup();mutate(x);
  assert(validateWorkingEstimates(x.rows).some(e=>e.startsWith(code)),
    name+" did not reject "+code);
}
setup();
rejected("unrelated donor",x=>x.target.workingEstimate.sourceRecordIDs=["wrong-recipe"],
  "WORKING_DONOR_CONTEXT_OR_EVIDENCE_MISMATCH");
rejected("nonexistent donor",x=>x.target.workingEstimate.sourceRecordIDs=["absent"],
  "WORKING_DONOR_ID_UNRESOLVED");
rejected("duplicate donor",x=>x.target.workingEstimate.sourceRecordIDs=["donor","donor"],
  "WORKING_DONOR_ID_DUPLICATE_OR_INVALID");
rejected("fabricated median",x=>x.target.workingEstimate.expectedQuantity=3,
  "WORKING_DONOR_MEDIAN_MISMATCH");
rejected("gross-input donor",x=>x.donor.expectedQuantity.blockers=["GROSS_INPUT_NOT_ACTUAL_CAST"],
  "WORKING_DONOR_CONTEXT_OR_EVIDENCE_MISMATCH");
rejected("missing ancestry array",x=>delete x.target.workingEstimate.sourceRecordIDs,
  "WORKING_DONOR_ANCESTRY_MISSING");
rejected("duplicate record identity",x=>x.rows.push({...x.donor}),
  "DUPLICATE_WORKING_RECORD_ID");
console.log("PASS: working-estimate donor ancestry (8 scenarios; preview-only)");
