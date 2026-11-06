"""Reported units enter the native evidence pipeline once, with their own scope."""
import copy
import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, 'tools')
import import_midnight_enchanting as importer
import evidence_check


class MidnightEnchantingImportTests(unittest.TestCase):
    def setUp(self):
        self.review = json.loads(importer.SOURCE.read_text())
        self.existing = importer.snapshot_lineages()

    def test_counted_units_do_not_turn_into_probabilities_or_ranges(self):
        records, skipped = importer.build(self.review, self.existing)
        self.assertEqual(len(records), 1)
        record = records[0]
        self.assertEqual(record['casts'], 1000)
        self.assertEqual(len(record['outputs']), 7)
        by_id = {out['item']: out for out in record['outputs']}
        self.assertEqual(by_id[243602]['totalQuantity'], 629)
        self.assertEqual(by_id[243603]['totalQuantity'], 660)
        for out in record['outputs']:
            self.assertFalse(set(out) & {'chance', 'castsWithDrop', 'min', 'max', 'averageQuantity'})
        self.assertEqual(evidence_check.check_evidence(record), [])
        self.assertEqual(sum('Already present' in reason for _, reason in skipped), 23)

    def test_upgraded_epic_variant_cannot_acquire_rare_study_scope(self):
        records, _ = importer.build(self.review, self.existing)
        self.assertEqual(records[0]['input'], 239671)
        self.assertEqual(records[0]['inputRarity'], 3)
        self.assertEqual(records[0]['inputClassID'], 4)
        self.assertEqual(records[0]['recipeID'], 13262)
        self.assertEqual(records[0]['expansionID'], 11)

    def test_same_cumulative_studies_are_not_imported_twice(self):
        existing = self.existing | set(importer.REVIEWED_SCOPES)
        records, _ = importer.build(self.review, existing)
        self.assertEqual(records, [])

    def test_unknown_denominators_and_fractional_units_fail_closed(self):
        for key, value in [('completedCastsReported', None), ('completedCastsReported', True)]:
            review = copy.deepcopy(self.review)
            review['cohorts'][0][key] = value
            with self.assertRaises(ValueError):
                importer.build(review, self.existing)
        review = copy.deepcopy(self.review)
        review['cohorts'][0]['outputs'][0]['totalUnitsReported'] = 1.5
        with self.assertRaises(ValueError):
            importer.build(review, self.existing)

    def test_generated_native_evidence_is_current(self):
        records, _ = importer.build(self.review, self.existing)
        self.assertEqual(json.loads(importer.OUTPUT.read_text()), records)


if __name__ == '__main__':
    unittest.main()
