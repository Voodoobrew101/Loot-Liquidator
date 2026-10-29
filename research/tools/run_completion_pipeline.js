"use strict";
// Research-only readiness pipeline. Never writes addon runtime or original evidence.
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");
const { spawnSync } = require("node:child_process");
const FIELDS = ["dropChance", "yieldMin", "yieldMax", "expectedQuantity"];

function summarize(records, report) {
  let evidenceNumeric = 0, evidenceGE90 = 0, completeEvidence = 0, workingNumeric = 0;
  let workingComplete = 0, verifiedBaselines = 0;
  const perField = Object.fromEntries(FIELDS.map(f => [f, { numeric: 0, missing: 0, ge90: 0, workingNumeric: 0 }]));
  const priorities = [];
  for (const r of records) {
    let complete = true, fullWorking = true;
    const gaps = [], conflicts = [];
    for (const f of FIELDS) {
      const value = r[f] && r[f].value;
      if (typeof value === "number" && Number.isFinite(value)) {
        evidenceNumeric++; perField[f].numeric++;
      } else { complete = false; perField[f].missing++; gaps.push(f); }
      if (typeof value === "number" && Number.isFinite(value) && r[f].confidence >= 90) {
        evidenceGE90++; perField[f].ge90++;
      }
      if (r[f] && r[f].status === "contradictory") conflicts.push(f);
      const w = r.workingEstimate && r.workingEstimate[f];
      const n = w && typeof w === "object" ? w.value : w;
      if (typeof n === "number" && Number.isFinite(n)) { workingNumeric++; perField[f].workingNumeric++; }
      else fullWorking = false;
    }
    if (complete) completeEvidence++;
    if (fullWorking) workingComplete++;
    if (r.workingEstimate && r.workingEstimate.normalizedVerified === true) verifiedBaselines++;
    if (gaps.length || conflicts.length) priorities.push({
      recordID: r.recordID, method: r.method, inputItemID: r.inputItemID,
      outputItemID: r.outputItemID, recipeSpellID: r.recipeSpellID || null,
      gaps, conflicts,
      priorityBasis: "FIELD_GAP_PROXY_NOT_MEASURED_GOLD_IMPACT",
      priority: (gaps.includes("expectedQuantity") ? 100 : 0) + conflicts.length * 20 + gaps.length,
      nextAction: conflicts.length ? "RECONCILE_SOURCE_CONFLICT" : gaps.includes("expectedQuantity") ? "VALIDATE_OR_REPLACE_E_PRIOR" : "VALIDATE_DISPLAY_METRICS"
    });
  }
  priorities.sort((a,b) => b.priority-a.priority || a.recordID.localeCompare(b.recordID));
  const slots = records.length * FIELDS.length;
  const ratio = n => slots ? n / slots : 0;
  return {
    snapshot: {
      schemaVersion: "1.0.0", status: "RESEARCH_ONLY_NOT_SHIPPED",
      compilerVersion: report.compilerVersion, sourceSHA: report.sourceSHA,
      mappingCount: records.length, fieldSlots: slots,
      independentRetailUniverseAudit: report.independentRetailUniverseAudit,
      exhaustiveRetailCoverage: null,
      evidenceNumericCells: evidenceNumeric, evidenceMissingCells: slots-evidenceNumeric,
      evidenceNumericCoverage: ratio(evidenceNumeric), evidenceCompleteRecords: completeEvidence,
      workingNumericCells: workingNumeric, workingNumericCoverage: ratio(workingNumeric),
      workingCompleteRecords: workingComplete,
      evidenceGE90Cells: evidenceGE90, evidenceGE90Coverage: ratio(evidenceGE90),
      verifiedBaselineRecords: verifiedBaselines, perField,
      confidenceMeaning: "ORDINAL_EVIDENCE_STRENGTH_NOT_PROBABILITY_CORRECT",
      operationalEstimatesAffectLiveValuation: false,
      inGameVerified: false
    }, priorities
  };
}

