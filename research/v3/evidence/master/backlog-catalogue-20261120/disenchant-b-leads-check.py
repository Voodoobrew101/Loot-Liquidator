"""Focused invariants for the reviewed DE-B source contract, no source writes."""
import collections, hashlib, json, pathlib
P=pathlib.Path(__file__).resolve().parent
def load(name):return json.loads((P/('disenchant-b-leads-'+name)).read_text(encoding='utf-8'))
r=load('review.json'); p=load('proposals.json'); a=load('current-addendum-review.json'); ap=load('current-addendum-proposals.json')
checks=0
def check(ok,why):
 global checks
 assert ok,why
 checks+=1
rows=[x for s in r['sources'] for x in s['rows']]
byid={x['recordID']:x for x in rows}
props=collections.defaultdict(list)
for x in p['fieldProposals']:props[x['recordID']].append(x)
check(len(r['sources'])==249,'249 original source units')
check(len({x['proposalID'] for x in p['fieldProposals']})==len(p['fieldProposals']),'same raw total and rounded mean cannot create duplicate weighted proposals')
check(len(rows)==len({x['locator'] for x in rows})==1249,'1249 unique frozen locators')
check(set(r['receipt']['coveredLocators'])=={x['locator'] for x in rows},'receipt exact locator equality')
check(sum(s['leadDecision'] is not None for s in r['sources'])==35,'35 assessed explicit leads')
check(all(s['reviewStatus']=='REVIEWED_CURRENT_BASELINE_PIPELINE' for s in r['sources']),'no source remains generic pending')
for s in r['sources']:
 if s['leadDecision']:
  check(s['leadDecision']['readExistingPublishedInformation'] and s['leadDecision']['inspection'] and s['leadDecision']['facts'],'lead has actual source-fact/retrieval disposition')
