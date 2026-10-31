"""C4a: staged token research stays research (never approved, never invented)."""
import json
from pathlib import Path

doc = json.loads(Path('database/research/tokens-midnight-s1.json').read_text())
assert doc['schemaVersion'] == 'loot-liquidator.token-research/1'
assert doc['independentReview'] == 'NOT_REVIEWED' and doc['automaticApproval'] is False
assert doc['completeUniverse'] is False

tokens = doc['tokens']
assert len(tokens) == 20, 'Tier 35: 4 armor groups x 5 slots'
seen = set()
for t in tokens:
    key = (t['slot'], t['armorGroup'])
    assert key not in seen, key
    seen.add(key)
    assert t['kind'] == 'open' and t['rewardsSoulbound'] is True
    assert t['tokenID'] is None or (isinstance(t['tokenID'], int) and t['tokenID'] > 0)
    # An item ID must come with the page it was read from.
    if t['tokenID'] is not None:
        assert any(f"item={t['tokenID']}" in s for s in t['sources']), t['name']
    assert len(set(t['sources'])) >= 2 and all(s.startswith('https://') for s in t['sources']), t['name']
    assert t['rewardIDs'] is None or all(isinstance(x, int) and x > 0 for x in t['rewardIDs'])
assert {s for s, _ in seen} == {'Head', 'Shoulders', 'Chest', 'Hands', 'Legs'}
assert {g for _, g in seen} == {'woven', 'cured', 'cast', 'forged'}

ids = [t['tokenID'] for t in tokens if t['tokenID']]
assert len(ids) == len(set(ids))
assert doc['exchange']['kind'] == 'exchange' and doc['exchange']['name'] == 'Chiming Void Curio'

# Research must not leak into the shipped database before C4b review.
records = Path('database/records.lua').read_text()
assert 'Nullcore' not in records and 'Riftbloom' not in records
print(f'TOKEN RESEARCH: staged {len(tokens)} tokens, {len(ids)} with item IDs; not reviewed, not shipped')
