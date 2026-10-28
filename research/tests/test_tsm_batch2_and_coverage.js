"use strict";
function testBatch2(review,coverage,overlay,observations){
 const lines=s=>s.trim().split(/\r?\n/);
 const r=lines(review).slice(1).map(x=>x.split(",")),c=lines(coverage).slice(1),o=lines(overlay).slice(1),obs=lines(observations).map(JSON.parse);
 const assertions=[],check=(name,ok)=>assertions.push({name,ok:!!ok});
 check("28 unique anomaly source tuples",r.length===28&&new Set(r.map(x=>x.slice(0,4).join("|"))).size===28);
 check("12 Pandaria precision-incompatible tuples",r.filter(x=>["72094","72103"].includes(x[1])&&x[11]==="INCOMPATIBLE").length===12);
 check("6 Legion precision-compatible tuples",r.filter(x=>x[1]==="123919"&&x[11]==="POSSIBLE").length===6);
 check("9 Dragonflight precision-compatible tuples",r.filter(x=>["188658","189143","190311"].includes(x[1])&&x[11]==="POSSIBLE").length===9);
 check("one 200061 boundary-only tuple",r.filter(x=>x[1]==="200061"&&x[11]==="BOUNDARY_ONLY").length===1);
 check("all operations normalized from 5 inputs",r.every(x=>x[4]==="0.16"||x[4]==="0.01"||x[4]==="0.0142"||x[4]==="0.002"));
 check("source rows deduped into 1171 keys",c.length===1171);
 check("40 first-pass examined",c.filter(x=>x.includes(",BLOCKED,2026-10-28,")||x.includes(",EXAMINED_INSUFFICIENT,2026-10-28,")).length===40);
 check("1131 never examined",c.filter(x=>x.includes(",NEVER_EXAMINED,,")).length===1131);
 check("25 blocked",c.filter(x=>x.includes(",BLOCKED,2026-10-28,")).length===25);
 check("15 insufficient",c.filter(x=>x.includes(",EXAMINED_INSUFFICIENT,2026-10-28,")).length===15);
 check("92 legacy overlay entries",o.length===92);
 check("62 explicit numeric overlay mappings",o.filter(x=>x.includes(",NUMERIC_MAPPING,")).length===62);
 check("7 source-only observations",obs.length===7);
 check("28 observation outputs, no fabricated totals",obs.reduce((n,x)=>n+x.outputs.length,0)===28&&obs.every(x=>x.processing.completedOperations===null&&x.outputs.every(y=>y.totalUnits===null&&y.perOperationHistogram===null)));
 check("all observation source contexts unverified",obs.every(x=>x.evidenceStatus==="UNVERIFIED_LEAD"&&x.normalization.status==="BLOCKED_CONTEXT_UNKNOWN"));
 return {passed:assertions.filter(x=>x.ok).length,failed:assertions.filter(x=>!x.ok).map(x=>x.name),assertions,inGameTested:false};
}
if(typeof module!=="undefined")module.exports={testBatch2};
if(typeof require==="function"&&typeof module!=="undefined"&&require.main===module){
 const fs=require("fs"),root="research/";
 const r=testBatch2(fs.readFileSync(root+"ledger/tsm-anomalies-batch2-field-review-2026-10-28.csv","utf8"),fs.readFileSync(root+"ledger/first-pass-coverage-v1.csv","utf8"),fs.readFileSync(root+"ledger/overlay-first-pass-inventory-v1.csv","utf8"),fs.readFileSync(root+"evidence/observations/tsm-anomaly-source-audit-2026-10-28.jsonl","utf8"));
 console.log(JSON.stringify(r,null,2));if(r.failed.length)process.exitCode=1;
}
