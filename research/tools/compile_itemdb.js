"use strict";
// Research-only deterministic compiler; never writes production addon files.
// Run: node research/tools/compile_itemdb.js [repository root]
const F=["dropChance","yieldMin","yieldMax","expectedQuantity"];
const {applyTooltipFallbacks,validateTooltipIsolation}=require("./itemdb_tooltip_channel.js");
const {applyWorkingEstimates,validateWorkingEstimates}=require("./working_estimates.js");
const COMPILER_VERSION="0.8.0",SCHEMA_VERSION="0.2.0",SELECTION_POLICY="context-evidence-first-v1";
function stable(v){if(v===null||typeof v!=="object")return JSON.stringify(v);if(Array.isArray(v))return "["+v.map(stable).join(",")+"]";return "{"+Object.keys(v).sort().map(k=>JSON.stringify(k)+":"+stable(v[k])).join(",")+"}";}
function logicalKey(r){return [r.method,r.inputItemID,r.outputItemID].join(":");}
// Operation identity includes the recipe and nominal batch. A historical mass
// operation must never replace an ordinary cast merely because it has more data.
function key(r){const base=logicalKey(r);return r.recipeSpellID!=null||r.inputCountPerOperation!==5?base+":recipe:"+(r.recipeSpellID??"unknown")+":batch:"+r.inputCountPerOperation:base;}
function sourceProfileKey(r){const c=r.conditions||{};return key(r)+"|"+stable({inputQualityRank:r.inputQualityRank??null,outputQualityRank:r.outputQualityRank??null,gameMode:(c.gameMode||"Retail").toUpperCase(),patchWindow:c.patchWindow??null,skillLineID:c.skillLineID??null,effectiveSkill:c.effectiveSkill??null,specialization:c.specialization??null,operationStats:c.operationStats??null,operationVariant:c.operationVariant??null});}
function contextAssessment(r,target={}){const c=r.conditions||{},mismatches=[],matched=[];const values={recipeSpellID:r.recipeSpellID,inputCountPerOperation:r.inputCountPerOperation,inputQualityRank:r.inputQualityRank,outputQualityRank:r.outputQualityRank,gameMode:c.gameMode,patchWindow:c.patchWindow,skillLineID:c.skillLineID,effectiveSkill:c.effectiveSkill,specialization:c.specialization,operationStats:c.operationStats};for(const [k,v]of Object.entries(values)){if(!Object.hasOwn(target,k)||target[k]===undefined||target[k]===null||v===undefined||v===null)continue;const a=k==="gameMode"?String(v).toUpperCase():stable(v),b=k==="gameMode"?String(target[k]).toUpperCase():stable(target[k]);if(a!==b)mismatches.push(k);else matched.push(k);}return {applicable:mismatches.length===0,mismatches,matched};}
function sourcePriority(r,target={}){const a=contextAssessment(r,target),rank={official:6,measured:5,"community-reported":4,modeled:3,proxy:1,unknown:0,contradictory:0};const known=F.map(f=>r[f]).filter(x=>x.value!==null);return [a.applicable?1:0,a.matched.length,Math.max(0,...known.map(x=>rank[x.status]||0)),r.conditionsConfidence||0,r.mappingConfidence||0,known.length?Math.min(...known.map(x=>x.confidence||0)):0,known.length];}
function compareSourceProfiles(a,b,target={}){const x=sourcePriority(a,target),y=sourcePriority(b,target);for(let n=0;n<x.length;n++)if(x[n]!==y[n])return x[n]-y[n];return a.recordID===b.recordID?0:(a.recordID<b.recordID?1:-1);}
function selectSourceProfile(candidates,target={}){let selected=null;for(const r of candidates){if(!contextAssessment(r,target).applicable)continue;if(!selected||compareSourceProfiles(r,selected,target)>0)selected=r;}return selected;}
function disagreement(a,b){const flags=[];if(sourceProfileKey(a)!==sourceProfileKey(b))flags.push("DISTINCT_SOURCE_CONTEXT");for(const f of F)if(a[f].value!==null&&b[f].value!==null&&Math.abs(a[f].value-b[f].value)>1e-9)flags.push("SOURCE_VALUE_DISAGREEMENT:"+f);return flags;}
function manifestRecord(r){if(!r.tooltipOnly)return r;const t=r.tooltipOnly;return {...r,tooltipOnly:{dropChance:t.dropChance,yieldMin:t.yieldMin,yieldMax:t.yieldMax,confidence:t.confidence,source:{url:t.sourceUrl,sourceType:t.sourceType,extractedOn:t.extractedOn,profileLabel:t.profileLabel,sourceObservedMax:t.sourceObservedMax,rawEventRatio:t.sourceRawRatio,rawCount:t.sourceCount,rawOutOf:t.sourceOutOf,denominatorUnit:t.sourceDenominator,claimID:t.sourceClaimID,positiveYieldUnit:t.sourceUnit},status:t.status,uncertainty:t.uncertainty,economicUse:t.economicUse,displayOnly:t.displayOnly,profileIsMeasured:t.profileIsMeasured,denominatorVerifiedCompletedCasts:t.denominatorVerifiedCompletedCasts}};}
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
function sourceOK(line,id){return new RegExp("(?:\\bid\\s*=\\s*|\\boutput\\s*=\\s*)"+id+"\\b").test(line||"");}
const TWW_PIGMENT_OUTPUT_RANK=new Map([[222618,1],[222619,2],[222620,3],[222612,1],[222613,2],[222614,3],[224800,1],[224801,2],[224802,3],[224803,1],[224804,2],[224805,3]]);
function validate(rows){let seen=new Set(),bad=[];for(let r of rows){let k=key(r);if(r.method==="Mill"&&TWW_PIGMENT_OUTPUT_RANK.has(r.outputItemID)&&r.outputQualityRank!==TWW_PIGMENT_OUTPUT_RANK.get(r.outputItemID))bad.push("OUTPUT_ID_RANK_MISMATCH:"+k);if(seen.has(k))bad.push("DUPLICATE:"+k);seen.add(k);
 if(!Number.isInteger(r.inputItemID)||r.inputItemID<1||!Number.isInteger(r.outputItemID)||r.outputItemID<1||r.inputItemID===r.outputItemID)bad.push("IDENTITY:"+k);
 if(!Number.isInteger(r.inputCountPerOperation)||r.inputCountPerOperation<1)bad.push("BATCH:"+k);
 if(r.method==="Smelt"&&(!Array.isArray(r.reagents)||!r.reagents.length||r.reagents[0].itemID!==r.inputItemID||r.reagents[0].quantity!==r.inputCountPerOperation||r.reagents.some(z=>!Number.isInteger(z.itemID)||z.itemID<1||!Number.isInteger(z.quantity)||z.quantity<1)||!Number.isInteger(r.recipeSpellID)||!Number.isInteger(r.conditions?.minimumRecipeSkill)||!r.conditions?.requiresLearnedRecipe||!r.conditions?.requiresForge||r.conditions?.reagentCostPolicy!=="ALL_REAGENTS_REQUIRED_NOT_SINGLE_INPUT"))bad.push("RECIPE_VECTOR:"+k);
 if(r.conditions?.operationVariant==="MASS_20_HERB"&&(r.method!=="Mill"||!Number.isInteger(r.recipeSpellID)||r.inputCountPerOperation!==20||!Array.isArray(r.reagents)||r.reagents.length!==1||r.reagents[0].itemID!==r.inputItemID||r.reagents[0].quantity!==20||r.conditions.minimumRecipeSkill!==50||!r.conditions.requiresLearnedRecipe||r.conditions.reagentCostPolicy!=="20_HERBS_PER_COMPLETED_MASS_OPERATION"))bad.push("MASS_RECIPE:"+k);
 if(r.method==="Refine"&&(!Number.isInteger(r.recipeSpellID)||r.recipeSpellID<1||r.inputQualityRank!==1||r.outputQualityRank!==2||!r.conditions?.requiresBench||!r.conditions?.requiresLearnedRecipe||!Number.isInteger(r.conditions?.minimumRecipeSkill)||!Array.isArray(r.reagents)||r.reagents.length!==1||r.reagents[0].itemID!==r.inputItemID||r.reagents[0].quantity!==r.inputCountPerOperation))bad.push("REFINE_RECIPE:"+k);
  if(r.recordConfidence!==Math.min(r.mappingConfidence,r.conditionsConfidence,...F.map(f=>r[f].confidence)))bad.push("CONFIDENCE:"+k);
 if((r.conditions?.quantityBasis||"").includes("NOT_ACTUAL_CAST")&&r.expectedQuantity.value!==null)bad.push("GROSS_INPUT_PROXY_NOT_CAST_E:"+k);
 for(let f of F){let x=r[f];if(!x||!Array.isArray(x.sourceClaimIDs)||!x.sourceClaimIDs.length||!Number.isInteger(x.confidence)||x.confidence<0||x.confidence>100||!Array.isArray(x.blockers))bad.push("FIELD:"+k+":"+f);}
 let p=r.dropChance.value,e=r.expectedQuantity.value,a=r.yieldMin.value,b=r.yieldMax.value;
 if(p!==null&&(p<0||p>1)||e!==null&&e<0||a!==null&&(!Number.isInteger(a)||a<1)||b!==null&&(!Number.isInteger(b)||b<1)||a!==null&&b!==null&&a>b)bad.push("DOMAIN:"+k);
 if(p!==null&&e!==null&&p>e+1e-9)bad.push("P_GT_E:"+k);
 if(p!==null&&e!==null&&a!==null&&b!==null&&(e+1e-9<p*a||e>p*b+1e-9))bad.push("P_E_RANGE:"+k);
 }return bad;}
