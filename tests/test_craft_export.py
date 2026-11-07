import copy
import importlib.util
import json
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('export_validator', 'tools/validate_craft_export.py')
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


class CraftExportTests(unittest.TestCase):
    def setUp(self):
        self.page = json.loads(Path('/tmp/loot-craft-export.json').read_text())

    def test_recycling_pilot_receipts_copy_and_stage_with_exact_contexts(self):
        raw = json.loads(Path('/tmp/loot-recycling-capture-v3.json').read_text())
        copied = json.loads(Path('/tmp/loot-recycling-popup.json').read_text())
        self.assertEqual(copied, raw)
        records, contexts, studies = validator.validate([copied])
        self.assertEqual(len(records), 20)
        self.assertTrue(all(r['method'] == 'Recycle' and r['nominalInputs'][0]['quantity'] == 5 for r in records))
        self.assertEqual(sum(r['outputs'][0]['quantity'] for r in records), 44)
        staged = validator.compile_baselines([copied])
        self.assertEqual(staged['excludedCohorts'], [])
        self.assertEqual(sum(b['operations'] for b in staged['baselines']), 20)
        self.assertEqual(len(staged['baselines']), len({c['baseSkill'] for c in contexts.values()}))
        self.assertFalse(staged['automaticMechanicsPromotion'])

    def test_recycling_reconciliation_rejects_missing_cast_and_fabricated_counts(self):
        original = json.loads(Path('/tmp/loot-recycling-popup.json').read_text())
        for mutate, message in [
            (lambda p: p['records'][0]['outputs'][0].update(quantity=99), 'receipts and outputs'),
            (lambda p: p['records'][0]['resultMetadata'][0].update(quantity=99), 'receipts and outputs'),
            (lambda p: p['records'][0]['bagReconciliation']['outputs'][0].update(quantity=99), 'Conflicting'),
        ]:
            page = copy.deepcopy(original)
            mutate(page)
            with self.assertRaisesRegex(ValueError, message): validator.validate([page])
        page = copy.deepcopy(original)
        page['records'].pop()
        page['retainedRecords'] -= 1
        with self.assertRaisesRegex(ValueError, 'Missing Recycling reconciliation casts'):
            validator.validate([page])

    def test_actual_disenchant_capture_copied_from_native_popup_validates(self):
        raw = json.loads(Path('/tmp/loot-disenchant-capture-v2.json').read_text())
        copied = json.loads(Path('/tmp/loot-disenchant-popup.json').read_text())
        self.assertEqual(copied, raw)
        records, contexts, studies = validator.validate([copied])
        self.assertEqual(len(records), 5)
        self.assertEqual(records[0]['captureVersion'], 2)
        self.assertEqual(records[0]['lootSlots'][0]['itemID'], 109693)
        self.assertEqual(records[2]['inputs'][0]['itemLevel'], 280)
        staged = validator.compile_baselines([copied])
        self.assertEqual(len(staged['baselines']), 5)
        self.assertEqual(staged['excludedCohorts'], [])

    def test_confirmed_zero_is_in_denominator_and_histogram(self):
        staged = validator.compile_baselines([self.page])
        self.assertEqual(len(staged['baselines']), 1)
        b = staged['baselines'][0]
        m = b['materials'][0]
        self.assertEqual(b['operations'], 2)
        self.assertEqual(m['expectedQuantity']['value'], 1)
        self.assertEqual(m['dropChance']['value'], .5)
        self.assertEqual(m['yieldMin']['value'], 2)
        self.assertEqual(m['yieldMax']['value'], 2)
        self.assertEqual(m['quantityHistogramIncludingZero'], {'0': 1, '2': 1})
        self.assertEqual(m['outputQualityRank'], 1)
        self.assertEqual(m['outputRarity'], 2)
        self.assertIsNone(m['expectedQuantity']['confidence'])
        self.assertFalse(staged['automaticMechanicsPromotion'])
        self.assertEqual(staged['mechanicRules'], [])

    def test_empty_outputs_are_json_arrays(self):
        self.assertEqual(self.page['records'][1]['outputs'], [])
        self.page['records'][1]['outputs'] = {}
        with self.assertRaisesRegex(ValueError, 'vectors'):
            validator.validate([self.page])

    def test_zero_requires_confirmation(self):
        del self.page['records'][1]['zeroEvidence']
        with self.assertRaisesRegex(ValueError, 'Empty outputs'):
            validator.validate([self.page])

    def test_unresolved_samples_block_the_cohort(self):
        self.page['records'][1]['outputCoverage'] = 'unresolved'
        compiled = validator.compile_baselines([self.page])
        self.assertEqual(compiled['baselines'], [])
        self.assertEqual(len(compiled['excludedCohorts']), 1)

    def test_censored_and_truncated_studies_stay_research_only(self):
        study_id = self.page['records'][0]['studyID']
        for field in ('censored', 'truncated'):
            page = copy.deepcopy(self.page)
            page['studies'][study_id][field] = True
            self.assertEqual(validator.compile_baselines([page])['baselines'], [])

    def test_missing_pages_do_not_create_positive_only_baselines(self):
        self.page['pages'] = 2
        with self.assertRaisesRegex(ValueError, 'All pages'):
            validator.validate([self.page])

    def test_duplicate_operation_is_rejected(self):
        self.page['records'][1]['operationID'] = self.page['records'][0]['operationID']
        with self.assertRaisesRegex(ValueError, 'Duplicate'):
            validator.validate([self.page])

    def test_manual_simulations_do_not_enter_measured_baselines(self):
        next(iter(self.page['contexts'].values()))['simulated'] = True
        with self.assertRaisesRegex(ValueError, 'simulation'):
            validator.validate([self.page])

    def test_context_recipe_cannot_be_substituted(self):
        next(iter(self.page['contexts'].values()))['recipeID'] = 999999
        with self.assertRaisesRegex(ValueError, 'recipe/method'):
            validator.validate([self.page])

    def test_build_and_character_cannot_be_substituted(self):
        for field in ('character', 'build'):
            page = copy.deepcopy(self.page)
            page['records'][0][field] = 'different'
            with self.assertRaisesRegex(ValueError, 'identity'):
                validator.validate([page])

    def test_nonfinite_measurements_rejected(self):
        next(iter(self.page['contexts'].values()))['effectiveSkill'] = float('nan')
        with self.assertRaisesRegex(ValueError, 'Nonfinite'):
            validator.validate([self.page])

    def test_capture_and_registry_approval_stay_separate(self):
        self.page['records'][0]['provenance']['numericTransformValidated'] = True
        with self.assertRaisesRegex(ValueError, 'unsafe mechanics'):
            validator.validate([self.page])

    def test_real_refunds_preserve_nominal_batch(self):
        page = json.loads(Path('/tmp/loot-craft-refund-export.json').read_text())
        staged = validator.compile_baselines([page])
        baseline = next(b for b in staged['baselines'] if b['recipeSpellID'] == 1000)
        self.assertEqual(baseline['nominalInputs'][0]['quantity'], 2)
        self.assertEqual(baseline['expectedInputsConsumed'][0]['expectedQuantity'], 1)
        self.assertEqual(baseline['materials'][0]['expectedQuantity']['value'], 3)
        record = next(r for r in page['records'] if r['recipeID'] == 1000)
        record['inputs'][0]['quantity'] = 0
        with self.assertRaisesRegex(ValueError, 'refunds disagree'):
            validator.validate([page])


if __name__ == '__main__':
    unittest.main()
