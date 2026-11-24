"""Promote owner-submitted complete observations to the shared gear category.

Item numbers are provenance only. Original uploads, context measurements and
coverage flags remain immutable; cumulative snapshots are deduplicated by cast.
This is an empirical category reference, not a fitted skill/talent coefficient.
"""
import collections
import hashlib
import json
from pathlib import Path

import evidence_check
import evidence_to_baselines
from validate_craft_export import validate, compile_baselines

ROOT = Path(__file__).resolve().parents[1]
SOURCES = (
    '2026-11-07-disenchant-108-export-freeze',
    '2026-11-07-pr48-reported-3000ms',
    '2026-11-07-pr48-reported-3000ms-after-reload',
    '2026-11-07-pr49-82-skill-194-update',
    '2026-11-07-pr49-82-skill-200-additional',
    '2026-11-07-pr49-82-skill-97-clean',
    '2026-11-07-pr49-mixed-rarity-41-disenchants',
    '2026-11-07-pr49-rod-transition',
    '2026-11-07-pr49-20-cast-check',
)


def compile_records(root=ROOT):
    folder = Path(root) / 'research/integration/measured-captures'
    selected, hashes = {}, {}
    for name in SOURCES:
        paths = sorted((folder / name).glob('export-page-*.json'))
        pages = [json.loads(path.read_text(encoding='utf-8')) for path in paths]
        records, contexts, _ = validate(pages)
        staged = compile_baselines(pages)
        admitted = {op for row in staged['baselines'] for op in row['sourceRecordIDs']}
        if name == '2026-11-07-pr49-20-cast-check':
            # The prior owner-confirmed denominator review is a narrow, pinned
            # exception. Never clear the original export's global/Craft flags.
            review_path = folder / name / 'reviewed-baselines.json'
            reviewed = json.loads(review_path.read_text(encoding='utf-8'))
            proof_path = folder / name / 'coverage-review.json'
            proof = json.loads(proof_path.read_text(encoding='utf-8'))
            reviewed_ids = {op for row in reviewed['baselines'] for op in row['sourceRecordIDs']}
            if (proof['operatorConfirmedAttemptCount'] != 20 or len(reviewed_ids) != 20
                    or reviewed_ids != set(proof['sourceRecordIDs'])
                    or len(paths) != 1
                    or hashlib.sha256(paths[0].read_bytes()).hexdigest() != proof['sourceDecodedSHA256']):
                raise ValueError('Twenty-cast operator review changed')
            admitted.update(reviewed_ids)
            paths.extend((review_path, proof_path))
        for path in paths:
            hashes[path.relative_to(root).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
        for row in records:
            inputs = row.get('nominalInputs', row['inputs'])
            if row['operationID'] not in admitted or row['method'] != 'Disenchant' or row['recipeID'] != 13262:
                continue
            if len(inputs) != 1 or inputs[0].get('quantity') != 1:
                continue
            item = inputs[0]
            if (not isinstance(item.get('expansionID'), int)
                    or not isinstance(item.get('rarity'), int)
                    or item.get('classID') not in (2, 4, 19)):
                continue
            kind = {2: 'weapon', 4: 'armor', 19: 'profession'}[item['classID']]
            category = f"gear:{item['expansionID']}:{item['rarity']}:{kind}"
            context = contexts[row['contextID']]
            profile = {key: context.get(key) for key in ('baseSkill', 'bonusSkill', 'effectiveSkill', 'specialization')}
            # Duration and export-local context IDs may change on roundtrip.
            signature = {'input': inputs, 'outputs': row['outputs'], 'profile': profile, 'category': category}
            op = row['operationID']
            if op in selected:
                if selected[op] != signature:
                    raise ValueError('Conflicting duplicate disenchant: ' + op)
                continue
            selected[op] = signature
    categories = collections.defaultdict(dict)
    for op, row in selected.items():
        categories[row['category']][op] = row
    return [category_record(category, rows, hashes) for category, rows in sorted(categories.items())]


def category_record(category, selected, hashes):
    profiles = collections.Counter(json.dumps(row['profile'], sort_keys=True) for row in selected.values())
    expansion, rarity, kind = category.split(':')[1:]
    identity = 'owner-shared-disenchant:' + category
    n = len(selected)
    if not n:
        raise ValueError('No complete shared disenchant observations')
    ids = sorted({out['itemID'] for row in selected.values() for out in row['outputs']})
    counts = {}
    outputs = []
    for item in ids:
        quantities = [sum(out['quantity'] for out in row['outputs'] if out['itemID'] == item)
                      for row in selected.values()]
        positive = [q for q in quantities if q > 0]
        counts[item] = dict(collections.Counter(map(str, quantities)))
        outputs.append({'item': item, 'castsWithDrop': len(positive), 'totalQuantity': sum(quantities),
                        'min': min(positive), 'max': max(positive)})
    source = {'method': 'Disenchant', 'profession': 'Enchanting', 'input': category,
              'inputPerCast': 1, 'casts': n, 'outputs': outputs, 'lineage': identity,
              'observedDate': '2026-11-07', 'patch': '12.1', 'stale': False,
              'source': 'https://github.com/Voodoobrew101/Loot-Liquidator/tree/main/research/integration/measured-captures',
              'recipeID': 13262, 'expansionID': int(expansion), 'inputRarity': int(rarity),
              'inputClassID': {'weapon': 2, 'armor': 4, 'profession': 19}[kind],
              'referenceContextID': identity, 'referenceConditions': {}}
    errors = evidence_check.check_evidence(source)
    if errors:
        raise ValueError('; '.join(errors))
    records, notes = evidence_to_baselines.build({'usable': [
        {'kind': 'evidence', 'id': identity, 'record': source}]})
    if len(records) != 1 or notes['used'] != 1:
        raise ValueError('Shared category did not compile')
    record = records[0]
    record['recordID'] = record['recordID'].replace('evidence:', 'evidence:category:', 1)
    record['studyID'] = record['recordID']
    record.update(isDisenchantCategory=True, categoryReferenceOnly=False,
                  sharedCategoryCapture=True, fixedReference=True,
                  categoryContext='shared-observed-reference',
                  categoryItemLevelMin=1, categoryItemLevelMax=999,
                  categoryObservedCasts=n, observedOperations=n,
                  sourceRecordIDs=sorted(selected), sourceFileSHA256=hashes,
                  sharedSourceProfiles=[dict(json.loads(key), operations=count)
                                        for key, count in sorted(profiles.items())],
                  baselineStatus='Owner-approved shared disenchant category observations; measured source profiles preserved, no zero-skill assumption',
                  categoryGeneralizationBasis='Expansion, rarity and gear class; input item numbers are provenance only')
    for material in record['materials']:
        material['quantityCounts'] = counts[material['id']]
        material['boundsBasis'] = 'observed-positive-range-not-guaranteed'
    return record
