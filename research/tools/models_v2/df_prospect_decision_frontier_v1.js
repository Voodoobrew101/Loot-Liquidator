"use strict";
/* F003 research-only scenario frontier for 38 priority-102 Dragonflight prospecting E gaps.
   No live EV/recommendation, no TSM data rewrite, no tooltip-only fallback. */
const MODEL_ID="df-prospect-decision-frontier-v1.0.0";
const POLICY=Object.freeze({"confidence":0,"economicUse":"PREVIEW_ONLY","normalizedVerified":false,"liveEconomicEligible":false,"tooltipOnlyEligible":false});
const TARGETS=Object.freeze([{"stableKey":"tsm:prospect:188658:192837:L1174","inputItemID":188658,"outputItemID":192837},{"stableKey":"tsm:prospect:188658:192838:L1175","inputItemID":188658,"outputItemID":192838},{"stableKey":"tsm:prospect:188658:192839:L1176","inputItemID":188658,"outputItemID":192839},{"stableKey":"tsm:prospect:188658:192840:L1177","inputItemID":188658,"outputItemID":192840},{"stableKey":"tsm:prospect:188658:192841:L1178","inputItemID":188658,"outputItemID":192841},{"stableKey":"tsm:prospect:188658:192842:L1179","inputItemID":188658,"outputItemID":192842},{"stableKey":"tsm:prospect:188658:192843:L1180","inputItemID":188658,"outputItemID":192843},{"stableKey":"tsm:prospect:188658:192844:L1181","inputItemID":188658,"outputItemID":192844},{"stableKey":"tsm:prospect:188658:192845:L1182","inputItemID":188658,"outputItemID":192845},{"stableKey":"tsm:prospect:188658:192846:L1183","inputItemID":188658,"outputItemID":192846},{"stableKey":"tsm:prospect:188658:192847:L1184","inputItemID":188658,"outputItemID":192847},{"stableKey":"tsm:prospect:188658:192848:L1185","inputItemID":188658,"outputItemID":192848},{"stableKey":"tsm:prospect:188658:192849:L1186","inputItemID":188658,"outputItemID":192849},{"stableKey":"tsm:prospect:188658:192850:L1187","inputItemID":188658,"outputItemID":192850},{"stableKey":"tsm:prospect:188658:192851:L1188","inputItemID":188658,"outputItemID":192851},{"stableKey":"tsm:prospect:188658:192852:L1189","inputItemID":188658,"outputItemID":192852},{"stableKey":"tsm:prospect:188658:192853:L1190","inputItemID":188658,"outputItemID":192853},{"stableKey":"tsm:prospect:188658:192855:L1191","inputItemID":188658,"outputItemID":192855},{"stableKey":"tsm:prospect:188658:192856:L1192","inputItemID":188658,"outputItemID":192856},{"stableKey":"tsm:prospect:188658:192857:L1193","inputItemID":188658,"outputItemID":192857},{"stableKey":"tsm:prospect:188658:192858:L1194","inputItemID":188658,"outputItemID":192858},{"stableKey":"tsm:prospect:188658:192859:L1195","inputItemID":188658,"outputItemID":192859},{"stableKey":"tsm:prospect:188658:192860:L1196","inputItemID":188658,"outputItemID":192860},{"stableKey":"tsm:prospect:188658:192861:L1197","inputItemID":188658,"outputItemID":192861},{"stableKey":"tsm:prospect:188658:192862:L1198","inputItemID":188658,"outputItemID":192862},{"stableKey":"tsm:prospect:188658:192863:L1199","inputItemID":188658,"outputItemID":192863},{"stableKey":"tsm:prospect:188658:192865:L1200","inputItemID":188658,"outputItemID":192865},{"stableKey":"tsm:prospect:188658:192866:L1201","inputItemID":188658,"outputItemID":192866},{"stableKey":"tsm:prospect:188658:192867:L1202","inputItemID":188658,"outputItemID":192867},{"stableKey":"tsm:prospect:188658:192868:L1203","inputItemID":188658,"outputItemID":192868},{"stableKey":"tsm:prospect:188658:192869:L1204","inputItemID":188658,"outputItemID":192869},{"stableKey":"tsm:prospect:189143:192837:L1212","inputItemID":189143,"outputItemID":192837},{"stableKey":"tsm:prospect:189143:192838:L1213","inputItemID":189143,"outputItemID":192838},{"stableKey":"tsm:prospect:189143:192839:L1214","inputItemID":189143,"outputItemID":192839},{"stableKey":"tsm:prospect:189143:192840:L1215","inputItemID":189143,"outputItemID":192840},{"stableKey":"tsm:prospect:189143:192841:L1216","inputItemID":189143,"outputItemID":192841},{"stableKey":"tsm:prospect:189143:192842:L1217","inputItemID":189143,"outputItemID":192842},{"stableKey":"tsm:prospect:189143:192843:L1218","inputItemID":189143,"outputItemID":192843}].map(x=>Object.freeze(x)));
function check(ok,code){if(!ok)throw Error(code);}

