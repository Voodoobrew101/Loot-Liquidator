"use strict";
/* F003 research-only: Midnight Crushing gross-vs-net gem denominator.
 * Source anecdotes are not cast measurements. This module does not feed live EV.
 */
const MODEL_ID="midnight-crushing-gross-net-identifiability-v1.0.0";
const POLICY=Object.freeze({confidence:0,economicUse:"PREVIEW_ONLY",normalizedVerified:false,liveEconomicEligible:false,tooltipOnlyEligible:false});
const SOURCE=Object.freeze({
 evidencePath:"research/evidence/v2/2026-10-29T2332Z-F004-midnight-crushing-net-gem-context.json",
 evidenceBlobSHA:"4fc9df14fa99275d1e46482403427a01ca64e5ce",
 primaryLineage:"MIDNIGHT-2026-TIRED-AND-FED-UP-CRUSHING-RATE",
 secondaryLineage:"MIDNIGHT-2026-JACARA-APRIL-CRUSHING-CONTEXT",
 reportedJulyPerGem:0.83925,reportedAugustApproxPerGem:0.84,
 julyAugustIndependent:false,completedCastDatasets:0,
 reportedBasis:"UNKNOWN_GROSS_OR_NET",exactGemRankIDs:null,exactDustRankIDs:null,
 sourceEpoch:"2026-07/2026-08",sourcePatchBuild:null
});
function check(ok,msg){if(!ok)throw Error(msg);}
function integer(n,min=0){return Number.isSafeInteger(n)&&n>=min;}
function ratioScenario(rate,basis,refundRange=[0,3],nominalGemsPerCast=3){
 check(Number.isFinite(rate)&&rate>=0,"RATE_DOMAIN");
 check(integer(nominalGemsPerCast,1),"NOMINAL_INPUT_DOMAIN");
 check(Array.isArray(refundRange)&&refundRange.length===2&&refundRange.every(Number.isFinite)&&refundRange[0]>=0&&refundRange[1]>=refundRange[0]&&refundRange[1]<=nominalGemsPerCast,"REFUND_RANGE_DOMAIN");
 check(["GROSS_SUPPLIED","NET_CONSUMED","UNKNOWN"].includes(basis),"RATE_BASIS_DOMAIN");
 const gross={basis:"GROSS_SUPPLIED",conditionalEPerCompletedCast:{lower:rate*nominalGemsPerCast,upper:rate*nominalGemsPerCast},requires:"RATE_IS_TOTAL_DUST_DIVIDED_BY_NOMINAL_GEMS_AND_SAME_COMPLETED_CAST_COHORT"};
 const net={basis:"NET_CONSUMED",conditionalEPerCompletedCast:{lower:rate*(nominalGemsPerCast-refundRange[1]),upper:rate*(nominalGemsPerCast-refundRange[0])},
  lowerIsUnattainedInfimum:refundRange[1]===nominalGemsPerCast&&rate>0,
  requires:"RATE_IS_TOTAL_DUST_DIVIDED_BY_ACTUALLY_CONSUMED_GEMS_AND_REFUND_RANGE_APPLIES_TO_SAME_COHORT"};
 return {modelID:MODEL_ID,nominalGemsPerCast,reportedRate:rate,rateBasis:basis,refundsPerCompletedCastRange:refundRange,
  scenarios:basis==="UNKNOWN"?[gross,net]:basis==="GROSS_SUPPLIED"?[gross]:[net],
  identifiableEconomicE:false,sourceRateIsMeasurement:false,rateUncertainty:"NOT_QUANTIFIED",applicability:"CONDITIONAL_ALGEBRA_ONLY",
  evidenceFields:{dropChance:null,yieldMin:null,yieldMax:null,expectedQuantity:null},...POLICY};
}
function inverseMeanRefund(ratePerNetGem,observedEPerCast,nominalGemsPerCast=3){
 check(Number.isFinite(ratePerNetGem)&&ratePerNetGem>0&&Number.isFinite(observedEPerCast)&&observedEPerCast>=0&&integer(nominalGemsPerCast,1),"INVERSE_DOMAIN");
 const meanRefund=nominalGemsPerCast-observedEPerCast/ratePerNetGem;
 check(meanRefund>=-1e-10&&meanRefund<=nominalGemsPerCast+1e-10,"INCOMPATIBLE_NET_RATE");
 return {meanRefundPerCast:Math.max(0,Math.min(nominalGemsPerCast,meanRefund)),
  interpretation:"IDENTIFIABLE_ONLY_IF_NET_RATE_AND_E_ARE_MEASURED_ON_SAME_COMPLETED_CAST_COHORT",
  sourceContextVerified:false,...POLICY};
}
function analyzeCastLog(input){
 check(input&&["SYNTHETIC","RAW_CURRENT_RETAIL"].includes(input.sourceType),"SOURCE_TYPE");
 check(input.sourceStudyFamilyID&&input.observationEpoch,"SOURCE_LINEAGE");
 const c=input.context;
 check(c&&integer(c.nominalGemsPerCast,1)&&Array.isArray(c.outputItemIDs)&&c.outputItemIDs.length>0&&new Set(c.outputItemIDs).size===c.outputItemIDs.length&&c.outputItemIDs.every(x=>integer(x,1)),"OUTPUT_CONTEXT");
 if(input.sourceType==="RAW_CURRENT_RETAIL"){
  for(const k of ["patchBuild","inputItemID","inputQualityRank","professionSkill","specialization","gear","resourcefulness","unlocks","recipeSpellID"])
   check(c[k]!==undefined&&c[k]!==null&&c[k]!==""&&c[k]!=="UNKNOWN","UNKNOWN_CONTEXT_"+k);
  check(/^\d+\.\d+\.\d+/.test(c.patchBuild)&&integer(c.inputItemID,1)&&integer(c.recipeSpellID,1),"PATCH_OR_ID");
 }
 check(Array.isArray(input.events)&&input.events.length>0,"EVENTS_REQUIRED");
 const ids=new Set(),totals=Object.fromEntries(c.outputItemIDs.map(id=>[id,0])),hits=Object.fromEntries(c.outputItemIDs.map(id=>[id,0]));
 const min=Object.fromEntries(c.outputItemIDs.map(id=>[id,Infinity])),max=Object.fromEntries(c.outputItemIDs.map(id=>[id,0]));
 let n=0,aborted=0,refunds=0,coHits=0,allDust=0,zeroDustCasts=0;
 for(const e of input.events){
  check(e&&typeof e.castID==="string"&&e.castID.length>0&&!ids.has(e.castID),"DUPLICATE_OR_MISSING_CAST_ID");ids.add(e.castID);
  check(e.status==="COMPLETED"||e.status==="ABORTED","EVENT_STATUS");
  if(e.status==="ABORTED"){
   check(e.outputs===undefined&&e.refundedGems===undefined,"ABORT_HAS_OUTPUT_OR_REFUND");
   aborted++;continue;
  }
  check(integer(e.refundedGems)&&e.refundedGems<=c.nominalGemsPerCast,"REFUND_DOMAIN");
  check(e.outputs&&Object.keys(e.outputs).length===c.outputItemIDs.length&&c.outputItemIDs.every(id=>Object.prototype.hasOwnProperty.call(e.outputs,id)),"ZERO_INCLUSIVE_OUTPUT_VECTOR");
  n++;refunds+=e.refundedGems;let positive=0,castDust=0;
  for(const id of c.outputItemIDs){
   const y=e.outputs[id];check(integer(y),"OUTPUT_COUNT_DOMAIN");
   totals[id]+=y;castDust+=y;
   if(y>0){positive++;hits[id]++;min[id]=Math.min(min[id],y);max[id]=Math.max(max[id],y);}
  }
  if(positive>1)coHits++;
  if(castDust===0)zeroDustCasts++;
  allDust+=castDust;
 }
 check(n>0,"NO_COMPLETED_CASTS");
 const nominalGems=n*c.nominalGemsPerCast,netGems=nominalGems-refunds;
 const outputs=c.outputItemIDs.map(id=>({outputItemID:id,observedCompletedCasts:n,observedSuccessCasts:hits[id],
  descriptiveDropChance:hits[id]/n,descriptiveUnconditionalE:totals[id]/n,
  observedPositiveYieldMin:hits[id]?min[id]:null,observedPositiveYieldMax:hits[id]?max[id]:null,
  observedZeroCasts:n-hits[id],...POLICY}));
 return {modelID:MODEL_ID,sourceStudyFamilyID:input.sourceStudyFamilyID,observationEpoch:input.observationEpoch,sourceType:input.sourceType,
  context:c,completedCasts:n,abortedRequests:aborted,nominalGems,refundedGems:refunds,netConsumedGems:netGems,
  totalDust:allDust,descriptiveDustPerCompletedCast:allDust/n,descriptiveDustPerGrossGem:allDust/nominalGems,
  descriptiveDustPerNetGem:netGems>0?allDust/netGems:null,netRateStatus:netGems>0?"DEFINED":"UNDEFINED_ZERO_NET_INPUT",
  coOutputCasts:coHits,zeroTotalDustCasts:zeroDustCasts,outputs,
  sourceDataCannotEstablishMinimumEligibleBaseline:true,
  evidencePromotion:false,independentStudyHoldout:"NOT_PERFORMED",
  evidenceFields:{dropChance:null,yieldMin:null,yieldMax:null,expectedQuantity:null},...POLICY};
}
function historical(){
 return {source:SOURCE,sourceReportedRate:SOURCE.reportedJulyPerGem,secondSameAuthorApprox:SOURCE.reportedAugustApproxPerGem,
  scenarios:ratioScenario(SOURCE.reportedJulyPerGem,"UNKNOWN",[0,3],3),
  exampleRefundOneGemPerCast:ratioScenario(SOURCE.reportedJulyPerGem,"NET_CONSUMED",[1,1],3),
  measuredRetailCastE:null,independentCurrentRetailCohorts:0,
  blockers:["SOURCE_RATE_DENOMINATOR_UNKNOWN","SOURCE_RATE_NOT_RAW_MEASUREMENT","REFUNDS_NOT_LOGGED","GEM_AND_DUST_RANK_IDENTITIES_UNKNOWN","PATCH_AND_CHARACTER_CONTEXT_UNKNOWN"],...POLICY};
}
function synthetic(){
 const context={nominalGemsPerCast:3,outputItemIDs:[9001,9002],patchBuild:"synthetic"};
 return {sourceType:"SYNTHETIC",sourceStudyFamilyID:"synthetic-test-only",observationEpoch:"synthetic",context,events:[
  {castID:"a",status:"COMPLETED",refundedGems:0,outputs:{"9001":2,"9002":0}},
  {castID:"b",status:"COMPLETED",refundedGems:1,outputs:{"9001":0,"9002":1}},
  {castID:"c",status:"COMPLETED",refundedGems:0,outputs:{"9001":0,"9002":0}},
  {castID:"d",status:"COMPLETED",refundedGems:2,outputs:{"9001":3,"9002":1}},
  {castID:"abort",status:"ABORTED"}]};
}
function selfTest(){
 let passed=0;function ok(v,name){check(v,"TEST_"+name);passed++;}
 function bad(fn,name){let rejected=false;try{fn();}catch(e){rejected=true;}ok(rejected,"REJECT_"+name);}
 const x=ratioScenario(.83925,"UNKNOWN",[0,3]);
 ok(x.scenarios.length===2,"TWO_BASIS_SCENARIOS");
 ok(Math.abs(x.scenarios[0].conditionalEPerCompletedCast.lower-2.51775)<1e-12,"GROSS_THREE_GEMS");
 ok(x.scenarios[1].conditionalEPerCompletedCast.lower===0&&x.scenarios[1].lowerIsUnattainedInfimum,"NET_ZERO_INFIMUM");
 ok(Math.abs(ratioScenario(.83925,"NET_CONSUMED",[1,1]).scenarios[0].conditionalEPerCompletedCast.lower-1.6785)<1e-12,"REFUND_SENSITIVITY");
 ok(inverseMeanRefund(.83925,1.6785).meanRefundPerCast===1,"INVERSE_REFUND");
 ok(historical().source.julyAugustIndependent===false,"ONE_AUTHOR");
 ok(historical().measuredRetailCastE===null,"NOT_MEASURED");
 const s=synthetic(),r=analyzeCastLog(s);
 ok(r.completedCasts===4&&r.abortedRequests===1,"COMPLETED_DENOMINATOR");
 ok(r.nominalGems===12&&r.refundedGems===3&&r.netConsumedGems===9,"REFUND_LEDGER");
 ok(r.totalDust===7&&r.descriptiveDustPerCompletedCast===1.75,"UNCONDITIONAL_E");
 ok(Math.abs(r.descriptiveDustPerNetGem-7/9)<1e-12,"NET_RATE");
 ok(Math.abs(r.descriptiveDustPerGrossGem-7/12)<1e-12,"GROSS_RATE");
 ok(r.zeroTotalDustCasts===1&&r.coOutputCasts===1,"CO_OUTPUTS_AND_ZEROS");
 ok(r.outputs.every(o=>o.descriptiveDropChance===.5),"MARGINAL_P");
 ok(r.outputs[0].observedPositiveYieldMin===2&&r.outputs[0].observedPositiveYieldMax===3,"OBSERVED_RANGE");
 ok(r.outputs[1].observedPositiveYieldMin===1&&r.outputs[1].observedPositiveYieldMax===1,"SECOND_RANGE");
 ok(r.outputs[0].descriptiveUnconditionalE===1.25&&r.outputs[1].descriptiveUnconditionalE===.5,"RANK_E");
 ok(r.outputs.every(o=>o.confidence===0&&o.economicUse==="PREVIEW_ONLY"&&!o.normalizedVerified&&!o.liveEconomicEligible),"OUTPUT_ISOLATION");
 ok(r.evidenceFields.expectedQuantity===null&&r.independentStudyHoldout==="NOT_PERFORMED","NO_EVIDENCE_PROMOTION");
 const fullRefund=analyzeCastLog({...s,events:[{castID:"full",status:"COMPLETED",refundedGems:3,outputs:{"9001":1,"9002":0}}]});
 ok(fullRefund.netConsumedGems===0&&fullRefund.descriptiveDustPerNetGem===null,"ZERO_NET_UNDEFINED");
 bad(()=>ratioScenario(-1,"UNKNOWN"),"NEGATIVE_RATE");
 bad(()=>ratioScenario(.84,"UNKNOWN",[2,1]),"REVERSED_REFUND");
 bad(()=>ratioScenario(.84,"UNKNOWN",[0,4]),"REFUND_OVER_INPUT");
 bad(()=>ratioScenario(.84,"WRONG"),"UNKNOWN_BASIS");
 bad(()=>inverseMeanRefund(.84,4),"INVERSE_INCOMPATIBLE");
 bad(()=>analyzeCastLog({...s,events:[...s.events,s.events[0]]}),"DUPLICATE_CAST");
 bad(()=>analyzeCastLog({...s,events:[{castID:"x",status:"COMPLETED",refundedGems:0,outputs:{"9001":2}}]}),"MISSING_ZERO_OUTPUT");
 bad(()=>analyzeCastLog({...s,events:[{castID:"x",status:"COMPLETED",refundedGems:4,outputs:{"9001":2,"9002":0}}]}),"REFUND_OVER_BATCH");
 bad(()=>analyzeCastLog({...s,events:[{castID:"x",status:"ABORTED",outputs:{}}]}),"ABORT_OUTPUT");
 bad(()=>analyzeCastLog({...s,events:[{castID:"x",status:"ABORTED"}]}),"NO_COMPLETED");
 bad(()=>analyzeCastLog({...s,sourceType:"RAW_CURRENT_RETAIL"}),"UNKNOWN_RETAIL_CONTEXT");
 bad(()=>analyzeCastLog({...s,context:{...s.context,outputItemIDs:[9001,9001]}}),"DUPLICATE_OUTPUT_ID");
 return {passed,failed:0,syntheticOnly:true,sourceCompletedCastDatasets:0,newEconomicE:0,workingCellsChanged:0};
}
module.exports={MODEL_ID,POLICY,SOURCE,ratioScenario,inverseMeanRefund,analyzeCastLog,historical,synthetic,selfTest};
if(typeof require==="function"&&require.main===module)console.log(JSON.stringify(process.argv.includes("--self-test")?selfTest():historical(),null,2));
