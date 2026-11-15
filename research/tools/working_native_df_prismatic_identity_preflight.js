'use strict';
// F002 research-only native replay of F005's Dragonflight Prismatic stage-identity
// suite. The repaired identity does not establish current-Retail applicability.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const {spawnSync}=require('node:child_process');
const ROOT=path.resolve(__dirname,'../..');
const MODEL='research/tools/models_v2/df_historical_diamond_denominator_stage_guard_v1.js';
const MANIFEST='research/models/v2/df_historical_diamond_denominator_stage_guard_v1.json';
const SUITE='research/tests/v2/test_f005_df_prismatic_stage_identity_20261030.js';
const OLD='research/evidence/v2/2026-10-30T2028Z-F004-df-two-stage-diamond-denominators.json';
const CORRECTION='research/evidence/v2/2026-10-30T2130Z-F004-df-prismatic-identity-and-primary-ore-cohorts.json';
const REVIEW='research/coordination/v2/reviews/20261030T2140Z-F005-df-prismatic-stage-identity.json';
const REPAIR_REVIEW='research/coordination/v2/reviews/20261030T2340Z-F005-frontier-repair-array-length-and-prismatic-qa.json';
const PINS=Object.freeze({
 [MODEL]:'2c9005e1d7be6df68d5631a418fbae95a144f6e7',
 [MANIFEST]:'8ed83117c738ed83ff418de4a677c31505d0e028',
 [SUITE]:'4f546a33559a9e8202c1c846d7bbfe91c9f8503c',
 [OLD]:'321dc050134de6a996e5978b87cf467516c4cb06',
 [CORRECTION]:'d31529efc7f6d2630bb399daa10740fbdbcf0e74',
 'research/evidence/v2/source-reviews/2026-10-30T2130Z-F004-df-prismatic-identity-and-primary-ore-cohorts-source-review.json':'89fd690a4dd386b746295c0e6318af86e53250de',
 [REVIEW]:'a48759080a362596293818abd019e973891e0fe7',
 [REPAIR_REVIEW]:'842fe7507e2f093fd307943d138f5a47c6b019b5'
});
const REPAIRED_ASSERTIONS=Object.freeze([
 'model source second-stage input uses corrected 194545',
 'model analyze second-stage input uses corrected 194545',
 'model manifest second-stage label uses corrected 194545'
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
  if(!real.startsWith(base+path.sep)||!fs.statSync(real).isFile())throw Error('UNSAFE_PATH:'+relative);
  const actual=gitBlobSHA(fs.readFileSync(real));
  if(actual!==expected)throw Error('SOURCE_PIN_MISMATCH:'+relative+':'+actual);
  result[relative]=actual;
 }
 return result;
}
function validateReport(output,exitCode){
 let r;
 try{r=JSON.parse(output.trim());}catch(_){throw Error('INVALID_F005_JSON');}
 if(!r||r.suite!=='F005_DF_PRISMATIC_STAGE_IDENTITY'||
    r.passed!==43||r.failed!==0||r.verdict!=='CONDITIONAL_PASS_NO_CURRENT_RETAIL_HOLDOUT'||
    exitCode!==0||!Array.isArray(r.tests)||r.tests.length!==43)
  throw Error('F005_REPAIR_REPLAY_COUNTS_OR_EXIT_DRIFT');
 const names=new Set();
 for(const t of r.tests){
  if(!t||typeof t.name!=='string'||!t.name||names.has(t.name)||t.status!=='PASS')
   throw Error('F005_TEST_IDENTITY_OR_STATUS_DRIFT');
  names.add(t.name);
 }
 if(REPAIRED_ASSERTIONS.some(n=>!names.has(n))||
    !Array.isArray(r.limitations)||!r.limitations.includes('No independently verified current-Retail casts'))
  throw Error('F005_IDENTITY_REPAIR_OR_HOLDOUT_CLAIM_DRIFT');
 return {nativePassed:43,nativeFailed:0,modelAccepted:false,independentRetailHoldouts:0};
}
function checkSourcePolicy(){
 const model=require(path.join(ROOT,MODEL));
 const manifest=JSON.parse(fs.readFileSync(path.join(ROOT,MANIFEST),'utf8'));
 const old=JSON.parse(fs.readFileSync(path.join(ROOT,OLD),'utf8'));
 const correction=JSON.parse(fs.readFileSync(path.join(ROOT,CORRECTION),'utf8'));
 const qa=JSON.parse(fs.readFileSync(path.join(ROOT,REVIEW),'utf8'));
 const repair=JSON.parse(fs.readFileSync(path.join(ROOT,REPAIR_REVIEW),'utf8'));
 const self=model.selfTest(),analysis=model.analyze();
 if(self.passed!==28||self.failed!==0||self.syntheticOnly!==true||
    model.POLICY.confidence!==0||model.POLICY.economicUse!=='PREVIEW_ONLY'||
    model.POLICY.normalizedVerified!==false||model.POLICY.liveEconomicEligible!==false||
    analysis.perCastExpectedQuantity!==undefined||
    analysis.secondStage.perCastExpectedQuantity!==null||
    analysis.confidence!==0||analysis.economicUse!=='PREVIEW_ONLY'||
    analysis.normalizedVerified!==false||analysis.liveEconomicEligible!==false)
  throw Error('MODEL_SELF_TEST_OR_ECONOMIC_ISOLATION_DRIFT');
 const oldCohort=old.cohorts.find(x=>x.id==='B-prismatic-1000');
 const c=correction.sourceIdentityCorrection;
 if(!oldCohort||oldCohort.inputItemID!==192880||
    c.priorValue!==192880||c.proposedValue!==194545||
    c.priorImmutableEvidencePath!==OLD||manifest.sourceEvidence!==OLD||
    manifest.modelCodeBlobSHA!==PINS[MODEL]||manifest.sourceIdentityCorrection!==CORRECTION||
    analysis.secondStage.inputItemID!==c.proposedValue||
    qa.status!=='FAIL_MODEL_IDENTITY_REPAIR_REQUIRED'||qa.executed.passed!==40||qa.executed.failed!==3||
    repair.status!=='FAIL_F003_FRONTIER_ARRAY_SNAPSHOT__CONDITIONAL_PASS_PRISMATIC_IDENTITY'||
    repair.sourcePins.stageModel!==PINS[MODEL]||repair.sourcePins.stageManifest!==PINS[MANIFEST])
  throw Error('SOURCE_CORRECTION_OR_F005_VERDICT_DRIFT');
 return {modelSelfTestsPassed:28,originalEvidenceItemID:192880,
   correctPrismaticOreItemID:194545,reviewVerdict:'CONDITIONAL_PASS_PRISMATIC_IDENTITY',economicPromotion:false};
}
function selfTest(){
 const assert=require('node:assert/strict');
 const make=()=>{
  const tests=Array.from({length:40},(_,i)=>({name:'passing-'+i,status:'PASS'}));
  for(const name of REPAIRED_ASSERTIONS)tests.push({name,status:'PASS'});
  return {suite:'F005_DF_PRISMATIC_STAGE_IDENTITY',passed:43,failed:0,
   tests,verdict:'CONDITIONAL_PASS_NO_CURRENT_RETAIL_HOLDOUT',
   limitations:['No independently verified current-Retail casts']};
 };
 assert.equal(gitBlobSHA(Buffer.from('hello')),'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0');
 assert.equal(validateReport(JSON.stringify(make()),0).nativePassed,43);
 const edits=[
  x=>x.passed=40,x=>x.failed=3,x=>x.verdict='FAIL_MODEL_IDENTITY',
  x=>x.tests[40].status='FAIL',x=>x.tests[40].name='missing identity assertion',
  x=>x.tests[0].name=x.tests[1].name,x=>x.tests.pop(),
  x=>x.tests[40].name='',x=>x.limitations=[],
  x=>x.suite='OTHER',x=>x.tests[0].status='UNKNOWN'
 ];
 let rejected=0;
 for(const edit of edits){const x=make();edit(x);assert.throws(()=>validateReport(JSON.stringify(x),0));rejected++;}
 assert.throws(()=>validateReport(JSON.stringify(make()),1));rejected++;
 assert.throws(()=>validateReport('invalid json',0));rejected++;
 const temp=fs.mkdtempSync(path.join(require('node:os').tmpdir(),'ll-prismatic-f002-'));
 try{
  fs.writeFileSync(path.join(temp,'x'),'safe');
  const good={x:gitBlobSHA(Buffer.from('safe'))};
  assert.equal(Object.keys(verifyPins(temp,good)).length,1);
  fs.writeFileSync(path.join(temp,'x'),'unsafe');
  assert.throws(()=>verifyPins(temp,good),/SOURCE_PIN_MISMATCH/);
  assert.throws(()=>verifyPins(temp,{x:'invalid'}),/INVALID_PIN/);
  assert.throws(()=>verifyPins(temp,{'../outside':'0'.repeat(40)}),/PATH_ESCAPE/);
 }finally{fs.rmSync(temp,{recursive:true,force:true});}
 return {status:'PASS',invalidReplayReportsRejected:rejected,pinMutationChecks:4,
  expectedIndependentCases:43,
  independentAcceptance:false};
}
function run(){
 const sourcePins=verifyPins(),sourcePolicy=checkSourcePolicy();
 const child=spawnSync(process.execPath,[path.join(ROOT,SUITE)],{
  cwd:ROOT,encoding:'utf8',timeout:120000,maxBuffer:8*1024*1024});
 if(child.error||child.signal)throw Error('NATIVE_F005_EXECUTION_ERROR:'+String(child.error||child.signal));
 const result=validateReport(child.stdout,child.status);
 return {status:'NATIVE_CONDITIONAL_PASS_NO_CURRENT_RETAIL_HOLDOUT',
  runType:'INFORMATIONAL_IDENTITY_QA_NOT_ECONOMIC_ACCEPTANCE',node:process.version,
  sourcePins,sourcePolicy,...result,
  admittedMappingsChanged:0,workingNumericCellsChanged:0,
  newVerifiedExpectedQuantityCells:0,confidencePromotions:0,economicPromotions:0,
  liveEVChanged:false,tooltipOnlyChanged:false};
}
if(require.main===module){
 try{console.log(JSON.stringify(process.argv.includes('--self-test')?selfTest():run()));}
 catch(e){console.error('F002 DF Prismatic identity replay FAIL: '+e.message);process.exitCode=1;}
}
module.exports={PINS,gitBlobSHA,verifyPins,validateReport,checkSourcePolicy,selfTest,run};
