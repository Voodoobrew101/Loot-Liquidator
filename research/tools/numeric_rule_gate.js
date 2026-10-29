"use strict";
// Shared evidence admission gate; no game coefficients are supplied here.
const ALLOWED={
 OUTPUT_UNCONDITIONAL_EXPECTATION:["RATIO_ADJUSTMENT","ADDITIVE_EXPECTATION"],
 OUTPUT_OCCURRENCE:["RATIO_ADJUSTMENT_OCCURRENCE"],
 OUTPUT_QUALITY:["QUALITY_TRANSITION_MATRIX"],
 EXPECTED_INPUT_CONSUMPTION:["EXPECTED_INPUT_SAVINGS"],
 OUTPUT_ELIGIBILITY:["VERIFIED_ELIGIBILITY"],
 OPERATION_DURATION:["DURATION_ADJUSTMENT"]
};
function canCompileNumericRule(r) {
 const errors=[];
 const fail=(ok,msg)=>{if(!ok)errors.push(msg);};
 const sc=r&&r.scope||{},review=r&&r.independentReview||{},src=r&&r.sources||[];
 fail(r&&r.evidenceStatus==="VERIFIED_NUMERIC","must be independently verified numeric");
 fail(r&&r.applyPolicy==="VERIFIED_FOR_COMPILE","must be master-authorized for compilation");
 fail(r&&r.numericTransformValidated===true,"numeric transform has not been validated");
 fail(r&&Number.isInteger(r.confidence0to100)&&r.confidence0to100>=90,"numeric confidence below 90 or missing");
 fail(Array.isArray(ALLOWED[r&&r.effectTarget])&&ALLOWED[r.effectTarget].includes(r.formulaID),"formula not supported for effect target");
 fail(r&&typeof r.profession==="string"&&r.profession.length>0&&Number.isInteger(r.expansionID)&&r.expansionID>=0,"missing profession/expansion");
 fail(sc.gameMode==="RETAIL","unsupported game mode for current Retail itemdb");
 fail(Array.isArray(sc.recipeSpellIDs)&&sc.recipeSpellIDs.length>0&&sc.recipeSpellIDs.every(Number.isSafeInteger),"missing exact recipe spell IDs");
 fail(Array.isArray(sc.inputItemIDs)&&sc.inputItemIDs.length>0&&sc.inputItemIDs.every(Number.isSafeInteger),"missing exact input item IDs");
 fail(Number.isSafeInteger(sc.nominalInputCount)&&sc.nominalInputCount>0,"missing actual recipe batch");
 fail(typeof sc.patchStartBuild==="string"&&sc.patchStartBuild.length>0,"unverified starting client build");
 fail(typeof sc.patchEndBuild==="string"&&sc.patchEndBuild.length>0,"unverified ending client build");
 if(r&&["OUTPUT_UNCONDITIONAL_EXPECTATION","OUTPUT_OCCURRENCE","OUTPUT_QUALITY","OUTPUT_ELIGIBILITY"].includes(r.effectTarget))
   fail(Array.isArray(sc.outputItemIDs)&&sc.outputItemIDs.length>0&&sc.outputItemIDs.every(Number.isSafeInteger),"missing exact affected output IDs");
 const params=r&&r.parameters;
 const isMatrix=r&&r.formulaID==="QUALITY_TRANSITION_MATRIX";
 const matrix=isMatrix&&params&&params.transitionMatrix;
 const ranks=sc.outputQualityRanks||[];
 const matrixOK=isMatrix&&Array.isArray(matrix)&&Array.isArray(ranks)&&ranks.length>=2
      &&matrix.length===ranks.length
      &&matrix.every(row=>Array.isArray(row)&&row.length===ranks.length
         &&row.every(v=>typeof v==="number"&&Number.isFinite(v)&&v>=0&&v<=1)
         &&Math.abs(row.reduce((a,b)=>a+b,0)-1)<1e-8);
 const scalarOK=params&&typeof params==="object"&&Object.keys(params).length>0
      &&Object.values(params).every(v=>typeof v==="number"&&Number.isFinite(v));
 fail(isMatrix?matrixOK:scalarOK,"missing/invalid formula parameters or probability transition matrix");
 if(r&&r.formulaID==="EXPECTED_INPUT_SAVINGS")
   fail(params&&Number.isFinite(params.expectedSavedInputs)&&params.expectedSavedInputs>=0
     &&params.expectedSavedInputs<sc.nominalInputCount,"invalid expected saved reagents");
 if(r&&r.formulaID==="RATIO_ADJUSTMENT")
   fail(params&&Number.isFinite(params.referenceFactor)&&params.referenceFactor>0
     &&Number.isFinite(params.targetFactor)&&params.targetFactor>=0,"invalid ratio factors");
 fail(r&&r.parameterUnits&&typeof r.parameterUnits==="object"
      &&Object.keys(r.parameters||{}).every(k=>typeof r.parameterUnits[k]==="string"&&r.parameterUnits[k].length>0),
      "units missing for formula parameters");
 fail(r&&r.referenceContext&&typeof r.referenceContext==="object"&&Object.keys(r.referenceContext).length>0
      &&r.targetContext&&typeof r.targetContext==="object"&&Object.keys(r.targetContext).length>0,
      "unbounded source or target character context");
 fail(r&&Array.isArray(r.requiredLiveContext)&&r.requiredLiveContext.length>0,"missing runtime context requirements");
 fail(Array.isArray(src)&&src.length>=2&&new Set(src.map(s=>s.claimID)).size>=2
      &&src.every(s=>s.url&&s.claimID&&s.evidenceKind!=="MODEL_ESTIMATE"&&s.evidenceKind!=="QUALITATIVE"),
      "insufficient independent numeric source evidence");
 fail(typeof review.reviewer==="string"&&review.reviewer.length>0
      &&typeof review.reviewedAt==="string"&&review.reviewedAt.length>0
      &&Array.isArray(review.passedTestIDs)&&review.passedTestIDs.length>0,
      "master review or regression evidence missing");
 fail(r&&Array.isArray(r.blockers)&&r.blockers.length===0,"unresolved numeric blocker");
 return {eligible:errors.length===0,errors};
}


module.exports={canCompileNumericRule};
