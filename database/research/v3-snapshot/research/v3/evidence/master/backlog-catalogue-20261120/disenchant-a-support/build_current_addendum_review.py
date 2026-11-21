"""Finite current-cutoff addendum: original native counters, not new studies."""
import collections
import hashlib
import json
import re
from pathlib import Path
HERE=Path(__file__).resolve().parent
OUT=HERE.parent
REPO=HERE.parents[5]
INPUT=REPO.parent/'.validation/backlog-closure-20261120/inputs/disenchant_a-current-addendum.json'
doc=json.loads(INPUT.read_text(encoding='utf-8'))
sources=[];proposals=[];covered=[];checks=[]
for source in doc['sources']:
    name=source['sourceKey'].rsplit('/',1)[-1].removesuffix('.lua')
    path=HERE/(name+'.lua.txt')
    body=path.read_text(encoding='utf-8')
    native=re.search(r'\bEnchantedLocal\s*=\s*\{(.*?)\n\}',body,re.S).group(1)
    entries=dict(re.findall(r'\["([^"\n]+)"\]\s*=\s*"([^"\n]+)"',native))
    archive_sha=hashlib.sha256(body.encode()).hexdigest()
    cohorts=collections.defaultdict(list)
    for row in source['candidateRows']:
        e=row['originalEvidenceRow'];n=e.get('casts');h=e['castsWithDrop'];q=e['totalQuantity']
        prose=(e.get('quote')or'')+' '+(e.get('notes')or'')
        keys=re.findall(r'(?<!\d)(\d+:\d+:-?\d+)(?!\d)',prose)
        key=next((k for k in keys if k.split(':')[0]==str(e['inputItemID'])and k in entries),None)
        value=f"{e['outputItemID']}:{h}:{q}:0"
        assert key in entries and value in entries[key].split(';'),(e['id'],key,value)
        assert n is None and h>0 and q>=h
        proof={'archive':str(path.relative_to(REPO)).replace('\\','/'),'archiveSHA256':archive_sha,'table':'EnchantedLocal','key':key,'tuple':value,'result':'EXACT_MATCH'}
        pid='dea-current-'+hashlib.sha256(row['locator'].encode()).hexdigest()[:18]
        proposal={'proposalID':pid,'sourceKey':source['sourceKey'],'studyKey':e['studyKey'],'canonicalCohortKey':e['studyKey'],'recordID':e['id'],'locator':row['locator'],'sourceURL':e['source']['url'],'metric':'conditionalMeanUnitsPerPositiveEvent','value':q/h,'arithmetic':f'{q}/{h}','unit':'units-per-positive-material-event','output':{'itemID':e['outputItemID'],'name':e['outputName'],'rank':e.get('outputRank')},'input':{'inputItemID':e['inputItemID'],'inputName':e.get('inputName'),'inputRank':e.get('inputRank'),'gearGroup':e.get('gearGroup')},'sourceProfile':{k:e.get(k)for k in ('skill','specialization','stats','patch','dataDate')},'nativeInputVariant':key,'measuredCasts':None,'sourcePositiveEvents':h,'sourceMaterialUnits':q,'modelingConfidence':0,'sourceRecordKind':e.get('sourceKind'),'economicPolicy':'item-identity-does-not-prove-current-tradability','nativeSourceVerification':proof,'sourceFacts':{'quote':e.get('quote'),'notes':e.get('notes')},'assumptions':[],'constraints':['Conditional quantity only, never unconditional EV or probability.','Native trailing0is not an observed-zero bin.','Exact source variant is not an asserted match to the current target variant/profile.','Contributor grouped/local/compiled views may overlap; never add them as independent casts.']}
        proposals.append(proposal)
        decision={'locator':row['locator'],'recordID':e['id'],'rawSHA256':row['rawSHA256'],'effectiveSHA256':row['effectiveSHA256'],'disposition':'CATALOGUED_CONDITIONAL_QUANTITY','sourceEvidenceExamined':True,'sourceFacts':{k:e.get(k)for k in ('inputItemID','inputName','outputItemID','outputName','casts','castsWithDrop','totalQuantity','quote','notes')},'proposalRefs':[pid],'nativeSourceVerification':proof,'fieldRejections':[{'field':'unconditionalQuantityAndProbability','decision':'CURRENT_NUMERICAL_REJECTION','reason':f'Exact original EnchantedLocal[{key}] records{h} positive material events and{q} units, with no full operation denominator, negatives, or joint event ledger. The source permits Q/H conditional amount only.','futureEvidenceTrigger':'A complete operation denominator and material attribution for the exact original variant/era, or an independently justified source probability; no Hsum cast assumption.'}]}
        cohorts[e['studyKey']].append(decision);covered.append(row['locator']);checks.append(dict(locator=row['locator'],**proof))
    sources.append({'sourceKey':source['sourceKey'],'rawURLs':source['sourceURLs'],'decision':'REVIEWED_ALL_ASSIGNED_SCOPES','coveredLocators':[r['locator']for r in source['candidateRows']],'cohorts':[{'studyKey':k,'decision':'REVIEWED_ALL_ASSIGNED_FIELDS','coveredLocators':[r['locator']for r in rs],'rowDecisions':rs}for k,rs in cohorts.items()]})
expected=[r['locator']for s in doc['sources']for r in s['candidateRows']]
assert len(sources)==6 and len(covered)==393 and len(set(covered))==393 and set(covered)==set(expected)
summary={'sourceKeys':6,'candidateRows':393,'cohorts':sum(len(s['cohorts'])for s in sources),'nativeRowsIndependentlyVerified':393,'numericFactProposals':393,'coverageMissing':[],'coverageExtra':[],'duplicateLocators':0,'candidateInputSHA256':hashlib.sha256(INPUT.read_bytes()).hexdigest(),'candidateLocatorSetSHA256':hashlib.sha256(json.dumps(sorted(covered),separators=(',',':')).encode()).hexdigest()}
common={'schemaVersion':1,'lane':'disenchant_a_current_addendum','reviewDate':'2026-11-20','researchSnapshot':doc['researchSnapshot'],'upstreamNativePin':'5918ca3e44f6e4bba9071731ab28be3189498001','reviewer':'controlled_study_design','confidencePolicy':'Exact original positive-only counters support conditionalQ/H with modelingConfidence0; measuredCasts remainsnull; no inventedN,probability,zerooutcomes,prices,or currentgameeligibility.','summary':summary}
(OUT/'disenchant-a-current-addendum-review.json').write_text(json.dumps(dict(common,sources=sources),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(OUT/'disenchant-a-current-addendum-proposals.json').write_text(json.dumps(dict(common,proposals=proposals),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(HERE/'current-addendum-coverage-proof.json').write_text(json.dumps(dict(summary,nativeChecks=checks),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(summary,indent=2))
