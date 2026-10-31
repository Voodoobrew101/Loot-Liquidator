"use strict";
/** F003 research-only: conditional TWW Gem Finding cohorts, never a live EV source. */
const MODEL_ID="tww-gem-finding-cohort-v1.0.0";
const INPUTS={210931:{Ruby:212495,Emerald:212505,Sapphire:212508,Onyx:212511},210934:{Ruby:212495,Onyx:212511},210937:{Emerald:212505,Sapphire:212508}};
const TARGETS=Object.entries(INPUTS).flatMap(([input,outputs])=>Object.entries(outputs).map(([gem,output])=>({recordID:"candidate:conditional:prospect:"+input+":"+output+":gem-finding:20261028",inputItemID:Number(input),outputItemID:output,gem,recipeSpellID:434018,inputQualityRank:2,outputQualityRank:null,nominalInputUnits:5})));
function check(ok,code){if(!ok)throw Error(code);}
function clone(x){return JSON.parse(JSON.stringify(x));}
function contextKey(s){const stats=Object.fromEntries(Object.keys(s.professionStats).sort().map(k=>[k,s.professionStats[k]]));return JSON.stringify([s.gameMode,s.patchEpoch,s.recipeSpellID,s.inputItemID,s.inputQualityRank,s.nominalInputUnits,s.operationVariant,s.effectiveSkill,stats,s.gemFindingUnlocks]);}
function validate(s){
 check(s&&s.sessionID&&s.studyFamilyID,"IDENTITY");
 check(s.gameMode==="Retail"&&typeof s.patchEpoch==="string"&&s.patchEpoch.length>0&&s.recipeSpellID===434018&&s.inputQualityRank===2&&s.nominalInputUnits===5&&typeof s.operationVariant==="string"&&s.operationVariant.length>0,"CONTEXT");
 const outputs=INPUTS[s.inputItemID];check(!!outputs,"INPUT_NOT_ASSIGNED");
 check(s.effectiveSkill===null||(Number.isInteger(s.effectiveSkill)&&s.effectiveSkill>=0),"SKILL");
 check(s.professionStats&&typeof s.professionStats==="object"&&!Array.isArray(s.professionStats),"STATS");
 for(const x of Object.values(s.professionStats))check(x&&typeof x.unit==="string"&&x.unit.length>0&&(x.value===null||(Number.isFinite(x.value)&&x.value>=0)),"STAT_UNIT");
 const u=s.gemFindingUnlocks;
 check(u&&Object.keys(u).sort().join(",")==="Emerald,Onyx,Ruby,Sapphire"&&Object.values(u).every(x=>x===true||x===false||x===null),"UNLOCK");
 check(Array.isArray(s.events)&&s.events.length>0,"EVENTS");
 const seen=new Set(),required=Object.values(outputs).map(String).sort().join(",");
 for(const e of s.events){
  check(e&&typeof e.eventID==="string"&&e.eventID.length>0&&!seen.has(e.eventID),"EVENT_ID");
  seen.add(e.eventID);
  if(e.status==="ABORTED"){check(e.outputCapture===null&&e.inputAccounting===null,"ABORT_HAS_RESULT");continue;}
  check(e.status==="COMPLETED"&&e.outputCapture&&e.outputCapture.complete===true&&e.inputAccounting,"NOT_COMPLETED");
  const counts=e.outputCapture.countsByItemID;
  check(counts&&Object.keys(counts).sort().join(",")===required&&Object.values(counts).every(x=>Number.isSafeInteger(x)&&x>=0),"EXPLICIT_ZERO_REQUIRED");
  const a=e.inputAccounting;
  check(a.nominalInputUnits===5&&Number.isSafeInteger(a.refundedInputUnits)&&a.refundedInputUnits>=0&&a.refundedInputUnits<=5&&a.netSpentInputUnits===5-a.refundedInputUnits,"REFUND_ACCOUNTING");
  for(const [gem,id] of Object.entries(outputs))check(u[gem]!==false||counts[String(id)]===0,"LOCKED_POSITIVE");
 }
 return TARGETS.filter(t=>t.inputItemID===s.inputItemID);
}
function summarize(s){
 const targets=validate(s),done=s.events.filter(e=>e.status==="COMPLETED"),refunded=done.reduce((v,e)=>v+e.inputAccounting.refundedInputUnits,0);
 const rows=targets.map(t=>{
  const base={recordID:t.recordID,gem:t.gem,outputItemID:t.outputItemID,outputQualityRank:null,completedCasts:done.length,confidence:0,economicUse:"PREVIEW_ONLY",normalizedVerified:false,evidencePromotion:false,verifiedMinimumEligibleBaseline:false};
  const unlock=s.gemFindingUnlocks[t.gem];
  if(unlock!==true||!done.length)return {...base,status:unlock===false?"INELIGIBLE_CONTEXT":unlock===null?"UNKNOWN_UNLOCK":"NO_COMPLETED_CASTS",dropChance:null,yieldMin:null,yieldMax:null,expectedQuantity:null};
  const values=done.map(e=>e.outputCapture.countsByItemID[String(t.outputItemID)]),positive=values.filter(x=>x>0);
  const P=positive.length/done.length,E=values.reduce((a,b)=>a+b,0)/done.length,min=positive.length?Math.min(...positive):null,max=positive.length?Math.max(...positive):null;
  check(P===0&&E===0&&min===null&&max===null||P>0&&P*min<=E+1e-12&&E<=P*max+1e-12,"INVARIANT");
  return {...base,status:s.effectiveSkill===null||s.patchEpoch==="UNKNOWN"?"OBSERVED_INCOMPLETE_CONTEXT":"OBSERVED_COHORT_NOT_BASELINE",dropChance:P,yieldMin:min,yieldMax:max,expectedQuantity:E,positiveCasts:positive.length,rangeBasis:"OBSERVED_POSITIVE_ONLY"};
 });
 return {modelID:MODEL_ID,sessionID:s.sessionID,studyFamilyID:s.studyFamilyID,contextKey:contextKey(s),completedCasts:done.length,abortedRequests:s.events.length-done.length,grossInputUnits:5*done.length,refundedInputUnits:refunded,netInputUnits:5*done.length-refunded,rows};
}
function partition(sessions){
 check(Array.isArray(sessions)&&sessions.length>0,"SESSIONS");
 const ids=new Set(),events=new Set(),groups=new Map();
 for(const s of sessions){
  const x=summarize(s);check(!ids.has(s.sessionID),"DUPLICATE_SESSION");ids.add(s.sessionID);
  for(const e of s.events){const k=s.studyFamilyID+":"+e.eventID;check(!events.has(k),"DUPLICATE_STUDY_EVENT");events.add(k);}
  const key=s.studyFamilyID+"|"+x.contextKey;if(!groups.has(key))groups.set(key,{studyFamilyID:s.studyFamilyID,contextKey:x.contextKey,sessions:0,completedCasts:0});
  const g=groups.get(key);g.sessions++;g.completedCasts+=x.completedCasts;
 }
 return [...groups.values()];
}
function synthetic(){
 const z=()=>({"212495":0,"212505":0,"212508":0,"212511":0});
 const cast=(id,c,r)=>({eventID:id,status:"COMPLETED",outputCapture:{complete:true,countsByItemID:c},inputAccounting:{nominalInputUnits:5,refundedInputUnits:r,netSpentInputUnits:5-r}});
 return {sessionID:"SYN-1",studyFamilyID:"SYNTHETIC-NOT-EVIDENCE",gameMode:"Retail",patchEpoch:"SYNTHETIC",recipeSpellID:434018,inputItemID:210931,inputQualityRank:2,nominalInputUnits:5,operationVariant:"SYNTHETIC",effectiveSkill:100,professionStats:{resourcefulness:{value:30,unit:"rating"}},gemFindingUnlocks:{Ruby:true,Emerald:true,Sapphire:false,Onyx:null},events:[cast("1",{...z(),"212495":1,"212505":2},2),cast("2",{...z(),"212495":1,"212505":1},0),cast("3",z(),1),{eventID:"4",status:"ABORTED",outputCapture:null,inputAccounting:null}]};
}
function selfTest(){
 let n=0;const ok=(v,name)=>{n++;check(v,"TEST_"+name);},bad=(fn,name)=>{n++;let failed=false;try{fn();}catch(e){failed=true;}check(failed,"TEST_EXPECT_REJECT_"+name);};
 const s=synthetic(),r=summarize(s),ruby=r.rows.find(x=>x.gem==="Ruby"),em=r.rows.find(x=>x.gem==="Emerald");
 ok(TARGETS.length===8,"KEYS");ok(r.completedCasts===3&&r.abortedRequests===1,"ABORT");ok(r.grossInputUnits===15&&r.refundedInputUnits===3&&r.netInputUnits===12,"REFUNDS");
 ok(ruby.dropChance===2/3&&ruby.expectedQuantity===2/3&&ruby.yieldMin===1,"RUBY");
 ok(em.dropChance===2/3&&em.expectedQuantity===1&&em.yieldMax===2,"EMERALD");
 ok(ruby.dropChance+em.dropChance>1,"COOUTPUT");
 ok(r.rows.find(x=>x.gem==="Sapphire").expectedQuantity===null,"LOCKED_NULL");
 ok(r.rows.find(x=>x.gem==="Onyx").dropChance===null,"UNKNOWN_NULL");
 ok(r.rows.every(x=>x.confidence===0&&x.economicUse==="PREVIEW_ONLY"&&!x.normalizedVerified),"ISOLATION");
 const zero=clone(s);zero.events[0].outputCapture.countsByItemID["212495"]=0;zero.events[1].outputCapture.countsByItemID["212495"]=0;ok(summarize(zero).rows[0].dropChance===0&&summarize(zero).rows[0].yieldMin===null,"ZERO_SUPPORT");
 const none=clone(s);none.events=none.events.slice(-1);ok(summarize(none).rows[0].expectedQuantity===null,"NO_CASTS");
 const unknown=clone(s);unknown.effectiveSkill=null;ok(summarize(unknown).rows[0].status==="OBSERVED_INCOMPLETE_CONTEXT","UNKNOWN_SKILL");
 const missing=clone(s);delete missing.events[0].outputCapture.countsByItemID["212508"];bad(()=>summarize(missing),"MISSING_ZERO");
 const negative=clone(s);negative.events[0].outputCapture.countsByItemID["212495"]=-1;bad(()=>summarize(negative),"NEGATIVE");
 const refund=clone(s);refund.events[0].inputAccounting.netSpentInputUnits=5;bad(()=>summarize(refund),"REFUND");
 const lock=clone(s);lock.gemFindingUnlocks.Ruby=false;bad(()=>summarize(lock),"LOCKED_POSITIVE");
 const abort=clone(s);abort.events[3].outputCapture={complete:true};bad(()=>summarize(abort),"ABORT_OUTPUT");
 const rank=clone(s);rank.inputQualityRank=3;bad(()=>summarize(rank),"RANK");
 const stat=clone(s);stat.professionStats.resourcefulness=30;bad(()=>summarize(stat),"STAT_UNITS");
 const other=clone(s);other.sessionID="SYN-2";other.events.forEach(e=>e.eventID+="x");
 ok(partition([s,other]).length===1,"SAME_COHORT");
 const patch=clone(other);patch.patchEpoch="OTHER";ok(partition([s,patch]).length===2,"PATCH_SPLIT");
 const unlock=clone(other);unlock.gemFindingUnlocks.Onyx=true;ok(partition([s,unlock]).length===2,"UNLOCK_SPLIT");
 const stats=clone(other);stats.professionStats.resourcefulness.value=31;ok(partition([s,stats]).length===2,"STATS_SPLIT");
 bad(()=>partition([s,s]),"DUPLICATE_SESSION");
 const overlap=clone(other);overlap.events=clone(s.events);bad(()=>partition([s,overlap]),"DUPLICATE_EVENTS");
 return {passed:n,failed:0,syntheticOnly:true,targets:TARGETS.length,actualCasts:0,economicPromotions:0};
}
module.exports={MODEL_ID,INPUTS,TARGETS,validate,summarize,partition,synthetic,selfTest};
if(require.main===module){if(process.argv.includes("--self-test"))console.log(JSON.stringify(selfTest()));else if(process.argv.includes("--synthetic-example"))console.log(JSON.stringify(summarize(synthetic()),null,2));}
