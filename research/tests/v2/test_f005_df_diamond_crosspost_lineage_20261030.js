"use strict";
/* F005 independent source/lineage QA. Historical observations are not live EV.
   Run: node research/tests/v2/test_f005_df_diamond_crosspost_lineage_20261030.js */
const fs=require("node:fs"),crypto=require("node:crypto"),path=require("node:path");
const root=path.resolve(__dirname,"../../..");
const evPath=path.join(root,"research/evidence/v2/2026-10-30T2334Z-F004-df-diamond-mixed-rank-denominator-crosspost.json");
const srPath=path.join(root,"research/evidence/v2/source-reviews/2026-10-30T2334Z-F004-df-diamond-mixed-rank-denominator-crosspost-source-review.json");
const rdPath=path.join(root,"research/coordination/completion-readiness.json");
const blob=p=>{const b=fs.readFileSync(p);return crypto.createHash("sha1").update("blob "+b.length+"\0").update(b).digest("hex");};
const load=p=>JSON.parse(fs.readFileSync(p,"utf8"));
const eq=(a,b)=>a===b;
function integrity(e,s){
 const a=e.observations;if(!Array.isArray(a)||a.length!==3)return false;
 const [d,q,c]=a;
 return new Set(a.map(x=>x.lineage)).size===3
 &&d.inputRank==="MIXED_R1_OR_R2_BY_PRICE_AND_SKILL_BREAKPOINT"&&d.inputRankPerRun===null
 &&d.reportedOreUnitsPerExampleRunApprox===15000
 &&d.reportedTypicalR3DiamondUnitsRange.join(",")==="10,15"
 &&d.reportedLowR3DiamondUnitsRange.join(",")==="3,4"
 &&q.inputRank===3&&q.skillReported===274&&q.reportedOreUnitsApprox===28000&&q.reportedR3DiamondUnits===24
 &&c.inputRank===2&&c.reportedOreUnits===54137&&c.reportedProspects===10827&&c.nominalInputPerCast===5
 &&c.nominalOreFromReportedProspects===54135&&c.reportedOreMinusNominal===2
 &&c.reportedOreUnits-c.reportedProspects*c.nominalInputPerCast===2
 &&c.outputCounts.length===2&&c.outputCounts[0].rank===2&&c.outputCounts[0].itemID===192870&&c.outputCounts[0].units===38
 &&c.outputCounts[1].rank===3&&c.outputCounts[1].itemID===192871&&c.outputCounts[1].units===23
 &&Math.abs(100*38/10827-c.outputCounts[0].reportedPercentPerProspectApprox)<0.0001
 &&Math.abs(100*23/10827-c.outputCounts[1].reportedPercentPerProspectApprox)<0.0001
 &&c.crosspostSource==="https://www.reddit.com/r/woweconomy/comments/108782r"
 &&a.every(x=>x.actualCompletedCasts===null&&x.measuredDropChance===null&&x.verifiedExpectedQuantity===null)
 &&a.every(x=>x.publicationDate.startsWith("2022")||x.publicationDate.startsWith("2023"))
 &&s.sourceAncestry[2].crosspostDuplicate===true&&s.confirmedIndependentAuthorLineages===0&&s.acceptedStudyCountChange===0
 &&e.safety.confidence===0&&e.safety.economicUse==="PREVIEW_ONLY"&&e.safety.normalizedVerified===false
 &&e.safety.liveEVEligible===false&&e.safety.liveRecommendationEligible===false;
}
function run(){
 const e=load(evPath),s=load(srPath),r=load(rdPath),tests=[];
 const test=(name,fn)=>{try{const ok=fn();tests.push({name,status:ok?"PASS":"FAIL",reason:ok?undefined:"INVARIANT_NOT_MET"});}catch(err){tests.push({name,status:"FAIL",reason:"UNEXPECTED_THROW:"+String(err.message||err)});}};
 test("exact evidence Git blob",()=>blob(evPath)==="b3a1012fe481e6bea27dace7ef4ee64b1a58755b");
 test("exact source-review Git blob",()=>blob(srPath)==="6441694177e8785a8633c522a26ade755f83ca1d");
 test("original cohorts and crosspost arithmetic, rank, provenance and economic isolation",()=>integrity(e,s));
 test("crosspost author independence not confirmed",()=>s.sourceAncestry.every(x=>x.newIndependentAuthorConfirmed===false));
 test("crosspost is one lineage despite two threads",()=>s.sourceAncestry[2].crosspostDuplicate&&e.observations[2].lineage.includes("zzyjzu-108782r"));
 test("two-ore discrepancy retained not rounded away",()=>e.observations[2].reportedOreUnits%5===2);
 test("reported per-prospect percentages not per-ore percentages",()=>Math.abs(100*38/54137-0.351)>0.1);
 test("current Retail inapplicable",()=>e.observations.every(x=>x.gameMode==="HISTORICAL_DRAGONFLIGHT_RETAIL"));
 test("no accepted study increase",()=>s.acceptedStudyCountChange===0);
 test("working preview still complete",()=>r.workingNumericCells===r.fieldSlots&&r.mappingCount===1018);
 test("confidence 90 not claimed",()=>r.evidenceGE90Cells===0&&r.verifiedBaselineRecords===0);
 const mutate=(name,fn)=>test("reject mutation: "+name,()=>{const x=JSON.parse(JSON.stringify(e));fn(x);return !integrity(x,s);});
 mutate("false exact completed casts",x=>x.observations[2].actualCompletedCasts=10827);
 mutate("fabricated occurrence chance",x=>x.observations[2].measuredDropChance=38/10827);
 mutate("fabricated verified expected quantity",x=>x.observations[2].verifiedExpectedQuantity=61/10827);
 mutate("duplicated lineage",x=>x.observations[1].lineage=x.observations[0].lineage);
 mutate("rank2 output mislabel",x=>x.observations[2].outputCounts[0].rank=3);
 mutate("two-ore discrepancy erased",x=>x.observations[2].reportedOreUnits=54135);
 mutate("reported prospects inflated",x=>x.observations[2].reportedProspects=10828);
 mutate("crosspost promoted to independent",x=>x.observations[2].crosspostSource="https://example.com/unrelated");
 mutate("economic-use promotion",x=>x.safety.economicUse="LIVE");
 mutate("confidence promotion",x=>x.safety.confidence=90);
 const passed=tests.filter(x=>x.status==="PASS").length;
 return {suite:"F005_DF_DIAMOND_CROSSPOST_LINEAGE",sourceBlob:"b3a1012fe481e6bea27dace7ef4ee64b1a58755b",reviewBlob:"6441694177e8785a8633c522a26ade755f83ca1d",total:tests.length,passed,failed:tests.length-passed,tests,independentRetailHoldouts:0,economicPromotions:0,verdict:passed===tests.length?"CONDITIONAL_PASS_HISTORICAL_LINEAGE_ONLY":"FAIL_SOURCE_INTEGRITY"};
}
module.exports={run};
if(require.main===module){const r=run();console.log(JSON.stringify(r,null,2));if(r.failed)process.exitCode=1;}
