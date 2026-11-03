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
    # Session 10: one reward per class in the armor group, each with its own evidence.
    assert [r['class'] for r in t['rewards']] == t['classes'], t['name']
    for r in t['rewards']:
        if r['itemID'] is None:
            assert isinstance(r.get('itemIDByPattern'), int), (t['name'], r['name'])
            continue
        assert isinstance(r['itemID'], int) and r['itemID'] > 0 and 'itemIDByPattern' not in r
        assert r['source'].startswith('https://'), r['name']
        # Read from a Wowhead URL, or from an explicit note (u.gg image asset name).
        assert f"item={r['itemID']}" in r['source'] or str(r['itemID']) in r.get('evidence', ''), r['name']
    if t['tokenID'] is None:
        assert isinstance(t.get('tokenIDByPattern'), int), t['name']
    # C4a3: the summary list must agree with the per-class rewards.
    if t['rewardIDs'] is not None:
        assert t['rewardIDs'] == [r['itemID'] for r in t['rewards']], t['name']
    if t['status'] == 'ids-complete-unreviewed':
        assert t['tokenID'] and all(r['itemID'] for r in t['rewards']), t['name']
assert {s for s, _ in seen} == {'Head', 'Shoulders', 'Chest', 'Hands', 'Legs'}
assert {g for _, g in seen} == {'woven', 'cured', 'cast', 'forged'}

ids = [t['tokenID'] for t in tokens if t['tokenID']]
assert len(ids) == len(set(ids))
rewards = [r['itemID'] for t in tokens for r in t['rewards'] if r['itemID']]
guesses = [r['itemIDByPattern'] for t in tokens for r in t['rewards'] if r['itemID'] is None]
guesses += [t['tokenIDByPattern'] for t in tokens if t['tokenID'] is None]
everything = ids + rewards + guesses + [doc['exchange']['tokenID']]
assert len(everything) == len(set(everything)), 'an item ID is used twice'
assert doc['exchange']['kind'] == 'exchange' and doc['exchange']['name'] == 'Chiming Void Curio'

# Research must not leak into the shipped database before C4b review.
records = Path('database/records.lua').read_text()
assert 'Nullcore' not in records and 'Riftbloom' not in records
print(f'TOKEN RESEARCH: {len(ids)}/20 token IDs, {len(rewards)}/65 reward IDs confirmed, {len(guesses)} pattern hints; not reviewed, not shipped')
