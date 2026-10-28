"use strict";
const assert=require("node:assert/strict");
const {infer}=require("../tools/infer_latent_study_context");
const identity={gameMode:"RETAIL",expansionID:11,method:"Prospect",recipeID:123,
 inputItemID:234,outputItemID:345,inputQualityRank:1,outputQualityRank:1};
const base={researchOnly:true,observation:{observationID:"unknown-character",studyID:"unique-holdout",
  identity,sourcePublicationDate:"2026-04-05",completedOperations:200,
  outputCountHistogram:{"0":100,"1":100},hitOperations:100,totalUnits:100},
 candidates:[
  {profileID:"pre-low",identity,epochID:"pre-mar31",earliestPossibleObservationDate:"2026-02-20",
   latestPossibleObservationDate:"2026-03-30",context:{skill:1,stats:{bonus:0}},
   priorWeight:1,modelStatus:"VERIFIED_NUMERIC",mechanicRuleVersion:"hypothetical-verified-1",
   trainingStudyIDs:["separate-measurement"],predictedOutputCountDistribution:{"0":.8,"1":.2}},
  {profileID:"post-high",identity,epochID:"post-mar31",earliestPossibleObservationDate:"2026-03-31",
   context:{skill:100,stats:{bonus:10}},priorWeight:1,modelStatus:"VERIFIED_NUMERIC",
   mechanicRuleVersion:"hypothetical-verified-2",trainingStudyIDs:["separate-measurement"],
   predictedOutputCountDistribution:{"0":.5,"1":.5}}
 ]};
const result=infer(base);
assert.equal(result.status,"RANKED_CONTEXT_HYPOTHESES");
assert.equal(result.bestHypothesis.profileID,"post-high");
assert.ok(result.bestHypothesis.posteriorProbability>.999);
assert.equal(result.credibleSet95[0],"post-high");
assert.ok(result.warnings.includes("NO_DIRECT_CAST_DATE"));
assert.ok(result.warnings.includes("NOT_PROOF_OF_EXACT_SKILL_BONUS_OR_CALENDAR_DATE"));
const prePublication=infer({...base,observation:{...base.observation,sourcePublicationDate:"2026-03-29"}});
assert.equal(prePublication.bestHypothesis.profileID,"pre-low");
assert.equal(prePublication.candidates.find(x=>x.profileID==="post-high").excluded,
  "POSTDATES_SOURCE_PUBLICATION");
const knownPre=infer({...base,observation:{...base.observation,allowedEpochs:["pre-mar31"]}});
assert.equal(knownPre.bestHypothesis.profileID,"pre-low");
const equal=infer({...base,candidates:base.candidates.map(x=>({...x,
  predictedOutputCountDistribution:{"0":.5,"1":.5}}))});
assert.equal(equal.status,"UNIDENTIFIABLE_SAME_DISTRIBUTION");
assert.equal(equal.bestHypothesis.posteriorProbability,.5);
assert.deepEqual(equal.credibleSet95.sort(),["post-high","pre-low"].sort());
const weak=infer({...base,observation:{...base.observation,completedOperations:1,
  outputCountHistogram:{"0":0,"1":1},hitOperations:1,totalUnits:1}});
assert.ok(weak.bestHypothesis.posteriorProbability<.9);
const notVerified=infer({...base,candidates:base.candidates.map(x=>({...x,modelStatus:"EMPIRICAL_ESTIMATE"}))});
assert.equal(notVerified.modelCalibrationVerified,false);
const trainingOverlap=infer({...base,candidates:base.candidates.map(x=>({...x,
 trainingStudyIDs:["unique-holdout"]}))});
assert.ok(trainingOverlap.warnings.includes("UNVERIFIED_MODEL_OR_TRAINING_DATA_LEAKAGE"));
const aggregateOnly=infer({...base,observation:{...base.observation,hitOperations:null,
  outputCountHistogram:null}});
assert.equal(aggregateOnly.status,"INSUFFICIENT_CAST_OUTCOME_DATA");
assert.equal(infer({...base,candidates:base.candidates.map(x=>({...x,priorWeight:
 x.profileID==="pre-low"?5:1}))}).bestHypothesis.profileID,"post-high");
assert.throws(()=>infer({...base,candidates:base.candidates.map(x=>({...x,
 predictedOutputCountDistribution:{"0":.1,"1":.8}}))}),/sum to one/);
assert.throws(()=>infer({...base,observation:{...base.observation,
 outputCountHistogram:{"0":99,"1":100}}}),/every cast/);
assert.throws(()=>infer({...base,candidates:[base.candidates[0],base.candidates[0]]}),/Unique profileID/);
const eventContradiction=infer({...base,observation:{...base.observation,allowedEpochs:["out-of-catalog"]}});
assert.equal(eventContradiction.status,"NO_ADMISSIBLE_CONTEXT");
const impossible=infer({...base,candidates:base.candidates.map(x=>({...x,
 predictedOutputCountDistribution:{"0":1,"1":0}}))});
assert.equal(impossible.status,"ALL_CANDIDATES_CONTRADICT_OBSERVATION");
console.log("latent profile inverse inference synthetic tests passed; NOT historical mechanic validation");
