'use strict';
// Independent synthetic F005 regression; never evidence for live EV or current Retail.
const MODEL_BLOB_SHA='e36328de0e677582bf9b2b36c4a6144a5c2f17be';
const model=require('../../tools/models_v2/df_milling_fixed_n_simultaneous_bounds_v1.js');
function run(){
 const results=[];const ok=x=>{if(!x)throw Error('ASSERTION_FAILED')};const bad=f=>{let thrown=false;try{f()}catch(_){thrown=true}ok(thrown)};
 const c={gameMode:'RETAIL',expansion:'DRAGONFLIGHT',method:'MILL',inputItemID:191462,patchBuild:'10.2.7',observationEpoch:'2026-10-30T19:00:00Z',studyFamilyID:'F005-SYNTHETIC',nominalInputUnits:5,inputQualityRank:1,minimumRecipeEligibleSkill:1,actualSkill:1,recipeSpellID:382981,professionContext:{specialization:'NONE',gear:'NONE',unlocks:'NONE',resourcefulness:{value:0,unit:'RATING'}},outputQualityRanks:{198421:1,198422:1,198423:1},directReagents:[{itemID:191462,quantity:5}],outputUniverseStatus:'UNVERIFIED'};
 const ev=(id,a=1,b=0,d=0)=>({castID:id,refundedInputUnits:0,outputs:{198421:a,198422:b,198423:d}});
 const casts=[ev('a'),ev('b',0,1,0)];const go=(context=c,events=casts,caps)=>model.summarize({context,casts:events,caps});
 const test=(name,fn)=>{try{fn();results.push({name,pass:true})}catch(e){results.push({name,pass:false,error:String(e.message||e)})}};
 test("context accessor",()=>{const x={...c};Object.defineProperty(x,'studyFamilyID',{get(){return 'x'},enumerable:true});bad(()=>go(x));});
 test("cast outputs accessor",()=>{const x=ev('a');Object.defineProperty(x,'outputs',{get(){return {198421:1,198422:0,198423:0}},enumerable:true});bad(()=>go(c,[x]));});
 test("array subclass",()=>{class Sub extends Array{};bad(()=>go(c,Sub.from(casts)));});
 test("sparse cast array",()=>{bad(()=>go(c,[ev('a'),,ev('b')]));});
 test("cast symbol property",()=>{const x=ev('a');x[Symbol('hidden')]=1;bad(()=>go(c,[x]));});
 test("hidden cast property",()=>{const x=ev('a');Object.defineProperty(x,'hidden',{value:1});bad(()=>go(c,[x]));});
 test("custom toJSON cast",()=>{const x=ev('a');x.toJSON=()=>({});bad(()=>go(c,[x]));});
 test("cyclic context",()=>{const x={...c};x.self=x;bad(()=>go(x));});
 test("nonfinite output count",()=>{bad(()=>go(c,[ev('a',Infinity)]));});
 test("aggregate safe-integer overflow",()=>{bad(()=>go(c,[ev('a',Number.MAX_SAFE_INTEGER),ev('b',1)]));});
 test("duplicate cast IDs",()=>{bad(()=>go(c,[ev('a'),ev('a')]));});
 test("duplicate reagent IDs",()=>{bad(()=>go({...c,directReagents:[{itemID:191462,quantity:5},{itemID:191462,quantity:5}]}));});
 test("conflicting batch",()=>{bad(()=>go({...c,nominalInputUnits:4}));});
 test("invalid leap day",()=>{bad(()=>go({...c,observationEpoch:'2026-02-29T00:00:00Z'}));});
 test("valid leap day",()=>{ok(go({...c,observationEpoch:'2024-02-29T00:00:00Z'}).completedCasts===2);});
 test("invalid timezone +14:01",()=>{bad(()=>go({...c,observationEpoch:'2026-10-30T19:00:00+14:01'}));});
 test("cap contradicted by cast",()=>{bad(()=>go(c,[ev('a',2)],{198421:{maxPerCast:1,status:'INDEPENDENTLY_VERIFIED',sourceID:'SYNTHETIC'}}));});
 test("cap source accessor",()=>{const cap={maxPerCast:3,status:'INDEPENDENTLY_VERIFIED'};Object.defineProperty(cap,'sourceID',{enumerable:true,get(){return 'x'}});bad(()=>go(c,casts,{198421:cap}));});
 test("proxy get trap ignored by canonical snapshot",()=>{const x=ev('a',2);const p=new Proxy(x,{get(t,k){if(k==='outputs')return {198421:999,198422:0,198423:0};return Reflect.get(t,k)}});ok(go(c,[p]).outputs[0].sampleUnconditionalE===2);});
 test("no cap gives no finite E interval",()=>{ok(go().outputs.every(x=>x.expectedQuantityInterval===null));});
 test("outputs preview-only",()=>{const r=go();ok(r.economicUse==='PREVIEW_ONLY'&&r.normalizedVerified===false&&r.confidence===0&&r.outputs.every(x=>x.economicUse==='PREVIEW_ONLY'&&x.confidence===0&&x.normalizedVerified===false));});
 test("plan preview-only",()=>{const p=model.plan({inputItemID:191462});ok(p.economicUse==='PREVIEW_ONLY'&&p.normalizedVerified===false&&p.confidence===0);});
 const failures=results.filter(x=>!x.pass);return {modelBlobSHA:MODEL_BLOB_SHA,total:results.length,passed:results.length-failures.length,failed:failures.length,failures,syntheticOnly:true,independentRetailHoldouts:0};
}
module.exports={run,MODEL_BLOB_SHA};
if(require.main===module){const fs=require('fs'),path=require('path'),crypto=require('crypto');const bytes=fs.readFileSync(path.resolve(__dirname,'../../tools/models_v2/df_milling_fixed_n_simultaneous_bounds_v1.js'));const sha=crypto.createHash('sha1').update('blob '+bytes.length+'\\0'.replace('\\0','\0')).update(bytes).digest('hex');if(sha!==MODEL_BLOB_SHA)throw Error('MODEL_SOURCE_PIN_MISMATCH '+sha);const r=run();console.log(JSON.stringify(r,null,2));if(r.failed)process.exitCode=1;}
