'use strict';
// F005 independent research-only eligibility/provenance regression.
// Run: node research/tests/v2/test_f005_midnight_diamond_trait_eligibility.js
// No synthetic test proves in-game unlock gating or current-Retail P/E.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const e=JSON.parse(fs.readFileSync(path.resolve(__dirname,'../../evidence/v2/2026-10-30T0826Z-F004-midnight-diamond-ore-trait-gates.json'),'utf8'));
const p=JSON.parse(fs.readFileSync(path.resolve(__dirname,'../../coordination/completion-priorities.json'),'utf8'));
const expected=[
 [106981,'Copper Consumer','Refulgent Copper',[237359,237361]],
 [106980,'Tin-vestigator','Umbral Tin',[237362,237363]],
 [106979,'Silver Scrapper','Brilliant Silver',[237364,237365]],
 [106978,'Thorium Thresher','Dazzling Thorium',[237366]]
];
let passed=0,failed=0;const cases=[];
function test(name,fn){try{fn();passed++;cases.push({name,result:'PASS'});}
catch(err){failed++;cases.push({name,result:'FAIL',detail:String(err.message)});}}
const copy=x=>JSON.parse(JSON.stringify(x));
function identity(x){
 assert.equal(x.traits.length,4);
 for(let i=0;i<4;i++){
  const t=x.traits[i],q=expected[i];
  assert.equal(t.traitID,q[0]);assert.equal(t.traitName,q[1]);assert.equal(t.ore,q[2]);
  assert.deepEqual(t.oreIDs,q[3]);
  assert.equal(t.url,'https://www.wowhead.com/profession-trait/'+q[1].toLowerCase().replaceAll(' ','-')+'-'+q[0]);
  assert.ok(t.exactText.includes(q[2])&&t.exactText.includes('Eversong Diamonds'));
 }
 const ids=x.traits.flatMap(t=>t.oreIDs);
 assert.equal(new Set(ids).size,7);
 assert.equal(new Set(x.traits.map(t=>t.traitID)).size,4);
 assert.equal(x.candidateContext.diamondItemID,242608);
 assert.equal(x.identityCaveat.alternateIndexedID,242712);
 assert.equal(x.identityCaveat.decision,'PRESERVE_EXISTING_242608_MAPPING_NO_CHANGE');
 assert.equal(x.candidateContext.targetPriorityKeys.length,7);
 assert.equal(new Set(x.candidateContext.targetPriorityKeys).size,7);
 for(const id of ids)assert.equal(x.candidateContext.targetPriorityKeys.filter(k=>k.startsWith('midnight:'+id+':242608:')).length,1);
}
function safety(x){
 assert.equal(x.numericFieldConfidence,0);
 assert.equal(x.economicUse,'PREVIEW_ONLY');
 assert.equal(x.normalizedVerified,false);
 assert.equal(x.liveEVEligible,false);
 assert.equal(x.tooltipOnlyPromotion,false);
 assert.deepEqual(x.fourEconomicFields,{dropChance:null,yieldMin:null,yieldMax:null,expectedQuantity:null});
 for(const t of x.traits){
  assert.equal(t.actualCompletedCasts,null);assert.equal(t.measuredDropChance,null);
  assert.equal(t.measuredExpectedQuantity,null);assert.equal(t.actualCastEpoch,null);
  assert.equal(t.gameBuild,null);
 }
}
test('four exact trait identities and seven ore mappings',()=>identity(e));
test('all seven keys already in canonical priority backlog',()=>{
 const records=new Set(p.records.map(r=>r.recordID));
 for(const key of e.candidateContext.targetPriorityKeys)assert.ok(records.has(key),key);
});
test('recipe and five-input nominal batch are context only',()=>{
 assert.equal(e.candidateContext.recipeSpellID,1231127);
 assert.equal(e.candidateContext.nominalOreUnitsPerOperation,5);
 assert.equal(e.candidateContext.method,'Prospect');
});
test('zero verified numeric cells and preview-only economic isolation',()=>safety(e));
test('guide lineage is not counted as independent cast families',()=>{
 assert.ok(e.originalDataLineage.includes('ONE_GAME_DATA_ORIGIN'));
 assert.equal(e.guideCrosschecks.length,3);
 for(const g of e.guideCrosschecks)assert.equal(g.sourceFamily,'GUIDE_INTERPRETATION_NOT_INDEPENDENT_CAST_COHORT');
});
test('unknown unlock and minimum point requirements not asserted as measured',()=>{
 assert.equal(e.candidateContext.unlocksUnknown,'KEEP_UNVERIFIED_PREVIEW_NOT_ZERO_OR_POSITIVE_LIVE_RATE');
 for(const t of e.traits){
  assert.equal(t.minimumNodePoints,'GUIDE_SAYS_1_KP_NOT_CLIENT_VERIFIED');
  assert.equal(t.observationDate,null);
 }
});
test('alternate catalog ID not silently admitted',()=>{
 assert.ok(e.candidateContext.targetPriorityKeys.every(k=>!k.includes(':242712:')));
});
const mutants=[
 ['fabricated positive P',m=>m.fourEconomicFields.dropChance=.02,safety],
 ['fabricated verified E',m=>m.traits[0].measuredExpectedQuantity=.1,safety],
 ['fabricated cast count',m=>m.traits[0].actualCompletedCasts=100,safety],
 ['fabricated patch build',m=>m.traits[0].gameBuild='12.0.5',safety],
 ['promoted confidence',m=>m.numericFieldConfidence=90,safety],
 ['promoted live economic use',m=>m.economicUse='LIVE',safety],
 ['promoted normalized verification',m=>m.normalizedVerified=true,safety],
 ['enabled live EV',m=>m.liveEVEligible=true,safety],
 ['swapped trait ID',m=>m.traits[0].traitID=106980,identity],
 ['omitted ore rank',m=>m.traits[1].oreIDs.pop(),identity],
 ['duplicated ore ID',m=>m.traits[2].oreIDs[1]=237364,identity],
 ['substituted alternate output ID',m=>m.candidateContext.diamondItemID=242712,identity]
];
for(const [name,mutate,validate] of mutants)test('reject '+name,()=>{
 const m=copy(e);mutate(m);assert.throws(()=>validate(m));
});
console.log(JSON.stringify({suite:'F005_MIDNIGHT_DIAMOND_TRAIT_ELIGIBILITY',
 source:e.runID,syntheticMutants:mutants.length,independentRetailCastFamilies:0,
 passed,failed,cases}));
if(failed)process.exitCode=1;
