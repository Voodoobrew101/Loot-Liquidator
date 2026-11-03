"use strict";
// Independent F005 follow-up for source-context v1.1.0. Synthetic only.
// Run: node research/tests/v2/test_f005_serialized_nested_provenance_v11.js
const assert = require("node:assert/strict");
const fs = require("node:fs");
const {spawnSync} = require("node:child_process");
const api = require("../../tools/working_estimates.js");
const modulePath = require.resolve("../../tools/working_estimates.js");
const childSource = [
  '"use strict";',
  'const fs=require("node:fs");',
  'const api=require('+JSON.stringify(modulePath)+');',
  'const p=JSON.parse(fs.readFileSync(0,"utf8"));',
  'process.stdout.write(JSON.stringify(api.validateSerializedWorkingEstimates(p.records,p.attestation,p.pin)));'
].join("\n");
const fields = ["dropChance","yieldMin","yieldMax","expectedQuantity"];
function source(id,outputID,missing=false) {
  const r = {
    recordID:id,method:"Mill",expansionID:11,inputItemID:3001,outputItemID:outputID,
    recipeSpellID:111,inputCountPerOperation:5,inputQualityRank:1,outputQualityRank:1,
    reagents:[{itemID:3001,quantity:5}],mappingConfidence:80,conditionsConfidence:80,
    conditions:{gameMode:"Retail",patchWindow:"12.0.5",effectiveSkill:50,
      operationVariant:"MILL",operationStats:{resourcefulnessPct:0},
      eligibilityStatus:"REQUIRES_LEARNED_RECIPE",baselineStatus:"UNVERIFIED",
      sourceContext:"CLEAN",quantityBasis:"ACTUAL_COMPLETED_CASTS"},
    sources:["original-study-1"],verifiedDate:"2026-10-29",status:"PROVISIONAL_CANDIDATE",
    tooltipOnly:{economicUse:"PROHIBITED",displayOnly:true,sourceClaimID:"tooltip-study-1",
      uncertainty:{basis:"NOT_MEASURED",denominator:"UNKNOWN"}}
  };
  const vals=[0.5,1,2,0.75];
  fields.forEach((f,i)=>r[f]={
    value:missing?null:vals[i],status:missing?"unknown":"measured",
    confidence:missing?0:60,sourceClaimIDs:["original-study-1"],blockers:[]});
  return r;
}
const records=[source("synthetic-source-1",5001),source("synthetic-source-2",5002),
  source("synthetic-policy-fallback",5003,true)];
api.applyWorkingEstimates(records);
const fallback=records[2].workingEstimate;
assert.ok(fields.every(f=>Number.isFinite(fallback[f])));
assert.equal(fallback.confidence,0);
assert.equal(fallback.economicUse,"PREVIEW_ONLY");
assert.equal(fallback.normalizedVerified,false);
assert.ok(fields.every(f=>fallback.fieldConfidence[f]===0));
const sealed=api.createWorkingAttestation(records);
const baseline={records:JSON.parse(JSON.stringify(records)),
  attestation:JSON.parse(JSON.stringify(sealed.attestation)),pin:sealed.sha256};
function detached(p) {
  const run=spawnSync(process.execPath,["-e",childSource],{
    input:JSON.stringify(p),encoding:"utf8",timeout:10000,maxBuffer:1024*1024});
  assert.equal(run.status,0,"Detached Node failed: "+run.stderr);
  return JSON.parse(run.stdout);
}
function clone(){return JSON.parse(JSON.stringify(baseline));}
const cases=[];
function check(name,mutation,expectPrefix) {
  const p=clone();mutation(p);
  const errors=detached(p);
  if(expectPrefix===null)assert.deepEqual(errors,[],name+": "+JSON.stringify(errors));
  else assert.ok(errors.some(e=>e.startsWith(expectPrefix)),
    name+": missing "+expectPrefix+" in "+JSON.stringify(errors));
  cases.push(name);
}
const sourceError="SERIALIZED_SOURCE_IDENTITY_STALE_OR_TAMPERED:";
const workingError="SERIALIZED_WORKING_PREVIEW_STALE_OR_TAMPERED:";
check("clean detached JSON roundtrip",()=>{},null);
check("nested tooltip uncertainty tamper",p=>p.records[0].tooltipOnly.uncertainty.basis="MEASURED",sourceError);
check("tooltip-only prohibition tamper",p=>p.records[0].tooltipOnly.economicUse="LIVE",sourceError);
check("source list append",p=>p.records[0].sources.push("forged"),sourceError);
check("source record status tamper",p=>p.records[0].status="ACCEPTED",sourceError);
check("source verified date tamper",p=>p.records[0].verifiedDate="2099-01-01",sourceError);
check("add previously unsealed source property",p=>p.records[0].newClaim="forged",sourceError);
check("delete original source property",p=>delete p.records[0].sources,sourceError);
check("nested source field blocker tamper",p=>p.records[0].expectedQuantity.blockers.push("FORGED"),sourceError);
check("working field provenance tamper",p=>p.records[0].workingEstimate.fieldStatus.expectedQuantity="POLICY_PRIOR",workingError);
check("self-reseal without changing independently pinned digest",p=>{
  p.records[0].sources.push("forged");
  p.attestation=api.createWorkingAttestation(p.records).attestation;
},"SERIALIZED_ATTESTATION_UNPINNED_OR_TAMPERED");
check("record order permutation is intentionally set-equivalent",p=>p.records.reverse(),null);
check("record removal",p=>p.records.pop(),"SERIALIZED_ATTESTATION_CONTRACT_OR_COUNT_MISMATCH");
check("duplicate record identity",p=>p.records[1].recordID=p.records[0].recordID,"DUPLICATE_WORKING_RECORD_ID:");
console.log(JSON.stringify({suite:"F005_SERIALIZED_NESTED_PROVENANCE_V11",
  detachedProcess:true,actualRetailCasts:0,syntheticOnly:true,
  cases:cases.length,passed:cases.length,failed:0,attestationVersion:api.SERIALIZED_ATTESTATION_VERSION}));
