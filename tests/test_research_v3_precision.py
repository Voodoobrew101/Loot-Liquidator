"""Coupled probability/quantity values survive Python-to-Lua export unchanged."""
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, 'tools')
import research_v3_to_baselines as v3
from evidence_to_baselines import lua

records = []
for index, (hits, casts, stack) in enumerate([(2, 41, 2), (3, 29, 2), (3, 41, 3),
                                              (1, 44, 2), (4, 31, 2)]):
    material = v3.material(100 + index, [{
        'simulation': {'chanceBeta': [hits + .5, casts - hits + .5]},
        'chanceSource': 'measured', 'averageSource': 'measured',
        'rangeSource': 'observed', 'average': hits * stack / casts,
        'range': [stack, stack], 'studyCasts': casts,
    }])
    assert abs(material['dropChance']['value'] - hits / casts) < 1e-12
    assert abs(material['expectedQuantity']['value'] - hits * stack / casts) < 1e-12
    material.pop('_casts')
    records.append(dict(recordID=f'precision:{index}', studyID=f'precision:{index}',
                        source='precision regression fixture', sourceKey='itemdb',
                        method='Disenchant', inputItemID=200 + index, inputCount=1,
                        materials=[material]))

# Exercise the actual runtime validator after serialization, including its
# rejection of inconsistent evidence. Do not relax the validator tolerance.
script = "local LL={}\nassert(loadfile('LootLiquidator/Database.lua'))('LootLiquidator',LL)\n"
script += 'local db=' + lua(dict(schemaVersion=1, processing=records)) + '\n'
script += "local ok,why=LL:ValidateItemDB(db); assert(ok,why)\n"
script += "local m=db.processing[1].materials[1]\n"
script += "m.expectedQuantity.value=m.expectedQuantity.value+0.001\n"
script += "local ok,why=LL:ValidateItemDB(db)\n"
script += "assert(not ok and why=='Contradictory probability/quantity fields')\n"
script += "print('PASS: five fixed-stack precision regressions; inconsistent evidence still rejected')\n"
lua_bin = shutil.which('lua5.1') or '/workspace/.loot-liquidator-tools/lua/usr/bin/lua5.1'
with tempfile.TemporaryDirectory() as tmp:
    path = Path(tmp) / 'precision.lua'
    path.write_text(script)
    subprocess.run([lua_bin, str(path)], check=True)
