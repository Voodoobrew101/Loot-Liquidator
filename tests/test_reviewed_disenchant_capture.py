"""Exact retained capture admission, not a waiver for censored exports."""
import copy
import hashlib
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, 'tools')
import reviewed_disenchant_capture as capture
from validate_craft_export import compile_baselines, unpack_transfer


class ReviewedCaptureTests(unittest.TestCase):
    def setUp(self):
        self.source = capture.ROOT / capture.RELATIVE

    def changed_review(self, change):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        folder = Path(temporary.name)
        shutil.copyfile(self.source / 'source-transfer.json', folder / 'source-transfer.json')
        review = json.loads((self.source / 'coverage-review.json').read_text(encoding='utf-8'))
        change(review)
        (folder / 'coverage-review.json').write_text(json.dumps(review), encoding='utf-8')
        return folder

    def test_exact_counts_profiles_histograms_and_no_source_mutation(self):
        paths = [self.source / name for name in ('source-transfer.json', 'coverage-review.json')]
        before = [path.read_bytes() for path in paths]
        review, cohorts, _ = capture.reviewed_counts()
        records = capture.compile_records()
        self.assertEqual(sum(group['operations'] for group, _ in cohorts), 93)
        self.assertEqual(len(review['heldOperationIDs']), 26)
        self.assertEqual(len({op for group, _ in cohorts for op in group['operationIDs']}), 93)
        self.assertEqual({r['gearKey']: r['observedOperations'] for r in records},
                         {'gear:9:4:armor': 66, 'gear:9:4:weapon': 17,
                          'gear:11:4:armor': 9, 'gear:11:4:weapon': 1})
        for record in records:
            group, counts = next((g, c) for g, c in cohorts if g['category'] == record['gearKey'])
            n = group['operations']
            self.assertEqual(record['baselineProfile'], group['baselineProfile'])
            self.assertNotIn('minimumSkill', record)
            self.assertNotIn('inputItemID', record)
            self.assertEqual(record['categorySourceStudyIDs'], [review['studyID']])
            self.assertTrue(record['studyCoverageCensored'])
            self.assertEqual(record['categoryItemLevelMin'], 1)
            self.assertEqual(record['categoryItemLevelMax'], 999)
            for material in record['materials']:
                count = counts[material['id']]
                self.assertAlmostEqual(material['expectedQuantity']['value'], count['units'] / n, places=6)
                self.assertAlmostEqual(material['dropChance']['value'], count['hits'] / n, places=6)
                self.assertEqual(sum(count['histogram'].values()), n)
                self.assertEqual(sum(int(q) * count for q, count in count['histogram'].items()), count['units'])
                self.assertEqual(material['quantityCounts'], count['histogram'])
                self.assertEqual(material['minQuantity']['value'], count['min'])
                self.assertEqual(material['maxQuantity']['value'], count['max'])
            # Existing non-minimum evidence support weighting is preserved.
            self.assertEqual(record['samples'], n / 2)
        payload = json.dumps(records, sort_keys=True)
        provenance = json.dumps([record['sourceRecordIDs'] for record in records])
        self.assertLess(len(provenance.encode('utf-8')), 10000)
        self.assertEqual({op for record in records for op in record['sourceRecordIDs']},
                         {op for group, _ in cohorts for op in group['operationIDs']})
        for record in records:
            self.assertEqual(len(record['sourceRecordIDs']), record['observedOperations'])
            self.assertTrue(record['fixedReference'])
            self.assertFalse(record['categoryReferenceOnly'])
            self.assertEqual(record['retainedSourceProfileKey'],
                             f"effective:{record['baselineProfile']['effectiveSkill']:g};specialization:none;buffs:")
            without_ids = dict(record, sourceRecordIDs=[])
            self.assertNotIn('Cast-', json.dumps(without_ids))
        self.assertNotIn('equipment', payload)
        self.assertNotIn('character', payload)
        self.assertNotIn('267655', payload)
        self.assertEqual([path.read_bytes() for path in paths], before)

    def test_general_export_coverage_is_still_strict(self):
        wire = json.loads((self.source / 'source-transfer.json').read_text(encoding='utf-8'))
        staged = compile_baselines([unpack_transfer(wire)])
        self.assertEqual(staged['baselines'], [])
        self.assertEqual(len(staged['excludedCohorts']), 104)
        self.assertEqual({r['reason'] for r in staged['excludedCohorts']},
                         {'Recipe capture has unresolved coverage gaps'})
        self.assertFalse(list(self.source.glob('cast-page-*')))

    def test_wire_hash_drift_fails_closed(self):
        folder = self.changed_review(lambda review: None)
        path = folder / 'source-transfer.json'
        path.write_bytes(path.read_bytes() + b' ')
        with self.assertRaisesRegex(ValueError, 'checksum'):
            capture.compile_records(folder)

    def test_duplicate_operation_cannot_add_denominator_weight(self):
        folder = self.changed_review(lambda r: r['groups'][0]['operationIDs'].__setitem__(
            1, r['groups'][0]['operationIDs'][0]))
        with self.assertRaisesRegex(ValueError, 'Duplicate'):
            capture.compile_records(folder)

    def test_wrong_measured_profile_cannot_become_another_source(self):
        folder = self.changed_review(lambda r: r['groups'][0]['baselineProfile'].__setitem__('effectiveSkill', 0))
        with self.assertRaisesRegex(ValueError, 'profile'):
            capture.compile_records(folder)
        folder = self.changed_review(lambda r: r['groups'][0].__setitem__(
            'profileKey', 'effective:0;specialization:none;buffs:'))
        with self.assertRaisesRegex(ValueError, 'profile key'):
            capture.compile_records(folder)

    def test_held_partition_and_native_band_cannot_expand(self):
        folder = self.changed_review(lambda r: r['heldOperationIDs'].pop())
        with self.assertRaisesRegex(ValueError, 'partition'):
            capture.compile_records(folder)
        folder = self.changed_review(lambda r: r['groups'][0].__setitem__('nativeBand', [1, 9999, [331]]))
        with self.assertRaisesRegex(ValueError, 'band'):
            capture.compile_records(folder)


if __name__ == '__main__':
    unittest.main()
