"use strict";
// Research-only replay tests; no production data or WoW runtime changes.
const assert=require("node:assert/strict");
const fs=require("node:fs"),path=require("node:path"),os=require("node:os");
const {resolveSampleWindow}=require("../tools/resolve_sample_time");
const {classify}=require("../tools/resolve_mechanics_epoch");
const {reprocess,loadEvidence}=require("../tools/reprocess_observation_archive");
const chronology=JSON.parse(fs.readFileSync(path.resolve(__dirname,"../mechanics/mechanics-chronology.json"),"utf8"));
const src={url:"https://example.invalid/old-study",publishedDate:"2026-04-05",retrievedDate:"2026-10-28"};
const template=(id,more={})=>({
 observationID:id,studyID:id,source:{...src},game:{gameMode:"RETAIL",expansionID:11,clientBuild:null},
 processing:{method:"Prospect",recipeID:123,inputItemID:222,completedOperations:100,actualOperationCountKnown:true,batchInputsPerOperation:5},
 characterContext:{effectiveSkill:50,specializations:[{id:9,rank:10}],professionGear:null,stats:{resourcefulness:0}},
 outputs:[{outputItemID:333,totalUnits:20,hitOperations:15,observedConditionalMin:1,observedConditionalMax:2}],
 ...more
});
const fam={inputs:{"222":"MIDNIGHT_ORE"},outputs:{"333":"GEM"}};
const published=template("published");
const before=template("before",{source:{...src,reportedObservationDate:"2026-03-25"}});
const after=template("after",{observationTiming:{observedStartDate:"2026-04-02",observedEndDate:"2026-04-03"}});
const publishedBefore=template("published-before",{source:{...src,publishedDate:"2026-03-29"}});
const unknown=template("unknown",{source:{url:src.url,retrievedDate:"2026-03-15"}});
assert.equal(resolveSampleWindow(published).kind,"PUBLICATION_UPPER_BOUND");
assert.equal(resolveSampleWindow(before).kind,"OBSERVED_INTERVAL");
assert.equal(resolveSampleWindow(unknown).kind,"TIME_UNKNOWN","retrieval date is never sample date");
assert.equal(resolveSampleWindow(after).startDate,"2026-04-02");
const samples=[published,before,after,publishedBefore,unknown].map(record=>({record,file:"raw.jsonl",line:1}));
const result=reprocess(samples,chronology,{familyMap:fam});
assert.equal(result.observationCount,5);
const indexed=Object.fromEntries(result.records.map(x=>[x.observationID,x]));
const era=id=>indexed[id].outputs[0].epochEvents[0].asOf;
assert.equal(era("published"),"UNKNOWN_PUBLICATION_BOUND","publication after hotfix is not proof sample is post-hotfix");
assert.equal(era("before"),"BEFORE");
assert.equal(era("after"),"AFTER");
assert.equal(era("published-before"),"BEFORE","publication before change proves observation earlier");
assert.equal(era("unknown"),"UNKNOWN_SAMPLE_DATE");
assert.equal(indexed.published.outputs[0].expectedQuantity.value,0.2);
assert.equal(indexed.published.outputs[0].dropChanceObserved,0.15);
assert.equal(indexed.published.originalProfessionContext.effectiveSkill,50);
assert.equal(result.productionPromotions,0);
assert.equal(result.rawObservationsChanged,false);
assert.equal(JSON.stringify(reprocess(samples,chronology,{familyMap:fam})),JSON.stringify(result),"same sources and chronology produce deterministic output");
const alteredChronology=structuredClone(chronology);
alteredChronology.events[0].firstAffectedDate="2026-04-06";
assert.equal(reprocess(samples,alteredChronology,{familyMap:fam}).records[0].outputs[0].epochEvents[0].asOf,"BEFORE",
 "newly supported chronology can reclassify unchanged historical observations");
const missingFamilies=reprocess(samples,chronology);
assert.equal(missingFamilies.records[0].outputs[0].epochEvents[0].asOf,"UNKNOWN_SCOPE",
 "no assumed eligible output/ore category");
const dir=fs.mkdtempSync(path.join(os.tmpdir(),"ll-mechanics-replay-"));
try {
 fs.writeFileSync(path.join(dir,"samples.jsonl"),samples.map(x=>JSON.stringify(x.record)).join("\n")+"\n");
 const loaded=loadEvidence([path.join(dir,"samples.jsonl")]);
 assert.equal(loaded.samples.length,5);
 assert.equal(loaded.inputs[0].sha256.length,64);
 assert.equal(loaded.samples[0].record.observationID,"published");
}finally{fs.rmSync(dir,{recursive:true,force:true});}
console.log("observation temporal replay tests passed; no coefficient or production migration claimed");
