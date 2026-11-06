import copy
import json
import sys
import unittest

sys.path.insert(0, 'tools')
import reference_calculators as calc


class CalculatorTests(unittest.TestCase):
    def test_formula_constant_is_independent_of_cached_zeros_and_saved_stats(self):
        self.assertEqual(calc.constant('=SUM(((((Materials!E2*0.3)/100)*G2)/5)+(G2/5)*0.08)'), .08)
        self.assertEqual(calc.constant('=SUM(((((Materials!E2*0.3)/100)*G12)/5)+(G12/5)*1.14)'), 1.14)
        with self.assertRaises(ValueError):
            calc.constant('=SUM((G2/20)*0.08)')

    def test_quality_sections_are_alternatives_and_unlocks_stay_held(self):
        records, held = calc.build()
        copper = next(r for r in records if r['inputItemID'] == 237359)
        self.assertEqual(len(copper['materials']), 7)
        garnet = next(m for m in copper['materials'] if m['outputName'] == 'Sanguine Garnet')
        self.assertEqual(garnet['expectedQuantity']['value'], .08)
        self.assertEqual(len(garnet['sourceCells']), 2)
        self.assertEqual(len(garnet['rankIDs']), 2)
        self.assertNotIn('value', garnet['dropChance'])
        self.assertNotIn('value', garnet['minQuantity'])
        self.assertNotIn('samples', garnet['expectedQuantity'])
        self.assertTrue(any(r.get('conditional') for r in held))
        diamond = next(m for m in copper['materials'] if m['outputName']=='Eversong Diamond')
        self.assertTrue(diamond['conditionalReference'])
        self.assertEqual(diamond['expectedQuantity']['value'], .025)
        self.assertTrue(any(r.get('sourceID') == 'bfa-milling-calculator' for r in held))

    def test_non_retail_cannot_enter_runtime(self):
        data = json.loads(calc.SOURCE.read_text())
        for source in data['sources']:
            source['gameMode'] = 'Classic'
        records, held = calc.build(data)
        self.assertEqual(records, [])
        self.assertTrue(any(r['reason'] == 'Non-Retail source' for r in held))

    def milling_fixture(self):
        data = json.loads(calc.SOURCE.read_text())
        source = next(s for s in data['sources'] if s.get('formulaMode') == calc.DIRECT_MODE)
        archive = json.loads(calc.archive_path(source).read_text())
        return data, source, {source['archive']: archive}

    def test_milling_family_total_exact_scope_and_unknown_probability(self):
        records, _ = calc.build()
        milling = [r for r in records if r['method'] == 'Mill']
        expected = {
            236761: (1, [245807, 245808]), 236767: (2, [245807, 245808]),
            236776: (1, [245803, 245804]), 236777: (2, [245803, 245804]),
            236770: (1, [245865, 245864]), 236771: (2, [245865, 245864]),
            236778: (1, [245867, 245866]), 236779: (2, [245867, 245866]),
        }
        self.assertEqual(len(milling), 8)
        self.assertEqual({r['inputItemID'] for r in milling}, set(expected))
        for record in milling:
            rank, family = expected[record['inputItemID']]
            self.assertEqual((record['recipeID'], record['expansionID'], record['inputCount']), (1269575, 11, 10))
            self.assertEqual(record['profession'], 'Inscription')
            self.assertEqual(record['inputQualityRank'], rank)
            self.assertEqual(record['sourceKey'], 'reference')
            self.assertTrue(record['fallbackOnly'])
            self.assertTrue(record['fixedReference'])
            self.assertFalse(record['realStudy'])
            self.assertEqual(len(record['materials']), 1)
            material = record['materials'][0]
            self.assertEqual(material['rankIDs'], family)
            self.assertEqual(material['id'], family[0])
            self.assertEqual(material['expectedQuantity']['value'], 13)
            self.assertEqual(material['expectedQuantity']['confidence'], 10)
            self.assertFalse(material['realStudy'])
            for key in ('dropChance', 'minQuantity', 'maxQuantity'):
                self.assertEqual(material[key], {'status': 'unknown', 'confidence': 0})
            for container in (record, material, material['expectedQuantity']):
                for key in ('samples', 'casts', 'histogram', 'quantityCounts', 'expectedInputCount'):
                    self.assertNotIn(key, container)
            self.assertEqual(record['sourceQuantityField'], 'baseYieldPerCraft')
            self.assertIn('before Resourcefulness', record['baselineStatus'])
            self.assertNotIn('outputQualityMode', record)

    def test_milling_value_is_derived_from_checked_source_field(self):
        data, source, archives = self.milling_fixture()
        archive = archives[source['archive']]
        archive['sourceExcerpt'] = archive['sourceExcerpt'].replace(
            'baseYieldPerCraft = 13.000000,', 'baseYieldPerCraft = 11.000000,', 1).replace(
            'baseYield = 1.300000,', 'baseYield = 1.100000,', 1)
        before = copy.deepcopy(archives)
        records, _ = calc.build(data, archives=archives)
        powder = [r for r in records if r['inputItemID'] in (236761, 236767)]
        self.assertEqual([r['materials'][0]['expectedQuantity']['value'] for r in powder], [11, 11])
        self.assertEqual(archives, before)

    def test_workbook_planning_totals_and_saved_stats_do_not_become_casts_or_bonuses(self):
        data, source, archives = self.milling_fixture()
        baseline, _ = calc.build(data, archives=archives)
        archive = archives[source['archive']]
        archive['sourceExcerpt'] = archive['sourceExcerpt'].replace(
            'defaultCrafts = 351.500000,', 'defaultCrafts = 999999.500000,').replace(
            'workbookExpectedQty = 5313.155860,', 'workbookExpectedQty = 999999999.000000,')
        altered, _ = calc.build(data, archives=archives)
        self.assertEqual(baseline, altered)
        self.assertEqual(len([r for r in altered if r['method'] == 'Prospect']), 7)

    def test_direct_source_requires_reviewed_units_and_recipe(self):
        for original, replacement in (
                ('recipeID = 1269575,', 'recipeID = 1269576,'),
                ('qtyPerCraft = 10.000000,', 'qtyPerCraft = 5.000000,'),
                ('baseYieldPerCraft = 13.000000,', 'baseYieldPerCraft = 13 * 2,')):
            data, source, archives = self.milling_fixture()
            archive = archives[source['archive']]
            archive['sourceExcerpt'] = archive['sourceExcerpt'].replace(original, replacement, 1)
            with self.assertRaises(ValueError):
                calc.build(data, archives=archives)
        data, source, archives = self.milling_fixture()
        archives[source['archive']]['realStudy'] = True
        with self.assertRaises(ValueError):
            calc.build(data, archives=archives)

    def test_duplicate_families_and_unsourced_rank_order_fail_closed(self):
        data, source, archives = self.milling_fixture()
        source['groups'].append(copy.deepcopy(source['groups'][0]))
        with self.assertRaises(ValueError):
            calc.build(data, archives=archives)
        data, source, archives = self.milling_fixture()
        data['outputIdentities']['Mana Lily Pigment'].pop('verifiedRanks')
        with self.assertRaises(ValueError):
            calc.build(data, archives=archives)

    def test_legacy_prospecting_records_unchanged_by_direct_source(self):
        data = json.loads(calc.SOURCE.read_text())
        complete, held = calc.build(data)
        data['sources'] = [s for s in data['sources'] if s.get('formulaMode') != calc.DIRECT_MODE]
        legacy, legacy_held = calc.build(data)
        self.assertEqual([r for r in complete if r['method'] == 'Prospect'], legacy)
        self.assertEqual(held, legacy_held)


if __name__ == '__main__':
    unittest.main()
