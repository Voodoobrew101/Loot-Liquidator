'use strict';
// F002: native replay of both independent F005 TWW milling suites.
const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const {spawnSync}=require('node:child_process');
const ROOT=path.resolve(__dirname,'../..');
const MODEL='research/tools/models_v2/tww_mill_reagent_accounting_identification_v1.js';
const MANIFEST='research/models/v2/tww_mill_reagent_accounting_identification_v1.json';
const ACCOUNTING_FIXTURE='research/tests/v2/test_f005_tww_mill_accounting_independent_attestation.js';
const SNAPSHOT_FIXTURE='research/tests/v2/test_f005_tww_mill_v101_snapshot_provenance_20261031.js';
const ACCOUNTING_ORIGINAL_MODEL='75169a9a6f2eb7a3f1c4148e09074fba65d88f4a';
const SNAPSHOT_ORIGINAL_MODEL='5d90046b15046fb210523c34363c66596b962d3d';
const OVERFLOW_TEST='inverse must not return nonfinite conditional mean';
const REJECTED_OVERFLOW='inverse result overflow';
const PINS=Object.freeze({
  [ACCOUNTING_FIXTURE]:'1dc22afeed2eefafd845979fafa15cbb59c15708',
  'research/coordination/v2/reviews/20261030T1845Z-F005-TWW-MILL-ACCOUNTING-INDEPENDENT-ATTESTATION.json':'eea3a0140b78e252f85d5c0f32914118b79d2962',
  [SNAPSHOT_FIXTURE]:'94ea3a1586e986d52d47394745181e8bab3f478e',
  'research/coordination/v2/reviews/20261031T0040Z-F005-TWW-MILL-V101-SNAPSHOT-AND-PROVENANCE.json':'d2432e177ba352d00c5e41466e8e64410316bdd6'
});
const SUITES=Object.freeze([
  {
    name:'37-case accounting suite', fixture:ACCOUNTING_FIXTURE, total:37,
    reportModelSHA:ACCOUNTING_ORIGINAL_MODEL, retailCount:'independentRetailHoldouts',
    knownFailures:[
      'reject contradictory nominal batch in typed context',
      'reject contradictory direct reagent vector in typed context',
      'reject proxy that changes mapping after identity check',
      'reject proxy cap whose units change after validation'
    ]
  },
  {
    name:'15-case snapshot and provenance suite', fixture:SNAPSHOT_FIXTURE, total:15,
    reportModelSHA:SNAPSHOT_ORIGINAL_MODEL, retailCount:'independentlyValidatedRetailStudyFamilies',
    knownFailures:[
      'reject context nominal batch conflicting with accounting batch',
      'reject context reagent vector conflicting with actual batch',
      'reject mutable targetKey after mapping validation',
      'reject mutable saving cap that inflates max casts',
      'reject saving cap status escalation after validation',
      'reject per-cast array length shrinking after structural validation',
      'reject mutable study-family identity after validation',
      'reject mutable patch-epoch identity after validation'
    ]
  }
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
function verifyModelManifest(root=ROOT){
  const manifest=JSON.parse(fs.readFileSync(path.join(root,MANIFEST),'utf8'));
  if(!manifest||manifest.sourcePath!==MODEL||typeof manifest.sourceBlobSHA!=='string'||
     !Number.isSafeInteger(manifest.sourceReadbackLength)||manifest.sourceReadbackLength<=0)
    throw Error('MODEL_MANIFEST_CONTRACT_CHANGED');
  const sourcePins=verifyPins(root,{[MODEL]:manifest.sourceBlobSHA});
  if(fs.statSync(path.join(root,MODEL)).size!==manifest.sourceReadbackLength)
    throw Error('MODEL_SOURCE_LENGTH_MISMATCH');
  return sourcePins[MODEL];
}
function validateReport(suite,output,exitCode,verifiedOverflow){
  let o;
  try{o=JSON.parse(output.trim());}catch(_){throw Error('INVALID_F005_JSON');}
  if(!o||o.modelBlobSHA!==suite.reportModelSHA||o.total!==suite.total||
     !Number.isInteger(o.passed)||o.passed<0||!Number.isInteger(o.failed)||o.failed<0||
     o.passed+o.failed!==suite.total||o.syntheticOnly!==true||o[suite.retailCount]!==0||
     !Array.isArray(o.failures)||o.failures.length!==o.failed||exitCode!==(o.failed?1:0))
    throw Error('F005_RESULT_CONTRACT_CHANGED');
  const names=new Set();
  const failures=[],expectedRejections=[];
  for(const failure of o.failures){
    if(!failure||typeof failure.name!=='string'||names.has(failure.name)||failure.pass!==false)
      throw Error('INVALID_F005_FAILURE:'+JSON.stringify(o.failures));
    names.add(failure.name);
    // The immutable accounting fixture assumes inverse() returns. Its review calls for rejection.
    if(suite.fixture===ACCOUNTING_FIXTURE&&failure.name===OVERFLOW_TEST&&
       failure.error===REJECTED_OVERFLOW&&verifiedOverflow===true){
      expectedRejections.push(failure);
    }else if(suite.knownFailures.includes(failure.name)&&failure.error==='unsafe input accepted'){
      failures.push(failure);
    }else{
      throw Error('UNEXPECTED_F005_FAILURE:'+JSON.stringify(o.failures));
    }
  }
  if(verifiedOverflow&&expectedRejections.length!==1)throw Error('MISSING_F005_OVERFLOW_CASE');
  return {suite:suite.name,fixture:suite.fixture,total:suite.total,
    fixtureReportedModelSHA:o.modelBlobSHA,passed:o.passed+expectedRejections.length,
    failed:failures.length,rawFixturePassed:o.passed,rawFixtureFailed:o.failed,failures,expectedRejections};
}
function selfTest(){
  const assert=require('node:assert/strict');
  assert.equal(gitBlobSHA(Buffer.from('hello')),'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0');
  const make=(suite,failures,verifiedOverflow=false)=>{
    const cases=failures.map(name=>({name,pass:false,error:'unsafe input accepted'}));
    if(verifiedOverflow)cases.push({name:OVERFLOW_TEST,pass:false,error:REJECTED_OVERFLOW});
    return {modelBlobSHA:suite.reportModelSHA,total:suite.total,passed:suite.total-cases.length,
      failed:cases.length,syntheticOnly:true,[suite.retailCount]:0,failures:cases};
  };
  const validate=(suite,report,exitCode,verifiedOverflow)=>
    validateReport(suite,JSON.stringify(report),exitCode,verifiedOverflow);
  let rejected=0;
  for(const suite of SUITES){
    const known=suite.knownFailures,verifiedOverflow=suite.fixture===ACCOUNTING_FIXTURE;
    for(const names of [known,known.slice(1),known.slice(0,1),[]]){
      const report=make(suite,names,verifiedOverflow);
      const result=validate(suite,report,report.failed?1:0,verifiedOverflow);
      assert.equal(result.passed,suite.total-names.length);
      assert.equal(result.failed,names.length);
    }
    const mutations=[
      x=>x.total--,x=>x.syntheticOnly=false,x=>x[suite.retailCount]=1,
      x=>x.modelBlobSHA='0'.repeat(40),x=>x.failed=0,
      x=>x.failures[0].name='unknown failure',x=>x.failures[0].error='unexpected exception',
      x=>x.failures[1].name=x.failures[0].name,x=>x.failures.pop(),
      x=>x.passed++,x=>x.failures[0].pass=true
    ];
    for(const edit of mutations){
      const report=make(suite,known,verifiedOverflow);edit(report);
      assert.throws(()=>validate(suite,report,1,verifiedOverflow));rejected++;
    }
    assert.throws(()=>validate(suite,make(suite,known,verifiedOverflow),0,verifiedOverflow));rejected++;
    assert.throws(()=>validateReport(suite,'not-json',1,verifiedOverflow));rejected++;
  }
  const accounting=SUITES[0];
  const overflow=make(accounting,[],true);
  assert.throws(()=>validate(accounting,overflow,1,false),/UNEXPECTED_F005_FAILURE/);rejected++;
  overflow.failures[0].error='inverse emitted Infinity (JSON serializes as null)';
  assert.throws(()=>validate(accounting,overflow,1,true),/UNEXPECTED_F005_FAILURE/);rejected++;
  assert.throws(()=>validate(accounting,make(accounting,[]),0,true),/MISSING_F005_OVERFLOW_CASE/);rejected++;
  assert.throws(()=>verifyInverseOverflow(()=>({conditionalMean:Infinity})),/MODEL_INVERSE_ACCEPTED_OVERFLOW/);rejected++;
  assert.throws(()=>verifyInverseOverflow(()=>{throw Error('other error');}),/MODEL_INVERSE_REJECTED_UNEXPECTEDLY/);rejected++;
  assert.equal(verifyInverseOverflow(()=>{throw Error(REJECTED_OVERFLOW);}),true);
  const tmp=fs.mkdtempSync(path.join(require('node:os').tmpdir(),'ll-tww-f002-'));
  try{
    fs.writeFileSync(path.join(tmp,'x'),'safe');
    const pins={x:gitBlobSHA(Buffer.from('safe'))};
    assert.equal(Object.keys(verifyPins(tmp,pins)).length,1);
    fs.writeFileSync(path.join(tmp,'x'),'altered');
    assert.throws(()=>verifyPins(tmp,pins),/SOURCE_PIN_MISMATCH/);
    assert.throws(()=>verifyPins(tmp,{x:'invalid'}),/INVALID_PIN/);
    assert.throws(()=>verifyPins(tmp,{'../outside':'0'.repeat(40)}),/PATH_ESCAPE/);
    for(const relative of [MODEL,MANIFEST])fs.mkdirSync(path.dirname(path.join(tmp,relative)),{recursive:true});
    fs.writeFileSync(path.join(tmp,MODEL),'safe');
    const versioned={sourcePath:MODEL,sourceBlobSHA:pins.x,sourceReadbackLength:4};
    const writeManifest=()=>fs.writeFileSync(path.join(tmp,MANIFEST),JSON.stringify(versioned));
    writeManifest();
    assert.equal(verifyModelManifest(tmp),pins.x);
    versioned.sourceReadbackLength=5;writeManifest();
    assert.throws(()=>verifyModelManifest(tmp),/MODEL_SOURCE_LENGTH_MISMATCH/);
    versioned.sourceReadbackLength=4;versioned.sourceBlobSHA='0'.repeat(40);writeManifest();
    assert.throws(()=>verifyModelManifest(tmp),/SOURCE_PIN_MISMATCH/);
    versioned.sourcePath='x';writeManifest();
    assert.throws(()=>verifyModelManifest(tmp),/MODEL_MANIFEST_CONTRACT_CHANGED/);
  }finally{fs.rmSync(tmp,{recursive:true,force:true});}
  return {status:'PASS',suites:2,unexpectedOutcomesRejected:rejected,pinChecks:8};
}
function verifyInverseOverflow(inverse){
  try{inverse(1e308,Number.MIN_VALUE);}
  catch(error){
    if(error.message===REJECTED_OVERFLOW)return true;
    throw Error('MODEL_INVERSE_REJECTED_UNEXPECTEDLY:'+error.message);
  }
  throw Error('MODEL_INVERSE_ACCEPTED_OVERFLOW');
}
function runSuite(suite){
  const fixture=path.join(ROOT,suite.fixture);
  const historicalFixture=suite.fixture===ACCOUNTING_FIXTURE;
  // Each fixture CLI pins its historical model. Run the unmodified exported tests
  // against the live model after checking its current manifest pin.
  const args=['-e',
    'const report=require(process.argv[1]).run(); console.log(JSON.stringify(report)); process.exitCode=report.failed?1:0;',
    fixture];
  const child=spawnSync(process.execPath,args,{cwd:ROOT,encoding:'utf8',timeout:120000,maxBuffer:8*1024*1024});
  if(child.error||child.signal||![0,1].includes(child.status))
    throw Error('NATIVE_F005_EXECUTION_ERROR:'+String(child.error||child.signal||child.status)+'\n'+(child.stderr||''));
  const verifiedOverflow=historicalFixture&&verifyInverseOverflow(require(path.join(ROOT,MODEL)).inverse);
  return validateReport(suite,child.stdout,child.status,verifiedOverflow);
}
function run(){
  const sourceBlobPins=verifyPins();
  const exercisedModelSHA=verifyModelManifest();
  const suites=SUITES.map(suite=>{
    try{return runSuite(suite);}
    catch(error){return {suite:suite.name,fixture:suite.fixture,total:suite.total,unexpectedFailure:error.message};}
  });
  let status='ALL_SYNTHETIC_CASES_PASSED_PENDING_INDEPENDENT_ACCEPTANCE';
  if(suites.some(suite=>suite.failed))status='KNOWN_F003_DEFECTS_STILL_BLOCK_INTEGRATION';
  if(suites.some(suite=>suite.unexpectedFailure))status='UNEXPECTED_F005_REPLAY_FAILURE';
  return {runType:'TWW_MILLING_REGRESSION_GUARD',node:process.version,
    sourceBlobPins,exercisedModelSHA,status,suites,independentAcceptance:false,
    workingNumericCellsChanged:0,evidenceExpectedQuantityPromotions:0,
    confidencePromotions:0,economicPromotions:0,liveEVChanged:false};
}
function writeSummary(lines){
  if(process.env.GITHUB_STEP_SUMMARY)
    fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY,['### War Within milling regression guard','',...lines,''].join('\n')+'\n');
}
if(require.main===module){
  try{
    const selfTesting=process.argv.includes('--self-test');
    const result=selfTesting?selfTest():run();
    console.log(JSON.stringify(result));
    if(!selfTesting){
      writeSummary([
        `Exercised model blob ${result.exercisedModelSHA}. Independent model acceptance remains pending.`,'',
        ...result.suites.flatMap(suite=>{
          const heading=[`#### ${suite.suite}`,''];
          if(suite.unexpectedFailure)return [...heading,`Unexpected replay failure: ${suite.unexpectedFailure}`,''];
          return [...heading,`Replay verdict: ${suite.passed}/${suite.total} passed. ${suite.failed} known checks still fail.`,'',
            ...suite.expectedRejections.map(failure=>`- Raw fixture: ${suite.rawFixturePassed} passed, ${suite.rawFixtureFailed} failed. It expects a return value for the overflow case. Directly verified the current model rejects overflow with “${failure.error}”, satisfying that case.`),
            ...suite.failures.map(failure=>`- ${failure.name} — ${failure.error}`),''];
        })
      ]);
      if(result.status==='UNEXPECTED_F005_REPLAY_FAILURE')process.exitCode=1;
    }
  }
  catch(e){
    console.error('F002 TWW native negative-QA preflight FAIL: '+e.message);
    process.exitCode=1;
    writeSummary([`Unexpected replay failure: ${e.message}`]);
  }
}
module.exports={PINS,SUITES,gitBlobSHA,verifyPins,verifyModelManifest,validateReport,selfTest,run};
