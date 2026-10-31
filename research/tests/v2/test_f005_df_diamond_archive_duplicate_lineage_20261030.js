"use strict";
/* F005 independent archive-lineage deduplication audit. Historical context
   is not verified Retail E/P; neither archive is rewritten. */
const FILES={
 "first": "research/evidence/v2/2026-10-29T1328Z-F004-historical-diamond-comment-cohorts.json",
 "firstReview": "research/evidence/v2/source-reviews/2026-10-29T1328Z-F004-diamond-comment-source-review.json",
 "later": "research/evidence/v2/2026-10-30T1930Z-F004-df-4000-prospects-rank-split.json",
 "laterReview": "research/evidence/v2/source-reviews/2026-10-30T1930Z-F004-df-4000-prospects-rank-split-source-review.json",
 "laterSubmission": "research/coordination/v2/submissions/evidence-researcher/2026-10-30T1930Z-F004-df-4000-prospects-rank-split-submission.json",
 "correction": "research/evidence/v2/2026-10-30T2230Z-F004-df-duplicate-cohort-ancestry.json",
 "correctionReview": "research/evidence/v2/source-reviews/2026-10-30T2230Z-F004-df-duplicate-cohort-ancestry-source-review.json"
};
function audit(x){
 const tests=[],check=(name,ok)=>tests.push({name,status:ok?"PASS":"FAIL"});
 const old=x.first.sources.find(s=>s.claimID==="df-2022-12-30-approx4000-prospects-diamond-comment");
 const oldEvent=x.firstReview.events.find(s=>s.claimID==="df-2022-12-30-approx4000-prospects-diamond-comment");
 const newEvent=x.laterReview.events[0],c=x.correction.exactDuplicate;
 const counts=a=>Object.fromEntries(a.map(y=>[y.itemID||y.outputItemID,y.units===undefined?y.reportedTotalUnits:y.units]));
 const a=old?counts(old.outputTotals):{},b=counts(x.later.cohort.outputs);
 check("older claim exists",!!old);
 check("older source-review event exists",!!oldEvent);
 check("same canonical original thread",!!old&&old.sourceURL===x.later.source.url&&old.sourceURL===c.sourceURL);
 check("same original short claim",!!old&&old.sourceStatement.includes("3 r3")&&x.later.source.originalShortExcerpt.includes("3 r3"));
 check("same approximate prospect count",!!old&&old.reportedApproximateProspects===4000&&x.later.cohort.reportedProspectsApprox===4000);
 check("same R2 item and 16 units",a[192870]===16&&b[192870]===16);
 check("same R3 item and 3 units",a[192871]===3&&b[192871]===3);
 check("same approximate 25 percent Inspiration",!!old&&old.inspirationPercent===25&&x.later.cohort.profession.inspirationFractionApprox===0.25);
 check("both missing input item identity",!!old&&old.inputItemID===null&&x.later.cohort.inputItemID===null);
 check("both missing input quality rank",!!old&&old.inputRank===null&&x.later.cohort.inputOreQualityRank===null);
 check("neither has verified completed casts",!!old&&old.actualCompletedCasts===null&&x.later.cohort.actualCompletedCastsVerified===null);
 check("older lineage matches correction",!!old&&old.studyFamilyID===c.firstLineageID);
 check("later lineage matches correction",x.later.source.studyFamilyID===c.laterLineageID);
 check("older claim identity matches correction",!!old&&old.claimID===c.firstClaimID);
 check("first archive path matches correction",c.firstArchivedEvidence===FILES.first);
 check("later archive path matches correction",c.laterEvidence===FILES.later);
 check("later original claimed one new lineage",x.later.impact.newOriginalAuthorLineages===1&&x.laterSubmission.exactDeltas.newOriginalAuthorLineages===1&&newEvent.independentNewLineages===1);
 check("older source review already recorded comment",!!oldEvent&&oldEvent.url===c.sourceURL&&oldEvent.newOriginalClaim===true);
 check("older independent study NOT confirmed",!!oldEvent&&oldEvent.independentStudyConfirmed===false);
 check("corrected independent lineage increment zero",x.correction.archiveDelta.newIndependentAuthorLineages===0&&x.correction.archiveDelta.proposedAcceptedIncrementForLaterSubmission===0);
 check("corrected aggregate decrement only conditional",x.correction.archiveDelta.proposedAdjustmentIfAlreadyCountedTwice===-1);
 check("do not assert measured Retail E",x.correction.archiveDelta.newMeasuredExpectedQuantity===0&&x.later.impact.newVerifiedExpectedQuantityCells===0);
 check("economic isolation correction",x.correction.safety.confidence===0&&x.correction.safety.economicUse==="PREVIEW_ONLY"&&x.correction.safety.normalizedVerified===false&&x.correction.safety.liveEVEligible===false);
 check("economic isolation later archive",x.later.safety.confidence===0&&x.later.safety.economicUse==="PREVIEW_ONLY"&&x.later.safety.normalizedVerified===false);
 check("do not infer ore rank from parent",x.later.cohort.oreIdentityContext.includes("Do not inherit")&&x.correction.exactDuplicate.matchingReportedFacts.oreRank===null);
 check("no invented current-patch bridge",x.correction.exactDuplicate.currentPatchApplicability==="NONE_VERIFIED"&&x.correction.exactDuplicate.rankSpecificMappingApplicability==="NONE_VERIFIED");
 check("same five affected mapping keys",JSON.stringify(x.first.assignedKeys)===JSON.stringify(x.later.priorityKeys)&&JSON.stringify(x.first.assignedKeys)===JSON.stringify(x.correction.targetKeys));
 check("corrected source-review does not rewrite originals",x.correctionReview.priorReportsModified===false&&x.correctionReview.sourceMemoryGlobalModified===false);
 check("source chronology preserved",x.correction.exactDuplicate.firstArchivalDateUTC<x.correction.exactDuplicate.laterArchivalDateUTC);
 check("older context retains tentative gear/spec",!!old&&typeof old.gear==="string"&&typeof old.specialization==="string"&&old.inspirationPercent===25);
 check("do not sum duplicate rank counts",x.correctionReview.sourceFamilyCountAfterDedup===1&&x.correctionReview.sourceFamilyCountBeforeDedupIfBothAccepted===2);
 return tests;
}
function runWithInputs(input){
 const tests=audit(input);
 const clone=()=>JSON.parse(JSON.stringify(input));
 const mutations=[
 ["changed old R2 count",x=>x.first.sources[1].outputTotals[0].units=17],
 ["changed later R3 count",x=>x.later.cohort.outputs[1].reportedTotalUnits=4],
 ["changed old approximate denominator",x=>x.first.sources[1].reportedApproximateProspects=4500],
 ["changed later denominator",x=>x.later.cohort.reportedProspectsApprox=3000],
 ["changed source thread",x=>x.later.source.url="https://www.reddit.com/r/woweconomy/comments/other"],
 ["changed Inspiration",x=>x.later.cohort.profession.inspirationFractionApprox=0.30],
 ["fabricated old ore rank",x=>x.first.sources[1].inputRank=3],
 ["fabricated later ore identity",x=>x.later.cohort.inputItemID=190311],
 ["fabricated actual casts",x=>x.later.cohort.actualCompletedCastsVerified=4000],
 ["new lineage counted twice",x=>x.correction.archiveDelta.newIndependentAuthorLineages=1],
 ["new accepted increment counted twice",x=>x.correction.archiveDelta.proposedAcceptedIncrementForLaterSubmission=1],
 ["promoted economic use",x=>x.correction.safety.economicUse="LIVE"],
 ["promoted confidence",x=>x.correction.safety.confidence=90],
 ["changed target mapping",x=>x.correction.targetKeys[0]="unrelated"],
 ["deleted older archival ancestry",x=>x.correction.exactDuplicate.firstArchivedEvidence="unknown"],
 ["removed prior source review",x=>x.firstReview.events.pop()],
 ["changed corrected family count",x=>x.correctionReview.sourceFamilyCountAfterDedup=2],
 ["lost historical specialization context",x=>x.first.sources[1].specialization=null]
 ];
 for(const [name,mutate] of mutations){const x=clone();mutate(x);tests.push({name:"mutation rejects "+name,status:audit(x).some(t=>t.status==="FAIL")?"PASS":"FAIL"});}
 const passed=tests.filter(t=>t.status==="PASS").length,failed=tests.length-passed;
 return {suite:"F005_DF_DIAMOND_ARCHIVE_DUPLICATE_LINEAGE",total:tests.length,passed,failed,tests,verdict:failed?"FAIL":"CONDITIONAL_PASS_ARCHIVE_DEDUP_ONLY",newIndependentStudies:0,confidencePromotions:0,economicPromotions:0,independentRetailHoldouts:0};
}
function run(){const fs=require("node:fs"),path=require("node:path"),root=path.resolve(__dirname,"../.."),x={};for(const [k,p] of Object.entries(FILES))x[k]=JSON.parse(fs.readFileSync(path.join(root,p),"utf8"));return runWithInputs(x);}
module.exports={audit,runWithInputs,run,FILES};
if(require.main===module){const r=run();console.log(JSON.stringify(r));if(r.failed)process.exitCode=1;}
