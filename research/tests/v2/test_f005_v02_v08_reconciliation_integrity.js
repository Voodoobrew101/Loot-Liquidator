'use strict';
const assert=require('node:assert/strict');
const fs=require('node:fs');
const F=['dropChance','yieldMin','yieldMax','expectedQuantity'];
function audit(d) {
  let checks=0;
  const eq=(a,b,msg)=>{checks++;assert.deepEqual(a,b,msg)};
  const ok=(v,msg)=>{checks++;assert.ok(v,msg)};
  const s=d.summary;
  eq(d.comparison.old.gitBlobSHA,'a838d75e82239339bea3861692291b44bd085662','old source pin');
  eq(d.comparison.new.gitBlobSHA,'560b885a0039045419c340716e263ae33ddf827a','new source pin');
  eq([s.oldRecords,s.newRecords,s.retained,s.added,s.removed,s.changedRetained,s.unchangedRetained],
    [976,1018,973,45,3,55,918],'partition totals');
  eq([d.addedRecords.length,d.removedRecords.length,d.changedRetainedRecords.length],[45,3,55],'delta lengths');
  eq(s.retained+s.added,s.newRecords,'new partition');
  eq(s.retained+s.removed,s.oldRecords,'old partition');
  eq(s.changedRetained+s.unchangedRetained,s.retained,'retained partition');
  const sets=[d.addedRecords,d.removedRecords,d.changedRetainedRecords].map(rows=>rows.map(r=>r.recordID));
  for(const ids of sets)eq(new Set(ids).size,ids.length,'unique record IDs');
  ok(!sets[0].some(id=>sets[1].includes(id)||sets[2].includes(id)),'addition overlap');
  ok(!sets[1].some(id=>sets[2].includes(id)),'retirement overlap');
  const counts=Object.fromEntries(F.map(k=>[k,0]));
  let rankChanges=0,metaChanges=0;
  for(const r of d.changedRetainedRecords){
    if(Object.keys(r.metadataDeltas||{}).length)metaChanges++;
    for(const k of F){
      const delta=r.fieldDeltas?.[k];if(!delta)continue;
      ok(delta.value&&Number.isFinite(delta.value.from)&&delta.value.to===null,'numeric quarantine '+r.recordID+'/'+k);
      eq(delta.status?.to,'unknown','unknown status '+r.recordID+'/'+k);
      eq(delta.confidence?.to,0,'zero confidence '+r.recordID+'/'+k);
      ok(Array.isArray(delta.blockers?.to)&&delta.blockers.to.length>0,'quarantine blocker '+r.recordID+'/'+k);
      if(delta.sourceClaimIDs)ok(delta.sourceClaimIDs.from.every(id=>delta.sourceClaimIDs.to.includes(id)),
        'preserved original claims '+r.recordID+'/'+k);
      counts[k]++;
    }
    if(Object.keys(r.mappingDeltas||{}).length){
      rankChanges++;
      eq(r.mappingDeltas.inputQualityRank,{from:1,to:null},'fish rank downgraded');
      eq(Object.keys(r.mappingDeltas),['inputQualityRank'],'no other identity change');
      ok(r.recordID.startsWith('tsm:mill:200061:'),'fish family only');
    }
  }
  eq(F.map(k=>counts[k]),[49,0,0,55],'104 quarantine field breakdown');
  eq(rankChanges,12,'fish rank changes');
  eq(metaChanges,54,'metadata changes');
  eq(s.oldEvidenceNumeric+58-6-104,s.newEvidenceNumeric,'numeric source reconciliation');
  eq([s.oldEvidenceNumeric,s.newEvidenceNumeric],[3610,3558],'numeric totals');
  let addedNumeric=0;const groups={};
  for(const r of d.addedRecords){
    const m=r.mapping,meta=r.metadata;
    groups[m.method]=(groups[m.method]||0)+1;
    ok(Number.isInteger(m.inputItemID)&&m.inputItemID>0&&Number.isInteger(m.outputItemID)&&m.outputItemID>0,'item IDs');
    ok(Number.isInteger(m.inputCountPerOperation)&&m.inputCountPerOperation>0,'batch');
    ok(typeof meta.sourceOrigin==='string'&&meta.sourceOrigin.length>0&&
       typeof meta.sourcePath==='string'&&meta.sourcePath.length>0,'provenance');
    ok(meta.recordConfidence<90,'no 90 admission');
    for(const k of F){
      const e=r.evidence[k];
      ok(e&&Number.isInteger(e.confidence)&&e.confidence>=0&&e.confidence<=100,'confidence');
      ok(Array.isArray(e.sourceClaimIDs)&&e.sourceClaimIDs.length>0,'source claims');
      if(e.value===null)eq(e.confidence,0,'null evidence confidence');
      else{ok(Number.isFinite(e.value)&&e.value>=0,'finite numeric');addedNumeric++;}
    }
    if(m.method==='Smelt'){
      ok(Number.isInteger(m.recipeSpellID)&&m.recipeSpellID>0,'smelt spell');
      ok(r.additionalContext?.reagents?.some(([id,n])=>id===m.inputItemID&&n===m.inputCountPerOperation),
        'direct reagent input match');
    }
    if(r.recordID.startsWith('historical:bfa:mass-mill:')){
      eq(m.inputCountPerOperation,20,'mass cast 20 herb');
      eq(r.evidence.expectedQuantity.status,'community-reported','historical not measured');
      ok(r.evidence.expectedQuantity.sampleOperations>0,'reported sample');
    }
    if(r.recordID.startsWith('candidate:tww:mill:')){
      eq(r.evidence.expectedQuantity.value,null,'candidate E unknown');
      ok(meta.eligibilityStatus.includes('NOT_VERIFIED'),'rank unverified');
    }
  }
  const tooltipContexts=d.changedRetainedRecords.filter(r=>r.addedContext?.tooltipOnly);
  eq(tooltipContexts.length,1,'one isolated tooltip-only context introduced');
  const tooltip=tooltipContexts[0];
  eq(tooltip.recordID,'retail12.0.5:prospect:36910:46849:globalmenace','tooltip-only identity');
  eq(tooltip.fieldDeltas.expectedQuantity.value.to,null,'gross-input E remains quarantined');
  eq(tooltip.addedContext.tooltipOnly[13],'PROVISIONAL_TOOLTIP_ONLY_NOT_ECONOMIC',
    'tooltip-only values prohibited from valuation');
  eq(addedNumeric,58,'added numeric fields');
  eq(groups,{Mill:21,Prospect:14,Refine:2,Smelt:8},'added families');
  const pairs=[];
  for(const r of d.removedRecords){
    const matches=d.addedRecords.filter(a=>a.mapping.method===r.mapping.method&&
      a.mapping.inputItemID===r.mapping.inputItemID&&a.mapping.outputItemID===r.mapping.outputItemID);
    eq(matches.length,1,'single candidate successor');
    const n=matches[0];
    eq(n.mapping.inputQualityRank,r.mapping.inputQualityRank,'same input rank');
    eq(n.mapping.inputCountPerOperation,r.mapping.inputCountPerOperation,'same batch');
    eq([r.mapping.expansionID,n.mapping.expansionID],[9,0],'expansion scope NOT identical');
    eq([r.mapping.outputQualityRank,n.mapping.outputQualityRank],[null,1],'output rank NOT identical');
    eq([n.evidence.dropChance.value,n.evidence.expectedQuantity.value],[null,null],'rank numeric quarantined');
    pairs.push([r.recordID,n.recordID]);
  }
  eq(pairs.length,3,'three conditional successor candidates');
  eq(d.safety.unsupportedFallbackConfidence,0,'fallback confidence');
  eq(d.safety.economicUse,'PREVIEW_ONLY','economic channel');
  eq(d.safety.normalizedVerified,false,'verification gate');
  eq(d.safety.liveEVPromotions,0,'live promotion');
  eq(d.safety.economicPromotionVerifiedByThisDiff,false,'no economic acceptance');
  return {checks,quarantinedFields:104,addedNumericFields:58,rankChanges:12,
    nonEquivalentReplacementPairs:pairs};
}
function selfTest(d){
  let rejected=0;
  function reject(name,mutate){const x=JSON.parse(JSON.stringify(d));mutate(x);
    try{audit(x)}catch(_){rejected++;return}
    throw Error('mutation escaped: '+name);
  }
  reject('numeric reintroduced',x=>x.changedRetainedRecords[0].fieldDeltas.dropChance.value.to=0);
  reject('confidence promotion',x=>x.changedRetainedRecords[0].fieldDeltas.dropChance.confidence.to=90);
  reject('missing blocker',x=>x.changedRetainedRecords[0].fieldDeltas.dropChance.blockers.to=[]);
  reject('rank reasserted',x=>x.changedRetainedRecords[0].mappingDeltas.inputQualityRank.to=1);
  reject('duplicate admission',x=>x.addedRecords[1].recordID=x.addedRecords[0].recordID);
  reject('historical measured claim',x=>x.addedRecords[0].evidence.expectedQuantity.status='measured');
  reject('historical cast denominator',x=>x.addedRecords[0].mapping.inputCountPerOperation=5);
  reject('invented TWW E',x=>x.addedRecords.find(r=>r.recordID.startsWith('candidate:tww:mill:')).evidence.expectedQuantity.value=1);
  reject('retired rank falsified',x=>x.removedRecords[0].mapping.outputQualityRank=1);
  reject('reagent mismatch',x=>x.addedRecords.find(r=>r.mapping.method==='Smelt').mapping.inputCountPerOperation=999);
  reject('missing provenance',x=>x.addedRecords[0].metadata.sourceOrigin='');
  reject('negative E',x=>x.addedRecords[0].evidence.expectedQuantity.value=-1);
  reject('missing admission',x=>x.addedRecords.pop());
  reject('numeric count altered',x=>x.summary.newEvidenceNumeric++);
  reject('live economic promotion',x=>x.safety.economicUse='LIVE');
  reject('forged verified',x=>x.safety.normalizedVerified=true);
  reject('tooltip-only economic leak',x=>x.changedRetainedRecords.find(r=>r.addedContext?.tooltipOnly).addedContext.tooltipOnly[13]='LIVE');
  return rejected;
}
if(require.main===module){
  const path=process.argv[2]||'research/proposed/itemdb-v02-v08-field-reconciliation.json';
  const d=JSON.parse(fs.readFileSync(path,'utf8'));
  console.log(JSON.stringify({...audit(d),mutationsRejected:selfTest(d)},null,2));
}
module.exports={audit,selfTest};
