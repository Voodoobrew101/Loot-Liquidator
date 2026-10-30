'use strict';
// F005 independent synthetic QA: fixed-n DF milling context, caps and economic isolation.
// Do not use as current-Retail evidence or as a live recommendation gate.
const MODEL_BLOB_SHA='216a929d4ab7b683e1bc9f4637273c4d766b1081';
const model=require('../../tools/models_v2/df_milling_fixed_n_simultaneous_bounds_v1.js');
function run(){
 const cases=[];
 const check=(name,fn)=>{try{fn();cases.push({name,pass:true});}catch(e){cases.push({name,pass:false,error:String(e.message||e)});}};
 const ok=(x,msg)=>{if(!x)throw Error(msg||'assertion failed');};
 const same=(a,b)=>ok(Object.is(a,b),String(a)+' != '+String(b));
 const close=(a,b)=>ok(Math.abs(a-b)<=1e-12*Math.max(1,Math.abs(b)),String(a)+' != '+String(b));
 const rejects=(f)=>{let threw=false;try{f();}catch(_){threw=true;}ok(threw,'unsafe input accepted');};
 const rejectsOrConsistent=(f,verify)=>{let result,threw=false;try{result=f();}catch(_){threw=true;}if(!threw)verify(result);};
 const c={gameMode:'RETAIL',expansion:'DRAGONFLIGHT',method:'MILL',inputItemID:191462,
  patchBuild:'10.2.7',observationEpoch:'2026-10-30T19:00:00Z',studyFamilyID:'F005-SYNTHETIC',
  nominalInputUnits:5,inputQualityRank:1,minimumRecipeEligibleSkill:1,actualSkill:1,recipeSpellID:382981,
  professionContext:{specialization:'NONE',gear:'NONE',unlocks:'NONE',resourcefulness:{value:0,unit:'RATING'}},
  outputQualityRanks:{198421:1,198422:1,198423:1},directReagents:[{itemID:191462,quantity:5}],outputUniverseStatus:'UNVERIFIED'};
 const event=(id,a,b,d,refund=0)=>({castID:id,outputs:{198421:a,198422:b,198423:d},refundedInputUnits:refund});
 const casts=[event('a',2,0,1,1),event('b',0,0,0,0),event('c',1,2,1,1)];
 const caps={198421:{maxPerCast:3,status:'INDEPENDENTLY_VERIFIED',sourceID:'SYNTHETIC-CAP'},
  198422:{maxPerCast:3,status:'INDEPENDENTLY_VERIFIED',sourceID:'SYNTHETIC-CAP'}};
 check('43 distinct exact stable keys',()=>{same(model.TARGETS.length,43);same(new Set(model.TARGETS.map(t=>t.stableKey)).size,43);});
 check('groups retain 3 and 12 target outputs',()=>{same(model.group(191462).length,3);same(model.group(200061).length,12);});
 check('original self-test passes 39 synthetic assertions',()=>same(model.selfTest().passed,39));
 check('completed casts and gross/refund/net conservation',()=>{const r=model.summarize({context:c,casts});same(r.completedCasts,3);same(r.grossNominalInputUnits,15);same(r.refundedInputUnits,2);same(r.netConsumedInputUnits,13);});
 check('zero-inclusive marginal P and unconditional E',()=>{const r=model.summarize({context:c,casts});const a=r.outputs;close(a[0].sampleDropChance,2/3);close(a[0].sampleUnconditionalE,1);close(a[1].sampleDropChance,1/3);close(a[1].sampleUnconditionalE,2/3);close(a[2].sampleUnconditionalE,2/3);});
 check('co-produced marginals are not forced to sum one',()=>{const r=model.summarize({context:c,casts});same(r.zeroTargetOutputCasts,1);same(r.coTargetOutputCasts,2);ok(r.outputs.reduce((s,o)=>s+o.sampleDropChance,0)>1);});
 check('family-wise P radius independently recomputed',()=>{const r=model.summarize({context:c,casts,alpha:0.05});same(r.simultaneousTestCount,3);const radius=Math.sqrt(Math.log(2*3/0.05)/(2*3));close(r.outputs[1].dropChanceInterval[0],Math.max(0,1/3-radius));close(r.outputs[1].dropChanceInterval[1],Math.min(1,1/3+radius));});
 check('capped E uses 5-test multiplicity and cap scaling',()=>{const r=model.summarize({context:c,casts,caps});same(r.simultaneousTestCount,5);const radius=Math.sqrt(Math.log(2*5/0.05)/6);const x=r.outputs[0];close(x.expectedQuantityInterval[0],Math.max(0,1-3*radius));close(x.expectedQuantityInterval[1],Math.min(3,1+3*radius));});
 check('unknown E cap refuses finite population interval',()=>{const r=model.summarize({context:c,casts});ok(r.outputs.every(x=>x.expectedQuantityInterval===null));});
 check('observed extrema are not hard game bounds',()=>{const x=model.summarize({context:c,casts}).outputs[0];same(x.observedPositiveMin,1);same(x.observedPositiveMax,2);same(x.sampleExtremaAreNotHardGameBounds,true);});
 check('zero sample outputs do not invent positive extrema',()=>{const r=model.summarize({context:c,casts:[event('z',0,0,0)]});ok(r.outputs.every(x=>x.observedPositiveMin===null&&x.observedPositiveMax===null&&x.sampleUnconditionalE===0));});
 check('all outputs remain preview-only and unverified',()=>{const r=model.summarize({context:c,casts});for(const x of [r,...r.outputs]){same(x.confidence,0);same(x.economicUse,'PREVIEW_ONLY');same(x.normalizedVerified,false);same(x.liveEconomicEligible,false);same(x.tooltipOnlyEligible,false);}same(r.currentRetailPopulationValidated,false);});
 check('no independent holdout or exhaustive universe claim',()=>{const r=model.summarize({context:c,casts});same(r.independentStudyFamilyHoldout,'NOT_PERFORMED');same(r.notAnExhaustiveOutputUniverseCertificate,true);});
 check('planning P uses fixed-n family-wise bound',()=>{const p=model.plan({inputItemID:191462,alpha:0.05,probabilityHalfWidth:0.1});same(p.plannedCastsForP,Math.ceil(Math.log(2*3/0.05)/0.02));same(p.notObservedCasts,true);});
 check('planning E without caps refuses guaranteed sample size',()=>{const p=model.plan({inputItemID:191462,expectedQuantityHalfWidth:0.5});ok(Object.values(p.plannedCastsForEByKey).every(x=>x===null));});
 check('planning capped E uses squared range',()=>{const p=model.plan({inputItemID:191462,caps,expectedQuantityHalfWidth:0.5});const key=model.group(191462)[0].stableKey;same(p.plannedCastsForEByKey[key],Math.ceil(9*Math.log(2*5/0.05)/(2*0.25)));});
 check('reject missing zero-inclusive target vector',()=>rejects(()=>model.summarize({context:c,casts:[{castID:'x',refundedInputUnits:0,outputs:{198421:1,198422:0}}]})));
 check('reject duplicate cast identifiers',()=>rejects(()=>model.summarize({context:c,casts:[casts[0],casts[0]]})));
 check('reject sparse cast array',()=>rejects(()=>model.summarize({context:c,casts:[casts[0],,casts[2]]})));
 check('reject unknown cap status',()=>rejects(()=>model.summarize({context:c,casts,caps:{198421:{maxPerCast:3,status:'SCENARIO_ONLY',sourceID:'synthetic'}}})));
 check('reject per-cast count exceeding asserted cap',()=>rejects(()=>model.summarize({context:c,casts,caps:{198421:{maxPerCast:1,status:'INDEPENDENTLY_VERIFIED',sourceID:'synthetic'}}})));
 check('reject invalid alpha',()=>rejects(()=>model.summarize({context:c,casts,alpha:1})));
 check('reject patch-build suffix contamination',()=>rejects(()=>model.summarize({context:{...c,patchBuild:'10.2.7garbage'},casts})));
 check('reject nonexistent calendar observation date',()=>rejects(()=>model.summarize({context:{...c,observationEpoch:'2026-02-30T19:00:00Z'},casts})));
 check('reject cast proxy changing outputs after validation',()=>{let reads=0;const p=new Proxy(casts[0],{get(o,k){if(k==='outputs')return ++reads<=1?o.outputs:{198421:100,198422:0,198423:0};return Reflect.get(o,k);}});rejectsOrConsistent(()=>model.summarize({context:c,casts:[p]}),r=>same(r.outputs[0].sampleUnconditionalE,2));});
 check('reject cap proxy changing maximum after attestation',()=>{let reads=0;const p=new Proxy({maxPerCast:3,status:'INDEPENDENTLY_VERIFIED',sourceID:'SYNTHETIC'},{get(o,k){if(k==='maxPerCast')return ++reads<=2?3:100;return Reflect.get(o,k);}});rejectsOrConsistent(()=>model.summarize({context:c,casts,caps:{198421:p}}),r=>ok(r.outputs[0].expectedQuantityInterval[1]<=3,'cap changed after validation'));});
 check('reject context proxy changing source lineage after validation',()=>{let reads=0;const p=new Proxy(c,{get(o,k){if(k==='studyFamilyID')return ++reads<=1?'F005-SYNTHETIC':'DIFFERENT-STUDY';return Reflect.get(o,k);}});rejectsOrConsistent(()=>model.summarize({context:p,casts}),r=>same(r.studyFamilyID,'F005-SYNTHETIC'));});
 check('reject context proxy changing epoch after validation',()=>{let reads=0;const p=new Proxy(c,{get(o,k){if(k==='observationEpoch')return ++reads<=2?o.observationEpoch:'2025-01-01T00:00:00Z';return Reflect.get(o,k);}});rejectsOrConsistent(()=>model.summarize({context:p,casts}),r=>same(r.observationEpoch,c.observationEpoch));});
 check('reject context proxy changing recipe identity after validation',()=>{let reads=0;const p=new Proxy(c,{get(o,k){if(k==='recipeSpellID')return ++reads<=1?382981:999999;return Reflect.get(o,k);}});rejectsOrConsistent(()=>model.summarize({context:p,casts}),r=>same(r.recipeSpellID,382981));});
 check('reject mutated cap source ID after validation',()=>{let reads=0;const p=new Proxy({maxPerCast:3,status:'INDEPENDENTLY_VERIFIED',sourceID:'SYNTHETIC'},{get(o,k){if(k==='sourceID')return ++reads<=2?'SYNTHETIC':'INVENTED-SOURCE';return Reflect.get(o,k);}});rejectsOrConsistent(()=>model.summarize({context:c,casts,caps:{198421:p}}),r=>same(r.outputs[0].capSourceID,'SYNTHETIC'));});
 const failed=cases.filter(x=>!x.pass);
 return {modelBlobSHA:MODEL_BLOB_SHA,total:cases.length,passed:cases.length-failed.length,failed:failed.length,failures:failed,syntheticOnly:true,independentRetailHoldouts:0};
}
module.exports={run,MODEL_BLOB_SHA};
if(require.main===module){
 const fs=require('fs'),crypto=require('crypto'),path=require('path');
 const p=path.resolve(__dirname,'../../tools/models_v2/df_milling_fixed_n_simultaneous_bounds_v1.js');
 const bytes=fs.readFileSync(p);const sha=crypto.createHash('sha1').update('blob '+bytes.length+'\0').update(bytes).digest('hex');
 if(sha!==MODEL_BLOB_SHA)throw Error('model source changed: '+sha);
 const result=run();console.log(JSON.stringify(result,null,2));if(result.failed)process.exitCode=1;
}
