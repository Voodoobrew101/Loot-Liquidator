"use strict";
/* F005 independent negative QA: F003 Dragonflight prospect decision frontier.
   Research-only. Failing tests document model defects; never economic acceptance. */
const model=require("../../tools/models_v2/df_prospect_decision_frontier_v1.js");
function run(){
 const tests=[];
 const key=model.TARGETS[0].stableKey,key2=model.TARGETS[1].stableKey;
 const base=()=>({inputItemID:188658,snapshotDate:"2026-10-30",scenarioSourceID:"F005-independent-synthetic",policy:"SCENARIO_ONLY",nominalInputPerCast:5,costGoldPerCast:3,depositGoldPerCast:0,alternativeNetGoldPerCast:6,feeRate:0.05,otherRevenueGoldPerCast:0,otherRevenueBasis:"EXCLUDES_SELECTED_OUTPUTS",costBasis:"GROSS_NO_REFUNDS",outputs:[{stableKey:key,priceGold:10,eLower:0.5,eUpper:1}]});
 function check(name,fn){try{const ok=fn();tests.push({name,status:ok?"PASS":"FAIL",reason:ok?undefined:"INVARIANT_NOT_MET"});}catch(e){tests.push({name,status:"FAIL",reason:"UNEXPECTED_THROW:"+e.message});}}
 function rejects(name,make){check(name,()=>{try{model.evaluateScenario(make());return false;}catch(_){return true;}});}
 check("source model version and 38 unique keys",()=>model.MODEL_ID==="df-prospect-decision-frontier-v1.0.0"&&model.TARGETS.length===38&&new Set(model.TARGETS.map(x=>x.stableKey)).size===38);
 check("original model self-tests 4039",()=>model.selfTest().passed===4039);
 check("baseline scenario lower and upper",()=>{const r=model.evaluateScenario(base());return r.lowerNetGoldPerCompletedCast===1.75&&r.upperNetGoldPerCompletedCast===6.5;});
 check("zero-confidence preview-only policy",()=>{const p=model.evaluateScenario(base()).policy;return p.confidence===0&&p.economicUse==="PREVIEW_ONLY"&&p.normalizedVerified===false&&p.liveEconomicEligible===false&&p.tooltipOnlyEligible===false;});
 check("unconditional co-output E not normalized",()=>{const r=model.evaluateScenario({...base(),outputs:[{stableKey:key,priceGold:10,eLower:1,eUpper:2},{stableKey:key2,priceGold:20,eLower:1,eUpper:2}]});return r.lowerNetGoldPerCompletedCast===25.5;});
 check("unknown upper remains unknown",()=>{const r=model.evaluateScenario({...base(),outputs:[{stableKey:key,priceGold:10,eLower:0,eUpper:null}]});return r.upperNetGoldPerCompletedCast===null&&r.scenarioDecision==="INDETERMINATE"&&r.sensitivity[0].uncertaintyGold===null;});
 check("known scenario lower dominates alternative",()=>model.evaluateScenario({...base(),alternativeNetGoldPerCast:1}).scenarioDecision==="PROSPECT_WINS_IN_SCENARIO");
 check("known scenario upper below alternative",()=>model.evaluateScenario({...base(),alternativeNetGoldPerCast:7}).scenarioDecision==="ALTERNATIVE_WINS_IN_SCENARIO");
 check("gross cost forbids refund provenance",()=>{try{model.evaluateScenario({...base(),refundSourceID:"unsupported"});return false;}catch(_){return true;}});
 check("net cost requires refund provenance",()=>{try{model.evaluateScenario({...base(),costBasis:"NET_WITH_ATTESTED_REFUNDS"});return false;}catch(_){return true;}});
 check("attested net cost context accepted as scenario",()=>model.evaluateScenario({...base(),costBasis:"NET_WITH_ATTESTED_REFUNDS",refundSourceID:"hypothetical-source"}).policy.economicUse==="PREVIEW_ONLY");
 rejects("reject cross-input stable key",()=>({...base(),inputItemID:189143}));
 rejects("reject impossible date",()=>({...base(),snapshotDate:"2026-02-30"}));
 rejects("reject NaN fee",()=>({...base(),feeRate:NaN}));
 rejects("reject infinite output price",()=>({...base(),outputs:[{...base().outputs[0],priceGold:Infinity}]}));
 rejects("reject duplicate output keys",()=>({...base(),outputs:[base().outputs[0],base().outputs[0]]}));
 rejects("reject hidden output metadata",()=>{const o={...base().outputs[0]};Object.defineProperty(o,"secret",{value:1});return {...base(),outputs:[o]};});
 rejects("reject sparse output array",()=>{const a=[base().outputs[0],,base().outputs[0]];return {...base(),outputs:a};});
 // Regression expectations: a valid DF prospect is five ore per completed cast.
 rejects("reject nominal batch size 1 for DF prospect",()=>({...base(),nominalInputPerCast:1}));
 rejects("reject nominal batch size 6 for DF prospect",()=>({...base(),nominalInputPerCast:6}));
 // Proxy traps expose validation/use TOCTOU. The source checks descriptors but
 // does not copy their values to an immutable canonical snapshot.
 rejects("reject changing output eLower proxy",()=>{let n=0;const o=new Proxy({...base().outputs[0]},{get(t,k,r){if(k==="eLower"){n++;return n<=2?0.5:n===3?100:1;}return Reflect.get(t,k,r);}});return {...base(),outputs:[o]};});
 rejects("reject changing feeRate proxy",()=>{let n=0;return new Proxy(base(),{get(t,k,r){if(k==="feeRate"){n++;return n<=2?0.05:0.9;}return Reflect.get(t,k,r);}});});
 rejects("reject changing costGoldPerCast proxy",()=>{let n=0;return new Proxy(base(),{get(t,k,r){if(k==="costGoldPerCast"){n++;return n===1?3:300;}return Reflect.get(t,k,r);}});});
 rejects("reject changing snapshotDate proxy",()=>{let n=0;return new Proxy(base(),{get(t,k,r){if(k==="snapshotDate"){n++;return n===1?"2026-10-30":"2022-01-01";}return Reflect.get(t,k,r);}});});
 rejects("reject changing scenarioSourceID proxy",()=>{let n=0;return new Proxy(base(),{get(t,k,r){if(k==="scenarioSourceID"){n++;return n===1?"original-source":"replaced-source";}return Reflect.get(t,k,r);}});});
 rejects("reject outputs array substitution after validation",()=>{let n=0;const b=base(),first=b.outputs,second=[{stableKey:key2,priceGold:999,eLower:1,eUpper:2}];return new Proxy(b,{get(t,k,r){if(k==="outputs"){n++;return n===1?first:second;}return Reflect.get(t,k,r);}});});
 // Valid static records should remain stable under repeated execution.
 check("deterministic static source replay",()=>{const b=base();return JSON.stringify(model.evaluateScenario(b))===JSON.stringify(model.evaluateScenario(b));});
 const passed=tests.filter(x=>x.status==="PASS").length,failed=tests.length-passed;
 return {suite:"F005_DF_PROSPECT_FRONTIER_V1_CONTEXT",modelCodeExpectedGitBlob:"7fb36b9d6c25f6a0bff02dfe5ab1b6855e6a4f42",total:tests.length,passed,failed,tests,verdict:failed?"FAIL_MODEL_CONTEXT_INTEGRITY":"CONDITIONAL_PASS_NO_RETAIL_HOLDOUT",economicPromotions:0,independentRetailHoldouts:0};
}
module.exports={run};
if(require.main===module){const r=run();console.log(JSON.stringify(r));if(r.failed)process.exitCode=1;}
