import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path('tools').resolve()))
from capture_observations import compile_observations


class CaptureObservationsTests(unittest.TestCase):
    def setUp(self):
        self.source = Path('research/integration/measured-captures/2026-11-06-disenchants')

    def test_owner_capture_identities_are_shared_without_inventing_rates(self):
        result = compile_observations(self.source.parent)
        self.assertEqual(sum(r['observedOperations'] for r in result['processing']), 42)
        self.assertTrue(all(r['studyCoverageIncomplete'] for r in result['processing']))
        for r in result['processing']:
            self.assertEqual(r['method'], 'Disenchant')
            self.assertTrue(r['sourceRecordIDs'])
            for m in r['materials']:
                for key in ('expectedQuantity', 'dropChance', 'minQuantity', 'maxQuantity'):
                    self.assertEqual(m[key], {'status': 'unknown', 'confidence': 0})

    def test_reexport_counts_once(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            for label in ('original', 'reexport'):
                folder = root / label
                folder.mkdir()
                for p in self.source.glob('cast-page-*.json'):
                    (folder / p.name).write_bytes(p.read_bytes())
            result = compile_observations(root)
            self.assertEqual(sum(r['observedOperations'] for r in result['processing']), 42)

    def test_incomplete_export_cannot_silently_build(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            folder = root / 'missing-page'
            folder.mkdir()
            p = self.source / 'cast-page-1.json'
            (folder / p.name).write_bytes(p.read_bytes())
            with self.assertRaisesRegex(ValueError, 'All pages'):
                compile_observations(root)

    def test_contradictory_reexport_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            for label in ('original', 'changed'):
                folder = root / label
                folder.mkdir()
                for p in self.source.glob('cast-page-*.json'):
                    data = json.loads(p.read_text())
                    if label == 'changed' and data['page'] == 2:
                        data['records'][0]['outputs'][0]['quantity'] += 1
                    (folder / p.name).write_text(json.dumps(data))
            with self.assertRaisesRegex(ValueError, 'Conflicting capture'):
                compile_observations(root)


if __name__ == '__main__':
    unittest.main()
