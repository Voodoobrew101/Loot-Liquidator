"""Check emitted conditional facts through the actual producer and UI consumer."""
from pathlib import Path
from collections import Counter
import json
import sys

HERE = Path(__file__).resolve().parent
RESEARCH = HERE.parents[4]
CODE = RESEARCH.parent / 'catalogue-backlog-pipeline-20261120'
sys.path.insert(0, str(CODE / 'tools'))
sys.path.insert(0, str(RESEARCH.parent / '.tools/python313'))
from lupa.lua51 import LuaRuntime
import reviewed_source_catalogue as producer

policy = json.loads((HERE / 'aure-cutoff-addendum-admitted-models.json').read_text(encoding='utf-8'))
original = producer.catalogue_policies
try:
    producer.catalogue_policies = lambda snapshot: [policy]
    consumed = producer.reviewed_context_facts(RESEARCH)
finally:
    producer.catalogue_policies = original
assert len(consumed['facts']) == 1575
assert {f['factID'] for f in consumed['facts']} == {f['factID'] for f in policy['facts']}
runtime = LuaRuntime(unpack_returned_tuples=True)
runtime.globals().consumer = (CODE / 'LootLiquidator/ReviewedSourceFacts.lua').as_posix()
runtime.execute(r"""
local LL={};assert(loadfile(consumer))('LL',LL)
LL.db={professionTooltipProfiles={}}
function LL:EvidenceSourceWeight()return self.enabled and 1 or 0 end
function LL:ProcessingDataMode()return 1 end
function validateFact(fact)
    LL.enabled=true
    LL.ItemDB={reviewedSourceFacts={schemaVersion=1,facts={fact}}}
    local f={id=fact.inputItemID,expansionID=11,classID=4,quality=3}
    local option={name='Disenchant',recipeID=13262}
    local result=LL:ReviewedProcessingSourceFacts(f,option)
    assert(#result==1 and result[1].sourceContextOnly and not result[1].targetProfileAdjusted,fact.factID)
    assert(result[1].expectedQuantity==nil and result[1].chance==nil and result[1].samples==nil,'source quantity leaked as EV/P/N')
    local lines=table.concat(LL:ReviewedProcessingSourceFactLines(f,{option}),'\n')
    assert(lines:find('units per positive result',1,true) and lines:find('Confidence 0%',1,true),'missing actual rendered dimension')
    assert(lines:find(fact.nativeInputVariant,1,true),'source variant context was lost')
    assert(#LL:ReviewedProcessingSourceFacts(f,option,nil,2)==0,'personal-only leak')
    LL.enabled=false;assert(#LL:ReviewedProcessingSourceFacts(f,option)==0,'disabled-source leak')
    LL.enabled=true;f.id=f.id+1000000
    assert(#LL:ReviewedProcessingSourceFacts(f,option)==0,'wrong input matched')
    f.id=fact.inputItemID
    assert(#LL:ReviewedProcessingSourceFacts(f,{name='Mill'})==0,'wrong method matched')
    LL.db.professionTooltipProfiles.Enchanting='@hide'
    assert(#LL:ReviewedProcessingSourceFacts(f,option)==0,'hidden profession leak')
    LL.db.professionTooltipProfiles.Enchanting=nil
end
""")


def table(value):
    if isinstance(value, dict):
        out = runtime.table()
        for key, child in value.items():
            out[key] = table(child)
        return out
    if isinstance(value, list):
        return runtime.table_from([table(child) for child in value])
    return value


for fact in consumed['facts']:
    assert fact['confidence0to100'] == 0 and fact['sourceSupportConfidence'] <= 20
    assert fact.get('expansionID') is None
    runtime.globals().validateFact(table(fact))
dispositions = json.loads((HERE / 'aure-cutoff-addendum-proposal-dispositions.json').read_text(encoding='utf-8'))
counts = Counter(d['decision'] for d in dispositions['decisions'])
assert counts == {'SOURCE_FACT': 1575, 'REJECTED_CURRENT_NUMERICAL': 45}
print(json.dumps({'producerFactsConsumed': 1575, 'actualFactsQueryAndLinesRendered': 1575,
    'negativeChecksPerFact': 5, 'terminalProposals': len(dispositions['decisions']),
    'groupLookupRejections': 45, 'newUnconditionalModels': 0, 'newObservedSamples': 0,
    'fullCombinedGeneratedItemDBVerified': False}, sort_keys=True))
