"""Trusted main-branch bridge from owner-authored JSON requests to the publisher.

Never check out/execute a request branch or consume its artifacts. The only
request-branch input is one bounded JSON blob. POSTs are sent once, never retried.
"""
import base64
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request

REPO = 'Voodoobrew101/Loot-Liquidator'
REPO_ID = 1436432359
OWNER_ID = 28468053
REQUEST_PATH = 'research/community/release-request.json'
LEDGER = 'research/community/daily-state.json'
SCHEMA = 'loot-liquidator.community-release-request/1'
SHA = re.compile(r'^[0-9a-f]{40}$')
DIGEST = re.compile(r'^[0-9a-f]{64}$')
ID = re.compile(r'^[a-z0-9][a-z0-9-]{7,63}$')
TAG = re.compile(r'^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$')
TERMINAL = {'uploaded', 'published'}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def version(tag):
    match = TAG.fullmatch(tag) if isinstance(tag, str) else None
    require(match, 'Only stable vMAJOR.MINOR.PATCH tags are supported')
    return tuple(map(int, match.groups()))


def parse_request(raw):
    require(len(raw) <= 65536, 'Request exceeds 64 KiB')
    def pairs(items):
        obj = {}
        for key, value in items:
            require(key not in obj, 'Duplicate JSON key')
            obj[key] = value
        return obj
    request = json.loads(raw, object_pairs_hook=pairs)
    require(isinstance(request, dict) and request.get('schemaVersion') == SCHEMA, 'Unsupported request schema')
    require(set(request) == {'schemaVersion', 'requestID', 'mode', 'sourceSHA', 'version', 'previousTag', 'reviews'},
            'Unexpected or missing request fields')
    require(isinstance(request['requestID'], str) and ID.fullmatch(request['requestID']), 'Invalid request identity')
    require(request['mode'] in ('dry-run', 'publish'), 'Invalid bridge mode')
    require(isinstance(request['sourceSHA'], str) and SHA.fullmatch(request['sourceSHA']), 'Exact source commit required')
    version(request['version']); version(request['previousTag'])
    require(isinstance(request['reviews'], list), 'Review inventory must be an array')
    keys = set()
    for review in request['reviews']:
        require(isinstance(review, dict) and set(review) == {'submissionKey', 'submissionSHA256', 'reviewSHA256'}, 'Invalid review proof')
        key = review['submissionKey']
        require(isinstance(key, str) and re.fullmatch(r'issue-[1-9][0-9]*-[0-9a-f]{16}', key) and key not in keys, 'Invalid/duplicate submission key')
        keys.add(key)
        require(all(isinstance(review[k], str) and DIGEST.fullmatch(review[k]) for k in ('submissionSHA256', 'reviewSHA256')), 'Invalid review hash')
    return request


class API:
    def __init__(self, token):
        self.token = token
    def call(self, path, method='GET', data=None, missing=False):
        require(path.startswith('/') and not path.startswith('//'), 'Repository-relative API path required')
        class NoRedirect(urllib.request.HTTPRedirectHandler):
            def redirect_request(self, *args, **kwargs):
                return None
        req = urllib.request.Request('https://api.github.com/repos/' + REPO + path, method=method,
            data=json.dumps(data).encode() if data is not None else None,
            headers={'Authorization': 'Bearer ' + self.token, 'Accept': 'application/vnd.github+json',
                     'Content-Type': 'application/json', 'User-Agent': 'Loot-Liquidator-community-bridge'})
        try:
            with urllib.request.build_opener(NoRedirect).open(req, timeout=60) as response:
                raw = response.read(8 * 1024 * 1024 + 1)
                require(len(raw) <= 8 * 1024 * 1024, 'API response too large')
                return json.loads(raw) if raw else {'httpStatus': response.status}
        except urllib.error.HTTPError as error:
            if missing and error.code == 404:
                return None
            raise ValueError(f'GitHub {method} returned HTTP {error.code}; no mutation retry') from None
    def file(self, path, ref):
        doc = self.call('/contents/' + path + '?ref=' + urllib.parse.quote(ref, safe=''))
        require(doc.get('encoding') == 'base64', 'Expected bounded repository file')
        raw = base64.b64decode(doc['content'], validate=False)
        require(len(raw) <= 65536, 'Repository metadata exceeds 64 KiB')
        return raw, doc['sha']
    def pages(self, path, key):
        for page in range(1, 101):
            result = self.call(path + ('&' if '?' in path else '?') + f'per_page=100&page={page}')
            items = result[key] if key else result
            yield from items
            if len(items) < 100:
                return
        raise ValueError('API pagination limit exceeded')


