"""Reproduce the exact Eoghals cutoff review and real Lua query/tooltip checks.

Reads preserved observations only. Writes this lane's four new catalogue files
and its assignment input; it does not edit an original observation or old review.
"""
import argparse
from collections import Counter, defaultdict
from copy import deepcopy
from hashlib import sha256
import json
from pathlib import Path
import re
import sys

sys.dont_write_bytecode = True
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--code-root', type=Path, required=True)
parser.add_argument('--research-root', type=Path, required=True)
parser.add_argument('--workspace', type=Path, required=True)
args = parser.parse_args()
code, research, workspace = (p.resolve() for p in (args.code_root, args.research_root, args.workspace))
sys.path.insert(0, str(code / 'tools'))
sys.path.insert(0, str(workspace / '.tools/python313'))
from reviewed_source_catalogue import canonical_hash, source_rows
from research_v3_to_baselines import load_calculator
from lupa.lua51 import LuaRuntime

folder = research / 'research/v3/evidence/master/backlog-catalogue-20261120'
prefix = 'eoghals-cutoff-addendum'
snapshot = 'e8327f30b82a16a19e6df43820277383085bcd3a'
cutoff = '0cd0bad8867e7a8d909b4ecae74f6136a3e23d42'
native_pin = '5918ca3e44f6e4bba9071731ab28be3189498001'
source_key = f'github.com/alex-berliner/wow_classic_de_table/blob/{native_pin}/dbfiles/eoghals_log.lua'
native_receipt = 'research/v3/evidence/master/20261120T0900-eoghals-native-enchantrix-821-row-admission-review.md'
review_path = str(folder.relative_to(research) / (prefix + '-review.json')).replace('\\', '/')
candidate_path = workspace / '.validation/source-backlog-20261120/current-e832/candidate-rows.jsonl'
candidates = [json.loads(line) for line in candidate_path.read_text(encoding='utf-8').splitlines()
              if line.strip() and json.loads(line)['sourceKey'] == source_key]
assert len(candidates) == 1665 and len({r['locator'] for r in candidates}) == 1665
effective = {(r['_file'], r['id']): r for r in load_calculator(research).load_reviewed_source_rows()}
cache = {}
groups = defaultdict(list)
for candidate in candidates:
    file = candidate['sourceFile']
    lines = cache.setdefault(file, (research / file).read_text(encoding='utf-8').splitlines())
    row = json.loads(lines[candidate['line'] - 1])
    assert row['id'] == candidate['recordID']
    assert canonical_hash(row) == candidate['rawSHA256']
    assert canonical_hash(effective[(file, row['id'])]) == candidate['effectiveSHA256']
    variant = re.search(r'\[\s*"(\d+:\d+:-?\d+)"\s*\]', row['quote'] + ' ' + row['notes']).group(1)
    assert int(variant.split(':')[0]) == row['inputItemID']
    hits, units = row['castsWithDrop'], row['totalQuantity']
    assert isinstance(hits, int) and hits > 0 and isinstance(units, int) and units >= hits
    assert row['casts'] is None and row['inputsPerCast'] is None
    assert row['averageShown'] is None and row['percentShown'] is None and row['histogram'] is None
    groups[(variant, row['outputItemID'], hits, units)].append((candidate, row))
assert len(groups) == 821 and Counter(map(len, groups.values())) == {2: 798, 3: 23}
assert len({key[0] for key in groups}) == 792
assert len({int(key[0].split(':')[0]) for key in groups}) == 583
assert sum(key[2] for key in groups) == 1092 and sum(key[3] for key in groups) == 2128

