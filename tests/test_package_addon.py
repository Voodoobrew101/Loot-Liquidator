"""E4: package CLI help is read-only and valid builds contain only runtime files."""
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import zipfile

SCRIPT = Path(__file__).resolve().parent.parent / 'tools/package_addon.py'


class PackageCLI(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.TemporaryDirectory()
        self.addCleanup(self.folder.cleanup)
        self.root = Path(self.folder.name)

    def run_tool(self, *args):
        return subprocess.run([sys.executable, str(SCRIPT), *args], cwd=self.root,
                              capture_output=True, text=True)

    def test_help_needs_no_addon_and_writes_nothing(self):
        result = self.run_tool('--help')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('usage:', result.stdout)
        self.assertIn('output', result.stdout)
        self.assertEqual(list(self.root.iterdir()), [])

    def test_missing_output_has_clear_usage_and_writes_nothing(self):
        result = self.run_tool()
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn('usage:', result.stderr)
        self.assertIn('output', result.stderr)
        self.assertNotIn('Traceback', result.stderr)
        self.assertEqual(list(self.root.iterdir()), [])

    def test_help_does_not_create_a_zip_named_help(self):
        addon = self.root / 'LootLiquidator'
        addon.mkdir()
        (addon / 'LootLiquidator.toc').write_text('## Title: Test\n')
        before = set(self.root.rglob('*'))
        result = self.run_tool('--help')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('usage:', result.stdout)
        self.assertEqual(set(self.root.rglob('*')), before)

    def test_valid_build_keeps_manifest_files_and_excludes_development_files(self):
        addon = self.root / 'LootLiquidator'
        addon.mkdir()
        toc = b'## Interface: 120105\n## Title: Test\nCore.lua\n'
        core = b'local ADDON, LL = ...\n'
        (addon / 'LootLiquidator.toc').write_bytes(toc)
        (addon / 'Core.lua').write_bytes(core)
        (addon / 'developer-notes.txt').write_text('Do not ship this')
        output = self.root / 'dist/test.zip'
        result = self.run_tool(str(output))
        self.assertEqual(result.returncode, 0, result.stderr)
        with zipfile.ZipFile(output) as archive:
            self.assertIsNone(archive.testzip())
            self.assertEqual(set(archive.namelist()), {'LootLiquidator/LootLiquidator.toc', 'LootLiquidator/Core.lua'})
            self.assertEqual(archive.read('LootLiquidator/LootLiquidator.toc'), toc)
            self.assertEqual(archive.read('LootLiquidator/Core.lua'), core)


if __name__ == '__main__':
    unittest.main()
