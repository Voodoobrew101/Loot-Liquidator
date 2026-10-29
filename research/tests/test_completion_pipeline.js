"use strict";
const assert=require("node:assert/strict"),fs=require("node:fs"),os=require("node:os"),path=require("node:path");
const {summarize,writeOrCheck}=require("../tools/run_completion_pipeline.js");
const f=(value,confidence=0,status="unknown")=>({value,confidence,status});
const records=[
 {recordID:"missing-e",method:"Prospect",inputItemID:1,outputItemID:2,dropChance:f(.5),yieldMin:f(1),yieldMax:f(2),expectedQuantity:f(null),workingEstimate:{dropChance:.5,yieldMin:1,yieldMax:2,expectedQuantity:.5,normalizedVerified:false}},
 {recordID:"conflict",method:"Mill",inputItemID:3,outputItemID:4,dropChance:f(null,0,"contradictory"),yieldMin:f(1,90,"measured"),yieldMax:f(1,90,"measured"),expectedQuantity:f(1,90,"measured"),workingEstimate:{dropChance:1,yieldMin:1,yieldMax:1,expectedQuantity:1,normalizedVerified:false}}
];
const copy=JSON.stringify(records),{snapshot,priorities}=summarize(records,{compilerVersion:"fixture",sourceSHA:{},independentRetailUniverseAudit:"NOT_COMPLETE"});
assert.equal(snapshot.fieldSlots,8);assert.equal(snapshot.evidenceNumericCells,6);assert.equal(snapshot.evidenceMissingCells,2);
assert.equal(snapshot.workingNumericCoverage,1);assert.equal(snapshot.evidenceGE90Cells,3);assert.equal(snapshot.verifiedBaselineRecords,0);
assert.equal(snapshot.exhaustiveRetailCoverage,null);assert.equal(snapshot.operationalEstimatesAffectLiveValuation,false);
assert.equal(priorities[0].recordID,"missing-e");assert.equal(JSON.stringify(records),copy,"reporting must not alter source evidence");
const dir=fs.mkdtempSync(path.join(os.tmpdir(),"ll-completion-"));
try {writeOrCheck(dir,"generated/status.json","a\n",false);writeOrCheck(dir,"generated/status.json","a\n",true);assert.throws(()=>writeOrCheck(dir,"generated/status.json","b\n",true),/Stale generated/);}finally{fs.rmSync(dir,{recursive:true,force:true});}
console.log("PASS: readiness separates working/evidence/confidence, prioritizes E gaps, detects stale artifacts");
