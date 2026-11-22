"""Replay the real Frostwoven Belt cohorts through producer and Lua valuation."""
import copy
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, 'tools')
import research_v3_to_baselines as v3
from research_v3_evidence import build_field_support

rows = json.loads(Path('tests/fixtures/observed-bound-cohorts.json').read_text(encoding='utf-8'))['rows']
original = copy.deepcopy(rows)
calculator = v3.load_calculator(Path('tests/fixtures/research-golden/v3-snapshot'))
estimates, _, _ = build_field_support(calculator, rows, calculator.name_maps(rows))
assert len(estimates) == 1
material = v3.material(34054, estimates)
assert material['dropChance']['value'] == 1 and material['expectedQuantity']['value'] == 3
assert material['minQuantity']['value'] == 1 and material['maxQuantity']['value'] == 2
assert material['maxQuantity']['basis'] == 'observed-sample'
proof = material['observedBoundIndependence']
assert proof['version'] == 1 and proof['field'] == 'maxQuantity'
assert proof['meanCohorts'] and proof['boundCohorts']
assert not set(proof['meanCohorts']) & set(proof['boundCohorts'])
assert 'heldExpectedQuantity' not in material and 'heldDropChance' not in material
assert rows == original, 'Source rows and their observed range remain immutable'
assert material == v3.material(34054, estimates), 'Cohort identities are deterministic'

record = {'recordID': 'evidence:v3:Disenchant:41522:x1', 'studyID': 'frozen-two-source-regression',
          'sourceKey': 'itemdb', 'source': 'Frozen original Frostwoven Belt reports',
          'method': 'Disenchant', 'inputItemID': 41522, 'inputCount': 1,
          'fieldSpecificEvidence': True, 'materials': [{k: v for k, v in material.items() if not k.startswith('_')}]}
code = r'''
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
GetBuildInfo=function()return '12.1.5','123456','',120105 end
GetTime=function()return 100 end
local LL={db={source_personal_enabled=false,source_imported_enabled=false,
    source_legacy_enabled=false,source_reference_enabled=false}}
for _,name in ipairs({'Database.lua','ConversionEngine.lua'})do
    assert(loadfile('LootLiquidator/'..name))('LL',LL)
end
LL.GetOutputPrice=function()return 100 end
LL.ItemDB={schemaVersion=1,processing={RECORD}}
assert(LL:InitializeItemDB(),LL.itemDBError)
local function model()
    LL._processingModelCache=nil
    return assert(LL:ComputeEvidenceModel({id=41522},{name='Disenchant',inputCount=1},nil,1,{}))
end
local result=model()
local m=result.materials[1]
assert(m.chance==1 and math.abs(m.expectedQuantity-3)<1e-9 and m.minQuantity==1 and m.maxQuantity==2)
assert(m.observedBoundIndependence and not m.inconsistentFields and not m.filled)
assert(math.abs(LL:ValueProcessingModel(result,0,true)-300)<1e-9 and not result.partialPrice,
    'The real measured mean supplies the full quote without inventing/extending the observed range')
assert(LL.ItemDB.processing[1].materials[1].expectedQuantity.value==3)
LL.ApplyProfessionModel=function(_,_,_,source)
    local out=source.materials[1]
    out.expectedQuantity=6;out.chance=nil;out.minQuantity=nil;out.maxQuantity=nil
    out.expectationTransformed=true
    return source
end
result=model();m=result.materials[1]
assert(math.abs(m.expectedQuantity-6)<1e-9 and m.chance==nil and m.minQuantity==nil and m.maxQuantity==nil
    and not m.observedBoundIndependence,'A changed mean cannot inherit the source occurrence or bound exception')
assert(LL.ItemDB.processing[1].materials[1].expectedQuantity.value==3,'Projection cannot mutate source evidence')
print('PASS: real independent observed-bound cohorts retain measured P/mean/range and complete valuation; transformed distributions stay unsupported')
'''.replace('RECORD', v3.lua(record))
lua = os.environ.get('LUA_BIN') or shutil.which('lua5.1') or shutil.which('lua')
if lua:
    subprocess.run([lua, '-'], input=code, text=True, check=True)
else:
    sys.path.insert(0, str(Path.cwd().parent/'.tools/python313'))
    from lupa.lua51 import LuaRuntime
    LuaRuntime(unpack_returned_tuples=True).execute(code)
