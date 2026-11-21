"""Finite native proof for the DE-only combat-aura equivalence exclusion."""
import csv
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
PROOF = ROOT / 'database/research/disenchant-nonoutput-auras-70961.json'
REVIEWED_PROOF_SHA256 = '4e537f63c249cbdfaf5b5caeac91d7dca52671f5363a1bebcc9b234efce8f94f'


def require_reviewed_proof(proof):
    payload = (json.dumps(proof, ensure_ascii=False, sort_keys=True, indent=2) + '\n').encode()
    if hashlib.sha256(payload).hexdigest() != REVIEWED_PROOF_SHA256:
        raise ValueError('Native aura proof changed; its effects and exclusion scope require review')


class DisenchantAuraProof(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.proof = json.loads(PROOF.read_text(encoding='utf-8'))
        require_reviewed_proof(cls.proof)
        cls.auras = {row['spellID']: row for row in cls.proof['auras']}

    def test_runtime_uses_only_reviewed_exact_ids(self):
        source = (ROOT / 'LootLiquidator/ProfessionModels.lua').read_text(encoding='utf-8')
        block = re.search(r'local disenchantNonOutputAuras70961=\{(.*?)\n\}', source, re.S).group(1)
        actual = {int(value) for value in re.findall(r"\['(\d+)'\]=true", block)}
        self.assertEqual(actual, set(self.proof['reviewedNonOutputAuraIDs']))
        self.assertEqual(actual, {1126, 5487, 22812, 22842, 61336, 192081, 1251877, 1261872, 1271910})
        self.assertEqual(self.proof['build'], 70961)
        self.assertEqual(self.proof['clientVersion'], '12.1.5')
        self.assertEqual(self.proof['unknownAuraPolicy'], 'RETAIN_PROFILE_CONSTRAINT')
        self.assertEqual(self.proof['knownProfessionConditionPolicy'], 'RETAIN_PROFILE_CONSTRAINT_EVEN_IF_LISTED')

    def test_complete_explicit_trigger_graph(self):
        roots = set(self.proof['rootAuraIDs'])
        self.assertEqual(roots, {1126, 5487, 22812, 22842, 61336, 192081})
        visited, pending = set(), list(roots)
        effect_ids = set()
        while pending:
            spell = pending.pop()
            if spell in visited:
                continue
            visited.add(spell)
            self.assertIn(spell, self.auras, 'a trigger must have its own native proof')
            node = self.auras[spell]
            self.assertTrue(node['name'])
            self.assertGreater(len(node['reviewedConclusion']), 25)
            self.assertTrue(node['nativeEffects'])
            for effect in node['nativeEffects']:
                self.assertEqual(int(effect['SpellID']), spell)
                self.assertNotIn(effect['ID'], effect_ids)
                effect_ids.add(effect['ID'])
                trigger = int(effect['EffectTriggerSpell'])
                if trigger:
                    pending.append(trigger)
        self.assertEqual(visited, set(self.auras), 'no unconnected name-only exclusions')
        self.assertEqual(len(effect_ids), 31)

    def test_changed_native_skill_effect_or_scope_expires_proof(self):
        skill_effect = deepcopy(self.proof)
        # Same spell ID and same runtime list, but a changed native skill aura
        # must not pass merely because tests mirror the exclusion constants.
        skill_effect['auras'][0]['nativeEffects'][0]['EffectAura'] = '30'
        extra_id = deepcopy(self.proof)
        extra_id['reviewedNonOutputAuraIDs'].append(12345)
        for changed in (skill_effect, extra_id):
            with self.assertRaises(ValueError):
                require_reviewed_proof(changed)

    def test_pinned_native_rows_when_cache_available(self):
        native = ROOT.parent / '.validation/de-formula-data'
        if not (native / 'SpellEffect-70961.csv').is_file():
            self.skipTest('optional original native cache absent; tracked complete graph still checked')
        ids = set(self.auras)
        for name, receipt in self.proof['sources'].items():
            path = native / name
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), receipt['sha256'])
            with path.open(encoding='utf-8-sig') as stream:
                rows = [row for row in csv.DictReader(stream)
                        if int(row['SpellID'] if name.startswith('SpellEffect') else row['ID']) in ids]
            if name.startswith('SpellEffect'):
                expected = [effect for node in self.auras.values() for effect in node['nativeEffects']]
                self.assertEqual(sorted(rows, key=lambda r: int(r['ID'])), sorted(expected, key=lambda r: int(r['ID'])))
            elif name.startswith('SpellName'):
                self.assertEqual({int(row['ID']): row['Name_lang'] for row in rows},
                                 {spell: node['name'] for spell, node in self.auras.items()})
            else:
                self.assertEqual({int(row['ID']): row for row in rows},
                                 {spell: node['spellText'] for spell, node in self.auras.items()})


if __name__ == '__main__':
    unittest.main()
