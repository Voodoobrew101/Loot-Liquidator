import copy
import json
import sys
import unittest
sys.path.insert(0, 'tools')
import att_token_references as att


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
        self.assertEqual(held, [])

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


if __name__=='__main__': unittest.main()
