'use strict';
// F005 independent source-date and epoch-boundary gate, research-only.
// Blizzard's prospecting-rate entry is under March 31, NOT April 1.
// Official source: https://worldofwarcraft.blizzard.com/en-us/news/24266320
// Blue-post mirror: https://www.bluetracker.gg/wow/topic/us-en/2260898-world-of-warcraft-midnight-hotfixes-april-17/
// No deployment hour, per-gem rate, completed casts, or current economic promotion established.
const assert=require('node:assert/strict');
const m=require('../../tools/models_v2/midnight_prospect_hotfix_epoch_isolation_v1.js');
const c={
 gameMode:'RETAIL',expansion:'MIDNIGHT',method:'PROSPECT',
 stableKey:'midnight:237359:242608:L733',inputItemID:237359,outputItemID:242608,
 sourceType:'RAW_CURRENT_RETAIL',patchBuild:'12.0.5',recipeSpellID:1231127,
 inputQualityRank:2,outputQualityRank:1,nominalInputPerCast:5,
 directReagents:[{itemID:237359,quantity:5}],minimumEligibleSkill:1,professionSkill:1,
 professionContext:{specialization:[],gear:[],unlocks:[],resourcefulnessPercent:0},
 studyFamilyID:'F005_SYNTHETIC_A',sourceLineage:'F005_SYNTHETIC_A',
 observationStart:'2026-03-30T12:00:00Z',observationEnd:'2026-03-30T13:00:00Z'
};
const events=[
 {castID:'a',status:'COMPLETED',outputCount:0,refundedInputUnits:0},
 {castID:'b',status:'COMPLETED',outputCount:2,refundedInputUnits:1},
 {castID:'c',status:'ABORTED'}
];
const at=(start,end=start,overrides={})=>({...c,...overrides,observationStart:start,observationEnd:end});
let passed=0,failed=0;const cases=[];
function check(name,fn){try{fn();passed++;cases.push({name,result:'PASS'});}
 catch(e){failed++;cases.push({name,result:'FAIL',detail:String(e.message)});}}
