"use strict";
// Static research-only batch006 QA. Run from repo root: node research/tests/test_master_batch006.js
const fs=require("node:fs"),assert=require("node:assert/strict");
const q=JSON.parse(fs.readFileSync("research/coordination/assignments.json","utf8"));
const lines=fs.readFileSync("research/ledger/first-pass-coverage-2026-10-28.csv","utf8").split(/\r?\n/);
const status={};const map=new Map();for(const line of lines.slice(1)){if(!line)continue;const key=line.slice(0,line.indexOf(","));const s=line.match(/,(NEVER_EXAMINED|EXAMINED_INSUFFICIENT|BLOCKED|CORRECTED|SUBSTANTIATED_GE90),/);assert.ok(s,key);status[s[1]]=(status[s[1]]||0)+1;assert.ok(!map.has(key));map.set(key,s[1]);}
assert.equal(map.size,1737);assert.equal(status.NEVER_EXAMINED,809);assert.equal(status.EXAMINED_INSUFFICIENT,915);assert.equal(status.BLOCKED,13);
assert.equal(q.queueRevision,9);assert.equal(q.baseline.cumulativeFirstPass,928);
const all=Object.values(q.workers).flatMap(w=>w.recordKeys);assert.equal(all.length,150);assert.equal(new Set(all).size,150);for(const k of all)assert.equal(map.get(k),"NEVER_EXAMINED",k);
assert.equal(q.mechanicsTrack.reviewCounters.verifiedNumeric,0);assert.equal(q.mechanicsTrack.reviewCounters.blockedForCompile,4);
const scored=fs.readFileSync("research/ledger/master-worker-batch006-four-field-scores-2026-10-28.csv","utf8").trim().split(/\r?\n/);assert.equal(scored.length,151);
for(const l of scored.slice(1)){const cols=l.split(",");assert.equal(map.get(cols[0]),"EXAMINED_INSUFFICIENT");for(const i of [2,3,4,5])assert.ok(+cols[i]>=0&&+cols[i]<90);}
console.log("batch006 static QA passed: 150 accepted, 150 disjoint next targets, numeric fail-closed");
