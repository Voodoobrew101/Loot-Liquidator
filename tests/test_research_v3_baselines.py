"""Check partial research fields and batch-scoped support against the pinned snapshot."""
import json
import sys
sys.dont_write_bytecode = True  # never leave cache files in the repo or snapshot
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, 'tools')
import research_v3_to_baselines as v3  # noqa: E402
import evidence_to_baselines as eb  # noqa: E402

SNAPSHOT = Path('tests/fixtures/research-golden/v3-snapshot')  # frozen research; live data changes on every refresh
LIVE = v3.DEFAULT_SNAPSHOT
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

def support(value, casts, status='measured', **counts):
    return {'value': value, 'casts': casts, 'status': status, **counts}


quantity = support(.75, 200, total=150)
occurrence = support(.5, 10, hits=5)
lo, hi = support(1, 3), support(2, 5)
m = v3.material(5, [{'fieldSupport': {'expectedQuantity': quantity, 'dropChance': occurrence,
                                    'minQuantity': lo, 'maxQuantity': hi}}])
near(m['expectedQuantity']['value'], .75, 'direct mean retained')
near(m['dropChance']['value'], .5, 'direct chance retained')
near(m['expectedQuantity']['samples'], 100, 'average uses its own casts')
near(m['dropChance']['samples'], 5, 'chance uses its own casts')
near(m['minQuantity']['samples'], 1.5, 'range support stays independent')
ok(m['expectedQuantity']['confidence'] == eb.quality_score(100), 'expected quantity receives its own score')
ok(m['dropChance']['confidence'] == eb.rate_confidence(2.5, 5), 'drop chance score uses observed occurrences')
ok(m['expectedQuantity']['independentConfidence'], 'mark independently supported mean for runtime')
m = v3.material(5, [{'fieldSupport': {'expectedQuantity': quantity, 'minQuantity': lo, 'maxQuantity': hi}}])
ok(m['dropChance']['status'] == 'unknown' and m['dropChance']['inferenceBlocked'],
   'mean and observed bounds do not establish a drop chance')
m = v3.material(5, [{'fieldSupport': {'dropChance': occurrence, 'minQuantity': lo, 'maxQuantity': hi}}])
ok(m['expectedQuantity']['status'] == 'unknown' and 'inferenceBlocked' not in m['expectedQuantity'],
   'measured chance and positive bounds allow only runtime modeled expectation')
m = v3.material(5, [{'fieldSupport': {'dropChance': occurrence}}])
ok(m['expectedQuantity']['status'] == 'unknown' and m['expectedQuantity']['inferenceBlocked'],
   'chance without positive stack bounds does not establish a mean')
m = v3.material(5, [{'fieldSupport': {'expectedQuantity': support(.7, 0, 'provisional')}}])
ok(m['expectedQuantity']['samples'] == 0 and not m['expectedQuantity']['sampleSizeKnown'],
   'published mean without a denominator carries no measured casts')
m = v3.material(5, [{'fieldSupport': {'expectedQuantity': support(.7, 0, 'provisional', reportedCasts=1146)}}])
ok(m['expectedQuantity']['reportedCasts'] == 1146 and m['expectedQuantity']['samples'] == 0
   and m['expectedQuantity']['status'] == 'provisional' and m['expectedQuantity']['confidence'] == 40,
   'rounded published mean preserves reported operations outside its measured count')
m = v3.material(5, [{'fieldSupport': {'dropChance': occurrence,
                                    'expectedQuantity': support(.1, 200, total=20)}}])
ok(m['dropChance']['inferenceBlocked'] and m['heldDropChance']['value'] == .5,
   'held conflicting occurrence stays auditable and is not inferred again')
near(m['expectedQuantity']['value'], .1, 'contradictory occurrence does not erase directly supported mean')

one = support(1, 40)
independent = {'dropChance': support(.4, 1000, hits=400, _countedCohorts={'hits'}),
               'expectedQuantity': support(.401, 1000, total=401, _countedCohorts={'units'}),
               'minQuantity': one, 'maxQuantity': one}
m = v3.material(5, [{'fieldSupport': independent}])
ok(m['samplingVariation'] and 'heldDropChance' not in m and 'heldExpectedQuantity' not in m,
   'small deviation from distinct sampled cohorts retains both values and observed bounds')
