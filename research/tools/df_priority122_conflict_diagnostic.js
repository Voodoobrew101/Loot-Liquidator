"use strict";
// F002 research-only diagnostic for five priority-122 Dragonflight prospecting
// conflicts. This never repairs or promotes the historical TSM source fields.
// Usage: node research/tools/df_priority122_conflict_diagnostic.js [repo-root]
const fs = require("node:fs");
const path = require("node:path");
const assert = require("node:assert/strict");
const {csv,compile,loadInputs} = require("./compile_itemdb.js");
const TARGETS = Object.freeze([
  "tsm:prospect:188658:192870:L1205",
  "tsm:prospect:188658:192871:L1206",
  "tsm:prospect:189143:192869:L1242",
  "tsm:prospect:189143:192870:L1243",
  "tsm:prospect:190311:192869:L1280"
]);
const SOURCE_PATH = "research/ledger/processing-output-fields.csv";
const AUDIT_PATH = "research/coordination/submissions/loot-liquidator-dragonflight/2026-10-28-1432-dragonflight-q16-batch014-40key-fourfield-audit.jsonl";
function decimalInterval(raw) {
  assert.match(String(raw), /^\d+(?:\.\d+)?$/);
  const digits = (String(raw).split(".")[1] || "").length;
  const half = 0.5 * 10 ** (-digits);
  return {low:Number(raw)-half,high:Number(raw)+half,precision:digits};
}
function intersect(...intervals) {
  const low = Math.max(...intervals.map(x=>x.low));
  const high = Math.min(...intervals.map(x=>x.high));
  return {low,high,nonempty:high>low};
}
function parseRaw(line) {
  const fields = {};
  for(const match of line.matchAll(/(id|matRate|amountOfMats|minAmount|maxAmount|sourceQuality|targetQuality)=(\d+(?:\.\d+)?)/g))
    fields[match[1]] = match[2];
  return fields;
}
function analyze(root,records) {
  const read = p => fs.readFileSync(path.join(root,p),"utf8");
  const primary = new Map(csv(read(SOURCE_PATH)).map(x=>[x.record_key,x]));
  const auditRows = read(AUDIT_PATH).trim().split(/\r?\n/).map(JSON.parse);
  const audits = new Map(auditRows.map(x=>[x.stableKey,x]));
  const lines = read("GameData.lua").split(/\r?\n/);
  const byID = new Map(records.map(x=>[x.recordID,x]));
  const results = [];
  for(const id of TARGETS) {
    const source = primary.get(id), record = byID.get(id);
    // Two batch014 reviews use a supplemental family key rather than the
    // exact primary-ledger key. Match their input/output only for diagnostic
    // corroboration; never re-label the family audit as a rank measurement.
    const audit = audits.get(id) || auditRows.find(x=>source && x.inputItemID===Number(source.input_id) && x.outputItemID===Number(source.output_id));
    assert(source && audit && record, "Missing priority-122 source/audit/candidate: "+id);
    assert.equal(source.method,"prospect");
    assert.equal(record.method,"Prospect");
    assert.equal(Number(source.batch_inputs),5);
    assert.equal(source.quantity_unit_basis,"TSM per input x 5");
    assert.equal(audit.sourceProvenance.sourceLineageIndependent,false);
    assert.equal(audit.originalProxy.actualCompletedOperations,null);
    if(audit.sourceLine!==null) assert.equal(audit.sourceLine,Number(source.source_line));
    else assert.equal(audit.sourceProvenance.originalSourceLine,null);
    assert.equal(audit.inputItemID,Number(source.input_id));
    assert.equal(audit.outputItemID,Number(source.output_id));
    assert.equal(record.inputItemID,audit.inputItemID);
    assert.equal(record.outputItemID,audit.outputItemID);
    assert.equal(record.inputQualityRank,Number(source.input_quality));
    assert.equal(record.outputQualityRank,Number(source.output_quality));
    const original = lines[Number(source.source_line)-1]?.trim();
    if(audit.sourceProvenance.originalSourceText!==null)
      assert.equal(original,audit.sourceProvenance.originalSourceText);
    const raw = parseRaw(original);
    assert.equal(Number(raw.id),record.outputItemID);
    assert.equal(Number(raw.sourceQuality),record.inputQualityRank);
    assert.equal(Number(raw.targetQuality),record.outputQualityRank);
    assert.equal(Number(raw.minAmount),Number(source.conditional_min));
    assert.equal(Number(raw.maxAmount),Number(source.conditional_max));
    assert.equal(Number(raw.matRate),Number(source.chance));
    assert.equal(Number(raw.matRate),audit.originalProxy.historicalFamilyTSMHitChance);
    assert.equal(Number(source.expected_units_per_operation),audit.originalProxy.historicalFamilyTSMExpectedPerFiveOre);
    const nominalBatch = Number(source.batch_inputs);
    const historicalE = nominalBatch*Number(raw.amountOfMats);
    assert(Math.abs(historicalE-Number(source.expected_units_per_operation))<1e-12,"Ledger unit conversion changed: "+id);
    // Historical values are incompatible as exact decimals (P > E) but
    // potentially compatible as independently rounded decimal strings.
    // Neither the meaning of matRate nor the rank-specific allocation is verified.
    const exactDiscrepancy = Number(raw.matRate)-historicalE;
    assert(exactDiscrepancy>0,"Expected source precision conflict disappeared: "+id);
    const pInterval=decimalInterval(raw.matRate);
    const perInputE=decimalInterval(raw.amountOfMats);
    const castEInterval={low:nominalBatch*perInputE.low,high:nominalBatch*perInputE.high};
    const ledgerEInterval=decimalInterval(source.expected_units_per_operation);
    const feasible=intersect(pInterval,castEInterval,ledgerEInterval);
    assert(feasible.nonempty,"No rounding-feasible P=E interval: "+id);
    assert.equal(record.dropChance.value,null);
    assert.equal(record.expectedQuantity.value,null);
    assert.equal(record.dropChance.confidence,0);
    assert.equal(record.expectedQuantity.confidence,0);
    assert(record.expectedQuantity.blockers.includes("BATCH014_RANK_OR_GROSS_INPUT_EQUIVALENT_NOT_EXACT_CAST_E"));
    const w=record.workingEstimate;
    assert(w && w.economicUse==="PREVIEW_ONLY" && w.normalizedVerified===false);
    for(const field of ["dropChance","expectedQuantity"]) {
      assert.equal(w.fieldConfidence[field],0);
      assert.equal(w.fieldStatus[field],"POLICY_PRIOR");
      assert(Number.isFinite(w[field]));
    }
    results.push({
      recordID:id,inputItemID:record.inputItemID,outputItemID:record.outputItemID,
      inputQualityRank:record.inputQualityRank,outputQualityRank:record.outputQualityRank,
      sourceLine:Number(source.source_line),sourceClaimIDs:[source.record_key,audit.stableKey],
      sourceLineage:"HISTORICAL_TSM_SAME_LINEAGE_NOT_INDEPENDENT",
      nominalInputBatch:nominalBatch,actualCompletedCasts:null,patchEpoch:null,
      raw:{matRate:Number(raw.matRate),amountOfMatsPerInput:Number(raw.amountOfMats),
        conditionalMin:Number(raw.minAmount),conditionalMax:Number(raw.maxAmount)},
      historicalLedger:{dropChance:Number(source.chance),expectedQuantityPerNominalFiveInputBatch:Number(source.expected_units_per_operation)},
      exactDecimalDifferencePMinusE:Number(exactDiscrepancy.toFixed(10)),
      roundingHypothesis:{assumesMatRateIsPerCastOccurrenceProbability:true,
        assumesAmountOfMatsIsPerInputUnconditionalQuantity:true,
        assumesIndependentNearestDecimalRounding:true,
        pInterval,castEInterval,ledgerEInterval,
        commonPAndEInterval:feasible,
        interpretation:"MATHEMATICALLY_FEASIBLE_ONLY_NOT_SEMANTICALLY_OR_CONTEXT_VERIFIED"},
      evidence:{dropChance:null,expectedQuantity:null,confidence:0},
      working:{dropChance:w.dropChance,expectedQuantity:w.expectedQuantity,
        fieldConfidence:0,economicUse:"PREVIEW_ONLY",normalizedVerified:false},
      verdict:"RETAIN_QUARANTINE_NO_RANK_SPECIFIC_E_OR_P_PROMOTION"
    });
  }
  assert.equal(results.length,5);
  return {schemaVersion:"1.0.0",taskID:"F002_PRIORITY122_CONFLICT_DIAGNOSTIC",
    status:"RESEARCH_ONLY_NONPROMOTING",sourceFiles:[SOURCE_PATH,AUDIT_PATH,"GameData.lua"],
    targetCount:results.length,roundingFeasibleUnderExplicitUnverifiedHypothesis:results.length,
    exactSourcePExceedsE:results.length,independentCurrentRetailCohorts:0,
    evidenceCellsFilled:0,workingCellsFilled:0,confidencePromotions:0,economicPromotions:0,
    results};
}
function selfTest() {
  const x=intersect(decimalInterval("0.0142"),{low:5*decimalInterval("0.0028").low,high:5*decimalInterval("0.0028").high},decimalInterval("0.014"));
  assert(x.nonempty && Math.abs(x.low-0.01415)<1e-12 && Math.abs(x.high-0.01425)<1e-12);
  assert.equal(intersect({low:0.2,high:0.3},{low:0.1,high:0.19}).nonempty,false);
  assert.deepEqual(parseRaw("{id=192870,matRate=0.0142,amountOfMats=0.0028,minAmount=1,maxAmount=2,sourceQuality=2,targetQuality=2},"),{
    id:"192870",matRate:"0.0142",amountOfMats:"0.0028",minAmount:"1",maxAmount:"2",sourceQuality:"2",targetQuality:"2"});
}
module.exports={analyze,selfTest,decimalInterval,intersect,TARGETS};
if(require.main===module) {
  const root=path.resolve(process.argv[2]||path.join(__dirname,"../.."));
  selfTest();
  const records=compile(loadInputs(root)).records;
  console.log(JSON.stringify(analyze(root,records),null,2));
}
