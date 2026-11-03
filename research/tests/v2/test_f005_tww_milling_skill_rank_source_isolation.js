'use strict';
// F005 independent TWW milling source-integrity gate. Indexed LotzBoi comment is
// ONE unmeasured historical lineage, not a current-Retail yield distribution.
const assert=require('node:assert/strict');
const e=require('../../evidence/v2/2026-10-30T1032Z-F004-tww-milling-skill-rank.json');
const sr=require('../../evidence/v2/source-reviews/2026-10-30T1032Z-F004-tww-milling-skill-rank-source-review.json');
const expectedPairs=['210796:222619','210797:222619','210798:222618','210799:222612',
 '210800:222613','210801:222614','210802:224800','210803:224801',
 '210804:224802','210805:224803','210806:224804','210807:224805'];
const families=[
 ['Mycobloom',210796,210797,210798,[222618,222619,222620]],
 ['Luredrop',210799,null,null,[222612,222613,222614]],
 ['Orbinid',210802,null,null,[224800,224801,224802]],
 ['Blessing Blossom',210805,null,null,[224803,224804,224805]]];
function guard(d){
 assert.equal(d.role,'evidence-researcher');
 assert.equal(d.source.author,'LotzBoi');
 assert.equal(d.source.lineage,'tww-lotzboi-wowhead-single-author-comment');
 assert.equal(d.source.sourceType,'ORIGINAL_COMMENT_UNVERIFIED_NO_CAST_LOG');
 assert.equal(d.source.mirrors.length,3);
 assert.equal(d.source.mirrorsIndependent,false);
 assert.equal(d.source.independentCohorts,0);
 for(const k of ['publicationDate','actualCastEpoch','patchBuild','completedCasts',
  'zeroInclusiveTotals','refunds','professionSpecGear'])assert.equal(d.source[k],null);
 assert.equal(d.claims.nominalHerbsPerOperation,10);
 assert.equal(d.claims.families.length,4);
 d.claims.families.forEach((f,i)=>{
  const [name,r1,r2,r3,outs]=families[i];
  assert.equal(f.herb,name);assert.equal(f.rank1Input,r1);
  if(r2!==null)assert.equal(f.rank2Input,r2);
  if(r3!==null)assert.equal(f.rank3Input,r3);
  assert.deepEqual(f.outputRanks,outs);
 });
 assert.deepEqual(d.claims.skillRankBands.map(x=>[x.effectiveSkillMin,x.effectiveSkillMax,x.nacreousOutputID,x.rank]),
  [[0,252,222618,1],[253,504,222619,2],[505,null,222620,3]]);
 assert.deepEqual(d.claims.mycobloomInputRankRanges.map(x=>
  [x.inputID,x.rank,x.claimedSkillBonus,x.claimedPositiveYieldMin,x.claimedPositiveYieldMax]),
  [[210796,1,0,4,6],[210797,2,101,5,7],[210798,3,202,6,8]]);
 assert.deepEqual(d.applicability.targetInputOutputPairs,expectedPairs);
 assert.equal(d.applicability.exactSpellID,444181);
 assert.equal(d.applicability.spellAssociation,'INDEXED_FAMILY_ONLY_NOT_VERIFIED_PER_RECIPE_NULL_ROW');
 assert.equal(d.applicability.effectiveSkillDefinition,'CLAIMED_NOT_CLIENT_VERIFIED');
 assert.equal(d.applicability.quantityRanges,'AUTHOR_CLAIMED_POSITIVE_RANGES_NOT_HARD_BOUNDS_OR_MEASURED_DISTRIBUTIONS');
 assert.equal(d.applicability.disposition,'CONTEXT_HYPOTHESIS_ONLY_NO_NEW_MAPPING_ADMISSION');
 for(const k of ['dropChance','yieldMin','yieldMax','expectedQuantity'])
  assert.equal(d.numericEvidence[k],null);
 assert.equal(d.numericEvidence.confidence,0);
 assert.equal(d.numericEvidence.economicUse,'PREVIEW_ONLY');
 assert.equal(d.numericEvidence.normalizedVerified,false);
 for(const k of ['admittedMappings','numericWorkingCells','verifiedExpectedQuantity',
  'confidencePromotions','economicPromotions'])assert.equal(d.exactDeltas[k],0);
 return true;
}
const cases=[];let passed=0,failed=0;
function check(name,fn){try{fn();passed++;cases.push({name,result:'PASS'});}
 catch(err){failed++;cases.push({name,result:'FAIL',detail:String(err.message)});}}
