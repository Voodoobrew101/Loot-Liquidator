"""Owner-only cloud bridge: reject untrusted/no-change/replayed requests."""
import base64
import copy
import json
import os
from pathlib import Path
import sys
import tempfile
import io
import tarfile
import types
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import community_release_bridge as bridge


def request(mode='publish'):
    return {'schemaVersion': bridge.SCHEMA, 'requestID': 'review-20261124-test', 'mode': mode,
        'sourceSHA': 'a' * 40, 'version': 'v1.0.2' if mode == 'publish' else 'v1.0.1',
        'previousTag': 'v1.0.1', 'reviews': [{'submissionKey': 'issue-123-' + 'b' * 16,
            'submissionSHA256': 'b' * 64, 'reviewSHA256': 'c' * 64}] if mode == 'publish' else []}


def ledger(req=None):
    result = {'schemaVersion': 1, 'repository': bridge.REPO, 'publications': [
        {'tag': 'v1.0.1', 'status': 'uploaded', 'curseForgeFileID': 9794558}]}
    if req and req['mode'] == 'publish':
        result['publications'].append({'tag': req['version'], 'sourceSHA': req['sourceSHA'],
            'bridgeRequestID': req['requestID'], 'previousTag': req['previousTag'],
            'reviews': req['reviews'], 'status': 'ready-for-bridge'})
    return result


class FakeAPI:
    def __init__(self, req=None):
        self.req = req or request()
        self.ledger = ledger(self.req)
        self.mutations = []
        self.failure = None
        self.run = {'workflow_id': 123, 'path': '.github/workflows/community-release-request.yml',
            'event': 'push', 'status': 'completed', 'conclusion': 'success',
            'head_repository': {'id': bridge.REPO_ID}, 'actor': {'id': bridge.OWNER_ID},
            'triggering_actor': {'id': bridge.OWNER_ID}, 'head_sha': 'd' * 40,
            'head_branch': 'automation/community-release-request-' + self.req['requestID']}
        self.compare = {'status': 'ahead', 'ahead_by': 1, 'behind_by': 0,
                        'files': [{'filename': bridge.REQUEST_PATH, 'status': 'added'}]}
        self.tag = None
    def file(self, path, ref):
        return json.dumps(self.req if path == bridge.REQUEST_PATH else self.ledger).encode(), 'blob-sha'
    def pages(self, path, key):
        yield {'head_sha': self.req['sourceSHA'], 'event': 'push', 'head_branch': 'main', 'conclusion': 'success'}
    def call(self, path, method='GET', data=None, missing=False):
        if method != 'GET':
            self.mutations.append((path, method, copy.deepcopy(data)))
            if self.failure == path:
                raise OSError('uncertain POST response')
            if method == 'PUT':
                self.ledger = json.loads(base64.b64decode(data['content']))
                return {'content': {'sha': 'next-blob-sha'}}
            return {'httpStatus': 204}
        if path.startswith('/actions/runs/'):
            return self.run
        if path == '/actions/workflows/community-release-request.yml':
            return {'id': 123}
        if path.startswith('/compare/'):
            return self.compare
        if path == '/git/ref/tags/' + self.req['previousTag']:
            return {'object': {'type': 'commit', 'sha': 'e' * 40}}
        if path.startswith('/git/ref/tags/'):
            return self.tag
        raise AssertionError(path)


