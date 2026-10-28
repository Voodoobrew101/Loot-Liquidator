"use strict";
/**
 * Research-only chronological source classification, NOT a numeric normalizer.
 * node research/tools/resolve_mechanics_epoch.js research/mechanics/mechanics-chronology.json <source-contexts.json>
 * Contexts must include actual gameMode, expansionID, method, inputFamily,
 * outputFamily, and an observationDate or [sampleStartDate,sampleEndDate].
 * Unknown relevant context always remains unknown. Date of patch publication
 * is not assumed to be its effective timestamp.
 */
const fs=require("node:fs");
const {resolveSampleWindow}=require("./resolve_sample_time");

function validDate(s) {
  if(typeof s!=="string"||!/^\d{4}-\d{2}-\d{2}$/.test(s))return false;
  const d=new Date(s+"T00:00:00.000Z");
  return Number.isFinite(d.valueOf())&&d.toISOString().slice(0,10)===s;
}
function scopeStatus(c,e) {
  const s=e.scope||{}, exact=[
    ["gameMode",e.gameMode],
    ["expansionID",s.expansionIDs],
    ["method",s.methods],
    ["inputFamily",s.inputFamily],
    ["outputFamily",s.outputFamily]
  ];
  let missing=false;
  for(const [name,allowed] of exact) {
    if(allowed===null||allowed===undefined)continue;
    const value=c?.[name];
    if(value===null||value===undefined){missing=true;continue;}
    const match=Array.isArray(allowed)?allowed.includes(value):value===allowed;
    if(!match)return "OUT_OF_SCOPE";
  }
  for(const [field,allowed] of [["recipeID",s.recipeIDs],["inputItemID",s.inputItemIDs],["outputItemID",s.outputItemIDs]]) {
    if(allowed===null||allowed===undefined)continue;
    if(!Array.isArray(allowed)||allowed.length===0)throw Error("Invalid scoped ID set: "+field);
    if(c?.[field]===null||c?.[field]===undefined){missing=true;continue;}
    if(!allowed.includes(c[field]))return "OUT_OF_SCOPE";
  }
  return missing?"UNKNOWN_SCOPE":"IN_SCOPE";
}
function classify(c,e) {
  const scope=scopeStatus(c,e);
  if(scope!=="IN_SCOPE")return scope;
  const first=e.firstAffectedDate;
  if(!validDate(first))return "UNKNOWN_EVENT_BOUNDARY";
  const timing=resolveSampleWindow(c);
  if(timing.kind==="INVALID_OBSERVATION_INTERVAL"||timing.kind==="CONTRADICTORY_TIME_EVIDENCE")return "INVALID_SAMPLE_TIME";
  if(timing.kind==="TIME_UNKNOWN")return "UNKNOWN_SAMPLE_DATE";
  const {startDate:begin,endDate:end}=timing;
  if(end&&end<first)return "BEFORE";
  if(begin&&begin>first)return "AFTER";
  if(timing.kind==="PUBLICATION_UPPER_BOUND"||timing.kind==="OBSERVATION_LOWER_BOUND")return "UNKNOWN_PUBLICATION_BOUND";
  // Unknown deployment clock within officially dated hotfix.
  return "CROSSES_OR_TOUCHES_EVENT_DAY";
}

function compare(a,b,chrono) {
  const decisions=[];
  for(const e of chrono.events||[]) {
    if(e.status!=="ACTIVE")continue;
    const left=classify(a,e),right=classify(b,e);
    if(left==="OUT_OF_SCOPE"&&right==="OUT_OF_SCOPE")continue;
    const record={eventID:e.eventID,eventRevision:e.revision,left,right};
    if(left==="OUT_OF_SCOPE"||right==="OUT_OF_SCOPE")record.decision="BLOCKED_DIFFERENT_SCOPE";
    else if(left==="UNKNOWN_SCOPE"||right==="UNKNOWN_SCOPE")record.decision="BLOCKED_UNKNOWN_SCOPE";
    else if(!["BEFORE","AFTER"].includes(left)||!["BEFORE","AFTER"].includes(right))record.decision="BLOCKED_UNRESOLVED_DATE";
    else if(left===right)record.decision="SAME_KNOWN_EVENT_SIDE";
    else record.decision=e.numericallyBridgeable===true?
      "CROSS_EPOCH_NEEDS_EXPLICIT_VALIDATED_BRIDGE":"BLOCKED_UNQUANTIFIED_CHANGE";
    decisions.push(record);
  }
  const blockers=decisions.filter(d=>d.decision!=="SAME_KNOWN_EVENT_SIDE");
  return {compatibleForChronology:!blockers.length,decision:blockers.length?"BLOCKED":decisions.length?"SAME_KNOWN_EPOCH":"NO_RELEVANT_REGISTERED_EVENT",eventDecisions:decisions,
    warning:"Chronology compatibility alone does not prove recipe, rank, skill, gear or other mechanics equivalence. No registered event does not prove unchanged mechanics."};
}
function validateChronology(c) {
  if(!c||!Array.isArray(c.events)||!Array.isArray(c.revisionHistory))throw Error("Missing versioned mechanics chronology");
  const eventIDs=new Set();
  const revisionKeys=new Set();
  for(const e of c.events) {
    if(typeof e.eventID!=="string"||!Number.isInteger(e.revision)||e.revision<1||eventIDs.has(e.eventID))throw Error("Duplicate/invalid active event");
    eventIDs.add(e.eventID);
    if(!validDate(e.firstAffectedDate)&&e.firstAffectedDate!==null)throw Error("Invalid event date");
    if(e.numericallyBridgeable===true&&!e.numericParameters)throw Error("Numerical bridge lacks parameters");
    if(!Array.isArray(e.sourceClaims)||e.sourceClaims.length===0)throw Error("Event lacks evidence");
  }
  for(const r of c.revisionHistory) {
    const k=r.eventID+"@"+r.revision;
    if(revisionKeys.has(k))throw Error("Duplicate revision "+k);
    revisionKeys.add(k);
    if(!eventIDs.has(r.eventID))throw Error("Orphan chronology revision "+k);
    if(!r.evidenceURL)throw Error("Revision missing source "+k);
  }
  for(const e of c.events)if(!revisionKeys.has(e.eventID+"@"+e.revision))throw Error("Active event missing revision audit");
  return true;
}
function main(argv) {
  const chronology=JSON.parse(fs.readFileSync(argv[0]||"research/mechanics/mechanics-chronology.json","utf8"));
  validateChronology(chronology);
  if(!argv[1]){process.stdout.write(JSON.stringify({valid:true,events:chronology.events.length,revisions:chronology.revisionHistory.length})+"\n");return;}
  const input=JSON.parse(fs.readFileSync(argv[1],"utf8"));
  const observations=input.observations||[];
  const byID=new Map(observations.map(x=>[x.observationID,x]));
  const classifications=observations.map(o=>({observationID:o.observationID,
    events:chronology.events.map(e=>({eventID:e.eventID,revision:e.revision,era:classify(o,e)}))}));
  const comparisons=(input.pairs||[]).map(([a,b])=>{
    if(!byID.has(a)||!byID.has(b))throw Error("Unrecognized observationID in pair");
    return {left:a,right:b,...compare(byID.get(a),byID.get(b),chronology)};
  });
  process.stdout.write(JSON.stringify({chronologyVersion:chronology.schemaVersion,classifications,comparisons},null,2)+"\n");
}
if(require.main===module)main(process.argv.slice(2));
module.exports={validDate,scopeStatus,classify,compare,validateChronology};