near(m['dropChance']['value'], .4, 'sampling tolerance never changes measured chance')
near(m['expectedQuantity']['value'], .401, 'sampling tolerance never changes measured mean')
same_casts = dict(independent, expectedQuantity=support(.401, 1000, total=401, _countedCohorts={'hits'}))
m = v3.material(5, [{'fieldSupport': same_casts}])
ok('samplingVariation' not in m and 'heldDropChance' in m, 'same cohort retains strict arithmetic')
wide_conflict = dict(independent, expectedQuantity=support(.25, 20, total=5, _countedCohorts={'units'}))
m = v3.material(5, [{'fieldSupport': wide_conflict}])
ok('samplingVariation' not in m and m['expectedQuantity']['inferenceBlocked'] and m['heldExpectedQuantity']['samples'] == 10,
   'large discrepancy retains better supported occurrence and archives the weaker mean')
near(m['dropChance']['value'], .4, 'better supported occurrence remains active')
zero_conflict = dict(independent, dropChance=support(0, 1000, hits=0, _countedCohorts={'hits'}),
                     expectedQuantity=support(.001, 1000, total=1, _countedCohorts={'units'}))
m = v3.material(5, [{'fieldSupport': zero_conflict}])
ok('samplingVariation' not in m and 'heldDropChance' in m, 'zero chance with positive reported mean remains strict')
weak_quantity = dict(independent, expectedQuantity=support(.401, 0, 'provisional', reportedCasts=1000))
m = v3.material(5, [{'fieldSupport': weak_quantity}])
ok('samplingVariation' not in m and 'heldExpectedQuantity' in m,
   'an uncounted reported mean does not qualify for sampling tolerance')

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
       and r['fieldSpecificEvidence']
       for r in records), 'record IDs and source')
ok(len({r['recordID'] for r in records}) == len(records), 'record IDs unique')
for r in records:
    ok(('inputItemID' in r) != ('gearKey' in r), f'{r["recordID"]}: one input key')
    for mat in r['materials']:
        f = mat['dropChance']
        p, e, lo, hi = (mat[field].get('value') for field in ('dropChance', 'expectedQuantity', 'minQuantity', 'maxQuantity'))
        ok(p is None or 0 <= p <= 1 and f['samples'] >= 0, f'{r["recordID"]}:{mat["id"]} chance')
        ok(lo is None or hi is None or 1 <= lo <= hi, f'{r["recordID"]}:{mat["id"]} range')
        ok(mat.get('samplingVariation') or e is None or p is None or lo is None or hi is None or p*lo - 1e-9 <= e <= p*hi + 1e-9,
           f'{r["recordID"]}:{mat["id"]} exposed average in range')
by_id = {r['recordID']: r for r in records}

# Saronite Ore has independently measured expected quantity without occurrence counts.
sar = by_id['evidence:v3:Prospect:36912:x5']
gem = {m['id']: m for m in sar['materials']}[36917]
near(gem['expectedQuantity']['value'], 0.1798, 'Saronite -> Bloodstone average', 1e-4)
ok(gem['dropChance']['status'] == 'unknown', 'Saronite -> Bloodstone chance unavailable')

# Aqirite rank 1 reports output units per 1,000 input ore, without occurrence counts.
aq = {m['id']: m for m in by_id['evidence:v3:Prospect:210933:x5']['materials']}
near(aq[213398]['expectedQuantity']['value'], 0.5195, 'Aqirite -> 213398 reported mean', 1e-4)
ok(aq[213398]['dropChance']['status'] == 'unknown', 'units per ore are not per-cast hit counts')

# D1c6: the 1,000-prospect R2 Serevite study names Ysemerald R3 (5 gems)
# and Neltharite R3 (8 gems), but some copies swapped the item numbers.
# Correct names/ranks before grouping and deduplication, then price the right gem.
serevite = {m['id']: m for m in by_id['evidence:v3:Prospect:190396:x5']['materials']}
near(serevite[192861]['expectedQuantity']['value'], 0.005, 'Serevite -> Ysemerald R3 average')
near(serevite[192865]['expectedQuantity']['value'], 0.008, 'Serevite -> Neltharite R3 average')
near(serevite[192861]['expectedQuantity']['samples'], 500, 'corrected study counted only once at half weight')

# Gear group written with names by a worker becomes the addon's numeric key.
ok('evidence:v3:Disenchant:gear:10:2:weapon:x1' in by_id, 'War Within green weapons from a worker study')
# Retain both observed batch units, without carrying P(hit) across them.
ok('evidence:v3:Mill:152506:x5' in by_id and 'evidence:v3:Mill:152506:x20' in by_id, 'mixed milling batches remain separate')
osmenite = {batch: {m['id']: m for m in by_id[f'evidence:v3:Prospect:168185:x{batch}']['materials']}[168191]
            for batch in (5, 20)}
