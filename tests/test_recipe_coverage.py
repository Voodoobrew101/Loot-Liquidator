import copy
import json
from pathlib import Path
import sys
import unittest
sys.path.insert(0, str(Path('tools').resolve()))
from validate_craft_export import compile_baselines, REVIEW_ROOT
from recycling_capture_baselines import compile_capture


class RecipeCoverageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.pages = [json.loads(p.read_text()) for p in sorted(REVIEW_ROOT.glob('export-page-*.json'))]

    def test_original_200_casts_are_restored_without_rewriting_raw_flags(self):
        compiled = compile_baselines(self.pages)
        recycle = [b for b in compiled['baselines'] if b['method'] == 'Recycle']
        self.assertEqual(len(recycle), 14)
        self.assertEqual(sum(b['operations'] for b in recycle), 200)
        total = sum(b['operations'] * b['materials'][0]['expectedQuantity']['value'] for b in recycle)
        self.assertAlmostEqual(total, 421)
        self.assertTrue(self.pages[0]['studies'][recycle[0]['studyID']]['censored'])
        self.assertEqual(len(compiled['excludedCohorts']), 60)
        shipped, _ = compile_capture()
        self.assertEqual(sum(r['observedOperations'] for r in shipped['processing']), 200)
        self.assertTrue(all(r['referenceConditions']['bonusSkill'] == 0 for r in shipped['processing']))
        self.assertEqual(len({op for r in shipped['processing'] for op in r['sourceRecordIDs']}), 200)

    def test_scoped_failure_blocks_its_recipe_only(self):
        pages = copy.deepcopy(self.pages)
        study = next(r['studyID'] for p in pages for r in p['records'] if r['method'] == 'Recycle')
        for p in pages:
            p['studies'][study].update(coverageVersion=2, coverageGaps={'Craft:1229866': {'reason': 'Missing inputs'}})
        def count(): return sum(b['operations'] for b in compile_baselines(pages)['baselines'] if b['method'] == 'Recycle')
        self.assertEqual(count(), 200)
        for p in pages: p['studies'][study]['coverageGaps']['Recycle:999999'] = {'reason': 'Different recipe'}
        self.assertEqual(count(), 200)
        for p in pages: p['studies'][study]['coverageGaps']['Recycle:1229930'] = {'reason': 'Missing result'}
        self.assertEqual(count(), 0)
        for p in pages:
            p['studies'][study]['coverageGaps'] = {'Craft:1229866': {}}
            p['studies'][study]['globalCoverageGap'] = 'Unclosed recording session'
        self.assertEqual(count(), 0)

    def test_legacy_review_does_not_admit_changed_records_or_unknown_gaps(self):
        pages = copy.deepcopy(self.pages)
        record = next(r for p in pages for r in p['records'] if r['method'] == 'Recycle')
        cid = record['contextID']
        for p in pages:
            if cid in p['contexts']: p['contexts'][cid]['baseSkill'] = 99
        admitted = [b for b in compile_baselines(pages)['baselines'] if b['method'] == 'Recycle']
        self.assertLess(sum(b['operations'] for b in admitted), 200)
        pages = copy.deepcopy(self.pages)
        for p in pages: p['studies'][record['studyID']]['coverageReason'] = 'Unclosed recording session'
        self.assertFalse(any(b['method'] == 'Recycle' for b in compile_baselines(pages)['baselines']))

    def test_all_in_one_native_popup_preserves_the_entire_upload(self):
        page = json.loads(Path('/tmp/loot-recycling-200-popup.json').read_text())
        compiled = compile_baselines([page])
        self.assertEqual(len(page['records']), 301)
        self.assertEqual(sum(b['operations'] for b in compiled['baselines'] if b['method'] == 'Recycle'), 200)


if __name__ == '__main__': unittest.main()
