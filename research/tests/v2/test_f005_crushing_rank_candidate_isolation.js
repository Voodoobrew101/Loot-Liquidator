'use strict';
// F005 independent structural QA of F004 Midnight Crushing rank disposition.
// Tests research-policy and candidate/eligibility isolation, NOT WoW client facts.
const assert=require('node:assert/strict');
const evidence=require('../../evidence/v2/2026-10-30T0432Z-F004-crushing-rank-identity-and-reagent-variant.json');
let passed=0,failed=0;const cases=[];
function check(name,fn){try{fn();passed++;cases.push({name,result:'PASS'});}
catch(e){failed++;cases.push({name,result:'FAIL',detail:e.message});}}
const grid=evidence.candidateContextGrid;
check('six unique rank-labelled item identities',()=>{
  assert.equal(evidence.itemRankIdentityEvidence.length,6);
  assert.equal(new Set(evidence.itemRankIdentityEvidence.map(x=>x.itemID)).size,6);
  assert.ok(evidence.itemRankIdentityEvidence.every(x=>Number.isSafeInteger(x.itemID)&&[1,2].includes(x.qualityRank)&&x.url));
});
check('candidate gem ranks are not invented mappings',()=>{
  assert.deepEqual(grid.gemIDs,[242553,242723]);assert.equal(grid.candidateTriples,8);
  assert.equal(grid.candidateTriples,grid.gemIDs.length*grid.stoneIDs.length*grid.dustIDs.length);
  assert.equal(grid.admittedTriples,0);assert.equal(evidence.newMappingsAdmitted,0);
});
check('recipe reagent variant remains a separate unresolved dimension',()=>{
  assert.deepEqual(grid.stoneIDs,[242788,242789]);
  assert.equal(evidence.recipeFacts.stoneRankAcceptedBySelector,null);
  assert.equal(evidence.recipeFacts.gemRankAcceptedBySelector,null);
  assert.equal(evidence.recipeFacts.dustOutputRankByInputAndSkill,null);
});
check('rank catalog is one source family, not six independent cast cohorts',()=>{
  assert.match(evidence.sourceLineages.rankCatalog,/ONE_SOURCE_FAMILY/);
  assert.equal(evidence.sourceLineages.newIndependentCompletedCastCohorts,0);
});
check('guide alternative operation is not misadmitted as spell 1231132 output',()=>{
  assert.equal(evidence.newSourceConflict.disposition,'DO_NOT_ADMIT_SINGLE_GEM_TO_STONE_AS_SPELL1231132_OUTPUT');
  assert.equal(evidence.recipeFacts.spellID,1231132);
});
check('two exact backlog targets are explicitly unadmitted',()=>{
  assert.equal(evidence.targets.length,2);
  assert.equal(new Set(evidence.targets).size,2);
  assert.ok(evidence.targets.every(x=>x.startsWith('universe-audit:midnight:crush:spell1231132:')));
});
check('each candidate has nullable original evidence and confidence zero',()=>{
  assert.equal(evidence.perTargetEconomicEvidence.length,2);
  for(const row of evidence.perTargetEconomicEvidence){
    assert.ok(evidence.targets.includes(row.stableKey));
    for(const k of ['dropChance','yieldMin','yieldMax','expectedQuantity'])assert.equal(row[k],null);
    assert.equal(row.confidence,0);
  }
});
check('no candidate can affect live economics',()=>{
  for(const row of evidence.perTargetEconomicEvidence){
    assert.equal(row.economicUse,'PREVIEW_ONLY');assert.equal(row.normalizedVerified,false);
    assert.equal(row.economicValueUseAllowed,false);assert.equal(row.selectorEligibility,'UNKNOWN');
  }
});
check('no new numeric working or verified E cells',()=>{
  assert.equal(evidence.workingNumericCellsAdded,0);
  assert.equal(evidence.newEconomicExpectedQuantityCells,0);
  assert.equal(evidence.confidencePromotions,0);
  assert.equal(evidence.existingWorkingCoverageChanged,false);
});
check('resourcefulness observation does not become measured refund evidence',()=>{
  assert.equal(evidence.newFirstPersonUIContext.actualCasts,null);
  assert.equal(evidence.newFirstPersonUIContext.refundCounts,null);
});
check('measurement protocol demands exact selector and cast context',()=>{
  const p=evidence.nextMeasurement.protocol;
  assert.match(p,/selectable\/not-selectable/);assert.match(p,/actual completed casts/);
  assert.match(p,/refunds separately/);
});
console.log(JSON.stringify({suite:'F005_CRUSHING_RANK_CANDIDATE_ISOLATION',
  sourceType:'RESEARCH_EVIDENCE_STRUCTURAL_QA_NOT_GAME_VERIFICATION',
  passed,failed,cases}));
if(failed)process.exitCode=1;
