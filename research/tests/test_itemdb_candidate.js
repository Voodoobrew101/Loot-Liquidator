"use strict";
// Research contract fixture tests. Run: node research/tests/test_itemdb_candidate.js
// No in-client WoW execution. Source checks describe known v0.9.70 architectural debt.
function runItemdbResearchQA(candidate, gameDataSource, statYieldSource) {
 const failures=[], passed=[];
 const check=(name, condition)=>{if(condition){passed.push(name)}else{failures.push(name)}};
 const records=candidate.processing||[];
 check("exactly eight Midnight herb/item relations",records.length===8);
 const expected={236761:245807,236767:245807,236776:245804,236777:245804,236778:245866,236779:245866,236770:245864,236771:245864};
 check("every input has corroborated output identity",records.every(r=>expected[r.inputItemID]===r.outputItemID));
 check("no duplicate condition records",new Set(records.map(r=>r.recordID)).size===8);
 check("all recipes consume ten herbs",records.every(r=>r.method==="Mill" && r.expansionID===11 && r.recipeSpellID===1269575 && r.inputCountPerOperation===10));
 check("all three tooltip fields distinct from gold expectation",records.every(r=>r.dropChance!==r.expectedQuantity && r.yieldMin!==r.yieldMax && typeof r.expectedQuantity.value==="number"));
 check("individual status and confidence attached to all four fields",records.every(r=>["dropChance","yieldMin","yieldMax","expectedQuantity"].every(k=>r[k] && typeof r[k].confidence==="number" && typeof r[k].status==="string" && r[k].sourceClaimIDs.length>0)));
 const invariant=r=>{const p=r.dropChance.value,E=r.expectedQuantity.value,mi=r.yieldMin.value,ma=r.yieldMax.value;return p>=0 && p<=1 && Number.isInteger(mi) && Number.isInteger(ma) && mi>=1 && ma>=mi && Number.isFinite(E) && E>=0 && p*mi<=E+1e-9 && E<=p*ma+1e-9};
 check("condition-matched p/min/max/mean invariants",records.every(invariant));
 check("contradictory old Cobalt-style tuple rejected",!invariant({dropChance:{value:.235},yieldMin:{value:1},yieldMax:{value:2},expectedQuantity:{value:2.5}}));
 check("historical 4.5 expectation is provisional not measured",records.every(r=>r.expectedQuantity.status==="modeled" && r.dropChance.status==="proxy" && r.expectedQuantity.confidence<90));
 check("weakest-field conservative score",records.every(r=>r.recordConfidence===Math.min(r.mappingConfidence,r.conditionsConfidence,...["dropChance","yieldMin","yieldMax","expectedQuantity"].map(k=>r[k].confidence))));
 check("10-herb pricing denominator once",Math.abs((records[0].expectedQuantity.value*100)/records[0].inputCountPerOperation-45)<1e-9);
 check("unknown skill/output ranks stay unknown, not zero",records.every(r=>r.conditions.effectiveSkill===null && r.outputQualityRank===null && r.inputQualityRank===null));
 check("main source contains all eight input IDs",records.every(r=>gameDataSource.includes("gd.mill["+r.inputItemID+"]")));
 const groups=[[236761,236767,245807],[236776,236777,245804],[236778,236779,245866],[236770,236771,245864]];
 check("each mapping copied without changing ids from original overlay",groups.every(g=>statYieldSource.includes("millGroup({"+g[0]+","+g[1]+"},{"+g[2]+"}")));
 const debt=statYieldSource.includes("gd.statYieldProfiles={Prospect={},Mill={}}") && statYieldSource.includes("gd.mill[id]=nil");
 check("known legacy second-database runtime debt detected (NOT resolved)",debt);
 // Explicit policy-only reference selection; no stat-yield transformation inferred.
 const selectContext=(real,sim)=>real && real.skillLineID!=null?"REAL":sim && sim.skillLineID!=null?"SIMULATED":"REFERENCE_UNKNOWN";
 check("context precedence REAL > SIMULATED > REFERENCE",selectContext({skillLineID:1},{skillLineID:2})==="REAL" && selectContext(null,{skillLineID:2})==="SIMULATED" && selectContext(null,null)==="REFERENCE_UNKNOWN");
 return {passed,failures,passedCount:passed.length,failedCount:failures.length,architectureDebtDetected:debt,gameClientTested:false};
}
if(typeof module!=="undefined" && module.exports) module.exports={runItemdbResearchQA};
if(typeof require==="function" && typeof module!=="undefined" && require.main===module){
 const fs=require("node:fs");
 const candidate=JSON.parse(fs.readFileSync("research/proposed/itemdb-midnight-milling-candidate.json","utf8"));
 const gd=fs.readFileSync("GameData.lua","utf8");
 const overlay=fs.readFileSync("StatYieldProfiles.lua","utf8");
 const result=runItemdbResearchQA(candidate,gd,overlay);
 process.stdout.write(JSON.stringify(result,null,2)+"\n");
 if(result.failedCount) process.exitCode=1;
}
