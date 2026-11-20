"""Exact archived unit totals survive without acquiring synthetic cast counts."""
from collections import Counter
import copy
from hashlib import sha256
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest.mock import patch
import warnings

sys.path.insert(0, 'tools')
import research_published_priors as priors
import research_v3_to_baselines as v3
import research_build_review as review

FIXTURE = Path('tests/fixtures/published-milling/legacy-milling-cohorts.jsonl')


class PublishedPerInputPriors(unittest.TestCase):
    def setUp(self):
        warnings.simplefilter('ignore', ResourceWarning)
        self.policy = json.loads(priors.POLICY.read_text())
        self.groups = self.policy['perInputGroups']
        self.rows = [json.loads(line) for line in FIXTURE.read_text().splitlines()]
        self.source_file = self.groups[0]['sourceFile']

    def snapshot(self, root, rows=None, calculator=False):
        path = root / self.source_file
        path.parent.mkdir(parents=True)
        if rows is None:
            path.write_bytes(FIXTURE.read_bytes())
        else:
            path.write_text(''.join(json.dumps(row) + '\n' for row in rows), encoding='utf-8', newline='\n')
        if calculator:
            data = root / 'research/v3'
            shutil.copytree(v3.DEFAULT_SNAPSHOT / 'research/v3/tools', data / 'tools')
            for name in ('corrections.jsonl', 'conditions.jsonl', 'rate-changes.jsonl'):
                (data / name).write_text('')
            (root / 'SNAPSHOT.json').write_text(json.dumps({'commit': 'c' * 40, 'branch': 'fixture', 'paths': v3.SNAPSHOT_PATHS}))
        return root

    def build(self, root, rows=None, records=None):
        rows = self.rows if rows is None else rows
        loaded = [dict(row, _file=self.source_file) for row in rows]
        records = [] if records is None else records
        notes = Counter()
        added = priors.preserve_published_priors(loaded, records, notes, snapshot=root)
        return added, notes

    def test_six_complete_herb_vectors_retain_all_eighteen_source_identities(self):
        before = copy.deepcopy(self.rows)
        with tempfile.TemporaryDirectory() as tmp:
            root = self.snapshot(Path(tmp))
            records, _ = self.build(root)
        self.assertEqual(len(records), 6)
        self.assertEqual(len({r['recordID'] for r in records}), 6)
        source_ids = []
        for record, group in zip(records, self.groups):
            self.assertEqual((record['inputCount'], record['quantityBasis']), (1, 'per-input'))
            self.assertTrue(record['operationUnverified'])
            self.assertEqual(record['baselineProfileConfidence'], 0)
            self.assertEqual(record['samples'], 0)
            self.assertFalse(record['sampleSizeKnown'])
            for field in ('recipeID', 'inputQualityRank', 'casts', 'castCount'):
                self.assertNotIn(field, record)
            self.assertEqual(len(record['materials']), 3)
            for material, output in zip(record['materials'], group['outputs']):
                self.assertEqual(material['expectedQuantity']['value'], output['reportedOutputTotal'] / 1000)
                self.assertEqual(material['expectedQuantity']['confidence'], 20)
                self.assertEqual(material['expectedQuantity']['modelConfidenceCap'], 0)
                self.assertEqual(material['expectedQuantity']['samples'], 0)
                self.assertNotIn('quality', material)
                for field in ('dropChance', 'minQuantity', 'maxQuantity'):
                    self.assertEqual(material[field], {'status': 'unknown', 'confidence': 0, 'inferenceBlocked': True})
            for evidence in record['sourceEvidence']:
                source_ids.append(evidence['sourceRecordID'])
                self.assertEqual(evidence['reportedInputsPerCast'], 20)
                self.assertEqual(evidence['inputsProcessed'], 1000)
                self.assertEqual(evidence['reportedSourceSupportConfidence'], 68)
                self.assertEqual(evidence['activeSourceSupportConfidence'], 20)
                self.assertEqual(evidence['archiveSHA256'], sha256((priors.ROOT / group['archivePath']).read_bytes()).hexdigest())
        self.assertEqual(sorted(source_ids), [f'import-legmill-{i:05}' for i in range(7, 25)])
        self.assertEqual(self.rows, before)

    def test_unrelated_append_or_change_does_not_blanket_hold_the_file(self):
        for operation in ('append', 'change'):
            rows = copy.deepcopy(self.rows)
            if operation == 'append':
                rows.append({'id': 'unrelated-new-source', 'type': 'note', 'notes': 'Independent later research'})
            else:
                rows[0]['notes'] += ' Unrelated record update.'
            with self.subTest(operation=operation), tempfile.TemporaryDirectory() as tmp:
                root = self.snapshot(Path(tmp), rows)
                records, _ = self.build(root, rows)
                self.assertEqual(len(records), 6)
                evidence = records[0]['sourceEvidence'][0]
                self.assertNotEqual(evidence['snapshotSourceFileSHA256'], evidence['reviewedSourceFileSHA256'])

    def test_changed_target_or_loader_identity_is_rejected_atomically(self):
        for field, value in (('totalQuantity', 815), ('averageShown', .815), ('casts', 200),
                             ('inputsPerCast', 5), ('inputRank', 1)):
            rows = copy.deepcopy(self.rows)
            next(row for row in rows if row['id'] == 'import-legmill-00007')[field] = value
            with self.subTest(field=field), tempfile.TemporaryDirectory() as tmp:
                root = self.snapshot(Path(tmp), rows)
                records, _ = self.build(root, rows)
                self.assertEqual(len(records), 5)
                self.assertNotIn(152505, {record['inputItemID'] for record in records})
        with tempfile.TemporaryDirectory() as tmp:
            root = self.snapshot(Path(tmp))
            loaded = [dict(row, _file=self.source_file) for row in self.rows]
            next(row for row in loaded if row['id'] == 'import-legmill-00007')['_file'] = 'unreviewed-copy.jsonl'
            self.assertEqual(len(priors.preserve_published_priors(loaded, [], Counter(), snapshot=root)), 5)
            loaded = copy.deepcopy(loaded)
            loaded[7]['averageShown'] = 999  # Physical source and loader must agree.
            self.assertEqual(len(priors.preserve_published_priors(loaded, [], Counter(), snapshot=root)), 5)

    def test_actual_archive_hash_is_required_not_merely_migration_metadata(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            snapshot = self.snapshot(root / 'snapshot')
            archive = root / self.groups[0]['archivePath']
            archive.parent.mkdir(parents=True)
            archive.write_bytes((priors.ROOT / self.groups[0]['archivePath']).read_bytes() + b'\n')
            with patch.object(priors, 'ROOT', root):
                records, notes = self.build(snapshot)
            self.assertEqual(records, [])
            self.assertEqual(notes['reviewed per-input prior immutable archive changed'], 6)

    def test_existing_record_is_not_overwritten_and_probability_only_rows_do_not_qualify(self):
        existing = {'recordID': self.groups[0]['recordID'], 'materials': [{'id': 153635, 'expectedQuantity': {'value': 7}}]}
        before = copy.deepcopy(existing)
        with tempfile.TemporaryDirectory() as tmp:
            root = self.snapshot(Path(tmp))
            records = [existing]
            added, _ = self.build(root, records=records)
            self.assertEqual(len(added), 5)
            self.assertEqual(records[0], before)
            probability = {'id': 'not-reviewed-probability', '_file': self.source_file, 'sourceKind': 'reference',
                'method': 'Prospect', 'inputItemID': 2771, 'outputItemID': 1529, 'percentShown': 3.33}
            self.assertEqual(priors.preserve_published_priors([probability], [], Counter(), snapshot=root), [])

    def test_actual_generator_and_review_preserve_reference_status_without_counting_casts(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = self.snapshot(Path(tmp), calculator=True)
            records, _, _, counted, _ = v3.build(root)
            selected = [record for record in records if record.get('reviewedPublishedPrior', {}).get('kind') == 'ARCHIVED_PER_INPUT_TOTALS']
            self.assertEqual(len(selected), 6)
            module = v3.load_calculator(root)
            for row in module.load():
                if row['id'] in {output['sourceRecordID'] for group in self.groups for output in group['outputs']}:
                    self.assertFalse(v3.is_counted(row, module))
            report = review.build_review(root, root / 'no-local')
            by_id = {row['recordID']: row for row in report['rows']}
            for group in self.groups:
                for output in group['outputs']:
                    row = by_id[output['sourceRecordID']]
                    self.assertEqual(row['disposition'], 'ADMITTED_AS_REVIEWED_PUBLISHED_PRIOR')
                    self.assertEqual(row['observedSamplesAdded'], 0)
            self.assertEqual(counted, 9)  # The other nine source rows, not Kidneph.

    def test_actual_snapshot_has_no_counted_alias_of_the_reviewed_archive(self):
        module = v3.load_calculator(v3.DEFAULT_SNAPSHOT)
        rows, _ = v3.retail_admission(module.load())
        archived = [row for row in rows if (row.get('migratedFrom') or {}).get('sha256') == self.groups[0]['archiveSHA256']]
        reviewed = {output['sourceRecordID'] for group in self.groups for output in group['outputs']}
        self.assertEqual({row['id'] for row in archived if row.get('inputItemID') in {g['inputItemID'] for g in self.groups}}, reviewed)
        self.assertTrue(all(not v3.is_counted(row, module) for row in archived if row['id'] in reviewed))
        self.assertFalse(any(v3.is_counted(row, module) and 'kidneph' in str(row.get('studyKey', '')).lower() for row in rows))


if __name__ == '__main__':
    unittest.main()
