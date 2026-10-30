'use strict';
// Independent F005 QA; synthetic-only fixtures. Do not modify model or evidence here.
const assert=require('node:assert/strict');
const m=require('../../tools/models_v2/df_prospecting_joint_cast_conflict_v1.js');
const c={gameMode:'RETAIL',expansion:'DRAGONFLIGHT',method:'PROSPECT',patchBuild:'10.2.7',
 observationEpoch:'2026-10-29T20:00:00Z',studyFamilyID:'F005_SYNTHETIC',sourceLineage:'F005_SYNTHETIC',
 inputItemID:188658,inputQualityRank:2,recipeSpellID:374627,nominalInputPerCast:5,
 directReagents:[{itemID:188658,quantity:5}],minimumEligibleSkill:1,professionSkill:100,
 professionContext:{specialization:{points:10},gear:{bonus:0},unlocks:['x'],resourcefulnessPercent:0},
 outputItemIDs:[192870,192871],outputQualityRanks:{192870:2,192871:3},outputUniverseVerified:true};
const events=[
 {castID:'a',status:'COMPLETED',refundedInputUnits:0,outputs:{192870:1,192871:0}},
 {castID:'b',status:'COMPLETED',refundedInputUnits:1,outputs:{192870:0,192871:2}},
 {castID:'c',status:'ABORTED'}];
const outputs=[
 {outputItemID:192870,outputQualityRank:2,unconditionalEInterval:[.1,.3],provenance:'SYNTHETIC'},
 {outputItemID:192871,outputQualityRank:3,unconditionalEInterval:[.2,.4],provenance:'SYNTHETIC'}];
const scenario={context:c,outputs,prices:{192870:10,192871:5},inputUnitPrice:1,auctionCut:0,refundsPerCast:[0,1]};
const cohort=(context=c,extra={})=>m.analyzeCasts({context,sourceType:'RAW_CURRENT_RETAIL',events,...extra});
const cases=[];let passed=0,failed=0;
function check(name,fn){try{fn();passed++;cases.push({name,result:'PASS'});}
 catch(e){failed++;cases.push({name,result:'FAIL',detail:String(e.message)});}}
check('zero-inclusive P/E excludes aborted requests',()=>{
 const r=cohort();assert.equal(r.completedCasts,2);assert.equal(r.abortedRequests,1);
 assert.deepEqual(r.outputs.map(o=>[o.observedP,o.observedUnconditionalE]),[[.5,.5],[.5,1]]);
});
check('joint covariance and refund accounting',()=>{
 const r=cohort();assert.equal(r.nominalGrossInput,10);assert.equal(r.refundedInput,1);
 assert.equal(r.netConsumedInput,9);assert.equal(r.covarianceSample[0][1],-1);
});
check('sample margins descriptive only',()=>{
 const r=cohort(c,{prices:{192870:10,192871:5},inputUnitPrice:2,auctionCut:0});
 assert.deepEqual(r.economics.sampleMargins,[0,2]);
 assert.equal(r.economics.decision,'DESCRIPTIVE_ONLY_NOT_RECOMMENDATION');
});
check('confidence-zero preview isolation for cohort and outputs',()=>{
 const r=cohort();for(const o of [r,...r.outputs]){
  assert.equal(o.confidence,0);assert.equal(o.economicUse,'PREVIEW_ONLY');
  assert.equal(o.normalizedVerified,false);assert.equal(o.liveEconomicEligible,false);}
});
check('scenario unconditional E and refund bounds',()=>{
 const r=m.scenarioBounds(scenario);assert.deepEqual(r.outputRevenueInterval,[2,5]);
 assert.deepEqual(r.netInputCostInterval,[4,5]);assert.deepEqual(r.marginInterval,[-3,1]);
 assert.equal(r.notAProductionRecommendation,true);
});
check('historical units and duplicate source ancestry remain distinct',()=>{
 const r=m.historicalRateAlternatives({stableKey:m.TARGETS[0],nominalInputPerCast:5,candidates:[
 {rate:.1,unit:'UNKNOWN',studyFamilyID:'A',sourceLineage:'TSM snapshot'},
 {rate:.2,unit:'PER_CAST',studyFamilyID:'mirror',sourceLineage:' tsm SNAPSHOT '}]});
 assert.deepEqual(r.alternatives[0].hypotheses.map(x=>x.hypotheticalEPerCast),[.5,.1]);
 assert.equal(r.distinctSourceLineages,1);assert.equal(r.reconciledCurrentRetailE,null);
});
check('reject incomplete output vector',()=>assert.throws(()=>cohort(c,{events:[
 {castID:'x',status:'COMPLETED',refundedInputUnits:0,outputs:{192870:1}}]})));
