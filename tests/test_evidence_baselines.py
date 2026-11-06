"""D1b step 2: research evidence -> baseline counts for ItemDB (tools/evidence_to_baselines.py)."""
import contextlib
import copy
import io
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, 'tools')
import evidence_check  # noqa: E402
import evidence_to_baselines as eb  # noqa: E402

passed = 0


def ok(condition, label):
    global passed
    assert condition, label
    passed += 1


def near(a, b, label):
    ok(a is not None and abs(a - b) < 1e-6, f'{label}: {a} != {b}')


# The confidence port gives exactly what LL:RateConfidence gives in the addon
# (study notes say ~30/64/81/94 for an 18% drop; the exact values are below).
# tests/test_evidence_baselines.lua cross-checks the compiled fixture in Lua.
for casts, expected in ((10, 33), (50, 65), (100, 81), (200, 94)):
    ok(eb.rate_confidence(0.18 * casts, casts) == expected, f'confidence {casts} casts')
ok(eb.rate_confidence(0, 0) == 0, 'no casts, no confidence')

report = evidence_check.check_folder(Path('tests/fixtures/evidence-v3'))
ok(len(report['setAside']) == 1, 'the broken fixture record is set aside by the checker')
records, notes = eb.build(report)
ok(len(records) == 3, 'three item records (the mismatch and the Craft record are left out)')
ok(notes['mismatch'] == 1 and notes['confirmed'] == 1 and notes['duplicates'] == 1, 'notes count verdicts and copies')
ok(any('Craft is not built' in why or 'method Craft' in why for _, why in notes['skipped']), 'Craft is reported as kept')

r = next(row for row in records if row['inputItemID'] == 990001)
ok(r['recordID'] == 'evidence:Prospect:990001:x5' and r['studyID'] == r['recordID'], 'record identity')
ok(r['inputItemID'] == 990001 and r['inputCount'] == 5 and r['sourceKey'] == 'itemdb', 'record input')
ok(r['evidenceRecordIDs'] == ['midnight/2026-10-31-fixture.json#0', 'midnight/2026-10-31-fixture.json#2',
                              'midnight/2026-10-31-fixture.json#3'], 'the bigger copy of lineage fixture-a wins')
ok('https://example.org/fixture/a-repost' not in r['source'], 'the smaller repost is not used')
near(r['samples'], 210, 'record samples = most weighted casts of any output')
ok('evidenceMinimumSkill' in r and r['evidenceMinimumSkill'] == 1, 'agreed minimum skill is kept for information')
by_id = {m['id']: m for m in r['materials']}

gem = by_id[990101]
# 200 casts at full weight + 80 stale, above-minimum casts at 0.25 x 0.5 = 10 casts.
near(gem['dropChance']['samples'], 210, 'gem casts')
near(gem['dropChance']['value'], 41 / 210, 'gem chance = weighted drops / weighted casts')
ok(gem['dropChance']['confidence'] == eb.rate_confidence(41, 210), 'gem confidence from the counts')
near(gem['expectedQuantity']['value'], 54 / 200, 'average only from records that counted quantities')
ok(gem['minQuantity']['value'] == 1 and gem['maxQuantity']['value'] == 3, 'range = smallest and largest seen')
ok(gem['dropChance']['status'] == 'measured', 'real counts are measured')

ore = by_id[990102]
near(ore['dropChance']['value'], 1.0, 'always drops')
near(ore['expectedQuantity']['value'], 3.0, 'average 3')

guess = by_id[990103]
near(guess['dropChance']['samples'], 10, 'percentage without sample size = 20-cast guess x 0.5 (unknown skill)')
near(guess['dropChance']['value'], 0.05, 'guess keeps its stated chance')
ok(guess['dropChance']['status'] == 'provisional', 'a guess is provisional, not measured')
ok(guess['expectedQuantity'] == {'status': 'unknown', 'confidence': 0}, 'no average invented')
ok(guess['minQuantity'] == {'status': 'unknown', 'confidence': 0}, 'no range invented')

# Weights.
ok(eb.record_weight({'stale': False, 'skill': 5, 'minimumSkill': 5, 'stats': None}) == 1, 'baseline sample')
ok(eb.record_weight({'stale': False, 'skill': 5, 'minimumSkill': 5, 'stats': {'multicraft': 12}}) == 0.5,
   'bonus stats are not baseline')
ok(eb.record_weight({'stale': True}) == 0.125, 'stale + unknown skill')

# An average that contradicts the chance and range is dropped, never shipped.
bad = eb.material(1, {'casts': 10.0, 'drops': 1.0, 'qtyCasts': 10.0, 'qty': 9.0, 'lo': 1, 'hi': 2, 'real': True})
ok(bad['expectedQuantity']['status'] == 'unknown', 'contradictory average left for the addon to fill')

