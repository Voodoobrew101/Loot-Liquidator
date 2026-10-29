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
  const {validateWorkingEstimates} = require(path.join(root,"research/tools/working_estimates.js"));
  const result = compile(loadInputs(root));
  const errors = [...validate(result.records), ...validateWorkingEstimates(result.records)];
  if (errors.length) throw Error(errors.join("\n"));
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
    for (const file of ["test_mechanics_compiler.js","test_working_estimates.js","test_compile_itemdb.js","test_itemdb_candidate.js","test_completion_pipeline.js","test_five_agent_workflow.js"]) {
      const testPath=path.join(root,"research/tests",file);
      if (!fs.existsSync(testPath)) throw Error("Required check missing: "+file);
      const child=spawnSync(process.execPath,[testPath],{cwd:root,encoding:"utf8"});
      if(child.status!==0) throw Error(file+" failed\n"+child.stdout+child.stderr);
      process.stdout.write(child.stdout);
    }
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
