'use strict';
// F005 independent synthetic integrity regression: compareEpochs must reject tampered cohort summaries.
// Research-only. No claims of real Retail drop rates, economic eligibility, or independent holdouts.
const assert = require('node:assert/strict');
const m = require('../../tools/models_v2/midnight_prospect_hotfix_epoch_isolation_v1.js');
const base = {
 gameMode:'RETAIL',expansion:'MIDNIGHT',method:'PROSPECT',
 stableKey:'midnight:237359:242608:L733',inputItemID:237359,outputItemID:242608,
 sourceType:'RAW_CURRENT_RETAIL',patchBuild:'12.0.5',recipeSpellID:1231127,
 inputQualityRank:2,outputQualityRank:1,nominalInputPerCast:5,
 directReagents:[{itemID:237359,quantity:5}],minimumEligibleSkill:1,professionSkill:1,
 professionContext:{specialization:[],gear:[],unlocks:[],resourcefulnessPercent:0},
 studyFamilyID:'F005_SYNTH_PRE',sourceLineage:'F005_SYNTH_PRE',
 observationStart:'2026-03-30T12:00:00Z',observationEnd:'2026-03-30T13:00:00Z'
};
const events=[
 {castID:'zero',status:'COMPLETED',outputCount:0,refundedInputUnits:0},
 {castID:'positive',status:'COMPLETED',outputCount:2,refundedInputUnits:1}
];
const pre=m.analyzeCohort({context:base,events});
const post=m.analyzeCohort({context:{...base,studyFamilyID:'F005_SYNTH_POST',sourceLineage:'F005_SYNTH_POST',
 observationStart:'2026-04-04T12:00:00Z',observationEnd:'2026-04-04T13:00:00Z'},events});
const clone=x=>JSON.parse(JSON.stringify(x));
let passed=0,failed=0;const cases=[];
function check(name,fn){try{fn();passed++;cases.push({name,result:'PASS'});}
 catch(e){failed++;cases.push({name,result:'FAIL',detail:String(e.message)});}}
function rejectMutation(name,mutate){
 check(name,()=>{const bad=clone(post);mutate(bad);assert.throws(()=>m.compareEpochs(pre,bad));});
}
check('valid pair retains zero-inclusive P/E and no economic use',()=>{
 const r=m.compareEpochs(pre,post);assert.equal(r.deltaObservedP,0);assert.equal(r.deltaObservedUnconditionalE,0);
 assert.equal(r.economicUse,'PREVIEW_ONLY');assert.equal(r.normalizedVerified,false);assert.equal(r.confidence,0);
});
check('duplicate lineage is rejected',()=>assert.throws(()=>m.compareEpochs(pre,{...post,sourceLineage:pre.sourceLineage})));
check('mismatched profession skill is rejected',()=>{
 const bad=clone(post);bad.contextSnapshot.professionSkill=2;
 assert.throws(()=>m.compareEpochs(pre,bad));
});
check('synthetic-only comparison is rejected',()=>{
 const bad=clone(post);bad.sourceType='SYNTHETIC';
 assert.throws(()=>m.compareEpochs(pre,bad));
});
rejectMutation('reject infinite unconditional E',x=>{x.observedUnconditionalE=Infinity;});
rejectMutation('reject negative unconditional E',x=>{x.observedUnconditionalE=-1;});
rejectMutation('reject P greater than one',x=>{x.observedP=1.01;});
rejectMutation('reject impossible completed-cast count',x=>{x.completedCasts=3;});
rejectMutation('reject refunds exceeding gross input',x=>{x.refundedInput=x.grossInput+1;});
rejectMutation('reject forged LIVE economicUse',x=>{x.economicUse='LIVE';});
rejectMutation('reject forged confidence promotion',x=>{x.confidence=99;});
rejectMutation('reject negative observed positive minimum',x=>{x.observedPositiveMin=-4;});
rejectMutation('reject changed observation epoch inconsistent with classification',x=>{
 x.contextSnapshot.observationStart='2026-03-30T12:00:00Z';
});
rejectMutation('reject changed output item identity',x=>{x.contextSnapshot.outputItemID=123;});
rejectMutation('reject zero completed casts with positive outputs',x=>{x.completedCasts=0;});
rejectMutation('reject inconsistent zero and positive cast totals',x=>{x.positiveCasts=2;});
rejectMutation('reject E outside observed P times positive bound',x=>{x.observedUnconditionalE=1.5;});
rejectMutation('reject forged source identity in context snapshot',x=>{x.contextSnapshot.sourceType='SYNTHETIC';});
console.log(JSON.stringify({suite:'F005_MIDNIGHT_PROSPECT_COMPARE_SUMMARY_ATTESTATION',
 modelID:m.MODEL_ID,syntheticOnly:true,independentCurrentRetailHoldouts:0,
 passed,failed,cases}));
if(failed)process.exitCode=1;
