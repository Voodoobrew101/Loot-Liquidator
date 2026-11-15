import copy
import json
import sys
import unittest
from pathlib import Path
import tempfile
sys.path.insert(0, 'tools')
import att_token_references as att


def build_original_holds(held):
    return {row['rewardID'] for row in held if row.get('tokenID') == 183895}


class ATTReferences(unittest.TestCase):
    def test_live_snapshot_costs_keep_consumed_gear_and_attribution(self):
        records, held = att.build()
        tokens = {r['tokenID']: r for r in records}
        self.assertIn(52026, tokens)
        cost = tokens[52029]['costs']['51286']
        self.assertEqual(cost, [{'kind': 'item', 'id': 51153, 'quantity': 1}, {'kind': 'item', 'id': 52029, 'quantity': 1}])
        self.assertEqual(tokens[52029]['rewardClassMasks']['51286'], 4)
        self.assertTrue(all(r['sourceRevision'] and r['sourceOrigin']=='ATT' and 'Permission is hereby granted' in r['licenseText'] for r in records))
        self.assertTrue(all(r['independentReview']=='NOT_REVIEWED' for r in records))
        self.assertEqual(build_original_holds(held), {174315, 177870})

    def test_macros_and_fractional_costs_are_never_executed(self):
        for cost in ['{{"i",123,evil()}}', '{{"i",123,1.5}}', '{{"i",123,0}}']:
            with self.assertRaises((ValueError, json.JSONDecodeError)):
                att.parse_leaf({'line': 1, 'lua': 's(1,2,{c={1},cost='+cost+'}), '})
        row = att.parse_leaf({'line': 1, 'lua': 's(1,2,{c={1},cost={{"i",123,2},{"c",99,5},10000},r=1,lvl=30}), '})
        self.assertTrue(row['requirementsUnverified'])
        self.assertEqual(row['costs'][-1], {'kind': 'money', 'quantity': 10000})

    def test_non_retail_source_rejected(self):
        data = json.loads(att.SOURCE.read_text()); data['gameMode']='Mists Classic'
        with self.assertRaises(ValueError): att.build(data)

    def test_complete_wrath_tier_families_preserve_class_and_source_scope(self):
        records, held = att.build()
        tokens = {r['tokenID']: r for r in records}
        for first, last in [(40610, 40639), (45632, 45661)]:
            family = [tokens[token] for token in range(first, last + 1)]
            self.assertEqual(sum(len(r['rewards']) for r in family), 190)
            rewards = [reward for r in family for reward in r['rewards']]
            self.assertEqual(len(set(rewards)), 190)
            for record in family:
                self.assertEqual(record['kind'], 'open')
                self.assertEqual(record['rewardSelection'], 'class')
                self.assertEqual(record['independentReview'], 'NOT_REVIEWED')
                self.assertNotIn('dropChance', record)
                self.assertNotIn('expectedQuantity', record)
                self.assertEqual(set(record['rewardClassMasks']), set(map(str, record['rewards'])))
        # Concrete reported tokens: both regular and heroic, all class groups.
        self.assertIn(46142, tokens[45642]['rewards'])
        self.assertIn(46145, tokens[45657]['rewards'])
        self.assertIn(45339, tokens[45661]['rewards'])
        self.assertEqual(build_original_holds(held), {174315, 177870})

    def test_castle_nathria_cost_variants_are_alternatives(self):
        data = json.loads(att.NATHRIA_SOURCE.read_text(encoding='utf-8'))
        held = []
        records = att.build_nathria_tokens(data, held)
        self.assertEqual([r['tokenID'] for r in records], list(range(183888, 183900)))
        self.assertEqual({r['tokenID'] for r in held}, {183895})
        self.assertEqual({r['rewardID'] for r in held}, {174315, 177870})
        zenith = records[2]
        self.assertEqual(zenith['rewardVariants']['3']['184272'], 115589)
        self.assertEqual(zenith['rewardVariants']['6']['184272'], 115590)
        self.assertFalse(zenith['costsComplete'])
        self.assertNotIn('costs', zenith)
        row = next(row for row in data['rows'] if '183890.004' in row['lua'])
        row['lua'] = row['lua'].replace('183890.004,1', '183890.004,2')
        with self.assertRaisesRegex(ValueError, 'Unsupported Castle Nathria exchange cost'):
            att.build_nathria_tokens(data, [])

    def test_tier_source_expressions_and_additional_costs_rejected(self):
        raw = Path('database/research/att-tier8-source.lua').read_text(encoding='utf-8')
        for replacement in ['evil()', '1.5', '1 }, { "i", 99, 1']:
            with self.assertRaises(ValueError):
                att.parse_tier_source(raw.replace('45640, 1', '45640, ' + replacement, 1))

    def test_tier_archive_hash_and_snapshot_class_tampering_rejected(self):
        snapshot, source, first, last = att.TIER_SOURCES[1]
        data = json.loads(snapshot.read_text(encoding='utf-8'))
        raw = snapshot.with_name(source).read_bytes()
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / snapshot.name
            archive = path.with_name(source)
            archive.write_bytes(raw + b'\n')
            path.write_text(json.dumps(data), encoding='utf-8')
            with self.assertRaisesRegex(ValueError, 'hash mismatch'):
                att.build_tier_tokens(path, source, first, last)
            archive.write_bytes(raw)
            data['rows'][0]['classID'] = 1
            path.write_text(json.dumps(data), encoding='utf-8')
            with self.assertRaisesRegex(ValueError, 'do not match'):
                att.build_tier_tokens(path, source, first, last)


if __name__=='__main__': unittest.main()
