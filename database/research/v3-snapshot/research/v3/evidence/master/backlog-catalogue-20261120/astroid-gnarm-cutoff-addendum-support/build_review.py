"""Finite cutoff addendum: native Astroid/Gnarm positive-event quantities.
No completed-cast count, probability, unconditional EV or current era is inferred.
"""
from __future__ import annotations
from collections import Counter,defaultdict
from copy import deepcopy
from hashlib import sha256
import argparse,json,re,sys
from pathlib import Path

CUT='0cd0bad8867e7a8d909b4ecae74f6136a3e23d42'
CAT=Path('research/v3/evidence/master/backlog-catalogue-20261120')
INPUTS=[('research/v3/evidence/legacy/2026-11-20T1940-astroid-gnarm-native-positive-counters.jsonl','EnchantedLocal'),
        ('research/v3/evidence/legacy/2026-11-19T2249-gnarm-original-classic-groups.jsonl','EnchantedItemTypes')]
CACHES={'astroid':CAT/'disenchant-a-support/astroid.lua.txt',
        'gnarm':CAT/'astroid-gnarm-cutoff-addendum-support/gnarm.lua.txt'}
PREFIX='astroid-gnarm-cutoff-addendum'
REVISION='astroid-gnarm-native-positive-source-fields/1'

def load(p):return json.loads(Path(p).read_text(encoding='utf-8-sig'))
def dump(p,v):Path(p).parent.mkdir(parents=True,exist_ok=True);Path(p).write_text(json.dumps(v,indent=2,ensure_ascii=False,allow_nan=False)+'\n',encoding='utf8',newline='\n')
def canon(v):return sha256(json.dumps({k:x for k,x in v.items() if not k.startswith('_')},sort_keys=True,ensure_ascii=False,separators=(',',':'),allow_nan=False).encode()).hexdigest()
def native_tables(path):
 text=path.read_text(encoding='utf-8-sig');result={}
 for section in ['EnchantedLocal','EnchantedItemTypes']:
  match=re.search(r'(?ms)^'+section+r'\s*=\s*\{(.*?)^\}',text);assert match,section
  table={}
  for signature,values in re.findall(r'\["([\d:\-]+)"\]\s*=\s*"([\d:;]+)"',match.group(1)):
   assert signature not in table,(path,section,signature)
   table[signature]={}
   for value in values.split(';'):
    item,h,q,tail=map(int,value.split(':'));assert item not in table[signature]
    table[signature][item]=(h,q,tail)
  result[section]=table
 return result

