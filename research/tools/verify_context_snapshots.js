'use strict';
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const {spawnSync}=require('node:child_process');
const blob=bytes=>crypto.createHash('sha1').update('blob '+bytes.length+'\0').update(bytes).digest('hex');
function verify(root) {
 for(const name of ['df_prospecting_joint_cast_conflict_v1','midnight_rare_gem_anytime_e_bounds_v1']) {
  const manifest=JSON.parse(fs.readFileSync(path.join(root,'research/models/v2',name+'.json'),'utf8'));
  const dependency=manifest.contextSnapshotSource;
  if(!dependency||dependency.path!=='research/tools/models_v2/json_context_snapshot.js'||
     blob(fs.readFileSync(path.join(root,dependency.path)))!==dependency.gitBlobSHA)
   throw Error('Context snapshot dependency changed without manifest re-pin: '+name);
 }
 const file='research/tests/v2/test_f005_df_prospect_array_context_attestation.js';
 const expectedFixtureBlob='77519d24493455616dbbf94d142af581aa857c3a';
 if(blob(fs.readFileSync(path.join(root,file)))!==expectedFixtureBlob)
  throw Error('Array context fixture changed without explicit review and re-pin');
 const child=spawnSync(process.execPath,[path.join(root,file)],{cwd:root,encoding:'utf8'});
 const report=JSON.parse(child.stdout||'null');
 if(child.status!==0||!report||report.suite!=='F005_DF_PROSPECT_ARRAY_CONTEXT_ATTESTATION'||
    report.syntheticOnly!==true||report.independentCurrentRetailHoldoutFamilies!==0||
    report.passed!==13||report.failed!==0||!Array.isArray(report.cases)||report.cases.length!==13||
    new Set(report.cases.map(c=>c.name)).size!==13||report.cases.some(c=>c.result!=='PASS'))
  throw Error('Array context attestation must pass all 13 cases: '+child.stdout+child.stderr);
 console.log('PASS: source-pinned snapshot dependency and native array context attestation 13/13; research-only');
}
module.exports={verify};
if(require.main===module)verify(path.resolve(__dirname,'../..'));
