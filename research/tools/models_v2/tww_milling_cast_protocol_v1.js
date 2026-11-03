"use strict";
/* Research-only TWW Mycobloom milling completed-cast protocol.
   No automatic evidence, tooltip, or economic promotion. */
const VERSION="tww-milling-cast-protocol-v1.0.0";
const TARGETS={
 "historical:tww:mill:210796:222619:reddit-1fdmzwy-2024":[210796,1,222619,2],
 "historical:tww:mill:210797:222619:reddit-1fdmzwy-2024":[210797,2,222619,2]
};
const STATUSES=new Set(["COMPLETED","ABORTED","FAILED_BEFORE_COMPLETION","UNRESOLVED"]);
function check(x,name){if(!x)throw Error(name);}
function nat(x){return Number.isSafeInteger(x)&&x>=0;}
function validateSnapshot(s){
 check(s&&typeof s.snapshotID==="string"&&s.snapshotID.length>0,"SNAPSHOT_ID");
 const t=TARGETS[s.targetKey];check(!!t,"UNKNOWN_TARGET");
 check(s.gameMode==="RETAIL"&&s.expansionID===10&&s.method==="Mill","CONTEXT");
 check(s.inputItemID===t[0]&&s.inputQualityRank===t[1]&&
   s.outputItemID===t[2]&&s.outputQualityRank===t[3],"ITEM_RANK");
 check(s.nominalInputCountPerOperation===10&&Array.isArray(s.reagentVector)&&
   s.reagentVector.length===1&&s.reagentVector[0].itemID===t[0]&&
   s.reagentVector[0].unitsPerOperation===10,"REAGENTS");
 check(s.recipeSpellID===444181||s.recipeSpellID===null,"RECIPE");
 check(s.patchBuild===null||typeof s.patchBuild==="string","PATCH");
 check(s.observedProfessionSkill===null||nat(s.observedProfessionSkill),"SKILL");
 check(s.minimumRecipeEligibleSkill===null||nat(s.minimumRecipeEligibleSkill),"MIN_SKILL");
 check(s.professionStatsWithUnits===null||
   (typeof s.professionStatsWithUnits==="object"&&!Array.isArray(s.professionStatsWithUnits)),"STATS");
 if(s.professionStatsWithUnits)for(const v of Object.values(s.professionStatsWithUnits))
   check(v===null||(v&&Number.isFinite(v.value)&&typeof v.unit==="string"&&v.unit.length>0),"STAT_UNITS");
 check(s.optionalBonuses===null||typeof s.optionalBonuses==="object","BONUSES");
 check(s.unlocks===null||typeof s.unlocks==="object","UNLOCKS");
}
function validateSession(x){
 check(x&&x.schemaVersion==="1.0.0"&&x.sourceType==="DIRECT_CAST_LOG","SCHEMA");
 check(typeof x.studyFamilyID==="string"&&x.studyFamilyID.length>0&&
   typeof x.sessionID==="string"&&x.sessionID.length>0,"LINEAGE");
 check(x.requestedBulkCasts===null||nat(x.requestedBulkCasts),"REQUEST_COUNT");
 check(Array.isArray(x.snapshots)&&x.snapshots.length>0&&Array.isArray(x.events),"ARRAYS");
 const snapshots=new Map(),seen=new Set();
 for(const s of x.snapshots){validateSnapshot(s);check(!snapshots.has(s.snapshotID),"DUPLICATE_SNAPSHOT");snapshots.set(s.snapshotID,s);}
 for(const e of x.events){
   check(e&&typeof e.eventID==="string"&&e.eventID.length>0&&!seen.has(e.eventID),"DUPLICATE_EVENT");
   seen.add(e.eventID);check(snapshots.has(e.snapshotID),"MISSING_SNAPSHOT");
   check(STATUSES.has(e.status),"STATUS");
   if(e.status!=="COMPLETED"){
     check(e.outputCapture===null&&e.inputAccounting===null,"NONCOMPLETED_NOT_ZERO");
     continue;
   }
   if(e.inputAccounting!==null){
     const a=e.inputAccounting;
     check(a&&a.grossRequiredUnits===10,"GROSS_UNITS");
     check(a.refundedInputUnits===null||nat(a.refundedInputUnits),"REFUNDS");
     check(a.netSpentInputUnits===null||nat(a.netSpentInputUnits),"NET_SPENT");
     if(a.refundedInputUnits!==null&&a.netSpentInputUnits!==null)
       check(a.refundedInputUnits+a.netSpentInputUnits===10,"BALANCE");
     check(a.refundedInputUnits===null||a.refundedInputUnits<=10,"REFUND_MAX");
     check(a.netSpentInputUnits===null||a.netSpentInputUnits<=10,"NET_MAX");
   }
   check(e.outputCapture&&typeof e.outputCapture.complete==="boolean","CAPTURE_FLAG");
   const capture=e.outputCapture;
   if(!capture.complete){check(capture.countsByItemID===null,"INCOMPLETE_MUST_BE_UNKNOWN");continue;}
   const counts=capture.countsByItemID;
   check(counts&&typeof counts==="object"&&!Array.isArray(counts),"OUTPUT_COUNTS");
   for(const [id,n] of Object.entries(counts))
     check(/^[0-9]+$/.test(id)&&Number(id)>0&&nat(n),"OUTPUT_ITEM_OR_COUNT");
   check(Object.prototype.hasOwnProperty.call(counts,String(snapshots.get(e.snapshotID).outputItemID)),
     "EXPLICIT_ZERO_REQUIRED");
 }
 return snapshots;
}
function summarize(session){
 const snapshots=validateSession(session),cohorts=[];
 for(const s of snapshots.values()){
   const rows=session.events.filter(e=>e.snapshotID===s.snapshotID);
   const done=rows.filter(e=>e.status==="COMPLETED");
   const incomplete=done.filter(e=>!e.outputCapture.complete).length;
   const identifiable=done.length>0&&incomplete===0;
   let success=0,total=0,min=Infinity,max=-Infinity;
   const histogram={};
   if(identifiable)for(const e of done){
     const n=e.outputCapture.countsByItemID[String(s.outputItemID)];
     histogram[n]=(histogram[n]||0)+1;total+=n;
     if(n>0){success++;min=Math.min(min,n);max=Math.max(max,n);}
   }
   const accounted=done.length>0&&done.every(e=>e.inputAccounting&&
     e.inputAccounting.refundedInputUnits!==null&&e.inputAccounting.netSpentInputUnits!==null);
   const sum=field=>accounted?done.reduce((a,e)=>a+e.inputAccounting[field],0):null;
   cohorts.push({
     targetKey:s.targetKey,snapshotID:s.snapshotID,
     studyFamilyID:session.studyFamilyID,sessionID:session.sessionID,
     attempts:{requestedBulkCasts:session.requestedBulkCasts,completedCasts:done.length,
       aborted:rows.filter(e=>e.status==="ABORTED").length,
       failedBeforeCompletion:rows.filter(e=>e.status==="FAILED_BEFORE_COMPLETION").length,
       unresolved:rows.filter(e=>e.status==="UNRESOLVED").length,
       incompleteCompletedCasts:incomplete},
     rawObserved:identifiable?{
       dropChance:success/done.length,yieldMin:success?min:null,yieldMax:success?max:null,
       expectedQuantity:total/done.length,successCasts:success,zeroCasts:done.length-success,
       totalOutputUnits:total,histogram,
       basis:"ZERO_INCLUSIVE_ACTUAL_COMPLETED_CASTS",
       yieldBounds:"OBSERVED_POSITIVE_SUPPORT_NOT_HARD_GAME_BOUNDS"
     }:null,
     inputAccounting:{grossRequiredUnits:done.length*10,refundedInputUnits:sum("refundedInputUnits"),
       netSpentInputUnits:sum("netSpentInputUnits"),
       status:accounted?"PER_CAST_OBSERVED":"UNKNOWN_OR_INCOMPLETE"},
     status:done.length===0?"NO_COMPLETED_CASTS":incomplete?"BLOCKED_MISSING_OUTPUT":"RAW_DESCRIPTIVE_ONLY",
     contextGaps:[...(s.patchBuild===null?["PATCH_UNKNOWN"]:[]),
       ...(s.observedProfessionSkill===null?["SKILL_UNKNOWN"]:[]),
       ...(s.professionStatsWithUnits===null?["STATS_UNKNOWN"]:[]),
       ...(s.minimumRecipeEligibleSkill===null?["MIN_ELIGIBLE_SKILL_UNKNOWN"]:[]),
       ...(s.unlocks===null?["UNLOCKS_UNKNOWN"]:[])],
     independentHoldout:"NONE",
     currentRetailEconomicFields:{dropChance:null,yieldMin:null,yieldMax:null,expectedQuantity:null},
     economicUse:"PREVIEW_ONLY",normalizedVerified:false,confidence:0,
     evidencePromotion:false,tooltipPromotion:false
   });
 }
 return {modelVersion:VERSION,scope:"RESEARCH_ONLY_NOT_SHIPPED",
   studyFamilyID:session.studyFamilyID,sessionID:session.sessionID,cohorts,
   independentHoldoutRequired:"WHOLE_UNRELATED_STUDY_FAMILY"};
}
function example(){
 const key=Object.keys(TARGETS)[0];
 return {schemaVersion:"1.0.0",sourceType:"DIRECT_CAST_LOG",
   studyFamilyID:"SYNTHETIC_NOT_EVIDENCE",sessionID:"SYNTHETIC_SESSION",
   requestedBulkCasts:99,
   snapshots:[{snapshotID:"S1",targetKey:key,gameMode:"RETAIL",expansionID:10,method:"Mill",
     recipeSpellID:444181,patchBuild:null,inputItemID:210796,inputQualityRank:1,
     outputItemID:222619,outputQualityRank:2,nominalInputCountPerOperation:10,
     reagentVector:[{itemID:210796,unitsPerOperation:10}],
     minimumRecipeEligibleSkill:null,observedProfessionSkill:null,
     professionStatsWithUnits:null,optionalBonuses:null,unlocks:null}],
   events:[
     {eventID:"C1",snapshotID:"S1",status:"COMPLETED",
       outputCapture:{complete:true,countsByItemID:{"222619":0}},
       inputAccounting:{grossRequiredUnits:10,refundedInputUnits:2,netSpentInputUnits:8}},
     {eventID:"C2",snapshotID:"S1",status:"COMPLETED",
       outputCapture:{complete:true,countsByItemID:{"222619":2,"222618":1}},
       inputAccounting:{grossRequiredUnits:10,refundedInputUnits:0,netSpentInputUnits:10}},
     {eventID:"A1",snapshotID:"S1",status:"ABORTED",outputCapture:null,inputAccounting:null}
   ]};
}
function selfTest(){
 let passed=0;
 const ok=(v,id)=>{check(v,"TEST_"+id);passed++;};
 const bad=(f,id)=>{let caught=false;try{f();}catch(_){caught=true;}ok(caught,id);};
 const x=summarize(example()).cohorts[0];
 ok(x.attempts.completedCasts===2&&x.attempts.aborted===1,"ABORT");
 ok(x.attempts.requestedBulkCasts===99,"BULK");
 ok(x.rawObserved.dropChance===0.5&&x.rawObserved.expectedQuantity===1,"ZERO_INCLUSIVE");
 ok(x.rawObserved.yieldMin===2&&x.rawObserved.yieldMax===2,"POSITIVE_BOUNDS");
 ok(x.rawObserved.histogram[0]===1&&x.rawObserved.histogram[2]===1,"HISTOGRAM");
 ok(x.inputAccounting.refundedInputUnits===2&&x.inputAccounting.netSpentInputUnits===18,"REFUND");
 ok(x.rawObserved.expectedQuantity===1,"NO_REFUND_E_SCALING");
 ok(x.currentRetailEconomicFields.expectedQuantity===null&&x.confidence===0&&
   x.economicUse==="PREVIEW_ONLY"&&!x.normalizedVerified,"ISOLATION");
 ok(x.contextGaps.includes("PATCH_UNKNOWN"),"UNKNOWN_CONTEXT");
 const z=example();z.events=[z.events[0]];
 const y=summarize(z).cohorts[0].rawObserved;
 ok(y.dropChance===0&&y.expectedQuantity===0&&y.yieldMin===null&&y.yieldMax===null,"ALL_ZERO");
 const inc=example();inc.events[0].outputCapture={complete:false,countsByItemID:null};
 ok(summarize(inc).cohorts[0].rawObserved===null,"MISSING_OUTPUT_BLOCKS");
 const none=example();none.events=[none.events[2]];
 ok(summarize(none).cohorts[0].rawObserved===null,"NO_COMPLETED_NOT_ZERO");
 const refund=example();refund.events[0].inputAccounting=null;
 ok(summarize(refund).cohorts[0].inputAccounting.refundedInputUnits===null,"UNKNOWN_REFUND");
 const dual=example();dual.snapshots.push({...dual.snapshots[0],snapshotID:"S2",
   targetKey:Object.keys(TARGETS)[1],inputItemID:210797,inputQualityRank:2,
   reagentVector:[{itemID:210797,unitsPerOperation:10}]});
 dual.events.push({eventID:"C3",snapshotID:"S2",status:"COMPLETED",
   outputCapture:{complete:true,countsByItemID:{"222619":3}},inputAccounting:null});
 const groups=summarize(dual).cohorts;
 ok(groups.length===2&&groups[0].attempts.completedCasts===2&&groups[1].attempts.completedCasts===1,"STRATIFY");
 ok(groups[1].rawObserved.expectedQuantity===3,"SECOND_RANK");
 const dup=example();dup.events[1].eventID="C1";bad(()=>summarize(dup),"DUPLICATE");
 const rank=example();rank.snapshots[0].inputQualityRank=3;bad(()=>summarize(rank),"RANK");
 const missing=example();delete missing.events[0].outputCapture.countsByItemID["222619"];
 bad(()=>summarize(missing),"EXPLICIT_ZERO");
 const negative=example();negative.events[0].outputCapture.countsByItemID["222619"]=-1;
 bad(()=>summarize(negative),"NEGATIVE");
 const aborted=example();aborted.events[2].outputCapture={complete:true,countsByItemID:{"222619":0}};
 bad(()=>summarize(aborted),"ABORTED_NOT_ZERO");
 const balance=example();balance.events[0].inputAccounting.netSpentInputUnits=9;
 bad(()=>summarize(balance),"BALANCE");
 const status=example();status.events[0].status="REQUESTED";bad(()=>summarize(status),"STATUS");
 const lineage=example();lineage.studyFamilyID="";bad(()=>summarize(lineage),"LINEAGE");
 const snapshot=example();snapshot.events[0].snapshotID="BAD";bad(()=>summarize(snapshot),"SNAPSHOT");
 const stats=example();stats.snapshots[0].professionStatsWithUnits={resourcefulness:{value:15,unit:"rating"}};
 ok(summarize(stats).cohorts[0].contextGaps.includes("SKILL_UNKNOWN"),"NO_SKILL_INFERENCE");
 const units=example();units.snapshots[0].professionStatsWithUnits={resourcefulness:15};
 bad(()=>summarize(units),"STAT_UNITS");
 return {passed,failed:0,syntheticOnly:true,rawEvidenceRows:0,newEconomicValues:0,targets:2};
}
module.exports={VERSION,TARGETS,validateSnapshot,validateSession,summarize,example,selfTest};
if(require.main===module){
 if(process.argv.includes("--self-test"))console.log(JSON.stringify(selfTest()));
 else if(process.argv.includes("--example"))console.log(JSON.stringify(example(),null,2));
 else console.log("Use --self-test or --example (SYNTHETIC, NOT EVIDENCE)");
}