def build(research,pipeline):
 sys.path.insert(0,str(pipeline/'tools'))
 import research_v3_to_baselines as bridge
 from reviewed_source_catalogue import source_rows
 effective={(r['_file'],r['id']):r for r in bridge.load_calculator(research).load_reviewed_source_rows()}
 native={name:native_tables(research/path) for name,path in CACHES.items()}
 native_hashes={name:sha256((research/path).read_bytes()).hexdigest() for name,path in CACHES.items()}
 assignments={};sources={};definitions=[];facts=[];decisions=[];raw_coverage=[];event_ranges=0;native_counts=Counter();seen_native=defaultdict(set)
 for file,section in INPUTS:
  for line,text in enumerate((research/file).read_text(encoding='utf-8-sig').splitlines(),1):
   if not text.strip():continue
   raw=json.loads(text);row=effective.get((file,raw['id']));assert row is not None,(file,raw['id'],'excluded source needs explicit disposition')
   row={k:v for k,v in row.items() if not k.startswith('_')}
   contributor='astroid' if 'astroid-' in raw['id'] else 'gnarm'
   signature=re.search(r'\["([\d:\-]+)"\]',row['quote']).group(1)
   h,q,tail=native[contributor][section][signature][row['outputItemID']]
   assert h==row['castsWithDrop'] and q==row['totalQuantity'] and h>0 and q>=h and tail==0
   assert row.get('casts') is None and row.get('inputsProcessed') is None
   assert row.get('histogram') is None and row.get('minSeen') is None and row.get('maxSeen') is None
   if section=='EnchantedLocal':assert int(signature.split(':')[0])==row['inputItemID']
   source_url=(row.get('source')or{})['url'];source_key=source_url.removeprefix('https://').removeprefix('http://')
   locator=f'{file}:{line}';ref={'sourceFile':file,'line':line,'sourceRecordID':row['id'],'rawSHA256':canon(raw),'effectiveSHA256':canon(row)}
   proof,reason=source_rows(research,[ref],effective=effective);assert proof and not reason,(locator,reason)
   candidate={'disposition':'PRESERVED_UNRESOLVED_SCOPE_OR_FIELDS','effectiveSHA256':canon(row),'line':line,'locator':locator,
    'method':row['method'],'rawSHA256':canon(raw),'reasons':['Native Q/H is a conditional material-positive-event quantity; no completed-cast denominator or unconditional yield is asserted.'],
    'recordID':row['id'],'sourceFile':file,'sourceURL':source_url,'studyKey':row.get('studyKey'),'originalEvidenceRow':raw,'effectiveEvidenceRow':row}
   assignments.setdefault(source_key,{'sourceKey':source_key,'sourceURLs':[source_url],'candidateRows':[]})['candidateRows'].append(candidate)
   source=sources.setdefault(source_key,{'sourceKey':source_key,'sourceURLs':[source_url],
    'reviewStatus':'REVIEWED_CURRENT_BASELINE_PIPELINE','rows':[]})
   raw_coverage.append(locator);native_counts[contributor+':'+section]+=1
   seen_native[(contributor,section)].add((signature,row['outputItemID'],h,q,tail))
   mean=q/h;metrics=[('conditionalQuantity','conditionalMeanUnitsPerPositiveEvent',{'value':mean})]
   if h==1 or q==h:
    units=q if h==1 else 1
    metrics.append(('observedPositiveQuantityRange','conditionalStackRange',{'lower':units,'upper':units}));event_ranges+=1
   field_decisions=[];row_props=[];row_facts=[]
   for field,metric,values in metrics:
    pid=PREFIX+':'+row['id']+':'+field;fid='reviewed-backlog:'+pid
    unit='material-units / recorded-material-positive-event'
    definition={'proposalID':pid,'sourceKey':source_key,'locator':locator,'recordID':row['id'],'studyKey':row.get('studyKey'),
     'method':'Disenchant','scope':{'nativeTable':section,'nativeSignature':signature,'inputItemID':row.get('inputItemID'),
       'rawGearGroup':deepcopy(row.get('gearGroup')),'currentEraOrFlavorVerified':False},
     'material':{'outputItemID':row['outputItemID'],'outputName':row.get('outputName')},
     'field':{'field':field,'metric':metric,**values,'unit':unit,'numeratorUnits':q,'denominatorRecordedPositiveEvents':h,
       'denominatorIsCompletedCasts':False,'trailingCounterUninterpreted':tail,'hardGameBounds':False},
     'sourceRows':[ref],'nativeCounterProof':{'sourceURL':source_url,'pinnedCommit':'5918ca3e44f6e4bba9071731ab28be3189498001',
       'cacheFile':CACHES[contributor].as_posix(),'LFCacheSHA256':native_hashes[contributor],
       'nativeTable':section,'nativeSignature':signature,'outputItemID':row['outputItemID'],'tuple':[h,q,tail]},
     'sourceSupportMaximum':20,'modelConfidenceCap':0,'empiricalSamples':0}
    definitions.append(definition);row_props.append(pid)
    if section=='EnchantedLocal':
     fact={'factID':fid,'method':'Disenchant','profession':'Enchanting','inputItemID':row['inputItemID'],
      'nativeInputVariant':signature,'outputItemID':row['outputItemID'],'outputName':row.get('outputName'),
      'metric':metric,**values,'unit':unit,'confidence0to100':0,'sourceSupportConfidence':20,
      'sourceKey':'itemdb','sourceStudyKey':row.get('studyKey') or row['id'],'sourceURL':source_url,'sourceRows':[ref],
      'sourceProfile':{'patch':'historical contributor client/build unverified'},
      'reportedObservationCounts':{'recordedMaterialPositiveEvents':h,'totalMaterialUnits':q,'uninterpretedTrailingCounter':tail,
        'completedOperations':None,'histogram':None},'nativeCounterProof':definition['nativeCounterProof'],
      'sourceContextOnly':True,'targetProfileAdjusted':False,'unconditionalEVGranted':False,'hardGameBounds':False,
      'sourceEventRangeBasis':'one recorded positive event' if h==1 else 'integer positive units Q equal positive-event H' if q==h else None,
      'samples':0,'sampleSizeKnown':False}
     facts.append(fact);row_facts.append(fid)
     decision={'proposalID':pid,'sourceKey':source_key,'decision':'SOURCE_CONTEXT_FACT','factIDs':[fid],'modelIDs':[],
       'reason':'Exact original native item variant and material-positive event tuple verified. Q/H and any identified observed positive-event stack are source-context units, never total-cast probability or unconditional expected yield.',
       'futureEvidenceTrigger':'Only a new source correction, exact new cohort, independently established completed-operation denominator, or current client/variant normalization evidence changes this scoped decision.'}
    else:
     decision={'proposalID':pid,'sourceKey':source_key,'decision':'REJECTED_CURRENT_NUMERICAL_USE','factIDs':[],'modelIDs':[],
       'reason':'Q/H remains a valid recorded-positive-event quantity in this exact source aggregate, but the historical EnchantedItemTypes group has no verified current era/flavor or exact item join. No truthful current item-tooltip selector exists; assigning expansion0 or all current items would invent scope. This aggregate overlaps the same contributor item log and adds no independent observations.',
       'futureEvidenceTrigger':'Verify the historical client/flavor and an exact group-to-item/variant join, or prove equivalence to an existing truthfully scoped source fact. A completed-cast denominator is not required to preserve Q/H.'}
    decisions.append(decision)
    field_decisions.append({'field':field,'decision':decision['decision'],'proposalIDs':[pid],'factIDs':decision['factIDs'],'modelIDs':[],
      'reason':decision['reason'],'futureEvidenceTrigger':decision['futureEvidenceTrigger']})
   for field,why in [('dropChance','Material-positive event H is known but the total completed-operation denominator and zero outcomes are not. H is not N.'),
       ('expectedQuantity','No completed-operation, total processed-input, or verified complete primary-event budget denominator exists. Q/H is conditional and cannot become unconditional EV.'),
       ('currentLookup','Exact native item ID supports informational source-context lookup only; current access, profile, era and target variant are not inferred.' if section=='EnchantedLocal' else 'No verified current-era/flavor or exact item join; raw group labels cannot create an expansion0 or all-items selector.')]:
    field_decisions.append({'field':field,'decision':'SOURCE_CONTEXT_FACT' if field=='currentLookup' and row_facts else 'REJECTED_CURRENT_NUMERICAL_USE',
      'proposalIDs':row_props if field=='currentLookup' and row_facts else [],'factIDs':row_facts if field=='currentLookup' and row_facts else [],'modelIDs':[],
      'reason':why,'futureEvidenceTrigger':'Only exact missing scope/denominator/current-client facts can change this field; do not re-fetch unchanged source tuples to manufacture N.'})
   source['rows'].append({'locator':locator,'recordID':row['id'],'studyKey':row.get('studyKey'),'rawSHA256':canon(raw),'effectiveSHA256':canon(row),
     'scope':{'nativeTable':section,'nativeSignature':signature,'inputItemID':row.get('inputItemID'),'rawGearGroup':row.get('gearGroup')},
     'sourceFacts':{'materialPositiveEvents':h,'materialUnits':q,'conditionalMeanUnitsPerPositiveEvent':mean,'uninterpretedTail':tail,
       'completedOperations':None,'observedPositiveRange':metrics[1][2] if len(metrics)>1 else None},
     'nativeCounterVerified':True,'decision':'SOURCE_CONTEXT_FACT' if row_facts else 'REJECTED_CURRENT_NUMERICAL_USE',
     'proposalIDs':row_props,'factIDs':row_facts,'modelIDs':[],'fieldDecisions':field_decisions})
 assert len(raw_coverage)==860 and len(set(raw_coverage))==860
 assert native_counts=={'astroid:EnchantedLocal':457,'gnarm:EnchantedLocal':380,'gnarm:EnchantedItemTypes':23},native_counts
 assert sum(len(v) for v in native['astroid']['EnchantedLocal'].values())==457
 assert sum(len(v) for v in native['gnarm']['EnchantedLocal'].values())==380
 for contributor in ['astroid','gnarm']:
  expected={(sig,item,*value) for sig,outputs in native[contributor]['EnchantedLocal'].items() for item,value in outputs.items()}
  assert seen_native[(contributor,'EnchantedLocal')]==expected,'Complete native item tuple set must match, not merely the row count'
 ids={f['factID'] for f in facts};assert len(ids)==len(facts)
 assert {d['proposalID'] for d in decisions}=={d['proposalID'] for d in definitions}
 assert {i for d in decisions for i in d['factIDs']}==ids
 receipt={'sourceCutoff':CUT,'sources':len(sources),'physicalRows':860,'nativeItemRows':837,'historicalAggregateRows':23,
  'byNativeSourceTable':dict(native_counts),'fieldProposals':len(definitions),'facts':len(facts),'models':0,
  'conditionalMeanFacts':837,'observedPositiveEventRangeFacts':sum(f['metric']=='conditionalStackRange' for f in facts),
  'unscopedGroupRowsRejectedCurrentLookup':23,'completeNativeItemTupleSetsVerified':True,
  'nativeDerivedAggregateTuplesAvailable':{name:sum(len(v) for v in tables['EnchantedItemTypes'].values()) for name,tables in native.items()},
  'nativeDerivedAggregateDisposition':'Metadata only: group labels without verified historical client/flavor and exact item/variant joins cannot select current tooltip inputs. These aggregates overlap contributor item events and are never additional independent casts.',
  'observedSamplesAdded':0,'confidence0to100':0,
  'allRawAndEffectiveProofsVerified':True,'nativeCacheSHA256':native_hashes,
  'sourceFilesSHA256':{name:sha256((research/name).read_bytes()).hexdigest() for name,_ in INPUTS}}
 return ({'researchSnapshot':CUT,'sources':list(assignments.values())},
  {'schemaVersion':1,'receipt':receipt,'sources':list(sources.values())},
  {'schemaVersion':1,'receipt':receipt,'fieldProposals':definitions},
  {'schemaVersion':1,'revision':REVISION,'models':[],'facts':facts},
  {'schemaVersion':1,'revision':REVISION,'coverage':receipt,'decisions':decisions,'sources':list(sources.values())})

def main():
 parser=argparse.ArgumentParser();parser.add_argument('--research-root',type=Path,required=True);parser.add_argument('--pipeline-root',type=Path,required=True);parser.add_argument('--check',action='store_true');args=parser.parse_args()
 args.research_root=args.research_root.resolve();args.pipeline_root=args.pipeline_root.resolve()
 docs=build(args.research_root,args.pipeline_root)
 paths=[args.pipeline_root.parent/'.validation/backlog-closure-20261120/inputs/astroid-gnarm-cutoff-addendum.json']+[args.research_root/CAT/(PREFIX+'-'+suffix+'.json') for suffix in ['review','proposals','admitted-models','proposal-dispositions']]
 for path,doc in zip(paths,docs):
  if args.check:assert load(path)==doc,'Changed generated addendum: '+str(path)
  else:dump(path,doc)
 print(json.dumps(docs[1]['receipt'],sort_keys=True))
if __name__=='__main__':main()
