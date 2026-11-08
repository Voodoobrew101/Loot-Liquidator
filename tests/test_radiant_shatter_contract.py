"""Check the real Lua recorder export at the Python research-import boundary."""
import copy
import importlib.util
import json
import os
from pathlib import Path
import unittest


spec = importlib.util.spec_from_file_location('shatter_export_validator', 'tools/validate_craft_export.py')
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)
EXPORT = Path(os.environ.get('LOOT_RADIANT_SHATTER_EXPORT', '/tmp/loot-radiant-shatter-capture-v3.json'))


class RadiantShatterContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Produced by test_radiant_shatter.lua through the actual recorder/export
        # functions, replaying fifty owner-supplied native result packets.
        cls.export = json.loads(EXPORT.read_text())

    def fresh(self):
        return copy.deepcopy(self.export)

    def rejected(self, page, reason):
        with self.assertRaisesRegex(ValueError, reason):
            validator.compile_baselines([page])

    def test_fifty_native_results_compile_without_inventing_extra_casts(self):
        original = self.fresh()
        records, _, _ = validator.validate([self.export])
        self.assertEqual(len(records), 50)
        self.assertTrue(all(r['method'] == 'Craft' and r['recipeID'] == 1280394 for r in records))
        self.assertEqual(len({r['resultMetadata'][0]['operationID'] for r in records}), 50)
        self.assertEqual(sum(r['inputs'][0]['quantity'] for r in records), 50)
        self.assertEqual(sum(r['outputs'][0]['quantity'] for r in records), 150)
        compiled = validator.compile_baselines([self.export])
        self.assertFalse(compiled['excludedCohorts'])
        self.assertEqual(sum(b['operations'] for b in compiled['baselines']), 50)
        self.assertEqual({op for b in compiled['baselines'] for op in b['sourceRecordIDs']},
                         {r['operationID'] for r in records})
        for baseline in compiled['baselines']:
            self.assertEqual(baseline['nominalInputs'][0]['quantity'], 1)
            self.assertEqual(baseline['expectedInputsConsumed'][0]['expectedQuantity'], 1)
            dust = next(m for m in baseline['materials'] if m['outputItemID'] == 243599)
            self.assertEqual(dust['expectedQuantity']['value'], 3)
            self.assertEqual(dust['quantityHistogramIncludingZero'], {'3': baseline['operations']})
            self.assertFalse(baseline['numericTransformValidated'])
            self.assertIn('INDEPENDENT_REVIEW_PENDING', baseline['blockers'])
        self.assertFalse(compiled['automaticMechanicsPromotion'])
        self.assertFalse(compiled['mechanicRules'])
        self.assertEqual(self.export, original, 'Import must not rewrite the captured evidence')

    def test_unknown_craft_cannot_borrow_shatter_reconciliation(self):
        page = self.fresh()
        for record in page['records']:
            record['recipeID'] = 987654
        for context in page['contexts'].values():
            context['recipeID'] = 987654
        self.rejected(page, 'Unsupported batch reconciliation operation')

    def test_method_and_recipe_must_be_an_explicit_supported_pair(self):
        for method, recipe in [('Recycle', 1280394), ('Craft', 1229930)]:
            with self.subTest(method=method, recipe=recipe):
                page = self.fresh()
                for record in page['records']:
                    record.update(method=method, recipeID=recipe)
                for context in page['contexts'].values():
                    context.update(method=method, recipeID=recipe)
                self.rejected(page, 'Unsupported batch reconciliation operation')

    def test_shatter_cannot_claim_the_five_input_recycling_batch(self):
        page = self.fresh()
        for record in page['records']:
            record['inputs'][0]['quantity'] = 5
            record['nominalInputs'][0]['quantity'] = 5
            record['salvageTarget']['quantity'] = 5
            record['bagReconciliation']['inputs'][0]['quantity'] = 250
        self.rejected(page, 'Invalid nominal salvage batch')

    def test_missing_member_cannot_be_normalized_into_a_smaller_sample(self):
        page = self.fresh()
        page['records'].pop(17)
        page['retainedRecords'] -= 1
        self.rejected(page, 'Missing salvage reconciliation casts')

    def test_another_supported_recipe_cannot_complete_a_shatter_batch(self):
        page = self.fresh()
        changed = page['records'][-1]
        other_context = copy.deepcopy(page['contexts'][changed['contextID']])
        other_context.update(method='Recycle', recipeID=1229930)
        page['contexts']['different-recipe'] = other_context
        changed.update(method='Recycle', recipeID=1229930, contextID='different-recipe')
        # Both method/recipe pairs are supported and both records have a valid
        # nominal batch size. They must still reconcile as separate operations,
        # even if the untrusted import supplies the same reconciliation ID.
        changed['inputs'][0].update(itemID=245807, quantity=5)
        changed['nominalInputs'][0].update(itemID=245807, quantity=5)
        changed['salvageTarget'].update(itemID=245807, quantity=5)
        self.rejected(page, 'Missing salvage reconciliation casts')

    def test_receipts_and_shared_inventory_totals_must_agree(self):
        page = self.fresh()
        for record in page['records']:
            record['bagReconciliation']['outputs'][0]['quantity'] = 153
        self.rejected(page, 'batch inventory totals disagree')
        page = self.fresh()
        page['records'][0]['resultMetadata'][0]['quantity'] = 4
        self.rejected(page, 'receipts and outputs disagree')
        page = self.fresh()
        page['records'][0]['resultMetadata'] = []
        self.rejected(page, 'Missing salvage result receipts')

    def test_reported_refund_changes_consumption_but_not_dust_quantity(self):
        # One explicit whole-shard refund in an otherwise unchanged replay.
        # Merely observing zero net consumption, without that receipt, is not
        # sufficient evidence of a refund (covered by the negative case below).
        page = self.fresh()
        record = page['records'][0]
        record['inputs'][0]['quantity'] = 0
        record['resultMetadata'][0]['resourcesReturned'] = [
            {'reagent': {'itemID': 243602}, 'quantity': 1}]
        for member in page['records']:
            member['bagReconciliation']['inputs'][0]['quantity'] = 49
        compiled = validator.compile_baselines([page])
        self.assertFalse(compiled['excludedCohorts'])
        self.assertEqual(sum(b['operations'] for b in compiled['baselines']), 50)
        self.assertAlmostEqual(sum(b['operations'] * b['expectedInputsConsumed'][0]['expectedQuantity']
                                   for b in compiled['baselines']), 49)
        self.assertEqual(sum(b['operations'] * b['materials'][0]['expectedQuantity']['value']
                             for b in compiled['baselines']), 150)

    def test_unreported_or_contradictory_refunds_cannot_make_free_materials(self):
        page = self.fresh()
        page['records'][0]['inputs'][0]['quantity'] = 0
        self.rejected(page, 'Nominal consumption/net inputs/refunds disagree')
        page = self.fresh()
        page['records'][0]['resultMetadata'][0]['resourcesReturned'] = [
            {'reagent': {'itemID': 243602}, 'quantity': 1}]
        self.rejected(page, 'Nominal consumption/net inputs/refunds disagree')

    def test_native_target_identity_and_eligibility_cannot_be_substituted(self):
        changes = [
            {'itemGUID': 'Item-another-target'},
            {'itemGUID': ''},
            {'itemID': 243603},
            {'eligibilitySource': 'inferred-from-bags'},
        ]
        for change in changes:
            with self.subTest(change=change):
                page = self.fresh()
                page['records'][0]['salvageTarget'].update(change)
                self.rejected(page, 'Missing verified salvage target')

    def test_replayed_result_or_cast_identity_is_not_an_extra_operation(self):
        page = self.fresh()
        page['records'][1]['resultMetadata'][0]['operationID'] = page['records'][0]['resultMetadata'][0]['operationID']
        self.rejected(page, 'Duplicate salvage result operation')
        page = self.fresh()
        page['records'][1]['operationID'] = page['records'][0]['operationID']
        self.rejected(page, 'Duplicate or missing operation ID')


if __name__ == '__main__':
    unittest.main()
