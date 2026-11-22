"""Native output percentages cannot be borrowed from adjacent speed clauses."""
from copy import deepcopy
from pathlib import Path
import sys
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import profession_profile_rules as rules

class OutputClauseTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source=rules.load_source()
        cls.nodes={n['nodeID']:n for n in cls.source['nodes']}
        cls.entries={e['entryID']:(n,e) for n in cls.source['nodes']
                     for e in n['baseEntries']+[e for m in n['milestones'] for e in m['entries']]}
        cls.recipes,_=rules.build_recipes(cls.source)
    def compile(self,identity,text=None):
        node,entry=self.entries[identity]
        entry=deepcopy(entry)
        if text is not None:entry['resolvedDescription']=text
        return rules.compile_entry(node,entry,self.nodes,self.recipes)
    def test_khazgorite_output_is_unknown_magnitude_and_prismatic_only(self):
        effects=self.compile(36392)
        speed=next(e for e in effects if e['metric']=='craftingSpeed')
        output=next(e for e in effects if e['metric']=='extraOutput')
        self.assertEqual((speed['amount'],speed['unit'],speed['sourceAmount']),(15,'percent',15))
        self.assertEqual((output['amount'],output['confidence'],output['unit']),(0,0,'quantity'))
        self.assertTrue(output['numericUnsupported'])
        self.assertEqual(output['scope']['inputItemIDs'],[194545])
        self.assertNotIn('inputItemIDs',speed['scope'])
        self.assertFalse(any(e['metric']=='dropChance' for e in effects))
    def test_midnight_speed_twenty_is_not_extra_gem_chance(self):
        effects=self.compile(131816)
        output=next(e for e in effects if e['metric']=='extraOutput')
        self.assertEqual((output['amount'],output['confidence']),(0,0))
        self.assertTrue(output['numericUnsupported'])
        self.assertFalse(any(e['metric']=='dropChance' for e in effects))
    def test_six_real_output_clauses_keep_their_explicit_percent(self):
        for identity in [87375,87397,121928,121934,121940,121946]:
            with self.subTest(entry=identity):
                chance=next(e for e in self.compile(identity) if e['metric']=='dropChance')
                self.assertEqual((chance['amount'],chance['unit'],chance['confidence']),(1,'percent',50))
    def test_decimal_output_percent_stays_with_its_output_clause(self):
        effects=self.compile(36392,"Prospecting speed increased by 15%. Increases your chance to acquire Khaz'gorite Ore by 2.5% when prospecting Prismatic Ore.")
        chance=next(e for e in effects if e['metric']=='dropChance')
        self.assertEqual((chance['amount'],chance['operator']),(2.5,'multiply'))
    def test_positive_explicit_output_percent_is_not_the_speed_percent(self):
        effects=self.compile(36392,"Prospecting speed increased by 15%. Prospecting Prismatic Ore has a 25% chance to contain Khaz'gorite Ore.")
        chance=next(e for e in effects if e['metric']=='dropChance')
        self.assertEqual((chance['amount'],chance['operator']),(25,'add'))
        self.assertFalse(chance['numericUnsupported'])

    def test_qualitative_rarity_words_do_not_invent_proc_rates(self):
        for description in ['You can now find extremely rare diamonds when prospecting.',
                            'You can now find very rare diamonds when prospecting.',
                            'Chance to receive additional materials when prospecting.',
                            'Increases your chances of acquiring raw gems when prospecting.']:
            with self.subTest(description=description):
                output = next(e for e in self.compile(36393, description)
                              if e['metric'] in ('extraOutput', 'dropChance'))
                self.assertEqual(output['amount'], 0)
                self.assertTrue(output['numericUnsupported'])

if __name__=='__main__':unittest.main()
