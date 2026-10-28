"use strict";
// Research-only: conservative synthesis of primary study observations, never an itemdb writer.
// node research/tools/synthesize_studies.js [file1.jsonl ...] (no files = entire observations directory)
const fs=require("node:fs"),path=require("node:path");
const ROOT=path.resolve(__dirname,"../evidence/observations");
function read(file){return fs.readFileSync(file,"utf8").split(/\r?\n/).filter(Boolean).map((line,i)=>{
 try{return JSON.parse(line);}catch(e){throw new Error(file+":"+(i+1)+" "+e.message);}
});}
function sourceKey(o){
 const raw=o?.source?.originalDocumentRef||o?.source?.url||o?.studyID||o?.observationID;
 if(!raw)return null;
 try {const u=new URL(raw); return (u.origin+u.pathname.replace(/\/+$/,"")).toLowerCase();}
 catch {return String(raw).trim().toLowerCase();}
}
function stable(x){if(x===undefined)return null;if(Array.isArray(x))return x.map(stable);
 if(x&&typeof x==="object")return Object.fromEntries(Object.keys(x).sort().map(k=>[k,stable(x[k])]));
 return x;}
function makeKey(o,item){
 const p=o.processing||{},g=o.game||{},c=o.characterContext||{};
 const context={gameMode:g.gameMode,expansionID:g.expansionID,clientBuild:g.clientBuild,
 hotfixWindow:g.hotfixWindow,method:p.method,recipeID:p.recipeID,inputItemID:p.inputItemID,
 inputQualityRank:p.inputQualityRank,batch:p.batchInputsPerOperation,
 outputItemID:item.outputItemID,outputQualityRank:item.outputQualityRank,
 childSkillLineID:c.childSkillLineID,baseSkill:c.baseSkill,effectiveSkill:c.effectiveSkill,
 specializations:c.specializations,professionGear:c.professionGear,stats:c.stats,
 concentrationUsed:c.concentrationUsed};
 const missing=[];
 for(const [label,value] of Object.entries(context))if(value===null||value===undefined)missing.push(label);
 const complete=!missing.length && g.gameMode==="RETAIL";
 // Unknown patches/profession contexts may NOT be considered compatible across studies.
 if(!complete)context.unmatchedSourceStudy=o.studyID||o.observationID;
 return {key:JSON.stringify(stable(context)),context,missing,complete};
}
function isNumeric(v){return typeof v==="number"&&Number.isFinite(v);}
function entry(o,item){
 const p=o.processing||{},n=p.completedOperations;
 const validItem=Number.isSafeInteger(item.outputItemID)&&item.outputItemID>0;
 const actual=Number.isSafeInteger(n)&&n>0&&p.actualOperationCountKnown===true;
 const raw=isNumeric(item.totalUnits)&&item.totalUnits>=0;
 const valid=validItem&&actual&&raw;
 const verified=valid&&p.batchCountDenominatorVerified===true;
 const blockers=[];
 if(!validItem)blockers.push("UNMAPPED_OUTPUT");
 if(!actual)blockers.push("ACTUAL_COMPLETED_OPERATIONS_UNVERIFIED");
 if(!raw)blockers.push("MISSING_TOTAL_OUTPUT_UNITS");
 if(valid&&!verified)blockers.push("BATCH_DENOMINATOR_NOT_INDEPENDENTLY_VERIFIED");
 if(!o.game?.clientBuild||!o.game?.hotfixWindow)blockers.push("PATCH_CONTEXT_INCOMPLETE");
 if(!Number.isSafeInteger(p.recipeID))blockers.push("RECIPE_ID_UNKNOWN");
 if(o.normalization?.status?.startsWith("BLOCKED"))blockers.push("SOURCE_NORMALIZATION_BLOCKED");
 if(o.evidenceStatus==="MODEL_ESTIMATE")blockers.push("MODEL_OUTPUT_NOT_PRIMARY_MEASUREMENT");
 const hits=item.hitOperations;
 const hitValid=valid&&Number.isSafeInteger(hits)&&hits>=0&&hits<=n;
 return {source:sourceKey(o),studyID:o.studyID,observationID:o.observationID,
 reportedOperations:actual?n:null,denominatorVerified:verified,
 totalUnits:raw?item.totalUnits:null,estimatedUnitsPerOperation:valid?item.totalUnits/n:null,
 occurrenceProbability:hitValid?hits/n:null,
 blockers};
}
function synthesize(obs){
 const map=new Map();const issues=[];const seen=new Set();
 for(const o of obs){
  if(!o||typeof o!=="object")continue;
  if(!o.observationID||seen.has(o.observationID)){issues.push("duplicate or missing observationID: "+o.observationID);continue;}
  seen.add(o.observationID);
  for(const item of o.outputs||[]){
   const k=makeKey(o,item);
   if(!map.has(k.key))map.set(k.key,{context:k.context,missing:k.missing,
    compatibleForPooling:k.complete,records:[]});
   map.get(k.key).records.push(entry(o,item));
  }
 }
 const groups=[];
 for(const g of map.values()){
  const bySource=new Map();
  for(const e of g.records){const key=e.source||e.studyID||e.observationID;
   if(!bySource.has(key))bySource.set(key,[]);bySource.get(key).push(e);}
  const duplicateSources=[...bySource].filter(([,xs])=>xs.length>1).map(([key])=>key);
  const independent=[...bySource.values()].filter(xs=>xs.length===1).map(xs=>xs[0]);
  const usable=independent.filter(e=>e.estimatedUnitsPerOperation!==null&&
   !e.blockers.includes("MODEL_OUTPUT_NOT_PRIMARY_MEASUREMENT"));
  // Do not aggregate incompatible or unverified denominators.
  const poolable=g.compatibleForPooling?usable.filter(e=>e.denominatorVerified):[];
  const N=poolable.reduce((s,x)=>s+x.reportedOperations,0);
  const U=poolable.reduce((s,x)=>s+x.totalUnits,0);
  const means=usable.map(e=>e.estimatedUnitsPerOperation);
  const blockers=[...new Set([
   ...(g.missing.length?["MISSING_CONTEXT:"+g.missing.join(",")]:[]),
   ...(duplicateSources.length?["DUPLICATE_OR_OVERLAPPING_SOURCE"]:[]),
   ...g.records.flatMap(e=>e.blockers)])];
  groups.push({context:g.context,independentSourceCount:bySource.size,
   reportedSourceCount:g.records.length,duplicateSources,eligiblePooledSourceCount:poolable.length,
   pooledActualOperations:N||null,pooledTotalUnits:N?U:null,
   // A source-weighted mean is valid only for comparable, verified cohorts.
   pooledExpectedQuantity:N?U/N:null,
   unpooledReportedMeanRange:means.length?[Math.min(...means),Math.max(...means)]:null,
   occurrenceProbability:null, // never turn mean into hit chance
   currentRetailApproved:false, // master QA, patch bridge and release review still required
   statisticalInterval:null, // no variance proof in aggregate-only sources
   blockers,
   sources:g.records});
 }
 groups.sort((a,b)=>JSON.stringify(a.context).localeCompare(JSON.stringify(b.context)));
 return {schemaVersion:"1.0",researchOnly:true,productionPromotions:0,
  studiesSeen:new Set(obs.map(o=>o.studyID).filter(Boolean)).size,
  observationsSeen:seen.size,groups:groups.length,issues,results:groups};
}
function main(argv){
 const files=argv.length?argv:(fs.existsSync(ROOT)?fs.readdirSync(ROOT).filter(s=>s.endsWith(".jsonl")).map(s=>path.join(ROOT,s)):[]);
 const output=synthesize(files.flatMap(read));
 process.stdout.write(JSON.stringify(output,null,2)+"\n");
}
if(require.main===module)main(process.argv.slice(2));
module.exports={synthesize,entry,makeKey,sourceKey};
