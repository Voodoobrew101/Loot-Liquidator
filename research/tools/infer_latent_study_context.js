"use strict";
/**
 * Research-only inverse inference over a FINITE, externally supplied set of
 * historical skill/stat/patch profiles with already-calibrated predictions.
 * Does not invent skill curves, infer an exact calendar date, or train formulas.
 * CLI: node research/tools/infer_latent_study_context.js <hypotheses.json>
 */
const fs=require("node:fs");
const finite=x=>typeof x==="number"&&Number.isFinite(x);
function validDate(s){
  if(typeof s!=="string"||!/^\d{4}-\d{2}-\d{2}$/.test(s))return false;
  const d=new Date(s+"T00:00:00Z");
  return Number.isFinite(d.valueOf())&&d.toISOString().slice(0,10)===s;
}
function histogram(observation){
  const n=observation.completedOperations;
  if(!Number.isSafeInteger(n)||n<1)throw Error("Actual operation count required");
  if(observation.outputCountHistogram!=null){
    const hist=observation.outputCountHistogram;
    if(!hist||typeof hist!=="object"||Array.isArray(hist))throw Error("Invalid histogram");
    let sum=0,hits=0,units=0;
    for(const [k,v] of Object.entries(hist)){
      if(!/^(0|[1-9]\d*)$/.test(k)||!Number.isSafeInteger(v)||v<0)throw Error("Invalid count histogram");
      sum+=v;
      if(Number(k)>0)hits+=v;
      units+=Number(k)*v;
    }
    if(sum!==n)throw Error("Histogram must include every cast and all zeros");
    if(observation.hitOperations!=null&&observation.hitOperations!==hits)throw Error("Hit/histogram disagreement");
    if(observation.totalUnits!=null&&observation.totalUnits!==units)throw Error("Total/histogram disagreement");
    return {kind:"MULTINOMIAL",counts:hist,n,hits,units};
  }
  const hits=observation.hitOperations;
  if(Number.isSafeInteger(hits)&&hits>=0&&hits<=n){
    return {kind:"BINOMIAL",n,hits,units:Number.isSafeInteger(observation.totalUnits)?observation.totalUnits:null};
  }
  return {kind:"NO_IDENTIFIABLE_LIKELIHOOD",n,hits:null,units:Number.isSafeInteger(observation.totalUnits)?observation.totalUnits:null};
}
function validateDistribution(dist) {
  if(!dist||typeof dist!=="object"||Array.isArray(dist))throw Error("Missing predicted count distribution");
  let sum=0;
  for(const [k,p] of Object.entries(dist)){
    if(!/^(0|[1-9]\d*)$/.test(k)||!finite(p)||p<0||p>1)throw Error("Invalid count distribution probability");
    sum+=p;
  }
  if(Math.abs(sum-1)>1e-8)throw Error("Predicted probabilities must sum to one");
  return dist;
}
function likelihood(data,dist){
  if(data.kind==="NO_IDENTIFIABLE_LIKELIHOOD")return null;
  if(data.kind==="MULTINOMIAL"){
    let value=0;
    for(const [k,count] of Object.entries(data.counts)){
      if(count===0)continue;
      const p=dist[k]??0;
      if(p===0)return -Infinity;
      value+=count*Math.log(p);
    }
    // Shared multinomial coefficient cancels in posterior comparisons.
    return value;
  }
  const q=1-(dist["0"]??0);
  if((q===0&&data.hits>0)||(q===1&&data.hits<data.n))return -Infinity;
  return (data.hits===0?0:data.hits*Math.log(q))+
    (data.hits===data.n?0:(data.n-data.hits)*Math.log(1-q));
}
function eqIdentifier(a,b){
  for(const k of ["gameMode","expansionID","method","recipeID","inputItemID","outputItemID","inputQualityRank","outputQualityRank"]){
    if(a[k]!==b[k])return false;
  }
  return true;
}
function admissibility(observation,candidate){
  if(observation.identity&&!eqIdentifier(observation.identity,candidate.identity||{}))
    return "RECIPE_OR_RANK_MISMATCH";
  if(observation.allowedEpochs&&(!Array.isArray(observation.allowedEpochs)||
    !observation.allowedEpochs.includes(candidate.epochID)))return "REVIEWED_EPOCH_EXCLUDED";
  const pub=observation.sourcePublicationDate;
  if(pub!==undefined&&pub!==null&&!validDate(pub))throw Error("Invalid source publication date");
  if(candidate.earliestPossibleObservationDate!=null){
    if(!validDate(candidate.earliestPossibleObservationDate))throw Error("Invalid earliest candidate date");
    if(pub&&candidate.earliestPossibleObservationDate>pub)return "POSTDATES_SOURCE_PUBLICATION";
  }
  if(observation.observedDate!=null) {
    if(!validDate(observation.observedDate))throw Error("Invalid observedDate");
    if(candidate.earliestPossibleObservationDate&&candidate.earliestPossibleObservationDate>observation.observedDate)
      return "AFTER_MEASURED_CAST_DATE";
    if(candidate.latestPossibleObservationDate&&candidate.latestPossibleObservationDate<observation.observedDate)
      return "BEFORE_MEASURED_CAST_DATE";
  }
  if(candidate.latestPossibleObservationDate!=null&&!validDate(candidate.latestPossibleObservationDate))
    throw Error("Invalid latest candidate date");
  return null;
}
function infer(input){
  if(!input||input.researchOnly!==true||!Array.isArray(input.candidates)||!input.observation)
    throw Error("Require research-only observation and explicit calibrated candidate profiles");
  if(input.candidates.length===0)throw Error("No candidate hypotheses");
  const obs=input.observation,data=histogram(obs),ids=new Set(),rows=[];
  for(const c of input.candidates){
    if(typeof c.profileID!=="string"||!c.profileID.trim()||ids.has(c.profileID))
      throw Error("Unique profileID required");
    ids.add(c.profileID);
    if(!finite(c.priorWeight)||c.priorWeight<=0)throw Error("Explicit positive priorWeight required");
    const dist=validateDistribution(c.predictedOutputCountDistribution);
    const excluded=admissibility(obs,c);
    const overlappingTraining=Array.isArray(c.trainingStudyIDs)&&
      typeof obs.studyID==="string"&&c.trainingStudyIDs.includes(obs.studyID);
    const modelKnown=c.modelStatus==="VERIFIED_NUMERIC";
    rows.push({profileID:c.profileID,epochID:c.epochID??null,
      inferredContext:c.context??null,mechanicRuleVersion:c.mechanicRuleVersion??null,
      trainingOverlap:overlappingTraining,modelKnown,
      priorWeight:c.priorWeight,excluded,distribution:dist,
      logLikelihood:excluded?null:likelihood(data,dist)});
  }
  const active=rows.filter(x=>!x.excluded);
  if(!active.length)return {schemaVersion:"1.0",researchOnly:true,status:"NO_ADMISSIBLE_CONTEXT",
    observationID:obs.observationID??null,candidates:rows.map(({distribution,...rest})=>rest)};
  if(data.kind==="NO_IDENTIFIABLE_LIKELIHOOD")
    return {schemaVersion:"1.0",researchOnly:true,status:"INSUFFICIENT_CAST_OUTCOME_DATA",
      observationID:obs.observationID??null,candidates:rows.map(({distribution,...rest})=>rest),
      note:"Aggregate total alone does not identify a likelihood without a justified output-count distribution model."};
  const logWeight=active.map(x=>Math.log(x.priorWeight)+x.logLikelihood);
  const max=Math.max(...logWeight);
  if(max===-Infinity)return {schemaVersion:"1.0",researchOnly:true,status:"ALL_CANDIDATES_CONTRADICT_OBSERVATION",
    observationID:obs.observationID??null,candidates:rows.map(({distribution,...rest})=>rest)};
  const scaled=logWeight.map(x=>Math.exp(x-max)),den=scaled.reduce((a,b)=>a+b,0);
  active.forEach((x,i)=>{x.posteriorProbability=scaled[i]/den;});
  const ordered=active.slice().sort((a,b)=>b.posteriorProbability-a.posteriorProbability);
  let cumulative=0;
  const credibleSet=[];
  for(const x of ordered){if(cumulative<.95)credibleSet.push(x.profileID);cumulative+=x.posteriorProbability;}
  const spread=ordered.length>1&&ordered.every(x=>{
    const first=ordered[0].distribution,second=x.distribution;
    const keys=new Set([...Object.keys(first),...Object.keys(second)]);
    return [...keys].every(k=>Math.abs((first[k]??0)-(second[k]??0))<=1e-12);
  });
  const couldVerify=active.every(x=>x.modelKnown&&!x.trainingOverlap);
  const warnings=[
    "PROFILE_POSTERIORS_CONDITIONAL_ON_ENUMERATED_CANDIDATES_PRIORS_AND_PREDICTED_DISTRIBUTIONS",
    "NOT_PROOF_OF_EXACT_SKILL_BONUS_OR_CALENDAR_DATE"
  ];
  if(!couldVerify)warnings.push("UNVERIFIED_MODEL_OR_TRAINING_DATA_LEAKAGE");
  if(!obs.observedDate)warnings.push("NO_DIRECT_CAST_DATE");
  if(spread)warnings.push("CANDIDATE_PROFILES_OBSERVATIONALLY_INDISTINGUISHABLE");
  const {distribution:_,...best}=ordered[0];
  return {schemaVersion:"1.0",researchOnly:true,productionPromotions:0,
    status:spread?"UNIDENTIFIABLE_SAME_DISTRIBUTION":"RANKED_CONTEXT_HYPOTHESES",
    observationID:obs.observationID??null,studyID:obs.studyID??null,
    availableCastEvidence:data.kind,numberOfCasts:data.n,
    modelCalibrationVerified:couldVerify,
    bestHypothesis:best,credibleSet95:credibleSet,
    candidates:rows.map(({distribution,...rest})=>rest).sort((a,b)=>
      (b.posteriorProbability??-1)-(a.posteriorProbability??-1)),warnings};
}
if(require.main===module){
  const r=infer(JSON.parse(fs.readFileSync(process.argv[2],"utf8")));
  process.stdout.write(JSON.stringify(r,null,2)+"\n");
}
module.exports={infer,histogram,validateDistribution,likelihood,admissibility};
