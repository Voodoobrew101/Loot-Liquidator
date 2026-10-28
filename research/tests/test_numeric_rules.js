"use strict";
// Research-only, dependency-free guard for future itemdb.lua mechanic compilation.
// Run: node research/tests/test_numeric_rules.js
// Tests are synthetic/structural; NO live WoW client tested.
const fs=require("node:fs");
const assert=require("node:assert/strict");

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
 fail(r&&r.parameters&&typeof r.parameters==="object"&&Object.keys(r.parameters).length>0
      &&Object.values(r.parameters).every(v=>typeof v==="number"&&Number.isFinite(v)),
      "missing/nonfinite formula parameters");
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

const fixture={
 hypothesisID:"SYNTHETIC_ONLY_NOT_REAL_GAME_EVIDENCE",evidenceStatus:"VERIFIED_NUMERIC",
 applyPolicy:"VERIFIED_FOR_COMPILE",numericTransformValidated:true,confidence0to100:94,
 profession:"Jewelcrafting",expansionID:11,method:"Prospect",
 effectTarget:"OUTPUT_UNCONDITIONAL_EXPECTATION",effectKind:"MULTIPLY",
 formulaID:"RATIO_ADJUSTMENT",parameters:{referenceFactor:1,targetFactor:1.2},
 parameterUnits:{referenceFactor:"dimensionless",targetFactor:"dimensionless"},
 scope:{gameMode:"RETAIL",recipeSpellIDs:[123456],inputItemIDs:[234567],outputItemIDs:[345678],
 nominalInputCount:5,inputQualityRanks:[1],outputQualityRanks:[1],patchStartBuild:"synthetic-a",patchEndBuild:"synthetic-b"},
 referenceContext:{skill:50},targetContext:{skill:100},requiredLiveContext:["skill"],
 sources:[{claimID:"synthetic-cohort-a",url:"synthetic://not-real-a",evidenceKind:"RAW_CAST_LOG",sampleOperations:100},
          {claimID:"synthetic-cohort-b",url:"synthetic://not-real-b",evidenceKind:"INDEPENDENT_REPLICATION",sampleOperations:100}],
 independentReview:{reviewer:"synthetic-master",reviewedAt:"synthetic",passedTestIDs:["synthetic-equality"]},
 blockers:[]
};
function test(){
 let pass=0;
 function check(name,p){assert.ok(p,name);pass++;}
 check("known-positive synthetic structurally eligible",canCompileNumericRule(fixture).eligible);
 for(const [name,mutation] of [
  ["qualitative status",o=>o.evidenceStatus="VERIFIED_QUALITATIVE"],
  ["unreviewed",o=>o.independentReview.reviewer=null],
  ["unverified coefficient",o=>o.numericTransformValidated=false],
  ["low confidence",o=>o.confidence0to100=89],
  ["unapproved",o=>o.applyPolicy="NO_NUMERIC_TRANSFORM"],
  ["unknown formula",o=>o.formulaID="GLOBAL_SKILL_LINEAR"],
  ["effect mismatch",o=>o.effectTarget="EXPECTED_INPUT_CONSUMPTION"],
  ["no recipe",o=>o.scope.recipeSpellIDs=[]],
  ["no outputs",o=>o.scope.outputItemIDs=[]],
  ["no input",o=>o.scope.inputItemIDs=[]],
  ["no batch",o=>o.scope.nominalInputCount=null],
  ["no patch",o=>o.scope.patchStartBuild=null],
  ["no stat context",o=>o.requiredLiveContext=[]],
  ["no independent source",o=>o.sources=[o.sources[0]]],
  ["infinite coefficient",o=>o.parameters.targetFactor=Infinity],
  ["missing units",o=>o.parameterUnits.targetFactor=""],
  ["unresolved blocker",o=>o.blockers=["hotfix magnitude unknown"]],
  ["wrong game mode",o=>o.scope.gameMode="PTR"]
 ]){
   const copy=JSON.parse(JSON.stringify(fixture));
   mutation(copy);
   check("reject "+name,!canCompileNumericRule(copy).eligible);
 }
 const reg=JSON.parse(fs.readFileSync("research/mechanics/ProfessionMechanicsRegistry.json","utf8"));
 const itemdb=JSON.parse(fs.readFileSync("research/proposed/itemdb.schema.json","utf8"));
 const candidateSchema=JSON.parse(fs.readFileSync("research/mechanics/numeric-rule-candidate.schema.json","utf8"));
 check("registry explicitly flags itself as research-only",reg.status==="RESEARCH_ONLY_INCOMPLETE_NOT_A_NUMERIC_NORMALIZER");
 check("all current registry rules are blocked from compilation",(reg.quantifiedMechanicRules||[]).every(r=>!canCompileNumericRule(r).eligible));
 check("itemdb proposed schema permits reviewed rules",!!itemdb.properties.mechanicRules && !!itemdb.$defs.compiledMechanicRule);
 check("mechanic research schema is research-only",candidateSchema.title.includes("research-only"));
 check("itemdb staging remains not shipped",itemdb.properties.artifactStatus.const==="RESEARCH_ONLY_NOT_SHIPPED");
 console.log(JSON.stringify({passed:pass,failed:0,actualRulesCompileEligible:reg.quantifiedMechanicRules.filter(r=>canCompileNumericRule(r).eligible).length,gameClientTested:false},null,2));
}
if(typeof module!=="undefined") module.exports={canCompileNumericRule,syntheticFixtureForTests:fixture};
if(typeof require==="function" && require.main===module) test();