function finiteNonnegative(x){return typeof x==="number"&&Number.isFinite(x)&&x>=0;}

function record(x,allowed,required){
 check(x!==null&&typeof x==="object"&&!Array.isArray(x)&&Object.getPrototypeOf(x)===Object.prototype,"PLAIN_RECORD");
 const keys=Reflect.ownKeys(x);check(keys.every(k=>typeof k==="string"&&allowed.includes(k)),"UNEXPECTED_FIELD");
 for(const k of keys){const d=Object.getOwnPropertyDescriptor(x,k);check(d&&d.enumerable&&"value"in d,"ACCESSOR_OR_HIDDEN_FIELD");}
 for(const k of required)check(Object.prototype.hasOwnProperty.call(x,k),"REQUIRED_FIELD_"+k);
}

function snapshotRecord(x,allowed,required){
 record(x,allowed,required);
 const out={};
 for(const k of Reflect.ownKeys(x)){
  const d=Object.getOwnPropertyDescriptor(x,k);
  for(let i=0;i<3;i++)check(Object.is(x[k],d.value),"UNSTABLE_FIELD_"+k);
  out[k]=d.value;
 }
 return Object.freeze(out);
}
function snapshotOutputs(a){
 dense(a);
 const out=[];
 for(let i=0;i<a.length;i++){
  const d=Object.getOwnPropertyDescriptor(a,String(i));
  for(let j=0;j<3;j++)check(Object.is(a[i],d.value),"UNSTABLE_OUTPUT_ARRAY");
  out.push(snapshotRecord(d.value,["stableKey","priceGold","eLower","eUpper"],["stableKey","priceGold","eLower","eUpper"]));
 }
 return Object.freeze(out);
}
function dense(a){
 check(Array.isArray(a)&&Object.getPrototypeOf(a)===Array.prototype&&a.length>0,"DENSE_ARRAY");
 const keys=Reflect.ownKeys(a);check(keys.length===a.length+1&&keys.includes("length"),"ARRAY_EXTRA_OR_HOLE");
 for(let i=0;i<a.length;i++){const d=Object.getOwnPropertyDescriptor(a,String(i));check(d&&d.enumerable&&"value"in d,"ARRAY_ACCESSOR_OR_HOLE");}
}

function dateOnly(x){
 check(typeof x==="string"&&/^\d{4}-\d{2}-\d{2}$/.test(x),"SNAPSHOT_DATE");
 const [y,m,d]=x.split("-").map(Number);
 check(y>=2000&&y<=2200&&new Date(Date.UTC(y,m-1,d)).toISOString().slice(0,10)===x,"SNAPSHOT_DATE");
}

function sumSafe(values){
 let s=0;for(const v of values){check(Number.isFinite(v),"NONFINITE_COMPONENT");s+=v;check(Number.isFinite(s),"NONFINITE_SUM");}return s;
}

