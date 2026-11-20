"""Published Shatter unit totals and native Skill scopes stay distinct."""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent.parent


class ShatterQualitySourceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = json.loads((ROOT / 'database/research/shatter-quality-models.json').read_text())
        cls.rule = cls.source['recipeQualityModels']['470726']
        cls.catalog = json.loads((ROOT / 'database/research/profession-effect-catalog-70961.json').read_text())
        cls.original = {row['id']: row for row in (
            json.loads(line) for line in (ROOT / 'research/v3/evidence/war-within/2026-10-31T1724-gleaming-shatter-cohorts.jsonl').read_text().splitlines())}

    def test_actual_cast_denominators_and_unit_totals_are_preserved(self):
        self.assertEqual([c['actualCasts'] for c in self.source['cohorts']], [1064, 1066])
        for cohort in self.source['cohorts']:
            self.assertEqual(sum(o['units'] for o in cohort['outputTotals']), 3 * cohort['actualCasts'])
            for record_id, output in zip(cohort['sourceRecordIDs'], cohort['outputTotals']):
                original = self.original[record_id]
                self.assertEqual(original['casts'], cohort['actualCasts'])
                self.assertEqual(original['totalQuantity'], output['units'])
                self.assertEqual(original['outputItemID'], output['itemID'])
                self.assertEqual(original['inputItemID'], cohort['inputItemID'])
                self.assertEqual(original['skill'], '105+28 Enchanting skill')
                self.assertEqual(original['specialization'], 'Maxed disenchanting tree')
                self.assertIsNone(original['castsWithDrop'])
                self.assertIsNone(original['histogram'])

    def test_native_labels_route_uncommon_skill_despite_rare_input(self):
        recipe = next(r for r in self.catalog['recipeRouting']['recipes'] if r['spellID'] == 470726)
        nodes = {n['nodeID']: n for n in self.catalog['nodes']}
        expected = {99890: (3404, 65), 99889: (3436, 80)}
        for node_id, (label, expected_skill) in expected.items():
            node = nodes[node_id]
            self.assertIn(label, recipe['labels'])
            point = sum(e['amount'] * node['maxInvestedRank'] for entry in node['baseEntries']
                        for e in entry['effects'] if e['typeEnum'] == 25)
            perks = sum(e['amount'] for milestone in node['milestones'] for entry in milestone['entries']
                        for e in entry['effects'] if e['typeEnum'] == 25)
            self.assertEqual(point + perks, expected_skill)
        self.assertNotIn(3437, recipe['labels'])
        self.assertNotIn(3438, recipe['labels'])
        self.assertEqual(self.rule['skillMaximum'], 133 + 65 + 80)

    def test_curve_retains_three_units_and_input_quality_cap(self):
        self.assertEqual(self.rule['baselineRankMeans'], [3, 0, 0])
        for rank in (1, 2, 3):
            endpoint = self.rule['targetRankMeansByInputRank'][str(rank)]
            self.assertAlmostEqual(sum(endpoint), 3)
            self.assertEqual(sum(endpoint[rank:]), 0)
            for skill in (0, 1, 133, 144, 145, 277, 278, 285, 1000):
                progress = max(0, min(1, skill / self.rule['skillMaximum']))
                means = [a + (b - a) * progress for a, b in zip(self.rule['baselineRankMeans'], endpoint)]
                self.assertAlmostEqual(sum(means), 3)
                self.assertTrue(all(mean >= 0 for mean in means))
                self.assertEqual(sum(means[rank:]), 0)

    def test_curve_assumptions_have_zero_confidence_and_no_invented_counts(self):
        self.assertEqual(self.rule['confidence'], 0)
        self.assertEqual(self.source['sourceNormalizationPolicy']['confidence0to100'], 0)
        self.assertTrue(self.source['sourceNormalizationPolicy']['baselineProfileAssumed'])
        self.assertEqual(set(self.rule['sourceRecordIDs']), {
            'war-within-20261031-17240' + str(i) for i in range(6, 10)} | {'war-within-20261031-172410'})
        for field in ('samples', 'casts', 'chance', 'dropChance', 'histogram', 'minQuantity', 'maxQuantity'):
            self.assertNotIn(field, self.rule)
        self.assertIsNone(self.rule['sourceConditions']['historicalBuild'])
        self.assertTrue(self.rule['assumptions'])


if __name__ == '__main__':
    unittest.main()
