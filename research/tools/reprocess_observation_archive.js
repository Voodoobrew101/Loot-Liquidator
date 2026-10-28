"use strict";
/**
 * Re-evaluate raw, immutable study JSONL at itemdb research-build time.
 * Usage:
 * node research/tools/reprocess_observation_archive.js \
 *   research/evidence/observations \
 *   research/mechanics/mechanics-chronology.json \
 *   research/proposed/reprocessed-observations.json \
 *   [verified-family-map.json]
 *
 * If no source observation timestamp is known, documented publication date is
 * only an upper bound, never assumed to be when actual casts were performed.
 * This tool does not fit coefficients, transform historical outputs to current
 * patch, or ship numeric mechanics. It produces a provenance-rich staging input.
 */
const fs=require("node:fs"),path=require("node:path"),crypto=require("node:crypto");
const {resolveSampleWindow}=require("./resolve_sample_time");
const {classify,validateChronology}=require("./resolve_mechanics_epoch");
const hash=s=>crypto.createHash("sha256").update(s).digest("hex");
const norm=x=>x===undefined?null:x;
function loadEvidence(files) {
  const samples=[],inputs=[];
  for(const file of files.slice().sort()) {
    const raw=fs.readFileSync(file,"utf8"),fingerprint=hash(raw);
    inputs.push({file:path.basename(file),sha256:fingerprint,bytes:Buffer.byteLength(raw)});
    for(const [i,line] of raw.split(/\r?\n/).entries()) {
      if(!line.trim())continue;
      const data=JSON.parse(line);
      if(!data.observationID)throw Error(file+":"+(i+1)+" missing observationID");
      samples.push({record:data,file:path.basename(file),line:i+1});
    }
  }
  return {samples,inputs};
}
function observedMean(o,item) {
  const n=o.processing?.completedOperations;
  if(o.processing?.actualOperationCountKnown===true&&Number.isSafeInteger(n)&&n>0
    &&typeof item.totalUnits==="number"&&Number.isFinite(item.totalUnits)&&item.totalUnits>=0) {
    return {value:item.totalUnits/n,status:"DERIVED_FROM_REPORTED_TOTAL_AND_ACTUAL_CASTS",
      actualOperations:n,reportedTotal:item.totalUnits};
  }
  if(o.processing?.actualOperationCountKnown===true&&Number.isSafeInteger(n)&&n>0
    &&typeof item.reportedMeanPerOperation==="number"&&Number.isFinite(item.reportedMeanPerOperation)
    &&item.reportedMeanPerOperation>=0) {
    return {value:item.reportedMeanPerOperation,status:"PUBLISHED_ROUNDED_MEAN",
      actualOperations:n,reportedTotal:null};
  }
  return {value:null,status:"NO_ACTUAL_CAST_MEAN",actualOperations:null,reportedTotal:null};
}
function processObservation(o,chrono,familyMap={}) {
  const src=o.source||{},g=o.game||{},p=o.processing||{},ctx=o.characterContext||{};
  const time=resolveSampleWindow(o);
  const inputFamily=norm(o.inputFamily??o.processing?.inputFamily??familyMap.inputs?.[String(p.inputItemID)]);
  const outputs=(o.outputs||[]).map(item=>{
    const outputFamily=norm(item.outputFamily??familyMap.outputs?.[String(item.outputItemID)]);
    const current={...o,gameMode:g.gameMode,expansionID:g.expansionID,method:p.method,
      recipeID:p.recipeID,inputItemID:p.inputItemID,outputItemID:item.outputItemID,
      inputFamily,outputFamily,observationTiming:o.observationTiming,source:src,game:g};
    const epochEvents=(chrono.events||[]).filter(e=>e.status==="ACTIVE").map(e=>({
      eventID:e.eventID,revision:e.revision,asOf:classify(current,e),
      numericBridgeAvailable:e.numericallyBridgeable===true
    }));
    const mean=observedMean(o,item),n=p.completedOperations;
    const hitProbability=(p.actualOperationCountKnown===true&&Number.isSafeInteger(n)&&n>0
      &&Number.isSafeInteger(item.hitOperations)&&item.hitOperations>=0&&item.hitOperations<=n)
        ?item.hitOperations/n:null;
    return {
      outputItemID:item.outputItemID,outputQualityRank:norm(item.outputQualityRank),
      outputFamily,expectedQuantity:mean,dropChanceObserved:hitProbability,
      yieldMinObserved:norm(item.observedConditionalMin),
      yieldMaxObserved:norm(item.observedConditionalMax),
      epochEvents,
      numericNormalizationApplied:false,
      allowedForAutomaticCurrentRetailPromotion:false
    };
  });
  return {
    observationID:o.observationID,studyID:norm(o.studyID),
    gameMode:norm(g.gameMode),expansionID:norm(g.expansionID),clientBuild:norm(g.clientBuild),
    recipeID:norm(p.recipeID),method:norm(p.method),inputItemID:norm(p.inputItemID),
    inputQualityRank:norm(p.inputQualityRank),batchInputsPerOperation:norm(p.batchInputsPerOperation),
    inputFamily,originalTimeEvidence:time,
    sourceURL:norm(src.originalDocumentRef??src.url),sourceClaim:norm(src.sampleClaim),
    reportedObservationDate:norm(src.reportedObservationDate),
    publishedDate:norm(time.publicationDate),
    retrievedDateNotUsedAsObservation:norm(src.retrievedDate),
    originalProfessionContext:{
      effectiveSkill:norm(ctx.effectiveSkill),baseSkill:norm(ctx.baseSkill),
      specialization:norm(ctx.specializations),gear:norm(ctx.professionGear),
      stats:norm(ctx.stats),unknownReasons:norm(ctx.unknownReasons)
    },
    outputs
  };
}
function reprocess(samples,chrono,{familyMap={},files=[]}={}) {
  validateChronology(chrono);
  const ids=new Set();
  const records=samples.map(({record,file,line})=>{
    if(ids.has(record.observationID))throw Error("Duplicate observationID: "+record.observationID);
    ids.add(record.observationID);
    return {rawLocation:{file,line},...processObservation(record,chrono,familyMap)};
  });
  return {
    schemaVersion:"1.0",purpose:"REPROCESSED_EVIDENCE_FOR_ITEMDB_MODELING_NOT_A_RELEASE",
    timelineSHA256:hash(JSON.stringify(chrono)),chronologyVersion:chrono.schemaVersion,
    sourceFileFingerprints:files,rawObservationsChanged:false,
    compiledNumericMechanics:0,productionPromotions:0,observationCount:records.length,
    records
  };
}
function main(argv) {
  if(argv.length<3)throw Error("Usage: node reprocess_observation_archive.js <raw-data-directory> <chronology.json> <output.json> [family-map.json]");
  const [dir,chronologyFile,outputFile,familyFile]=argv;
  const c=JSON.parse(fs.readFileSync(chronologyFile,"utf8"));
  const familyMap=familyFile?JSON.parse(fs.readFileSync(familyFile,"utf8")):{};
  const files=fs.readdirSync(dir).filter(f=>f.endsWith(".jsonl")).map(f=>path.join(dir,f));
  const evidence=loadEvidence(files);
  const result=reprocess(evidence.samples,c,{familyMap,files:evidence.inputs});
  fs.mkdirSync(path.dirname(outputFile),{recursive:true});
  fs.writeFileSync(outputFile,JSON.stringify(result,null,2)+"\n","utf8");
  process.stdout.write(JSON.stringify({outputs:outputFile,observations:result.observationCount,
    unknownTime:result.records.filter(r=>r.originalTimeEvidence.kind==="TIME_UNKNOWN").length,
    publicationOnly:result.records.filter(r=>r.originalTimeEvidence.kind==="PUBLICATION_UPPER_BOUND").length,
    modelValuesPromoted:result.productionPromotions})+"\n");
}
if(require.main===module)main(process.argv.slice(2));
module.exports={hash,loadEvidence,observedMean,processObservation,reprocess};
