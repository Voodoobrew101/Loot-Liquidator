'use strict';
// F002 research-only native replay of the F005 independently authored direct
// ORIGINAL compact Lua source test. No derived reconciliation JSON is used
// as test input. Native success is not independent-validator acceptance.
const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const {spawnSync}=require('node:child_process');
const ROOT=path.resolve(__dirname,'../..');
const PINS=Object.freeze({
  old:'a838d75e82239339bea3861692291b44bd085662',
  new:'560b885a0039045419c340716e263ae33ddf827a',
  test:'fee8e048406827478cb261b10ca6843422470b5f'
});
const NEW='research/proposed/itemdb.lua';
const TEST='research/tests/v2/test_f005_v02_v08_direct_lua_identity_reparse.js';
const EXPECTED_SUCCESSORS=Object.freeze([
  'tsm:prospect:188658:192869:L1204',
  'tsm:prospect:189143:192869:L1242',
  'tsm:prospect:190311:192869:L1280'
]);
function gitBlobSHA(bytes){
  return crypto.createHash('sha1').update(Buffer.from('blob '+bytes.length+'\0')).update(bytes).digest('hex');
}
function verifyFile(file,expected){
  if(!/^[a-f0-9]{40}$/.test(expected))throw Error('INVALID_PIN');
  const stat=fs.statSync(file);
  if(!stat.isFile()||stat.size===0)throw Error('NOT_NONEMPTY_FILE: '+file);
  const actual=gitBlobSHA(fs.readFileSync(file));
  if(actual!==expected)throw Error('SOURCE_PIN_MISMATCH: '+file+' '+actual);
  return actual;
}
function validateOutput(output){
  let o;
  try{o=JSON.parse(output.trim());}catch(_){throw Error('INVALID_TEST_JSON');}
  const eq=(a,b)=>JSON.stringify(a)===JSON.stringify(b);
  if(!o||o.checks!==180||o.oldRecords!==976||o.newRecords!==1018||
     o.retired!==3||o.added!==45||o.oldNumeric!==3610||o.newNumeric!==3558||
     o.fishRankChanges!==12||o.mutantsRejected!==14||
     !eq(o.fieldQuarantines,[49,0,0,55])||
     !eq(o.nonEquivalentPairs,EXPECTED_SUCCESSORS))
    throw Error('UNEXPECTED_DIRECT_SOURCE_TEST_RESULT');
  return {assertionsPassed:o.checks,mutantsRejected:o.mutantsRejected,
    oldRecords:o.oldRecords,newRecords:o.newRecords,added:o.added,retired:o.retired,
    quarantinedEvidenceFields:104,fishInputRankUnknown:12,
    nonEquivalentSuccessors:o.nonEquivalentPairs};
}
function selfTest(){
  if(gitBlobSHA(Buffer.from('hello'))!=='b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0')
    throw Error('GIT_BLOB_HASH');
  const good={checks:180,oldRecords:976,newRecords:1018,retired:3,added:45,
    oldNumeric:3610,newNumeric:3558,fishRankChanges:12,mutantsRejected:14,
    fieldQuarantines:[49,0,0,55],nonEquivalentPairs:[...EXPECTED_SUCCESSORS]};
  validateOutput(JSON.stringify(good));
  const edits=[
    o=>o.checks--,o=>o.oldRecords--,o=>o.newRecords--,
    o=>o.fieldQuarantines[0]--,o=>o.fieldQuarantines[3]--,
    o=>o.nonEquivalentPairs.pop(),o=>o.nonEquivalentPairs.reverse(),
    o=>o.fishRankChanges--,o=>o.mutantsRejected--,
    o=>o.newNumeric++,o=>o.added--
  ];
  let rejected=0;
  for(const edit of edits){
    const x=JSON.parse(JSON.stringify(good));edit(x);
    try{validateOutput(JSON.stringify(x));}catch(_){rejected++;}
  }
  try{validateOutput('not-json');}catch(_){rejected++;}
  if(rejected!==12)throw Error('REPORT_FAIL_CLOSED: '+rejected);
  return {status:'PASS',checks:14,mutantReportsRejected:12};
}
function run(oldPath){
  if(!oldPath)throw Error('PINNED_V02_SOURCE_PATH_REQUIRED');
  const old=path.resolve(oldPath),next=path.join(ROOT,NEW),test=path.join(ROOT,TEST);
  const hashes={old:verifyFile(old,PINS.old),new:verifyFile(next,PINS.new),
    test:verifyFile(test,PINS.test)};
  const child=spawnSync(process.execPath,[test,old,next],
    {cwd:ROOT,encoding:'utf8',timeout:90000,maxBuffer:8*1024*1024});
  if(child.error||child.status!==0||child.signal)
    throw Error('F005_NATIVE_DIRECT_REPARSE_FAILED: '+String(child.error||child.signal||child.status)+
      '\n'+(child.stdout||'')+'\n'+(child.stderr||''));
  return {status:'NATIVE_DIRECT_ORIGINAL_LUA_REPARSE_INFORMATIONAL_PENDING_F005_ACCEPTANCE',
    node:process.version,sourceBlobPins:hashes,...validateOutput(child.stdout),
    currentRetailEligibilityVerified:false,independentRetailCastFamilies:0,
    newEvidenceExpectedQuantityCells:0,confidencePromotions:0,economicPromotions:0,
    liveEVChanged:false,economicUse:'PREVIEW_ONLY',normalizedVerified:false};
}
if(require.main===module){
  try{console.log(JSON.stringify(process.argv.includes('--self-test')?selfTest():run(process.argv[2])));}
  catch(e){console.error('F002 native direct Lua preflight FAIL: '+e.message);process.exitCode=1;}
}
module.exports={PINS,EXPECTED_SUCCESSORS,gitBlobSHA,verifyFile,validateOutput,selfTest,run};
