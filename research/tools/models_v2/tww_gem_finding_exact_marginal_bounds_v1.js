"use strict";
/* Research-only F003: exact simultaneous marginal Gem Finding intervals; no economic promotion. */
const base=require("./tww_gem_finding_conditional_cohorts_v1.js");
const MODEL_ID="tww-gem-finding-exact-marginal-bounds-v1.0.1";
const KEYS=base.TARGETS.map(x=>x.recordID);
function assert(v,m){if(!v)throw Error(m);}
// Stable binomial tails anchored at the requested boundary, not at P(X=0).
// The latter underflows for ordinary large-n/high-p cohorts and corrupts CP intervals.
const LOG_FACTORIAL=[0];
function logFactorial(n){for(let i=LOG_FACTORIAL.length;i<=n;i++)LOG_FACTORIAL[i]=LOG_FACTORIAL[i-1]+Math.log(i);return LOG_FACTORIAL[n];}
function cdf(n,k,p){
 assert(Number.isSafeInteger(n)&&n>=0&&n<=10000&&Number.isSafeInteger(k)&&Number.isFinite(p)&&p>=0&&p<=1,"CDF_DOMAIN");
 if(k<0)return 0;if(k>=n||p===0)return 1;if(p===1)return 0;
 const logMass=j=>logFactorial(n)-logFactorial(j)-logFactorial(n-j)+j*Math.log(p)+(n-j)*Math.log1p(-p);
 let sum=0;
 if(k<n*p){
  let term=Math.exp(logMass(k));
  for(let j=k;j>=0;j--){sum+=term;term*=j/(n-j+1)*(1-p)/p;}
 }else{
  let term=Math.exp(logMass(k+1));
  for(let j=k+1;j<=n;j++){sum+=term;term*=(n-j)/(j+1)*p/(1-p);}
  sum=1-sum;
 }
 return Math.max(0,Math.min(1,sum));
}
function invert(fn,target,increasing){let lo=0,hi=1;for(let i=0;i<65;i++){let mid=(lo+hi)/2;if((fn(mid)<target)===increasing)lo=mid;else hi=mid;}return (lo+hi)/2;}
function interval(n,k,alpha){assert(Number.isSafeInteger(n)&&n>0&&Number.isSafeInteger(k)&&k>=0&&k<=n&&alpha>0&&alpha<1,"INTERVAL_DOMAIN");let a=alpha/2;let lower=k===0?0:invert(p=>1-cdf(n,k-1,p),a,true);let upper=k===n?1:invert(p=>cdf(n,k,p),a,false);assert(lower<=upper,"ORDER");return {completedCasts:n,successCasts:k,observedRate:k/n,lower,upper};}
function zeroUpper(n,alpha=.05,m=8){assert(Number.isSafeInteger(n)&&n>0&&alpha>0&&alpha<1&&Number.isSafeInteger(m)&&m>0,"ZERO_DOMAIN");return -Math.expm1(Math.log(alpha/(2*m))/n);}
function design(target=.01,alpha=.05,m=8){assert(target>0&&target<1&&alpha>0&&alpha<1&&Number.isSafeInteger(m)&&m>0,"DESIGN_DOMAIN");const casts=Math.ceil(Math.log(alpha/(2*m))/Math.log1p(-target));return {casts,nominalOre:casts*5,zeroHitUpper:zeroUpper(casts,alpha,m),condition:"ZERO_HITS_ONLY"};}
function analyze(session,alpha=.05){assert(alpha>0&&alpha<1,"ALPHA");const summary=base.summarize(session),m=KEYS.length;return {modelID:MODEL_ID,scope:"RESEARCH_ONLY",sourceFamily:session.studyFamilyID,patchEpoch:session.patchEpoch,comparisonCount:m,alpha,perComparisonAlpha:alpha/m,completedCasts:summary.completedCasts,rows:summary.rows.map(r=>{let x={recordID:r.recordID,status:r.status,confidence:0,economicUse:"PREVIEW_ONLY",normalizedVerified:false,evidenceExpectedQuantity:null,evidenceDropChance:null,goldRecommendationEligible:false,tooltipFallbackEligible:false};if(r.dropChance===null||!r.completedCasts)return {...x,interval:null,reason:"UNKNOWN_UNLOCK_OR_NO_CASTS"};const k=Math.round(r.dropChance*r.completedCasts);assert(Math.abs(k-r.dropChance*r.completedCasts)<1e-9,"CAST_COUNT");return {...x,interval:interval(r.completedCasts,k,alpha/m),descriptiveCohortE:r.expectedQuantity,descriptivePositiveMin:r.yieldMin,descriptivePositiveMax:r.yieldMax};}),familywiseStatement:"BONFERRONI_COVERAGE_CONDITIONAL_ON_IID_BINOMIAL_PER_OUTPUT",nonexclusiveCooutputs:true,evidenceFields:{dropChance:null,yieldMin:null,yieldMax:null,expectedQuantity:null},confidence:0,economicUse:"PREVIEW_ONLY",normalizedVerified:false};}
function selfTest(){let n=0;const ok=(v,s)=>{n++;assert(v,"TEST_"+s);},bad=(f,s)=>{n++;let rejected=false;try{f();}catch(e){rejected=true;}assert(rejected,"TEST_REJECT_"+s);};
ok(KEYS.length===8&&new Set(KEYS).size===8,"KEYS");ok(cdf(2,0,.5)===.25&&Math.abs(cdf(2,1,.5)-.75)<1e-14,"CDF");
ok(Math.abs(cdf(10000,5000,.5)-.503989323242)<1e-8,"LARGE_N_BALANCED");
ok(Math.abs(cdf(10000,8999,.9)-.491578960654)<1e-8,"LARGE_N_HIGH_P");
ok(Math.abs(cdf(10000,9899,.99)-.473437465948)<1e-8,"LARGE_N_EXTREME_P");
ok(Math.abs(cdf(10000,8999,.9)+cdf(10000,1000,.1)-1)<1e-8,"BINOMIAL_SYMMETRY");
let large=interval(10000,9000,.05);ok(large.lower>.88&&large.lower<.9&&large.upper>.9&&large.upper<.92,"LARGE_N_CP");
ok(cdf(10000,0,.9)===0&&cdf(10000,10000,.9)===1,"TAIL_BOUNDARY");
bad(()=>cdf(10000,5000,NaN),"NAN_REJECT");let z=interval(10,0,.05),a=interval(10,10,.05),h=interval(20,10,.05);ok(z.lower===0&&z.upper>0,"ZERO_NONZERO");ok(a.upper===1&&a.lower>0,"ALL");ok(Math.abs(z.upper-(1-Math.pow(.025,.1)))<1e-10,"ZERO_FORMULA");ok(h.lower<.5&&h.upper>.5,"HALF");ok(Math.abs(h.lower-(1-h.upper))<1e-9,"SYMMETRY");ok(zeroUpper(100,.05,8)>zeroUpper(100,.05,1),"MULTIPLE");ok(zeroUpper(200)<zeroUpper(100),"MORE_DATA");let d=design();ok(d.zeroHitUpper<=.01+1e-12&&zeroUpper(d.casts-1)>.01,"DESIGN_MIN");ok(d.nominalOre===5*d.casts,"ORE");let s=base.synthetic(),r=analyze(s);ok(r.rows.length===4&&r.comparisonCount===8,"ROWS");let ruby=r.rows.find(x=>x.recordID.includes(":212495:")),em=r.rows.find(x=>x.recordID.includes(":212505:"));ok(ruby.interval.successCasts===2&&ruby.interval.completedCasts===3,"RUBY");ok(em.interval.successCasts===2&&em.interval.observedRate===2/3,"COOUTPUT");ok(r.rows.find(x=>x.recordID.includes(":212508:")).interval===null,"LOCKED");ok(r.rows.find(x=>x.recordID.includes(":212511:")).interval===null,"UNKNOWN");ok(r.rows.every(x=>x.confidence===0&&x.economicUse==="PREVIEW_ONLY"&&!x.normalizedVerified&&!x.goldRecommendationEligible&&!x.tooltipFallbackEligible),"ISOLATION");ok(r.evidenceFields.expectedQuantity===null,"NO_E");let q=base.synthetic();q.events.filter(x=>x.status==="COMPLETED").forEach(x=>x.outputCapture.countsByItemID["212495"]=0);ok(analyze(q).rows[0].interval.upper>0,"ZERO_NOT_ABSENCE");bad(()=>interval(0,0,.05),"N0");bad(()=>interval(10,11,.05),"K_GT_N");bad(()=>interval(10,2,0),"ALPHA");bad(()=>design(0),"TARGET");bad(()=>analyze({...s,events:[]}),"EVENTS");return {passed:n,failed:0,syntheticOnly:true,actualRetailCasts:0,newVerifiedE:0,exactTargetKeys:KEYS.length,onePercentZeroHitDesign:d};}
module.exports={MODEL_ID,KEYS,cdf,interval,zeroUpper,design,analyze,selfTest};
if(require.main===module){console.log(JSON.stringify(process.argv.includes("--self-test")?selfTest():analyze(base.synthetic()),null,2));}