facts, proposals, decisions, rows = [], [], [], []
constraints = [
    'Conditional material quantity only; no unconditional EV or probability is identified.',
    'Trailing source zero is a stored tuple field, not an observed zero-output event.',
    'Exact source item variant is retained as historical context, not a verified current target match.',
    'Local/grouped/derived views are the same source cohort and must not add independent observations.',
    'Original client/build/date, skill/specification/stats, full casts and current Retail eligibility remain unknown.',
]
for (variant, output, hits, units), copies in sorted(groups.items()):
    copies.sort(key=lambda item: (not ('0846' in item[0]['sourceFile']), item[0]['locator']))
    primary_candidate, primary = copies[0]
    assert '0846' in primary_candidate['sourceFile']
    key = sha256(f'{source_key}|{variant}|{output}|{hits}|{units}'.encode()).hexdigest()[:24]
    fact_id = 'source-fact:eoghals-cutoff:' + key
    refs = [{'sourceFile': c['sourceFile'], 'line': c['line'], 'sourceRecordID': c['recordID'],
             'rawSHA256': c['rawSHA256'], 'effectiveSHA256': c['effectiveSHA256']} for c, _ in copies]
    proof, reason = source_rows(research, refs, effective=effective)
    assert proof is not None and reason is None
    profile = {name: primary.get(name) for name in ('skill', 'specialization', 'stats', 'patch', 'dataDate')}
    profile['published'] = primary['source'].get('published')
    fact = {
        'factID': fact_id, 'method': 'Disenchant', 'inputItemID': primary['inputItemID'],
        'outputItemID': output, 'outputName': primary['outputName'],
        'metric': 'conditionalMeanUnitsPerPositiveEvent', 'value': units / hits,
        'unit': 'positive-material-event', 'confidence0to100': 0, 'sourceSupportConfidence': 20,
        'sourceKey': 'itemdb', 'sourceURL': primary['source']['url'],
        'sourceStudyKey': primary['studyKey'], 'sourceProfile': profile,
        'nativeInputVariant': variant, 'sourceRows': refs,
        'sourceContextOnly': True, 'targetProfileAdjusted': False,
        'referenceConditions': {'sourceEpoch': 'Historical Vanilla-level source; original client/build/date unknown',
                                'quantityBasis': 'material units divided by positive material sightings',
                                'sourceInput': primary['inputName']},
        'reportedObservationCounts': {'sourcePositiveEvents': hits, 'sourceMaterialUnits': units,
                                      'measuredCasts': None, 'sourceTableDenominator': None},
        'derivation': {'kind': 'positive-event-ratio', 'numerator': units, 'denominator': hits,
                       'denominatorMeaning': 'positive-material-events'},
        'sourceFacts': {'quote': primary['quote'], 'notes': primary['notes']},
        'economicPolicy': 'item-identity-does-not-prove-current-tradability',
        'constraints': constraints, 'modelingAssumptions': [], 'proposalIDs': [],
    }
    for candidate, original in copies:
        proposal_id = 'eoghals-cutoff-' + sha256(candidate['locator'].encode()).hexdigest()[:24]
        fact['proposalIDs'].append(proposal_id)
        alias = candidate['locator'] != primary_candidate['locator']
        proposal = {
            'proposalID': proposal_id, 'sourceKey': source_key, 'sourceURL': primary['source']['url'],
            'locator': candidate['locator'], 'recordID': candidate['recordID'],
            'studyKey': original['studyKey'], 'canonicalCohortKey': primary['studyKey'],
            'canonicalSourceLocator': primary_candidate['locator'], 'nativeInputVariant': variant,
            'metric': fact['metric'], 'value': units / hits, 'arithmetic': f'{units}/{hits}',
            'unit': 'units-per-positive-material-event',
            'input': {'inputItemID': primary['inputItemID'], 'inputName': primary['inputName']},
            'output': {'itemID': output, 'name': primary['outputName']},
            'sourceProfile': profile, 'sourcePositiveEvents': hits, 'sourceMaterialUnits': units,
            'measuredCasts': None, 'modelingConfidence': 0,
            'sourceRows': [next(ref for ref in refs if ref['sourceFile'] == candidate['sourceFile'])],
            'sourceFacts': {'quote': original['quote'], 'notes': original['notes']},
            'duplicateOfCanonicalTuple': alias, 'constraints': constraints,
        }
        proposals.append(proposal)
        decisions.append({
            'proposalID': proposal_id, 'sourceKey': source_key, 'locator': candidate['locator'],
            'sourceStudyKey': primary['studyKey'], 'metric': fact['metric'],
            'decision': 'ALREADY_REPRESENTED' if alias else 'SOURCE_FACT',
            'modelIDs': [], 'factIDs': [fact_id], 'receiptPath': review_path,
            'reason': ('Exact variant/output/positive-event/material-unit tuple matches the canonical native transcription; '
                       'retain its row proof on that same informational fact, with no second independent evidence weight.'
                       if alias else 'Original positive-event denominator supports units per positive material result. '
                       'The missing all-operation denominator does not erase this conditional quantity.'),
        })
        rows.append({
            'locator': candidate['locator'], 'recordID': candidate['recordID'],
            'rawSHA256': candidate['rawSHA256'], 'effectiveSHA256': candidate['effectiveSHA256'],
            'decision': 'EXACT_DUPLICATE_CONDITIONAL_FACT' if alias else 'ADMIT_CONDITIONAL_SOURCE_FACT',
            'canonicalSourceLocator': primary_candidate['locator'], 'factIDs': [fact_id],
            'proposalIDs': [proposal_id], 'nativeInputVariant': variant,
            'fields': {'conditionalMeanUnitsPerPositiveEvent': {'decision': 'SOURCE_FACT', 'value': units / hits,
                                                                'numerator': units, 'positiveEventDenominator': hits},
                       'expectedQuantity': {'decision': 'REJECTED_CURRENT_NUMERICAL',
                                            'reason': 'No completed-cast or processed-input denominator; positive sightings are conditional events.'},
                       'dropChance': {'decision': 'REJECTED_CURRENT_NUMERICAL',
                                      'reason': 'No all-attempt denominator or validated zero-event ledger.'},
                       'stackRangeOrHistogram': {'decision': 'REJECTED_CURRENT_NUMERICAL',
                                                'reason': 'Material totals and sightings do not identify event-level extrema or bins.'}},
            'futureEvidenceTrigger': 'An original all-attempt ledger, per-event stack observations, or source client/profile/eligibility proof resolving the precise missing field; never infer casts from positive counters.',
        })
    facts.append(fact)

