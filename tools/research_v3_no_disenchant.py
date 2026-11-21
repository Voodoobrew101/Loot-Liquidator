#!/usr/bin/env python3
"""Source-scoped no-disenchant observations, separate from native hard flags.

The agents record items whose page says "Cannot be disenchanted" as v3 records with
type "noDisenchant" (itemID, itemName, source.url). This runs inside
tools/research_v3_to_baselines.py on every refresh and writes them as `noDisenchant` in
database/research-v3-baselines.lua. Catalog pages and base-variant observations
remain warnings with their original scope/provenance; they do not become global
item-ID prohibitions. Native DB2 restrictions remain independent and unchanged.

Left out with a reason: records excluded in corrections.jsonl or replaced by a later record,
the imported/ folder (a copy of the old addon's own tables), and records with no item ID or no
https source (owner decision 15: only a claim with no source at all is left out).
"""
import json
import hashlib
import re
from collections import Counter

from research_v3_tokens import excluded_ids, https, is_excluded


def load_rows(snapshot):
    rows = []
    base = snapshot / 'research' / 'v3' / 'evidence'
    for path in sorted(base.rglob('*.jsonl')):
        rel = path.relative_to(base).as_posix()
        for line_number, line in enumerate(path.read_text(encoding='utf-8').splitlines(), 1):
            line = line.strip()
            if not line:
                continue
            try:
                r = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(r, dict):
                raw = json.dumps(r, sort_keys=True, ensure_ascii=False, separators=(',', ':')).encode()
                r['_rawSHA256'] = hashlib.sha256(raw).hexdigest()
                r['_file'] = rel
                r['_line'] = line_number
                rows.append(r)
    return rows


def native_global_proof(row):
    """A prose/catalog claim is not proof of the native NO_DISENCHANT bit."""
    p = row.get('nativeRestrictionProof')
    return (isinstance(p, dict) and p.get('kind') == 'ItemSparseNO_DISENCHANT'
            and p.get('scope') == 'all-item-variants' and p.get('verified') is True
            and p.get('itemID') == row.get('itemID')
            and isinstance(p.get('flags0'), int) and not isinstance(p['flags0'], bool)
            and p['flags0'] & 0x8000 != 0
            and isinstance(p.get('build'), int) and not isinstance(p['build'], bool) and p['build'] > 0
            and isinstance(p.get('sourceSHA256'), str)
            and re.fullmatch(r'[a-fA-F0-9]{64}', p['sourceSHA256']) is not None)


def observation(row, url):
    scope = dict(row.get('restrictionScope') or {}) if isinstance(row.get('restrictionScope'), dict) else {}
    text = row.get('notes') or ''
    base = re.search(r'\bbase\s+(?:item\s*level|ilvl)\s*(\d+)', text, re.I)
    if base and 'itemLevel' not in scope:
        scope['itemLevel'] = int(base.group(1))
        scope['kind'] = 'catalog-base-variant'
    scope.setdefault('kind', 'catalog-observation')
    scope['allVariantsVerified'] = native_global_proof(row)
    build = re.search(r'\bbuild\s*(\d{4,})', text, re.I)
    if build: scope.setdefault('sourceBuild', int(build.group(1)))
    if row.get('patch') is not None: scope.setdefault('sourcePatch', row['patch'])
    return {'recordID': row.get('id'), 'sourceFile': 'research/v3/evidence/' + row['_file'],
            'sourceLine': row['_line'], 'rawSHA256': row['_rawSHA256'],
            'sourceURL': url, 'quote': row.get('quote'), 'notes': row.get('notes'),
            'recordedOn': row.get('recordedOn'), 'scope': scope,
            'nativeRestrictionProof': row.get('nativeRestrictionProof'),
            'globalRestriction': native_global_proof(row),
            'warning': 'Source reports no disenchant for its stated catalog/variant context; current native instance eligibility is not established.'}


def build_no_disenchant(snapshot):
    """-> (records sorted by itemID, Counter of left-out reasons).
    record = {'itemID': int, 'name': str (when known), 'sourceURLs': [https urls, sorted, unique]}"""
    rows = load_rows(snapshot)
    excluded = excluded_ids(snapshot)
    replaced = {r.get('replaces') for r in rows if r.get('replaces')}
    notes = Counter()
    by_item = {}
    for r in rows:
        if r.get('type') != 'noDisenchant':
            continue
        url = https((r.get('source') or {}).get('url')) if isinstance(r.get('source'), dict) else None
        item = r.get('itemID')
        if is_excluded(r, excluded):
            notes['excluded by corrections.jsonl'] += 1
        elif r['_file'].startswith('imported/'):
            notes['copy of the old addon tables (not counted)'] += 1
        elif r.get('id') and r['id'] in replaced:
            notes['replaced by a later correction'] += 1
        elif not isinstance(item, int) or isinstance(item, bool) or item <= 0:
            notes['no item ID'] += 1
        elif not url:
            notes['no https source'] += 1
        else:
            entry = by_item.setdefault(item, {'itemID': item, 'name': None, 'sourceURLs': set(), 'observations': []})
            entry['sourceURLs'].add(url)
            entry['observations'].append(observation(r, url))
            if not entry['name'] and isinstance(r.get('itemName'), str) and r['itemName'].strip():
                entry['name'] = r['itemName'].strip()
    records = []
    for item in sorted(by_item):
        e = by_item[item]
        rec = {'itemID': item, 'sourceURLs': sorted(e['sourceURLs']),
               'globalRestriction': any(o['globalRestriction'] for o in e['observations']),
               'observations': e['observations']}
        if e['name']:
            rec['name'] = e['name']
        records.append(rec)
    return records, notes


def summary(records, notes):
    two = sum(1 for r in records if len(r['sourceURLs']) >= 2)
    lines = [f'RESEARCH V3 NO-DISENCHANT: {len(records)} item(s) ({two} with two or more pages)']
    for why, n in sorted(notes.items()):
        lines.append(f'  left out: {n}: {why}')
    return '\n'.join(lines)
