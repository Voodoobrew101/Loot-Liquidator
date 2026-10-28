"use strict";
// Master QA structural/quantitative invariants; no WoW client access.
function auditMasterQA(q,csv,sch,reg,oldObs,newStudy,candidate,scoreCsv){
 const results=[];const check=(name,ok)=>results.push({name,ok:!!ok});
 const rows=csv.trim().split(/\r?\n/).slice(1).map(s=>{const a=s.split(",");return {key:a[0],scope:a[1],status:a[5]}});
 const map=new Map(rows.map(x=>[x.key,x])),keys=Object.values(q.workers).flatMap(w=>w.recordKeys),previews=Object.values(q.workers).flatMap(w=>w.nextBatchPreview);
 const counts={};for(const r of rows)counts[r.status]=(counts[r.status]||0)+1;
 check("1737 stable source/overlay/profile keys",rows.length===1737&&map.size===1737);
 const expected=q.current?.coverageStatuses||q.baseline.coverageStatuses;
 check("coverage matches master-owned current scorecard",counts.NEVER_EXAMINED===expected.NEVER_EXAMINED&&counts.EXAMINED_INSUFFICIENT===expected.EXAMINED_INSUFFICIENT&&counts.BLOCKED===expected.BLOCKED);
 check("active assigned keys disjoint",keys.length>=25&&new Set(keys).size===keys.length);
 check("all assigned keys exist and never examined",keys.every(k=>map.get(k)?.status==="NEVER_EXAMINED"));
 check("worker batch sizes within target 25–50",Object.values(q.workers).every(w=>w.recordKeys.length>=25&&w.recordKeys.length<=50));
 check("next-preview keys unexamined, unique and not assigned",new Set(previews).size===previews.length&&previews.every(k=>map.get(k)?.status==="NEVER_EXAMINED"&&!keys.includes(k)));
 check("queue remains research-only and master-owned",q.branch==="research/processing-confidence"&&q.masterOwned===true&&q.rules.noMainChanges===true);
 check("worker success metadata matches current or initial queue",Object.values(q.workers).every(w=>q.current?(w.lastSuccessfulRunUTC!==null&&w.acceptedFirstPassRecords>0):(w.lastSuccessfulRunUTC===null&&w.acceptedFirstPassRecords===0)));
 check("historical aggregate enum recognized",sch.properties.evidenceStatus.enum.includes("HISTORICAL_COMMUNITY_REPORTED_AGGREGATE"));
 check("unmapped-only observation permitted with nonempty guard",sch.properties.outputs.minItems===0&&sch.anyOf?.length===2&&sch.properties.unmappedReportedOutputs.minItems===1);
 check("all 9 previous observations use recognized statuses",oldObs.length===9&&oldObs.every(o=>sch.properties.evidenceStatus.enum.includes(o.evidenceStatus)));
 check("all old observations retain mapped outputs",oldObs.every(o=>o.outputs.length>0));
 check("new observation has 113 actual reported mass casts",newStudy.processing.completedOperations===113&&newStudy.processing.batchInputsPerOperation===20&&newStudy.processing.inputItemID===123919);
 check("no fabricated reported ore consumption",newStudy.processing.reportedInputsConsumed===null&&newStudy.processing.derivedInputsConsumedIfNoRefunds===2260);
 check("13 unmapped totals preserved with no invented IDs",newStudy.outputs.length===0&&newStudy.unmappedReportedOutputs.length===13&&newStudy.unmappedReportedOutputs.every((o,i)=>o.outputItemID===null&&o.reportedIndex===i+1));
 check("13 indexed totals and denominator arithmetic",newStudy.unmappedReportedOutputs.reduce((s,o)=>s+o.reportedTotalUnits,0)===1072&&newStudy.unmappedReportedOutputs.every(o=>Math.abs(o.perReportedMassCastMean-o.reportedTotalUnits/113)<1e-12));
 check("first index arithmetic exactly 4 per mass cast",newStudy.unmappedReportedOutputs[0].perReportedMassCastMean===4);
 check("no current Retail normalization",newStudy.normalization.targetCurrentRetail===false&&newStudy.normalization.status.startsWith("BLOCKED_"));
 const recipe=reg.verifiedRecipeBatches?.find(x=>x.recipeSpellID===225904);
 check("specific Felslate mass recipe documented as 20 ore",recipe?.inputItemID===123919&&recipe.inputCountPerOperation===20&&recipe.expansionID===6);
 check("recipe batch does not claim output rate formula",recipe?.outputYieldTransform===null&&recipe?.currentRetailRecipeExecutionVerified===false&&recipe?.applyPolicy==="RECIPE_BATCH_METADATA_ONLY_NO_RATE_TRANSFORM");
 check("recipe source claims exist",recipe?.sourceClaimIDs.every(id=>reg.sourceClaims.some(c=>c.claimID===id&&c.url.startsWith("https://"))));
 check("candidate eight fields remain provisional below gate",candidate.processing.length===8&&candidate.processing.every(r=>r.recordConfidence<70&&["dropChance","yieldMin","yieldMax","expectedQuantity"].every(k=>r[k].confidence<70)));
 check("34 scored four-field records remain unpromoted",scoreCsv.trim().split(/\r?\n/).slice(1).length===34);
 const tuple=(p,mi,ma,E)=>[p,mi,ma,E].every(Number.isFinite)&&p>=0&&p<=1&&Number.isInteger(mi)&&Number.isInteger(ma)&&mi>=1&&ma>=mi&&E>=0&&p*mi<=E+1e-10&&E<=p*ma+1e-10;
 check("known consistent probability/conditional range/mean tuple accepted",tuple(.25,1,2,.3));
 check("unknown null chance is never treated as zero",!tuple(null,1,2,0));
 check("known contradictory Cobalt tuple rejected",!tuple(.235,1,2,2.5));
 check("empty mapped+unmapped evidence rejected by schema guard",!(0>=1||0>=sch.properties.unmappedReportedOutputs.minItems));
 return {passed:results.filter(x=>x.ok).length,failed:results.filter(x=>!x.ok).map(x=>x.name),checks:results,clientTested:false};
}
module.exports={auditMasterQA};
if(require.main===module){
 const fs=require("fs"),j=p=>JSON.parse(fs.readFileSync(p,"utf8"));
 const old=["research/evidence/observations/legion-felslate-3200ore-community.jsonl","research/evidence/observations/midnight-refulgent-copper-r2-50ore-community.jsonl","research/evidence/observations/tsm-anomaly-source-audit-2026-10-28.jsonl"].flatMap(p=>fs.readFileSync(p,"utf8").trim().split(/\r?\n/).map(JSON.parse));
 const r=auditMasterQA(j("research/coordination/assignments.json"),fs.readFileSync("research/ledger/first-pass-coverage-2026-10-28.csv","utf8"),j("research/evidence/observation.schema.json"),j("research/mechanics/ProfessionMechanicsRegistry.json"),old,j("research/evidence/observations/legion-felslate-113mass-unmapped-community.jsonl"),j("research/proposed/itemdb-midnight-milling-candidate.json"),fs.readFileSync("research/ledger/first-pass-34-critical-field-scores-2026-10-28.csv","utf8"));
 console.log(JSON.stringify(r,null,2));if(r.failed.length)process.exitCode=1;
}
