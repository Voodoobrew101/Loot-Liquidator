"""D1c: research team v3 results -> ItemDB baselines (tools/research_v3_to_baselines.py).

Runs against the pinned snapshot database/research/v3-snapshot/, so results are fixed until
the snapshot is refreshed on purpose. Checks that only real studies are counted (no TSM or
reference starting guesses, no copy of the addon's own old disenchant tables), that the
research team's own numbers come through unchanged, and that blended operations are left out.
"""
import json
import sys
sys.dont_write_bytecode = True  # never leave cache files in the repo or snapshot
from pathlib import Path

sys.path.insert(0, 'tools')
import research_v3_to_baselines as v3  # noqa: E402
import evidence_to_baselines as eb  # noqa: E402

SNAPSHOT = Path('database/research/v3-snapshot')
passed = 0


def ok(condition, label):
    global passed
    assert condition, label
    passed += 1


def near(a, b, label, tol=1e-6):
    ok(a is not None and abs(a - b) <= tol, f'{label}: {a} != {b}')


# ---- snapshot is pinned and complete
info = json.loads((SNAPSHOT / 'SNAPSHOT.json').read_text())
ok(len(info['commit']) == 40 and info['branch'] == 'implementation/five-agent-completion', 'snapshot names its commit')
for path in info['paths']:
    ok((SNAPSHOT / path).exists(), f'snapshot has {path}')

# ---- small pure helpers
ok(v3.gear_key('gear:The War Within:uncommon:weapon') == 'gear:10:2:weapon', 'gear names map to numbers')
ok(v3.gear_key('gear:11:4:armor') == 'gear:11:4:armor', 'numeric gear keys pass through')
ok(v3.gear_key('gear:Midnight:rare:trinket') is None, 'gear key must end in armor or weapon')
ok(v3.counts({'simulation': {'chanceBeta': [10.5, 90.5]}}) == (10.0, 100.0), 'beta parameters back to counts')

# A chance worked out from an average carries half confidence; the average stays measured.
m = v3.material(5, [{'simulation': {'chanceBeta': [50.5, 50.5]}, 'chanceSource': 'estimated',
                     'averageSource': 'measured', 'rangeSource': 'reference', 'average': 0.75,
                     'range': [1, 2], 'studyCasts': 200.0}])
