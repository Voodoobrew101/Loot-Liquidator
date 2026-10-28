"use strict";
/* Durable source memory: research-only and deterministic. Run from repo root. */
const fs=require("node:fs"),path=require("node:path");
const ROOT=path.resolve(__dirname,"..");
const root=(p)=>path.join(ROOT,p);
const rows=(dir)=>{const d=root(dir);return fs.existsSync(d)?fs.readdirSync(d).filter(f=>f.endsWith(".jsonl")).sort().flatMap(f=>fs.readFileSync(path.join(d,f),"utf8").split(/\r?\n/).filter(x=>x.trim()).map((line,i)=>{try{return JSON.parse(line)}catch(e){throw Error(f+":"+(i+1)+": "+e.message)}})):[]};
const normalize=url=>{if(!url)return null;try{const u=new URL(url);u.hash="";const drop=["utm_source","utm_medium","utm_campaign","utm_term","utm_content","fbclid","gclid"];for(const d of drop)u.searchParams.delete(d);u.searchParams.sort();return(u.origin.toLowerCase()+u.pathname.replace(/\/+$/,"")+u.search).toLowerCase()}catch{return String(url).trim().toLowerCase()}};
const statuses=new Set(["FULLY_ANALYZED","PARTIAL","NEEDS_RECHECK","DUPLICATE","DISCOVERED"]);
const outcomes={ACCEPTED_NEW_EVIDENCE:6,ACCEPTED_CORRECTION:4,ACCEPTED_REUSE:3,USEFUL_NEGATIVE:2,NEEDS_WORK:0,REJECTED_UNSUPPORTED:-4,REJECTED_CONTEXT_MISMATCH:-4,REJECTED_DUPLICATE:-3,RETRACTED:-6};
const id=(o)=>[o.datasetID||"",o.studyID||"",o.originalStudyUrl||"",o.sourceUrl||""].join("|");
function build(observations,reviews,feedback){
 const map=new Map(),warnings=[];
 const get=url=>{const k=normalize(url);if(!k)return null;if(!map.has(k))map.set(k,{canonicalUrl:k,urls:[],observationIDs:[],studyIDs:[],datasetIDs:[],reviewedRecordKeys:[],status:"DISCOVERED",missingFields:[],lastReviewedAt:null,reviewEvents:0,originalStudyUrls:[],changeTriggers:[],revisitReasons:[]});return map.get(k)};
 const add=(a,v)=>{if(v!==null&&v!==undefined&&v!==""&&!a.includes(v))a.push(v)};
 for(const o of observations){const s=o.source||{},x=get(s.originalDocumentRef||s.url);if(!x)continue;add(x.urls,s.url);add(x.observationIDs,o.observationID);add(x.studyIDs,o.studyID);add(x.datasetIDs,o.datasetID);add(x.originalStudyUrls,s.originalDocumentRef);for(const z of o.outputs||[])if(z.outputItemID)add(x.reviewedRecordKeys,[o.processing?.inputItemID,o.processing?.method,z.outputItemID].join(":"))}
 const sorted=[...reviews].sort((a,b)=>String(a.reviewedAt||"").localeCompare(String(b.reviewedAt||"")));
 for(const r of sorted){if(!r.sourceUrl||!r.workerID||!r.reviewedAt||!statuses.has(r.status)){warnings.push("invalid review: "+id(r));continue}const x=get(r.sourceUrl);add(x.urls,r.sourceUrl);add(x.studyIDs,r.studyID);add(x.datasetIDs,r.datasetID);add(x.originalStudyUrls,r.originalStudyUrl);for(const z of r.observationIDs||[])add(x.observationIDs,z);for(const z of r.recordKeys||[])add(x.reviewedRecordKeys,z);for(const z of r.changeTrigger?[r.changeTrigger]:[])add(x.changeTriggers,z);for(const z of r.revisitReason?[r.revisitReason]:[])add(x.revisitReasons,z);x.status=r.status;x.missingFields=r.missingFields||[];x.lastReviewedAt=r.reviewedAt;x.reviewEvents++}
 const seen=new Set(),strats={};let approved=0;
 for(const f of feedback){if(!f.qaOutcome||!Object.hasOwn(outcomes,f.qaOutcome)||!f.claimID||!f.strategyID||!f.reviewer||!f.workerID||!f.reviewedAt){warnings.push("invalid feedback: "+(f.claimID||"missing"));continue}
 const key=[f.claimID,f.qaOutcome,f.reviewer].join("|");if(seen.has(key)){warnings.push("repeat feedback: "+key);continue}seen.add(key);
 const x=strats[f.strategyID]||(strats[f.strategyID]={reviewedClaims:0,accepted:0,rejected:0,points:0});
 x.reviewedClaims++;const score=outcomes[f.qaOutcome];x.points+=score;if(score>0){x.accepted++;approved++}if(score<0)x.rejected++;
 }
 const sources=[...map.values()].sort((a,b)=>a.canonicalUrl.localeCompare(b.canonicalUrl));
 return {schemaVersion:1,researchOnly:true,sourcesCount:sources.length,reviewEvents:sorted.length,qaEvents:seen.size,approvedQaEvents:approved,warnings,strategies:strats,sources};
}
function main(){const result=build(rows("evidence/observations"),rows("coordination/source-reviews"),rows("coordination/qa-feedback"));process.stdout.write(JSON.stringify(result,null,2)+"\n")}
if(require.main===module)main();
module.exports={normalize,build,outcomes};
