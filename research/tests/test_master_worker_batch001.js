"use strict";
// Master first-pass worker acceptance tests; structural only, not WoW client tests.
function masterWorkerQA(queue,coverage,fieldCSV,mechanics,workerData){
 const checks=[],ck=(n,v)=>checks.push({name:n,ok:!!v});
 const rows=coverage.trim().split(/\r?\n/).slice(1),fields=fieldCSV.trim().split(/\r?\n/).slice(1);
 const counts={};for(const line of rows){const z=line.split(",");counts[z[5]]=(counts[z[5]]||0)+1}
 ck("1737 stable coverage records",rows.length===1737);
 ck("194 cumulative first-pass, 1543 never",counts.NEVER_EXAMINED===1543&&1737-counts.NEVER_EXAMINED===194);
 ck("181 insufficient and 13 blocked",counts.EXAMINED_INSUFFICIENT===181&&counts.BLOCKED===13);
 ck("140 accepted independent field rows",fields.length===140);
 ck("140 accepted keys unique",new Set(fields.map(x=>x.split(",")[0])).size===140);
 ck("all worker field minima below 70",fields.every(line=>{const z=line.split(",");return +z[9]<70}));
 ck("four worker submissions exact assigned counts",workerData.midnight.length===35&&workerData.war_within.length===39&&workerData.dragonflight.length===36&&workerData.legacy.length===30);
 ck("all four next batches disjoint",new Set(Object.values(queue.workers).flatMap(w=>w.recordKeys)).size===134);
 ck("next batch counts 34/30/40/30",queue.workers.midnight.recordKeys.length===34&&queue.workers.war_within.recordKeys.length===30&&queue.workers.dragonflight.recordKeys.length===40&&queue.workers.legacy.recordKeys.length===30);
 const coverageKeys=new Map(rows.map(x=>{const a=x.split(",");return [a[0],a[5]]}));
 ck("all next keys never examined",Object.values(queue.workers).flatMap(w=>w.recordKeys).every(k=>coverageKeys.get(k)==="NEVER_EXAMINED"));
 ck("next keys exclude accepted source rows",Object.values(queue.workers).flatMap(w=>w.recordKeys).every(k=>!fields.some(s=>s.startsWith(k+","))));
 ck("worker success times grounded",Object.values(queue.workers).every(w=>w.lastSuccessfulRunUTC?.endsWith("Z")&&w.acceptedFirstPassRecords>0));
 ck("March 31 date corrected in patch registry",mechanics.patchEvents.some(x=>x.id==="midnight_mar_31_prospecting_gem_increase"&&x.effectiveDate==="2026-03-31"));
 ck("March 31 date corrected in verified model",mechanics.patchEventVerifiedModels.some(x=>x.eventID==="midnight-gem-hotfix-2026-03-31"&&x.effectiveDate==="2026-03-31"&&x.numericTransformID===null));
 ck("old April1 claim deprecated not deleted",mechanics.sourceClaims.some(x=>x.claimID==="blizzard-2026-04-01-midnight-gems"&&x.deprecatedDateAlias===true));
 ck("new official source claim present",mechanics.sourceClaims.some(x=>x.claimID==="blizzard-2026-03-31-midnight-gems"&&x.numericalSupport===false));
 ck("no numeric hotfix coefficient fabricated",mechanics.patchEvents.find(x=>x.id==="midnight_mar_31_prospecting_gem_increase")?.numericEffect===null);
 ck("master records evidence quarantine",queue.masterReview.quarantinedRawEvidence.midnightInvalidBasisEntries===17&&queue.masterReview.quarantinedRawEvidence.midnightInferredCastObservations===3);
 ck("all current Retail evidence gate still blocked",queue.current.allFields90GateMet===false);
 return {passed:checks.filter(x=>x.ok).length,failed:checks.filter(x=>!x.ok).map(x=>x.name),checks,clientTested:false};
}
module.exports={masterWorkerQA};
if(require.main===module){const fs=require("fs"),j=p=>JSON.parse(fs.readFileSync(p,"utf8"));const csv=p=>fs.readFileSync(p,"utf8");const workerData={midnight:csv("research/coordination/submissions/loot-liquidator-midnight/2026-10-28-batch-001-source-audit.csv").trim().split(/\r?\n/).slice(1),war_within:csv("research/coordination/submissions/loot-liquidator-war-within/2026-10-28-tww-batch001-audit.csv").trim().split(/\r?\n/).slice(1),dragonflight:csv("research/coordination/submissions/loot-liquidator-dragonflight/2026-10-28-assignment-001-audit.csv").trim().split(/\r?\n/).slice(1),legacy:csv("research/evidence/observations/2026-10-28-legacy-milling-batch01.jsonl").trim().split(/\r?\n/)};const r=masterWorkerQA(j("research/coordination/assignments.json"),csv("research/ledger/first-pass-coverage-2026-10-28.csv"),csv("research/ledger/master-worker-batch001-four-field-scores-2026-10-28.csv"),j("research/mechanics/ProfessionMechanicsRegistry.json"),workerData);console.log(JSON.stringify(r,null,2));if(r.failed.length)process.exitCode=1;}
