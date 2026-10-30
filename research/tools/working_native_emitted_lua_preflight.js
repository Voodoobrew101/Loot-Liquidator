'use strict';
// F002 native replay of F005's independently authored emitted-Lua isolation
// fixture. Research-only: native execution is not independent F005 acceptance.
const fs=require('node:fs');
const path=require('node:path');
const os=require('node:os');
const crypto=require('node:crypto');
const {spawnSync}=require('node:child_process');
const ROOT=path.resolve(__dirname,'../..');
const PINS=Object.freeze({
  'research/proposed/itemdb.lua':'560b885a0039045419c340716e263ae33ddf827a',
  'research/tests/v2/test_f005_emitted_working_lua_channel_isolation.js':'78a9d35a1c667b039911e7a8950be21ef34dff8c'
});
const FIELDS=['dropChance','yieldMin','yieldMax','expectedQuantity'];
const EXPECTED=Object.freeze({
  prior:{dropChance:995,yieldMin:105,yieldMax:105,expectedQuantity:941},
  copied:{dropChance:23,yieldMin:913,yieldMax:913,expectedQuantity:77}
});
function gitBlobSHA(bytes){
  return crypto.createHash('sha1').update('blob '+bytes.length+'\0').update(bytes).digest('hex');
}
function verifyPins(root=ROOT,pins=PINS){
  const base=fs.realpathSync(root), hashes={};
  for(const [relative,expected] of Object.entries(pins)){
    if(!/^[a-f0-9]{40}$/.test(expected))throw Error('INVALID_PIN:'+relative);
    const absolute=path.resolve(root,relative);
    if(!absolute.startsWith(path.resolve(root)+path.sep))throw Error('PATH_ESCAPE:'+relative);
    const real=fs.realpathSync(absolute);
    if(!real.startsWith(base+path.sep))throw Error('SYMLINK_ESCAPE:'+relative);
    if(!fs.statSync(real).isFile())throw Error('NOT_FILE:'+relative);
    const actual=gitBlobSHA(fs.readFileSync(real));
    if(actual!==expected)throw Error('SOURCE_PIN_MISMATCH:'+relative+':'+actual);
    hashes[relative]=actual;
  }
  return hashes;
}
function validateOutput(output){
  let o;
  try{o=JSON.parse(output.trim());}catch(_){throw Error('INVALID_F005_JSON');}
  if(!o||o.suite!=='F005_EMITTED_WORKING_LUA_CHANNEL_ISOLATION'||
     o.sourceBlobSHA!==PINS['research/proposed/itemdb.lua']||
     o.checks!==18320||o.records!==1018||o.workingNumericCells!==4072||
     o.tooltipRecords!==1||o.mutantsRejected!==12||
     o.economicPromotions!==0||o.independentRetailCasts!==0)
    throw Error('UNEXPECTED_F005_EMITTED_LUA_REPORT');
  for(const channel of ['prior','copied']){
    if(!o[channel]||Object.keys(o[channel]).sort().join(',')!==FIELDS.slice().sort().join(','))
      throw Error('UNEXPECTED_F005_FIELD_KEYS:'+channel);
    for(const field of FIELDS){
      if(o[channel][field]!==EXPECTED[channel][field])
        throw Error('UNEXPECTED_F005_FIELD_COUNT:'+channel+':'+field);
    }
  }
  for(const field of FIELDS)
    if(o.prior[field]+o.copied[field]!==o.records)
      throw Error('F005_FIELD_PARTITION_MISMATCH:'+field);
  return {assertionsPassed:o.checks,mutantsRejected:o.mutantsRejected,
    admittedMappings:o.records,workingNumericFields:o.workingNumericCells,
    policyPriorCounts:o.prior,copiedEvidenceCounts:o.copied,
    tooltipOnlyRecords:o.tooltipRecords,economicPromotions:0};
}
function selfTest(){
  const assert=require('node:assert/strict');
  const good={suite:'F005_EMITTED_WORKING_LUA_CHANNEL_ISOLATION',
    sourceBlobSHA:PINS['research/proposed/itemdb.lua'],checks:18320,
    records:1018,workingNumericCells:4072,tooltipRecords:1,
    mutantsRejected:12,economicPromotions:0,independentRetailCasts:0,
    prior:{...EXPECTED.prior},copied:{...EXPECTED.copied}};
  validateOutput(JSON.stringify(good));
  const edits=[
    x=>x.checks--,x=>x.records--,x=>x.workingNumericCells--,
    x=>x.mutantsRejected--,x=>x.economicPromotions++,
    x=>x.independentRetailCasts++,x=>x.tooltipRecords++,
    x=>x.sourceBlobSHA='0'.repeat(40),
    x=>x.prior.dropChance--,x=>x.copied.expectedQuantity++,
    x=>x.prior.extra=1,x=>delete x.copied.yieldMin
  ];
  let rejected=0;
  for(const edit of edits){
    const x=JSON.parse(JSON.stringify(good));edit(x);
    try{validateOutput(JSON.stringify(x));}catch(_){rejected++;}
  }
  try{validateOutput('not json');}catch(_){rejected++;}
  assert.equal(rejected,13,'Report mutations must fail closed');
  assert.equal(gitBlobSHA(Buffer.from('hello')),'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0');
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),'ll-f002-emitted-lua-'));
  try{
    const a='candidate.lua',b='fixture.js';
    fs.writeFileSync(path.join(dir,a),'original');
    fs.writeFileSync(path.join(dir,b),'fixture');
    const pins={[a]:gitBlobSHA(Buffer.from('original')),[b]:gitBlobSHA(Buffer.from('fixture'))};
    assert.equal(Object.keys(verifyPins(dir,pins)).length,2);
    fs.writeFileSync(path.join(dir,a),'tampered');
    assert.throws(()=>verifyPins(dir,pins),/SOURCE_PIN_MISMATCH/);
    fs.writeFileSync(path.join(dir,a),'original');
    assert.throws(()=>verifyPins(dir,{[a]:'invalid'}),/INVALID_PIN/);
    assert.throws(()=>verifyPins(dir,{'../outside':'0'.repeat(40)}),/PATH_ESCAPE/);
  }finally{fs.rmSync(dir,{recursive:true,force:true});}
  return {status:'PASS',reportMutationsRejected:13,pinChecks:5};
}
function run(){
  const hashes=verifyPins();
  const fixture=path.join(ROOT,'research/tests/v2/test_f005_emitted_working_lua_channel_isolation.js');
  const child=spawnSync(process.execPath,[fixture],{
    cwd:ROOT,encoding:'utf8',timeout:120000,maxBuffer:8*1024*1024
  });
  if(child.error||child.signal||child.status!==0)
    throw Error('F005_NATIVE_EMITTED_LUA_FAILED:'+String(child.error||child.signal||child.status)+
      '\n'+(child.stdout||'')+'\n'+(child.stderr||''));
  return {status:'NATIVE_EMITTED_LUA_REPLAY_INFORMATIONAL_PENDING_F005_NATIVE_ACCEPTANCE',
    node:process.version,sourceBlobPins:hashes,...validateOutput(child.stdout),
    liveEVChanged:false,normalizedVerified:false,economicUse:'PREVIEW_ONLY',
    currentRetailEligibilityVerified:false};
}
if(require.main===module){
  try{console.log(JSON.stringify(process.argv.includes('--self-test')?selfTest():run()));}
  catch(e){console.error('F002 emitted-Lua native preflight FAIL: '+e.message);process.exitCode=1;}
}
module.exports={PINS,gitBlobSHA,verifyPins,validateOutput,selfTest,run};
