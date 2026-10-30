'use strict';
/* Research-only; all estimates confidence 0, PREVIEW_ONLY. */
const KEYS=[
  "historical:tww:mill:210796:222619:reddit-1fdmzwy-2024",
  "historical:tww:mill:210797:222619:reddit-1fdmzwy-2024",
  "candidate:tww:mill:210798:222618:runtime-method-family:20261028",
  "candidate:tww:mill:210799:222612:runtime-method-family:20261028",
  "candidate:tww:mill:210800:222613:runtime-method-family:20261028",
  "candidate:tww:mill:210801:222614:runtime-method-family:20261028",
  "candidate:tww:mill:210802:224800:runtime-method-family:20261028",
  "candidate:tww:mill:210803:224801:runtime-method-family:20261028",
  "candidate:tww:mill:210804:224802:runtime-method-family:20261028",
  "candidate:tww:mill:210805:224803:runtime-method-family:20261028",
  "candidate:tww:mill:210806:224804:runtime-method-family:20261028",
  "candidate:tww:mill:210807:224805:runtime-method-family:20261028"
];
function plain(x,label){
 if(!x||typeof x!=="object"||Array.isArray(x)||Object.getPrototypeOf(x)!==Object.prototype)throw Error(label+" not plain object");
 for(const k of Reflect.ownKeys(x)){const d=Object.getOwnPropertyDescriptor(x,k);if(typeof k!=="string"||!d.enumerable||!("value" in d))throw Error(label+" unsafe metadata");}
 return x;
}

function uint(x,label,min=0){if(!Number.isSafeInteger(x)||x<min)throw Error(label+" invalid integer");return x;}

function denominator(x){
 plain(x,"accounting");const b=uint(x.nominalBatchSize,"batch",1);
 const n=x.netConsumed==null?null:uint(x.netConsumed,"net");
 const s=x.savedTotal==null?null:uint(x.savedTotal,"saved");
 const c=x.completedCasts==null?null:uint(x.completedCasts,"casts");
 let cap=null;if(x.maxSavedPerCast!=null){cap=plain(x.maxSavedPerCast,"cap");uint(cap.units,"cap units");if(cap.units>=b||!["INDEPENDENTLY_VERIFIED","SCENARIO_ONLY"].includes(cap.status)||typeof cap.sourceID!=="string"||!cap.sourceID.trim())throw Error("cap lacks valid provenance");}
 const status=cap?cap.status:null;
 if(c!==null){
  const gross=c*b;if(!Number.isSafeInteger(gross)||n!==null&&n>gross||s!==null&&s>gross||n!==null&&s!==null&&n+s!==gross)throw Error("reagent conservation failure");
  if(cap&&(s!==null&&s>c*cap.units||n!==null&&gross-n>c*cap.units))throw Error("saving cap contradiction");
  return {min:c,max:c,identified:true,reason:"ACTUAL_CASTS",capStatus:status};
 }
 if(n===null)return {min:null,max:null,identified:false,reason:"NO_CAST_DENOMINATOR",capStatus:status};
 if(s!==null){
  const gross=n+s;if(!Number.isSafeInteger(gross)||gross%b!==0)throw Error("reagent conservation not divisible");
  const count=gross/b;if(cap&&s>count*cap.units)throw Error("saving cap contradiction");
  return {min:count,max:count,identified:true,reason:"NET_PLUS_SAVED",capStatus:status};
 }
 const lo=Math.ceil(n/b);
 if(!cap)return {min:lo,max:null,identified:false,reason:"UNKNOWN_REFUNDS",capStatus:null};
 const hi=Math.floor(n/(b-cap.units));if(hi<lo)throw Error("infeasible saving cap");
 return {min:lo,max:hi,identified:lo===hi,reason:"BOUNDED_BY_SAVINGS",capStatus:status};
}

