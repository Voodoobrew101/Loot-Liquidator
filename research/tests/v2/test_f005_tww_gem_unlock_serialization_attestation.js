'use strict';
// F005 independent exact-source regression: TWW Gem Finding nonexclusive model.
// Research-only. Fail closed on non-JSON-safe context/event inputs.
// Run: node research/tests/v2/test_f005_tww_gem_unlock_serialization_attestation.js
const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const MODEL=path.resolve(__dirname,'../../tools/models_v2/tww_gem_finding_partial_unlock_identification_v1.js');
const PIN='908a447dfeac840aa0d8e2ea63efd2c3323a99e4';
function gitBlob(bytes){return crypto.createHash('sha1').update(Buffer.from('blob '+bytes.length+'\0')).update(bytes).digest('hex');}
function checkPin(){const actual=gitBlob(fs.readFileSync(MODEL));if(actual!==PIN)throw Error('MODEL_SOURCE_CHANGED_REVIEW_REQUIRED:'+actual);}
function run(model){
 const m=model||require(MODEL),cases=[],copy=x=>JSON.parse(JSON.stringify(x));
 const test=(name,expectedReject,mutate,inspect)=>{
  const s=m.synthetic();mutate(s);
  let rejected=false,result=null,error=null;
  try{result=m.analyze(s);if(inspect&&!inspect(result,s))throw Error('ASSERTION_FAILED');}
  catch(e){rejected=true;error=e.message;}
  const passed=expectedReject?rejected:!rejected;
  cases.push({name,result:passed?'PASS':'FAIL',expected:expectedReject?'REJECT':'ACCEPT',observed:rejected?'REJECT':'ACCEPT',error});
 };
 const baseline=m.selfTest();
 cases.push({name:'original model self-test 29/29',result:baseline.passed===29&&baseline.failed===0?'PASS':'FAIL',expected:'29_PASS',observed:baseline.passed});
 test('nonexclusive default null conditional P/E',false,()=>{},r=>r.rows.length===4&&r.rows.every(x=>x.eligibleCohortPBounds===null&&x.eligibleCohortEBounds===null&&x.confidence===0&&x.economicUse==='PREVIEW_ONLY'&&x.normalizedVerified===false&&!x.goldRecommendationEligible));
 test('actual completed casts and Resourcefulness refunds',false,()=>{},r=>r.completedCasts===5&&r.abortedRequests===1&&r.refundedInputUnits===1&&r.netInputUnits===24);
 test('positive gem while trait locked is permitted without exclusivity',false,s=>s.events[0].gemFindingUnlocks.Ruby=false,r=>r.rows.find(x=>x.gem==='Ruby').positiveCasts===2);
 test('hypothetical exclusivity rejects positive locked output',true,s=>{s.events[0].gemFindingUnlocks.Ruby=false;s.scenarioExclusiveOutputGate={status:'SCENARIO_ONLY',provenance:'SYNTHETIC'};});
 test('cap alone does not imply conditional E',false,s=>s.scenarioCaps={'212495':{maxPerCompletedCast:3,status:'SCENARIO_ONLY',provenance:'SYNTHETIC'}},r=>r.rows.find(x=>x.gem==='Ruby').eligibleCohortEBounds===null);
 test('gate plus cap remains hypothetical and non-economic',false,s=>{s.scenarioCaps={'212495':{maxPerCompletedCast:3,status:'SCENARIO_ONLY',provenance:'SYNTHETIC'}};s.scenarioExclusiveOutputGate={status:'SCENARIO_ONLY',provenance:'SYNTHETIC'};},r=>r.rows.find(x=>x.gem==='Ruby').eligibleCohortEBounds!==null&&r.rows.every(x=>x.economicUse==='PREVIEW_ONLY'&&x.confidence===0));
 test('invalid output rank rejected',true,s=>s.inputQualityRank=3);
 test('incorrect net reagent accounting rejected',true,s=>s.events[0].inputAccounting.netSpentInputUnits=5);
 test('invalid nonfinite profession stat rejected',true,s=>s.professionStats.resourcefulness.value=Infinity);
 // The following inputs must fail attestation. In v1.1.0 they are silently
 // accepted, even when serialization changes the context or completed casts.
 test('hidden nested toJSON alters stat',true,s=>Object.defineProperty(s.professionStats.resourcefulness,'toJSON',{value(){return {value:999,unit:'rating'}},enumerable:false}));
 test('visible nested toJSON alters stat',true,s=>s.professionStats.resourcefulness.toJSON=()=>({value:999,unit:'rating'}));
 test('hidden root toJSON alters stats',true,s=>Object.defineProperty(s.professionStats,'toJSON',{value(){return {resourcefulness:{value:999,unit:'rating'}}},enumerable:false}));
 test('root symbol metadata omitted by JSON',true,s=>s.professionStats[Symbol('hidden')]=999);
 test('nested symbol metadata omitted by JSON',true,s=>s.professionStats.resourcefulness[Symbol('hidden')]=999);
 test('nested getter drifts between validation and output',true,s=>{let n=0;Object.defineProperty(s.professionStats.resourcefulness,'value',{get(){return ++n},enumerable:true});});
 test('events hidden toJSON changes completed-cast array',true,s=>Object.defineProperty(s.events,'toJSON',{value(){return []},enumerable:false}));
 test('events hidden nonenumerable patch metadata',true,s=>Object.defineProperty(s.events,'patchEpoch',{value:'OTHER',enumerable:false}));
 test('array subclass overrides serialized events',true,s=>{class A extends Array{toJSON(){return []}}s.events=Object.assign(new A(),s.events);});
 test('output counts hidden toJSON changes positive counts',true,s=>Object.defineProperty(s.events[0].outputCapture.countsByItemID,'toJSON',{value(){return {'212495':0,'212505':0,'212508':0,'212511':0}},enumerable:false}));
 test('unlocks hidden nonenumerable context',true,s=>Object.defineProperty(s.events[0].gemFindingUnlocks,'patchOverride',{value:'OTHER',enumerable:false}));
 test('event hidden nonenumerable context',true,s=>Object.defineProperty(s.events[0],'shadow',{value:'OTHER',enumerable:false}));
 test('nested hidden stat bonus',true,s=>Object.defineProperty(s.professionStats.resourcefulness,'hiddenBonus',{value:100,enumerable:false}));
 test('counts getter changes across validation and analysis',true,s=>{let n=0;Object.defineProperty(s.events[0].outputCapture.countsByItemID,'212495',{get(){return ++n},enumerable:true});});
 const passed=cases.filter(c=>c.result==='PASS').length,failed=cases.length-passed;
 return {suite:'F005_TWW_GEM_UNLOCK_SERIALIZATION_ATTESTATION',sourceBlobSHA:PIN,modelID:m.MODEL_ID,passed,failed,total:cases.length,modelSelfTestPassed:baseline.passed,actualRetailCasts:0,independentHoldoutFamilies:0,economicPromotions:0,cases};
}
if(require.main===module){try{checkPin();const r=run();console.log(JSON.stringify(r,null,2));if(r.failed)process.exitCode=1;}catch(e){console.error('F005 model pin or test execution failed: '+e.message);process.exitCode=1;}}
module.exports={run,checkPin};
