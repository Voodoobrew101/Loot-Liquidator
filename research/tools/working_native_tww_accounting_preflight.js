'use strict';
// F002: native replay of F005's TWW milling accounting negative QA.
// The five independently reported defects are known blockers, not passing tests.
// This is research-only and does not change F003, evidence, economic or runtime gates.
const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const {spawnSync}=require('node:child_process');
const ROOT=path.resolve(__dirname,'../..');
const PINS=Object.freeze({
  'research/tools/models_v2/tww_mill_reagent_accounting_identification_v1.js':'75169a9a6f2eb7a3f1c4148e09074fba65d88f4a',
  'research/models/v2/tww_mill_reagent_accounting_identification_v1.json':'758b38f4a42b5becd353ca5e17fb920000f7355c',
  'research/tests/v2/test_f005_tww_mill_accounting_independent_attestation.js':'1dc22afeed2eefafd845979fafa15cbb59c15708',
  'research/coordination/v2/reviews/20261030T1845Z-F005-TWW-MILL-ACCOUNTING-INDEPENDENT-ATTESTATION.json':'eea3a0140b78e252f85d5c0f32914118b79d2962'
});
const KNOWN_FAILURES=Object.freeze([
  'reject contradictory nominal batch in typed context',
  'reject contradictory direct reagent vector in typed context',
  'inverse must not return nonfinite conditional mean',
  'reject proxy that changes mapping after identity check',
  'reject proxy cap whose units change after validation'
]);
function gitBlobSHA(bytes){return crypto.createHash('sha1').update('blob '+bytes.length+'\0').update(bytes).digest('hex');}
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
  if(!o||o.modelBlobSHA!==PINS['research/tools/models_v2/tww_mill_reagent_accounting_identification_v1.js']||
     o.total!==37||!Number.isInteger(o.passed)||!Number.isInteger(o.failed)||
     o.passed+o.failed!==37||o.syntheticOnly!==true||o.independentRetailHoldouts!==0||
     !Array.isArray(o.failures)||o.failures.length!==o.failed)
    throw Error('F005_RESULT_CONTRACT_CHANGED');
  const names=o.failures.map(x=>x&&x.name);
  if(names.some(x=>typeof x!=='string')||new Set(names).size!==names.length||
     o.failures.some(x=>x.pass!==false||typeof x.error!=='string'||!x.error))
    throw Error('F005_FAILURE_DETAILS_INVALID');
  const known=new Set(KNOWN_FAILURES);
  if(names.some(x=>!known.has(x)))throw Error('NEW_INDEPENDENT_FAILURE:'+names.filter(x=>!known.has(x)).join(','));
  if(o.failed===5){
    if(o.passed!==32||exitCode!==1||names.some((x,i)=>x!==KNOWN_FAILURES[i]))
      throw Error('KNOWN_FAILURE_BASELINE_DRIFT');
    return {status:'KNOWN_F003_DEFECTS_STILL_BLOCK_INTEGRATION',passed:32,failed:5,
      blockerNames:names,independentAcceptance:false};
  }
  if(o.failed===0){
    if(o.passed!==37||exitCode!==0)throw Error('STRICT_37_EXIT_STATUS_MISMATCH');
    return {status:'ALL_37_PASS_PENDING_INDEPENDENT_F005_ACCEPTANCE',passed:37,failed:0,
      blockerNames:[],independentAcceptance:false};
  }
  throw Error('PARTIAL_REPAIR_REQUIRES_F005_REVIEW:'+o.failed);
}
function selfTest(){
  const assert=require('node:assert/strict');
  assert.equal(gitBlobSHA(Buffer.from('hello')),'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0');
  const make=(failures)=>({modelBlobSHA:PINS['research/tools/models_v2/tww_mill_reagent_accounting_identification_v1.js'],
    total:37,passed:37-failures.length,failed:failures.length,syntheticOnly:true,
    independentRetailHoldouts:0,failures:failures.map(name=>({name,pass:false,error:'synthetic defect'}))});
  assert.equal(validateReport(JSON.stringify(make(KNOWN_FAILURES)),1).failed,5);
  assert.equal(validateReport(JSON.stringify(make([])),0).passed,37);
  const mutations=[
    [x=>x.total=36,1],[x=>x.syntheticOnly=false,1],[x=>x.independentRetailHoldouts=1,1],
    [x=>x.modelBlobSHA='0'.repeat(40),1],[x=>x.failed=0,1],
    [x=>x.failures[0].name='unknown failure',1],[x=>x.failures[0].error='',1],
    [x=>x.failures[1].name=x.failures[0].name,1],[x=>x.failures.pop(),1],
    [x=>x.passed=33,1],[x=>x.failures[0].pass=true,1]
  ];
  let rejected=0;
  for(const [edit,code] of mutations){const x=make(KNOWN_FAILURES);edit(x);
    assert.throws(()=>validateReport(JSON.stringify(x),code));rejected++;}
  assert.throws(()=>validateReport(JSON.stringify(make(KNOWN_FAILURES)),0));rejected++;
  assert.throws(()=>validateReport(JSON.stringify(make([])),1));rejected++;
  assert.throws(()=>validateReport(JSON.stringify(make(KNOWN_FAILURES.slice(1))),1));rejected++;
  assert.throws(()=>validateReport('not-json',1));rejected++;
  const tmp=fs.mkdtempSync(path.join(require('node:os').tmpdir(),'ll-tww-f002-'));
  try{
    fs.writeFileSync(path.join(tmp,'x'),'safe');
    const pins={x:gitBlobSHA(Buffer.from('safe'))};
    assert.equal(Object.keys(verifyPins(tmp,pins)).length,1);
    fs.writeFileSync(path.join(tmp,'x'),'altered');
    assert.throws(()=>verifyPins(tmp,pins),/SOURCE_PIN_MISMATCH/);
    assert.throws(()=>verifyPins(tmp,{x:'invalid'}),/INVALID_PIN/);
    assert.throws(()=>verifyPins(tmp,{'../outside':'0'.repeat(40)}),/PATH_ESCAPE/);
  }finally{fs.rmSync(tmp,{recursive:true,force:true});}
  return {status:'PASS',knownFailuresExplicit:5,reportMutationsRejected:rejected,pinChecks:4};
}
function run(){
  const sourceBlobPins=verifyPins();
  const fixture=path.join(ROOT,'research/tests/v2/test_f005_tww_mill_accounting_independent_attestation.js');
  const child=spawnSync(process.execPath,[fixture],{cwd:ROOT,encoding:'utf8',timeout:120000,maxBuffer:8*1024*1024});
  if(child.error||child.signal||![0,1].includes(child.status))
    throw Error('NATIVE_F005_EXECUTION_ERROR:'+String(child.error||child.signal||child.status)+'\n'+(child.stderr||''));
  return {runType:'INFORMATIONAL_NEGATIVE_QA_NOT_ECONOMIC_ACCEPTANCE',node:process.version,
    sourceBlobPins,...validateReport(child.stdout,child.status),
    workingNumericCellsChanged:0,evidenceExpectedQuantityPromotions:0,
    confidencePromotions:0,economicPromotions:0,liveEVChanged:false};
}
if(require.main===module){
  try{console.log(JSON.stringify(process.argv.includes('--self-test')?selfTest():run()));}
  catch(e){console.error('F002 TWW native negative-QA preflight FAIL: '+e.message);process.exitCode=1;}
}
module.exports={PINS,KNOWN_FAILURES,gitBlobSHA,verifyPins,validateReport,selfTest,run};
