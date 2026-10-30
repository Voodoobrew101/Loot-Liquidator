'use strict';
// F003 research-only Midnight rare-gem partial-identification model; never live EV.
const assert=require('node:assert/strict');
const MODEL_ID='midnight-rare-gem-anytime-e-bounds-v1.0.0';
const POLICY=Object.freeze({confidence:0,economicUse:'PREVIEW_ONLY',normalizedVerified:false,liveEconomicEligible:false,evidencePromotion:false});
const INPUTS=Object.freeze([237359,237361,237362,237363,237364,237365,237366]);
const OUTPUT=242608;
const TARGETS=Object.freeze(INPUTS.map(i=>'midnight:'+i+':'+OUTPUT+':L'+({237359:733,237361:744,237362:755,237363:766,237364:777,237365:788,237366:799}[i])));
function check(b,msg){if(!b)throw Error(msg);}
function posint(x){return Number.isSafeInteger(x)&&x>0;}
function nonnegint(x){return Number.isSafeInteger(x)&&x>=0;}
function known(x){return x!==null&&x!==undefined&&x!==''&&x!=='UNKNOWN';}
function validateContext(c){
 check(c&&typeof c==='object'&&c.gameMode==='RETAIL','RETAIL_CONTEXT_REQUIRED');
 check(INPUTS.includes(c.inputItemID)&&c.outputItemID===OUTPUT,'TARGET_IDENTITY_REQUIRED');
 check(posint(c.inputQualityRank)&&posint(c.outputQualityRank),'QUALITY_RANK_REQUIRED');
 check(posint(c.nominalInputCountPerCast),'NOMINAL_INPUT_REQUIRED');
 check(Array.isArray(c.directReagents)&&c.directReagents.length>0&&c.directReagents.every(r=>r&&posint(r.itemID)&&posint(r.quantity)),'REAGENTS_REQUIRED');
 check(new Set(c.directReagents.map(r=>r.itemID)).size===c.directReagents.length,'DUPLICATE_REAGENT');
 check(c.directReagents.some(r=>r.itemID===c.inputItemID&&r.quantity===c.nominalInputCountPerCast),'INPUT_REAGENT_MISMATCH');
 check(posint(c.minimumRecipeEligibleSkill)&&posint(c.professionSkill)&&c.professionSkill>=c.minimumRecipeEligibleSkill,'RECIPE_ELIGIBLE_SKILL_REQUIRED');
 check(c.professionContext&&typeof c.professionContext==='object'&&['specialization','gear','unlocks'].every(k=>known(c.professionContext[k])),'PROFESSION_CONTEXT_REQUIRED');
 check(typeof c.professionContext.resourcefulnessPercent==='number'&&Number.isFinite(c.professionContext.resourcefulnessPercent)&&c.professionContext.resourcefulnessPercent>=0&&c.professionContext.resourcefulnessPercent<=100,'RESOURCEFULNESS_PERCENT_REQUIRED');
 check(typeof c.sourceStudyFamilyID==='string'&&c.sourceStudyFamilyID.trim(),'STUDY_LINEAGE_REQUIRED');
 check(['SYNTHETIC','RAW_CURRENT_RETAIL'].includes(c.sourceType),'SOURCE_TYPE_REQUIRED');
 if(c.sourceType==='RAW_CURRENT_RETAIL'){
  check(typeof c.patchBuild==='string'&&/^\d+\.\d+\.\d+(?:[.-][A-Za-z0-9.-]+)?$/.test(c.patchBuild),'EXACT_PATCH_REQUIRED');
  check(posint(c.recipeSpellID),'RECIPE_ID_REQUIRED');
  check(typeof c.observationEpoch==='string'&&/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$/.test(c.observationEpoch)&&Number.isFinite(Date.parse(c.observationEpoch)),'OBSERVATION_EPOCH_REQUIRED');
 }else{
  check(known(c.patchBuild)&&known(c.recipeSpellID)&&known(c.observationEpoch),'SYNTHETIC_CONTEXT_REQUIRED');
 }
}
// Hoeffding + alpha spending: alpha(n,key,metric)=alpha*6/(pi^2*n^2*7*2).
// Union bound over all n>=1, seven keys and P/E metrics is at most alpha.
function width(n,range,alpha){
 check(posint(n)&&typeof range==='number'&&Number.isFinite(range)&&range>=0,'BOUND_DOMAIN');
 check(typeof alpha==='number'&&Number.isFinite(alpha)&&alpha>0&&alpha<1,'ALPHA_DOMAIN');
 return range*Math.sqrt(Math.log((2*Math.PI*Math.PI*n*n*INPUTS.length*2)/(6*alpha))/(2*n));
}
function analyzeCohort({context,events,alpha=0.05,certifiedMaxPerCast=null,capEvidenceID=null}){
 validateContext(context);
 check(Array.isArray(events)&&events.length>0,'EVENTS_REQUIRED');
 check(typeof alpha==='number'&&Number.isFinite(alpha)&&alpha>0&&alpha<1,'ALPHA_DOMAIN');
 if(certifiedMaxPerCast!==null)check(posint(certifiedMaxPerCast)&&typeof capEvidenceID==='string'&&capEvidenceID.trim()&&capEvidenceID!==context.sourceStudyFamilyID,'INDEPENDENT_CAP_CERTIFICATE_REQUIRED');
 else check(capEvidenceID===null,'CAP_WITHOUT_MAX');
 let n=0,aborted=0,success=0,sum=0,refund=0,min=Infinity,max=0;
 const seen=new Set();
 for(const e of events){
  check(e&&typeof e.castID==='string'&&e.castID&&!seen.has(e.castID),'CAST_ID_UNIQUE_REQUIRED');seen.add(e.castID);
  check(e.status==='COMPLETED'||e.status==='ABORTED','CAST_STATUS_REQUIRED');
  if(e.status==='ABORTED'){check(e.outputCount===undefined&&e.refundedInputCount===undefined,'ABORT_HAS_RESULTS');aborted++;continue;}
  check(nonnegint(e.outputCount)&&nonnegint(e.refundedInputCount)&&e.refundedInputCount<=context.nominalInputCountPerCast,'ZERO_INCLUSIVE_OUTPUT_REFUND_REQUIRED');
  if(certifiedMaxPerCast!==null)check(e.outputCount<=certifiedMaxPerCast,'OBSERVED_COUNT_EXCEEDS_CERTIFIED_CAP');
  n++;sum+=e.outputCount;refund+=e.refundedInputCount;
  check(Number.isSafeInteger(sum)&&Number.isSafeInteger(refund)&&Number.isSafeInteger(n*context.nominalInputCountPerCast),'INTEGER_TOTAL_OVERFLOW');
  if(e.outputCount>0){success++;min=Math.min(min,e.outputCount);max=Math.max(max,e.outputCount);}
 }
 check(n>0,'NO_COMPLETED_CASTS');
 const p=success/n,eMean=sum/n,epsP=width(n,1,alpha);
 const pInterval=[Math.max(0,p-epsP),Math.min(1,p+epsP)];
 let eInterval,capStatus;
 if(certifiedMaxPerCast===null){
  eInterval=[pInterval[0],null];capStatus='NO_INDEPENDENT_HARD_CAP_E_UPPER_UNIDENTIFIABLE';
 }else{
  const epsE=width(n,certifiedMaxPerCast,alpha);
  eInterval=[Math.max(0,eMean-epsE,pInterval[0]),Math.min(certifiedMaxPerCast,eMean+epsE,certifiedMaxPerCast*pInterval[1])];
  capStatus='CONDITIONAL_ON_CALLER_SUPPLIED_INDEPENDENT_CAP_AND_IID';
 }
 return {modelID:MODEL_ID,targetKey:TARGETS[INPUTS.indexOf(context.inputItemID)],sourceStudyFamilyID:context.sourceStudyFamilyID,
  sourceType:context.sourceType,completedCasts:n,abortedRequests:aborted,nominalGrossInputs:n*context.nominalInputCountPerCast,
  refundedInputs:refund,netConsumedInputs:n*context.nominalInputCountPerCast-refund,
  zeroOutputCasts:n-success,positiveOutputCasts:success,observedTotalOutput:sum,
  observedDropChance:p,observedUnconditionalExpectedQuantity:eMean,
  observedPositiveYieldMin:success?min:null,observedPositiveYieldMax:success?max:null,
  observedExtremaAreNotHardBounds:true,dropChanceAnytimeInterval:pInterval,expectedQuantityAnytimeInterval:eInterval,
  intervalConfidence:1-alpha,simultaneousTargetKeys:INPUTS.length,metricsPerKey:2,
  anytimeGuarantee:'CONDITIONAL_ON_FIXED_CONTEXT_IID_COMPLETE_ZERO_INCLUSIVE_CASTS_AND_CORRECT_CAP_IF_USED',
  capStatus,certifiedMaxPerCast,capEvidenceID,outputUniverseStatus:'NOT_INDEPENDENTLY_CERTIFIED',
  completeEconomicOutputUniverse:false,independentStudyHoldout:'NOT_PERFORMED',
  ...POLICY};
}
function selfTest(){
 let n=0;const eq=(a,b)=>{assert.deepEqual(a,b);n++},ok=x=>{assert.ok(x);n++},bad=f=>{assert.throws(f);n++};
 const ctx={gameMode:'RETAIL',sourceType:'SYNTHETIC',patchBuild:'SYNTHETIC',recipeSpellID:'SYNTHETIC',observationEpoch:'SYNTHETIC',
 inputItemID:237359,outputItemID:OUTPUT,inputQualityRank:1,outputQualityRank:1,nominalInputCountPerCast:5,
 directReagents:[{itemID:237359,quantity:5}],minimumRecipeEligibleSkill:1,professionSkill:1,
 professionContext:{specialization:'NONE',gear:'NONE',unlocks:'NONE',resourcefulnessPercent:0},sourceStudyFamilyID:'synthetic-fixture'};
 const cast=(castID,outputCount,refundedInputCount=0)=>({castID,status:'COMPLETED',outputCount,refundedInputCount});
 const events=[cast('a',0,1),cast('b',2),cast('c',0),{castID:'abort',status:'ABORTED'}];
 const r=analyzeCohort({context:ctx,events});
 eq(TARGETS.length,7);eq(new Set(TARGETS).size,7);eq(r.targetKey,'midnight:237359:242608:L733');
 eq(r.completedCasts,3);eq(r.abortedRequests,1);eq(r.nominalGrossInputs,15);eq(r.refundedInputs,1);eq(r.netConsumedInputs,14);
 eq(r.zeroOutputCasts,2);eq(r.positiveOutputCasts,1);eq(r.observedUnconditionalExpectedQuantity,2/3);
 eq(r.observedDropChance,1/3);eq(r.observedPositiveYieldMin,2);eq(r.observedPositiveYieldMax,2);
 eq(r.expectedQuantityAnytimeInterval[1],null);eq(r.capStatus,'NO_INDEPENDENT_HARD_CAP_E_UPPER_UNIDENTIFIABLE');
 eq(r.confidence,0);eq(r.economicUse,'PREVIEW_ONLY');eq(r.normalizedVerified,false);eq(r.completeEconomicOutputUniverse,false);
 const b=analyzeCohort({context:ctx,events,certifiedMaxPerCast:3,capEvidenceID:'independent-cap-hypothesis'});
 ok(b.expectedQuantityAnytimeInterval[0]>=0&&b.expectedQuantityAnytimeInterval[1]<=3);
 ok(b.dropChanceAnytimeInterval[0]<=r.observedDropChance&&b.dropChanceAnytimeInterval[1]>=r.observedDropChance);
 const many=Array.from({length:200},(_,i)=>cast('z'+i,0));
 const z=analyzeCohort({context:ctx,events:many});
 ok(z.dropChanceAnytimeInterval[1]<1);eq(z.expectedQuantityAnytimeInterval[1],null);
 ok(width(10000,1,.05)<width(100,1,.05));
 bad(()=>analyzeCohort({context:{...ctx,inputItemID:999},events}));
 bad(()=>analyzeCohort({context:ctx,events:[cast('a',0),cast('a',1)]}));
 bad(()=>analyzeCohort({context:ctx,events:[{castID:'x',status:'COMPLETED',refundedInputCount:0}]}));
 bad(()=>analyzeCohort({context:ctx,events:[{castID:'x',status:'ABORTED',outputCount:0}]}));
 bad(()=>analyzeCohort({context:ctx,events:[cast('x',0,6)]}));
 bad(()=>analyzeCohort({context:ctx,events:[cast('x',4)],certifiedMaxPerCast:3,capEvidenceID:'other'}));
 bad(()=>analyzeCohort({context:ctx,events,certifiedMaxPerCast:3,capEvidenceID:ctx.sourceStudyFamilyID}));
 bad(()=>analyzeCohort({context:ctx,events,capEvidenceID:'orphan'}));
 bad(()=>analyzeCohort({context:ctx,events,alpha:1}));
 bad(()=>analyzeCohort({context:{...ctx,professionContext:{...ctx.professionContext,resourcefulnessPercent:101}},events}));
 bad(()=>analyzeCohort({context:{...ctx,directReagents:[{itemID:237359,quantity:4}]},events}));
 const raw={...ctx,sourceType:'RAW_CURRENT_RETAIL',patchBuild:'12.0.0',recipeSpellID:12345,observationEpoch:'2026-10-29T20:00:00Z'};
 eq(analyzeCohort({context:raw,events}).sourceType,'RAW_CURRENT_RETAIL');
 bad(()=>analyzeCohort({context:{...raw,recipeSpellID:'banana'},events}));
 bad(()=>analyzeCohort({context:{...raw,observationEpoch:'UNKNOWN'},events}));
 bad(()=>analyzeCohort({context:{...raw,professionSkill:0},events}));
 return {modelID:MODEL_ID,passed:n,failed:0,syntheticOnly:true,targetKeys:TARGETS.length};
}
module.exports={MODEL_ID,POLICY,TARGETS,width,validateContext,analyzeCohort,selfTest};
if(require.main===module)console.log(JSON.stringify(selfTest()));
