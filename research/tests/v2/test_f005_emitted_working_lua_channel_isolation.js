'use strict';
// F005 independently parses the emitted v0.8 Lua, including the separate
// working, contexts and selection tables. It does not trust derived F002 JSON.
// Run: node research/tests/v2/test_f005_emitted_working_lua_channel_isolation.js
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const PIN='560b885a0039045419c340716e263ae33ddf827a';
const LUA=path.resolve(__dirname,'../../proposed/itemdb.lua');
const FIELDS=['dropChance','yieldMin','yieldMax','expectedQuantity'];
function gitBlob(bytes){return crypto.createHash('sha1').update(Buffer.from('blob '+bytes.length+'\0')).update(bytes).digest('hex');}
function extract(lua,label){
 let i=lua.indexOf('local '+label+'=');
 if(i<0)throw Error('MISSING_TABLE:'+label);
 i=lua.indexOf('{',i);
 const start=i;let depth=0,quote=false,escape=false;
 for(;i<lua.length;i++){const c=lua[i];if(quote){if(escape)escape=false;else if(c==='\\')escape=true;else if(c==='"')quote=false;}else if(c==='"')quote=true;else if(c==='{')depth++;else if(c==='}'&&--depth===0){i++;break;}}
 if(depth!==0)throw Error('UNCLOSED_TABLE:'+label);
 const t=lua.slice(start,i);let p=0;
 function ws(){while(/\s/.test(t[p]||''))p++;}
 function value(){
  ws();
  if(t[p]==='{'){p++;let arr=[],obj={},keyed=false;
   for(;;){ws();if(t[p]==='}'){p++;return keyed?obj:arr;}
    let key=null;if(t[p]==='['){p++;key=value();ws();if(t[p++]!==']'||t[p++]!=='=')throw Error('INVALID_KEY:'+p);keyed=true;}
    const v=value();if(key!==null)obj[key]=v;else arr.push(v);
    ws();if(t[p]===',')p++;else if(t[p]!=='}')throw Error('INVALID_SEPARATOR:'+p);
   }
  }
  if(t[p]==='"'){const start=p++;let escape=false;for(;p<t.length;){const c=t[p++];if(escape)escape=false;else if(c==='\\')escape=true;else if(c==='"')break;}return JSON.parse(t.slice(start,p));}
  const m=t.slice(p).match(/^(?:true|false|nil|-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)/);
  if(!m)throw Error('INVALID_VALUE:'+label+':'+p);p+=m[0].length;
  return m[0]==='true'?true:m[0]==='false'?false:m[0]==='nil'?null:Number(m[0]);
 }
 const rows=value();ws();if(p!==t.length)throw Error('TRAILING_TABLE_CONTENT:'+label);return rows;
}
function parse(lua){return {raw:extract(lua,'raw'),working:extract(lua,'working'),contexts:extract(lua,'contexts'),selections:extract(lua,'selections')};}
function audit(t,lua){
 let checks=0,prior=Object.fromEntries(FIELDS.map(f=>[f,0])),copied=Object.fromEntries(FIELDS.map(f=>[f,0])),tooltip=0;
 const ok=(v,msg)=>{checks++;if(!v)throw Error('EMITTED_LUA_INTEGRITY:'+msg);};
 const {raw,working,contexts,selections}=t;
 ok(raw.length===1018&&working.length===1018&&contexts.length===1018&&selections.length===1018,'ROW_COUNTS');
 const ids=new Set(raw.map(r=>r[0]));ok(ids.size===1018,'UNIQUE_MAPPING_KEYS');
 for(let i=0;i<raw.length;i++){
  const r=raw[i],w=working[i],c=contexts[i],s=selections[i],id=r[0],ctx=w.targetContext;
  ok(w.economicUse==='PREVIEW_ONLY'&&w.normalizedVerified===false&&w.evidenceFieldsPreserved===true,'PREVIEW_FLAGS:'+id);
  ok(s.selectedRecordID===id&&s.normalizedVerified===false,'SELECTION_ID:'+id);
  ok(ctx.contextID==='HYPOTHETICAL_PREVIEW_NOT_VERIFIED_BASELINE'&&ctx.operationBasis==='ONE_COMPLETED_OPERATION','CONTEXT_BASIS:'+id);
  ok(ctx.inputCountPerOperation===r[6]&&ctx.inputQualityRank===r[7]&&ctx.outputQualityRank===r[8],'INPUT_OUTPUT_RANK:'+id);
  ok(ctx.gameMode===c.gameMode&&ctx.patchWindow===(c.patchWindow??false),'PATCH_MODE:'+id);
  ok(ctx.sourceQuantityBasis===(c.quantityBasis??'UNKNOWN')&&ctx.eligibilityStatus===(c.eligibilityStatus??'UNKNOWN')&&ctx.sourceBaselineStatus===(c.baselineStatus??'UNKNOWN'),'SOURCE_CONTEXT:'+id);
  ok(Array.isArray(w.sourceRecordIDs)&&w.sourceRecordIDs.every(k=>ids.has(k)),'DONOR_ANCESTRY:'+id);
  for(let j=0;j<FIELDS.length;j++){
   const f=FIELDS[j],n=w[f],source=r[9+j],status=w.fieldStatus[f],confidence=w.fieldConfidence[f];
   ok(typeof n==='number'&&Number.isFinite(n),'FINITE:'+id+':'+f);
   if(status==='COPIED_EVIDENCE'){
    copied[f]++;ok(n===source[0]&&confidence===source[2]&&source[1]!==7,'COPIED_SOURCE:'+id+':'+f);
   }else if(status==='POLICY_PRIOR'||status==='WORKING_CONSISTENCY_ADJUSTMENT'){
    if(status==='POLICY_PRIOR')prior[f]++;
    ok(confidence===0,'IMPUTATION_CONFIDENCE_ZERO:'+id+':'+f);
   }else ok(false,'UNKNOWN_FIELD_STATUS:'+id+':'+f);
  }
  ok(w.dropChance>=0&&w.dropChance<=1&&w.expectedQuantity>=0&&w.yieldMin>=0&&w.yieldMax>=w.yieldMin,'WORKING_BOUNDS:'+id);
  if(w.dropChance>0&&w.conditionalYieldApplicable)ok(w.dropChance*w.yieldMin<=w.expectedQuantity+1e-7&&w.expectedQuantity<=w.dropChance*w.yieldMax+1e-7,'ZERO_INCLUSIVE_E:'+id);
  if(FIELDS.some(f=>w.fieldStatus[f]!=='COPIED_EVIDENCE'))ok(w.confidence===0,'OVERALL_IMPUTED_CONFIDENCE_ZERO:'+id);
  if(r[37]!==false){tooltip++;ok(r[37][13]==='PROVISIONAL_TOOLTIP_ONLY_NOT_ECONOMIC','TOOLTIP_SOURCE:'+id);}
 }
 ok(tooltip===1,'TOOLTIP_COUNT');
 if(lua!==undefined){
  ok(lua.includes('economicUse="PROHIBITED",displayOnly=true,profileIsMeasured=false,denominatorVerifiedCompletedCasts=false'),'TOOLTIP_EMITTER_PROHIBITION');
  ok(lua.includes('processing[i].workingEstimate=working[i]')&&lua.includes('artifactStatus="RESEARCH_ONLY_NOT_SHIPPED"'),'SEPARATE_CHANNEL_EMITTER');
 }
 return {checks,records:raw.length,workingNumericCells:raw.length*4,prior,copied,tooltipRecords:tooltip};
}
function mutants(parsed){
 const copy=x=>JSON.parse(JSON.stringify(x));let rejected=0;
 const cases=[
  x=>x.working[0].economicUse='LIVE',
  x=>x.working[0].normalizedVerified=true,
  x=>x.working[0].fieldConfidence.dropChance=1,
  x=>x.working[0].expectedQuantity=NaN,
  x=>x.working[0].dropChance=1.5,
  x=>x.working[0].targetContext.inputCountPerOperation=6,
  x=>x.selections[0].selectedRecordID='FORGED',
  x=>x.working[0].yieldMin=99,
  x=>x.working[0].sourceRecordIDs=['NONEXISTENT'],
  x=>x.contexts[0].quantityBasis='FORGED',
  x=>x.working[0].fieldConfidence.yieldMin=99,
  x=>x.working[0].targetContext.outputQualityRank=3
 ];
 for(const mutate of cases){const x=copy(parsed);mutate(x);try{audit(x);}catch(_){rejected++;}}
 if(rejected!==cases.length)throw Error('ESCAPED_MUTANTS:'+rejected+'/'+cases.length);
 return rejected;
}
function run(lua){
 const parsed=parse(lua),result=audit(parsed,lua);
 return {suite:'F005_EMITTED_WORKING_LUA_CHANNEL_ISOLATION',sourceBlobSHA:PIN,...result,mutantsRejected:mutants(parsed),economicPromotions:0,independentRetailCasts:0};
}
if(require.main===module){try{const bytes=fs.readFileSync(LUA);if(gitBlob(bytes)!==PIN)throw Error('CANDIDATE_SOURCE_CHANGED_REVIEW_REQUIRED');console.log(JSON.stringify(run(bytes.toString('utf8')),null,2));}catch(e){console.error('F005 emitted Lua FAIL: '+e.message);process.exitCode=1;}}
module.exports={parse,audit,mutants,run};
