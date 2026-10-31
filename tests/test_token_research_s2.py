"""C4a4: staged Season 2 (Tier 36) token research stays research (never approved, never invented)."""
import json
from pathlib import Path

doc = json.loads(Path('database/research/tokens-midnight-s2.json').read_text())
assert doc['schemaVersion'] == 'loot-liquidator.token-research/1'
assert doc['independentReview'] == 'NOT_REVIEWED' and doc['automaticApproval'] is False
assert doc['completeUniverse'] is False

SUFFIX = {'Hands': 'Idol', 'Head': 'Effigy', 'Legs': 'Relic', 'Shoulders': 'Remnant', 'Chest': 'Icon'}
CLASSES = {
    'woven': ['Priest', 'Mage', 'Warlock'],
    'cured': ['Rogue', 'Monk', 'Druid', 'Demon Hunter'],
    'cast': ['Hunter', 'Shaman', 'Evoker'],
    'forged': ['Warrior', 'Paladin', 'Death Knight'],
}

tokens = doc['tokens']
assert len(tokens) == 20, 'Tier 36: 4 armor groups x 5 slots'
seen = set()
for t in tokens:
    key = (t['slot'], t['armorGroup'])
    assert key not in seen, key
    seen.add(key)
    assert t['name'] == f"Venom{t['armorGroup']} {SUFFIX[t['slot']]}", t['name']
    assert t['classes'] == CLASSES[t['armorGroup']], t['name']
    assert t['kind'] == 'open' and t['rewardsSoulbound'] is True
    # Every token ID must come with the Wowhead page it was read from.
    assert isinstance(t['tokenID'], int) and t['tokenID'] > 0, t['name']
    assert any(f"item={t['tokenID']}" in s for s in t['sources']), t['name']
    assert 'tokenIDByPattern' not in t, 'no pattern guesses in Season 2'
    assert len(set(t['sources'])) >= 2 and all(s.startswith('https://') for s in t['sources']), t['name']
    # One reward per class; a name or ID is either blank or comes with its page.
    assert [r['class'] for r in t['rewards']] == t['classes'], t['name']
    assert t['rewardNames'] == [r['name'] for r in t['rewards']], t['name']
    for r in t['rewards']:
        assert 'itemIDByPattern' not in r, (t['name'], r['class'])
        if r['name'] is not None:
            assert r['nameSource'].startswith('https://'), (t['name'], r['class'])
        if r['itemID'] is not None:
            assert isinstance(r['itemID'], int) and r['itemID'] > 0
            assert f"item={r['itemID']}" in r['source'] or str(r['itemID']) in r.get('evidence', ''), r['name']
    if t['rewardIDs'] is not None:
        assert t['rewardIDs'] == [r['itemID'] for r in t['rewards']], t['name']
    if t['status'] == 'ids-complete-unreviewed':
        assert all(r['itemID'] for r in t['rewards']), t['name']
assert {s for s, _ in seen} == set(SUFFIX)
assert {g for _, g in seen} == set(CLASSES)

ids = [t['tokenID'] for t in tokens]
rewards = [r['itemID'] for t in tokens for r in t['rewards'] if r['itemID']]
names = [r['name'] for t in tokens for r in t['rewards'] if r['name']]
everything = ids + rewards + [doc['exchange']['tokenID']]
assert len(everything) == len(set(everything)), 'an item ID is used twice'
assert len(names) == len(set(names)), 'a reward name is used twice'
ex = doc['exchange']
assert ex['kind'] == 'exchange' and ex['name'] == 'Slumbering Coil Curio'
assert any(f"item={ex['tokenID']}" in s for s in ex['sources'])

# Season 1 and Season 2 must not share item IDs.
s1 = json.loads(Path('database/research/tokens-midnight-s1.json').read_text())
s1ids = {t['tokenID'] for t in s1['tokens']} | {s1['exchange']['tokenID']}
s1ids |= {r['itemID'] for t in s1['tokens'] for r in t['rewards'] if r['itemID']}
assert not (set(everything) & s1ids), 'Season 2 reuses a Season 1 item ID'

# Research must not leak into the shipped database before C4b review.
records = Path('database/records.lua').read_text()
assert 'Venomwoven' not in records and 'Slumbering Coil' not in records
print(f'TOKEN RESEARCH S2: {len(ids)}/20 token IDs, {len(names)}/65 reward names, {len(rewards)}/65 reward IDs; not reviewed, not shipped')
