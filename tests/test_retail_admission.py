"""Reviewed-cohort quarantine at the Retail import boundary, not URL classification."""
import copy
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, 'tools')
import research_v3_to_baselines as v3

FIXTURE = Path('tests/fixtures/retail-admission')
SNAPSHOT = Path('database/research/v3-snapshot')


def rows(name):
    return [json.loads(line) for line in (FIXTURE / name).read_text().splitlines()]


class AdmissionTests(unittest.TestCase):
    def test_real_rows_cannot_reach_either_estimator_pass(self):
        original = rows('mop-looter.jsonl')
        self.assertEqual(len(original), 16)
        self.assertEqual(len({r['inputItemID'] for r in original}), 5)
        retail = copy.deepcopy(original[0])
        retail.update(id='retail-control', studyKey='independent-retail-control', inputItemID=999001)
        retail['source']['url'] = 'https://www.wowhead.com/item=999001'
        historical = copy.deepcopy(retail)
        historical.update(id='historical-control', studyKey='original-era-control', inputItemID=999002)
        historical['source']['url'] = 'https://www.wowhead.com/mop-classic/item=999002'
        historical['notes'] = 'Original-era historical study mirrored on Classic item page.'
        loaded = original + [retail, historical]
        before = copy.deepcopy(loaded)
        module = v3.load_calculator(SNAPSHOT)
        original_build = module.build
        calls = []
        def checked_build(data):
            calls.append([r['id'] for r in data])
            return original_build(data)
        with patch.object(module, 'load', return_value=loaded), patch.object(module, 'build', side_effect=checked_build), patch.object(v3, 'load_calculator', return_value=module):
            records, notes, total, counted, _ = v3.build(SNAPSHOT)
        self.assertEqual(len(calls), 2)  # published ranges AND counted yields
        for call in calls:
            self.assertEqual(set(call), {'retail-control', 'historical-control'})
        self.assertEqual({r['inputItemID'] for r in records}, {999001, 999002})
        self.assertEqual((total, counted), (18, 2))
        self.assertEqual(sum(notes.values()), 16)
        self.assertEqual(loaded, before)

    def test_renamed_cohort_copy_is_still_quarantined(self):
        row = rows('mop-looter.jsonl')[0]
        row['id'] = 'a-later-transcription'
        admitted, notes = v3.retail_admission([row])
        self.assertEqual(admitted, [])
        self.assertEqual(sum(notes.values()), 1)

    def test_ambiguous_rank_shares_do_not_become_rank_means(self):
        evidence = rows('tww-rank-shares.jsonl')
        module = v3.load_calculator(SNAPSHOT)
        for row in evidence[:3]:
            self.assertIsNone(row['percentShown'])
            self.assertIsNone(row['averageShown'])
            self.assertIsNone(row['castsWithDrop'])
        self.assertEqual(evidence[3]['averageShown'], 2.85)
        self.assertIsNone(evidence[3]['outputItemID'])
        with patch.object(module, 'load', return_value=evidence), patch.object(v3, 'load_calculator', return_value=module):
            records, *_ = v3.build(SNAPSHOT)
        self.assertEqual(records, [])


if __name__ == '__main__':
    unittest.main()
