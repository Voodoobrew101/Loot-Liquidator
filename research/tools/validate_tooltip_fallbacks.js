"use strict";
// Research-only tooltip fallback gate; deliberately does not modify itemdb.lua or economic fields.
function validate(doc){
 const errors=[];
 if(doc.artifactStatus!=="RESEARCH_ONLY_TOOLTIP_FALLBACK_STAGING_NOT_COMPILED")errors.push("not staging");
 if(doc.goldIsolation?.indexOf("NO_ECONOMIC_FIELDS")<0)errors.push("economic isolation declaration missing");
 const seen=new Set();
 for(const r of doc.tooltipFallbacks??[]){
  if(seen.has(r.stableKey))errors.push("duplicate "+r.stableKey);seen.add(r.stableKey);
  if(!Number.isInteger(r.inputItemID)||r.inputItemID<=0||!Number.isInteger(r.outputItemID)||r.outputItemID<=0)errors.push("IDs "+r.stableKey);
  if(!r.displayOnly||!r.provisional||r.economicUse!=="PROHIBITED"||r.profileIsMeasured!==false)errors.push("mode "+r.stableKey);
  if(Object.keys(r.economicFields??{}).sort().join(",")!=="dropChance,expectedQuantity,yieldMax,yieldMin"||Object.values(r.economicFields??{}).some(x=>x!==null))errors.push("economic leak "+r.stableKey);
  if("expectedQuantity" in (r.displayFields??{}))errors.push("display E leak "+r.stableKey);
  if(!r.source?.url?.startsWith("https://www.wowhead.com/item=")||!r.source?.variant?.startsWith("RETAIL_")||r.source?.url?.includes("classic"))errors.push("source "+r.stableKey);
  const p=r.displayFields?.dropChance,mn=r.displayFields?.yieldMin,mx=r.displayFields?.yieldMax;
  if(!p||!Number.isInteger(p.rawCount)||!Number.isInteger(p.rawOutOf)||p.rawCount<=0||p.rawCount>p.rawOutOf||Math.abs(p.rawCount/p.rawOutOf-p.rawRatio)>1e-9||p.value<=0||p.value>p.rawRatio||p.denominatorVerifiedCompletedCasts!==false||p.notMeasuredP!==true)errors.push("P denominator "+r.stableKey);
  if(!mn||!mx||!Number.isInteger(mn.value)||!Number.isInteger(mx.value)||!Number.isInteger(mx.sourceObservedMax)||mn.value<1||mn.value>mx.value||mx.value>mx.sourceObservedMax)errors.push("yield "+r.stableKey);
  if(mx.value<mx.sourceObservedMax&&mx.status!=="CONSERVATIVE_DISPLAY_TRIMMED_RARE_TAIL")errors.push("trim provenance "+r.stableKey);
 }
 if(!doc.tooltipFallbacks?.length)errors.push("empty");
 return errors;
}
module.exports={validate};
if(require.main===module){
 const fs=require("fs"),path=require("path"),root=process.argv[2]||".",file=path.join(root,"research/proposed/itemdb-tooltip-fallbacks-q25.json");
 const doc=JSON.parse(fs.readFileSync(file,"utf8")),errors=validate(doc);
 if(errors.length){console.error(errors.join("\n"));process.exitCode=1;}else console.log("Tooltip fallback staging valid: "+doc.tooltipFallbacks.length+" display-only rows; economic fields isolated.");
}
