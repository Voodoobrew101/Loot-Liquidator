'use strict';
// F003 research-only. Anytime-valid *conditional* decision sensitivity for Dragonflight prospecting.
// Not a Retail yield estimator without independently supported caps, full universe, and IID casts.
const assert=require('node:assert/strict');
const {validateContext}=require('./df_prospecting_joint_cast_conflict_v1.js');
const MODEL_ID='df-prospect-sequential-margin-cs-v1.0.0';
const POLICY=Object.freeze({confidence:0,economicUse:'PREVIEW_ONLY',normalizedVerified:false,liveEconomicEligible:false,tooltipOnlyEligible:false});
const TARGETS=Object.freeze(['tsm:prospect:188658:192870:L1205','tsm:prospect:188658:192871:L1206','tsm:prospect:189143:192869:L1242','tsm:prospect:189143:192870:L1243','tsm:prospect:190311:192869:L1280']);
const safeInt=(v,min=0)=>Number.isSafeInteger(v)&&v>=min;
const finiteNonnegative=v=>typeof v==='number'&&Number.isFinite(v)&&v>=0;
function need(ok,code){if(!ok)throw Error(code)}
function checked(v){need(Number.isFinite(v),'NONFINITE_ARITHMETIC');return v}
function keyLineage(v){return typeof v==='string'?v.trim().toLowerCase():''}
function analyze({context,events,sourceType='SYNTHETIC',caps=null,priceSnapshot=null,alpha=0.05}){
 validateContext(context);
 need(['SYNTHETIC','RAW_CURRENT_RETAIL'].includes(sourceType),'SOURCE_TYPE');
 if(sourceType==='RAW_CURRENT_RETAIL')need(/^\d+\.\d+\.\d+(?:\.\d+)?$/.test(context.patchBuild),'BUILD_REQUIRED');
 need(Array.isArray(events)&&events.length>0,'EVENTS');
 need(typeof alpha==='number'&&Number.isFinite(alpha)&&alpha>0&&alpha<1,'ALPHA');
 const ids=context.outputItemIDs,seen=new Set(),casts=[];let aborted=0;
 for(const e of events){
  need(e&&typeof e.castID==='string'&&e.castID.trim()&&!seen.has(e.castID),'CAST_ID');seen.add(e.castID);
  need(e.status==='COMPLETED'||e.status==='ABORTED','STATUS');
  if(e.status==='ABORTED'){need(!Object.hasOwn(e,'outputs')&&!Object.hasOwn(e,'refundedInputUnits'),'ABORTED_DATA');aborted++;continue}
  need(safeInt(e.refundedInputUnits)&&e.refundedInputUnits<=context.nominalInputPerCast,'REFUND');
  need(e.outputs&&typeof e.outputs==='object'&&!Array.isArray(e.outputs)&&Object.keys(e.outputs).length===ids.length&&ids.every(id=>Object.hasOwn(e.outputs,id)&&safeInt(e.outputs[id])),'COMPLETE_ZERO_INCLUSIVE_OUTPUTS');
  casts.push({outputs:ids.map(id=>e.outputs[id]),refund:e.refundedInputUnits});
 }
 need(casts.length>0,'NO_COMPLETED_CASTS');
 const n=casts.length;
 const sampleE=ids.map((id,j)=>checked(casts.reduce((s,c)=>checked(s+c.outputs[j]),0)/n));
 const sampleP=ids.map((id,j)=>casts.filter(c=>c.outputs[j]>0).length/n);
 const gross=checked(n*context.nominalInputPerCast),refunds=checked(casts.reduce((s,c)=>s+c.refund,0));
 const descriptive={modelID:MODEL_ID,contextSnapshot:JSON.parse(JSON.stringify(context)),sourceType,
  completedCasts:n,abortedRequests:aborted,nominalGrossInput:gross,refundedInput:refunds,netConsumedInput:checked(gross-refunds),
  sampleUnconditionalE:sampleE,sampleP,outputItemIDs:ids.slice(),
  uncertaintyStatement:'Conditional IID bounded-cast inference only; sample means are not independently verified Retail rates',
  independentHoldout:'NOT_PERFORMED',...POLICY};
 // Unsupported cap or incomplete independent universe must never generate a finite statistical margin interval.
 const capOK=caps&&caps.status==='INDEPENDENTLY_REVIEWED'&&keyLineage(caps.sourceLineage)&&
  keyLineage(caps.sourceLineage)!==keyLineage(context.sourceLineage)&&
  Array.isArray(caps.outputs)&&caps.outputs.length===ids.length&&
  new Set(caps.outputs.map(o=>o&&o.outputItemID)).size===ids.length&&
  ids.every(id=>caps.outputs.some(o=>o&&o.outputItemID===id&&safeInt(o.maxPerCast)&&o.maxPerCast>=0&&
   o.outputQualityRank===context.outputQualityRanks[id]));
 const universeOK=context.outputUniverseVerified===true&&caps&&caps.outputUniverseIndependentlyReviewed===true;
 if(!capOK||!universeOK)return {...descriptive,statisticalStatus:'BLOCKED_UNVERIFIED_CAP_OR_OUTPUT_UNIVERSE',
  sampleMeanMargin:null,anytimeMarginInterval:null,decision:'NOT_IDENTIFIED',capReviewCallerAttested:false};
 const capMap=new Map(caps.outputs.map(o=>[o.outputItemID,o.maxPerCast]));
 for(const c of casts)ids.forEach((id,j)=>need(c.outputs[j]<=capMap.get(id),'OBSERVATION_EXCEEDS_CAP'));
 if(!priceSnapshot)return {...descriptive,statisticalStatus:'BLOCKED_NO_FIXED_PRICE_SNAPSHOT',
  sampleMeanMargin:null,anytimeMarginInterval:null,decision:'NOT_IDENTIFIED',capReviewCallerAttested:true};
 need(priceSnapshot&&typeof priceSnapshot.sourceID==='string'&&priceSnapshot.sourceID.trim()&&
  typeof priceSnapshot.observedAt==='string'&&priceSnapshot.observedAt.trim()&&
  finiteNonnegative(priceSnapshot.inputUnitPrice)&&finiteNonnegative(priceSnapshot.auctionCut)&&priceSnapshot.auctionCut<1&&
  finiteNonnegative(priceSnapshot.depositPerCast)&&priceSnapshot.outputUnitPrices&&
  Object.keys(priceSnapshot.outputUnitPrices).length===ids.length&&ids.every(id=>finiteNonnegative(priceSnapshot.outputUnitPrices[id])),'PRICE_SNAPSHOT');
 const revenueCap=checked(ids.reduce((s,id)=>checked(s+checked(capMap.get(id)*priceSnapshot.outputUnitPrices[id]*(1-priceSnapshot.auctionCut))),0));
 const low=checked(-context.nominalInputPerCast*priceSnapshot.inputUnitPrice-priceSnapshot.depositPerCast);
 const high=checked(revenueCap-priceSnapshot.depositPerCast);
 need(high>=low,'MARGIN_RANGE');
 const margins=casts.map(c=>checked(c.outputs.reduce((s,q,j)=>checked(s+checked(q*priceSnapshot.outputUnitPrices[ids[j]]*(1-priceSnapshot.auctionCut))),0)-
  checked((context.nominalInputPerCast-c.refund)*priceSnapshot.inputUnitPrice)-priceSnapshot.depositPerCast));
 const mean=checked(margins.reduce((s,v)=>checked(s+v),0)/n);
 const radius=checked((high-low)*Math.sqrt(Math.log(2*n*(n+1)/alpha)/(2*n)));
 const interval=[Math.max(low,mean-radius),Math.min(high,mean+radius)];
 need(interval[0]<=interval[1],'INVALID_INTERVAL');
 return {...descriptive,statisticalStatus:'CONDITIONAL_IID_BOUNDED_CASTS',
  capReviewCallerAttested:true,capSourceLineage:caps.sourceLineage,
  priceSnapshotID:priceSnapshot.sourceID,priceObservedAt:priceSnapshot.observedAt,
  sampleMeanMargin:mean,perCastMarginRange:[low,high],anytimeMarginInterval:interval,
  confidenceSequenceAlpha:alpha,lookNumber:n,
  decision:interval[0]>0?'PROCESSING_POSITIVE_CONDITIONAL':interval[1]<0?'PROCESSING_NEGATIVE_CONDITIONAL':'UNRESOLVED_CONDITIONAL',
  assumptionWarnings:['Independent cap/universe review is caller-attested, not verified by this code','IID fixed-context casts and fixed prices required','Optional stopping union-bound over all n; no current-Retail promotion'],...POLICY};
}
function selfTest(){
 let passed=0;const eq=(a,b)=>{assert.deepEqual(a,b);passed++};const bad=(f,code)=>{assert.throws(f,new RegExp(code));passed++};
 const context={gameMode:'RETAIL',expansion:'DRAGONFLIGHT',method:'PROSPECT',patchBuild:'10.2.7',observationEpoch:'2026-10-01T00:00:00Z',
  studyFamilyID:'synthetic-study',sourceLineage:'synthetic-casts',inputItemID:188658,inputQualityRank:1,recipeSpellID:382981,
  nominalInputPerCast:5,directReagents:[{itemID:188658,quantity:5}],minimumEligibleSkill:1,professionSkill:1,
  professionContext:{specialization:[],gear:[],unlocks:[],resourcefulnessPercent:0},outputItemIDs:[192870,192871],outputQualityRanks:{192870:1,192871:2},outputUniverseVerified:true};
 const events=[{castID:'a',status:'COMPLETED',refundedInputUnits:0,outputs:{192870:0,192871:0}},
 {castID:'b',status:'COMPLETED',refundedInputUnits:1,outputs:{192870:2,192871:1}},
 {castID:'c',status:'ABORTED'}];
 const caps={status:'INDEPENDENTLY_REVIEWED',sourceLineage:'independent-cap-source',outputUniverseIndependentlyReviewed:true,
  outputs:[{outputItemID:192870,outputQualityRank:1,maxPerCast:2},{outputItemID:192871,outputQualityRank:2,maxPerCast:1}]};
 const priceSnapshot={sourceID:'synthetic-price',observedAt:'2026-10-01T00:00:00Z',inputUnitPrice:1,auctionCut:0,depositPerCast:0,outputUnitPrices:{192870:5,192871:2}};
 const a=analyze({context,events});eq(a.completedCasts,2);eq(a.abortedRequests,1);eq(a.sampleP,[.5,.5]);eq(a.sampleUnconditionalE,[1,.5]);
 eq(a.nominalGrossInput,10);eq(a.refundedInput,1);eq(a.netConsumedInput,9);eq(a.anytimeMarginInterval,null);eq(a.decision,'NOT_IDENTIFIED');
 const b=analyze({context,events,caps,priceSnapshot});eq(b.perCastMarginRange,[-5,12]);eq(b.sampleMeanMargin,1.5);
 eq(b.statisticalStatus,'CONDITIONAL_IID_BOUNDED_CASTS');eq(b.decision,'UNRESOLVED_CONDITIONAL');eq(b.economicUse,'PREVIEW_ONLY');
 eq(b.normalizedVerified,false);eq(b.confidence,0);eq(b.anytimeMarginInterval[0],-5);eq(b.anytimeMarginInterval[1],12);
 eq(analyze({context,events,caps}).statisticalStatus,'BLOCKED_NO_FIXED_PRICE_SNAPSHOT');
 eq(analyze({context,events,caps:{...caps,sourceLineage:'synthetic-casts'},priceSnapshot}).statisticalStatus,'BLOCKED_UNVERIFIED_CAP_OR_OUTPUT_UNIVERSE');
 eq(analyze({context,events,caps:{...caps,outputUniverseIndependentlyReviewed:false},priceSnapshot}).statisticalStatus,'BLOCKED_UNVERIFIED_CAP_OR_OUTPUT_UNIVERSE');
 bad(()=>analyze({context,events:[...events,events[0]]}),'CAST_ID');
 bad(()=>analyze({context,events:[{castID:'x',status:'COMPLETED',outputs:{192870:1},refundedInputUnits:0}]}),'COMPLETE_ZERO_INCLUSIVE_OUTPUTS');
 bad(()=>analyze({context,events:[{castID:'x',status:'COMPLETED',outputs:{192870:3,192871:0},refundedInputUnits:0}],caps,priceSnapshot}),'OBSERVATION_EXCEEDS_CAP');
 bad(()=>analyze({context,events:[{castID:'x',status:'ABORTED',outputs:{}}]}),'ABORTED_DATA');
 bad(()=>analyze({context,events,alpha:0}),'ALPHA');
 bad(()=>analyze({context,events,caps,priceSnapshot:{...priceSnapshot,inputUnitPrice:-1}}),'PRICE_SNAPSHOT');
 bad(()=>analyze({context,events,caps,priceSnapshot:{...priceSnapshot,outputUnitPrices:{192870:Infinity,192871:2}}}),'PRICE_SNAPSHOT');
 bad(()=>analyze({context,events,caps,priceSnapshot:{...priceSnapshot,outputUnitPrices:{192870:1e308,192871:1e308}}}),'NONFINITE_ARITHMETIC');
 bad(()=>analyze({context:{...context,outputUniverseVerified:false},events}),'OUTPUT_UNIVERSE_UNVERIFIED');
 return {modelID:MODEL_ID,passed,failed:0,syntheticOnly:true};
}
module.exports={MODEL_ID,POLICY,TARGETS,analyze,selfTest};
if(require.main===module)console.log(JSON.stringify(selfTest()));
