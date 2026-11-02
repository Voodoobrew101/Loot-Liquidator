#!/usr/bin/env python3
"""D1c4: "can't be disenchanted" flags from the research team's v3 notes, for ItemDB.

The agents record items whose page says "Cannot be disenchanted" as v3 records with
type "noDisenchant" (itemID, itemName, source.url). This runs inside
tools/research_v3_to_baselines.py on every refresh and writes them as `noDisenchant` in
database/research-v3-baselines.lua; tools/compile_itemdb.lua then adds any item the game-file
list (database/sources/DB2Restrictions.lua) doesn't already have to ItemDB.restrictions as
`researchNoDisenchant`. Only adding: nothing here ever removes a game-file entry.

Left out with a reason: records excluded in corrections.jsonl or replaced by a later record,
the imported/ folder (a copy of the old addon's own tables), and records with no item ID or no
https source (owner decision 15: only a claim with no source at all is left out).
"""
import json
from collections import Counter

from research_v3_tokens import excluded_ids, https, is_excluded


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
            if isinstance(r, dict):
                r['_file'] = rel
                rows.append(r)
    return rows


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
            entry = by_item.setdefault(item, {'itemID': item, 'name': None, 'sourceURLs': set()})
            entry['sourceURLs'].add(url)
            if not entry['name'] and isinstance(r.get('itemName'), str) and r['itemName'].strip():
                entry['name'] = r['itemName'].strip()
    records = []
    for item in sorted(by_item):
        e = by_item[item]
        rec = {'itemID': item, 'sourceURLs': sorted(e['sourceURLs'])}
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