class BridgeTests(unittest.TestCase):
    def test_parse_requires_exact_typed_schema_and_unique_json_keys(self):
        self.assertEqual(bridge.parse_request(json.dumps(request()).encode()), request())
        for change in [lambda r:r.update(mode='force'), lambda r:r.update(sourceSHA='main'),
                       lambda r:r.update(version='v1.0.2; bad'), lambda r:r.update(requestID='../bad'),
                       lambda r:r.update(extra=True), lambda r:r.update(reviews=[r['reviews'][0]] * 2)]:
            doc = request(); change(doc)
            with self.assertRaises(ValueError): bridge.parse_request(json.dumps(doc).encode())
        with self.assertRaises(ValueError): bridge.parse_request(b'{"schemaVersion":1,"schemaVersion":2}')
        with self.assertRaises(ValueError): bridge.parse_request(b' ' * 65537)

    def test_owner_receipt_and_single_data_file_only(self):
        api = FakeAPI()
        event = {'repository': {'full_name': bridge.REPO, 'id': bridge.REPO_ID}, 'workflow_run': {'id': 5}}
        with patch.object(bridge.subprocess, 'run'):
            self.assertEqual(bridge.trusted_event(event, api), request())
            for field, value in [('event','pull_request'), ('conclusion','failure'), ('workflow_id',999),
                                 ('head_repository',{'id':1}), ('actor',{'id':1}), ('triggering_actor',{'id':1}),
                                 ('head_branch','arbitrary'), ('head_sha','main')]:
                original = copy.deepcopy(api.run)
                api.run[field] = value
                with self.assertRaises(ValueError): bridge.trusted_event(event, api)
                api.run = original
            api.compare['files'].append({'filename': 'tools/community_release_bridge.py', 'status':'modified'})
            with self.assertRaises(ValueError): bridge.trusted_event(event, api)
            api.compare['files'].pop(); api.compare['ahead_by'] = 2
            with self.assertRaises(ValueError): bridge.trusted_event(event, api)
        self.assertEqual(api.mutations, [])

    def test_intent_requires_next_patch_real_reviews_and_no_pending_release(self):
        req = request()
        self.assertEqual(bridge.ledger_entry(req, ledger(req))['status'], 'ready-for-bridge')
        for field, value in [('sourceSHA','f'*40), ('bridgeRequestID','other-request'),
                             ('reviews',[]), ('status','bridge-dispatching'), ('status','uploaded')]:
            state = ledger(req); state['publications'][-1][field] = value
            with self.assertRaises(ValueError): bridge.ledger_entry(req, state)
        state = ledger(req); state['publications'].append({'tag':'v1.0.3','status':'publishing'})
        with self.assertRaises(ValueError): bridge.ledger_entry(req, state)
        bad = request(); bad['version'] = 'v1.0.3'
        with self.assertRaises(ValueError): bridge.ledger_entry(bad, ledger(bad))
        bad = request(); bad['reviews'] = []
        with self.assertRaises(ValueError): bridge.ledger_entry(bad, ledger(bad))

    def test_source_checks_reject_version_ci_tag_and_no_data_change(self):
        req = request(); api = FakeAPI(req)
        def git(*args):
            if args[0] == 'diff': return ''
            ref = args[1]
            if ref.endswith('LootLiquidator.toc'): return '## Version: 1.0.2'
            if ref.endswith('Core.lua'): return 'LA.version = "1.0.2"'
            return 'unchanged data'
        with patch.object(bridge, 'git', side_effect=git), patch.object(bridge.subprocess, 'run'):
            with self.assertRaisesRegex(ValueError, 'No reviewed community database change'):
                bridge.source_checks(req, api)
            api.tag = {'object': {'sha':'a'*40}}
            with self.assertRaisesRegex(ValueError, 'already exists'): bridge.source_checks(req, api)
            api.tag = None
            with patch.object(api, 'pages', return_value=iter([])):
                with self.assertRaisesRegex(ValueError, 'full main validation'): bridge.source_checks(req, api)
        with patch.object(bridge, 'git', return_value='wrong'):
            with self.assertRaisesRegex(ValueError, 'Production advanced'): bridge.source_checks(req, api)
        with patch.object(bridge, 'git', side_effect=lambda *args: '' if args[0] == 'diff' else 'wrong'):
            with self.assertRaisesRegex(ValueError, 'version mismatch'): bridge.source_checks(req, api)
        self.assertEqual(api.mutations, [])

    def test_actual_reviewed_capture_must_reproduce_source_and_review_proofs(self):
        import community_research as intake
        from test_community_research import sample
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            export = root / 'export.json'; intake.write_json(export, sample())
            manifest = intake.stage(root, 123, 'https://github.com/Voodoobrew101/Loot-Liquidator/issues/123', [export])
            staged = intake.load_submission(root, manifest['key'])[3]
            review = {'schemaVersion':intake.REVIEW_SCHEMA, 'submissionSHA256':manifest['submissionSHA256'],
                'reviewer':'fixture reviewer', 'rationale':'Complete measured Retail source checked.',
                'gameMode':'RETAIL', 'scientificReviewComplete':True,
                'cohorts':[{'cohortID':b['communityCohortID'], 'outputs':{str(m['outputItemID']):
                    {'decision':'material','reason':'Verified saleable fixture output'} for m in b['materials']}}
                    for b in staged['baselines']]}
            review_file = root / 'review.json'; intake.write_json(review_file, review)
            intake.approve(root, manifest['key'], review_file)
            generated = intake.render(intake.compile_reviewed(root)).strip()
            buffer = io.BytesIO()
            with tarfile.open(fileobj=buffer, mode='w') as archive:
                archive.add(root/'research', arcname='research')
            req = request(); req['reviews'] = [{'submissionKey':manifest['key'],
                'submissionSHA256':manifest['submissionSHA256'], 'reviewSHA256':intake.hashed(review)}]
            api = FakeAPI(req)
            def source_git(*args):
                if args[0] == 'diff': return ''
                ref = args[1]
                if ref.endswith('LootLiquidator.toc'): return '## Version: 1.0.2'
                if ref.endswith('Core.lua'): return 'LA.version = "1.0.2"'
                if ref.startswith('a'*40+':database/community'): return generated
                if ref.endswith('database/community-capture-baselines.lua'): return 'old community data'
                return 'new runtime' if ref.startswith('a'*40) else 'old runtime'
            with patch.object(bridge,'git',side_effect=source_git), \
                 patch.object(bridge.subprocess,'check_output',return_value=buffer.getvalue()), \
                 patch.object(bridge.subprocess,'run',return_value=types.SimpleNamespace(returncode=1)):
                self.assertEqual(bridge.source_checks(req, api), 'e'*40)
                req['reviews'][0]['reviewSHA256'] = '0'*64
                with self.assertRaisesRegex(ValueError,'proof mismatch'): bridge.source_checks(req, api)
            self.assertEqual(api.mutations, [])

    def run_execute(self, api):
        with tempfile.TemporaryDirectory() as tmp:
            old = Path.cwd(); os.chdir(tmp)
            try:
                with patch.dict(os.environ, {'GITHUB_RUN_ID':'12345'}):
                    return bridge.execute(api.req, api, 'e'*40)
            finally: os.chdir(old)

    def test_publish_reserves_before_tag_and_one_dispatch(self):
        api = FakeAPI()
        receipt = self.run_execute(api)
        self.assertEqual([m[:2] for m in api.mutations], [('/contents/'+bridge.LEDGER,'PUT'),
            ('/git/refs','POST'), ('/actions/workflows/curseforge.yml/dispatches','POST'), ('/contents/'+bridge.LEDGER,'PUT')])
        self.assertEqual(api.mutations[1][2], {'ref':'refs/tags/v1.0.2','sha':'a'*40})
        self.assertEqual(receipt['publisherInputs'], {'version':'v1.0.2','publish':True})
        before = copy.deepcopy(api.mutations)
        with self.assertRaises(ValueError): self.run_execute(api)
        self.assertEqual(api.mutations, before)

    def test_dry_run_never_creates_tag_or_requests_publication(self):
        api = FakeAPI(request('dry-run'))
        receipt = self.run_execute(api)
        self.assertTrue(receipt['dryRun'])
        self.assertEqual(receipt['publisherInputs'], {'version':'v1.0.1','publish':False})
        self.assertFalse(any(m[0]=='/git/refs' for m in api.mutations))
        before = copy.deepcopy(api.mutations)
        with self.assertRaises(ValueError): self.run_execute(api)
        self.assertEqual(api.mutations, before)

    def test_uncertain_post_never_retries_tag_or_dispatch(self):
        for endpoint in ('/git/refs','/actions/workflows/curseforge.yml/dispatches'):
            api = FakeAPI(); api.failure = endpoint
            with self.assertRaises(OSError): self.run_execute(api)
            self.assertEqual(api.ledger['publications'][-1]['status'], 'bridge-dispatching')
            before = copy.deepcopy(api.mutations)
            with self.assertRaises(ValueError): self.run_execute(api)
            self.assertEqual(api.mutations, before)

    def test_workflows_keep_request_read_only_and_privileged_code_on_main(self):
        root = Path(__file__).resolve().parents[1]
        receipt = (root/'.github/workflows/community-release-request.yml').read_text()
        privileged = (root/'.github/workflows/community-release-bridge.yml').read_text()
        self.assertIn('contents: read', receipt)
        self.assertNotIn('checkout', receipt)
        self.assertNotIn('write', receipt)
        self.assertIn('workflow_run:', privileged)
        self.assertIn('ref: main', privileged)
        self.assertIn('persist-credentials: false', privileged)
        self.assertIn('contents: write', privileged)
        self.assertIn('actions: write', privileged)
        self.assertNotIn('CURSEFORGE_API_TOKEN', privileged)


if __name__ == '__main__':
    unittest.main()
