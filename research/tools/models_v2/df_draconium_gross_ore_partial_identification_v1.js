"use strict";
/* F003: historical Dragonflight Draconium gross-ore denominator partial identification.
   Research only. No recovered per-cast rates or 2026 economic inputs. */
const MODEL_ID="df-draconium-gross-ore-partial-identification-v1.0.0";
const SOURCE={
  path:"research/evidence/observations/2026-10-29-0217-warwithin-q28-batch026-user-workbook-draconium-gross-ore-log.md",
  workbookSHA256:"847caa75c43c1227a29eb0939c80cc0d077c997c3321d3bd76dc640a519bb4ca",
  sheet:"Prospecting Log", epoch:"2023-01-03/2023-02-06",
  lineage:"ONE_WORKBOOK_FAMILY_INDEPENDENCE_FROM_2022_REDDIT_UNRESOLVED",
  sourceMeaning:"Quantity is reported gross ore; completed casts and refunded units not recorded"
};
const ROWS=[
  [28,2,8543,0,15,9,237,33.9,5.1],
  [52,2,15000,1,39,10,248,34.8,13.3],
  [53,3,10000,0,2,37,281,19.8,30.6],
  [54,2,13000,1,21,20,248,36.8,13.3],
  [55,2,21000,2,37,22,249,34.8,13.3],
  [56,3,22000,1,1,82,282,19.8,30.6],
  [58,3,10000,0,1,37,283,19.8,30.6],
  [60,3,15000,1,2,60,283,19.8,30.6],
  [62,2,13000,0,26,19,250,36.8,13.3],
  [63,3,30000,1,3,127,283,19.8,30.6],
  [64,3,14000,1,0,48,283,19.8,30.6],
  [65,3,30000,0,1,109,283,19.8,30.6],
  [66,3,19000,0,0,78,283,19.8,30.6],
  [67,3,20000,0,0,72,283,19.8,30.6]
].map(([sheetRow,inputRank,reportedOre,epicQ1,epicQ2,epicQ3,skill,inspirationPercent,resourcefulnessPercent])=>
  ({sheetRow,inputRank,reportedOre,outputs:{"192869":epicQ1,"192870":epicQ2,"192871":epicQ3},skill,inspirationPercent,resourcefulnessPercent}));
