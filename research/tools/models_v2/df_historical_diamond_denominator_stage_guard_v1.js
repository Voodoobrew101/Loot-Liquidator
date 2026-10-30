"use strict";
/* F003 research only: historical Dragonflight diamond denominator and two-stage guard.
   No game rate, confidence, live EV or tooltip fallback may be inferred from these reports. */
const MODEL_ID="df-historical-diamond-denominator-stage-guard-v1.0.0";
const POLICY=Object.freeze({confidence:0,economicUse:"PREVIEW_ONLY",normalizedVerified:false,liveEconomicEligible:false,tooltipOnlyEligible:false});
const PRIORITY_KEYS=Object.freeze([
"tsm:prospect:188658:192870:L1205","tsm:prospect:188658:192871:L1206",
"tsm:prospect:189143:192869:L1242","tsm:prospect:189143:192870:L1243",
"tsm:prospect:190311:192869:L1280"]);
const SOURCE=Object.freeze({
 evidencePath:"research/evidence/v2/2026-10-30T2028Z-F004-df-two-stage-diamond-denominators.json",
 historicalEpoch:"ON_OR_BEFORE_2023-01-10_BUILD_UNKNOWN",
 thread:"https://www.reddit.com/r/woweconomy/comments/108782r",
 access:"ORIGINAL_COMMENTS_SEARCH_INDEXED_DIRECT_READ_BLOCKED",
 firstAuthorLineage:"reddit-108782r-comment-A-30k-serevite-50k-draconium",
 secondAuthorLineage:"reddit-108782r-comment-B-prismatic-1000-25-diamonds",
 firstStage:Object.freeze([
 Object.freeze({inputFamily:"Serevite Ore",reportedOreUnits:30000,ratePer1000Text:"1.08",inputRank:null,exactCount:null}),
 Object.freeze({inputFamily:"Draconium Ore",reportedOreUnits:50000,ratePer1000Text:"2.57",inputRank:null,exactCount:null})]),
 secondStage:Object.freeze({inputFamily:"Prismatic Ore",inputItemID:192880,reportedOreUnits:1000,reportedDiamonds:25,actualCompletedCasts:null,oreRefunds:null})
});
function need(x,code){if(!x)throw Error(code);}
const posInt=x=>Number.isSafeInteger(x)&&x>0;
function decimal(s){
 need(typeof s==="string"&&/^\d+(?:\.\d+)?$/.test(s),"RATE_DECIMAL");
 const digits=(s.split(".")[1]||"").length;need(digits<=9,"RATE_PRECISION");
 return {digits,scale:10n**BigInt(digits),value:BigInt(s.replace(".",""))};
}
function ceilDiv(a,b){need(a>=0n&&b>0n,"DIV_DOMAIN");return (a+b-1n)/b;}
function countRange(oreUnits,rateText){
 need(posInt(oreUnits),"ORE_UNITS");
 const d=decimal(rateText);need(d.value>0n,"POSITIVE_RATE_REQUIRED");
 const den=2n*d.scale*1000n,n=BigInt(oreUnits);
 const lo=ceilDiv((2n*d.value-1n)*n,den),hi=ceilDiv((2n*d.value+1n)*n,den)-1n;
 need(lo<=BigInt(Number.MAX_SAFE_INTEGER)&&hi<=BigInt(Number.MAX_SAFE_INTEGER),"COUNT_OVERFLOW");
 return {minCount:Number(lo),maxCount:Number(hi),integerFeasible:hi>=lo,
 roundingIntervalPer1000:{lowerInclusive:Number(2n*d.value-1n)/Number(2n*d.scale),upperExclusive:Number(2n*d.value+1n)/Number(2n*d.scale)},
 interpretation:"EXACT_ORE_DENOMINATOR_AND_NEAREST_DECIMAL_ROUNDING_HYPOTHESIS"};
}
function nearestCompatibleOre(oreUnits,rateText,maxDelta=1000,multipleOf=1){
 need(posInt(oreUnits)&&Number.isSafeInteger(maxDelta)&&maxDelta>=0&&maxDelta<=100000&&posInt(multipleOf),"SEARCH_DOMAIN");
 for(let delta=0;delta<=maxDelta;delta++){
  const candidates=delta===0?[oreUnits]:[oreUnits-delta,oreUnits+delta];
  for(const n of candidates){
   if(n<1||n%multipleOf!==0)continue;
   const r=countRange(n,rateText);
   if(r.integerFeasible)return {nearestOreUnits:n,deltaOreUnits:n-oreUnits,
    compatibleIntegerCountRange:[r.minCount,r.maxCount],multipleOf,
    status:"SCENARIO_ONLY_DENOMINATOR_RECONCILIATION_NOT_OBSERVED"};
  }
 }
 return null;
}
function stageOf(family){
 need(["Serevite Ore","Draconium Ore","Prismatic Ore"].includes(family),"UNKNOWN_STAGE");
 return family==="Prismatic Ore"?"SECOND_STAGE":"FIRST_STAGE";
}
function preventFalseDirectJoin(a,b){
 const same=stageOf(a)===stageOf(b);
 return {allowed:same,reason:same?"SAME_STAGE_NOT_PROOF_OF_MATCHED_CONTEXT":"DIFFERENT_PROCESSING_STAGE_DO_NOT_ADD_OR_POOL"};
}
function analyze(){
 const firstStage=SOURCE.firstStage.map(x=>{
  const exact=countRange(x.reportedOreUnits,x.ratePer1000Text);
  return {...x,stage:"FIRST_STAGE",sourceLineage:SOURCE.firstAuthorLineage,
   exactDenominatorIntegerFeasible:exact.integerFeasible,
   impliedCountIfLiteral:Number(x.ratePer1000Text)*x.reportedOreUnits/1000,
   exactRoundingCountRange:exact.integerFeasible?[exact.minCount,exact.maxCount]:null,
   nearestAnyOreScenario:nearestCompatibleOre(x.reportedOreUnits,x.ratePer1000Text),
   nearestFiveOreScenario:nearestCompatibleOre(x.reportedOreUnits,x.ratePer1000Text,1000,5),
   nominalFiveOreCastEquivalents:x.reportedOreUnits/5,
   actualCompletedCasts:null,oreRefunds:null,skillContext:null,outputRank:null,
   probability:null,expectedQuantity:null,
   unverifiedFiveOreCastEIllustration:Number(x.ratePer1000Text)*5/1000,
   illustrationStatus:"SCENARIO_ONLY_NOT_EVIDENCE_OR_LIVE_VALUE"};
 });
 return {modelID:MODEL_ID,source:SOURCE.evidencePath,priorityKeys:PRIORITY_KEYS,firstStage,
  secondStage:{...SOURCE.secondStage,stage:"SECOND_STAGE",sourceLineage:SOURCE.secondAuthorLineage,
   nominalFiveOreCastEquivalents:200,verifiedCastCount:null,perCastExpectedQuantity:null},
  separation:preventFalseDirectJoin("Draconium Ore","Prismatic Ore"),
  cannotAllocateToRankSpecificKeys:true,cannotTreatReportedOreAsVerifiedCasts:true,
  sourceAuthorsAreNotIndependentReplicatesOfSameConversion:true,
  independentCurrentRetailHoldouts:0,newVerifiedEvidence:null,...POLICY};
}
function selfTest(){
 let passed=0;
 const ok=(v,name)=>{need(v,"TEST_"+name);passed++;};
 const bad=(fn,name)=>{let threw=false;try{fn();}catch(e){threw=true;}ok(threw,"REJECT_"+name);};
 const a=countRange(30000,"1.08"),b=countRange(50000,"2.57");
 ok(!a.integerFeasible&&a.minCount===33&&a.maxCount===32,"SEREVITE_NONINTEGER");
 ok(!b.integerFeasible&&b.minCount===129&&b.maxCount===128,"DRACONIUM_NONINTEGER");
 ok(countRange(1000,"2.00").integerFeasible&&countRange(1000,"2.00").minCount===2,"EXACT_INTEGER");
 ok(!countRange(1000,"2.50").integerFeasible,"HALF_UNIT");
 ok(countRange(100000,"1.08").integerFeasible,"LARGE_DENOMINATOR");
 const x=nearestCompatibleOre(30000,"1.08"),y=nearestCompatibleOre(50000,"2.57");
 ok(x!==null&&Math.abs(x.deltaOreUnits)===233,"SEREVITE_NEAREST");
 ok(y!==null&&Math.abs(y.deltaOreUnits)===98,"DRACONIUM_NEAREST");
 const x5=nearestCompatibleOre(30000,"1.08",1000,5),y5=nearestCompatibleOre(50000,"2.57",1000,5);
 ok(x5!==null&&Math.abs(x5.deltaOreUnits)===235,"SEREVITE_MULTIPLE5");
 ok(y5!==null&&Math.abs(y5.deltaOreUnits)===100,"DRACONIUM_MULTIPLE5");
 ok(nearestCompatibleOre(30000,"1.08",100)===null,"NO_CLOSE_WITNESS");
 ok(!preventFalseDirectJoin("Serevite Ore","Prismatic Ore").allowed,"NO_STAGE_MERGE");
 ok(preventFalseDirectJoin("Serevite Ore","Draconium Ore").allowed,"SAME_STAGE_ONLY");
 const z=analyze();
 ok(z.priorityKeys.length===5&&new Set(z.priorityKeys).size===5,"TARGET_KEYS");
 ok(z.firstStage.every(c=>c.expectedQuantity===null&&c.probability===null),"NO_EVIDENCE");
 ok(z.firstStage[0].sourceLineage===z.firstStage[1].sourceLineage,"ONE_AUTHOR");
 ok(z.secondStage.sourceLineage!==z.firstStage[0].sourceLineage,"SECOND_AUTHOR");
 ok(z.secondStage.perCastExpectedQuantity===null&&z.secondStage.verifiedCastCount===null,"NO_STAGE2_CASTS");
 ok(z.confidence===0&&z.economicUse==="PREVIEW_ONLY"&&!z.normalizedVerified&&!z.liveEconomicEligible,"NO_LIVE_ECONOMICS");
 ok(z.cannotAllocateToRankSpecificKeys&&z.cannotTreatReportedOreAsVerifiedCasts,"NO_RANK_INFERENCE");
 bad(()=>countRange(0,"1.08"),"ZERO_ORE");
 bad(()=>countRange(1000,"-1.08"),"NEGATIVE_RATE");
 bad(()=>countRange(1000,"0"),"ZERO_RATE");
 bad(()=>countRange(1000,"NaN"),"BAD_RATE");
 bad(()=>countRange(1000,"1.1234567890"),"EXCESS_PRECISION");
 bad(()=>nearestCompatibleOre(1000,"1.08",-1),"NEGATIVE_RADIUS");
 bad(()=>nearestCompatibleOre(1000,"1.08",100,0),"BAD_MULTIPLE");
 bad(()=>stageOf("Unknown Ore"),"UNKNOWN_STAGE");
 return {modelID:MODEL_ID,passed,failed:0,syntheticOnly:true,actualCurrentRetailCasts:0,newVerifiedE:0};
}
module.exports={MODEL_ID,POLICY,PRIORITY_KEYS,SOURCE,decimal,countRange,nearestCompatibleOre,stageOf,preventFalseDirectJoin,analyze,selfTest};
if(typeof require==="function"&&require.main===module){
 if(process.argv.includes("--self-test"))console.log(JSON.stringify(selfTest()));
 else if(process.argv.includes("--emit"))console.log(JSON.stringify(analyze(),null,2));
}