function estimate(x){
 plain(x,"study");const c=plain(x.context,"context");
 if(!KEYS.includes(c.targetKey)||c.expansion!=="tww"||c.method!=="mill"||c.gameMode!=="retail"||typeof c.patchEpoch!=="string"||!c.patchEpoch||typeof c.studyFamily!=="string"||!c.studyFamily)throw Error("context not admitted");
 const parts=c.targetKey.split(":");
 if(uint(c.inputItemID,"input",1)!==Number(parts[3])||uint(c.outputItemID,"output",1)!==Number(parts[4]))throw Error("mapping identity mismatch");
 if(c.minimumEligibleSkill!=null)uint(c.minimumEligibleSkill,"minimum skill");
 if(c.actualSkill!=null)uint(c.actualSkill,"actual skill");
 if(c.minimumEligibleSkill!=null&&c.actualSkill!=null&&c.actualSkill<c.minimumEligibleSkill)throw Error("recipe ineligible");
 let casts=x.completedCasts,outputs=x.totalOutputs,success=x.positiveCasts,observedConditionalRange=null;
 if(x.perCastOutputs!=null){
  const a=x.perCastOutputs;if(!Array.isArray(a)||Object.getPrototypeOf(a)!==Array.prototype||!a.length||a.length>1000000||Reflect.ownKeys(a).length!==a.length+1)throw Error("unsafe or sparse cast array");
  let total=0,pos=0,min=Infinity,max=0;
  for(let i=0;i<a.length;i++){const d=Object.getOwnPropertyDescriptor(a,String(i));if(!d||!("value" in d))throw Error("cast accessor/hole");const v=uint(d.value,"output");total+=v;if(!Number.isSafeInteger(total))throw Error("output overflow");if(v>0){pos++;min=Math.min(min,v);max=Math.max(max,v);}}
  if(casts!=null&&casts!==a.length||outputs!=null&&outputs!==total||success!=null&&success!==pos)throw Error("aggregates disagree");
  casts=a.length;outputs=total;success=pos;observedConditionalRange=pos?{min,max}:{min:null,max:null};
 }
 const d=denominator({nominalBatchSize:x.nominalBatchSize,netConsumed:x.netConsumed,savedTotal:x.savedTotal,completedCasts:casts,maxSavedPerCast:x.maxSavedPerCast});
 outputs=outputs==null?null:uint(outputs,"total outputs");
 success=success==null?null:uint(success,"positive casts");
 if(outputs===0&&success!=null&&success!==0||outputs!=null&&outputs>0&&success===0||success!=null&&outputs!=null&&success>outputs||success!=null&&d.max!=null&&success>d.max||outputs!=null&&outputs>0&&d.max===0)throw Error("output count contradiction");
 const lo=d.min==null?null:Math.max(d.min,success||0),hi=d.max;
 const E=outputs!=null&&lo!=null&&lo>0?{lower:hi==null?0:outputs/hi,upper:outputs/lo}:null;
 const P=success!=null&&lo!=null&&lo>0?{lower:hi==null?0:success/hi,upper:Math.min(1,success/lo)}:null;
 return {modelID:"tww-mill-reagent-accounting-identification-v1.0.0",targetKey:c.targetKey,studyFamily:c.studyFamily,patchEpoch:c.patchEpoch,denominator:d,empiricalE:E,empiricalP:P,observedConditionalRange,interpretation:"SAMPLE_OR_CONDITIONAL_IDENTIFICATION_NOT_POPULATION_CONFIDENCE_INTERVAL",confidence:0,economicUse:"PREVIEW_ONLY",normalizedVerified:false,usableForLiveEV:false,usableForRecommendation:false};
}

function forward(P,conditionalMean){
 if(typeof P!=="number"||!Number.isFinite(P)||P<0||P>1||typeof conditionalMean!=="number"||!Number.isFinite(conditionalMean)||conditionalMean<0||P>0&&conditionalMean===0)throw Error("invalid forward model");
 return {unconditionalE:P*conditionalMean,status:"SCENARIO_ONLY"};
}

function inverse(E,P){
 if(typeof E!=="number"||!Number.isFinite(E)||E<0||typeof P!=="number"||!Number.isFinite(P)||P<0||P>1)throw Error("invalid inverse model");
 if(P===0){if(E!==0)throw Error("P=0 requires E=0");return {conditionalMean:null,identified:false};}
 if(E===0)throw Error("positive P requires positive E");
 return {conditionalMean:E/P,identified:true,hardYieldBound:false};
}

