import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, 'tools')
from att_modern_gear import build_modern_gear, SOURCE


class ModernGearTokens(unittest.TestCase):
    def test_void_touched_family_has_slot_pools_and_safe_unverified_economics(self):
        records, _ = build_modern_gear()
        by_id = {row['tokenID']: row for row in records}
        pool = by_id[281429]
        self.assertEqual(len(pool['rewards']), 160)
        self.assertEqual(len(pool['rewardSources']), 154)
        for token in range(281405, 281417):
            adventurer, veteran = by_id[token], by_id[token + 12]
            self.assertEqual(adventurer['rewards'], veteran['rewards'])
            self.assertTrue(set(adventurer['rewards']) < set(pool['rewards']))
            for record in (adventurer, veteran, pool):
                self.assertEqual(record['kind'], 'open')
                self.assertTrue(record['candidateRewards'])
                self.assertFalse(record['costsComplete'])
                self.assertNotIn('costs', record)
        self.assertIn(263734, by_id[281410]['rewards'])
        self.assertNotIn(263734, by_id[281405]['rewards'])
        self.assertIn(263906, by_id[281414]['rewards'])
        self.assertEqual(by_id[281415]['rewards'], [263891, 263892, 263893])
        self.assertFalse(by_id[281415]['protectCollection'])
        self.assertIs(pool['rewardRequirements']['263891']['hasAppearance'], False)

    def test_emblem_costs_dreambound_openings_and_unverified_holds(self):
        records, held = build_modern_gear()
        by_id = {row['tokenID']: row for row in records}
        emblem = by_id[238920]
        self.assertEqual(len(emblem['rewards']), 80)
        self.assertEqual(len(emblem['rewardSources']), 68)
        self.assertTrue(emblem['costsComplete'] and emblem['protectCollection'])
        for item in emblem['rewards']:
            self.assertEqual(emblem['costs'][str(item)], [{'kind': 'item', 'id': 238920, 'quantity': 1}])
            self.assertEqual(emblem['rewardRequirements'][str(item)]['unverified'], True)
        self.assertEqual(by_id[208909]['rewards'], [209383])
        self.assertEqual(by_id[208910]['rewards'], [209384])
        self.assertEqual(by_id[208922]['rewards'], [209357, 209412, 209413, 209414])
        self.assertEqual(by_id[208923]['rewards'], [209358, 209367, 209368])
        self.assertEqual(by_id[208924]['rewards'], [209356])
        self.assertEqual(len(by_id[208926]['rewards']), 19)
        self.assertEqual({row['tokenID'] for row in held}, {208925, 271991, 274272})
        self.assertFalse(by_id.keys() & {row['tokenID'] for row in held})

    def test_changed_slot_and_added_emblem_cost_fail_closed(self):
        data = json.loads(Path(SOURCE).read_text(encoding='utf-8'))
        row = data['tokenRows']['281405']
        source = row['lua']
        row['lua'] = source.replace('INVTYPE_FEET', 'INVTYPE_LEGS')
        with self.assertRaisesRegex(ValueError, 'Wrong Void-Touched inventory filter'):
            build_modern_gear(data)
        row['lua'] = source
        row = data['emblemRows'][0]
        row['lua'] = row['lua'].replace('{"i",238920,1}', '{"i",238920,1},{"c",1,1}')
        with self.assertRaisesRegex(ValueError, 'Unsupported Nightfall one-emblem equipment leaf'):
            build_modern_gear(data)


if __name__ == '__main__':
    unittest.main()
