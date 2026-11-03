'use strict';
// F003 research-only: fixed-n simultaneous marginal bounds for 43 DF milling E gaps.
// No output from this module may be used in live EV, recommendations or tooltip fallback.
const MODEL_ID='df-milling-fixed-n-simultaneous-bounds-v1.0.1';
const POLICY=Object.freeze({confidence:0,economicUse:'PREVIEW_ONLY',normalizedVerified:false,liveEconomicEligible:false,tooltipOnlyEligible:false});
const tupleText=[
'191461:198423:1942',
'191462:198421:1945','191462:198422:1946','191462:198423:1947',
'191464:198418:1950','191464:198419:1951','191464:198420:1952',
'191465:198418:1955','191465:198419:1956','191465:198420:1957',
'191466:198418:1960','191466:198419:1961','191466:198420:1962',
'191467:198412:1965','191467:198413:1966','191467:198414:1967',
'191468:198412:1970','191468:198413:1971','191468:198414:1972',
'191469:198412:1975','191469:198413:1976','191469:198414:1977',
'191470:198415:1980','191470:198416:1981','191470:198417:1982',
'191471:198415:1985','191471:198416:1986','191471:198417:1987',
'191472:198415:1990','191472:198416:1991','191472:198417:1992',
'200061:198412:1998','200061:198413:1999','200061:198414:2000',
'200061:198415:2001','200061:198416:2002','200061:198417:2003',
'200061:198418:2004','200061:198419:2005','200061:198420:2006',
'200061:198421:2007','200061:198422:2008','200061:198423:2009'
];
const TARGETS=Object.freeze(tupleText.map(s=>{const a=s.split(':').map(Number);return Object.freeze({inputItemID:a[0],outputItemID:a[1],stableKey:'tsm:mill:'+a[0]+':'+a[1]+':L'+a[2]});}));
function requireValid(v,code){if(!v)throw Error(code);}
function uint(v,min=0){return Number.isSafeInteger(v)&&v>=min;}
function plain(o){if(!o||typeof o!=='object'||Array.isArray(o)||Object.getPrototypeOf(o)!==Object.prototype)return false;for(const k of Reflect.ownKeys(o)){const d=Object.getOwnPropertyDescriptor(o,k);if(typeof k!=='string'||!d.enumerable||!Object.prototype.hasOwnProperty.call(d,'value'))return false;}return true;}
function safeArray(a){if(!Array.isArray(a)||Object.getPrototypeOf(a)!==Array.prototype||Reflect.ownKeys(a).length!==a.length+1)return false;for(let i=0;i<a.length;i++){const d=Object.getOwnPropertyDescriptor(a,String(i));if(!d||!Object.prototype.hasOwnProperty.call(d,'value'))return false;}return true;}
// Copy untrusted caller objects once via data descriptors; reject accessors,
 // hidden metadata, sparse arrays and non-finite/undefined values. Never use
 // mutable caller objects for subsequent validation, calculation or reporting.
