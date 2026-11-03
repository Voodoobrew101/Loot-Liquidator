"use strict"; // Run: node research/tests/test_master_batch005.js
const fs=require("node:fs"),assert=require("node:assert/strict");
const q=JSON.parse(fs.readFileSync("research/coordination/assignments.json","utf8"));
const obs=fs.readFileSync("research/evidence/observations/2026-10-28-master-legacy-thorium-felslate-source-audit.jsonl","utf8").trim().split(/\r?\n/).map(JSON.parse);
const scores=fs.readFileSync("research/ledger/master-worker-batch005-four-field-scores-2026-10-28.csv","utf8").trim().split(/\r?\n/);
const keys=Object.values(q.workers).flatMap(w=>w.recordKeys);
assert.equal(q.queueRevision>=8,true);assert.equal(q.current.cumulativeFirstPass,778);
assert.equal(q.current.coverageStatuses.NEVER_EXAMINED,959);
assert.equal(scores.length,151);assert.equal(keys.length,150);assert.equal(new Set(keys).size,150);
assert.equal(obs.length,3);assert.equal(obs[1].reportedBatchTotals.reduce((a,b)=>a+b,0),560);
assert.equal(obs[2].reportedBatchTotals.reduce((a,b)=>a+b,0),97);
assert.equal(obs[2].arithmeticOnlyFiveOreEquivalentMean,0.0485);
assert.equal(q.mechanicsTrack.reviewCounters.verifiedNumeric,0);
assert.equal(q.mechanicsTrack.reviewCounters.blockedForCompile,4);
assert.equal(q.current.allFields90GateMet,false);
console.log("batch005 static regression: 12 assertions passed (not WoW client)");