check('full source/economic gate',()=>assert.equal(guard(e),true));
check('one original comment, three mirrors not independent',()=>{
 assert.equal(e.exactDeltas.newOriginalCommentLineages,1);
 assert.equal(e.exactDeltas.mirrorsDeduplicated,3);
 assert.equal(sr.sourceEvents[1].disposition,'DUPLICATE_NOT_INDEPENDENT');
});
check('indexed spell is not proof of exact row recipe',()=>{
 assert.equal(e.applicability.exactSpellID,444181);
 assert.match(e.applicability.spellAssociation,/NOT_VERIFIED/);
});
check('claimed positive ranges are not zero-inclusive E',()=>{
 assert.equal(e.source.completedCasts,null);
 assert.equal(e.numericEvidence.expectedQuantity,null);
 assert.match(e.applicability.quantityRanges,/NOT_HARD_BOUNDS_OR_MEASURED/);
});
check('comment has no observed skill, build or cast epoch',()=>{
 assert.equal(e.source.professionSpecGear,null);
 assert.equal(e.source.patchBuild,null);
 assert.equal(e.source.actualCastEpoch,null);
});
check('thresholds are hypotheses, not live validated gates',()=>{
 assert.equal(e.applicability.effectiveSkillDefinition,'CLAIMED_NOT_CLIENT_VERIFIED');
 assert.equal(e.exactDeltas.confidencePromotions,0);
});
check('guide 5-herb vs spell 10-herb discrepancy remains visible',()=>{
 assert.match(sr.sourceEvents[2].disposition,/CONFLICTS_WITH_INDEXED_10_HERB_SPELL/);
 assert.equal(e.claims.nominalHerbsPerOperation,10);
});
check('previous TWW research is not double counted',()=>{
 assert.equal(sr.priorReports.length,2);
 assert.equal(sr.sourceEvents[4].disposition,'PREVIOUSLY_REVIEWED_NOT_INDEPENDENT_VALIDATION_OF_LOTZBOI');
});
check('all 12 queue29 targets are present exactly once',()=>{
 assert.equal(new Set(e.applicability.targetInputOutputPairs).size,12);
 assert.deepEqual(e.applicability.targetInputOutputPairs,expectedPairs);
});
check('measurement request includes zeros and refunds',()=>{
 assert.match(e.measurementRequest.method,/zero-output casts/);
 assert.match(e.measurementRequest.method,/saved\/refunded herbs/);
});
const mutations=[
 ['fabricated completed casts',d=>d.source.completedCasts=10],
 ['fabricated current cast epoch',d=>d.source.actualCastEpoch='2026-10-30T10:00:00Z'],
 ['fabricated patch',d=>d.source.patchBuild='12.0.1'],
 ['fabricated measured E',d=>d.numericEvidence.expectedQuantity=5],
 ['fabricated confidence',d=>d.numericEvidence.confidence=90],
 ['live economic use',d=>d.numericEvidence.economicUse='LIVE'],
 ['false normalized verification',d=>d.numericEvidence.normalizedVerified=true],
 ['mirrors miscounted independent',d=>d.source.mirrorsIndependent=true],
 ['independent cohort invented',d=>d.source.independentCohorts=1],
 ['mapping admission invented',d=>d.exactDeltas.admittedMappings=1],
 ['skill threshold shifted',d=>d.claims.skillRankBands[1].effectiveSkillMin=254],
 ['yield range shifted',d=>d.claims.mycobloomInputRankRanges[0].claimedPositiveYieldMax=7],
 ['output rank item swapped',d=>d.claims.families[0].outputRanks[2]=222619],
 ['target pair omitted',d=>d.applicability.targetInputOutputPairs.pop()],
 ['unsupported recipe row verified',d=>d.applicability.spellAssociation='VERIFIED_PER_RECIPE']
];
for(const [name,change] of mutations)check('reject '+name,()=>{
 const d=JSON.parse(JSON.stringify(e));change(d);assert.throws(()=>guard(d));
});
console.log(JSON.stringify({suite:'F005_TWW_MILLING_SKILL_RANK_SOURCE_ISOLATION',
 sourceBlobSHA:'1396ef6ce5348e1d0cf9052ef0ad205975c3f869',
 syntheticMutationChecks:mutations.length,independentCurrentRetailCohorts:0,
 passed,failed,cases}));
if(failed)process.exitCode=1;
