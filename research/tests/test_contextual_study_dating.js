"use strict";
// Scenario-based static regression; no live WoW validation.
const assert=require("node:assert/strict");
const fs=require("node:fs"),path=require("node:path");
const {classifyWithContext}=require("../tools/classify_study_context");
const {reprocess}=require("../tools/reprocess_observation_archive");
const timeline=JSON.parse(fs.readFileSync(path.resolve(__dirname,"../mechanics/mechanics-chronology.json"),"utf8"));
const eventID=timeline.events[0].eventID;
const base={
  observationID:"april-5-study",studyID:"original-author-study",
  source:{url:"https://example.org/original-report",publishedDate:"2026-04-05",retrievedDate:"2026-10-28"},
  game:{gameMode:"RETAIL",expansionID:11,clientBuild:null},
  processing:{method:"Prospect",recipeID:100,inputItemID:200,inputQualityRank:1,
    batchInputsPerOperation:5,completedOperations:100,actualOperationCountKnown:true},
  characterContext:{baseSkill:1,effectiveSkill:10,specializations:null,professionGear:null,stats:null},
  outputs:[{outputItemID:300,outputQualityRank:1,totalUnits:25,hitOperations:20}]
};
const fam={inputs:{"200":"MIDNIGHT_ORE"},outputs:{"300":"GEM"}};
function record(b=base){return {record:b,file:"source.jsonl",line:1};}
function sig(kind,relation,excerpt,referencedEventID=eventID){return {
 kind,relation,excerpt,referencedEventID,sourceURL:"https://example.org/original-report",
 reason:"The cited original study contains this relative-to-patch statement"
};}
function at(conclusion,reviewStatus,signals){return {
 attributionID:"date-analysis-001",observationID:base.observationID,eventID,revision:1,
 conclusion,reviewStatus,signals,alternatives:["BEFORE","AFTER"],
 rationale:"Study source contains or lacks evidence of the date of actual casts."
};}
function classify(a) {
 const r=reprocess([record()],timeline,{familyMap:fam,temporalAttributions:a?[a]:[]});
 return r.records[0].outputs[0].epochEvents[0];
}
let r=classify(null);
assert.equal(r.asOf,"UNKNOWN_PUBLICATION_BOUND","April 5 post date is not proof of later cast");
assert.equal(r.contextualAttributionID,null);
r=classify(at("LIKELY_AFTER","WORKER_PROPOSED",[
  sig("RECENT_TEST_LANGUAGE","AFTER","Wanted to see whether the recent hotfix helped")
]));
assert.equal(r.asOf,"UNKNOWN_PUBLICATION_BOUND");
assert.equal(r.provisionalAlternateEra,"AFTER","Keep plausible post-epoch hypothesis separately");
r=classify(at("AFTER","WORKER_PROPOSED",[
  sig("EXPLICIT_CASTS_AFTER_EVENT","AFTER","I ran 100 prospects after the March 31 hotfix")
]));
assert.equal(r.asOf,"UNKNOWN_PUBLICATION_BOUND","Worker cannot self-certify dating");
r=classify(at("AFTER","MASTER_REVIEWED",[
  sig("EXPLICIT_CASTS_AFTER_EVENT","AFTER","I ran 100 prospects after the March 31 hotfix")
]));
assert.equal(r.asOf,"CONTEXTUALLY_AFTER");
assert.equal(r.dateBasis,"MASTER_REVIEWED_EXPLICIT_CONTEXT_NOT_OBSERVED_TIMESTAMP");
assert.equal(r.provisionalAlternateEra,null);
r=classify(at("AFTER","MASTER_REVIEWED",[
  sig("SOURCE_PUBLICATION_AFTER_EVENT","AFTER","Post timestamp April 5")
]));
assert.equal(r.asOf,"UNKNOWN_PUBLICATION_BOUND","Publication timing not qualifying evidence");
r=classify(at("AFTER","MASTER_REVIEWED",[
  sig("EXPLICIT_CASTS_AFTER_EVENT","AFTER","I tested after another patch","unrelated-event")
]));
assert.equal(r.asOf,"UNKNOWN_PUBLICATION_BOUND","Do not map evidence from another event");
r=classify(at("AFTER","MASTER_REVIEWED",[
  sig("EXPLICIT_CASTS_AFTER_EVENT","AFTER","I ran after the hotfix"),
  sig("EXPLICIT_CASTS_BEFORE_EVENT","BEFORE","These results were recorded before the hotfix")
]));
assert.equal(r.asOf,"UNKNOWN_PUBLICATION_BOUND","Conflicting statements require review");
assert.ok(r.contextualWarnings.includes("CONFLICTING_SIGNALS"));
r=classify(at("AFTER","REJECTED",[
  sig("EXPLICIT_CASTS_AFTER_EVENT","AFTER","I ran after the hotfix")
]));
assert.equal(r.asOf,"UNKNOWN_PUBLICATION_BOUND");
const before={...base,source:{...base.source,publishedDate:"2026-03-27"}};
const inconsistent=at("AFTER","MASTER_REVIEWED",[
  sig("EXPLICIT_CASTS_AFTER_EVENT","AFTER","After the March 31 hotfix")
]);
const cr=reprocess([record(before)],timeline,{familyMap:fam,temporalAttributions:[inconsistent]});
assert.equal(cr.records[0].outputs[0].epochEvents[0].asOf,"CONTRADICTORY_CONTEXT");
assert.equal(cr.records[0].outputs[0].expectedQuantity.value,0.25,
 "Context interpretation cannot overwrite source-measured expected yield");
assert.throws(()=>reprocess([record()],timeline,{temporalAttributions:[
  at("AFTER","MASTER_REVIEWED",[sig("EXPLICIT_CASTS_AFTER_EVENT","AFTER","A")]),
  at("AFTER","MASTER_REVIEWED",[sig("EXPLICIT_CASTS_AFTER_EVENT","AFTER","A")])
]}),/Duplicate temporal attribution revision/);
console.log("Contextual study dating static regressions passed; no automatic current-Retail promotion");
