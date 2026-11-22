"""Retired editor/projection data is pruned without changing actual item values."""
import hashlib
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import import_profession_catalog as catalog
import profession_profile_rules as profiles


def canonical(value):
    if isinstance(value, dict):
        return sorted([[type(key).__name__ + ':' + str(key), canonical(item)]
                       for key, item in value.items()], key=lambda pair: pair[0])
    if isinstance(value, list):
        return [canonical(item) for item in value]
    return value


def digest(value):
    return hashlib.sha256(json.dumps(canonical(value), sort_keys=True,
                                     separators=(',', ':')).encode()).hexdigest()


class ProcessingProfilePruningTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = profiles.load_source()
        cls.original = digest(cls.source)
        cls.document, _ = profiles.build(cls.source)
        cls.controls = catalog.processing_control_nodes(cls.document, cls.source)

    def effects(self):
        return sorted([effect for profile in self.document['profiles'].values()
                       for node in profile['nodes'].values()
                       for effects in [node['pointEffects'], node['learningEffects']]
                       + [milestone['effects'] for milestone in node['milestones']]
                       for effect in effects], key=lambda effect: effect['effectID'])

    def test_all_actual_value_effects_are_identical_to_pre_cleanup(self):
        # Receipt from the pinned source before removing non-value projections.
        self.assertEqual(len(self.effects()), 2826)
        self.assertEqual(digest(self.effects()),
                         '194aafd20f56ad2822fce4172051525b3cd8582d7493b5cdaef45003e8bedb73')
        self.assertTrue({effect['metric'] for effect in self.effects()}
                        <= {'skill', 'difficulty', 'resourcefulness', 'multicraft', 'extraOutput',
                            'dropChance', 'resourcefulnessSaved', 'multicraftExtra'})

    def test_all_native_items_families_and_nonretired_recipe_fields_survive(self):
        self.assertEqual(len(self.document['recipes']), 11485)
        self.assertEqual(len(self.document['items']), 29222)
        self.assertEqual(len(self.document['qualityFamilies']), 700)
        self.assertEqual(digest(self.document['recipes']),
                         '1bce4e9bfed150bcc859742a56276945aa0542980cf10e839996be2ed59161d7')
        self.assertEqual(digest(self.document['items']),
                         '3f73e7c44d03f7d96ab390dafab96fbb20291c6d84cab1058c7ce09202d46966')
        self.assertEqual(digest(self.document['qualityFamilies']),
                         'c2ccd8fd2f63e4a4f653b50a100115a362428ed69817b4a9209171b4ffca0798')

    def test_retired_simulated_profiles_and_projection_fields_are_absent(self):
        professions = {'Alchemy', 'Blacksmithing', 'Cooking', 'Enchanting', 'Engineering',
                       'Inscription', 'Jewelcrafting', 'Leatherworking', 'Mining', 'Tailoring'}
        self.assertEqual(set(self.document['profiles']),
                         {f'{profession}:{expansion}' for profession in professions for expansion in (9, 10, 11)})
        for profile in self.document['profiles'].values():
            self.assertFalse(set(profile['statKeys']) - {'skill', 'resourcefulness', 'multicraft'})
        for recipe in self.document['recipes'].values():
            self.assertFalse({'baseDuration', 'baseDurationSource', 'supportsIngenuity'} & set(recipe))
            for field in ('capabilityEvidence', 'capabilityConfidence'):
                self.assertNotIn('ingenuity', recipe.get(field, {}))

    def test_unrouted_source_labels_are_not_shipped_but_real_craft_alternates_survive(self):
        for effect in self.effects():
            if effect['scope'].get('method') in {'Refine', 'Unravel'}:
                self.assertEqual(effect['scope'].get('alternateMethod'), 'Craft')
                self.assertTrue(effect['scope'].get('alternateRecipeIDs'))
        for method in ('Refine', 'Unravel'):
            effect = {'metric': 'skill', 'scope': {'method': method}}
            self.assertFalse(profiles.is_runtime_value_effect(effect))
            effect['scope'].update(alternateMethod='Craft', alternateRecipeIDs=[1230867])
            self.assertTrue(profiles.is_runtime_value_effect(effect))

    def test_shared_parameter_maps_remain_for_real_gathering_profession_crafts(self):
        for profession, expected in [('Herbalism', 7), ('Skinning', 33), ('Fishing', 6)]:
            crafts = [recipe for recipe in self.document['recipes'].values()
                      if recipe['profession'] == profession and recipe['outputIDs']]
            self.assertEqual(len(crafts), expected)
            self.assertIn(profession, self.document['professionParameters'])
            self.assertFalse(any(key.startswith(profession + ':') for key in self.document['profiles']))

    def test_catalog_uses_shared_scoped_policy_and_retains_real_processing_controls(self):
        self.assertFalse(any(key.startswith(('Herbalism:', 'Skinning:', 'Fishing:')) for key in self.controls))
        self.assertTrue({106978, 106979, 106980, 106981, 106982, 106983, 107014}
                        <= self.controls['Jewelcrafting:11'])
        self.assertTrue({106278, 106280, 109653, 109655, 109660}
                        <= self.controls['Inscription:11'])
        self.assertEqual(self.controls['Enchanting:11'], {107649, 107648, 107647, 107646})
        for key, nodes in self.controls.items():
            profile = self.document['profiles'][key]
            self.assertTrue(nodes <= set(profile['nodes']))
            for identity in nodes:
                parent = profile['nodes'][identity].get('parentID')
                if parent in profile['nodes']:
                    self.assertIn(parent, nodes, 'A retained control must keep its native prerequisite')

    def test_source_and_generated_rules_are_unchanged_by_build(self):
        self.assertEqual(digest(self.source), self.original)
        self.assertEqual(profiles.OUTPUT.read_text(encoding='utf-8'), profiles.render(self.document))


if __name__ == '__main__':
    unittest.main()
