"""The source export must stay distinct from counts and unsupported formulas."""
import copy
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, 'tools')
import skill_quality_to_rules as quality


def fixture():
    return {
        'schemaVersion': 1, 'revision': 'fixture/1',
        'sourceClaims': [{'id': 'test:source', 'url': 'https://example.com/observed-quality',
                          'support': 'Synthetic pipeline contract fixture, not game evidence.'}],
        'rules': [{
            'ruleID': 'fixture:quality', 'method': 'Prospect', 'recipeID': 1231127,
            'expansionID': 11, 'formulaID': quality.FORMULA, 'maxQuality': 2,
            'inputQualityRanks': [1, 2], 'requireExactOperationContext': True,
            'quantityPolicy': quality.QUANTITY_POLICY, 'confidence0to100': 60,
            'applyPolicy': 'EXECUTE', 'evidenceStatus': 'SOURCED_PROVISIONAL',
            'sourceClaimIDs': ['test:source'],
            'outputFamilies': [{'name': 'Reverse ID family', 'rankItemIDs': [200, 100],
                                'rankMappingStatus': 'SOURCE_CHECKED_ORDER',
                                'sourceClaimIDs': ['test:source']}],
        }],
    }


class SkillQualityPipelineTests(unittest.TestCase):
    def test_known_rank_order_is_preserved_without_quantity_or_fixed_threshold(self):
        original = fixture()
        frozen = copy.deepcopy(original)
        compiled = quality.build(original)
        rule = compiled['skillQualityRules'][0]
        self.assertEqual(rule['outputFamilies'][0]['rankItemIDs'], [200, 100])
        self.assertEqual(rule['quantityPolicy'], quality.QUANTITY_POLICY)
        self.assertTrue(rule['requireExactOperationContext'])
        self.assertFalse(any(k in rule for k in ('skillThreshold', 'baseDifficulty', 'skillFactors')))
        self.assertEqual(original, frozen)

    def test_unsupported_rules_are_held_and_never_executable(self):
        cases = [('applyPolicy', 'PREVIEW_ONLY'), ('formulaID', 'SKILL_TIMES_OUTPUT'),
                 ('method', 'Disenchant'), ('expansionID', 10), ('maxQuality', 3),
                 ('requireExactOperationContext', False), ('skillThreshold', 365),
                 ('expectedQuantityMultiplier', 1.1)]
        for key, value in cases:
            with self.subTest(key=key):
                data = fixture()
                data['rules'][0][key] = value
                result = quality.build(data)
                self.assertEqual(result['skillQualityRules'], [])
                self.assertTrue(result['held'][0]['reason'])

    def test_unproven_conditional_or_overlapping_maps_stay_held(self):
        for patch in ({'rankMappingStatus': 'UNVERIFIED'}, {'conditional': True},
                      {'rankItemIDs': [100, 100]}, {'rankItemIDs': [True, 100]},
                      {'sourceClaimIDs': ['missing']}):
            with self.subTest(patch=patch):
                data = fixture()
                data['rules'][0]['outputFamilies'][0].update(patch)
                result = quality.build(data)
                self.assertEqual(result['skillQualityRules'], [])
                self.assertGreaterEqual(len(result['held']), 1)
        data = fixture()
        duplicate = copy.deepcopy(data['rules'][0]['outputFamilies'][0])
        duplicate['name'] = 'Overlapping family'
        data['rules'][0]['outputFamilies'].append(duplicate)
        result = quality.build(data)
        self.assertEqual(len(result['skillQualityRules'][0]['outputFamilies']), 1)
        self.assertIn('overlaps', result['held'][0]['reason'])

    def test_invalid_or_duplicate_rule_identity_and_inputs_fail_build(self):
        changes = [('confidence0to100', float('nan')), ('confidence0to100', float('inf')),
                   ('confidence0to100', True), ('confidence0to100', 101),
                   ('recipeID', True), ('inputQualityRanks', [1, 1]),
                   ('inputQualityRanks', [1, 3]), ('inputItemIDs', [12, 12]),
                   ('sourceClaimIDs', []), ('sourceClaimIDs', ['missing'])]
        for key, value in changes:
            with self.subTest(key=key, value=value):
                data = fixture()
                data['rules'][0][key] = value
                with self.assertRaises(ValueError):
                    quality.build(data)
        data = fixture()
        data['rules'].append(copy.deepcopy(data['rules'][0]))
        with self.assertRaisesRegex(ValueError, 'Duplicate.*identity'):
            quality.build(data)
        data['rules'][1]['ruleID'] = 'different-id-same-scope'
        with self.assertRaisesRegex(ValueError, 'duplicate quality rule scope'):
            quality.build(data)

    def test_duplicate_json_keys_are_rejected(self):
        with self.assertRaisesRegex(ValueError, 'Duplicate JSON object key'):
            json.loads('{"rules": [], "rules": [1]}', object_pairs_hook=quality.no_duplicate_keys)

    def test_generator_check_detects_stale_source_without_network_or_rewriting(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory, 'source.json')
            output = Path(directory, 'generated.lua')
            source.write_text(json.dumps(fixture()))
            command = [sys.executable, 'tools/skill_quality_to_rules.py', '--source', str(source), '--output', str(output)]
            subprocess.run(command, check=True, capture_output=True, text=True)
            content = output.read_bytes()
            subprocess.run(command + ['--check'], check=True, capture_output=True, text=True)
            source.write_text(source.read_text() + '\n')
            stale = subprocess.run(command + ['--check'], capture_output=True, text=True)
            self.assertNotEqual(stale.returncode, 0)
            self.assertIn('stale', stale.stderr)
            self.assertEqual(output.read_bytes(), content)

    def test_real_export_holds_historical_hypotheses_and_resolves_reverse_ids(self):
        data = json.loads(quality.SOURCE.read_text())
        result = quality.build(data)
        self.assertEqual({r['method'] for r in result['skillQualityRules']}, {'Prospect', 'Mill'})
        families = {f['name']: f for r in result['skillQualityRules'] for f in r['outputFamilies']}
        self.assertEqual(families['Crystalline Glass']['rankItemIDs'], [242787, 242786])
        self.assertEqual(families['Sanguithorn Pigment']['rankItemIDs'], [245865, 245864])
        self.assertNotIn('Mana Lily Pigment', families)
        self.assertTrue(any(h.get('outputFamily') == 'Eversong Diamond' for h in result['held']))
        candidates = result['heldNumericCandidates']
        self.assertTrue(any(c['id'] == 'tww-rank-pair-quantity-scenario' for c in candidates))
        self.assertTrue(all(c['status'] == 'HELD' and not c['runtimeAdmissible'] for c in candidates))

    def test_actual_compiler_embeds_rules_and_source_lineage(self):
        lua = shutil.which('lua5.1') or '/workspace/.loot-liquidator-tools/lua/usr/bin/lua5.1'
        if not Path(lua).exists():
            self.skipTest('Lua 5.1 is unavailable for compiler integration')
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory, 'ItemDB.lua')
            subprocess.run([lua, 'tools/compile_itemdb.lua', str(output)], check=True,
                           capture_output=True, text=True)
            check = """
local LL={}
assert(loadfile(arg[1]))('LootLiquidator',LL)
local source=assert(loadfile('database/skill-quality-rules.lua'))()
assert(#LL.ItemDB.skillQualityRules==#source.skillQualityRules)
assert(LL.ItemDB.buildReport.skillQuality.rules==#source.skillQualityRules)
assert(#LL.ItemDB.skillQualitySources==#source.sourceClaims)
assert(#LL.ItemDB.skillQualityHeldNumericCandidates==#source.heldNumericCandidates)
assert(LL.ItemDB.skillQualityRevision==source.revision..':'..source.sourceSHA256)
for _,r in ipairs(LL.ItemDB.skillQualityRules) do
  assert(r.requireExactOperationContext and r.formulaID=='EXACT_INPUT_QUALITY_THRESHOLD')
  assert(r.skillThreshold==nil and r.baseDifficulty==nil and r.expectedQuantityMultiplier==nil)
end
"""
            subprocess.run([lua, '-', str(output)], input=check, check=True,
                           capture_output=True, text=True)


if __name__ == '__main__':
    unittest.main()
