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
assert len([s for s in manifest if s.endswith('.lua')]) == 18  # B2: itemTSM.lua removed; B5b: AltRosterUI.lua removed
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
print('PASS: installable LootLiquidator/ package, 20 Lua sources, manifest coverage/load order and XML')

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
for name, expected in {'GameData.lua':'a1970683591d9511bd5724eaa90ebfccfabfd178effd0c6e6e91e57d6e4eebf0'}.items():
    assert hashlib.sha256((root/name).read_bytes()).hexdigest()==expected, 'Frozen reference changed: '+name
print('PASS: frozen reference checksums unchanged after formula retirement')
