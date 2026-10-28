"use strict";
// Run from repository root: node research/tests/test_compile_itemdb.js
const fs=require("node:fs"),assert=require("node:assert/strict"),path=require("node:path");
const root=path.resolve(__dirname,"../.."),read=p=>fs.readFileSync(path.join(root,p),"utf8");
const {compile,validate,csv}=require("../tools/compile_itemdb.js");
const input={
 primaryCSV:read("research/ledger/processing-output-fields.csv"),
 supplementalCSV:read("research/ledger/supplemental-output-fields.csv"),
 midnightCandidateJSON:read("research/proposed/itemdb-midnight-milling-candidate.json"),
 curatedJSON:read("research/proposed/itemdb-curated-additions.json"),
 rankAuditJSONL:read("research/coordination/submissions/loot-liquidator-dragonflight/2026-10-28-1231-dragonflight-batch012-40key-field-audit.jsonl"),
 midnightAuditCSV:read("research/coordination/submissions/loot-liquidator-midnight/2026-10-28-1211-midnight-batch012-35key-field-audit.csv"),
 batch013DragonflightJSONL:read("research/coordination/submissions/loot-liquidator-dragonflight/2026-10-28-1328-dragonflight-batch013-40key-field-audit.jsonl"),
 batch013TWWJSONL:read("research/coordination/submissions/loot-liquidator-war-within/2026-10-28-1321-warwithin-batch013-35key-field-audit.jsonl"),
 batch013LegacyJSONL:read("research/coordination/submissions/loot-liquidator-legacy/2026-10-28-1340-legacy-batch013-40key-field-audit.jsonl"),
 gameDataSource:read("GameData.lua"),statYieldSource:read("StatYieldProfiles.lua"),
 sha:JSON.parse(read("research/proposed/itemdb-compiler-source-shas.json"))
};
const a=compile(input),b=compile(input);
assert.equal(a.lua,b.lua,"deterministic Lua");
assert.deepEqual(a.report,b.report);
assert.deepEqual(validate(a.records),[]);
assert.equal(a.report.sourceMappingCandidates,976);
assert.equal(a.report.curatedAdded,1);
assert.equal(a.report.rankSpecificProxyRecordsQuarantined,31);
assert.equal(a.report.diamondSpecializationGated,7);
assert.equal(a.report.fullyNumericFourFields,791);
assert.equal(a.report.batch013RankQuarantined,50);
assert.equal(a.report.fishInputRankCorrected,12);
assert.equal(a.report.invalidSourceChanceQuarantined,2);
assert.equal(a.report.legacyArithmeticContradictionsReviewed,8);
assert.equal(a.records.filter(r=>r.inputItemID===200061&&r.outputQualityRank!==null&&r.inputQualityRank===null).length,12);
assert.equal(a.records.filter(r=>r.conditions.eligibilityStatus==="REQUIRES_ORE_SPECIFIC_PROFICIENT_PROCESSOR_SPECIALIZATION").length,7);
assert.equal(a.report.fieldSlots,3904);
assert.deepEqual(a.report.missingFieldCounts,{"dropChance":172,"yieldMin":68,"yieldMax":68,"expectedQuantity":88});
assert.equal(a.report.quarantineBreakdown.MULTI_REAGENT_SCHEMA_GAP,8);
const powder=a.records.find(r=>r.method==="Prospect"&&r.inputItemID===36910&&r.outputItemID===46849);
assert.ok(powder);
assert.equal(powder.expectedQuantity.value,143/1000*5);
assert.equal(powder.expectedQuantity.status,"community-reported");
assert.equal(powder.expectedQuantity.confidence,62);
for(const f of ["dropChance","yieldMin","yieldMax"])assert.equal(powder[f].value,null);
assert.equal(powder.conditions.patchWindow,"REPORTED_12.0.5_CAST_DATE_UNSPECIFIED");
assert.equal(powder.recordConfidence,0);
const rankRows=a.records.filter(r=>r.conditions.sourceContext==="DRAGONFLIGHT_RANK_EXCLUSIVE_TSM_FAMILY_PROXY_QUARANTINED");
assert.equal(rankRows.length,31);
for(const r of rankRows){assert.equal(r.dropChance.value,null);assert.equal(r.expectedQuantity.value,null);assert.ok(r.dropChance.blockers.includes("RANK_SPECIFIC_TSM_FAMILY_RATE_NOT_MEASURED"));assert.ok(r.expectedQuantity.sourceClaimIDs.length>=2);}
const gated=a.records.filter(r=>r.conditions.eligibilityStatus==="REQUIRES_ORE_SPECIFIC_PROFICIENT_PROCESSOR_SPECIALIZATION");
assert.equal(gated.length,7);
assert.ok(gated.every(r=>r.outputItemID===242608&&r.conditions.baselineStatus.includes("NOT_MEASURED_ZERO")));
assert.ok(a.lua.includes("sourceClaimIDs=opt(x[6])"));
assert.ok(a.lua.includes("patchWindow=opt(x[24])"));
assert.ok(a.lua.includes("eligibilityStatus=opt(x[25])"));
assert.ok(a.lua.includes("baselineStatus=opt(x[26])"));
assert.equal(a.lua,read("research/proposed/itemdb.lua"),"generated candidate readback");
assert.equal(a.gapCSV,read("research/ledger/itemdb-missing-fields.csv"),"gap ledger readback");
assert.deepEqual(a.report,JSON.parse(read("research/proposed/itemdb-build-report.json")));
assert.deepEqual(csv('"a","b"\n"1","two,three"\n')[0],{a:"1",b:"two,three"});
console.log("PASS research compiler v0.3.0 static regression; no Lua interpreter or WoW client test");
