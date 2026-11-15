'use strict';
// F002: native replay of F005's TWW milling v1.0.1 snapshot and provenance QA.
// The eight independently reported defects remain blockers, not passing tests.
const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const {spawnSync}=require('node:child_process');
const ROOT=path.resolve(__dirname,'../..');
const MODEL='research/tools/models_v2/tww_mill_reagent_accounting_identification_v1.js';
const FIXTURE='research/tests/v2/test_f005_tww_mill_v101_snapshot_provenance_20261031.js';
const PINS=Object.freeze({
  [MODEL]:'5d90046b15046fb210523c34363c66596b962d3d',
  'research/models/v2/tww_mill_reagent_accounting_identification_v1.json':'b8d6218f3515f7b3c1f9c32906d8225dba37013d',
  [FIXTURE]:'94ea3a1586e986d52d47394745181e8bab3f478e',
  'research/coordination/v2/reviews/20261031T0040Z-F005-TWW-MILL-V101-SNAPSHOT-AND-PROVENANCE.json':'d2432e177ba352d00c5e41466e8e64410316bdd6'
});
const KNOWN_FAILURES=Object.freeze([
  'reject context nominal batch conflicting with accounting batch',
  'reject context reagent vector conflicting with actual batch',
  'reject mutable targetKey after mapping validation',
  'reject mutable saving cap that inflates max casts',
  'reject saving cap status escalation after validation',
  'reject per-cast array length shrinking after structural validation',
  'reject mutable study-family identity after validation',
  'reject mutable patch-epoch identity after validation'
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
  if(!o||o.modelBlobSHA!==PINS[MODEL]||
     o.total!==15||!Number.isInteger(o.passed)||!Number.isInteger(o.failed)||
     o.passed+o.failed!==15||o.syntheticOnly!==true||o.independentlyValidatedRetailStudyFamilies!==0||
     !Array.isArray(o.failures)||o.failures.length!==o.failed)
    throw Error('F005_RESULT_CONTRACT_CHANGED');
  if(o.failed!==KNOWN_FAILURES.length||exitCode!==1||
     o.failures.some((failure,i)=>!failure||failure.name!==KNOWN_FAILURES[i]||
       failure.pass!==false||failure.error!=='unsafe input accepted'))
    throw Error('KNOWN_FAILURE_BASELINE_DRIFT:'+JSON.stringify(o.failures));
  return {status:'KNOWN_F003_DEFECTS_STILL_BLOCK_INTEGRATION',passed:o.passed,failed:o.failed,
    blockerNames:o.failures.map(failure=>failure.name),failures:o.failures,independentAcceptance:false};
}
function selfTest(){
  const assert=require('node:assert/strict');
  assert.equal(gitBlobSHA(Buffer.from('hello')),'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0');
  const make=(failures)=>({modelBlobSHA:PINS[MODEL],
    total:15,passed:15-failures.length,failed:failures.length,syntheticOnly:true,
    independentlyValidatedRetailStudyFamilies:0,
    failures:failures.map(name=>({name,pass:false,error:'unsafe input accepted'}))});
  const expected=validateReport(JSON.stringify(make(KNOWN_FAILURES)),1);
  assert.equal(expected.passed,7);
  assert.equal(expected.failed,8);
  assert.equal(expected.independentAcceptance,false);
  const mutations=[
    [x=>x.total=14,1],[x=>x.syntheticOnly=false,1],[x=>x.independentlyValidatedRetailStudyFamilies=1,1],
    [x=>x.modelBlobSHA='0'.repeat(40),1],[x=>x.failed=0,1],
    [x=>x.failures[0].name='unknown failure',1],[x=>x.failures[0].error='unexpected exception',1],
    [x=>x.failures[1].name=x.failures[0].name,1],[x=>x.failures.pop(),1],
    [x=>x.passed=8,1],[x=>x.failures[0].pass=true,1]
  ];
  let rejected=0;
  for(const [edit,code] of mutations){const x=make(KNOWN_FAILURES);edit(x);
    assert.throws(()=>validateReport(JSON.stringify(x),code));rejected++;}
  assert.throws(()=>validateReport(JSON.stringify(make(KNOWN_FAILURES)),0));rejected++;
  assert.throws(()=>validateReport(JSON.stringify(make([])),0));rejected++;
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
  return {status:'PASS',knownFailuresExplicit:8,reportMutationsRejected:rejected,pinChecks:4};
}
function run(){
  const sourceBlobPins=verifyPins();
  const fixture=path.join(ROOT,FIXTURE);
  const child=spawnSync(process.execPath,[fixture],{cwd:ROOT,encoding:'utf8',timeout:120000,maxBuffer:8*1024*1024});
  if(child.error||child.signal||![0,1].includes(child.status))
    throw Error('NATIVE_F005_EXECUTION_ERROR:'+String(child.error||child.signal||child.status)+'\n'+(child.stderr||''));
  return {runType:'INFORMATIONAL_NEGATIVE_QA_NOT_ECONOMIC_ACCEPTANCE',node:process.version,
    sourceBlobPins,...validateReport(child.stdout,child.status),
    workingNumericCellsChanged:0,evidenceExpectedQuantityPromotions:0,
    confidencePromotions:0,economicPromotions:0,liveEVChanged:false};
}
if(require.main===module){
  try{
    const selfTesting=process.argv.includes('--self-test');
    const result=selfTesting?selfTest():run();
    console.log(JSON.stringify(result));
    if(!selfTesting&&process.env.GITHUB_STEP_SUMMARY){
      fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY,[
        '### TWW milling v1.0.1 independent model QA',
        '',
        `${result.passed} synthetic cases passed. ${result.failed} known model defects reproduced and still block integration.`,
        '',
        ...result.failures.map(failure=>`- ${failure.name} — ${failure.error}`),
        '',
      ].join('\n')+'\n');
    }
  }
  catch(e){console.error('F002 TWW native negative-QA preflight FAIL: '+e.message);process.exitCode=1;}
}
module.exports={PINS,KNOWN_FAILURES,gitBlobSHA,verifyPins,validateReport,selfTest,run};