near(m['dropChance']['value'], 0.5, 'derived chance = average / middle of range')
ok(m['dropChance']['status'] == 'provisional' and m['expectedQuantity']['status'] == 'measured', 'statuses')
ok(m['dropChance']['confidence'] == eb.rate_confidence(25, 50) // 2, 'derived chance at half confidence')
near(m['expectedQuantity']['samples'], 100.0, 'average counts its own casts (x0.5 until scaling rules)')

# Fixed positive yields must survive serialization as a consistent pair.
# Real new cohorts have 2/41 hits returning exactly two units (4/41 mean).
for hits, casts, units in [(2, 41, 2), (3, 29, 2), (3, 41, 3), (1, 44, 2), (1, 3, 3)]:
    exact = v3.material(5, [{'simulation': {'chanceBeta': [hits + .5, casts - hits + .5]},
        'chanceSource': 'measured', 'averageSource': 'measured', 'rangeSource': 'observed',
        'average': hits * units / casts, 'range': [units, units], 'studyCasts': casts}])
    p, e = exact['dropChance']['value'], exact['expectedQuantity']['value']
    ok(p * units - 1e-9 <= e <= p * units, 'serialized fixed yield stays inside probability bounds')
    near(e, hits * units / casts, 'fixed yield retains source precision', 1e-10)

derived = v3.material(5, [{'simulation': {'chanceBeta': [1500.5, 500.5]},
    'chanceSource': 'measured', 'averageSource': 'estimated', 'rangeSource': 'observed',
    'average': 3, 'range': [2, 6], 'studyCasts': 2000}])
ok(derived['expectedQuantity']['status'] == 'provisional', 'midpoint mean is never marked measured')
ok(derived['expectedQuantity']['confidence'] == derived['dropChance']['confidence'] // 2,
   'large hit counts do not give a guessed average full occurrence confidence')

# ---- the real build
# D1c5: the pinned calculator matches correction paths exactly. Windows paths
# must be normalized before corrections, or excluded/conditional studies return.
module = v3.load_calculator(SNAPSHOT)
fix = json.loads((SNAPSHOT / 'research/v3/corrections.jsonl').read_text().splitlines()[0])
probe = {'id': fix['recordID'], '_file': fix['file'].replace('/', '\\')}
corrected = module.apply_corrections([probe])
ok(corrected[0].get(fix['field']) == fix['value'], 'file-specific correction applies to Windows paths')
ok(corrected[0]['_file'] == fix['file'], 'calculator receives portable evidence paths')
ok(probe['_file'] != fix['file'], 'path normalization does not rewrite the original row')
records, notes, total, counted, unplaced = v3.build(SNAPSHOT)
ok(len(records) > 50 and counted < total, 'records built, some rows not counted')
module = v3.load_calculator(SNAPSHOT)
rows = module.load()
for r in rows:
    if r.get('sourceKind') in module.REFERENCE_KINDS or r['_file'].endswith(v3.LEGACY_COPY):
        ok(not v3.is_counted(r, module), 'reference values and the old addon tables are never counted')
        break
ok(all(r['recordID'].startswith('evidence:v3:') and r['sourceKey'] == 'itemdb' and r['supersedesResearch']
       for r in records), 'record IDs and source')
ok(len({r['recordID'] for r in records}) == len(records), 'record IDs unique')
for r in records:
    ok(('inputItemID' in r) != ('gearKey' in r), f'{r["recordID"]}: one input key')
    for mat in r['materials']:
        f = mat['dropChance']
        ok(f['status'] != 'unknown' and 0 <= f['value'] <= 1 and f['samples'] > 0, f'{r["recordID"]}:{mat["id"]} chance')
        lo, hi, e = mat['minQuantity']['value'], mat['maxQuantity']['value'], mat['expectedQuantity'].get('value')
        ok(1 <= lo <= hi, f'{r["recordID"]}:{mat["id"]} range')
        ok(e is None or f['value'] * lo - 1e-9 <= e <= f['value'] * hi + 1e-9, f'{r["recordID"]}:{mat["id"]} average in range')
by_id = {r['recordID']: r for r in records}

# Saronite Ore (the owner's reference tooltip): matches the research team's published estimate
# (chance from average / middle of 1-2, half confidence), from real studies only.
sar = by_id['evidence:v3:Prospect:36912:x5']
gem = {m['id']: m for m in sar['materials']}[36917]
near(gem['expectedQuantity']['value'], 0.1792, 'Saronite -> Bloodstone average', 1e-4)
near(gem['dropChance']['value'], 0.1195, 'Saronite -> Bloodstone chance', 1e-4)
ok(gem['dropChance']['confidence'] == 50, 'Saronite -> Bloodstone confidence')

# Aqirite rank 1: measured chances straight from the 1,040-prospect study family.
aq = {m['id']: m for m in by_id['evidence:v3:Prospect:210933:x5']['materials']}
near(aq[213398]['dropChance']['value'], 0.5209, 'Aqirite -> 213398 chance', 1e-4)

# D1c6: the 1,000-prospect R2 Serevite study names Ysemerald R3 (5 gems)
# and Neltharite R3 (8 gems), but some copies swapped the item numbers.
# Correct names/ranks before grouping and deduplication, then price the right gem.
serevite = {m['id']: m for m in by_id['evidence:v3:Prospect:190396:x5']['materials']}
near(serevite[192861]['expectedQuantity']['value'], 0.005, 'Serevite -> Ysemerald R3 average')
near(serevite[192865]['expectedQuantity']['value'], 0.008, 'Serevite -> Neltharite R3 average')
near(serevite[192861]['expectedQuantity']['samples'], 500, 'corrected study counted only once at half weight')

# Gear group written with names by a worker becomes the addon's numeric key.
ok('evidence:v3:Disenchant:gear:10:2:weapon:x1' in by_id, 'War Within green weapons from a worker study')
# Battle for Azeroth herbs mix 5-herb and 20-herb studies: left out, never blended.
ok('evidence:v3:Mill:152506:x5' not in by_id and 'evidence:v3:Mill:152506:x20' not in by_id, 'mixed batch sizes left out')
ok(notes['studies mix batch sizes (e.g. milling and mass milling)'] > 0, 'mixed batch sizes reported')
ok(notes['conditional drop (needs an unlock the addon cannot check yet)'] > 0, 'conditional drops reported')
ok(not any(isinstance(m['id'], str) for r in records for m in r['materials']), 'no family outputs')

# C4b3: token reward lists from the v3 notes. Pinned numbers may move after a refresh, on purpose.
import research_v3_tokens as vt  # noqa: E402
revision = json.loads((SNAPSHOT / 'SNAPSHOT.json').read_text())['commit']
tokens, token_notes, conflicts = vt.build_tokens(SNAPSHOT, revision)
tok = {t['tokenID']: t for t in tokens}
ok(tok[270910]['rewards'] == [271547, 271556, 271565] and tok[270910]['confidence0to100'] == 90,
   'Venomwoven Idol: 3 pieces, research and our list agree (two pages each)')
ok(tok[249347]['rewards'] == [250045, 250054, 250063], 'Alnwoven Riftbloom: IDs filled from our staged list by name')
ok(tok[237581]['rewards'] == [237631, 237694, 237703], 'Manaforge Omega chest token from a War Within worker')
ok(all(t['independentReview'] == 'NOT_REVIEWED' and t['recordID'].startswith('v3token:') for t in tokens),
   'never marked APPROVED here')
ok(249367 not in tok and 270909 not in tok, 'curio exchanges left out (cost not recorded)')
ok(45634 not in tok, 'copy of the old addon token table not counted')
ok(not conflicts, 'no source conflicts in this snapshot')
ok(all(t['sourceURLs'] and all(u.startswith('https://') for u in t['sourceURLs']) for t in tokens), 'every list has https sources')

# The committed file is current.
no_de, _ = v3.research_v3_no_disenchant.build_no_disenchant(SNAPSHOT)  # D1c4
ok(v3.render(records, SNAPSHOT, tokens, no_de) == v3.DEFAULT_OUTPUT.read_text(), 'database/research-v3-baselines.lua is current')
print(f'RESEARCH V3 BASELINE TESTS: {passed} passed, 0 failed; {len(records)} records')
