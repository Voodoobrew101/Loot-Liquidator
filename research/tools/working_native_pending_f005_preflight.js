'use strict';
// F002: source-pinned, research-only native replay of pending independent F005 suites.
// This preflight is NOT F005 acceptance and does not promote any economic field.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');
const ROOT = path.resolve(__dirname, '../..');
const PINS = Object.freeze({
  'research/tools/models_v2/midnight_prospect_hotfix_epoch_isolation_v1.js': '70652482e4ac63db50f567fae5cbb35e6f50accd',
  'research/models/v2/midnight_prospect_hotfix_epoch_isolation_v1.json': '4820000901b87d122e864a08cf88d6decd25746d',
  'research/coordination/completion-priorities.json': 'a656c3afa7e8cf2e6f3e5b93915706985a6eefae',
  'research/evidence/v2/2026-10-30T0826Z-F004-midnight-diamond-ore-trait-gates.json': '6433cfe3cc77a1b91da6da09e3bf18581f994c87',
  'research/evidence/v2/2026-10-30T1428Z-F004-tww-prospecting-amber-substitution-epoch.json': '93ae42122b69df8a60389d3fd466c92c91d48e7c',
  'research/tests/v2/test_f005_midnight_prospect_compare_summary_attestation.js': 'a909b82ec0144bbcd48b868103c955d1e33d851a',
  'research/tests/v2/test_f005_midnight_prospect_mar31_official_epoch.js': '167582dd8448ec3abe686d036c4a2f4d938ecde4',
  'research/tests/v2/test_f005_midnight_prospect_context_array_attestation.js': '08e6dba858bffb69561fc8c7f238af8e51e340a4',
  'research/tests/v2/test_f005_midnight_diamond_trait_eligibility.js': 'b79c4cc0acbcd84026b6bb38caa56024e4d636d0',
  'research/tests/v2/test_f005_tww_prospect_amber_substitution_source_isolation.js': 'c80c7a853437151593d17dcbd26acc13ca883a7b'
});
const SUITES = Object.freeze([
  {file:'research/tests/v2/test_f005_midnight_prospect_compare_summary_attestation.js',
   suite:'F005_MIDNIGHT_PROSPECT_COMPARE_SUMMARY_ATTESTATION', count:18},
  {file:'research/tests/v2/test_f005_midnight_prospect_mar31_official_epoch.js',
   suite:'F005_MIDNIGHT_PROSPECT_MARCH31_OFFICIAL_EPOCH', count:26},
  {file:'research/tests/v2/test_f005_midnight_prospect_context_array_attestation.js',
   suite:'F005_MIDNIGHT_PROSPECT_CONTEXT_ARRAY_ATTESTATION', count:12},
  {file:'research/tests/v2/test_f005_midnight_diamond_trait_eligibility.js',
   suite:'F005_MIDNIGHT_DIAMOND_TRAIT_ELIGIBILITY', count:19},
  {file:'research/tests/v2/test_f005_tww_prospect_amber_substitution_source_isolation.js',
   suite:'F005_TWW_PROSPECT_AMBER_SUBSTITUTION_SOURCE_ISOLATION', count:31}
]);
function gitBlobSHA(bytes) {
  return crypto.createHash('sha1').update(Buffer.from('blob ' + bytes.length + '\0')).update(bytes).digest('hex');
}
function verifyPins(root=ROOT, pins=PINS) {
  const rootReal=fs.realpathSync(root);
  for (const [relative, expected] of Object.entries(pins)) {
    if (!/^[a-f0-9]{40}$/.test(expected)) throw Error('INVALID_PIN: '+relative);
    const absolute=path.resolve(root,relative);
    if (!absolute.startsWith(root+path.sep)) throw Error('PATH_ESCAPE: '+relative);
    const real=fs.realpathSync(absolute);
    if (!real.startsWith(rootReal+path.sep)) throw Error('SYMLINK_ESCAPE: '+relative);
    if (gitBlobSHA(fs.readFileSync(real))!==expected) throw Error('PIN_MISMATCH: '+relative);
  }
  return Object.keys(pins).length;
}
function validateReport(output, spec) {
  const lines=output.trim().split(/\r?\n/).filter(Boolean);
  let report;
  try { report=JSON.parse(lines.at(-1)); } catch (_) { throw Error('INVALID_TEST_JSON: '+spec.file); }
  if (report.suite!==spec.suite) throw Error('SUITE_ID_MISMATCH: '+spec.file);
  if (report.passed!==spec.count || report.failed!==0 ||
      !Array.isArray(report.cases) || report.cases.length!==spec.count ||
      report.cases.some(x=>x.result!=='PASS')) throw Error('UNEXPECTED_TEST_RESULT: '+spec.file);
  return {suite:report.suite,passed:report.passed,failed:0,syntheticOnly:true};
}
function selfTest() {
  const bytes=Buffer.from('hello');
  if (gitBlobSHA(bytes)!=='b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0') throw Error('GIT_BLOB_HASH');
  const spec={file:'fixture',suite:'FIXTURE',count:1};
  const good=JSON.stringify({suite:'FIXTURE',passed:1,failed:0,cases:[{result:'PASS'}]});
  validateReport(good,spec);
  let rejected=0;
  for (const bad of [
    '{"suite":"FIXTURE","passed":1,"failed":0,"cases":[{"result":"FAIL"}]}',
    '{"suite":"FIXTURE","passed":1,"failed":0,"cases":[]}',
    '{"suite":"WRONG","passed":1,"failed":0,"cases":[{"result":"PASS"}]}',
    '{"suite":"FIXTURE","passed":1,"failed":1,"cases":[{"result":"PASS"}]}',
    'not-json'
  ]) {
    try {validateReport(bad,spec);} catch (_) {rejected++;}
  }
  if (rejected!==5) throw Error('REPORT_FAIL_CLOSED');
  return {status:'PASS',checks:7,mutantReportsRejected:5};
}
function run() {
  const pinnedFiles=verifyPins();
  const suites=[];
  for (const spec of SUITES) {
    const child=spawnSync(process.execPath,[path.join(ROOT,spec.file)],{
      cwd:ROOT,encoding:'utf8',timeout:45000,maxBuffer:4*1024*1024
    });
    if (child.error || child.status!==0 || child.signal) {
      throw Error('NATIVE_SUITE_FAILED: '+spec.file+': '+String(child.error||child.signal||child.status)+'\n'+(child.stdout||'')+'\n'+(child.stderr||''));
    }
    suites.push(validateReport(child.stdout,spec));
  }
  return {
    status:'NATIVE_PRECHECK_ONLY_NOT_INDEPENDENT_ACCEPTANCE',
    node:process.version,pinnedFiles,
    suites,totalPassed:suites.reduce((n,s)=>n+s.passed,0),totalFailed:0,
    independentCurrentRetailHoldouts:0,confidencePromotions:0,economicPromotions:0,
    note:'No real cast verification, no mapping admission and no live EV or tooltip-only change'
  };
}
if (require.main===module) {
  try { console.log(JSON.stringify(process.argv.includes('--self-test')?selfTest():run())); }
  catch (error) { console.error('F002 pending F005 native preflight FAIL: '+error.message); process.exitCode=1; }
}
module.exports={PINS,SUITES,gitBlobSHA,verifyPins,validateReport,selfTest,run};
