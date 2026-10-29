"use strict";
/**
 * Research-only TWW milling identifiability and preview sensitivity model v1.
 * No live runtime import. No evidence/tooltip/gold promotion.
 * CLI: node research/tools/models_v2/tww_milling_context_sensitivity_v1.js --self-test
 *      node research/tools/models_v2/tww_milling_context_sensitivity_v1.js --emit
 */
const VERSION = "tww-milling-context-sensitivity-v1.0.0";
const KEYS = [
  ["historical:tww:mill:210796:222619:reddit-1fdmzwy-2024",210796,222619,1.15,1,2,444181],
  ["historical:tww:mill:210797:222619:reddit-1fdmzwy-2024",210797,222619,1.35,2,2,444181],
  ["candidate:tww:mill:210798:222618:runtime-method-family:20261028",210798,222618,null,3,1,null],
  ["candidate:tww:mill:210799:222612:runtime-method-family:20261028",210799,222612,null,1,1,null],
  ["candidate:tww:mill:210800:222613:runtime-method-family:20261028",210800,222613,null,2,2,null],
  ["candidate:tww:mill:210801:222614:runtime-method-family:20261028",210801,222614,null,3,3,null],
  ["candidate:tww:mill:210802:224800:runtime-method-family:20261028",210802,224800,null,1,1,null],
  ["candidate:tww:mill:210803:224801:runtime-method-family:20261028",210803,224801,null,2,2,null],
  ["candidate:tww:mill:210804:224802:runtime-method-family:20261028",210804,224802,null,3,3,null],
  ["candidate:tww:mill:210805:224803:runtime-method-family:20261028",210805,224803,null,1,1,null],
  ["candidate:tww:mill:210806:224804:runtime-method-family:20261028",210806,224804,null,2,2,null],
  ["candidate:tww:mill:210807:224805:runtime-method-family:20261028",210807,224805,null,3,3,null]
];
const SOURCE = {
  studyFamilyID:"reddit-1fdmzwy-2024-original-author",
  url:"https://www.reddit.com/r/woweconomy/comments/1fdmzwy",
  observationEpoch:"2024-09-10",
  retrievedDate:"2026-10-29",
  originalCompletedCasts:null,
  originalInputRankCohortDenominators:null,
  reportedMetric:"output_units_per_herb_aggregate",
  numeratorAndDenominatorAudit:"UNAVAILABLE",
  characterSkillAndStats:"UNKNOWN",
  independentHoldout:"NONE"
};
const isFiniteNumber = x => typeof x === "number" && Number.isFinite(x);
function requireValid(ok, code) { if (!ok) throw new Error(code); }
function contextFor(keyRow) {
  const [recordID,inputItemID,outputItemID,_,inputQualityRank,outputQualityRank,recipeSpellID] = keyRow;
  const context = {
    contextVersion:"1.0.0", recordID, gameMode:"RETAIL",
    targetBuildOrPatchEpoch:null, expansionID:10, method:"Mill",
    recipeOrOperationVariant:"Khaz Algar Milling",
    recipeSpellID, operationFamilySpellID:444181, inputItemID, outputItemID,
    inputQualityRank, outputQualityRank,
    nominalInputCountPerOperation:10,
    reagentVector:[{itemID:inputItemID,unitsPerOperation:10}],
    minimumRecipeEligibleSkill:null,
    optionalSkillSpecializationGearBonuses:{referenceOptionalBonus:0,actualBonuses:null},
    professionStatsWithUnits:null, unlocks:null,
    sourceStudyFamilyID:keyRow[3]===null?null:SOURCE.studyFamilyID,
    observationEpoch:keyRow[3]===null?null:SOURCE.observationEpoch,
    completedCasts:null, grossInputUnits:null, refundedReagentUnits:null,
    baselineStatus:"HYPOTHETICAL_ZERO_OPTIONAL_BONUS_NOT_VERIFIED_MIN_SKILL",
    eligibilityStatus:"EXACT_OUTPUT_RANK_AND_SKILL_ELIGIBILITY_UNVERIFIED"
  };
  validateContext(context);
  return context;
}
function validateContext(c) {
  requireValid(c && c.gameMode==="RETAIL" && c.method==="Mill", "CONTEXT_GAME_METHOD");
  requireValid(Number.isSafeInteger(c.inputItemID)&&c.inputItemID>0 &&
    Number.isSafeInteger(c.outputItemID)&&c.outputItemID>0, "CONTEXT_IDS");
  requireValid(c.nominalInputCountPerOperation===10 &&
    c.reagentVector.length===1 &&
    c.reagentVector[0].itemID===c.inputItemID &&
    c.reagentVector[0].unitsPerOperation===10, "CONTEXT_REAGENT_VECTOR");
  requireValid([1,2,3].includes(c.inputQualityRank) && [1,2,3].includes(c.outputQualityRank), "CONTEXT_QUALITY_RANK");
  requireValid(c.minimumRecipeEligibleSkill===null ||
    (Number.isInteger(c.minimumRecipeEligibleSkill)&&c.minimumRecipeEligibleSkill>=0),
    "CONTEXT_MIN_ELIGIBLE_SKILL");
  requireValid(c.optionalSkillSpecializationGearBonuses.referenceOptionalBonus===0,
    "CONTEXT_OPTIONAL_BONUS");
  return true;
}
/**
 * Conditional positive integer PMF is a hypothetical generative model, not
 * empirical support. P is an independent parameter; E includes zero outcomes.
 */
