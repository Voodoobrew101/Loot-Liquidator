"""Real pinned source/native regression; no generated artifacts are written."""
from collections import defaultdict
from copy import deepcopy
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from curate_processing_catalogue import Curator, ore_matched_crushed_family


class CrushedOreQualityPlaceholders(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.curator = Curator(ROOT / 'database/research/v3-snapshot')
        cls.crushed = next(p for p in cls.curator.proposals['proposals']
                           if p['proposalID'] == 'p055-003:war-within-20261116-0424012')

    def emit(self, proposal, input_id, output_id):
        c = self.curator
        context, _, assumptions, _ = c.profile(proposal, proposal['method'], c.names[input_id]['expansionID'])
        before = deepcopy(proposal)
        c.emit_record(('test-native-ore-quality', input_id, False),
                      [(proposal, proposal['quantity']['value'], [output_id], [])],
                      context, assumptions, True, defaultdict(list))
        self.assertEqual(proposal, before, 'source evidence must remain immutable')
        return c.model[-1]

    def test_actual_aqirite_rank2_preserves_positive_mean_without_sibling_zeros(self):
        spec = self.emit(self.crushed, 210934, 213220)
        self.assertEqual([m['id'] for m in spec['materials']], [213220])
        self.assertAlmostEqual(spec['materials'][0]['expectedQuantity']['value'], .104)
        self.assertEqual(spec['inputQualityRank'], 2)
        self.assertEqual(spec['referenceConditions']['modeledMissingRankZeroItemIDs'], [])
        self.assertNotIn('reviewedQualityProjection', spec)
        self.assertNotIn('minQuantity', spec['materials'][0])
        self.assertNotIn('maxQuantity', spec['materials'][0])

    def test_unknown_native_input_rank_does_not_authorize_removal(self):
        item = self.curator.items[210934]
        original = item.pop('qualityRank')
        try:
            spec = self.emit(self.crushed, 210934, 213220)
        finally:
            item['qualityRank'] = original
        self.assertEqual({m['id'] for m in spec['materials']}, {213219, 213220, 213221})
        self.assertAlmostEqual(next(m for m in spec['materials'] if m['id'] == 213220)['expectedQuantity']['value'], .104)

    def test_other_actual_gem_family_keeps_existing_behavior(self):
        proposal = next(p for p in self.curator.proposals['proposals']
                        if p.get('method') == 'Prospect'
                        and 188658 in p.get('inputIdentity', {}).get('itemIDs', [])
                        and p.get('outputIdentity', {}).get('itemIDs') == [192870]
                        and p.get('admissionDecision') == 'USE_BASELINE_QUANTITY_PRIOR')
        spec = self.emit(proposal, 188658, 192870)
        self.assertEqual({m['id'] for m in spec['materials']}, {192869, 192870, 192871})
        self.assertEqual(set(spec['referenceConditions']['modeledMissingRankZeroItemIDs']), {192869, 192871})

    def test_native_rule_requires_exact_identity_text_and_quality_family(self):
        source = self.curator.native_source
        self.assertEqual(ore_matched_crushed_family(source), 383)
        changed = deepcopy(source)
        node = next(n for n in changed['nodes'] if n['nodeID'] == 98663)
        entry = next(e for m in node['milestones'] for e in m.get('entries', []) if e['entryID'] == 121951)
        entry['resolvedDescription'] = 'A different or unresolved rule'
        self.assertIsNone(ore_matched_crushed_family(changed))
        changed = deepcopy(source)
        changed['recipeRouting']['qualityFamilies']['383']['qualityOrderVerified'] = False
        self.assertIsNone(ore_matched_crushed_family(changed))


if __name__ == '__main__':
    unittest.main()
