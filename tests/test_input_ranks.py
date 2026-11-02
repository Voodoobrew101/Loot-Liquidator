"""D1c7: audit ore IDs without guessing, discarding, or changing research."""
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, 'tools')
import audit_research_input_ranks as ranks

catalog = json.loads(ranks.CATALOG.read_text(encoding='utf-8'))
expected = {
    'Serevite Ore': {'1': 190395, '2': 190396, '3': 190394},
    'Draconium Ore': {'1': 189143, '2': 188658, '3': 190311},
    "Khaz'gorite Ore": {'1': 190312, '2': 190313, '3': 190314},
}
seen = set()
for name, mapping in expected.items():
    entry = catalog['items'][name]
    assert entry['ranks'] == mapping, name
    assert entry['source'].startswith('https://warcraft.wiki.gg/wiki/'), name
    for item in mapping.values():
        assert isinstance(item, int) and item > 0 and item not in seen
        seen.add(item)

probe = [
    {'type': 'drop', 'inputName': 'Serevite Ore', 'inputRank': 2, 'inputItemID': 190396},
    {'type': 'drop', 'inputName': 'Serevite Ore', 'inputRank': 2, 'inputItemID': 190395},
    {'type': 'drop', 'inputName': 'Serevite Ore', 'inputRank': None, 'inputItemID': 190395},
    {'type': 'drop', 'inputName': 'Serevite Ore', 'inputRank': 3, 'inputItemID': None},
    {'type': 'token', 'inputName': 'Serevite Ore', 'inputRank': 2, 'inputItemID': 190395},
    {'type': 'drop', 'inputName': 'Unlisted Ore', 'inputRank': 1, 'inputItemID': 123},
]
original = json.dumps(probe, sort_keys=True)
report = ranks.audit(probe, catalog)
assert report['matched'] == 1 and len(report['conflicts']) == 1 and len(report['unresolved']) == 2
assert report['conflicts'][0]['expectedItemID'] == 190396
assert json.dumps(probe, sort_keys=True) == original, 'audit must not rewrite any value'

module = ranks.v3.load_calculator(ranks.v3.DEFAULT_SNAPSHOT)
rows = [r for r in module.load() if ranks.v3.is_counted(r, module)]
before = json.dumps(rows, sort_keys=True)
report = ranks.audit(rows, catalog)
# Pin the known conflicts as findings, not approvals or automatic corrections.
# Their notes infer the rank and/or casts are missing. Research must resolve
# them against original sources; the audit never substitutes an item ID.
assert report['matched'] >= 400
assert {r['recordID'] for r in report['conflicts']} == {
    'dragonflight-20261031-10007', 'dragonflight-20261031-10008',
    'dragonflight-20261031-10013', 'dragonflight-20261031-10014',
}
assert all(r['itemID'] == 190395 and r['expectedItemID'] == 190396 for r in report['conflicts'])
assert json.dumps(rows, sort_keys=True) == before
print(f'INPUT RANK AUDIT: PASS; {report["matched"]} matching study rows, '
      f'{len(report["unresolved"])} unresolved identities, {len(report["conflicts"])} known conflicts preserved')
