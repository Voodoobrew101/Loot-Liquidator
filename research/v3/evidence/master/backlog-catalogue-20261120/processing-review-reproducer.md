# Processing catalogue derivation receipt

Lane-only audit reproducer. Reads pinned sources/native CSVs; writes only owned review/proposal JSONs; does not change evidence, corrections, shared code, runtime, or observed counts. Run only with the source snapshot, reviewed denominator decisions and native CSV fingerprints stated in the catalogue.

```python
import json,re,csv,hashlib,collections
from pathlib import Path
W=Path('D:/My Documents/ChatGPT/Loot Liquidator');R=W/'catalogue-backlog-research-20261120';D=R/'research/v3/evidence/master/backlog-catalogue-20261120'
S=json.load(open(D/'processing-evidence-index.json',encoding='utf-8'));I=json.load(open(W/'.validation/backlog-closure-20261120/inputs/processing.json',encoding='utf-8'))
P0=json.load(open(D/'processing-proposals.json',encoding='utf-8'))
denoms={p['sourceLocator']:(p.get('sourceDenominator') or p.get('quantity',{}).get('sourceDenominator'))for p in P0['proposals']if p.get('sourceDenominator') or p.get('quantity',{}).get('sourceDenominator')}
manual={3:{'p003-000':9000,'p003-002':350,'p003-005':9000,'p003-007':350,'p003-008':9000},10:{'default':100},11:{'default':100},13:{237361:67,237365:66,237363:8},21:{'default':5000},25:{'p025-001':70,'p025-007':70},31:{'default':44925},32:{'p032-000':54137,'p032-006':1000,'p032-007':40000,'p032-011':40000,'p032-012':1000,'p032-014':10000,'p032-015':8000,'p032-018':20000},33:{'p033-000':33000,'p033-002':33000,188658:30000},45:{'default':660},53:{210936:10000,210933:10000,'p053-005':1000,'p053-006':1000},56:{'default':400},82:{169701:1700000,171315:10000,168589:1000},83:{'default':48315},86:{'default':5000},87:{'default':1100},88:{'p088-000':12000,'p088-001':26000,'p088-002':6000,'p088-003':10000,'p088-004':10000,'p088-005':26000,'p088-006':10000},90:{'p090-000':5000,'p090-001':50000},92:{'default':100},94:{'p094-001':1000,'p094-002':5000,'p094-005':1000,'p094-006':5000},97:{3858:1000,10620:1000,2770:200},98:{'default':40000},99:{'default':2000},100:{'p100-001':80},102:{'p102-000':5160,'p102-002':5160},103:{'default':3760},104:{'p104-001':840},105:{23425:50},109:{'p109-000':600,'p109-001':1000,'p109-002':340},110:{'p110-000':300,'p110-001':50},111:{'default':100},114:{124101:440,124104:45,124103:121,128304:1000},115:{'default':200},116:{'default':500},118:{'default':185},119:{'default':2000},120:{'p120-000':2700,'p120-001':2800,'p120-002':366900},121:{'default':200},122:{'default':1000},123:{'default':200},124:{'p124-003':335,'p124-009':335,'p124-011':335,'p124-004':500,'p124-012':500,'p124-013':500},125:{'default':20},126:{'p126-002':20000,'p126-006':20000,'default':5000},127:{'default':500},128:{'default':1000},129:{'default':3000},130:{'p130-000':600,'p130-001':100,'p130-002':400},131:{'default':10000},132:{'default':1700},133:{'default':968},135:{190311:35,188658:150,190395:1000,190396:1000,'p135-003':100,'p135-006':100,'p135-011':100,'p135-014':100},137:{'default':300},138:{'p138-000':5000,'p138-001':7000,'p138-002':400,'p138-003':5000,'p138-004':7000,'p138-005':400,'p138-006':5000,'p138-007':7000,'p138-009':5000,'p138-010':5000,'p138-011':7000,'p138-013':7000},139:{'default':5000},141:{'p141-001':1000,'p141-002':1000},142:{'p142-001':450,'p142-003':450,'p142-006':450},147:{'p147-000':565,'p147-001':100,'p147-002':565},150:{'default':150},151:{'default':150},152:{'default':4000},153:{'default':4000},154:{23425:50},155:{23425:50},156:{'p156-000':1000,'p156-001':1000,'p156-004':1000,'p156-005':1000},157:{'default':200},158:{'default':180},159:{'default':480},161:{'p161-000':680,'p161-001':5000,'p161-003':360,'p161-004':200,'p161-005':200,'p161-006':120},172:{785:284,2450:273,2452:114,2453:58},173:{785:284,2450:273,2452:114,2453:58},180:{'default':22000},181:{22790:22000},182:{'default':3760},185:{'default':1000},186:{'default':1200},187:{'p187-002':80,'p187-003':100},190:{'p190-000':40000,'p190-002':1910,'p190-004':10000,'p190-006':500,'p190-007':400},191:{'p191-000':10000},194:{'default':1755},195:{'default':1300},197:{'default':1300},200:{'default':400},201:{'p201-001':370},202:{'p202-000':200,'p202-001':20},203:{'p203-000':60,'p203-002':65},205:{'p205-001':615},207:{'default':50},208:{'p208-000':1020,'p208-001':1005,'p208-002':1020,'p208-003':1005},211:{'default':5600},213:{'p213-001':700},214:{'default':2000},219:{'default':100},222:{'default':1000},223:{'default':1000}}
manual.update({1:{'default':480},7:{'default':400},8:{'default':100},22:{'p022-008':26000,'p022-009':22000,'p022-010':1000,'p022-012':9000,'p022-014':6090,'p022-017':13000},73:{'default':1000},168:{'default':287},193:{'default':577},216:{'default':700}})
manual[32].update({'p032-019':10000,'p032-026':1000,'p032-027':1000})
sp=W/'.validation/de-formula-data/ItemSparse-70961.csv';ip=W/'.validation/de-formula-data/Item-70961.csv';qp=W/'.validation/de-formula-data/CraftingQuality-70961.csv'
with qp.open(encoding='utf-8-sig')as f:qt={int(r['ID']):int(r['QualityTier'])for r in csv.DictReader(f)}
with ip.open(encoding='utf-8-sig')as f:quality={int(r['ID']):qt.get(int(r.get('CraftingQualityID')or 0))for r in csv.DictReader(f)}
names=collections.defaultdict(list);native={}
with sp.open(encoding='utf-8-sig')as f:
 for r in csv.DictReader(f):
  n=int(r['ID']);name=r.get('Display_lang')or'';native[n]={'name':name,'expansionID':int(r['ExpansionID']),'description':r.get('Description_lang'),'rarity':int(r['OverallQualityID']or 0),'rank':quality.get(n)};names[name.casefold()].append(n)
familyNames={str(q['effective'].get(k)or'').casefold() for s in S for g in s['groups']for q in g['rows']for k in('inputName','outputName')if str(q['effective'].get(k)or'').casefold()in names}
cache={}
def archive(r):
 m=r.get('migratedFrom')or{};path=m.get('path');ref=m.get('recordRef')or'';p=R/str(path)
 if not path or not p.is_file():return None
 if path not in cache:
  b=p.read_bytes()
  try:vals=[json.loads(l)for l in b.decode('utf-8').splitlines()if l.strip()]
  except Exception:
   try:vals=[json.loads(b)]
   except Exception:return None
  cache[path]=(hashlib.sha256(b).hexdigest(),vals)
 sha,vals=cache[path]
 if m.get('sha256')and sha!=m['sha256']:return None
 z=re.search(r'line\s+(\d+)',ref)
 if z and 0<int(z[1])<=len(vals):return dict(path=path,sha256=sha,record=vals[int(z[1])-1])
 for v in vals:
  if any(v.get(k)and v[k]in ref for k in('observationID','recordKey')):return dict(path=path,sha256=sha,record=v)
 return None
def profile(r):
 raw={k:r.get(k)for k in('skill','specialization','stats','patch','dataDate')};txt=' '.join(str(v)for v in raw.values()if v is not None)+' '+str(r.get('notes')or'');p={'raw':raw,'unreportedNodesRemainUnknown':True};sk=str(r.get('skill')or'')
 z=re.search(r'(?:effective(?:\s+prospecting)?\s+skill\s*|Skill\s*)(\d+(?:\.\d+)?)',sk,re.I)or re.match(r'^(\d+(?:\.\d+)?)/\d+',sk)
 if z:p.update(effectiveSkill=float(z[1]),skillIncludesSpecialization=True)
 elif sk.isdigit():p.update(reportedSkill=float(sk),skillBasis='Source numeric skill; inclusion of recipe/tree/input bonuses unresolved')
 stats={}
 for stat in('resourcefulness','inspiration','multicraft'):
  a=re.search(r'(\d+(?:\.\d+)?)\s*%\s*'+stat,txt,re.I);b=re.search(stat+r'(?:\s+rate)?\s*[=:]\s*(0?\.\d+|\d+(?:\.\d+)?)',txt,re.I)
  if a:stats[stat]={'percent':float(a[1])}
  elif b:stats[stat]={'percent':float(b[1])*100 if float(b[1])<=1 else float(b[1])}
 if stats:p['stats']=stats
 p['inspirationCapabilityEvidence']='SOURCE_OPERATIVE_CLAIM'if re.search(r'with inspiration|inspiration breakpoint|inspiration.*guaranteed rank|guaranteed rank.*inspiration',txt,re.I)else'CHARACTER_CONTEXT_ONLY_NOT_METHOD_CAPABILITY_PROOF'
 if re.search(r'maxed|full\s+\w+\s+tree|30/30|40/40',str(r.get('specialization')or''),re.I):p['normalizationConstraint']='Known invested source profile; never label it observed minimum/zero investment. Typed nodes require a verified name/cap join.'
 return p
def identity(r,k):
 n=r.get(k+'Name');i=r.get(k+'ItemID');rank=r.get(k+'Rank')
 if n:
  z=re.search(r'\s+(?:quality|rank|q)\s*([123])$',n,re.I)
  if z:n=n[:z.start()].strip();rank=rank or int(z[1])
 if i in native:
  v=native[i];explicit=names.get(str(n or'').casefold(),[])
  if explicit and n.casefold()!=v['name'].casefold():
   matches=[z for z in explicit if not rank or native[z]['rank']==rank]or explicit
   return dict(kind='source-name-native-identity-correction',itemIDs=matches,rawItemID=i,sourceName=n,reason='Historical numeric ID disagrees with exact source material name; pinned native name join preserves measurement without editing archive.')
  if rank is None and v['rank']is not None:
   ids=[z for z in names[v['name'].casefold()]if native[z]['rank']is not None]
   return dict(kind='verified-unranked-native-family',itemIDs=ids,sourceItemID=i,sourceName=n,nativeName=v['name'],rankUnknown=True,allocation='No observed rank-specific counts asserted')
  o={'kind':'exact-native-item','itemIDs':[i],'nativeName':v['name'],'nativeRank':v['rank'],'sourceRank':rank,'sourceItemID':i,'nativeExpansionID':v['expansionID']}
  if rank and v['rank']and rank!=v['rank']:
   a=[z for z in names[v['name'].casefold()]if native[z]['rank']==rank]
   if len(a)==1:o.update(kind='source-rank-native-identity-correction',itemIDs=a,rawItemID=i,reason='Source quality disagrees with historical numeric ID; native same-name rank join resolves it.')
   else:o['kind']='unresolved-rank-conflict'
  return o
 if n:
  low=n.casefold().strip();base=re.sub(r'\s*\([^)]*\)','',low).strip();ids=names.get(base,[])
  if ids and not re.search(r'mixed|unspecified|thread context|not explicitly|unidentified',low):
   if rank:ids=[z for z in ids if native[z]['rank']==rank]or ids
   return dict(kind='verified-native-name-family',itemIDs=ids,sourceName=n,sourceRank=rank,rankUnknown=rank is None)
  ids=[]
  for name in familyNames:
   if len(name)>5 and name in low and re.search(r'pooled|any rank|all rank|rank unspecified|unranked',low):ids.extend(z for z in names[name]if not rank or native[z]['rank']==rank)
  if ids:return dict(kind='verified-named-family-pool',itemIDs=sorted(set(ids)),sourceName=n,allocation='Pooled total only; no full total copied per member')
  if k=='output'and re.search(r'gems?|^uncommon$|^rare$',low):
   era=(native.get(r.get('inputItemID'))or{}).get('expansionID')
   rarity=2 if re.search(r'green|uncommon',low)else 3 if re.search(r'blue|rare',low)else 4 if'epic'in low else None
   if era==9:
    ids=[z for z,v in native.items()if v['expansionID']==9 and'prospecting'in str(v['description']).lower()and(not rarity or v['rarity']==rarity)and(not rank or v['rank']==rank)]
    if ids:return dict(kind='verified-native-prospect-rarity-pool',itemIDs=ids,sourceName=n,sourceRarity=rarity,sourceRank=rank,identityProof='Pinned native acquisition description, rarity and Item->CraftingQuality rank join',allocation='One pooled total; no observed per-species allocation')
   pools={1:{2:[23117,23077,23079,21929,23112,23107],3:[23436,23438,23437,23439,23440,23441]},2:{2:[36917,36920,36923,36926,36929,36932],3:[36918,36921,36924,36927,36930,36933],4:[36919,36922,36925,36928,36931,36934]},3:{2:[52177,52178,52179,52180,52181,52182],3:[52190,52191,52192,52193,52194,52195]},6:{2:[130173,130174,130175,130176,130177,130172],3:[130178,130179,130180,130181,130182,130183]},7:{2:[153700,153701,153702,153703,153704,153705],3:[154120,154121,154122,154123,154124,154125],4:[153706]}}
   ids=[z for z in pools.get(era,{}).get(rarity,[])if z in native]
   if ids:return dict(kind='reviewed-era-rarity-family-pool',itemIDs=ids,sourceName=n,sourceRarity=rarity,identityProof='Native names/rarities checked; legal family independently corroborated by named source outcomes in this lane; native current action eligibility separate',allocation='Pooled quantity only; no observed species allocation')
 return dict(kind='unresolved-source-identity',sourceName=n,sourceItemID=i,sourceRank=rank)

proposals=[];reviews=[];counts=collections.Counter()
for s in S:
 sr=dict(sourceKey=s['sourceKey'],sourceIndex=s['index'],reviewStatus='FIELD_AND_COHORT_DECISIONS_COMPLETE',candidateRows=sum(len(g['rows'])for g in s['groups']),cohorts=[],existingReviewReceipts=[z['receiptPath']for z in I['sources'][s['index']]['priorReviewFacts']])
 for g in s['groups']:
  gr=dict(cohortID=g['groupID'],sourceStudyKey=g['cohort'][0],sourceProfile=profile(g['rows'][0]['effective']),rowDecisions=[])
  for e in g['rows']:
   r=e['effective'];txt=str(r.get('quote')or'')+' '+str(r.get('notes')or'');a=archive(r);old=a['record']if a else{};op=old.get('processing')or{};ins=identity(r,'input');outs=identity(r,'output');N=r.get('casts');basis=str(r.get('castsBasis')or'');sel=bool(re.search(r'selected anecdotal|selected.*positive|once received|single positive anecdote|one selected',txt,re.I))
   ar=bool(re.search(r'nominal|fiveOreEquivalent|nominalFiveOre|casts\s*=|casts from the old record.s.*[Ee]quivalent|derived at five|divided by.*per cast',txt,re.I))or bool(re.search(r'equivalent|derived|arithmetic',basis,re.I))or op.get('actualOperationCountKnown')is False
   obs=N if isinstance(N,(int,float))and N>0 and float(N).is_integer()and not ar and not sel else None
   facts={k:r.get(k)for k in('type','method','inputItemID','inputName','inputRank','outputItemID','outputName','outputRank','casts','castsBasis','inputsProcessed','inputsPerCast','totalQuantity','castsWithDrop','percentShown','percentMeaning','minSeen','maxSeen','averageShown','averagePer','histogram')if r.get(k)is not None}
   row=dict(locator=e['locator'],recordID=r['id'],rawSHA256=e['candidate']['rawSHA256'],effectiveSHA256=hashlib.sha256(json.dumps({k:v for k,v in r.items()if not k.startswith('_')},sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()).hexdigest(),sourceFacts=facts,inputIdentity=ins,outputIdentity=outs,castDenominator=dict(decision='RETAIN_REPORTED_OPERATION_COUNT'if obs is not None else'UNKNOWN_NO_SAMPLE_PROMOTION',observedCount=obs,reportedValue=N,reason='Reported completed operations retained, distinct from output units.'if obs is not None else('Selected positive event is not an all-attempt denominator.'if sel else'No independently stated complete-operation count; input/batch arithmetic remains provenance.')),fields={})
   if a:row['archiveReceipt']=dict(path=a['path'],actualSHA256=a['sha256'],recordID=old.get('observationID')or old.get('recordKey'))
   if outs['kind']=='unresolved-source-identity'and a:
    note=str(r.get('notes')or'');z=re.search(r'unmappedReportedOutputs\[(\d+)\]',note)
    if z and int(z[1])<len(old.get('unmappedReportedOutputs',[])):
     u=old['unmappedReportedOutputs'][int(z[1])];nm=u.get('materialFamily')or u.get('outputName')or u.get('originalName')or u.get('name')
     lab=re.search(r"labels output '(.+?)' but",str(u.get('reason')or''))
     if lab:nm=lab[1]
     if nm:outs=identity(dict(r,outputName=nm),'output');row.update(outputIdentity=outs,recoveredOutputName=nm)
    z=re.search(r'originalNamedGemTotalsRank2Rank3\.([^\[]+)\[([01])\]',note)
    if z:
     nm=z[1].strip();outs=identity(dict(r,outputName=nm,outputRank=2+int(z[2])),'output');row.update(outputIdentity=outs,recoveredOutputName=nm,recoveredSourceOutputRank=2+int(z[2]))
    z=re.search(r'rawNamedCounts\.([^;]+?);',note)
    if z:nm=z[1].strip();outs=identity(dict(r,outputName=nm),'output');row.update(outputIdentity=outs,recoveredOutputName=nm)
   den=denoms.get(e['locator'])or manual.get(s['index'],{}).get(g['groupID'],manual.get(s['index'],{}).get(r.get('inputItemID'),manual.get(s['index'],{}).get('default')))
   proof='Source quote/notes manually reconciled in processing review; not a completed-cast denominator.'if den else None
   if not den and isinstance(r.get('inputsProcessed'),(int,float))and r['inputsProcessed']>0:den=r['inputsProcessed'];proof='Source inputsProcessed field; no cast-count promotion.'
   if not den and isinstance(op.get('reportedInputsConsumed'),(int,float))and op['reportedInputsConsumed']>0:den=op['reportedInputsConsumed'];proof='Hash-verified archive processing.reportedInputsConsumed; not an observed operation count.'
   if not den:
    z=re.search(r'(?:Source |Workbook |source workbook |listed )?Quantity\s*(?:=\s*)?([0-9][0-9,]*)',txt,re.I)
    if z:den=int(z[1].replace(',',''));proof='Source workbook Quantity column; nominal input budget, not casts.'
   val=None;der=None;unit=None;oldmean=None
   for oo in old.get('outputs',[]):
    if oo.get('outputItemID')==r.get('outputItemID'):
     oldmean=oo.get('reportedHistoricalMeanPerCast')
     if oldmean is None:oldmean=oo.get('reportedMeanPerCompletedOperation')
     if oldmean is not None:break
   if oldmean is not None:
    b=op.get('batchInputsPerOperation');val=oldmean/(b or 1);der=f'{oldmean} / {b or 1}';unit='input'if b else'cast';row['recoveredReportedMeanPerCast']=oldmean
   elif r.get('averageShown')is not None:
    per=r.get('averagePer')
    if per in('input','1000 inputs'):z=1000 if per=='1000 inputs'else 1;val=r['averageShown']/z;der=f"{r['averageShown']} / {z}";unit='input'
    elif per=='cast':b=r.get('inputsPerCast');val=r['averageShown']/(b or 1);der=f"{r['averageShown']} / {b or 1}";unit='input'if b else'cast'
   if r.get('totalQuantity')is not None and den and not sel:val=r['totalQuantity']/den;der=f"{r['totalQuantity']} / {den}";unit='input'
   elif r.get('totalQuantity')is not None and obs and not sel:
    b=r.get('inputsPerCast');val=r['totalQuantity']/obs/(b or 1);der=f"{r['totalQuantity']} / {obs}"+(f' / {b}'if b else'');unit='input'if b else'cast'
   if val is None and r.get('percentShown')is not None and r.get('percentMeaning')=='perInput'and re.search(r'unit|quantity|yield|per.ore rate|per-input.ore rate',txt,re.I):val=r['percentShown']/100;der=f"{r['percentShown']} / 100";unit='input';row['percentSemantic']='OUTPUT_UNIT_RATIO_NOT_OCCURRENCE'
   zero=False
   if val is None and r.get('totalQuantity')==0 and re.search(r'over|more than|at least|stacks|ore|herbs|seeds|prospect|milled',txt,re.I)and not sel:val=0.;der='0 / positive but unknown processed-input denominator = 0';unit='input';zero=True
   zero = val == 0 if val is not None else False
   removed=bool(re.search(r'beta-only|beta.*(?:8885|8905)|(?:removed|replaced).*patch 3\.0\.2|Fel Iron Powder',txt,re.I))or r.get('outputItemID')==24242
   alias=bool(re.search(r'zen mystic sapphire|brill draenite|brilliant.*draenite',str(r.get('outputName')or''),re.I))
   cz=val==0 and(r.get('outputItemID')==242608 or'eversong diamond'in str(r.get('outputName')or'').casefold())and not re.search(r'unlock:\s*yes|full Prospecting|Max Prospecting',str(r.get('specialization')or''),re.I)
   pre=s['index']in(2,3,4,48,50,53,55,56);ep=pre and(r.get('outputItemID')in(213398,213399,212498)or str(r.get('outputName')or'')in('Glittering Glass','Handful of Pebbles'))
   ok=not ins['kind'].startswith('unresolved')and not outs['kind'].startswith('unresolved')
   if val is not None:
    if removed:dec='REJECT_CURRENT_NUMERICAL_USE_RETAIN_HISTORICAL';why='Explicit transient beta/removed-output mechanics are not a current Retail outcome rate.'
    elif alias:dec='REJECT_CURRENT_IDENTITY_ALIAS';why='Source label is a crafted cut or ambiguous gem; raw-family equivalence is unverified.'
    elif cz:dec='RETAIN_CONDITIONAL_ZERO_CONTEXT_ONLY';why='Absence does not establish source unlock eligibility; zero cannot calibrate the unlocked outcome.'
    elif ep:dec='USE_HISTORICAL_COMPOSITION_CALIBRATION';why='Known 2024-10-25 byproduct/Amber-perk change prevents direct old mean transfer; use composition only with a current pool constraint.'
    elif not ok:dec='RETAIN_NUMERICAL_SCENARIO_REJECT_ITEM_ATTRIBUTION';why='Ratio is valid in source units, but input/output identity or legal pool is unresolved for an item quote.'
    else:dec='USE_BASELINE_QUANTITY_PRIOR';why='Supported source mean in stated units. Unknown casts/profile do not erase quantities; preserve source context and independently verified current action eligibility.'
    q=dict(decision=dec,value=val,unit=unit,formula=der,sourceDenominator=den,denominatorProof=proof,modelConfidence0to100=0,sourceSupportMaximum=5 if zero else 20,zeroSampleSizeUnknown=zero and obs is None,reason=why)
    row['fields']['expectedQuantity']=q;counts[dec]+=1
    if dec in('USE_BASELINE_QUANTITY_PRIOR','USE_HISTORICAL_COMPOSITION_CALIBRATION','RETAIN_NUMERICAL_SCENARIO_REJECT_ITEM_ATTRIBUTION'):
     pp=dict(proposalID=g['groupID']+':'+r['id'],sourceKey=s['sourceKey'],sourceStudyKey=r.get('studyKey'),sourceLocator=e['locator'],sourceRawSHA256=e['candidate']['rawSHA256'],inputIdentity=ins,outputIdentity=outs,method=r.get('method'),quantity=q,sourceQuantityBasis='net-input'if s['index']==39 else('reported-input-budget'if unit=='input'else'reported-operation'),sourceProfile=profile(r),reportedSourceCasts=obs,compiledObservedSamplesAdded=0,admissionDecision=dec,sourceNotes=r.get('notes'))
     if s['index']==39:pp['normalizationFormula']='q_gross=q_net*SOURCE inputFactor; inverse SOURCE outputFactor; project TARGET factors once.'
     if zero:pp.update(gapOnly=True,absenceProof=r.get('quote')or r.get('notes'),mustNotSuppressKnownPositiveSources=True)
     proposals.append(pp);row['proposalID']=pp['proposalID']
   else:row['fields']['expectedQuantity']=dict(decision='REJECT_CURRENT_NUMERICAL_MEAN',reason='Selected positive event establishes conditional yield, not unconditional units.'if sel else'Total '+str(r.get('totalQuantity'))+' lacks a processed-input denominator, a valid all-attempt operation count or a stated average; output units do not supply those missing units.',recheckTrigger='Original processed input amount or explicit average for this same cohort.')
   hits=r.get('castsWithDrop');p=r.get('percentShown');sem=r.get('percentMeaning')
   if obs and isinstance(hits,(int,float))and 0<=hits<=obs:row['fields']['dropChance']=dict(decision='USE_REPORTED_HIT_FREQUENCY_IN_SOURCE_CONTEXT',value=hits/obs,formula=f'{hits} / {obs}',hits=hits,reportedCasts=obs,currentContextGate='Same eligibility/epoch/input scope only')
   elif p is not None and sem=='perCast'and 0<=p<=100:row['fields']['dropChance']=dict(decision='USE_REFERENCE_PROBABILITY_ONLY',value=p/100,formula=f'{p} / 100',observedHits=None,reason='Occurrence per operation is source-labeled; no unknown hits or conditional yield invented.')
   else:row['fields']['dropChance']=dict(decision='REJECT_PROBABILITY_INFERENCE',reason='Output-unit percentages, colour shares, aggregate totals or unstated hit events are not per-operation occurrence.')
   if r.get('minSeen')is not None or r.get('maxSeen')is not None:row['fields']['conditionalYieldRange']=dict(decision='RETAIN_SOURCE_RANGE_CONTEXT',minimum=r.get('minSeen'),maximum=r.get('maxSeen'),reason='Retain per-positive/per-mill semantics; selected/positive-only events are not a complete population distribution.')
   else:row['fields']['conditionalYieldRange']=dict(decision='REJECT_RANGE_INFERENCE',reason='Aggregate totals or averages do not establish per-cast extrema.')
   row['recheckTrigger']='New source-specific unit/identity/native-recipe fact resolving this exact rejected field; access failure alone is not a scientific rejection.'
   gr['rowDecisions'].append(row)
  sr['cohorts'].append(gr)
 reviews.append(sr)
coverage=dict(sourceKeys=len(reviews),candidateRows=sum(s['candidateRows']for s in reviews),uniqueLocators=len({r['locator']for s in reviews for g in s['cohorts']for r in g['rowDecisions']}),effectiveRowsUniquelyResolved=2845,profileCohortGroups=sum(len(s['cohorts'])for s in reviews))
assert coverage['sourceKeys']==224 and coverage['candidateRows']==coverage['uniqueLocators']==2845
review=dict(schemaVersion=1,lane='processing',reviewStatus='SCIENTIFIC_FIELD_REVIEW_COMPLETE_IMPLEMENTATION_AND_CROSS_REVIEW_PENDING',inputSnapshot=I['researchSnapshot'],reviewedResearchHead='0cd0bad8867e7a8d909b4ecae74f6136a3e23d42',currentCorrectionsApplied=True,coverageProof=coverage,nativeIdentityReceipts={p.name:hashlib.sha256(p.read_bytes()).hexdigest()for p in(sp,ip,qp)},quantityDecisionCounts=dict(counts),sources=reviews,accessLog=dict(newOriginalFetches=0,reason='Existing current corrections, primary transcriptions, retained reviews and immutable archives supply field facts. No fetch failure treated as scientific rejection.'))
(D/'processing-review.json').write_text(json.dumps(review,ensure_ascii=False,indent=1),encoding='utf-8')
prop=dict(schemaVersion=1,lane='processing',status='QUANTITY_PASS_COMPLETE_COMPOSITION_AND_ALIAS_REVIEW_IN_PROGRESS',researchHead=review['reviewedResearchHead'],proposals=proposals,contracts=dict(unknownOperationCounts='Never derive sample strength from inputs/batch; source casts retained separately.',netConsumedMeans='q_gross=q_net*SOURCE inputFactor; then inverse source outputFactor and target factors once.',sourceProfiles='Retain known invested profiles, stats and unresolved nodes; never call these observed zero baselines.',zeroPrior='Complete absence only; gap-only support<=5/modelconfidence0; no probability/histogram or suppression of known positive means.',epoch='Known changed mechanics require current constraints or historical scope.',identity='Exact native ID or verified named-family pool; no duplicated units per member.',labels='Confidence-only user uncertainty; internal assumptions retained.'))
(D/'processing-proposals.json').write_text(json.dumps(prop,ensure_ascii=False,indent=1),encoding='utf-8')
print(coverage);print('quantity decisions',dict(counts),'proposals',len(proposals),'verified archives',len(cache))

```
