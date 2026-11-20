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
        self.assertEqual(len(compiled['specializationRules']), 25)
        self.assertEqual(sum(r['kind'] == 'skill-per-point' for r in compiled['specializationRules']), 20)
        for rule in compiled['specializationRules']:
            self.assertEqual(rule['evidenceStatus'], 'SOURCED_PROVISIONAL')
            self.assertEqual(rule['build'], 70961 if rule.get('nodeID') == 107646 else 70783)
            self.assertEqual(rule['clientVersion'], '12.1.5')
            self.assertNotIn('samples', rule)
            self.assertNotIn('quantityMultiplier', rule)
            if 'nodeID' in rule:
                catalog = self.catalog['catalogs'][f'{rule["profession"]}:{rule["expansionID"]}']
                node = next(n for n in catalog['nodes'] if n['id'] == rule['nodeID'])
                self.assertEqual(rule['maxRank'], node['maxRank'])

    def test_patch_compatibility_is_optional_and_requires_a_valid_version_and_build(self):
        data = copy.deepcopy(self.document)
        del data['rules'][0]['clientVersion']
        self.assertNotIn('clientVersion', next(
            r for r in effects.build(data, self.catalog)['specializationRules']
            if r['ruleID'] == data['rules'][0]['ruleID']))
        for value in (None, True, 120105, '', '12.1', '12.1.5.70961', '12.1.x',
                      ' 12.1.5', '12.1.5\n', '012.1.5'):
            with self.subTest(value=value):
                data = copy.deepcopy(self.document)
                data['rules'][0]['clientVersion'] = value
                with self.assertRaisesRegex(ValueError, 'client version/build'):
                    effects.build(data, self.catalog)
        for value in (None, True, 0, -1, '70783', 70783.5):
            with self.subTest(build=value):
                data = copy.deepcopy(self.document)
                data['rules'][0]['build'] = value
                with self.assertRaises(ValueError):
                    effects.build(data, self.catalog)

    def test_live_midnight_skill_milestones_preserve_learning_and_observed_build(self):
        rules = {r.get('nodeID'): r for r in effects.build(self.document, self.catalog)['specializationRules']
                 if r.get('nodeID') in (107646, 107647, 107648, 107649)}
        for node, rule in rules.items():
            self.assertEqual(rule['learningSkill'], 5)
            self.assertEqual(rule['skillMilestoneBuild'], 70961,
                             'newly resolved milestone evidence must not be backdated to the catalog build')
            self.assertEqual(rule['skillMilestones'],
                             [{'rank': 10, 'skill': 5}, {'rank': 20, 'skill': 10}, {'rank': 30, 'skill': 20}]
                             if node == 107649 else
                             [{'rank': 5, 'skill': 5}, {'rank': 10, 'skill': 5}, {'rank': 15, 'skill': 5},
                              {'rank': 25, 'skill': 10}, {'rank': 30, 'skill': 20}])
            self.assertIn('blizzard-live-midnight-skill-perks-70961', rule['sourceClaimIDs'])
        crystal = rules[107646]
        self.assertEqual((crystal['build'], crystal['perPoint'], crystal['confidence0to100']), (70961, 1, 60))
        claim = next(s for s in self.document['sourceClaims']
                     if s['id'] == 'db2-midnight-crystal-skill-per-point-70961')
        self.assertTrue(claim['inference'])
        self.assertEqual((claim['join']['professionEffectID'], claim['join']['amount'],
                          claim['join']['traitLabel']), (146, 1, 5052))
        self.assertEqual(len(claim['sourceSHA256']), 4)

    def test_learning_and_milestone_fields_reject_unknown_or_malformed_arithmetic(self):
        for key, value in [('learningSkill', None), ('learningSkill', True), ('learningSkill', 0),
                           ('learningSkill', float('inf')), ('skillMilestoneBuild', 70782),
                           ('skillMilestoneBuild', 70783),
                           ('skillMilestoneBuild', 999999), ('skillMilestoneBuild', '70961'),
                           ('skillMilestones', []), ('skillMilestones', {}),
                           ('skillMilestones', [{'rank': 0, 'skill': 5}]),
                           ('skillMilestones', [{'rank': 31, 'skill': 5}]),
                           ('skillMilestones', [{'rank': True, 'skill': 5}]),
                           ('skillMilestones', [{'rank': 5, 'skill': 0}]),
                           ('skillMilestones', [{'rank': 5, 'skill': float('nan')}]),
                           ('skillMilestones', [{'rank': 5, 'skill': 5, 'quantityMultiplier': 2}]),
                           ('skillMilestones', [{'rank': 10, 'skill': 5}, {'rank': 5, 'skill': 5}]),
                           ('skillMilestones', [{'rank': 5, 'skill': 5}, {'rank': 5, 'skill': 5}])]:
            with self.subTest(key=key, value=value):
                data = copy.deepcopy(self.document)
                data['rules'][0][key] = value
                with self.assertRaises(ValueError):
                    effects.build(data, self.catalog)
        for key in ('learningSkill', 'skillMilestoneBuild', 'skillMilestones'):
            data = copy.deepcopy(self.document)
            del data['rules'][0][key]
            with self.assertRaises(ValueError):
                effects.build(data, self.catalog)

    def test_later_rule_build_requires_an_explicit_matching_source_claim(self):
        data = copy.deepcopy(self.document)
        data['rules'][0]['build'] = 999999
        with self.assertRaisesRegex(ValueError, 'matching source evidence'):
            effects.build(data, self.catalog)
        data = copy.deepcopy(self.document)
        crystal = next(r for r in data['rules'] if r.get('nodeID') == 107646)
        crystal['sourceClaimIDs'] = ['wago-node-identity', 'live-trait:107646']
        with self.assertRaisesRegex(ValueError, 'matching source evidence'):
            effects.build(data, self.catalog)

    def test_milestone_arithmetic_cannot_be_added_to_yield_or_reference_rules(self):
        for kind in ('replace-family', 'reference-context'):
            data = copy.deepcopy(self.document)
            rule = next(r for r in data['rules'] if r['kind'] == kind)
            rule.update(learningSkill=5, skillMilestoneBuild=70961,
                        skillMilestones=[{'rank': 5, 'skill': 5}])
            with self.assertRaisesRegex(ValueError, 'learning/milestone skill fields'):
                effects.build(data, self.catalog)
        for key in ('procChance', 'procRate', 'procProbability', 'bonusQuantity',
                    'yieldMultiplier', 'quantityMilestones'):
            data = copy.deepcopy(self.document)
            data['rules'][0][key] = .5
            with self.assertRaises(ValueError):
                effects.build(data, self.catalog)

    def test_relevant_skill_scopes_exclude_other_rarities_and_preserve_inferred_epic_coefficient(self):
        rules = effects.build(self.document, self.catalog)['specializationRules']
        midnight = {r['nodeID']: r for r in rules if r['kind'] == 'skill-per-point' and r['expansionID'] == 11}
        self.assertEqual(midnight[107648]['inputRarity'], 2)
        self.assertEqual(midnight[107647]['inputRarity'], 3)
        self.assertNotIn('inputRarity', midnight[107649])
        self.assertEqual(midnight[107646]['inputRarity'], 4)
        self.assertEqual(midnight[107646]['perPoint'], 1)
        self.assertEqual(midnight[107646]['confidence0to100'], 60)
        for node in (106982, 106983, 109653, 109655, 109660):
            self.assertEqual(midnight[node]['perPoint'], 1)
        self.assertNotIn(98663, {r.get('nodeID') for r in rules},
                         'Gem Finding crafting skill is not silently added to Algari prospecting')

    def test_described_output_effects_preserve_scope_without_becoming_numeric_rules(self):
        before = copy.deepcopy(self.document)
        compiled = effects.build(self.document, self.catalog)
        descriptions = compiled['describedEffects']
        self.assertEqual(self.document, before)
        self.assertEqual({effect['nodeID']: effect['inputRarity'] for effect in descriptions},
                         {107648: 2, 107647: 3, 107646: 4})
        self.assertEqual([effect['effectID'] for effect in descriptions],
                         sorted(effect['effectID'] for effect in descriptions))
        for effect in descriptions:
            self.assertEqual((effect['profession'], effect['method'], effect['expansionID']),
                             ('Enchanting', 'Disenchant', 11))
            self.assertEqual((effect['build'], effect['clientVersion'], effect['maxRank']),
                             (70783, '12.1.5', 30))
            self.assertIn('not quantified', effect['description'])
            self.assertNotIn('perPoint', effect)
            self.assertNotIn('applyPolicy', effect)
        self.assertIn(107646, {r.get('nodeID') for r in compiled['specializationRules']})
        self.assertTrue(any(held.get('nodeID') == 107646 for held in compiled['held']),
                        'Crystal Collector direct in-game differential validation remains pending')
        data = copy.deepcopy(self.document)
        del data['describedEffects']
        self.assertEqual(effects.build(data, self.catalog)['describedEffects'], [])

    def test_descriptions_reject_numeric_transform_fields_and_invalid_provenance(self):
        for key, value in [('perPoint', 1), ('quantityMultiplier', 1.2),
                           ('applyPolicy', 'EXECUTE'), ('kind', 'skill-per-point'),
                           ('samples', 100), ('milestones', [{'rank': 20, 'multiplier': 2}]),
                           ('skillFactors', [{'skill': 10, 'factor': 2}])]:
            with self.subTest(key=key):
                data = copy.deepcopy(self.document)
                data['describedEffects'][0][key] = value
                with self.assertRaisesRegex(ValueError, 'cannot carry numeric transforms'):
                    effects.build(data, self.catalog)
        for key, value in [('effectID', ''), ('nodeID', 999999), ('nodeID', True),
                           ('maxRank', 31), ('nodeName', 'Incorrect trait name'),
                           ('description', ''), ('build', 70961), ('build', True),
                           ('clientVersion', '12.1.5.70961'), ('inputRarity', 1),
                           ('inputClassID', 7), ('profession', 'Inscription'),
                           ('sourceClaimIDs', []), ('sourceClaimIDs', ['missing']),
                           ('sourceClaimIDs', [['unhashable']])]:
            with self.subTest(key=key, value=value):
                data = copy.deepcopy(self.document)
                data['describedEffects'][0][key] = value
                with self.assertRaises(ValueError):
                    effects.build(data, self.catalog)

    def test_descriptions_reject_duplicate_identities_and_scopes(self):
        data = copy.deepcopy(self.document)
        data['describedEffects'].append(copy.deepcopy(data['describedEffects'][0]))
        with self.assertRaisesRegex(ValueError, 'duplicate described specialization effect identity'):
            effects.build(data, self.catalog)
        data['describedEffects'][-1]['effectID'] = 'another-description-of-the-same-node'
        with self.assertRaisesRegex(ValueError, 'Duplicate described specialization effect scope'):
            effects.build(data, self.catalog)

    def test_gem_color_replacements_share_one_original_amber_reservoir(self):
        rules = [r for r in effects.build(self.document, self.catalog)['specializationRules'] if r['kind'] == 'replace-family']
        self.assertEqual({r['nodeID']: r['targetFamily']['id'] for r in rules},
                         {98659: 212508, 98660: 212495, 98661: 212511, 98662: 212505})
        self.assertEqual({r['sourceFamily']['id'] for r in rules}, {212498})
        self.assertEqual({r['recipeID'] for r in rules}, {434018})
        self.assertAlmostEqual(sum(r['maxRank'] * r['perPoint'] +
                                   sum(m['fraction'] for m in r['replacementMilestones']) for r in rules), 1)
        for rule in rules:
            self.assertEqual(rule['replacementMilestoneBuild'], 70961)
            self.assertEqual(rule['replacementMilestones'],
                             [{'rank': 5, 'fraction': .02}, {'rank': 15, 'fraction': .03}])
        self.assertEqual({r['quantityPolicy'] for r in rules}, {'CONSERVE_TOTAL_GEM_UNITS'})
        self.assertEqual({r['reservoirPolicy'] for r in rules}, {'shared-original-source-quantity'})

    def test_replacement_milestones_require_reviewed_fraction_boundaries_and_shared_budget(self):
        for key, value in [('replacementMilestoneBuild', 999999), ('replacementMilestoneBuild', True),
                           ('replacementMilestones', []),
                           ('replacementMilestones', [{'rank': 0, 'fraction': .02}]),
                           ('replacementMilestones', [{'rank': 21, 'fraction': .02}]),
                           ('replacementMilestones', [{'rank': 5, 'fraction': True}]),
                           ('replacementMilestones', [{'rank': 5, 'fraction': 0}]),
                           ('replacementMilestones', [{'rank': 5, 'fraction': .3}]),
                           ('replacementMilestones', [{'rank': 15, 'fraction': .03}, {'rank': 5, 'fraction': .02}]),
                           ('replacementMilestones', [{'rank': 5, 'fraction': .02, 'samples': 100}])]:
            with self.subTest(key=key, value=value):
                data = copy.deepcopy(self.document)
                next(r for r in data['rules'] if r['kind'] == 'replace-family')[key] = value
                with self.assertRaises(ValueError):
                    effects.build(data, self.catalog)
        data = copy.deepcopy(self.document)
        data['rules'][0]['replacementMilestones'] = [{'rank': 5, 'fraction': .02}]
        data['rules'][0]['replacementMilestoneBuild'] = 70961
        with self.assertRaisesRegex(ValueError, 'replacement milestone fields'):
            effects.build(data, self.catalog)

    def test_published_references_remain_separate_text_with_historical_sources(self):
        before = copy.deepcopy(self.document)
        compiled = effects.build(self.document, self.catalog)
        self.assertEqual(self.document, before)
        references = compiled['publishedReferences']
        self.assertEqual(len(references), 2)
        self.assertEqual([entry['referenceID'] for entry in references],
                         sorted(entry['referenceID'] for entry in references))
        by_rarity = {entry['inputRarity']: entry for entry in references}
        self.assertIn('2.9 Eversinging Dust', by_rarity[2]['displayText'])
        self.assertIn('66% chance', by_rarity[4]['displayText'])
        self.assertEqual(by_rarity[2]['requiredNodes'], {'107649': 30, '107648': 30})
        self.assertEqual(by_rarity[4]['requiredNodes'], {'107649': 30, '107646': 30})
        for entry in references:
            self.assertEqual((entry['build'], entry['clientVersion']), (70961, '12.1.5'))
            self.assertEqual((entry['applyPolicy'], entry['displayPolicy']),
                             ('DISPLAY_ONLY', 'MAX_INVESTMENT_SCENARIO_ONLY'))
            for source_id in entry['sourceClaimIDs']:
                source = next(s for s in compiled['sourceClaims'] if s['id'] == source_id)
                self.assertIsNone(source['sourceBuild'])
                self.assertEqual(source['currentBuildApplicability'], 'UNVERIFIED')
                self.assertIn(source['sourcePublishedOn'], entry['displayText'])
                self.assertEqual(source['sampleSizeStatus'], 'UNKNOWN')
        self.assertEqual(len(compiled['specializationRules']), 25)
        data = copy.deepcopy(self.document)
        del data['publishedReferences']
        self.assertEqual(effects.build(data, self.catalog)['publishedReferences'], [])

    def test_published_references_reject_numeric_execution_and_invented_counts(self):
        for key, value in [('samples', 20), ('casts', 100), ('effectiveSamples', 20),
                           ('probability', .66), ('meanQuantity', .66),
                           ('expectedQuantity', 1), ('rank1Probability', .34),
                           ('quantityMultiplier', 1.2), ('confidence0to100', 80),
                           ('rankComplement', .34), ('perPoint', .01)]:
            with self.subTest(key=key):
                data = copy.deepcopy(self.document)
                data['publishedReferences'][1][key] = value
                with self.assertRaisesRegex(ValueError, 'text-only'):
                    effects.build(data, self.catalog)

    def test_published_references_require_matching_caps_policy_and_source_review(self):
        for key, value in [('applyPolicy', 'EXECUTE'), ('displayPolicy', 'ALWAYS'),
                           ('requiredNodes', {'107649': 29, '107648': 30}),
                           ('requiredNodes', {'107649': 31, '107648': 30}),
                           ('requiredNodes', {'107649': True, '107648': 30}),
                           ('requiredNodes', {'107649': 30, '107646': 30}),
                           ('inputRarity', True), ('inputRarity', 3),
                           ('sourceClaimIDs', ['missing']), ('sourceClaimIDs', [['bad']]),
                           ('build', True), ('build', 70962),
                           ('clientVersion', '12.1'), ('notes', []), ('displayText', '')]:
            with self.subTest(key=key, value=value):
                data = copy.deepcopy(self.document)
                data['publishedReferences'][0][key] = value
                with self.assertRaises(ValueError):
                    effects.build(data, self.catalog)
        data = copy.deepcopy(self.document)
        source_id = data['publishedReferences'][0]['sourceClaimIDs'][0]
        source = next(s for s in data['sourceClaims'] if s['id'] == source_id)
        source['sourcePublishedOn'] = '2026-02-30'
        with self.assertRaisesRegex(ValueError, 'source date required'):
            effects.build(data, self.catalog)
        data = copy.deepcopy(self.document)
        data['publishedReferences'].append(copy.deepcopy(data['publishedReferences'][0]))
        with self.assertRaisesRegex(ValueError, 'duplicate published reference identity'):
            effects.build(data, self.catalog)

    def test_complete_specialization_selects_real_category_reference_without_interpolation(self):
        rule = next(r for r in effects.build(self.document, self.catalog)['specializationRules'] if r['kind'] == 'reference-context')
        self.assertEqual(rule['requiredNodes'], {'107649': 30, '107647': 30})
        self.assertEqual((rule['expansionID'], rule['inputRarity'], rule['inputClassID']), (11, 3, 4))
        self.assertIn(rule['referenceContextID'], (ROOT / 'database/disenchant-category-baselines.lua').read_text())
        self.assertEqual(rule['quantityPolicy'], 'USE_REFERENCE_VECTOR_ONCE_NO_EXTRA_MULTIPLIER')
        self.assertNotIn('perPoint', rule)

    def test_modeled_disenchant_rules_preserve_explicit_assumptions_without_observations(self):
        before = copy.deepcopy(self.document)
        compiled = effects.build(self.document, self.catalog)
        self.assertEqual(self.document, before)
        rules = compiled['modeledDisenchantRules']
        self.assertEqual(len(rules), 3)
        by_rarity = {rule['inputRarity']: rule for rule in rules}
        self.assertEqual(set(by_rarity), {2, 3, 4})
        for rarity, rule in by_rarity.items():
            self.assertEqual((rule['method'], rule['profession'], rule['expansionID']),
                             ('Disenchant', 'Enchanting', 11))
            self.assertEqual((rule['build'], rule['clientVersion']), (70961, '12.1.5'))
            self.assertEqual((rule['applyPolicy'], rule['evidenceStatus']), ('EXECUTE', 'MODELED'))
            self.assertEqual(rule['inputClassIDs'], [2, 4])
            self.assertEqual(rule['rootNodeID'], 107649)
            self.assertEqual(rule['childNodeID'], {2: 107648, 3: 107647, 4: 107646}[rarity])
            self.assertEqual(rule['skillMaximum'], 290)
            self.assertEqual(rule['quantityMilestones'],
                             [{'rank': 20, 'progress': .5}, {'rank': 30, 'progress': .5}])
            self.assertIn('synthetic zero-total-skill reference', ' '.join(rule['assumptions']))
            self.assertNotIn('samples', rule)
            self.assertNotIn('casts', rule)
        self.assertEqual((by_rarity[2]['confidence0to100'], by_rarity[2]['crossClassConfidence']), (10, 5))
        self.assertEqual((by_rarity[3]['confidence0to100'], by_rarity[3]['crossClassConfidence']), (30, 15))
        self.assertEqual((by_rarity[4]['confidence0to100'], by_rarity[4]['crossClassConfidence']), (20, 20))
        self.assertEqual(by_rarity[2]['targetPooledMean'], 2.9)
        self.assertEqual(by_rarity[2]['targetRank2Share'], .65)
        self.assertEqual(by_rarity[2]['baselineFallbackClassID'], 4)
        self.assertAlmostEqual(by_rarity[3]['targetRank2Share'], .660 / 1.289)
        self.assertEqual(by_rarity[3]['targetPooledMean'], 1.289)
        self.assertTrue(by_rarity[4]['preservePrimaryTotal'])
        self.assertEqual(by_rarity[4]['targetRank2Share'], .66)
        self.assertNotIn('targetPooledMean', by_rarity[4])
        self.assertIn('not a measured Dust Deliverer endpoint', next(
            s['support'] for s in compiled['sourceClaims']
            if s['id'] == 'midnight-nearby-r2-share-estimate-20260301'))

    def test_modeled_disenchant_rules_reject_counts_and_unreviewed_transforms(self):
        for key, value in [('samples', 1000), ('casts', 20), ('effectiveSamples', 100),
                           ('rank1Probability', .34), ('quantityMultiplier', 2),
                           ('skillFactors', [{'skill': 10, 'factor': 2}]),
                           ('inputItemID', 239671), ('kind', 'measured')]:
            with self.subTest(key=key):
                data = copy.deepcopy(self.document)
                data['modeledDisenchantRules'][0][key] = value
                with self.assertRaisesRegex(ValueError, 'missing or unknown fields'):
                    effects.build(data, self.catalog)
        data = copy.deepcopy(self.document)
        data['modeledDisenchantRules'][2]['targetPooledMean'] = 1
        with self.assertRaisesRegex(ValueError, 'missing or unknown fields'):
            effects.build(data, self.catalog)

    def test_modeled_disenchant_rules_validate_scope_caps_and_interpolation(self):
        for key, value in [('inputRarity', 3), ('inputRarity', True), ('inputClassIDs', [4]),
                           ('inputClassIDs', [2.0, 4]), ('primaryRankIDs', [243599.0, 243600]),
                           ('rootNodeID', 107649.0), ('childNodeID', 107647),
                           ('build', 70783), ('clientVersion', '12.1.7'),
                           ('applyPolicy', 'DISPLAY_ONLY'), ('evidenceStatus', 'MEASURED'),
                           ('sourceKey', 'itemdb'), ('confidence0to100', 11),
                           ('crossClassConfidence', 6), ('crossClassConfidence', True),
                           ('skillMaximum', 291), ('targetRank2Share', 1.01),
                           ('targetRank2Share', float('nan')), ('targetPooledMean', 0),
                           ('baselineFallbackClassID', 2), ('assumptions', []),
                           ('sourceClaimIDs', ['missing']), ('sourceClaimIDs', [['bad']]),
                           ('quantityMilestones', [{'rank': 20, 'progress': 1}]),
                           ('quantityMilestones', [{'rank': 20, 'progress': .5},
                                                   {'rank': 30, 'progress': .6}])]:
            with self.subTest(key=key, value=value):
                data = copy.deepcopy(self.document)
                data['modeledDisenchantRules'][0][key] = value
                with self.assertRaises(ValueError):
                    effects.build(data, self.catalog)
        data = copy.deepcopy(self.document)
        data['modeledDisenchantRules'][1]['endpointRecordID'] = 'unknown-endpoint'
        with self.assertRaisesRegex(ValueError, 'reviewed full-specialization endpoint'):
            effects.build(data, self.catalog)
        data = copy.deepcopy(self.document)
        data['modeledDisenchantRules'][2]['preservePrimaryTotal'] = False
        with self.assertRaisesRegex(ValueError, 'preserve the existing primary total'):
            effects.build(data, self.catalog)
        data = copy.deepcopy(self.document)
        data['modeledDisenchantRules'].pop()
        with self.assertRaisesRegex(ValueError, 'exactly three'):
            effects.build(data, self.catalog)

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