function snapshot(value,seen=new WeakSet()){
 if(value===null||typeof value==='string'||typeof value==='boolean'||typeof value==='number'&&Number.isFinite(value))return value;
 requireValid(typeof value==='object','SNAPSHOT_DATA_ONLY');
 requireValid(!seen.has(value),'SNAPSHOT_CYCLE');seen.add(value);
 const array=Array.isArray(value);
 requireValid(Object.getPrototypeOf(value)===(array?Array.prototype:Object.prototype),'SNAPSHOT_PROTOTYPE');
 const keys=Reflect.ownKeys(value),out=array?[]:{};
 if(array){
  const d=Object.getOwnPropertyDescriptor(value,'length'),n=d&&d.value;
  requireValid(Number.isSafeInteger(n)&&n>=0&&keys.length===n+1,'SNAPSHOT_ARRAY_SHAPE');
  for(let i=0;i<n;i++){const x=Object.getOwnPropertyDescriptor(value,String(i));requireValid(x&&x.enumerable&&Object.prototype.hasOwnProperty.call(x,'value'),'SNAPSHOT_ARRAY_ELEMENT');out.push(snapshot(x.value,seen));}
 }else{
  for(const key of keys){requireValid(typeof key==='string','SNAPSHOT_KEY');const d=Object.getOwnPropertyDescriptor(value,key);
   requireValid(d&&d.enumerable&&Object.prototype.hasOwnProperty.call(d,'value'),'SNAPSHOT_DESCRIPTOR');
   Object.defineProperty(out,key,{value:snapshot(d.value,seen),enumerable:true,writable:false,configurable:false});}
 }
 seen.delete(value);return Object.freeze(out);
}
function strictEpoch(s){
 if(typeof s!=='string')return false;
 const m=/^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(?:\.\d+)?(Z|[+-]\d\d:\d\d)$/.exec(s);
 if(!m)return false;
 const [y,mo,d,h,mi,se]=m.slice(1,7).map(Number);
 if(y<2004||mo<1||mo>12||d<1||d>31||h>23||mi>59||se>59)return false;
 const utc=new Date(Date.UTC(y,mo-1,d));if(utc.getUTCFullYear()!==y||utc.getUTCMonth()!==mo-1||utc.getUTCDate()!==d)return false;
 if(m[7]!=='Z'){const oh=Number(m[7].slice(1,3)),om=Number(m[7].slice(4));if(oh>14||om>59||oh===14&&om!==0)return false;}
 return Number.isFinite(Date.parse(s));
}
function group(input){requireValid(uint(input,1),'INPUT_ID');const g=TARGETS.filter(t=>t.inputItemID===input);requireValid(g.length>0,'INPUT_NOT_TARGETED');return g;}
function validateContext(untrusted){
 const c=snapshot(untrusted);
 requireValid(plain(c)&&c.gameMode==='RETAIL'&&c.expansion==='DRAGONFLIGHT'&&c.method==='MILL','CONTEXT_IDENTITY');
 const g=group(c.inputItemID);
 requireValid(typeof c.patchBuild==='string'&&/^\d+\.\d+\.\d+(?:\.\d+)*$/.test(c.patchBuild),'PATCH_BUILD');
 requireValid(strictEpoch(c.observationEpoch),'OBSERVATION_EPOCH');
 requireValid(typeof c.studyFamilyID==='string'&&c.studyFamilyID.trim(),'STUDY_LINEAGE');
 requireValid(uint(c.nominalInputUnits,1)&&uint(c.inputQualityRank,1)&&uint(c.minimumRecipeEligibleSkill,1)&&uint(c.actualSkill,c.minimumRecipeEligibleSkill)&&uint(c.recipeSpellID,1),'RECIPE_OR_SKILL');
 requireValid(plain(c.professionContext)&&['specialization','gear','unlocks'].every(k=>typeof c.professionContext[k]==='string'&&c.professionContext[k].trim()),'PROFESSION_CONTEXT');
 requireValid(plain(c.professionContext.resourcefulness)&&Number.isFinite(c.professionContext.resourcefulness.value)&&c.professionContext.resourcefulness.value>=0&&['RATING','PERCENT'].includes(c.professionContext.resourcefulness.unit),'RESOURCEFULNESS_UNITS');
 requireValid(plain(c.outputQualityRanks)&&Object.keys(c.outputQualityRanks).length===g.length&&g.every(t=>uint(c.outputQualityRanks[t.outputItemID],1)),'OUTPUT_RANKS');
 requireValid(safeArray(c.directReagents)&&c.directReagents.length>0&&c.directReagents.every(r=>plain(r)&&uint(r.itemID,1)&&uint(r.quantity,1))&&new Set(c.directReagents.map(r=>r.itemID)).size===c.directReagents.length,'DIRECT_REAGENTS');
 requireValid(c.directReagents.filter(r=>r.itemID===c.inputItemID).length===1&&c.directReagents.find(r=>r.itemID===c.inputItemID).quantity===c.nominalInputUnits,'BATCH_CONSERVATION');
 requireValid(['UNVERIFIED','INDEPENDENTLY_VERIFIED'].includes(c.outputUniverseStatus),'UNIVERSE_STATUS');
 return g;
}
function validateCaps(caps,g){
 requireValid(caps===undefined||plain(caps),'CAP_MAP');
 const capMap=caps===undefined?{}:snapshot(caps);
 requireValid(Object.keys(capMap).every(id=>g.some(t=>String(t.outputItemID)===id)),'EXTRA_CAP');
 for(const id of Object.keys(capMap)){const cap=capMap[id];requireValid(plain(cap)&&uint(cap.maxPerCast,1)&&cap.status==='INDEPENDENTLY_VERIFIED'&&typeof cap.sourceID==='string'&&cap.sourceID.trim(),'CAP_ATTESTATION_REQUIRED');}
 return capMap;
}
function summarize({context:rawContext,casts:rawCasts,alpha=0.05,caps}){
 const context=snapshot(rawContext),casts=snapshot(rawCasts);
 const g=validateContext(context),capMap=validateCaps(caps,g);
 requireValid(Number.isFinite(alpha)&&alpha>0&&alpha<1,'ALPHA');
 requireValid(safeArray(casts)&&casts.length>0&&casts.length<=100000,'CAST_ARRAY');
 const counts={},hits={},mins={},maxs={};for(const t of g){counts[t.outputItemID]=0;hits[t.outputItemID]=0;mins[t.outputItemID]=Infinity;maxs[t.outputItemID]=0;}
 const ids=new Set();let refunds=0,zeroTarget=0,coTarget=0;
 for(const e of casts){
  requireValid(plain(e)&&typeof e.castID==='string'&&e.castID.trim()&&!ids.has(e.castID),'CAST_ID');ids.add(e.castID);
  requireValid(uint(e.refundedInputUnits)&&e.refundedInputUnits<=context.nominalInputUnits,'REFUNDS');
  requireValid(plain(e.outputs)&&Object.keys(e.outputs).length===g.length&&g.every(t=>Object.prototype.hasOwnProperty.call(e.outputs,String(t.outputItemID))),'ZERO_INCLUSIVE_TARGET_VECTOR');
  refunds+=e.refundedInputUnits;requireValid(Number.isSafeInteger(refunds),'REFUND_OVERFLOW');
  let positive=0;
  for(const t of g){
   const id=t.outputItemID,y=e.outputs[id];requireValid(uint(y),'OUTPUT_COUNT');
   requireValid(!capMap[id]||y<=capMap[id].maxPerCast,'VERIFIED_CAP_CONTRADICTION');
   counts[id]+=y;requireValid(Number.isSafeInteger(counts[id]),'TOTAL_OVERFLOW');
   if(y>0){positive++;hits[id]++;mins[id]=Math.min(mins[id],y);maxs[id]=Math.max(maxs[id],y);}
  }
  if(positive===0)zeroTarget++;if(positive>1)coTarget++;
 }
 const n=casts.length,gross=n*context.nominalInputUnits;requireValid(Number.isSafeInteger(gross),'GROSS_OVERFLOW');
 const tests=g.length+Object.keys(capMap).length;
 const radius=Math.sqrt(Math.log(2*tests/alpha)/(2*n));
 return {modelID:MODEL_ID,studyFamilyID:context.studyFamilyID,patchBuild:context.patchBuild,observationEpoch:context.observationEpoch,
  inputItemID:context.inputItemID,inputQualityRank:context.inputQualityRank,recipeSpellID:context.recipeSpellID,
  completedCasts:n,grossNominalInputUnits:gross,refundedInputUnits:refunds,netConsumedInputUnits:gross-refunds,
  zeroTargetOutputCasts:zeroTarget,coTargetOutputCasts:coTarget,trackedTargetCount:g.length,
  outputUniverseStatus:context.outputUniverseStatus,notAnExhaustiveOutputUniverseCertificate:true,
  inference:'FIXED_N_IID_SCENARIO_ONLY',alphaFamilyWise:alpha,simultaneousTestCount:tests,
  outputs:g.map(t=>{const id=t.outputItemID,p=hits[id]/n,e=counts[id]/n,cap=capMap[id];return {stableKey:t.stableKey,outputItemID:id,
    sampleDropChance:p,sampleUnconditionalE:e,observedPositiveMin:hits[id]?mins[id]:null,observedPositiveMax:hits[id]?maxs[id]:null,
    dropChanceInterval:[Math.max(0,p-radius),Math.min(1,p+radius)],
    expectedQuantityInterval:cap?[Math.max(0,e-cap.maxPerCast*radius),Math.min(cap.maxPerCast,e+cap.maxPerCast*radius)]:null,
    expectedQuantityIntervalUnavailableReason:cap?null:'NO_INDEPENDENTLY_ATTESTED_PER_CAST_CAP',
    capSourceID:cap?cap.sourceID:null,capAttestation:cap?'CALLER_ASSERTED_NOT_INDEPENDENTLY_REVIEWED_BY_MODEL':null,
    sampleExtremaAreNotHardGameBounds:true,...POLICY};}),
  independentStudyFamilyHoldout:'NOT_PERFORMED',currentRetailPopulationValidated:false,...POLICY};
}
function plan({inputItemID,alpha=0.05,probabilityHalfWidth=0.1,expectedQuantityHalfWidth=null,caps}){
 const g=group(inputItemID),capMap=validateCaps(caps,g);
 requireValid(Number.isFinite(alpha)&&alpha>0&&alpha<1&&Number.isFinite(probabilityHalfWidth)&&probabilityHalfWidth>0&&probabilityHalfWidth<1,'PRECISION');
 requireValid(expectedQuantityHalfWidth===null||Number.isFinite(expectedQuantityHalfWidth)&&expectedQuantityHalfWidth>0,'E_PRECISION');
 const tests=g.length+Object.keys(capMap).length,log=Math.log(2*tests/alpha);
 const nP=Math.ceil(log/(2*probabilityHalfWidth**2));requireValid(Number.isSafeInteger(nP),'SAMPLE_SIZE_OVERFLOW');
 const nE={};for(const t of g){const cap=capMap[t.outputItemID];if(!cap||expectedQuantityHalfWidth===null)nE[t.stableKey]=null;else{const n=Math.ceil(cap.maxPerCast**2*log/(2*expectedQuantityHalfWidth**2));requireValid(Number.isSafeInteger(n),'E_SAMPLE_SIZE_OVERFLOW');nE[t.stableKey]=n;}}
 return {modelID:MODEL_ID,inputItemID,trackedTargetCount:g.length,alphaFamilyWise:alpha,probabilityHalfWidth,plannedCastsForP:nP,plannedCastsForEByKey:nE,
  assumptions:'FIXED_N_IID_HOEFFDING_AND_CALLER_ATTESTED_CAPS_ONLY',noFiniteEGuaranteeWithoutCap:true,notObservedCasts:true,...POLICY};
}
function selfTest(){
 let n=0;function eq(a,b){if(JSON.stringify(a)!==JSON.stringify(b))throw Error('ASSERT '+JSON.stringify(a)+' != '+JSON.stringify(b));n++;}function ok(a){if(!a)throw Error('ASSERT_FALSE');n++;}function bad(f){let fail=false;try{f();}catch(_){fail=true;}if(!fail)throw Error('EXPECTED_REJECTION');n++;}
 eq(TARGETS.length,43);eq(new Set(TARGETS.map(x=>x.stableKey)).size,43);eq(group(191462).length,3);eq(group(200061).length,12);bad(()=>group(42));
 const c={gameMode:'RETAIL',expansion:'DRAGONFLIGHT',method:'MILL',inputItemID:191462,patchBuild:'10.2.7',observationEpoch:'2026-10-30T19:00:00Z',studyFamilyID:'SYNTHETIC-ONLY',nominalInputUnits:5,inputQualityRank:1,minimumRecipeEligibleSkill:1,actualSkill:1,recipeSpellID:382981,professionContext:{specialization:'NONE',gear:'NONE',unlocks:'NONE',resourcefulness:{value:0,unit:'RATING'}},outputQualityRanks:{198421:1,198422:1,198423:1},directReagents:[{itemID:191462,quantity:5}],outputUniverseStatus:'UNVERIFIED'};
 const ev=(id,outputs,refundedInputUnits=0)=>({castID:id,outputs,refundedInputUnits});
 const casts=[ev('a',{198421:1,198422:0,198423:2},1),ev('b',{198421:0,198422:0,198423:0}),ev('c',{198421:0,198422:2,198423:1},1)];
 const r=summarize({context:c,casts});
 eq(r.completedCasts,3);eq(r.grossNominalInputUnits,15);eq(r.refundedInputUnits,2);eq(r.netConsumedInputUnits,13);eq(r.zeroTargetOutputCasts,1);eq(r.coTargetOutputCasts,2);
 eq(r.outputs.map(x=>x.sampleUnconditionalE),[1/3,2/3,1]);eq(r.outputs.map(x=>x.sampleDropChance),[1/3,1/3,2/3]);
 eq(r.outputs[0].expectedQuantityInterval,null);eq(r.outputs[0].sampleExtremaAreNotHardGameBounds,true);
 eq(r.outputs[0].confidence,0);eq(r.outputs[0].economicUse,'PREVIEW_ONLY');eq(r.outputs[0].normalizedVerified,false);eq(r.currentRetailPopulationValidated,false);
 const caps={198421:{maxPerCast:2,status:'INDEPENDENTLY_VERIFIED',sourceID:'SYNTHETIC-ATTESTATION'},198422:{maxPerCast:2,status:'INDEPENDENTLY_VERIFIED',sourceID:'SYNTHETIC-ATTESTATION'},198423:{maxPerCast:3,status:'INDEPENDENTLY_VERIFIED',sourceID:'SYNTHETIC-ATTESTATION'}};
 const bounded=summarize({context:c,casts,caps});eq(bounded.simultaneousTestCount,6);ok(bounded.outputs.every(x=>x.expectedQuantityInterval&&x.expectedQuantityInterval[0]<=x.sampleUnconditionalE&&x.expectedQuantityInterval[1]>=x.sampleUnconditionalE));
 const p=plan({inputItemID:191462});ok(p.plannedCastsForP>0);ok(Object.values(p.plannedCastsForEByKey).every(x=>x===null));
 const pe=plan({inputItemID:191462,caps,expectedQuantityHalfWidth:0.5});ok(Object.values(pe.plannedCastsForEByKey).every(x=>Number.isSafeInteger(x)&&x>0));eq(pe.notObservedCasts,true);
 bad(()=>summarize({context:{...c,actualSkill:0},casts}));bad(()=>summarize({context:{...c,recipeSpellID:'382981'},casts}));
 bad(()=>summarize({context:{...c,outputQualityRanks:{198421:1}},casts}));
 bad(()=>summarize({context:{...c,directReagents:[{itemID:191462,quantity:4}]},casts}));
 bad(()=>summarize({context:c,casts:[ev('a',{198421:0,198422:0})]}));
 bad(()=>summarize({context:c,casts:[casts[0],casts[0]]}));
 bad(()=>summarize({context:c,casts:[ev('a',{198421:0,198422:0,198423:0},6)]}));
 bad(()=>summarize({context:c,casts,caps:{198421:{maxPerCast:0,status:'INDEPENDENTLY_VERIFIED',sourceID:'x'}}}));
 bad(()=>summarize({context:c,casts,caps:{198423:{maxPerCast:1,status:'INDEPENDENTLY_VERIFIED',sourceID:'x'}}}));
 bad(()=>summarize({context:c,casts,caps:{198421:{maxPerCast:2,status:'SCENARIO_ONLY',sourceID:'x'}}}));
 bad(()=>summarize({context:c,casts,alpha:0}));
 bad(()=>plan({inputItemID:191462,expectedQuantityHalfWidth:0}));
 const sparse=[casts[0],,casts[2]];bad(()=>summarize({context:c,casts:sparse}));
 const withHidden=casts.slice();Object.defineProperty(withHidden,'hidden',{value:1});bad(()=>summarize({context:c,casts:withHidden}));
 return {modelID:MODEL_ID,passed:n,failed:0,syntheticOnly:true,trackedKeys:TARGETS.length};
}
module.exports={MODEL_ID,POLICY,TARGETS,group,validateContext,validateCaps,summarize,plan,selfTest};
if(typeof require==='function'&&require.main===module)console.log(JSON.stringify(selfTest()));
