#!/usr/bin/env python3
"""C4b3: gear-token reward lists from the research team's v3 notes, for ItemDB.

Owner (session 15): "the rewards should be part of the compiler system for updating the itemdb,
so when item db is updated so are the [token] rewards". So this runs inside
tools/research_v3_to_baselines.py: every refresh of the research snapshot rebuilds the token
lists too, and tools/compile_itemdb.lua compiles them into ItemDB.tokenRewards.

How a token list is built (nothing typed by hand, nothing marked APPROVED here):
  * every v3 record with type "token" in the snapshot, except imported/ (a copy of the old
    addon table) and records another record says it `replaces`;
  * rewards of all records for the same token are merged; a reward with no item ID gets it from
    our own staged lists (database/research/tokens-midnight-s*.json) when the name matches;
  * a reward whose sources disagree on the item ID is left out (reported), never guessed;
  * confidence: 90 when every reward is backed by at least two different pages, else 60;
    20 less when no source says the list is complete. independentReview = NOT_REVIEWED.
Left out with a reason: vendor exchanges ("curios": the cost isn't recorded yet), tokens with
no usable reward ID.
"""
import json
import re
from collections import Counter, defaultdict
from pathlib import Path

STAGED = [Path('database/research/tokens-midnight-s1.json'), Path('database/research/tokens-midnight-s2.json')]
TWO_SOURCE_CONFIDENCE = 90
ONE_SOURCE_CONFIDENCE = 60
INCOMPLETE_PENALTY = 20
# Token data doesn't change with a game build; the window is "any Retail build".
PATCH_START, PATCH_END = 1, 2147483647


def norm(name):
    return re.sub(r"[^a-z0-9]", '', (name or '').lower().replace('’', "'"))


def https(url):
    return url if isinstance(url, str) and re.match(r'^https://\S+$', url) else None


def excluded_ids(snapshot):
    """research/v3/corrections.jsonl lines with field "exclude": true (later lines win), as
    {(recordID, file-or-None): bool}. Same rule as their build_estimates.py."""
    path = snapshot / 'research' / 'v3' / 'corrections.jsonl'
    out = {}
    if path.exists():
        for line in path.read_text().splitlines():
            try:
                c = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(c, dict) and c.get('field') == 'exclude' and c.get('recordID'):
                out[(c['recordID'], c.get('file'))] = c.get('value') is True
    return out


def is_excluded(row, excluded):
    for (rid, file), value in excluded.items():
        if rid == row.get('id') and (file is None or str(file).endswith(row['_file'])):
            if value:
                return True
    return False


def load_rows(snapshot):
    rows = []
    base = snapshot / 'research' / 'v3' / 'evidence'
    for path in sorted(base.rglob('*.jsonl')):
        rel = path.relative_to(base).as_posix()
        for line in path.read_text().splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                r = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(r, dict) and r.get('type') == 'token':
                r['_file'] = rel
                rows.append(r)
    return rows


def load_staged(paths=STAGED):
    """tokenID -> {'sources': [...], 'byName': {norm(name): (itemID, [urls])}}"""
    staged = {}
    for path in paths:
        if not path.exists():
            continue
        for t in json.loads(path.read_text()).get('tokens', []):
            if not isinstance(t.get('tokenID'), int):
                continue
            entry = staged.setdefault(t['tokenID'], {'sources': [], 'byName': {}})
            entry['sources'] += [u for u in t.get('sources', []) if https(u)]
            for w in t.get('rewards', []) or []:
                if isinstance(w.get('itemID'), int) and w.get('name'):
                    urls = [u for u in (w.get('source'), w.get('nameSource')) if https(u)]
                    entry['byName'][norm(w['name'])] = (w['itemID'], urls)
    return staged


