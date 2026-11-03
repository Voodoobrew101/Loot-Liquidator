'use strict';
// F002 research-only native replay of F005's cross-version reconciliation test.
// Informational until F005 independently accepts it. Derived report is NOT
// an independent reparse of the two historical compact Lua sources.
const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const {spawnSync}=require('node:child_process');
const ROOT=path.resolve(__dirname,'../..');
const PINS=Object.freeze({
  'research/tests/v2/test_f005_v02_v08_reconciliation_integrity.js':'d38b5f662c607a1f5553ee3e4440081cbb396cd9',
  'research/proposed/itemdb-v02-v08-field-reconciliation.json':'f951706c3602baf07bfa3f88311304d16067be3a',
  'research/proposed/itemdb.lua':'560b885a0039045419c340716e263ae33ddf827a'
});
function gitBlobSHA(bytes){
  return crypto.createHash('sha1').update(Buffer.from('blob '+bytes.length+'\0')).update(bytes).digest('hex');
}
function verifyPins(root=ROOT,pins=PINS){
  const base=fs.realpathSync(root);
  for(const [relative,expected] of Object.entries(pins)){
    if(!/^[a-f0-9]{40}$/.test(expected))throw Error('INVALID_PIN: '+relative);
    const abs=path.resolve(root,relative);
    if(!abs.startsWith(path.resolve(root)+path.sep))throw Error('PATH_ESCAPE: '+relative);
    const real=fs.realpathSync(abs);
    if(!real.startsWith(base+path.sep))throw Error('SYMLINK_ESCAPE: '+relative);
    if(gitBlobSHA(fs.readFileSync(real))!==expected)throw Error('PIN_MISMATCH: '+relative);
  }
  return Object.keys(pins).length;
}
function validateOutput(output){
  let result;
  try{result=JSON.parse(output.trim());}catch(_){throw Error('INVALID_TEST_JSON');}
  if(!result||result.checks!==1385||result.quarantinedFields!==104||
     result.addedNumericFields!==58||result.rankChanges!==12||
     result.mutationsRejected!==17||
     !Array.isArray(result.nonEquivalentReplacementPairs)||
     result.nonEquivalentReplacementPairs.length!==3||
     result.nonEquivalentReplacementPairs.some(pair=>!Array.isArray(pair)||pair.length!==2||
       pair.some(id=>typeof id!=='string'||!id)))throw Error('UNEXPECTED_TEST_RESULT');
  return {assertionsPassed:result.checks,mutantsRejected:result.mutationsRejected,
    quarantinedEvidenceFields:result.quarantinedFields,nonEquivalentSuccessorPairs:3};
}
function selfTest(){
  if(gitBlobSHA(Buffer.from('hello'))!=='b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0')throw Error('GIT_BLOB_HASH');
  const good={checks:1385,quarantinedFields:104,addedNumericFields:58,
    rankChanges:12,mutationsRejected:17,nonEquivalentReplacementPairs:[['a','b'],['c','d'],['e','f']]};
  validateOutput(JSON.stringify(good));
  let rejected=0;
  for(const mutate of [
    x=>x.checks--,x=>x.mutationsRejected--,
    x=>x.quarantinedFields--,x=>x.nonEquivalentReplacementPairs.pop(),
    x=>x.nonEquivalentReplacementPairs[0]=['a']
  ]){
    const x=JSON.parse(JSON.stringify(good));mutate(x);
    try{validateOutput(JSON.stringify(x));}catch(_){rejected++;}
  }
  try{validateOutput('not-json');}catch(_){rejected++;}
  if(rejected!==6)throw Error('REPORT_FAIL_CLOSED');
  return {status:'PASS',checks:8,mutantReportsRejected:6};
}
function run(){
  const pinnedFiles=verifyPins();
  const child=spawnSync(process.execPath,
    [path.join(ROOT,'research/tests/v2/test_f005_v02_v08_reconciliation_integrity.js')],
    {cwd:ROOT,encoding:'utf8',timeout:45000,maxBuffer:4*1024*1024});
  if(child.error||child.status!==0||child.signal)
    throw Error('NATIVE_TEST_FAILED: '+String(child.error||child.signal||child.status)+'\n'+
      (child.stdout||'')+'\n'+(child.stderr||''));
  return {status:'INFORMATIONAL_PENDING_INDEPENDENT_NATIVE_ACCEPTANCE',
    node:process.version,pinnedFiles,...validateOutput(child.stdout),
    sourceReparse:'NOT_RUN_DERIVED_DIFF_ONLY',independentRetailCastFamilies:0,
    numericWorkingCellsFilled:0,confidencePromotions:0,economicPromotions:0,
    liveEVChanged:false,normalizedVerified:false,economicUse:'PREVIEW_ONLY'};
}
if(require.main===module){
  try{console.log(JSON.stringify(process.argv.includes('--self-test')?selfTest():run()));}
  catch(e){console.error('F002 cross-version native preflight FAIL: '+e.message);process.exitCode=1;}
}
module.exports={PINS,gitBlobSHA,verifyPins,validateOutput,selfTest,run};
