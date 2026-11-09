import sys
import unittest
from pathlib import Path
sys.path.insert(0, str(Path('tools').resolve()))
from stamp_build_info import collect


class BuildInfoTests(unittest.TestCase):
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