def build_tokens(snapshot, revision, staged=None):
    staged = load_staged() if staged is None else staged
    notes = Counter()
    rows = load_rows(snapshot)
    excluded = excluded_ids(snapshot)
    replaced = {r.get('replaces') for r in rows if r.get('replaces')}
    by_token = defaultdict(list)
    for r in rows:
        if is_excluded(r, excluded):
            notes['excluded by corrections.jsonl'] += 1
        elif r['_file'].startswith('imported/'):
            notes['copy of the old addon token table (not counted)'] += 1
        elif r.get('id') and r['id'] in replaced:
            notes['replaced by a later correction'] += 1
        elif not isinstance(r.get('tokenItemID'), int) or r['tokenItemID'] <= 0:
            notes['no token item ID'] += 1
        else:
            by_token[r['tokenItemID']].append(r)
    records, conflicts = [], []
    for token_id in sorted(by_token):
        group = by_token[token_id]
        if any(r.get('howRedeemed') == 'vendor' for r in group):
            notes['vendor exchange (curio): cost not recorded yet'] += 1
            continue
        stage = staged.get(token_id, {'sources': [], 'byName': {}})
        # name -> {itemID: set(urls)}
        claims = defaultdict(lambda: defaultdict(set))
        token_urls, complete = set(), False
        for r in group:
            url = https((r.get('source') or {}).get('url'))
            if url:
                token_urls.add(url)
            complete = complete or r.get('listComplete') is True
            for w in r.get('rewards') or []:
                key = norm(w.get('name')) or f"id:{w.get('itemID')}"
                if isinstance(w.get('itemID'), int) and w['itemID'] > 0:
                    claims[key][w['itemID']].add(url or f"record:{r.get('id')}")
                else:
                    claims[key]  # name known, ID unknown so far
        for key, (item_id, urls) in stage['byName'].items():
            claims[key][item_id].update(urls or stage['sources'][:1] or ['staged-list'])
        rewards, weakest = [], 99
        for key in sorted(claims):
            ids = claims[key]
            if len(ids) > 1:
                conflicts.append({'tokenID': token_id, 'reward': key, 'itemIDs': sorted(ids)})
                notes['reward left out: sources disagree on its item ID'] += 1
                continue
            if not ids:
                notes['reward left out: no item ID in any source'] += 1
                continue
            (item_id, urls), = ids.items()
            if item_id == token_id or item_id in rewards:
                continue
            rewards.append(item_id)
            weakest = min(weakest, len(urls))
        if not rewards:
            notes['token left out: no usable reward item ID'] += 1
            continue
        sources = sorted(token_urls | {u for u in stage['sources']} |
                         {u for ids in claims.values() for us in ids.values() for u in us if https(u)})
        if not sources:
            notes['token left out: no https source'] += 1
            continue
        confidence = TWO_SOURCE_CONFIDENCE if weakest >= 2 else ONE_SOURCE_CONFIDENCE
        if not complete:
            confidence -= INCOMPLETE_PENALTY
        records.append({
            'recordID': f'v3token:{token_id}', 'tokenID': token_id,
            'tokenName': next((r.get('tokenName') for r in group if r.get('tokenName')), None),
            'kind': 'open', 'gameMode': 'Retail',
            'evidenceStatus': 'RESEARCH_RELATIONSHIP', 'independentReview': 'NOT_REVIEWED',
            'listComplete': complete, 'requirements': {}, 'requirementsReviewed': False,
            'confidence0to100': confidence, 'patchStartBuild': PATCH_START, 'patchEndBuild': PATCH_END,
            'sourceRevision': revision, 'sourceURLs': sources[:20], 'rewards': sorted(rewards),
            'researchRecordIDs': sorted(str(r.get('id')) for r in group),
        })
    return records, notes, conflicts


def summary(records, notes, conflicts):
    by_conf = Counter(r['confidence0to100'] for r in records)
    lines = [f'RESEARCH V3 TOKENS: {len(records)} token(s), {sum(len(r["rewards"]) for r in records)} rewards '
             f'(confidence {", ".join(f"{c}%: {n}" for c, n in sorted(by_conf.items(), reverse=True))})']
    for why, n in sorted(notes.items()):
        lines.append(f'  left out: {n}: {why}')
    for c in conflicts[:10]:
        lines.append(f"  conflict: token {c['tokenID']} reward {c['reward']}: item IDs {c['itemIDs']}")
    return '\n'.join(lines)
