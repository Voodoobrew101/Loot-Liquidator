# Processing final scientific adjudications

Run after the two preceding lane reproducers. Writes only lane-owned review, proposals and notes. Adds explicit modeled stack priors, source coefficient arithmetic, selected-batch/overlap constraints and source-profile interpretations. Does not edit original evidence or runtime.

```python
import json,re,hashlib,collections
from pathlib import Path
W=Path('D:/My Documents/ChatGPT/Loot Liquidator');R=W/'catalogue-backlog-research-20261120';D=R/'research/v3/evidence/master/backlog-catalogue-20261120'
review=json.load(open(D/'processing-review.json',encoding='utf-8'));prop=json.load(open(D/'processing-proposals.json',encoding='utf-8'));idx=json.load(open(D/'processing-evidence-index.json',encoding='utf-8'));nm=json.load(open(D/'processing-native-identities.json',encoding='utf-8'))
entries={e['locator']:e for s in idx for g in s['groups']for e in g['rows']};rows={r['locator']:r for s in review['sources']for g in s['cohorts']for r in g['rowDecisions']};groups={g['cohortID']:g for s in review['sources']for g in s['cohorts']};sources={s['sourceIndex']:s for s in review['sources']};prop['proposals']=[p for p in prop['proposals']if not p.get('finalAdjudicationAdded')]
pp={p['sourceLocator']:p for p in prop['proposals']}
def attach(si,g,row,value,formula,decision='USE_BASELINE_QUANTITY_PRIOR',support=5,assumptions=None,basis='reported-input-budget'):
 r=entries[row['locator']]['effective'];q=dict(decision=decision,value=value,unit='input',formula=formula,sourceDenominator=None,modelConfidence0to100=0,sourceSupportMaximum=support,reason='Source-supported quantity with explicit unit/model assumptions; no completed-cast inference.',assumptions=assumptions or[])
 p=dict(proposalID=g['cohortID']+':'+r['id']+':adjudicated',sourceKey=sources[si]['sourceKey'],sourceStudyKey=r.get('studyKey'),sourceLocator=row['locator'],sourceFile=row['currentPhysicalSourcePath'],sourceRawSHA256=row['currentPhysicalRowSHA256'],sourceEffectiveSHA256=row['effectiveSHA256'],sourceBacklogRawSHA256=row['backlogRawSHA256'],inputIdentity=row['inputIdentity'],outputIdentity=row['outputIdentity'],method=r.get('method'),quantity=q,sourceQuantityBasis=basis,sourceProfile=g['sourceProfile'],reportedSourceCasts=row['castDenominator']['observedCount'],compiledObservedSamplesAdded=0,admissionDecision=decision,sourceNotes=r.get('notes'),finalAdjudicationAdded=True)
 ids=p['inputIdentity'].get('itemIDs',[]);era={nm['items'][str(i)]['expansionID']for i in ids if str(i)in nm['items']};p['canonicalExpansionID']=next(iter(era))if len(era)==1 else None
 if not ids or not p['outputIdentity'].get('itemIDs'):p.update(admissionDecision='RETAIN_NUMERICAL_SCENARIO_REJECT_ITEM_ATTRIBUTION',currentItemNumericalDecision='REJECT_CURRENT_ITEM_QUOTE',rejectionReason='Valid scenario ratio lacks one attributable input or verified output family.',recheckTrigger='Exact source/native identity or scenario route; never guess a per-item attribution.')
 prop['proposals'].append(p);pp[row['locator']]=p;row['modeledQuantityProposalID']=p['proposalID'];row['fields']['modeledQuantity']=q
 return p
# Clarify skill and stat semantics; do not equate a profession-bar number with effective operation skill.
for gid in('p032-011','p102-002','p203-000'):
 for row in groups[gid]['rowDecisions']:
  n=entries[row['locator']]['effective'].get('casts')
  if n:
   row['castDenominator'].update(decision='RETAIN_REPORTED_OPERATION_COUNT',observedCount=n,reason='Source explicitly reports completed operations; nearby nominal-input comparison or words denying nominal arithmetic do not negate this count.')
   if row['locator']in pp:pp[row['locator']]['reportedSourceCasts']=n
for si,s in sources.items():
 for g in s['cohorts']:
  for profile in [g['sourceProfile']]+[pp[x['locator']]['sourceProfile']for x in g['rowDecisions']if x['locator']in pp]:
   raw=profile['raw'];sk=str(raw.get('skill')or'');text=' '.join(str(raw.get(k)or'')for k in('skill','specialization','stats'))
   profile.pop('effectiveSkill',None);profile.pop('skillIncludesSpecialization',None)
   eff=re.search(r'effective(?:\s+prospecting)?\s+skill\s*(\d+(?:\.\d+)?)',sk,re.I)or re.search(r'(\d+(?:\.\d+)?)\s+effective',sk,re.I)
   if eff:profile.update(effectiveSkill=float(eff[1]),skillIncludesSpecialization=True,skillBasis='Source explicitly describes total effective operation skill.')
   elif si==39 and re.search(r'\b(202|233)/250',sk):profile.update(effectiveSkill=float(re.search(r'\b(202|233)/250',sk)[1]),skillIncludesSpecialization=True,skillBasis='Hochenblume operation skill versus recipe difficulty250; base profession100 separately reported.')
   elif si==33 and '255/265'in sk:profile.update(effectiveSkill=255,skillIncludesSpecialization=True,skillBasis='Author operation skill255 versus recipe difficulty265; source explicitly includes racial, talents and gear.')
   elif re.search(r'(\d+)\+(\d+)',sk):
    z=re.search(r'(\d+)\+(\d+)',sk);profile.update(preSpecializationSkill=int(z[1])+int(z[2]),skillIncludesSpecialization=False,skillBasis='Explicit profession skill plus equipment grant; source specialization retained separately.')
   elif re.search(r'\b(\d+)/100\b',sk):profile.update(preSpecializationSkill=int(re.search(r'\b(\d+)/100\b',sk)[1]),skillIncludesSpecialization=False,skillBasis='Reported profession-bar+equipment skill, not additional tree skill.')
   else:profile['skillBasis']='Reported source skill retained; operation-effective versus profession-bar inclusion unresolved unless explicitly stated.'
   for stat in('resourcefulness','inspiration','multicraft'):
    z=re.search(stat+r'\s*(?:rate)?\s*[=:]?\s*(\d+(?:\.\d+)?)\s*%',text,re.I)
    if not z:z=re.search(r'(\d+(?:\.\d+)?)\s*%\s*'+stat,text,re.I)
    if z:profile.setdefault('stats',{})[stat]={'percent':float(z[1])}
   try:js=json.loads(str(raw.get('stats')))
   except Exception:js={}
   if isinstance(js,dict):
    for stat in('resourcefulness','inspiration','multicraft'):
     for key,val in js.items():
      if re.sub(r'[^a-z]','',key.casefold())in(stat+'pct',stat+'percent')and isinstance(val,(int,float)):profile.setdefault('stats',{})[stat]={'percent':val}
   if profile.get('normalizationConstraint'):profile['sourceSpecializationUnresolvedIsNotZero']=True
# A correct existing Mycobloom per-input source supersedes the old per-cast transcription; no 10x duplicate.
for g in sources[52]['cohorts']:
 for row in g['rowDecisions']:
  p=pp.get(row['locator']);r=entries[row['locator']]['effective']
  if p and g['cohortID']in('p052-002','p052-003'):
   p.update(admissionDecision='REJECT_SUPERSEDED_UNIT_TRANSCRIPTION',currentItemNumericalDecision='REJECT_CURRENT_ITEM_QUOTE',rejectionReason='Same author/source average was mistranscribed per cast. Source example1000herbs→1350pigment resolves it per input; use matching1.15/1.35 per-input representative, not this tenfold-divided alias.',canonicalRepresentativeCohortID='p052-004'if g['cohortID']=='p052-002'else'p052-005')
   row['fields']['expectedQuantity']['decision']='REJECT_SUPERSEDED_UNIT_TRANSCRIPTION';row['fields']['expectedQuantity']['reason']=p['rejectionReason']
  elif p and g['cohortID']in('p052-006','p052-007'):p['independencePolicy']='Reference alternative1.1/1.3 excluding RF; no measured N and not additive to author1.15/1.35 means.'
# Recovered explicit source means despite conflicting completed-operation statement.
for g in sources[192]['cohorts']:
 for row in g['rowDecisions']:
  r=entries[row['locator']]['effective'];v=2.4 if r.get('outputItemID')==61979 else .238
  attach(192,g,row,v/5,f'{v} source stated mean per mill / 5 source recipe inputs',assumptions=['Use the source-stated rounded mean as an independent mean assertion; do not choose84or96 as observed casts.','Historical Cataclysm source; current-transfer is a model assumption, not a measured current cohort.'])
# Preserve mixed-input denominator ambiguity as a quantity interval, without per-item attribution.
scenarios=[]
for si in(1,73,112,168,193,216):
 for g in sources[si]['cohorts']:
  for row in g['rowDecisions']:
   r=entries[row['locator']]['effective'];t=r.get('totalQuantity');p=pp.get(row['locator'])
   if t is None:continue
   if si==112:
    scenarios.append(dict(proposalID=g['cohortID']+':'+r['id']+':denominator-band',sourceLocator=row['locator'],sourceFile=row['currentPhysicalSourcePath'],sourceRawSHA256=row['currentPhysicalRowSHA256'],quantityRangePerInput=[t/1120,t/1080],formula=f'{t}/1120 .. {t}/1080',rangeMeaning='Competing whole-batch input denominators, not per-cast outcome bounds or a confidence interval.',admissionDecision='REJECT_SINGLE_ITEM_MEAN_RETAIN_MIXED_SCENARIO_INTERVAL',modelConfidence0to100=0,sourceSupportMaximum=5,observedSamplesAdded=0))
   elif p:
    p['sourceMixturePolicy']='Single combined mixture scenario only; output total must not be independently assigned to each input.'
    if si==193:p['quantity'].setdefault('assumptions',[]).append('577is gathered stock, not verified consumption; source scenario assumes all relevant stock milled and small remainders ignored.')
    scenarios.append(dict(proposalID=p['proposalID'],sourceLocator=row['locator'],value=p['quantity']['value'],unit='mixed-input budget',admissionDecision='RETAIN_SCENARIO_REJECT_PER_ITEM_ATTRIBUTION',modelConfidence0to100=0,observedSamplesAdded=0))
# Selected Prismatic batch is a real ratio but not a representative unconditional material mean.
for g in sources[32]['cohorts']:
 for row in g['rowDecisions']:
  r=entries[row['locator']]['effective'];text=str(r.get('quote')or'')+' '+str(r.get('notes')or'');p=pp.get(row['locator'])
  if r.get('inputItemID')==194545 and r.get('totalQuantity')==25:
   if not p:p=attach(32,g,row,.025,'25 reported diamonds / 1000 nominal Prismatic Ore',decision='RETAIN_SELECTED_BATCH_RATIO_CONTEXT_ONLY',support=5)
   p.update(admissionDecision='RETAIN_SELECTED_BATCH_RATIO_CONTEXT_ONLY',currentItemNumericalDecision='REJECT_POPULATION_MEAN',rejectionReason='Latest source review identifies a selected high-output historical batch; valid25/1000 ratio alone does not establish representative unconditional expected quantity.',lineagePolicy='Same source commenter and selected1000/25 batch regardless of capture/studyKey; no independent repetitions.')
   row['fields']['expectedQuantity'].update(decision='RETAIN_SELECTED_BATCH_RATIO_CONTEXT_ONLY',reason=p['rejectionReason'])
# Keep accepted-only operation ledgers usable as conditional quantities and RF-return diagnostics, never all-attempt N.
conditional=[]
for g in sources[23]['cohorts']:
 for row in g['rowDecisions']:
  r=entries[row['locator']]['effective'];t=r.get('totalQuantity');z=re.search(r'accepted runCount=(\d+)',str(r.get('notes')))
  if t is not None and z:conditional.append(dict(proposalID=g['cohortID']+':'+r['id']+':accepted-only',sourceLocator=row['locator'],sourceFile=row['currentPhysicalSourcePath'],sourceRawSHA256=row['currentPhysicalRowSHA256'],conditionalUnitsPerAcceptedRun=t/int(z[1]),formula=f'{t}/{z[1]}',acceptedRecords=int(z[1]),actualAllAttempts=None,modelConfidence0to100=0,admissionDecision='RETAIN_ACCEPTED_OUTPUT_CONDITIONAL_MEAN_NOT_UNCONDITIONAL_EV',reason='Recorder rejects noProducedOutputs; no independent proof that zero-output attempts are impossible or completely captured. Native guarantee could close this later.'))
# Explicit historical full-stack priors. The20factor is a model assumption, never a reported item/cast count.
stackmodels=[]
for si,s in sources.items():
 for g in s['cohorts']:
  for row in g['rowDecisions']:
   if row['locator']in pp or row['fields']['expectedQuantity']['decision']!='REJECT_CURRENT_NUMERICAL_MEAN':continue
   r=entries[row['locator']]['effective'];text=str(r.get('quote')or'')+' '+str(r.get('notes')or'');t=r.get('totalQuantity')
   if t is None or not row['inputIdentity'].get('itemIDs')or not row['outputIdentity'].get('itemIDs'):continue
   # Explicit number+stacks, singular stack, or word-number stacks; never parse ore counts as stacks.
   z=re.search(r'(?<![\d.])(\d+(?:\.\d+)?)\s*(?:historical(?:ly sized)?\s*)?(?:20[- ](?:ore|herb)\s*)?stacks?\b',text,re.I)
   word=re.search(r'\b(one|two|three|four|six|eight|ten|eleven|twenty|thirty)\s+(?:historical(?:ly sized)?\s*)?stacks?\b',text,re.I)
   n=float(z[1])if z else {'one':1,'two':2,'three':3,'four':4,'six':6,'eight':8,'ten':10,'eleven':11,'twenty':20,'thirty':30}.get(word[1].lower())if word else 1 if re.search(r'\ba stack\b',text,re.I)else None
   if not n:continue
   ids=row['inputIdentity']['itemIDs'];eras={nm['items'][str(i)]['expansionID']for i in ids if str(i)in nm['items']}
   if not eras or max(eras)>4:continue
   if re.search(r'beta|removed|selected positive|once received|one selected|positive.only|partial.only|denominator conflict',text,re.I):continue
   p=attach(si,g,row,t/(n*20),f'{t} / ({n:g} reported stacks * 20 assumed full historical stack)',support=5,basis='modeled-full-stack-input-budget',assumptions=['Each reported historical stack modeled as full20items; fullness/size was not measured by this source.','Actual input total and completed operations remain unknown; calculated divisor is not a statistical sample.','Current mechanics transfer is a confidence-zero prior; known changed/removed outcomes must retain their epoch gate.'])
   p['modeledNominalInputDenominator']=n*20;stackmodels.append(p['proposalID'])
# Approximate source quantities are usable model priors even where exact totalQuantity is deliberately absent.
wordMeans=[]
for si,gid,lo,hi,den in[(2,'p002-002',1,1,150),(2,'p002-004',5,6,50),(3,'p003-003',1,2,100),(3,'p003-004',1,2,10),(5,'p005-000',15,20,100),(14,'p014-000',5,5,100),(34,'p034-001',1,1,15000),(43,'p043-004',1,1,1000),(63,'p063-000',6,7,300),(63,'p063-001',6,7,100),(108,'p108-000',10,10,10),(138,'p138-006',40,40,5000),(143,'p143-000',80,80,1000)]:
 g=groups[gid]
 for row in g['rowDecisions']:
  if row['locator']in pp:continue
  p=attach(si,g,row,(lo+hi)/2/den,f'({lo}+{hi}) / 2 / {den} source stated inputs',assumptions=['Source approximate quantity/average retained as a confidence-zero mean assertion; rounded numerator and denominator are not fabricated exact measured totals.','A range midpoint is a working uniform prior, not an observed average.']if lo!=hi else['Source rounded/approximate mean retained; no exact measured total or operation count created.'])
  p['sourceReportedQuantityBandPerInput']=[lo/den,hi/den];p['sourceQuantityBandMeaning']='Approximate whole-batch mean/range assertion, not per-cast outcome bounds or confidence interval.'
  if si in(2,3):p['epochPolicy']='Pre-late-October2024 byproduct source; historical composition/context only unless reconciled to current byproduct floor.'
  wordMeans.append(p['proposalID'])
# Unnamed herb ranges are retained as explicit scoped scenarios; never assigned wholesale to each herb.
rangeScenarios=[]
for si in(49,58):
 for g in sources[si]['cohorts']:
  row=g['rowDecisions'][0];r=entries[row['locator']]['effective'];a=r.get('minSeen');b=r.get('maxSeen')
  if a is None or b is None:continue
  batch=r.get('inputsPerCast')or 10
  rangeScenarios.append(dict(proposalID=g['cohortID']+':unnamed-range-scenario',sourceLocator=row['locator'],sourceFile=row['currentPhysicalSourcePath'],sourceRawSHA256=row['currentPhysicalRowSHA256'],sourceReportedRange=[a,b],modeledMeanPerInput=(a+b)/2/batch,formula=f'({a}+{b})/2/{batch}',distributionAssumption='Uniform midpoint of reported per-mill range; native10herb batch is assumed only when source omitted it.',admissionDecision='REJECT_ITEM_ATTRIBUTION_RETAIN_SCOPED_RANGE_MODEL',rejectionReason='Herb/pigment identity and rank are unstated; cannot assert every native herb has this yield.',modelConfidence0to100=0,sourceSupportMaximum=5,observedSamplesAdded=0,epoch='Before/afterAug31ranges remain distinct; source claim alone does not prove official hotfix.'if si==49 else'March2026 source, exact collection build unknown.'))
# A stack-derived number is not measured completed casts, even if older evidence accidentally typed it that way.
row=groups['p028-000']['rowDecisions'][0];row['castDenominator'].update(decision='UNKNOWN_NO_SAMPLE_PROMOTION',observedCount=None,reason='100 is25historical20herb stacks divided by5, not independently counted casts;54proc events are separately reported.');row['fields']['dropChance']=dict(decision='RETAIN_MODELED_NOMINAL_EVENT_RATE',value=.54,formula='54 source procs / (25 assumed full20herb stacks / 5 recipe input units)',observedHits=54,observedCasts=None,reason='Full-stack approximation supplies modeled event frequency, not a measured binomial denominator or sample size.')
eventRates=[dict(proposalID='p028-000:nominal-event-intensity',sourceLocator=row['locator'],sourceFile=row['currentPhysicalSourcePath'],sourceRawSHA256=row['currentPhysicalRowSHA256'],eventsPerModeledInput=.108,formula='54/(25*20)',observedPositiveEvents=54,observedAllAttemptCasts=None,conditionalOutputUnitsUnknown=True,admissionDecision='USE_SCOPED_EVENT_RATE_MODEL_ONLY',modelConfidence0to100=0,sourceSupportMaximum=5)]
# Mean-only unit relations can constrain returns without inventing observed proc counts.
coeff=[]
for si,gid,casts,nominal,saved,pct in[(32,'p032-007',8000,40000,2650,22),(153,'p153-000',800,4000,715,39.6)]:
 g=groups[gid];row=g['rowDecisions'][0]
 coeff.append(dict(proposalID=gid+':resourcefulness-return-calibration',sourceKey=sources[si]['sourceKey'],sourceLocator=row['locator'],sourceFile=row['currentPhysicalSourcePath'],sourceRawSHA256=row['currentPhysicalRowSHA256'],sourceReportedCompletedOperations=casts,sourceNominalInputs=nominal,sourceReturnedInputUnits=saved,sourceResourcefulnessPercent=pct,observedReturnedInputFraction=saved/nominal,conditionalSavedFractionModel=saved/(nominal*pct/100),formula=f'{saved}/({nominal}*{pct}/100)',observedResourcefulnessEvents=None,modelConfidence0to100=0,sourceSupportMaximum=20,admissionDecision='USE_SOURCE_RETURN_FACTOR_CALIBRATION',assumptions=['Displayed chance is stable across source operations; return-per-proc treated as independent of chance for this coefficient.','Only reported operation count retained; casts*chance is an expected value, never an observed proc sample.','Source talent/epoch affects return fraction; do not apply Dragonflight .30 and Midnight .45 identically across all profiles.'],sourceProfile=g['sourceProfile']))
for gid,accepted,events,saved in[('p023-000',254,110,250),('p023-001',255,106,238),('p023-002',251,107,250)]:
 g=groups[gid];row=g['rowDecisions'][0]
 coeff.append(dict(proposalID=gid+':accepted-return-per-proc-calibration',sourceKey=sources[23]['sourceKey'],sourceLocator=row['locator'],sourceFile=row['currentPhysicalSourcePath'],sourceRawSHA256=row['currentPhysicalRowSHA256'],acceptedRecordedRuns=accepted,observedResourcefulnessEventsInAcceptedRuns=events,observedReturnedInputUnits=saved,returnFractionPerAcceptedResourcefulnessProc=saved/(events*5),formula=f'{saved}/({events}*5)',observedAllAttemptCasts=None,modelConfidence0to100=0,sourceSupportMaximum=5,admissionDecision='USE_CONDITIONAL_RETURN_MAGNITUDE_CALIBRATION_ONLY',assumptions=['Counts refer to accepted output-producing records; not independently all-attempt casts.','A return-magnitude coefficient can be modeled from saved units/observed RF events; transferring it beyond accepted records assumes selection does not change RF-return magnitude.','Do not infer RF occurrence probability or one exact source skill from aggregate skillAtCraft totals.'],sourceProfile=g['sourceProfile']))
# Overlap constraints supplement current source-identity dedupe. They are field-specific, not whole-URL bans.
overlaps=[
 dict(sourceIndex=2,cohorts=['p002-000','p002-001','p002-008'],policy='Later415casts/84glass snapshot preferred to200casts/25glass for the same author; possible cumulative overlap, not independent; all remain mixed-ore historical byproduct context.'),
 dict(sourceIndex=33,cohorts=['p033-001','p033-003','p033-004'],policy='Same30kDraconium subset; aliases add no weight, later180k cumulative statement must not be independent.'),
 dict(sourceIndex=37,cohorts=['p037-000','p037-003','p037-005','p037-008'],policy='Prefer exact591/400000 to rounded1.48/1000; later700k cumulative history cannot add independent weight.'),
 dict(sourceIndex=88,cohorts=['p088-001','p088-002','p088-003','p088-004','p088-005','p088-006'],policy='26kaggregate includes6k/10k/10k subbatches. Per-output field uses aggregate OR partition, never both; byproducts10ksubset not a new parallel full26k observation.'),
 dict(sourceIndex=88,cohorts=['p088-000','p088-007'],policy='12koriginal aggregate includes7kpre-reset and5kpost-reset diamond quantities; retain phase contexts instead of counting aggregate and phases independently.'),
 dict(sourceIndex=52,cohorts=['p052-002','p052-003','p052-004','p052-005'],policy='Per-input1.15/1.35 author means supersede old per-cast transcription; no extra author sample or weight.'),
 dict(sourceIndex=123,cohorts=[g['cohortID']for g in sources[123]['cohorts']],policy='Baadkitty200-herb source totals already represented by existing BfA references/aggregates; lineage must replace/annotate, never add a second source copy. Kidneph and Jiyao are separate authors.'),
 dict(sourceIndex=208,cohorts=[g['cohortID']for g in sources[208]['cohorts']],policy='Direct Dreamleaf milling and recursive NightmarePod opening are separate operations; final recursive pigments cannot be assigned again to initial Mill. Same capture aliases add no weight.'),
 dict(sourceIndex=32,cohorts=[g['cohortID']for g in sources[32]['cohorts']if g['cohortID']in('p032-006','p032-012','p032-026','p032-027','p032-028')],policy='One selected1000Prismatic/25diamond batch across captures; context-only quantity, no repeated population prior.')]
for o in overlaps:
 for gid in o['cohorts']:
  if gid in groups:groups[gid]['lineageConstraint']=o['policy']
  for p in prop['proposals']:
   if p['proposalID'].startswith(gid+':'):p['lineageConstraint']=o['policy']
# Preserve cross-species source output composition even without a known input denominator. It scales a separately calibrated pool only.
composition=[]
for si,s in sources.items():
 for g in s['cohorts']:
  outcomes={}
  for row in g['rowDecisions']:
   r=entries[row['locator']]['effective'];t=r.get('totalQuantity');ids=tuple(sorted(row['outputIdentity'].get('itemIDs',[])))
   if t is not None and t>=0 and ids and row['fields']['expectedQuantity']['decision']not in('REJECT_SUPERSEDED_UNIT_TRANSCRIPTION',):outcomes.setdefault(ids,dict(itemIDs=list(ids),units=t,sourceLocator=row['locator']))
  if len(outcomes)<2:continue
  den=sum(x['units']for x in outcomes.values())
  if den<=0:continue
  composition.append(dict(proposalID=g['cohortID']+':reported-output-composition',sourceKey=s['sourceKey'],sourceStudyKey=g['sourceStudyKey'],cohortID=g['cohortID'],reportedMaterialUnits=den,outcomes=[dict(x,share=x['units']/den)for x in outcomes.values()],scope='Conditional composition across explicitly reported output fields only; missing fields/ranks/species are not zero.',sampleCount=None,modelConfidence0to100=0,sourceSupportMaximum=5,admissionDecision='USE_SCOPED_COMPOSITION_CALIBRATION_ONLY',formula='reported named output units / sum of deduplicated reported output units',useConstraint='May allocate a separately verified/modelled total pool within matching rarity/quality/recipe scope; never infer an absolute mean, hit probability, complete loot table or extra source N from this denominator.'))
row=groups['p134-000']['rowDecisions'][0]
composition.append(dict(proposalID='p134-000:amber-colour-share',sourceLocator=row['locator'],sourceFile=row['currentPhysicalSourcePath'],sourceRawSHA256=row['currentPhysicalRowSHA256'],outputIdentity=row['outputIdentity'],reportedOutputUnitShare=.72,sourceReportedCasts=100,outputUnitDenominatorUnknown=True,admissionDecision='USE_SCOPED_UNIT_COMPOSITION_CALIBRATION_ONLY',modelConfidence0to100=0,sourceSupportMaximum=5,reason='Source explicitly describes72%ofgemcolour; no per-cast hit chance, exact72units or physical unit denominator invented. Rank and source skill basis unresolved.'))
# Apply current identity dedupe to newly modeled aliases too.
import sys
sys.path.insert(0,str(W/'catalogue-backlog-pipeline-20261120/tools'));import research_v3_to_baselines as bridge
calc=bridge.load_calculator(R);loaded=calc.load();vec,_,_=calc.study_vectors(loaded);loadedByID={(r.get('_file'),r.get('id')):r for r in loaded};aliases=collections.defaultdict(list)
for p in prop['proposals']:
 e=entries[p['sourceLocator']];r=loadedByID[(e['candidate']['sourceFile'],e['effective']['id'])]
 try:key=calc.study_identity(r,vec)
 except KeyError:key=('unplaced-or-reference-source-key',p['sourceKey'],p['sourceStudyKey'])
 p['sourceIdentityKey']=json.dumps(key,sort_keys=True,ensure_ascii=False);aliases[(p['sourceIdentityKey'],tuple(sorted(p['inputIdentity'].get('itemIDs',[]))),tuple(sorted(p['outputIdentity'].get('itemIDs',[]))),p['quantity']['unit'],p['quantity']['value'])].append(p)
aliasReceipts=[]
for aa in aliases.values():
 if len(aa)<2:continue
 canonical=max(aa,key=lambda p:(p['admissionDecision']=='USE_BASELINE_QUANTITY_PRIOR',bool(p['sourceProfile'].get('effectiveSkill')),len(str(p['sourceProfile']))))
 for p in aa:
  p['canonicalRepresentativeProposalID']=canonical['proposalID']
  if p is not canonical:p['aliasPolicy']='Same current source identity and exact same normalized field; no independent weight added.'
 aliasReceipts.append(dict(representative=canonical['proposalID'],members=[p['proposalID']for p in aa],reason='Current identity plus same canonical input/output/unit/quantity, including full-stack model aliases.'))
prop.update(mixedInputScenarioProposals=scenarios,acceptedRecordConditionalProposals=conditional,resourcefulnessCoefficientProposals=coeff,modeledHistoricalStackProposalIDs=stackmodels,lineageOverlapConstraints=overlaps,reportedOutputCompositionProposals=composition,sourceWordMeanProposalIDs=wordMeans,unnamedRangeScenarioProposals=rangeScenarios,nominalEventRateProposals=eventRates,canonicalAliasReceipts=aliasReceipts,sourceProfilePolicy='Typed operation-effective values require explicit source wording/recipe difficulty context. Profession-bar+gear totals are pre-specialization; all other numeric skill basis retained unknown. Raw stats and unreported nodes stay intact; character Inspiration alone is not method capability proof.')
review['quantityDecisionCounts']=dict(collections.Counter(r['fields']['expectedQuantity']['decision']for r in rows.values()))
review['coverageProof'].update(modeledHistoricalStackPriors=len(stackmodels),mixedInputScenarioFields=len(scenarios),resourcefulnessCoefficientProposals=len(coeff),acceptedRecordConditionalFields=len(conditional),outputCompositionProposals=len(composition),sourceWordMeanPriors=len(wordMeans),unnamedRangeScenarios=len(rangeScenarios),currentIdentityAliasGroups=len(aliasReceipts),allRowsHaveExpectedQuantityDecision=all(r['fields']['expectedQuantity'].get('decision')for r in rows.values()))
assert len(sources)==224 and len(rows)==2845 and not review['coverageProof']['physicalPinErrors']
assert all(p.get('compiledObservedSamplesAdded')==0 for p in prop['proposals'])
assert all(p['quantity'].get('sourceSupportMaximum',20)<=20 for p in prop['proposals'])
assert all(p['quantity'].get('modelConfidence0to100')==0 for p in prop['proposals'])
prop['status']='SCIENTIFIC_REVIEW_COMPLETE_IMPLEMENTATION_AND_PARENT_CROSS_REVIEW_PENDING'
for s in review['sources']:
 rr=[r for g in s['cohorts']for r in g['rowDecisions']];sp=[p for p in prop['proposals']if p['sourceKey']==s['sourceKey']]
 s['terminalFieldSummary']=dict(quantityDecisions=dict(collections.Counter(r['fields']['expectedQuantity']['decision']for r in rr)),probabilityDecisions=dict(collections.Counter(r['fields']['dropChance']['decision']for r in rr)),rangeDecisions=dict(collections.Counter(r['fields']['conditionalYieldRange']['decision']for r in rr)),proposalFields=len(sp),baselineMeanFields=sum(p['admissionDecision']=='USE_BASELINE_QUANTITY_PRIOR'for p in sp),historicalCompositionFields=sum(p['admissionDecision']=='USE_HISTORICAL_COMPOSITION_CALIBRATION'for p in sp),modeledQuantityFields=sum('modeledQuantity'in r['fields']for r in rr),recheckPolicy='Rejected current field is revisited when its exact unit/identity/eligibility/source-profile/epoch/lineage gap is resolved; no fetch-failure rejection and no requirement for new game collection.')
(D/'processing-review.json').write_text(json.dumps(review,ensure_ascii=False,indent=1),encoding='utf-8');(D/'processing-proposals.json').write_text(json.dumps(prop,ensure_ascii=False,indent=1),encoding='utf-8')
notes='''# Processing backlog scientific review — 2026-11-20

All 224 processing source keys and 2,845 candidate rows have field-level terminal decisions against current research head 0cd0bad8867e7a8d909b4ecae74f6136a3e23d42. The original backlog pin remains e8327f30b82a16a19e6df43820277383085bcd3a. This is a research catalogue and implementation handoff; it does not claim every proposal is already compiled or displayed in game. Root owns producer changes, source-to-baseline checks and tooltip verification.

## Files and reproducibility

- `processing-review.json`: every original source key, source/profile cohort, row locator, current physical row hash, effective corrected hash, original backlog hash, numerical-field decision and recheck trigger. Existing source-specific master reviews are retained under `existingReviewReceipts`.
- `processing-proposals.json`: executable-quantity candidates and aliases, plus quality shares, output compositions, historical range/full-stack model priors, source-return coefficient calibrations and mixed-input/selected-event context. An entry is a field proposal, not an independent study or a new observed sample.
- `processing-native-identities.json`: compact pinned70961 input/output names, expansion and actual crafting-quality joins. Numeric item order is not rank order. The authoritative cached CSVs are `.validation/de-formula-data/ItemSparse-70961.csv`, `Item-70961.csv`, and `CraftingQuality-70961.csv` in the workspace root. Their exact fingerprints are embedded in the JSONs.
- `processing-evidence-index.json` and `processing-source-digest.md`: lane-only evidence inspection aids. Original rows and immutable archives remain authoritative. These aids do not add evidence or override correction rules.
- Run embedded Python in `processing-review-reproducer.md`, `processing-finalization-reproducer.md`, then `processing-adjudication-reproducer.md` in that order. They write only these lane files. All proposals require parent cross-review and field-specific admission; one numerical alias must not add a second source weight.

## Quantities, observations and source normalization

Unknown completed casts do not make a stated mean unusable. Per-input source totals, author means, unit percentages, legal family pools and modeled distribution means are retained with model/display confidence0. Ordinary source reliability is capped20, assumption-heavy/full-stack/range/composition priors5. Reported input budget is a unit denominator, never an operation count. No proposal manufactures hits, zero bins, sample size or conditional stack counts. Explicit completed operations are retained separately as source facts; even a real count is not silently attributed to another profile or author.

For known net-consumption means, canonical gross-input quantity is `q_net * SOURCE inputFactor`, then inverse SOURCE outputFactor; target effects are applied once. Source39 Hochenblume describes re-milling refunds:1063/1500 and202/1500 for R1;6050/8998 and1418/8998 for R2 (9000started,2left). RF35%, effective operation skill202/233,100profession and full RuneMastery remain source conditions. Typed unreported node allocations remain unknown. Effective operation skill is distinguished from profession-bar+equipment or unresolved source Skill numbers. A maxed source is never called an observed zero-investment baseline. Character Inspiration alone does not establish that Mill/Prospect has Inspiration capability.

Full historical stacks are modeled as20inputs only where a source supplies stack count, a named legal input and actual output totals. Fullness/size are explicit confidence-zero assumptions; modeled nominal denominator is separate from any observed input total. These priors add zero observed samples. Ambiguous '50obsidium' without a unit is not automatically a stack or prospect. Incomplete/positive-only output logs are not completed by inventing zeros. A q=0 prior is gap-only and support≤5, never P=0 or evidence against a known positive current source. Missing conditional unlock means zero is context only.

## Important source adjudications

1. **Reikah / TWW pre-change prospecting:**9000R1Ironclaw is explicit for first character (139profession+equipment/0Prospect KP),951Pebbles358Glass1089pooled gems. Second character's1030Pebbles335Glass202Crushed1504pooledgems has no unambiguous individual consumed budget; no reuse of9000or10000 as observed denominator. Known late-October2024 byproduct/gem/perk changes prevent direct unscoped current byproduct means. Preserve composition and current-pool constraints separately; one pool total is never copied to every gem.
2. **Xenastro workbook:** Quantity and OreRefund columns support nominal per-input quantities and source refund facts; no fractional/nominal cast equivalents become observed casts. Extra restored rows have26000/22000Serevite,1000Khaz'gorite,9000/6090/13000Serevite budgets. Native quality joins now resolve formerly unverified IDs. Refund reuse remains unknown. Stated Skill/Inspiration/RF retain source semantics, no guessed point allocation.
3. **Dragonflight Serevite true8000prospect cohort:**40000nominalR3ore,2650ore saved, RF22%,283reportedskill. Return fraction2650/40000=.06625; conditional return model2650/(40000*.22)=.301136. No1760expectedproc count becomes an observed count. Same cohort's repeated captures are aliases.
4. **Midnight Cardinalai:**800reported completed prospects,4000nominalBrilliantSilver,3285used715saved, RF39.6%, maxedknowledge. Model715/(4000*.396)=.451389 conditional return fraction; source-specific talent/epoch, not universal all-era coefficient. PocketCFO accepted-record RF magnitude calibrations give250/(110*5),238/(106*5),250/(107*5), but no all-attempt denominator or exact individual source skill.
5. **KingOfKingz and Riverbud archive recovery:** native era4Pandaria replaces old archive's editorial era5; source numbers untouched. Twelve KingOfKingz means: Shadow/Misty per five-herb operation2.47/.27(72234),2.51/.28(72235),2.52/.28(72237),2.51/.27(79010),3.11/.59(79011),2.35/.30(89639); actual stated operation counts1146/412/332/329/46/23 retained. Rounded means do not determine integer output totals. Jiyao Riverbud source39massoperations/780inputs means16.03/6.79/2.10pigments per20sourceinputs. Hash-verified immutable archive fields were omitted by old scalar importer; now proposed explicitly.
6. **Mycobloom:** source1.15/1.35R2pigment is per herb, clarified by source1000herbs→1350pigment example. Older per-cast transcription is rejected, not a second10x-lower prior. Independent1.1/1.3 base-return reply is a reference alternative without measured N, not additive observed support. Existing reviewed Myco bridge should remain unchanged.
7. **Mixed batches:**480Elementium+Obsidium source input,1000DeathBlossom+RisingGlory,287Icecap+MountainSilversage,577Whiptail+Cinderbloom and700Leystone+Felslate support scenario ratios only. They do not identify individual input yields. The1120vs1080Legion denominator conflict is retained as a competing-denominator quantity band, not a confidence interval or cast range.577is gathered stock; processing all stock is an explicit scenario assumption.
8. **Source epochs and changed mechanics:** pre/post2026-03-31Midnight gem reports stay separate; the official increase has no supplied numeric multiplier. Alleged Aug31TWW herb changes remain author context, not an official measured coefficient. Historical removed FelIronPowder or transient beta pigments do not become current outputs. Historical live source on a PTR/Classic mirror URL is classified by its actual source context, not hostname alone (e.g. Retail12.0.5Titanium1000→143Powder).
9. **Native identities:** exact native family/rank joins recover KypariteSparklingShard90407 totals303/1000,219/690,161/500; raw MysticSapphire192840/1/2 is not crafted ZenMysticSapphire192903/4/5. The six unresolved Zen aliases remain rejected for current item attribution; other valid Bugy named output families are retained. Named pools carry one pooled quantity, no per-species observed allocation. CrystallineGlass R2 is242786; SanguithornPigment R2 is245864 despite reversed numeric ordering.
10. **Lineage:** later415cast/84Glass snapshot may encompass earlier200cast/25Glass; prefer later per-field rather than sum. Draconium30k is a subset of later180k. Exact591diamonds/400kSerevite supersedes rounded1.48/1000 and overlaps later700k.26kaggregate includes6k/10k/10k subbatches;12kaggregate includes7kpre/5kpost. Baadkitty historical200-herb source must not acquire another weight through existing BfA references; Kidneph/Jiyao separate authors remain separate. Direct Dreamleaf Mill cannot also receive recursive NightmarePod-opening pigments. Selected25diamonds/1000PrismaticOre is a real selected batch ratio, context-only, not repeated representative means across captures.
11. **Ranges, probabilities and composition:** Argentleaf min2/max15/mode12 supports declared triangular mean29/3per10herbs=.9666667/input; mode is not a measured mean. Luredrop11–17supports uniform midpoint14per10=1.4/input. Unnamed ranges retain scoped scenarios but fail per-item identity. Per-colour or per-rank output-unit shares never become hit probability. The72%Amber colour report can constrain a separately calibrated gem pool only. PocketCFO accepted output-producing254/255/251records support conditional means, not unconditional all-attemptN. Source28Whiptail100casts was25stacks arithmetic;54reported positive events retained separately.
12. **Probability-only guide rows:** preserve their quoted chances and exact provenance. A guide chance without conditional material quantity is not a new EV. No TBC guessed guide chance was turned into a material mean or sample count. Source support68 inherited from old nominal casts is not reinstated by this catalogue.

## Screenshot inputs prioritized in the owner handoff

- BrilliantSilverOreR2 **237365**: Stormwarning source66startingore gives11DuskStoneR2(242789),16CrystallineGlassR2(242786),1EversongDiamondR2(242712),4SanguineGarnet(242723),4FlawlessSanguine(242724),4AmaniLapis(242722),1FlawlessAmani(242727).66is starting stock; full processing/remainder assumption is explicit0confidence. Separate no-KP/no-tool Killersmark report gives8Glass/50R2Silver=.16/input, rank composition unknown. No13.2or10fake casts.
- ArgentleafR2 **236777**: named family model above uses236776/236777 and pigment245803/245804; pooled total, no invented rank split. Later1335pigment line does not independently state its input count, so it is not silently1335/1000.
- SanguithornR1 **236770**: Kyzenbka source1000herbs→1286pigment=1.286/input; current native R2pigment245864. The old archive/capture adds no independent weight. Input-rank/source-skill ambiguity in other captures is retained, not resolved from Russian 'level1' alone.

## Coverage and implementation boundary

The following table is the exhaustive224-key field/cohort ledger. Mean/model counts are proposed row fields, not observations, independent studies or completed builds. `Q` counts baseline quantity proposals, `H` historical composition, `M` explicit modeled-quantity additions; `R` counts row fields that still reject an empirical current mean. A rejected empirical field can coexist with a separately accepted assumption-based model. Full row reasons and original quotations are in the JSON/index. Every rejection has an exact unit/identity/context/epoch/lineage gap and a recheck trigger; missing fetch access is never the reason.

| Index | Source key | Rows / cohorts | Q / H / M / R | One concrete source field or retained constraint |
|---:|---|---:|---:|---|
'''
for si,s in sources.items():
 rr=[r for g in s['cohorts']for r in g['rowDecisions']];summary=s['terminalFieldSummary'];sample=next((r for r in rr if r['fields']['expectedQuantity'].get('value')is not None),rr[0]);q=sample['fields']['expectedQuantity'];inp=sample['inputIdentity'].get('sourceName')or sample['inputIdentity'].get('nativeName')or str(sample['sourceFacts'].get('inputItemID')or'input unspecified');out=sample['outputIdentity'].get('sourceName')or sample['outputIdentity'].get('nativeName')or str(sample['sourceFacts'].get('outputItemID')or'output unspecified');desc=(f"{inp} → {out}: {q.get('formula')} = {q['value']:.7g}/{q.get('unit')}"if q.get('value')is not None else f"{inp} → {out}: "+q['reason'])
 reject=sum(r['fields']['expectedQuantity']['decision'].startswith('REJECT')for r in rr);clean=lambda x:str(x).replace('|','/').replace('\n',' ')
 notes+=f"| {si} | {clean(s['sourceKey'])} | {len(rr)} / {len(s['cohorts'])} | {summary['baselineMeanFields']} / {summary['historicalCompositionFields']} / {summary['modeledQuantityFields']} / {reject} | {clean(desc)} |\n"
notes+='\nCoverage proof: `'+json.dumps(review['coverageProof'],sort_keys=True)+'`.\n\nNo source evidence, correction file, shared producer/runtime file, count, baseline artifact, commit, PR or installation was changed by this lane. Parent implementation and actual source-weighted tooltip verification remain required.\n'
(D/'processing-notes.md').write_text(notes,encoding='utf-8')
print(review['coverageProof']);print('proposals',len(prop['proposals']),'composition',len(composition),'stackmodels',len(stackmodels),'coefficients',len(coeff))
```
