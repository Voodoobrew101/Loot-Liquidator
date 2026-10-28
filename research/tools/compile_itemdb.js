"use strict";
// Research-only deterministic compiler; never writes production addon files.
// Run: node research/tools/compile_itemdb.js [repository root]
const F=["dropChance","yieldMin","yieldMax","expectedQuantity"];
function csv(s){let a=[],r=[],v="",q=false;for(let i=0;i<s.length;i++){let c=s[i];if(c==='"'){if(q&&s[i+1]==='"'){v+='"';i++}else q=!q;}else if(c===","&&!q){r.push(v);v="";}else if((c==="\n"||c==="\r")&&!q){if(c==="\r"&&s[i+1]==="\n")i++;r.push(v);if(r.some(x=>x!==""))a.push(r);r=[];v="";}else v+=c;}if(q)throw Error("Unclosed CSV quote");if(r.length||v){r.push(v);a.push(r);}let h=a.shift()||[];return a.map((r,i)=>{if(r.length!==h.length)throw Error("CSV columns at "+(i+2));return Object.fromEntries(h.map((k,j)=>[k,r[j]]));});}
function num(v){if(v===null||v===undefined||String(v).trim()==="")return null;let x=Number(v);return Number.isFinite(x)?x:null;}
function rank(v){let x=num(v);return x!==null&&Number.isInteger(x)&&x>=1?x:null;}
function score(v){return Math.max(0,Math.min(100,Math.floor(num(v)||0)));}
function field(v,t,s,claim,block){let x=num(v),st=t,b=block||"";if(x!==null&&(x<0||(t==="proxy-p"&&x>1)||(t==="proxy-y"&&(!Number.isInteger(x)||x<1)))){x=null;st="contradictory";b="INVALID_SOURCE_NUMBER";}if(x===0&&t!=="proxy-p"){x=null;st="unknown";b="SOURCE_ZERO_NOT_PROVEN";}if(x===null&&st!=="contradictory")st="unknown";if(st==="proxy-p"||st==="proxy-y")st="proxy";return {value:x,status:st,confidence:x===null?0:score(s),sourceClaimIDs:[claim],sampleOperations:null,blockers:b?[b]:[]};}
function make(r,type,path){let primary=type==="primary",id=Number(primary?r.input_id:r.input_or_profile),out=Number(r.output_id),claim=r.record_key;
 let m=(r.method||"").toLowerCase()==="mill"?"Mill":"Prospect",exp=type==="midnight_low_high"||type==="condition_cohort"?11:type==="dragonflight_low_high"?9:0;
 let iq=primary?rank(r.input_quality):rank((r.context||"").match(/input_rank=(\d+)/)?.[1]),oq=primary?rank(r.output_quality):type==="dragonflight_low_high"?null:null;
 let x={recordID:claim,method:m,expansionID:exp,inputItemID:id,outputItemID:out,recipeSpellID:type==="condition_cohort"?1231127:null,inputCountPerOperation:Number(r.batch_inputs),inputQualityRank:iq,outputQualityRank:oq,
 conditions:{gameMode:"Retail",patchWindow:null,characterContext:"REFERENCE_UNKNOWN",skillLineID:null,effectiveSkill:null,specialization:null,operationStats:null,eligibilityStatus:"UNVERIFIED_CURRENT_RETAIL",baselineStatus:"MINIMUM_RECIPE_ELIGIBLE_UNSKILLED_NOT_ESTABLISHED",expansionIDKnown:exp!==0,sourceContext:primary?r.evidence_type:r.evidence,quantityBasis:primary?r.quantity_unit_basis:"SOURCE_LOW_SCENARIO_NOT_VERIFIED_UNSKILLED"},
 dropChance:field(r.chance,"proxy-p",primary?r.score_probability:r.score_probability,claim),
 yieldMin:field(r.conditional_min,"proxy-y",primary?r.score_conditional_range:r.score_range,claim),
 yieldMax:field(r.conditional_max,"proxy-y",primary?r.score_conditional_range:r.score_range,claim),
 expectedQuantity:field(primary?r.expected_units_per_operation:r.expected_units_per_operation_low,"proxy",primary?r.score_expected_units:r.score_expected,claim),
 mappingConfidence:score(primary?r.score_input_output:r.score_identity),conditionsConfidence:score(primary?r.score_conditions:r.score_context),recordConfidence:0,
 sources:[path,r.source_url||"main/GameData.lua","main/GameData.lua:L"+r.source_line],verifiedDate:r.checked_date||r.verified_date||"2026-10-28",status:"PROVISIONAL_CANDIDATE"};
 if(type==="condition_cohort"){x.inputQualityRank=2;x.expectedQuantity.status=x.expectedQuantity.value===null?"unknown":"community-reported";x.expectedQuantity.sampleOperations=10;x.conditions.quantityBasis="TEN_REPORTED_OPERATIONS_HOTFIX_UNKNOWN";}
 if(x.dropChance.value!==null&&x.yieldMin.value!==null&&x.yieldMax.value!==null&&x.expectedQuantity.value!==null){
  let p=x.dropChance.value,a=x.yieldMin.value,b=x.yieldMax.value,e=x.expectedQuantity.value;
  if(a>b||e+1e-9<p*a||e>p*b+1e-9){x.dropChance.value=null;x.dropChance.status="contradictory";x.dropChance.confidence=0;x.dropChance.blockers.push("P_E_RANGE_CONFLICT_PRESERVE_EXPECTATION");}
 }
 x.recordConfidence=Math.min(x.mappingConfidence,x.conditionsConfidence,...F.map(k=>x[k].confidence));return x;
}
function key(r){return [r.method,r.inputItemID,r.outputItemID].join(":");}
function sourceOK(line,id){return new RegExp("(?:\\bid\\s*=\\s*|\\boutput\\s*=\\s*)"+id+"\\b").test(line||"");}
function validate(rows){let seen=new Set(),bad=[];for(let r of rows){let k=key(r);if(seen.has(k))bad.push("DUPLICATE:"+k);seen.add(k);
 if(!Number.isInteger(r.inputItemID)||r.inputItemID<1||!Number.isInteger(r.outputItemID)||r.outputItemID<1||r.inputItemID===r.outputItemID)bad.push("IDENTITY:"+k);
 if(!Number.isInteger(r.inputCountPerOperation)||r.inputCountPerOperation<1)bad.push("BATCH:"+k);
 if(r.recordConfidence!==Math.min(r.mappingConfidence,r.conditionsConfidence,...F.map(f=>r[f].confidence)))bad.push("CONFIDENCE:"+k);
 for(let f of F){let x=r[f];if(!x||!Array.isArray(x.sourceClaimIDs)||!x.sourceClaimIDs.length||!Number.isInteger(x.confidence)||x.confidence<0||x.confidence>100||!Array.isArray(x.blockers))bad.push("FIELD:"+k+":"+f);}
 let p=r.dropChance.value,e=r.expectedQuantity.value,a=r.yieldMin.value,b=r.yieldMax.value;
 if(p!==null&&(p<0||p>1)||e!==null&&e<0||a!==null&&(!Number.isInteger(a)||a<1)||b!==null&&(!Number.isInteger(b)||b<1)||a!==null&&b!==null&&a>b)bad.push("DOMAIN:"+k);
 if(p!==null&&e!==null&&a!==null&&b!==null&&(e+1e-9<p*a||e>p*b+1e-9))bad.push("P_E_RANGE:"+k);
 }return bad;}
