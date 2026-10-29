"use strict";
// Research-only tooltip data. No tooltip fallback is an economic input.
const {validate:validateStaging}=require("./validate_tooltip_fallbacks.js");
const ECON=["dropChance","yieldMin","yieldMax","expectedQuantity"];
function applyTooltipFallbacks(records,raw){
 const report={reviewed:0,activeRecords:0,appliedYieldFields:0,blockedProbabilityUnverifiedCasts:0,existingYieldFieldsProtected:0,economicFieldsUnchanged:true};
 if(!raw)return report;
 const doc=JSON.parse(raw),issues=validateStaging(doc);
 if(issues.length)throw Error("Tooltip staging rejected: "+issues.join("|"));
 const before=records.map(r=>ECON.map(k=>JSON.stringify(r[k])).join("|"));
 for(const z of doc.tooltipFallbacks){
  report.reviewed++;
  const found=records.filter(r=>r.method===z.method&&r.inputItemID===z.inputItemID&&r.outputItemID===z.outputItemID&&(z.recipeSpellID==null||r.recipeSpellID===z.recipeSpellID));
  if(found.length!==1)throw Error("Tooltip exact mapping ambiguity "+z.stableKey+" matches="+found.length);
  const r=found[0],d=z.displayFields,p=d.dropChance;
  if(!p.denominatorVerifiedCompletedCasts||p.notMeasuredP)report.blockedProbabilityUnverifiedCasts++;
  else throw Error("Verified cast P requires separately audited zero-inclusive cast evidence "+z.stableKey);
  const mn=r.yieldMin.value===null?d.yieldMin.value:null;
  const mx=r.yieldMax.value===null?d.yieldMax.value:null;
  report.existingYieldFieldsProtected+=(r.yieldMin.value!==null?1:0)+(r.yieldMax.value!==null?1:0);
  if(mn===null&&mx===null)continue;
  if(mn!==null&&r.yieldMax.value!==null&&mn>r.yieldMax.value)throw Error("Tooltip min conflicts existing bound "+z.stableKey);
  if(mx!==null&&r.yieldMin.value!==null&&mx<r.yieldMin.value)throw Error("Tooltip max conflicts existing bound "+z.stableKey);
  r.tooltipOnly={dropChance:null,yieldMin:mn,yieldMax:mx,confidence:z.fieldConfidence,sourceUrl:z.source.url,sourceType:z.source.sourceType,extractedOn:z.source.extractedOn,profileLabel:z.profileLabel,sourceObservedMax:d.yieldMax.sourceObservedMax,sourceRawRatio:p.rawRatio,sourceCount:p.rawCount,sourceOutOf:p.rawOutOf,sourceDenominator:z.source.denominatorUnit,status:"PROVISIONAL_TOOLTIP_ONLY_NOT_ECONOMIC",uncertainty:d.yieldMax.value<d.yieldMax.sourceObservedMax?"Conservative display upper bound; observed rare tail up to "+d.yieldMax.sourceObservedMax:"Crowdsourced positive stack bounds; mixed patch/skill",sourceClaimID:z.stableKey,sourceUnit:"positive items per prospecting observation",economicUse:"PROHIBITED",displayOnly:true,profileIsMeasured:false,denominatorVerifiedCompletedCasts:false};
  report.activeRecords++;report.appliedYieldFields+=(mn!==null?1:0)+(mx!==null?1:0);
 }
 report.economicFieldsUnchanged=records.every((r,i)=>ECON.map(k=>JSON.stringify(r[k])).join("|")===before[i]);
 if(!report.economicFieldsUnchanged)throw Error("Tooltip source altered economic fields");
 return report;
}
function validateTooltipIsolation(records){
 const errors=[];
 for(const r of records){
  const t=r.tooltipOnly;if(!t)continue;
  if(t.economicUse!=="PROHIBITED"||t.displayOnly!==true||t.profileIsMeasured!==false||"expectedQuantity" in t||t.dropChance!==null||t.denominatorVerifiedCompletedCasts!==false)errors.push("ECONOMIC_LEAK:"+r.recordID);
  if(!t.sourceUrl.startsWith("https://www.wowhead.com/item=")||!t.sourceClaimID||!t.sourceDenominator||!Number.isInteger(t.confidence)||t.confidence<0||t.confidence>100)errors.push("PROVENANCE:"+r.recordID);
  for(const [name,existing] of [["yieldMin",r.yieldMin],["yieldMax",r.yieldMax]])if(t[name]!==null&&(existing.value!==null||!Number.isInteger(t[name])||t[name]<1))errors.push("OVERRIDE_OR_INVALID:"+r.recordID+":"+name);
  if(t.yieldMin!==null&&t.yieldMax!==null&&t.yieldMin>t.yieldMax)errors.push("RANGE:"+r.recordID);
  if(t.yieldMax!==null&&t.yieldMax>t.sourceObservedMax)errors.push("OVERPROMISE:"+r.recordID);
 }
 return errors;
}
module.exports={applyTooltipFallbacks,validateTooltipIsolation};
