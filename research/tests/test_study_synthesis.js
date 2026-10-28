"use strict";
// Synthetic regression only; no WoW client execution.
const assert=require("node:assert/strict");
const {synthesize}=require("../tools/synthesize_studies");
function o(id,url,n,units,extra={}){
 return {observationID:id,studyID:id,source:{url},game:{gameMode:"RETAIL",expansionID:11,clientBuild:"known-build",hotfixWindow:"verified-epoch"},
 processing:{method:"Prospect",recipeID:123,inputItemID:456,inputQualityRank:1,
 batchInputsPerOperation:5,completedOperations:n,actualOperationCountKnown:true,
 batchCountDenominatorVerified:true},
 characterContext:{childSkillLineID:999,baseSkill:100,effectiveSkill:120,
 specializations:[{id:1,rank:10}],professionGear:"gear-A",stats:{resourcefulness:0},
 concentrationUsed:false},
 outputs:[{outputItemID:789,outputQualityRank:1,totalUnits:units,hitOperations:null}],
 normalization:{status:"SOURCE_ONLY"},...extra};
}
let r=synthesize([o("a","https://example.org/a",10,12),o("b","https://example.org/b",20,18)]);
assert.equal(r.groups,1);assert.equal(r.results[0].eligiblePooledSourceCount,2);
assert.equal(r.results[0].pooledActualOperations,30);
assert.equal(r.results[0].pooledExpectedQuantity,1);
assert.equal(r.results[0].occurrenceProbability,null);
assert.equal(r.results[0].currentRetailApproved,false);
r=synthesize([o("a","https://example.org/a?copy=1",10,12),
 o("copy","https://example.org/a?copy=2",10,12)]);
assert.equal(r.results[0].pooledExpectedQuantity,null,"duplicated source must not count twice");
assert.equal(r.results[0].duplicateSources.length,1);
r=synthesize([o("a","https://example.org/a",10,12,
 {processing:{...o("base","x",10,12).processing,actualOperationCountKnown:false}})]);
assert.equal(r.results[0].pooledExpectedQuantity,null,"do not infer casts from ore");
r=synthesize([o("a","https://example.org/a",10,12,
 {processing:{...o("base","x",10,12).processing,batchCountDenominatorVerified:false}})]);
assert.equal(r.results[0].pooledExpectedQuantity,null,"reported but unverified denominators remain provisional");
assert.deepEqual(r.results[0].unpooledReportedMeanRange,[1.2,1.2]);
r=synthesize([o("a","https://example.org/a",10,12,
 {game:{gameMode:"RETAIL",expansionID:11,clientBuild:null,hotfixWindow:null}}),
 o("b","https://example.org/b",20,18,
 {game:{gameMode:"RETAIL",expansionID:11,clientBuild:null,hotfixWindow:null}})]);
assert.equal(r.groups,2,"unknown patch cannot be pooled across studies");
assert.ok(r.results.every(x=>x.pooledExpectedQuantity===null));
r=synthesize([o("a","https://example.org/a",10,12),
 o("b","https://example.org/b",20,18,
 {processing:{...o("base","x",10,12).processing,inputQualityRank:2}})]);
assert.equal(r.groups,2,"do not mix input ranks");
r=synthesize([o("a","https://example.org/a",10,12,{outputs:[]})]);
assert.equal(r.groups,0,"unmapped reported outputs cannot become a material valuation");
console.log("study synthesis static regressions passed (7 cases); no production changes");