function forward({hitProbability,positiveYieldPMF}) {
  requireValid(isFiniteNumber(hitProbability)&&hitProbability>=0&&hitProbability<=1,"P_DOMAIN");
  // A zero-hit model has no positive conditional outcome, even if a caller
  // supplied a hypothetical PMF. Suppress support instead of leaking bounds.
  if(hitProbability===0){
    requireValid(positiveYieldPMF===undefined || positiveYieldPMF===null ||
      Array.isArray(positiveYieldPMF),"PMF_DOMAIN");
    return {dropChance:0,yieldMin:null,yieldMax:null,expectedQuantity:0,
      conditionalYieldApplicable:false,
      zeroSemantics:"MODEL_ZERO_HIT_NOT_PROOF_OF_IMPOSSIBILITY",
      economicUse:"PREVIEW_ONLY",normalizedVerified:false,confidence:0,
      status:"HYPOTHETICAL_ZERO_HIT_SUPPORT_INAPPLICABLE"};
  }
  requireValid(Array.isArray(positiveYieldPMF)&&positiveYieldPMF.length>0,"PMF_MISSING");
  let sum=0,mean=0,min=Infinity,max=-Infinity;
  for(const row of positiveYieldPMF) {
    requireValid(Number.isSafeInteger(row.quantity)&&row.quantity>0 &&
      isFiniteNumber(row.probability)&&row.probability>=0&&row.probability<=1,"PMF_DOMAIN");
    sum+=row.probability;mean+=row.quantity*row.probability;
    min=Math.min(min,row.quantity);max=Math.max(max,row.quantity);
  }
  requireValid(Math.abs(sum-1)<1e-9,"PMF_NOT_NORMALIZED");
  const e=hitProbability*mean;
  requireValid(e+1e-9>=hitProbability*min&&e<=hitProbability*max+1e-9,"PE_RANGE");
  return {dropChance:hitProbability,yieldMin:min,yieldMax:max,expectedQuantity:e,
    conditionalYieldApplicable:true,zeroSemantics:null,
    economicUse:"PREVIEW_ONLY",normalizedVerified:false,confidence:0,
    status:"HYPOTHETICAL_MODEL_NOT_MEASURED"};
}
/** Recover only identifiable empirical quantities from a zero-inclusive histogram. */
function inverseHistogram({completedCasts,histogram}) {
  if(!Number.isSafeInteger(completedCasts)||completedCasts<1 ||
     !histogram || typeof histogram!=="object")
    return {identifiable:false,dropChance:null,yieldMin:null,yieldMax:null,
      expectedQuantity:null,blocker:"MISSING_ACTUAL_CASTS_OR_HISTOGRAM"};
  let casts=0,hits=0,total=0,min=Infinity,max=-Infinity;
  for(const [quantityString,count] of Object.entries(histogram)) {
    const q=Number(quantityString);
    requireValid(String(q)===quantityString && Number.isSafeInteger(q)&&q>=0 &&
      Number.isSafeInteger(count)&&count>=0,"HISTOGRAM_DOMAIN");
    casts+=count;total+=q*count;
    if(q>0 && count>0){hits+=count;min=Math.min(min,q);max=Math.max(max,q);}
  }
  requireValid(casts===completedCasts,"HISTOGRAM_DENOMINATOR_MISMATCH");
  return {identifiable:true,dropChance:hits/casts,
    yieldMin:hits?min:null,yieldMax:hits?max:null,expectedQuantity:total/casts,
    conditionalYieldApplicable:hits>0,
    zeroSemantics:hits?null:"OBSERVED_ZERO_HITS_NOT_PROOF_OF_IMPOSSIBILITY",
    completedCasts:casts,successCasts:hits,
    observationBasis:"ZERO_INCLUSIVE_ACTUAL_COMPLETED_CASTS",
    baselineNormalized:false};
}
/**
 * For ratio y per herb:
 *  - if herb denominator is NOMINAL (10*C), E=10*y;
 *  - if denominator is NET (10*C - refunds), E=10*y*(1-r).
 * Neither hypothesis identifies r, character context or 2026 E.
 */
