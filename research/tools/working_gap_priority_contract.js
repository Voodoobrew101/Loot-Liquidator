'use strict';
// F002: research-only generated-gap identity gate. Not a validation of missing evidence.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const F=['dropChance','yieldMin','yieldMax','expectedQuantity'];
const ROOT=path.resolve(__dirname,'../..');
const PATHS={csv:'research/ledger/itemdb-missing-fields.csv',priorities:'research/coordination/completion-priorities.json',readiness:'research/coordination/completion-readiness.json',report:'research/proposed/itemdb-build-report.json'};
function csvParse(s){
 const lines=[],row=[];let field='',quoted=false;
 for(let i=0;i<s.length;i++){const c=s[i];
  if(c==='"'){if(quoted&&s[i+1]==='"'){field+='"';i++;}else quoted=!quoted;}
  else if(c===','&&!quoted){row.push(field);field='';}
  else if((c==='\n'||c==='\r')&&!quoted){if(c==='\r'&&s[i+1]==='\n')i++;row.push(field);field='';if(row.some(x=>x!==''))lines.push(row.splice(0));else row.length=0;}
  else field+=c;
 }
 if(quoted)throw Error('UNCLOSED_CSV_QUOTE');
 if(row.length||field){row.push(field);lines.push(row);}
 return lines;
}
function check(csv,priorities,readiness,report){
 const fail=code=>{throw Error(code);};
 const rows=csvParse(csv),header=rows.shift();
 if(JSON.stringify(header)!==JSON.stringify(['record_id','method','input_id','output_id','missing_field','status','reason']))fail('CSV_HEADER_DRIFT');
 if(!Array.isArray(priorities.records)||!Number.isInteger(readiness.mappingCount)||!Number.isInteger(readiness.fieldSlots))fail('ARTIFACT_SHAPE');
 const gaps=new Map(),fields=Object.fromEntries(F.map(f=>[f,0])),unique=new Set();
 for(const [i,row] of rows.entries()){
  if(row.length!==7)fail('CSV_COLUMN_COUNT:'+i);
  const [id,method,input,output,field,status,reason]=row;
  if(!id||!method||!/^[1-9]\d*$/.test(input)||!/^[1-9]\d*$/.test(output)||!F.includes(field)||!['unknown','contradictory'].includes(status)||!reason)fail('CSV_INVALID_GAP:'+i);
  const key=id+'\u0000'+field;if(unique.has(key))fail('CSV_DUPLICATE_GAP:'+key);unique.add(key);fields[field]++;
  if(!gaps.has(id))gaps.set(id,[]);gaps.get(id).push({method,input:Number(input),output:Number(output),field});
 }
 const seen=new Set();
 for(const r of priorities.records){
  if(!r||typeof r.recordID!=='string'||seen.has(r.recordID))fail('PRIORITY_DUPLICATE_OR_INVALID_ID');
  seen.add(r.recordID);const found=gaps.get(r.recordID);
  if(!found)fail('PRIORITY_RECORD_WITHOUT_CSV_GAP:'+r.recordID);
  if(!Array.isArray(r.gaps)||new Set(r.gaps).size!==r.gaps.length||r.gaps.length!==found.length)fail('PRIORITY_GAP_CARDINALITY:'+r.recordID);
  for(const x of found)if(!r.gaps.includes(x.field)||x.method!==r.method||x.input!==r.inputItemID||x.output!==r.outputItemID)fail('PRIORITY_IDENTITY_OR_FIELD_DRIFT:'+r.recordID+':'+x.field);
 }
 if(gaps.size!==seen.size)fail('CSV_GAP_NOT_IN_PRIORITIES');
 const total=rows.length;
 if(total!==readiness.evidenceMissingCells||readiness.fieldSlots!==readiness.mappingCount*4||readiness.workingNumericCells!==readiness.fieldSlots||readiness.workingNumericCoverage!==1||readiness.workingCompleteRecords!==readiness.mappingCount)fail('READINESS_COVERAGE_DRIFT');
 if(readiness.evidenceNumericCells+total!==readiness.fieldSlots||readiness.evidenceCompleteRecords!==readiness.mappingCount-gaps.size)fail('READINESS_EVIDENCE_DRIFT');
 if(report.sourceMappingCandidates!==readiness.mappingCount||report.fieldSlots!==readiness.fieldSlots||report.fullyNumericFourFields!==readiness.evidenceCompleteRecords)fail('BUILD_REPORT_TOTAL_DRIFT');
 for(const f of F){const r=readiness.perField?.[f];if(!r||r.missing!==fields[f]||r.numeric+fields[f]!==readiness.mappingCount||r.workingNumeric!==readiness.mappingCount||report.missingFieldCounts?.[f]!==fields[f])fail('PER_FIELD_GAP_DRIFT:'+f);}
 if(readiness.operationalEstimatesAffectLiveValuation!==false||readiness.status!=='RESEARCH_ONLY_NOT_SHIPPED'||report.productionWrites!==0)fail('ECONOMIC_POLICY_DRIFT');
 return {status:'PASS_RESEARCH_ONLY',admittedMappings:readiness.mappingCount,workingNumericCells:readiness.workingNumericCells,priorityRecords:seen.size,evidenceMissingCells:total,missingByField:fields,missingExpectedQuantity:fields.expectedQuantity,independentEvidenceValidated:false,economicPromotions:0};
}
function selfTest(){
 const csv='record_id,method,input_id,output_id,missing_field,status,reason\n"id-1","Mill","1","2","expectedQuantity","unknown","NOT_MEASURED"\n';
 const priorities={records:[{recordID:'id-1',method:'Mill',inputItemID:1,outputItemID:2,gaps:['expectedQuantity']}]};
 const readiness={status:'RESEARCH_ONLY_NOT_SHIPPED',mappingCount:1,fieldSlots:4,workingNumericCells:4,workingNumericCoverage:1,workingCompleteRecords:1,evidenceMissingCells:1,evidenceNumericCells:3,evidenceCompleteRecords:0,operationalEstimatesAffectLiveValuation:false,perField:{dropChance:{numeric:1,missing:0,workingNumeric:1},yieldMin:{numeric:1,missing:0,workingNumeric:1},yieldMax:{numeric:1,missing:0,workingNumeric:1},expectedQuantity:{numeric:0,missing:1,workingNumeric:1}}};
 const report={sourceMappingCandidates:1,fieldSlots:4,fullyNumericFourFields:0,missingFieldCounts:{dropChance:0,yieldMin:0,yieldMax:0,expectedQuantity:1},productionWrites:0};
 assert.equal(check(csv,priorities,readiness,report).evidenceMissingCells,1);
 const mutants=[
  [csv.replace('expectedQuantity','dropChance'),priorities,readiness,report],
  [csv+csv.split('\n')[1]+'\n',priorities,readiness,report],
  [csv,{records:[]},readiness,report],
  [csv,{records:[{...priorities.records[0],inputItemID:3}]},readiness,report],
  [csv,priorities,{...readiness,workingNumericCells:3},report],
  [csv,priorities,{...readiness,evidenceMissingCells:0},report],
  [csv,priorities,{...readiness,evidenceCompleteRecords:1},report],
  [csv,priorities,{...readiness,operationalEstimatesAffectLiveValuation:true},report],
  [csv,priorities,readiness,{...report,productionWrites:1}],
  [csv,priorities,readiness,{...report,missingFieldCounts:{...report.missingFieldCounts,expectedQuantity:0}}],
  [csv.replace('NOT_MEASURED',''),priorities,readiness,report],
  [csv.replace('unknown','measured'),priorities,readiness,report]
 ];
 for(const args of mutants)assert.throws(()=>check(...args));
 assert.throws(()=>csvParse('"unterminated'));
 assert.deepEqual(csvParse('a,b\n"x,y","z"\n'),[['a','b'],['x,y','z']]);
 return {status:'PASS',adversarialMutationsRejected:mutants.length+1,independentEvidenceValidated:false};
}
function run(root=ROOT){const read=p=>fs.readFileSync(path.join(root,p),'utf8');return check(read(PATHS.csv),JSON.parse(read(PATHS.priorities)),JSON.parse(read(PATHS.readiness)),JSON.parse(read(PATHS.report)));}
if(require.main===module){try{console.log(JSON.stringify(process.argv.includes('--self-test')?selfTest():run()));}catch(e){console.error('F002 gap-priority contract FAIL: '+e.message);process.exitCode=1;}}
module.exports={csvParse,check,selfTest,run};
