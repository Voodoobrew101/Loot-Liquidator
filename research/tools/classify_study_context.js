"use strict";
/**
 * Contextual study dating as an auditable, per-patch interpretation.
 * Explicit source statements about WHEN casts were done may be reviewed and
 * accepted, but mere publication recency or "new rates?" language is NOT proof.
 * No numeric probability of historical era is fabricated.
 */
const STRONG_AFTER=new Set([
  "EXPLICIT_CASTS_AFTER_EVENT","DOCUMENTED_EVENT_BOUND_GAME_BUILD",
  "SOURCE_LINKED_CAST_LOG_TIMESTAMP"
]);
const STRONG_BEFORE=new Set([
  "EXPLICIT_CASTS_BEFORE_EVENT","DOCUMENTED_EVENT_BOUND_GAME_BUILD",
  "SOURCE_LINKED_CAST_LOG_TIMESTAMP"
]);
function validateAttribution(a,eventID) {
  if(!a||a.eventID!==eventID||typeof a.observationID!=="string")return false;
  if(!Array.isArray(a.signals)||a.signals.length===0)return false;
  if(!["BEFORE","AFTER","LIKELY_BEFORE","LIKELY_AFTER","AMBIGUOUS","CONTRADICTORY"].includes(a.conclusion))return false;
  if(!["WORKER_PROPOSED","MASTER_REVIEWED","REJECTED"].includes(a.reviewStatus))return false;
  for(const s of a.signals) {
    if(!s||typeof s.sourceURL!=="string"||!s.sourceURL.trim()||
      typeof s.excerpt!=="string"||!s.excerpt.trim()||
      !["BEFORE","AFTER","UNDETERMINED"].includes(s.relation))return false;
  }
  return true;
}
function classifyWithContext(rawEra,attribution,eventID) {
  const result={rawEra,era:rawEra,temporalBasis:"DATE_OR_PUBLICATION_BOUND",
    proposedEra:null,conclusion:"NO_CONTEXT_REVIEW",attributionID:null,notes:[]};
  if(!attribution)return result;
  if(!validateAttribution(attribution,eventID)) {
    result.notes.push("INVALID_OR_UNRELATED_ATTRIBUTION");
    return result;
  }
  result.attributionID=attribution.attributionID||null;
  result.conclusion=attribution.conclusion;
  if(attribution.reviewStatus==="REJECTED") {
    result.notes.push("REJECTED_CONTEXTUAL_INTERPRETATION");
    return result;
  }
  const c=attribution.conclusion;
  const side=c==="BEFORE"||c==="LIKELY_BEFORE"?"BEFORE":
    c==="AFTER"||c==="LIKELY_AFTER"?"AFTER":null;
  if(["BEFORE","AFTER"].includes(rawEra)) {
    if(side&&rawEra!==side) {
      result.era="CONTRADICTORY_CONTEXT";
      result.temporalBasis="CONFLICT_REQUIRES_REVIEW";
      result.proposedEra=side;
      result.notes.push("DIRECT_DATE_CONFLICTS_WITH_CONTEXTUAL_ATTRIBUTION");
    }
    return result;
  }
  if(rawEra==="OUT_OF_SCOPE"||rawEra==="UNKNOWN_SCOPE"||
    rawEra==="INVALID_SAMPLE_TIME"||rawEra==="UNKNOWN_EVENT_BOUNDARY")return result;
  if(!side || c==="CONTRADICTORY") {
    if(c==="CONTRADICTORY")result.notes.push("COMPETING_CONTEXTUAL_EVIDENCE");
    return result;
  }
  const qualifying=attribution.signals.some(s=>
    s.relation===side&&
    (side==="AFTER"?STRONG_AFTER:STRONG_BEFORE).has(s.kind)&&
    (!s.referencedEventID||s.referencedEventID===eventID));
  const contradicting=attribution.signals.some(s=>s.relation!=="UNDETERMINED"&&s.relation!==side);
  // Only an independently reviewed direct claim or build/log evidence can
  // give the study a contextual era for stratification, NEVER a verified date.
  if(["BEFORE","AFTER"].includes(c)&&
    attribution.reviewStatus==="MASTER_REVIEWED"&&qualifying&&!contradicting) {
    result.era="CONTEXTUALLY_"+side;
    result.temporalBasis="MASTER_REVIEWED_EXPLICIT_CONTEXT_NOT_OBSERVED_TIMESTAMP";
    result.notes.push("NOT_A_VERIFIED_CAST_DATE");
    return result;
  }
  result.proposedEra=side;
  result.temporalBasis="PROVISIONAL_CONTEXTUAL_HYPOTHESIS";
  result.notes.push("KEEP_ALTERNATIVE_EPOCHS_AND_TEST_SENSITIVITY");
  if(!qualifying)result.notes.push("NO_DIRECT_EVENT_RELATIVE_EVIDENCE");
  if(contradicting)result.notes.push("CONFLICTING_SIGNALS");
  if(attribution.reviewStatus!=="MASTER_REVIEWED")result.notes.push("MASTER_REVIEW_PENDING");
  return result;
}
module.exports={validateAttribution,classifyWithContext};
