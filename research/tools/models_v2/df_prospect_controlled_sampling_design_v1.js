'use strict';
// F003 research-only: controlled zero-inclusive cast sampling design for unresolved DF prospecting.
// Planning calculations are NOT measurements, verified yields, or live recommendations.
const assert = require('node:assert/strict');
const MODEL_ID = 'df-prospect-controlled-sampling-design-v1.0.0';
const POLICY = Object.freeze({confidence:0,economicUse:'PREVIEW_ONLY',normalizedVerified:false,liveEconomicEligible:false,tooltipOnlyEligible:false});
const TARGETS = Object.freeze([
 {stableKey:'tsm:prospect:188658:192870:L1205',inputItemID:188658,outputItemID:192870},
 {stableKey:'tsm:prospect:188658:192871:L1206',inputItemID:188658,outputItemID:192871},
 {stableKey:'tsm:prospect:189143:192869:L1242',inputItemID:189143,outputItemID:192869},
 {stableKey:'tsm:prospect:189143:192870:L1243',inputItemID:189143,outputItemID:192870},
 {stableKey:'tsm:prospect:190311:192869:L1280',inputItemID:190311,outputItemID:192869}
]);
function need(ok,code){if(!ok)throw Error(code)}
const positiveInt=x=>Number.isSafeInteger(x)&&x>0;
const positiveFinite=x=>typeof x==='number'&&Number.isFinite(x)&&x>0;
function sampleCount(range,epsilon,logTerm){
 const n=Math.ceil(range*range*logTerm/(2*epsilon*epsilon));
 need(Number.isSafeInteger(n)&&n>0,'SAMPLE_SIZE_OVERFLOW');
 return n;
}
function design({selectedKeys,nominalInputPerCast,alpha=0.05,epsilonP=0.1,epsilonE=0.25,capAttestations={},plannedStudyFamilyID}){
 need(Array.isArray(selectedKeys)&&selectedKeys.length>0&&selectedKeys.length<=TARGETS.length,'SELECTED_KEYS');
 need(selectedKeys.every(k=>typeof k==='string'&&TARGETS.some(t=>t.stableKey===k))&&new Set(selectedKeys).size===selectedKeys.length,'UNKNOWN_OR_DUPLICATE_KEY');
 need(positiveInt(nominalInputPerCast),'NOMINAL_INPUT');
 need(positiveFinite(alpha)&&alpha<1&&positiveFinite(epsilonP)&&epsilonP<1&&positiveFinite(epsilonE),'PRECISION_DOMAIN');
 need(typeof plannedStudyFamilyID==='string'&&plannedStudyFamilyID.trim(),'STUDY_FAMILY');
 need(capAttestations&&typeof capAttestations==='object'&&!Array.isArray(capAttestations),'CAP_ATTESTATIONS');
 need(Object.keys(capAttestations).every(k=>selectedKeys.includes(k)),'UNSELECTED_CAP');
 const selected=TARGETS.filter(t=>selectedKeys.includes(t.stableKey));
 const K=selected.length;
 // Bonferroni: 2K potential two-sided P and E intervals, even if E caps unavailable.
 // Hoeffding per interval: Pr(|mean - truth| >= epsilon) <= 2 exp(-2 n epsilon^2 / range^2).
 const logTerm=Math.log(4*K/alpha);
 const nP=sampleCount(1,epsilonP,logTerm);
 const groups=new Map();
 for(const t of selected){
  const cap=capAttestations[t.stableKey];
  let nE=null,capStatus='UNVERIFIED_OR_ABSENT';
  if(cap!==undefined){
   need(cap&&typeof cap==='object'&&!Array.isArray(cap),'CAP_OBJECT');
   need(positiveInt(cap.maxPerCompletedCast),'CAP_RANGE');
   need(cap.status==='INDEPENDENTLY_REVIEWED'||cap.status==='HYPOTHETICAL','CAP_STATUS');
   need(typeof cap.sourceLineage==='string'&&cap.sourceLineage.trim(),'CAP_LINEAGE');
   need(cap.sourceLineage.trim().toLowerCase()!==plannedStudyFamilyID.trim().toLowerCase(),'CAP_NOT_INDEPENDENT');
   capStatus=cap.status==='INDEPENDENTLY_REVIEWED'?'CALLER_ATTESTED_REVIEW_NOT_AUTHENTICATED':'HYPOTHETICAL_NOT_VALID_FOR_INFERENCE';
   if(cap.status==='INDEPENDENTLY_REVIEWED')nE=sampleCount(cap.maxPerCompletedCast,epsilonE,logTerm);
  }
  if(!groups.has(t.inputItemID))groups.set(t.inputItemID,{inputItemID:t.inputItemID,targets:[]});
  groups.get(t.inputItemID).targets.push({stableKey:t.stableKey,outputItemID:t.outputItemID,probabilityPrecisionCasts:nP,expectedQuantityPrecisionCasts:nE,capStatus});
 }
 const cohorts=[...groups.values()].map(g=>{
  const allCaps=g.targets.every(t=>t.expectedQuantityPrecisionCasts!==null);
  const probabilityOnlyCasts=nP;
  const fullPrecisionCasts=allCaps?Math.max(nP,...g.targets.map(t=>t.expectedQuantityPrecisionCasts)):null;
  const grossInputAtPOnly=probabilityOnlyCasts*nominalInputPerCast;
  const grossInputAtFull=fullPrecisionCasts===null?null:fullPrecisionCasts*nominalInputPerCast;
  need(Number.isSafeInteger(grossInputAtPOnly)&&(grossInputAtFull===null||Number.isSafeInteger(grossInputAtFull)),'GROSS_INPUT_OVERFLOW');
  return {...g,probabilityOnlyCasts,fullPrecisionCasts,grossInputAtPOnly,grossInputAtFull,netConsumedInput:null,refunds:null,recipeEligibility:'REQUIRES_INDEPENDENT_VERIFICATION'};
 });
 return {modelID:MODEL_ID,targetKeys:selected.map(t=>t.stableKey),plannedStudyFamilyID,alpha,epsilonP,epsilonE,
  confidenceAllocation:'BONFERRONI_2K_TWO_SIDED_FIXED_N_HOEFFDING',logTerm,
  cohorts,protocol:['Record actual completed casts, aborted requests separately, unique cast IDs and exact timestamps/build','Record every output and quality rank per completed cast including zero counts and co-outputs','Record gross reagents and saved/refunded reagents per cast, never infer completed casts from consumed inputs','Record recipe ID, input rank, minimum eligible skill, actual skill, specialization, gear, unlocks and profession stats','Do not pool input ores, ranks, patches, unknown skill profiles or source-study families','Independently audit output universe, recipe eligibility and caps before interpreting E intervals'],
  caveats:['Sample sizes assume independent identically distributed completed casts at a fixed context','Output universe and hard caps are not authenticated by this planner','Unreviewed or hypothetical caps do not produce finite E sample-size guarantees','This is fixed-sample design, NOT an anytime-valid sequential confidence sequence','Planning alpha is statistical error budget, NOT evidence confidence or drop probability'],
  newObservedP:null,newObservedE:null,independentHoldouts:0,...POLICY};
}
function selfTest(){
 let passed=0;
 const eq=(a,b)=>{assert.deepEqual(a,b);passed++};
 const bad=(f,code)=>{assert.throws(f,new RegExp(code));passed++};
 const keys=TARGETS.map(t=>t.stableKey),base={selectedKeys:keys,nominalInputPerCast:5,plannedStudyFamilyID:'new-independent-cast-cohort'};
 const a=design(base);eq(a.targetKeys.length,5);eq(a.cohorts.length,3);eq(a.cohorts[0].targets.length,2);
 eq(a.cohorts[0].fullPrecisionCasts,null);eq(a.cohorts[0].netConsumedInput,null);
 eq(a.cohorts[0].grossInputAtPOnly,a.cohorts[0].probabilityOnlyCasts*5);
 eq(a.cohorts.every(g=>g.targets.every(t=>t.expectedQuantityPrecisionCasts===null)),true);
 eq(a.economicUse,'PREVIEW_ONLY');eq(a.confidence,0);eq(a.normalizedVerified,false);eq(a.newObservedE,null);
 const cap=Object.fromEntries(keys.map(k=>[k,{maxPerCompletedCast:2,status:'INDEPENDENTLY_REVIEWED',sourceLineage:'external-cap-review'}]));
 const b=design({...base,capAttestations:cap});eq(b.cohorts.every(g=>g.fullPrecisionCasts!==null),true);
 eq(b.cohorts.every(g=>g.fullPrecisionCasts>=g.probabilityOnlyCasts),true);
 eq(b.cohorts[0].grossInputAtFull,b.cohorts[0].fullPrecisionCasts*5);
 eq(b.cohorts[0].targets[0].capStatus,'CALLER_ATTESTED_REVIEW_NOT_AUTHENTICATED');
 const h=design({...base,capAttestations:{[keys[0]]:{...cap[keys[0]],status:'HYPOTHETICAL'}}});
 eq(h.cohorts[0].targets[0].expectedQuantityPrecisionCasts,null);
 eq(h.cohorts[0].targets[0].capStatus,'HYPOTHETICAL_NOT_VALID_FOR_INFERENCE');
 const n=design({...base,selectedKeys:[keys[0]],capAttestations:{[keys[0]]:cap[keys[0]]},epsilonP:.1,epsilonE:.25});
 eq(n.cohorts[0].probabilityOnlyCasts,Math.ceil(Math.log(4/.05)/(.02)));
 eq(n.cohorts[0].targets[0].expectedQuantityPrecisionCasts,Math.ceil(4*Math.log(4/.05)/(.125)));
 bad(()=>design({...base,selectedKeys:[keys[0],keys[0]]}),'UNKNOWN_OR_DUPLICATE_KEY');
 bad(()=>design({...base,selectedKeys:['invented']}),'UNKNOWN_OR_DUPLICATE_KEY');
 bad(()=>design({...base,alpha:0}),'PRECISION_DOMAIN');
 bad(()=>design({...base,epsilonE:0}),'PRECISION_DOMAIN');
 bad(()=>design({...base,nominalInputPerCast:0}),'NOMINAL_INPUT');
 bad(()=>design({...base,capAttestations:{[keys[0]]:{...cap[keys[0]],sourceLineage:base.plannedStudyFamilyID}}}),'CAP_NOT_INDEPENDENT');
 bad(()=>design({...base,capAttestations:{[keys[0]]:{...cap[keys[0]],maxPerCompletedCast:Infinity}}}),'CAP_RANGE');
 bad(()=>design({...base,capAttestations:{other:cap[keys[0]]}}),'UNSELECTED_CAP');
 bad(()=>design({...base,epsilonP:1e-300}),'SAMPLE_SIZE_OVERFLOW');
 bad(()=>design({...base,nominalInputPerCast:Number.MAX_SAFE_INTEGER}),'GROSS_INPUT_OVERFLOW');
 return {modelID:MODEL_ID,passed,failed:0,syntheticOnly:true};
}
module.exports={MODEL_ID,POLICY,TARGETS,design,selfTest};
if(require.main===module)console.log(JSON.stringify(selfTest()));
