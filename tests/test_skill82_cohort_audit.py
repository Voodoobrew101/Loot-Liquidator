"""Regression checks for archived facts, not approval of numerical baselines."""
import copy
import json
import sys
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import audit_skill82_cohorts as gate
from validate_craft_export import compile_baselines


class Skill82AuditTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root = gate.DEFAULT_ROOT
        cls.bundle = {}
        archive = cls.root / 'research/integration/measured-captures'
        for suffix in gate.PINS:
            p = archive / ('2026-11-07-pr49-' + suffix)
            cls.bundle[suffix] = {
                'raw': json.loads((p / 'export-page-1.json').read_text()),
                'staged': json.loads((p / 'staged-baselines.json').read_text()),
                'files': {},
            }
        comp = archive / '2026-11-07-pr49-104-skill-199-casts'
        cls.bundle['comparison'] = json.loads((comp / 'reviewed-comparison.json').read_text())
        cls.bundle['completeReview'] = json.loads((comp / 'complete-batch-review.json').read_text())
        cls.evidence = [json.loads(line) for line in (cls.root / gate.FIXTURE_PATH).read_text().splitlines()]

    def test_full_pinned_gate_and_exact_histograms(self):
        result = gate.audit()
        self.assertEqual(len(result['groups']), 8)
        self.assertEqual(result['reconciliation']['allCleanSkill82'], 405)
        self.assertTrue(all(result['gates'].values()))
        self.assertEqual(sum(g['casts'] for g in result['groups']), 394)
        for g in result['groups']:
            self.assertEqual(sum(m['totalQuantity'] for m in g['outputs'].values()), g['casts'])
            for m in g['outputs'].values():
                self.assertEqual(sum(m['histogram'].values()), g['casts'])

    def test_cli_outside_checkout_and_optimized_python(self):
        with tempfile.TemporaryDirectory() as d:
            output = Path(d) / 'report.json'
            subprocess.run([sys.executable, '-O', str(self.root / 'tools/audit_skill82_cohorts.py'),
                            '--output', str(output)], cwd=d, check=True, capture_output=True)
            self.assertEqual(json.loads(output.read_text())['reconciliation']['allCleanSkill82'], 405)

    def test_raw_and_review_pins_fail_closed(self):
        for pins, name in [(gate.PINS, '82-skill-194-update'),
                           (gate.REVIEW_PINS, 'reviewed-comparison.json'),
                           (gate.REVIEW_PINS, 'complete-batch-review.json')]:
            with self.subTest(name=name), patch.dict(pins, {name: '0' * 64}):
                with self.assertRaisesRegex(ValueError, 'hash'):
                    gate.audit()

    def test_research_fixture_pin_fails_closed(self):
        with tempfile.TemporaryDirectory() as d:
            fixture = Path(d) / 'changed.jsonl'
            fixture.write_bytes((self.root / gate.FIXTURE_PATH).read_bytes() + b'\n')
            with self.assertRaisesRegex(ValueError, 'fixture hash'):
                gate.audit(fixture=fixture)

    def reject_semantic_mutation(self, mutate, restage=False):
        # This entry deliberately bypasses byte pins. If source bytes were
        # re-pinned, the independently meaningful data contracts still reject.
        bundle, evidence = copy.deepcopy(self.bundle), copy.deepcopy(self.evidence)
        mutate(bundle, evidence)
        with self.assertRaises((ValueError, KeyError, StopIteration)):
            if restage:
                for suffix in gate.PINS:
                    bundle[suffix]['staged'] = compile_baselines([bundle[suffix]['raw']])
            gate.verify_measurements(bundle, evidence)

    def test_references_cannot_be_promoted_or_recounted(self):
        for key, value in [('sourceKind', 'study'), ('casts', 394), ('outputRank', 2),
                           ('inputRank', 1), ('stats', []), ('minSeen', 0)]:
            with self.subTest(key=key):
                self.reject_semantic_mutation(lambda b, e: e[0].update({key: value}))
        self.reject_semantic_mutation(lambda b, e: e.__setitem__(1, copy.deepcopy(e[0])))
        self.reject_semantic_mutation(lambda b, e: e[0]['histogram'].update({'0': 0}))

    def test_context_output_rank_and_input_variant_are_not_interchangeable(self):
        suffix = '82-skill-194-update'
        changes = [
            lambda p: p['contexts']['context:78'].update(effectiveSkill=104),
            lambda p: p['contexts']['context:78'].update(operationStats=[]),
            lambda p: p['contexts']['context:78'].update(specialization='invented'),
            lambda p: p['records'][0]['outputs'][0].update(qualityRank=9),
            lambda p: p['records'][0]['inputs'][0].update(itemLevel=166),
            lambda p: p['records'][0].update(build='99999'),
            lambda p: p['records'][0].update(operationID='synthetic-new-id'),
        ]
        for i, change in enumerate(changes):
            with self.subTest(change=i):
                self.reject_semantic_mutation(lambda b, e: change(b[suffix]['raw']), restage=True)

    def test_recipe_and_global_gaps_exclude_but_unrelated_craft_gap_does_not(self):
        for suffix in ('82-skill-194-update', '82-skill-200-additional'):
            original = self.bundle[suffix]['raw']
            self.assertEqual(sum(b['operations'] for b in compile_baselines([original])['baselines']),
                             len(original['records']))
            for gap in ('recipe', 'global', 'truncated'):
                page = copy.deepcopy(original)
                for study in page['studies'].values():
                    if gap == 'recipe':
                        study.update(censored=True, coverageVersion=2,
                                     coverageGaps={'Disenchant:13262': {'reason': 'synthetic audit gap'}})
                    elif gap == 'global':
                        study['globalCoverageGap'] = True
                    else:
                        study['truncated'] = True
                with self.subTest(source=suffix, gap=gap):
                    self.assertEqual(compile_baselines([page])['baselines'], [])

    def test_104_censor_cannot_be_imputed_or_changed_to_199(self):
        changes = [
            lambda b, e: b['comparison'].update(operatorConfirmedCompletedCasts=199),
            lambda b, e: b['comparison'].update(fullBatchR2PointEstimate=20/199),
            lambda b, e: b['comparison'].update(fullBatchQuantityDistribution={'1': 200}),
            lambda b, e: b['comparison']['R2OutputIncidenceBounds'].update(denominator=199),
            lambda b, e: b['completeReview']['unclassifiedResult'].update(outputRanks=[2]),
            lambda b, e: b['completeReview'].update(runtimePromotion=True),
            lambda b, e: b['completeReview']['classifiedNativeRecordIDs'].pop(),
            lambda b, e: e[16].update(histogram={'0': 21, '1': 179}),
            lambda b, e: e[17].update(totalQuantity=21),
        ]
        for i, change in enumerate(changes):
            with self.subTest(change=i):
                self.reject_semantic_mutation(change)


if __name__ == '__main__':
    unittest.main()
