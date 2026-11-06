"""Sourced point effects must retain their identities, scope and dimensions."""
import copy
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import unittest

sys.path.insert(0, 'tools')
import specialization_effects as effects

ROOT = Path(__file__).resolve().parent.parent


class SpecializationEffectsPipelineTests(unittest.TestCase):
    def setUp(self):
        self.document = json.loads(effects.SOURCE.read_text())
        self.catalog = json.loads(effects.CATALOG.read_text())

    def test_compilation_preserves_source_and_uses_catalog_spend_point_caps(self):
        before = copy.deepcopy(self.document)
        compiled = effects.build(self.document, self.catalog)
        self.assertEqual(self.document, before)
        self.assertEqual(len(compiled['specializationRules']), 24)
        self.assertEqual(sum(r['kind'] == 'skill-per-point' for r in compiled['specializationRules']), 19)
        for rule in compiled['specializationRules']:
            self.assertEqual(rule['evidenceStatus'], 'SOURCED_PROVISIONAL')
            self.assertNotIn('samples', rule)
            self.assertNotIn('quantityMultiplier', rule)
            if 'nodeID' in rule:
                catalog = self.catalog['catalogs'][f'{rule["profession"]}:{rule["expansionID"]}']
                node = next(n for n in catalog['nodes'] if n['id'] == rule['nodeID'])
                self.assertEqual(rule['maxRank'], node['maxRank'])

    def test_relevant_skill_scopes_exclude_other_rarities_and_unknown_epic_coefficient(self):
        rules = effects.build(self.document, self.catalog)['specializationRules']
        midnight = {r['nodeID']: r for r in rules if r['kind'] == 'skill-per-point' and r['expansionID'] == 11}
        self.assertEqual(midnight[107648]['inputRarity'], 2)
        self.assertEqual(midnight[107647]['inputRarity'], 3)
        self.assertNotIn('inputRarity', midnight[107649])
        self.assertNotIn(107646, midnight)
        for node in (106982, 106983, 109653, 109655, 109660):
            self.assertEqual(midnight[node]['perPoint'], 1)
        self.assertNotIn(98663, {r.get('nodeID') for r in rules},
                         'Gem Finding crafting skill is not silently added to Algari prospecting')

    def test_gem_color_replacements_share_one_original_amber_reservoir(self):
        rules = [r for r in effects.build(self.document, self.catalog)['specializationRules'] if r['kind'] == 'replace-family']
        self.assertEqual({r['nodeID']: r['targetFamily']['id'] for r in rules},
                         {98659: 212508, 98660: 212495, 98661: 212511, 98662: 212505})
        self.assertEqual({r['sourceFamily']['id'] for r in rules}, {212498})
        self.assertEqual({r['recipeID'] for r in rules}, {434018})
        self.assertAlmostEqual(sum(r['maxRank'] * r['perPoint'] for r in rules), .8)
        self.assertEqual({r['quantityPolicy'] for r in rules}, {'CONSERVE_TOTAL_GEM_UNITS'})
        self.assertEqual({r['reservoirPolicy'] for r in rules}, {'shared-original-source-quantity'})

    def test_complete_specialization_selects_real_category_reference_without_interpolation(self):
        rule = next(r for r in effects.build(self.document, self.catalog)['specializationRules'] if r['kind'] == 'reference-context')
        self.assertEqual(rule['requiredNodes'], {'107649': 30, '107647': 30})
        self.assertEqual((rule['expansionID'], rule['inputRarity'], rule['inputClassID']), (11, 3, 4))
        self.assertIn(rule['referenceContextID'], (ROOT / 'database/disenchant-category-baselines.lua').read_text())
        self.assertEqual(rule['quantityPolicy'], 'USE_REFERENCE_VECTOR_ONCE_NO_EXTRA_MULTIPLIER')
        self.assertNotIn('perPoint', rule)

    def test_unsupported_yield_curves_and_empirical_claims_are_rejected(self):
        for key, value in [('kind', 'quantity-multiplier'), ('samples', 100), ('casts', 100),
                           ('skillFactors', [{'skill': 100, 'factor': 2}]), ('quantityMultiplier', 1.2),
                           ('inputItemID', 239671)]:
            with self.subTest(key=key):
                data = copy.deepcopy(self.document)
                data['rules'][0][key] = value
                with self.assertRaises(ValueError):
                    effects.build(data, self.catalog)

    def test_malformed_identities_coefficients_scope_and_source_lineage_fail(self):
        for key, value in [('nodeID', True), ('nodeID', 999999), ('maxRank', 31),
                           ('perPoint', float('nan')), ('perPoint', float('inf')), ('perPoint', True),
                           ('perPoint', -1), ('build', 70784), ('inputRarity', 999),
                           ('confidence0to100', 101), ('confidence0to100', False),
                           ('sourceClaimIDs', []), ('sourceClaimIDs', ['missing'])]:
            with self.subTest(key=key, value=value):
                data = copy.deepcopy(self.document)
                data['rules'][0][key] = value
                with self.assertRaises(ValueError):
                    effects.build(data, self.catalog)
        data = copy.deepcopy(self.document)
        data['sourceClaims'][0]['url'] = 'http://example.com/source'
        with self.assertRaises(ValueError):
            effects.build(data, self.catalog)

    def test_duplicate_rule_identity_and_scope_are_not_double_counted(self):
        data = copy.deepcopy(self.document)
        data['rules'].append(copy.deepcopy(data['rules'][0]))
        with self.assertRaisesRegex(ValueError, 'duplicate specialization rule identity'):
            effects.build(data, self.catalog)
        data['rules'][-1]['ruleID'] = 'another-copy-of-the-same-node'
        with self.assertRaisesRegex(ValueError, 'Duplicate specialization rule scope'):
            effects.build(data, self.catalog)

    def test_replacement_requires_conservation_and_cannot_overdraw_shared_reservoir(self):
        for key, value in [('perPoint', .1), ('quantityPolicy', 'ADD_EXTRA_GEMS'),
                           ('reservoirPolicy', 'APPLY_SEQUENTIALLY'), ('targetFamily', {'id': 212498})]:
            data = copy.deepcopy(self.document)
            rule = next(r for r in data['rules'] if r['kind'] == 'replace-family')
            rule[key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                effects.build(data, self.catalog)

    def test_reference_context_requires_actual_point_caps_and_matching_physical_category(self):
        for key, value in [('requiredNodes', {'107649': 31}), ('requiredNodes', {'999': 30}),
                           ('requiredNodes', {'107649': True}), ('inputClassID', 2), ('inputRarity', 4)]:
            data = copy.deepcopy(self.document)
            rule = next(r for r in data['rules'] if r['kind'] == 'reference-context')
            rule[key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                effects.build(data, self.catalog)

    def test_generated_output_and_pinned_catalog_are_current(self):
        self.assertEqual(self.document['catalogSourceSHA256'], hashlib.sha256(effects.CATALOG.read_bytes()).hexdigest())
        completed = subprocess.run([sys.executable, 'tools/specialization_effects.py', '--check'], cwd=ROOT,
                                   text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        self.assertEqual(completed.returncode, 0, completed.stdout)
        with self.assertRaisesRegex(ValueError, 'Duplicate JSON key'):
            json.loads('{"rules":[],"rules":[]}', object_pairs_hook=effects.no_duplicate_keys)


if __name__ == '__main__':
    unittest.main()
