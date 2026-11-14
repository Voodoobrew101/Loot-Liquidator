"""Exact held Anniversary cohorts, not an item/skill/notes-based quarantine."""
import copy
import hashlib
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True
sys.path.insert(0, 'tools')
import research_v3_to_baselines as v3

SNAPSHOT = Path('database/research/v3-snapshot')
FIXTURE = Path('tests/fixtures/retail-admission/anniversary-held.jsonl')
SHA256 = '7e3cd720753be660e92fddb53c58b2a2039295389d2dd36a34168d2ce85582e5'


def rows():
    raw = FIXTURE.read_bytes()
    if hashlib.sha256(raw).hexdigest() != SHA256:
        raise ValueError('Immutable Anniversary fixture changed')
    return [json.loads(line) for line in raw.decode().splitlines()]


class AnniversaryAdmissionTests(unittest.TestCase):
    def test_source_identity_and_explicit_hold(self):
        source = rows()
        self.assertEqual(len(source), 16)
        self.assertEqual({r['inputItemID'] for r in source}, {224744, 224745, 224747})
        self.assertEqual(len({r['studyKey'] for r in source}), 3)
        for r in source:
            self.assertEqual(r['sourceKind'], 'study')
            self.assertIn('DO NOT promote into current The War Within disenchant baseline', r['notes'])
        self.assertEqual({r['inputItemID']: r['casts'] for r in source},
                         {224744: 32, 224745: 199, 224747: 53})

    def test_both_passes_hold_rows_without_mutation_or_item_blacklist(self):
        source = rows()
        control = copy.deepcopy(source[1])
        control.update(id='independent-same-item-study', studyKey='independent-same-item-study')
        # Identical item, skill, URL and notes must not be a heuristic blacklist.
        loaded = source + [control]
        before = copy.deepcopy(loaded)
        module = v3.load_calculator(SNAPSHOT)
        build = module.build
        calls = []
        def observe(data):
            calls.append(copy.deepcopy(data))
            return build(data)
        with patch.object(module, 'load', return_value=loaded), patch.object(module, 'build', side_effect=observe), patch.object(v3, 'load_calculator', return_value=module):
            records, notes, total, counted, _ = v3.build(SNAPSHOT)
        self.assertEqual(len(calls), 2)
        for call in calls:
            self.assertEqual(call, [control])
        self.assertEqual((total, counted), (17, 1))
        self.assertEqual(sum(notes.values()), 16)
        self.assertEqual([r['inputItemID'] for r in records], [224744])
        self.assertEqual(loaded, before)

    def test_existing_gate_fails_without_new_identities(self):
        module = v3.load_calculator(SNAPSHOT)
        with patch.object(module, 'load', return_value=rows()), patch.object(v3, 'load_calculator', return_value=module):
            records, *_ = v3.build(SNAPSHOT)
        self.assertEqual(records, [])

    def test_reachable_regression_is_three_priced_records_without_gate(self):
        module = v3.load_calculator(SNAPSHOT)
        with patch.object(module, 'load', return_value=rows()), patch.object(v3, 'load_calculator', return_value=module), patch.object(v3, 'retail_admission', side_effect=lambda data: (data, {})):
            records, *_ = v3.build(SNAPSHOT)
        self.assertEqual({r['inputItemID'] for r in records}, {224744, 224745, 224747})
        self.assertTrue(all(any(m['expectedQuantity'].get('value', 0) > 0
                            for m in r['materials'] if m['expectedQuantity'].get('value') is not None)
                            for r in records))

    def test_each_identity_independently_holds_renamed_and_malformed_copy(self):
        for missing in (None, '', [], {}, 0, False, ['not-an-identity']):
            for field in ('id', 'studyKey'):
                row = copy.deepcopy(rows()[0])
                row[field] = missing
                admitted, notes = v3.retail_admission([row])
                self.assertEqual(admitted, [])  # the other exact identity survives
                self.assertEqual(sum(notes.values()), 1)
        row = copy.deepcopy(rows()[0])
        row.pop('id')
        self.assertEqual(v3.retail_admission([row])[0], [])
        row = copy.deepcopy(rows()[0])
        row.pop('studyKey')
        self.assertEqual(v3.retail_admission([row])[0], [])

    def test_lost_identity_is_not_inferred_from_item_or_prose(self):
        for missing in (None, '', [], {}, 0, False):
            row = copy.deepcopy(rows()[0])
            row.update(id=missing, studyKey=missing)
            admitted, notes = v3.retail_admission([row])
            self.assertEqual(admitted, [row])
            self.assertFalse(notes)
        row = copy.deepcopy(rows()[0])
        row.pop('id'); row.pop('studyKey')
        self.assertEqual(v3.retail_admission([row])[0], [row])

    def test_earlier_transcription_is_not_independent_support(self):
        raw = FIXTURE.with_name('anniversary-earlier.jsonl').read_bytes()
        self.assertEqual(hashlib.sha256(raw).hexdigest(),
                         'd280d8207bc661301369b9b88ea3e3428e99afe77ce7ca257d85d92aa7fee6e5')
        earlier = [json.loads(line) for line in raw.decode().splitlines()]
        self.assertEqual(len(earlier), 11)
        self.assertTrue(all(r['outputItemID'] is None for r in earlier))
        self.assertEqual(v3.retail_admission(earlier)[0], earlier)
        module = v3.load_calculator(SNAPSHOT)
        with patch.object(module, 'load', return_value=earlier + rows()), patch.object(v3, 'load_calculator', return_value=module):
            records, *_ = v3.build(SNAPSHOT)
        self.assertEqual(records, [])

    def test_malformed_policy_cannot_silently_disable_hold(self):
        valid = json.loads(Path('database/research/retail-admission.json').read_text())
        variants = [[], None, {}, dict(valid, version=True), dict(valid, version='1')]
        for value in (None, {}, '', 0):
            variants.append(dict(valid, exclusions=value))
        for value in (None, [], '', 0):
            variants.append(dict(valid, exclusions=[value]))
        for key in ('recordIDs', 'studyKeys', 'reason', 'review'):
            values = (None, {}, '', 0, [None], ['']) if key in ('recordIDs', 'studyKeys') else (None, {}, '', 0)
            for value in values:
                rule = copy.deepcopy(valid['exclusions'][-1])
                rule[key] = value
                variants.append(dict(valid, exclusions=[rule]))
            rule = copy.deepcopy(valid['exclusions'][-1])
            rule.pop(key)
            variants.append(dict(valid, exclusions=[rule]))
        rule = copy.deepcopy(valid['exclusions'][-1])
        rule.update(recordIDs=[], studyKeys=[])
        variants.append(dict(valid, exclusions=[rule]))
        for invalid in variants:
            with self.subTest(policy=invalid), patch.object(Path, 'read_text', return_value=json.dumps(invalid)):
                with self.assertRaises(ValueError):
                    v3.retail_admission(rows())

    def test_valid_policy_variants_keep_exact_matching(self):
        policy = json.loads(Path('database/research/retail-admission.json').read_text())
        for empty in ('recordIDs', 'studyKeys'):
            rule = copy.deepcopy(policy['exclusions'][-1])
            rule[empty] = []
            with patch.object(Path, 'read_text', return_value=json.dumps(dict(policy, exclusions=[rule]))):
                self.assertEqual(v3.retail_admission(rows())[0], [])
        with patch.object(Path, 'read_text', return_value=json.dumps(dict(policy, exclusions=[]))):
            self.assertEqual(v3.retail_admission(rows())[0], rows())

    def test_pinned_build_unchanged(self):
        baseline = v3.build(SNAPSHOT)
        original = v3.retail_admission
        policy = json.loads(Path('database/research/retail-admission.json').read_text())
        old = copy.deepcopy(policy)
        old['exclusions'] = [r for r in old['exclusions']
                             if 'war-within-20261108-2228-001' not in r['recordIDs']]
        real_read = Path.read_text
        def old_policy(path, *args, **kwargs):
            if path.name == 'retail-admission.json':
                return json.dumps(old)
            return real_read(path, *args, **kwargs)
        with patch.object(Path, 'read_text', old_policy):
            self.assertEqual(v3.build(SNAPSHOT), baseline)
        # The original shared helper remains the enforcement mechanism.
        self.assertIs(v3.retail_admission, original)


if __name__ == '__main__':
    unittest.main()
