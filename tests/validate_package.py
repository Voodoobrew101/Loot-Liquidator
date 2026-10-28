from pathlib import Path
import xml.etree.ElementTree as ET

root = Path('LootLiquidator')
manifest = [s.strip() for s in (root / 'LootLiquidator.toc').read_text().splitlines()
            if s.strip() and not s.lstrip().startswith('#')]
assert len(manifest) == len(set(manifest)), 'Duplicate TOC entry'
assert all((root / s).is_file() for s in manifest), 'Missing runtime file'
assert {s for s in manifest if s.endswith('.lua')} == {s.name for s in root.glob('*.lua')}
assert len(list(root.glob('*.lua'))) == 16
for name in manifest:
    assert '/' not in name and '\\' not in name, 'Runtime package must be self-contained'
    if name.endswith('.xml'):
        ET.parse(root / name)
assert not list(Path('.').glob('*.lua')), 'All runtime Lua belongs in LootLiquidator/'
# No runtime file loads build-time source or fetches data from the network.
for file in root.glob('*.lua'):
    text = file.read_text()
    assert 'loadfile(' not in text and 'dofile(' not in text, file
assert manifest.index('itemdb.lua') < manifest.index('Database.lua') < manifest.index('Core.lua')
assert manifest.index('Professions.lua') < manifest.index('Observations.lua') < manifest.index('ConversionEngine.lua')
print('PASS: installable LootLiquidator/ package, 16 Lua sources, manifest coverage/load order and XML')
