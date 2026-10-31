from pathlib import Path
import xml.etree.ElementTree as ET

root = Path('LootLiquidator')
toc_lines = (root / 'LootLiquidator.toc').read_text().splitlines()
versions = [line.removeprefix('## Version:').strip() for line in toc_lines
            if line.startswith('## Version:')]
assert len(versions) == 1 and versions[0], 'TOC must declare one non-empty addon version'
manifest = [s.strip() for s in (root / 'LootLiquidator.toc').read_text().splitlines()
            if s.strip() and not s.lstrip().startswith('#')]
assert len(manifest) == len(set(manifest)), 'Duplicate TOC entry'
assert all((root / s).is_file() for s in manifest), 'Missing runtime file'
assert {s for s in manifest if s.endswith('.lua')} == {s.name for s in root.glob('*.lua') if s.name != 'itemdb.lua'}
assert len([s for s in manifest if s.endswith('.lua')]) == 17  # B2: itemTSM.lua removed; B5b: AltRosterUI.lua removed; B7: ImportedResults.lua added; C3: GameData.lua + DB2Restrictions.lua folded into ItemDB
assert 'itemdb.lua' not in manifest, 'Research-only schema must not replace the runtime database'
for name in manifest:
    assert '/' not in name and '\\' not in name, 'Runtime package must be self-contained'
    if name.endswith('.xml'):
        ET.parse(root / name)
assert not list(Path('.').glob('*.lua')), 'All runtime Lua belongs in LootLiquidator/'
# No runtime file loads build-time source or fetches data from the network.
for file in root.glob('*.lua'):
    text = file.read_text()
    assert 'loadfile(' not in text and 'dofile(' not in text, file
assert manifest.index('ItemDBRuntime.lua') < manifest.index('Database.lua') < manifest.index('Core.lua')
assert manifest.index('Professions.lua') < manifest.index('Observations.lua') < manifest.index('CraftRecording.lua') < manifest.index('ConversionEngine.lua')
print('PASS: installable LootLiquidator/ package, 17 Lua sources, manifest coverage/load order and XML')

import hashlib
import json
provenance = json.loads(Path('database/research-itemdb-source.json').read_text())
assert hashlib.sha256(Path('database/research/itemdb.lua').read_bytes()).hexdigest() == provenance['sha256'], 'Research copy differs from pinned source'
print('PASS: latest research itemdb copy checksum and runtime separation')

# Frozen references retain the exact pre-cleanup values; old formulas are retired.
assert not Path('database/sources/StatYieldProfiles.lua').exists()
assert not Path('database/sources/GameData.lua').exists()
# B2: the frozen TSM conversion table is no longer shipped (TSM = AH prices only).
assert not (root/'itemTSM.lua').exists(), 'itemTSM.lua must not ship (B2)'
# C3: GameData.lua and DB2Restrictions.lua no longer ship; their data is inside
# ItemDBRuntime.lua. The old disenchant estimates must be byte-identical to the
# encoded table GameData.lua carried (same sha256 as before the move).
for name in ('GameData.lua','DB2Restrictions.lua'):
    assert not (root/name).exists(), name+' must not ship (C3)'
runtime_lines = (root/'ItemDBRuntime.lua').read_text().splitlines()
legacy = [l for l in runtime_lines if l.startswith('LL.ItemDB.legacy=')]
assert len(legacy) == 1, 'ItemDB must carry the old estimates once'
assert hashlib.sha256(legacy[0].split('=',1)[1].encode()).hexdigest() == \
    'e97a947b5c8690c69e1f37aa85437a5d824aa14e065907e3d5080450e336bc08', 'Frozen reference changed: legacy'
assert sum(l.startswith('LL.ItemDB.restrictions=') for l in runtime_lines) == 1
print('PASS: frozen reference checksums unchanged after formula retirement')
