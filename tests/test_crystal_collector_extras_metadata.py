"""Unsupported Crystal extra-material priors never reach numerical rules."""
import copy
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import specialization_effects


class CrystalCollectorExtrasMetadataTests(unittest.TestCase):
    def setUp(self):
        self.document = json.loads(specialization_effects.SOURCE.read_text(encoding='utf-8'))
        self.catalog = json.loads(specialization_effects.CATALOG.read_text(encoding='utf-8'))
        self.compiled = specialization_effects.build(self.document, self.catalog)

    def crystal(self):
        return next(r for r in self.compiled['modeledDisenchantRules'] if r['childNodeID'] == 107646)

    def test_unverified_archive_is_not_a_numeric_input(self):
        archive = json.loads((ROOT / 'database/research/crystal-collector-extra-materials.json').read_text(encoding='utf-8'))
        self.assertEqual(archive['identityStatus'], 'POSSIBLE_NATIVE_ESSENCE_POOL_NOT_VERIFIED_DISENCHANT_LOOT_LINK')
        self.assertIn('no concrete Mote disenchant outcome', ' '.join(archive['assumptions']))
        for key in ('additionalOutputs', 'additionalOutputMilestones', 'additionalOutputBaselinePolicy'):
            self.assertNotIn(key, self.crystal())
        self.assertNotIn('crystalExtraRevision', self.compiled)
        self.assertNotIn('crystalExtraSourceSHA256', self.compiled)
        admitted = {source['id'] for source in self.compiled['sourceClaims']}
        self.assertTrue(admitted.isdisjoint(source['id'] for source in archive['sourceClaims']))

    def test_real_native_crystal_skill_grants_are_preserved(self):
        skill = next(r for r in self.compiled['specializationRules']
                     if r.get('nodeID') == 107646 and r['kind'] == 'skill-per-point')
        self.assertEqual(skill['perPoint'], 1)
        self.assertIn({'rank': 30, 'skill': 20}, skill['skillMilestones'])
        self.assertIn('blizzard-live-midnight-skill-perks-70961', skill['sourceClaimIDs'])
        self.assertEqual(self.crystal()['primaryRankIDs'], [243605, 243606])
        self.assertTrue(self.crystal()['preservePrimaryTotal'])

    def test_measured_supplier_endpoint_and_source_observations_are_preserved(self):
        before = copy.deepcopy(self.document)
        compiled = specialization_effects.build(self.document, self.catalog)
        self.assertEqual(self.document, before)
        supplier = next(r for r in compiled['modeledDisenchantRules'] if r['childNodeID'] == 107647)
        self.assertEqual(supplier['targetPooledMean'], 1.289)
        self.assertAlmostEqual(supplier['targetRank2Share'], 660 / 1289)
        self.assertEqual(supplier['endpointRecordID'], 'de-category:gear:11:3:armor:max-specialization:a194c8a33fcf')
        self.assertEqual(len(compiled['specializationRules']), 25)

    def test_raw_rule_cannot_smuggle_extra_material_quantities(self):
        changed = copy.deepcopy(self.document)
        crystal = next(r for r in changed['modeledDisenchantRules'] if r['childNodeID'] == 107646)
        crystal['additionalOutputs'] = [{'id': 236949, 'expectedQuantity': .07225, 'confidence0to100': 5}]
        with self.assertRaises(ValueError):
            specialization_effects.build(changed, self.catalog)


if __name__ == '__main__':
    unittest.main()