function evaluateScenario(s){
 s=snapshotRecord(s,["inputItemID","snapshotDate","scenarioSourceID","policy","nominalInputPerCast","costGoldPerCast","depositGoldPerCast","alternativeNetGoldPerCast","feeRate","otherRevenueGoldPerCast","otherRevenueBasis","costBasis","refundSourceID","outputs"],["inputItemID","snapshotDate","scenarioSourceID","policy","nominalInputPerCast","costGoldPerCast","depositGoldPerCast","alternativeNetGoldPerCast","feeRate","otherRevenueGoldPerCast","otherRevenueBasis","costBasis","outputs"]);
 check(s.policy==="SCENARIO_ONLY","SCENARIO_POLICY");
 check(s.inputItemID===188658||s.inputItemID===189143,"INPUT_FAMILY");
 dateOnly(s.snapshotDate);
 check(typeof s.scenarioSourceID==="string"&&s.scenarioSourceID.trim().length>0&&s.scenarioSourceID.length<=256,"SOURCE_ID");
 check(s.nominalInputPerCast===5,"NOMINAL_DF_FIVE_ORE");
 for(const k of ["costGoldPerCast","depositGoldPerCast","alternativeNetGoldPerCast","feeRate","otherRevenueGoldPerCast"])check(finiteNonnegative(s[k]),"SCENARIO_NUMBER_"+k);
 check(s.feeRate<1,"FEE_RATE");
 check(s.otherRevenueBasis==="EXCLUDES_SELECTED_OUTPUTS","OTHER_REVENUE_OVERLAP_GUARD");
 check(s.costBasis==="GROSS_NO_REFUNDS"||s.costBasis==="NET_WITH_ATTESTED_REFUNDS","COST_BASIS");
 if(s.costBasis==="NET_WITH_ATTESTED_REFUNDS")check(typeof s.refundSourceID==="string"&&s.refundSourceID.trim().length>0,"REFUND_PROVENANCE");
 else check(!Object.prototype.hasOwnProperty.call(s,"refundSourceID"),"UNSUPPORTED_REFUND_FIELD");
 s=Object.freeze({...s,outputs:snapshotOutputs(s.outputs)});
 const seen=new Set(),rows=[];
 for(const o of s.outputs){
  record(o,["stableKey","priceGold","eLower","eUpper"],["stableKey","priceGold","eLower","eUpper"]);
  const target=TARGETS.find(t=>t.stableKey===o.stableKey);
  check(target&&target.inputItemID===s.inputItemID,"UNKNOWN_OR_CROSS_INPUT_KEY");
  check(!seen.has(o.stableKey),"DUPLICATE_KEY");seen.add(o.stableKey);
  check(finiteNonnegative(o.priceGold)&&finiteNonnegative(o.eLower),"OUTPUT_PRICE_OR_LOWER");
  check(o.eUpper===null||(finiteNonnegative(o.eUpper)&&o.eUpper>=o.eLower),"OUTPUT_UPPER");
  const netPrice=o.priceGold*(1-s.feeRate);
  check(Number.isFinite(netPrice),"NET_PRICE_OVERFLOW");
  const low=netPrice*o.eLower,high=o.eUpper===null?null:netPrice*o.eUpper;
  check(Number.isFinite(low)&&(high===null||Number.isFinite(high)),"REVENUE_OVERFLOW");
  check(high===null||high>=low,"ORDERED_OUTPUT_REVENUE");
  rows.push({stableKey:o.stableKey,outputItemID:target.outputItemID,netPrice,eLower:o.eLower,eUpper:o.eUpper,low,high});
 }
 const offset=s.otherRevenueGoldPerCast-s.costGoldPerCast-s.depositGoldPerCast;
 check(Number.isFinite(offset),"OFFSET_OVERFLOW");
 const lowerNet=sumSafe([offset,...rows.map(r=>r.low)]);
 const upperNet=rows.every(r=>r.high!==null)?sumSafe([offset,...rows.map(r=>r.high)]):null;
 check(upperNet===null||upperNet>=lowerNet,"ORDERED_NET_BOUNDS");
 const alternative=s.alternativeNetGoldPerCast;
 const status=lowerNet>alternative?"PROSPECT_WINS_IN_SCENARIO":upperNet!==null&&upperNet<alternative?"ALTERNATIVE_WINS_IN_SCENARIO":"INDETERMINATE";
 const sensitivity=rows.map(r=>{
  const others=rows.filter(x=>x!==r);
  const othersLow=sumSafe([offset,...others.map(x=>x.low)]);
  const othersHigh=others.every(x=>x.high!==null)?sumSafe([offset,...others.map(x=>x.high)]):null;
  const maxRequiredE=r.netPrice>0?(alternative-othersLow)/r.netPrice:null;
  const minRequiredE=r.netPrice>0&&othersHigh!==null?(alternative-othersHigh)/r.netPrice:null;
  check((maxRequiredE===null||Number.isFinite(maxRequiredE))&&(minRequiredE===null||Number.isFinite(minRequiredE)),"THRESHOLD_OVERFLOW");
  return {stableKey:r.stableKey,outputItemID:r.outputItemID,netGoldPerExtraExpectedUnit:r.netPrice,uncertaintyGold:r.high===null?null:r.high-r.low,requiredEAtOtherLower:maxRequiredE,requiredEAtOtherUpper:minRequiredE};
 }).sort((a,b)=>(b.uncertaintyGold===null?Infinity:b.uncertaintyGold)-(a.uncertaintyGold===null?Infinity:a.uncertaintyGold)||a.stableKey.localeCompare(b.stableKey));
 return {modelID:MODEL_ID,policy:POLICY,scope:"RESEARCH_ONLY_SYNTHETIC_SCENARIO_NOT_LIVE_EV",sourceID:s.scenarioSourceID,snapshotDate:s.snapshotDate,inputItemID:s.inputItemID,selectedKeys:rows.map(r=>r.stableKey),lowerNetGoldPerCompletedCast:lowerNet,upperNetGoldPerCompletedCast:upperNet,alternativeNetGoldPerCompletedCast:alternative,scenarioDecision:status,sensitivity,independentStudies:0,confidencePromotions:0,economicPromotions:0};
}

