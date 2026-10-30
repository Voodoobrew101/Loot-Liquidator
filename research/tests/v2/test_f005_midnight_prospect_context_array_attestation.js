'use strict';
// F005 independent regression: Midnight hotfix date repair plus nested array attestation.
// Synthetic only. This intentionally fails until F003 rejects unsafe array metadata.
const assert=require('node:assert/strict');
const m=require('../../tools/models_v2/midnight_prospect_hotfix_epoch_isolation_v1.js');
const base={
 gameMode:'RETAIL',expansion:'MIDNIGHT',method:'PROSPECT',
 stableKey:'midnight:237359:242608:L733',inputItemID:237359,outputItemID:242608,
 sourceType:'RAW_CURRENT_RETAIL',patchBuild:'12.0.5',recipeSpellID:1231127,
 inputQualityRank:2,outputQualityRank:1,nominalInputPerCast:5,
 directReagents:[{itemID:237359,quantity:5}],minimumEligibleSkill:1,professionSkill:1,
 professionContext:{specialization:[],gear:[],unlocks:[],resourcefulnessPercent:0},
 studyFamilyID:'F005_SYNTHETIC_CONTEXT',sourceLineage:'F005_SYNTHETIC_CONTEXT',
 observationStart:'2026-03-30T12:00:00Z',observationEnd:'2026-03-30T13:00:00Z'
};
const events=[
 {castID:'zero',status:'COMPLETED',outputCount:0,refundedInputUnits:0},
 {castID:'positive',status:'COMPLETED',outputCount:2,refundedInputUnits:1},
 {castID:'aborted',status:'ABORTED'}
];
const contextWith=arr=>({...base,professionContext:{...base.professionContext,specialization:arr}});
let passed=0,failed=0;const cases=[];
function check(name,fn){try{fn();passed++;cases.push({name,result:'PASS'});}
 catch(e){failed++;cases.push({name,result:'FAIL',detail:String(e.message)});}}
check('official March 31 date repaired',()=>assert.equal(m.OFFICIAL_ENTRY_DATE,'2026-03-31'));
check('March 31 local date quarantined',()=>assert.equal(m.classifyEpoch('2026-03-31T00:30:00+14:00'),'TRANSITION_QUARANTINE'));
check('April 3 UTC post-buffer',()=>assert.equal(m.classifyEpoch('2026-04-03T00:00:00Z'),'POST_HOTFIX'));
check('zero-inclusive unconditional E and P',()=>{const r=m.analyzeCohort({context:base,events});assert.equal(r.observedP,.5);assert.equal(r.observedUnconditionalE,1);});
check('gross input and refunds remain separate',()=>{const r=m.analyzeCohort({context:base,events});assert.equal(r.completedCasts,2);assert.equal(r.grossInput,10);assert.equal(r.refundedInput,1);assert.equal(r.netConsumedInput,9);});
check('preview-only and no economic eligibility',()=>{const r=m.analyzeCohort({context:base,events});assert.equal(r.confidence,0);assert.equal(r.economicUse,'PREVIEW_ONLY');assert.equal(r.normalizedVerified,false);assert.equal(r.liveEconomicEligible,false);assert.equal(r.tooltipOnlyEligible,false);});
check('snapshot is independent of later input mutation',()=>{const arr=['trait'];const c=contextWith(arr);const r=m.analyzeCohort({context:c,events});arr[0]='changed';assert.deepEqual(r.contextSnapshot.professionContext.specialization,['trait']);});
check('reject symbol property on profession array',()=>{const arr=[];arr[Symbol('trait')]='hidden';assert.throws(()=>m.analyzeCohort({context:contextWith(arr),events}),/UNSAFE_CONTEXT/);});
check('reject non-enumerable property on profession array',()=>{const arr=[];Object.defineProperty(arr,'trait',{value:'hidden'});assert.throws(()=>m.analyzeCohort({context:contextWith(arr),events}),/UNSAFE_CONTEXT/);});
check('reject sparse array disguised with extra key',()=>{const arr=['a',,'c'];arr.extra='hidden';assert.throws(()=>m.analyzeCohort({context:contextWith(arr),events}),/UNSAFE_CONTEXT/);});
check('reject Array subclass with inherited custom toJSON',()=>{class Trick extends Array{toJSON(){return ['changed'];}}const arr=new Trick('original');assert.throws(()=>m.analyzeCohort({context:contextWith(arr),events}),/UNSAFE_CONTEXT/);});
check('reject own non-enumerable custom toJSON',()=>{const arr=['original'];Object.defineProperty(arr,'toJSON',{value(){return ['changed'];}});assert.throws(()=>m.analyzeCohort({context:contextWith(arr),events}),/UNSAFE_CONTEXT/);});
console.log(JSON.stringify({suite:'F005_MIDNIGHT_PROSPECT_CONTEXT_ARRAY_ATTESTATION',syntheticOnly:true,independentCurrentRetailHoldouts:0,passed,failed,cases}));
if(failed)process.exitCode=1;
