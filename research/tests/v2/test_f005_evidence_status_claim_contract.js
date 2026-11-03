"use strict";
// F005 independent evidence-status/claim-lineage boundary; synthetic fixtures only.
// Run: node research/tests/v2/test_f005_evidence_status_claim_contract.js
const assert=require("node:assert/strict");
const {applyWorkingEstimates,validateWorkingEstimates}=require("../../tools/working_estimates.js");
const FIELDS=["dropChance","yieldMin","yieldMax","expectedQuantity"];
function record(status="measured",claims=["synthetic-cohort"],confidence=60){
 const r={recordID:"synthetic-status-lineage",method:"Mill",expansionID:11,
 inputItemID:3001,outputItemID:5001,inputQualityRank:1,outputQualityRank:1,
 recipeSpellID:111,inputCountPerOperation:5,reagents:[{itemID:3001,quantity:5}],
 mappingConfidence:99,conditionsConfidence:99,
 conditions:{gameMode:"Retail",patchWindow:"12.0.5",effectiveSkill:50,
 operationVariant:"MILL",operationStats:{resourcefulnessPct:0},
 eligibilityStatus:"REQUIRES_LEARNED_RECIPE",baselineStatus:"UNVERIFIED",
 sourceContext:"CLEAN"}};
 const vals={dropChance:0.5,yieldMin:1,yieldMax:1,expectedQuantity:0.5};
 for(const f of FIELDS)r[f]={value:vals[f],status,confidence,
 sourceClaimIDs:claims.slice(),blockers:[]};
 return r;
}
let passed=0,failed=0;const cases=[];
function check(name,fn){try{fn();passed++;cases.push({name,result:"PASS"});}
 catch(e){failed++;cases.push({name,result:"FAIL",detail:e.message});}}
function accepted(r){applyWorkingEstimates([r]);assert.deepEqual(validateWorkingEstimates([r]),[]);return r;}
function rejectOrQuarantine(r,field="expectedQuantity"){
 let rejected=false;try{applyWorkingEstimates([r]);rejected=validateWorkingEstimates([r]).length>0;}
 catch(_e){rejected=true;}
 const w=r.workingEstimate;
 const quarantined=!!w&&w.fieldStatus[field]!=="COPIED_EVIDENCE"&&
 w.fieldConfidence[field]===0&&w.confidence===0;
 assert.ok(rejected||quarantined,"unqualified source field accepted as copied evidence: "+field);
}
check("control: measured with source claim and confidence 60",()=>{
 const r=accepted(record());assert.equal(r.workingEstimate.confidence,60);});
check("control: legitimate proxy with claim remains preview-only",()=>{
 const r=accepted(record("proxy",["historical-proxy"],60));
 assert.equal(r.workingEstimate.economicUse,"PREVIEW_ONLY");
 assert.equal(r.workingEstimate.normalizedVerified,false);});
check("control: contradictory numeric source excluded from copied evidence",()=>{
 const r=accepted(record("contradictory"));
 assert.equal(r.workingEstimate.fieldConfidence.expectedQuantity,0);
 assert.equal(r.workingEstimate.fieldStatus.expectedQuantity,"POLICY_PRIOR");});
check("reject unknown-status numeric source even with a claim",()=>{
 rejectOrQuarantine(record("unknown",["claimed-but-unknown"],99));});
check("reject unknown-status numeric source with confidence zero",()=>{
 rejectOrQuarantine(record("unknown",["claimed-but-unknown"],0));});
check("reject unrecognized-status numeric source",()=>{
 rejectOrQuarantine(record("forged-status",["claim"],99));});
check("reject measured numeric source without claim ancestry",()=>{
 rejectOrQuarantine(record("measured",[],99));});
check("reject modeled numeric source without claim ancestry",()=>{
 rejectOrQuarantine(record("modeled",[],99));});
check("reject community-reported numeric source without claim ancestry",()=>{
 rejectOrQuarantine(record("community-reported",[],99));});
check("control: post-build source status mutation invalidates lease",()=>{
 const r=accepted(record());r.expectedQuantity.status="unknown";
 assert.ok(validateWorkingEstimates([r]).length>0);});
check("control: preview cannot be escalated to LIVE",()=>{
 const r=accepted(record());r.workingEstimate.economicUse="LIVE";
 assert.ok(validateWorkingEstimates([r]).length>0);});
console.log(JSON.stringify({suite:"F005_EVIDENCE_STATUS_CLAIM_CONTRACT",
 syntheticOnly:true,passed,failed,cases}));
if(failed)process.exitCode=1;
module.exports={passed,failed,cases};
