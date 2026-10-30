"use strict";
/* F005 independent QA: source-attested Prismatic Ore identity and two-stage economics.
 * Run: node research/tests/v2/test_f005_df_prismatic_stage_identity_20261030.js
 * Research-only. Do not alter evidence, model or live economics to make tests pass.
 */
const fs=require("node:fs"),path=require("node:path");
const model=require("../../tools/models_v2/df_historical_diamond_denominator_stage_guard_v1.js");
const root=path.resolve(__dirname,"../../..");
const read=p=>JSON.parse(fs.readFileSync(path.join(root,p),"utf8"));
const old=read("research/evidence/v2/2026-10-30T2028Z-F004-df-two-stage-diamond-denominators.json");
const evidence=read("research/evidence/v2/2026-10-30T2130Z-F004-df-prismatic-identity-and-primary-ore-cohorts.json");
const review=read("research/evidence/v2/source-reviews/2026-10-30T2130Z-F004-df-prismatic-identity-and-primary-ore-cohorts-source-review.json");
const manifest=read("research/models/v2/df_historical_diamond_denominator_stage_guard_v1.json");
const readiness=read("research/coordination/completion-readiness.json");
const priorities=read("research/coordination/completion-priorities.json");
const eq=(a,b)=>{if(a!==b)throw Error("expected "+JSON.stringify(b)+" got "+JSON.stringify(a));};
const yes=(a,msg)=>{if(!a)throw Error(msg||"assertion failed");};
const throws=(fn)=>{let threw=false;try{fn();}catch(_){threw=true;}yes(threw,"expected rejection");};
const corrected=194545,crumbled=192880;
function gate(x){return x&&x.inputFamily==="Prismatic Ore"&&x.inputItemID===corrected&&x.stage==="SECOND_STAGE";}
function run(){
 const results=[];const t=(name,fn)=>{try{fn();results.push({name,status:"PASS"});}catch(e){results.push({name,status:"FAIL",reason:String(e.message||e)});}};
 const oldB=old.cohorts.find(x=>x.id==="B-prismatic-1000");
 const a=evidence.firstStageOriginalCohorts.find(x=>x.author==="TheChisel");
 const b=evidence.firstStageOriginalCohorts.find(x=>x.author==="Hotfor");
 const out=model.analyze();
 t("old immutable cohort exhibits recorded 192880 misattribution",()=>eq(oldB.inputItemID,crumbled));
 t("correction references exact old path and cohort",()=>{eq(evidence.sourceIdentityCorrection.priorImmutableEvidencePath,manifest.sourceEvidence);eq(evidence.sourceIdentityCorrection.priorCohortID,oldB.id);});
 t("correction retains old and new IDs separately",()=>{eq(evidence.sourceIdentityCorrection.priorValue,crumbled);eq(evidence.sourceIdentityCorrection.proposedValue,corrected);yes(crumbled!==corrected);});
 t("Prismatic Ore source identity is 194545",()=>{eq(a.outputItemID,corrected);eq(b.outputItemID,corrected);});
 t("model source second-stage input uses corrected 194545",()=>eq(model.SOURCE.secondStage.inputItemID,corrected));
 t("model analyze second-stage input uses corrected 194545",()=>eq(out.secondStage.inputItemID,corrected));
 t("model manifest second-stage label uses corrected 194545",()=>yes(manifest.modelAssumptions.stageSeparation.includes("(194545)"),"manifest still labels 192880 as Prismatic"));
 t("stage gate rejects mislabeled Crumbled Stone",()=>yes(!gate({inputFamily:"Prismatic Ore",inputItemID:crumbled,stage:"SECOND_STAGE"})));
 t("stage gate accepts corrected Prismatic Ore",()=>yes(gate({inputFamily:"Prismatic Ore",inputItemID:corrected,stage:"SECOND_STAGE"})));
 t("stage gate rejects renamed Crumbled Stone",()=>yes(!gate({inputFamily:"Crumbled Stone",inputItemID:corrected,stage:"SECOND_STAGE"})));
 t("stage gate rejects first-stage spoof",()=>yes(!gate({inputFamily:"Prismatic Ore",inputItemID:corrected,stage:"FIRST_STAGE"})));
 t("new source correction is proposal, not accepted",()=>yes(evidence.sourceIdentityCorrection.proposedAction.includes("Coordinator")));
 t("original study lineages distinct",()=>yes(a.sourceLineage!==b.sourceLineage));
 t("new studies not misrepresented as independently validated",()=>eq(review.independentValidation,"NOT_PERFORMED"));
 t("source URL shared and old cohort not double counted",()=>{eq(evidence.sourceAncestry.reusedCohortCount,0);yes(review.sourceMemoryCheck.existingURLIndexed);});
 t("TheChisel raw input and cast reports",()=>{eq(a.reportedOreUnits,5000);eq(a.reportedProspects,1000);eq(a.reportedOutputUnits,31);eq(a.reportedInputRank,3);});
 t("TheChisel observed units per reported cast",()=>yes(Math.abs(a.observedOutputUnitsPerReportedCast-31/1000)<1e-14));
 t("TheChisel rank ID is proposed not original",()=>{eq(a.proposedCatalogInputItemID,190394);eq(a.itemIDExplicitInOriginal,false);});
 t("TheChisel 3 percent is not measured P",()=>{eq(a.isMeasuredOccurrenceProbability,false);eq(a.outputCastHistogram,null);});
 t("TheChisel exact epoch and refunds unknown",()=>{eq(a.actualObservationEpoch,null);eq(a.resourcefulnessRefunds,null);});
 t("Hotfor three rank IDs are distinct",()=>{eq(b.inputItemIDs.length,3);eq(new Set(b.inputItemIDs).size,3);});
 t("Hotfor rank mixture not allocatable",()=>{eq(b.reportedInputRank,"MIXED_THREE_RANKS");eq(b.actualCompletedCasts,null);});
 t("Hotfor raw 7000 and 62 quantities",()=>{eq(b.reportedOreUnits,7000);eq(b.reportedOutputUnits,62);});
 t("Hotfor nominal 5 ore equivalents not actual casts",()=>{eq(b.nominalCastEquivalents,1400);eq(b.actualCompletedCasts,null);});
 t("Hotfor nominal ratio is not an economic E",()=>yes(Math.abs(b.nominalOutputUnitsPerFiveOreEquivalent-62/1400)<1e-14));
 t("new evidence has no economic promotion",()=>{eq(evidence.economicSafety.confidence,0);eq(evidence.economicSafety.economicUse,"PREVIEW_ONLY");eq(evidence.economicSafety.normalizedVerified,false);eq(evidence.economicSafety.expectedQuantity,null);});
 t("model has no economic promotion",()=>{eq(out.confidence,0);eq(out.economicUse,"PREVIEW_ONLY");eq(out.normalizedVerified,false);eq(out.liveEconomicEligible,false);});
 t("first-stage model E and P remain null",()=>yes(out.firstStage.every(x=>x.expectedQuantity===null&&x.probability===null)));
 t("second-stage model cast E remains null",()=>{eq(out.secondStage.perCastExpectedQuantity,null);eq(out.secondStage.verifiedCastCount,null);});
 t("old cohort 25/1000 cannot become verified cast E",()=>{eq(oldB.actualCompletedCasts,null);eq(out.secondStage.perCastExpectedQuantity,null);});
 t("source lineage 30k and 50k one family",()=>eq(out.firstStage[0].sourceLineage,out.firstStage[1].sourceLineage));
 t("second-stage author not same study as first",()=>yes(out.secondStage.sourceLineage!==out.firstStage[0].sourceLineage));
 t("first and second processing stages cannot pool",()=>yes(!model.preventFalseDirectJoin("Serevite Ore","Prismatic Ore").allowed));
 t("rank-specific priority keys stay untouched",()=>{eq(model.PRIORITY_KEYS.length,5);yes(model.PRIORITY_KEYS.every(x=>priorities.records.some(y=>y.recordID===x)));});
 t("working preview remains complete in canonical readiness",()=>{eq(readiness.mappingCount,1018);eq(readiness.workingNumericCells,readiness.fieldSlots);eq(readiness.operationalEstimatesAffectLiveValuation,false);});
 t("integer infeasibility 30k ore / 1.08 rate",()=>{let r=model.countRange(30000,"1.08");eq(r.integerFeasible,false);eq(r.minCount,33);eq(r.maxCount,32);});
 t("integer infeasibility 50k ore / 2.57 rate",()=>{let r=model.countRange(50000,"2.57");eq(r.integerFeasible,false);eq(r.minCount,129);eq(r.maxCount,128);});
 t("nearest Serevite integer witness",()=>{let r=model.nearestCompatibleOre(30000,"1.08");eq(r.nearestOreUnits,29767);});
 t("nearest Draconium integer witness",()=>{let r=model.nearestCompatibleOre(50000,"2.57");eq(r.nearestOreUnits,49902);});
 t("nearest 5 ore Serevite witness",()=>eq(model.nearestCompatibleOre(30000,"1.08",1000,5).nearestOreUnits,29765));
 t("nearest 5 ore Draconium witness",()=>eq(model.nearestCompatibleOre(50000,"2.57",1000,5).nearestOreUnits,49900));
 t("invalid ore and decimal rejected",()=>{throws(()=>model.countRange(0,"1.08"));throws(()=>model.countRange(100,"NaN"));});
 t("unknown family rejected",()=>throws(()=>model.stageOf("Crumbled Stone")));
 const passed=results.filter(x=>x.status==="PASS").length,failed=results.length-passed;
 return {suite:"F005_DF_PRISMATIC_STAGE_IDENTITY",passed,failed,tests:results,
  verdict:failed?"FAIL_MODEL_IDENTITY":"CONDITIONAL_PASS_NO_CURRENT_RETAIL_HOLDOUT",
  limitations:["Historical source observations only","No independently verified current-Retail casts","No native WoW client validation"]};
}
module.exports={run};
if(require.main===module){const r=run();console.log(JSON.stringify(r,null,2));if(r.failed)process.exitCode=1;}
