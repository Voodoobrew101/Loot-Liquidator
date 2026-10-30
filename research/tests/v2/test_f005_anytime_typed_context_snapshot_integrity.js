'use strict';
// F005 independent adversarial test: Midnight anytime typed-context snapshot integrity.
// Synthetic fixtures only. Never changes evidence, candidates or economic eligibility.
const assert=require('node:assert/strict');
const model=require('../../tools/models_v2/midnight_rare_gem_anytime_e_bounds_v1.js');
const base={
 gameMode:'RETAIL',sourceType:'RAW_CURRENT_RETAIL',patchBuild:'12.0.0',
 recipeSpellID:1231127,observationEpoch:'2026-10-29T20:00:00Z',
 inputItemID:237363,outputItemID:242608,inputQualityRank:2,outputQualityRank:1,
 nominalInputCountPerCast:5,directReagents:[{itemID:237363,quantity:5}],
 minimumRecipeEligibleSkill:1,professionSkill:1,
 professionContext:{specialization:{points:5},gear:{stat:10},unlocks:['a'],resourcefulnessPercent:0},
 sourceStudyFamilyID:'SYNTHETIC_F005_CONTEXT_SNAPSHOT'
};
const events=[{castID:'s1',status:'COMPLETED',outputCount:0,refundedInputCount:1},
 {castID:'s2',status:'COMPLETED',outputCount:2,refundedInputCount:0},
 {castID:'s3',status:'COMPLETED',outputCount:0,refundedInputCount:0},
 {castID:'s4',status:'ABORTED'}];
function ctx(){return {...base,directReagents:base.directReagents.map(x=>({...x})),
 professionContext:{specialization:{points:5},gear:{stat:10},unlocks:['a'],resourcefulnessPercent:0}};}
function analyze(c=ctx(),extra={}){return model.analyzeCohort({context:c,events,...extra});}
let passed=0,failed=0;const cases=[];
function check(name,fn){try{fn();passed++;cases.push({name,result:'PASS'});}
 catch(e){failed++;cases.push({name,result:'FAIL',detail:String(e.message)});}}
check('raw-shaped synthetic sample stays confidence-zero preview',()=>{
 const r=analyze();assert.equal(r.confidence,0);assert.equal(r.economicUse,'PREVIEW_ONLY');
 assert.equal(r.normalizedVerified,false);assert.equal(r.liveEconomicEligible,false);
});
check('zero-inclusive E and P retain distinct denominators',()=>{
 const r=analyze();assert.equal(r.observedDropChance,1/3);
 assert.equal(r.observedUnconditionalExpectedQuantity,2/3);assert.equal(r.expectedQuantityAnytimeInterval[1],null);
});
check('typedContextKey initially describes typedContext',()=>{
 const r=analyze();assert.equal(r.typedContextKey,JSON.stringify(r.typedContext));
});
check('directReagents source mutation does not alter returned snapshot',()=>{
 const c=ctx(),r=analyze(c);c.directReagents[0].quantity=999;
 assert.equal(r.typedContext.directReagents[0].quantity,5);
});
check('nested specialization source mutation cannot rewrite returned provenance',()=>{
 const c=ctx(),r=analyze(c);c.professionContext.specialization.points=999;
 assert.equal(r.typedContext.professionContext.specialization.points,5);
 assert.equal(JSON.stringify(r.typedContext),r.typedContextKey);
});
check('nested gear source mutation cannot rewrite returned provenance',()=>{
 const c=ctx(),r=analyze(c);c.professionContext.gear.stat=999;
 assert.equal(r.typedContext.professionContext.gear.stat,10);
 assert.equal(JSON.stringify(r.typedContext),r.typedContextKey);
});
check('nested unlocks source mutation cannot rewrite returned provenance',()=>{
 const c=ctx(),r=analyze(c);c.professionContext.unlocks.push('b');
 assert.deepEqual(r.typedContext.professionContext.unlocks,['a']);
 assert.equal(JSON.stringify(r.typedContext),r.typedContextKey);
});
check('NaN specialization must not be admitted into serialized context',()=>{
 const c=ctx();c.professionContext.specialization=NaN;
 assert.throws(()=>analyze(c),/CONTEXT|PROFESSION|FINITE|SERIAL/);
});
check('Infinity gear must not be admitted into serialized context',()=>{
 const c=ctx();c.professionContext.gear=Infinity;
 assert.throws(()=>analyze(c),/CONTEXT|PROFESSION|FINITE|SERIAL/);
});
check('function unlocks must not be silently erased by JSON serialization',()=>{
 const c=ctx();c.professionContext.unlocks=()=>true;
 assert.throws(()=>analyze(c),/CONTEXT|PROFESSION|SERIAL/);
});
check('distinct nonfinite specialization values must not share a context key',()=>{
 const a=ctx(),b=ctx();a.professionContext.specialization=NaN;
 b.professionContext.specialization=Infinity;
 assert.notEqual(analyze(a).typedContextKey,analyze(b).typedContextKey);
});
check('nested undefined profession field must not silently disappear',()=>{
 const c=ctx();c.professionContext.gear={stat:10,unknown:undefined};
 assert.throws(()=>analyze(c),/CONTEXT|PROFESSION|SERIAL/);
});
check('same cap lineage with trailing whitespace still rejected',()=>{
 const c=ctx();assert.throws(()=>analyze(c,{certifiedMaxPerCast:3,
 capEvidenceID:c.sourceStudyFamilyID+' '}),/INDEPENDENT_CAP_CERTIFICATE_REQUIRED/);
});
console.log(JSON.stringify({suite:'F005_ANYTIME_TYPED_CONTEXT_SNAPSHOT_INTEGRITY',
 syntheticOnly:true,actualRetailCasts:0,sourceModelID:model.MODEL_ID,
 passed,failed,cases}));
if(failed)process.exitCode=1;