check('reject refunds exceeding nominal input',()=>assert.throws(()=>cohort(c,{events:[
 {castID:'x',status:'COMPLETED',refundedInputUnits:6,outputs:{192870:1,192871:0}}]})));
check('reject NaN observed output count',()=>assert.throws(()=>cohort(c,{events:[
 {castID:'x',status:'COMPLETED',refundedInputUnits:0,outputs:{192870:NaN,192871:0}}]})));
check('reject unverified output universe',()=>assert.throws(()=>cohort({...c,outputUniverseVerified:false})));
check('reject historical source type in current-cast path',()=>assert.throws(()=>cohort(c,{sourceType:'HISTORICAL_TSM'})));
check('reject malformed RAW build suffix',()=>assert.throws(()=>cohort({...c,patchBuild:'10.2.7BANANA'})));
check('reject nested NaN specialization',()=>assert.throws(()=>cohort({...c,professionContext:{...c.professionContext,specialization:{points:NaN}}})));
check('reject nested Infinity gear',()=>assert.throws(()=>cohort({...c,professionContext:{...c.professionContext,gear:{bonus:Infinity}}})));
check('reject function unlocks',()=>assert.throws(()=>cohort({...c,professionContext:{...c.professionContext,unlocks:()=>true}})));
check('reject undefined specialization',()=>assert.throws(()=>cohort({...c,professionContext:{...c.professionContext,specialization:undefined}})));
check('reject BigInt nested stat',()=>assert.throws(()=>cohort({...c,professionContext:{...c.professionContext,gear:{bonus:2n}}})));
check('reject nested undefined that JSON would omit',()=>assert.throws(()=>cohort({...c,professionContext:{...c.professionContext,gear:{bonus:0,unknown:undefined}}})));
check('reject wrong output quality rank in scenario',()=>assert.throws(()=>m.scenarioBounds({...scenario,outputs:outputs.map((o,i)=>({...o,outputQualityRank:i===0?3:2}))})));
check('reject missing output quality rank in scenario',()=>assert.throws(()=>m.scenarioBounds({...scenario,outputs:outputs.map(({outputQualityRank,...o})=>o)})));
check('reject overflowed historical per-cast E',()=>assert.throws(()=>m.historicalRateAlternatives({stableKey:m.TARGETS[0],nominalInputPerCast:5,candidates:[{rate:1e308,unit:'PER_INPUT',studyFamilyID:'A',sourceLineage:'A'}]})));
check('reject overflowed scenario revenue/margin',()=>assert.throws(()=>m.scenarioBounds({...scenario,outputs:outputs.map(o=>({...o,unconditionalEInterval:[1e308,1e308]})),prices:{192870:1e308,192871:1e308}})));
check('reject overflowed observed economic margins',()=>assert.throws(()=>cohort(c,{prices:{192870:1e308,192871:1e308},inputUnitPrice:1})));
console.log(JSON.stringify({suite:'F005_DF_PROSPECT_JOINT_CAST_ADVERSARIAL',modelID:m.MODEL_ID,
 syntheticOnly:true,independentCurrentRetailHoldoutFamilies:0,passed,failed,cases}));
if(failed)process.exitCode=1;
