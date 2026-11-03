#!/usr/bin/env python3
"""Reproduce research-data readiness without calling it live recommendation coverage.

The denominator is the pinned v3 import's method/input/batch records, including
gear groups. It is not an exhaustive Retail item inventory. This audit does not
assume a character can process an item, manufacture market prices, or turn an
unknown expected quantity into zero.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path

import research_v3_to_baselines as v3


def audit(snapshot=v3.DEFAULT_SNAPSHOT):
    records, notes, total, counted, unplaced = v3.build(snapshot)
    fields = ('dropChance', 'expectedQuantity', 'minQuantity', 'maxQuantity')
    materials = [m for r in records for m in r['materials']]
    methods = {}
    for method in sorted({r['method'] for r in records}):
        subset = [r for r in records if r['method'] == method]
        methods[method] = {
            'records': len(subset),
            'all_listed_expectations_known': sum(all('value' in m['expectedQuantity'] for m in r['materials']) for r in subset),
            'some_listed_expectation_known': sum(any('value' in m['expectedQuantity'] for m in r['materials']) for r in subset),
        }
    return {
        'methodology': 'v3-data-readiness/1',
        'scope': 'Pinned v3 method/input/batch records; gear groups are records, not individual items. Known listed expectations do not prove a complete output universe or current Retail applicability.',
        'source_snapshot': json.loads((snapshot / 'SNAPSHOT.json').read_text()),
        'artifact_sha256': {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in (v3.DEFAULT_OUTPUT, Path('LootLiquidator/ItemDBRuntime.lua'))},
        'actionable_gold_coverage': {
            'eligible_items': None, 'supported_actionable_items': None, 'percent': None,
            'reason': 'No exhaustive eligible-item inventory, validated current character profile, or controlled end-to-end action-selection census. Data readiness is a separate diagnostic.',
        },
        'market_price_coverage': {'percent': None, 'reason': 'No live market-price snapshot supplied; missing research is counted independently.'},
        'processing_records': len(records),
        'exact_input_ids': len({r['inputItemID'] for r in records if r.get('inputItemID')}),
        'gear_group_records': sum('gearKey' in r for r in records),
        'material_entries': len(materials),
        'field_status': {f: dict(sorted(Counter(m[f]['status'] for m in materials).items())) for f in fields},
        'methods': methods,
        'source_rows_after_corrections': total,
        'non_reference_rows_considered': counted,
        'unplaced_non_reference_drop_rows': unplaced,
        'converter_notes': dict(sorted(notes.items())),
        'missing_expectations': [
            {'record_id': r['recordID'], 'output_ids': [m['id'] for m in r['materials'] if 'value' not in m['expectedQuantity']]}
            for r in records if any('value' not in m['expectedQuantity'] for m in r['materials'])
        ],
    }


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    text = json.dumps(audit(), indent=2, sort_keys=True) + '\n'
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text)
    else:
        print(text, end='')
