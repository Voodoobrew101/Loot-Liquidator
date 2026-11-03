'use strict';
// F005 independent adversarial QA, TWW milling accounting model v1.0.1.
// This test intentionally fails closed on unsafe mutable inputs.
// Research-only: passing tests do NOT authorize current-Retail economic use.
const EXPECTED_MODEL_BLOB_SHA = '5d90046b15046fb210523c34363c66596b962d3d';
const model = require('../../tools/models_v2/tww_mill_reagent_accounting_identification_v1.js');
function run() {
  const cases = [];
  const check = (name, fn) => {
    try { fn(); cases.push({name, pass:true}); }
    catch(e) { cases.push({name, pass:false, error:String(e.message || e)}); }
  };
  const ok = (v,msg) => { if(!v) throw Error(msg || 'assertion failed'); };
  const same = (a,b) => ok(Object.is(a,b), String(a)+' !== '+String(b));
  const rejects = fn => { let rejected=false; try { fn(); } catch(e) { rejected=true; } ok(rejected,'unsafe input accepted'); };
  const ctx = {
    targetKey:model.KEYS[2], expansion:'tww', method:'mill', gameMode:'retail',
    inputItemID:210798, outputItemID:222618, patchEpoch:'2026-10-30',
    studyFamily:'independent-synthetic'
  };
  const study = (extra={},context=ctx) => ({context,nominalBatchSize:5,...extra});
  check('scope contains twelve target mappings',()=>same(model.KEYS.length,12));
  check('zero-inclusive E preserves zero casts',()=>same(model.estimate(study({perCastOutputs:[0,2,0,1,0]})).empiricalE.lower,3/5));
  check('normal saving cap gives sharp cast bound',()=>same(model.denominator({nominalBatchSize:5,netConsumed:45,maxSavedPerCast:{units:1,status:'SCENARIO_ONLY',sourceID:'synthetic'}}).max,11));
  check('v1.0.1 inverse overflow is rejected',()=>rejects(()=>model.inverse(1e308,1e-308)));
  check('v1.0.1 whitespace patch rejected',()=>rejects(()=>model.estimate(study({completedCasts:2,totalOutputs:1},{...ctx,patchEpoch:'   '}))));
  check('v1.0.1 whitespace lineage rejected',()=>rejects(()=>model.estimate(study({completedCasts:2,totalOutputs:1},{...ctx,studyFamily:'  '}))));
  check('working estimate remains economically isolated',()=>{
    const r=model.estimate(study({completedCasts:2,totalOutputs:2,positiveCasts:1}));
    same(r.confidence,0);same(r.economicUse,'PREVIEW_ONLY');
    same(r.normalizedVerified,false);same(r.usableForLiveEV,false);
    same(r.usableForRecommendation,false);
  });
  check('reject context nominal batch conflicting with accounting batch',()=>rejects(()=>
    model.estimate(study({completedCasts:5,totalOutputs:5},{...ctx,nominalBatchSize:1}))));
  check('reject context reagent vector conflicting with actual batch',()=>rejects(()=>
    model.estimate(study({completedCasts:5,totalOutputs:5},{...ctx,reagentVector:[{itemID:210798,quantity:1}]}))));
  check('reject mutable targetKey after mapping validation',()=>{
    let reads=0;
    const c=new Proxy({...ctx},{get(t,k){if(k==='targetKey')return ++reads<=2?t[k]:model.KEYS[3];return Reflect.get(t,k);}});
    rejects(()=>model.estimate(study({completedCasts:2,totalOutputs:2},c)));
  });
  check('reject mutable saving cap that inflates max casts',()=>{
    let reads=0;
    const cap=new Proxy({units:1,status:'SCENARIO_ONLY',sourceID:'synthetic'},{get(t,k){
      if(k==='units')return ++reads<=2?1:4;
      return Reflect.get(t,k);
    }});
    rejects(()=>model.denominator({nominalBatchSize:5,netConsumed:45,maxSavedPerCast:cap}));
  });
  check('reject saving cap status escalation after validation',()=>{
    let reads=0;
    const cap=new Proxy({units:1,status:'SCENARIO_ONLY',sourceID:'synthetic'},{get(t,k){
      if(k==='status')return ++reads===1?'SCENARIO_ONLY':'INDEPENDENTLY_VERIFIED';
      return Reflect.get(t,k);
    }});
    rejects(()=>model.denominator({nominalBatchSize:5,netConsumed:45,maxSavedPerCast:cap}));
  });
  check('reject per-cast array length shrinking after structural validation',()=>{
    let reads=0;
    const a=new Proxy([0,2],{get(t,k){
      if(k==='length')return ++reads<=4?2:1;
      return Reflect.get(t,k);
    }});
    rejects(()=>model.estimate(study({perCastOutputs:a})));
  });
  check('reject mutable study-family identity after validation',()=>{
    let reads=0;
    const c=new Proxy({...ctx},{get(t,k){
      if(k==='studyFamily')return ++reads<=3?'original-family':'altered-family';
      return Reflect.get(t,k);
    }});
    rejects(()=>model.estimate(study({completedCasts:2,totalOutputs:2},c)));
  });
  check('reject mutable patch-epoch identity after validation',()=>{
    let reads=0;
    const c=new Proxy({...ctx},{get(t,k){
      if(k==='patchEpoch')return ++reads<=3?'2026-10-30':'2024-08-26';
      return Reflect.get(t,k);
    }});
    rejects(()=>model.estimate(study({completedCasts:2,totalOutputs:2},c)));
  });
  return {
    modelBlobSHA:EXPECTED_MODEL_BLOB_SHA, total:cases.length,
    passed:cases.filter(x=>x.pass).length,
    failed:cases.filter(x=>!x.pass).length,
    failures:cases.filter(x=>!x.pass),
    syntheticOnly:true, independentlyValidatedRetailStudyFamilies:0
  };
}
module.exports={run,EXPECTED_MODEL_BLOB_SHA};
if(require.main===module){
  const fs=require('fs'),crypto=require('crypto'),path=require('path');
  const bytes=fs.readFileSync(path.resolve(__dirname,'../../tools/models_v2/tww_mill_reagent_accounting_identification_v1.js'));
  const sha=crypto.createHash('sha1').update('blob '+bytes.length+'\0').update(bytes).digest('hex');
  if(sha!==EXPECTED_MODEL_BLOB_SHA)throw Error('model source changed; re-review '+sha);
  const result=run();console.log(JSON.stringify(result,null,2));
  if(result.failed)process.exitCode=1;
}
