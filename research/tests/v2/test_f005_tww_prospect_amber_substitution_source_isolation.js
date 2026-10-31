'use strict';
// F005 independent source-fidelity/anti-promotion gate for F004 TWW prospecting evidence.
// Source checks are pinned to indexed Wowhead PeaEsk comment, four game-data trait pages,
// and Blizzard's dated October 25 2024 hotfix entry. NOT a current-Retail yield validation.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const evidence=JSON.parse(fs.readFileSync(path.join(__dirname,'../../evidence/v2/2026-10-30T1428Z-F004-tww-prospecting-amber-substitution-epoch.json'),'utf8'));
const expectedTraits=[[98659,212508,'Sapphire'],[98660,212495,'Ruby'],[98661,212511,'Onyx'],[98662,212505,'Emerald']];
const expectedCohorts=[
 [210937,2,[[212511,20],[212495,13],[212498,33],[null,11],[213398,51]],128],
 [210934,2,[[212508,20],[212505,15],[212498,35],[null,13],[213398,35]],118],
 [210931,2,[[212498,35],[213398,85],[null,22]],142]
];
function guard(x){
 const fail=(ok,code)=>{if(!ok)throw Error(code)};
 fail(x.schemaVersion==='1.0.0'&&x.role==='evidence-researcher','ROLE_SCHEMA');
 fail(x.traitMechanics.sourceFamily==='WOWHEAD_GAME_DATA_PROFESSION_TRAIT_FOUR_PAGES_ONE_LINEAGE','TRAIT_LINEAGE');
 fail(x.traitMechanics.amberItemID===212498,'AMBER_ID');
 fail(x.traitMechanics.traits.length===4,'TRAIT_COUNT');
 const seen=new Set();
 for(let i=0;i<4;i++){
  const t=x.traitMechanics.traits[i],e=expectedTraits[i];
  fail(t.traitID===e[0]&&t.outputItemID===e[1]&&t.name===e[2],'TRAIT_ID_OUTPUT');
  fail(!seen.has(t.traitID),'DUPLICATE_TRAIT');seen.add(t.traitID);
  fail(t.sourceURL==='https://www.wowhead.com/profession-trait/'+e[2].toLowerCase()+'-'+e[0],'TRAIT_URL');
  fail(t.wording.includes('instead of an Ambivalent Amber')&&t.wording.includes('1% chance'),'SUBSTITUTION_WORDING');
  fail(t.interpretation==='AMBER_SUBSTITUTION_CONDITIONAL_NOT_UNCONDITIONAL_GEM_PER_CAST'&&t.perPointProbabilityInterpretation==='NOT_VALIDATED_IN_GAME','NO_UNCONDITIONAL_RATE');
 }
 fail(x.traitMechanics.mechanicsInterpretation.includes('Do not directly add pointPercent'),'NO_RATE_PROMOTION');
 const h=x.historicalPatchBoundary;
 fail(h.date==='2024-10-25'&&h.blizzardArticleID==='24148555','HOTFIX_DATE');
 fail(h.primaryDirectFetch==='HTTP_403_NOT_DIRECTLY_READ','NO_FAKE_DIRECT_SOURCE');
 fail(h.changes.length===3&&h.changes.some(s=>s.includes('every Prospecting action')),'HOTFIX_MECHANICS');
 fail(h.castEpochGuard.includes('unknown date cannot be assigned pre/post'),'UNKNOWN_EPOCH_GUARD');
 fail(h.interpretationGuard.includes('not a guarantee of each specific byproduct'),'NO_EACH_BYPRODUCT_GUARANTEE');
 const study=x.originalHistoricalCohort;
 fail(study.canonicalStudyID==='wowhead-peaesk-algari-prospecting-three-r2-ore-summaries'&&study.independentOriginalAuthorFamilies===1,'SINGLE_AUTHOR_FAMILY');
 fail(study.sourceAuthor==='PeaEsk'&&study.sourceURL==='https://www.wowhead.com/spell=434018/algari-prospecting','STUDY_SOURCE');
 fail(study.cohorts.length===3,'COHORT_COUNT');
 let n=0;
 for(let i=0;i<3;i++){
  const c=study.cohorts[i],e=expectedCohorts[i];
  fail(c.inputItemID===e[0]&&c.inputRank===e[1]&&c.spellID===434018,'ORE_RANK_RECIPE');
  fail(c.outputs.length===e[2].length&&c.reportedOutputs.length===e[2].length,'OUTPUT_ROWS');
  for(let j=0;j<e[2].length;j++){
   const r=c.reportedOutputs[j],o=c.outputs[j],v=e[2][j];
   fail(r.itemID===v[0]&&r.reportedCount===v[1]&&o[1]===v[0]&&o[2]===v[1],'SOURCE_COUNTS');
  }
  fail(c.reportedOutputs.reduce((a,r)=>a+r.reportedCount,0)===e[3]&&c.reportedOutputTotal===e[3],'OUTPUT_TOTAL');
  fail(c.actualCompletedCasts===null&&c.resourcefulnessRefunds===null&&c.skill===null&&c.specialization===null&&c.gear===null&&c.outputRank===null,'UNKNOWN_CONTEXT');
  fail(c.observationDate===null&&c.publicationDate===null,'UNKNOWN_OBSERVATION_DATE');
  fail(c.verifiedExpectedQuantity===null&&c.verifiedDropChance===null,'NO_VERIFIED_P_E');
  fail(c.nominalUnitsConfidence==='INFERRED_FROM_AUTHOR_LABEL_NOT_CONFIRMED','NOMINAL_UNITS_NOT_CASTS');
  n+=c.reportedOutputs.length;
 }
 fail(n===13&&study.rawReportedOutputCountCells===13,'THIRTEEN_COUNTS');
 fail(study.denominatorCaveat.includes('NOT verified E denominator'),'DENOMINATOR_UNVERIFIED');
 fail(study.negativeEvidenceGuard.includes('not an observed zero'),'NO_ABSENCE_AS_ZERO');
 fail(study.crossStudyCaveat.includes('Do not pool'),'NO_CROSS_STUDY_POOL');
 fail(x.exactTargetKeys.length===8&&new Set(x.exactTargetKeys).size===8&&x.exactTargetKeys.every(s=>s.startsWith('candidate:conditional:prospect:')),'CANDIDATE_ONLY_TARGETS');
 const w=x.workingAndEconomicStatus;
 fail(w.newAdmittedMappings===0&&w.newWorkingNumericCells===0&&w.newVerifiedExpectedQuantityCells===0,'NO_ADMISSIONS_OR_VERIFIED_E');
 fail(w.newConfidencePromotions===0&&w.newEconomicPromotions===0,'NO_PROMOTIONS');
 fail(w.unsupportedFallbackConfidence===0&&w.economicUse==='PREVIEW_ONLY'&&w.normalizedVerified===false,'PREVIEW_ISOLATION');
 fail(w.workingCoverageBefore==='4072/4072'&&w.workingCoverageAfter==='4072/4072'&&w.evidenceMissingCellsBefore===514&&w.evidenceMissingCellsAfter===514,'CANONICAL_COUNTERS');
 return true;
}
const copy=x=>JSON.parse(JSON.stringify(x));
let passed=0,failed=0;const cases=[];
function test(name,fn){try{fn();passed++;cases.push({name,result:'PASS'});}catch(e){failed++;cases.push({name,result:'FAIL',detail:String(e.message)});}}
function mutate(name,fn){test(name,()=>{const x=copy(evidence);fn(x);assert.throws(()=>guard(x));});}
test('full evidence contract and independent source-count transcription',()=>assert.equal(guard(evidence),true));
for(let i=0;i<4;i++)test('trait '+expectedTraits[i][2]+' is amber substitution, not unconditional gem P',()=>{
 const t=evidence.traitMechanics.traits[i];assert.equal(t.traitID,expectedTraits[i][0]);assert.equal(t.outputItemID,expectedTraits[i][1]);
 assert.ok(t.wording.includes('instead of an Ambivalent Amber'));
});
for(let i=0;i<3;i++)test('PeaEsk rank-2 ore '+expectedCohorts[i][0]+' totals and unknown cast basis',()=>{
 const c=evidence.originalHistoricalCohort.cohorts[i];assert.equal(c.reportedOutputTotal,expectedCohorts[i][3]);
 assert.equal(c.actualCompletedCasts,null);assert.equal(c.verifiedExpectedQuantity,null);
});
test('hotfix October 25 date and byproduct scope retained',()=>{assert.equal(evidence.historicalPatchBoundary.date,'2024-10-25');assert.ok(evidence.historicalPatchBoundary.interpretationGuard.includes('not a guarantee'));});
test('eight conditional candidate keys remain unadmitted',()=>{assert.equal(evidence.exactTargetKeys.length,8);assert.equal(evidence.workingAndEconomicStatus.newAdmittedMappings,0);});
test('economic isolation and unchanged canonical numeric coverage',()=>{assert.equal(evidence.workingAndEconomicStatus.economicUse,'PREVIEW_ONLY');assert.equal(evidence.workingAndEconomicStatus.workingCoverageAfter,'4072/4072');});
mutate('reject fabricated unconditional 1%-per-point cast probability',x=>x.traitMechanics.traits[0].interpretation='UNCONDITIONAL_GEM_PER_CAST');
mutate('reject substitution target changed from Amber',x=>x.traitMechanics.traits[1].wording='1% chance to acquire a Ruby on every cast');
mutate('reject wrong gem trait ID',x=>x.traitMechanics.traits[2].traitID=98660);
mutate('reject wrong gem item ID',x=>x.traitMechanics.traits[3].outputItemID=212511);
mutate('reject duplicate trait entry',x=>x.traitMechanics.traits[3]=copy(x.traitMechanics.traits[0]));
mutate('reject incorrect October hotfix date',x=>x.historicalPatchBoundary.date='2024-10-30');
mutate('reject unsupported direct primary fetch claim',x=>x.historicalPatchBoundary.primaryDirectFetch='HTTP_200_FULLY_VERIFIED');
mutate('reject each-byproduct-per-cast guarantee',x=>x.historicalPatchBoundary.interpretationGuard='Every individual byproduct guaranteed each cast');
mutate('reject fabricated completed cast denominator',x=>x.originalHistoricalCohort.cohorts[0].actualCompletedCasts=20);
mutate('reject fabricated refund-free cohort',x=>x.originalHistoricalCohort.cohorts[1].resourcefulnessRefunds=0);
mutate('reject fabricated observation epoch',x=>x.originalHistoricalCohort.cohorts[2].observationDate='2024-10-26');
mutate('reject invented verified E from nominal ore',x=>x.originalHistoricalCohort.cohorts[0].verifiedExpectedQuantity=1.0);
mutate('reject altered source output count',x=>x.originalHistoricalCohort.cohorts[1].reportedOutputs[0].reportedCount=21);
mutate('reject altered source output ID',x=>x.originalHistoricalCohort.cohorts[0].outputs[0][1]=212508);
mutate('reject inferred negative eligibility as zero',x=>x.originalHistoricalCohort.negativeEvidenceGuard='Unreported outputs are observed zero');
mutate('reject synthetic second independent study family',x=>x.originalHistoricalCohort.independentOriginalAuthorFamilies=2);
mutate('reject conditional mapping admission',x=>x.workingAndEconomicStatus.newAdmittedMappings=1);
mutate('reject confidence promotion',x=>x.workingAndEconomicStatus.newConfidencePromotions=1);
mutate('reject economic promotion',x=>x.workingAndEconomicStatus.economicUse='LIVE');
mutate('reject working coverage regression',x=>x.workingAndEconomicStatus.workingCoverageAfter='4071/4072');
console.log(JSON.stringify({suite:'F005_TWW_PROSPECT_AMBER_SUBSTITUTION_SOURCE_ISOLATION',syntheticMutationsOnly:true,independentCurrentRetailHoldouts:0,passed,failed,cases}));
if(failed)process.exitCode=1;
