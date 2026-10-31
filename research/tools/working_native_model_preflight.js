'use strict';
// F002 research-only native preflight; NOT an accepted CI/economic gate.
// Independent F005 owns the fixtures and must review native results before
// this can be promoted into run_completion_pipeline.js.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');
const ROOT = path.resolve(__dirname, '../..');
const PINS = Object.freeze({
  'research/tests/v2/test_f005_df_prospect_array_context_attestation.js': '77519d24493455616dbbf94d142af581aa857c3a',
  'research/tools/models_v2/df_prospecting_joint_cast_conflict_v1.js': '70bab20081db23e899a45b73186200869efae48c',
  'research/models/v2/df_prospecting_joint_cast_conflict_v1.json': 'd18b9ab544bfdc3a575ce88027297ce1ba341893',
  'research/tests/v2/test_f005_tww_milling_skill_rank_source_isolation.js': 'f24454a4187263c064eb3a17e94e0770b279e618',
  'research/evidence/v2/2026-10-30T1032Z-F004-tww-milling-skill-rank.json': '1396ef6ce5348e1d0cf9052ef0ad205975c3f869',
  'research/evidence/v2/source-reviews/2026-10-30T1032Z-F004-tww-milling-skill-rank-source-review.json': 'ae511c18dc3fb4110c81eb48b79b2f072f8e82e5'
});
const SUITES = Object.freeze([
  { file: 'research/tests/v2/test_f005_df_prospect_array_context_attestation.js',
    name: 'F005_DF_PROSPECT_ARRAY_CONTEXT_ATTESTATION', count: 13,
    modelID: 'df-prospecting-joint-cast-conflict-v1.0.2' },
  { file: 'research/tests/v2/test_f005_tww_milling_skill_rank_source_isolation.js',
    name: 'F005_TWW_MILLING_SKILL_RANK_SOURCE_ISOLATION', count: 25,
    sourceBlobSHA: PINS['research/evidence/v2/2026-10-30T1032Z-F004-tww-milling-skill-rank.json'] }
]);
function blobSHA(bytes) {
  return crypto.createHash('sha1').update('blob ' + bytes.length + '\0').update(bytes).digest('hex');
}
function checkPins(root) {
  const rootReal = fs.realpathSync(root);
  for (const [relative, expected] of Object.entries(PINS)) {
    const absolute = path.resolve(root, relative);
    if (!absolute.startsWith(root + path.sep)) throw Error('PATH_OUTSIDE_ROOT: ' + relative);
    const actualReal = fs.realpathSync(absolute);
    if (!actualReal.startsWith(rootReal + path.sep)) throw Error('SYMLINK_OUTSIDE_ROOT: ' + relative);
    if (blobSHA(fs.readFileSync(absolute)) !== expected) throw Error('SOURCE_OR_FIXTURE_PIN_CHANGED: ' + relative);
  }
  const manifest = JSON.parse(fs.readFileSync(path.join(root, 'research/models/v2/df_prospecting_joint_cast_conflict_v1.json'), 'utf8'));
  if (manifest.modelID !== SUITES[0].modelID ||
      manifest.modelSourceBlobSHA !== PINS['research/tools/models_v2/df_prospecting_joint_cast_conflict_v1.js'])
    throw Error('DF_MODEL_MANIFEST_ID_OR_SOURCE_STALE');
  return Object.keys(PINS).length;
}
function validateReport(spec, report, status) {
  if (status !== 0 || !report || report.suite !== spec.name ||
      report.passed !== spec.count || report.failed !== 0 ||
      !Array.isArray(report.cases) || report.cases.length !== spec.count ||
      new Set(report.cases.map(c => c.name)).size !== spec.count ||
      report.cases.some(c => c.result !== 'PASS' || typeof c.name !== 'string' || !c.name))
    throw Error('NATIVE_FIXTURE_RESULT_INVALID: ' + spec.name);
  if (spec.modelID && (report.modelID !== spec.modelID || report.syntheticOnly !== true ||
      report.independentCurrentRetailHoldoutFamilies !== 0))
    throw Error('DF_CONTEXT_OR_HOLDOUT_CLAIM_INVALID');
  if (spec.sourceBlobSHA && (report.sourceBlobSHA !== spec.sourceBlobSHA ||
      report.syntheticMutationChecks !== 15 || report.independentCurrentRetailCohorts !== 0))
    throw Error('TWW_SOURCE_OR_HOLDOUT_CLAIM_INVALID');
  return { suite: spec.name, passed: spec.count, failed: 0, currentRetailHoldouts: 0 };
}
function selfTest() {
  const bytes = Buffer.from('abc');
  if (blobSHA(bytes) !== 'f2ba8f84ab5c1bce84a7b441cb1959cfc7093b7f') throw Error('GIT_BLOB_SHA_TEST_FAILED');
  const spec = SUITES[0];
  const report = { suite: spec.name, passed: 13, failed: 0, modelID: spec.modelID,
    syntheticOnly: true, independentCurrentRetailHoldoutFamilies: 0,
    cases: Array.from({ length: 13 }, (_, i) => ({ name: 'case-' + i, result: 'PASS' })) };
  validateReport(spec, report, 0);
  let rejected = 0;
  for (const mutate of [
    x => { x.failed = 1; }, x => { x.passed = 12; },
    x => { x.cases[0].result = 'FAIL'; }, x => { x.cases[1].name = 'case-0'; },
    x => { x.syntheticOnly = false; }, x => { x.independentCurrentRetailHoldoutFamilies = 1; },
    x => { x.modelID = 'wrong'; }
  ]) {
    const copy = JSON.parse(JSON.stringify(report)); mutate(copy);
    try { validateReport(spec, copy, 0); } catch (_) { rejected++; }
  }
  try { validateReport(spec, report, 1); } catch (_) { rejected++; }
  if (rejected !== 8) throw Error('ADVERSARIAL_SELFTEST_FAILED: ' + rejected);
  return { passed: 10, failed: 0, description: 'Git blob hash, positive fixture and eight malformed-result probes' };
}
function run(root = ROOT) {
  const pinnedFiles = checkPins(root);
  const results = [];
  for (const spec of SUITES) {
    const child = spawnSync(process.execPath, [path.join(root, spec.file)],
      { cwd: root, encoding: 'utf8', timeout: 120000, maxBuffer: 4 * 1024 * 1024 });
    if (child.error) throw Error('NATIVE_FIXTURE_EXECUTION_FAILED: ' + spec.name + ': ' + child.error.message);
    let report;
    try { report = JSON.parse((child.stdout || '').trim()); }
    catch (_) { throw Error('NATIVE_FIXTURE_NON_JSON_OUTPUT: ' + spec.name + ': ' + (child.stdout || '').slice(0, 300)); }
    results.push(validateReport(spec, report, child.status));
  }
  return { status: 'PREFLIGHT_ONLY_NOT_F005_ACCEPTANCE', runtime: process.version,
    pinnedFiles, suites: results, totalPassed: 38, totalFailed: 0,
    economicPromotions: 0, currentRetailHoldouts: 0 };
}
if (require.main === module) {
  try { console.log(JSON.stringify(process.argv.includes('--self-test') ? selfTest() : run())); }
  catch (error) { console.error('F002 native preflight FAIL: ' + error.message); process.exitCode = 1; }
}
module.exports = { PINS, SUITES, blobSHA, checkPins, validateReport, selfTest, run };
