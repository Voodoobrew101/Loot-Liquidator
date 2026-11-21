# Processing finalization derivation receipt

Lane-only post-review reconciliation: pins current physical rows, retains e832 lineage, identifies current-source aliases, derives output-unit quality shares without casts, and emits a compact native identity receipt. No raw/shared/runtime writes.

```python
import json,re,csv,hashlib,collections,sys
from pathlib import Path
W=Path('D:/My Documents/ChatGPT/Loot Liquidator');R=W/'catalogue-backlog-research-20261120';D=R/'research/v3/evidence/master/backlog-catalogue-20261120'
review=json.load(open(D/'processing-review.json',encoding='utf-8'));prop=json.load(open(D/'processing-proposals.json',encoding='utf-8'));idx=json.load(open(D/'processing-evidence-index.json',encoding='utf-8'))
srcByLoc={e['locator']:e for s in idx for g in s['groups']for e in g['rows']}
rows={r['locator']:r for s in review['sources']for g in s['cohorts']for r in g['rowDecisions']}
sp=W/'.validation/de-formula-data/ItemSparse-70961.csv';ip=W/'.validation/de-formula-data/Item-70961.csv';qp=W/'.validation/de-formula-data/CraftingQuality-70961.csv'
with qp.open(encoding='utf-8-sig')as f:qt={int(r['ID']):int(r['QualityTier'])for r in csv.DictReader(f)}
with ip.open(encoding='utf-8-sig')as f:rank={int(r['ID']):qt.get(int(r.get('CraftingQualityID')or 0))for r in csv.DictReader(f)}
native={};byname=collections.defaultdict(list)
with sp.open(encoding='utf-8-sig')as f:
 for r in csv.DictReader(f):
  n=int(r['ID']);native[n]=dict(name=r.get('Display_lang'),expansionID=int(r['ExpansionID']),qualityRank=rank.get(n),rarity=int(r['OverallQualityID']or 0),description=r.get('Description_lang'));byname[str(r.get('Display_lang')).casefold()].append(n)
def canon(r):return hashlib.sha256(json.dumps({k:v for k,v in r.items()if not k.startswith('_')},sort_keys=True,separators=(',',':'),ensure_ascii=False,allow_nan=False).encode()).hexdigest()
physical={};pinErrors=[]
for loc,row in rows.items():
 e=srcByLoc[loc];p=e['candidate']['sourceFile']
 if p not in physical:
  bs=(R/p).read_bytes();parsed=[]
  for line,t in enumerate(bs.decode('utf-8').splitlines(),1):
   try:q=json.loads(t)
   except Exception:continue
   if isinstance(q,dict):parsed.append((line,q))
  physical[p]=(hashlib.sha256(bs).hexdigest(),parsed)
 filehash,rs=physical[p];matched=[(n,r)for n,r in rs if r.get('id')==e['effective']['id']]
 if len(matched)!=1:pinErrors.append(loc);continue
 ln,raw=matched[0];row['backlogRawSHA256']=row['rawSHA256'];row['currentPhysicalRowSHA256']=canon(raw);row['currentPhysicalSourcePath']=p;row['currentPhysicalLine']=ln;row['physicalFileFingerprint']=filehash
 hist=e['effective'].get('histogram');obs=row['castDenominator']['observedCount']
 if isinstance(hist,dict):
  total=sum(hist.values());complete=obs is not None and total==obs
  row['fields']['histogram']=dict(decision='USE_SOURCE_COMPLETE_HISTOGRAM_IN_ITS_CONTEXT'if complete else'RETAIN_PARTIAL_POSITIVE_EVENT_DISTRIBUTION_ONLY',sourceBins=hist,reportedEvents=total,complete=complete,zeroBinObserved='0'in hist,reason='Separate positive-only bins from all-attempt denominator; no unknown zero count invented.')
 else:row['fields']['histogram']=dict(decision='UNKNOWN_NO_HISTOGRAM_INFERENCE',reason='Totals, percentages and ranges do not determine cast-level bins.')
 # Source unit-resolution assumptions are explicit, not false observations.
 si=int(next(s['sourceIndex']for s in review['sources']if any(loc==r['locator']for g in s['cohorts']for r in g['rowDecisions'])))
 if si in(195,197):row['fields']['expectedQuantity']['unitResolutionAssumption']='Interpret 1300 Whiptail as herb inputs; interpreting it as 1300 casts contradicts the reported common-pigment quantity under the retained ordinary milling yield constraint. This is a confidence-zero model interpretation, not measured casts.'
 if si==13:row['fields']['expectedQuantity']['unitResolutionAssumption']='Gathered ore is a reported starting budget, not verified consumed ore; all relevant stock processed and small remainders ignored is an explicit zero-confidence modeling assumption.'
 if si in(104,187)and row['fields']['expectedQuantity'].get('value')is not None and re.search(r'inconsisten|disagree',str(e['effective'].get('notes')),re.I):row['fields']['expectedQuantity']['unitResolutionAssumption']='Use the explicitly stated input ore quantity; reject conflicting claimed/nominal cast count as sample strength.'
assert not pinErrors,pinErrors
for p in prop['proposals']:
 row=rows[p['sourceLocator']];p['sourceBacklogRawSHA256']=row['backlogRawSHA256'];p['sourceRawSHA256']=row['currentPhysicalRowSHA256'];p['sourceFile']=row['currentPhysicalSourcePath'];p['sourceEffectiveSHA256']=row['effectiveSHA256'];p['quantity']=row['fields']['expectedQuantity']
 p['sourceInputUnitIsNotAnOperationCount']=True;p['sourceObservedSamplesAdded']=0
 ids=p['inputIdentity'].get('itemIDs',[]);eras={native[i]['expansionID']for i in ids if i in native};p['canonicalExpansionID']=next(iter(eras))if len(eras)==1 else None
 if p['sourceProfile'].get('raw',{}).get('specialization'):p['sourceProfile']['sourceSpecializationUnresolvedIsNotZero']=True
# Recovered archived means get correct native eras; archive's editorial exp IDs are not adopted.
# Stable alias authority from the current source identity machinery plus exact numerical/profile scope.
sys.path.insert(0,str(W/'catalogue-backlog-pipeline-20261120/tools'));import research_v3_to_baselines as v
m=v.load_calculator(R);allrows=m.load();vectors,_,_=m.study_vectors(allrows);byid={(r.get('_file'),r.get('id')):r for r in allrows}
aliasGroups=collections.defaultdict(list)
for p in prop['proposals']:
 e=srcByLoc[p['sourceLocator']];r=byid[(e['candidate']['sourceFile'],e['effective']['id'])]
 try:co=m.study_identity(r,vectors);p['sourceIdentityAuthority']='current-source-identity'
 except KeyError:co=('unplaced-or-reference-source-key',p['sourceKey'],p['sourceStudyKey']);p['sourceIdentityAuthority']='explicit-source-key-fallback-no-new-independence'
 p['sourceIdentityKey']=json.dumps(co,sort_keys=True,ensure_ascii=False)
 key=(p['sourceIdentityKey'],tuple(sorted(p['inputIdentity'].get('itemIDs',[]))),tuple(sorted(p['outputIdentity'].get('itemIDs',[]))),p['quantity'].get('unit'),p['quantity'].get('value'))
 aliasGroups[key].append(p)
aliasReceipts=[]
for group in aliasGroups.values():
 if len(group)<2:continue
 chosen=max(group,key=lambda p:(bool(p['sourceProfile'].get('effectiveSkill')),bool(p['sourceProfile'].get('stats')),len(str(p['sourceProfile']['raw'])),-len(p['sourceLocator'])))
 for p in group:
  p['canonicalRepresentativeProposalID']=chosen['proposalID']
  if p is not chosen:p['aliasPolicy']='SAME_CURRENT_SOURCE_IDENTITY_AND_EXACT_SAME_NORMALIZED_FIELD; retain provenance, add no independent field weight'
 aliasReceipts.append(dict(representative=chosen['proposalID'],members=[p['proposalID']for p in group],reason='Current source identity plus exact canonical input/output/quantity/unit agrees; no duplicate observation weighting.'))
# Field-specific unit-quality shares. Output-unit denominator is never an operation denominator.
shares=[]
for s in review['sources']:
 for g in s['cohorts']:
  bucket=collections.defaultdict(dict);bad=set()
  for row in g['rowDecisions']:
   r=srcByLoc[row['locator']]['effective'];total=r.get('totalQuantity');rr=r.get('outputRank')or row.get('recoveredSourceOutputRank')or row['outputIdentity'].get('sourceRank')
   if rr is None:
    z=re.search(r'(?:quality|rank|q)\s*([123])',str(row.get('recoveredOutputName')or r.get('outputName')or''),re.I)
    if z:rr=int(z[1])
   if total is None or rr not in(1,2,3):continue
   name=str(row.get('recoveredOutputName')or r.get('outputName')or row['outputIdentity'].get('nativeName')or'')
   if re.search(r'green gems',name,re.I):family='pooled green/uncommon gems'
   elif re.search(r'blue gems',name,re.I):family='pooled blue/rare gems'
   else:family=re.sub(r'\s*(?:\([^)]*\)|(?:quality|rank|q)\s*[123])','',name,flags=re.I).strip().casefold()
   if not family:continue
   if rr in bucket[family]and bucket[family][rr]['units']!=total:bad.add(family)
   bucket[family][rr]=dict(rank=rr,units=total,sourceLocator=row['locator'])
  for family,bs in bucket.items():
   if family in bad or len(bs)<2:continue
   denom=sum(z['units']for z in bs.values())
   if denom<=0:continue
   nativeRanks={native[i]['qualityRank']for i in byname.get(family,[])if native[i]['qualityRank']is not None}
   complete=set(bs)==(nativeRanks or{1,2,3})
   sh=dict(proposalID=g['cohortID']+':quality-share:'+hashlib.sha256(family.encode()).hexdigest()[:10],sourceKey=s['sourceKey'],sourceStudyKey=g['sourceStudyKey'],cohortID=g['cohortID'],family=family,reportedRankUnits=[bs[k]for k in sorted(bs)],totalReportedOutputUnits=denom,unitShares={str(k):bs[k]['units']/denom for k in sorted(bs)},formula='rank output units / sum of same-family reported rank output units',completeRankCoverage=complete,sampleCount=None,hits=None,modelConfidence0to100=0,sourceProfile=g['sourceProfile'],admissionDecision='USE_PROFILE_SCOPED_UNIT_QUALITY_SHARE'if complete else'RETAIN_CONDITIONAL_SHARE_OF_REPORTED_RANKS_ONLY',conditions='This is output-unit quality composition, not hit probability. Missing rank outcomes are not complemented. Character Inspiration alone does not prove method eligibility; operative claims need explicit source/native evidence.')
   shares.append(sh);g['qualityShareProposalIDs']=g.get('qualityShareProposalIDs',[])+[sh['proposalID']]
# A few explicitly reported averages are present only as words, not averageShown.
supp=[]
for si,gi,val,div in[(37,'p037-000',1.48,1000),(37,'p037-001',3.6,1000)]:
 g=next(g for g in review['sources'][si]['cohorts']if g['cohortID']==gi);row=g['rowDecisions'][0]
 supp.append(dict(proposalID=gi+':source-word-average',sourceKey=review['sources'][si]['sourceKey'],sourceLocator=row['locator'],sourceFile=row['currentPhysicalSourcePath'],sourceRawSHA256=row['currentPhysicalRowSHA256'],inputIdentity=row['inputIdentity'],outputIdentity=row['outputIdentity'],value=val/div,formula=f'{val} / {div}',unit='input',modelConfidence0to100=0,sourceSupportMaximum=20,sourceProfile=g['sourceProfile'],admissionDecision='USE_REPORTED_MEAN_PRIOR_WITH_CANONICAL_LINEAGE',conditions='Source explicitly states mean per1000ore. Keep overlapping precise591/400000 representative instead of also weighting rounded1.48. No sampled cast count manufactured.'))
# Explicit source range+mode supports a declared distribution prior; no empirical N.
ranges=[]
for si,minimum,maximum,mode,den in[(51,11,17,None,10),(64,2,15,12,10)]:
 g=review['sources'][si]['cohorts'][0];row=g['rowDecisions'][0];r=srcByLoc[row['locator']]['effective']
 name=r.get('inputName')or'';outname=r.get('outputName')or''
 # Exact native named families, unknown ranks kept as a pool.
 inf=byname.get(name.casefold(),[]);ouf=byname.get(outname.casefold(),[])
 mean=(minimum+maximum+(mode if mode is not None else 0))/(3 if mode is not None else 2)
 ranges.append(dict(proposalID=g['cohortID']+':distribution-prior',sourceKey=review['sources'][si]['sourceKey'],sourceLocator=row['locator'],sourceFile=row['currentPhysicalSourcePath'],sourceRawSHA256=row['currentPhysicalRowSHA256'],inputItemIDs=inf,outputItemIDs=ouf,sourceMinimum=minimum,sourceMaximum=maximum,sourceMode=mode,meanPerInput=mean/den,formula=f'({minimum}+{maximum}'+(f'+{mode})/3'if mode is not None else')/2')+f'/{den}',distributionAssumption='triangular on reported min/mode/max'if mode is not None else'uniform midpoint on source-reported each-mill range',modelConfidence0to100=0,sourceSupportMaximum=5,observedSamplesAdded=0,admissionDecision='USE_SCOPED_DISTRIBUTION_MODEL_PRIOR'if inf and ouf else'REJECT_ITEM_ATTRIBUTION_RETAIN_RANGE_SCENARIO',conditions='Distribution is modeled, not observed frequencies; source mode is not asserted as a measured mean. Requires actual native operation eligibility and preserved unknown source profile.'))
rejected=[p for p in prop['proposals']if p['admissionDecision']=='RETAIN_NUMERICAL_SCENARIO_REJECT_ITEM_ATTRIBUTION']
for p in rejected:p['currentItemNumericalDecision']='REJECT_CURRENT_ITEM_QUOTE';p['rejectionReason']='Source ratio preserved, but a verified input/output identity or legal pool cannot be attached without adding an unsupported attribution.';p['recheckTrigger']='Original named input/output identity or verified recipe-family join; no new in-game collection requested.'
prop.update(status='SCIENTIFIC_REVIEW_COMPLETE_IMPLEMENTATION_AND_PARENT_CROSS_REVIEW_PENDING',sourcePhysicalRowPinPolicy='Exact canonical physical row/path/ID hash is admission authority; whole-file fingerprints are provenance, not blanket holds on unrelated appended rows.',canonicalAliasReceipts=aliasReceipts,qualityShareProposals=shares,recoveredSourceWordMeanProposals=supp,distributionModelProposals=ranges,sourceRawHashMeaning='sourceRawSHA256 hashes the current0cd physical source row before corrections; sourceEffectiveSHA256 hashes after current module corrections. sourceBacklogRawSHA256 retains e832 backlog lineage.')
review['coverageProof'].update(currentPhysicalRowsPinned=len(rows),physicalPinErrors=pinErrors,distinctPhysicalSourceFiles=len(physical),qualityShareProposals=len(shares),currentIdentityAliasGroups=len(aliasReceipts))
review['sourceRawHashMeaning']=prop['sourceRawHashMeaning']
needed={i for p in prop['proposals']for k in('inputIdentity','outputIdentity')for i in p[k].get('itemIDs',[])}
needed.update(i for p in ranges for k in('inputItemIDs','outputItemIDs')for i in p[k])
subset=dict(schemaVersion=1,build=70961,sourceFiles=review['nativeIdentityReceipts'],items={str(i):native[i]for i in sorted(needed)if i in native},policy='Native names/qualities/expansion/acquisition metadata only; not fabricated observed outcomes or standalone native processing eligibility.')
(D/'processing-native-identities.json').write_text(json.dumps(subset,ensure_ascii=False,indent=1),encoding='utf-8')
(D/'processing-review.json').write_text(json.dumps(review,ensure_ascii=False,indent=1),encoding='utf-8')
(D/'processing-proposals.json').write_text(json.dumps(prop,ensure_ascii=False,indent=1),encoding='utf-8')
print(review['coverageProof']);print('native subset',len(subset['items']),'aliases',len(aliasReceipts),'unit quality shares',len(shares),'complete',sum(p['completeRankCoverage']for p in shares),'wordmeans',len(supp),'rangepriors',len(ranges))

```
