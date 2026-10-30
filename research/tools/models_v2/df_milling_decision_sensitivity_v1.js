'use strict';
// F003 research-only Dragonflight milling decision-sensitivity model; never live EV.
const assert=require('node:assert/strict');
const MODEL_ID='df-milling-decision-sensitivity-v1.0.1';
const POLICY=Object.freeze({confidence:0,economicUse:'PREVIEW_ONLY',normalizedVerified:false,liveEconomicEligible:false,tooltipOnlyEligible:false});
const tuples=[
[191469,198412,1975],[191469,198413,1976],[191469,198414,1977],
[191470,198415,1980],[191470,198416,1981],[191470,198417,1982],
[191471,198415,1985],[191471,198416,1986],[191471,198417,1987],
[191472,198415,1990],[191472,198416,1991],[191472,198417,1992],
[200061,198412,1998],[200061,198413,1999],[200061,198414,2000],
[200061,198415,2001],[200061,198416,2002],[200061,198417,2003],
[200061,198418,2004],[200061,198419,2005],[200061,198420,2006],
[200061,198421,2007],[200061,198422,2008],[200061,198423,2009]];
const TARGETS=Object.freeze(tuples.map(t=>'tsm:mill:'+t[0]+':'+t[1]+':L'+t[2]));
function check(x,msg){if(!x)throw Error(msg);}
function nonneg(x){return typeof x==='number'&&Number.isFinite(x)&&x>=0;}
function integer(x,min=0){return Number.isSafeInteger(x)&&x>=min;}
function bounds(x,label){check(Array.isArray(x)&&x.length===2&&x.every(nonneg)&&x[0]<=x[1],'INVALID_'+label);return x;}
function keyFor(i,o){return TARGETS.find(k=>k.startsWith('tsm:mill:'+i+':'+o+':L'))||null;}
function validateContext(c){
 check(c&&integer(c.inputItemID,1)&&Array.isArray(c.outputItemIDs)&&c.outputItemIDs.length>0,'IDENTITY_REQUIRED');
 check(c.outputItemIDs.every(id=>integer(id,1)&&keyFor(c.inputItemID,id))&&new Set(c.outputItemIDs).size===c.outputItemIDs.length,'UNTRACKED_OR_DUPLICATE_OUTPUT');
 check(typeof c.patchBuild==='string'&&c.patchBuild&&typeof c.studyFamilyID==='string'&&c.studyFamilyID,'PATCH_AND_LINEAGE_REQUIRED');
 check(integer(c.nominalInputUnits,1),'NOMINAL_INPUT_REQUIRED');
 check(c.professionContext&&typeof c.professionContext==='object','PROFESSION_CONTEXT_REQUIRED');
 for(const k of ['skill','specialization','gear','resourcefulness','unlocks','recipeSpellID'])
   check(Object.prototype.hasOwnProperty.call(c.professionContext,k),'MISSING_CONTEXT_'+k);
}
// A caller-asserted output universe is a required research decision gate,
// not independent proof of eligibility. Never infer omitted outputs as zeros.
function validateRawContext(c){
 check(c.gameMode==='RETAIL','RAW_GAME_MODE_REQUIRED');
 check(typeof c.actualObservationEpoch==='string'&&/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$/.test(c.actualObservationEpoch)&&Number.isFinite(Date.parse(c.actualObservationEpoch)),'RAW_OBSERVATION_EPOCH_REQUIRED');
 check(integer(c.inputQualityRank,1),'RAW_INPUT_QUALITY_RANK_REQUIRED');
 check(c.outputQualityRanks&&typeof c.outputQualityRanks==='object'&&!Array.isArray(c.outputQualityRanks)&&Object.keys(c.outputQualityRanks).length===c.outputItemIDs.length&&c.outputItemIDs.every(id=>integer(c.outputQualityRanks[id],1)),'RAW_OUTPUT_QUALITY_RANKS_REQUIRED');
 check(Array.isArray(c.directReagents)&&c.directReagents.length>0&&c.directReagents.every(r=>r&&integer(r.itemID,1)&&integer(r.quantity,1))&&new Set(c.directReagents.map(r=>r.itemID)).size===c.directReagents.length,'RAW_DIRECT_REAGENT_VECTOR_REQUIRED');
 const primary=c.directReagents.filter(r=>r.itemID===c.inputItemID);
 check(primary.length===1&&primary[0].quantity===c.nominalInputUnits,'RAW_PRIMARY_REAGENT_COUNT_MISMATCH');
 check(integer(c.minimumRecipeSkill,1),'RAW_MINIMUM_RECIPE_SKILL_REQUIRED');
 check(integer(c.professionContext.skill,c.minimumRecipeSkill),'RAW_PROFESSION_SKILL_REQUIRED');
 check(nonneg(c.professionContext.resourcefulness),'RAW_RESOURCEFULNESS_NUMERIC_REQUIRED');
 check(c.outputUniverseVerified===true,'RAW_OUTPUT_UNIVERSE_UNVERIFIED');
}
function historicalRateScenarios({rate,reportedUnit,nominalInputUnits,sourceLineage}){
 check(nonneg(rate)&&integer(nominalInputUnits,1)&&typeof sourceLineage==='string'&&sourceLineage,'RATE_OR_LINEAGE');
 check(['PER_INPUT_UNIT','PER_COMPLETED_CAST','UNKNOWN'].includes(reportedUnit),'UNIT_REQUIRED');
 const scenarios=[];
 if(reportedUnit!=='PER_COMPLETED_CAST')scenarios.push({unit:'PER_INPUT_UNIT',conditionalEPerCast:rate*nominalInputUnits});
 if(reportedUnit!=='PER_INPUT_UNIT')scenarios.push({unit:'PER_COMPLETED_CAST',conditionalEPerCast:rate});
 return {modelID:MODEL_ID,sourceLineage,reportedUnit,scenarios,currentRetailE:null,currentRetailP:null,sourceHistoricalNotMeasuredCurrentRetail:true,...POLICY};
}
function summarizeCasts({context,sourceType,events}){
 validateContext(context);check(['SYNTHETIC','RAW_CURRENT_RETAIL'].includes(sourceType),'SOURCE_TYPE');
 if(sourceType==='RAW_CURRENT_RETAIL'){
  validateRawContext(context);
  check(/^\d+\.\d+\.\d+/.test(context.patchBuild),'EXACT_BUILD_REQUIRED');
  for(const k of ['skill','specialization','gear','resourcefulness','unlocks','recipeSpellID'])
   check(context.professionContext[k]!==null&&context.professionContext[k]!==undefined&&context.professionContext[k]!=='UNKNOWN','UNKNOWN_'+k);
 }
 check(Array.isArray(events)&&events.length>0,'EVENTS_REQUIRED');
 const seen=new Set(),totals={},hits={},mins={},maxs={};let completed=0,aborted=0,refunds=0,zeroCasts=0,coOutputs=0;
 for(const id of context.outputItemIDs){totals[id]=0;hits[id]=0;mins[id]=Infinity;maxs[id]=0;}
 for(const e of events){
  check(e&&typeof e.castID==='string'&&e.castID&&!seen.has(e.castID),'DUPLICATE_CAST');seen.add(e.castID);
  check(['COMPLETED','ABORTED'].includes(e.status),'CAST_STATUS');
  if(e.status==='ABORTED'){check(e.outputs===undefined&&e.refundedInputUnits===undefined,'ABORT_HAS_OUTPUT');aborted++;continue;}
  check(integer(e.refundedInputUnits)&&e.refundedInputUnits<=context.nominalInputUnits,'REFUND_DOMAIN');
  check(e.outputs&&Object.keys(e.outputs).length===context.outputItemIDs.length&&context.outputItemIDs.every(id=>Object.hasOwn(e.outputs,id)),'ZERO_INCLUSIVE_VECTOR');
  completed++;refunds+=e.refundedInputUnits;let positive=0;
  for(const id of context.outputItemIDs){
   const y=e.outputs[id];check(integer(y),'OUTPUT_DOMAIN');totals[id]+=y;
   if(y>0){positive++;hits[id]++;mins[id]=Math.min(mins[id],y);maxs[id]=Math.max(maxs[id],y);}
  }
  if(positive===0)zeroCasts++;if(positive>1)coOutputs++;
 }
 check(completed>0,'NO_COMPLETED_CASTS');
 return {modelID:MODEL_ID,sourceType,studyFamilyID:context.studyFamilyID,completedCasts:completed,abortedRequests:aborted,
  nominalInputUnits:completed*context.nominalInputUnits,refundedInputUnits:refunds,netConsumedInputUnits:completed*context.nominalInputUnits-refunds,
  zeroOutputCasts:zeroCasts,coOutputCasts:coOutputs,
  outputs:context.outputItemIDs.map(id=>({stableKey:keyFor(context.inputItemID,id),outputItemID:id,
   observedDropChance:hits[id]/completed,observedUnconditionalE:totals[id]/completed,
   observedPositiveMin:hits[id]?mins[id]:null,observedPositiveMax:hits[id]?maxs[id]:null,...POLICY})),
  independentHoldout:'NOT_PERFORMED',...POLICY};
}
function decisionSensitivity({context,outputs,prices,inputUnitValue,auctionCut=0.05,refundsPerCast=[0,0],alternativeIncrementalValuePerCast=0,priceEpoch}){
 validateContext(context);check(context.outputUniverseVerified===true,'OUTPUT_UNIVERSE_UNVERIFIED');check(typeof priceEpoch==='string'&&priceEpoch,'PRICE_EPOCH');
 check(nonneg(inputUnitValue)&&nonneg(alternativeIncrementalValuePerCast)&&Number.isFinite(auctionCut)&&auctionCut>=0&&auctionCut<1,'PRICE_OR_CUT');
 bounds(refundsPerCast,'REFUNDS');check(refundsPerCast[1]<=context.nominalInputUnits,'REFUNDS_GT_NOMINAL');
 check(Array.isArray(outputs)&&outputs.length===context.outputItemIDs.length,'COMPLETE_OUTPUT_SET_REQUIRED');
 let low=0,high=0;const seen=new Set(),terms=[];
 for(const o of outputs){
  check(context.outputItemIDs.includes(o.outputItemID)&&!seen.has(o.outputItemID),'OUTPUT_ID');seen.add(o.outputItemID);
  const e=bounds(o.unconditionalEInterval,'E');const p=prices[o.outputItemID];
  check(nonneg(p)&&typeof o.provenance==='string'&&o.provenance,'PRICE_OR_PROVENANCE');
  const a=e[0]*p*(1-auctionCut),b=e[1]*p*(1-auctionCut);low+=a;high+=b;
  terms.push({outputItemID:o.outputItemID,unconditionalEInterval:e,netRevenueInterval:[a,b],provenance:o.provenance});
 }
 const costs=[(context.nominalInputUnits-refundsPerCast[1])*inputUnitValue,(context.nominalInputUnits-refundsPerCast[0])*inputUnitValue];
 const margin=[low-costs[1]-alternativeIncrementalValuePerCast,high-costs[0]-alternativeIncrementalValuePerCast];
 return {modelID:MODEL_ID,priceEpoch,terms,outputRevenueInterval:[low,high],inputOpportunityCostInterval:costs,marginInterval:margin,
  decision:margin[0]>0?'PROCESS_DOMINATES_UNDER_ASSUMPTIONS':margin[1]<0?'ALTERNATIVE_DOMINATES_UNDER_ASSUMPTIONS':'UNRESOLVED_DECISION_BOUNDARY',
  potentialDecisionSwing:margin[1]-margin[0],correlationNotRequiredForLinearExpectedValue:true,
  hypotheticalNotMeasuredGoldImpact:true,requiresIndependentRetailE:true,...POLICY};
}
function selfTest(){
 let n=0;const eq=(a,b)=>{assert.deepEqual(a,b);n++;},ok=x=>{assert.ok(x);n++;},bad=f=>{assert.throws(f);n++;};
 const context={inputItemID:191469,outputItemIDs:[198412,198413,198414],patchBuild:'SYNTHETIC',studyFamilyID:'synthetic',
 nominalInputUnits:5,outputUniverseVerified:true,professionContext:{skill:'UNKNOWN',specialization:'UNKNOWN',gear:'UNKNOWN',resourcefulness:'UNKNOWN',unlocks:'UNKNOWN',recipeSpellID:'UNKNOWN'}};
 eq(TARGETS.length,24);eq(new Set(TARGETS).size,24);ok(keyFor(191469,198412));eq(keyFor(191469,999999),null);
 const h=historicalRateScenarios({rate:.12,reportedUnit:'UNKNOWN',nominalInputUnits:5,sourceLineage:'frozen-tsm-hypothesis'});
 eq(h.scenarios.map(x=>x.conditionalEPerCast),[.6,.12]);eq(h.currentRetailE,null);eq(h.confidence,0);
 bad(()=>historicalRateScenarios({rate:-1,reportedUnit:'UNKNOWN',nominalInputUnits:5,sourceLineage:'x'}));
 const c=(castID,outputs,refundedInputUnits=0)=>({castID,status:'COMPLETED',outputs,refundedInputUnits});
 const events=[c('a',{198412:0,198413:2,198414:1},1),c('b',{198412:0,198413:0,198414:0}),c('c',{198412:1,198413:1,198414:0}),{castID:'abort',status:'ABORTED'}];
 const s=summarizeCasts({context,sourceType:'SYNTHETIC',events});
 eq(s.completedCasts,3);eq(s.abortedRequests,1);eq(s.nominalInputUnits,15);eq(s.netConsumedInputUnits,14);
 eq(s.zeroOutputCasts,1);eq(s.coOutputCasts,2);eq(s.outputs[0].observedUnconditionalE,1/3);eq(s.outputs[1].observedUnconditionalE,1);
 eq(s.outputs[0].observedDropChance,1/3);eq(s.outputs[0].observedPositiveMin,1);eq(s.outputs[0].normalizedVerified,false);
 bad(()=>summarizeCasts({context,sourceType:'RAW_CURRENT_RETAIL',events}));
 bad(()=>summarizeCasts({context,sourceType:'SYNTHETIC',events:[c('x',{198412:1,198413:0})]}));
 bad(()=>summarizeCasts({context,sourceType:'SYNTHETIC',events:[c('x',{198412:0,198413:0,198414:0}),c('x',{198412:0,198413:0,198414:0})]}));
 const args={context,outputs:[{outputItemID:198412,unconditionalEInterval:[.1,.3],provenance:'SYNTHETIC'},
 {outputItemID:198413,unconditionalEInterval:[.2,.4],provenance:'SYNTHETIC'},
 {outputItemID:198414,unconditionalEInterval:[0,.2],provenance:'SYNTHETIC'}],
 prices:{198412:10,198413:5,198414:1},inputUnitValue:1,auctionCut:0,refundsPerCast:[0,1],priceEpoch:'SYNTHETIC'};
 const d=decisionSensitivity(args);
 eq(d.outputRevenueInterval,[2,5.2]);eq(d.inputOpportunityCostInterval,[4,5]);
 ok(Math.abs(d.marginInterval[0]+3)<1e-12&&Math.abs(d.marginInterval[1]-1.2)<1e-12);
 eq(d.decision,'UNRESOLVED_DECISION_BOUNDARY');eq(d.economicUse,'PREVIEW_ONLY');
 eq(decisionSensitivity({...args,inputUnitValue:0}).decision,'PROCESS_DOMINATES_UNDER_ASSUMPTIONS');
 eq(decisionSensitivity({...args,inputUnitValue:10}).decision,'ALTERNATIVE_DOMINATES_UNDER_ASSUMPTIONS');
 bad(()=>decisionSensitivity({...args,outputs:args.outputs.slice(0,2)}));
 bad(()=>decisionSensitivity({...args,refundsPerCast:[0,6]}));
 bad(()=>decisionSensitivity({...args,prices:{198412:10,198413:5}}));
 return {modelID:MODEL_ID,passed:n,failed:0,targetMappings:TARGETS.length,syntheticOnly:true};
}
module.exports={MODEL_ID,POLICY,TARGETS,keyFor,historicalRateScenarios,summarizeCasts,decisionSensitivity,selfTest};
if(require.main===module)console.log(JSON.stringify(selfTest()));
