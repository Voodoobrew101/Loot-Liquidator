"""Exact, fail-closed compatibility preservation for one reference-only range."""
import copy
import hashlib
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.dont_write_bytecode = True
sys.path.insert(0, 'tools')
import research_v3_to_baselines as adapter
import research_v3_reference_ranges as repair
FIXTURE = Path('tests/fixtures/legacy-reference-range')
PIN = Path('database/research/v3-snapshot')
TARGET = 'legacy-20261110-24914'
CANONICAL = 'legacy-20261106-004102'


def raw_rows():
    manifest = json.loads((FIXTURE/'SOURCES.json').read_text())
    result = []
    for name, meta in manifest['files'].items():
        data = (FIXTURE/name).read_bytes()
        if hashlib.sha256(data).hexdigest() != meta['sha256']:
            raise ValueError('Changed immutable fixture: ' + name)
        result.extend(dict(json.loads(line), _file=meta['path'])
                      for line in data.decode().splitlines() if line.strip())
    return result


def loaded_rows():
    rr = raw_rows()
    replaced = {r['replaces'] for r in rr if r.get('replaces')}
    return [r for r in rr if r['id'] not in replaced]


def target(rr, key=TARGET):
    return next(r for r in rr if r['id'] == key)


class ReferenceRangeTests(unittest.TestCase):
    def test_exact_contract_preserves_only_two_fields_without_mutation(self):
        rr = loaded_rows(); before = copy.deepcopy(rr)
        result = repair.preserve_reference_range(rr)
        expected = copy.deepcopy(before)
        target(expected).update(minSeen=2, maxSeen=2)
        self.assertEqual(result, expected)
        self.assertEqual(rr, before)
        self.assertIsNot(result, rr)
        self.assertEqual((target(result)['sourceKind'], target(result)['casts'],
                          target(result)['histogram']), ('reference', None, None))
        self.assertIs(repair.preserve_reference_range(result), result)
        for a, b in zip(rr, result):
            if a['id'] != TARGET: self.assertIs(a, b)

    def test_each_changed_removed_or_extra_field_fails_closed(self):
        # Exhaustive top-level provenance/count/identity/schema mutation controls.
        for key in (TARGET, CANONICAL):
            original = target(loaded_rows(), key)
            for field in original:
                for remove in (False, True):
                    with self.subTest(key=key, field=field, remove=remove):
                        rr = loaded_rows(); row = target(rr, key)
                        if remove: row.pop(field)
                        else: row[field] = {'unexpected': 'changed'}
                        self.assertIs(repair.preserve_reference_range(rr), rr)
            rr = loaded_rows(); target(rr, key)['unreviewedField'] = True
            self.assertIs(repair.preserve_reference_range(rr), rr)

    def test_nested_provenance_and_non_json_values_fail_closed(self):
        for key in (TARGET, CANONICAL):
            for field in target(loaded_rows(), key)['source']:
                rr = loaded_rows(); target(rr, key)['source'][field] = 'changed'
                self.assertIs(repair.preserve_reference_range(rr), rr)
            for value in (float('nan'), float('inf'), object(), {1, 2}):
                rr = loaded_rows(); target(rr, key)['casts'] = value
                self.assertIs(repair.preserve_reference_range(rr), rr)
        # bools/floats are not silently equivalent to reviewed integer facts.
        for field, value in [('castsWithDrop', True), ('totalQuantity', 2.0)]:
            rr = loaded_rows(); target(rr)[field] = value
            self.assertIs(repair.preserve_reference_range(rr), rr)

    def test_missing_and_duplicate_identities_fail_closed(self):
        for key in (TARGET, CANONICAL):
            rr = [r for r in loaded_rows() if r['id'] != key]
            self.assertIs(repair.preserve_reference_range(rr), rr)
            rr = loaded_rows(); rr.append(copy.deepcopy(target(rr, key)))
            self.assertIs(repair.preserve_reference_range(rr), rr)
        self.assertEqual(repair.preserve_reference_range([]), [])

    def test_reordered_rows_and_keys_are_equivalent(self):
        rr = list(reversed(loaded_rows()))
        rr = [dict(reversed(list(r.items()))) for r in rr]
        target(rr)['source'] = dict(reversed(list(target(rr)['source'].items())))
        result = repair.preserve_reference_range(rr)
        self.assertEqual([r['id'] for r in result], [r['id'] for r in rr])
        self.assertEqual((target(result)['minSeen'], target(result)['maxSeen']), (2, 2))

    def test_already_corrected_upstream_and_different_ranges_are_untouched(self):
        for lo, hi in [(2, 2), (1, 3), (None, 2), (2, None), (0, 0)]:
            rr = loaded_rows(); target(rr).update(minSeen=lo, maxSeen=hi)
            self.assertIs(repair.preserve_reference_range(rr), rr)
        rr = loaded_rows(); target(rr)['id'] = 'upstream-replacement'
        target(rr, 'upstream-replacement')['replaces'] = TARGET
        self.assertIs(repair.preserve_reference_range(rr), rr)

    def test_unrelated_rows_cannot_claim_repair_and_are_unchanged(self):
        rr = loaded_rows(); alias = copy.deepcopy(target(rr))
        alias.update(id='unreviewed-alias', studyKey='unreviewed', minSeen=9,
                     repairAs=TARGET, minSeenOverride=2)
        rr.append(alias)
        result = repair.preserve_reference_range(rr)
        self.assertIs(result[-1], alias)
        self.assertEqual(result[-1]['minSeen'], 9)
        rr.remove(target(rr))
        self.assertIs(repair.preserve_reference_range(rr), rr)

    def test_actual_loader_replacements_precede_repair(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            shutil.copytree(PIN/'research/v3/tools', root/'research/v3/tools')
            for name in ('corrections.jsonl', 'conditions.jsonl', 'rate-changes.jsonl'):
                (root/'research/v3'/name).write_text('')
            meta = json.loads((FIXTURE/'SOURCES.json').read_text())
            for name, info in meta['files'].items():
                p = root/info['path']; p.parent.mkdir(parents=True, exist_ok=True)
                p.write_bytes((FIXTURE/name).read_bytes())
            module = adapter.load_calculator(root)
            rr = module.load()
            self.assertNotIn('legacy-20261110-24702', {r['id'] for r in rr})
            self.assertEqual(target(rr)['minSeen'], None)
            self.assertEqual(target(repair.preserve_reference_range(rr))['minSeen'], 2)
            # An upstream replacement suppresses the target; never resurrect it.
            replacement = dict(target(rr), id='upstream-repair', replaces=TARGET,
                               minSeen=2, maxSeen=2)
            (root/'research/v3/evidence/upstream.jsonl').write_text(json.dumps(replacement)+'\n')
            rr = module.load()
            self.assertNotIn(TARGET, {r['id'] for r in rr})
            self.assertIs(repair.preserve_reference_range(rr), rr)

    def test_range_pass_only_no_count_or_study_roles(self):
        module = adapter.load_calculator(PIN)
        rr = loaded_rows(); fixed = repair.preserve_reference_range(rr)
        self.assertEqual([r for r in rr if adapter.is_counted(r, module)],
                         [r for r in fixed if adapter.is_counted(r, module)])
        _, _, usage = module.analyze(fixed)
        u = usage[id(target(fixed))]
        self.assertFalse(u['used']); self.assertTrue(u['range'])
        self.assertEqual(u['reason'], 'reference:noUsableValue')
        calls = []; original = module.build
        def observe(rows):
            calls.append(copy.deepcopy(rows)); return original(rows)
        with patch.object(module, 'load', return_value=rr), patch.object(module, 'build', side_effect=observe), patch.object(adapter, 'load_calculator', return_value=module):
            adapter.build(PIN)
        self.assertEqual(len(calls), 2)
        self.assertEqual(target(calls[0])['minSeen'], 2)
        self.assertNotIn(TARGET, {r['id'] for r in calls[1]})
        self.assertEqual(target(rr)['minSeen'], None)

    def test_consumed_pin_noop_and_fixture_quote(self):
        module = adapter.load_calculator(PIN); rr = module.load()
        self.assertIs(repair.preserve_reference_range(rr), rr)
        self.assertEqual(target(loaded_rows())['quote'], target(loaded_rows(), CANONICAL)['quote'])
        self.assertEqual(target(raw_rows(), 'legacy-20261110-24702')['minSeen'], 2)


if __name__ == '__main__': unittest.main()