function selfTest(){
 let passed=0;const ok=(condition,label)=>{check(condition,"TEST_"+label);passed++;};
 const bad=(fn,label)=>{let thrown=false;try{fn();}catch(e){thrown=true;}ok(thrown,label);};
 const key=TARGETS[0].stableKey,key2=TARGETS[1].stableKey;
 const base={inputItemID:188658,snapshotDate:"2026-10-30",scenarioSourceID:"synthetic-test-family",policy:"SCENARIO_ONLY",nominalInputPerCast:5,costGoldPerCast:3,depositGoldPerCast:0,alternativeNetGoldPerCast:6,feeRate:0.05,otherRevenueGoldPerCast:0,otherRevenueBasis:"EXCLUDES_SELECTED_OUTPUTS",costBasis:"GROSS_NO_REFUNDS",outputs:[{stableKey:key,priceGold:10,eLower:0.5,eUpper:1}]};
 ok(TARGETS.length===38,"38_KEYS");
 ok(new Set(TARGETS.map(x=>x.stableKey)).size===38,"UNIQUE_KEYS");
 const r=evaluateScenario(base);
 ok(Math.abs(r.lowerNetGoldPerCompletedCast-1.75)<1e-10,"LOWER_EV");
 ok(Math.abs(r.upperNetGoldPerCompletedCast-6.5)<1e-10,"UPPER_EV");
 ok(r.scenarioDecision==="INDETERMINATE","CROSSING");
 ok(Math.abs(r.sensitivity[0].requiredEAtOtherLower-9/9.5)<1e-10,"BREAK_EVEN");
 ok(r.policy.confidence===0&&r.policy.economicUse==="PREVIEW_ONLY"&&r.policy.normalizedVerified===false,"POLICY");
 ok(evaluateScenario({...base,alternativeNetGoldPerCast:1}).scenarioDecision==="PROSPECT_WINS_IN_SCENARIO","LOWER_DOMINATES");
 ok(evaluateScenario({...base,alternativeNetGoldPerCast:7}).scenarioDecision==="ALTERNATIVE_WINS_IN_SCENARIO","UPPER_BELOW");
 const unknown=evaluateScenario({...base,outputs:[{stableKey:key,priceGold:10,eLower:0,eUpper:null}]});
 ok(unknown.upperNetGoldPerCompletedCast===null&&unknown.scenarioDecision==="INDETERMINATE","UNKNOWN_NOT_ZERO");
 ok(unknown.sensitivity[0].uncertaintyGold===null,"UNKNOWN_UNCERTAINTY");
 ok(evaluateScenario({...base,outputs:[{stableKey:key,priceGold:0,eLower:0,eUpper:null}]}).sensitivity[0].requiredEAtOtherLower===null,"ZERO_PRICE");
 const multi=evaluateScenario({...base,outputs:[{stableKey:key,priceGold:10,eLower:1,eUpper:2},{stableKey:key2,priceGold:20,eLower:1,eUpper:2}]});
 ok(multi.lowerNetGoldPerCompletedCast===25.5,"MULTI_OUTPUT_NOT_NORMALIZED");
 ok(multi.sensitivity[0].requiredEAtOtherUpper< multi.sensitivity[0].requiredEAtOtherLower,"THRESHOLD_BAND");
 ok(evaluateScenario({...base,costBasis:"NET_WITH_ATTESTED_REFUNDS",refundSourceID:"synthetic-refund-study"}).scenarioDecision==="INDETERMINATE","REFUND_PROVENANCE");
 const cases=[
 [{...base,policy:"LIVE"},"POLICY"],
 [{...base,inputItemID:189143},"CROSS_INPUT"],
 [{...base,snapshotDate:"2026-02-30"},"INVALID_DATE"],
 [{...base,snapshotDate:"2026-13-01"},"INVALID_MONTH"],
 [{...base,nominalInputPerCast:0},"NOMINAL_ZERO"],
 [{...base,feeRate:1},"FEE_ONE"],
 [{...base,costBasis:"NET_WITH_ATTESTED_REFUNDS"},"NO_REFUND_SOURCE"],
 [{...base,refundSourceID:"unused"},"EXTRANEOUS_REFUND"],
 [{...base,otherRevenueBasis:"UNKNOWN"},"OTHER_OVERLAP"],
 [{...base,outputs:[base.outputs[0],base.outputs[0]]},"DUPLICATE"],
 [{...base,outputs:[{...base.outputs[0],eUpper:0.1}]},"REVERSED_BOUNDS"],
 [{...base,outputs:[{...base.outputs[0],eUpper:-1}]},"NEGATIVE_UPPER"],
 [{...base,outputs:[{...base.outputs[0],priceGold:NaN}]},"NAN_PRICE"],
 [{...base,outputs:[{...base.outputs[0],eLower:Infinity}]},"INFINITY_E"],
 [{...base,outputs:[{...base.outputs[0],confidence:90}]},"FORGED_CONFIDENCE"],
 [{...base,outputs:[]},"EMPTY_OUTPUT"],
 [{...base,outputs:[{stableKey:"invented",priceGold:1,eLower:0,eUpper:1}]},"INVENTED_MAPPING"],
 [{...base,alternativeNetGoldPerCast:-1},"NEGATIVE_ALT"],
 [{...base,outputs:[{...base.outputs[0],priceGold:1e308,eLower:1e308,eUpper:1e308}]},"OVERFLOW"],
 [{...base,sourceID:"not_allowed"},"EXTRA_TOP_LEVEL"]
 ];
 for(const [x,label]of cases)bad(()=>evaluateScenario(x),label);
 const sparse=[base.outputs[0],,base.outputs[0]];bad(()=>evaluateScenario({...base,outputs:sparse}),"SPARSE");
 const hidden=base.outputs.slice();Object.defineProperty(hidden,"secret",{value:1});bad(()=>evaluateScenario({...base,outputs:hidden}),"HIDDEN_ARRAY");
 const accessor=Object.defineProperty({...base.outputs[0]},"eLower",{get(){return 1},enumerable:true});bad(()=>evaluateScenario({...base,outputs:[accessor]}),"ACCESSOR");
 const withSymbol={...base};withSymbol[Symbol("x")]=1;bad(()=>evaluateScenario(withSymbol),"SYMBOL");
 // Deterministic synthetic arithmetic identities: all amounts are scenario values, never Retail observations.
 let n=0;
 for(let i=0;i<4000;i++){
  const p=1+(i%101),e=(i%23)/10,c=(i%17)/4,fee=(i%9)/100;
  const z=evaluateScenario({...base,costGoldPerCast:c,feeRate:fee,alternativeNetGoldPerCast:5,outputs:[{stableKey:key,priceGold:p,eLower:e,eUpper:e}]});
  const expected=e*p*(1-fee)-c;
  ok(Math.abs(z.lowerNetGoldPerCompletedCast-expected)<1e-9&&Math.abs(z.upperNetGoldPerCompletedCast-expected)<1e-9,"SYNTHETIC_ARITHMETIC");
  n++;
 }
 return {modelID:MODEL_ID,passed,failed:0,syntheticScenarios:n,targetKeys:TARGETS.length,actualRetailObservations:0,economicPromotions:0};
}
module.exports={MODEL_ID,POLICY,TARGETS,evaluateScenario,selfTest};
if(require.main===module)console.log(JSON.stringify(selfTest()));