function writeOrCheck(root, relative, contents, check) {
  const target = path.join(root, relative);
  if (check) {
    if (!fs.existsSync(target) || fs.readFileSync(target,"utf8") !== contents) throw Error("Stale generated file: " + relative);
  } else { fs.mkdirSync(path.dirname(target), {recursive:true}); fs.writeFileSync(target, contents); }
}

function run(root, options={}) {
  const {compile,loadInputs,validate} = require(path.join(root,"research/tools/compile_itemdb.js"));
  const {validateWorkingEstimates,createWorkingAttestation,validateSerializedWorkingEstimates} = require(path.join(root,"research/tools/working_estimates.js"));
  const result = compile(loadInputs(root));
  const errors = [...validate(result.records), ...validateWorkingEstimates(result.records)];
  if (errors.length) throw Error(errors.join("\n"));
  // Exercise the detached v1 source/context/value seal across a JSON reload.
  // A production verifier must obtain the expected digest from a separately
  // pinned coordinator acceptance, never trust the candidate to supply it.
  const {attestation,sha256:pin} = createWorkingAttestation(result.records);
  const reload = value => JSON.parse(JSON.stringify(value));
  const checkSerialized = rows => validateSerializedWorkingEstimates(rows,reload(attestation),pin);
  const reloaded = reload(result.records);
  const serializedErrors = checkSerialized(reloaded);
  if (serializedErrors.length) throw Error("Serialized attestation roundtrip failed: "+serializedErrors.slice(0,8).join(","));
  const sourceMutation = reload(reloaded);
  sourceMutation[0].expectedQuantity.status = "TAMPERED_SOURCE_STATUS";
  if (!checkSerialized(sourceMutation).some(x=>x.startsWith("SERIALIZED_SOURCE_IDENTITY_STALE_OR_TAMPERED:")))
    throw Error("Serialized source-status tamper escaped attestation");
  const contextMutation = reload(reloaded);
  contextMutation[0].conditions.gameMode = "TAMPERED_GAME_MODE";
  if (!checkSerialized(contextMutation).some(x=>x.startsWith("SERIALIZED_SOURCE_IDENTITY_STALE_OR_TAMPERED:")))
    throw Error("Serialized source-context tamper escaped attestation");
  const previewMutation = reload(reloaded);
  previewMutation[0].workingEstimate.expectedQuantity += 1;
  if (!checkSerialized(previewMutation).some(x=>x.startsWith("SERIALIZED_WORKING_PREVIEW_STALE_OR_TAMPERED:")))
    throw Error("Serialized working-value tamper escaped attestation");
  const forgedSeal = reload(attestation);
  forgedSeal.entries[0].sourceSHA256 = "0".repeat(64);
  if (!validateSerializedWorkingEstimates(reloaded,forgedSeal,pin).includes("SERIALIZED_ATTESTATION_UNPINNED_OR_TAMPERED"))
    throw Error("Forged serialized seal escaped external digest pin");
  console.log("PASS: versioned serialized source/context/value attestation, 4 adversarial cases");
  const {snapshot,priorities} = summarize(result.records,result.report);
  if (!snapshot.mappingCount || snapshot.workingNumericCells !== snapshot.fieldSlots) throw Error("Working estimate completeness gate failed");
  const check = options.check === true;
  const outputs = {
    "research/proposed/itemdb.lua": result.lua,
    "research/proposed/itemdb-build-report.json": JSON.stringify(result.report,null,2)+"\n",
    "research/ledger/itemdb-missing-fields.csv": result.gapCSV,
    "research/ledger/itemdb-source-alternates.csv": "method_input_output,selected_source_key,not_selected_source_key\n"+result.alternates.map(r=>r.map(v=>'"'+String(v).replace(/"/g,'""')+'"').join(",")).join("\n")+"\n",
    "research/coordination/completion-readiness.json": JSON.stringify(snapshot,null,2)+"\n",
    "research/coordination/completion-priorities.json": JSON.stringify({schemaVersion:"1.0.0",priorityBasis:"FIELD_GAP_PROXY_NOT_MEASURED_GOLD_IMPACT",records:priorities},null,2)+"\n"
  };
  for (const [relative,contents] of Object.entries(outputs)) writeOrCheck(root,relative,contents,check);
  if (options.test !== false) {
    for (const file of ["test_working_estimates.js","test_compile_itemdb.js","test_itemdb_candidate.js","test_completion_pipeline.js","test_five_agent_workflow.js"]) {
      const testPath=path.join(root,"research/tests",file);
      if (!fs.existsSync(testPath)) throw Error("Required check missing: "+file);
      const child=spawnSync(process.execPath,[testPath],{cwd:root,encoding:"utf8"});
      if(child.status!==0) throw Error(file+" failed\n"+child.stdout+child.stderr);
      process.stdout.write(child.stdout);
    }
    const ancestryTest=path.join(root,"research/tools/working_estimates_ancestry_selftest.js");
    const ancestryChild=spawnSync(process.execPath,[ancestryTest],{cwd:root,encoding:"utf8"});
    if(ancestryChild.status!==0)
      throw Error("working_estimates_ancestry_selftest.js failed\\n"+ancestryChild.stdout+ancestryChild.stderr);
    process.stdout.write(ancestryChild.stdout);
    // Independent validator F005: exercise PMF zero-mass support and stale
    // donor ancestry on native Node, not only in the validator's V8 shim.
    // Keep the validator-owned fixture immutable; CI only invokes it.
    const independentTest=path.join(root,"research/tests/v2/test_f005_postrepair_metamorphic.js");
    if(!fs.existsSync(independentTest)) throw Error("Required independent F005 check missing");
    const independentChild=spawnSync(process.execPath,[independentTest],{cwd:root,encoding:"utf8"});
    if(independentChild.status!==0)
      throw Error("F005 postrepair metamorphic regression failed\\n"+independentChild.stdout+independentChild.stderr);
    process.stdout.write(independentChild.stdout);
    // Independent F005 rank-pool isolation must run on native Node in CI.
    const rankPoolTest=path.join(root,"research/tests/v2/test_f005_rank_pool_isolation.js");
    if(!fs.existsSync(rankPoolTest)) throw Error("Required independent rank-pool check missing");
    const rankPoolChild=spawnSync(process.execPath,[rankPoolTest],{cwd:root,encoding:"utf8"});
    if(rankPoolChild.status!==0)
      throw Error("F005 rank-pool isolation failed\\n"+rankPoolChild.stdout+rankPoolChild.stderr);
    process.stdout.write(rankPoolChild.stdout);
    // F005 policy-anchor and stale-context adversarial suite; retain validator
    // ownership of its fixture and run it without editing the fixture.
    const policyTest=path.join(root,"research/tests/v2/test_f005_pool_policy_anchor_and_target_context.js");
    if(!fs.existsSync(policyTest)) throw Error("Required independent pool-policy check missing");
    const policyChild=spawnSync(process.execPath,[policyTest],{cwd:root,encoding:"utf8"});
    if(policyChild.status!==0)
      throw Error("F005 pool-policy/target-context regression failed\\n"+policyChild.stdout+policyChild.stderr);
    process.stdout.write(policyChild.stdout);
    // Execute the validator-owned full source-identity mutation suite on native Node.
    const identityTest=path.join(root,"research/tests/v2/test_f005_target_identity_staleness.js");
    if(!fs.existsSync(identityTest)) throw Error("Required F005 target-identity check missing");
    const identityChild=spawnSync(process.execPath,[identityTest],{cwd:root,encoding:"utf8"});
    if(identityChild.status!==0)
      throw Error("F005 target-identity regression failed\\n"+identityChild.stdout+identityChild.stderr);
    process.stdout.write(identityChild.stdout);
    // Validator-owned provenance/confidence suite must run in native CI.
    // This rejects stale evidence lineage and self-consistent preview edits.
    const provenanceTest=path.join(root,"research/tests/v2/test_f005_provenance_confidence_integrity.js");
    if(!fs.existsSync(provenanceTest)) throw Error("Required F005 provenance check missing");
    const provenanceChild=spawnSync(process.execPath,[provenanceTest],{cwd:root,encoding:"utf8"});
    if(provenanceChild.status!==0)
      throw Error("F005 provenance/confidence regression failed\\n"+provenanceChild.stdout+provenanceChild.stderr);
    process.stdout.write(provenanceChild.stdout);
    // Independently authored F005 status/claim admission regression. This
    // guards the direct estimator, not just canonical compiler validation.
    const admissionTest=path.join(root,"research/tests/v2/test_f005_evidence_status_claim_contract.js");
    if(!fs.existsSync(admissionTest)) throw Error("Required F005 source-admission check missing");
    const admissionChild=spawnSync(process.execPath,[admissionTest],{cwd:root,encoding:"utf8"});
    if(admissionChild.status!==0)
      throw Error("F005 source-status/claim admission failed\\n"+admissionChild.stdout+admissionChild.stderr);
    process.stdout.write(admissionChild.stdout);
    // F005 independently authored cast-basis/denominator quarantine regression.
    // A source gross-input or rank proxy must not be copied as completed-cast P/E.
    const castBasisTest=path.join(root,"research/tests/v2/test_f005_blocked_evidence_cast_basis.js");
    if(!fs.existsSync(castBasisTest)) throw Error("Required F005 cast-basis check missing");
    const castBasisChild=spawnSync(process.execPath,[castBasisTest],{cwd:root,encoding:"utf8"});
    if(castBasisChild.status!==0)
      throw Error("F005 cast-basis quarantine regression failed\\n"+castBasisChild.stdout+castBasisChild.stderr);
    process.stdout.write(castBasisChild.stdout);
    // F005 independently authored 476-case F003 numerical fixture runs on
    // native Node, not just the independent validator V8 harness.
    const binomialTest=path.join(root,"research/tests/v2/test_f005_f003_independent_binomial_numerics.js");
    if(!fs.existsSync(binomialTest)) throw Error("Required F005/F003 binomial check missing");
    const binomialChild=spawnSync(process.execPath,[binomialTest],{cwd:root,encoding:"utf8",timeout:120000});
    if(binomialChild.status!==0)
      throw Error("F005/F003 independent binomial numerics failed\n"+binomialChild.stdout+binomialChild.stderr);
    process.stdout.write(binomialChild.stdout);
    const schemaInput = result.manifest || {schemaVersion:"0.2.0",artifactStatus:"RESEARCH_ONLY_NOT_SHIPPED",sourceManifest:{gameDataSha:result.report.sourceSHA.gameData,statYieldProfilesSha:result.report.sourceSHA.statYield,reviewDate:"2026-10-29"},processing:result.records,mechanicRules:[]};
    const schemaDir=fs.mkdtempSync(path.join(os.tmpdir(),"ll-candidate-schema-"));
    const schemaFile=path.join(schemaDir,"candidate.json");
    fs.writeFileSync(schemaFile,JSON.stringify(schemaInput));
    let schemaTest;
    try {
      schemaTest=spawnSync("python3",["-c","import json,sys,jsonschema; schema=json.load(open(sys.argv[1])); jsonschema.Draft202012Validator.check_schema(schema); jsonschema.Draft202012Validator(schema).validate(json.load(open(sys.argv[2]))); print('PASS: full generated candidate JSON Schema validation')",path.join(root,"research/proposed/itemdb.schema.json"),schemaFile],{cwd:root,encoding:"utf8",timeout:60000,maxBuffer:16*1024*1024});
    } finally { fs.rmSync(schemaDir,{recursive:true,force:true}); }
    if(schemaTest.status!==0) throw Error("Schema check failed\n"+schemaTest.stdout+schemaTest.stderr);
    process.stdout.write(schemaTest.stdout);
  }
  return snapshot;
}

module.exports={summarize,writeOrCheck,run};
if(require.main===module){
  try {
    const args=process.argv.slice(2),root=path.resolve(args.find(x=>!x.startsWith("--"))||path.join(__dirname,"../.."));
    console.log(JSON.stringify(run(root,{check:args.includes("--check")}),null,2));
  } catch(error){console.error(error.message);process.exitCode=1;}
}
