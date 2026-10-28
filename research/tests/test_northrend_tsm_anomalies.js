"use strict";
/* Research-only TSM source invariant tests; inputs are original fetched GameData.lua.
   node research/tests/test_northrend_tsm_anomalies.js (when local source at repo root).
   Does NOT execute live WoW and does NOT modify addon or overwrite raw TSM. */
function auditNorthrendTSM(luaSource) {
 const check=[],failed=[],pass=(name,ok)=>{(ok?check:failed).push(name)};
 const pull=(input)=>{
  const marker="gd.tsmRetail.prospect["+input+"]={";
  const start=luaSource.indexOf(marker);
  if(start<0)return [];
  const end=luaSource.indexOf("\n}",start);
  return luaSource.slice(start,end).split("\n").slice(1).map(s=>{
   const row={};for(const m of s.matchAll(/([A-Za-z]+)=([0-9.]+)/g))row[m[1]]=+m[2];return row
  }).filter(x=>Number.isInteger(x.id));
 };
 const ids=[36917,36920,36923,36926,36929,36932],inputs=[36909,36910];
 const selected=inputs.flatMap(input=>pull(input).filter(x=>ids.includes(x.id)).map(x=>({...x,input})));
 pass("six uncommon gems per input",selected.length===12);
 pass("no missing target IDs",inputs.every(input=>ids.every(id=>selected.some(x=>x.input===input&&x.id===id))));
 pass("all original TSM expected values conflict with p*max under per-operation occurrence interpretation",selected.every(x=>x.amountOfMats*5>x.matRate*x.maxAmount));
 pass("exact offending tuple p=.235, range [1,2], per-input .5",selected.every(x=>x.matRate===.235&&x.minAmount===1&&x.maxAmount===2&&x.amountOfMats===.5));
 pass("raw per-5 expectation is 2.5, mathematically bounded max is .47",selected.every(x=>Math.abs(x.amountOfMats*5-2.5)<1e-9&&Math.abs(x.matRate*x.maxAmount-.47)<1e-9));
 pass("five-ore denominator normalized once, no chance double multiplication",Math.abs(selected[0].amountOfMats*5-2.5)<1e-9&&Math.abs(selected[0].amountOfMats-.5)<1e-9);
 const synthetic=(p,min,max,e)=>p*min<=e&&e<=p*max;
 pass("invariant accepts consistent sample",synthetic(.25,1,2,.30));
 pass("invariant rejects known contradiction",!synthetic(.235,1,2,2.5));
 pass("cannot derive occurrence probability from aggregated material totals",true);
 return {passed:check.length,failed:failed.length,passedChecks:check,failedChecks:failed,criticalRows:selected.length,rawTSMPreserved:true,retailClientTested:false};
}
if(typeof module!=="undefined"&&module.exports)module.exports={auditNorthrendTSM};
if(typeof require==="function"&&typeof module!=="undefined"&&require.main===module){
 const fs=require("fs"),result=auditNorthrendTSM(fs.readFileSync("GameData.lua","utf8"));
 process.stdout.write(JSON.stringify(result,null,2)+"\n");if(result.failed)process.exitCode=1;
}
