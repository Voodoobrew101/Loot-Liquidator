"use strict";
/**
 * Research-only temporal provenance adapter for raw study observations.
 * Never replace an observed date with retrieval date or silently assume
 * a publication date equals the date of experiments.
 */
function dateOnly(s) {
  if(typeof s!=="string")return null;
  const m=/^(\d{4}-\d{2}-\d{2})(?:T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2}))?$/.exec(s);
  if(!m)return null;
  const d=new Date(m[1]+"T00:00:00.000Z");
  return Number.isFinite(d.valueOf())&&d.toISOString().slice(0,10)===m[1]?m[1]:null;
}
function resolveSampleWindow(observation) {
  const t=observation.observationTiming||{},src=observation.source||{};
  const rawStart=t.observedStartDate??t.sampleStartDate??observation.sampleStartDate??null;
  const rawEnd=t.observedEndDate??t.sampleEndDate??observation.sampleEndDate??null;
  const rawSingle=t.observedDate??observation.observationDate??src.reportedObservationDate??null;
  const pubRaw=t.sourcePublicationDate??src.publishedDate??src.publicationDate??src.originalPublishedDate??null;
  const earliestRaw=t.earliestPossibleObservationDate??null;
  const publication=dateOnly(pubRaw),earliest=dateOnly(earliestRaw);
  const start=dateOnly(rawStart??rawSingle);
  const end=dateOnly(rawEnd??rawSingle);
  const timingMetadata={reportedObservationDate:src.reportedObservationDate??null,
    observedDateSource:t.observedDateSource??(src.reportedObservationDate?"SOURCE_REPORTED":"UNKNOWN"),
    originalPublicationDate:pubRaw,sourceRetrievedDate:src.retrievedDate??null,
    gameBuild:observation.game?.clientBuild??observation.clientBuild??null,
    timezone:t.timezone??null};
  if(rawStart||rawEnd||rawSingle) {
    if(!start||!end||start>end)return {kind:"INVALID_OBSERVATION_INTERVAL",startDate:null,endDate:null,publicationDate:publication,earliestPossibleDate:earliest,...timingMetadata};
    if(publication&&end>publication)return {kind:"CONTRADICTORY_TIME_EVIDENCE",startDate:start,endDate:end,publicationDate:publication,earliestPossibleDate:earliest,...timingMetadata};
    return {kind:"OBSERVED_INTERVAL",startDate:start,endDate:end,publicationDate:publication,earliestPossibleDate:earliest,...timingMetadata};
  }
  if(publication) {
    // The observation may be substantially older than its publication.
    return {kind:"PUBLICATION_UPPER_BOUND",startDate:earliest,endDate:publication,
      publicationDate:publication,earliestPossibleDate:earliest,...timingMetadata};
  }
  if(earliest)return {kind:"OBSERVATION_LOWER_BOUND",startDate:earliest,endDate:null,
    publicationDate:null,earliestPossibleDate:earliest,...timingMetadata};
  return {kind:"TIME_UNKNOWN",startDate:null,endDate:null,publicationDate:null,
    earliestPossibleDate:null,...timingMetadata};
}
module.exports={dateOnly,resolveSampleWindow};
