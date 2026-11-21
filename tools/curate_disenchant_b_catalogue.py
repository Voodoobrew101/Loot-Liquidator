"""Translate the finite DE-B/lead catalogue into typed, zero-sample consumers.

This adapter adds no scientific measurements. Conditional positive-event amounts
stay informational; source-profile means are never relabelled neutral captures.
The frozen human review, exact source pointers, and each proposal remain auditable.
"""
from __future__ import annotations
import argparse
from collections import Counter, defaultdict
from copy import deepcopy
from hashlib import sha256
import json
import math
from pathlib import Path
import re

from reviewed_source_catalogue import canonical_hash, model_record, source_rows

CAT = Path('research/v3/evidence/master/backlog-catalogue-20261120')
REVISION = 'reviewed-disenchant-b-catalogue/1'
PROFESSIONS = {'Disenchant':'Enchanting','Mill':'Inscription','Prospect':'Jewelcrafting','Recycle':'Engineering','Use':None}
EXPANSIONS = {'Classic':0,'The Burning Crusade':1,'Wrath of the Lich King':2,'Cataclysm':3,
              'Mists of Pandaria':4,'Warlords of Draenor':5,'Legion':6,'Battle for Azeroth':7,
              'Shadowlands':8,'Dragonflight':9,'The War Within':10,'Midnight':11}
ARTIFACTS = ('disenchant-b-leads-proposals.json','disenchant-b-leads-current-addendum-proposals.json',
             'disenchant-b-leads-review.json','disenchant-b-leads-current-addendum-review.json',
             'disenchant-b-leads-workbook-review.json')


def read(path): return json.loads(Path(path).read_text(encoding='utf-8-sig'))
def dump(path,value): Path(path).write_text(json.dumps(value,indent=2,ensure_ascii=False,allow_nan=False)+'\n',encoding='utf-8',newline='\n')
def key(value): return sha256(json.dumps(value,sort_keys=True,ensure_ascii=False,separators=(',',':')).encode()).hexdigest()[:20]
def number(value): return type(value) in (int,float) and math.isfinite(value) and value >= 0
def pointer_ref(name,pointer,obj): return {'sourceFile':(CAT/name).as_posix(),'jsonPointer':pointer,'rawSHA256':canonical_hash(obj)}
def rarity(value):
    text=str(value or '').lower()
    for term,n in [('uncommon',2),('rare',3),('epic',4),('common',1)]:
        if re.search(r'\b'+term+r'\b',text): return n
    return None


