"""Stamp the packaged addon's source commit, branch and included PR identities."""
import json
import os
from pathlib import Path
import re
import subprocess
import urllib.request

from capture_observations import lua

TARGET = Path('LootLiquidator/BuildInfo.lua')


def git(*args):
    try: result = subprocess.run(['git', *args], capture_output=True, text=True)
    except OSError: return ''
    return result.stdout.strip() if result.returncode == 0 else ''


def associated_prs(repository, commit):
    request = urllib.request.Request(
        f'https://api.github.com/repos/{repository}/commits/{commit}/pulls?per_page=100',
        headers={'Accept': 'application/vnd.github+json', 'X-GitHub-Api-Version': '2026-03-10',
                 'User-Agent': 'Loot-Liquidator-build'})
    with urllib.request.urlopen(request, timeout=20) as response:
        return json.load(response)


def collect(env, event, read_git=git, lookup=associated_prs):
    commit = read_git('rev-parse', 'HEAD') or 'unknown'
    pr = event.get('pull_request') or {}
    branch = pr.get('head', {}).get('ref') or env.get('GITHUB_REF_NAME') or read_git('branch', '--show-current') or 'unknown'
    repository = env.get('GITHUB_REPOSITORY', 'Voodoobrew101/Loot-Liquidator')
    changed = read_git('diff', '--name-only', 'HEAD').splitlines()
    dirty = any(path != TARGET.as_posix() for path in changed)
    ci = env.get('GITHUB_ACTIONS') == 'true'
    kind = 'local'
    prs = {}
    if ci and not dirty and commit != 'unknown':
        kind = 'pr' if pr else 'main' if env.get('GITHUB_REF') == 'refs/heads/main' else 'branch'
    elif not ci and not dirty and branch == 'main' and commit != 'unknown' and read_git('rev-parse', 'origin/main') == commit:
        kind = 'main'
    if pr:
        prs[pr['number']] = {'number': pr['number'], 'title': pr['title'], 'url': pr['html_url']}
    elif ci and kind == 'branch':
        try:
            for item in lookup(repository, commit):
                if item.get('head', {}).get('sha') == commit and not item.get('merged_at'):
                    prs[item['number']] = {'number': item['number'], 'title': item['title'], 'url': item['html_url']}
        except (OSError, ValueError):
            pass  # Explicitly unknown, never mislabeled as main-only.
    if kind in ('pr', 'branch'):
        # Combined branches can contain additional merge/squash PR commits.
        for subject in read_git('log', '--format=%s', 'origin/main..HEAD').splitlines():
            match = re.match(r'Merge pull request #(\d+)\b', subject) or re.search(r'\(#(\d+)\)$', subject)
            if match:
                number = int(match[1])
                prs.setdefault(number, {'number': number, 'title': subject,
                                        'url': f'https://github.com/{repository}/pull/{number}'})
    if kind == 'main': prs = {}
    result = {'kind': kind, 'repository': repository, 'branch': branch, 'commit': commit,
              'dirty': dirty, 'prs': [prs[n] for n in sorted(prs)],
              'prStatus': 'identified' if prs else 'main-only' if kind == 'main' else 'unknown'}
    if pr.get('head', {}).get('sha'): result['headCommit'] = pr['head']['sha']
    if env.get('GITHUB_RUN_ID'):
        result['runURL'] = f'https://github.com/{repository}/actions/runs/{env["GITHUB_RUN_ID"]}'
    return result


def stamp():
    if not TARGET.exists(): return  # Generic package fixtures contain no provenance module.
    env = os.environ
    event_path = env.get('GITHUB_EVENT_PATH')
    event = json.loads(Path(event_path).read_text()) if event_path else {}
    info = collect(env, event)
    text = TARGET.read_text(encoding='utf-8')
    replacement = '-- BEGIN GENERATED BUILD INFO\nLL.buildInfo=' + lua(info) + '\n-- END GENERATED BUILD INFO'
    text, count = re.subn(r'-- BEGIN GENERATED BUILD INFO\n.*?-- END GENERATED BUILD INFO',
                         lambda _: replacement, text, flags=re.DOTALL)
    assert count == 1, 'Build provenance marker missing or duplicated'
    TARGET.write_text(text, encoding='utf-8', newline='\n')
    print('BUILD:', info['kind'], info['commit'][:12], 'PRs:', [p['number'] for p in info['prs']])


if __name__ == '__main__': stamp()
