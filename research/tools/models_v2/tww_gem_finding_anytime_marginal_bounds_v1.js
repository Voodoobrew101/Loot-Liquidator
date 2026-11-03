"use strict";
/** Research-only F003: optional-stopping-safe simultaneous marginal intervals.
 * At each completed-cast count n, allocate alpha/(m*n*(n+1)) to a two-sided
 * Clopper-Pearson interval for each of m predeclared output relationships.
 * Since sum_{n>=1} 1/(n(n+1))=1, the union bound gives simultaneous coverage
 * at every look under fixed-context IID Bernoulli indicators for each output.
 * Co-outputs need not be independent; no evidence or economic promotion.
 */
const base=require("./tww_gem_finding_conditional_cohorts_v1.js");
const exact=require("./tww_gem_finding_exact_marginal_bounds_v1.js");
const MODEL_ID="tww-gem-finding-anytime-marginal-bounds-v1.0.0";
const KEYS=exact.KEYS;
const MAX_CASTS=10000; // Numerical CDF limit in the imported exact model.
function check(v,msg){if(!v)throw Error(msg);}
function spending(n,alpha=.05,m=KEYS.length){
 check(Number.isSafeInteger(n)&&n>=1&&n<=MAX_CASTS,"COMPLETED_CAST_COUNT_DOMAIN");
 check(Number.isFinite(alpha)&&alpha>0&&alpha<1,"ALPHA_DOMAIN");
 check(Number.isSafeInteger(m)&&m>=1,"COMPARISON_COUNT_DOMAIN");
 return alpha/(m*n*(n+1));
}
function interval(n,k,alpha=.05,m=KEYS.length){
 check(Number.isSafeInteger(k)&&k>=0&&k<=n,"SUCCESS_CAST_COUNT_DOMAIN");
 const a=spending(n,alpha,m);
 return {...exact.interval(n,k,a),perLookPerOutputAlpha:a,method:"TWO_SIDED_CP_WITH_INFINITE_LOOK_ALPHA_SPENDING"};
}
function zeroUpper(n,alpha=.05,m=KEYS.length){
 const a=spending(n,alpha,m);
 return -Math.expm1(Math.log(a/2)/n);
}
function design(target=.01,alpha=.05,m=KEYS.length){
 check(Number.isFinite(target)&&target>0&&target<1,"TARGET_DOMAIN");
 check(Number.isFinite(alpha)&&alpha>0&&alpha<1&&Number.isSafeInteger(m)&&m>=1,"DESIGN_DOMAIN");
 for(let n=1;n<=MAX_CASTS;n++)if(zeroUpper(n,alpha,m)<=target){
  return {completedCasts:n,nominalOre:n*5,zeroHitUpper:zeroUpper(n,alpha,m),condition:"ZERO_HITS_EVERY_LOOK_FIXED_CONTEXT",maxSupportedCasts:MAX_CASTS};
 }
 throw Error("DESIGN_EXCEEDS_SUPPORTED_CAST_LIMIT");
}
function analyze(session,alpha=.05){
 const summary=base.summarize(session),m=KEYS.length;
 check(summary.completedCasts<=MAX_CASTS,"SESSION_EXCEEDS_CAST_LIMIT");
 return {modelID:MODEL_ID,scope:"RESEARCH_ONLY",studyFamilyID:session.studyFamilyID,
  sessionID:session.sessionID,contextKey:summary.contextKey,
  completedCasts:summary.completedCasts,abortedRequests:summary.abortedRequests,
  alpha,predeclaredComparisons:m,perLookPerOutputAlpha:summary.completedCasts?spending(summary.completedCasts,alpha,m):null,
  coverageClaim:"AT_LEAST_1_MINUS_ALPHA_SIMULTANEOUSLY_OVER_ALL_LOOKS_AND_EIGHT_PREDECLARED_MARGINALS_UNDER_IID_FIXED_CONTEXT",
  optionalStoppingAllowed:true,coOutputsIndependentRequired:false,
  conditions:["COMPLETE_ZERO_INCLUSIVE_CAST_LOG","SAME_PATCH_SKILL_STATS_UNLOCK_AND_RANK_FOR_ALL_CASTS","IID_BERNOULLI_PER_OUTPUT","PREDECLARED_EIGHT_OUTPUTS","NO_POST_HOC_CONTEXT_OR_OUTPUT_SELECTION"],
  rows:summary.rows.map(r=>{
   const x={recordID:r.recordID,status:r.status,confidence:0,economicUse:"PREVIEW_ONLY",normalizedVerified:false,
    evidenceDropChance:null,evidenceExpectedQuantity:null,goldRecommendationEligible:false,tooltipFallbackEligible:false};
   if(r.dropChance===null||!r.completedCasts)return {...x,interval:null,reason:"UNKNOWN_UNLOCK_OR_NO_COMPLETED_CASTS"};
   const k=Math.round(r.dropChance*r.completedCasts);
   check(Math.abs(k-r.dropChance*r.completedCasts)<1e-9,"CAST_INTEGER_RECONSTRUCTION");
   return {...x,interval:interval(r.completedCasts,k,alpha,m),descriptiveCohortE:r.expectedQuantity,
    descriptivePositiveMin:r.yieldMin,descriptivePositiveMax:r.yieldMax};
  }),
  evidenceFields:{dropChance:null,yieldMin:null,yieldMax:null,expectedQuantity:null},
  confidence:0,economicUse:"PREVIEW_ONLY",normalizedVerified:false};
}
function analyzeLooks(session,completedCastLooks,alpha=.05){
 check(Array.isArray(completedCastLooks)&&completedCastLooks.length>0,"LOOKS_REQUIRED");
 const total=base.summarize(session).completedCasts;
 let previous=0;
 const results=[];
 for(const n of completedCastLooks){
  check(Number.isSafeInteger(n)&&n>previous&&n<=total&&n<=MAX_CASTS,"LOOK_ORDER_OR_DOMAIN");
  let completed=0,cut=0;
  for(let i=0;i<session.events.length;i++){
   if(session.events[i].status==="COMPLETED")completed++;
   if(completed===n){cut=i+1;break;}
  }
  const result=analyze({...session,events:session.events.slice(0,cut)},alpha);
  check(result.completedCasts===n,"LOOK_DENOMINATOR");
  results.push(result);previous=n;
 }
 return {modelID:MODEL_ID,lookCounts:completedCastLooks.slice(),results,
  independentStudyHoldout:"PENDING",actualRetailEvidenceAdded:0};
}
function selfTest(){
 let passed=0;
 const ok=(v,s)=>{passed++;check(v,"TEST_"+s);};
 const bad=(f,s)=>{passed++;let rejected=false;try{f();}catch(e){rejected=true;}check(rejected,"TEST_REJECT_"+s);};
 ok(KEYS.length===8&&new Set(KEYS).size===8,"EIGHT_PREDECLARED_KEYS");
 ok(Math.abs(spending(1)-.05/16)<1e-15,"FIRST_LOOK_SPEND");
 let sum=0;for(let n=1;n<=1000;n++)sum+=spending(n);
 ok(Math.abs(sum-(.05/8)*(1-1/1001))<1e-13,"TELESCOPING_SPEND");
 ok(zeroUpper(574)>.03,"FIXED_SAMPLE_574_NOT_ANYTIME_SAFE");
 const d=design();ok(d.completedCasts===2096&&d.nominalOre===10480,"ONE_PERCENT_ANYTIME_DESIGN");
 ok(d.zeroHitUpper<=.01&&zeroUpper(d.completedCasts-1)>.01,"MINIMAL_DESIGN");
 ok(zeroUpper(3000)<zeroUpper(2000),"ZERO_UPPER_DECREASES");
 const z=interval(20,0),a=interval(20,20),h=interval(20,10);
 ok(z.lower===0&&z.upper>0&&a.upper===1&&a.lower>0,"BOUNDARIES");
 ok(h.lower<.5&&h.upper>.5,"MIDPOINT");
 ok(z.upper>exact.interval(20,0,.05/8).upper,"ANYTIME_WIDER_THAN_FIXED");
 ok(Math.abs(z.upper-zeroUpper(20))<1e-10,"ZERO_FORMULA");
 const s=base.synthetic(),r=analyze(s);
 ok(r.rows.length===4&&r.predeclaredComparisons===8,"TARGETS");
 const ruby=r.rows.find(x=>x.recordID.includes(":212495:"));
 ok(ruby.interval.completedCasts===3&&ruby.interval.successCasts===2,"CAST_COUNTS");
 ok(r.rows.filter(x=>x.interval===null).length===2,"UNKNOWN_UNLOCKS_NULL");
 ok(r.rows.every(x=>x.confidence===0&&x.economicUse==="PREVIEW_ONLY"&&!x.normalizedVerified&&!x.goldRecommendationEligible&&!x.tooltipFallbackEligible),"ISOLATION");
 const looks=analyzeLooks(s,[1,2,3]);
 ok(looks.results.map(x=>x.completedCasts).join(",")==="1,2,3","SEQUENTIAL_LOOKS");
 ok(looks.results[2].abortedRequests===0,"ABORT_AFTER_LAST_LOOK_EXCLUDED");
 ok(looks.results[0].rows.find(x=>x.recordID.includes(":212495:")).interval.successCasts===1,"FIRST_LOOK");
 bad(()=>spending(0),"NO_ZERO_LOOK");bad(()=>spending(10001),"MAX_CASTS");
 bad(()=>spending(1,NaN),"NAN_ALPHA");bad(()=>spending(1,.05,0),"M_ZERO");
 bad(()=>interval(10,11),"INVALID_SUCCESS");bad(()=>design(0),"TARGET_ZERO");
 bad(()=>design(.00001),"DESIGN_TOO_LONG");
 bad(()=>analyzeLooks(s,[2,2]),"REPEATED_LOOK");
 bad(()=>analyzeLooks(s,[4]),"BEYOND_CASTS");
 bad(()=>analyzeLooks(s,[]),"NO_LOOKS");
 return {passed,failed:0,syntheticOnly:true,actualRetailCasts:0,economicPromotions:0,
  designOnePercentZeroHits:d,originalFixedSampleCasts:exact.design().casts};
}
module.exports={MODEL_ID,KEYS,MAX_CASTS,spending,interval,zeroUpper,design,analyze,analyzeLooks,selfTest};
if(require.main===module)console.log(JSON.stringify(process.argv.includes("--self-test")?selfTest():analyze(base.synthetic()),null,2));
