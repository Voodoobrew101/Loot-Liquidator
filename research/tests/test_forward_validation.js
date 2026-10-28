"use strict";
const assert=require("node:assert/strict");
const {validate,histogramStats,score,betaBinomialPredictiveZ}=require("../tools/validate_forward_predictions");
const good={
 observationID:"holdout-gem",targetKey:"ore:Prospect:gem",set:"HOLDOUT",
 numericMechanicStatus:"VERIFIED_NUMERIC",
 provenance:{
  recipeOutputRankMatches:true,historicalEpochResolved:true,
  holdoutStudyID:"original-holdout",holdoutDatasetID:"cast-log-2",
  modelTrainingStudyIDs:["separate-study"],modelTrainingDatasetIDs:["cast-log-1"]
 },
 prediction:{dropChance:.25,expectedQuantity:.5,yieldMin:2,yieldMax:2,hardYieldBoundsVerified:true},
 observed:{completedOperations:40,totalUnits:20,hitOperations:10,
  outputCountHistogram:{"0":30,"2":10}}
};
const base=score(good);
assert.equal(base.status,"HOLDOUT_CONSISTENT_NOT_PROOF");
assert.equal(base.evaluatedFields.dropChance.observed,.25);
assert.equal(base.evaluatedFields.expectedQuantity.observed,.5);
assert.equal(base.evaluatedFields.yieldMin.observed,2);
assert.equal(base.evaluatedFields.yieldMax.observed,2);
assert.equal(histogramStats({"0":30,"2":10},40).units,20);
assert.equal(score({...good,provenance:{...good.provenance,holdoutDatasetID:"cast-log-1"}}).status,"NOT_VERIFIED");
assert.ok(score({...good,provenance:{...good.provenance,historicalEpochResolved:false}}).diagnostics.includes("CONTEXT_OR_PATCH_UNRESOLVED"));
assert.ok(score({...good,numericMechanicStatus:"EMPIRICAL_ESTIMATE"}).diagnostics.includes("NUMERIC_MECHANIC_UNVERIFIED"));
let z=score({...good,prediction:{...good.prediction,dropChance:0,expectedQuantity:0}});
assert.ok(z.diagnostics.includes("PROBABILITY_SUPPORT_CONTRADICTION"));
assert.ok(z.diagnostics.includes("EXPECTED_QUANTITY_ZERO_SUPPORT_CONTRADICTION"));
assert.ok(score({...good,prediction:{...good.prediction,yieldMax:1}}).diagnostics.includes("YIELDMAX_HARD_SUPPORT_CONTRADICTION"));
assert.throws(()=>score({...good,observed:{...good.observed,totalUnits:40}}),/disagrees/);
assert.throws(()=>score({...good,observed:{...good.observed,outputCountHistogram:{"0":20,"2":10}}}),/exactly n/);
assert.throws(()=>score({...good,prediction:{...good.prediction,dropChance:1.5}}),/outside/);
const other=score({...good,observed:{completedOperations:40,totalUnits:20,hitOperations:null}});
assert.equal(other.evaluatedFields.expectedQuantity.uncertaintyStatus,"NO_PER_CAST_VARIANCE");
assert.equal(other.evaluatedFields.dropChance.observed,null);
const adj=score({...good,prediction:{dropChance:.1,expectedQuantity:.2,yieldMin:2,yieldMax:2,hardYieldBoundsVerified:true},
  observed:{completedOperations:40,totalUnits:8,hitOperations:4,outputCountHistogram:{"0":36,"2":4}}});
assert.equal(adj.status,"HOLDOUT_CONSISTENT_NOT_PROOF","positive bonus from zero should be representable");
assert.ok(score({...good,prediction:{...good.prediction,expectedQuantity:0}}).diagnostics.includes("INCONSISTENT_P_POSITIVE_BUT_E_ZERO"));
const bayes=betaBinomialPredictiveZ(10,30,40,10);
assert.equal(bayes.expectedHoldoutFraction,.25);
assert.equal(bayes.zPredictive,0);
assert.ok(score({...good,prediction:{...good.prediction,
  trainingPosteriorForDropChance:{alpha:10,beta:30}}}).evaluatedFields.dropChance.bayesianPredictive);
assert.ok(score({...good,prediction:{...good.prediction,
  trainingPosteriorForDropChance:{alpha:500,beta:1500}},
  observed:{completedOperations:40,totalUnits:80,hitOperations:40,outputCountHistogram:{"2":40}}})
  .diagnostics.includes("BAYESIAN_POSTERIOR_PREDICTIVE_DISCREPANCY_RESEARCH"));
assert.equal(score({...good,prediction:{dropChance:null,expectedQuantity:null,yieldMin:null,yieldMax:null}}).status,
  "NOT_VERIFIED","Empty models must not pass a holdout check");
const report=validate({researchOnly:true,modelRevision:"1",registryRevision:"v0.2",evaluations:[good]});
assert.equal(report.counts.consistent,1);
assert.equal(report.productionPromotions,0);
console.log("forward prediction static tests passed (23 checks); synthetic data only, no real mechanics coefficients verified");
