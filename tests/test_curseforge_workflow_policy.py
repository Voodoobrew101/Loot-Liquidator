"""Check actual workflow routing and execute its publication guard offline."""
import os
from pathlib import Path
import re
import subprocess
import sys
import textwrap
from types import SimpleNamespace
import unittest
from unittest.mock import call, patch

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = (ROOT / '.github/workflows/curseforge.yml').read_text(encoding='utf-8')
VALIDATE = "github.event_name == 'workflow_dispatch' && inputs.publish == true"
UPLOAD = (VALIDATE + " && startsWith(github.ref, 'refs/tags/')"
          " && inputs.version == github.ref_name")


def step(name):
    found = re.search(r'^      - name: ' + re.escape(name)
                      + r'\n(.*?)(?=^      - |\Z)', WORKFLOW, re.M | re.S)
    if not found:
        raise AssertionError('Missing workflow step: ' + name)
    return found.group(1)


def condition(block):
    found = re.search(r'^        if: (.+)$', block, re.M)
    if not found:
        raise AssertionError('Conditional step has no explicit condition')
    return found.group(1)


def permits(expression, event, ref, version, publish):
    # Execute only these two exact reviewed conditions, with typed booleans;
    # arbitrary workflow text cannot become test code.
    if expression not in (VALIDATE, UPLOAD):
        raise AssertionError('Unexpected publication policy: ' + expression)
    return eval(expression.replace('&&', ' and '), {'__builtins__': {}}, {
        'github': SimpleNamespace(event_name=event, ref=ref, ref_name=ref.rsplit('/', 1)[-1]),
        'inputs': SimpleNamespace(version=version, publish=publish),
        'true': True, 'startsWith': lambda value, prefix: value.startswith(prefix)})


class WorkflowPolicyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.validation = step('Validate explicit publication target')
        cls.upload = step('Upload verified version tag to CurseForge')
        cls.validate_if = condition(cls.validation)
        cls.upload_if = condition(cls.upload)
        found = re.search(r"^          python3 - <<'PY'\n(.*?)^          PY$",
                          cls.validation, re.M | re.S)
        if not found:
            raise AssertionError('Publication guard must be the actual inline Python block')
        cls.guard_code = compile(textwrap.dedent(found.group(1)), 'workflow-publication-guard', 'exec')

    def guard(self, version='v1.2.3', ref='refs/tags/v1.2.3', head='approved-sha', tagged='approved-sha',
              tag_missing=False, off_main=False, no_git=False):
        if tag_missing:
            answers = [head, subprocess.CalledProcessError(128, ['git', 'rev-parse'])]
        else:
            answers = [head, tagged]
        ancestor_error = subprocess.CalledProcessError(1, ['git', 'merge-base']) if off_main else None
        with patch.dict(os.environ, {'REQUESTED_VERSION': version, 'GITHUB_REF': ref}, clear=True), \
                patch.object(sys, 'path', list(sys.path)), \
                patch('subprocess.check_output', side_effect=answers) as read_git, \
                patch('subprocess.run', side_effect=ancestor_error) as ancestor:
            try:
                exec(self.__class__.guard_code, {})
            finally:
                if no_git:
                    read_git.assert_not_called()
                    ancestor.assert_not_called()
            self.assertEqual(read_git.call_args_list, [
                call(['git', 'rev-parse', 'HEAD'], text=True),
                call(['git', 'rev-parse', '--verify', 'refs/tags/' + version + '^{commit}'], text=True)])
            ancestor.assert_called_once_with(
                ['git', 'merge-base', '--is-ancestor', head, 'origin/main'], check=True)

    def test_publish_is_optional_boolean_and_defaults_false(self):
        declared = WORKFLOW.split('      publish:\n', 1)[1].split('\n\n', 1)[0]
        for setting in ('required: false', 'default: false', 'type: boolean'):
            self.assertRegex(declared, r'(?m)^        ' + re.escape(setting) + r'$')
        self.assertEqual(self.validate_if, VALIDATE)
        self.assertEqual(self.upload_if, UPLOAD)

    def test_tag_push_pr_and_unchecked_manual_runs_never_upload(self):
        cases = [
            ('push', 'refs/tags/v1.2.3', 'v1.2.3', None),
            ('push', 'refs/tags/v1.2.3', 'v1.2.3', True),
            ('pull_request', 'refs/pull/1/merge', 'v1.2.3', True),
            ('workflow_dispatch', 'refs/heads/main', 'v1.2.3', False),
            ('workflow_dispatch', 'refs/tags/v1.2.3', 'v1.2.3', False),
            ('workflow_dispatch', 'refs/tags/v1.2.3', 'v1.2.3', None),
            ('workflow_dispatch', 'refs/tags/v1.2.3', 'v1.2.3', 'false')]
        for case in cases:
            with self.subTest(case=case):
                self.assertFalse(permits(self.upload_if, *case))
                self.assertFalse(permits(self.validate_if, *case))

    def test_only_manual_true_matching_tag_can_reach_upload(self):
        self.assertTrue(permits(self.upload_if, 'workflow_dispatch', 'refs/tags/v1.2.3', 'v1.2.3', True))
        for ref, version in [('refs/heads/main', 'v1.2.3'),
                             ('refs/tags/v1.2.4', 'v1.2.3')]:
            self.assertTrue(permits(self.validate_if, 'workflow_dispatch', ref, version, True))
            self.assertFalse(permits(self.upload_if, 'workflow_dispatch', ref, version, True))

    def test_actual_guard_accepts_matching_existing_main_tags(self):
        for version in ('v1.2.3', '1.2.3', 'v1.2.3-alpha.1', 'v1.2.3-rc.1'):
            with self.subTest(version=version):
                self.guard(version=version, ref='refs/tags/' + version)

    def test_actual_guard_rejects_branch_and_mismatched_tag_before_git(self):
        for ref in ('refs/heads/main', 'refs/heads/v1.2.3', 'refs/tags/v1.2.4'):
            with self.subTest(ref=ref), self.assertRaisesRegex(SystemExit, 'same existing release tag'):
                self.guard(ref=ref, no_git=True)

    def test_actual_guard_rejects_invalid_version(self):
        for version in ('v1.2', 'v01.2.3', 'v1.2.3\n', 'v1.2.3;echo secret'):
            with self.subTest(version=version), self.assertRaises(ValueError):
                self.guard(version=version, ref='refs/tags/' + version, no_git=True)

    def test_actual_guard_rejects_missing_tag_wrong_checkout_and_off_main(self):
        with self.assertRaises(subprocess.CalledProcessError):
            self.guard(tag_missing=True)
        with self.assertRaisesRegex(SystemExit, 'checkout does not match'):
            self.guard(tagged='different-sha')
        with self.assertRaises(subprocess.CalledProcessError):
            self.guard(off_main=True)

    def test_checkout_and_version_preserve_the_dispatch_ref(self):
        checkout = re.search(r'^      - uses: actions/checkout@[^\n]+\n(.*?)(?=^      - )',
                             WORKFLOW, re.M | re.S).group(1)
        self.assertNotRegex(checkout, r'(?m)^          ref:')
        self.assertIn('fetch-depth: 0', checkout)
        self.assertIn('persist-credentials: false', checkout)
        self.assertIn('REQUESTED_VERSION: ${{ inputs.version }}', self.validation)
        self.assertNotIn('${{', self.validation.split('        run: |', 1)[1])
        prepare = step('Prepare version and CurseForge metadata')
        self.assertIn("RELEASE_TAG: ${{ github.event_name == 'push' && github.ref_name || inputs.version || 'v0.0.0-alpha.1' }}", prepare)

    def test_mandatory_checks_and_token_are_confined_to_expected_steps(self):
        order = ['Validate explicit publication target', 'Review studies and compile the build database',
                 'Run all addon validation', 'Prepare version and CurseForge metadata',
                 'Package and verify', 'Upload verified version tag to CurseForge']
        positions = [WORKFLOW.index('- name: ' + name) for name in order]
        self.assertEqual(positions, sorted(positions))
        self.assertNotIn('continue-on-error', WORKFLOW)
        self.assertIn('contents: read', WORKFLOW)
        self.assertEqual(WORKFLOW.count('${{ secrets.CURSEFORGE_API_TOKEN }}'), 1)
        self.assertIn('${{ secrets.CURSEFORGE_API_TOKEN }}', self.upload)
        self.assertNotIn('CURSEFORGE_API_TOKEN', WORKFLOW[:WORKFLOW.index('- name: Upload verified')])
        self.assertIn('python3 tools/verify_distribution.py dist/LootLiquidator.zip', step('Package and verify'))
        self.assertIn('python3 tools/prepare_build_research.py', step('Review studies and compile the build database'))
        self.assertNotIn('--research-ref', step('Review studies and compile the build database'))


if __name__ == '__main__':
    unittest.main()
