"use strict";
// Run from repo root: node research/tests/test_master_batch003.js
const fs=require("node:fs"),assert=require("node:assert/strict");
function csv(s){let a=[],r=[],v="",q=false;for(let i=0;i<s.length;i++){let c=s[i];if(q){if(c==='"'&&s[i+1]==='"'){v+='"';i++}else if(c==='"')q=false;else v+=c;}else if(c===','){r.push(v);v=""}else if(c==="\n"){r.push(v);if(r.some(Boolean))a.push(r);r=[];v=""}else if(c!=="\r")v+=c;}if(r.length||v){r.push(v);a.push(r)}let [h,...d]=a;return d.map(r=>Object.fromEntries(h.map((v,i)=>[v,r[i]??""])));}
const read=p=>fs.readFileSync(p,"utf8");
const q=JSON.parse(read("research/coordination/assignments.json")),c=csv(read("research/ledger/first-pass-coverage-2026-10-28.csv"));
assert.equal(q.queueRevision,6);assert.equal(c.length,1737);
let counts={};for(let r of c)counts[r.coverage_status]=(counts[r.coverage_status]||0)+1;
assert.equal(counts.NEVER_EXAMINED,1259);assert.equal(counts.EXAMINED_INSUFFICIENT,465);assert.equal(counts.BLOCKED,13);
let by=new Map(c.map(r=>[r.stable_key,r])),old=new Set(),next=new Set();
const names={midnight:"loot-liquidator-midnight/2026-10-28-batch003-35key-audit.csv",war_within:"loot-liquidator-war-within/2026-10-28-tww-batch003-35key-audit.csv",dragonflight:"loot-liquidator-dragonflight/2026-10-28-assignment003-0330-audit.csv",legacy:"loot-liquidator-legacy/2026-10-28-legacy-batch003-40key-audit.csv"};
for(let [w,p] of Object.entries(names)){for(let r of csv(read("research/coordination/submissions/"+p))){let k=r.stable_key||r.stableKey;assert.ok(!old.has(k));old.add(k);assert.equal(by.get(k).first_pass_run,"MASTER_ACCEPTED_BATCH003_"+w.toUpperCase());}for(let k of q.workers[w].recordKeys){assert.ok(!next.has(k));next.add(k);assert.equal(by.get(k).coverage_status,"NEVER_EXAMINED");}}
assert.equal(old.size,150);assert.equal(next.size,150);assert.equal(q.mechanicsTrack.reviewCounters.verifiedNumeric,0);assert.equal(q.mechanicsTrack.reviewCounters.blockedForCompile,4);
console.log("Master batch003 coverage/assignment gate PASS");
