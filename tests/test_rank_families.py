#!/usr/bin/env python3
"""D1c2: database/research/rank-families.json has a sane shape and the research build uses it."""
import json
import sys
sys.dont_write_bytecode = True
from pathlib import Path

root = Path(__file__).resolve().parent.parent
data = json.loads((root / 'database/research/rank-families.json').read_text())
passed = 0


def ok(cond, label):
    global passed
    if not cond:
        print('FAIL:', label)
        sys.exit(1)
    passed += 1


seen_ids = {}
for name, entry in data['families'].items():
    ids = entry['ids']
    ok(ids and all(isinstance(i, int) and i > 0 for i in ids), f'{name}: item IDs are positive whole numbers')
    ok(len(set(ids)) == len(ids), f'{name}: no repeated ID')
    ok(entry['source'].startswith('https://'), f'{name}: has an https source')
    for rank, item in entry.get('verifiedRanks', {}).items():
        ok(rank in ('1', '2', '3') and item in ids, f'{name}: verified rank belongs to its family')
    ranked_ids = list(entry.get('verifiedRanks', {}).values())
    ok(len(set(ranked_ids)) == len(ranked_ids), f'{name}: verified ranks have distinct IDs')
    for i in ids:
        ok(i not in seen_ids, f'{name}: ID {i} also listed under {seen_ids.get(i)}')
        seen_ids[i] = name
ok(data['families']['Ysemerald']['ids'] == [192859, 192860, 192861], 'Ysemerald IDs checked against item pages')
ok(data['families']['Neltharite']['ids'] == [192862, 192863, 192865], 'Neltharite IDs checked against item pages')

# The shipped baselines carry the rank-unknown materials and nothing lists a rank twice.
text = (root / 'database/research-v3-baselines.lua').read_text()
ok('rankIDs={' in text, 'baselines carry rank-unknown materials')
sys.path.insert(0, str(root / 'tools'))
import research_v3_to_baselines as conv  # noqa: E402
families = conv.load_families()
ok(families['harandar peridot'] == [242607, 242720], 'converter reads the table by lower-case name')
# D1c6: normalize only the explicitly verified name/rank pairs. Never guess a
# missing rank, infer it from list order, or change the study's counts/source.
rows = [
    {'outputName': 'Ysemerald', 'outputRank': 3, 'outputItemID': 192865, 'totalQuantity': 5, 'casts': 1000},
    {'outputName': 'Neltharite', 'outputRank': 2, 'outputItemID': 192860},
    {'outputName': 'Ysemerald', 'outputRank': 1, 'outputItemID': None},
    {'outputName': 'Neltharite', 'outputRank': 3, 'outputItemID': 192865},
    {'outputName': 'Ysemerald', 'outputRank': None, 'outputItemID': None},
    {'outputName': 'Crystalline Glass', 'outputRank': 1, 'outputItemID': None},
]
fixed = conv.resolve_ranked_outputs(rows)
ok([r['outputItemID'] for r in fixed] == [192861, 192863, 192859, 192865, None, None],
   'swapped and missing IDs resolved; correct IDs kept; unverified ranks stay unknown')
ok(rows[0]['outputItemID'] == 192865 and rows[2]['outputItemID'] is None, 'original evidence untouched')
ok(fixed[0]['totalQuantity'] == 5 and fixed[0]['casts'] == 1000, 'identity correction preserves counts')
print(f'RANK FAMILIES: {passed} passed, 0 failed; {len(data["families"])} names')
