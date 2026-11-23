"""Write build provenance beside build artifacts, outside the installed addon."""
import json
import hashlib
import os
from pathlib import Path
import re
import subprocess
import urllib.request

TARGET = Path('dist/build-info.json')
GENERATED_RESEARCH_PATHS = {
    'LootLiquidator/ProfessionCatalog.lua',
    *('database/' + name + '.lua' for name in (
        'profession-profile-rules', 'reference-calculator-baselines',
        'skill-quality-rules', 'specialization-effects', 'research-v3-baselines',
        'evidence-baselines', 'capture-observations', 'att-token-baselines', 'disenchant-category-baselines')),
    *('database/research/' + name for name in (
        'build-study-review.json', 'build-study-review.lua', 'source-catalogue-build-review.json',
        'profession-profile-rule-coverage.json',
        'profession-effect-coverage.json', 'disenchant-gaps.lua')),
    'research/evidence/v3/midnight/2026-11-06-enchanting-yields.json',
    'research/mechanics/2026-11-19-profession-profile-coverage.md',
}


def generated_research_hashes(root=Path('.')):
    paths = set(GENERATED_RESEARCH_PATHS)
    snapshot = root / 'database/research/v3-snapshot'
    paths.update(path.relative_to(root).as_posix() for path in snapshot.rglob('*') if path.is_file())
    reviewed = root / 'research/integration/measured-captures/2026-11-22-reviewed-disenchant-subset'
    paths.update(path.relative_to(root).as_posix() for path in reviewed.glob('*.json') if path.is_file())
    return {path: hashlib.sha256((root / path).read_bytes()).hexdigest()
            for path in sorted(paths) if (root / path).is_file()}


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


def verified_release(env, commit, changed, read_git=git, root=Path('.')):
    """Validate generated release changes without trusting a tag name alone."""
    ref = env.get('GITHUB_REF', '')
    if env.get('GITHUB_ACTIONS') != 'true' or not re.fullmatch(r'refs/tags/v?\d+\.\d+\.\d+(?:-(?:alpha|beta|rc)(?:\.\d+)?)?', ref):
        return False
    if commit == 'unknown' or read_git('merge-base', commit, 'origin/main') != commit:
        return False
    version = ref.rsplit('/', 1)[1].removeprefix('v')
    try:
        receipt = json.loads((root / 'database/research/build-research-manifest.json').read_text())
        runtime = root / 'LootLiquidator/ItemDBRuntime.lua'
        if receipt.get('generatedInBuildWorkspace') is not True or receipt.get('sourceEvidencePreserved') is not True:
            return False
        if hashlib.sha256(runtime.read_bytes()).hexdigest() != receipt.get('runtimeSHA256'):
            return False
        versions = {'LootLiquidator/Core.lua': r'^LA.version = ".*"$',
                    'LootLiquidator/LootLiquidator.toc': r'^## Version: .+$'}
        for path in changed:
            if path in (TARGET.as_posix(), 'LootLiquidator/ItemDBRuntime.lua', 'database/research/build-research-manifest.json'):
                continue
            if path in GENERATED_RESEARCH_PATHS or path.startswith('database/research/v3-snapshot/'):
                expected_hash = receipt.get('generatedFileSHA256', {}).get(path)
                if not expected_hash or hashlib.sha256((root / path).read_bytes()).hexdigest() != expected_hash:
                    return False
                continue
            if path not in versions:
                return False
            current = (root / path).read_text(encoding='utf-8')
            original = read_git('show', 'HEAD:' + path)
            pattern = versions[path]
            expected = f'LA.version = "{version}"' if path.endswith('Core.lua') else f'## Version: {version}'
            if re.findall(pattern, current, re.M) != [expected] or not original:
                return False
            if re.sub(pattern, '', current, flags=re.M).strip() != re.sub(pattern, '', original, flags=re.M).strip():
                return False
    except (OSError, ValueError):
        return False
    return True


def collect(env, event, read_git=git, lookup=associated_prs):
    commit = read_git('rev-parse', 'HEAD') or 'unknown'
    pr = event.get('pull_request') or {}
    branch = pr.get('head', {}).get('ref') or env.get('GITHUB_REF_NAME') or read_git('branch', '--show-current') or 'unknown'
    repository = env.get('GITHUB_REPOSITORY', 'Voodoobrew101/Loot-Liquidator')
    changed = read_git('diff', '--name-only', 'HEAD').splitlines()
    dirty = any(path != TARGET.as_posix() for path in changed)
    ci = env.get('GITHUB_ACTIONS') == 'true'
    release = verified_release(env, commit, changed, read_git)
    if release:
        dirty = False  # Only the verified research product and release version changed.
    kind = 'local'
    prs = {}
    if ci and not dirty and commit != 'unknown':
        kind = 'pr' if pr else 'main' if release or env.get('GITHUB_REF') == 'refs/heads/main' else 'branch'
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
    if release:
        result['releaseTag'] = env.get('GITHUB_REF_NAME') or env['GITHUB_REF'].rsplit('/', 1)[1]
        result['verifiedGeneratedResearch'] = True
    if env.get('GITHUB_RUN_ID'):
        result['runURL'] = f'https://github.com/{repository}/actions/runs/{env["GITHUB_RUN_ID"]}'
    return result


def stamp():
    if not Path('LootLiquidator/ItemDBRuntime.lua').exists(): return
    env = os.environ
    event_path = env.get('GITHUB_EVENT_PATH')
    event = json.loads(Path(event_path).read_text()) if event_path else {}
    info = collect(env, event)
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    TARGET.write_text(json.dumps(info, sort_keys=True, indent=2) + '\n', encoding='utf-8', newline='\n')
    print('BUILD:', info['kind'], info['commit'][:12], 'PRs:', [p['number'] for p in info['prs']])


if __name__ == '__main__': stamp()
