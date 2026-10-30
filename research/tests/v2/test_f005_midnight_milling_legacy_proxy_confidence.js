"use strict";
// F005 independent acceptance regression for the eight known Midnight Milling
// legacy-reference mappings. The source facts are proposals, not a Retail cast
// study. Run: node research/tests/v2/test_f005_midnight_milling_legacy_proxy_confidence.js
//
// Expected to FAIL on compiler 0.8.0 until unsupported legacy display values
// are represented as confidence-zero working policy priors. Do not delete or
// rewrite the original source fields to make this test pass.
const assert=require("node:assert/strict");
const fs=require("node:fs");
const path=require("node:path");
const root=path.resolve(__dirname,"../../..");
const {compile,loadInputs}=require("../../tools/compile_itemdb.js");
const {applyWorkingEstimates}=require("../../tools/working_estimates.js");
const load=p=>JSON.parse(fs.readFileSync(path.join(root,p),"utf8"));
const source=load("research/proposed/itemdb-midnight-milling-candidate.json");
const lead=load("research/evidence/v2/2026-10-30T0030Z-F004-midnight-milling-batch-and-mixed-rank.json");
const compiled=compile(loadInputs(root)).records;
const F=["dropChance","yieldMin","yieldMax","expectedQuantity"];
const pairs=[[236761,245807],[236767,245807],[236776,245804],
 [236777,245804],[236778,245866],[236779,245866],
 [236770,245864],[236771,245864]];
let passed=0,failed=0;const cases=[];
function check(name,fn) {
 try {fn();passed++;cases.push({name,result:"PASS"});}
 catch(e) {failed++;cases.push({name,result:"FAIL",detail:e.message});}
}
check("F004 batch lead is scoped and does not verify mixed-rank casts",()=>{
 assert.equal(lead.findings.midnight.spellID,1269575);
 assert.equal(lead.findings.midnight.nominalInputHerbsPerCast,10);
 assert.equal(lead.findings.dragonflight.spellID,382981);
 assert.equal(lead.findings.dragonflight.nominalInputHerbsPerCast,5);
 assert.equal(lead.findings.mixedRankTestVector.isObserved,false);
 assert.equal(lead.mappingDisposition,"NO_MAPPING_ADMISSION");
});
check("all eight rank-alternative universe leads remain proposals, not admitted",()=>{
 assert.equal(lead.affectedQueue30UniverseKeys.length,8);
 assert.equal(new Set(lead.affectedQueue30UniverseKeys).size,8);
 const alternateByInput=new Map([[236761,245808],[236767,245808],
  [236776,245803],[236777,245803],[236778,245867],
  [236779,245867],[236770,245865],[236771,245865]]);
 for(const [input,output] of alternateByInput) {
  assert.ok(!compiled.some(r=>r.method==="Mill"&&r.expansionID===11&&
   r.inputItemID===input&&r.outputItemID===output),
   "unverified rank alternate admitted "+input+":"+output);
 }
});
for(const [input,output] of pairs) {
 const key=input+":"+output;
 const original=source.processing.find(r=>r.inputItemID===input&&r.outputItemID===output);
 const row=original&&compiled.find(r=>r.recordID===original.recordID);
 check(key+" spell-specific nominal batch, not Dragonflight 5",()=>{
  assert.ok(original&&row,"missing admitted source mapping");
  for(const r of [original,row]) {
   assert.equal(r.method,"Mill");
   assert.equal(r.expansionID,11);
   assert.equal(r.recipeSpellID,1269575);
   assert.equal(r.inputCountPerOperation,10);
  }
  assert.ok(!compiled.some(r=>r.method==="Mill"&&r.recipeSpellID===1269575&&
   r.inputItemID===input&&r.outputItemID===output&&r.inputCountPerOperation===5));
 });
 check(key+" provisional preview and original fallback provenance retained",()=>{
  assert.ok(row,"missing compiled row");
  assert.equal(row.workingEstimate.economicUse,"PREVIEW_ONLY");
  assert.equal(row.workingEstimate.normalizedVerified,false);
  assert.equal(row.workingEstimate.evidenceFieldsPreserved,true);
  assert.ok(F.every(f=>Number.isFinite(row.workingEstimate[f])));
  for(const f of F) {
   assert.equal(row[f].sampleOperations,null,"invented completed-cast denominator");
   assert.ok(row[f].sourceClaimIDs.length>0,"missing original source lineage");
   assert.ok(row[f].blockers.length>0,"missing legacy fallback disclaimer");
   assert.notEqual(row[f].status,"measured");
  }
 });
 check(key+" unsupported legacy display fallback is not copied as evidence",()=>{
  assert.ok(row,"missing compiled row");
  const w=row.workingEstimate;
  for(const f of F) {
   assert.equal(w.fieldConfidence[f],0,
    f+" unsupported legacy display fallback must have zero working confidence");
   assert.notEqual(w.fieldStatus[f],"COPIED_EVIDENCE",
    f+" legacy assumption cannot be classified as copied evidence");
  }
  assert.equal(w.confidence,0);
  assert.ok(w.assumptions.length>0,"working policy prior must be explicit");
 });
}
// Positive control: a genuinely labelled completed-cast measurement must
// remain eligible for copying. No actual WoW casts are represented here.
check("synthetic completed-cast evidence is not indiscriminately quarantined",()=>{
 const r=JSON.parse(JSON.stringify(source.processing[0]));
 r.recordID="synthetic-f005-completed-cast-control";
 r.mappingConfidence=80;r.conditionsConfidence=80;r.recordConfidence=60;
 r.conditions.quantityBasis="ACTUAL_COMPLETED_CASTS";
 for(const f of F) {
  r[f].status="measured";r[f].confidence=60;
  r[f].sourceClaimIDs=["synthetic-completed-cast-study"];
  r[f].sampleOperations=100;r[f].blockers=[];
 }
 applyWorkingEstimates([r]);
 assert.equal(r.workingEstimate.confidence,60);
 assert.ok(F.every(f=>r.workingEstimate.fieldStatus[f]==="COPIED_EVIDENCE"));
 assert.equal(r.workingEstimate.economicUse,"PREVIEW_ONLY");
});
const result={suite:"F005_MIDNIGHT_MILLING_LEGACY_PROXY_CONFIDENCE",
 syntheticOnly:true,actualRetailCasts:0,passed,failed,cases};
console.log(JSON.stringify(result));
if(failed)process.exitCode=1;
