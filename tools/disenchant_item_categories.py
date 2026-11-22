#!/usr/bin/env python3
"""Build-only native scope for ordinary disenchant studies; no yield calculation.

Pinned Item/ItemSparse supply default item identity, not an assertion about an
unreported historical upgrade. Explicit study variant scope wins. Raw studies
remain in their original snapshot; the generated map contains no guessed rates.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from evidence_to_baselines import lua

KINDS = {2: 'weapon', 4: 'armor', 19: 'profession'}


def load_lua(path):
    local_runner = Path(__file__).resolve().parents[2] / '.tools/python313'
    if local_runner.is_dir():
        sys.path.insert(0, str(local_runner))
    from lupa.lua51 import LuaRuntime
    runtime = LuaRuntime(unpack_returned_tuples=True)

    def plain(value):
        if hasattr(value, 'items'):
            result = {key: plain(item) for key, item in value.items()}
            if result and set(result) == set(range(1, len(result) + 1)):
                return [result[index] for index in range(1, len(result) + 1)]
            return result
        return value
    return plain(runtime.execute(Path(path).read_text(encoding='utf-8')))


def source_review(document):
    """Adapt the independently reviewed, fully quoted offline provenance manifest."""
    if 'offlineArchiveItems' not in document:
        return document
    result = {'schemaVersion': 1, 'items': {}, 'records': {}}
    for item in document['offlineArchiveItems']:
        sources = sorted({row['sourceURL'] for row in item['sourceEvidence'] if row.get('sourceURL', '').startswith('https://')})
        result['items'][str(item['itemID'])] = {
            'disposition': 'archive', 'reason': item['reason'], 'sources': sources}
    for item in document['scopeReviews']:
        decision = item['decision']
        if decision not in ('ordinary-gear-archive-band-unknown-source', 'isolate-mixed-version-source-cohort',
                            'ordinary-native-era-gear', 'distinct-profession-gear-category'):
            raise ValueError(f'Unreviewed source-scope disposition: {decision}')
        sources = sorted({row['sourceURL'] for row in item['sourceEvidence'] if row.get('sourceURL', '').startswith('https://')})
        for record_id in item['compiledRecordIDs']:
            if decision in ('ordinary-gear-archive-band-unknown-source', 'isolate-mixed-version-source-cohort'):
                result['records'][record_id] = {'disposition': 'archive', 'reason': item['reason'], 'sources': sources}
            elif decision == 'ordinary-native-era-gear':
                result['records'][record_id] = {'disposition': 'category', 'reason': item['reason'], 'sources': sources,
                                               'scope': {'expansionID': int(item['native']['ExpansionID'])}}
    return result


def read_native(folder, build=70961):
    folder = Path(folder)
    names = ('Item', 'ItemSparse', 'ItemDisenchantLoot')
    tables, proofs = {}, {}
    for name in names:
        path = folder / f'{name}-{build}.csv'
        data = path.read_bytes()
        proofs[name] = {'file': path.name, 'sha256': hashlib.sha256(data).hexdigest()}
        with path.open(encoding='utf-8-sig', newline='') as stream:
            tables[name] = {int(row['ID']): row for row in csv.DictReader(stream)}
    return tables, proofs


def classify(item_id, tables):
    item, sparse = tables['Item'].get(item_id), tables['ItemSparse'].get(item_id)
    if not item or not sparse:
        return {'disposition': 'unmapped', 'reason': 'No pinned Retail Item and ItemSparse identity'}
    class_id = int(item['ClassID'])
    result = {'name': sparse['Display_lang'], 'classID': class_id,
              'subclassID': int(item['SubclassID']), 'expansionID': int(sparse['ExpansionID']),
              'rarity': int(sparse['OverallQualityID']), 'itemLevel': int(sparse['ItemLevel']),
              'noDisenchant': bool(int(sparse['Flags_0']) & 32768)}
    if class_id not in KINDS:
        return dict(result, disposition='non-gear', reason='Pinned native item class is not disenchant equipment')
    bands = []
    for band in tables['ItemDisenchantLoot'].values():
        if (int(band['ExpansionID']), int(band['Quality']), int(band['Class'])) != (
                result['expansionID'], result['rarity'], class_id):
            continue
        if int(band['Subclass']) not in (-1, result['subclassID']):
            continue
        lo, hi = int(band['MinLevel']), int(band['MaxLevel'])
        if lo <= result['itemLevel'] <= hi:
            bands.append({'id': int(band['ID']), 'min': lo, 'max': hi})
    if not bands:
        return dict(result, disposition='unmapped', reason='No matching pinned native disenchant category band')
    # Boundary levels sometimes match two native bands. Restrict the estimate to
    # their intersection rather than arbitrarily selecting either category.
    result.update(disposition='category', nativeBandIDs=sorted(b['id'] for b in bands),
                  minItemLevel=max(b['min'] for b in bands),
                  maxItemLevel=min(b['max'] for b in bands))
    return result


def generate(item_ids, tables, proofs, review=None, build=70961):
    review = source_review(review) if review else {'schemaVersion': 1, 'items': {}, 'records': {}}
    if review.get('schemaVersion') != 1:
        raise ValueError('Unsupported disenchant source-scope review')
    rows = {item_id: classify(item_id, tables) for item_id in sorted(set(item_ids))}
    for text, policy in review.get('items', {}).items():
        item_id = int(text)
        if item_id not in rows:
            continue
        if policy.get('disposition') not in ('archive', 'exception', 'category'):
            raise ValueError(f'Invalid scope policy for {item_id}')
        if not policy.get('reason') or not policy.get('sources') or not all(
                url.startswith('https://') for url in policy['sources']):
            raise ValueError(f'Source proof required for scope policy {item_id}')
        rows[item_id]['policy'] = policy
    for identity, policy in review.get('records', {}).items():
        if policy.get('disposition') not in ('archive', 'category', 'exception') or not policy.get('reason') \
                or not policy.get('sources') or not all(url.startswith('https://') for url in policy['sources']):
            raise ValueError(f'Source proof required for record scope policy {identity}')
    bands = {}
    for row in tables['ItemDisenchantLoot'].values():
        class_id = int(row['Class'])
        if class_id in KINDS and int(row['Subclass']) == -1:
            key = f"gear:{row['ExpansionID']}:{row['Quality']}:{KINDS[class_id]}"
            bands.setdefault(key, []).append({'id': int(row['ID']), 'min': int(row['MinLevel']), 'max': int(row['MaxLevel'])})
    for values in bands.values():
        values.sort(key=lambda row: row['id'])
    return {'schemaVersion': 1, 'build': build, 'nativeSources': proofs,
            'items': rows, 'recordPolicies': review.get('records', {}), 'bands': bands}


def category_remainders(snapshot, categories, original_records):
    """Use the existing estimator after removing already represented raw lineages.

    This is not item-ID deduplication: a later independent study of the same item
    remains. Only real source record IDs/study keys present in the category are
    removed, before the estimator's original counting and context logic runs.
    """
    import research_v3_to_baselines as compiler
    source_ids, study_keys, represented_by = set(), set(), {}
    for category in categories:
        for field, target in (('categorySourceRecordIDs', source_ids), ('categorySourceStudyIDs', study_keys)):
            for identity in category.get(field, []):
                target.add(identity)
                represented_by.setdefault(identity, set()).add(category['recordID'])
    original_loader = compiler.load_calculator
    # Compare the filtered and unfiltered *same compiler* outputs. The checked
    # baseline file can intentionally predate unrelated producer changes; this
    # adapter must neither import that drift nor mistake it for a DE change.
    fresh, _, _, _, _ = compiler.build(snapshot)
    fresh = {row['recordID']: row for row in fresh}
    removed = []

    def factory(folder):
        module = original_loader(folder)

        def filter_rows(loader):
            def load():
                kept = []
                for row in loader():
                    if row.get('method') == 'Disenchant' and (
                            row.get('id') in source_ids or row.get('studyKey') in study_keys):
                        removed.append(row)
                    else:
                        kept.append(row)
                return kept
            return load
        module.load = filter_rows(module.load)
        module.load_reviewed_source_rows = filter_rows(module.load_reviewed_source_rows)
        return module
    compiler.load_calculator = factory
    try:
        rebuilt, _, _, _, _ = compiler.build(snapshot)
    finally:
        compiler.load_calculator = original_loader
    original = {row['recordID']: row for row in original_records}
    rebuilt = {row['recordID']: row for row in rebuilt}
    # A DE-only evidence adapter must never change another processing method.
    for identity, row in fresh.items():
        if row['method'] != 'Disenchant' and rebuilt.get(identity) != row:
            raise ValueError(f'Unrelated source rebuild drift: {identity}')
    for identity, row in rebuilt.items():
        if identity not in fresh:
            raise ValueError(f'Unexpected newly generated source record: {identity}')
    replacements, represented = {}, {}
    affected_inputs = {row.get('inputItemID') for row in removed}
    aliases_by_input = {}
    for row in removed:
        aliases_by_input.setdefault(row.get('inputItemID'), set()).update(
            name for key in ('id', 'studyKey') for name in represented_by.get(row.get(key), ()))
    for identity, row in original.items():
        if row['method'] != 'Disenchant':
            continue
        replacement = rebuilt.get(identity)
        if replacement == fresh.get(identity):
            continue
        if row.get('inputItemID') not in affected_inputs and row.get('inputItemID') is not None:
            raise ValueError(f'DE rebuild changed an unrelated input: {identity}')
        if replacement:
            replacements[identity] = replacement
        else:
            aliases = aliases_by_input.get(row.get('inputItemID'), ())
            if row.get('gearKey'):
                aliases = {category['recordID'] for category in categories if category.get('gearKey') == row['gearKey']}
            if not aliases:
                raise ValueError(f'Missing actual category lineage for represented record: {identity}')
            represented[identity] = sorted(aliases)
    return replacements, represented, {'removedRawRecordIDs': sorted({row['id'] for row in removed}),
                                       'removedStudyKeys': sorted({row['studyKey'] for row in removed if row.get('studyKey')})}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--native-dir', type=Path, required=True)
    parser.add_argument('--build', type=int, default=70961)
    parser.add_argument('--input-ids', type=Path,
                        help='JSON list of exact DE input IDs from compiler inventory')
    parser.add_argument('--review', type=Path, default=Path('database/research/disenchant-source-scope-review.json'))
    parser.add_argument('--output', type=Path, default=Path('database/disenchant-item-categories.lua'))
    parser.add_argument('--report', type=Path)
    parser.add_argument('--snapshot', type=Path, default=Path('database/research/v3-snapshot'))
    parser.add_argument('--skip-remainders', action='store_true', help='Synthetic mapping tests only')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args(argv)
    tables, proofs = read_native(args.native_dir, args.build)
    review = json.loads(args.review.read_text()) if args.review.exists() else None
    inputs = set(json.loads(args.input_ids.read_text())) if args.input_ids else set()
    original = load_lua('database/research-v3-baselines.lua')['processing']
    for path in ('database/evidence-baselines.lua', 'database/capture-observations.lua'):
        for row in load_lua(path).get('processing', []):
            if row.get('method') == 'Disenchant' and row.get('inputItemID'):
                inputs.add(row['inputItemID'])
    inputs.update(row['inputItemID'] for row in original if row['method'] == 'Disenchant' and row.get('inputItemID'))
    document = generate(inputs, tables, proofs, review, args.build)
    if not args.skip_remainders:
        categories = load_lua('database/disenchant-category-baselines.lua')['processing']
        replacements, represented, dedupe = category_remainders(args.snapshot, categories, original)
        document['replacements'], document['represented'] = replacements, represented
        document['dedupe'] = dedupe
    content = ('-- Generated by tools/disenchant_item_categories.py; build-only default identity, no yields.\n'
               'return ' + lua(document) + '\n')
    if args.check:
        if not args.output.exists() or args.output.read_text() != content:
            parser.exit(1, f'{args.output} is out of date\n')
    else:
        args.output.write_text(content)
    if args.report:
        args.report.write_text(json.dumps(document, indent=2) + '\n')
    from collections import Counter
    print('DISENCHANT ITEM SCOPES:', dict(Counter(row['disposition'] for row in document['items'].values())))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
