'use strict';
// F003 research-only TWW milling aggregate-denominator partial-identification.
// No live-E, recipe eligibility or confidence promotion.
const assert=require('node:assert/strict');
const MODEL_ID='tww-milling-aggregate-denominator-bounds-v1.0.0';
const POLICY=Object.freeze({confidence:0,economicUse:'PREVIEW_ONLY',normalizedVerified:false,liveEconomicEligible:false,evidencePromotion:false});
const TARGETS=Object.freeze([
'historical:tww:mill:210796:222619:reddit-1fdmzwy-2024',
'historical:tww:mill:210797:222619:reddit-1fdmzwy-2024',
'candidate:tww:mill:210798:222618:runtime-method-family:20261028',
'candidate:tww:mill:210799:222612:runtime-method-family:20261028',
'candidate:tww:mill:210800:222613:runtime-method-family:20261028',
'candidate:tww:mill:210801:222614:runtime-method-family:20261028',
'candidate:tww:mill:210802:224800:runtime-method-family:20261028',
'candidate:tww:mill:210803:224801:runtime-method-family:20261028',
'candidate:tww:mill:210804:224802:runtime-method-family:20261028',
'candidate:tww:mill:210805:224803:runtime-method-family:20261028',
'candidate:tww:mill:210806:224804:runtime-method-family:20261028',
'candidate:tww:mill:210807:224805:runtime-method-family:20261028']);
function check(x,msg){if(!x)throw Error(msg);}
function posint(x){return Number.isSafeInteger(x)&&x>0;}
function nonnegint(x){return Number.isSafeInteger(x)&&x>=0;}
function rank(x){return x==='UNKNOWN'||posint(x);}
function analyzeAggregate(a){
 check(a&&TARGETS.includes(a.targetKey),'TARGET_KEY_REQUIRED');
 check(a.sourceType==='SYNTHETIC'||a.sourceType==='HISTORICAL_AGGREGATE','SOURCE_TYPE_REQUIRED');
 check(typeof a.sourceStudyFamilyID==='string'&&a.sourceStudyFamilyID.trim(),'LINEAGE_REQUIRED');
 check(typeof a.observationEpoch==='string'&&a.observationEpoch.trim(),'OBSERVATION_EPOCH_REQUIRED');
 check(a.rankContext&&rank(a.rankContext.inputRank)&&rank(a.rankContext.outputRank),'RANK_CONTEXT_REQUIRED');
 check(posint(a.nominalInputCountPerCast)&&posint(a.reportedInputUnits)&&nonnegint(a.totalOutputUnits),'AGGREGATE_UNITS_REQUIRED');
 check(a.zeroInclusiveTotals===true,'ZERO_INCLUSIVE_TOTALS_REQUIRED');
 check(['GROSS_COMPLETED_CAST_INPUTS','NET_CONSUMED_INPUTS'].includes(a.inputAccounting),'ACCOUNTING_UNIT_REQUIRED');
 let minCasts,maxCasts,refundStatus;
 if(a.inputAccounting==='GROSS_COMPLETED_CAST_INPUTS'){
  check(a.reportedInputUnits%a.nominalInputCountPerCast===0,'GROSS_NOT_EXACT_COMPLETED_CAST_MULTIPLE');
  minCasts=maxCasts=a.reportedInputUnits/a.nominalInputCountPerCast;
  refundStatus='GROSS_CAST_COUNT_IDENTIFIED_REFUNDS_NOT_NEEDED_FOR_DENOMINATOR';
 }else{
  minCasts=Math.ceil(a.reportedInputUnits/a.nominalInputCountPerCast);
  if(a.maxRefundPerCast===null){
   maxCasts=null;refundStatus='REFUND_MAX_UNKNOWN_CAST_COUNT_NOT_UPPER_BOUNDED';
  }else{
   check(nonnegint(a.maxRefundPerCast)&&a.maxRefundPerCast<a.nominalInputCountPerCast,'MAX_REFUND_DOMAIN');
   maxCasts=Math.floor(a.reportedInputUnits/(a.nominalInputCountPerCast-a.maxRefundPerCast));
   check(maxCasts>=minCasts,'NO_FEASIBLE_CAST_COUNT');
   refundStatus='CONDITIONAL_ON_CALLER_ASSERTED_REFUND_MAX';
  }
 }
 check(posint(minCasts)&&(!maxCasts||posint(maxCasts)),'CAST_DENOMINATOR_DOMAIN');
 const lower=maxCasts===null?0:a.totalOutputUnits/maxCasts;
 const upper=a.totalOutputUnits/minCasts;
 return {modelID:MODEL_ID,targetKey:a.targetKey,sourceStudyFamilyID:a.sourceStudyFamilyID,
  sourceType:a.sourceType,observationEpoch:a.observationEpoch,rankContext:a.rankContext,
  reportedInputUnits:a.reportedInputUnits,inputAccounting:a.inputAccounting,nominalInputCountPerCast:a.nominalInputCountPerCast,
  completedCastCountInterval:[minCasts,maxCasts],historicalUnconditionalEPerCastInterval:[lower,upper],
  zeroInclusiveTotalOutputUnits:a.totalOutputUnits,refundStatus,
  actualCompletedCasts:maxCasts===minCasts?minCasts:null,
  observedOccurrenceP:null,observedPositiveYieldMin:null,observedPositiveYieldMax:null,
  currentRetailExpectedQuantity:null,currentRetailDropChance:null,independentHoldout:'NOT_PERFORMED',
  inverseIdentifiability:maxCasts===null?'NOT_IDENTIFIABLE_WITHOUT_REFUND_MAX':maxCasts===minCasts?'CAST_DENOMINATOR_IDENTIFIED_CONDITIONALLY':'PARTIALLY_IDENTIFIED',
  qualityRankTransferAllowed:false,recipeEligibilityVerified:false,
  ...POLICY};
}
function selfTest(){
 let n=0;const eq=(x,y)=>{assert.deepEqual(x,y);n++},ok=x=>{assert.ok(x);n++},bad=f=>{assert.throws(f);n++};
 const base={targetKey:TARGETS[0],sourceType:'SYNTHETIC',sourceStudyFamilyID:'synthetic-study',
 observationEpoch:'SYNTHETIC',rankContext:{inputRank:'UNKNOWN',outputRank:'UNKNOWN'},
 nominalInputCountPerCast:10,reportedInputUnits:100,totalOutputUnits:20,
 zeroInclusiveTotals:true,inputAccounting:'NET_CONSUMED_INPUTS',maxRefundPerCast:2};
 const x=analyzeAggregate(base);
 eq(TARGETS.length,12);eq(new Set(TARGETS).size,12);
 eq(x.completedCastCountInterval,[10,12]);eq(x.historicalUnconditionalEPerCastInterval,[20/12,2]);
 eq(x.actualCompletedCasts,null);eq(x.currentRetailExpectedQuantity,null);eq(x.observedOccurrenceP,null);
 eq(x.confidence,0);eq(x.economicUse,'PREVIEW_ONLY');eq(x.normalizedVerified,false);
 const y=analyzeAggregate({...base,inputAccounting:'GROSS_COMPLETED_CAST_INPUTS',maxRefundPerCast:null});
 eq(y.completedCastCountInterval,[10,10]);eq(y.historicalUnconditionalEPerCastInterval,[2,2]);
 eq(y.actualCompletedCasts,10);
 const z=analyzeAggregate({...base,maxRefundPerCast:null});
 eq(z.completedCastCountInterval,[10,null]);eq(z.historicalUnconditionalEPerCastInterval,[0,2]);
 eq(z.inverseIdentifiability,'NOT_IDENTIFIABLE_WITHOUT_REFUND_MAX');
 const t=analyzeAggregate({...base,reportedInputUnits:19,totalOutputUnits:5,maxRefundPerCast:2});
 eq(t.completedCastCountInterval,[2,2]);eq(t.historicalUnconditionalEPerCastInterval,[2.5,2.5]);
 const zero=analyzeAggregate({...base,totalOutputUnits:0});
 eq(zero.historicalUnconditionalEPerCastInterval,[0,0]);
 bad(()=>analyzeAggregate({...base,targetKey:'invented'}));
 bad(()=>analyzeAggregate({...base,sourceStudyFamilyID:''}));
 bad(()=>analyzeAggregate({...base,zeroInclusiveTotals:false}));
 bad(()=>analyzeAggregate({...base,nominalInputCountPerCast:0}));
 bad(()=>analyzeAggregate({...base,reportedInputUnits:0}));
 bad(()=>analyzeAggregate({...base,totalOutputUnits:-1}));
 bad(()=>analyzeAggregate({...base,maxRefundPerCast:10}));
 bad(()=>analyzeAggregate({...base,maxRefundPerCast:-1}));
 bad(()=>analyzeAggregate({...base,maxRefundPerCast:0,reportedInputUnits:19}));
 bad(()=>analyzeAggregate({...base,inputAccounting:'GROSS_COMPLETED_CAST_INPUTS',reportedInputUnits:101}));
 bad(()=>analyzeAggregate({...base,inputAccounting:'UNKNOWN'}));
 bad(()=>analyzeAggregate({...base,rankContext:{inputRank:0,outputRank:1}}));
 bad(()=>analyzeAggregate({...base,sourceType:'RAW_CURRENT_RETAIL'}));
 ok(analyzeAggregate({...base,targetKey:TARGETS[11]}).targetKey===TARGETS[11]);
 return {modelID:MODEL_ID,passed:n,failed:0,targetKeys:TARGETS.length,syntheticOnly:true};
}
module.exports={MODEL_ID,POLICY,TARGETS,analyzeAggregate,selfTest};
if(require.main===module)console.log(JSON.stringify(selfTest()));
