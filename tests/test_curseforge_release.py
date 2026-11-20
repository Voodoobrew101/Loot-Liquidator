"""Exercise release channels, package identity, and upload failure handling offline."""
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('release', Path(__file__).resolve().parents[1] / 'tools/curseforge_release.py')
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


class ReleaseTests(unittest.TestCase):
    def test_channels(self):
        for tag, kind in [('v1.2.3', 'release'), ('1.2.3', 'release'), ('v1.2.3-alpha.1', 'alpha'), ('v1.2.3-beta.2', 'beta'), ('v1.2.3-rc.1', 'beta')]:
            with self.subTest(tag=tag):
                self.assertEqual(release.release_version(tag), (tag.removeprefix('v'), kind))

    def test_reject_invalid_tags(self):
        for tag in ['build-123', 'v1.2', 'v01.2.3', 'v1.2.3\n', 'v1.2.3-test', 'v1.2.3;echo secret']:
            with self.subTest(tag=tag), self.assertRaises(ValueError):
                release.release_version(tag)

    def fixture(self, root):
        (root / 'LootLiquidator').mkdir()
        (root / 'LootLiquidator/LootLiquidator.toc').write_text('## Interface: 120100, 120105\n## Version: 0.0.1\nCore.lua\n')
        (root / 'LootLiquidator/Core.lua').write_text('LA.version = "0.0.1"\n')
        return release.prepare('v1.2.3-alpha.1', root)

    def test_prepare_stamps_both_versions_and_maps_interfaces(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            metadata = self.fixture(root)
            self.assertEqual(metadata['gameVersionNames'], ['12.1.0', '12.1.5'])
            self.assertEqual(metadata['releaseType'], 'alpha')
            self.assertIn('## Version: 1.2.3-alpha.1', (root / 'LootLiquidator/LootLiquidator.toc').read_text())
            self.assertIn('LA.version = "1.2.3-alpha.1"', (root / 'LootLiquidator/Core.lua').read_text())
            self.assertEqual(json.loads((root / 'dist/curseforge-metadata.json').read_text()), metadata)

    def test_missing_or_ambiguous_game_version_fails(self):
        for versions in [[], [{'id': 1, 'name': '12.1.0'}, {'id': 2, 'name': '12.1.0'}]]:
            with self.assertRaises(ValueError):
                release.resolve_versions({'gameVersionNames': ['12.1.0']}, versions)

    def test_missing_token_does_not_send_request(self):
        with patch.dict(os.environ, {}, clear=True), patch.object(release, 'request_json') as request:
            with self.assertRaisesRegex(ValueError, 'CURSEFORGE_API_TOKEN'):
                release.upload()
            request.assert_not_called()

    def test_upload_sends_one_post_with_resolved_versions_and_file(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            self.fixture(root)
            (root / 'dist/LootLiquidator.zip').write_bytes(b'zip-fixture')
            versions = [{'id': 10, 'name': '12.1.0'}, {'id': 20, 'name': '12.1.5'}]
            with patch.dict(os.environ, {'CURSEFORGE_API_TOKEN': 'test-token'}), patch.object(release, 'request_json', side_effect=[versions, {'id': 123}]) as request:
                self.assertEqual(release.upload(root), 123)
                self.assertEqual(request.call_count, 2)
                path, token, body, content_type = request.call_args.args
                self.assertEqual(path, '/projects/1760478/upload-file')
                self.assertIn(b'"gameVersions": [10, 20]', body)
                self.assertNotIn(b'gameVersionNames', body)
                self.assertIn(b'zip-fixture', body)
                self.assertNotIn(token.encode(), body)
                self.assertTrue(content_type.startswith('multipart/form-data; boundary='))

    def test_failed_post_is_not_retried(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            self.fixture(root)
            (root / 'dist/LootLiquidator.zip').write_bytes(b'zip-fixture')
            versions = [{'id': 10, 'name': '12.1.0'}, {'id': 20, 'name': '12.1.5'}]
            with patch.dict(os.environ, {'CURSEFORGE_API_TOKEN': 'test-token'}), patch.object(release, 'request_json', side_effect=[versions, ValueError('timeout')]) as request:
                with self.assertRaises(ValueError):
                    release.upload(root)
                self.assertEqual(request.call_count, 2)


if __name__ == '__main__':
    unittest.main()