rawfiles={}
for x in rows+[x for s in a['sources'] for x in s['rows']]:
 path,line=x['locator'].rsplit(':',1)
 if path not in rawfiles:rawfiles[path]=(P.parents[4]/path).read_text(encoding='utf-8').splitlines()
 raw=json.loads(rawfiles[path][int(line)-1])
 digest=hashlib.sha256(json.dumps(raw,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
 check(raw['id']==x['recordID'] and digest==x['frozenRawSHA256'],'every locator still resolves exact unchanged original raw row')
for x in p['fieldProposals']+ap['fieldProposals']:
 check(x['empiricalSamples']==x['modelConfidenceCap']==0 and x['sourceSupportMaximum']<=20,'model prior cannot fabricate N or confidence')
 f=x['field']
 if f['field']=='conditionalQuantity':
  check(f['basis']=='Q/H' and f['notActualCastDenominator'] and f['denominatorMeaning']=='recorded-material-positive-events','positive-event quantity is distinct from unconditional output')
  check(abs(f['value']*f['denominator']-f['numerator'])<1e-8,'Q/H arithmetic')
 if f['field']=='dropChance':
  check(0<=f['value']<=1 and x['material']['outputItemID'] is not None,'no rank-unknown row counter promoted')
  check(not any(y['field']=='expectedQuantity' and y['basis']==f['basis'] for y in [f]),'chance is not an amount')
 if x.get('scope',{}).get('exactNativeItemSignature'):
  check(':' in x['scope']['exactNativeItemSignature'],'native exact variant retained')
# A real fixed-positive-stack website reference supports Q/N, not a made-up 100%.
void=[x for x in p['fieldProposals'] if x['scope']['inputItemID']==250059 and x['material']['outputItemID']==243605]
check(any(x['field']['field']=='expectedQuantity' and abs(x['field']['value']-71/134)<1e-12 for x in void),'71 fixed-one Crystal units /134 source operations')
unknown=[x for x in rows if x['scope']['inputItemID']==249962]
check(unknown and all(x['decision']=='REJECTED_CURRENT_NUMERICAL_USE' for x in unknown),'unlinked Dawn Crystal rows cannot be rank assigned')
knife=[x for x in p['fieldProposals'] if x['scope']['inputItemID']==194378]
check(any(x['field']['field']=='dropChance' and abs(x['field']['value']-2/22)<1e-12 for x in knife),'K/N retained even when raw measured H deliberately null')
check(not any(x['field']['field']=='expectedQuantity' for x in knife),'no stack quantity inferred for occurrence-only source')
native=[x for x in p['fieldProposals'] if 'andrew-tiller' in str(x['studyKey'])]
check(native and all(x['field']['field']=='conditionalQuantity' for x in native),'positive native counters do not create cast EV')
sample=[x for x in p['fieldProposals'] if x['scope']['inputItemID']==13856]
check(any(x['field']['field']=='expectedQuantity' and abs(x['field']['value']-20/6)<1e-12 for x in sample),'six directly listed belt outcomes retain mean')
nominal=[x for x in p['fieldProposals'] if x['studyKey']=='wowhead-tbc-souldust-biocyte-1382-azure-silk-cloaks']
check(any(x['field']['field']=='expectedQuantityPerInput' and x['field']['denominator']==1382 for x in nominal),'nominal-input source quantities are not discarded')
check(all(x['sourceReportedCounters']['casts'] is None for x in nominal),'nominal inputs never rewritten as completed casts')
dark=[x for x in p['fieldProposals'] if x['studyKey']=='reddit-1fqb34c-darkmoon-decks-505-20240927']
check(len([x for x in dark if x['field']['field']=='expectedQuantity'])==7,'Epic source keeps all4 extra output materials alongside3 Crystal ranks')
check(all(x['sourceProfile']['specialization'] for x in dark),'maxed source profile not erased')
check(all(not x['currentEffective'] or x['recordID']!='midnight-20261101-004' or 'outcomes.jsonl:4' not in x['locator'] for x in rows),'superseded frozen row not reactivated')
models=p['leadModelProposals']; m={x['proposalID']:x for x in models}
ni=m['deb-lead:nirosu-riverbud-140']
check(ni['inputsPerCast']==20 and ni['sourceReportedCompletedOperations']==140 and ni['sourceInputs']==2800,'Riverbud actual mass batch20 /140 reported operations')
check(abs(ni['materials'][0]['expectedQuantity']-2272/140)<1e-12,'Nirosu source material mean')
emp=[x for x in models if x['sourceKey']=='reddit:6ygegx']
check(len(emp)==7,'six reposted Empyrium arms plus independently read4800input comment')
cam=m['deb-lead:empyrium-camzaman-150']
check(cam['sourceReportedCompletedOperations'] is None and cam['sourceReportedInputs']==3000 and all('expectedQuantityPerReportedInput' in x for x in cam['materials']),'primary purchased-input tally overrides secondary150cast retelling')
check(all('do not sum' in x['overlapPolicy'] for x in emp if x.get('arm','').startswith('op-')),'overlapping same-author arm status not silently erased')
ma=m['deb-lead:empyrium-maiazndrew-389']
check(ma['materials'][-1]['id']==129100 and ma['materials'][-1]['expectedQuantity']==4,'Gem Chip secondary material preserved')
bf=[x for x in models if x['sourceKey']=='reddit:98oyfb']
check(len(bf)==7 and sum(x['sourceReportedCompletedOperations'] for x in bf)==36000 and all(x['neverPromoteToCurrentLiveCapture'] for x in bf),'beta sample segregated from current live evidence')
bags=[x for x in models if x['method']=='Use']
check(len(bags)==7 and sum(x['sourceEpoch']=='beta' for x in bags)==2,'seven bag material vectors /two beta')
check([sum(x['materials'][i]['sourceQuantity'] for x in bags) for i in range(4)]==[423,164,51,9],'all bag materials independently reconcile')
check(all(x['sourceCurrencyCost']=={'currencyID':3258,'amount':600} and x['neverTreatCurrencyAsCopper'] for x in bags),'Moxie cost never represented as gold')
check(len(a['sources'])==6 and len(ap['fieldProposals'])==515,'six added source keys /515 original tuple matches')
check(all(x['sourceNativeTupleVerified'] for s in a['sources'] for x in s['rows']),'all added source tuples actually verified')
check(set(a['receipt']['coveredLocators'])=={x['locator'] for s in a['sources'] for x in s['rows']},'addendum exact unique locator coverage')
check(all(x['sourceReportedCounters']['casts'] is None for x in ap['fieldProposals']),'addendum not synthetic casts')
w=load('workbook-review.json')
check(len(w['rows'])==387 and len({x['matrixRowIndex'] for x in w['rows']})==387,'all original workbook rows have exact decisions')
check(w['receipt']['probabilityRows']==212 and not w['receipt']['expectedQuantityColumnPresent'],'actual workbook fields, not advertised104 quantities')
mop=[x for x in w['rows'] if x['rawRow']['Expansion']=='Mists of Pandaria']
check(len(mop)==48 and all(x['decision']=='REJECTED_CURRENT_NUMERICAL_USE' for x in mop),'explicit MoPClassic source not silently admitted as Retail')
check(all(x['empiricalSamples']==0 and x['modelConfidenceCap']==0 and not x['unconditionalEVGranted'] for x in p['workbookFieldProposals']),'workbook priors do not invent N or expected quantities')
silver=m['deb-lead:silver-source-calculator']
check(silver['inputItemID']==237365 and silver['sourceInputRank']==2,'native rank mapping fixes old237364 candidate mismatch')
check(len(silver['materials'])==7 and all(len(x['legalRankIDs'])==2 for x in silver['materials']),'Silver source model uses legal native quality pools, no arbitrary priced rank')
check(silver['sourceReportedCompletedOperations'] is None and abs(silver['materials'][2]['expectedQuantity']-.0635)<1e-12,'calculator mean retained without calling2000 observed casts or chance')
check(silver['materials'][2]['condition']['sourceUnlockState']=='assumed-eligible-not-captured','Diamond eligibility assumption explicit')
print(f'{checks} source-contract checks passed')
