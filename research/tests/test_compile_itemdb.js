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
 batch014DragonflightJSONL:read("research/coordination/submissions/loot-liquidator-dragonflight/2026-10-28-1432-dragonflight-q16-batch014-40key-fourfield-audit.jsonl"),
 batch014TWWJSONL:read("research/coordination/submissions/loot-liquidator-war-within/2026-10-28-2116-warwithin-batch014-q16-35key-fourfield-audit.jsonl"),
 gameDataSource:read("GameData.lua"),statYieldSource:read("StatYieldProfiles.lua"),
 sha:JSON.parse(read("research/proposed/itemdb-compiler-source-shas.json"))
};
const a=compile(input),b=compile(input);
assert.equal(a.lua,b.lua,"deterministic Lua");
assert.deepEqual(a.report,b.report);
assert.deepEqual(validate(a.records),[]);
assert.equal(a.report.sourceMappingCandidates,984);
assert.equal(a.report.curatedAdded,1);
assert.equal(a.report.rankSpecificProxyRecordsQuarantined,31);
assert.equal(a.report.diamondSpecializationGated,7);
assert.equal(a.report.fullyNumericFourFields,799);
assert.equal(a.report.batch013RankQuarantined,50);
assert.equal(a.report.fishInputRankCorrected,12);
assert.equal(a.report.invalidSourceChanceQuarantined,0);
assert.equal(a.report.batch014SourceProbabilityQuarantined,2);
assert.equal(a.report.batch014UnsafeExpectedQuantityQuarantined,7);
assert.equal(a.report.fixedSmeltRecipeVectorsCompiled,8);
assert.equal(a.report.verifiedSourceLineIdentities,1202);
assert.equal(a.report.legacyArithmeticContradictionsReviewed,8);
assert.equal(a.records.filter(r=>r.inputItemID===200061&&r.outputQualityRank!==null&&r.inputQualityRank===null).length,12);
assert.equal(a.records.filter(r=>r.conditions.eligibilityStatus==="REQUIRES_ORE_SPECIFIC_PROFICIENT_PROCESSOR_SPECIALIZATION").length,7);
assert.equal(a.report.fieldSlots,3936);
assert.deepEqual(a.report.missingFieldCounts,{"dropChance":172,"yieldMin":68,"yieldMax":68,"expectedQuantity":95});
assert.equal(a.report.quarantineBreakdown.MULTI_REAGENT_SCHEMA_GAP||0,0);
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
assert.ok(a.lua.includes("recipeReagents(x[27])"));
assert.ok(a.lua.includes("minimumRecipeSkill=opt(x[29])"));
assert.ok(a.lua.includes("rareRecipeItemID=opt(x[33])"));
assert.ok(a.lua.includes("reagentCostPolicy=opt(x[34])"));
const smelts=a.records.filter(r=>r.method==="Smelt");assert.equal(smelts.length,8);
for(const r of smelts){assert.ok(r.reagents.length>0);assert.equal(r.reagents[0].itemID,r.inputItemID);assert.equal(r.reagents[0].quantity,r.inputCountPerOperation);assert.equal(r.conditions.reagentCostPolicy,"ALL_REAGENTS_REQUIRED_NOT_SINGLE_INPUT");assert.equal(r.conditions.requiresLearnedRecipe,true);assert.equal(r.conditions.requiresForge,true);assert.ok(r.conditions.minimumRecipeSkill>=1);assert.equal(r.expectedQuantity.status,"modeled");}
const khorium=smelts.find(r=>r.recipeSpellID===46353);assert.equal(khorium.conditions.rareRecipeItemID,35273);assert.deepEqual(khorium.reagents,[{itemID:23449,quantity:3},{itemID:23573,quantity:1}]);
const bronze=smelts.find(r=>r.recipeSpellID===2659);assert.equal(bronze.expectedQuantity.value,2);
const felIron=smelts.find(r=>r.recipeSpellID===29356);assert.deepEqual(felIron.reagents,[{itemID:23424,quantity:2}]);
for(const k of [[192880,192849],[192880,192866],[189143,192869],[190311,192869],[188658,192870],[188658,192871],[189143,192870]]){const r=a.records.find(x=>x.inputItemID===k[0]&&x.outputItemID===k[1]);assert.ok(r);assert.equal(r.expectedQuantity.value,null);assert.ok(r.expectedQuantity.blockers.includes("BATCH014_RANK_OR_GROSS_INPUT_EQUIVALENT_NOT_EXACT_CAST_E"));}
assert.equal(a.lua,read("research/proposed/itemdb.lua"),"generated candidate readback");
assert.equal(a.gapCSV,read("research/ledger/itemdb-missing-fields.csv"),"gap ledger readback");
assert.deepEqual(a.report,JSON.parse(read("research/proposed/itemdb-build-report.json")));
assert.deepEqual(csv('"a","b"\n"1","two,three"\n')[0],{a:"1",b:"two,three"});
console.log("PASS research compiler v0.4.0 static regression; no Lua interpreter or WoW client test");
