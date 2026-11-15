import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import att_legacy_omni as omni


class LegacyOmniTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        records, held = omni.build_legacy_omni()
        cls.ids = {record['tokenID']: record for record in records}
        if len(cls.ids) != len(records) or held:
            raise AssertionError('Legacy omni sources must be unique and covered')

    def test_forlorn_uses_one_essence_and_preserves_optional_vendor_costs(self):
        essence = self.ids[66998]
        self.assertEqual(len(essence['rewards']), 15)
        self.assertEqual(essence['costs']['67423'], [omni.item_cost(66998)])
        slot = self.ids[67423]
        self.assertEqual(slot['kind'], 'open')
        self.assertEqual(slot['rewardSources']['65214'], 32775)
        self.assertEqual(slot['vendorCosts']['65214'], [omni.item_cost(60344), omni.item_cost(67423)])
        self.assertNotIn('costs', slot)

    def test_cursed_keeps_five_choices_per_essence_and_existing_slots(self):
        essences = [self.ids[token] for token in range(105857, 105869)]
        self.assertTrue(all(essence['kind'] == 'exchange' and len(essence['rewards']) == 5
                            for essence in essences))
        self.assertEqual(essences[1]['rewards'], [99686, 99687, 99688, 99689, 99690])
        slots = {slot for essence in essences for slot in essence['rewards']}
        self.assertEqual(len(slots), 60)
        self.assertEqual(slots - self.ids.keys(), {99713, 99723, 99725})
        self.assertTrue(self.ids[99688]['rewardRequirements']['99118']['unverified'])

    def test_iron_keeps_faction_and_difficulty_specific_sources(self):
        horde, alliance = self.ids[120209], self.ids[120283]
        self.assertEqual(horde['rewards'], alliance['rewards'])
        self.assertEqual(horde['rewards'], [120242, 120243, 120244, 120245, 120246])
        self.assertEqual(horde['rewardRequirements']['120245']['faction'], 'Horde')
        self.assertEqual(alliance['rewardRequirements']['120245']['faction'], 'Alliance')
        self.assertFalse(horde['costsComplete'])
        self.assertFalse(alliance['costsComplete'])
        self.assertEqual(self.ids[120215]['rewardSources']['115568'], 64458)
        self.assertEqual(self.ids[120230]['rewardSources']['115568'], 67303)
        self.assertEqual(self.ids[120245]['rewardSources']['115568'], 67304)
        self.assertEqual(len(self.ids), 148)

    def test_changed_literal_cost_refuses_import(self):
        data = json.loads(omni.SOURCE.read_text(encoding='utf-8'))
        family = data['families']['forlorn']
        row = family['offers'][0]
        row['lua'] = row['lua'].replace('66998,1', '66998,2')
        with self.assertRaisesRegex(ValueError, 'Unsupported legacy token source'):
            omni.vendor_family(data, family, omni.FORLORN, 15, 15)


if __name__ == '__main__':
    unittest.main()
