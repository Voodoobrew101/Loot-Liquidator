'use strict';
// Independent F005 adversarial QA of the F003 Midnight rare-gem anytime model.
// All observations are synthetic. No game measurements or economic promotions.
// Run: node research/tests/v2/test_f005_midnight_anytime_context_lineage.js
const assert=require('node:assert/strict');
const model=require('../../tools/models_v2/midnight_rare_gem_anytime_e_bounds_v1.js');
const context={
  gameMode:'RETAIL',sourceType:'RAW_CURRENT_RETAIL',patchBuild:'12.0.0',
  recipeSpellID:1231127,observationEpoch:'2026-10-29T20:00:00Z',
  inputItemID:237363,outputItemID:242608,inputQualityRank:2,outputQualityRank:1,
  nominalInputCountPerCast:5,directReagents:[{itemID:237363,quantity:5}],
  minimumRecipeEligibleSkill:1,professionSkill:1,
  professionContext:{specialization:'NONE',gear:'NONE',unlocks:'NONE',resourcefulnessPercent:0},
  sourceStudyFamilyID:'SYNTHETIC_FAMILY_A'
};
const events=[
  {castID:'SYNTHETIC_1',status:'COMPLETED',outputCount:0,refundedInputCount:1},
  {castID:'SYNTHETIC_2',status:'COMPLETED',outputCount:2,refundedInputCount:0},
  {castID:'SYNTHETIC_3',status:'COMPLETED',outputCount:0,refundedInputCount:0},
  {castID:'SYNTHETIC_ABORT',status:'ABORTED'}
];
let passed=0,failed=0;const cases=[];
function check(name,fn){
  try{fn();passed++;cases.push({name,result:'PASS'});}
  catch(e){failed++;cases.push({name,result:'FAIL',detail:e.message});}
}
const analyze=(c=context,options={})=>model.analyzeCohort({context:c,events,...options});
check('valid RAW-shaped synthetic fixture stays PREVIEW_ONLY and confidence zero',()=>{
  const x=analyze();
  assert.equal(x.confidence,0);assert.equal(x.economicUse,'PREVIEW_ONLY');
  assert.equal(x.normalizedVerified,false);assert.equal(x.liveEconomicEligible,false);
  assert.equal(x.completeEconomicOutputUniverse,false);
});
check('zero-inclusive unconditional E is 2/3, not P multiplied again',()=>{
  const x=analyze();assert.equal(x.completedCasts,3);
  assert.equal(x.observedDropChance,1/3);
  assert.equal(x.observedUnconditionalExpectedQuantity,2/3);
  assert.equal(x.expectedQuantityAnytimeInterval[1],null);
});
check('aborted requests excluded from cast and refund denominators',()=>{
  const x=analyze();assert.equal(x.abortedRequests,1);
  assert.equal(x.nominalGrossInputs,15);assert.equal(x.refundedInputs,1);
  assert.equal(x.netConsumedInputs,14);
});
check('duplicate cast IDs rejected',()=>{
  assert.throws(()=>model.analyzeCohort({context,events:[events[0],events[0]]}),/CAST_ID_UNIQUE_REQUIRED/);
});
check('identical unmodified cap study lineage rejected',()=>{
  assert.throws(()=>analyze(context,{certifiedMaxPerCast:3,capEvidenceID:context.sourceStudyFamilyID}),/INDEPENDENT_CAP_CERTIFICATE_REQUIRED/);
});
check('distinct hypothetical cap stays conditional and research-only',()=>{
  const x=analyze(context,{certifiedMaxPerCast:3,capEvidenceID:'SYNTHETIC_OTHER_FAMILY'});
  assert.equal(x.confidence,0);assert.equal(x.normalizedVerified,false);
  assert.equal(x.economicUse,'PREVIEW_ONLY');
  assert.ok(x.expectedQuantityAnytimeInterval[1]<=3);
});
check('anytime width matches independently evaluated union-bound expression',()=>{
  const n=173,alpha=.05;
  const expected=Math.sqrt(Math.log(2*Math.PI*Math.PI*n*n*7*2/(6*alpha))/(2*n));
  assert.ok(Math.abs(model.width(n,1,alpha)-expected)<1e-13);
});
check('RAW unknown patch rejected',()=>{
  assert.throws(()=>analyze({...context,patchBuild:'UNKNOWN'}),/EXACT_PATCH_REQUIRED/);
});
check('RAW impossible February 30 calendar date rejected',()=>{
  assert.throws(()=>analyze({...context,observationEpoch:'2026-02-30T20:00:00Z'}),/OBSERVATION_EPOCH_REQUIRED/);
});
check('RAW nonleap February 29 calendar date rejected',()=>{
  assert.throws(()=>analyze({...context,observationEpoch:'2026-02-29T20:00:00Z'}),/OBSERVATION_EPOCH_REQUIRED/);
});
check('same cap study family with whitespace cannot masquerade as independent',()=>{
  assert.throws(()=>analyze(context,{certifiedMaxPerCast:3,capEvidenceID:context.sourceStudyFamilyID+' '}),/INDEPENDENT_CAP_CERTIFICATE_REQUIRED/);
});
check('different RAW patch/rank/recipe/skill context must remain distinguishable in serialized output',()=>{
  const a=analyze();
  const changed={...context,patchBuild:'12.0.1',recipeSpellID:999999,
    inputQualityRank:3,outputQualityRank:2,professionSkill:100,
    professionContext:{...context.professionContext,resourcefulnessPercent:80}};
  const b=analyze(changed);
  assert.notDeepEqual(a,b,'A model result must retain a typed context or fingerprint so distinct cohorts cannot silently collapse into one identical record');
});
console.log(JSON.stringify({suite:'F005_MIDNIGHT_ANYTIME_CONTEXT_LINEAGE',
  modelID:model.MODEL_ID,syntheticOnly:true,actualRetailCasts:0,
  passed,failed,cases}));
if(failed)process.exitCode=1;
