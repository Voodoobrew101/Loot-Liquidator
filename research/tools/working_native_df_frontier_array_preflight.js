'use strict';
// F002: source-pinned native replay of F005's 21-case DF frontier snapshot suite.
// Expected negative QA is a model defect, never evidence/model acceptance.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const {spawnSync}=require('node:child_process');
const assert=require('node:assert/strict');
const ROOT=path.resolve(__dirname,'../..');
const MODEL='research/tools/models_v2/df_prospect_decision_frontier_v1.js';
const STAGE='research/tools/models_v2/df_historical_diamond_denominator_stage_guard_v1.js';
const SUITE='research/tests/v2/test_f005_df_frontier_v101_array_snapshot_repair_20261030.js';
const PINS=Object.freeze({
 [MODEL]:'483842ab580808cbd9d9c130d26781b59d2e6ee4',
 [STAGE]:'2c9005e1d7be6df68d5631a418fbae95a144f6e7',
 [SUITE]:'14ad7d0693ee9e1bda43b7352854188972a8fb8d',
 'research/tests/v2/test_f005_df_prospect_frontier_v1_context_attestation_20261030.js':'bbb4c309a98e5a14dd8f15ae5225703a828cbad8',
 'research/tests/v2/test_f005_df_prismatic_stage_identity_20261030.js':'4f546a33559a9e8202c1c846d7bbfe91c9f8503c',
 'research/coordination/v2/reviews/20261030T2340Z-F005-frontier-repair-array-length-and-prismatic-qa.json':'842fe7507e2f093fd307943d138f5a47c6b019b5'
});
const FAILURES=Object.freeze([
 'reject output array length shrink 1 to 0 after dense validation',
 'reject output array length shrink 2 to 1 after dense validation'
]);
function blobSHA(bytes){return crypto.createHash('sha1').update('blob '+bytes.length+'\0').update(bytes).digest('hex');}
function verifyPins(root=ROOT,pins=PINS){
 const base=fs.realpathSync(root),result={};
 for(const [rel,expected] of Object.entries(pins)){
  if(!/^[a-f0-9]{40}$/.test(expected))throw Error('INVALID_PIN:'+rel);
  const absolute=path.resolve(root,rel);
  if(!absolute.startsWith(path.resolve(root)+path.sep))throw Error('PATH_ESCAPE:'+rel);
  const real=fs.realpathSync(absolute);
  if(!real.startsWith(base+path.sep)||!fs.statSync(real).isFile())throw Error('UNSAFE_PATH:'+rel);
  const actual=blobSHA(fs.readFileSync(real));
  if(actual!==expected)throw Error('SOURCE_PIN_MISMATCH:'+rel+':'+actual);
  result[rel]=actual;
 }
 return result;
}
function validateReport(raw,exitCode){
 let r;try{r=JSON.parse(raw.trim());}catch(_){throw Error('INVALID_F005_JSON');}
 if(!r||r.suite!=='F005_DF_FRONTIER_REPAIR_AND_ARRAY_SNAPSHOT'||
  r.frontierGitBlob!==PINS[MODEL]||r.stageGitBlob!==PINS[STAGE]||
  r.assertions!==21||!Number.isInteger(r.passed)||!Number.isInteger(r.failed)||
  r.passed+r.failed!==21||!Array.isArray(r.tests)||r.tests.length!==21||
  r.economicPromotions!==0||r.independentRetailHoldouts!==0||
  JSON.stringify(r.expectedOutstanding)!==JSON.stringify(FAILURES))
  throw Error('F005_RESULT_CONTRACT_CHANGED');
 const seen=new Set(),failed=[];
 for(const t of r.tests){
  if(!t||typeof t.name!=='string'||!t.name||seen.has(t.name)||
   !['PASS','FAIL'].includes(t.status))throw Error('F005_TEST_IDENTITY_DRIFT');
  seen.add(t.name);
  if(t.status==='FAIL'){
   if(typeof t.reason!=='string'||!t.reason)throw Error('F005_FAILURE_REASON_MISSING');
   failed.push(t.name);
  }
 }
 if(failed.length!==r.failed)throw Error('F005_FAILURE_COUNT_DRIFT');
 if(r.failed===2){
  if(r.passed!==19||exitCode!==1||r.verdict!=='FAIL_F003_ARRAY_SNAPSHOT_INTEGRITY'||
   JSON.stringify(failed)!==JSON.stringify(FAILURES))
   throw Error('KNOWN_NEGATIVE_QA_DRIFT');
  return {status:'KNOWN_F003_ARRAY_LENGTH_DEFECTS',nativePassed:19,nativeFailed:2,
   failedAssertions:failed,modelAccepted:false};
 }
 if(r.failed===0){
  if(r.passed!==21||exitCode!==0||r.verdict!=='CONDITIONAL_PASS_SYNTHETIC_ONLY')
   throw Error('FULL_REPAIR_REPORT_DRIFT');
  return {status:'21_PASS_REQUIRES_INDEPENDENT_F005_REVIEW',nativePassed:21,nativeFailed:0,
   failedAssertions:[],modelAccepted:false};
 }
 throw Error('PARTIAL_OR_NEW_FAILURE_REQUIRES_F005_REVIEW:'+r.failed+':'+failed.join('|'));
}
function selfTest(){
 assert.equal(blobSHA(Buffer.from('hello')),'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0');
 const make=()=>({suite:'F005_DF_FRONTIER_REPAIR_AND_ARRAY_SNAPSHOT',
  frontierGitBlob:PINS[MODEL],stageGitBlob:PINS[STAGE],assertions:21,
  passed:19,failed:2,tests:[...Array.from({length:19},(_,i)=>({name:'pass-'+i,status:'PASS'})),
   ...FAILURES.map(name=>({name,status:'FAIL',reason:'synthetic counterexample'}))],
  expectedOutstanding:[...FAILURES],economicPromotions:0,independentRetailHoldouts:0,
  verdict:'FAIL_F003_ARRAY_SNAPSHOT_INTEGRITY'});
 assert.equal(validateReport(JSON.stringify(make()),1).nativeFailed,2);
 const good=make();good.tests.slice(19).forEach(x=>{x.status='PASS';delete x.reason;});
 good.passed=21;good.failed=0;good.verdict='CONDITIONAL_PASS_SYNTHETIC_ONLY';
 assert.equal(validateReport(JSON.stringify(good),0).nativePassed,21);
 const edits=[x=>x.assertions=20,x=>x.passed=20,x=>x.failed=1,
  x=>x.frontierGitBlob='0'.repeat(40),x=>x.stageGitBlob='0'.repeat(40),
  x=>x.expectedOutstanding=[],x=>x.economicPromotions=1,
  x=>x.independentRetailHoldouts=1,x=>x.tests.pop(),
  x=>x.tests[0].name=x.tests[1].name,x=>x.tests[19].status='PASS',
  x=>x.tests[19].reason='',x=>x.tests[19].name='new failure',
  x=>x.verdict='CONDITIONAL_PASS_SYNTHETIC_ONLY'];
 let rejected=0;for(const edit of edits){const x=make();edit(x);
  assert.throws(()=>validateReport(JSON.stringify(x),1));rejected++;}
 assert.throws(()=>validateReport(JSON.stringify(make()),0));rejected++;
 assert.throws(()=>validateReport('not json',1));rejected++;
 const tmp=fs.mkdtempSync(path.join(require('node:os').tmpdir(),'ll-df-frontier-f002-'));
 try{
  fs.writeFileSync(path.join(tmp,'x'),'safe');
  assert.equal(Object.keys(verifyPins(tmp,{x:blobSHA(Buffer.from('safe'))})).length,1);
  fs.writeFileSync(path.join(tmp,'x'),'changed');
  assert.throws(()=>verifyPins(tmp,{x:blobSHA(Buffer.from('safe'))}),/SOURCE_PIN_MISMATCH/);
  assert.throws(()=>verifyPins(tmp,{x:'invalid'}),/INVALID_PIN/);
  assert.throws(()=>verifyPins(tmp,{'../escape':'0'.repeat(40)}),/PATH_ESCAPE/);
 }finally{fs.rmSync(tmp,{recursive:true,force:true});}
 return {status:'PASS',knownDefects:2,adversarialReportsRejected:rejected,pinChecks:4};
}
function run(){
 const sourcePins=verifyPins();
 const child=spawnSync(process.execPath,[path.join(ROOT,SUITE)],{
  cwd:ROOT,encoding:'utf8',timeout:120000,maxBuffer:8*1024*1024});
 if(child.error||child.signal||![0,1].includes(child.status))
  throw Error('NATIVE_F005_EXECUTION_ERROR:'+String(child.error||child.signal||child.status));
 let report;
 try{report=validateReport(child.stdout,child.status);}
 catch(e){
  if(String(e.message).startsWith('PARTIAL_OR_NEW_FAILURE_REQUIRES_F005_REVIEW:')){
   // Expose which exact pinned predecessor assertion is stale; never patch F005
   // or reclassify a failed assertion as passing in this engineer-owned runner.
   const previous=require(path.join(ROOT,'research/tests/v2/test_f005_df_prismatic_stage_identity_20261030.js')).run();
   const failed=previous.tests.filter(t=>t.status==='FAIL');
   throw Error(e.message+'; PREDECESSOR_STAGE_QA='+JSON.stringify({
    passed:previous.passed,failed:previous.failed,failures:failed}));
  }
  throw e;
 }
 return {runType:'INFORMATIONAL_NEGATIVE_QA_NOT_ECONOMIC_ACCEPTANCE',
  node:process.version,sourcePins,...report,
  mappingChanges:0,workingCellsFilled:0,newEvidenceExpectedQuantityCells:0,
  confidencePromotions:0,economicPromotions:0,liveEVChanged:false};
}
if(require.main===module){try{console.log(JSON.stringify(process.argv.includes('--self-test')?selfTest():run()));}
 catch(e){console.error('F002 DF frontier native preflight FAIL: '+e.message);process.exitCode=1;}}
module.exports={PINS,FAILURES,blobSHA,verifyPins,validateReport,selfTest,run};
