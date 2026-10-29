"use strict";
// Research-only, dependency-free guard for future itemdb.lua mechanic compilation.
// Run: node research/tests/test_numeric_rules.js
// Tests are synthetic/structural; NO live WoW client tested.
const fs=require("node:fs");
const assert=require("node:assert/strict");

const {canCompileNumericRule}=require("../tools/numeric_rule_gate.js");

const fixture={
 hypothesisID:"SYNTHETIC_ONLY_NOT_REAL_GAME_EVIDENCE",evidenceStatus:"VERIFIED_NUMERIC",
 applyPolicy:"VERIFIED_FOR_COMPILE",numericTransformValidated:true,confidence0to100:94,
 profession:"Jewelcrafting",expansionID:11,method:"Prospect",
 effectTarget:"OUTPUT_UNCONDITIONAL_EXPECTATION",effectKind:"MULTIPLY",
 formulaID:"RATIO_ADJUSTMENT",parameters:{referenceFactor:1,targetFactor:1.2},
 parameterUnits:{referenceFactor:"dimensionless",targetFactor:"dimensionless"},
 scope:{gameMode:"RETAIL",recipeSpellIDs:[123456],inputItemIDs:[234567],outputItemIDs:[345678],
 nominalInputCount:5,inputQualityRanks:[1],outputQualityRanks:[1],patchStartBuild:"synthetic-a",patchEndBuild:"synthetic-b"},
 referenceContext:{skill:50,build:"synthetic-a"},targetContext:{skill:100,build:"synthetic-b"},requiredLiveContext:["skill"],
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
 const matrixFixture=JSON.parse(JSON.stringify(fixture));
 matrixFixture.effectTarget="OUTPUT_QUALITY";
 matrixFixture.formulaID="QUALITY_TRANSITION_MATRIX";
 matrixFixture.scope.outputQualityRanks=[1,2];
 matrixFixture.scope.outputItemIDs=[345678,345679];
 matrixFixture.parameters={transitionMatrix:[[0.8,0.2],[0.1,0.9]]};
 matrixFixture.parameterUnits={transitionMatrix:"probability_fraction"};
 check("valid synthetic two-rank transition matrix",canCompileNumericRule(matrixFixture).eligible);
 matrixFixture.parameters.transitionMatrix[0][1]=0.3;
 check("reject transition matrix with nonconserving row",!canCompileNumericRule(matrixFixture).eligible);
 const inputFixture=JSON.parse(JSON.stringify(fixture));
 inputFixture.effectTarget="EXPECTED_INPUT_CONSUMPTION";
 inputFixture.formulaID="EXPECTED_INPUT_SAVINGS";
 inputFixture.scope.outputItemIDs=[];
 inputFixture.parameters={expectedSavedInputs:0.75};
 inputFixture.parameterUnits={expectedSavedInputs:"reagent_units_per_operation"};
 check("valid synthetic reagent savings independent of output",canCompileNumericRule(inputFixture).eligible);
 inputFixture.parameters.expectedSavedInputs=6;
 check("reject reagent savings greater than batch",!canCompileNumericRule(inputFixture).eligible);
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
