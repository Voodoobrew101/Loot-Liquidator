import copy
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path('tools').resolve()))
from recycling_capture_baselines import compile_capture, zero_profile_prior
from validate_craft_export import REVIEW_ROOT
import json


class RecyclingZeroPriorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.compiled, cls.staged = compile_capture()

    def test_source_observations_and_target_model_are_separate(self):
        raw = self.compiled['processing']
        self.assertEqual(len(raw), 14)
        self.assertEqual(sum(r['observedOperations'] for r in raw), 200)
        self.assertTrue(all(r['targetBuild'] == '70783' for r in raw))
        prior, = self.compiled['modeledBaselines']
        self.assertEqual(prior['studyID'], raw[0]['studyID'])
        self.assertEqual(prior['samples'], 0)
        self.assertEqual(prior['observedOperations'], 0)
        self.assertEqual(prior['observedSourceOperations'], 200)
        self.assertEqual(len(set(prior['sourceRecordIDs'])), 200)
        self.assertEqual(len(prior['sourceContextIDs']), 14)
        self.assertEqual(sum(prior['sourceHistogram'].values()), 200)
        self.assertEqual(prior['sourceUnits'], 421)
        self.assertEqual(prior['baselineProfile']['skill'], 0)
        self.assertTrue(prior['baselineProfileAssumed'])
        self.assertEqual(prior['currentPatchApplicabilityConfidence'], 0)
        self.assertNotIn('targetBuild', prior)
        self.assertEqual(prior['nativeBinding']['rankItemIDs'], [243581, 243582])
        low, high = prior['materials']
        self.assertEqual(low['expectedQuantity']['value'], 2.105)
        self.assertEqual(high['expectedQuantity']['value'], 0)
        for material in prior['materials']:
            mean = material['expectedQuantity']
            self.assertEqual(mean['status'], 'modeled')
            self.assertEqual(mean['samples'], 0)
            self.assertEqual(mean['confidence'], 0)
            self.assertNotIn('quantityCounts', material)
            for field in ('dropChance', 'minQuantity', 'maxQuantity'):
                self.assertNotIn('value', material[field])
                self.assertTrue(material[field]['inferenceBlocked'])

    def test_overlapping_contexts_cannot_inflate_source_counts(self):
        cohorts = copy.deepcopy([b for b in self.staged['baselines'] if b['method'] == 'Recycle'])
        cohorts[1]['sourceRecordIDs'][0] = cohorts[0]['sourceRecordIDs'][0]
        review = json.loads((REVIEW_ROOT / 'coverage-review.json').read_text())
        with self.assertRaisesRegex(AssertionError, 'Overlapping'):
            zero_profile_prior(cohorts, review)


if __name__ == '__main__':
    unittest.main()