# Actual Lua 5.1 database policy, public fact query and recommendation tooltip.
runtime = LuaRuntime(unpack_returned_tuples=True)
def table(value):
    if isinstance(value, dict):
        out = runtime.table()
        for key, child in value.items():
            if child is not None: out[key] = table(child)
        return out
    if isinstance(value, list): return runtime.table_from([table(child) for child in value])
    return value
runtime.globals().code_root = str(code).replace('\\', '/')
runtime.execute(r'''
LL={db={tooltipDetail=3,showResearchDetails=true}}
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
GetBuildInfo=function()return '12.1.5','70961','',120105 end
for _,file in ipairs({'Database.lua','Observations.lua','ReviewedSourceFacts.lua','Badges.lua'})do
 assert(loadfile(code_root..'/LootLiquidator/'..file))('LootLiquidator',LL)
end
LL.MarkupColor=function()return ''end
LL.Money=function(_,v)return tostring(v)..' copper'end
LL.ProfessionProgression=function()return {}end
function checkFact(fact)
 LL.ItemDB={reviewedSourceFacts={schemaVersion=1,facts={fact}}}
 local f={id=fact.inputItemID,expansionID=0,classID=4,quality=2,nativeInputVariant='target:unknown'}
 local option={name='Disenchant',profession='Enchanting',available=false,eligibleInput=false,
   value=nil,recipeID=0,yieldModel={materials={},confidence=0}}
 local list=LL:ReviewedProcessingSourceFacts(f,option,{skill=999,simulated=true})
 assert(#list==1 and math.abs(list[1].value-fact.value)<1e-12,'conditional query lost value')
 assert(list[1].nativeInputVariant==fact.nativeInputVariant and list[1].targetProfileAdjusted==false,'source scope lost')
 local tip={lines={}}
 function tip:AddLine(s)self.lines[#self.lines+1]=s end
 function tip:AddDoubleLine(l,r)self.lines[#self.lines+1]=l..' | '..r end
 LL:AppendRecommendationTooltip(tip,{facts=f,conversionOptions={option}})
 local text=table.concat(tip.lines,'\n')
 assert(text:find('units per positive result',1,true) and text:find('Confidence 0%',1,true),'actual tooltip lost dimension/confidence')
 assert(text:find(fact.nativeInputVariant,1,true),'actual tooltip lost source variant')
 assert(not text:find('999',1,true) and not text:find('copper',1,true),'source context joined target/gold')
 for _,label in ipairs({'estimate','provisional','unquantified',' casts'})do assert(not text:find(label,1,true),'invented label/casts')end
 assert(option.available==false and option.eligibleInput==false and option.value==nil and #option.yieldModel.materials==0,'source fact created action/EV')
 assert(#LL:ReviewedProcessingSourceFacts(f,option,nil,2)==0,'personal-only leak')
 LL.db.source_itemdb_enabled=false;assert(#LL:ReviewedProcessingSourceFacts(f,option)==0,'disabled ItemDB leak');LL.db.source_itemdb_enabled=nil
 LL.db.source_itemdb_weight=0;assert(#LL:ReviewedProcessingSourceFacts(f,option)==0,'zero weight leak');LL.db.source_itemdb_weight=nil
 LL.db.disenchantDataMode=2;assert(#LL:ReviewedProcessingSourceFacts(f,option)==0,'personal-only setting leak');LL.db.disenchantDataMode=nil
 LL.db.professionTooltipProfiles={Enchanting='@hide'};assert(#LL:ReviewedProcessingSourceFacts(f,option)==0,'hidden profile leak');LL.db.professionTooltipProfiles={}
 assert(#LL:ReviewedProcessingSourceFacts(f,{name='Prospect'})==0,'wrong method leak')
 assert(#LL:ReviewedProcessingSourceFacts({id=999999999},option)==0,'wrong item leak')
 assert(fact.reportedObservationCounts.measuredCasts==nil and fact.confidence0to100==0,'invented measurement')
end
''')
for fact in facts: runtime.globals().checkFact(table(fact))
runtime.globals().LL.ItemDB = table({'reviewedSourceFacts': {'schemaVersion': 1, 'facts': facts}})
counts = Counter(fact['inputItemID'] for fact in facts)
for item, count in counts.items():
    got = runtime.globals().LL.ReviewedProcessingSourceFacts(runtime.globals().LL, table({'id': item}), table({'name': 'Disenchant'}))
    assert len(got) == count

