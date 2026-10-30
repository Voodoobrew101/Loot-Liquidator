'use strict';
// F002 research-only source-pinned native replay of F005's repaired Dragonflight
// milling v1.0.1: 39 author self-checks + 30 original + 22 new independent
// synthetic tests. Native success is NOT a current-Retail holdout or EV gate.
const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const {spawnSync}=require('node:child_process');
const ROOT=path.resolve(__dirname,'../..');
const MODEL='research/tools/models_v2/df_milling_fixed_n_simultaneous_bounds_v1.js';
const SUITES=Object.freeze([
  Object.freeze({file:'research/tests/v2/test_f005_df_milling_fixed_n_independent_attestation.js',total:30}),
  Object.freeze({file:'research/tests/v2/test_f005_df_milling_v101_snapshot_boundary.js',total:22})
]);
const PINS=Object.freeze({
  [MODEL]:'e36328de0e677582bf9b2b36c4a6144a5c2f17be',
  'research/models/v2/df_milling_fixed_n_simultaneous_bounds_v1.json':'94e57e0f7dc91b95c9eed3bb575db3812fb45155',
  [SUITES[0].file]:'4bf40e94e4cfccd483a9bd0263c7525777def6f8',
  [SUITES[1].file]:'25855bf7d5b03ac0782a232a6d7b17819f5db690',
  'research/coordination/v2/reviews/20261030T2044Z-F005-df-milling-v101-repair-and-diamond-source-attestation.json':'1769f8a8aa9e52509e0e8fe431aab13c55f28bf4'
});
function gitBlobSHA(bytes){
  return crypto.createHash('sha1').update('blob '+bytes.length+'\0').update(bytes).digest('hex');
}
function verifyPins(root=ROOT,pins=PINS){
  const base=fs.realpathSync(root),result={};
  for(const [relative,expected] of Object.entries(pins)){
    if(!/^[0-9a-f]{40}$/.test(expected))throw Error('INVALID_PIN:'+relative);
    const absolute=path.resolve(root,relative);
    if(!absolute.startsWith(path.resolve(root)+path.sep))throw Error('PATH_ESCAPE:'+relative);
    const real=fs.realpathSync(absolute);
    if(!real.startsWith(base+path.sep)||!fs.statSync(real).isFile())throw Error('UNSAFE_SOURCE_PATH:'+relative);
    const actual=gitBlobSHA(fs.readFileSync(real));
    if(actual!==expected)throw Error('SOURCE_PIN_MISMATCH:'+relative+':'+actual);
    result[relative]=actual;
  }
  return result;
}
function validateReport(output,exitCode,expected){
  let o;
  try{o=JSON.parse(output.trim());}catch(_){throw Error('INVALID_F005_JSON:'+expected.file);}
  if(!o||o.modelBlobSHA!==PINS[MODEL]||o.total!==expected.total||
     o.passed!==expected.total||o.failed!==0||exitCode!==0||
     o.syntheticOnly!==true||o.independentRetailHoldouts!==0||
     !Array.isArray(o.failures)||o.failures.length!==0)
    throw Error('F005_STRICT_RESULT_CONTRACT_CHANGED:'+expected.file);
  return {fixture:expected.file,passed:o.passed,failed:0,syntheticOnly:true};
}
function verifyAuthorSelfTest(){
  const model=require(path.join(ROOT,MODEL));
  if(model.MODEL_ID!=='df-milling-fixed-n-simultaneous-bounds-v1.0.1'||
     model.POLICY?.confidence!==0||model.POLICY?.economicUse!=='PREVIEW_ONLY'||
     model.POLICY?.normalizedVerified!==false||model.POLICY?.liveEconomicEligible!==false||
     model.POLICY?.tooltipOnlyEligible!==false||model.TARGETS?.length!==43)
    throw Error('MODEL_POLICY_OR_SCOPE_DRIFT');
  const r=model.selfTest();
  if(r.passed!==39||r.failed!==0||r.syntheticOnly!==true||r.trackedKeys!==43||
     r.modelID!==model.MODEL_ID)throw Error('MODEL_SELF_TEST_DRIFT');
  return {passed:39,failed:0,syntheticOnly:true};
}
function selfTest(){
  const assert=require('node:assert/strict');
  const pins=verifyPins();
  const author=verifyAuthorSelfTest();
  assert.equal(gitBlobSHA(Buffer.from('hello')),'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0');
  const make=(total)=>({modelBlobSHA:PINS[MODEL],total,passed:total,failed:0,
    syntheticOnly:true,independentRetailHoldouts:0,failures:[]});
  for(const suite of SUITES)assert.equal(validateReport(JSON.stringify(make(suite.total)),0,suite).passed,suite.total);
  const edits=[
    x=>x.modelBlobSHA='0'.repeat(40),x=>x.total=29,x=>x.passed=29,
    x=>x.failed=1,x=>x.syntheticOnly=false,x=>x.independentRetailHoldouts=1,
    x=>x.failures=[{name:'hidden failure',pass:false,error:'failed'}],
    x=>x.failures=null,x=>x.passed='30',x=>x.failed='0',
    x=>x.independentRetailHoldouts=null,x=>x.syntheticOnly='true'
  ];
  let rejected=0;
  for(const suite of SUITES){
    for(const edit of edits){const x=make(suite.total);edit(x);
      assert.throws(()=>validateReport(JSON.stringify(x),0,suite));rejected++;}
    assert.throws(()=>validateReport(JSON.stringify(make(suite.total)),1,suite));rejected++;
    assert.throws(()=>validateReport('not-json',0,suite));rejected++;
    assert.throws(()=>validateReport(JSON.stringify(make(suite.total+1)),0,suite));rejected++;
  }
  const tmp=fs.mkdtempSync(path.join(require('node:os').tmpdir(),'ll-df-v101-f002-'));
  try{
    fs.writeFileSync(path.join(tmp,'x'),'safe');
    const good={x:gitBlobSHA(Buffer.from('safe'))};
    assert.equal(Object.keys(verifyPins(tmp,good)).length,1);
    fs.writeFileSync(path.join(tmp,'x'),'altered');
    assert.throws(()=>verifyPins(tmp,good),/SOURCE_PIN_MISMATCH/);
    assert.throws(()=>verifyPins(tmp,{x:'invalid'}),/INVALID_PIN/);
    assert.throws(()=>verifyPins(tmp,{'../outside':'0'.repeat(40)}),/PATH_ESCAPE/);
  }finally{fs.rmSync(tmp,{recursive:true,force:true});}
  return {status:'PASS',modelVersion:'1.0.1',modelSelfTests:author.passed,
    independentCasesExpected:52,reportMutationsRejected:rejected,
    sourcePinsVerified:Object.keys(pins).length,pinChecks:4,
    independentAcceptance:false};
}
function run(){
  const sourceBlobPins=verifyPins();
  const authorSelfTest=verifyAuthorSelfTest();
  const independentSuites=[];
  for(const suite of SUITES){
    const child=spawnSync(process.execPath,[path.join(ROOT,suite.file)],
      {cwd:ROOT,encoding:'utf8',timeout:120000,maxBuffer:8*1024*1024});
    if(child.error||child.signal||child.status!==0)
      throw Error('NATIVE_F005_EXECUTION_ERROR:'+suite.file+':'+
        String(child.error||child.signal||child.status)+'\n'+(child.stderr||''));
    independentSuites.push(validateReport(child.stdout,child.status,suite));
  }
  const passed=independentSuites.reduce((n,x)=>n+x.passed,0);
  if(passed!==52)throw Error('INDEPENDENT_TOTAL_DRIFT');
  return {runType:'INFORMATIONAL_SYNTHETIC_QA_NOT_ECONOMIC_ACCEPTANCE',
    node:process.version,sourceBlobPins,authorSelfTest,independentSuites,
    independentSyntheticPassed:passed,independentSyntheticFailed:0,
    independentRetailHoldouts:0,independentAcceptance:false,
    workingNumericCellsChanged:0,evidenceExpectedQuantityPromotions:0,
    confidencePromotions:0,economicPromotions:0,liveEVChanged:false};
}
if(require.main===module){
  try{console.log(JSON.stringify(process.argv.includes('--self-test')?selfTest():run()));}
  catch(e){console.error('F002 DF milling v1.0.1 native preflight FAIL: '+e.message);process.exitCode=1;}
}
module.exports={PINS,SUITES,gitBlobSHA,verifyPins,validateReport,verifyAuthorSelfTest,selfTest,run};
