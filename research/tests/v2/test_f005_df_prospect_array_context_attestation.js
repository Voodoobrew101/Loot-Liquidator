'use strict';
// F005 independent research-only QA: JSON-safe context attestation must not discard array metadata.
// Synthetic fixtures; neither game mechanics nor economic eligibility are established.
const assert=require('node:assert/strict');
const m=require('../../tools/models_v2/df_prospecting_joint_cast_conflict_v1.js');
const context={
 gameMode:'RETAIL',expansion:'DRAGONFLIGHT',method:'PROSPECT',patchBuild:'10.2.7',
 observationEpoch:'2026-10-30T07:00:00Z',studyFamilyID:'F005_ARRAY_CONTEXT_SYNTHETIC',
 sourceLineage:'F005_ARRAY_CONTEXT_SYNTHETIC',inputItemID:188658,inputQualityRank:2,
 recipeSpellID:374627,nominalInputPerCast:5,directReagents:[{itemID:188658,quantity:5}],
 minimumEligibleSkill:1,professionSkill:100,
 professionContext:{specialization:{points:10},gear:{bonus:0},unlocks:['x'],resourcefulnessPercent:0},
 outputItemIDs:[192870,192871],outputQualityRanks:{192870:2,192871:3},outputUniverseVerified:true
};
const events=[{castID:'a',status:'COMPLETED',refundedInputUnits:0,outputs:{192870:1,192871:0}}];
const scenario={context,outputs:[
 {outputItemID:192870,outputQualityRank:2,unconditionalEInterval:[0.1,0.3],provenance:'SYNTHETIC'},
 {outputItemID:192871,outputQualityRank:3,unconditionalEInterval:[0.2,0.4],provenance:'SYNTHETIC'}
],prices:{192870:10,192871:5},inputUnitPrice:1,auctionCut:0,refundsPerCast:[0,1]};
function changed(kind){
 let a;
 if(kind==='symbol'){a=['x'];a[Symbol('sourceStudy')]='hidden-source';}
 if(kind==='nonenumerable'){a=['x'];Object.defineProperty(a,'sourceStudy',{value:'hidden-source',enumerable:false});}
 if(kind==='sparse-offset'){a=['x',,];a.sourceStudy='hidden-source';}
 if(kind==='subclass-toJSON'){class Spoof extends Array{toJSON(){return ['forged'];}}a=new Spoof('x');}
 if(kind==='own-hidden-toJSON'){a=['x'];Object.defineProperty(a,'toJSON',{value:()=>['forged'],enumerable:false});}
 return {...context,professionContext:{...context.professionContext,unlocks:a}};
}
const cases=[];let passed=0,failed=0;
function check(name,fn){try{fn();passed++;cases.push({name,result:'PASS'});}
 catch(e){failed++;cases.push({name,result:'FAIL',detail:String(e.message)});}}
check('ordinary cohort remains accepted',()=>{
 const r=m.analyzeCasts({context,sourceType:'RAW_CURRENT_RETAIL',events});
 assert.equal(r.completedCasts,1);assert.equal(r.economicUse,'PREVIEW_ONLY');
 assert.equal(r.normalizedVerified,false);assert.equal(r.confidence,0);
});
check('ordinary scenario remains accepted',()=>{
 const r=m.scenarioBounds(scenario);assert.equal(r.notAProductionRecommendation,true);
 assert.equal(r.contextSnapshot.professionContext.unlocks[0],'x');
});
check('explicit null array value is preserved, not silently synthesized from a hole',()=>{
 const c={...context,professionContext:{...context.professionContext,unlocks:['x',null]}};
 const r=m.analyzeCasts({context:c,sourceType:'RAW_CURRENT_RETAIL',events});
 assert.equal(r.contextSnapshot.professionContext.unlocks[1],null);
});
for(const kind of ['symbol','nonenumerable','sparse-offset','subclass-toJSON','own-hidden-toJSON']){
 check('reject '+kind+' in cast-context attestation',()=>assert.throws(()=>
  m.analyzeCasts({context:changed(kind),sourceType:'RAW_CURRENT_RETAIL',events})));
 check('reject '+kind+' in scenario-context attestation',()=>assert.throws(()=>
  m.scenarioBounds({...scenario,context:changed(kind)})));
}
console.log(JSON.stringify({suite:'F005_DF_PROSPECT_ARRAY_CONTEXT_ATTESTATION',
 modelID:m.MODEL_ID,syntheticOnly:true,independentCurrentRetailHoldoutFamilies:0,
 passed,failed,cases}));
if(failed)process.exitCode=1;
