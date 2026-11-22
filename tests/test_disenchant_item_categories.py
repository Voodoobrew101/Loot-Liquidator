"""Native scope recovery has no authority to invent yields or study versions."""
import copy
import sys
import unittest

sys.path.insert(0, 'tools')
import disenchant_item_categories as categories


def native(item_class=4, rarity=4, level=441, expansion=9):
    return {
        'Item': {207160: {'ClassID': str(item_class), 'SubclassID': '1'}},
        'ItemSparse': {207160: {'Display_lang': 'Inflammable Drapeleaf', 'ExpansionID': str(expansion),
                               'OverallQualityID': str(rarity), 'ItemLevel': str(level), 'Flags_0': '0'}},
        'ItemDisenchantLoot': {
            310: {'ID': '310', 'ExpansionID': str(expansion), 'Quality': str(rarity),
                  'Class': str(item_class), 'Subclass': '-1', 'MinLevel': '1', 'MaxLevel': '999'}}}


class NativeDisenchantCategoryTests(unittest.TestCase):
    def test_actual_dragonflight_epic_armor_identity_not_weapon_fallback(self):
        row = categories.classify(207160, native())
        self.assertEqual((row['expansionID'], row['rarity'], row['classID']), (9, 4, 4))
        self.assertEqual(row['nativeBandIDs'], [310])
        self.assertEqual((row['minItemLevel'], row['maxItemLevel']), (1, 999))
        self.assertNotIn('expectedQuantity', row)
        self.assertNotIn('dropChance', row)

    def test_boundary_overlap_is_intersection_never_arbitrary_native_row(self):
        data = native(level=16, expansion=0)
        data['ItemDisenchantLoot'][310].update(MinLevel='13', MaxLevel='16')
        data['ItemDisenchantLoot'][311] = dict(data['ItemDisenchantLoot'][310], ID='311', MinLevel='16', MaxLevel='18')
        row = categories.classify(207160, data)
        self.assertEqual(row['nativeBandIDs'], [310, 311])
        self.assertEqual((row['minItemLevel'], row['maxItemLevel']), (16, 16))

    def test_missing_and_non_gear_are_not_synthetic_item_exceptions(self):
        self.assertEqual(categories.classify(999, native())['disposition'], 'unmapped')
        self.assertEqual(categories.classify(207160, native(item_class=7))['disposition'], 'non-gear')

    def test_review_requires_source_proof_and_does_not_mutate_native_input(self):
        data = native()
        original = copy.deepcopy(data)
        review = {'schemaVersion': 1, 'items': {'207160': {'disposition': 'archive', 'reason': 'Historical only',
                                                         'sources': ['https://example.com/original']}}, 'records': {}}
        result = categories.generate([207160], data, {}, review)
        self.assertEqual(result['items'][207160]['policy']['disposition'], 'archive')
        self.assertEqual(data, original)
        review['items']['207160']['sources'] = []
        with self.assertRaises(ValueError):
            categories.generate([207160], data, {}, review)

    def test_profession_gear_has_distinct_native_category(self):
        result = categories.generate([207160], native(item_class=19, expansion=10, rarity=2), {})
        self.assertIn('gear:10:2:profession', result['bands'])
        self.assertNotIn('gear:10:2:armor', result['bands'])


if __name__ == '__main__':
    unittest.main()
