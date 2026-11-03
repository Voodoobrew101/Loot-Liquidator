#!/usr/bin/env python3
"""Bounded, non-executing import of pinned AllTheThings Retail cost records.

Only literal equipment leaf nodes in the archived inventory are parsed. Full
Lua expressions, unsupported costs and conflicting variant costs stay held.
Inherited/faction requirements remain unavailable until independently checked.
"""
import hashlib
import json
from pathlib import Path
import re
import sys

from evidence_to_baselines import lua as scalar_lua

SOURCE = Path('database/research/att-exchanges-snapshot.json')
OUTPUT = Path('database/att-token-baselines.lua')


def lua(value):
    if value is None:
        return 'nil'
    if isinstance(value, dict):
        return '{' + ','.join((key if re.fullmatch(r'[A-Za-z_]\w*', key) else '[' + lua(key) + ']')
                              + '=' + lua(item) for key, item in sorted(value.items())) + '}'
    if isinstance(value, list):
        return '{' + ','.join(lua(item) for item in value) + '}'
    return scalar_lua(value)


def literal_table(text, start):
    if text[start] != '{':
        raise ValueError('Expected a literal table')
    depth = 0
    for pos in range(start, len(text)):
        if text[pos] == '{':
            depth += 1
        elif text[pos] == '}':
            depth -= 1
            if depth == 0:
                raw = text[start:pos + 1]
                # JSON is a strict data parser, never eval/load/exec.
                return json.loads(raw.replace('{', '[').replace('}', ']')), pos + 1
    raise ValueError('Unclosed literal table')


def parse_leaf(row):
    text = row['lua']
    match = re.match(r'^s\((\d+),(\d+),\{', text)
    if not match:
        raise ValueError('Not an equipment leaf')
    item = int(match[2])
    key = text.index('cost=') + 5
    values, end = literal_table(text, key)
    costs = []
    for value in values:
        if isinstance(value, int) and not isinstance(value, bool) and value > 0:
            costs.append({'kind': 'money', 'quantity': value})
        elif (isinstance(value, list) and len(value) == 3 and value[0] in ('i', 'c')
              and all(isinstance(n, int) and not isinstance(n, bool) and n > 0 for n in value[1:])):
            costs.append({'kind': 'item' if value[0] == 'i' else 'currency', 'id': value[1], 'quantity': value[2]})
        else:
            raise ValueError('Unsupported/nonintegral exchange cost')
    if not costs:
        raise ValueError('Empty cost is not free')
    fields = set(re.findall(r'(\w+)=', text))
    safe = {'b', 'c', 'cost', 'f', 'loc', 'lvl', 'modID', 'bonusID', 'awp'}
    requirements_unverified = bool(fields - safe)
    classes = re.search(r'(?:\{|,)c=(\{[\d,]+\})', text)
    class_ids = json.loads(classes[1].replace('{', '[').replace('}', ']')) if classes else []
    requirements_unverified = requirements_unverified or not class_ids
    if any(not 1 <= c <= 13 for c in class_ids):
        raise ValueError('Unknown class ID')
    level = re.search(r'(?:\{|,)lvl=(\d+)', text)
    return {'itemID': item, 'costs': costs, 'classMask': sum(2 ** (c - 1) for c in set(class_ids)) if class_ids else None,
            'minimumLevel': int(level[1]) if level else None,
            'requirementsUnverified': requirements_unverified,
            'line': row['line'], 'original': text}


def build(data=None):
    data = json.loads(SOURCE.read_text()) if data is None else data
    if data['gameMode'] != 'Retail' or data['licenseSPDX'] != 'MIT' or not data['revision']:
        raise ValueError('Only a pinned, attributed Retail source is supported')
    # The snapshot is bounded to the pre-existing research/discovery inventory.
    targets = set(data['targetTokenIDs'])
    grouped, held = {}, []
    for row in data['rows']:
        try:
            leaf = parse_leaf(row)
        except (ValueError, KeyError, json.JSONDecodeError) as error:
            held.append({'line': row['line'], 'reason': str(error)})
            continue
        for cost in leaf['costs']:
            if cost['kind'] == 'item' and cost['id'] in targets:
                grouped.setdefault(cost['id'], []).append(leaf)
    records = []
    url = f"https://github.com/{data['repository']}/blob/{data['revision']}/{data['path']}"
    for token, rows in sorted(grouped.items()):
        rewards, costs, masks, requirements, evidence = [], {}, {}, {}, []
        variants = {}
        for row in rows:
            variants.setdefault(row['itemID'], []).append(row)
        for item, alternatives in sorted(variants.items()):
            fingerprints = {json.dumps(r['costs'], sort_keys=True) for r in alternatives}
            if len(fingerprints) != 1:
                held.append({'tokenID': token, 'rewardID': item, 'reason': 'Variant cost conflict'})
                continue
            row = alternatives[0]
            rewards.append(item); costs[str(item)] = row['costs']; masks[str(item)] = row['classMask']
            requirements[str(item)] = {k: v for k, v in {
                'minimumLevel': row['minimumLevel'],
                'unverified': row['requirementsUnverified'] or None}.items() if v is not None}
            evidence += [{'line': r['line'], 'rewardID': item} for r in alternatives]
        if rewards:
            records.append({'recordID': f'att-token:{token}', 'tokenID': token, 'kind': 'exchange',
                'gameMode': 'Retail', 'requirements': {}, 'requirementsReviewed': False,
                'rewardSelection': 'choice', 'costsComplete': True, 'listComplete': False,
                'evidenceStatus': 'RESEARCH_RELATIONSHIP', 'independentReview': 'NOT_REVIEWED',
                'confidence0to100': 60, 'patchStartBuild': 1, 'patchEndBuild': 2147483647,
                'sourceRevision': data['revision'], 'sourceOrigin': 'ATT', 'sourceURLs': [url],
                'licenseSPDX': 'MIT', 'licenseText': data['licenseText'], 'rewards': rewards,
                'costs': costs, 'rewardClassMasks': masks, 'rewardRequirements': requirements,
                'sourceEvidence': evidence,
                'sourceAssumption': 'Pinned Retail equipment costs; base variants only; unsupported inherited requirements remain unavailable'})
    return records, held


def render():
    data = json.loads(SOURCE.read_text()); records, held = build(data)
    return '-- Generated by tools/att_token_references.py; ATT MIT attribution retained.\nreturn ' + lua({
        'schemaVersion': 1, 'tokenRewards': records, 'held': held,
        'sourceManifest': {'repository': data['repository'], 'revision': data['revision'],
                           'sourceSHA256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
                           'licenseSPDX': 'MIT', 'curioCostsEstablished': False},
        'licenseText': data['licenseText'],
        'curioEvidence': [{'tokenID': int(token), 'rewards': proof['rewards'],
                          'sourceURL': f"https://github.com/{data['repository']}/blob/{data['revision']}/db/Standard/Categories/Instances.lua",
                          'sourceRevision': data['revision']} for token, proof in sorted(data['midnightTierProof'].items())]}) + '\n'


if __name__ == '__main__':
    output = render()
    if '--check' in sys.argv:
        if not OUTPUT.exists() or OUTPUT.read_text() != output:
            sys.exit('ATT token references stale: run python3 tools/att_token_references.py')
    else:
        OUTPUT.write_text(output)
    records, held = build()
    print(f'ATT REFERENCES: {len(records)} exchanges; {sum(len(r["rewards"]) for r in records)} reward/cost relationships; {len(held)} held')
