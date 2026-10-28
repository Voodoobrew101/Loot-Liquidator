"use strict";
/**
 * Research-only prediction diagnostics for a candidate unskilled baseline
 * projected by an external, historically scoped mechanics model.
 *
 * This does NOT implement registry coefficient estimation, regression fitting,
 * Bayesian posterior inference, or automatic model promotion. Input predictions
 * must be generated from source-backed mechanics, not the held-out observations.
 *
 * CLI: node research/tools/validate_forward_predictions.js <validation-input.json>
 */
const fs=require("node:fs");
const finite=x=>typeof x==="number"&&Number.isFinite(x);
const bounded=(x,a,b)=>finite(x)&&x>=a&&x<=b;
const has=(a,b)=>a.includes(b);
function unique(xs){return [...new Set(xs)];}
function histogramStats(hist,n) {
  if(!hist||typeof hist!=="object"||Array.isArray(hist))return null;
  let totalEvents=0,units=0,squares=0,positiveHits=0,min=null,max=null;
  for(const [k,v] of Object.entries(hist)){
    if(!/^(0|[1-9]\d*)$/.test(k)||!Number.isSafeInteger(v)||v<0)throw Error("Invalid output histogram");
    const x=Number(k);
    totalEvents+=v;units+=x*v;squares+=x*x*v;
    if(x>0&&v>0){positiveHits+=v;min=min===null?x:Math.min(x,min);max=max===null?x:Math.max(x,max);}
  }
  if(totalEvents!==n)throw Error("Histogram does not include exactly n casts including zeros");
  const mean=units/n;
  const sampleVariance=n>1?Math.max(0,(squares-n*mean*mean)/(n-1)):null;
  return {n,units,hits:positiveHits,positiveMin:min,positiveMax:max,
    mean,sampleVariance,standardError:sampleVariance===null?null:Math.sqrt(sampleVariance/n)};
}
function checkObservation(o){
  if(!o||!Number.isSafeInteger(o.completedOperations)||o.completedOperations<=0)
    throw Error("Actual completedOperations required");
  const n=o.completedOperations;
  const hist=histogramStats(o.outputCountHistogram,n);
  for(const k of ["hitOperations","totalUnits"]){
    const v=o[k];
    if(v!==undefined&&v!==null&&(!Number.isSafeInteger(v)||v<0))
      throw Error("Invalid "+k);
  }
  if(o.hitOperations!=null&&o.hitOperations>n)throw Error("Impossible hit count");
  if(hist){
    if(o.hitOperations!=null&&o.hitOperations!==hist.hits)throw Error("Hit count disagrees with histogram");
    if(o.totalUnits!=null&&o.totalUnits!==hist.units)throw Error("Output count disagrees with histogram");
  }
  return {n,hits:o.hitOperations??hist?.hits??null,units:o.totalUnits??hist?.units??null,histogram:hist};
}
function score(e) {
  const p=e.prediction||{},obs=checkObservation(e.observed),notes=[],fields={};
  const provenance=e.provenance||{};
  const matches=provenance.recipeOutputRankMatches===true&&provenance.historicalEpochResolved===true;
  if(!matches)notes.push("CONTEXT_OR_PATCH_UNRESOLVED");
  const trainStudies=provenance.modelTrainingStudyIDs||[];
  const trainData=provenance.modelTrainingDatasetIDs||[];
  const independent=Array.isArray(trainStudies)&&Array.isArray(trainData)&&
    typeof provenance.holdoutStudyID==="string"&&
    typeof provenance.holdoutDatasetID==="string"&&
    trainStudies.length>0 && trainData.length>0 &&
    !has(trainStudies,provenance.holdoutStudyID)&&!has(trainData,provenance.holdoutDatasetID);
  if(!independent)notes.push("INDEPENDENT_HOLDOUT_NOT_ESTABLISHED");
  if(e.set!=="HOLDOUT")notes.push("NOT_HELD_OUT");
  if(e.numericMechanicStatus!=="VERIFIED_NUMERIC")notes.push("NUMERIC_MECHANIC_UNVERIFIED");
  const hitP=obs.hits===null?null:obs.hits/obs.n;
  if(p.dropChance!==null&&p.dropChance!==undefined) {
    if(!bounded(p.dropChance,0,1))throw Error("Predicted chance outside 0..1");
    if(hitP!==null) {
      const q=p.dropChance;
      const variance=q*(1-q)/obs.n;
      const z=variance>0?(hitP-q)/Math.sqrt(variance):null;
      const deterministicViolation=(q===0&&obs.hits>0)||(q===1&&obs.hits<obs.n);
      const logLikelihood=deterministicViolation?-Infinity:
        (obs.hits===0?0:obs.hits*Math.log(q))+
        (obs.hits===obs.n?0:(obs.n-obs.hits)*Math.log(1-q));
      fields.dropChance={predicted:q,observed:hitP,actualOperations:obs.n,
        probabilityZ:z,deterministicViolation,logLikelihood,
        observationalModel:"BINOMIAL_HOLDOUT_DIAGNOSTIC_ONLY"};
      if(deterministicViolation)notes.push("PROBABILITY_SUPPORT_CONTRADICTION");
      else if(z!==null&&Math.abs(z)>2.576)notes.push("PROBABILITY_LARGE_RESIDUAL_RESEARCH");
    }else{fields.dropChance={predicted:p.dropChance,observed:null,reason:"HIT_COUNTS_NOT_REPORTED"};}
  } else fields.dropChance={predicted:null,observed:hitP,reason:"NO_PREDICTION"};
  if(p.expectedQuantity!==null&&p.expectedQuantity!==undefined){
    if(!finite(p.expectedQuantity)||p.expectedQuantity<0)throw Error("Invalid expectedQuantity prediction");
    if(obs.units!==null) {
      const mu=obs.units/obs.n;
      const sem=obs.histogram?.standardError??null;
      // Standard error is descriptive only. No normal-model approval from sparse sample.
      const z=sem&&sem>0?(mu-p.expectedQuantity)/sem:null;
      fields.expectedQuantity={predicted:p.expectedQuantity,observed:mu,residual:mu-p.expectedQuantity,
        standardErrorFromCompleteHistogram:sem,zDescriptive:z,
        uncertaintyStatus:sem===null?"NO_PER_CAST_VARIANCE":sem===0?"ZERO_EMPIRICAL_VARIANCE":"MEASURED_PER_CAST_HISTOGRAM"};
      if(p.expectedQuantity===0&&obs.units>0)notes.push("EXPECTED_QUANTITY_ZERO_SUPPORT_CONTRADICTION");
      if(z!==null&&Math.abs(z)>2.576)notes.push("MEAN_LARGE_RESIDUAL_RESEARCH");
    }else fields.expectedQuantity={predicted:p.expectedQuantity,observed:null,reason:"TOTAL_UNITS_UNREPORTED"};
  }else fields.expectedQuantity={predicted:null,observed:obs.units===null?null:obs.units/obs.n,reason:"NO_PREDICTION"};
  if(bounded(p.dropChance,0,1)&&p.dropChance===0&&finite(p.expectedQuantity)&&p.expectedQuantity>0)
    notes.push("INCONSISTENT_P_ZERO_BUT_E_POSITIVE");
  if(bounded(p.dropChance,0,1)&&p.dropChance>0&&p.expectedQuantity===0)
    notes.push("INCONSISTENT_P_POSITIVE_BUT_E_ZERO");
  for(const [k,positiveValue,op] of [["yieldMin",obs.histogram?.positiveMin,"below"],["yieldMax",obs.histogram?.positiveMax,"above"]]){
    const predicted=p[k];
    if(predicted!==null&&predicted!==undefined&&(!Number.isSafeInteger(predicted)||predicted<1))throw Error("Invalid positive yield limit");
    const hard=p.hardYieldBoundsVerified===true;
    const observed=positiveValue??null;
    const contradicts=hard&&observed!==null&&predicted!=null&&
      (op==="below"?observed<predicted:observed>predicted);
    fields[k]={predicted:predicted??null,observed,hardBoundVerified:hard,
      deterministicViolation:contradicts,
      note:"Observed positive extremes are sample-dependent, not guaranteed true physical limits"};
    if(contradicts)notes.push(k.toUpperCase()+"_HARD_SUPPORT_CONTRADICTION");
  }
  if(p.yieldMin!=null&&p.yieldMax!=null&&p.yieldMin>p.yieldMax)notes.push("PREDICTED_BOUNDS_INVERTED");
  if(bounded(p.dropChance,0,1)&&finite(p.expectedQuantity)&&p.yieldMin!=null&&p.yieldMax!=null) {
    if(p.expectedQuantity+1e-9<p.dropChance*p.yieldMin||
       p.expectedQuantity-1e-9>p.dropChance*p.yieldMax)notes.push("P_E_CONDITIONAL_BOUNDS_INCONSISTENT");
  }
  const blocking=notes.some(n=>/CONTRADICTION|INCONSISTENT|UNRESOLVED|NOT_ESTABLISHED|NOT_HELD_OUT|UNVERIFIED|INVERTED/.test(n));
  return {observationID:e.observationID??null,targetKey:e.targetKey??null,
    verifiedPrediction:!blocking,
    status:blocking?"NOT_VERIFIED":"HOLDOUT_CONSISTENT_NOT_PROOF",
    evaluatedFields:fields,diagnostics:unique(notes)};
}
function validate(input){
  if(!input||input.researchOnly!==true||!Array.isArray(input.evaluations))throw Error("Invalid research-only validation input");
  const results=input.evaluations.map(score);
  const counts={evaluations:results.length,consistent:results.filter(x=>x.status==="HOLDOUT_CONSISTENT_NOT_PROOF").length,
    notVerified:results.filter(x=>x.status==="NOT_VERIFIED").length};
  return {schemaVersion:"1.0",researchOnly:true,productionPromotions:0,
    modelRevision:input.modelRevision??null,registryRevision:input.registryRevision??null,
    checks:"Out-of-sample forward predictions; fitted-sample agreement is not independent verification",
    counts,results};
}
if(require.main===module){
  const input=JSON.parse(fs.readFileSync(process.argv[2],"utf8"));
  process.stdout.write(JSON.stringify(validate(input),null,2)+"\n");
}
module.exports={histogramStats,checkObservation,score,validate};
