'use strict';
// F003 research-only: Midnight prospecting March 31, 2026 dated-hotfix epoch isolation.
// No historical/current rates are promoted to economic use, recipe eligibility or measured facts.
const assert = require('node:assert/strict');
const MODEL_ID = 'midnight-prospect-hotfix-epoch-isolation-v1.0.3';
const POLICY = Object.freeze({confidence:0,economicUse:'PREVIEW_ONLY',normalizedVerified:false,liveEconomicEligible:false,tooltipOnlyEligible:false});
const TARGETS = Object.freeze({
  237359:'midnight:237359:242608:L733',237361:'midnight:237361:242608:L744',
  237362:'midnight:237362:242608:L755',237363:'midnight:237363:242608:L766',
  237364:'midnight:237364:242608:L777',237365:'midnight:237365:242608:L788',
  237366:'midnight:237366:242608:L799'
});
// Blizzard's prospecting entry is dated March 31; exact deployment hour/region is unknown.
// Quarantine March 31-April 2 UTC and observations locally dated March 31-April 2 across offsets.
// The April 1 Stoic Eversong Diamond armor hotfix is unrelated.
// This is a safety buffer, NOT an asserted deployment window.
const OFFICIAL_ENTRY_DATE='2026-03-31';
const OFFICIAL_SOURCE_URL='https://worldofwarcraft.blizzard.com/en-us/news/24266320';
const BEFORE_END_MS = Date.parse('2026-03-31T00:00:00Z');
const AFTER_START_MS = Date.parse('2026-04-03T00:00:00Z');
function check(ok,code){if(!ok)throw Error(code);}
const positive = x=>Number.isSafeInteger(x)&&x>0;
const nonnegative = x=>Number.isSafeInteger(x)&&x>=0;
function epochMs(s){
 check(typeof s==='string','EPOCH_REQUIRED');
 const m=/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.(\d{1,3}))?(Z|[+-]\d{2}:\d{2})$/.exec(s);
 check(!!m,'EPOCH_FORMAT');
 const y=+m[1],mon=+m[2],d=+m[3],h=+m[4],min=+m[5],sec=+m[6];
 const leap=y%4===0&&(y%100!==0||y%400===0);
 const days=[31,leap?29:28,31,30,31,30,31,31,30,31,30,31];
 check(y>=1970&&mon>=1&&mon<=12&&d>=1&&d<=days[mon-1]&&h<=23&&min<=59&&sec<=59,'EPOCH_CALENDAR');
 const tz=m[8];
 if(tz!=='Z'){
  const hh=+tz.slice(1,3),mm=+tz.slice(4,6);
  check(hh<=14&&mm<=59&&(hh<14||mm===0),'EPOCH_TIMEZONE');
 }
 const t=Date.parse(s);check(Number.isFinite(t),'EPOCH_UNPARSEABLE');return t;
}
function classifyEpoch(s){
 const ms=epochMs(s);
 // Do not certify any locally dated March 31-April 2 cohort as PRE or POST,
 // even when its timezone conversion falls outside the UTC buffer.
 const localDate=s.slice(0,10);
 if(localDate==='2026-03-31'||localDate==='2026-04-01'||localDate==='2026-04-02')return 'TRANSITION_QUARANTINE';
 return ms<BEFORE_END_MS?'PRE_HOTFIX':ms>=AFTER_START_MS?'POST_HOTFIX':'TRANSITION_QUARANTINE';
}
function jsonSafe(v,ancestors=new Set()){
 if(v===null||typeof v==='string'||typeof v==='boolean')return true;
 if(typeof v==='number')return Number.isFinite(v);
 if(typeof v!=='object'||ancestors.has(v))return false;
 const array=Array.isArray(v),proto=Object.getPrototypeOf(v);
 if(array?proto!==Array.prototype:proto!==Object.prototype&&proto!==null)return false;
 ancestors.add(v);
 const keys=Reflect.ownKeys(v);
 let ok=true;
 if(array){
  // Own property order for dense arrays is 0..length-1 followed by "length".
  // Reject holes, added keys, symbols, accessors and custom serialization.
  const n=v.length;
  ok=Number.isSafeInteger(n)&&keys.length===n+1&&keys[n]==='length';
  for(let i=0;ok&&i<n;i++){
   if(keys[i]!==String(i)){ok=false;break;}
   const d=Object.getOwnPropertyDescriptor(v,keys[i]);
   ok=!!d&&d.enumerable&&Object.hasOwn(d,'value')&&jsonSafe(d.value,ancestors);
  }
 }else{
  for(const k of keys){
   const d=typeof k==='string'&&Object.getOwnPropertyDescriptor(v,k);
   if(k==='toJSON'||!d||!d.enumerable||!Object.hasOwn(d,'value')||!jsonSafe(d.value,ancestors)){ok=false;break;}
  }
 }
 ancestors.delete(v);
 return ok;
}
function validateContext(c){
 check(c&&jsonSafe(c),'UNSAFE_CONTEXT');
 check(c.gameMode==='RETAIL'&&c.expansion==='MIDNIGHT'&&c.method==='PROSPECT','GAME_METHOD');
 check(Object.hasOwn(TARGETS,c.inputItemID)&&c.stableKey===TARGETS[c.inputItemID]&&c.outputItemID===242608,'TARGET_IDENTITY');
 check(['SYNTHETIC','RAW_CURRENT_RETAIL'].includes(c.sourceType),'SOURCE_TYPE');
 check(typeof c.patchBuild==='string'&&/^\d+\.\d+\.\d+(?:\.\d+)?$/.test(c.patchBuild),'PATCH_BUILD');
 check(positive(c.recipeSpellID)&&positive(c.inputQualityRank)&&positive(c.outputQualityRank),'RECIPE_RANK');
 check(positive(c.nominalInputPerCast)&&Array.isArray(c.directReagents)&&c.directReagents.length>0,'REAGENTS');
 check(c.directReagents.every(r=>r&&positive(r.itemID)&&positive(r.quantity))&&new Set(c.directReagents.map(r=>r.itemID)).size===c.directReagents.length,'REAGENT_VECTOR');
 check(c.directReagents.some(r=>r.itemID===c.inputItemID&&r.quantity===c.nominalInputPerCast),'INPUT_REAGENT');
 check(positive(c.minimumEligibleSkill)&&positive(c.professionSkill)&&c.professionSkill>=c.minimumEligibleSkill,'SKILL');
 check(c.professionContext&&['specialization','gear','unlocks','resourcefulnessPercent'].every(k=>Object.hasOwn(c.professionContext,k)),'PROFESSION_CONTEXT');
 check(typeof c.professionContext.resourcefulnessPercent==='number'&&c.professionContext.resourcefulnessPercent>=0&&c.professionContext.resourcefulnessPercent<=100,'RESOURCEFULNESS');
 check(typeof c.studyFamilyID==='string'&&c.studyFamilyID.trim()&&typeof c.sourceLineage==='string'&&c.sourceLineage.trim(),'LINEAGE');
 epochMs(c.observationStart);epochMs(c.observationEnd);
 check(epochMs(c.observationEnd)>=epochMs(c.observationStart),'OBSERVATION_ORDER');
 return true;
}
function analyzeCohort({context,events}){
 validateContext(context);
 const c=JSON.parse(JSON.stringify(context));
 check(Array.isArray(events)&&events.length>0,'EVENTS');
 const start=classifyEpoch(c.observationStart),end=classifyEpoch(c.observationEnd);
 const epoch=start===end?start:'TRANSITION_QUARANTINE';
 let completed=0,aborted=0,positiveCasts=0,zeroCasts=0,outputTotal=0,refunds=0;
 const ids=new Set();let observedMin=null,observedMax=null;
 for(const e of events){
  check(e&&typeof e.castID==='string'&&e.castID.trim()&&!ids.has(e.castID),'CAST_ID');ids.add(e.castID);
  check(e.status==='COMPLETED'||e.status==='ABORTED','CAST_STATUS');
  if(e.status==='ABORTED'){
   check(!Object.hasOwn(e,'outputCount')&&!Object.hasOwn(e,'refundedInputUnits'),'ABORTED_HAS_OUTPUT');aborted++;continue;
  }
  check(nonnegative(e.outputCount)&&nonnegative(e.refundedInputUnits)&&e.refundedInputUnits<=c.nominalInputPerCast,'COUNT_REFUND');
  completed++;outputTotal+=e.outputCount;refunds+=e.refundedInputUnits;
  check(Number.isSafeInteger(outputTotal)&&Number.isSafeInteger(refunds),'TOTAL_OVERFLOW');
  if(e.outputCount===0)zeroCasts++;
  else {positiveCasts++;observedMin=observedMin===null?e.outputCount:Math.min(observedMin,e.outputCount);observedMax=observedMax===null?e.outputCount:Math.max(observedMax,e.outputCount);}
 }
 check(completed>0&&Number.isSafeInteger(completed*c.nominalInputPerCast),'NO_VALID_CASTS');
 const gross=completed*c.nominalInputPerCast,net=gross-refunds;
 const p=positiveCasts/completed,e=outputTotal/completed;
 check(Number.isFinite(p)&&Number.isFinite(e),'NONFINITE_RESULT');
 return {modelID:MODEL_ID,stableKey:c.stableKey,sourceType:c.sourceType,studyFamilyID:c.studyFamilyID,sourceLineage:c.sourceLineage,
  epoch,epochStartClass:start,epochEndClass:end,officialHotfixEntryDate:OFFICIAL_ENTRY_DATE,
  officialHotfixSource:OFFICIAL_SOURCE_URL,hotfixDeploymentHour:'UNKNOWN',hotfixCausalEffect:'NOT_IDENTIFIED',
  contextSnapshot:c,completedCasts:completed,abortedRequests:aborted,zeroOutputCasts:zeroCasts,
  positiveCasts,observedP:p,observedUnconditionalE:e,observedPositiveMin:observedMin,observedPositiveMax:observedMax,
  grossInput:gross,refundedInput:refunds,netConsumedInput:net,
  hardYieldCap:null,fullOutputUniverseIndependentlyAudited:false,independentHoldout:'NOT_PERFORMED',...POLICY};
}
function profileKey(c){
 return JSON.stringify({stableKey:c.stableKey,recipeSpellID:c.recipeSpellID,inputQualityRank:c.inputQualityRank,
 outputQualityRank:c.outputQualityRank,nominalInputPerCast:c.nominalInputPerCast,directReagents:c.directReagents,
 minimumEligibleSkill:c.minimumEligibleSkill,professionSkill:c.professionSkill,professionContext:c.professionContext});
}
function compareEpochs(pre,post){
 check(pre&&post&&pre.modelID===MODEL_ID&&post.modelID===MODEL_ID,'MODEL_PAIR');
 check(pre.epoch==='PRE_HOTFIX'&&post.epoch==='POST_HOTFIX','CROSS_EPOCH_PAIR');
 check(pre.sourceType==='RAW_CURRENT_RETAIL'&&post.sourceType==='RAW_CURRENT_RETAIL','RAW_PAIR_REQUIRED');
 check(profileKey(pre.contextSnapshot)===profileKey(post.contextSnapshot),'PROFILE_MISMATCH');
 check(pre.sourceLineage.trim().toLowerCase()!==post.sourceLineage.trim().toLowerCase(),'DUPLICATE_SOURCE_LINEAGE');
 check(pre.studyFamilyID.trim().toLowerCase()!==post.studyFamilyID.trim().toLowerCase(),'DUPLICATE_STUDY_FAMILY');
 return {modelID:MODEL_ID,stableKey:pre.stableKey,preStudyFamilyID:pre.studyFamilyID,postStudyFamilyID:post.studyFamilyID,
  patchBuildChanged:pre.contextSnapshot.patchBuild!==post.contextSnapshot.patchBuild,
  deltaObservedP:post.observedP-pre.observedP,deltaObservedUnconditionalE:post.observedUnconditionalE-pre.observedUnconditionalE,
  ratioObservedE:pre.observedUnconditionalE>0?post.observedUnconditionalE/pre.observedUnconditionalE:null,
  independentHoldout:'NOT_PERFORMED',causalAttribution:'NOT_IDENTIFIED',postHotfixEffectSize:'NOT_VERIFIED',
  fullOutputUniverseIndependentlyAudited:false,...POLICY};
}
function selfTest(){
 let passed=0;const eq=(a,b)=>{assert.deepEqual(a,b);passed++};
 const throws=(fn,code)=>{assert.throws(fn,new RegExp(code));passed++};
 const c={gameMode:'RETAIL',expansion:'MIDNIGHT',method:'PROSPECT',stableKey:TARGETS[237359],inputItemID:237359,outputItemID:242608,
 sourceType:'RAW_CURRENT_RETAIL',patchBuild:'12.0.5',recipeSpellID:1231127,inputQualityRank:2,outputQualityRank:1,
 nominalInputPerCast:5,directReagents:[{itemID:237359,quantity:5}],minimumEligibleSkill:1,professionSkill:1,
 professionContext:{specialization:[],gear:[],unlocks:[],resourcefulnessPercent:0},studyFamilyID:'synthetic-pre',sourceLineage:'synthetic-pre',
 observationStart:'2026-03-30T12:00:00Z',observationEnd:'2026-03-30T13:00:00Z'};
 const es=[{castID:'1',status:'COMPLETED',outputCount:0,refundedInputUnits:0},{castID:'2',status:'COMPLETED',outputCount:2,refundedInputUnits:1},{castID:'3',status:'ABORTED'}];
 const a=analyzeCohort({context:c,events:es});
 eq(a.epoch,'PRE_HOTFIX');eq(a.completedCasts,2);eq(a.abortedRequests,1);eq(a.zeroOutputCasts,1);eq(a.observedP,.5);eq(a.observedUnconditionalE,1);
 eq(a.observedPositiveMin,2);eq(a.grossInput,10);eq(a.refundedInput,1);eq(a.netConsumedInput,9);eq(a.economicUse,'PREVIEW_ONLY');eq(a.confidence,0);eq(a.normalizedVerified,false);
 const post={...c,studyFamilyID:'synthetic-post',sourceLineage:'synthetic-post',observationStart:'2026-04-10T12:00:00Z',observationEnd:'2026-04-10T13:00:00Z'};
 const b=analyzeCohort({context:post,events:[{castID:'4',status:'COMPLETED',outputCount:3,refundedInputUnits:0}]});
 eq(b.epoch,'POST_HOTFIX');eq(b.observedUnconditionalE,3);
 const comp=compareEpochs(a,b);eq(comp.deltaObservedUnconditionalE,2);eq(comp.deltaObservedP,.5);eq(comp.causalAttribution,'NOT_IDENTIFIED');eq(comp.patchBuildChanged,false);
 eq(classifyEpoch('2026-04-01T23:59:59Z'),'TRANSITION_QUARANTINE');eq(classifyEpoch('2026-04-02T00:00:00Z'),'TRANSITION_QUARANTINE');
 eq(classifyEpoch('2026-04-03T12:00:00Z'),'POST_HOTFIX');eq(classifyEpoch('2026-04-05T23:59:59Z'),'POST_HOTFIX');
 eq(classifyEpoch('2026-04-06T00:00:00Z'),'POST_HOTFIX');
 eq(classifyEpoch('2026-03-31T23:59:59Z'),'TRANSITION_QUARANTINE');
 eq(classifyEpoch('2026-04-01T00:00:00Z'),'TRANSITION_QUARANTINE');
 eq(classifyEpoch('2026-04-02T23:59:59Z'),'TRANSITION_QUARANTINE');
 eq(classifyEpoch('2026-04-03T00:00:00Z'),'POST_HOTFIX');
 eq(classifyEpoch('2026-04-01T01:00:00+02:00'),'TRANSITION_QUARANTINE');
 eq(classifyEpoch('2026-04-02T23:59:00-07:00'),'TRANSITION_QUARANTINE');
 eq(classifyEpoch('2026-03-31T23:30:00-07:00'),'TRANSITION_QUARANTINE');
 eq(classifyEpoch('2026-03-31T00:00:00Z'),'TRANSITION_QUARANTINE');
 eq(classifyEpoch('2026-03-31T12:00:00Z'),'TRANSITION_QUARANTINE');
 eq(classifyEpoch('2026-03-31T00:30:00+14:00'),'TRANSITION_QUARANTINE');
 eq(classifyEpoch('2026-03-30T23:30:00-07:00'),'TRANSITION_QUARANTINE');
 eq(classifyEpoch('2026-03-30T10:00:00+14:00'),'PRE_HOTFIX');
 eq(classifyEpoch('2026-04-04T10:00:00+14:00'),'POST_HOTFIX');
 eq(analyzeCohort({context:{...c,observationEnd:'2026-03-31T12:00:00Z'},events:es}).epoch,'TRANSITION_QUARANTINE');
 eq(classifyEpoch('2026-04-03T00:30:00+02:00'),'TRANSITION_QUARANTINE');
 eq(a.officialHotfixEntryDate,'2026-03-31');
 eq(classifyEpoch('2026-04-06T01:00:00+02:00'),'POST_HOTFIX');
 const mixed={...c,observationEnd:'2026-04-07T13:00:00Z'};
 eq(analyzeCohort({context:mixed,events:es}).epoch,'TRANSITION_QUARANTINE');
 throws(()=>epochMs('2026-02-29T00:00:00Z'),'EPOCH_CALENDAR');eq(classifyEpoch('2024-02-29T00:00:00Z'),'PRE_HOTFIX');
 throws(()=>epochMs('2026-04-01T00:00:00+14:30'),'EPOCH_TIMEZONE');throws(()=>epochMs('banana'),'EPOCH_FORMAT');
 throws(()=>analyzeCohort({context:{...c,patchBuild:'12.0.5BAD'},events:es}),'PATCH_BUILD');
 throws(()=>analyzeCohort({context:{...c,recipeSpellID:1.5},events:es}),'RECIPE_RANK');
 throws(()=>analyzeCohort({context:{...c,inputItemID:999},events:es}),'TARGET_IDENTITY');
 throws(()=>analyzeCohort({context:{...c,professionContext:{...c.professionContext,gear:[NaN]}},events:es}),'UNSAFE_CONTEXT');
 throws(()=>analyzeCohort({context:c,events:[...es,{...es[0]}]}),'CAST_ID');
 throws(()=>analyzeCohort({context:c,events:[{castID:'a',status:'ABORTED',outputCount:0}]}),'ABORTED_HAS_OUTPUT');
 throws(()=>analyzeCohort({context:c,events:[{castID:'a',status:'COMPLETED',outputCount:0,refundedInputUnits:6}]}),'COUNT_REFUND');
 throws(()=>analyzeCohort({context:c,events:[{castID:'a',status:'ABORTED'}]}),'NO_VALID_CASTS');
 throws(()=>compareEpochs(a,analyzeCohort({context:{...post,professionSkill:2},events:es})),'PROFILE_MISMATCH');
 throws(()=>compareEpochs(a,analyzeCohort({context:{...post,sourceLineage:'synthetic-pre'},events:es})),'DUPLICATE_SOURCE_LINEAGE');
 throws(()=>compareEpochs(a,analyzeCohort({context:{...post,studyFamilyID:'synthetic-pre'},events:es})),'DUPLICATE_STUDY_FAMILY');
 throws(()=>compareEpochs(a,a),'CROSS_EPOCH_PAIR');
 throws(()=>compareEpochs(a,analyzeCohort({context:{...post,sourceType:'SYNTHETIC'},events:es})),'RAW_PAIR_REQUIRED');
 eq(a.contextSnapshot.professionSkill,1);c.professionSkill=99;eq(a.contextSnapshot.professionSkill,1);
 const arrayContext=arr=>({...c,professionContext:{...c.professionContext,specialization:arr}});
 const symbolArray=[];symbolArray[Symbol('trait')]='hidden';
 throws(()=>analyzeCohort({context:arrayContext(symbolArray),events:es}),'UNSAFE_CONTEXT');
 const hiddenArray=[];Object.defineProperty(hiddenArray,'trait',{value:'hidden'});
 throws(()=>analyzeCohort({context:arrayContext(hiddenArray),events:es}),'UNSAFE_CONTEXT');
 const sparseArray=['a',,'c'];sparseArray.extra='hidden';
 throws(()=>analyzeCohort({context:arrayContext(sparseArray),events:es}),'UNSAFE_CONTEXT');
 class CustomArray extends Array{toJSON(){return ['changed'];}}
 throws(()=>analyzeCohort({context:arrayContext(new CustomArray('original')),events:es}),'UNSAFE_CONTEXT');
 const customSerializer=['original'];Object.defineProperty(customSerializer,'toJSON',{value(){return ['changed'];}});
 throws(()=>analyzeCohort({context:arrayContext(customSerializer),events:es}),'UNSAFE_CONTEXT');
 const accessorArray=['original'];Object.defineProperty(accessorArray,'0',{get(){return 'changed';},enumerable:true,configurable:true});
 throws(()=>analyzeCohort({context:arrayContext(accessorArray),events:es}),'UNSAFE_CONTEXT');
 const objectSerializer={...c.professionContext,toJSON(){return {specialization:[]};}};
 throws(()=>analyzeCohort({context:{...c,professionContext:objectSerializer},events:es}),'UNSAFE_CONTEXT');
 const validDense=analyzeCohort({context:arrayContext(['trait','gear']),events:es});
 eq(validDense.contextSnapshot.professionContext.specialization,['trait','gear']);
 return {passed,failed:0,syntheticOnly:true};
}
module.exports={MODEL_ID,POLICY,TARGETS,OFFICIAL_ENTRY_DATE,OFFICIAL_SOURCE_URL,classifyEpoch,validateContext,analyzeCohort,compareEpochs,selfTest};
if(require.main===module)console.log(JSON.stringify(selfTest()));