summary = {
    'sourceKeys': 1, 'candidateRows': 1665, 'canonicalConditionalFacts': 821,
    'aliasRows': 844, 'nativeVariants': 792, 'inputItemIDs': 583, 'outputItemIDs': 16,
    'sourcePositiveEvents': 1092, 'sourceMaterialUnits': 2128, 'measuredCasts': None,
    'observedSamplesAdded': 0, 'unconditionalExpectedQuantityModels': 0, 'occurrenceModels': 0,
    'coverageMissing': [], 'coverageExtra': [], 'duplicateAssignedLocators': 0,
    'perFactRealPolicyQueryAndTooltipChecksPassed': len(facts),
    'allFactsCombinedInputQueriesPassed': len(counts), 'fullDatabaseEmbeddingVerified': False,
    'sourceRowsPhysicalAndCorrectedProofsPassed': 1665,
    'nativeReceiptPath': native_receipt,
    'nativeReceiptSHA256': sha256((research / native_receipt).read_bytes()).hexdigest(),
    'nativeGitBlob': 'f1ad158e7fda46178406a5fa4df2a03e14820cea',
    'candidateLocatorSetSHA256': canonical_hash({'locators': sorted(c['locator'] for c in candidates)}),
}
common = {'schemaVersion': 1, 'lane': prefix, 'reviewDate': '2026-11-20', 'reviewer': 'published_dust_crystal',
          'researchSnapshot': snapshot, 'researchCutoff': cutoff, 'upstreamNativePin': native_pin,
          'summary': summary}
review = dict(common, sources=[{
    'sourceKey': source_key, 'rawURLs': ['https://' + source_key],
    'decision': 'REVIEWED_ALL_ASSIGNED_SCOPES',
    'sourceConclusion': 'Prior cleared-source EV rejection omitted usable conditional Q/H. Retain821 canonical informational facts, deduplicate844 transcription aliases, and keep all1665 exact row proofs. All-operation rate/zero/stack/profile/current-eligibility unknowns remain distinct.',
    'existingReviewFactsCredited': [{'path': native_receipt, 'sha256': summary['nativeReceiptSHA256'],
                                    'nativeSourceGitBlob': summary['nativeGitBlob']}],
    'coveredLocators': sorted(c['locator'] for c in candidates),
    'rows': sorted(rows, key=lambda r: r['locator']),
}])
def write(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, sort_keys=True, indent=2, allow_nan=False) + '\n', encoding='utf-8', newline='\n')
write(folder / (prefix + '-review.json'), review)
write(folder / (prefix + '-proposals.json'), dict(common, proposals=sorted(proposals, key=lambda p: p['proposalID'])))
write(folder / (prefix + '-admitted-models.json'), {
    'schemaVersion': 1, 'lane': prefix, 'revision': 'reviewed-eoghals-cutoff/1',
    'summary': summary, 'models': [], 'facts': sorted(facts, key=lambda f: f['factID']), 'sourceFieldExclusions': [],
})
write(folder / (prefix + '-proposal-dispositions.json'), {
    'schemaVersion': 1, 'lane': prefix, 'revision': 'reviewed-eoghals-cutoff/1', 'summary': summary,
    'decisions': sorted(decisions, key=lambda d: d['proposalID']),
})
assignment = {'schemaVersion': 1, 'scope': 'Previously cleared source within the original cutoff; recover supported conditional fields, not a new post-cutoff source',
              'researchSnapshot': snapshot, 'currentResearchBase': cutoff, 'lane': prefix,
              'sources': [{'sourceKey': source_key, 'rawURLs': ['https://' + source_key],
                           'explicitLeadStillPending': False, 'candidateRows': candidates,
                           'masterReviewFacts': [{'path': native_receipt, 'sha256': summary['nativeReceiptSHA256']}]}]}
write(workspace / '.validation/backlog-closure-20261120/inputs/eoghals-cutoff-addendum.json', assignment)
print(json.dumps(summary, sort_keys=True))
for suffix in ('review', 'proposals', 'admitted-models', 'proposal-dispositions'):
    path = folder / (prefix + '-' + suffix + '.json')
    print(path.name, sha256(path.read_bytes()).hexdigest())
