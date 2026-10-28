"use strict";
// Staged build test: node research/tests/test_mechanics_compiler.js
// Synthetic positive is NOT a claim about real game mechanics.
const fs=require("node:fs");
const assert=require("node:assert/strict");
const {compileVerifiedMechanics}=require("../tools/compile_verified_mechanics.js");
const {syntheticFixtureForTests,canCompileNumericRule}=require("./test_numeric_rules.js");
function run(){
 const candidate=JSON.parse(fs.readFileSync("research/proposed/itemdb-midnight-milling-candidate.json","utf8"));
 const registryText=fs.readFileSync("research/mechanics/ProfessionMechanicsRegistry.json","utf8");
 const registry=JSON.parse(registryText);
 let checks=0;
 const check=(name,condition)=>{assert.ok(condition,name);checks++};
 const base=compileVerifiedMechanics(candidate,registry,registryText);
 check("no real verified numeric rules currently",base.mechanicRules.length===0);
 check("source baselines untouched",JSON.stringify(base.processing)===JSON.stringify(candidate.processing));
 check("no loss of research artifact safety",base.artifactStatus==="RESEARCH_ONLY_NOT_SHIPPED");
 check("registry revision sealed by sha256",typeof base.sourceManifest.mechanicsRegistrySha256==="string"&&base.sourceManifest.mechanicsRegistrySha256.length===64);
 const clone=o=>JSON.parse(JSON.stringify(o));
 const testRegistry=clone(registry);
 testRegistry.numericRuleCandidates=[clone(syntheticFixtureForTests)];
 check("synthetic compiler input passes numerical gate",canCompileNumericRule(testRegistry.numericRuleCandidates[0]).eligible);
 const built=compileVerifiedMechanics(candidate,testRegistry,JSON.stringify(testRegistry));
 check("one synthetic numerical rule staged",built.mechanicRules.length===1);
 check("synthetic scoped ID and units retained",built.mechanicRules[0].ruleID==="SYNTHETIC_ONLY_NOT_REAL_GAME_EVIDENCE"&&built.mechanicRules[0].parameterUnits.targetFactor==="dimensionless");
 check("no synthetic baseline replacement",JSON.stringify(built.processing)===JSON.stringify(candidate.processing));
 check("input research fixture not mutated",!("mechanicRules" in candidate));
 const blocked=clone(syntheticFixtureForTests);blocked.applyPolicy="NO_NUMERIC_TRANSFORM";blocked.evidenceStatus="VERIFIED_QUALITATIVE";
 testRegistry.numericRuleCandidates=[blocked];
 check("unverified/blocked rule excluded",compileVerifiedMechanics(candidate,testRegistry,"blocked").mechanicRules.length===0);
 const bad=clone(syntheticFixtureForTests);bad.confidence0to100=45;
 testRegistry.numericRuleCandidates=[bad];
 assert.throws(()=>compileVerifiedMechanics(candidate,testRegistry,"invalid"),/Reject claimed approved/);checks++;
 testRegistry.numericRuleCandidates=[clone(syntheticFixtureForTests),clone(syntheticFixtureForTests)];
 assert.throws(()=>compileVerifiedMechanics(candidate,testRegistry,"dupe"),/Duplicate approved rule/);checks++;
 const noArray=clone(registry);delete noArray.numericRuleCandidates;
 assert.throws(()=>compileVerifiedMechanics(candidate,noArray,"missing"),/Missing master-reviewed/);checks++;
 console.log(JSON.stringify({passed:checks,failed:0,compiledRealMechanicRules:base.mechanicRules.length,liveWoWTested:false},null,2));
}
if(require.main===module)run();
module.exports={run};
