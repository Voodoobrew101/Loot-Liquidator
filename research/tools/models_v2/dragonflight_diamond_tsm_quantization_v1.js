"use strict";
/** Research-only Dragonflight diamond quantization diagnostic. Witnesses are NOT game observations. */
const MODEL_ID="dragonflight-diamond-tsm-quantization-v1.0.0";
const SOURCE_ROWS=[
  {
    "recordID": "tsm:prospect:188658:192869:L1204",
    "inputItemID": 188658,
    "outputItemID": 192869,
    "gameDataLine": 1204,
    "inputQualityRank": 2,
    "outputQualityRank": 1,
    "matRate": "0.0142",
    "amountOfMats": "0.0028",
    "nominalInputUnits": 5,
    "positiveYieldMin": 1,
    "positiveYieldMax": 2,
    "priority": 102,
    "priorityConflict": false
  },
  {
    "recordID": "tsm:prospect:188658:192870:L1205",
    "inputItemID": 188658,
    "outputItemID": 192870,
    "gameDataLine": 1205,
    "inputQualityRank": 2,
    "outputQualityRank": 2,
    "matRate": "0.0142",
    "amountOfMats": "0.0028",
    "nominalInputUnits": 5,
    "positiveYieldMin": 1,
    "positiveYieldMax": 2,
    "priority": 122,
    "priorityConflict": true
  },
  {
    "recordID": "tsm:prospect:188658:192871:L1206",
    "inputItemID": 188658,
    "outputItemID": 192871,
    "gameDataLine": 1206,
    "inputQualityRank": 2,
    "outputQualityRank": 3,
    "matRate": "0.0142",
    "amountOfMats": "0.0028",
    "nominalInputUnits": 5,
    "positiveYieldMin": 1,
    "positiveYieldMax": 2,
    "priority": 122,
    "priorityConflict": true
  },
  {
    "recordID": "tsm:prospect:189143:192869:L1242",
    "inputItemID": 189143,
    "outputItemID": 192869,
    "gameDataLine": 1242,
    "inputQualityRank": 1,
    "outputQualityRank": 1,
    "matRate": "0.0142",
    "amountOfMats": "0.0028",
    "nominalInputUnits": 5,
    "positiveYieldMin": 1,
    "positiveYieldMax": 2,
    "priority": 122,
    "priorityConflict": true
  },
  {
    "recordID": "tsm:prospect:189143:192870:L1243",
    "inputItemID": 189143,
    "outputItemID": 192870,
    "gameDataLine": 1243,
    "inputQualityRank": 1,
    "outputQualityRank": 2,
    "matRate": "0.0142",
    "amountOfMats": "0.0028",
    "nominalInputUnits": 5,
    "positiveYieldMin": 1,
    "positiveYieldMax": 2,
    "priority": 122,
    "priorityConflict": true
  },
  {
    "recordID": "tsm:prospect:189143:192871:L1244",
    "inputItemID": 189143,
    "outputItemID": 192871,
    "gameDataLine": 1244,
    "inputQualityRank": 1,
    "outputQualityRank": 3,
    "matRate": "0.0142",
    "amountOfMats": "0.0028",
    "nominalInputUnits": 5,
    "positiveYieldMin": 1,
    "positiveYieldMax": 2,
    "priority": 21,
    "priorityConflict": true
  },
  {
    "recordID": "tsm:prospect:190311:192869:L1280",
    "inputItemID": 190311,
    "outputItemID": 192869,
    "gameDataLine": 1280,
    "inputQualityRank": 3,
    "outputQualityRank": 1,
    "matRate": "0.0142",
    "amountOfMats": "0.0028",
    "nominalInputUnits": 5,
    "positiveYieldMin": 1,
    "positiveYieldMax": 2,
    "priority": 122,
    "priorityConflict": true
  },
  {
    "recordID": "tsm:prospect:190311:192870:L1281",
    "inputItemID": 190311,
    "outputItemID": 192870,
    "gameDataLine": 1281,
    "inputQualityRank": 3,
    "outputQualityRank": 2,
    "matRate": "0.0142",
    "amountOfMats": "0.0028",
    "nominalInputUnits": 5,
    "positiveYieldMin": 1,
    "positiveYieldMax": 2,
    "priority": 21,
    "priorityConflict": true
  },
  {
    "recordID": "tsm:prospect:190311:192871:L1282",
    "inputItemID": 190311,
    "outputItemID": 192871,
    "gameDataLine": 1282,
    "inputQualityRank": 3,
    "outputQualityRank": 3,
    "matRate": "0.0142",
    "amountOfMats": "0.0028",
    "nominalInputUnits": 5,
    "positiveYieldMin": 1,
    "positiveYieldMax": 2,
    "priority": 21,
    "priorityConflict": true
  }
];
function decimalInterval(s){if(typeof s!=="string"||!/^\d+(\.\d+)?$/.test(s))throw Error("DECIMAL");const n=Number(s),digits=(s.split(".")[1]||"").length,half=0.5*10**(-digits);return {low:Math.max(0,n-half),high:n+half,upperExclusive:true,decimals:digits};}
function solve(r){if(!Number.isInteger(r.nominalInputUnits)||r.nominalInputUnits<1||!Number.isInteger(r.positiveYieldMin)||r.positiveYieldMin<1||!Number.isInteger(r.positiveYieldMax)||r.positiveYieldMax<r.positiveYieldMin)throw Error("DOMAIN");const p=decimalInterval(r.matRate),q=decimalInterval(r.amountOfMats),e={low:q.low*r.nominalInputUnits,high:q.high*r.nominalInputUnits,upperExclusive:true};if(p.high>1)throw Error("P_DOMAIN");const lo=Math.max(p.low,e.low/r.positiveYieldMax),hi=Math.min(p.high,e.high/r.positiveYieldMin),nominalE=Number(r.amountOfMats)*r.nominalInputUnits,nominalP=Number(r.matRate),nominalInconsistent=nominalE<nominalP*r.positiveYieldMin-1e-12||nominalE>nominalP*r.positiveYieldMax+1e-12;if(hi<=lo+1e-14)return {status:"INCOMPATIBLE_UNDER_STATED_ROUNDING_AND_UNITS",nominalInconsistent,pInterval:p,eInterval:e,feasiblePInterval:null,witness:null};const wp=(lo+hi)/2,elow=Math.max(e.low,wp*r.positiveYieldMin),ehigh=Math.min(e.high,wp*r.positiveYieldMax),we=(elow+ehigh)/2;if(!(wp>=p.low&&wp<p.high&&we>=e.low&&we<e.high&&we>=wp*r.positiveYieldMin-1e-12&&we<=wp*r.positiveYieldMax+1e-12))throw Error("BAD_WITNESS");return {status:"ROUNDING_FEASIBLE_UNDER_UNVERIFIED_TSM_UNIT_SEMANTICS",nominalInconsistent,pInterval:p,eInterval:e,feasiblePInterval:{low:lo,high:hi,upperExclusive:true},witness:{dropChance:wp,expectedQuantity:we,amountOfMatsPerInput:we/r.nominalInputUnits,conditionalPositiveMean:we/wp}};}
function runTests(rs){let n=0;const ok=(v,s)=>{n++;if(!v)throw Error("TEST_"+s)};for(const r of rs){const x=solve(r);ok(x.status.startsWith("ROUNDING_FEASIBLE"),r.recordID+"-feasible");ok(x.nominalInconsistent,r.recordID+"-nominal");ok(x.witness.conditionalPositiveMean>=1&&x.witness.conditionalPositiveMean<=2,r.recordID+"-bounds");ok(x.witness.expectedQuantity>=x.witness.dropChance,r.recordID+"-zero-inclusive");}const r=rs[0];ok(solve({...r,amountOfMats:"0.0001"}).status.startsWith("INCOMPATIBLE"),"lowE");ok(solve({...r,amountOfMats:"0.1000"}).status.startsWith("INCOMPATIBLE"),"highE");ok(solve({...r,positiveYieldMin:2,positiveYieldMax:2}).status.startsWith("INCOMPATIBLE"),"positive_min_two");ok(solve({...r,nominalInputUnits:1}).status.startsWith("INCOMPATIBLE"),"one_input");ok(solve({...r,nominalInputUnits:10}).status.startsWith("ROUNDING_FEASIBLE"),"alternate_denominator_possible");ok(decimalInterval("0.0028").decimals===4,"precision");ok(rs.length===9&&rs.filter(x=>x.priority===122).length===5&&rs.filter(x=>x.priorityConflict).length===8,"source_and_priority_counts");return {passed:n,failed:0,sourceRows:rs.length,priority122:rs.filter(x=>x.priority===122).length,flaggedConflicts:rs.filter(x=>x.priorityConflict).length};}
function analyze(){return SOURCE_ROWS.map(r=>({...r,...solve(r),economicUse:"PREVIEW_ONLY",normalizedVerified:false,confidence:0,evidencePromotion:false}));}
module.exports={MODEL_ID,SOURCE_ROWS,decimalInterval,solve,runTests,analyze};
if(require.main===module){if(process.argv.includes("--self-test"))console.log(JSON.stringify(runTests(SOURCE_ROWS)));else if(process.argv.includes("--emit"))console.log(JSON.stringify(analyze(),null,2));else console.log("Use --self-test or --emit");}