def git(*args):
    return subprocess.check_output(['git', *args], text=True, encoding='utf-8').strip()


def trusted_event(event, api):
    require(event.get('repository', {}).get('full_name') == REPO and event['repository'].get('id') == REPO_ID, 'Wrong repository')
    run_id = event.get('workflow_run', {}).get('id')
    require(type(run_id) is int and run_id > 0, 'Expected workflow_run event')
    run = api.call('/actions/runs/' + str(run_id))
    workflow = api.call('/actions/workflows/community-release-request.yml')
    require(run.get('workflow_id') == workflow['id'] and run.get('path') == '.github/workflows/community-release-request.yml', 'Unexpected receipt workflow')
    require(run.get('event') == 'push' and run.get('status') == 'completed' and run.get('conclusion') == 'success', 'Receipt did not succeed')
    require(run.get('head_repository', {}).get('id') == REPO_ID and run.get('actor', {}).get('id') == OWNER_ID
            and run.get('triggering_actor', {}).get('id') == OWNER_ID, 'Only owner-authored same-repository requests are allowed')
    require(isinstance(run.get('head_sha'), str) and SHA.fullmatch(run['head_sha']), 'Missing receipt commit')
    raw, _ = api.file(REQUEST_PATH, run['head_sha'])
    request = parse_request(raw)
    require(run.get('head_branch') == 'automation/community-release-request-' + request['requestID'], 'Branch/request identity mismatch')
    compare = api.call('/compare/' + request['sourceSHA'] + '...' + run['head_sha'])
    require(compare.get('status') == 'ahead' and compare.get('ahead_by') == 1 and compare.get('behind_by') == 0
            and [f['filename'] for f in compare.get('files', [])] == [REQUEST_PATH]
            and compare['files'][0]['status'] in ('added', 'modified'), 'Request branch must add only one JSON request on exact production source')
    subprocess.run(['git', 'merge-base', '--is-ancestor', request['sourceSHA'], 'HEAD'], check=True)
    return request


def ledger_entry(request, ledger):
    require(ledger.get('schemaVersion') == 1 and ledger.get('repository') == REPO, 'Invalid durable ledger')
    pubs = ledger.get('publications', [])
    uploaded = [p for p in pubs if p.get('status') in TERMINAL and type(p.get('curseForgeFileID')) is int and p['curseForgeFileID'] > 0]
    require(uploaded, 'No prior verified publication')
    latest = max(uploaded, key=lambda p: version(p['tag']))
    require(latest['tag'] == request['previousTag'], 'Previous tag must be latest uploaded version')
    if request['mode'] == 'dry-run':
        require(request['version'] == latest['tag'] and request['reviews'] == [], 'Dry run validates the existing uploaded version only')
        require(all(p.get('status') in TERMINAL for p in pubs), 'Unresolved publication blocks dry run')
        return None
    prev = version(latest['tag'])
    require(version(request['version']) == (prev[0], prev[1], prev[2] + 1), 'Choose the next unused patch version')
    require(request['reviews'], 'Publishing requires approved new community data')
    matches = [p for p in pubs if p.get('tag') == request['version']]
    require(len(matches) == 1, 'One durable publication intent required')
    entry = matches[0]
    require(entry.get('sourceSHA') == request['sourceSHA'] and entry.get('bridgeRequestID') == request['requestID']
            and entry.get('previousTag') == request['previousTag'] and entry.get('reviews') == request['reviews'], 'Publication intent differs from request')
    require(entry.get('status') == 'ready-for-bridge', 'Request already attempted or pending: reconcile receipt; never redispatch blindly')
    require(all(p is entry or p.get('status') in TERMINAL for p in pubs), 'Another publication is unresolved')
    return entry