function assert(x,code){if(!x)throw Error(code);}
function castRange(reportedOre,interpretation,maxRefundPerCast=null){
  assert(Number.isSafeInteger(reportedOre)&&reportedOre>0,"ORE_DOMAIN");
  assert(["NOMINAL_REQUIRED","NET_CONSUMED","INITIAL_INVENTORY"].includes(interpretation),"INTERPRETATION");
  assert(maxRefundPerCast===null||(Number.isSafeInteger(maxRefundPerCast)&&maxRefundPerCast>=0&&maxRefundPerCast<5),"REFUND_CAP");
  if(interpretation==="INITIAL_INVENTORY")return {status:"DENOMINATOR_UNIDENTIFIABLE",min:null,max:null};
  if(interpretation==="NOMINAL_REQUIRED"){
    if(reportedOre%5!==0)return {status:"INCOMPATIBLE_NOMINAL_BATCH",min:null,max:null};
    return {status:"CONDITIONAL_EXACT",min:reportedOre/5,max:reportedOre/5};
  }
  const min=Math.ceil(reportedOre/5),max=maxRefundPerCast===null?null:Math.floor(reportedOre/(5-maxRefundPerCast));
  if(max!==null&&max<min)return {status:"INCOMPATIBLE_REFUND_CAP",min:null,max:null};
  return {status:max===null?"UNBOUNDED_WITHOUT_REFUND_CAP":"CONDITIONAL_INTERVAL",min,max};
}
function outputBounds(totalUnits,castCounts,maxPositiveUnitsPerCast=null){
  assert(Number.isSafeInteger(totalUnits)&&totalUnits>=0,"OUTPUT_UNITS");
  assert(castCounts&&castCounts.min!==null&&castCounts.min>0,"NO_CAST_DENOMINATOR");
  assert(maxPositiveUnitsPerCast===null||(Number.isSafeInteger(maxPositiveUnitsPerCast)&&maxPositiveUnitsPerCast>=1),"MAX_YIELD_CAP");
  const {min,max}=castCounts;
  if(totalUnits===0)return {expectedQuantity:{infimum:0,supremum:0},dropChance:{infimum:0,supremum:0},yieldMin:null,yieldMax:null};
  const requiredPositiveCasts=maxPositiveUnitsPerCast===null?1:Math.ceil(totalUnits/maxPositiveUnitsPerCast);
  if(max!==null&&requiredPositiveCasts>max)return {status:"INCOMPATIBLE_ASSUMED_POSITIVE_YIELD_CAP"};
  return {
    expectedQuantity:{infimum:max===null?0:totalUnits/max,supremum:totalUnits/min},
    dropChance:{infimum:max===null?0:requiredPositiveCasts/max,supremum:Math.min(totalUnits,min)/min},
    yieldMin:null,yieldMax:null,
    notes:"Bounds require complete capture and the stated ore-denominator interpretation; infimum 0 with unbounded casts is NOT a zero estimate."
  };
}
function analyze(interpretation="NET_CONSUMED",maxRefundPerCast=1,maxPositiveUnitsPerCast=null){
  const groups=[2,3].map(rank=>{
    const rows=ROWS.filter(x=>x.inputRank===rank);
    const castCounts=rows.map(x=>castRange(x.reportedOre,interpretation,maxRefundPerCast));
    const feasible=castCounts.every(x=>x.min!==null);
    const casts=feasible?{min:castCounts.reduce((a,x)=>a+x.min,0),max:castCounts.every(x=>x.max!==null)?castCounts.reduce((a,x)=>a+x.max,0):null}:null;
    const totals=Object.fromEntries(["192869","192870","192871"].map(id=>[id,rows.reduce((a,x)=>a+x.outputs[id],0)]));
    const outputs=Object.fromEntries(Object.entries(totals).map(([id,n])=>[id,feasible?outputBounds(n,casts,maxPositiveUnitsPerCast):null]));
    return {inputRank:rank,sourceRows:rows.map(x=>x.sheetRow),rowCount:rows.length,reportedOre:rows.reduce((a,x)=>a+x.reportedOre,0),outputTotals:totals,castCounts:casts,outputs,feasible,
      skillRange:[Math.min(...rows.map(x=>x.skill)),Math.max(...rows.map(x=>x.skill))],
      studyContext:"HISTORICAL_MIXED_SKILL_AND_STATS_NOT_BASELINE"};
  });
  return {modelID:MODEL_ID,source:SOURCE,interpretation,maxRefundPerCast,maxPositiveUnitsPerCast,
    groups,context:{gameMode:"Retail",expansion:"Dragonflight",patchEpoch:"2023_HISTORY_ONLY",recipeOperation:"Prospect",nominalOrePerCast:5,
      oreRankItemID:"NOT_ATTESTED_IN_WORKBOOK",minimumEligibleSkill:null,actualCompletedCasts:null,
      refundRate:"UNKNOWN_NOT_EQUAL_TO_REPORTED_RESOURCEFULNESS_PERCENT",outputRankItemIDs:["192869","192870","192871"]},
    status:"CONDITIONAL_HISTORICAL_PARTIAL_IDENTIFICATION_NOT_CURRENT_EVIDENCE",
    economicFields:{dropChance:null,yieldMin:null,yieldMax:null,expectedQuantity:null},
    confidence:0,economicUse:"PREVIEW_ONLY",normalizedVerified:false,
    sourceIndependence:"UNRESOLVED",independentHoldout:null,
    blockedBy:["Unknown meaning of workbook Quantity","Unknown actual completed cast counts","Blank Ore Refund column","No cast-level diamond output histogram","Unknown independence from 2022 Reddit author","No 2026 Retail applicability bridge","Ore rank to item ID not attested by workbook"],
    policy:"No tooltip or economic promotion; no E inferred from per-ore proxies, rank shares or refund stat percentages."};
}
function selfTest(){
  let passed=0;const ok=(x,id)=>{assert(x,"TEST_"+id);passed++;};
  const sum=(rs,k)=>rs.reduce((a,r)=>a+r[k],0);
  ok(ROWS.length===14,"ROW_COUNT");
  ok(sum(ROWS,"reportedOre")===240543,"ORE_TOTAL");
  ok(ROWS.filter(x=>x.inputRank===2).length===5&&ROWS.filter(x=>x.inputRank===3).length===9,"RANK_ROWS");
  ok(ROWS.reduce((a,r)=>a+r.outputs["192869"],0)===8,"Q1_TOTAL");
  ok(ROWS.reduce((a,r)=>a+r.outputs["192870"],0)===148,"Q2_TOTAL");
  ok(ROWS.reduce((a,r)=>a+r.outputs["192871"],0)===730,"Q3_TOTAL");
  ok(castRange(8543,"NOMINAL_REQUIRED").status==="INCOMPATIBLE_NOMINAL_BATCH","NOMINAL_NONMULTIPLE");
  ok(castRange(15000,"NOMINAL_REQUIRED").min===3000,"NOMINAL_MULTIPLE");
  ok(castRange(8543,"NET_CONSUMED",0).status==="INCOMPATIBLE_REFUND_CAP","ZERO_REFUND_CAP");
  ok(castRange(8543,"NET_CONSUMED",1).min===1709&&castRange(8543,"NET_CONSUMED",1).max===2135,"ONE_REFUND_CAP");
  ok(castRange(8543,"NET_CONSUMED",null).max===null,"UNBOUNDED_REFUND");
  ok(castRange(8543,"INITIAL_INVENTORY").min===null,"INITIAL_INVENTORY");
  const a=analyze(),g2=a.groups[0],g3=a.groups[1];
  ok(g2.reportedOre===70543&&g3.reportedOre===170000,"GROUP_ORE");
  ok(g2.outputTotals["192869"]===4&&g2.outputTotals["192870"]===138&&g2.outputTotals["192871"]===80,"GROUP_Q2");
  ok(g3.outputTotals["192869"]===4&&g3.outputTotals["192870"]===10&&g3.outputTotals["192871"]===650,"GROUP_Q3");
  ok(g2.castCounts.min>0&&g2.castCounts.max>=g2.castCounts.min,"CAST_INTERVAL");
  ok(g2.outputs["192870"].expectedQuantity.infimum<=g2.outputs["192870"].expectedQuantity.supremum,"E_ORDER");
  ok(g2.outputs["192870"].dropChance.infimum<=g2.outputs["192870"].dropChance.supremum,"P_ORDER");
  ok(g2.outputs["192870"].yieldMin===null&&g2.outputs["192870"].yieldMax===null,"NO_YIELD_INFERENCE");
  ok(a.economicFields.expectedQuantity===null&&a.confidence===0&&a.economicUse==="PREVIEW_ONLY"&&!a.normalizedVerified,"ISOLATION");
  ok(a.context.actualCompletedCasts===null&&a.context.minimumEligibleSkill===null,"CONTEXT_NULLS");
  ok(a.context.refundRate.startsWith("UNKNOWN"),"RESOURCEFULNESS_NOT_REFUND_RATE");
  const b=analyze("NET_CONSUMED",null);
  ok(b.groups[0].castCounts.max===null&&b.groups[0].outputs["192870"].expectedQuantity.infimum===0,"UNBOUNDED_INFIMUM_NOT_E");
  const c=analyze("NOMINAL_REQUIRED",null);
  ok(!c.groups[0].feasible&&c.groups[0].outputs["192870"]===null,"NOMINAL_REJECTS_ROW28");
  const d=analyze("INITIAL_INVENTORY",null);
  ok(!d.groups[0].feasible&&d.groups[0].castCounts===null,"INITIAL_UNIDENTIFIABLE");
  const z=outputBounds(0,{min:5,max:10});
  ok(z.dropChance.supremum===0&&z.expectedQuantity.supremum===0&&z.yieldMin===null,"OBSERVED_ZERO_CONDITIONAL");
  const cap=outputBounds(12,{min:4,max:6},2);
  ok(cap.dropChance.infimum===1&&cap.expectedQuantity.supremum===3,"CAP_CONDITIONAL");
  ok(outputBounds(20,{min:4,max:5},2).status.startsWith("INCOMPATIBLE"),"CAP_IMPOSSIBLE");
  for(const bad of [()=>castRange(10,"NET_CONSUMED",5),()=>castRange(10,"UNDECLARED"),()=>outputBounds(-1,{min:2,max:3}),()=>outputBounds(2,{min:0,max:3})]){
    let rejected=false;try{bad();}catch(e){rejected=true;}ok(rejected,"REJECT_DOMAIN_"+passed);
  }
  return {passed,failed:0,sourceRows:14,realCompletedCastHistograms:0,newVerifiedE:0,workingCellsChanged:0,syntheticAssumptionsOnly:true};
}
module.exports={MODEL_ID,SOURCE,ROWS,castRange,outputBounds,analyze,selfTest};
if(require.main===module){if(process.argv.includes("--self-test"))console.log(JSON.stringify(selfTest()));else if(process.argv.includes("--emit"))console.log(JSON.stringify(analyze(),null,2));}
