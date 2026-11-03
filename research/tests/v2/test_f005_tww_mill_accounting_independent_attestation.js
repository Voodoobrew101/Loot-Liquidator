'use strict';
// Independent F005 regression for F003 TWW milling accounting identification.
// Research-only; assertions must not be used as live economic eligibility gates.
const EXPECTED_MODEL_BLOB_SHA='75169a9a6f2eb7a3f1c4148e09074fba65d88f4a';
const model=require('../../tools/models_v2/tww_mill_reagent_accounting_identification_v1.js');
function run(){
 const cases=[], check=(name,fn)=>{try{fn();cases.push({name,pass:true});}catch(e){cases.push({name,pass:false,error:String(e.message||e)});}};
 const ok=(condition,message)=>{if(!condition)throw Error(message||'assertion failed');};
 const same=(a,b)=>ok(Object.is(a,b),JSON.stringify(a)+' != '+JSON.stringify(b));
 const rejects=(fn)=>{let rejected=false;try{fn();}catch(e){rejected=true;}ok(rejected,'unsafe input accepted');};
 const context={targetKey:model.KEYS[2],expansion:'tww',method:'mill',gameMode:'retail',inputItemID:210798,outputItemID:222618,patchEpoch:'2026-10-30',studyFamily:'independent-synthetic'};
 const study=(x,c=context)=>({context:c,nominalBatchSize:5,...x});
 check('twelve explicitly scoped keys',()=>same(model.KEYS.length,12));
 check('actual completed casts remain denominator',()=>same(model.denominator({nominalBatchSize:5,completedCasts:10,netConsumed:45,savedTotal:5}).min,10));
 check('net plus saved identifies ten casts',()=>same(model.denominator({nominalBatchSize:5,netConsumed:45,savedTotal:5}).max,10));
 check('net only has no finite upper without saving cap',()=>same(model.denominator({nominalBatchSize:5,netConsumed:45}).max,null));
 check('scenario cap creates labelled bounds',()=>{const d=model.denominator({nominalBatchSize:5,netConsumed:45,maxSavedPerCast:{units:1,status:'SCENARIO_ONLY',sourceID:'synthetic'}});same(d.min,9);same(d.max,11);same(d.capStatus,'SCENARIO_ONLY');});
 check('verified cap status is retained without claiming independent verification',()=>same(model.denominator({nominalBatchSize:5,netConsumed:45,maxSavedPerCast:{units:1,status:'INDEPENDENTLY_VERIFIED',sourceID:'external-attestation-pending'}}).capStatus,'INDEPENDENTLY_VERIFIED'));
 check('reject nondivisible net plus saved',()=>rejects(()=>model.denominator({nominalBatchSize:5,netConsumed:45,savedTotal:4})));
 check('reject impossible conservation with casts',()=>rejects(()=>model.denominator({nominalBatchSize:5,completedCasts:10,netConsumed:45,savedTotal:4})));
 check('reject cap equal to batch',()=>rejects(()=>model.denominator({nominalBatchSize:5,netConsumed:45,maxSavedPerCast:{units:5,status:'SCENARIO_ONLY',sourceID:'synthetic'}})));
 check('reject unlabelled cap',()=>rejects(()=>model.denominator({nominalBatchSize:5,netConsumed:45,maxSavedPerCast:{units:1,status:'UNVERIFIED',sourceID:'synthetic'}})));
 check('reject missing cap source',()=>rejects(()=>model.denominator({nominalBatchSize:5,netConsumed:45,maxSavedPerCast:{units:1,status:'SCENARIO_ONLY',sourceID:'  '}})));
 check('reject unsafe batch size',()=>rejects(()=>model.denominator({nominalBatchSize:0,netConsumed:1})));
 check('reject unsafe input integer',()=>rejects(()=>model.denominator({nominalBatchSize:5,netConsumed:Number.MAX_SAFE_INTEGER+1})));
 check('sample E includes zero casts',()=>same(model.estimate(study({netConsumed:20,savedTotal:5,perCastOutputs:[0,2,0,1,0]})).empiricalE.lower,3/5));
 check('sample P includes zero casts',()=>same(model.estimate(study({netConsumed:20,savedTotal:5,perCastOutputs:[0,2,0,1,0]})).empiricalP.lower,2/5));
 check('observed positive yield bounds not hard bounds',()=>{const a=model.estimate(study({completedCasts:5,perCastOutputs:[0,2,0,1,0]}));same(a.observedConditionalRange.min,1);same(a.observedConditionalRange.max,2);});
 check('economic preview never live',()=>{const a=model.estimate(study({completedCasts:2,totalOutputs:2,positiveCasts:1}));same(a.confidence,0);same(a.economicUse,'PREVIEW_ONLY');same(a.normalizedVerified,false);same(a.usableForLiveEV,false);same(a.usableForRecommendation,false);});
 check('zero inclusive all-zero sample',()=>{const a=model.estimate(study({completedCasts:3,perCastOutputs:[0,0,0]}));same(a.empiricalE.lower,0);same(a.empiricalP.upper,0);same(a.observedConditionalRange.min,null);});
 check('reject sparse per-cast array',()=>rejects(()=>model.estimate(study({perCastOutputs:[0,,2]}))));
 check('reject per-cast accessor',()=>{const a=[0,1];Object.defineProperty(a,'0',{get(){return 0},enumerable:true});rejects(()=>model.estimate(study({perCastOutputs:a})));});
 check('reject per-cast extra property',()=>{const a=[0,1];a.extra='unsafe';rejects(()=>model.estimate(study({perCastOutputs:a})));});
 check('reject per-cast symbol metadata',()=>{const a=[0,1];a[Symbol('x')]=3;rejects(()=>model.estimate(study({perCastOutputs:a})));});
 check('reject array subclass',()=>{class A extends Array{};rejects(()=>model.estimate(study({perCastOutputs:new A(0,1)})));});
 check('reject positive casts with zero outputs',()=>rejects(()=>model.estimate(study({completedCasts:3,totalOutputs:0,positiveCasts:1}))));
 check('reject more positive casts than outputs',()=>rejects(()=>model.estimate(study({completedCasts:3,totalOutputs:1,positiveCasts:2}))));
 check('reject incorrect item identity',()=>rejects(()=>model.estimate(study({completedCasts:2,totalOutputs:2},{...context,inputItemID:210799}))));
 check('reject recipe-ineligible skill',()=>rejects(()=>model.estimate(study({completedCasts:2,totalOutputs:2},{...context,minimumEligibleSkill:20,actualSkill:10}))));
 check('normal inverse preserves conditional mean',()=>same(model.inverse(0.8,0.4).conditionalMean,2));
 check('normal forward preserves unconditional E',()=>same(model.forward(0.4,2).unconditionalE,0.8));
 check('zero P and E inverse unidentified',()=>same(model.inverse(0,0).identified,false));
 check('reject E positive when P zero',()=>rejects(()=>model.inverse(1,0)));
 check('integer cast interval sharpness independently enumerated',()=>{
   for(let b=2;b<=8;b++)for(let cap=0;cap<b;cap++)for(let net=1;net<=40;net++){
    const lo=Math.ceil(net/b),hi=Math.floor(net/(b-cap));
    if(hi<lo){rejects(()=>model.denominator({nominalBatchSize:b,netConsumed:net,maxSavedPerCast:{units:cap,status:'SCENARIO_ONLY',sourceID:'synthetic'}}));continue;}
    const d=model.denominator({nominalBatchSize:b,netConsumed:net,maxSavedPerCast:{units:cap,status:'SCENARIO_ONLY',sourceID:'synthetic'}});
    same(d.min,lo);same(d.max,hi);
    const feasible=[];for(let c=0;c<=50;c++)if(c*b-net>=0&&c*b-net<=c*cap)feasible.push(c);
    same(feasible[0],lo);same(feasible[feasible.length-1],hi);
   }
 });
 // Adversarial cases: these are EXPECTED rejections or invariants, not optional features.
 check('reject contradictory nominal batch in typed context',()=>rejects(()=>model.estimate(study({completedCasts:5,totalOutputs:5},{...context,nominalBatchSize:1}))));
 check('reject contradictory direct reagent vector in typed context',()=>rejects(()=>model.estimate(study({completedCasts:5,totalOutputs:5},{...context,reagentVector:[{itemID:210798,quantity:1}]}))));
 check('inverse must not return nonfinite conditional mean',()=>{const x=model.inverse(1e308,Number.MIN_VALUE);ok(Number.isFinite(x.conditionalMean),'inverse emitted Infinity (JSON serializes as null)');});
 check('reject proxy that changes mapping after identity check',()=>{
   let reads=0;const p=new Proxy({...context},{get(t,k){if(k==='targetKey')return ++reads<=2?t[k]:model.KEYS[3];return Reflect.get(t,k);}});
   rejects(()=>model.estimate(study({completedCasts:2,totalOutputs:2},p)));
 });
 check('reject proxy cap whose units change after validation',()=>{
   let reads=0;const p=new Proxy({units:1,status:'SCENARIO_ONLY',sourceID:'synthetic'},{get(t,k){if(k==='units')return ++reads<=2?1:4;return Reflect.get(t,k);}});
   rejects(()=>model.denominator({nominalBatchSize:5,netConsumed:45,maxSavedPerCast:p}));
 });
 return {modelBlobSHA:EXPECTED_MODEL_BLOB_SHA,passed:cases.filter(x=>x.pass).length,failed:cases.filter(x=>!x.pass).length,total:cases.length,failures:cases.filter(x=>!x.pass),syntheticOnly:true,independentRetailHoldouts:0};
}
module.exports={run,EXPECTED_MODEL_BLOB_SHA};
if(require.main===module){
 const fs=require('fs'),crypto=require('crypto'),path=require('path');
 const p=path.resolve(__dirname,'../../tools/models_v2/tww_mill_reagent_accounting_identification_v1.js');
 const bytes=fs.readFileSync(p);const sha=crypto.createHash('sha1').update('blob '+bytes.length+'\0').update(bytes).digest('hex');
 if(sha!==EXPECTED_MODEL_BLOB_SHA)throw Error('model source changed: '+sha);
 const result=run();console.log(JSON.stringify(result,null,2));if(result.failed)process.exitCode=1;
}
