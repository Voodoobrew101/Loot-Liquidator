"""Stage ATT JSON / direct-token exports for review; never approve runtime data."""
import argparse
import csv
import hashlib
import io
import json
from pathlib import Path


def positive(value):
    return isinstance(value, int) and not isinstance(value, bool) and value > 0


def stage(paths):
    documents, snapshots, candidates, pages, capped, unresolved = [], [], {}, [], set(), set()
    for path in paths:
        path = Path(path)
        raw = path.read_bytes()
        text = raw.decode('utf-8-sig')
        digest = hashlib.sha256(raw).hexdigest()
        documents.append({'file': path.name, 'sha256': digest})
        if text.lstrip().startswith('{'):
            data = json.loads(text)
            if data.get('schemaVersion') != 'loot-liquidator.att-research/1':
                raise ValueError(f'{path.name}: unsupported ATT export schema')
            if data.get('completeUniverse') is not False or data.get('automaticApproval') is not False:
                raise ValueError(f'{path.name}: research export must disclaim completeness/approval')
            page, total = data.get('page'), data.get('pages')
            if not positive(page) or not positive(total) or page > total:
                raise ValueError(f'{path.name}: invalid export pagination')
            pages.append({'document': digest, 'page': page, 'pages': total, 'totalTokens': data.get('totalTokens')})
            rows = data.get('records')
            if not isinstance(rows, list):
                raise ValueError(f'{path.name}: records must be a JSON array')
            for row in rows:
                if not isinstance(row, dict):
                    raise ValueError(f'{path.name}: each record must be an object')
                token = row.get('tokenID')
                rewards = row.get('rewards') or []
                if not positive(token) or not isinstance(rewards, list) or any(not positive(x) or x == token for x in rewards):
                    raise ValueError(f'{path.name}: invalid token/reward identities')
                snapshots.append({'document': digest, 'sourceKind': 'ATT', 'raw': row})
                limits = row.get('limitations') or {}
                if not isinstance(limits, dict):
                    raise ValueError(f'{path.name}: limitations must be an object')
                if len(rewards) >= 50 or any(limits.get(k) for k in ('rewardLimitReached', 'depthLimitReached', 'metadataTruncated')):
                    capped.add(token)
                scan = row.get('scan') or {}
                metadata = row.get('itemMetadata') or {}
                if not isinstance(scan, dict) or not isinstance(metadata, dict):
                    raise ValueError(f'{path.name}: source metadata and scan must be objects')
                if (not rewards and metadata.get('status') != 'FOUND_SOURCE_CANDIDATES') or scan.get('status') in ('NO_MATCH_OR_UNRESOLVED', 'CACHE_LIMIT_REACHED'):
                    unresolved.add(token)
                if (metadata.get('lastAttempt') or {}).get('status') == 'NO_MATCH_OR_UNRESOLVED':
                    unresolved.add(token)
                if metadata.get('metadataTruncated') or data.get('itemMetadataLimitReached'):
                    capped.add(token)
                if row.get('kind') not in ('open', 'exchange', 'unknown'):
                    raise ValueError(f'{path.name}: unsupported relationship kind')
                for reward in rewards:
                    key = (token, row['kind'], reward, 'ATT')
                    c = candidates.setdefault(key, {'tokenID': token, 'kind': row['kind'], 'rewardID': reward,
                        'sourceKind': 'ATT', 'reviewStatus': 'UNREVIEWED', 'runtimeEligible': False,
                        'inputQuantity': None, 'rewardQuantity': None, 'listComplete': False, 'documents': []})
                    if digest not in c['documents']:
                        c['documents'].append(digest)
        else:
            lines = [line for line in text.splitlines() if line and not line.startswith('#')]
            reader = csv.DictReader(io.StringIO('\n'.join(lines)), delimiter='|')
            expected = ['kind', 'inputID', 'inputQty', 'rewardID', 'rewardQty', 'vendorID', 'otherCosts', 'observations', 'lastSeen']
            if reader.fieldnames != expected:
                raise ValueError(f'{path.name}: unsupported direct-token header')
            for row in reader:
                token, reward, iq, oq = (int(row[k]) for k in ('inputID', 'rewardID', 'inputQty', 'rewardQty'))
                if not all(positive(x) for x in (token, reward, iq, oq)) or token == reward:
                    raise ValueError(f'{path.name}: invalid direct observation')
                legacy = row['kind'].startswith('att_')
                origin = 'ATT_LEGACY_CACHE' if legacy else 'DIRECT_CLIENT'
                snapshots.append({'document': digest, 'sourceKind': origin, 'raw': row})
                key = (token, row['kind'], reward, origin, iq, oq)
                c = candidates.setdefault(key, {'tokenID': token, 'kind': row['kind'], 'rewardID': reward,
                    'sourceKind': origin, 'reviewStatus': 'UNREVIEWED', 'runtimeEligible': False,
                    'inputQuantity': None if legacy else iq, 'rewardQuantity': None if legacy else oq,
                    'listComplete': False, 'documents': []})
                if digest not in c['documents']:
                    c['documents'].append(digest)
    missing = []
    for total in sorted({p['pages'] for p in pages}):
        seen = {p['page'] for p in pages if p['pages'] == total}
        missing.extend({'pages': total, 'page': n} for n in range(1, total + 1) if n not in seen)
    return {'schemaVersion': 'loot-liquidator.token-candidates/1', 'automaticApproval': False,
        'runtimeEligible': False, 'documents': documents, 'snapshots': snapshots,
        'candidates': sorted(candidates.values(), key=lambda c: (c['tokenID'], c['kind'], c['rewardID'], c['sourceKind'])),
        'coverage': {'completeUniverse': False, 'scope': 'supplied exports only; not all ATT/retail content',
            'missingPages': missing, 'cappedTokenIDs': sorted(capped), 'unresolvedTokenIDs': sorted(unresolved),
            'removalReady': False,
            'blockers': ['Define and independently review the relevant Retail token universe.',
                'Resolve missing pages, truncated lists, inherited requirements, variants and costs.',
                'Independently approve scoped relationships in database/records.lua; rebuild and test without ATT.',
                'Review and replace required source-location/difficulty/event/patch metadata presentation.']}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('exports', type=Path, nargs='+')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    try:
        result = stage(args.exports)
    except (ValueError, OSError, KeyError, TypeError) as error:
        parser.exit(2, f'Import rejected: {error}\n')
    if args.output.resolve() in {p.resolve() for p in args.exports}:
        parser.exit(2, 'Output must not overwrite an input export.\n')
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, ensure_ascii=False) + '\n')
    print(f"Staged {len(result['candidates'])} candidate relationships; zero runtime approvals. See coverage blockers.")


if __name__ == '__main__':
    main()
