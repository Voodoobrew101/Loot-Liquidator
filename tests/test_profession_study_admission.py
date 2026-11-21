"""Actual profession studies retain exact method/recipe/profile identity."""
import copy
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import warnings

sys.path.insert(0, 'tools')
import evidence_check as checker
import evidence_to_baselines as local
import research_build_review as review
import research_v3_to_baselines as v3
from research_methods import GENERIC_METHODS, processing_reasons, apply_reviewed_operation_aliases


class ProfessionStudyAdmission(unittest.TestCase):
    def setUp(self):
        warnings.simplefilter('ignore', ResourceWarning)

    def source(self, **updates):
        row = {'id': 'study', 'type': 'drop', 'method': 'Craft', 'profession': 'Alchemy',
               'recipeID': 999001, 'expansionID': 11, 'inputItemID': 999100,
               'outputItemID': 999200, 'inputsPerCast': 2, 'casts': 10,
               'totalQuantity': 20, 'cohortKey': 'controlled-fixture',
               'sourceKind': 'comment', 'source': {'url': 'https://example.org/controlled-fixture'},
               'dataDate': '2026-11-01', 'patch': '12.1.5',
               'baselineProfile': {'skill': 0, 'preSpecializationSkill': 0, 'stats': {}, 'specializationPoints': {}}}
        row.update(updates)
        return row

    def make_snapshot(self, root, rows):
        snapshot = root / 'snapshot'
        data = snapshot / 'research/v3'
        shutil.copytree(v3.DEFAULT_SNAPSHOT / 'research/v3/tools', data / 'tools')
        (data / 'evidence').mkdir()
        (data / 'evidence/studies.jsonl').write_text(''.join(json.dumps(r) + '\n' for r in rows))
        for name in ('corrections.jsonl', 'conditions.jsonl', 'rate-changes.jsonl'):
            (data / name).write_text('')
        (snapshot / 'SNAPSHOT.json').write_text(json.dumps({'commit': 'f' * 40, 'branch': 'fixture', 'paths': v3.SNAPSHOT_PATHS}))
        return snapshot

    def test_v3_real_methods_stay_distinct_and_counts_are_not_benchmarks(self):
        base = self.source()
        rows = [base, dict(base, id='copy'),
                self.source(id='other-recipe', recipeID=999002, totalQuantity=50, cohortKey='other-recipe'),
                self.source(id='other-era', expansionID=10, totalQuantity=30, cohortKey='other-era'),
                self.source(id='other-profile', totalQuantity=40, cohortKey='other-profile',
                            baselineProfile={'skill': 100, 'stats': {'multicraft': {'percent': 25}}}),
                self.source(id='published', inputItemID=999101, casts=None, totalQuantity=None,
                            averageShown=2.5, averagePer='cast', cohortKey='published')]
        for index, (method, profession) in enumerate([('Research', 'Engineering'), ('Recycle', 'Engineering'),
                ('Unravel', 'Tailoring'), ('Crush', 'Jewelcrafting'), ('Thaumaturgy', 'Alchemy'), ('Refine', 'Herbalism')]):
            rows.append(self.source(id=method, method=method, profession=profession, recipeID=999010 + index, cohortKey=method))
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            snapshot = self.make_snapshot(root, rows)
            original = (snapshot / 'research/v3/evidence/studies.jsonl').read_bytes()
            records, notes, *_ = v3.build(snapshot)
            self.assertEqual(len(records), 11)
            self.assertEqual({r['method'] for r in records}, GENERIC_METHODS)
            crafts = [r for r in records if r['method'] == 'Craft' and r['inputItemID'] == 999100]
            self.assertEqual(sorted(r['materials'][0]['expectedQuantity']['value'] for r in crafts), [2, 3, 4, 5])
            self.assertEqual(len({r['recordID'] for r in crafts}), 4)
            for record in records:
                self.assertIsInstance(record['profession'], str)
                self.assertIsInstance(record['recipeID'], int)
                self.assertIn(record['expansionID'], (10, 11))
                self.assertEqual(record['sourceOperationScope']['profession'], record['profession'])
                field = record['materials'][0]['expectedQuantity']
                self.assertEqual(field['samples'], 0 if record['inputItemID'] == 999101 else 5)
            published = next(r for r in records if r['inputItemID'] == 999101)['materials'][0]['expectedQuantity']
            self.assertFalse(published['sampleSizeKnown'])
            self.assertEqual(original, (snapshot / 'research/v3/evidence/studies.jsonl').read_bytes())
            result = review.build_review(snapshot, root / 'no-local')
            self.assertTrue(all(r['disposition'] == 'ADMITTED_TO_BASELINE_PIPELINE' for r in result['rows']))

    def test_unverified_profession_recipe_batch_and_world_ids_remain_held(self):
        base = self.source()
        malformed = [dict(base, profession=None), dict(base, recipeID=None), dict(base, inputsPerCast=None),
                     dict(base, expansionID=None), dict(base, method='Unravel', profession='Alchemy'),
                     dict(base, method='Gather', profession='Herbalism', nativeTargetID='gameobject:123')]
        before = copy.deepcopy(malformed)
        admitted, notes = review.automatic_admission(malformed)
        self.assertFalse(admitted)
        self.assertEqual(malformed, before)
        self.assertTrue(any('native-target' in reason for reason in notes))
        self.assertFalse(processing_reasons(base))

    def test_build_review_keeps_disjoint_compiled_fields_in_either_record_order(self):
        rows = [self.source(id='quantity-source', cohortKey='quantity-source'),
                self.source(id='chance-source', cohortKey='chance-source', totalQuantity=None, castsWithDrop=3)]
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            snapshot = self.make_snapshot(root, rows)
            records, notes, total, counted, unplaced = v3.build(snapshot)
            self.assertEqual(len(records), 1)
            original = copy.deepcopy(records)
            quantity, chance = copy.deepcopy(records[0]), copy.deepcopy(records[0])
            quantity['recordID'] += ':quantity-only'
            chance['recordID'] += ':chance-only'
            unknown = {'status': 'unknown', 'confidence': 0}
            for record, kept in ((quantity, 'expectedQuantity'), (chance, 'dropChance')):
                for field in ('expectedQuantity', 'dropChance', 'minQuantity', 'maxQuantity'):
                    if field != kept:
                        record['materials'][0][field] = copy.deepcopy(unknown)
                self.assertIn('value', record['materials'][0][kept])
            for order in ([quantity, chance], [chance, quantity]):
                with self.subTest(first=order[0]['recordID']), patch.object(
                        v3, 'build', return_value=(order, notes, total, counted, unplaced)):
                    report = review.build_review(snapshot, root / 'no-local')
                reviewed = {row['recordID']: row for row in report['rows']}
                self.assertEqual(reviewed['quantity-source']['disposition'], 'ADMITTED_TO_BASELINE_PIPELINE')
                self.assertEqual(reviewed['quantity-source']['supportedFields'], ['expectedQuantity'])
                self.assertEqual(reviewed['chance-source']['disposition'], 'ADMITTED_TO_BASELINE_PIPELINE')
                self.assertEqual(reviewed['chance-source']['supportedFields'], ['dropChance'])
            self.assertEqual(records, original)

    def local_source(self, **updates):
        row = {'method': 'Craft', 'profession': 'Cooking', 'recipeID': 999301, 'expansionID': 11,
               'input': 999100, 'inputPerCast': 2, 'casts': 10,
               'outputs': [{'item': 999200, 'totalQuantity': 20}],
               'source': 'https://example.org/cooking-study', 'lineage': 'cooking-study',
               'observedDate': '2026-11-01', 'patch': '12.1.5', 'stale': False,
               'referenceConditions': {'skill': 100}}
        row.update(updates)
        return row

    def test_local_craft_admission_and_source_scope_are_not_recycle_aliases(self):
        a = self.local_source()
        b = self.local_source(recipeID=999302, lineage='other-recipe', outputs=[{'item': 999200, 'totalQuantity': 50}])
        self.assertFalse(checker.check_evidence(a))
        self.assertFalse(checker.check_evidence(b))
        report = {'usable': [{'kind': 'evidence', 'id': 'fixture.json#' + str(i), 'record': r} for i, r in enumerate([a, b])], 'setAside': []}
        records, _ = local.build(report)
        self.assertEqual(len(records), 2)
        self.assertEqual({r['method'] for r in records}, {'Craft'})
        self.assertEqual({r['profession'] for r in records}, {'Cooking'})
        self.assertEqual({r['recipeID'] for r in records}, {999301, 999302})
        self.assertEqual(sorted(r['materials'][0]['expectedQuantity']['value'] for r in records), [2, 5])
        self.assertTrue(all(r['materials'][0]['expectedQuantity']['samples'] == 5 for r in records))
        self.assertTrue(checker.check_evidence(self.local_source(profession=None)))
        self.assertTrue(checker.check_evidence(self.local_source(method='Unravel', profession='Cooking')))
        world = self.local_source(method='Skin', profession='Skinning')
        self.assertTrue(any('native-target' in why for why in checker.check_evidence(world)))

    def test_reviewed_shatter_alias_is_exact_and_keeps_refund_units_separate(self):
        policy = json.loads(Path('database/research/reviewed-operation-aliases.json').read_text())
        aliases = policy['aliases']
        rows = []
        for file in sorted({a['sourceFile'] for a in aliases}):
            rows.extend(dict(json.loads(line), _file=file) for line in (v3.DEFAULT_SNAPSHOT / file).read_text().splitlines())
        before = copy.deepcopy(rows)
        mapped = apply_reviewed_operation_aliases(rows)
        by_id = {r['id']: r for r in mapped}
        self.assertEqual(rows, before)
        for alias in aliases:
            raw = next(r for r in rows if r['id'] == alias['recordID'])
            row = by_id[raw['id']]
            self.assertEqual((row['method'], row['profession'], row['recipeID'], row['expansionID']), ('Craft', 'Enchanting', 470726, 10))
            for field in ('casts', 'castsWithDrop', 'totalQuantity', 'sourceKind', 'skill', 'specialization', 'stats', 'source', 'dataDate', 'patch'):
                self.assertEqual(row.get(field), raw.get(field))
            self.assertEqual(row['operationAlias']['sourceMethod'], 'Disenchant')
        refund = by_id['war-within-20261120-0338-001']
        self.assertEqual(refund['casts'], 1700)
        self.assertEqual(refund['sourceKind'], 'reference')
        self.assertIsNone(refund['totalQuantity'])
        self.assertIsNone(refund['castsWithDrop'])
        self.assertIsNone(refund['outputItemID'])
        self.assertNotIn('baselineProfile', refund)
        changed = copy.deepcopy(rows[0]);changed['totalQuantity'] = 999
        blocked = apply_reviewed_operation_aliases([changed])[0]
        self.assertTrue(blocked['_operationAliasBlocked'])
        self.assertFalse(review.automatic_admission([blocked])[0])
        unrelated = dict(rows[0], _file='unreviewed-copy.jsonl')
        self.assertEqual(apply_reviewed_operation_aliases([unrelated])[0]['method'], 'Disenchant')

    def test_shatter_completed_operation_means_reach_the_real_v3_pipeline(self):
        records, *_ = v3.build(v3.DEFAULT_SNAPSHOT)
        all_shatters = [r for r in records if r['method'] == 'Craft' and r.get('recipeID') == 470726]
        shatters = [r for r in all_shatters if r.get('baselineProfileAssumed')]
        self.assertEqual(len(shatters), 2)
        self.assertEqual(len(all_shatters), 3)
        occurrence = next(r for r in all_shatters if not r.get('baselineProfileAssumed'))['materials'][0]
        self.assertEqual(occurrence['dropChance']['value'], 1)
        self.assertEqual(occurrence['dropChance']['samples'], 1)
        self.assertEqual(occurrence['expectedQuantity']['status'], 'unknown')
        expected = {219950: (1064, {219946: 2157, 219947: 1035}),
                    219951: (1066, {219946: 1314, 219947: 1275, 219948: 609})}
        for row in shatters:
            casts, outputs = expected[row['inputItemID']]
            self.assertTrue(row['baselineProfileAssumed'])
            self.assertEqual(row['baselineProfileConfidence'], 0)
            self.assertEqual(row['baselineProfile']['preSpecializationSkill'], 133)
            self.assertEqual(row['baselineProfile']['specializationPoints'], {'99890': 30, '99889': 30})
            self.assertEqual(row['samples'], casts * v3.NOT_BASELINE_FACTOR)
            for material in row['materials']:
                self.assertAlmostEqual(material['expectedQuantity']['value'], outputs[material['id']] / casts)
                self.assertEqual(material['expectedQuantity']['samples'], casts * v3.NOT_BASELINE_FACTOR)
                self.assertEqual(material['dropChance']['status'], 'unknown')
            self.assertAlmostEqual(sum(m['expectedQuantity']['value'] for m in row['materials']), 3)
            self.assertTrue(all(e['operationAlias']['sourceMethod'] == 'Disenchant' for e in row['sourceEvidence']))

    def test_lua_export_preserves_numeric_string_and_reserved_profile_keys(self):
        value = {'specializationPoints': {'99890': 30, '99889': 30},
                 'learnedSpecializations': {'99890': True, '99889': True},
                 'end': 'reserved', 'a-b': 'punctuation', '1': 'string', 1: 'number',
                 'controls': 'line\r\n\t\x007', 'nilValue': None}
        serialized = local.lua(value)
        self.assertIn('["99890"]=30', serialized)
        self.assertIn('["end"]="reserved"', serialized)
        self.assertIn('[1]="number"', serialized)
        self.assertEqual(serialized, local.lua(dict(reversed(list(value.items())))))
        script = 'local t=' + serialized + '\n' + '''
assert(t.specializationPoints['99890']==30 and t.specializationPoints['99889']==30)
assert(t.learnedSpecializations['99890']==true and t.learnedSpecializations['99889']==true)
assert(t['end']=='reserved' and t['a-b']=='punctuation')
assert(t['1']=='string' and t[1]=='number' and t.nilValue==nil)
assert(t.controls==('line'..string.char(13,10,9,0)..'7'))
'''
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            runner = shutil.which('lua5.1')
            self.assertIsNotNone(runner, 'Lua5.1 runner required for export round-trip')
            with tempfile.TemporaryDirectory() as temporary:
                path = Path(temporary) / 'roundtrip.lua'
                path.write_text(script, encoding='utf-8')
                subprocess.run([runner, str(path)], check=True)
        else:
            LuaRuntime(unpack_returned_tuples=True).execute(script)

    def test_unverified_resonant_table_denominators_do_not_become_cast_samples(self):
        source = v3.DEFAULT_SNAPSHOT / 'research/v3/evidence/dragonflight/2026-11-20T0347-resonant-crystal-ten-unindexed-gear-items.jsonl'
        raw_bytes = source.read_bytes()
        rows = [json.loads(line) for line in raw_bytes.decode('utf-8').splitlines() if line.strip()]
        self.assertEqual(len(rows), 10)
        self.assertTrue(all(r['percentMeaning'] == 'unclear' and r['outputItemID'] == 200113 for r in rows))
        admitted, notes = v3.retail_admission(rows)
        self.assertFalse(admitted)
        self.assertEqual(sum(notes.values()), 10)
        copies = [dict(row, id='renamed-copy-' + row['id']) for row in rows]
        self.assertFalse(v3.retail_admission(copies)[0])
        control = self.source(id='verified-control', method='Disenchant', profession='Enchanting',
                              inputsPerCast=1, recipeID=13262, cohortKey='verified-control')
        with tempfile.TemporaryDirectory() as temporary:
            snapshot = self.make_snapshot(Path(temporary), rows + [control])
            records, reasons, *_ = v3.build(snapshot)
            self.assertEqual(len(records), 1)
            self.assertEqual(records[0]['inputItemID'], control['inputItemID'])
            self.assertEqual(records[0]['materials'][0]['expectedQuantity']['samples'], 5)
            self.assertTrue(any('verified completed-operation denominator' in reason for reason in reasons))
            report = review.build_review(snapshot, Path(temporary) / 'no-local')
            dispositions = {row['recordID']: row['disposition'] for row in report['rows']}
            self.assertTrue(all(dispositions[row['id']] == 'PRESERVED_CORRECTED_OR_HELD' for row in rows))
            self.assertEqual(dispositions['verified-control'], 'ADMITTED_TO_BASELINE_PIPELINE')
        self.assertEqual(source.read_bytes(), raw_bytes)


if __name__ == '__main__':
    unittest.main()
