import copy
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
        self.assertEqual(len(copper['materials']), 6)
        garnet = next(m for m in copper['materials'] if m['outputName'] == 'Sanguine Garnet')
        self.assertEqual(garnet['expectedQuantity']['value'], .08)
        self.assertEqual(len(garnet['sourceCells']), 2)
        self.assertEqual(len(garnet['rankIDs']), 2)
        self.assertNotIn('value', garnet['dropChance'])
        self.assertNotIn('value', garnet['minQuantity'])
        self.assertNotIn('samples', garnet['expectedQuantity'])
        self.assertTrue(any(r.get('conditional') for r in held))
        self.assertTrue(any(r.get('sourceID') == 'bfa-milling-calculator' for r in held))

    def test_non_retail_cannot_enter_runtime(self):
        import json
        data = json.loads(calc.SOURCE.read_text())
        data['sources'][0]['gameMode'] = 'Classic'
        records, held = calc.build(data)
        self.assertEqual(records, [])
        self.assertTrue(any(r['reason'] == 'Non-Retail source' for r in held))


if __name__ == '__main__':
    unittest.main()
