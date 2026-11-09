"""Candidate fallback is not an additional direct vendor inventory."""
import hashlib
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import research_v3_tokens as tokens

FIXTURES = ROOT / 'tests/fixtures/curio-direct-enumeration'
PINNED = ROOT / 'database/research/v3-snapshot'
MANIFEST = json.loads((FIXTURES / 'manifest.json').read_text())
STAGED = tokens.load_staged([ROOT / path for path in tokens.STAGED])


def build(path, staged=STAGED):
    return tokens.build_tokens(path, 'fixture', staged=staged)


def row(ids=(101, 102), complete=True, **extra):
    return dict({'id': 'source', 'type': 'token', 'tokenItemID': 100,
                 'source': {'url': 'https://example.org/direct'}, 'howRedeemed': 'vendor',
                 'listComplete': complete,
                 'rewards': [{'itemID': i, 'name': str(i)} for i in ids]}, **extra)


class StagedFallbackTests(unittest.TestCase):
    def test_pinned_records_and_notes_unchanged(self):
        records, notes, conflicts = build(PINNED)
        payload = json.dumps([records, dict(notes), conflicts], sort_keys=True, separators=(',', ':')).encode()
        self.assertEqual(len(records), 237)
        self.assertEqual(hashlib.sha256(payload).hexdigest(), MANIFEST['pinnedGeneratorSHA256'])
        by_id = {r['tokenID']: r for r in records}
        self.assertEqual(len(by_id[237602]['rewards']), 85)
        self.assertEqual(len(by_id[270909]['rewards']), 65)

    def test_immutable_future_source_enumeration(self):
        before, _, _ = build(PINNED)
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp)
            shutil.copytree(PINNED / 'research', path / 'research')
            for source in MANIFEST['files']:
                raw = (FIXTURES / source['name']).read_bytes()
                self.assertEqual(hashlib.sha256(raw).hexdigest(), source['sha256'])
                target = path / source['path']
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(raw)
            after, _, _ = build(path)
        old, new = ({r['tokenID']: r for r in rows} for rows in (before, after))
        self.assertEqual([i for i in old if old[i] != new[i]], [270909])
        curio = new[270909]
        self.assertEqual(curio['rewards'], list(range(270910, 270930)))
        self.assertTrue(curio['candidateRewards'])
        self.assertFalse(curio['costsComplete'])
        self.assertFalse(curio['listComplete'])
        self.assertFalse(curio['requirementsReviewed'])
        self.assertEqual(curio['independentReview'], 'NOT_REVIEWED')
        self.assertEqual(curio['confidence0to100'], 20)
        self.assertNotIn('costs', curio)
        self.assertNotIn('rewardLinks', curio)
        self.assertIn('Source-enumerated possible direct rewards', curio['sourceAssumption'])

    def synthetic(self, rows, candidate=True, corrections=None):
        staged = {100: {'sources': ['https://example.org/staged'],
                        'byName': {'candidate': (999, ['https://example.org/candidate'])}}}
        if candidate:
            staged[100]['candidateOnly'] = True
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            path = root / 'research/v3/evidence/test.jsonl'
            path.parent.mkdir(parents=True)
            path.write_text(''.join(json.dumps(r) + '\n' for r in rows))
            if corrections:
                (root / 'research/v3/corrections.jsonl').write_text(json.dumps(corrections) + '\n')
            return build(root, staged)[0]

    def test_complete_source_and_subset_note(self):
        result = self.synthetic([row(), row((101,), False, id='partial'), row((), None, id='cost')])[0]
        self.assertEqual(result['rewards'], [101, 102])
        self.assertTrue(result['candidateRewards'])
        self.assertEqual(result['confidence0to100'], 20)

    def test_partial_empty_and_unknown_enumeration_keep_fallback(self):
        for rows in [[row((101,), False)], [row((), True)], [row((), None)],
                     [row((101, None), True)], [row(), row((None,), False, id='unknown')]]:
            with self.subTest(rows=rows):
                self.assertIn(999, self.synthetic(rows)[0]['rewards'])

    def test_contradictory_enumerations_keep_fallback(self):
        for rows in [[row(), row((101, 103), True, id='conflict')],
                     [row(), row((103,), False, id='outside')],
                     [row((101, 101), True)], [row((100, 101), True)],
                     [row(), row((), True, id='empty_complete')]]:
            with self.subTest(rows=rows):
                self.assertIn(999, self.synthetic(rows)[0]['rewards'])

    def test_conflicting_name_identity_keeps_fallback(self):
        first, second = row(), row(id='conflict')
        second['rewards'][0]['name'] = '102'
        second['rewards'][1]['name'] = '101'
        self.assertIn(999, self.synthetic([first, second])[0]['rewards'])

    def test_identical_complete_sets_ignore_order(self):
        result = self.synthetic([row(), row((102, 101), True, id='same')])[0]
        self.assertEqual(result['rewards'], [101, 102])

    def test_excluded_or_replaced_complete_row_cannot_suppress(self):
        for rows, corrections in [
            ([row(), row((), None, id='note')], {'recordID': 'source', 'field': 'exclude', 'value': True}),
            ([row(), row((101,), False, id='replacement', replaces='source')], None)]:
            self.assertIn(999, self.synthetic(rows, corrections=corrections)[0]['rewards'])

    def test_non_candidate_staged_enrichment_unchanged(self):
        result = self.synthetic([row()], candidate=False)[0]
        self.assertEqual(result['rewards'], [101, 102, 999])

    def test_strict_identity_guard(self):
        for value in [True, False, 0, -1, '101', 1.5, None]:
            self.assertFalse(tokens.has_consistent_direct_enumeration([row((value,))]))
        for rewards in ['invalid', [101], [{'name': 'unknown'}]]:
            source = row(); source['rewards'] = rewards
            self.assertFalse(tokens.has_consistent_direct_enumeration([source]))


if __name__ == '__main__':
    unittest.main()