ok(osmenite[5]['expectedQuantity']['samples'] > osmenite[20]['expectedQuantity']['samples'] > 0,
   'Osmenite source denominators are distinct across batches')
ok(osmenite[5]['samplingVariation'] and osmenite[20]['dropChance']['status'] == 'unknown',
   'five-input Osmenite preserves separately sampled occurrence without inventing 20-input occurrence')
ok(all(m['dropChance']['status'] == 'measured' and m.get('samplingVariation')
       for m in by_id['evidence:v3:Prospect:168185:x5']['materials']),
   'all seven five-input Osmenite occurrence estimates survive the source sampling differences')
near(osmenite[5]['dropChance']['value'], 0.228625, 'Osmenite occurrence preserved')
near(osmenite[5]['expectedQuantity']['value'], 0.22772277, 'Osmenite measured mean preserved')
adamantite = {m['id']: m for m in by_id['evidence:v3:Prospect:23425:x5']['materials']}[23437]
near(adamantite['expectedQuantity']['value'], 0.037876, 'Adamantite measured mean survives', 1e-6)
near(adamantite['heldDropChance']['samples'], 7, 'small conflicting hit-count study retained in held evidence')
ok(notes['conditional drop (needs an unlock the addon cannot check yet)'] > 0, 'conditional drops reported')
ok(not any(isinstance(m['id'], str) for r in records for m in r['materials']), 'no family outputs')

# Rank-family fallback must only test overlap within the candidate's own operation.
def row(id, **values):
    return dict(type='drop', sourceKind='study', id=id, studyKey=id,
                _file=f'research/v3/evidence/fixture/{id}.jsonl',
                source={'url': f'https://www.wowhead.com/item=222845#comments:id={id}'}, **values)


fixture = [
    row('1234567', method='Mill', inputItemID=900001, inputsPerCast=5, outputName='Nacreous Pigment',
        casts=100, totalQuantity=203),
    row('1234568', method='Mill', inputItemID=900001, inputsPerCast=20, outputName='Nacreous Pigment',
        outputItemID=222618, outputRank=1, casts=30, totalQuantity=56),
    row('1234569', method='Disenchant', inputItemID=222845, outputName='Storm Dust (all quality ranks pooled)',
        casts=108, totalQuantity=303),
]
with patch.object(module, 'load', return_value=fixture), patch.object(v3, 'load_calculator', return_value=module):
    candidate, _, _, _, _ = v3.build(SNAPSHOT)
fixture_material = {r['recordID']: r['materials'][0] for r in candidate}
pooled = fixture_material['evidence:v3:Mill:900001:x5']
ok(pooled['rankIDs'] == [222618, 222619, 222620], 'another batch exact rank does not suppress a pooled mean')
ok('rankIDs' not in fixture_material['evidence:v3:Mill:900001:x20'], 'exact rank remains exact at its own batch size')
storm_dust = fixture_material['evidence:v3:Disenchant:222845:x1']
ok(storm_dust['rankIDs'] == [219946, 219947, 219948], 'explicit pooled Storm Dust maps to the three verified ranks')
near(storm_dust['expectedQuantity']['value'], 303 / 108, 'keep quantity from all ranks without assigning rank yields')
ok(storm_dust['dropChance']['status'] == 'unknown', 'pooled units alone do not give occurrence')

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
ok(tok[249367]['kind']=='exchange' and tok[249367]['costsComplete'] is False,
   'known curio relationship retained while unknown full costs block an action')
ok(tok[270909]['candidateRewards'] and not tok[270909]['listComplete'] and tok[270909]['confidence0to100']==20,
   'staged S2 membership remains an explicitly unverified candidate list')
ok(45634 not in tok, 'copy of the old addon token table not counted')
ok(not conflicts, 'no source conflicts in this snapshot')
ok(all(t['sourceURLs'] and all(u.startswith('https://') for u in t['sourceURLs']) for t in tokens), 'every list has https sources')

# The committed file is current.
# The committed file is built from the live snapshot, not the frozen test copy.
live_records = v3.build(LIVE)[0]
live_revision = json.loads((LIVE / 'SNAPSHOT.json').read_text())['commit']
live_tokens = vt.build_tokens(LIVE, live_revision)[0]
no_de, _ = v3.research_v3_no_disenchant.build_no_disenchant(LIVE)  # D1c4
ok(v3.render(live_records, LIVE, live_tokens, no_de) == v3.DEFAULT_OUTPUT.read_text(), 'database/research-v3-baselines.lua is current')
print(f'RESEARCH V3 BASELINE TESTS: {passed} passed, 0 failed; {len(records)} records')