class Curator:
    def __init__(self,snapshot,native):
        self.snapshot=Path(snapshot);self.folder=self.snapshot/CAT
        self.docs={name:read(self.folder/name) for name in ARTIFACTS}
        routing=read(native)['recipeRouting'];self.items=routing['items'];self.families=routing['qualityFamilies']
        self.models={};self.facts={};self.decisions=[];self.row_index={};self.model_groups={};self.proposal_refs={};self.lookup_rejections=[]
        for name in ('disenchant-b-leads-review.json','disenchant-b-leads-current-addendum-review.json'):
            doc=self.docs[name]
            for si,source in enumerate(doc.get('sources',[])):
                for ri,row in enumerate(source.get('rows',[])):
                    self.row_index[row['recordID']] = (row,source,pointer_ref(name,f'/sources/{si}/rows/{ri}',row))
        self.scope_links=defaultdict(lambda:{'modelIDs':set(),'factIDs':set(),'proposalIDs':set()})

    def native(self,item): return self.items.get(str(item),{})
    def expansion(self,scope):
        text=str((scope.get('gearGroup') or {}).get('expansion') or scope.get('sourceExpansion') or '')
        for name,exp in sorted(EXPANSIONS.items(),key=lambda x:-len(x[0])):
            if text.startswith(name):return exp
        item=self.native(scope.get('inputItemID'))
        return item.get('expansionID') if item else None

    def scope_fields(self,scope):
        result={'method':scope.get('method','Disenchant')}
        exp=self.expansion(scope)
        if exp is not None:result['expansionID']=exp
        if scope.get('inputItemID'): result['inputItemID']=scope['inputItemID']
        elif scope.get('legalInputRankIDs'):
            ids=scope['legalInputRankIDs']
            if not all(type(i)is int and i>0 and self.native(i) for i in ids):raise ValueError('Unverified source input family IDs')
            families={self.native(i).get('qualityFamilyID') for i in ids}
            if len(families)!=1 or None in families:raise ValueError('Source input alternatives must be one verified native family')
            result['inputFamilyIDs']=deepcopy(ids)
        if isinstance(scope.get('inputRank'),int):result['inputQualityRank']=scope['inputRank']
        gear=scope.get('gearGroup') or {}
        q=rarity(gear.get('quality'));kind=str(gear.get('kind') or '').lower()
        cls=2 if 'weapon' in kind else 4 if 'armor' in kind or 'armour' in kind else None
        if not result.get('inputItemID') and exp is not None and (q is not None or cls is not None):
            result['gearScope']={'expansionID':exp}
            if q is not None:result['gearScope']['rarity']=q
            if cls is not None:result['gearScope']['classID']=cls
        if scope.get('exactNativeItemSignature'):result['nativeInputVariant']=scope['exactNativeItemSignature']
        return result

    def ref(self,proposal,name,pointer):
        refs=[pointer_ref(name,pointer,proposal)]
        row_data=self.row_index.get(proposal.get('recordID'))
        if row_data:
            row,_,_=row_data;file,line=row['locator'].rsplit(':',1)
            raw=read_jsonl_line(self.snapshot/file,int(line))
            refs.insert(0,{'sourceFile':file,'line':int(line),'sourceRecordID':raw['id'],'rawSHA256':canonical_hash(raw),
                'effectiveSHA256':row.get('currentEffectiveSHA256') or row['frozenEffectiveSHA256']})
        return refs

    def fact(self,proposal,refs,*,metric,value=None,unit=None,lower=None,upper=None,scope=None,material=None,profile=None,suffix=''):
        fid='reviewed-backlog:deb-fact:'+proposal['proposalID']+suffix
        scope=scope or proposal.get('scope',{});material=material or proposal.get('material',{})
        fact={'factID':fid,**self.scope_fields(scope),'metric':metric,'unit':unit or proposal.get('field',{}).get('unit','source-reference'),
              'confidence0to100':0,'sourceSupportConfidence':20,'samples':0,'sampleSizeKnown':False,
              'sourceKey':'itemdb','sourceStudyKey':proposal.get('studyKey') or proposal.get('proposalID'),
              'sourceURL':(proposal.get('sourceURLs') or [proposal.get('sourceURL') or self.source_url(proposal['sourceKey'])])[0],
              'sourceRows':deepcopy(refs),'sourceProfile':deepcopy(profile if profile is not None else proposal.get('sourceProfile',{})),
              'reportedObservationCounts':deepcopy(proposal.get('sourceReportedCounters',{})),
              'sourceContextOnly':True,'targetProfileAdjusted':False,'unconditionalEVGranted':False}
        if material.get('outputItemID'):fact['outputItemID']=material['outputItemID']
        if material.get('outputName'):fact['outputName']=material['outputName']
        if isinstance(material.get('outputRank'),int):fact['outputRank']=material['outputRank']
        if material.get('legalFamilyIDs'):fact['legalOutputFamilyIDs']=deepcopy(material['legalFamilyIDs'])
        if value is not None:fact['value']=value
        if lower is not None:fact['lower']=lower
        if upper is not None:fact['upper']=upper
        if not fact.get('outputItemID') and not fact.get('outputName'):fact['outputName']='Original source material (identity unresolved)'
        self.facts[fid]=fact
        return fid

    def decision(self,p,status,reason,models=(),facts=()):
        self.decisions.append({'proposalID':p['proposalID'],'sourceKey':p['sourceKey'],'decision':status,
            'modelIDs':list(models),'factIDs':list(facts),'reason':reason,
            'futureEvidenceTrigger':'Only unresolved identity, source-profile normalization, epoch or denominator named in this decision; unchanged primary facts do not require a fresh source fetch.'})
        link=self.scope_links[p.get('recordID') or p['proposalID']]
        link['proposalIDs'].add(p['proposalID']);link['modelIDs'].update(models);link['factIDs'].update(facts)

    def profile_non_neutral(self,proposal):
        profile=proposal.get('sourceProfile') or {}
        return any(profile.get(k) not in (None,'',{},[]) for k in ('skill','specialization','stats'))

    def model(self,p,refs,field,value,*,scope=None,output=None,derivation=None,input_count=None,extra=None):
        scope=scope or p.get('scope',{});output=output or p['material'];sf=self.scope_fields(scope)
        input_id=sf.get('inputItemID');exp=sf.get('expansionID')
        gear=scope.get('gearGroup') or {};kind=str(gear.get('kind') or '').lower();q=rarity(gear.get('quality'))
        cls=2 if 'weapon' in kind else 4 if 'armor' in kind or 'armour' in kind else None
        gear_key=f'gear:{exp}:{q}:{"weapon" if cls==2 else "armor"}' if exp is not None and q is not None and cls else None
        if not input_id and not gear_key:return None,'Rarity/expansion is source context, but armor versus weapon is unresolved; no universal category EV prior.'
        if exp is None:return None,'Source expansion/epoch is not identifiable for target processing.'
        if not output.get('outputItemID'):return None,'No verified exact output item ID or native legal rank family binds this quantity.'
        if scope.get('exactNativeItemSignature'):return None,'Exact native suffix/enchant variant is source-specific; informational fact preserved until the operation consumer can enforce that complete variant.'
        batch=input_count or scope.get('inputsPerCast')
        if not isinstance(batch,int) or batch<=0:return None,'A native legal input batch is unidentified; preserve a per-input/source field without inventing an operation count.'
        if p.get('sourceKey','').endswith('@mop-classic') or 'mop-classic' in str(p.get('sourceURLs','')):
            return None,'Explicit MoP Classic source environment is not established as the current Retail instance epoch.'
        group=(p.get('sourceKey'),p.get('studyKey') or p.get('proposalID'),json.dumps(scope,sort_keys=True),batch)
        rid='evidence:reviewed-backlog:deb:'+key(group)
        if rid not in self.models:
            record={'recordID':rid,'method':sf['method'],'inputCount':batch,'expansionID':exp,
                    'sourceKey':p['sourceKey'],'sourceStudyKey':p.get('studyKey') or p['proposalID'],
                    'sourceURL':(p.get('sourceURLs') or [p.get('sourceURL') or self.source_url(p['sourceKey'])])[0],
                    'sourceTitle':'Reviewed historical source fields','sourceRows':[],
                    'baselineProfile':{'sourceProfile':'unknown; neutral projection prior is a modeling assumption, not a capture',
                        'skill':0,'preSpecializationSkill':0,'specializationPoints':{},'stats':{},'specializationKnown':False},
                    'baselineProfileAssumed':True,'baselineProfileConfidence':0,
                    'sourceQuantityBasis':'gross-input','materials':[],
                    'assumptions':['Unknown original profile is a confidence-zero numerical prior, never an observed zero-skill capture.',
                        'All original counters stay provenance; active empirical sample count is zero.',
                        'No access, unconditional chance, omitted output zero or output rank is inferred.'],
                    'reportedObservationCounts':deepcopy(p.get('sourceReportedCounters',{})),
                    'sourceEpoch':scope.get('dataDate') or scope.get('sourceEnvironment') or (scope.get('gearGroup') or {}).get('expansion') or 'historical source; exact patch unknown'}
            if input_id:record['inputItemID']=input_id
            else:record.update(gearKey=gear_key,inputRarity=q,inputClassID=cls,isDisenchantCategory=True,categoryReferenceOnly=True)
            if sf.get('inputQualityRank'):record['inputQualityRank']=sf['inputQualityRank']
            if extra:record.update(deepcopy(extra))
            self.models[rid]=record
        model=self.models[rid]
        for ref in refs:
            if ref not in model['sourceRows']:model['sourceRows'].append(ref)
        material=next((m for m in model['materials'] if m['id']==output['outputItemID']),None)
        if not material:material={'id':output['outputItemID']};model['materials'].append(material)
        if output.get('rankIDs'):material['rankIDs']=deepcopy(output['rankIDs'])
        spec={'value':value,'sourceSupportConfidence':20,'modelConfidenceCap':0,
              'derivation':derivation or {'kind':'explicit-source-value','sourceUnit':p.get('field',{}).get('unit')}}
        if field in material and material[field]!=spec:raise ValueError('Conflicting fields inside one source cohort '+rid)
        material[field]=spec
        return rid,None

    def field(self,p,refs):
        field=p['field'];kind=field['field'];value=field['value'];facts=[];models=[]
        metric={'conditionalQuantity':'conditionalMeanUnitsPerPositiveEvent','dropChance':'sourceOccurrenceFraction',
                'expectedQuantity':'sourceProfileMeanUnitsPerOperation','expectedQuantityPerInput':'sourceProfileMeanUnitsPerInput',
                'positiveQuantityRange':'conditionalStackRange','observedPositiveQuantity':'conditionalStackRange'}[kind]
        if kind in ('positiveQuantityRange','observedPositiveQuantity'):
            lo,hi=value if isinstance(value,list) else (value,value)
            facts.append(self.fact(p,refs,metric=metric,lower=lo,upper=hi))
        else:facts.append(self.fact(p,refs,metric=metric,value=value))
        reason='Exact source denominator retained separately from unconditional material EV.'
        eligible=kind in ('dropChance','expectedQuantity','expectedQuantityPerInput') and not self.profile_non_neutral(p)
        if eligible:
            scope=deepcopy(p['scope']);batch=scope.get('inputsPerCast')
            material=p['material'];out=deepcopy(material)
            derivative={'kind':'ratio','numerator':field.get('numerator'),'denominator':field.get('denominator'),
                        'denominatorMeaning':field.get('denominatorMeaning') or field.get('reportedNumeratorMeaning') or field.get('basis')}
            if not number(derivative['numerator']) or not number(derivative['denominator']) or derivative['denominator']<=0:
                derivative={'kind':'explicit-source-value','sourceUnit':field['unit']}
            model_value=value
            if kind=='expectedQuantityPerInput':
                if not isinstance(batch,int):batch=1 if scope.get('method')=='Disenchant' else None
                if batch:model_value=value*batch;derivative={'kind':'reviewed-model-formula','formula':'source per-input mean Ãƒâ€” native operation input count',
                    'sourcePerInputMean':value,'inputCount':batch,'original':derivative}
            rid,why=self.model(p,refs,'dropChance' if kind=='dropChance' else 'expectedQuantity',model_value,scope=scope,output=out,derivation=derivative,input_count=batch)
            if rid:models.append(rid);reason='Dimensioned source field admitted as a confidence-zero historical prior with unchanged original counters; informational source fact also retained.'
            else:reason=why
        elif kind in ('expectedQuantity','expectedQuantityPerInput'):
            reason='Reported nonneutral skill/specialization/stats are retained with this exact source-profile mean. A compatible inverse curve/source allocation is not identified; this mean is not relabelled a zero-profile baseline.'
        self.decision(p,'MODEL_AND_SOURCE_FACT' if models else 'SOURCE_CONTEXT_FACT',reason,models,facts)

    def workbook(self,p,index):
        f=p['field'];name=f['field'];scope=deepcopy(p['scope']);material=deepcopy(p['material'])
        refs=[pointer_ref('disenchant-b-leads-proposals.json',f'/workbookFieldProposals/{index}',p)]
        p=deepcopy(p);p['studyKey']='deb-workbook:'+p['sourceKey'];p['sourceURLs']=[self.source_url(p['sourceKey'])]
        profile={'source':'Compiled reference workbook, not a measured source cohort','sourceEnvironment':scope['sourceEnvironment']}
        metric='sourceOccurrenceFraction' if name=='dropChance' else 'conditionalStackRange'
        if name=='dropChance':fid=self.fact(p,refs,metric=metric,value=f['value'],profile=profile)
        else:
            related=[(i,x) for i,x in enumerate(self.docs['disenchant-b-leads-proposals.json']['workbookFieldProposals'])
                     if x['worksheetRow']==p['worksheetRow'] and x['field']['field']!='dropChance']
            bounds={x['field']['field']:x['field']['value'] for _,x in related}
            boundrefs=[pointer_ref('disenchant-b-leads-proposals.json',f'/workbookFieldProposals/{i}',x) for i,x in related]
            shared=deepcopy(p);shared['proposalID']=p['proposalID'].rsplit(':',1)[0]+':positive-stack-bounds'
            if 'positiveQuantityMaximum' in bounds:
                fid=self.fact(shared,boundrefs,metric=metric,lower=bounds['positiveQuantityMinimum'],upper=bounds['positiveQuantityMaximum'],profile=profile)
            else:
                fid=self.fact(shared,boundrefs,metric='conditionalStackLowerBound',value=bounds['positiveQuantityMinimum'],profile=profile)
        models=[];reason='The workbook has no measured N, completed operation history or expected-quantity column. Source probability/range is preserved without deriving an EV.'
        if material.get('representativeVariantOnly'):
            item=self.native(material.get('outputItemID'));family=self.families.get(str(item.get('qualityFamilyID')),{}).get('rankItemIDs')
            if family:material['rankIDs']=family
        if not scope.get('inputRankUnknown') and (name=='dropChance' or f['value']>0 and float(f['value']).is_integer()):
            rid,why=self.model(p,refs,{'dropChance':'dropChance','positiveQuantityMinimum':'minQuantity','positiveQuantityMaximum':'maxQuantity'}[name],f['value'] if name=='dropChance' else int(f['value']),scope=scope,output=material,
                derivation={'kind':'explicit-source-value','sourceUnit':f['unit']})
            if rid:models.append(rid)
            else:reason=why
        else:reason='Input quality variant is unverified in the workbook; its representative ID cannot establish a ranked operation. Source field retained informationally.'
        self.decision(p,'MODEL_AND_SOURCE_FACT' if models else 'SOURCE_CONTEXT_FACT',reason,models,[fid])

    def lead(self,p,index):
        refs=[pointer_ref('disenchant-b-leads-proposals.json',f'/leadModelProposals/{index}',p)]
        refs.extend(self.lead_review_ref(p['sourceKey']))
        ident=p['proposalID'];method=p['method'];exp=p.get('expansionID')
        if exp is None:
            if 'empyrium' in ident:exp=6
            elif 'bilis' in ident or 'sygon' in ident:exp=7
            elif 'magma-thresher' in ident:exp=9
            elif 'moxie-bag' in ident or 'silver-source' in ident:exp=11
        scope={'method':method,'inputItemID':p.get('inputItemID'),'inputsPerCast':p.get('inputsPerCast'),
               'dataDate':p.get('sourceEpoch'),'sourceExpansion':next((k for k,v in EXPANSIONS.items() if v==exp),None)}
        if p.get('sourceInputRank'):scope['inputRank']=p['sourceInputRank']
        profile={'dataDate':p.get('sourceEpoch'),'specialization':p.get('sourceSpecialization'),
                 'skill':p.get('sourceSkill'),'source':p.get('sourceProfile')}
        facts=[];models=[];reasons=[]
        if 'zarp-shatter' in ident:
            material={'outputName':'Returned source shard (recipe and item identity unspecified)'}
            facts.append(self.fact(p,refs,metric='sourceProfileMeanUnitsPerOperation',value=p['refundUnitsPerReportedOperation'],unit='returned-shard-units/source-reported-operation',scope=scope,material=material,profile=profile))
            reasons.append('45 returned units /800 reported operations is a refund-unit mean, not a proc chance. Unspecified recipe/input/shard identity prevents numerical operation binding.')
        for j,m in enumerate(p.get('materials',[])):
            material={'outputItemID':m.get('id'),'outputName':m.get('name') or self.native(m.get('id')).get('name')}
            pool=m.get('legalRankIDs')
            if pool:
                if p.get('rankKnown') and len(pool)>1:
                    material.update(outputItemID=pool[-1],outputRank=len(pool))
                elif len(pool)==1:material.update(outputItemID=pool[0])
                else:material.update(outputItemID=pool[0],rankIDs=pool)
            value=m.get('expectedQuantity');per_input=m.get('expectedQuantityPerReportedInput')
            if per_input is not None:
                metric='sourceProfileMeanUnitsPerInput';value=per_input
            else:metric='sourceProfileMeanUnitsPerOperation'
            if value is None:
                for endpoint,amount in [('base',m.get('basePooledExpectedQuantity')),('full',m.get('fullPooledExpectedQuantity'))]:
                    if amount is not None:facts.append(self.fact(p,refs,metric=metric,value=amount,scope=scope,material=material,profile={'sourceSpecializationEndpoint':endpoint,'points':0 if endpoint=='base' else 30},suffix=f':{j}:{endpoint}'))
                reasons.append('Native legal Recycling input and its basic/advanced output family are unspecified; base/full30-point pooled endpoints remain source facts, without a universal input allowlist or rank price.')
                continue
            factmat=deepcopy(material)
            if pool and len(pool)>1 and not p.get('rankKnown'):factmat['legalFamilyIDs']=pool;factmat['outputItemID']=None
            facts.append(self.fact(p,refs,metric=metric,value=value,scope=scope,material=factmat,profile=profile,suffix=f':{j}'))
            if m.get('condition'):
                reasons.append('Silver diamond source mean requires Silver Scrapper unlock; exact source state is assumed, not captured. Retained as a scoped source-profile fact without bypassing target unlock gates.');continue
            if 'empyrium-op-' in ident:
                reasons.append('Three same-author arms have unverified overlap; preserved as alternative source vectors, not extra independent baseline weight.');continue
            if p.get('sourceSpecialization'):
                reasons.append('The reported nonzero source specialization cannot be inverted from an unspecified allocation; mean remains source-profile-specific.');continue
            if p.get('sourceOutputRank'):
                reasons.append('Source rank claim lacks exact output links, and the fish consumption recipe/batch is unknown; named source mean only.');continue
            if not material.get('outputItemID'):
                reasons.append('No verified output item ID or legal rank family binds this named quantity.');continue
            batch=scope.get('inputsPerCast');quantity=value
            if per_input is not None:
                # A published per-input ratio is not a proof of a selected
                # native processing recipe/batch. Keep it useful as a fact.
                reasons.append('Per-input published mean retained; no source-native operation batch/recipe is established for this vector. No invented casts or free input allocation.');continue
            out=deepcopy(material)
            if pool and len(pool)>1 and not p.get('rankKnown'):out['rankIDs']=pool
            extra={'sourceEpoch':p.get('sourceEpoch') or 'unknown source epoch'}
            if p.get('recipeID'):extra['recipeID']=p['recipeID']
            if method=='Use':
                names=list(p.get('namedUnpricedExtras',[]))
                if p.get('additionalNamedRecipeReceipt'):names.append(p['additionalNamedRecipeReceipt']['name'])
                extra.update(useReferenceOnly=True,profession=None,namedOutputs=[{'name':n,'sourceOnly':True} for n in names],unknownOutputs=bool(names))
            derivation={'kind':'explicit-source-value','sourceUnit':'material units per reported operation',
                        'sourceReportedOperations':p.get('sourceReportedCompletedOperations'),
                        'sourceQuantity':m.get('sourceQuantity'),'sourceDenominator':m.get('sourceDenominator'),
                        'neverObservedSamples':True}
            pp=deepcopy(p);pp['studyKey']=p['proposalID'];pp['sourceReportedCounters']={k:deepcopy(v) for k,v in p.items() if k.startswith('sourceReported') or k in ('sourceInputs','sourceCurrencyCost')};pp['sourceURLs']=[p.get('sourceURL') or self.source_url(p['sourceKey'])]
            rid,why=self.model(pp,refs,'expectedQuantity',quantity,scope=scope,output=out,input_count=batch,derivation=derivation,extra=extra)
            if rid:models.append(rid)
            else:reasons.append(why)
        if not reasons:reasons=['Explicit source material vector admitted with active samples0/confidence0; unknown epoch, original counters and legal rank pools remain separate.']
        self.decision(p,'MODEL_AND_SOURCE_FACT' if models else 'SOURCE_CONTEXT_FACT',' '.join(dict.fromkeys(reasons)),sorted(set(models)),facts)

    def source_url(self,source_key):
        for name in ('disenchant-b-leads-review.json','disenchant-b-leads-current-addendum-review.json'):
            for source in self.docs[name]['sources']:
                if source['sourceKey']!=source_key:continue
                if source.get('leadDecision',{}):
                    url=source['leadDecision'].get('url')
                    if url:return url
                urls=[u for u in source.get('sourceURLs',[]) if u]
                if urls:return urls[0]
                for row in source.get('rows',[]):
                    facts=row.get('sourceFacts') or {}
                    url=facts.get('originalSource') or (facts.get('source') or {}).get('url')
                    if url:return url
        if source_key.startswith(('http://','https://')):return source_key
        if source_key.startswith('github.com/'):return 'https://'+source_key
        return ''

    def lead_review_ref(self,source_key):
        doc=self.docs['disenchant-b-leads-review.json']
        for i,s in enumerate(doc['sources']):
            if s['sourceKey']==source_key and s.get('leadDecision'):
                return [pointer_ref('disenchant-b-leads-review.json',f'/sources/{i}/leadDecision',s['leadDecision'])]
        return []

    def reject_unreachable_fact_scopes(self):
        """Preserve source values without pretending an unknown input is a selector.

        A method/output label or candidate item name is not a current input ID.
        Explicit native input families and truthful gear scopes remain valid.
        """
        definitions={p['proposalID']:p for name in ('disenchant-b-leads-proposals.json','disenchant-b-leads-current-addendum-proposals.json')
                     for key in ('fieldProposals','leadModelProposals','workbookFieldProposals') for p in self.docs[name].get(key,[])}
        rejected={}
        for fid,fact in list(self.facts.items()):
            selected=bool(fact.get('inputItemID') or fact.get('inputFamilyIDs') or fact.get('gearKey') or fact.get('gearScope'))
            if selected:continue
            linked=[d for d in self.decisions if fid in d['factIDs']]
            assert linked,'Fact without a source proposal'
            p=definitions[linked[0]['proposalID']]
            if p.get('method')=='Recycle':
                reason='The source publishes Recycling quantity endpoints for five inputs, but does not bind a legal native recipe/input family to the basic Evercore versus advanced Aetherlume outcome. A universal crafted-reagent selector is not justified.'
                trigger='Verify the exact legal native input/recipe and corresponding output family; retain both published base/full endpoints without inferring a rank split.'
            elif p['proposalID']=='deb-lead:zarp-shatter-refunds':
                reason='The source reports45 returned shard units over800 operations, but identifies neither the shard nor the shatter recipe or era. A generic Craft/shatter label cannot truthfully select a current input or operation.'
                trigger='Identify the original shard, recipe and era. The preserved45/800 value is a refund-unit mean, not a proc chance.'
            else:
                scope=p.get('scope') or {}
                description=scope.get('inputName') or 'an unidentified input'
                reason=('The source field for '+description+' has no verified exact input item/family, or era-qualified rarity/class selector. '
                        'Mixed/candidate item names, output material identity and profession labels cannot establish a current item join. '
                        'The original value, unit, counters and source profile remain in review/proposal metadata; this is a current-lookup rejection, not a rejection of the conditional/source mean arithmetic.')
                trigger='Verify the exact original item/variant or complete legal input family and historical client/flavor. Do not manufacture IDs, expansion0, rarity or an all-items selector.'
            rejected[fid]={'factID':fid,'sourceValues':deepcopy(fact),'reason':reason,'futureEvidenceTrigger':trigger,
                           'currentLookupRejected':True,'numericalSourceValueInvalidated':False}
            del self.facts[fid]
        for d in self.decisions:
            removed=[fid for fid in d['factIDs'] if fid in rejected]
            if not removed:continue
            d['factIDs']=[fid for fid in d['factIDs'] if fid not in rejected]
            d['rejectedSourceMetadataIDs']=removed
            d['retainedSourceValues']=[deepcopy(rejected[fid]['sourceValues']) for fid in removed]
            d['reason']=' '.join(dict.fromkeys(rejected[fid]['reason'] for fid in removed))
            d['futureEvidenceTrigger']=' '.join(dict.fromkeys(rejected[fid]['futureEvidenceTrigger'] for fid in removed))
            if d['modelIDs']:d['decision']='MODEL_AND_SOURCE_FACT' if d['factIDs'] else 'ADMITTED_MODEL_PRIOR'
            elif d['factIDs']:d['decision']='SOURCE_CONTEXT_FACT'
            else:d['decision']='REJECTED_CURRENT_NUMERICAL_USE'
        self.lookup_rejections=[rejected[fid] for fid in sorted(rejected)]
        # Rebuild every source-row link after rejection; no orphan consumer IDs.
        self.scope_links=defaultdict(lambda:{'modelIDs':set(),'factIDs':set(),'proposalIDs':set()})
        for d in self.decisions:
            p=definitions[d['proposalID']];link=self.scope_links[p.get('recordID') or p['proposalID']]
            link['proposalIDs'].add(d['proposalID']);link['modelIDs'].update(d['modelIDs']);link['factIDs'].update(d['factIDs'])

    def ordinary_source_field_audit(self):
        """Check fact-only profiles against the actual pre-catalogue generator.

        An unsupported input family or a source row rejected by the ordinary
        cohort gates is not a numerical baseline contribution to remove.
        A newly enabled contribution requires a precise reviewed exclusion.
        """
        import research_v3_to_baselines as v3
        import research_v3_evidence as evidence
        from research_build_review import automatic_admission
        module=v3.load_calculator(self.snapshot)
        rows=v3.resolve_ranked_outputs(v3.preserve_reference_range(module.load()))
        rows,_=automatic_admission(rows);rows,_=v3.retail_admission(rows)
        names=module.name_maps(rows)
        for name,ids in v3.load_families().items():
            if len(ids)==1:names.setdefault(name,ids[0])
        ordinary=[r for r in rows if v3.is_counted(r,module) and r.get('method') not in v3.GENERIC_METHODS]
        vectors,_,_=module.study_vectors(ordinary)
        eligible={};cohort_fields=defaultdict(lambda:defaultdict(list))
        original=evidence.row_support
        def trace(mod,row,batch,weight,notes,shared_casts=None):
            support=original(mod,row,batch,weight,notes,shared_casts)
            identity=mod.key_of(row,names);cohort=evidence.identified_cohort(mod,row,vectors)
            eligible[(row['_file'],row['id'])]=(identity,batch,cohort,support)
            for field,values in support.items():cohort_fields[(*identity,batch,cohort)][field].extend(values)
            return support
        evidence.row_support=trace
        try:estimates,_,_=evidence.build_field_support(module,ordinary,names)
        finally:evidence.row_support=original
        compiled={}
        for estimate in estimates:
            identity=estimate['input']
            if estimate['conditional'] or str(identity).startswith('family:'):continue
            if str(identity).startswith('gear:') and not v3.gear_key(identity):continue
            compiled[(estimate['method'],identity,estimate['outputItemID'],estimate['inputsPerCast'])]=estimate
        fields={'expectedQuantity':['expectedQuantity'],'expectedQuantityPerInput':['expectedQuantity'],
                'dropChance':['dropChance'],'positiveQuantityRange':['minQuantity','maxQuantity']}
        traces=[];leaks=[]
        for proposal in self.docs['disenchant-b-leads-proposals.json']['fieldProposals']:
            wanted=fields.get(proposal['field']['field'])
            if not wanted or not self.profile_non_neutral(proposal):continue
            location=(proposal['locator'].rsplit(':',1)[0],proposal['recordID'])
            observed=eligible.get(location)
            status='Not an eligible ordinary source row after exact cohort/copy/condition/epoch gates'
            contributing=[]
            if observed:
                identity,batch,cohort,support=observed
                estimate=compiled.get((*identity,batch))
                if estimate:
                    status='No selected field from this source cohort contributes to a compiled ordinary record'
                    for field in wanted:
                        if field not in support or field not in estimate['fieldSupport']:continue
                        choice=evidence.choose_observation(cohort_fields[(*identity,batch,cohort)][field])
                        if choice is None:continue
                        if choice.casts:
                            contributes=any(o.casts and (o.casts,o.amount,o.value)==(choice.casts,choice.amount,choice.value) for o in support[field])
                        else:contributes=any(o.source==choice.source and abs(o.value-choice.value)<1e-10 for o in support[field])
                        if contributes:contributing.append(field)
                    if contributing:status='Explicit current-field exclusion required before numerical admission'
                else:status='No supported ordinary input/batch/category identity; unresolved input families and conditional groups are not compiled'
            entry={'proposalID':proposal['proposalID'],'recordID':proposal['recordID'],'locator':proposal['locator'],
                   'sourceKey':proposal['sourceKey'],'status':status,'contributingFields':contributing}
            traces.append(entry)
            if contributing:leaks.append(entry)
        report={'policy':'reviewed-b-source-profile-transfer/1','proposalFieldsChecked':len(traces),
                'activeUnnormalizedFieldCount':sum(len(e['contributingFields']) for e in leaks),
                'sourceFieldExclusionsRequired':len(leaks),'checks':traces}
        if leaks:raise ValueError('New fact-only source profile fields enter the ordinary baseline; review exact exclusions: '+str(leaks[:3]))
        return report

    def run(self):
        initial=self.docs['disenchant-b-leads-proposals.json'];add=self.docs['disenchant-b-leads-current-addendum-proposals.json']
        for name,doc in [('disenchant-b-leads-proposals.json',initial),('disenchant-b-leads-current-addendum-proposals.json',add)]:
            for i,p in enumerate(doc['fieldProposals']):self.field(p,self.ref(p,name,f'/fieldProposals/{i}'))
        for i,p in enumerate(initial['workbookFieldProposals']):self.workbook(p,i)
        for i,p in enumerate(initial['leadModelProposals']):self.lead(p,i)
        self.reject_unreachable_fact_scopes()
        ids=[d['proposalID'] for d in self.decisions]
        expected=[p['proposalID'] for p in initial['fieldProposals']+add['fieldProposals']+initial['workbookFieldProposals']+initial['leadModelProposals']]
        assert len(ids)==len(set(ids)) and set(ids)==set(expected)
        from research_v3_to_baselines import load_calculator
        effective={(r.get('_file'),r.get('id')):r for r in load_calculator(self.snapshot).load_reviewed_source_rows()}
        proof_cache={}
        for model in self.models.values():
            model['materials'].sort(key=lambda x:x['id'])
            model_record(model,model['sourceRows'],REVISION)
            checked,why=source_rows(self.snapshot,model['sourceRows'],effective=effective,cache=proof_cache);assert checked and not why,(model['recordID'],why)
        for fact in self.facts.values():
            checked,why=source_rows(self.snapshot,fact['sourceRows'],effective=effective,cache=proof_cache);assert checked and not why,(fact['factID'],why)
            assert fact.get('value') is None or number(fact['value'])
        sources=[]
        for name in ('disenchant-b-leads-review.json','disenchant-b-leads-current-addendum-review.json'):
            for source in self.docs[name]['sources']:
                decisions=[d for d in self.decisions if d['sourceKey']==source['sourceKey']]
                scopes=[]
                for row in source.get('rows',[]):
                    link=self.scope_links.get(row['recordID'],{'modelIDs':set(),'factIDs':set(),'proposalIDs':set()})
                    scopes.append({'locator':row['locator'],'recordID':row['recordID'],
                        'decision':'MODEL_AND_SOURCE_FACT' if link['modelIDs'] else 'SOURCE_CONTEXT_FACT' if link['factIDs'] else 'REJECTED_CURRENT_NUMERICAL_USE' if link['proposalIDs'] else row['decision'],
                        **{k:sorted(v) for k,v in link.items()},'reason':' '.join(row.get('currentNumericalLimits',[])) or 'Exact typed source fields retained by the listed consumers.',
                        'rawSHA256':row.get('frozenRawSHA256') or row.get('currentRawSHA256') or row.get('sourceRecordSHA256'),
                        'currentEffectiveSHA256':row.get('currentEffectiveSHA256')})
                source_out={'sourceKey':source['sourceKey'],'decision':'MIXED_CATALOGUED',
                    'modelIDs':sorted({m for d in decisions for m in d['modelIDs']}),
                    'factIDs':sorted({f for d in decisions for f in d['factIDs']}),
                    'scopes':scopes,'leadDecision':source.get('leadDecision')}
                if source.get('leadDecision'):
                    lead_decisions=[d for d in decisions if d['proposalID'].startswith('deb-lead:') or d['proposalID'].startswith('deb-workbook:')]
                    lead_models=sorted({m for d in lead_decisions for m in d['modelIDs']})
                    lead_facts=sorted({f for d in lead_decisions for f in d['factIDs']})
                    source_out['leadTerminal']={'decision':'MODEL_AND_SOURCE_FACT' if lead_models else 'SOURCE_CONTEXT_FACT' if lead_facts else 'REJECTED_CURRENT_NUMERICAL_USE',
                        'modelIDs':lead_models,'factIDs':lead_facts,'proposalIDs':[d['proposalID'] for d in lead_decisions],
                        'reason':' '.join(dict.fromkeys(d['reason'] for d in lead_decisions)) if lead_decisions else source['leadDecision']['facts'],
                        'futureEvidenceTrigger':source['leadDecision']['futureEvidenceTrigger'],
                        'originalScientificDecision':source['leadDecision']['decision']}
                sources.append(source_out)
        # Scientific dimensions and finite coverage, independently of record count.
        assert sum(len(s['scopes']) for s in sources)==1764
        assert sum(bool(s.get('leadTerminal')) for s in sources)==35
        for model in self.models.values():
            for material in model['materials']:
                for field,spec in material.items():
                    if field in ('id','rankIDs'):continue
                    assert spec['modelConfidenceCap']==0 and spec['sourceSupportConfidence']<=20
                    if field=='expectedQuantity':
                        assert spec['derivation'].get('denominatorMeaning') not in ('positive-material-events','recorded-material-positive-events')
        definitions={p['proposalID']:p for p in initial['fieldProposals']+add['fieldProposals']}
        for decision in self.decisions:
            definition=definitions.get(decision['proposalID'])
            if definition and definition['field']['field']=='conditionalQuantity':assert not decision['modelIDs']
        assert not any('sourceCurrencyCost' in m and isinstance(m['sourceCurrencyCost'],(int,float)) for m in self.models.values())
        summary={'proposalCount':len(ids),'modelCount':len(self.models),'factCount':len(self.facts),
            'sourceUnits':len(sources),'sourceLocators':sum(len(s['scopes']) for s in sources),
            'currentLookupScopeRejections':len(self.lookup_rejections),
            'proposalDecisions':dict(Counter(d['decision'] for d in self.decisions)),
            'modelsByMethod':dict(Counter(m['method'] for m in self.models.values())),
            'factsByMetric':dict(Counter(f['metric'] for f in self.facts.values())),
            'observedSamplesAdded':0,'modelConfidenceCap':0,'sourceSupportMaximum':20}
        field_audit=self.ordinary_source_field_audit()
        admitted={'schemaVersion':1,'revision':REVISION,'sourceFieldExclusions':[],'sourceArtifacts':{name:sha256((self.folder/name).read_bytes()).hexdigest() for name in ARTIFACTS},'summary':summary,'models':sorted(self.models.values(),key=lambda m:m['recordID']),
                  'facts':sorted(self.facts.values(),key=lambda f:f['factID'])}
        dispositions={'schemaVersion':1,'revision':REVISION,'currentLookupScopeRejections':self.lookup_rejections,'sourceFieldExclusionAudit':field_audit,'summary':summary,'decisions':sorted(self.decisions,key=lambda d:d['proposalID']),'sources':sources}
        return admitted,dispositions


def read_jsonl_line(path,line): return json.loads(path.read_text(encoding='utf-8-sig').splitlines()[line-1])

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--snapshot',type=Path,required=True)
    parser.add_argument('--native-catalog',type=Path,default=Path('database/research/profession-effect-catalog-70961.json'))
    parser.add_argument('--check',action='store_true');args=parser.parse_args()
    admitted,dispositions=Curator(args.snapshot,args.native_catalog).run()
    for name,obj in [('disenchant-b-admitted-models.json',admitted),('disenchant-b-proposal-dispositions.json',dispositions)]:
        path=args.snapshot/CAT/name
        if args.check:assert read(path)==obj,'Regenerated catalogue differs: '+str(path)
        else:dump(path,obj)
    print(json.dumps(admitted['summary'],sort_keys=True))
if __name__=='__main__':main()