def source_checks(request, api):
    source = request['sourceSHA']
    advanced = set(git('diff', '--name-only', source, 'HEAD').splitlines())
    require(advanced <= {LEDGER}, 'Production advanced beyond this source; only later ledger metadata may differ')
    toc = git('show', source + ':LootLiquidator/LootLiquidator.toc')
    core = git('show', source + ':LootLiquidator/Core.lua')
    v = request['version'][1:]
    require(re.findall(r'^## Version: (.+)$', toc, re.M) == [v]
            and re.findall(r'^LA.version = "([^"]+)"$', core, re.M) == [v], 'Source manifest/runtime version mismatch')
    require(any(r.get('head_sha') == source and r.get('event') == 'push' and r.get('head_branch') == 'main'
                and r.get('conclusion') == 'success' for r in api.pages('/actions/workflows/verify-modernization.yml/runs?head_sha=' + source, 'workflow_runs')),
            'Exact production source needs successful full main validation')
    previous = api.call('/git/ref/tags/' + request['previousTag'])
    if previous['object']['type'] == 'tag':
        previous_sha = api.call('/git/tags/' + previous['object']['sha'])['object']['sha']
    else:
        previous_sha = previous['object']['sha']
    require(previous_sha and SHA.fullmatch(previous_sha), 'Invalid prior tag')
    subprocess.run(['git', 'merge-base', '--is-ancestor', previous_sha, source], check=True)
    if request['mode'] == 'dry-run':
        return previous_sha
    require(api.call('/git/ref/tags/' + request['version'], missing=True) is None, 'Version tag already exists')
    require(git('show', source + ':database/community-capture-baselines.lua') != git('show', previous_sha + ':database/community-capture-baselines.lua'), 'No reviewed community database change')
    require(git('show', source + ':LootLiquidator/ItemDBRuntime.lua') != git('show', previous_sha + ':LootLiquidator/ItemDBRuntime.lua'), 'No compiled runtime data change')
    # Archive only trusted production source, never the request branch. Intake
    # code is imported from trusted main and reads this immutable source snapshot.
    import community_research as intake
    with tempfile.TemporaryDirectory(prefix='community-bridge-') as temporary:
        root = Path(temporary)
        # git restore uses the selected production tree in a separate index via
        # archive; extraction paths are checked before writing any member.
        import io
        import tarfile
        raw = subprocess.check_output(['git', 'archive', source, 'research/community', 'research/integration/measured-captures'])
        with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
            for member in archive.getmembers():
                path = (root / member.name).resolve()
                require(path.is_relative_to(root.resolve()) and (member.isfile() or member.isdir()), 'Unsafe production archive member')
                if member.isdir():
                    path.mkdir(parents=True, exist_ok=True)
                else:
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(archive.extractfile(member).read())
        compiled = intake.compile_reviewed(root)
        require(intake.render(compiled).strip() == git('show', source + ':database/community-capture-baselines.lua'), 'Reviewed source does not reproduce committed community data')
        for proof in request['reviews']:
            manifest, _, _, _, _ = intake.load_submission(root, proof['submissionKey'])
            review = intake.read_json(intake.submission_folder(root, proof['submissionKey']) / 'review.json')[1]
            require(manifest['submissionSHA256'] == proof['submissionSHA256'] and intake.hashed(review) == proof['reviewSHA256'], 'Review/source proof mismatch')
            old_path = previous_sha + ':research/community/submissions/' + proof['submissionKey'] + '/review.json'
            require(subprocess.run(['git', 'cat-file', '-e', old_path], capture_output=True).returncode != 0, 'Review was already in prior release')
            require(any(r.get('sourceReviewSHA256') == proof['reviewSHA256'] for r in compiled['processing']), 'Review contributes no shared numerical data')
    return previous_sha