function ratioSensitivity({perHerb,denominatorBasis,refundFraction}) {
  requireValid(isFiniteNumber(perHerb)&&perHerb>=0,"RATIO_DOMAIN");
  requireValid(denominatorBasis==="NOMINAL"||denominatorBasis==="NET","BASIS_UNKNOWN");
  requireValid(isFiniteNumber(refundFraction)&&refundFraction>=0&&refundFraction<1,"REFUND_DOMAIN");
  const e=10*perHerb*(denominatorBasis==="NET"?(1-refundFraction):1);
  return {expectedQuantity:e,dropChance:null,yieldMin:null,yieldMax:null,
    evidencePromotion:false,economicUse:"PREVIEW_ONLY",normalizedVerified:false,
    confidence:0,assumedDenominatorBasis:denominatorBasis,
    assumedRefundFraction:refundFraction,
    applicability:"HISTORICAL_AGGREGATE_SENSITIVITY_ONLY"};
}
function scenarioDistribution(expectedQuantity) {
  requireValid(isFiniteNumber(expectedQuantity)&&expectedQuantity>=1,"SCENARIO_E_DOMAIN");
  const lo=Math.floor(expectedQuantity),hi=Math.ceil(expectedQuantity);
  const pmf=lo===hi?[{quantity:lo,probability:1}]:
    [{quantity:lo,probability:hi-expectedQuantity},
     {quantity:hi,probability:expectedQuantity-lo}];
  return {...forward({hitProbability:1,positiveYieldPMF:pmf}),
    positiveYieldPMF:pmf,assumption:"P_EQUALS_ONE_AND_SUPPORT_FLOOR_CEIL_ARE_SYNTHETIC_NOT_SOURCE_BOUNDS"};
}
function buildProposal() {
  return {modelVersion:VERSION,scope:"RESEARCH_ONLY",targetKeys:KEYS.map(x=>x[0]),
    source:SOURCE,recipeFact:{spellID:444181,nominalHerbsPerOperation:10,
      provenance:"https://www.wowhead.com/spell=444181/khaz-algar-milling"},
    records:KEYS.map(row=>{
      const context=contextFor(row),ratio=row[3];
      const historicalScenarios=ratio===null?[]:
        ["NOMINAL","NET"].flatMap(basis=>[0,0.1,0.2].map(refundFraction=>{
          const sensitivity=ratioSensitivity({perHerb:ratio,denominatorBasis:basis,refundFraction});
          return {...sensitivity,previewScenario:scenarioDistribution(sensitivity.expectedQuantity)};
        }));
      return {recordID:row[0],context,sourceRatioPerHerb:ratio,
        sourceRatioStatus:ratio===null?"NO_EXACT_TUPLE_SOURCE":"HISTORICAL_REPORTED_CONTEXT_UNVERIFIED",
        currentRetailEconomicFields:{dropChance:null,yieldMin:null,yieldMax:null,expectedQuantity:null},
        historicalScenarios,missingEvidence:["actual completed casts","zero-inclusive per-cast histogram",
          "rank-verified output selector","minimum eligible skill and observed character skill",
          "specialization/gear/stat units","gross versus net herb denominator and refunds",
          "current Retail patch holdout"],
        economicUse:"PREVIEW_ONLY",normalizedVerified:false,confidence:0};
    }),
    identifiability:"HISTORICAL_RATIO_PLUS_UNKNOWN_REFUNDS_AND_SKILL_DOES_NOT_IDENTIFY_CURRENT_BASELINE",
    independence:"ALL_RATIO_SCENARIOS_SHARE_ONE_AUTHOR_STUDY_FAMILY_NOT_HOLDOUTS",
    nextDataRequest:"Current-Retail 10-herb actual completed casts, exact output-rank histogram including zeros, skill/spec/gear, refunds, patch and author/session ID",
    validatorHoldout:"Hold out entire independent author/session family; compare raw unnormalized per-cast output by rank and stat context; do not reuse Reddit author scenarios as independent validation"};
}
function selfTest(){
  const proposal=buildProposal();
  requireValid(proposal.records.length===12&&new Set(proposal.targetKeys).size===12,"TARGET_KEYS");
  requireValid(proposal.records.every(r=>r.context.nominalInputCountPerOperation===10 &&
    r.context.inputQualityRank!==null && r.context.outputQualityRank!==null &&
    r.economicUse==="PREVIEW_ONLY" && r.confidence===0 &&
    Object.values(r.currentRetailEconomicFields).every(v=>v===null)),"ISOLATION");
  requireValid(proposal.records.filter(r=>r.historicalScenarios.length===6).length===2,"SCENARIO_SCOPE");
  const observed=inverseHistogram({completedCasts:4,histogram:{"0":2,"1":1,"3":1}});
  requireValid(observed.dropChance===0.5&&observed.expectedQuantity===1&&
    observed.yieldMin===1&&observed.yieldMax===3,"HISTOGRAM_ESTIMATOR");
  requireValid(!inverseHistogram({completedCasts:null,histogram:null}).identifiable,"MISSING_CAST_GUARD");
  const x=ratioSensitivity({perHerb:1.15,denominatorBasis:"NET",refundFraction:0.2});
  requireValid(Math.abs(x.expectedQuantity-9.2)<1e-9,"REFUND_SENSITIVITY");
  const f=scenarioDistribution(11.5);
  requireValid(f.expectedQuantity===11.5&&f.dropChance===1&&f.confidence===0,"FORWARD");
  let rejected=false;try{inverseHistogram({completedCasts:4,histogram:{"0":3}})}catch(_){rejected=true;}
  requireValid(rejected,"DENOMINATOR_GUARD");
  const zero=forward({hitProbability:0,positiveYieldPMF:[{quantity:3,probability:1}]});
  requireValid(zero.dropChance===0&&zero.expectedQuantity===0&&
    zero.yieldMin===null&&zero.yieldMax===null&&
    zero.conditionalYieldApplicable===false,"ZERO_FORWARD_SUPPORT_SUPPRESSED");
  const zeroNoPMF=forward({hitProbability:0});
  requireValid(zeroNoPMF.expectedQuantity===0&&zeroNoPMF.yieldMin===null&&
    zeroNoPMF.yieldMax===null,"ZERO_FORWARD_NO_PMF");
  const allZero=inverseHistogram({completedCasts:3,histogram:{"0":3}});
  requireValid(allZero.dropChance===0&&allZero.expectedQuantity===0&&
    allZero.yieldMin===null&&allZero.yieldMax===null&&
    allZero.conditionalYieldApplicable===false,"ZERO_INVERSE_SUPPORT");
  requireValid(observed.conditionalYieldApplicable===true&&
    f.conditionalYieldApplicable===true,"NONZERO_CONDITIONAL_SUPPORT");
  requireValid(zero.economicUse==="PREVIEW_ONLY"&&zero.normalizedVerified===false&&
    zero.confidence===0,"ZERO_PREVIEW_ISOLATION");
  return {passed:13,targets:12,sourceAnchoredTargets:2,unanchoredTargets:10,
    currentRetailNumericPromotions:0,previewScenarios:12};
}
module.exports={VERSION,KEYS,SOURCE,contextFor,validateContext,forward,inverseHistogram,
  ratioSensitivity,scenarioDistribution,buildProposal,selfTest};
if(typeof require!=="undefined"&&require.main===module){
  if(process.argv.includes("--self-test"))console.log(JSON.stringify(selfTest(),null,2));
  else if(process.argv.includes("--emit"))console.log(JSON.stringify(buildProposal(),null,2));
  else console.log("Use --self-test or --emit");
}
