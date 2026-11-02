"""Research refresh includes calculator dependencies and isolates their imports."""
import io
from pathlib import Path
import sys
import tarfile
import tempfile
import types
import unittest
from unittest.mock import patch

sys.path.insert(0, 'tools')
import research_v3_to_baselines as v3


class SnapshotTests(unittest.TestCase):
    def make_snapshot(self, root, label):
        folder = root / 'research/v3/tools'
        folder.mkdir(parents=True)
        (folder / 'source_keys.py').write_text(f'def normalize_url(value): return {label!r} + value\n')
        (folder / 'build_estimates.py').write_text(
            'from source_keys import normalize_url\n'
            'def apply_corrections(rows): return rows\n')
        return folder

    def test_pinned_helper_isolated_between_snapshots_and_caller(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            self.make_snapshot(root / 'first', 'first:')
            self.make_snapshot(root / 'second', 'second:')
            caller = types.ModuleType('source_keys')
            caller.normalize_url = lambda value: 'caller:' + value
            old_path = sys.path[:]
            with patch.dict(sys.modules, {'source_keys': caller}):
                first = v3.load_calculator(root / 'first')
                second = v3.load_calculator(root / 'second')
                self.assertEqual(first.normalize_url('x'), 'first:x')
                self.assertEqual(second.normalize_url('x'), 'second:x')
                self.assertIs(sys.modules['source_keys'], caller)
                self.assertEqual(sys.path, old_path)

    def test_refresh_archives_calculator_dependency_and_loads_it(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            folder = self.make_snapshot(root / 'source', 'pinned:')
            archive = io.BytesIO()
            with tarfile.open(fileobj=archive, mode='w') as tar:
                for file in folder.iterdir():
                    tar.add(file, arcname=file.relative_to(root / 'source').as_posix())
            def git(args, **kwargs):
                if args[1] == 'rev-parse': return 'a' * 40
                if args[1] == 'show': return '2026-11-01T00:00:00Z'
                self.assertIn('research/v3/tools', args)
                return archive.getvalue()
            with patch.object(v3.subprocess, 'check_output', side_effect=git):
                v3.refresh('origin/research-fixture', root / 'snapshot')
            module = v3.load_calculator(root / 'snapshot')
            self.assertEqual(module.normalize_url('x'), 'pinned:x')

    def test_failed_import_restores_caller_state(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            folder = self.make_snapshot(root, 'broken:')
            (folder / 'build_estimates.py').write_text('from source_keys import normalize_url\nraise RuntimeError("fixture")\n')
            old_path = sys.path[:]
            caller = types.ModuleType('source_keys')
            with patch.dict(sys.modules, {'source_keys': caller}):
                with self.assertRaisesRegex(RuntimeError, 'fixture'):
                    v3.load_calculator(root)
                self.assertIs(sys.modules['source_keys'], caller)
                self.assertEqual(sys.path, old_path)


if __name__ == '__main__':
    unittest.main()