# Totals-only observations have their own true operation denominator. They do
# not acquire a drop probability from units, stack guesses, or another study.
units = next(row for row in records if row['inputItemID'] == 990004)
ok(units['recipeID'] == 13262 and units['expansionID'] == 11 and units['inputRarity'] == 3 and units['inputClassID'] == 4,
   'exact operation and gear identity metadata survive conversion')
ok(units['referenceContextID'] == 'fixture-maxspec-study' and units['referenceConditions'] == {}, 'source context survives conversion')
ok(units['recordID'].startswith('evidence:Disenchant:990004:x1:scope:'), 'scoped evidence identity cannot collide with legacy records')
for m, total in zip(units['materials'], (629, 660)):
    near(m['expectedQuantity']['value'], total / 1000, 'units divided by actual completed operations')
    near(m['expectedQuantity']['samples'], 500, 'unknown-baseline weighting changes support, not E')
    ok(m['expectedQuantity']['observedSamples'] == 1000 and m['expectedQuantity']['sampleSizeKnown'], 'actual n recorded independently')
    ok(m['dropChance'] == {'status': 'unknown', 'confidence': 0}, 'unit total never masquerades as occurrence probability')
    ok(m['minQuantity']['status'] == 'unknown' and m['maxQuantity']['status'] == 'unknown', 'unit totals invent no stack range')

mean = next(row for row in records if row['inputItemID'] == 990005)
family = mean['materials'][0]
near(family['expectedQuantity']['value'], 13, 'published family mean included once')
ok(family['rankIDs'] == [990501, 990502] and family['rankSources'] == ['https://example.org/fixture/rank-family'], 'sourced family alternatives preserved')
ok(family['expectedQuantity']['status'] == 'provisional' and family['expectedQuantity']['samples'] == 0
   and family['expectedQuantity']['observedSamples'] == 0 and not family['expectedQuantity']['sampleSizeKnown'], 'unknown-n mean never claims measured casts')
near(family['expectedQuantity']['priorWeight'], 10, 'unknown-n expectation uses only a half-weight 20-cast prior')
ok(family['expectedQuantity']['confidence'] == 20 and family['dropChance']['status'] == 'unknown', 'field-specific source quality does not invent P')
ok(mean['samples'] == 0 and mean['inputQualityRank'] == 1, 'row preserves unknown observed n and exact input rank')

def build_sources(sources):
    report = {'usable': [], 'setAside': []}
    for index, source in enumerate(sources):
        ok(evidence_check.check_record(source)[1] == [], 'test source validates')
        report['usable'].append({'id': f'scope.json#{index}', 'kind': 'evidence', 'record': source})
    return eb.build(report)

source = copy.deepcopy(next(entry['record'] for entry in report['usable'] if entry['kind'] == 'evidence' and entry['record']['input'] == 990004))
copy_source = copy.deepcopy(source)
copy_source.update(casts=100, source='https://example.org/repost')
copy_source['outputs'] = [{'item': 990401, 'totalQuantity': 100}]
scoped, detail = build_sources([source, copy_source])
ok(len(scoped) == 1 and detail['duplicates'] == 1 and scoped[0]['materials'][0]['expectedQuantity']['observedSamples'] == 1000,
   'same published study deduplicates inside one exact scope')
other_scope = copy.deepcopy(copy_source)
other_scope['inputRarity'] = 4
scoped, detail = build_sources([source, other_scope])
ok(len(scoped) == 2 and len({row['recordID'] for row in scoped}) == 2 and detail['duplicates'] == 0, 'different identity scopes never collide or deduplicate')
other_context = copy.deepcopy(source)
other_context['referenceContextID'] = 'different-source-conditions'
scoped, _ = build_sources([source, other_context])
ok(len(scoped) == 2, 'different source contexts remain separate distributions')
stale = copy.deepcopy(source)
stale['stale'] = True
scoped, _ = build_sources([stale])
near(scoped[0]['materials'][0]['expectedQuantity']['samples'], 125, 'stale units-only study discounted')
near(scoped[0]['materials'][0]['expectedQuantity']['value'], .629, 'stale discount never changes source mean')

# Lua output round-trips through the checked-in format and --check spots drift.
text = eb.render(records)
ok(text.startswith('-- Generated by tools/evidence_to_baselines.py') and 'evidence:Prospect:990001:x5' in text, 'render')
with tempfile.TemporaryDirectory() as tmp, contextlib.redirect_stdout(io.StringIO()):
    out = Path(tmp) / 'b.lua'
    ok(eb.main(['tests/fixtures/evidence-v3', str(out)]) == 0 and out.read_text() == text, 'write')
    ok(eb.main(['--check', 'tests/fixtures/evidence-v3', str(out)]) == 0, 'check passes when current')
    out.write_text(text + '-- edited\n')
    ok(eb.main(['--check', 'tests/fixtures/evidence-v3', str(out)]) == 1, 'check fails when edited')

print(f'EVIDENCE BASELINE TESTS: {passed} passed, 0 failed')
