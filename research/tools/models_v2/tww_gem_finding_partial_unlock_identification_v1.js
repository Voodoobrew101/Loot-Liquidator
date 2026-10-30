"use strict";
/* F003 research-only: partial identification when cast-level Gem Finding unlocks are unknown.
 * Independent, not necessarily identically distributed completed casts. At a predeclared
 * fixed N, Hoeffding bounds the average occurrence probability even with heterogeneous
 * eligible casts. q is the actual eligible fraction; qLow <= q <= qHigh.
 * Ineligible casts must be structural zeros. E bounds require a scenario hard cap.
 * No current-Retail rate, baseline, economic promotion or independent evidence claimed.
 */
const MODEL_ID="tww-gem-finding-partial-unlock-identification-v1.0.0";
const INPUTS={210931:{Ruby:212495,Emerald:212505,Sapphire:212508,Onyx:212511},210934:{Ruby:212495,Onyx:212511},210937:{Emerald:212505,Sapphire:212508}};
const GEMS=["Emerald","Onyx","Ruby","Sapphire"];
const TARGETS=Object.entries(INPUTS).flatMap(([input,gems])=>Object.entries(gems).map(([gem,output])=>({recordID:"candidate:conditional:prospect:"+input+":"+output+":gem-finding:20261028",inputItemID:Number(input),outputItemID:output,gem})));
const M=TARGETS.length;
function check(ok,code){if(!ok)throw Error(code);}
function finite(x){return typeof x==="number"&&Number.isFinite(x);}
function plain(x){return x!==null&&typeof x==="object"&&!Array.isArray(x)&&Object.getPrototypeOf(x)===Object.prototype;}
function keys(x,expected){return plain(x)&&Object.keys(x).sort().join("|")===expected.slice().sort().join("|");}
function radius(n,alpha=.05,m=M){
 check(Number.isSafeInteger(n)&&n>0&&finite(alpha)&&alpha>0&&alpha<1&&Number.isSafeInteger(m)&&m>0,"ALPHA_N_DOMAIN");
 return Math.sqrt(Math.log(4*m/alpha)/(2*n)); // Bonferroni over P and E for m targets
}
function partial(mean,eps,qLow,qHigh,max=1){
 check(finite(mean)&&mean>=0&&finite(eps)&&eps>=0&&finite(qLow)&&finite(qHigh)&&qLow>=0&&qLow<=qHigh&&qHigh<=1&&finite(max)&&max>0,"BOUND_DOMAIN");
 if(qHigh===0)return null; // ineligible != measured eligible rate of zero
 const lo=Math.min(max,Math.max(0,(mean-eps)/qHigh));
 const hi=qLow===0?max:Math.min(max,(mean+eps)/qLow);
 return {lower:lo,upper:Math.max(lo,hi)};
}
function validate(s){
 check(plain(s)&&typeof s.sessionID==="string"&&s.sessionID.length>0&&typeof s.studyFamilyID==="string"&&s.studyFamilyID.length>0,"IDENTITY");
 check(s.gameMode==="Retail"&&typeof s.patchEpoch==="string"&&s.patchEpoch.length>0&&s.recipeSpellID===434018&&Number.isSafeInteger(s.inputItemID)&&Object.hasOwn(INPUTS,s.inputItemID)&&s.inputQualityRank===2&&s.nominalInputUnits===5&&typeof s.operationVariant==="string"&&s.operationVariant.length>0,"CONTEXT");
 check(s.effectiveSkill===null||(Number.isSafeInteger(s.effectiveSkill)&&s.effectiveSkill>=0),"SKILL");
 check(plain(s.professionStats),"STATS");
 for(const [k,v] of Object.entries(s.professionStats))check(k.length>0&&plain(v)&&typeof v.unit==="string"&&v.unit.length>0&&(v.value===null||(finite(v.value)&&v.value>=0)),"STAT_UNITS");
 check(Array.isArray(s.events)&&s.events.length>0,"EVENTS");
 const gemMap=INPUTS[s.inputItemID],outputIDs=Object.values(gemMap).map(String),ids=new Set(),completed=[];
 for(const e of s.events){
  check(plain(e)&&typeof e.eventID==="string"&&e.eventID.length>0&&!ids.has(e.eventID),"EVENT_ID");ids.add(e.eventID);
  if(e.status==="ABORTED"){check(e.outputCapture===null&&e.inputAccounting===null&&e.gemFindingUnlocks===null,"ABORT_RESULT");continue;}
  check(e.status==="COMPLETED"&&plain(e.outputCapture)&&e.outputCapture.complete===true&&plain(e.inputAccounting),"CAST");
  const c=e.outputCapture.countsByItemID;
  check(keys(c,outputIDs)&&Object.values(c).every(x=>Number.isSafeInteger(x)&&x>=0),"ZERO_INCLUSIVE_OUTPUTS");
  check(keys(e.gemFindingUnlocks,GEMS)&&Object.values(e.gemFindingUnlocks).every(x=>x===true||x===false||x===null),"UNLOCKS");
  const a=e.inputAccounting;
  check(a.nominalInputUnits===5&&Number.isSafeInteger(a.refundedInputUnits)&&a.refundedInputUnits>=0&&a.refundedInputUnits<=5&&a.netSpentInputUnits===5-a.refundedInputUnits,"REFUNDS");
  for(const [gem,id] of Object.entries(gemMap))check(e.gemFindingUnlocks[gem]!==false||c[String(id)]===0,"LOCKED_POSITIVE");
  completed.push(e);
 }
 check(completed.length>0&&s.predeclaredFixedCompletedCasts===completed.length,"FIXED_N_REQUIRED");
 const caps=s.scenarioCaps===undefined||s.scenarioCaps===null?{}:s.scenarioCaps;
 check(plain(caps),"CAPS");
 for(const [id,cap] of Object.entries(caps))check(outputIDs.includes(id)&&plain(cap)&&Number.isSafeInteger(cap.maxPerCompletedCast)&&cap.maxPerCompletedCast>0&&cap.status==="SCENARIO_ONLY"&&typeof cap.provenance==="string"&&cap.provenance.length>0,"UNVERIFIED_CAP");
 return {gemMap,completed,caps};
}
function analyze(s,alpha=.05){
 const {gemMap,completed,caps}=validate(s),n=completed.length,eps=radius(n,alpha);
 const refund=completed.reduce((v,e)=>v+e.inputAccounting.refundedInputUnits,0);
 const rows=Object.entries(gemMap).map(([gem,id])=>{
  const values=completed.map(e=>e.outputCapture.countsByItemID[String(id)]),states=completed.map(e=>e.gemFindingUnlocks[gem]);
  const yes=states.filter(x=>x===true).length,no=states.filter(x=>x===false).length,unknown=states.filter(x=>x===null).length;
  const forced=states.filter((x,i)=>x===null&&values[i]>0).length;
  const qLow=(yes+forced)/n,qHigh=(yes+unknown)/n;
  const hits=values.filter(x=>x>0).length,total=values.reduce((a,b)=>a+b,0);
  check(Number.isSafeInteger(total),"OUTPUT_OVERFLOW");
  const cap=caps[String(id)]||null;
  if(cap)check(values.every(v=>v<=cap.maxPerCompletedCast),"SCENARIO_CAP_EXCEEDED");
  return {recordID:TARGETS.find(t=>t.inputItemID===s.inputItemID&&t.outputItemID===id).recordID,
   gem,outputItemID:id,completedCasts:n,positiveCasts:hits,totalOutputUnits:total,
   knownEligibleCasts:yes,knownIneligibleCasts:no,unknownUnlockCasts:unknown,unknownPositiveForcesEligibility:forced,
   eligibleFractionBounds:{lower:qLow,upper:qHigh},
   descriptivePAllCasts:hits/n,descriptiveEAllCasts:total/n,
   eligibleCohortPBounds:partial(hits/n,eps,qLow,qHigh),
   eligibleCohortEBounds:cap?partial(total/n,eps*cap.maxPerCompletedCast,qLow,qHigh,cap.maxPerCompletedCast):null,
   eBoundsStatus:cap?"SCENARIO_ONLY_NOT_VERIFIED":"MISSING_INDEPENDENT_HARD_CAP",
   scenarioCap:cap?{...cap}:null,confidence:0,economicUse:"PREVIEW_ONLY",normalizedVerified:false,
   evidenceFields:{dropChance:null,yieldMin:null,yieldMax:null,expectedQuantity:null},
   goldRecommendationEligible:false,tooltipFallbackEligible:false};
 });
 return {modelID:MODEL_ID,sessionID:s.sessionID,studyFamilyID:s.studyFamilyID,
  context:{gameMode:s.gameMode,patchEpoch:s.patchEpoch,recipeSpellID:s.recipeSpellID,inputItemID:s.inputItemID,inputQualityRank:s.inputQualityRank,operationVariant:s.operationVariant,effectiveSkill:s.effectiveSkill,professionStats:JSON.parse(JSON.stringify(s.professionStats))},
  completedCasts:n,abortedRequests:s.events.length-n,grossNominalInputUnits:5*n,refundedInputUnits:refund,netInputUnits:5*n-refund,
  alpha,predeclaredRelationships:M,simultaneousFields:2*M,perFieldProbabilityRadius:eps,
  coverage:"FIXED_N_HOEFFDING_FAMILYWISE_CONDITIONAL_ON_STRUCTURAL_ZERO_INDEPENDENT_CASTS_AND_VALID_ELIGIBILITY",
  coOutputsIndependentRequired:false,unknownUnlockNotZero:true,sourceLineage:"CALLER_SUPPLIED_NOT_INDEPENDENTLY_VERIFIED",
  confidence:0,economicUse:"PREVIEW_ONLY",normalizedVerified:false,rows};
}
function synthetic(){
 const z=()=>({"212495":0,"212505":0,"212508":0,"212511":0});
 const cast=(id,c,u,refund=0)=>({eventID:String(id),status:"COMPLETED",outputCapture:{complete:true,countsByItemID:c},gemFindingUnlocks:{Ruby:null,Emerald:null,Sapphire:null,Onyx:null,...u},inputAccounting:{nominalInputUnits:5,refundedInputUnits:refund,netSpentInputUnits:5-refund}});
 return {sessionID:"SYN-1",studyFamilyID:"SYNTHETIC-NOT-EVIDENCE",gameMode:"Retail",patchEpoch:"SYNTHETIC",recipeSpellID:434018,inputItemID:210931,inputQualityRank:2,nominalInputUnits:5,operationVariant:"SYNTHETIC",effectiveSkill:null,professionStats:{resourcefulness:{value:null,unit:"rating"}},predeclaredFixedCompletedCasts:5,
 events:[cast(1,{...z(),"212495":1,"212505":2},{Ruby:true},1),cast(2,z(),{Ruby:false,Emerald:false}),cast(3,{...z(),"212495":2},{}),cast(4,z(),{Emerald:true}),cast(5,z(),{Ruby:true}),{eventID:"abort",status:"ABORTED",outputCapture:null,gemFindingUnlocks:null,inputAccounting:null}]};
}
function selfTest(){
 let passed=0;const ok=(v,name)=>{passed++;check(v,"TEST_"+name);};
 const bad=(fn,name)=>{passed++;let rejected=false;try{fn();}catch(e){rejected=true;}check(rejected,"TEST_EXPECT_REJECT_"+name);};
 const copy=x=>JSON.parse(JSON.stringify(x)),s=synthetic(),r=analyze(s),ruby=r.rows.find(x=>x.gem==="Ruby");
 ok(TARGETS.length===8,"TARGETS");ok(r.completedCasts===5&&r.abortedRequests===1,"DENOMINATOR");
 ok(r.grossNominalInputUnits===25&&r.refundedInputUnits===1&&r.netInputUnits===24,"REFUNDS");
 ok(ruby.knownEligibleCasts===2&&ruby.knownIneligibleCasts===1&&ruby.unknownUnlockCasts===2,"UNLOCKS");
 ok(ruby.unknownPositiveForcesEligibility===1&&ruby.eligibleFractionBounds.lower===.6&&ruby.eligibleFractionBounds.upper===.8,"ELIGIBILITY_BOUNDS");
 ok(ruby.positiveCasts===2&&ruby.totalOutputUnits===3&&ruby.descriptiveEAllCasts===.6,"E_VS_P");
 ok(r.rows.every(x=>x.confidence===0&&x.economicUse==="PREVIEW_ONLY"&&!x.normalizedVerified&&!x.goldRecommendationEligible&&!x.tooltipFallbackEligible),"ISOLATION");
 ok(r.rows.every(x=>x.eligibleCohortEBounds===null),"NO_HARD_CAP");
 ok(radius(1000)<radius(100),"PRECISION");
 ok(Math.abs(partial(.4,.05,.5,.8).lower-.35/.8)<1e-12,"LOWER");
 ok(Math.abs(partial(.4,.05,.5,.8).upper-.9)<1e-12,"UPPER");
 ok(partial(0,.1,0,.5).upper===1&&partial(0,.1,0,0)===null,"INELIGIBLE");
 const cap=copy(s);cap.scenarioCaps={"212495":{maxPerCompletedCast:3,status:"SCENARIO_ONLY",provenance:"SYNTHETIC_HYPOTHESIS"}};
 ok(analyze(cap).rows.find(x=>x.gem==="Ruby").eligibleCohortEBounds!==null,"SCENARIO_CAP");
 const high=copy(cap);high.scenarioCaps["212495"].maxPerCompletedCast=1;bad(()=>analyze(high),"CAP_TOO_LOW");
 const fake=copy(cap);fake.scenarioCaps["212495"].status="VERIFIED";bad(()=>analyze(fake),"FAKE_VERIFICATION");
 const mutate=(f,name)=>{const x=copy(s);f(x);bad(()=>analyze(x),name);};
 mutate(x=>x.predeclaredFixedCompletedCasts=6,"N_NOT_PREDECLARED");
 mutate(x=>x.events[0].outputCapture.countsByItemID["212495"]=-1,"NEGATIVE");
 mutate(x=>delete x.events[0].outputCapture.countsByItemID["212505"],"MISSING_ZERO");
 mutate(x=>x.events[0].gemFindingUnlocks.Ruby=false,"LOCKED_POSITIVE");
 mutate(x=>x.events[0].inputAccounting.netSpentInputUnits=5,"REFUND_MISMATCH");
 mutate(x=>x.events[5].outputCapture={complete:true},"ABORT_RESULT");
 mutate(x=>x.events[0].eventID=x.events[1].eventID,"DUPLICATE_EVENT");
 mutate(x=>x.effectiveSkill=NaN,"SKILL_NAN");
 mutate(x=>x.professionStats.resourcefulness.unit="","STAT_UNIT");
 mutate(x=>x.inputQualityRank=3,"INPUT_RANK");
 mutate(x=>x.events[2].gemFindingUnlocks.Ruby="UNKNOWN","BAD_UNLOCK");
 return {passed,failed:0,syntheticOnly:true,actualRetailCasts:0,independentLineages:0,economicPromotions:0};
}
module.exports={MODEL_ID,INPUTS,TARGETS,radius,partial,validate,analyze,synthetic,selfTest};
if(require.main===module)console.log(JSON.stringify(process.argv.includes("--self-test")?selfTest():analyze(synthetic()),null,2));
