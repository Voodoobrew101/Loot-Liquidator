"""D1c4: research v3 "noDisenchant" records -> ItemDB.restrictions (add only).

Unit checks on a small temporary snapshot, then checks on the pinned real snapshot and the
shipped ItemDBRuntime.lua: every game-file no-disenchant entry is still there, research adds
only items the game-file list lacks, and every added item is backed by a v3 record.
"""
import json
import re
import sys
import tempfile
sys.dont_write_bytecode = True
from pathlib import Path

sys.path.insert(0, 'tools')
import research_v3_no_disenchant as nd  # noqa: E402

passed = 0


def ok(condition, label):
    global passed
    assert condition, label
    passed += 1


def rec(rid, item, url='https://www.wowhead.com/item=%d', name='Thing', **extra):
    r = {'id': rid, 'type': 'noDisenchant', 'itemID': item, 'itemName': name,
         'source': {'url': (url % item) if url and '%d' in url else url}, 'replaces': None}
    r.update(extra)
    return r


with tempfile.TemporaryDirectory() as folder:
    snap = Path(folder)
    ev = snap / 'research' / 'v3' / 'evidence'
    (ev / 'midnight').mkdir(parents=True)
    (ev / 'imported').mkdir()
    rows = [
        rec('a1', 1001),
        rec('a2', 1001, url='https://www.wowdb.com/items/%d'),     # second page, same item
        rec('a3', 1002),                                            # excluded by a correction
        rec('a4', 1003, url='http://insecure.example/%d'),          # no https source
        rec('a5', 1004),                                            # replaced by a6
        rec('a6', 1005, replaces='a5'),
        rec('a7', 'x', url='https://x.test/a'),                                        # no item ID
        {'id': 'd1', 'type': 'drop', 'itemID': 1006},               # other record kinds ignored
    ]
    (ev / 'midnight' / 'f.jsonl').write_text('\n'.join(json.dumps(r) for r in rows) + '\nnot json\n')
    (ev / 'imported' / 'old.jsonl').write_text(json.dumps(rec('i1', 1007)) + '\n')
    (snap / 'research' / 'v3' / 'corrections.jsonl').write_text(
        json.dumps({'recordID': 'a3', 'field': 'exclude', 'value': True}) + '\n')
    records, notes = nd.build_no_disenchant(snap)
    ids = [r['itemID'] for r in records]
    ok(ids == [1001, 1005], f'only sourced, current, non-excluded items: {ids}')
    ok(len(records[0]['sourceURLs']) == 2, 'two pages for the same item are merged')
    ok(records[0]['name'] == 'Thing', 'name kept')
    ok(notes['excluded by corrections.jsonl'] == 1 and notes['no https source'] == 1
       and notes['replaced by a later correction'] == 1 and notes['no item ID'] == 1
       and notes['copy of the old addon tables (not counted)'] == 1, f'reasons: {dict(notes)}')
    ok(nd.summary(records, notes).startswith('RESEARCH V3 NO-DISENCHANT: 2 item(s) (1 with two'), 'summary')

# ---- pinned real snapshot and shipped database
real, _ = nd.build_no_disenchant(Path('database/research/v3-snapshot'))
ok(len(real) > 100, 'the research team has recorded no-disenchant items')
src = Path('database/sources/DB2Restrictions.lua').read_text()
runtime = [l for l in Path('LootLiquidator/ItemDBRuntime.lua').read_text().splitlines()
           if l.startswith('LL.ItemDB.restrictions=')]
ok(len(runtime) == 1, 'one restrictions line')
line = runtime[0]


def ids_in(key):
    m = re.search(r'\["%s"\]=\{([^}]*)\}' % key, line)
    return {int(x) for x in re.findall(r'\]=(\d+)', m.group(1))} if m else set()


game, added = ids_in('noDisenchant'), ids_in('researchNoDisenchant')
block = src[src.index('for _,itemID in ipairs({') + len('for _,itemID in ipairs({'):]
game_source = {int(x) for x in re.findall(r'\d+', block[:block.index('})')])}
ok(game_source and game == game_source, 'every game-file no-disenchant entry ships unchanged')
ok(added and not (added & game), 'research adds only items the game-file list lacks')
ok(added == {r['itemID'] for r in real} - game, 'every research item ships, nothing else')
print(f'RESEARCH V3 NO-DISENCHANT TESTS: {passed} passed, 0 failed; {len(added)} added, '
      f'{len({r["itemID"] for r in real} & game)} already in the game-file list')
