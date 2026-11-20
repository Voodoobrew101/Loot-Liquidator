"""Prepare tag releases and upload verified distribution ZIPs to CurseForge."""
import argparse
import json
import os
from pathlib import Path
import re
import sys
import urllib.error
import urllib.request
import uuid

PROJECT_ID = 1760478
API = 'https://wow.curseforge.com/api'
TAG = re.compile(r'v?((?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)(?:-(alpha|beta|rc)(?:\.(?:0|[1-9][0-9]*))?)?)')


def release_version(tag):
    match = TAG.fullmatch(tag)
    if not match:
        raise ValueError('Expected vMAJOR.MINOR.PATCH, optionally -alpha.N, -beta.N or -rc.N')
    return match[1], 'alpha' if match[2] == 'alpha' else 'beta' if match[2] else 'release'


def prepare(tag, root=Path('.')):
    version, kind = release_version(tag)
    toc = root / 'LootLiquidator/LootLiquidator.toc'
    core = root / 'LootLiquidator/Core.lua'
    toc_text = toc.read_text(encoding='utf-8')
    core_text = core.read_text(encoding='utf-8')
    interfaces = re.findall(r'^## Interface: (.+)$', toc_text, re.M)
    if len(interfaces) != 1:
        raise ValueError('Expected exactly one Retail Interface declaration')
    names = []
    for value in interfaces[0].split(','):
        value = value.strip()
        if not value.isdecimal() or int(value) < 10000:
            raise ValueError('Invalid Retail Interface number')
        number = int(value)
        names.append(f'{number // 10000}.{number // 100 % 100}.{number % 100}')
    toc_text, toc_count = re.subn(r'^## Version: .+$', f'## Version: {version}', toc_text, flags=re.M)
    core_text, core_count = re.subn(r'^LA.version = ".*"$', f'LA.version = "{version}"', core_text, flags=re.M)
    if toc_count != 1 or core_count != 1:
        raise ValueError('Expected exactly one TOC version and runtime version')
    # Changelog is read as data, never evaluated by a shell.
    notes = root / 'CHANGELOG.md'
    changelog = notes.read_text(encoding='utf-8') if notes.is_file() else f'Loot Liquidator {version}.\n\nSource tag: {tag}'
    metadata = {'displayName': f'Loot Liquidator {version}', 'releaseType': kind,
                'changelog': changelog, 'changelogType': 'markdown',
                'gameVersionNames': list(dict.fromkeys(names))}
    toc.write_text(toc_text, encoding='utf-8', newline='\n')
    core.write_text(core_text, encoding='utf-8', newline='\n')
    dist = root / 'dist'
    dist.mkdir(exist_ok=True)
    (dist / 'curseforge-metadata.json').write_text(json.dumps(metadata, indent=2) + '\n', encoding='utf-8')
    print(f'Prepared {version} ({kind}) for CurseForge project {PROJECT_ID}')
    return metadata


def request_json(path, token, data=None, content_type=None):
    headers = {'X-Api-Token': token, 'User-Agent': 'Loot-Liquidator-release', 'Accept': 'application/json'}
    if content_type:
        headers['Content-Type'] = content_type
    request = urllib.request.Request(API + path, data=data, headers=headers)
    # Never forward the token to a redirect destination.
    class NoRedirect(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, req, fp, code, msg, headers, newurl):
            return None
    try:
        with urllib.request.build_opener(NoRedirect).open(request, timeout=120) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        raise ValueError(f'CurseForge returned HTTP {error.code}; check the project token and upload permissions') from None
    except (OSError, ValueError):
        raise ValueError('CurseForge request failed or returned invalid JSON; check the run before retrying an upload') from None


def resolve_versions(metadata, versions):
    ids = []
    for name in metadata['gameVersionNames']:
        matches = [v['id'] for v in versions if v['name'] == name]
        if len(matches) != 1:
            raise ValueError(f'Expected one CurseForge game version for {name}, found {len(matches)}; check the TOC Interface')
        ids.append(matches[0])
    return {**{k: v for k, v in metadata.items() if k != 'gameVersionNames'}, 'gameVersions': ids}


def multipart(metadata, archive):
    boundary = 'loot-liquidator-' + uuid.uuid4().hex
    body = (f'--{boundary}\r\nContent-Disposition: form-data; name="metadata"\r\n'
            'Content-Type: application/json\r\n\r\n').encode() + json.dumps(metadata).encode()
    body += (f'\r\n--{boundary}\r\nContent-Disposition: form-data; name="file"; '
             'filename="LootLiquidator.zip"\r\nContent-Type: application/zip\r\n\r\n').encode()
    body += archive.read_bytes() + f'\r\n--{boundary}--\r\n'.encode()
    return body, f'multipart/form-data; boundary={boundary}'


def upload(root=Path('.')):
    token = os.environ.get('CURSEFORGE_API_TOKEN', '').strip()
    if not token:
        raise ValueError('Add the CURSEFORGE_API_TOKEN Actions secret in GitHub repository Settings > Secrets and variables > Actions')
    metadata = json.loads((root / 'dist/curseforge-metadata.json').read_text(encoding='utf-8'))
    metadata = resolve_versions(metadata, request_json('/game/versions', token))
    body, content_type = multipart(metadata, root / 'dist/LootLiquidator.zip')
    # A POST is deliberately sent once: an uncertain response must not cause duplicate releases.
    result = request_json(f'/projects/{PROJECT_ID}/upload-file', token, body, content_type)
    if not isinstance(result, dict) or not isinstance(result.get('id'), int) or result['id'] <= 0:
        raise ValueError('Upload response contained no file ID; inspect CurseForge before retrying')
    message = f'Uploaded CurseForge file {result["id"]}: https://www.curseforge.com/wow/addons/loot-liquidator/files/{result["id"]}'
    print(message)
    if os.environ.get('GITHUB_STEP_SUMMARY'):
        with open(os.environ['GITHUB_STEP_SUMMARY'], 'a', encoding='utf-8') as summary:
            summary.write(message + '\n')
    return result['id']


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['prepare', 'upload'])
    args = parser.parse_args()
    try:
        prepare(os.environ.get('RELEASE_TAG', '')) if args.command == 'prepare' else upload()
    except (ValueError, OSError) as error:
        print(f'ERROR: {error}', file=sys.stderr)
        sys.exit(1)
