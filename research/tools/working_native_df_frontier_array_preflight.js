'use strict';
// Native regression for the Frontier repair. F005's original fixture and review
// stay pinned to the historical candidate they evaluated.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const {spawnSync}=require('node:child_process');
const assert=require('node:assert/strict');
const ROOT=path.resolve(__dirname,'../..');
const MODEL='research/tools/models_v2/df_prospect_decision_frontier_v1.js';
const MANIFEST='research/models/v2/df_prospect_decision_frontier_v1.json';
const STAGE='research/tools/models_v2/df_historical_diamond_denominator_stage_guard_v1.js';
const SUITE='research/tests/test_df_frontier_array_repair.js';
const SUITE_ID='DF_FRONTIER_ARRAY_REPAIR_REGRESSION';
const CASES=23;
const PINS=Object.freeze({
 [MODEL]:'6ed12499bb287e684a4e7b2831e7eca1a61513f6',
 [MANIFEST]:'cb15082f324bc5ec1435e01f23df0dad6ee1a76a',
 [STAGE]:'2c9005e1d7be6df68d5631a418fbae95a144f6e7',
 [SUITE]:'7f2716da47c171818dd9fd4fd904035383929cbd',
 'research/tests/v2/test_f005_df_frontier_v101_array_snapshot_repair_20261030.js':'14ad7d0693ee9e1bda43b7352854188972a8fb8d',
 'research/tests/v2/test_f005_df_prospect_frontier_v1_context_attestation_20261030.js':'bbb4c309a98e5a14dd8f15ae5225703a828cbad8',
 'research/tests/v2/test_f005_df_prismatic_stage_identity_20261030.js':'4f546a33559a9e8202c1c846d7bbfe91c9f8503c',
 'research/coordination/v2/reviews/20261030T2340Z-F005-frontier-repair-array-length-and-prismatic-qa.json':'842fe7507e2f093fd307943d138f5a47c6b019b5'
});
const REPAIR_ASSERTIONS=Object.freeze([
 'previous Prismatic identity 43-case repair',
 'reject output array length shrink 1 to 0 after dense validation',
 'reject output array length shrink 2 to 1 after dense validation',
 'reject a nested record proxy before it can replace a later output',
 'reject a scenario record proxy before it can modify its output'
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
 let r;try{r=JSON.parse(raw.trim());}catch(_){throw Error('INVALID_FRONTIER_REGRESSION_JSON');}
 if(!r||r.suite!==SUITE_ID||
  r.frontierGitBlob!==PINS[MODEL]||r.stageGitBlob!==PINS[STAGE]||
  r.assertions!==CASES||r.passed!==CASES||r.failed!==0||exitCode!==0||
  r.verdict!=='PASS_SYNTHETIC_REGRESSION'||!Array.isArray(r.tests)||r.tests.length!==CASES||
  r.economicPromotions!==0||r.independentRetailHoldouts!==0){
  const failed=Array.isArray(r?.tests)?r.tests.filter(t=>t?.status==='FAIL').map(t=>t.name):[];
  throw Error('FRONTIER_REGRESSION_FAILED:'+failed.join('|'));
 }
 const seen=new Set();
 for(const t of r.tests){
  if(!t||typeof t.name!=='string'||!t.name||seen.has(t.name)||
   t.status!=='PASS')throw Error('FRONTIER_TEST_IDENTITY_DRIFT');
  seen.add(t.name);
 }
 if(REPAIR_ASSERTIONS.some(n=>!seen.has(n)))throw Error('FRONTIER_REPAIR_ASSERTION_MISSING');
 return {status:'AUTHOR_REGRESSION_PASS',nativePassed:CASES,nativeFailed:0,
  failedAssertions:[],modelAccepted:false};
}
function selfTest(){
 assert.equal(blobSHA(Buffer.from('hello')),'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0');
 const make=()=>({suite:SUITE_ID,
  frontierGitBlob:PINS[MODEL],stageGitBlob:PINS[STAGE],assertions:CASES,
  passed:CASES,failed:0,tests:[...Array.from({length:CASES-REPAIR_ASSERTIONS.length},(_,i)=>({name:'pass-'+i,status:'PASS'})),
   ...REPAIR_ASSERTIONS.map(name=>({name,status:'PASS'}))],
  economicPromotions:0,independentRetailHoldouts:0,verdict:'PASS_SYNTHETIC_REGRESSION'});
 assert.equal(validateReport(JSON.stringify(make()),0).nativePassed,CASES);
 const edits=[x=>x.assertions=CASES-1,x=>x.passed=CASES-1,x=>x.failed=1,
  x=>x.frontierGitBlob='0'.repeat(40),x=>x.stageGitBlob='0'.repeat(40),
  x=>x.economicPromotions=1,
  x=>x.independentRetailHoldouts=1,x=>x.tests.pop(),
  x=>x.tests[0].name=x.tests[1].name,x=>x.tests.at(-1).status='FAIL',
  x=>x.tests.at(-1).name='missing repaired assertion',x=>x.tests.at(-1).name='',
  x=>x.verdict='FAIL_ARRAY_SNAPSHOT_INTEGRITY'];
 let rejected=0;for(const edit of edits){const x=make();edit(x);
  assert.throws(()=>validateReport(JSON.stringify(x),0));rejected++;}
 assert.throws(()=>validateReport(JSON.stringify(make()),1));rejected++;
 assert.throws(()=>validateReport('not json',0));rejected++;
 const tmp=fs.mkdtempSync(path.join(require('node:os').tmpdir(),'ll-df-frontier-f002-'));
 try{
  fs.writeFileSync(path.join(tmp,'x'),'safe');
  assert.equal(Object.keys(verifyPins(tmp,{x:blobSHA(Buffer.from('safe'))})).length,1);
  fs.writeFileSync(path.join(tmp,'x'),'changed');
  assert.throws(()=>verifyPins(tmp,{x:blobSHA(Buffer.from('safe'))}),/SOURCE_PIN_MISMATCH/);
  assert.throws(()=>verifyPins(tmp,{x:'invalid'}),/INVALID_PIN/);
  assert.throws(()=>verifyPins(tmp,{'../escape':'0'.repeat(40)}),/PATH_ESCAPE/);
 }finally{fs.rmSync(tmp,{recursive:true,force:true});}
 return {status:'PASS',expectedRepairCases:CASES,adversarialReportsRejected:rejected,pinChecks:4};
}
function run(){
 const sourcePins=verifyPins();
 const manifest=JSON.parse(fs.readFileSync(path.join(ROOT,MANIFEST),'utf8'));
 if(manifest.modelCodeBlobSHA!==sourcePins[MODEL])throw Error('MODEL_MANIFEST_PIN_MISMATCH');
 const child=spawnSync(process.execPath,[path.join(ROOT,SUITE)],{
  cwd:ROOT,encoding:'utf8',timeout:120000,maxBuffer:8*1024*1024});
 if(child.error||child.signal||![0,1].includes(child.status))
  throw Error('FRONTIER_REGRESSION_EXECUTION_ERROR:'+String(child.error||child.signal||child.status));
 const report=validateReport(child.stdout,child.status);
 return {runType:'INFORMATIONAL_ARRAY_REPAIR_QA_NOT_ECONOMIC_ACCEPTANCE',
  node:process.version,sourcePins,...report,
  mappingChanges:0,workingCellsFilled:0,newEvidenceExpectedQuantityCells:0,
  confidencePromotions:0,economicPromotions:0,liveEVChanged:false};
}
if(require.main===module){try{console.log(JSON.stringify(process.argv.includes('--self-test')?selfTest():run()));}
 catch(e){console.error('F002 DF frontier native preflight FAIL: '+e.message);process.exitCode=1;}}
module.exports={PINS,blobSHA,verifyPins,validateReport,selfTest,run};