function selfTest(){
 let n=0;const eq=(a,b)=>{if(!Object.is(a,b))throw Error("assertion mismatch "+a+" vs "+b);n++;};const bad=f=>{let t=false;try{f();}catch(e){t=true;}if(!t)throw Error("expected rejection");n++;};
 const ctx={targetKey:KEYS[2],expansion:"tww",method:"mill",gameMode:"retail",inputItemID:210798,outputItemID:222618,patchEpoch:"synthetic",studyFamily:"synthetic"};
 eq(KEYS.length,12);eq(denominator({nominalBatchSize:5,netConsumed:45,savedTotal:5}).min,10);eq(denominator({nominalBatchSize:5,netConsumed:45}).max,null);
 eq(denominator({nominalBatchSize:5,netConsumed:45,maxSavedPerCast:{units:1,status:"SCENARIO_ONLY",sourceID:"synthetic"}}).max,11);
 bad(()=>denominator({nominalBatchSize:5,netConsumed:45,savedTotal:4}));
 bad(()=>denominator({nominalBatchSize:5,netConsumed:45,completedCasts:10,savedTotal:4}));
 bad(()=>denominator({nominalBatchSize:5,netConsumed:45,maxSavedPerCast:{units:5,status:"SCENARIO_ONLY",sourceID:"x"}}));
 bad(()=>denominator({nominalBatchSize:5,netConsumed:45,maxSavedPerCast:{units:1,status:"UNVERIFIED",sourceID:"x"}}));
 const a=estimate({context:ctx,nominalBatchSize:5,netConsumed:20,savedTotal:5,perCastOutputs:[0,2,0,1,0]});
 eq(a.empiricalE.lower,0.6);eq(a.empiricalP.lower,0.4);eq(a.observedConditionalRange.max,2);eq(a.usableForLiveEV,false);
 const b=estimate({context:ctx,nominalBatchSize:5,netConsumed:45,totalOutputs:20,positiveCasts:5,maxSavedPerCast:{units:1,status:"SCENARIO_ONLY",sourceID:"synthetic"}});
 eq(b.empiricalE.lower,20/11);eq(b.empiricalE.upper,20/9);eq(b.empiricalP.lower,5/11);eq(b.empiricalP.upper,5/9);
 eq(estimate({context:ctx,nominalBatchSize:5,netConsumed:45,totalOutputs:20}).empiricalE.lower,0);
 bad(()=>estimate({context:{...ctx,inputItemID:210799},nominalBatchSize:5,completedCasts:2,totalOutputs:2}));
 bad(()=>estimate({context:ctx,nominalBatchSize:5,completedCasts:2,totalOutputs:0,positiveCasts:1}));
 bad(()=>estimate({context:ctx,nominalBatchSize:5,completedCasts:2,totalOutputs:1,positiveCasts:2}));
 bad(()=>estimate({context:ctx,nominalBatchSize:5,perCastOutputs:[0,,2]}));
 const getter=[0,1];Object.defineProperty(getter,"0",{get(){return 0},enumerable:true});bad(()=>estimate({context:ctx,nominalBatchSize:5,perCastOutputs:getter}));
 eq(forward(0.4,2).unconditionalE,0.8);eq(inverse(0.8,0.4).conditionalMean,2);eq(inverse(0,0).identified,false);bad(()=>inverse(1,0));bad(()=>forward(1.2,1));
 for(let batch=2;batch<=12;batch++)for(let cap=0;cap<batch;cap++)for(let net=1;net<=100;net++){
  const arg={nominalBatchSize:batch,netConsumed:net,maxSavedPerCast:{units:cap,status:"SCENARIO_ONLY",sourceID:"synthetic"}};
  const lo=Math.ceil(net/batch),hi=Math.floor(net/(batch-cap));
  if(hi<lo){bad(()=>denominator(arg));continue;}
  const d=denominator(arg);eq(d.min,lo);eq(d.max,hi);
  let count=0;for(let c=1;c<=100;c++)if(c*batch-net>=0&&c*batch-net<=c*cap)count++;
  eq(count,hi-lo+1);
 }
 return {passed:n,failed:0,syntheticOnly:true};
}
if(typeof module!=='undefined')module.exports={KEYS,denominator,estimate,forward,inverse,selfTest};
if(typeof require!=='undefined'&&require.main===module&&process.argv.includes('--self-test'))console.log(JSON.stringify(selfTest()));
