"""Reviewed historical source cannot overwrite independent current token semantics."""
import copy
import hashlib
import json
import sys
import tempfile
import unittest
from collections import Counter
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import research_v3_tokens as tokens

FIXTURE = ROOT / 'tests/fixtures/token-source-applicability'
HELD_ID = 'legacy-20261107-234113'
CURRENT_ID = 'legacy-20261101-216'
POLICY = json.loads((ROOT / 'database/research/token-admission.json').read_text())


class SourceApplicability(unittest.TestCase):
    def setUp(self):
        rows = tokens.load_rows(FIXTURE)
        self.current = next(r for r in rows if r['id'] == CURRENT_ID)
        self.held = next(r for r in rows if r['id'] == HELD_ID)

    def build(self, rows):
        with patch.object(tokens, 'load_rows', return_value=rows):
            return tokens.build_tokens(FIXTURE, 'fixture', staged={})

    def test_immutable_source_bytes(self):
        for entry in json.loads((FIXTURE / 'manifest.json').read_text()):
            raw = (FIXTURE / entry['path']).read_bytes()
            self.assertEqual(len(raw), entry['bytes'])
            self.assertEqual(hashlib.sha256(raw).hexdigest(), entry['sha256'])
            self.assertEqual(hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest(), entry['gitBlob'])
            self.assertIn('/blob/' + entry['commit'] + '/' + entry['path'], entry['url'])

    def test_actual_historical_record_regression(self):
        expected, _, _ = self.build([self.current])
        actual, notes, conflicts = self.build([self.current, self.held])
        self.assertEqual(actual, expected)
        self.assertEqual(actual[0]['kind'], 'open')
        self.assertEqual(actual[0]['rewards'], [45339, 45344, 45349, 45352, 45359, 45369, 45400])
        self.assertEqual(actual[0]['researchRecordIDs'], [CURRENT_ID])
        self.assertFalse(actual[0]['requirementsReviewed'])
        self.assertEqual(actual[0]['independentReview'], 'NOT_REVIEWED')
        self.assertEqual(sum(notes.values()), 1)
        self.assertEqual(conflicts, [])
        with patch.object(tokens, 'token_admission', side_effect=lambda rows: (rows, Counter())):
            original, _, _ = self.build([self.current, self.held])
        self.assertEqual(original[0]['kind'], 'exchange')
        self.assertFalse(original[0]['costsComplete'])
        self.assertEqual(original[0]['rewardSelection'], 'choice')

    def test_held_only_never_becomes_free_open(self):
        records, notes, _ = self.build([self.held])
        self.assertEqual(records, [])
        self.assertEqual(sum(notes.values()), 1)

    def test_all_held_claims_and_replacement_are_removed(self):
        held = copy.deepcopy(self.held)
        held.update(tokenName='Held name', replaces=CURRENT_ID, listComplete=True,
                    source={'url': 'https://example.invalid/held'},
                    rewards=[{'itemID': 999999, 'name': 'Held-only reward'}])
        current = copy.deepcopy(self.current)
        current['listComplete'] = False
        actual, _, _ = self.build([held, current])
        expected, _, _ = self.build([current])
        self.assertEqual(actual, expected)
        self.assertNotIn('Held', json.dumps(actual))

    def test_independent_vendor_is_not_rejected(self):
        vendor = copy.deepcopy(self.held)
        vendor['id'] = 'independent-current-vendor'
        records, notes, _ = self.build([self.current, self.held, vendor])
        self.assertEqual(records[0]['kind'], 'exchange')
        self.assertFalse(records[0]['costsComplete'])
        self.assertIn(vendor['id'], records[0]['researchRecordIDs'])
        self.assertNotIn(HELD_ID, records[0]['researchRecordIDs'])
        self.assertEqual(sum(notes.values()), 2)  # hold plus unknown vendor costs

    def test_same_record_id_other_file_is_not_the_reviewed_identity(self):
        row = copy.deepcopy(self.held)
        row['_file'] = 'legacy/independent.jsonl'
        admitted, notes = tokens.token_admission([row])
        self.assertEqual(admitted, [row])
        self.assertEqual(notes, {})

    def test_source_text_is_not_a_classifier(self):
        row = copy.deepcopy(self.held)
        row['id'] = 'independent-historical-wording'
        admitted, notes = tokens.token_admission([row])
        self.assertEqual(admitted, [row])
        self.assertEqual(notes, {})

    def test_new_wayward_sources_are_held_without_blocking_independent_vendors(self):
        rows = [r for r in tokens.load_rows(FIXTURE) if r['id'] in
                ('legacy-20261109-94008', 'legacy-20261109-94009')]
        self.assertEqual(len(rows), 2)
        self.assertEqual(self.build(rows)[0], [])
        for row in rows:
            independent = copy.deepcopy(row)
            independent['id'] += '-independent'
            records, _, _ = self.build([row, independent])
            self.assertEqual(len(records), 1)
            self.assertEqual(records[0]['kind'], 'exchange')
            self.assertFalse(records[0]['costsComplete'])
            self.assertEqual(records[0]['researchRecordIDs'], [independent['id']])

    def test_corrections_and_replacements_still_apply(self):
        with patch.object(tokens, 'excluded_ids', return_value={(CURRENT_ID, None): True}):
            self.assertEqual(self.build([self.current, self.held])[0], [])
        replacement = copy.deepcopy(self.current)
        replacement.update(id='replacement', replaces=CURRENT_ID)
        records, _, _ = self.build([self.current, self.held, replacement])
        self.assertEqual(records[0]['researchRecordIDs'], ['replacement'])

    def test_imported_copy_stays_excluded(self):
        row = copy.deepcopy(self.current)
        row['_file'] = 'imported/old.jsonl'
        self.assertEqual(self.build([row, self.held])[0], [])

    def test_pinned_all_records_notes_and_conflicts_unchanged(self):
        snapshot = ROOT / 'database/research/v3-snapshot'
        staged = tokens.load_staged([ROOT / p for p in tokens.STAGED])
        actual = tokens.build_tokens(snapshot, 'same-revision', staged)
        with patch.object(tokens, 'token_admission', side_effect=lambda rows: (rows, Counter())):
            expected = tokens.build_tokens(snapshot, 'same-revision', staged)
        self.assertEqual(actual, expected)
        self.assertEqual(len(actual[0]), 237)

    def test_invalid_policy_fails_closed(self):
        malformed = [None, [], {}, {'version': True, 'exclusions': []},
                     {'version': 1, 'exclusions': {}}, {'version': 1, 'exclusions': [None]}]
        for key, values in {'recordIDs': [None, [], 'id', [None], ['']],
                            'file': [None, '', '/absolute', '../escape'],
                            'reason': [None, ''], 'reviewEvidence': [None, [], ['http://bad']]}.items():
            for value in values:
                policy = copy.deepcopy(POLICY)
                policy['exclusions'][0][key] = value
                malformed.append(policy)
        duplicate = copy.deepcopy(POLICY)
        duplicate['exclusions'].append(copy.deepcopy(duplicate['exclusions'][0]))
        malformed.append(duplicate)
        for policy in malformed:
            with self.subTest(policy=policy), patch.object(tokens.json, 'loads', return_value=policy):
                with self.assertRaises(ValueError):
                    tokens.token_admission([self.held])
        with patch.object(tokens.json, 'loads', return_value={'version': 1, 'exclusions': []}):
            self.assertEqual(tokens.token_admission([self.held]), ([self.held], Counter()))

    def test_missing_policy_fails_closed(self):
        with patch.object(Path, 'read_text', side_effect=FileNotFoundError):
            with self.assertRaises(FileNotFoundError):
                tokens.token_admission([self.held])


if __name__ == '__main__':
    unittest.main()
