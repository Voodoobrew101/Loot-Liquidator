"""Verify every DE-A emitted fact through the actual query/line consumer.

Usage: python verify_runtime_facts.py --code-root PATH --lupa-path PATH
This uses synthetic matching item facts, not new game observations, prices,
source admission, or proof of current-patch historical applicability.
"""
import argparse
from collections import Counter
import json
from pathlib import Path
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--code-root', required=True, type=Path)
parser.add_argument('--lupa-path', type=Path)
args = parser.parse_args()
if args.lupa_path:
    sys.path.insert(0, str(args.lupa_path))
from lupa.lua51 import LuaRuntime

document = json.loads((Path(__file__).parents[1] / 'disenchant-a-admitted-models.json').read_text(encoding='utf-8'))
runtime = LuaRuntime(unpack_returned_tuples=True)
runtime.globals().consumer = str(args.code_root / 'LootLiquidator/ReviewedSourceFacts.lua').replace('\\', '/')
runtime.execute(r"""
LL={};assert(loadfile(consumer))('LootLiquidator',LL)
function LL:EvidenceSourceWeight() return self.enabled and 1 or 0 end
function LL:ProcessingDataMode() return 1 end
LL.db={professionTooltipProfiles={}}
function checkFact(fact)
    LL.enabled=true
    LL.ItemDB={reviewedSourceFacts={schemaVersion=1,facts={fact}}}
    local scope=fact.gearScope or {}
    local f={id=fact.inputItemID or(fact.inputFamilyIDs and fact.inputFamilyIDs[1])or 999999,
        expansionID=fact.expansionID or scope.expansionID,quality=fact.inputRarity or scope.rarity or 3,
        classID=fact.inputClassID or scope.classID or 4,reagentQuality=fact.inputQualityRank}
    local option={name='Disenchant',recipeID=13262}
    assert(#LL:ReviewedProcessingSourceFacts(f,option)==1,fact.factID..': query lost source fact')
    local lines=LL:ReviewedProcessingSourceFactLines(f,{option})
    assert(#lines>=2 and table.concat(lines,'\n'):find('Confidence 0%%'),fact.factID..': no rendered dimension/confidence')
    assert(#LL:ReviewedProcessingSourceFacts(f,option,nil,2)==0,fact.factID..': personal-only leak')
    LL.enabled=false
    assert(#LL:ReviewedProcessingSourceFacts(f,option)==0,fact.factID..': disabled source leak')
    LL.enabled=true
    assert(#LL:ReviewedProcessingSourceFacts(f,{name='Mill'})==0,fact.factID..': method scope leak')
    LL.db.professionTooltipProfiles.Enchanting='@hide'
    assert(#LL:ReviewedProcessingSourceFacts(f,option)==0,fact.factID..': hidden profession leak')
    LL.db.professionTooltipProfiles.Enchanting=nil
    return #lines
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


metrics = Counter()
for fact in document['facts']:
    runtime.globals().checkFact(table(fact))
    metrics[fact['metric']] += 1
sys.path.insert(0, str(args.code_root / 'tools'))
from reviewed_source_catalogue import model_record
spec = next(model for model in document['models'] if model['sourceStudyKey'] == 'reddit-1f9qado-blood-elf-297-hammers')
record = model_record(spec, spec['sourceRows'], document['revision'])
assert record['samples'] == 0 and record['sampleSizeKnown'] is False
runtime.globals().reviewed_record = table(record)
runtime.globals().quality_consumer = str(args.code_root / 'LootLiquidator/ProfessionCalculations.lua').replace('\\', '/')
runtime.globals().profile_rules = str(args.code_root / 'database/profession-profile-rules.lua').replace('\\', '/')
runtime.globals().baseline_builder = str(args.code_root / 'tools/profession_baselines.lua').replace('\\', '/')
anchor_result = runtime.execute(r"""
local Q={};assert(loadfile(quality_consumer))('LL',Q)
Q.ItemDB={professionProfiles=assert(loadfile(profile_rules))()}
local db={processing={reviewed_record},professionProfiles=Q.ItemDB.professionProfiles}
local built=assert(loadfile(baseline_builder))()(db,Q)
local baseline=assert(built[reviewed_record.recordID],'reviewed297model has no compiled baseline')
local option={name='Disenchant',recipeID=13262,inputCount=1,profession='Enchanting'}
local f={expansionID=10,quality=2,classID=2}
local source=Q:ProfessionProfileParameters('Enchanting',10,reviewed_record.baselineProfile,option,f)
assert(source.skill==290,'145native skill plus145native specialization applied once')
local roundtrip=assert(Q:ProjectProfessionBaseline(baseline,source,option))
for i,material in ipairs(roundtrip.materials) do
    assert(math.abs(material.expectedQuantity-reviewed_record.materials[i].expectedQuantity.value)<1e-9,'source rank means do not roundtrip')
    assert(material.chance==nil and material.samples==nil,'model fabricated source probability/samples')
end
local zero=Q:ProfessionProfileParameters('Enchanting',10,{skill=0,preSpecializationSkill=0,
    specializationPoints={},learnedSpecializations={},stats={}},option,f)
local projected=assert(Q:ProjectProfessionBaseline(baseline,zero,option))
for _,material in ipairs(projected.materials)do
    if material.id~=219946 then assert(material.expectedQuantity==0,'source maximum was used as the zero-quality distribution')end
end
local _,anchor=next(baseline.reviewedQualityAnchors.families)
assert(anchor and anchor.sourceProgress==1,'max source anchor was lost')
return {sourceSkill=source.skill,sourceMaximum=source.skillMaximum,sourceProgress=anchor.sourceProgress,
    sourceFamilyTotal=anchor.sourceFamilyTotal,normalizedFamilyTotal=anchor.normalizedFamilyTotal,
    activeObservedSamples=reviewed_record.samples,sourceRowAliases=#reviewed_record.reviewedPublishedPrior.sourceRows}
""")
anchor_result = {key: value for key, value in anchor_result.items()}
print(json.dumps({'factsQueriedAndRendered': len(document['facts']),
                  'perFactPolicyAndScopeNegativeChecks': 4,
                  'metrics': metrics, 'newObservedSamples': 0,
                  'reviewed297SourceAnchor': anchor_result,
                  'fullDatabaseEmbeddingVerified': False}, sort_keys=True))