check('official prospecting-rate entry is dated March 31, 2026',()=>assert.equal(m.OFFICIAL_ENTRY_DATE,'2026-03-31'));
check('official Blizzard URL pinned',()=>assert.equal(m.OFFICIAL_SOURCE_URL,'https://worldofwarcraft.blizzard.com/en-us/news/24266320'));
check('March 30 midday safely pre',()=>assert.equal(m.classifyEpoch('2026-03-30T12:00:00Z'),'PRE_HOTFIX'));
check('March 31 UTC start quarantined',()=>assert.equal(m.classifyEpoch('2026-03-31T00:00:00Z'),'TRANSITION_QUARANTINE'));
check('March 31 UTC midday quarantined',()=>assert.equal(m.classifyEpoch('2026-03-31T12:00:00Z'),'TRANSITION_QUARANTINE'));
check('March 31 UTC end quarantined',()=>assert.equal(m.classifyEpoch('2026-03-31T23:59:59Z'),'TRANSITION_QUARANTINE'));
check('April 1 UTC start quarantined',()=>assert.equal(m.classifyEpoch('2026-04-01T00:00:00Z'),'TRANSITION_QUARANTINE'));
check('April 1 UTC end quarantined',()=>assert.equal(m.classifyEpoch('2026-04-01T23:59:59Z'),'TRANSITION_QUARANTINE'));
check('April 2 conservative buffer quarantined',()=>assert.equal(m.classifyEpoch('2026-04-02T12:00:00Z'),'TRANSITION_QUARANTINE'));
check('April 3 UTC safely post under current conservative policy',()=>assert.equal(m.classifyEpoch('2026-04-03T00:00:00Z'),'POST_HOTFIX'));
check('March 31 local +14 quarantined even if UTC March 30',()=>assert.equal(m.classifyEpoch('2026-03-31T00:30:00+14:00'),'TRANSITION_QUARANTINE'));
check('March 31 local -12 quarantined',()=>assert.equal(m.classifyEpoch('2026-03-31T23:30:00-12:00'),'TRANSITION_QUARANTINE'));
check('March 30 local -07 crossing UTC March 31 quarantined',()=>assert.equal(m.classifyEpoch('2026-03-30T23:30:00-07:00'),'TRANSITION_QUARANTINE'));
check('April 3 local +14 crossing UTC April 2 quarantined',()=>assert.equal(m.classifyEpoch('2026-04-03T00:30:00+14:00'),'TRANSITION_QUARANTINE'));
check('March 30 local +14 safely pre',()=>assert.equal(m.classifyEpoch('2026-03-30T10:00:00+14:00'),'PRE_HOTFIX'));
check('April 4 local +14 safely post',()=>assert.equal(m.classifyEpoch('2026-04-04T10:00:00+14:00'),'POST_HOTFIX'));
check('March 30 to March 31 cohort quarantined',()=>assert.equal(m.analyzeCohort({context:at('2026-03-30T12:00:00Z','2026-03-31T12:00:00Z'),events}).epoch,'TRANSITION_QUARANTINE'));
check('March 31 to April 3 cohort quarantined',()=>assert.equal(m.analyzeCohort({context:at('2026-03-31T12:00:00Z','2026-04-03T12:00:00Z'),events}).epoch,'TRANSITION_QUARANTINE'));
check('zero-inclusive cast P and E remain separate',()=>{const r=m.analyzeCohort({context:c,events});assert.equal(r.observedP,.5);assert.equal(r.observedUnconditionalE,1);});
check('gross and refunds not conflated with casts',()=>{const r=m.analyzeCohort({context:c,events});assert.equal(r.completedCasts,2);assert.equal(r.grossInput,10);assert.equal(r.refundedInput,1);assert.equal(r.netConsumedInput,9);});
check('no live economic or tooltip eligibility',()=>{const r=m.analyzeCohort({context:c,events});assert.equal(r.confidence,0);assert.equal(r.economicUse,'PREVIEW_ONLY');assert.equal(r.normalizedVerified,false);assert.equal(r.liveEconomicEligible,false);assert.equal(r.tooltipOnlyEligible,false);});
check('epoch comparison remains noncausal',()=>{const pre=m.analyzeCohort({context:c,events});const post=m.analyzeCohort({context:at('2026-04-04T12:00:00Z','2026-04-04T13:00:00Z',{studyFamilyID:'F005_SYNTHETIC_B',sourceLineage:'F005_SYNTHETIC_B'}),events});const r=m.compareEpochs(pre,post);assert.equal(r.causalAttribution,'NOT_IDENTIFIED');assert.equal(r.postHotfixEffectSize,'NOT_VERIFIED');});
check('duplicate study lineage rejected',()=>{const pre=m.analyzeCohort({context:c,events});const post=m.analyzeCohort({context:at('2026-04-04T12:00:00Z','2026-04-04T13:00:00Z',{studyFamilyID:'F005_SYNTHETIC_B',sourceLineage:'F005_SYNTHETIC_A'}),events});assert.throws(()=>m.compareEpochs(pre,post),/DUPLICATE_SOURCE_LINEAGE/);});
check('profile mismatch rejected',()=>{const pre=m.analyzeCohort({context:c,events});const post=m.analyzeCohort({context:at('2026-04-04T12:00:00Z','2026-04-04T13:00:00Z',{studyFamilyID:'F005_SYNTHETIC_B',sourceLineage:'F005_SYNTHETIC_B',professionSkill:2}),events});assert.throws(()=>m.compareEpochs(pre,post),/PROFILE_MISMATCH/);});
check('impossible February 29 rejected',()=>assert.throws(()=>m.classifyEpoch('2026-02-29T12:00:00Z'),/EPOCH_CALENDAR/));
check('all seven target keys retained',()=>assert.equal(Object.keys(m.TARGETS).length,7));
console.log(JSON.stringify({suite:'F005_MIDNIGHT_PROSPECT_MARCH31_OFFICIAL_EPOCH',sourceType:'OFFICIAL_BLIZZARD_DATED_ENTRY',syntheticOnly:true,independentCurrentRetailCastHoldouts:0,passed,failed,cases}));
if(failed)process.exitCode=1;
