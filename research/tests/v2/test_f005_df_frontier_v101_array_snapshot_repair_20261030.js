"use strict";
/* F005 independent repair regression. Research-only; no live EV or release.
   Run: node research/tests/v2/test_f005_df_frontier_v101_array_snapshot_repair_20261030.js
   A failed negative case is an actionable F003 defect, not an accepted estimate. */
const fs=require("node:fs"),crypto=require("node:crypto"),path=require("node:path");
const frontier=require("../../tools/models_v2/df_prospect_decision_frontier_v1.js");
const stage=require("../../tools/models_v2/df_historical_diamond_denominator_stage_guard_v1.js");
const previousFrontier=require("./test_f005_df_prospect_frontier_v1_context_attestation_20261030.js");
const previousStage=require("./test_f005_df_prismatic_stage_identity_20261030.js");
const root=path.resolve(__dirname,"../../..");
const frontierPath=path.join(root,"research/tools/models_v2/df_prospect_decision_frontier_v1.js");
const stagePath=path.join(root,"research/tools/models_v2/df_historical_diamond_denominator_stage_guard_v1.js");
const sha=p=>{const b=fs.readFileSync(p);return crypto.createHash("sha1").update("blob "+b.length+"\0").update(b).digest("hex");};
const FRONTIER_BLOB="483842ab580808cbd9d9c130d26781b59d2e6ee4";
const STAGE_BLOB="2c9005e1d7be6df68d5631a418fbae95a144f6e7";
const key=frontier.TARGETS[0].stableKey,key2=frontier.TARGETS[1].stableKey;
const base=()=>({inputItemID:188658,snapshotDate:"2026-10-30",scenarioSourceID:"F005-synthetic-array-snapshot",policy:"SCENARIO_ONLY",nominalInputPerCast:5,costGoldPerCast:3,depositGoldPerCast:0,alternativeNetGoldPerCast:6,feeRate:0.05,otherRevenueGoldPerCast:0,otherRevenueBasis:"EXCLUDES_SELECTED_OUTPUTS",costBasis:"GROSS_NO_REFUNDS",outputs:[{stableKey:key,priceGold:10,eLower:0.5,eUpper:1}]});
const rejects=fn=>{try{fn();return false;}catch(_){return true;}};
function run(){
 const tests=[];const test=(name,fn)=>{try{const ok=fn();tests.push({name,status:ok?"PASS":"FAIL",reason:ok?undefined:"INVARIANT_NOT_MET"});}catch(e){tests.push({name,status:"FAIL",reason:"UNEXPECTED_THROW:"+String(e.message||e)});}};
 test("frontier exact Git blob",()=>sha(frontierPath)===FRONTIER_BLOB);
 test("stage exact Git blob",()=>sha(stagePath)===STAGE_BLOB);
 test("previous frontier 27-case repair",()=>{const r=previousFrontier.run();return r.total===27&&r.passed===27&&r.failed===0;});
 test("previous Prismatic identity 43-case repair",()=>{const r=previousStage.run();return r.total===43&&r.passed===43&&r.failed===0;});
 test("frontier self-test",()=>frontier.selfTest().passed===4039);
 test("stage self-test",()=>stage.selfTest().passed===28);
 test("stage corrected identity",()=>stage.SOURCE.secondStage.inputItemID===194545&&stage.analyze().secondStage.inputItemID===194545);
 test("stage cannot join first and second conversion",()=>!stage.preventFalseDirectJoin("Draconium Ore","Prismatic Ore").allowed);
 test("frontier unchanged arithmetic",()=>{const r=frontier.evaluateScenario(base());return r.lowerNetGoldPerCompletedCast===1.75&&r.upperNetGoldPerCompletedCast===6.5;});
 test("frontier no economic promotion",()=>{const p=frontier.evaluateScenario(base()).policy;return p.confidence===0&&p.economicUse==="PREVIEW_ONLY"&&p.normalizedVerified===false&&!p.liveEconomicEligible;});
 test("frontier five ore enforced",()=>rejects(()=>frontier.evaluateScenario({...base(),nominalInputPerCast:1}))&&rejects(()=>frontier.evaluateScenario({...base(),nominalInputPerCast:6})));
 test("stable dense single-output array accepted",()=>frontier.evaluateScenario(base()).selectedKeys.length===1);
 test("stable dense two-output array accepted",()=>frontier.evaluateScenario({...base(),outputs:[base().outputs[0],{stableKey:key2,priceGold:20,eLower:0.5,eUpper:1}]}).selectedKeys.length===2);
 test("reject output array length shrink 1 to 0 after dense validation",()=>{
  const b=base(),a=b.outputs;let reads=0;
  b.outputs=new Proxy(a,{get(t,k,r){if(k==="length")return ++reads<=3?1:0;return Reflect.get(t,k,r);}});
  return rejects(()=>frontier.evaluateScenario(b));
 });
 test("reject output array length shrink 2 to 1 after dense validation",()=>{
  const b=base(),a=[b.outputs[0],{stableKey:key2,priceGold:20,eLower:0.5,eUpper:1}];let reads=0;
  b.outputs=new Proxy(a,{get(t,k,r){if(k==="length")return ++reads<=4?2:1;return Reflect.get(t,k,r);}});
  return rejects(()=>frontier.evaluateScenario(b));
 });
 test("reject output element getter substitution",()=>{
  const b=base(),a=b.outputs;let reads=0;
  b.outputs=new Proxy(a,{get(t,k,r){if(k==="0"&&++reads>=2)return {stableKey:key2,priceGold:999,eLower:1,eUpper:2};return Reflect.get(t,k,r);}});
  return rejects(()=>frontier.evaluateScenario(b));
 });
 test("reject sparse outputs",()=>{const b=base();b.outputs=[b.outputs[0],,b.outputs[0]];return rejects(()=>frontier.evaluateScenario(b));});
 test("reject unexpected metadata",()=>{const b=base();b.outputs[0].verified=true;return rejects(()=>frontier.evaluateScenario(b));});
 test("reject output price Infinity",()=>{const b=base();b.outputs[0].priceGold=Infinity;return rejects(()=>frontier.evaluateScenario(b));});
 test("reject invalid date",()=>rejects(()=>frontier.evaluateScenario({...base(),snapshotDate:"2026-02-30"})));
 test("unknown upper remains indeterminate",()=>{const b=base();b.outputs[0].eUpper=null;const r=frontier.evaluateScenario(b);return r.upperNetGoldPerCompletedCast===null&&r.scenarioDecision==="INDETERMINATE";});
 const passed=tests.filter(t=>t.status==="PASS").length;
 return {suite:"F005_DF_FRONTIER_REPAIR_AND_ARRAY_SNAPSHOT",frontierGitBlob:FRONTIER_BLOB,stageGitBlob:STAGE_BLOB,assertions:tests.length,passed,failed:tests.length-passed,tests,expectedOutstanding:["reject output array length shrink 1 to 0 after dense validation","reject output array length shrink 2 to 1 after dense validation"],economicPromotions:0,independentRetailHoldouts:0,verdict:passed===tests.length?"CONDITIONAL_PASS_SYNTHETIC_ONLY":"FAIL_F003_ARRAY_SNAPSHOT_INTEGRITY"};
}
module.exports={run};
if(require.main===module){const r=run();console.log(JSON.stringify(r,null,2));if(r.failed)process.exitCode=1;}
