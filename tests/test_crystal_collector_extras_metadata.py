"""Crystal extras retain actual perk boundaries and explicit transferred priors."""
import json
import copy
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / 'tools'))
import specialization_effects


class CrystalCollectorExtrasMetadataTests(unittest.TestCase):
    def setUp(self):
        self.extra = json.loads((ROOT / 'database/research/crystal-collector-extra-materials.json').read_text())

    def test_unlocks_match_preserved_primary_db2_descriptions(self):
        data = json.loads((ROOT / 'research/mechanics/2026-11-19-game-data-formulas.json').read_text())
        node = next(n for n in data['nodes'] if n['nodeID'] == self.extra['childNodeID'])
        perks = {m['investedPointsRequired']: m for m in node['milestones']}
        self.assertEqual(perks[20]['nodeID'], 107620)
        self.assertEqual(perks[30]['nodeID'], 107618)
        self.assertIn('native magical essences', perks[20]['description'])
        self.assertIn('increasing your chances', perks[30]['description'])
        self.assertEqual(perks[20]['rawProfessionEffects'], [])
        self.assertEqual(perks[30]['resolvedSkillAmount'], 20)
        self.assertEqual(self.extra['additionalOutputMilestones'],
                         [{'rank': 20, 'progress': .5}, {'rank': 30, 'progress': .5}])

    def test_pool_is_a_declared_identity_assumption_with_existing_item_identities(self):
        self.assertEqual(self.extra['identityStatus'],
                         'POSSIBLE_NATIVE_ESSENCE_POOL_NOT_VERIFIED_DISENCHANT_LOOT_LINK')
        source = ROOT / 'research/v3/evidence/midnight/2026-10-31T1012-alchemy-transmutes-recycling-and-exclusions.jsonl'
        identities = {}
        for line in source.read_text().splitlines():
            record = json.loads(line)
            for prefix in ('give', 'get'):
                if record.get(prefix + 'ItemID'):
                    identities[record[prefix + 'ItemID']] = record[prefix + 'Name']
        outputs = self.extra['additionalOutputs']
        self.assertEqual({entry['id'] for entry in outputs}, {236949, 236950, 236951, 236952})
        for entry in outputs:
            self.assertEqual(identities[entry['id']], self.extra['outputNames'][str(entry['id'])])
            self.assertEqual(set(entry), {'id', 'expectedQuantity', 'confidence0to100'})
            self.assertEqual(entry['confidence0to100'], 5)
        self.assertIn('no concrete Mote disenchant outcome', ' '.join(self.extra['assumptions']))

    def test_transferred_unit_budget_creates_no_empirical_proc_or_sample_claim(self):
        data = json.loads((ROOT / 'research/mechanics/midnight-enchanting-yields-2026-11-06.json').read_text())
        cohort = next(c for c in data['cohorts'] if c['studyKey'] == 'wowhead-mikimm-courtly-wrists-1000')
        budget = cohort['listedOtherMaterialEUnitsPerCompletedCast']
        self.assertAlmostEqual(sum(e['expectedQuantity'] for e in self.extra['additionalOutputs']), budget)
        self.assertEqual(self.extra['additionalOutputBaselinePolicy'], 'ZERO_BEFORE_UNLOCK')
        for rank, expected in [(0, 0), (19, 0), (20, budget / 2), (29, budget / 2), (30, budget)]:
            progress = sum(m['progress'] for m in self.extra['additionalOutputMilestones'] if rank >= m['rank'])
            self.assertAlmostEqual(sum(e['expectedQuantity'] * progress for e in self.extra['additionalOutputs']), expected)
        for key in ('samples', 'casts', 'effectiveSamples', 'procProbability', 'conditionalStackSize'):
            self.assertNotIn(key, self.extra)
        self.assertIn('does not transfer any sample count', self.extra['sourceClaims'][2]['support'])

    def test_compiler_consumes_extra_contract_without_mutating_base_rule_sources(self):
        document = json.loads(specialization_effects.SOURCE.read_text())
        catalog = json.loads(specialization_effects.CATALOG.read_text())
        before = copy.deepcopy(document)
        compiled = specialization_effects.build(document, catalog, self.extra)
        self.assertEqual(document, before)
        crystal = next(r for r in compiled['modeledDisenchantRules'] if r['childNodeID'] == 107646)
        for key in ('additionalOutputs', 'additionalOutputMilestones', 'additionalOutputBaselinePolicy'):
            self.assertEqual(crystal[key], self.extra[key])
        self.assertEqual(len(compiled['specializationRules']), 25)
        for key, value in [('childNodeID', 107647), ('inputRarity', 3),
                           ('additionalOutputBaselinePolicy', 'SCALE_PRIMARY_TOTAL')]:
            changed = copy.deepcopy(self.extra)
            changed[key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                specialization_effects.build(document, catalog, changed)


if __name__ == '__main__':
    unittest.main()
