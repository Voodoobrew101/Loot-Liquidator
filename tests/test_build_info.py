import sys
import unittest
import hashlib
import json
import tempfile
import os
from unittest.mock import patch
from pathlib import Path
sys.path.insert(0, str(Path('tools').resolve()))
from stamp_build_info import collect, verified_release, stamp


class BuildInfoTests(unittest.TestCase):
    def test_provenance_is_written_offline_without_runtime_module(self):
        previous = Path.cwd()
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'LootLiquidator').mkdir()
            runtime = root / 'LootLiquidator/ItemDBRuntime.lua'
            original = b'-- immutable compiled test data\n'
            runtime.write_bytes(original)
            info = {'kind': 'local', 'commit': 'test-source', 'prs': []}
            try:
                os.chdir(root)
                with patch('stamp_build_info.collect', return_value=info):
                    stamp()
                self.assertEqual(json.loads(Path('dist/build-info.json').read_text()), info)
                self.assertEqual(runtime.read_bytes(), original)
                self.assertFalse(Path('LootLiquidator/BuildInfo.lua').exists())
            finally:
                os.chdir(previous)

    def test_verified_tag_accepts_only_generated_research_and_version_changes(self):
        env = {'GITHUB_ACTIONS': 'true', 'GITHUB_REF': 'refs/tags/v0.12.46', 'GITHUB_REF_NAME': 'v0.12.46'}
        changed = ['database/research/build-research-manifest.json', 'LootLiquidator/ItemDBRuntime.lua',
                   'LootLiquidator/Core.lua', 'LootLiquidator/LootLiquidator.toc']
        originals = {'LootLiquidator/Core.lua': 'LA.version = "0.12.45"\nlocal unchanged=true\n',
                     'LootLiquidator/LootLiquidator.toc': '## Version: 0.12.45\nCore.lua\n'}
        def git(*args):
            if args[0] == 'merge-base': return 'main-sha'
            if args[0] == 'show': return originals[args[1].removeprefix('HEAD:')]
            return ''
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'LootLiquidator').mkdir()
            (root / 'database/research').mkdir(parents=True)
            runtime = root / 'LootLiquidator/ItemDBRuntime.lua'
            runtime.write_bytes(b'-- compiled fixture, no game rates\n')
            receipt = {'generatedInBuildWorkspace': True, 'sourceEvidencePreserved': True,
                       'runtimeSHA256': hashlib.sha256(runtime.read_bytes()).hexdigest()}
            (root / 'database/research/build-research-manifest.json').write_text(json.dumps(receipt))
            for name, text in originals.items():
                (root / name).write_text(text.replace('0.12.45', '0.12.46'))
            self.assertTrue(verified_release(env, 'main-sha', changed, git, root))
            self.assertFalse(verified_release(env, 'feature-sha', changed, git, root))
            self.assertFalse(verified_release({}, 'main-sha', changed, git, root))
            self.assertFalse(verified_release(env, 'main-sha', changed + ['LootLiquidator/Badges.lua'], git, root))
            self.assertFalse(verified_release(env, 'main-sha', changed + ['database/sources/ReferenceData.lua'], git, root))
            self.assertFalse(verified_release(env, 'main-sha', changed + ['database/research/unreviewed-source.json'], git, root))
            generated = root / 'database/research/build-study-review.json'
            generated.write_text('{"reviewedRows": 1}\n')
            generated_path = generated.relative_to(root).as_posix()
            self.assertFalse(verified_release(env, 'main-sha', changed + [generated_path], git, root))
            receipt['generatedFileSHA256'] = {generated_path: hashlib.sha256(generated.read_bytes()).hexdigest()}
            (root / 'database/research/build-research-manifest.json').write_text(json.dumps(receipt))
            self.assertTrue(verified_release(env, 'main-sha', changed + [generated_path], git, root))
            generated.write_text('{"reviewedRows": 2}\n')
            self.assertFalse(verified_release(env, 'main-sha', changed + [generated_path], git, root))
            runtime.write_bytes(b'-- unverified replacement\n')
            self.assertFalse(verified_release(env, 'main-sha', changed, git, root))
            runtime.write_bytes(b'-- compiled fixture, no game rates\n')
            (root / 'LootLiquidator/Core.lua').write_text('LA.version = "0.12.46"\nlocal changed=true\n')
            self.assertFalse(verified_release(env, 'main-sha', changed, git, root))
        with patch('stamp_build_info.verified_release', return_value=True):
            info = collect(env, {}, self.git, lambda *_: [])
        self.assertEqual((info['kind'], info['prStatus'], info['prs']), ('main', 'main-only', []))
        self.assertEqual(info['releaseTag'], 'v0.12.46')
        self.assertTrue(info['verifiedGeneratedResearch'])

    def git(self, *args):
        if args == ('rev-parse', 'HEAD'): return 'merge-sha'
        if args == ('branch', '--show-current'): return 'feature'
        return ''

    def test_main_and_pr_builds_are_distinct(self):
        env = {'GITHUB_ACTIONS': 'true', 'GITHUB_REF': 'refs/heads/main', 'GITHUB_REF_NAME': 'main'}
        main = collect(env, {}, self.git)
        self.assertEqual((main['kind'], main['prStatus'], main['prs']), ('main', 'main-only', []))
        event = {'pull_request': {'number': 49, 'title': 'Recycling capture', 'html_url': 'https://github.com/o/r/pull/49',
                                 'head': {'ref': 'fix/recycling', 'sha': 'head-sha'}}}
        pr = collect({'GITHUB_ACTIONS': 'true'}, event, self.git)
        self.assertEqual(pr['kind'], 'pr')
        self.assertEqual(pr['branch'], 'fix/recycling')
        self.assertEqual(pr['commit'], 'merge-sha')
        self.assertEqual(pr['headCommit'], 'head-sha')
        self.assertEqual(pr['prs'][0]['number'], 49)

    def test_combined_branch_and_dispatch_resolve_prs(self):
        def git(*args):
            return 'Merge pull request #12 from o/fix\nOther change (#13)' if args[0] == 'log' else self.git(*args)
        def lookup(*args): return [{'number': 49, 'title': 'Recycling', 'html_url': 'url', 'head': {'sha': 'merge-sha'}}]
        result = collect({'GITHUB_ACTIONS': 'true', 'GITHUB_REF_NAME': 'integration'}, {}, git, lookup)
        self.assertEqual(result['kind'], 'branch')
        self.assertEqual([p['number'] for p in result['prs']], [12, 13, 49])

    def test_missing_metadata_and_dirty_checkout_never_claim_main_only(self):
        def fail(*args): raise OSError('offline')
        result = collect({'GITHUB_ACTIONS': 'true'}, {}, self.git, fail)
        self.assertEqual((result['kind'], result['prStatus']), ('branch', 'unknown'))
        def dirty(*args): return 'LootLiquidator/Core.lua' if args[0] == 'diff' else self.git(*args)
        result = collect({'GITHUB_ACTIONS': 'true', 'GITHUB_REF': 'refs/heads/main'}, {}, dirty)
        self.assertEqual(result['kind'], 'local')
        self.assertTrue(result['dirty'])
        local = collect({}, {}, self.git, lambda *args: self.fail('local builds must not call GitHub'))
        self.assertEqual(local['kind'], 'local')
        missing = collect({'GITHUB_ACTIONS': 'true', 'GITHUB_REF': 'refs/heads/main'}, {}, lambda *args: '')
        self.assertEqual(missing['kind'], 'local')
        self.assertEqual(missing['prStatus'], 'unknown')


if __name__ == '__main__': unittest.main()
