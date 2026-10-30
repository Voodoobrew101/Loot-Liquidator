'use strict';
// F002 research-only native replay of F005 Dragonflight milling fixed-n negative QA.
// Known eight failures are blockers, never converted into passing assertions.
const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const {spawnSync}=require('node:child_process');
const ROOT=path.resolve(__dirname,'../..');
const MODEL='research/tools/models_v2/df_milling_fixed_n_simultaneous_bounds_v1.js';
const FIXTURE='research/tests/v2/test_f005_df_milling_fixed_n_independent_attestation.js';
const PINS=Object.freeze({
  [MODEL]:'216a929d4ab7b683e1bc9f4637273c4d766b1081',
  'research/models/v2/df_milling_fixed_n_simultaneous_bounds_v1.json':'b981ee50df8ebddf85cecd36e471cbb5903c1fd1',
  [FIXTURE]:'94c85850e353892e1a62c60a1503a6f6e5e37b50',
  'research/coordination/v2/reviews/20261030T1940Z-F005-df-milling-fixed-n-context-attestation.json':'4dbaf5eb06b46bb3b2f81ec51e088150ec23ce42'
});
const KNOWN_FAILURES=Object.freeze([
  'reject patch-build suffix contamination',
  'reject nonexistent calendar observation date',
  'reject cast proxy changing outputs after validation',
  'reject cap proxy changing maximum after attestation',
  'reject context proxy changing source lineage after validation',
  'reject context proxy changing epoch after validation',
  'reject context proxy changing recipe identity after validation',
  'reject mutated cap source ID after validation'
]);
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
function validateReport(output,exitCode){
  let o;
  try{o=JSON.parse(output.trim());}catch(_){throw Error('INVALID_F005_JSON');}
  if(!o||o.modelBlobSHA!==PINS[MODEL]||o.total!==30||
    !Number.isInteger(o.passed)||!Number.isInteger(o.failed)||
    o.passed<0||o.failed<0||o.passed+o.failed!==30||
    o.syntheticOnly!==true||o.independentRetailHoldouts!==0||
    !Array.isArray(o.failures)||o.failures.length!==o.failed)
    throw Error('F005_RESULT_CONTRACT_CHANGED');
  const names=o.failures.map(x=>x&&x.name);
  if(names.some(x=>typeof x!=='string')||new Set(names).size!==names.length||
    o.failures.some(x=>x.pass!==false||typeof x.error!=='string'||!x.error))
    throw Error('F005_FAILURE_DETAILS_INVALID');
  if(names.some(x=>!KNOWN_FAILURES.includes(x)))
    throw Error('NEW_INDEPENDENT_FAILURE:'+names.filter(x=>!KNOWN_FAILURES.includes(x)).join(','));
  if(o.failed===8){
    if(o.passed!==22||exitCode!==1||names.some((x,i)=>x!==KNOWN_FAILURES[i]))
      throw Error('KNOWN_FAILURE_BASELINE_DRIFT');
    return {status:'KNOWN_F003_EIGHT_DEFECTS_STILL_BLOCK_INTEGRATION',
      passed:22,failed:8,blockerNames:names,independentAcceptance:false};
  }
  if(o.failed===0){
    if(o.passed!==30||exitCode!==0)throw Error('STRICT_30_EXIT_STATUS_MISMATCH');
    return {status:'ALL_30_PASS_PENDING_INDEPENDENT_F005_ACCEPTANCE',
      passed:30,failed:0,blockerNames:[],independentAcceptance:false};
  }
  throw Error('PARTIAL_REPAIR_REQUIRES_F005_REVIEW:'+o.failed);
}
function selfTest(){
  const assert=require('node:assert/strict');
  assert.equal(gitBlobSHA(Buffer.from('hello')),'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0');
  const make=(failures)=>({modelBlobSHA:PINS[MODEL],total:30,passed:30-failures.length,
    failed:failures.length,syntheticOnly:true,independentRetailHoldouts:0,
    failures:failures.map(name=>({name,pass:false,error:'synthetic defect'}))});
  assert.equal(validateReport(JSON.stringify(make(KNOWN_FAILURES)),1).failed,8);
  assert.equal(validateReport(JSON.stringify(make([])),0).passed,30);
  const mutations=[
    x=>x.total=29,x=>x.syntheticOnly=false,x=>x.independentRetailHoldouts=1,
    x=>x.modelBlobSHA='0'.repeat(40),x=>x.failed=0,
    x=>x.failures[0].name='unknown failure',x=>x.failures[0].error='',
    x=>x.failures[1].name=x.failures[0].name,x=>x.failures.pop(),
    x=>x.passed=23,x=>x.failures[0].pass=true,
    x=>x.failures.reverse(),x=>x.failed=-8
  ];
  let rejected=0;
  for(const edit of mutations){const x=make(KNOWN_FAILURES);edit(x);
    assert.throws(()=>validateReport(JSON.stringify(x),1));rejected++;}
  assert.throws(()=>validateReport(JSON.stringify(make(KNOWN_FAILURES)),0));rejected++;
  assert.throws(()=>validateReport(JSON.stringify(make([])),1));rejected++;
  assert.throws(()=>validateReport(JSON.stringify(make(KNOWN_FAILURES.slice(1))),1));rejected++;
  assert.throws(()=>validateReport('not-json',1));rejected++;
  const tmp=fs.mkdtempSync(path.join(require('node:os').tmpdir(),'ll-df-f002-'));
  try{
    fs.writeFileSync(path.join(tmp,'x'),'safe');
    const pins={x:gitBlobSHA(Buffer.from('safe'))};
    assert.equal(Object.keys(verifyPins(tmp,pins)).length,1);
    fs.writeFileSync(path.join(tmp,'x'),'altered');
    assert.throws(()=>verifyPins(tmp,pins),/SOURCE_PIN_MISMATCH/);
    assert.throws(()=>verifyPins(tmp,{x:'invalid'}),/INVALID_PIN/);
    assert.throws(()=>verifyPins(tmp,{'../outside':'0'.repeat(40)}),/PATH_ESCAPE/);
  }finally{fs.rmSync(tmp,{recursive:true,force:true});}
  return {status:'PASS',knownFailuresExplicit:8,reportMutationsRejected:rejected,pinChecks:4};
}
function run(){
  const sourceBlobPins=verifyPins();
  const child=spawnSync(process.execPath,[path.join(ROOT,FIXTURE)],
    {cwd:ROOT,encoding:'utf8',timeout:120000,maxBuffer:8*1024*1024});
  if(child.error||child.signal||![0,1].includes(child.status))
    throw Error('NATIVE_F005_EXECUTION_ERROR:'+String(child.error||child.signal||child.status)+'\n'+(child.stderr||''));
  return {runType:'INFORMATIONAL_NEGATIVE_QA_NOT_ECONOMIC_ACCEPTANCE',
    node:process.version,sourceBlobPins,...validateReport(child.stdout,child.status),
    workingNumericCellsChanged:0,evidenceExpectedQuantityPromotions:0,
    confidencePromotions:0,economicPromotions:0,liveEVChanged:false};
}
if(require.main===module){
  try{console.log(JSON.stringify(process.argv.includes('--self-test')?selfTest():run()));}
  catch(e){console.error('F002 DF milling native negative-QA preflight FAIL: '+e.message);process.exitCode=1;}
}
module.exports={PINS,KNOWN_FAILURES,gitBlobSHA,verifyPins,validateReport,selfTest,run};