function encode(v){if(v===null||v===undefined)return "false";if(typeof v==="number"){if(!Number.isFinite(v))throw Error("Nonfinite");return String(v);}if(typeof v==="string")return JSON.stringify(v);if(typeof v==="boolean")return v?"true":"false";if(Array.isArray(v))return "{"+v.map(encode).join(",")+"}";if(typeof v==="object")return "{"+Object.keys(v).sort().map(k=>"["+JSON.stringify(k)+"]="+encode(v[k])).join(",")+"}";throw Error("Unsupported value");}
function compile(i){
 let primary=csv(i.primaryCSV),supp=csv(i.supplementalCSV),lines=i.gameDataSource.split(/\r?\n/),map=new Map(),profiles=new Map(),alternates=[],quarantine=[],checked=0;
 const target=i.targetContext||{};
 function offer(r){let k=key(r),old=map.get(k),assessment=contextAssessment(r,target);if(!profiles.has(k))profiles.set(k,[]);profiles.get(k).push(structuredClone(r));if(!assessment.applicable){quarantine.push([r.recordID,"TARGET_CONTEXT_MISMATCH:"+assessment.mismatches.join("|")]);return;}if(!old){map.set(k,r);return;}
 if(compareSourceProfiles(r,old,target)>0){map.set(k,r);alternates.push([k,r.recordID,old.recordID]);}else alternates.push([k,old.recordID,r.recordID]);
 }
 function findCandidate(a){let candidates=[...map.values()].filter(r=>r.method===a.method&&r.inputItemID===a.inputItemID&&r.outputItemID===a.outputItemID);if(a.recipeSpellID!=null&&candidates.some(r=>r.recipeSpellID===a.recipeSpellID))candidates=candidates.filter(r=>r.recipeSpellID===a.recipeSpellID);else if(candidates.some(r=>r.recipeSpellID===null))candidates=candidates.filter(r=>r.recipeSpellID===null);if(a.inputCountPerOperation!=null)candidates=candidates.filter(r=>r.inputCountPerOperation===a.inputCountPerOperation);else if(candidates.some(r=>r.inputCountPerOperation===5))candidates=candidates.filter(r=>r.inputCountPerOperation===5);if(candidates.length!==1)throw Error("Audited operation ambiguity "+logicalKey(a)+" candidates="+candidates.length);return candidates[0];}
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
 const curated=JSON.parse(i.curatedJSON||'{"processing":[]}');let curatedAdded=0;
 for(const r of curated.processing||[]){if(map.has(key(r)))throw Error("Curated duplicate "+key(r));offer(r);curatedAdded++;}
 let rankQuarantined=0;
 for(const a of (i.rankAuditJSONL||"").trim().split(String.fromCharCode(10)).filter(Boolean).map(JSON.parse)){
  if(a.decisionRisk!=="RANK_ALTERNATIVES_MUST_NOT_BE_VALUED_SIMULTANEOUSLY")continue;
  const k=["Mill",a.inputItemID,a.outputItemID].join(":"),r=findCandidate({method:"Mill",inputItemID:a.inputItemID,outputItemID:a.outputItemID});
  if(!r)throw Error("Missing rank mapping "+k);
  if(r.inputQualityRank!==a.inputQualityRank||r.outputQualityRank!==a.outputQualityRank)throw Error("Rank identity conflict "+k);
  for(const fieldName of ["dropChance","expectedQuantity"]){
   const x=r[fieldName];x.value=null;x.status="unknown";x.confidence=0;x.blockers=[...new Set([...x.blockers,"RANK_SPECIFIC_TSM_FAMILY_RATE_NOT_MEASURED"])];
   x.sourceClaimIDs=[...new Set([...x.sourceClaimIDs,"batch012-DF-rank-audit:"+a.stableKey])];
  }
  r.conditions.sourceContext="DRAGONFLIGHT_RANK_EXCLUSIVE_TSM_FAMILY_PROXY_QUARANTINED";
  r.recordConfidence=Math.min(r.mappingConfidence,r.conditionsConfidence,...F.map(f=>r[f].confidence));rankQuarantined++;
 }
 if(rankQuarantined!==31)throw Error("Expected 31 rank records, got "+rankQuarantined);
 let diamondGated=0;
 for(const a of (i.midnightAuditCSV||"").trim().split(String.fromCharCode(10)).slice(1)){
  const c=a.replace(/^"/,"").split('","');if(!a.includes("SPECIALIZATION_GATED_NO_UNSKILLED_OUTPUT"))continue;
  const input=Number(c[1].replaceAll('"',"")),output=Number(c[2].replaceAll('"',""));
  const r=findCandidate({method:"Prospect",inputItemID:input,outputItemID:output});if(!r)throw Error("Missing gated diamond "+input+":"+output);
  r.conditions.eligibilityStatus="REQUIRES_ORE_SPECIFIC_PROFICIENT_PROCESSOR_SPECIALIZATION";
  r.conditions.baselineStatus="NO_UNSKILLED_DIAMOND_BASELINE__NOT_MEASURED_ZERO";
  r.conditions.sourceContext="MIDNIGHT_DIAMOND_SPECIALIZATION_GATE_BATCH012";
  r.conditionsConfidence=Math.min(r.conditionsConfidence,35);
  r.recordConfidence=Math.min(r.mappingConfidence,r.conditionsConfidence,...F.map(f=>r[f].confidence));diamondGated++;
 }
 if(diamondGated!==7)throw Error("Expected 7 diamond gates got "+diamondGated);
 let batch013RankQuarantined=0,fishInputRankCorrected=0,invalidSourceChanceQuarantined=0;
 const df13=(i.batch013DragonflightJSONL||"").trim().split("\n").filter(Boolean).map(JSON.parse);
 const tww13=(i.batch013TWWJSONL||"").trim().split("\n").filter(Boolean).map(JSON.parse);
 const legacy13=(i.batch013LegacyJSONL||"").trim().split("\n").filter(Boolean).map(JSON.parse);
 function auditRecord(a){
  const r=findCandidate(a);
  if(!r)throw Error("Batch013 missing candidate "+a.stableKey);
  if(a.sourceLine && !sourceOK(lines[a.sourceLine-1],a.outputItemID))throw Error("Batch013 GameData identity "+a.stableKey);
  return r;
 }
 for(const a of df13){
  const r=auditRecord(a);
  if(a.inputItemID===200061&&a.sourceQualityCorrection==="REMOVE_FICTITIOUS_INPUT_RANK_1_FISH"){
   if(r.inputQualityRank!==1)throw Error("Fish input rank mismatch "+a.stableKey);
   r.inputQualityRank=null;fishInputRankCorrected++;
  }
 }
 for(const a of [...df13,...tww13]){
  const isRank=a.decisionRisk==="RANK_ALTERNATIVES_NOT_INDEPENDENT_TSM_MEASUREMENTS" ||
   (a.method==="Prospect"&&[188658,189143].includes(a.inputItemID)&&a.outputQualityRank!=null&&a.fields?.dropChance?.value===null&&a.fields?.expectedQuantity?.value===null);
  if(!isRank)continue;
  const r=auditRecord(a);
  if(a.outputQualityRank!=null&&r.outputQualityRank!==null&&r.outputQualityRank!==a.outputQualityRank)throw Error("Batch013 output rank mismatch "+a.stableKey);
  if(r.outputQualityRank===null&&a.outputQualityRank!=null)r.conditions.sourceContext="RANK_IDENTITY_UNRESOLVED_SOURCE_ALTERNATE";
  for(const f of ["dropChance","expectedQuantity"]){
   r[f].value=null;r[f].status="unknown";r[f].confidence=0;
   r[f].blockers=[...new Set([...r[f].blockers,"RANK_SPECIFIC_TSM_FAMILY_RATE_NOT_MEASURED"])];
   r[f].sourceClaimIDs=[...new Set([...r[f].sourceClaimIDs,"batch013-rank-audit:"+a.stableKey])];
  }
  if(r.outputQualityRank!==null)r.conditions.sourceContext="BATCH013_RANK_EXCLUSIVE_HISTORICAL_PROXY_QUARANTINED";
  r.recordConfidence=Math.min(r.mappingConfidence,r.conditionsConfidence,...F.map(f=>r[f].confidence));
  batch013RankQuarantined++;
 }
 if(batch013RankQuarantined!==50||fishInputRankCorrected!==12||legacy13.filter(a=>a.arithmeticConflict).length!==8)
  throw Error("Batch013 audit count mismatch "+batch013RankQuarantined+"/"+fishInputRankCorrected);

 const df14=(i.batch014DragonflightJSONL||"").trim().split("\n").filter(Boolean).map(JSON.parse);
 const unsafe=new Set(["192880:192849","192880:192866","189143:192869","190311:192869","188658:192870","188658:192871","189143:192870"]);
 let batch014ExpectedQuarantined=0,batch014SourceProbabilityQuarantined=0;
 for(const a of df14){
  if(!unsafe.has(a.inputItemID+":"+a.outputItemID))continue;
  const r=findCandidate(a);
  if(!r||r.expectedQuantity.value===null)throw Error("Batch014 missing retained unsafe E "+a.stableKey);
  if(a.sourceLine&&!sourceOK(lines[a.sourceLine-1],a.outputItemID))throw Error("Batch014 source identity "+a.stableKey);
  const x=r.expectedQuantity;
  if(r.dropChance.value!==null&&r.dropChance.value>x.value+1e-9){
   r.dropChance.value=null;r.dropChance.status="contradictory";r.dropChance.confidence=0;
   r.dropChance.blockers=[...new Set([...r.dropChance.blockers,"SOURCE_P_GT_HISTORICAL_E_PRESERVED"])];batch014SourceProbabilityQuarantined++;
  }
  x.value=null;x.status="unknown";x.confidence=0;
  x.blockers=[...new Set([...x.blockers,"BATCH014_RANK_OR_GROSS_INPUT_EQUIVALENT_NOT_EXACT_CAST_E"])];
  x.sourceClaimIDs=[...new Set([...x.sourceClaimIDs,"batch014-DF:"+a.stableKey])];
  r.conditions.sourceContext="BATCH014_RANK_OR_GROSS_INPUT_E_QUARANTINED";
  r.recordConfidence=Math.min(r.mappingConfidence,r.conditionsConfidence,...F.map(f=>r[f].confidence));
  batch014ExpectedQuarantined++;
 }
 if(batch014ExpectedQuarantined!==7)throw Error("Batch014 unsafe count mismatch "+batch014ExpectedQuarantined);
 const tww14=(i.batch014TWWJSONL||"").trim().split("\n").filter(Boolean).map(JSON.parse).filter(x=>x.method==="Smelt");
 if(tww14.length!==8)throw Error("Expected eight smelt vectors");
 let fixedSmeltRecipeVectorsCompiled=0;
 for(const a of tww14){
  const s=supp.find(x=>x.dataset==="fixed_smelt"&&Number(x.input_or_profile)===a.recipeSpellID&&Number(x.output_id)===a.outputItemID);
  if(!s)throw Error("Missing fixed smelt source "+a.recipeSpellID);
  const line=lines[Number(s.source_line)-1]||"";
  const m=line.match(/^gd\.smelt\[(\d+)\]=\{spell=(\d+),output=(\d+),outputCount=([\d.]+),source="([^"]+)",inputs=\{(.+)\}\}$/);
  if(!m||Number(m[1])!==a.recipeSpellID||Number(m[2])!==a.recipeSpellID||Number(m[3])!==a.outputItemID)throw Error("Smelt source identity "+a.recipeSpellID);
  const reagents=[...line.matchAll(/\{id=(\d+),amount=(\d+)\}/g)].map(z=>({itemID:Number(z[1]),quantity:Number(z[2])}));
  if(!reagents.length||JSON.stringify(reagents)!==JSON.stringify(a.reagentVector)||Number(m[4])!==a.fields.expectedQuantity.value||Number(s.expected_units_per_operation_low)!==Number(m[4]))throw Error("Smelt reagent/output conflict "+a.recipeSpellID);
  if(!Number.isInteger(a.minimumRecipeSkill)||a.minimumRecipeSkill<1||a.requiresForge!==true||a.requiresLearnedRecipe!==true)throw Error("Missing smelt eligibility "+a.recipeSpellID);
  const fields=Object.fromEntries(F.map(k=>[k,{value:a.fields[k].value,status:"modeled",confidence:Math.min(80,a.fields[k].confidence),sourceClaimIDs:[s.record_key,a.stableKey],sampleOperations:null,blockers:["RECIPE_DESCRIPTION_FIXED_OUTPUT_NOT_EMPIRICAL_CAST","REQUIRES_LEARNED_RECIPE_AND_FORGE","CURRENT_RETAIL_CLIENT_NOT_VERIFIED"]}]));
  const expansion={"Classic Mining":0,"Outland Mining":1,"Northrend Mining":2,"Cataclysm Mining":3,"Pandaria Mining":4}[a.requiredProfession];
  if(expansion===undefined)throw Error("Unmapped smelt profession "+a.requiredProfession);
  const r={recordID:s.record_key,method:"Smelt",expansionID:expansion,inputItemID:reagents[0].itemID,outputItemID:a.outputItemID,recipeSpellID:a.recipeSpellID,inputCountPerOperation:reagents[0].quantity,inputQualityRank:null,outputQualityRank:null,reagents,
   conditions:{gameMode:"Retail",patchWindow:null,characterContext:"REFERENCE_UNKNOWN",skillLineID:null,effectiveSkill:null,specialization:null,operationStats:null,sourceContext:"FIXED_RECIPE_DIRECT_REAGENTS_NOT_CURRENT_CLIENT_VERIFIED",quantityBasis:"ONE_COMPLETED_LEARNED_SUCCESSFUL_RECIPE",eligibilityStatus:"REQUIRES_LEARNED_RECIPE_FORGE_AND_EXPANSION_MINING_SKILL",baselineStatus:"CONDITIONAL_FIXED_OUTPUT_NOT_VERIFIED_UNSKILLED",requiredProfession:a.requiredProfession,minimumRecipeSkill:a.minimumRecipeSkill,requiresForge:true,requiresLearnedRecipe:true,recipeAcquisition:a.acquisition,rareRecipeItemID:a.recipeSpellID===46353?35273:null,reagentCostPolicy:"ALL_REAGENTS_REQUIRED_NOT_SINGLE_INPUT",expansionIDKnown:true},
   ...fields,mappingConfidence:65,conditionsConfidence:55,recordConfidence:55,sources:["research/ledger/supplemental-output-fields.csv",s.source_url,"main/GameData.lua:L"+s.source_line],verifiedDate:"2026-10-28",status:"PROVISIONAL_CANDIDATE"};
  if(map.has(key(r)))throw Error("Duplicate smelt "+key(r));
  offer(r);fixedSmeltRecipeVectorsCompiled++;checked++;
 }
 quarantine=quarantine.filter(x=>x[1]!=="MULTI_REAGENT_SCHEMA_GAP");
 for(const r of map.values()){
  if(r.dropChance.value!==null&&r.expectedQuantity.value!==null&&r.dropChance.value>r.expectedQuantity.value+1e-9){
   r.dropChance.value=null;r.dropChance.status="contradictory";r.dropChance.confidence=0;
   r.dropChance.blockers=[...new Set([...r.dropChance.blockers,"SOURCE_P_GT_UNCONDITIONAL_E"])];
   r.recordConfidence=Math.min(r.mappingConfidence,r.conditionsConfidence,...F.map(f=>r[f].confidence));
   invalidSourceChanceQuarantined++;
  }
 }
 let records=[...map.values()].sort((a,b)=>key(a)<key(b)?-1:key(a)>key(b)?1:0);
 for(const r of records){const others=(profiles.get(key(r))||[]).filter(x=>x.recordID!==r.recordID);r.sourceSelection={policyVersion:SELECTION_POLICY,sourceProfileKey:sourceProfileKey(r),selectedRecordID:r.recordID,selectionReason:"APPLICABLE_CONTEXT_THEN_EVIDENCE_STRENGTH_THEN_COMPLETENESS",targetContextSupplied:Object.keys(target).length>0,normalizedVerified:false,conflictFlags:[...new Set(others.flatMap(x=>disagreement(r,x)))].sort(),alternateProfiles:others.map(x=>({recordID:x.recordID,sourceProfileKey:sourceProfileKey(x),selectionReason:contextAssessment(x,target).applicable?"LOWER_CONTEXT_EVIDENCE_PRIORITY":"KNOWN_CONTEXT_MISMATCH"})).sort((a,b)=>a.recordID<b.recordID?-1:a.recordID>b.recordID?1:0)};}
 const tooltipReport=applyTooltipFallbacks(records,i.tooltipFallbacksJSON);
 const evidenceBefore=records.map(r=>JSON.stringify(F.map(f=>r[f])));
 const workingReport=applyWorkingEstimates(records);
 if(records.some((r,n)=>JSON.stringify(F.map(f=>r[f]))!==evidenceBefore[n]))throw Error("Working estimate mutated evidence");
 let bad=[...validate(records),...validateTooltipIsolation(records),...validateWorkingEstimates(records)];if(bad.length)throw Error("Validation "+bad.slice(0,8).join(","));
 let missing=Object.fromEntries(F.map(f=>[f,0])),gaps=[],complete=0,knownE=0,fullHigh=0;
 for(let r of records){let all=true;for(let f of F)if(r[f].value===null){missing[f]++;all=false;gaps.push([r.recordID,r.method,r.inputItemID,r.outputItemID,f,r[f].status,r[f].blockers.join("|")]);}
 if(all)complete++;if(r.expectedQuantity.value!==null)knownE++;if(r.recordConfidence>=90)fullHigh++;
 }
 let manifest={schemaVersion:SCHEMA_VERSION,artifactStatus:"RESEARCH_ONLY_NOT_SHIPPED",sourceManifest:{gameDataSha:i.sha.gameData,statYieldProfilesSha:i.sha.statYield,mechanicsRegistrySha:i.sha.mechanics,reviewDate:"2026-10-28",compilerVersion:COMPILER_VERSION,sourceSelectionPolicy:SELECTION_POLICY,ledgerSHAs:{primary:i.sha.primary,supplemental:i.sha.supplemental,midnightCandidate:i.sha.midnightCandidate,curatedAdditions:i.sha.curatedAdditions,rankAudit:i.sha.rankAudit,midnightAudit:i.sha.midnightAudit},targetBaseline:"HYPOTHETICAL_MINIMUM_ELIGIBLE_NO_OPTIONAL_BONUSES_NOT_VERIFIED"},mechanicRules:[],unmigratedLegacy:quarantine.map(x=>x.join(":"))};
 let statuses=["unknown","proxy","modeled","measured","community-reported","official","contradictory"],methods=["Mill","Prospect","Disenchant","Smelt","Refine"];
 let raw=records.map(r=>[r.recordID,methods.indexOf(r.method)+1,r.expansionID,r.inputItemID,r.outputItemID,r.recipeSpellID,r.inputCountPerOperation,r.inputQualityRank,r.outputQualityRank,
 ...F.map(f=>[r[f].value,statuses.indexOf(r[f].status)+1,r[f].confidence,r[f].blockers.join("|")||null,r[f].sampleOperations,r[f].sourceClaimIDs,r[f].uncertainty||null]),
 r.mappingConfidence,r.conditionsConfidence,r.recordConfidence,r.sources[0],r.sources[1],r.sources[2],r.verifiedDate,r.conditions.sourceContext||null,r.conditions.quantityBasis||null,r.conditions.expansionIDKnown!==false,r.conditions.patchWindow||null,r.conditions.eligibilityStatus||"UNVERIFIED_CURRENT_RETAIL",r.conditions.baselineStatus||"MINIMUM_RECIPE_ELIGIBLE_UNSKILLED_NOT_ESTABLISHED",r.reagents?r.reagents.map(z=>[z.itemID,z.quantity]):null,r.conditions.requiredProfession||null,r.conditions.minimumRecipeSkill||null,r.conditions.requiresForge??null,r.conditions.requiresLearnedRecipe??null,r.conditions.recipeAcquisition||null,r.conditions.rareRecipeItemID||null,r.conditions.reagentCostPolicy||null,r.conditions.requiresBench??null,r.conditions.specialization?.gem||null,r.conditions.operationVariant||null,r.tooltipOnly?[r.tooltipOnly.dropChance,r.tooltipOnly.yieldMin,r.tooltipOnly.yieldMax,r.tooltipOnly.confidence,r.tooltipOnly.sourceUrl,r.tooltipOnly.sourceType,r.tooltipOnly.extractedOn,r.tooltipOnly.profileLabel,r.tooltipOnly.sourceObservedMax,r.tooltipOnly.sourceRawRatio,r.tooltipOnly.sourceCount,r.tooltipOnly.sourceOutOf,r.tooltipOnly.sourceDenominator,r.tooltipOnly.status,r.tooltipOnly.uncertainty,r.tooltipOnly.sourceClaimID,r.tooltipOnly.sourceUnit]:null]);
 let pre="-- Research-only provisional candidate. NOT shipped. No skill/patch normalization is asserted.\n-- Generated by research/tools/compile_itemdb.js v"+COMPILER_VERSION+". Unknown=false in compact source, nil in decoded evidence fields.\n-- workingEstimate is a separate PREVIEW_ONLY assumption layer; never empirical evidence.\n";
 pre+="local raw="+encode(raw)+"\nlocal statuses="+encode(statuses)+"\nlocal methods="+encode(methods)+"\n";
 pre+="local function opt(v) if v==false then return nil end return v end\n";
 pre+="local function field(x,claim) local b={} if x[4]~=false then b[1]=x[4] end return {value=opt(x[1]),status=statuses[x[2]],confidence=x[3],sourceClaimIDs=opt(x[6]) or {claim},sampleOperations=opt(x[5]),uncertainty=opt(x[7]),blockers=b} end\n";
 pre+="local function recipeReagents(v) if v==false then return nil end local t={} for i=1,#v do local a=v[i];t[i]={itemID=a[1],quantity=a[2]} end return t end\n";
 pre+="local function tooltip(v) if v==false then return nil end return {dropChance=opt(v[1]),yieldMin=opt(v[2]),yieldMax=opt(v[3]),confidence=v[4],source={url=v[5],sourceType=v[6],extractedOn=v[7],profileLabel=v[8],sourceObservedMax=v[9],rawEventRatio=v[10],rawCount=v[11],rawOutOf=v[12],denominatorUnit=v[13],claimID=v[16],positiveYieldUnit=v[17]},status=v[14],uncertainty=v[15],economicUse=\"PROHIBITED\",displayOnly=true,profileIsMeasured=false,denominatorVerifiedCompletedCasts=false} end\n";
 pre+="local processing={}\nfor i=1,#raw do local x=raw[i]; local r={recordID=x[1],method=methods[x[2]],expansionID=x[3],inputItemID=x[4],outputItemID=x[5],recipeSpellID=opt(x[6]),inputCountPerOperation=x[7],inputQualityRank=opt(x[8]),outputQualityRank=opt(x[9]),reagents=recipeReagents(x[27]),tooltipOnly=tooltip(x[38]),dropChance=field(x[10],x[1]),yieldMin=field(x[11],x[1]),yieldMax=field(x[12],x[1]),expectedQuantity=field(x[13],x[1]),mappingConfidence=x[14],conditionsConfidence=x[15],recordConfidence=x[16],sources={x[17],x[18],x[19]},verifiedDate=x[20],status=\"PROVISIONAL_CANDIDATE\",conditions={gameMode=\"Retail\",patchWindow=opt(x[24]),characterContext=\"REFERENCE_UNKNOWN\",skillLineID=nil,effectiveSkill=nil,specialization=opt(x[36]) and {tree='Shaping/Gem Finding',gem=x[36],requiredPoints=nil} or nil,operationStats=nil,eligibilityStatus=opt(x[25]),baselineStatus=opt(x[26]),requiredProfession=opt(x[28]),minimumRecipeSkill=opt(x[29]),requiresForge=opt(x[30]),requiresBench=opt(x[35]),requiresLearnedRecipe=opt(x[31]),recipeAcquisition=opt(x[32]),rareRecipeItemID=opt(x[33]),reagentCostPolicy=opt(x[34]),sourceContext=opt(x[21]),operationVariant=opt(x[37]),quantityBasis=opt(x[22]),expansionIDKnown=x[23]}};processing[#processing+1]=r end\n";
 const small=v=>{if(v===null||v===undefined)return "nil";if(typeof v==="number")return String(v);if(typeof v==="string")return JSON.stringify(v);if(typeof v==="boolean")return v?"true":"false";if(Array.isArray(v))return "{"+v.map(small).join(",")+"}";return "{"+Object.keys(v).sort().map(k=>"["+JSON.stringify(k)+"]="+small(v[k])).join(",")+"}";};
 pre+="local working="+encode(records.map(r=>r.workingEstimate))+"\nlocal selections="+encode(records.map(r=>r.sourceSelection))+"\nlocal contexts="+small(records.map(r=>r.conditions))+"\nfor i=1,#processing do processing[i].workingEstimate=working[i];processing[i].sourceSelection=selections[i];processing[i].conditions=contexts[i] end\n";
 let lua=pre+"return {schemaVersion="+JSON.stringify(SCHEMA_VERSION)+",artifactStatus=\"RESEARCH_ONLY_NOT_SHIPPED\",sourceManifest="+small(manifest.sourceManifest)+",processing=processing,unmigratedLegacy="+small(manifest.unmigratedLegacy)+",mechanicRules={}}\n";
 let report={compilerVersion:COMPILER_VERSION,schemaVersion:SCHEMA_VERSION,status:"BUILT_RESEARCH_ONLY",sourceSelectionPolicy:SELECTION_POLICY,sourceSHA:i.sha,primarySourceRows:primary.length,supplementalSourceRows:supp.length,verifiedSourceLineIdentities:checked,sourceMappingCandidates:records.length,uniqueInputIDs:new Set(records.map(r=>r.inputItemID)).size,sourceAlternates:alternates.length,sourceContextConflictRecords:records.filter(r=>r.sourceSelection.conflictFlags.length).length,fullyNumericFourFields:complete,expectedQuantityPresent:knownE,fieldSlots:records.length*4,missingFieldCounts:missing,workingEstimates:workingReport,completeRecordConfidenceGE90:fullHigh,quarantined:quarantine.length,curatedAdded,rankSpecificProxyRecordsQuarantined:rankQuarantined,batch013RankQuarantined,fishInputRankCorrected,invalidSourceChanceQuarantined,legacyArithmeticContradictionsReviewed:8,batch014UnsafeExpectedQuantityQuarantined:batch014ExpectedQuarantined,batch014SourceProbabilityQuarantined,fixedSmeltRecipeVectorsCompiled,diamondSpecializationGated:diamondGated,quarantineBreakdown:Object.fromEntries([...new Set(quarantine.map(x=>x[1]))].map(k=>[k,quarantine.filter(x=>x[1]===k).length])),independentRetailUniverseAudit:"NOT_COMPLETE",baselineMinimumSkillVerified:0,provisionalRecords:records.length,luaBytes:lua.length,tooltipFallbacks:tooltipReport,productionWrites:0};
 const esc=v=>'"'+String(v===null?"":v).replace(/"/g,'""')+'"';
 let gapCSV="record_id,method,input_id,output_id,missing_field,status,reason\n"+gaps.map(row=>row.map(esc).join(",")).join("\n")+"\n";
 return {lua,report,gapCSV,records,alternates,quarantine,manifest:{...manifest,processing:records.map(manifestRecord)}};
}
function loadInputs(root="."){
 const fs=require("fs"),path=require("path"),get=p=>fs.readFileSync(path.join(root,p),"utf8");
 let i={curatedJSON:get("research/proposed/itemdb-curated-additions.json"),rankAuditJSONL:get("research/coordination/submissions/loot-liquidator-dragonflight/2026-10-28-1231-dragonflight-batch012-40key-field-audit.jsonl"),midnightAuditCSV:get("research/coordination/submissions/loot-liquidator-midnight/2026-10-28-1211-midnight-batch012-35key-field-audit.csv"),batch013DragonflightJSONL:get("research/coordination/submissions/loot-liquidator-dragonflight/2026-10-28-1328-dragonflight-batch013-40key-field-audit.jsonl"),batch013TWWJSONL:get("research/coordination/submissions/loot-liquidator-war-within/2026-10-28-1321-warwithin-batch013-35key-field-audit.jsonl"),batch013LegacyJSONL:get("research/coordination/submissions/loot-liquidator-legacy/2026-10-28-1340-legacy-batch013-40key-field-audit.jsonl"),batch014DragonflightJSONL:get("research/coordination/submissions/loot-liquidator-dragonflight/2026-10-28-1432-dragonflight-q16-batch014-40key-fourfield-audit.jsonl"),batch014TWWJSONL:get("research/coordination/submissions/loot-liquidator-war-within/2026-10-28-2116-warwithin-batch014-q16-35key-fourfield-audit.jsonl"),primaryCSV:get("research/ledger/processing-output-fields.csv"),supplementalCSV:get("research/ledger/supplemental-output-fields.csv"),midnightCandidateJSON:get("research/proposed/itemdb-midnight-milling-candidate.json"),gameDataSource:get("GameData.lua"),statYieldSource:get("StatYieldProfiles.lua"),tooltipFallbacksJSON:get("research/proposed/itemdb-tooltip-fallbacks-q25.json"),sha:JSON.parse(get("research/proposed/itemdb-compiler-source-shas.json"))};
 return i;
}
module.exports={csv,compile,validate,loadInputs,key,sourceProfileKey,contextAssessment,compareSourceProfiles,selectSourceProfile};
if(require.main===module){
 const fs=require("fs"),path=require("path"),root=process.argv[2]||".";
 let x=compile(loadInputs(root));fs.writeFileSync(path.join(root,"research/proposed/itemdb.lua"),x.lua);fs.writeFileSync(path.join(root,"research/proposed/itemdb-build-report.json"),JSON.stringify(x.report,null,2)+"\n");fs.writeFileSync(path.join(root,"research/ledger/itemdb-missing-fields.csv"),x.gapCSV);fs.writeFileSync(path.join(root,"research/ledger/itemdb-source-alternates.csv"),"method_input_output,selected_source_key,not_selected_source_key\n"+x.alternates.map(r=>r.map(v=>'"'+String(v).replace(/"/g,'""')+'"').join(",")).join("\n")+"\n");console.log(x.report);
}

