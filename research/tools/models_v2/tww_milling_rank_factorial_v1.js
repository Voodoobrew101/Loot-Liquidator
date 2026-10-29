'use strict';
// Research-only TWW milling rank-factorial observation model. No live valuation export.
const assert = require('node:assert/strict');
const MODEL_ID = 'tww-milling-rank-factorial-v1.0.0';
const POLICY = Object.freeze({confidence:0,economicUse:'PREVIEW_ONLY',normalizedVerified:false,evidencePromotion:false});
const REQUIRED = ['patchBuild','recipeSpellID','herbSpecies','professionSkill','professionContext','outputRankIDs'];
function fail(message){ throw new Error(message); }
function positiveInt(n){return Number.isSafeInteger(n)&&n>0;}
function validateContext(c){
  if(!c||typeof c!=='object')fail('missing context');
  for(const k of REQUIRED)if(c[k]===null||c[k]===undefined||c[k]===''||(typeof c[k]==='string'&&c[k].toUpperCase()==='UNKNOWN'))fail('unknown context: '+k);
  if(c.recipeSpellID!==444181||!positiveInt(c.professionSkill))fail('invalid recipe/skill');
  if(!c.professionContext||typeof c.professionContext!=='object')fail('missing profession context');
  for(const k of ['specialization','gear','resourcefulness','unlocks'])if(c.professionContext[k]===undefined||c.professionContext[k]===null||c.professionContext[k]==='UNKNOWN')fail('missing profession context: '+k);
  if(!positiveInt(c.outputRankIDs[1])||!positiveInt(c.outputRankIDs[2])||c.outputRankIDs[1]===c.outputRankIDs[2])fail('output rank identity');
  if(c.nominalHerbsPerCast!==10)fail('nominal input must be ten herbs for this model');
}
function contextKey(c){validateContext(c);return JSON.stringify(REQUIRED.map(k=>c[k]).concat([c.nominalHerbsPerCast]));}
function summarizeCohort(cohort, context){
  if(!cohort||![1,2].includes(cohort.inputRank)||!positiveInt(cohort.inputItemID))fail('input rank or item identity missing');
  if(!Array.isArray(cohort.casts)||!cohort.casts.length)fail('no completed casts');
  if(!positiveInt(cohort.actualCompletedCasts)||cohort.actualCompletedCasts!==cohort.casts.length)fail('completed cast denominator mismatch');
  if(!Number.isSafeInteger(cohort.abortedRequests)||cohort.abortedRequests<0)fail('aborted request count missing');
  if(!Number.isSafeInteger(cohort.refundedHerbs)||cohort.refundedHerbs<0)fail('refund ledger missing');
  if(cohort.grossHerbs!==10*cohort.actualCompletedCasts||cohort.netHerbs!==cohort.grossHerbs-cohort.refundedHerbs||cohort.refundedHerbs>cohort.grossHerbs)fail('gross/net/refund ledger mismatch');
  const seen=new Set(),sums={1:0,2:0},hits={1:0,2:0},min={1:Infinity,2:Infinity},max={1:0,2:0},rankDifferences=[];let coHits=0,castRefundTotal=0,castRefundCount=0;
  for(const cast of cohort.casts){
    if(!cast||typeof cast.castID!=='string'||!cast.castID||seen.has(cast.castID))fail('missing or duplicate cast ID');
    seen.add(cast.castID);
    if(cast.completed!==true)fail('aborted request in completed cast list');
    if(!cast.outputs||Object.keys(cast.outputs).sort().join(',')!=='1,2')fail('missing zero-inclusive rank output vector');
    if(cast.refundedHerbs!==undefined){
      if(!Number.isSafeInteger(cast.refundedHerbs)||cast.refundedHerbs<0||cast.refundedHerbs>10)fail('invalid cast refund');
      castRefundTotal+=cast.refundedHerbs;castRefundCount++;
    }
    for(const rank of [1,2]){
      const y=cast.outputs[rank];if(!Number.isSafeInteger(y)||y<0)fail('invalid cast output');
      sums[rank]+=y;if(y>0){hits[rank]++;min[rank]=Math.min(min[rank],y);max[rank]=Math.max(max[rank],y);}
    }
    if(cast.outputs[1]>0&&cast.outputs[2]>0)coHits++;
    rankDifferences.push(cast.outputs[2]-cast.outputs[1]);
  }
  if(castRefundCount!==0&&castRefundCount!==cohort.actualCompletedCasts)fail('partial per-cast refund ledger');
  if(castRefundCount&&castRefundTotal!==cohort.refundedHerbs)fail('per-cast refund sum mismatch');
  const n=cohort.actualCompletedCasts;
  const byOutputRank={};
  for(const rank of [1,2])byOutputRank[rank]={outputItemID:context.outputRankIDs[rank],dropChance:hits[rank]/n,expectedQuantity:sums[rank]/n,observedPositiveYieldMin:hits[rank]?min[rank]:null,observedPositiveYieldMax:hits[rank]?max[rank]:null,positiveRangeApplicable:hits[rank]>0,observedZeroCasts:n-hits[rank],observedSuccessCasts:hits[rank],...POLICY};
  const meanDifference=rankDifferences.reduce((a,b)=>a+b,0)/n;
  const varianceDifference=n>1?rankDifferences.reduce((a,b)=>a+(b-meanDifference)**2,0)/(n-1):null;
  return {inputRank:cohort.inputRank,inputItemID:cohort.inputItemID,actualCompletedCasts:n,abortedRequests:cohort.abortedRequests,grossHerbs:cohort.grossHerbs,refundedHerbs:cohort.refundedHerbs,netHerbs:cohort.netHerbs,coOutputHitCasts:coHits,byOutputRank,withinCastOutputRankDifference:{mean:meanDifference,sampleVariance:varianceDifference}};
}
function analyzeMatchedRankCohorts(input){
  if(!input||!Array.isArray(input.cohorts)||input.cohorts.length!==2)fail('requires two input rank cohorts');
  const ctx=input.context;contextKey(ctx);
  if(!input.sourceStudyFamilyID||!input.observationEpoch||!input.sourceType)fail('source lineage/epoch missing');
  if(input.sourceType!=='SYNTHETIC'&&input.sourceType!=='RAW_CURRENT_RETAIL')fail('unapproved source type');
  if(input.sourceType==='RAW_CURRENT_RETAIL'&&!/^\d+\.\d+\.\d+/.test(ctx.patchBuild))fail('current Retail patch version must be explicit');
  const cohorts=input.cohorts.map(c=>{if(contextKey(c.context)!==contextKey(ctx))fail('context mismatch');return summarizeCohort(c,ctx);});
  if(cohorts[0].inputRank===cohorts[1].inputRank||cohorts[0].inputItemID===cohorts[1].inputItemID)fail('input ranks must be distinct item IDs');
  const a=cohorts.find(c=>c.inputRank===1),b=cohorts.find(c=>c.inputRank===2);
  const e11=a.byOutputRank[1].expectedQuantity,e12=a.byOutputRank[2].expectedQuantity,e21=b.byOutputRank[1].expectedQuantity,e22=b.byOutputRank[2].expectedQuantity;
  const vA=a.withinCastOutputRankDifference.sampleVariance,vB=b.withinCastOutputRankDifference.sampleVariance;
  const descriptiveInteractionSE=vA===null||vB===null?null:Math.sqrt(vA/a.actualCompletedCasts+vB/b.actualCompletedCasts);
  return {modelID:MODEL_ID,sourceStudyFamilyID:input.sourceStudyFamilyID,observationEpoch:input.observationEpoch,sourceType:input.sourceType,context:ctx,cohorts:[a,b],contrasts:{inputRankEffectAtOutputRank1:e21-e11,inputRankEffectAtOutputRank2:e22-e12,outputRankEffectAtInputRank1:e12-e11,outputRankEffectAtInputRank2:e22-e21,interactionDifferenceInDifferences:(e22-e12)-(e21-e11),descriptiveInteractionSE,uncertaintyStatus:'DESCRIPTIVE_IID_APPROXIMATION_NOT_AN_INDEPENDENT_CONFIDENCE_INTERVAL'},applicability:'OBSERVED_MATCHED_CONTEXT_ONLY_NOT_BASELINE_TRANSFER',...POLICY};
}
function auditHistoricalTwoAxisEvidence(){
  return {modelID:MODEL_ID,sourceLineages:[
    {id:'tww-2024-aug-beta-milling-rank-observation',epoch:'2024-08-21_BETA',fixedInputRank:1,outputRank1MeanPerNominal10:13,outputRank2MeanPerNominal10:11,withinSourceOutputRankContrast:-2,actualCompletedCasts:null,exactItemIDs:null},
    {id:'tww-2024-nov-r2-pigment-herb-rank-comment',epoch:'2024-11-02_LIVE_UNVERIFIED',fixedOutputRank:2,inputRank1ApproxPerNominal10:11,inputRank2ApproxPerNominal10:13,withinSourceInputRankContrastApprox:2,actualCompletedCasts:null,exactItemIDs:null}
  ],crossSourceRankInteraction:'NOT_IDENTIFIABLE',currentRetailExpectedQuantity:null,currentRetailDropChance:null,currentRetailYieldMin:null,currentRetailYieldMax:null,reason:'Different source families/epochs, missing IDs, cast denominators and profession contexts; do not combine 3 corners into a 2x2 panel',...POLICY};
}
function selfTest(){
  let tests=0;const eq=(a,b)=>{assert.deepEqual(a,b);tests++},throws=(fn)=>{assert.throws(fn);tests++};
  const ctx={patchBuild:'2026-10-29-test',recipeSpellID:444181,herbSpecies:'SYNTHETIC_SAME_SPECIES',professionSkill:100,professionContext:{specialization:'fixed',gear:'fixed',resourcefulness:'fixed-percent',unlocks:'fixed',multicraft:'fixed-percent'},outputRankIDs:{1:9001,2:9002},nominalHerbsPerCast:10};
  const cast=(id,r1,r2)=>({castID:id,completed:true,outputs:{1:r1,2:r2}});
  const make=(rank,item,casts)=>({inputRank:rank,inputItemID:item,context:ctx,casts,actualCompletedCasts:casts.length,abortedRequests:0,grossHerbs:10*casts.length,refundedHerbs:0,netHerbs:10*casts.length});
  const a=make(1,8001,[cast('a',0,2),cast('b',4,3),cast('c',2,0),cast('d',0,0)]);
  const b=make(2,8002,[cast('e',0,4),cast('f',6,5),cast('g',4,0),cast('h',0,0)]);
  const base={context:ctx,sourceStudyFamilyID:'synthetic-1',observationEpoch:'synthetic',sourceType:'SYNTHETIC',cohorts:[a,b]};
  const r=analyzeMatchedRankCohorts(base);
  eq(r.cohorts[0].byOutputRank[1].expectedQuantity,1.5);
  eq(r.cohorts[0].byOutputRank[1].dropChance,.5);
  eq(r.cohorts[0].byOutputRank[1].observedPositiveYieldMin,2);
  eq(r.cohorts[0].byOutputRank[1].observedPositiveYieldMax,4);
  eq(r.cohorts[0].byOutputRank[1].observedZeroCasts,2);
  eq(r.cohorts[0].coOutputHitCasts,1);
  eq(r.cohorts[1].byOutputRank[1].expectedQuantity,2.5);
  eq(r.cohorts[1].byOutputRank[2].expectedQuantity,2.25);
  eq(r.contrasts.inputRankEffectAtOutputRank1,1);
  eq(r.contrasts.inputRankEffectAtOutputRank2,1);
  eq(r.contrasts.interactionDifferenceInDifferences,0);
  eq(r.cohorts[0].withinCastOutputRankDifference.mean,-.25);
  eq(r.cohorts[1].withinCastOutputRankDifference.mean,-.25);
  eq(Number.isFinite(r.contrasts.descriptiveInteractionSE),true);
  eq(Math.abs(r.contrasts.descriptiveInteractionSE-1.8596594670351163)<1e-12,true);
  eq(r.confidence,0);eq(r.economicUse,'PREVIEW_ONLY');eq(r.normalizedVerified,false);
  const z=make(1,8001,[cast('zero',0,0)]),zz=summarizeCohort(z,ctx);
  eq(zz.byOutputRank[1].dropChance,0);eq(zz.byOutputRank[1].expectedQuantity,0);eq(zz.byOutputRank[1].observedPositiveYieldMin,null);eq(zz.byOutputRank[1].observedPositiveYieldMax,null);
  eq(auditHistoricalTwoAxisEvidence().crossSourceRankInteraction,'NOT_IDENTIFIABLE');
  throws(()=>analyzeMatchedRankCohorts({...base,cohorts:[a,a]}));
  throws(()=>analyzeMatchedRankCohorts({...base,cohorts:[{...a,actualCompletedCasts:3},b]}));
  throws(()=>analyzeMatchedRankCohorts({...base,cohorts:[{...a,netHerbs:39},b]}));
  throws(()=>analyzeMatchedRankCohorts({...base,cohorts:[{...a,casts:[cast('a',0,2),cast('a',4,3),cast('c',2,0),cast('d',0,0)]},b]}));
  throws(()=>analyzeMatchedRankCohorts({...base,cohorts:[{...a,casts:[cast('a',0,2),cast('b',4,3),cast('c',2,0),{castID:'d',completed:true,outputs:{1:0}}]},b]}));
  throws(()=>analyzeMatchedRankCohorts({...base,cohorts:[{...a,casts:[cast('a',0,2),cast('b',4,3),cast('c',2,0),{...cast('d',0,0),completed:false}]},b]}));
  throws(()=>analyzeMatchedRankCohorts({...base,cohorts:[{...a,context:{...ctx,professionSkill:101}},b]}));
  throws(()=>analyzeMatchedRankCohorts({...base,context:{...ctx,outputRankIDs:{1:9001,2:9001}}}));
  throws(()=>analyzeMatchedRankCohorts({...base,context:{...ctx,professionContext:null}}));
  throws(()=>analyzeMatchedRankCohorts({...base,sourceType:'UNVERIFIED_ANECDOTE'}));
  throws(()=>analyzeMatchedRankCohorts({...base,sourceType:'RAW_CURRENT_RETAIL',context:{...ctx,patchBuild:'unknown'}}));
  throws(()=>analyzeMatchedRankCohorts({...base,context:{...ctx,recipeSpellID:999}}));
  throws(()=>analyzeMatchedRankCohorts({...base,context:{...ctx,professionContext:{specialization:'fixed'}}}));
  throws(()=>analyzeMatchedRankCohorts({...base,cohorts:[{...a,casts:[{...cast('a',0,2),refundedHerbs:1},cast('b',4,3),cast('c',2,0),cast('d',0,0)]},b]}));
  throws(()=>analyzeMatchedRankCohorts({...base,cohorts:[{...a,refundedHerbs:1,netHerbs:39,casts:[{...cast('a',0,2),refundedHerbs:0},{...cast('b',4,3),refundedHerbs:0},{...cast('c',2,0),refundedHerbs:0},{...cast('d',0,0),refundedHerbs:0}]},b]}));
  const co=make(1,8001,[cast('co1',2,3),cast('co2',1,4)]);
  eq(summarizeCohort(co,ctx).byOutputRank[1].dropChance+summarizeCohort(co,ctx).byOutputRank[2].dropChance,2);
  return {tests,failed:0};
}
module.exports={MODEL_ID,POLICY,analyzeMatchedRankCohorts,auditHistoricalTwoAxisEvidence,selfTest};
if(require.main===module)process.stdout.write(JSON.stringify(selfTest())+'\n');
