"""Build-time research review preserves evidence and needs no routine PR."""
from collections import Counter
from hashlib import sha256
import json
from pathlib import Path
import shutil
import sys
import tempfile
import types
import unittest
import warnings
from unittest.mock import patch

sys.path.insert(0, 'tools')
import prepare_build_research as prepare
import research_build_review as review
import research_v3_to_baselines as v3


class BuildResearchTests(unittest.TestCase):
    def setUp(self):
        # The immutable vendored calculator uses open() iteration without a
        # context manager; its ResourceWarnings are unrelated to this adapter.
        caught = warnings.catch_warnings()
        caught.__enter__()
        warnings.simplefilter('ignore', ResourceWarning)
        self.addCleanup(caught.__exit__, None, None, None)

    def snapshot(self, root):
        snapshot = root / 'snapshot'
        folder = snapshot / 'research/v3'
        shutil.copytree(v3.DEFAULT_SNAPSHOT / 'research/v3/tools', folder / 'tools')
        (folder / 'evidence').mkdir()
        base = {'id': 'counts', 'type': 'drop', 'method': 'Disenchant', 'inputItemID': 100,
                'outputItemID': 200, 'inputsPerCast': 1, 'casts': 10, 'castsWithDrop': 4,
                'totalQuantity': 8, 'minSeen': 2, 'maxSeen': 2, 'cohortKey': 'fixture-counted-cohort',
                'sourceKind': 'comment', 'source': {'url': 'https://www.wowhead.com/item=100', 'author': 'fixture'},
                'dataDate': '2026-11-01', 'patch': '12.1.5'}
        rows = [base, dict(base, id='same-cohort-copy'),
                dict(base, id='published', inputItemID=101, outputItemID=201,
                     cohortKey='fixture-published', casts=None, castsWithDrop=None, totalQuantity=None,
                     averageShown=2.5, averagePer='cast'),
                dict(base, id='invalid-item', inputItemID=-1), dict(base, id='held', inputItemID=102),
                {'id': 'metadata', 'type': 'note', 'text': 'Archived context'}]
        (folder / 'evidence/fixture.jsonl').write_text(''.join(json.dumps(row) + '\n' for row in rows))
        (folder / 'corrections.jsonl').write_text(json.dumps({'recordID': 'held', 'field': 'exclude', 'value': True}) + '\n')
        for name in ('conditions.jsonl', 'rate-changes.jsonl'):
            (folder / name).write_text('')
        (snapshot / 'SNAPSHOT.json').write_text(json.dumps({'branch': 'durable-fixture', 'commit': 'a' * 40,
            'committed': '2026-11-01T00:00:00Z', 'paths': v3.SNAPSHOT_PATHS}))
        return snapshot

    def test_invalid_explicit_ids_are_classified_without_rewriting_rows(self):
        good = {'inputItemID': 1, 'outputItemID': 2, 'recipeID': 3}
        unknown = {'inputName': 'Source-resolvable family'}
        bad = [{'inputItemID': value} for value in (True, 0, -1, 1.5, 2**53)]
        rows = [good, unknown, *bad]
        before = json.dumps(rows)
        admitted, notes = review.automatic_admission(rows)
        self.assertEqual(admitted, [good, unknown])
        self.assertEqual(sum(notes.values()), len(bad))
        self.assertEqual(json.dumps(rows), before)

    def test_admission_is_on_the_actual_baseline_build_path(self):
        good = {'id': 'good', 'inputItemID': 1}
        bad = {'id': 'bad', 'inputItemID': False}
        calculator = types.SimpleNamespace(load=lambda: [good, bad], name_maps=lambda rows: {},
            evidence_load_notes=Counter(), REFERENCE_KINDS=set())
        with patch.object(v3, 'load_calculator', return_value=calculator), \
             patch.object(v3, 'resolve_ranked_outputs', side_effect=lambda rows: rows), \
             patch.object(v3, 'preserve_reference_range', side_effect=lambda rows: rows), \
             patch.object(v3, 'retail_admission', side_effect=lambda rows: (rows, Counter())), \
             patch.object(v3, 'load_families', return_value={}), \
             patch.object(v3, 'reference_ranges', return_value={}), \
             patch.object(v3, 'build_field_support', return_value=([], Counter(), 0)) as support:
            records, notes, _, counted, _ = v3.build(Path('fixture'))
        self.assertEqual(records, [])
        self.assertEqual(counted, 1)
        self.assertEqual(support.call_args.args[1], [good])
        self.assertTrue(any(reason.startswith('Automatic admission:') for reason in notes))

    def test_review_and_generation_are_deterministic_and_keep_real_denominators(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            snapshot = self.snapshot(root)
            before = {path.relative_to(snapshot).as_posix(): path.read_bytes()
                      for path in snapshot.rglob('*') if path.is_file()}
            first = review.write_review(snapshot, root / 'review.json', root / 'no-local-evidence')
            rendered = (root / 'review.json').read_bytes()
            second = review.write_review(snapshot, root / 'review.json', root / 'no-local-evidence')
            self.assertEqual(first, second)
            self.assertEqual((root / 'review.json').read_bytes(), rendered)
            self.assertEqual(first, review.write_review(snapshot, root / 'review.json', root / 'no-local-evidence', check=True))
            self.assertEqual(first['reviewedRows'], 6)
            self.assertFalse(first['independentScientificApproval'])
            report = json.loads(rendered)
            by_id = {row['recordID']: row for row in report['rows']}
            self.assertEqual(by_id['invalid-item']['disposition'], 'HELD_INVALID_IDENTITY')
            self.assertEqual(by_id['held']['disposition'], 'PRESERVED_CORRECTED_OR_HELD')
            self.assertEqual(by_id['metadata']['disposition'], 'PRESERVED_METADATA')
            self.assertEqual(by_id['published']['disposition'], 'ADMITTED_TO_BASELINE_PIPELINE')
            self.assertNotIn('samples', by_id['published'])
            records, *_ = v3.build(snapshot)
            counted = next(record for record in records if record.get('inputItemID') == 100)['materials'][0]
            published = next(record for record in records if record.get('inputItemID') == 101)['materials'][0]
            self.assertAlmostEqual(counted['expectedQuantity']['value'], .8)
            self.assertEqual(counted['expectedQuantity']['samples'], 10 * v3.NOT_BASELINE_FACTOR)
            self.assertEqual(published['expectedQuantity']['value'], 2.5)
            self.assertEqual(published['expectedQuantity']['samples'], 0)
            self.assertFalse(published['expectedQuantity']['sampleSizeKnown'])
            self.assertEqual(before, {path.relative_to(snapshot).as_posix(): path.read_bytes()
                                      for path in snapshot.rglob('*') if path.is_file()})

    def test_prepare_build_pins_one_ref_and_never_publishes_source_changes(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / 'database/research/v3-snapshot').mkdir(parents=True)
            source = {'commit': 'b' * 40, 'branch': 'durable-source'}
            (root / 'database/research/v3-snapshot/SNAPSHOT.json').write_text(json.dumps(source))
            (root / 'LootLiquidator').mkdir()
            runtime = b'compiled fixture database'
            (root / 'LootLiquidator/ItemDBRuntime.lua').write_bytes(runtime)
            commands = []
            previous = Path.cwd()
            summary = {'reviewedRows': 6, 'baselineRecords': 2, 'policy': review.POLICY}
            with patch.object(prepare.v3, 'refresh') as refresh, \
                 patch.object(prepare.research_build_review, 'write_review', return_value=summary):
                result = prepare.prepare('exact-source-ref', ['lua-fixture'],
                    run=lambda command, **kwargs: commands.append(command), root=root)
            refresh.assert_called_once_with('exact-source-ref', v3.DEFAULT_SNAPSHOT)
            self.assertEqual(Path.cwd(), previous)
            self.assertEqual(result['researchSnapshot'], source)
            self.assertEqual(result['runtimeSHA256'], sha256(runtime).hexdigest())
            self.assertFalse(result['automaticPullRequests'])
            self.assertNotIn('nativeGatheringReview', result)
            self.assertTrue(any(command[0] == 'lua-fixture' and command[1] == 'tools/compile_itemdb.lua' for command in commands))
            self.assertFalse(any('gathering' in part.lower() for command in commands for part in command))
            self.assertFalse(any(command[0] in {'git', 'gh'} for command in commands))
            self.assertTrue(any('tools/specialization_effects.py' in command for command in commands))
            self.assertTrue(any('tools/disenchant_categories.py' in command for command in commands))

    def test_automatic_research_and_version_push_are_removed(self):
        self.assertFalse(Path('.github/workflows/research-refresh.yml').exists())
        self.assertFalse(Path('.github/workflows/addon-version.yml').exists())
        self.assertFalse(Path('tools/update_addon_version.py').exists())
        distribution = Path('.github/workflows/distribution.yml').read_text()
        self.assertIn('pull_request:', distribution)
        self.assertIn('workflow_dispatch:', distribution)
        self.assertIn('if: inputs.publish', distribution)
        self.assertIn('git rev-parse FETCH_HEAD', distribution)
        self.assertIn('build-research-manifest.json', distribution)
        for file in ('docs/master-prompts/directors/research-manager.md', 'docs/research-manager/OPERATING-INSTRUCTIONS.md'):
            text = Path(file).read_text()
            self.assertIn('Do not open automatic or routine PRs for those data updates.', text)
            self.assertIn('Code, schema and CI changes still use explicitly initiated feature PRs', text)


if __name__ == '__main__':
    unittest.main()
