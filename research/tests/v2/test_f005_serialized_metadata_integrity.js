"use strict";
// F005 independent detached-process regression: source provenance and tooltip-only
// metadata must not be silently changed while a pinned candidate is accepted.
// Synthetic fixture only; this test does not attest any actual WoW drop rate.
// Run: node research/tests/v2/test_f005_serialized_metadata_integrity.js
const assert=require("node:assert/strict");
const path=require("node:path");
const {spawnSync}=require("node:child_process");
const {applyWorkingEstimates,createWorkingAttestation}=require("../../tools/working_estimates.js");
const FIELDS=["dropChance","yieldMin","yieldMax","expectedQuantity"];
const modulePath=require.resolve("../../tools/working_estimates.js");
const CHILD=`
"use strict";
const fs=require("node:fs");
const api=require(${JSON.stringify(modulePath)});
const p=JSON.parse(fs.readFileSync(0,"utf8"));
const errors=api.validateSerializedWorkingEstimates(p.records,p.attestation,p.pin);
process.stdout.write(JSON.stringify(errors));
`;
function record(){
 const r={recordID:"synthetic-detached-metadata-1",method:"Mill",expansionID:11,
  inputItemID:3001,outputItemID:5001,inputQualityRank:1,outputQualityRank:1,
  recipeSpellID:111,inputCountPerOperation:5,reagents:[{itemID:3001,quantity:5}],
  mappingConfidence:99,conditionsConfidence:99,
  conditions:{gameMode:"Retail",patchWindow:"12.0.5",effectiveSkill:50,
   operationVariant:"MILL",operationStats:{resourcefulnessPct:0},
   eligibilityStatus:"REQUIRES_LEARNED_RECIPE",baselineStatus:"UNVERIFIED",
   sourceContext:"CLEAN",quantityBasis:"ACTUAL_COMPLETED_CASTS"},
  sources:["original-study-1"],verifiedDate:"2026-10-29",
  status:"PROVISIONAL_CANDIDATE",
  tooltipOnly:{economicUse:"PROHIBITED",displayOnly:true,
   dropChance:0.2,yieldMin:1,yieldMax:2,sourceClaimID:"tooltip-study-1"}};
 for(const [i,f] of FIELDS.entries())r[f]={
  value:[0.5,1,2,0.75][i],status:"measured",confidence:60,
  sourceClaimIDs:["original-study-1"],blockers:[]};
 return r;
}
const original=record();
applyWorkingEstimates([original]);
const seal=createWorkingAttestation([original]);
const baseline={records:JSON.parse(JSON.stringify([original])),
 attestation:JSON.parse(JSON.stringify(seal.attestation)),pin:seal.sha256};
function detached(p){
 const child=spawnSync(process.execPath,["-e",CHILD],{
  input:JSON.stringify(p),encoding:"utf8",timeout:10000,maxBuffer:1024*1024});
 assert.equal(child.status,0,"detached validator failed: "+child.stderr);
 return JSON.parse(child.stdout);
}
let passed=0,failed=0;const cases=[];
function check(name,fn){
 try{fn();passed++;cases.push({name,result:"PASS"});}
 catch(e){failed++;cases.push({name,result:"FAIL",detail:e.message});}
}
function mutation(name,fn,expectedPrefix){
 check(name,()=>{
  const p=structuredClone(baseline);fn(p);
  const errors=detached(p);
  assert.ok(errors.some(x=>x.startsWith(expectedPrefix)),
   "pinned detached validator accepted mutation; errors="+JSON.stringify(errors));
 });
}
check("clean JSON roundtrip across a separate Node process",()=>{
 assert.deepEqual(detached(structuredClone(baseline)),[]);
});
mutation("source numeric evidence tamper",p=>p.records[0].expectedQuantity.value=0.8,
 "SERIALIZED_SOURCE_IDENTITY_STALE_OR_TAMPERED:");
mutation("source claim ancestry tamper",p=>p.records[0].expectedQuantity.sourceClaimIDs=["forged"],
 "SERIALIZED_SOURCE_IDENTITY_STALE_OR_TAMPERED:");
mutation("source patch context tamper",p=>p.records[0].conditions.patchWindow="12.0.6",
 "SERIALIZED_SOURCE_IDENTITY_STALE_OR_TAMPERED:");
mutation("working expected quantity tamper",p=>p.records[0].workingEstimate.expectedQuantity=0.8,
 "SERIALIZED_WORKING_PREVIEW_STALE_OR_TAMPERED:");
mutation("working scope live tamper",p=>p.records[0].workingEstimate.economicUse="LIVE",
 "SERIALIZED_WORKING_PREVIEW_STALE_OR_TAMPERED:");
mutation("forged attestation entry with old external pin",p=>p.attestation.entries[0].sourceSHA256="0".repeat(64),
 "SERIALIZED_ATTESTATION_UNPINNED_OR_TAMPERED");
mutation("missing independently pinned digest",p=>{delete p.pin;},
 "SERIALIZED_ATTESTATION_UNPINNED_OR_TAMPERED");
// Expected security requirements; failures expose unsealed source metadata.
// Do not relabel these fields as evidence or use tooltip values in economic E.
mutation("tooltip-only economic prohibition tamper",p=>p.records[0].tooltipOnly.economicUse="LIVE",
 "SERIALIZED_SOURCE_IDENTITY_STALE_OR_TAMPERED:");
mutation("tooltip-only display-only prohibition tamper",p=>p.records[0].tooltipOnly.displayOnly=false,
 "SERIALIZED_SOURCE_IDENTITY_STALE_OR_TAMPERED:");
mutation("tooltip-only original claim tamper",p=>p.records[0].tooltipOnly.sourceClaimID="forged",
 "SERIALIZED_SOURCE_IDENTITY_STALE_OR_TAMPERED:");
mutation("source provenance URL/list tamper",p=>p.records[0].sources=["forged"],
 "SERIALIZED_SOURCE_IDENTITY_STALE_OR_TAMPERED:");
mutation("source verified-date tamper",p=>p.records[0].verifiedDate="2099-01-01",
 "SERIALIZED_SOURCE_IDENTITY_STALE_OR_TAMPERED:");
mutation("source record status tamper",p=>p.records[0].status="ACCEPTED",
 "SERIALIZED_SOURCE_IDENTITY_STALE_OR_TAMPERED:");
const result={suite:"F005_SERIALIZED_METADATA_INTEGRITY",syntheticOnly:true,
 detachedProcess:true,actualRetailCasts:0,passed,failed,cases};
console.log(JSON.stringify(result));
if(failed)process.exitCode=1;
module.exports=result;
