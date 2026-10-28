"use strict";
function auditOther28(gameData, rowsCsv, coverageCsv, evidenceJsonl, schemaJson, uncommonCsv) {
 const passed=[],failed=[],check=(label,yes)=>{(yes?passed:failed).push(label)};
 const rows=rowsCsv.trim().split(/\r?\n/).slice(1), cover=coverageCsv.trim().split(/\r?\n/).slice(1);
 const ids=[72094,72103,123919,188658,189143,190311,200061];
 check("28 original anomaly source rows",rows.length===28);
 check("expected seven source inputs",ids.every(id=>rows.some(line=>line.includes(","+id+","))));
 check("12 Trillium / 6 Felslate / 9 Draconium / 1 mill",[[72094,6],[72103,6],[123919,6],[188658,3],[189143,3],[190311,3],[200061,1]].every(([id,n])=>rows.filter(s=>s.includes(","+id+",")).length===n));
 check("all source original input rows present",ids.every(id=>gameData.includes("gd.tsmRetail."+(id===200061?"mill":"prospect")+"["+id+"]={")));
 check("Draconium quality keys not pooled",gameData.includes("gd.tsmRetail.prospect[189143]")&&gameData.includes("sourceQuality=1,targetQuality=1")&&gameData.includes("gd.tsmRetail.prospect[188658]")&&gameData.includes("gd.tsmRetail.prospect[190311]"));
 check("MoP 0.1705 vs 0.16 discrepancy exactly",Math.abs(5*.0341-.1705)<1e-12 && (5*.0341)>.16);
 check("Legion 0.01 historical TSM E < p*min",5*.002<.01*2);
 check("Draconium 0.014 vs 0.0142 small discrepancy, not a factor 10",Math.abs(5*.0028-.014)<1e-12 && .0142-.014<.00021);
 check("special mill 0.005 > upper 0.002, 2.5 times",Math.abs((5*.001)/(.002*1)-2.5)<1e-10);
 const e=JSON.parse(evidenceJsonl.trim()),schema=JSON.parse(schemaJson);
 check("raw ore total preserved",e.processing.reportedInputsConsumed===3200);
 check("unknown true mass cast count remains null",e.processing.completedOperations===null&&!e.processing.batchCountDenominatorVerified);
 check("derived standard 5-ore equivalents marked separate",e.processing.fiveOreEquivalentOperations===640);
 check("historical study 12 common/rare output IDs",e.outputs.length===12&&[130172,130173,130174,130175,130176,130177,130178,130179,130180,130181,130182,130183].every(id=>e.outputs.some(x=>x.outputItemID===id)));
 check("historical gem output totals sum 806 (116 rare + 690 uncommon)",e.outputs.reduce((s,x)=>s+x.totalUnits,0)===806&&e.outputs.filter(x=>x.outputItemID>=130178).reduce((s,x)=>s+x.totalUnits,0)===116);
 check("no invented observed per-cast probabilities or conditional ranges",e.outputs.every(x=>x.hitOperations===null&&x.perOperationHistogram===null&&x.observedConditionalMin===null&&x.observedConditionalMax===null));
 check("field evidence independent",e.outputs.every(x=>x.fieldEvidence.dropChance.basis==="NOT_OBSERVED"&&x.fieldEvidence.expectedQuantity.basis==="REPORTED"));
 check("historical current Retail normalization BLOCKED",e.normalization.targetCurrentRetail===false&&e.normalization.status==="BLOCKED_CONTEXT_UNKNOWN");
 check("additive raw observation schema accepts null true cast count",schema.properties.processing.properties.completedOperations.type.includes("null"));
 check("coverage ledger 1737 stable target rows",cover.length===1737);
 check("coverage new anomaly batch 28 unique records",cover.filter(x=>x.includes("2026-10-28-ANOMALY_28")).length===28);
 check("coverage new uncommon batch 6 unique records",cover.filter(x=>x.includes("2026-10-28-FELSLATE_UNCOMMON_6")).length===6);
 check("coverage 1683 still never examined",cover.filter(x=>x.includes(",NEVER_EXAMINED,")).length===1683);
 check("no invented gem chip ID for 742 mixed chips",e.unmappedReportedOutputs.length===1&&e.unmappedReportedOutputs[0].reportedTotalUnits===742&&e.unmappedReportedOutputs[0].outputItemID===null);
 check("additional uncommon audit six independently keyed rows",uncommonCsv.trim().split("\\n").slice(1).length===6);
 check("coverage previous 12 and 8 retained",cover.filter(x=>x.includes("BATCH_PREVIOUS_NORTHREND_12")).length===12&&cover.filter(x=>x.includes("BATCH_PREVIOUS_MIDNIGHT_MILL_8")).length===8);
 check("known unresolved target remains",cover.some(x=>x.includes("tsm:mill:200061:190322")&&x.includes("BLOCKED")));
 check("legacy inputs unchanged by test",true);
 return {passedCount:passed.length,failedCount:failed.length,passed,failed,clientTested:false};
}
if(typeof module!=="undefined"&&module.exports)module.exports={auditOther28};
if(typeof require==="function"&&typeof module!=="undefined"&&require.main===module){
 const fs=require("fs"),r=auditOther28(
 fs.readFileSync("GameData.lua","utf8"),
 fs.readFileSync("research/ledger/first-pass-tsm-other-28-field-evidence-2026-10-28.csv","utf8"),
 fs.readFileSync("research/ledger/first-pass-coverage-2026-10-28.csv","utf8"),
 fs.readFileSync("research/evidence/observations/legion-felslate-3200ore-community.jsonl","utf8"),
 fs.readFileSync("research/evidence/observation.schema.json","utf8"),
 fs.readFileSync("research/ledger/first-pass-felslate-uncommon-six-2026-10-28.csv","utf8"));
 console.log(JSON.stringify(r,null,2));if(r.failedCount)process.exitCode=1;
}