def save_ledger(api, ledger, sha, message):
    content = json.dumps(ledger, indent=2) + '\n'
    return api.call('/contents/' + LEDGER, 'PUT', {'branch': 'main', 'sha': sha,
        'message': message, 'content': base64.b64encode(content.encode()).decode()})['content']['sha']


def execute(request, api, previous_sha):
    raw, ledger_sha = api.file(LEDGER, 'main')
    ledger = json.loads(raw)
    entry = ledger_entry(request, ledger)
    receipt = {'schemaVersion': 1, 'request': request, 'workflowRunID': os.environ.get('GITHUB_RUN_ID'),
               'dryRun': request['mode'] == 'dry-run', 'publicationRequested': entry is not None,
               'publicationPerformed': False}
    Path('dist').mkdir(exist_ok=True)
    path = Path('dist/community-release-bridge.json')
    def write():
        path.write_text(json.dumps(receipt, indent=2) + '\n')
    if entry is not None:
        # Persist a fail-closed reservation before either POST. Reruns stop here
        # even after a timeout or runner crash; the cloud agent reconciles first.
        entry.update(status='bridge-dispatching', bridgeRunID=os.environ.get('GITHUB_RUN_ID'))
        ledger_sha = save_ledger(api, ledger, ledger_sha, 'Reserve community release ' + request['requestID'])
        receipt['status'] = 'reserved'; write()
        api.call('/git/refs', 'POST', {'ref': 'refs/tags/' + request['version'], 'sha': request['sourceSHA']})
        receipt['tagCreated'] = request['version']; write()
    else:
        # Successful dry-run attempts are also recorded before dispatch; repeat
        # deliveries of the same request cannot create another build.
        attempts = ledger.setdefault('bridgeDryRuns', {})
        require(request['requestID'] not in attempts, 'Dry run already attempted; inspect its receipt')
        attempts[request['requestID']] = {'status': 'dispatching', 'bridgeRunID': os.environ.get('GITHUB_RUN_ID')}
        ledger_sha = save_ledger(api, ledger, ledger_sha, 'Reserve bridge dry run ' + request['requestID'])
        receipt['status'] = 'reserved'; write()
    inputs = {'version': request['version'], 'publish': entry is not None}
    api.call('/actions/workflows/curseforge.yml/dispatches', 'POST', {'ref': request['version'], 'inputs': inputs})
    receipt.update(status='dispatched', publisherInputs=inputs, publisherSourceSHA=request['sourceSHA'] if entry else previous_sha)
    write()
    if entry is not None:
        entry.update(status='bridge-dispatched', bridgeRunID=os.environ.get('GITHUB_RUN_ID'))
    else:
        ledger['bridgeDryRuns'][request['requestID']]['status'] = 'dispatched'
    # A concurrent main update is not overwritten. The durable reservation and
    # receipt remain sufficient to prevent an unsafe retry if this CAS fails.
    save_ledger(api, ledger, ledger_sha, 'Record bridge dispatch ' + request['requestID'])
    print(json.dumps(receipt))
    if os.environ.get('GITHUB_STEP_SUMMARY'):
        with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as summary:
            summary.write('Community bridge: ' + request['requestID'] + ' — ' + receipt['status'] + '\n')
    return receipt


def main():
    require(os.environ.get('GITHUB_EVENT_NAME') == 'workflow_run', 'Only the trusted workflow_run bridge may execute')
    require(os.environ.get('GITHUB_REPOSITORY') == REPO and os.environ.get('GH_TOKEN'), 'Expected repository Actions token')
    api = API(os.environ['GH_TOKEN'])
    event = json.loads(Path(os.environ['GITHUB_EVENT_PATH']).read_text())
    request = trusted_event(event, api)
    previous_sha = source_checks(request, api)
    execute(request, api, previous_sha)


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print('BRIDGE STOPPED: ' + str(error), file=sys.stderr)
        sys.exit(1)
