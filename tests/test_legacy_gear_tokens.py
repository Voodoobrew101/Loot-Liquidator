"""Replay the pinned legacy gear token evidence through the ATT importer."""

import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from att_legacy_gear import SOURCE, build_legacy_gear


class LegacyGearTokens(unittest.TestCase):
    def setUp(self):
        self.data = json.loads(SOURCE.read_text(encoding='utf-8'))
        records, held = build_legacy_gear(self.data)
        self.tokens = {record['tokenID']: record for record in records}
        self.assertEqual(len(records), len(self.tokens))
        self.assertEqual(held, [])

    def test_family_coverage_and_conservative_opening_economics(self):
        expected = (set(range(71668, 71689)) | set(range(78170, 78185))
                    | set(range(78847, 78877)) | set(range(169477, 169486))
                    | (set(range(173393, 173426)) - {173421}) | {187187}
                    | set(range(188153, 188164)) | set(range(191002, 191022)))
        self.assertEqual(set(self.tokens), expected)
        for record in self.tokens.values():
            self.assertEqual(record['kind'], 'open')
            self.assertFalse(record['costsComplete'])
            self.assertTrue(record['protectCollection'])
            self.assertNotIn('costs', record)
            self.assertNotIn('dropChance', record)
            self.assertNotIn('expectedQuantity', record)
            self.assertTrue(record['sourceEvidence'])

    def test_sepulcher_same_piece_has_distinct_difficulty_appearances(self):
        record = self.tokens[191002]
        self.assertEqual(record['rewards'], [188844, 188847, 188859])
        self.assertEqual(record['rewardClassMasks']['188847'], 2 ** 10)
        self.assertEqual(
            [record['rewardVariants'][context]['188847'] for context in ('3', '4', '5', '6')],
            [166069, 166070, 166071, 166072],
        )
        self.assertEqual(sum(len(self.tokens[token]['sourceEvidence']) for token in range(191002, 191022)), 240)

    def test_benthic_and_black_empire_use_armor_class_and_condition_evidence(self):
        benthic = self.tokens[169479]
        self.assertEqual(len(benthic['rewards']), 4)
        self.assertEqual(benthic['rewardSources']['167754'], 104104)
        self.assertEqual(benthic['rewardClassMasks']['167754'], 2 ** 4 + 2 ** 7 + 2 ** 8)
        chest = self.tokens[173393]
        self.assertTrue(chest['rewardRequirements']['173454']['unverified'])
        self.assertTrue(chest['rewardRequirements']['184599']['unverified'])
        conditions = {r['rewardID']: r['heartOfAzeroth'] for r in chest['sourceEvidence']}
        self.assertTrue(conditions[173454])
        self.assertFalse(conditions[184599])
        self.assertTrue(all(not r.get('unverified') for r in self.tokens[173394]['rewardRequirements'].values()))

    def test_korthian_slot_tables_protect_unresolved_specializations(self):
        weapon = self.tokens[188162]
        self.assertTrue(weapon['candidateRewards'])
        self.assertEqual(len(weapon['rewards']), 26)
        self.assertTrue(set(weapon['rewards']) < set(self.tokens[187187]['rewards']))
        accessories = self.tokens[188156]
        self.assertEqual(len(accessories['rewards']), 7)
        self.assertFalse(accessories['rewardSources'])
        self.assertTrue(all(not r['hasAppearance'] for r in accessories['rewardRequirements'].values()))
        self.assertTrue(set(self.tokens[188153]['rewards']).isdisjoint(weapon['rewards']))

    def test_cataclysm_preserves_potential_rewards_and_keeps_distinct_vendor_routes(self):
        gloves = self.tokens[71669]
        self.assertIn(71538, gloves['rewards'])
        self.assertNotIn(71046, gloves['rewards'])
        self.assertEqual(gloves['rewardSources']['71538'], 36764)
        self.assertEqual(self.tokens[78170]['rewardSources']['76216'], 38466)
        bug = self.tokens[78863]
        self.assertTrue(any(r.get('unverified') for r in bug['rewardRequirements'].values()))

    def test_malformed_cited_rows_rejected(self):
        families = self.data['families']
        row = families['sepulcher']['tokens']['191002']['rows'][0]
        row['lua'] = row['lua'].replace('c={11}', 'c={13}', 1)
        with self.assertRaisesRegex(ValueError, 'Conflicting Sepulcher class rewards'):
            build_legacy_gear(self.data)


if __name__ == '__main__':
    unittest.main()
