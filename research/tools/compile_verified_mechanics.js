"use strict";
// Research-only staged compilation of independently QA-approved mechanic parameters.
// Example (still NOT a shipped Lua file):
// node research/tools/compile_verified_mechanics.js research/proposed/itemdb-midnight-milling-candidate.json research/proposed/itemdb-mechanics-staged.json
const fs=require("node:fs");
const path=require("node:path");
const crypto=require("node:crypto");
const {canCompileNumericRule}=require("../tests/test_numeric_rules.js");
const REGISTRY_PATH="research/mechanics/ProfessionMechanicsRegistry.json";

function compileVerifiedMechanics(itemdb,registry,registrySource){
 if(!itemdb||itemdb.artifactStatus!=="RESEARCH_ONLY_NOT_SHIPPED"||!Array.isArray(itemdb.processing))
   throw Error("Only a research/proposed itemdb candidate with processing records is supported");
 if(!registry||!Array.isArray(registry.numericRuleCandidates))
   throw Error("Missing master-reviewed numericRuleCandidates array: fail closed");
 if(registry.status!=="RESEARCH_ONLY_INCOMPLETE_NOT_A_NUMERIC_NORMALIZER")
   throw Error("Unexpected mechanics registry status; review compiler compatibility first");
 const accepted=[],ids=new Set();
 for(const r of registry.numericRuleCandidates){
   // Keep all preliminary/blocked hypotheses as research; never bundle them.
   if(r.applyPolicy!=="VERIFIED_FOR_COMPILE")continue;
   const gate=canCompileNumericRule(r);
   if(!gate.eligible)throw Error("Reject claimed approved mechanic "+r.hypothesisID+": "+gate.errors.join("; "));
   if(ids.has(r.hypothesisID))throw Error("Duplicate approved rule "+r.hypothesisID);
   ids.add(r.hypothesisID);
   const rule={
     ruleID:r.hypothesisID,profession:r.profession,expansionID:r.expansionID,
     method:r.method,effectTarget:r.effectTarget,formulaID:r.formulaID,
     parameters:r.parameters,parameterUnits:r.parameterUnits,scope:r.scope,
     referenceContext:r.referenceContext,targetContext:r.targetContext,
     requiredLiveContext:r.requiredLiveContext,sources:r.sources,
     independentReview:r.independentReview,confidence0to100:r.confidence0to100,
     evidenceStatus:r.evidenceStatus,applyPolicy:r.applyPolicy,
     numericTransformValidated:r.numericTransformValidated,blockers:[]
   };
   accepted.push(rule);
 }
 accepted.sort((a,b)=>a.ruleID.localeCompare(b.ruleID,"en"));
 const out=JSON.parse(JSON.stringify(itemdb));
 out.mechanicRules=accepted;
 out.sourceManifest=Object.assign({},itemdb.sourceManifest||{},{
   mechanicsRegistrySha256:crypto.createHash("sha256").update(registrySource,"utf8").digest("hex"),
   mechanicsRuleCount:accepted.length
 });
 // A proposed staged JSON cannot be mistaken for a production addon runtime file.
 out.artifactStatus="RESEARCH_ONLY_NOT_SHIPPED";
 return out;
}
function withinProposed(p){
 const base=path.resolve("research/proposed");
 const resolved=path.resolve(p);
 return resolved.startsWith(base+path.sep)&&!resolved.endsWith(".lua");
}
if(require.main===module){
 const [input,output]=process.argv.slice(2);
 if(!input||!output||!withinProposed(input)||!withinProposed(output)||!output.endsWith(".json"))
   throw Error("Both input/output must be JSON paths under research/proposed/, never production Lua");
 const registryText=fs.readFileSync(REGISTRY_PATH,"utf8");
 const registry=JSON.parse(registryText);
 const candidate=JSON.parse(fs.readFileSync(input,"utf8"));
 const result=compileVerifiedMechanics(candidate,registry,registryText);
 fs.writeFileSync(output,JSON.stringify(result,null,2)+"\n",{flag:"wx"});
 process.stdout.write(JSON.stringify({stagedOutput:output,compiledMechanics:result.mechanicRules.length,productionModified:false})+"\n");
}
module.exports={compileVerifiedMechanics};
