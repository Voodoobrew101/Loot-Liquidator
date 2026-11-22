"""Research no-DE source facts remain scoped; native hard flags stay intact.

Unit checks on a small temporary snapshot, then checks on the pinned snapshot and the
shipped ItemDBRuntime.lua: authoritative restrictions are intact and research-only
claims remain offline with provenance, while native proofs and conflicts are retained.
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
src = Path('database/sources/DB2Restrictions.lua').read_text(encoding='utf-8')
compiled = Path('LootLiquidator/ItemDBRuntime.lua').read_text(encoding='utf-8')
runtime = [l for l in compiled.splitlines() if l.startswith('LL.ItemDB.restrictions=')]
ok(len(runtime) == 1, 'one restrictions line')
line = runtime[0]


def ids_in(key):
    m = re.search(r'\["%s"\]=\{([^}]*)\}' % key, line)
    if not m:
        return set()
    entries = re.sub(r'\[\d+\]=', '', m.group(1))
    assert re.fullmatch(r'(?:\d+,)*', entries), 'Invalid restriction list'
    return {int(x) for x in entries.split(',') if x}


game, added = ids_in('noDisenchant'), ids_in('researchNoDisenchant')
held = set(map(int, re.findall(r'\["disenchantRecordID"\]="[^"]+",\["itemID"\]=(\d+),\["sourceURLs"\]=', compiled)))
block = src[src.index('for _,itemID in ipairs({') + len('for _,itemID in ipairs({'):]
game_source = {int(x) for x in re.findall(r'\d+', block[:block.index('})')])}
ok(game_source and game == game_source, 'every game-file no-disenchant entry ships unchanged')
ok(not (added & game), 'verified research flags never duplicate or remove native flags')
proven = {r['itemID'] for r in real if r.get('globalRestriction')}
ok(added == proven - game, 'only explicit native all-variant proofs become global research flags')
ok(held <= {r['itemID'] for r in real}, 'positive-output conflicts retain their source item identities')
ok('researchNoDisenchantObservations' not in line, 'unused scoped observation payload stays out of the runtime database')
ok(all(r.get('observations') and all(o.get('rawSHA256') and o.get('sourceFile')
       and o.get('sourceURL') and isinstance(o.get('scope'), dict) for o in r['observations']) for r in real),
   'full offline observations retain source lineage, hashes and scope')
ok('researchNoDisenchantPolicy' in line and 'native-proof-only' in line, 'compiled native-only hard restriction policy explicit')
trinket = next((r for r in real if r['itemID'] == 251786), None)
if trinket:
    ok(251786 not in added and not trinket['globalRestriction'], 'base197 trinket catalog cannot globally block292 bonus item')
    ok(any(o['scope'].get('itemLevel') == 197 for o in trinket['observations']), 'trinket source scope and provenance preserved')
print(f'RESEARCH V3 NO-DISENCHANT TESTS: {passed} passed, 0 failed; {len(added)} added, '
      f'{len({r["itemID"] for r in real} & game)} already in the game-file list')
