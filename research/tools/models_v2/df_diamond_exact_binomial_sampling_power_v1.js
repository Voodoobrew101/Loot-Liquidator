"use strict";
/** F003 research-only: prospective sample design for the frozen Dragonflight diamond
 * rate conflict. Hypothetical binomial scenarios are NOT observed game rates.
 * No economic or tooltip values are exported. */
const MODEL_ID="df-diamond-exact-binomial-sampling-power-v1.0.0";
const SOURCE={
  frozenModel:"research/tools/models_v2/dragonflight_diamond_tsm_quantization_v1.js",
  sourceFamily:"ONE_FROZEN_TSM_DERIVATIVE_FAMILY",
  matRateText:"0.0142",
  meaning:"UNVERIFIED: p0=0.0142 is a sensitivity hypothesis only, not a verified occurrence probability",
  epoch:"DRAGONFLIGHT_HISTORICAL_NOT_2026_RETAIL"
};
const PRIORITY_KEYS=[
 "tsm:prospect:188658:192870:L1205",
 "tsm:prospect:188658:192871:L1206",
 "tsm:prospect:189143:192869:L1242",
 "tsm:prospect:189143:192870:L1243",
 "tsm:prospect:190311:192869:L1280"
];
function check(v,msg){if(!v)throw Error(msg);}
function probability(p){check(Number.isFinite(p)&&p>=0&&p<=0.1,"P_DOMAIN");}
function cdf(n,k,p){
 check(Number.isSafeInteger(n)&&n>=0&&n<=10000&&Number.isSafeInteger(k),"BINOMIAL_DOMAIN");
 probability(p);
 if(k<0)return 0;
 if(k>=n||p===0)return 1;
 if(n===0)return 1;
 let term=Math.pow(1-p,n),sum=term;
 for(let i=0;i<k;i++){term*=((n-i)/(i+1))*(p/(1-p));sum+=term;}
 return Math.max(0,Math.min(1,sum));
}
function minCastsToObserveAtLeastOne(p,target){
 probability(p);check(p>0&&p<1&&target>0&&target<1,"DETECTION_DOMAIN");
 const n=Math.ceil(Math.log1p(-target)/Math.log1p(-p));
 return {casts:n,nominalOre:n*5,probabilityAtLeastOne:1-Math.pow(1-p,n)};
}
function lowerTailTest(n,p0,alternative,alpha){
 probability(p0);probability(alternative);
 check(p0>alternative&&alternative>=0&&alpha>0&&alpha<1&&n>0&&Number.isSafeInteger(n)&&n<=10000,"TEST_DOMAIN");
 // Reject the higher-rate hypothesis only for unusually FEW successes.
 let k=-1;
 for(let j=0;j<=n;j++){if(cdf(n,j,p0)<=alpha+1e-15)k=j;else break;}
 return {n,rejectWhenSuccessesAtMost:k,actualTypeI:k<0?0:cdf(n,k,p0),
   power:k<0?0:cdf(n,k,alternative)};
}
function minimumCastsForPower(p0,alternative,alpha,targetPower,maxN=10000){
 check(targetPower>0&&targetPower<1&&Number.isSafeInteger(maxN)&&maxN>=1&&maxN<=10000,"POWER_DOMAIN");
 for(let n=1;n<=maxN;n++){
  const t=lowerTailTest(n,p0,alternative,alpha);
  if(t.power+1e-14>=targetPower)return {...t,nominalOre:n*5,targetPower};
 }
 return {status:"NOT_REACHED_WITHIN_LIMIT",maxN,p0,alternative,alpha,targetPower};
}
function plan(){
 const p0=Number(SOURCE.matRateText),half=p0/2,quarter=p0/4;
 const sensitivity=[p0,half,quarter].map(p=>({assumedP:p,atLeastOne95:minCastsToObserveAtLeastOne(p,0.95),
  zeroHitsAt100Casts:cdf(100,0,p)}));
 const discrimination=minimumCastsForPower(p0,half,0.05,0.8,10000);
 return {modelID:MODEL_ID,scope:"PROSPECTIVE_DESIGN_ONLY",targetKeys:PRIORITY_KEYS,source:SOURCE,
  hypothesis:{p0,alternativeHalf:half,alternativeQuarter:quarter,
    sourceUnitStatus:"UNVERIFIED_TSM_MAT_RATE_SEMANTICS",
    binomialIID:"DESIGN_ASSUMPTION_REQUIRES_HOMOGENEOUS_CAST_CONTEXT"},
  sensitivity,discrimination,
  requiredMeasurement:{unit:"ONE_ACTUAL_COMPLETED_PROSPECTING_CAST",inputUnitsPerCast:5,
   independentStrata:["inputItemID","inputRank","outputItemID","outputRank","RetailBuild","effectiveSkill","specialization","professionStats","unlockState"],
   capture:["completedCastID","zeroInclusiveOutputCount","refundedOreUnits","abortedRequestsSeparately","studyFamilyID","observationEpoch"],
   noPooling:"DO_NOT_POOL_RANKS_OR_SHARED_SOURCE_FAMILIES_AS_INDEPENDENT",
   designCaveat:"One-sided fixed-N plan; preregister N and threshold. Optional stopping invalidates nominal alpha without adjustment."},
  evidenceFields:{dropChance:null,yieldMin:null,yieldMax:null,expectedQuantity:null},
  confidence:0,economicUse:"PREVIEW_ONLY",normalizedVerified:false,
  independentHoldout:"SEPARATE_2026_RETAIL_STUDY_FAMILY_REQUIRED",
  goldRecommendationEligible:false,tooltipFallbackEligible:false,
  limitations:["TSM matRate unit semantics unverified","No 2026 current-Retail cast histogram",
   "Binomial independence and homogeneous skill/patch assumed for power only",
   "Rare output success may be co-produced with other outputs; never force marginal rates to sum to one",
   "Nominal ore budget excludes unknown Resourcefulness refunds"]};
}
function selfTest(){
 let n=0;const ok=(v,s)=>{n++;check(v,"TEST_"+s);},bad=(f,s)=>{n++;let failed=false;try{f();}catch(e){failed=true;}check(failed,"TEST_REJECT_"+s);};
 ok(cdf(0,0,.01)===1,"N0");
 ok(cdf(10,-1,.01)===0,"NEG_K");
 ok(Math.abs(cdf(10,0,.01)-Math.pow(.99,10))<1e-12,"ZERO_CDF");
 ok(Math.abs(cdf(2,1,.1)-.99)<1e-12,"TWO_CDF");
 ok(cdf(100,100,.01)===1,"FULL_CDF");
 ok(cdf(10,3,0)===1,"P_ZERO");
 ok(cdf(100,0,.0142)>0&&cdf(100,0,.0142)<1,"RARE_EVENT");
 const d=minCastsToObserveAtLeastOne(.0142,.95);
 ok(d.casts>100&&d.casts<300,"DETECTION_SIZE");
 ok(d.probabilityAtLeastOne>=.95,"DETECTION_POWER");
 ok(1-Math.pow(1-.0142,d.casts-1)<.95,"DETECTION_MINIMAL");
 const a=lowerTailTest(1000,.0142,.0071,.05);
 ok(a.actualTypeI<=.05+1e-12,"TYPE_I");
 ok(a.power>=0&&a.power<=1,"POWER_RANGE");
 ok(a.rejectWhenSuccessesAtMost>=0,"NONTRIVIAL_TEST");
 const x=minimumCastsForPower(.0142,.0071,.05,.8,5000);
 ok(x.n>100&&x.n<5000&&x.power>=.8,"POWER_REACHED");
 ok(x.actualTypeI<=.05+1e-12,"EXACT_ALPHA");
 ok(lowerTailTest(x.n-1,.0142,.0071,.05).power<.8+1e-12,"MINIMAL_N");
 const z=minimumCastsForPower(.0142,.0071,.05,.8,20);
 ok(z.status==="NOT_REACHED_WITHIN_LIMIT","LIMIT");
 const p=plan();
 ok(p.targetKeys.length===5&&new Set(p.targetKeys).size===5,"TARGETS");
 ok(p.evidenceFields.expectedQuantity===null&&p.confidence===0&&p.economicUse==="PREVIEW_ONLY"&&!p.normalizedVerified,"ISOLATION");
 ok(!p.goldRecommendationEligible&&!p.tooltipFallbackEligible,"NO_LEAKAGE");
 ok(p.discrimination.nominalOre===5*p.discrimination.n,"ORE_BUDGET");
 ok(p.sensitivity[0].atLeastOne95.casts<p.sensitivity[1].atLeastOne95.casts,"SENSITIVITY");
 bad(()=>cdf(10,1,-.01),"BAD_P");
 bad(()=>cdf(10,1,.2),"BAD_P_HIGH");
 bad(()=>lowerTailTest(100,.0071,.0142,.05),"REVERSED_HYPOTHESES");
 bad(()=>minCastsToObserveAtLeastOne(0,.95),"ZERO_P");
 bad(()=>minimumCastsForPower(.0142,.0071,.05,.8,10001),"MAXN");
 return {passed:n,failed:0,scenarioOnly:true,actualCastObservations:0,independentStudiesAdded:0,
  newVerifiedE:0,workingCellsChanged:0,discriminationCasts:p.discrimination.n,
  nominalOre:p.discrimination.nominalOre};
}
module.exports={MODEL_ID,SOURCE,PRIORITY_KEYS,cdf,minCastsToObserveAtLeastOne,lowerTailTest,minimumCastsForPower,plan,selfTest};
if(require.main===module){
 if(process.argv.includes("--self-test"))console.log(JSON.stringify(selfTest()));
 else if(process.argv.includes("--emit"))console.log(JSON.stringify(plan(),null,2));
}
