'use strict';
// Independent F005 adversarial source-ancestry test for F002 priority-122.
// Creates only temporary synthetic source files; never edits research evidence.
const assert=require('node:assert/strict');
const fs=require('node:fs'),os=require('node:os'),path=require('node:path');
const diagnostic=require('../../tools/df_priority122_conflict_diagnostic.js');
const ids=diagnostic.TARGETS;
const pairs=ids.map(id=>{const x=id.split(':');return {id,input:Number(x[2]),output:Number(x[3])};});
const header=['record_key','method','input_id','output_id','source_line','batch_inputs',
  'quantity_unit_basis','input_quality','output_quality','conditional_min',
  'conditional_max','chance','expected_units_per_operation'];
const ledger=[header.join(','),...pairs.map((p,i)=>[
  p.id,'prospect',p.input,p.output,i+1,5,'TSM per input x 5',2,2,1,2,.0142,.014
].join(','))].join('\n');
const original=pairs.map(p=>
  '{id='+p.output+',matRate=0.0142,amountOfMats=0.0028,minAmount=1,maxAmount=2,sourceQuality=2,targetQuality=2},'
).join('\n');
const audit=pairs.map(p=>({
  stableKey:'supplemental:rank-two:'+p.input+':'+p.output,
  inputItemID:p.input,outputItemID:p.output,inputQualityRank:2,outputQualityRank:2,
  sourceLine:null,
  sourceProvenance:{sourceLineageIndependent:false,originalSourceLine:null,originalSourceText:null},
  originalProxy:{actualCompletedOperations:null,historicalFamilyTSMHitChance:.0142,
    historicalFamilyTSMExpectedPerFiveOre:.014}
}));
const records=pairs.map(p=>({
  recordID:p.id,method:'Prospect',inputItemID:p.input,outputItemID:p.output,
  inputQualityRank:2,outputQualityRank:2,
  dropChance:{value:null,confidence:0},
  expectedQuantity:{value:null,confidence:0,
    blockers:['BATCH014_RANK_OR_GROSS_INPUT_EQUIVALENT_NOT_EXACT_CAST_E']},
  workingEstimate:{economicUse:'PREVIEW_ONLY',normalizedVerified:false,
    fieldConfidence:{dropChance:0,expectedQuantity:0},
    fieldStatus:{dropChance:'POLICY_PRIOR',expectedQuantity:'POLICY_PRIOR'},
    dropChance:.014,expectedQuantity:.014}
}));
const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'f005-priority122-'));
function put(relative,contents){const dest=path.join(tmp,relative);
  fs.mkdirSync(path.dirname(dest),{recursive:true});fs.writeFileSync(dest,contents);}
function run(auditRows){
  put('research/ledger/processing-output-fields.csv',ledger);
  put('GameData.lua',original);
  put('research/coordination/submissions/loot-liquidator-dragonflight/2026-10-28-1432-dragonflight-q16-batch014-40key-fourfield-audit.jsonl',
    auditRows.map(x=>JSON.stringify(x)).join('\n'));
  return diagnostic.analyze(tmp,records);
}
let passed=0,failed=0;const cases=[];
function check(name,fn){try{fn();passed++;cases.push({name,result:'PASS'});}
  catch(e){failed++;cases.push({name,result:'FAIL',detail:e.message});}}
try{
  check('five synthetic matched source audits preserve preview quarantine',()=>{
    const r=run(audit);assert.equal(r.targetCount,5);
    assert.equal(r.confidencePromotions,0);assert.equal(r.economicPromotions,0);
    assert.ok(r.results.every(x=>x.verdict==='RETAIN_QUARANTINE_NO_RANK_SPECIFIC_E_OR_P_PROMOTION'));
  });
  check('unmatched source audit output identity is rejected',()=>{
    const a=audit.map(x=>({...x}));a[0]={...a[0],outputItemID:999999};
    assert.throws(()=>run(a));
  });
  check('explicitly contradictory source-line provenance is rejected',()=>{
    const a=audit.map(x=>({...x}));a[0]={...a[0],sourceLine:999};
    assert.throws(()=>run(a));
  });
  check('missing source family audit is rejected',()=>{
    assert.throws(()=>run(audit.slice(1)));
  });
  check('rounded historical P=E hypothesis does not become measured E',()=>{
    const r=run(audit);assert.ok(r.results.every(x=>x.exactDecimalDifferencePMinusE>0));
    assert.ok(r.results.every(x=>x.roundingHypothesis.commonPAndEInterval.nonempty));
    assert.ok(r.results.every(x=>x.evidence.dropChance===null&&x.evidence.expectedQuantity===null));
  });
  check('explicit input-quality rank mismatch in supplemental family must not corroborate rank-2 target',()=>{
    const a=audit.map(x=>({...x}));a[0]={...a[0],inputQualityRank:1,
      stableKey:'supplemental:rank-one:'+pairs[0].input+':'+pairs[0].output};
    assert.throws(()=>run(a),'Matching only input/output IDs can silently attach wrong-rank source ancestry');
  });
}finally{fs.rmSync(tmp,{recursive:true,force:true});}
console.log(JSON.stringify({suite:'F005_PRIORITY122_SUPPLEMENTAL_RANK_LINEAGE',
  syntheticOnly:true,actualRetailCasts:0,passed,failed,cases}));
if(failed)process.exitCode=1;
