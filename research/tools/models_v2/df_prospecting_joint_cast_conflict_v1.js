'use strict';
// F003 research-only. Dragonflight prospecting joint-cast sensitivity and historical source conflict.
// No mapping admission, production EV, recipe eligibility, or independent evidence promotion.
const assert=require('node:assert/strict');
const MODEL_ID='df-prospecting-joint-cast-conflict-v1.0.2';
const POLICY=Object.freeze({confidence:0,economicUse:'PREVIEW_ONLY',normalizedVerified:false,liveEconomicEligible:false,tooltipOnlyEligible:false});
const TARGETS=Object.freeze(['tsm:prospect:188658:192870:L1205','tsm:prospect:188658:192871:L1206','tsm:prospect:189143:192869:L1242','tsm:prospect:189143:192870:L1243','tsm:prospect:190311:192869:L1280']);
const int=(x,min=0)=>Number.isSafeInteger(x)&&x>=min;
const nn=x=>typeof x==='number'&&Number.isFinite(x)&&x>=0;
function hasSerializationHook(value){
 for(let proto=value;proto!==null;proto=Object.getPrototypeOf(proto)){
  if(Object.getOwnPropertyDescriptor(proto,'toJSON'))return true;
 }
 return false;
}
function jsonSafe(value,ancestors=new Set()){
 if(value===null||typeof value==='string'||typeof value==='boolean')return true;
 if(typeof value==='number')return Number.isFinite(value);
 if(typeof value!=='object'||ancestors.has(value)||hasSerializationHook(value))return false;
 ancestors.add(value);
 let valid=false;
 if(Array.isArray(value)){
  // Only dense, ordinary arrays with native length and own enumerable data indices.
  // Reflect.ownKeys catches hidden non-enumerable and Symbol metadata that JSON drops.
  const keys=Reflect.ownKeys(value),length=value.length;
  valid=Object.getPrototypeOf(value)===Array.prototype&&
   Number.isSafeInteger(length)&&keys.length===length+1&&keys.includes('length');
  if(valid)for(let i=0;i<length;i++){
   const descriptor=Object.getOwnPropertyDescriptor(value,String(i));
   if(!descriptor||!descriptor.enumerable||!Object.hasOwn(descriptor,'value')||
      !jsonSafe(descriptor.value,ancestors)){valid=false;break}
  }
 }else if(Object.getPrototypeOf(value)===Object.prototype||Object.getPrototypeOf(value)===null){
  valid=Reflect.ownKeys(value).every(k=>{
   if(typeof k!=='string')return false;
   const descriptor=Object.getOwnPropertyDescriptor(value,k);
   return descriptor&&descriptor.enumerable&&Object.hasOwn(descriptor,'value')&&
    jsonSafe(descriptor.value,ancestors);
  });
 }
 ancestors.delete(value);return valid;
}
function checked(value,code='NONFINITE_OR_UNSAFE_RESULT'){
 requireThat(jsonSafe(value),code);return value;
}
function requireThat(x,code){if(!x)throw Error(code)}
function interval(x,code){requireThat(Array.isArray(x)&&x.length===2&&x.every(nn)&&x[0]<=x[1],code);return x}
function validEpoch(s){
 const m=typeof s==='string'&&/^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(?:\.\d+)?(Z|[+-]\d\d:\d\d)$/.exec(s);
 if(!m)return false;
 const [y,mo,d,h,mi,se]=m.slice(1,7).map(Number);
 const z=m[7],zh=z==='Z'?0:Number(z.slice(1,3)),zm=z==='Z'?0:Number(z.slice(4,6));
 return y>=1970&&mo>=1&&mo<=12&&d>=1&&d<=new Date(Date.UTC(y,mo,0)).getUTCDate()&&h<24&&mi<60&&se<60&&zh<=14&&zm<60&&(zh<14||zm===0);
}
function validateContext(c){
 requireThat(jsonSafe(c),'UNSAFE_CONTEXT');
 requireThat(c&&c.gameMode==='RETAIL'&&c.expansion==='DRAGONFLIGHT'&&c.method==='PROSPECT','GAME_METHOD');
 requireThat(typeof c.patchBuild==='string'&&c.patchBuild.length>0&&validEpoch(c.observationEpoch),'PATCH_EPOCH');
 requireThat(typeof c.studyFamilyID==='string'&&c.studyFamilyID.trim()&&typeof c.sourceLineage==='string'&&c.sourceLineage.trim(),'LINEAGE');
 requireThat(int(c.inputItemID,1)&&int(c.inputQualityRank,1)&&int(c.recipeSpellID,1),'RECIPE_INPUT_RANK');
 requireThat(int(c.nominalInputPerCast,1)&&Array.isArray(c.directReagents)&&c.directReagents.length>0,'REAGENTS');
 requireThat(c.directReagents.every(r=>r&&int(r.itemID,1)&&int(r.quantity,1))&&new Set(c.directReagents.map(r=>r.itemID)).size===c.directReagents.length,'REAGENT_VECTOR');
 requireThat(c.directReagents.some(r=>r.itemID===c.inputItemID&&r.quantity===c.nominalInputPerCast),'PRIMARY_REAGENT');
 requireThat(int(c.minimumEligibleSkill,1)&&int(c.professionSkill,c.minimumEligibleSkill),'SKILL');
 requireThat(c.professionContext&&['specialization','gear','unlocks','resourcefulnessPercent'].every(k=>Object.hasOwn(c.professionContext,k)),'PROFESSION_CONTEXT');
 requireThat(nn(c.professionContext.resourcefulnessPercent)&&c.professionContext.resourcefulnessPercent<=100,'RESOURCEFULNESS_PERCENT');
 requireThat(Array.isArray(c.outputItemIDs)&&c.outputItemIDs.length>0&&c.outputItemIDs.every(x=>int(x,1))&&new Set(c.outputItemIDs).size===c.outputItemIDs.length,'OUTPUT_IDS');
 requireThat(c.outputQualityRanks&&c.outputItemIDs.every(id=>int(c.outputQualityRanks[id],1))&&Object.keys(c.outputQualityRanks).length===c.outputItemIDs.length,'OUTPUT_RANKS');
 requireThat(c.outputUniverseVerified===true,'OUTPUT_UNIVERSE_UNVERIFIED');
 return true;
}
function analyzeCasts({context,sourceType,events,prices=null,inputUnitPrice=null,auctionCut=0.05}){
 validateContext(context);
 context=JSON.parse(JSON.stringify(context));
 requireThat(['SYNTHETIC','RAW_CURRENT_RETAIL'].includes(sourceType),'SOURCE_TYPE');
 if(sourceType==='RAW_CURRENT_RETAIL')requireThat(/^\d+\.\d+\.\d+(?:\.\d+)?$/.test(context.patchBuild),'BUILD_REQUIRED');
 requireThat(Array.isArray(events)&&events.length>0,'EVENTS');
 const ids=context.outputItemIDs,seen=new Set(),vectors=[],refunds=[];let aborted=0,zero=0,co=0;
 for(const e of events){
  requireThat(e&&typeof e.castID==='string'&&e.castID.trim()&&!seen.has(e.castID),'CAST_ID');
  seen.add(e.castID);requireThat(['COMPLETED','ABORTED'].includes(e.status),'CAST_STATUS');
  if(e.status==='ABORTED'){requireThat(e.outputs===undefined&&e.refundedInputUnits===undefined,'ABORTED_DATA');aborted++;continue}
  requireThat(int(e.refundedInputUnits)&&e.refundedInputUnits<=context.nominalInputPerCast,'REFUNDS');
  requireThat(e.outputs&&typeof e.outputs==='object'&&!Array.isArray(e.outputs)&&Object.keys(e.outputs).length===ids.length&&ids.every(id=>Object.hasOwn(e.outputs,id)&&int(e.outputs[id])),'ZERO_INCLUSIVE_VECTOR');
  const v=ids.map(id=>e.outputs[id]);vectors.push(v);refunds.push(e.refundedInputUnits);
  const positives=v.filter(x=>x>0).length;if(!positives)zero++;if(positives>1)co++;
 }
 const n=vectors.length;requireThat(n>0,'NO_COMPLETED_CASTS');
 const means=ids.map((_,j)=>vectors.reduce((s,v)=>s+v[j],0)/n);
 const covariance=ids.map((_,i)=>ids.map((_,j)=>n>1?vectors.reduce((s,v)=>s+(v[i]-means[i])*(v[j]-means[j]),0)/(n-1):null));
 const outputs=ids.map((id,j)=>{const positives=vectors.map(v=>v[j]).filter(x=>x>0);return {
  outputItemID:id,outputQualityRank:context.outputQualityRanks[id],observedP:positives.length/n,observedUnconditionalE:means[j],
  observedPositiveMin:positives.length?Math.min(...positives):null,observedPositiveMax:positives.length?Math.max(...positives):null,
  positiveCasts:positives.length,...POLICY};});
 let economics=null;
 if(prices!==null||inputUnitPrice!==null){
  requireThat(prices&&nn(inputUnitPrice)&&nn(auctionCut)&&auctionCut<1,'PRICES');
  requireThat(ids.every(id=>nn(prices[id]))&&Object.keys(prices).length===ids.length,'PRICE_UNIVERSE');
  const margins=vectors.map((v,i)=>v.reduce((s,x,j)=>s+x*prices[ids[j]]*(1-auctionCut),0)-(context.nominalInputPerCast-refunds[i])*inputUnitPrice);
  const mean=margins.reduce((s,x)=>s+x,0)/n;
  const variance=n>1?margins.reduce((s,x)=>s+(x-mean)**2,0)/(n-1):null;
  economics={sampleMargins:margins,sampleMeanMarginPerCast:mean,sampleVarianceMargin:variance,
   sampleStandardError:n>1?Math.sqrt(variance/n):null,samplePositiveMarginFraction:margins.filter(x=>x>0).length/n,
   decision:'DESCRIPTIVE_ONLY_NOT_RECOMMENDATION',...POLICY};
 }
 const totalRefunds=refunds.reduce((s,x)=>s+x,0);
 return checked({modelID:MODEL_ID,sourceType,studyFamilyID:context.studyFamilyID,sourceLineage:context.sourceLineage,
  contextSnapshot:context,contextIdentity:JSON.stringify(context),
  completedCasts:n,abortedRequests:aborted,zeroOutputCasts:zero,coOutputCasts:co,
  nominalGrossInput:n*context.nominalInputPerCast,refundedInput:totalRefunds,netConsumedInput:n*context.nominalInputPerCast-totalRefunds,
  outputs,covarianceSample:covariance,economics,independentHoldout:'NOT_PERFORMED',
  outputUniverseCallerAttestedNotIndependentlyAudited:true,...POLICY});
}
function historicalRateAlternatives({stableKey,nominalInputPerCast,candidates}){
 requireThat(TARGETS.includes(stableKey)&&int(nominalInputPerCast,1),'TARGET_BATCH');
 requireThat(Array.isArray(candidates)&&candidates.length>0,'CANDIDATES');
 const out=[],lineages=new Set();
 for(const c of candidates){
  requireThat(c&&nn(c.rate)&&typeof c.studyFamilyID==='string'&&c.studyFamilyID.trim()&&typeof c.sourceLineage==='string'&&c.sourceLineage.trim(),'SOURCE_RATE');
  requireThat(['PER_INPUT','PER_CAST','UNKNOWN'].includes(c.unit),'SOURCE_UNIT');
  lineages.add(c.sourceLineage.trim().toLowerCase());
  const hypotheses=[];
  if(c.unit!=='PER_CAST')hypotheses.push({unit:'PER_INPUT',hypotheticalEPerCast:checked(c.rate*nominalInputPerCast,'HISTORICAL_RATE_OVERFLOW')});
  if(c.unit!=='PER_INPUT')hypotheses.push({unit:'PER_CAST',hypotheticalEPerCast:c.rate});
  out.push({studyFamilyID:c.studyFamilyID,sourceLineage:c.sourceLineage,unit:c.unit,hypotheses});
 }
 return {modelID:MODEL_ID,stableKey,candidateCount:candidates.length,distinctSourceLineages:lineages.size,
  alternatives:out,reconciledCurrentRetailP:null,reconciledCurrentRetailE:null,
  conflictDisposition:'UNRESOLVED_NO_CURRENT_RETAIL_COHORT',historicalNotMeasuredRetail:true,...POLICY};
}
function scenarioBounds({context,outputs,prices,inputUnitPrice,auctionCut=0.05,refundsPerCast=[0,0],alternativeValuePerCast=0}){
 validateContext(context);
 context=JSON.parse(JSON.stringify(context));
 requireThat(Array.isArray(outputs)&&outputs.length===context.outputItemIDs.length,'FULL_OUTPUT_SET');
 requireThat(prices&&nn(inputUnitPrice)&&nn(auctionCut)&&auctionCut<1&&nn(alternativeValuePerCast),'PRICE_DOMAIN');
 interval(refundsPerCast,'REFUND_RANGE');requireThat(refundsPerCast[1]<=context.nominalInputPerCast,'REFUNDS_EXCEED_INPUT');
 const seen=new Set();let low=0,high=0;
 for(const o of outputs){
  requireThat(o&&context.outputItemIDs.includes(o.outputItemID)&&!seen.has(o.outputItemID),'DUPLICATE_OR_UNKNOWN_OUTPUT');seen.add(o.outputItemID);
  requireThat(int(o.outputQualityRank,1)&&o.outputQualityRank===context.outputQualityRanks[o.outputItemID],'OUTPUT_RANK_MISMATCH');
  const b=interval(o.unconditionalEInterval,'E_INTERVAL');
  requireThat(nn(prices[o.outputItemID])&&typeof o.provenance==='string'&&o.provenance.trim(),'PRICE_PROVENANCE');
  low+=b[0]*prices[o.outputItemID]*(1-auctionCut);high+=b[1]*prices[o.outputItemID]*(1-auctionCut);
 }
 requireThat(Object.keys(prices).length===context.outputItemIDs.length,'PRICE_UNIVERSE');
 const costs=[(context.nominalInputPerCast-refundsPerCast[1])*inputUnitPrice,(context.nominalInputPerCast-refundsPerCast[0])*inputUnitPrice];
 const margin=[low-costs[1]-alternativeValuePerCast,high-costs[0]-alternativeValuePerCast];
 return checked({modelID:MODEL_ID,contextSnapshot:context,contextIdentity:JSON.stringify(context),outputRevenueInterval:[low,high],netInputCostInterval:costs,marginInterval:margin,
  scenarioClassification:margin[0]>0?'POSITIVE_UNDER_ASSUMPTIONS':margin[1]<0?'NEGATIVE_UNDER_ASSUMPTIONS':'SIGN_UNRESOLVED',
  covarianceNotNeededForExpectedLinearRevenue:true,notAProductionRecommendation:true,...POLICY});
}
function selfTest(){
 let n=0;const eq=(a,b)=>{if(typeof a==='number'&&typeof b==='number')assert.ok(Math.abs(a-b)<1e-10);else assert.deepEqual(a,b);n++};
 const ok=x=>{assert.ok(x);n++},bad=f=>{assert.throws(f);n++};
 const context={gameMode:'RETAIL',expansion:'DRAGONFLIGHT',method:'PROSPECT',patchBuild:'SYNTHETIC',observationEpoch:'2026-10-29T20:00:00Z',
 studyFamilyID:'synthetic-family',sourceLineage:'synthetic-cast-log',inputItemID:188658,inputQualityRank:1,recipeSpellID:382995,
 nominalInputPerCast:5,directReagents:[{itemID:188658,quantity:5}],minimumEligibleSkill:1,professionSkill:1,
 professionContext:{specialization:'NONE',gear:'NONE',unlocks:'NONE',resourcefulnessPercent:0},
 outputItemIDs:[192870,192871],outputQualityRanks:{192870:1,192871:2},outputUniverseVerified:true};
 const c=(id,a,b,r=0)=>({castID:id,status:'COMPLETED',refundedInputUnits:r,outputs:{192870:a,192871:b}});
 const events=[c('1',0,0),c('2',1,2,1),c('3',2,0),{castID:'x',status:'ABORTED'}];
 const s=analyzeCasts({context,sourceType:'SYNTHETIC',events,prices:{192870:10,192871:5},inputUnitPrice:2,auctionCut:0});
 eq(TARGETS.length,5);eq(new Set(TARGETS).size,5);eq(s.completedCasts,3);eq(s.abortedRequests,1);
 eq(s.zeroOutputCasts,1);eq(s.coOutputCasts,1);eq(s.nominalGrossInput,15);eq(s.refundedInput,1);eq(s.netConsumedInput,14);
 eq(s.outputs[0].observedP,2/3);eq(s.outputs[0].observedUnconditionalE,1);
 eq(s.outputs[1].observedP,1/3);eq(s.outputs[1].observedUnconditionalE,2/3);
 eq(s.outputs[0].observedPositiveMin,1);eq(s.outputs[0].observedPositiveMax,2);
 eq(s.covarianceSample[0][0],1);eq(s.covarianceSample[0][1],0);eq(s.covarianceSample[1][1],4/3);
 eq(s.economics.sampleMargins,[-10,12,10]);eq(s.economics.sampleMeanMarginPerCast,4);eq(s.economics.sampleVarianceMargin,148);
 eq(s.economics.decision,'DESCRIPTIVE_ONLY_NOT_RECOMMENDATION');eq(s.confidence,0);eq(s.economicUse,'PREVIEW_ONLY');eq(s.normalizedVerified,false);
 eq(analyzeCasts({context,sourceType:'SYNTHETIC',events:[c('a',0,0)]}).covarianceSample[0][0],null);
 bad(()=>analyzeCasts({context:{...context,outputUniverseVerified:false},sourceType:'SYNTHETIC',events}));
 bad(()=>analyzeCasts({context,sourceType:'RAW_CURRENT_RETAIL',events}));
 bad(()=>analyzeCasts({context,sourceType:'SYNTHETIC',events:[c('x',0,0),c('x',1,0)]}));
 bad(()=>analyzeCasts({context,sourceType:'SYNTHETIC',events:[{castID:'x',status:'COMPLETED',refundedInputUnits:0,outputs:{192870:1}}]}));
 bad(()=>analyzeCasts({context,sourceType:'SYNTHETIC',events:[{castID:'x',status:'ABORTED',outputs:{}}]}));
 bad(()=>analyzeCasts({context,sourceType:'SYNTHETIC',events:[c('x',0,0,6)]}));
 bad(()=>analyzeCasts({context,sourceType:'SYNTHETIC',events:[c('x',0,0)],prices:{192870:1},inputUnitPrice:1}));
 bad(()=>analyzeCasts({context:{...context,observationEpoch:'2026-02-29T20:00:00Z'},sourceType:'SYNTHETIC',events}));
 ok(validEpoch('2024-02-29T12:00:00+01:00'));ok(!validEpoch('2026-10-29T25:00:00Z'));
 const h=historicalRateAlternatives({stableKey:TARGETS[0],nominalInputPerCast:5,candidates:[
 {rate:0.1,unit:'UNKNOWN',studyFamilyID:'A',sourceLineage:'TSM snapshot'},
 {rate:0.2,unit:'PER_CAST',studyFamilyID:'A-mirror',sourceLineage:' tsm SNAPSHOT '}]});
 eq(h.alternatives[0].hypotheses.map(x=>x.hypotheticalEPerCast),[.5,.1]);eq(h.distinctSourceLineages,1);
 eq(h.reconciledCurrentRetailE,null);eq(h.conflictDisposition,'UNRESOLVED_NO_CURRENT_RETAIL_COHORT');
 bad(()=>historicalRateAlternatives({stableKey:'unknown',nominalInputPerCast:5,candidates:[]}));
 bad(()=>historicalRateAlternatives({stableKey:TARGETS[0],nominalInputPerCast:5,candidates:[{rate:-1,unit:'UNKNOWN',studyFamilyID:'a',sourceLineage:'b'}]}));
 const args={context,outputs:[{outputItemID:192870,outputQualityRank:1,unconditionalEInterval:[0.1,0.3],provenance:'synthetic'},
 {outputItemID:192871,outputQualityRank:2,unconditionalEInterval:[0.2,0.4],provenance:'synthetic'}],
 prices:{192870:10,192871:5},inputUnitPrice:1,auctionCut:0,refundsPerCast:[0,1]};
 const b=scenarioBounds(args);eq(b.outputRevenueInterval,[2,5]);eq(b.netInputCostInterval,[4,5]);
 eq(b.marginInterval,[-3,1]);eq(b.scenarioClassification,'SIGN_UNRESOLVED');
 eq(scenarioBounds({...args,inputUnitPrice:0}).scenarioClassification,'POSITIVE_UNDER_ASSUMPTIONS');
 eq(scenarioBounds({...args,inputUnitPrice:10}).scenarioClassification,'NEGATIVE_UNDER_ASSUMPTIONS');
 bad(()=>scenarioBounds({...args,outputs:args.outputs.slice(0,1)}));
 bad(()=>scenarioBounds({...args,refundsPerCast:[0,6]}));
 bad(()=>scenarioBounds({...args,prices:{192870:10}}));
 bad(()=>analyzeCasts({context:{...context,professionContext:{...context.professionContext,gear:{bonus:NaN}}},sourceType:'SYNTHETIC',events}));
 bad(()=>analyzeCasts({context:{...context,professionContext:{...context.professionContext,unlocks:()=>true}},sourceType:'SYNTHETIC',events}));
 bad(()=>analyzeCasts({context:{...context,professionContext:{...context.professionContext,specialization:undefined}},sourceType:'SYNTHETIC',events}));
 bad(()=>analyzeCasts({context:{...context,patchBuild:'10.2.7BANANA'},sourceType:'RAW_CURRENT_RETAIL',events}));
 bad(()=>scenarioBounds({...args,outputs:args.outputs.map(o=>({...o,outputQualityRank:3}))}));
 bad(()=>scenarioBounds({...args,outputs:args.outputs.map(({outputQualityRank,...o})=>o)}));
 bad(()=>scenarioBounds({...args,outputs:args.outputs.map(o=>({...o,unconditionalEInterval:[1e308,1e308]})),prices:{192870:1e308,192871:1e308}}));
 bad(()=>historicalRateAlternatives({stableKey:TARGETS[0],nominalInputPerCast:5,candidates:[{rate:1e308,unit:'PER_INPUT',studyFamilyID:'A',sourceLineage:'A'}]}));
 eq(s.contextSnapshot.professionSkill,1);eq(b.contextSnapshot.outputQualityRanks[192871],2);
 return {modelID:MODEL_ID,passed:n,failed:0,targetMappings:TARGETS.length,syntheticOnly:true};
}
module.exports={MODEL_ID,POLICY,TARGETS,validEpoch,validateContext,analyzeCasts,historicalRateAlternatives,scenarioBounds,selfTest};
if(require.main===module)console.log(JSON.stringify(selfTest()));
