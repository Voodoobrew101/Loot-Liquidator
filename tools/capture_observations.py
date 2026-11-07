"""Compile direct cast observations into shared output identities, never yield rates.

Complete casts remain evidence that an item produced an output even when the
surrounding study has a denominator gap. Preserve those identities in ItemDB;
do not treat missing casts as failures, or observed stacks as guaranteed bounds.
Numerical cohorts still go through validate_craft_export.compile_baselines.
"""
from __future__ import annotations

import argparse
import collections
import hashlib
import json
from pathlib import Path

from validate_craft_export import validate

DEFAULT_ROOT = Path('research/integration/measured-captures')
DEFAULT_OUTPUT = Path('database/capture-observations.lua')


def lua(value):
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, list):
        return '{' + ','.join(lua(v) for v in value) + '}'
    if isinstance(value, dict):
        return '{' + ','.join('[' + lua(k) + ']=' + lua(v) for k, v in sorted(value.items())) + '}'
    raise TypeError(type(value))


def compile_observations(root):
    groups, seen = {}, {}
    for folder in sorted(root.glob('*')):
        paths = sorted(folder.glob('cast-page-*.json'))
        if not paths:
            continue
        pages = [json.loads(p.read_text(encoding='utf-8-sig')) for p in paths]
        records, contexts, studies = validate(pages)
        source_hash = hashlib.sha256(b''.join(p.read_bytes() for p in paths)).hexdigest()
        for r in records:
            # Context IDs are local to an export. Compare resolved facts to
            # reject a contradictory re-export rather than counting it twice.
            signature = json.dumps({'record': {k: v for k, v in r.items() if k != 'contextID'},
                                    'context': contexts[r['contextID']]}, sort_keys=True)
            previous = seen.get(r['operationID'])
            if previous is not None:
                if previous != signature:
                    raise ValueError('Conflicting capture operation: ' + r['operationID'])
                continue
            seen[r['operationID']] = signature
            if r['method'] != 'Disenchant' or r['outputCoverage'] != 'complete' or not r['outputs']:
                continue
            if len(r['inputs']) != 1 or r['inputs'][0]['quantity'] != 1:
                raise ValueError('Disenchant must consume one identified input')
            item = r['inputs'][0]
            if item.get('classID') not in (2, 4):
                raise ValueError('Disenchant input is not captured gear')
            key = (r['build'], item['itemID'], item.get('expansionID'))
            group = groups.setdefault(key, {'records': [], 'sources': set(), 'hashes': set(), 'censored': False})
            group['records'].append(r)
            group['sources'].add(folder.name)
            group['hashes'].add(source_hash)
            study = studies[r['studyID']]
            group['censored'] |= bool(study.get('censored') or study.get('truncated'))
    result = []
    for (build, input_id, expansion), group in sorted(groups.items()):
        records = group['records']
        ids = sorted({m['itemID'] for r in records for m in r['outputs']})
        materials = []
        for item_id in ids:
            positive = [m['quantity'] for r in records for m in r['outputs'] if m['itemID'] == item_id]
            materials.append({'id': item_id,
                              'observedPositiveQuantityHistogram': dict(sorted(collections.Counter(map(str, positive)).items())),
                              **{k: {'status': 'unknown', 'confidence': 0}
                                 for k in ('expectedQuantity', 'dropChance', 'minQuantity', 'maxQuantity')}})
        record_id = f'evidence:capture:Disenchant:{input_id}:exp{expansion}:build{build}'
        row = {'recordID': record_id, 'studyID': record_id, 'sourceKey': 'itemdb',
               'sourceKind': 'direct-player-cast-observation', 'method': 'Disenchant', 'profession': 'Enchanting',
               'inputItemID': input_id, 'inputCount': 1, 'recipeID': 13262, 'patchBuild': build,
               'source': '; '.join('research/integration/measured-captures/' + s for s in sorted(group['sources'])),
               'sourceSHA256': sorted(group['hashes']),
               'sourceRecordIDs': sorted(r['operationID'] for r in records),
               'observedOperations': len(records), 'observationOnly': True,
               'studyCoverageIncomplete': group['censored'], 'provisional': True,
               'baselineStatus': 'Direct player captures establish observed output identities; yield rates and guaranteed bounds are unknown',
               'materials': materials}
        if expansion is not None:
            row['expansionID'] = expansion
        result.append(row)
    return {'schemaVersion': 1, 'processing': result}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=DEFAULT_ROOT)
    parser.add_argument('--output', type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    result = compile_observations(args.root)
    text = '-- Generated by tools/capture_observations.py. Output identities only; no numerical yield claims.\nreturn ' + lua(result) + '\n'
    if args.check:
        if args.output.read_text(encoding='utf-8') != text:
            parser.exit(1, 'Capture observations are out of date\n')
    else:
        args.output.write_text(text, encoding='utf-8', newline='\n')
    print(f"CAPTURE OBSERVATIONS: {len(result['processing'])} input records; "
          f"{sum(r['observedOperations'] for r in result['processing'])} unique complete casts; no yield rates")


if __name__ == '__main__':
    main()