function encode(v){if(v===null||v===undefined)return "false";if(typeof v==="number"){if(!Number.isFinite(v))throw Error("Nonfinite");return String(v);}if(typeof v==="string")return JSON.stringify(v);if(typeof v==="boolean")return v?"true":"false";if(Array.isArray(v))return "{"+v.map(encode).join(",")+"}";throw Error("Unsupported value");}
function compile(i){
 let primary=csv(i.primaryCSV),supp=csv(i.supplementalCSV),lines=i.gameDataSource.split(/\r?\n/),map=new Map(),alternates=[],quarantine=[],checked=0;
 function offer(r){let k=key(r),old=map.get(k);if(!old){map.set(k,r);return;}
 let priority=x=>(x.expectedQuantity.value!==null?100:0)+(x.dropChance.value!==null?12:0)+(x.yieldMin.value!==null&&x.yieldMax.value!==null?6:0)+(x.recordID.startsWith("tsm:")?1:0);
 if(priority(r)>priority(old)){map.set(k,r);alternates.push([k,r.recordID,old.recordID]);}else alternates.push([k,old.recordID,r.recordID]);
 }
 for(let r of primary){if(!sourceOK(lines[Number(r.source_line)-1],r.output_id))throw Error("Primary identity "+r.record_key);checked++;offer(make(r,"primary","research/ledger/processing-output-fields.csv"));}
 for(let r of supp){
  if(!["midnight_low_high","dragonflight_low_high","condition_cohort"].includes(r.dataset)){quarantine.push([r.record_key,r.dataset==="fixed_smelt"?"MULTI_REAGENT_SCHEMA_GAP":r.dataset==="disenchant"?"GENERIC_GEAR_NOT_ITEM":"TOKEN_CHOICE_NOT_RNG"]);continue;}
  if(r.input_or_profile===r.output_id){quarantine.push([r.record_key,"SELF_RETURN_INPUT_SAVING_UNRESOLVED"]);continue;}
  if(!sourceOK(lines[Number(r.source_line)-1],r.output_id))throw Error("Supplement identity "+r.record_key);
  checked++;offer(make(r,r.dataset,"research/ledger/supplemental-output-fields.csv"));
 }
 let mid=JSON.parse(i.midnightCandidateJSON);
 for(let r of mid.processing){
  if(!i.gameDataSource.includes("gd.mill["+r.inputItemID+"]")||!i.statYieldSource.includes(String(r.inputItemID))||!i.statYieldSource.includes(String(r.outputItemID)))throw Error("Overlay identity "+r.recordID);
  r.conditions.eligibilityStatus="UNVERIFIED_CURRENT_RETAIL";r.conditions.baselineStatus="MINIMUM_RECIPE_ELIGIBLE_UNSKILLED_NOT_ESTABLISHED";
  r.sources=[...new Set([...r.sources,"research/proposed/itemdb-midnight-milling-candidate.json"])];
  r.recordConfidence=Math.min(r.mappingConfidence,r.conditionsConfidence,...F.map(f=>r[f].confidence));offer(r);
 }
 let records=[...map.values()].sort((a,b)=>key(a).localeCompare(key(b))),bad=validate(records);if(bad.length)throw Error("Validation "+bad.slice(0,8).join(","));
 let missing=Object.fromEntries(F.map(f=>[f,0])),gaps=[],complete=0,knownE=0,fullHigh=0;
 for(let r of records){let all=true;for(let f of F)if(r[f].value===null){missing[f]++;all=false;gaps.push([r.recordID,r.method,r.inputItemID,r.outputItemID,f,r[f].status,r[f].blockers.join("|")]);}
 if(all)complete++;if(r.expectedQuantity.value!==null)knownE++;if(r.recordConfidence>=90)fullHigh++;
 }
 let manifest={schemaVersion:"0.1.0",artifactStatus:"RESEARCH_ONLY_NOT_SHIPPED",sourceManifest:{gameDataSha:i.sha.gameData,statYieldProfilesSha:i.sha.statYield,mechanicsRegistrySha:i.sha.mechanics,reviewDate:"2026-10-28",compilerVersion:"0.1.0",ledgerSHAs:{primary:i.sha.primary,supplemental:i.sha.supplemental,midnightCandidate:i.sha.midnightCandidate},targetBaseline:"MINIMUM_RECIPE_ELIGIBLE_UNSKILLED_UNVERIFIED"},mechanicRules:[],unmigratedLegacy:quarantine.map(x=>x.join(":"))};
 let statuses=["unknown","proxy","modeled","measured","community-reported","official","contradictory"],methods=["Mill","Prospect","Disenchant","Smelt"];
 let raw=records.map(r=>[r.recordID,methods.indexOf(r.method)+1,r.expansionID,r.inputItemID,r.outputItemID,r.recipeSpellID,r.inputCountPerOperation,r.inputQualityRank,r.outputQualityRank,
 ...F.map(f=>[r[f].value,statuses.indexOf(r[f].status)+1,r[f].confidence,r[f].blockers.join("|")||null,r[f].sampleOperations]),
 r.mappingConfidence,r.conditionsConfidence,r.recordConfidence,r.sources[0],r.sources[1],r.sources[2],r.verifiedDate,r.conditions.sourceContext||null,r.conditions.quantityBasis||null,r.conditions.expansionIDKnown!==false]);
 let pre="-- Research-only provisional candidate. NOT shipped. No skill/patch normalization is asserted.\n-- Generated by research/tools/compile_itemdb.js v0.1.0. Unknown=false in compact source, nil in decoded fields.\n";
 pre+="local raw="+encode(raw)+"\nlocal statuses="+encode(statuses)+"\nlocal methods="+encode(methods)+"\n";
 pre+="local function opt(v) if v==false then return nil end return v end\n";
 pre+="local function field(x,claim) local b={} if x[4]~=false then b[1]=x[4] end return {value=opt(x[1]),status=statuses[x[2]],confidence=x[3],sourceClaimIDs={claim},sampleOperations=opt(x[5]),blockers=b} end\n";
 pre+="local processing={}\nfor i=1,#raw do local x=raw[i]; local r={recordID=x[1],method=methods[x[2]],expansionID=x[3],inputItemID=x[4],outputItemID=x[5],recipeSpellID=opt(x[6]),inputCountPerOperation=x[7],inputQualityRank=opt(x[8]),outputQualityRank=opt(x[9]),dropChance=field(x[10],x[1]),yieldMin=field(x[11],x[1]),yieldMax=field(x[12],x[1]),expectedQuantity=field(x[13],x[1]),mappingConfidence=x[14],conditionsConfidence=x[15],recordConfidence=x[16],sources={x[17],x[18],x[19]},verifiedDate=x[20],status=\"PROVISIONAL_CANDIDATE\",conditions={gameMode=\"Retail\",patchWindow=nil,characterContext=\"REFERENCE_UNKNOWN\",skillLineID=nil,effectiveSkill=nil,specialization=nil,operationStats=nil,eligibilityStatus=\"UNVERIFIED_CURRENT_RETAIL\",baselineStatus=\"MINIMUM_RECIPE_ELIGIBLE_UNSKILLED_NOT_ESTABLISHED\",sourceContext=opt(x[21]),quantityBasis=opt(x[22]),expansionIDKnown=x[23]}};processing[#processing+1]=r end\n";
 const small=v=>{if(v===null||v===undefined)return "nil";if(typeof v==="number")return String(v);if(typeof v==="string")return JSON.stringify(v);if(typeof v==="boolean")return v?"true":"false";if(Array.isArray(v))return "{"+v.map(small).join(",")+"}";return "{"+Object.keys(v).sort().map(k=>"["+JSON.stringify(k)+"]="+small(v[k])).join(",")+"}";};
 let lua=pre+"return {schemaVersion=\"0.1.0\",artifactStatus=\"RESEARCH_ONLY_NOT_SHIPPED\",sourceManifest="+small(manifest.sourceManifest)+",processing=processing,unmigratedLegacy="+small(manifest.unmigratedLegacy)+",mechanicRules={}}\n";
 let report={compilerVersion:"0.1.0",status:"BUILT_RESEARCH_ONLY",sourceSHA:i.sha,primarySourceRows:primary.length,supplementalSourceRows:supp.length,verifiedSourceLineIdentities:checked,sourceMappingCandidates:records.length,uniqueInputIDs:new Set(records.map(r=>r.inputItemID)).size,sourceAlternates:alternates.length,fullyNumericFourFields:complete,expectedQuantityPresent:knownE,fieldSlots:records.length*4,missingFieldCounts:missing,completeRecordConfidenceGE90:fullHigh,quarantined:quarantine.length,quarantineBreakdown:Object.fromEntries([...new Set(quarantine.map(x=>x[1]))].map(k=>[k,quarantine.filter(x=>x[1]===k).length])),independentRetailUniverseAudit:"NOT_COMPLETE",baselineMinimumSkillVerified:0,provisionalRecords:records.length,luaBytes:lua.length,productionWrites:0};
 const esc=v=>'"'+String(v===null?"":v).replace(/"/g,'""')+'"';
 let gapCSV="record_id,method,input_id,output_id,missing_field,status,reason\n"+gaps.map(row=>row.map(esc).join(",")).join("\n")+"\n";
 return {lua,report,gapCSV,records,alternates,quarantine};
}
module.exports={csv,compile,validate};
if(require.main===module){
 const fs=require("fs"),path=require("path"),root=process.argv[2]||".",get=p=>fs.readFileSync(path.join(root,p),"utf8");
 let i={primaryCSV:get("research/ledger/processing-output-fields.csv"),supplementalCSV:get("research/ledger/supplemental-output-fields.csv"),midnightCandidateJSON:get("research/proposed/itemdb-midnight-milling-candidate.json"),gameDataSource:get("GameData.lua"),statYieldSource:get("StatYieldProfiles.lua"),sha:JSON.parse(get("research/proposed/itemdb-compiler-source-shas.json"))};
 let x=compile(i);fs.writeFileSync(path.join(root,"research/proposed/itemdb.lua"),x.lua);fs.writeFileSync(path.join(root,"research/proposed/itemdb-build-report.json"),JSON.stringify(x.report,null,2)+"\n");fs.writeFileSync(path.join(root,"research/ledger/itemdb-missing-fields.csv"),x.gapCSV);fs.writeFileSync(path.join(root,"research/ledger/itemdb-source-alternates.csv"),"method_input_output,selected_source_key,not_selected_source_key\n"+x.alternates.map(r=>r.map(v=>'"'+String(v).replace(/"/g,'""')+'"').join(",")).join("\n")+"\n");console.log(x.report);
}
