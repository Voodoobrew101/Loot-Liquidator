"use strict";
// F005 independent, synthetic-only numerical acceptance for F003 exact binomial bounds.
// Reference CDF is mode-normalized bidirectional recurrence, NOT the model's log-mass tail.
const assert=require("node:assert/strict");
const m=require("../../tools/models_v2/tww_gem_finding_exact_marginal_bounds_v1.js");
const base=require("../../tools/models_v2/tww_gem_finding_conditional_cohorts_v1.js");
function referenceCDF(n,k,p){
  if(k<0)return 0;if(k>=n||p===0)return 1;if(p===1)return 0;
  const mode=Math.floor((n+1)*p),q=1-p,weights=new Float64Array(n+1);
  weights[mode]=1;
  for(let j=mode;j>0;j--)weights[j-1]=weights[j]*j/(n-j+1)*q/p;
  for(let j=mode;j<n;j++)weights[j+1]=weights[j]*(n-j)/(j+1)*p/q;
  let total=0,partial=0;
  for(let j=0;j<=n;j++){total+=weights[j];if(j<=k)partial+=weights[j];}
  return partial/total;
}
let passed=0,failed=0,maxAbsoluteError=0;const failures=[];
function check(name,fn){
  try{fn();passed++;}
  catch(e){failed++;if(failures.length<15)failures.push({name,error:e.message});}
}
const probabilities=[1e-7,.0001,.001,.01,.1,.3,.5,.7,.9,.99,.999,.9999,1-1e-7];
for(const n of [1,2,3,10,100,1000,10000]){
 for(const p of probabilities){
  const mean=n*p,sd=Math.sqrt(n*p*(1-p));
  const ks=[0,1,2,n-2,n-1,Math.floor(mean-5*sd),Math.floor(mean-2*sd),Math.floor(mean),Math.floor(mean+2*sd),Math.floor(mean+5*sd)].filter(k=>k>=0&&k<n);
  for(const k of new Set(ks)){
   check("cdf:"+n+":"+k+":"+p,()=>{
    const actual=m.cdf(n,k,p),expected=referenceCDF(n,k,p),err=Math.abs(actual-expected);
    maxAbsoluteError=Math.max(maxAbsoluteError,err);
    assert.ok(err<2e-8,"CDF_DIFFERENCE "+err);
   });
  }
 }
}
for(const [n,k,alpha] of [[1,0,.05],[1,1,.05],[2,1,.05],[10,0,.05],[10,10,.05],[10,5,.05],[100,1,.05],[100,99,.05],[100,50,.05],[1000,1,.05],[1000,999,.05],[1000,500,.05],[10000,1,.05],[10000,9999,.05],[10000,5000,.05],[10000,9000,.05],[10000,9900,.05],[10000,9000,.05/8],[10000,1,.05/8],[10000,9999,.05/8]]){
 check("cp:"+n+":"+k+":"+alpha,()=>{
  const r=m.interval(n,k,alpha),a=alpha/2;
  assert.ok(r.lower>=0&&r.upper<=1&&r.lower<=k/n&&r.upper>=k/n&&r.lower<=r.upper,"CP_ORDER");
  if(k>0)assert.ok(Math.abs(1-referenceCDF(n,k-1,r.lower)-a)<3e-8,"CP_LOWER");
  if(k<n)assert.ok(Math.abs(referenceCDF(n,k,r.upper)-a)<3e-8,"CP_UPPER");
 });
}
check("eight-way Bonferroni zero-hit design",()=>{
 const d=m.design(.01,.05,8);
 assert.equal(d.casts,574);assert.equal(d.nominalOre,2870);
 assert.ok(m.zeroUpper(574,.05,8)<=.01&&m.zeroUpper(573,.05,8)>.01);
});
check("source family and economic isolation",()=>{
 const r=m.analyze(base.synthetic());
 assert.equal(r.comparisonCount,8);assert.equal(r.rows.length,4);
 assert.ok(r.rows.every(x=>x.confidence===0&&x.economicUse==="PREVIEW_ONLY"&&x.normalizedVerified===false&&x.goldRecommendationEligible===false&&x.tooltipFallbackEligible===false));
 assert.equal(r.evidenceFields.expectedQuantity,null);
});
const result={suite:"F005_F003_INDEPENDENT_BINOMIAL_NUMERICS",syntheticOnly:true,actualRetailCasts:0,passed,failed,maxAbsoluteError,failures,independentReference:"MODE_NORMALIZED_BIDIRECTIONAL_RECURRENCE"};
console.log(JSON.stringify(result));
if(failed)process.exitCode=1;
module.exports=result;
