#!/usr/bin/env python3
"""Trace stored source fields through admission, runtime values and tooltips.

This is a fixed-price offline data-flow census, not real-character eligibility,
live-price coverage, or exhaustive Retail coverage. All source variants remain
visible in the CSV; represented alternatives never count as independent studies.
"""
import argparse
from collections import Counter, defaultdict
import csv
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile


def items(value):
    return value if isinstance(value, list) else []


def output_ids(material):
    return material.get('rankIDs') or [material['id']]


def get_field(material, name):
    return material.get(name, {}).get('value')


def identity(record):
    return record.get('inputItemID', record.get('gearKey'))


def make_ledger(data):
    compiled = data['compiled']['processing'] + data['compiled']['legacy']['processing']
    index = defaultdict(list)
    for record in compiled:
        for material in record['materials']:
            for item in output_ids(material):
                index[(record['method'], identity(record), item)].append((record, material))
    probes = {p['key']: p for p in data['probes']}
    rows = []

    def add(layer, record, material, status=''):
        inp = identity(record)
        batch = record.get('inputCount', record.get('inputCountPerOperation'))
        out = material['id']
        matches = index.get((record['method'], inp, out), [])
        key = f"{record['method']}:{inp}:x{batch}"
        probe = probes.get(key, {})
        runtime_material = next((m for m in probe.get('materials', []) if out in output_ids(m)), {})
        mean = runtime_material.get('expectedQuantity')
        if matches:
            direct_ids = {record.get('recordID'), 'research:' + record.get('recordID', ''),
                          'reference:' + record.get('recordID', '')}
            normalization = ('source record compiled' if any(r['recordID'] in direct_ids for r, _ in matches)
                             else 'related output compiled; candidate selection/lineage kept separate')
            if any(m.get('rankIDs') for _, m in matches):
                normalization = 'rank-family reference; quality alternatives not summed'
            if any(m.get('referenceCorrection') for _, m in matches):
                normalization = 'contradictory source mean preserved; conservative derived alternative compiled'
        else:
            normalization = status or 'source present; not admitted'
        reason = probe.get('reason', '')
        if matches and mean is not None:
            reason = 'Usable expectation reaches runtime; alternate source need not contribute twice'
        elif matches and probe.get('state') in ('value', 'partial_value'):
            reason = 'Output remains unknown or context/rank excluded; other outputs can be valued'
        elif not matches:
            reason = status or 'Needs identity, unit, recipe or context review'
        if runtime_material.get('unavailableReason'):
            reason = runtime_material['unavailableReason']
        visible = bool(runtime_material and f"Material {runtime_material['id']} " in probe.get('tooltip', ''))
        rows.append({
            'source_layer': layer, 'source_record': record.get('recordID', ''),
            'method': record['method'], 'input': inp, 'input_count': batch, 'output_item_id': out,
            'source_expected_quantity': get_field(material, 'expectedQuantity'),
            'source_mean_status': material.get('expectedQuantity', {}).get('status', 'raw reference'),
            'source_chance': get_field(material, 'dropChance'),
            'source_minimum': get_field(material, 'minQuantity'), 'source_maximum': get_field(material, 'maxQuantity'),
            'compiled_records': ' | '.join(r['recordID'] for r, _ in matches),
            'compiled_input_counts': ' | '.join(str(r['inputCount']) for r, _ in matches),
            'compiled_conditional_requirements': ' | '.join(m['conditionalReference'] for _, m in matches if m.get('conditionalReference')),
            'compiled_mean_values': ' | '.join(str(get_field(m, 'expectedQuantity')) if get_field(m, 'expectedQuantity') is not None else 'unknown' for _, m in matches),
            'compiled_chance_values': ' | '.join(str(get_field(m, 'dropChance')) if get_field(m, 'dropChance') is not None else 'unknown' for _, m in matches),
            'compiled_minimum_values': ' | '.join(str(get_field(m, 'minQuantity')) if get_field(m, 'minQuantity') is not None else 'unknown' for _, m in matches),
            'compiled_maximum_values': ' | '.join(str(get_field(m, 'maxQuantity')) if get_field(m, 'maxQuantity') is not None else 'unknown' for _, m in matches),
            'normalization': normalization, 'runtime_state': probe.get('state', 'not probed'),
            'runtime_expected_quantity': mean, 'runtime_chance': runtime_material.get('chance'),
            'runtime_minimum': runtime_material.get('minQuantity'), 'runtime_maximum': runtime_material.get('maxQuantity'),
            'runtime_mean_derived': runtime_material.get('derivedMean', False),
            'runtime_mean_basis': runtime_material.get('meanBasis'),
            'conditional_expected_quantity': runtime_material.get('conditionalExpectedQuantity'),
            'conditional_value_per_input_copper': (runtime_material['conditionalExpectedValue']/probe['inputCount']
                if runtime_material.get('conditionalExpectedValue') is not None else None),
            'operation_unverified': probe.get('operationUnverified', False),
            'separate_rank_references': json.dumps(runtime_material.get('rankReferences', []), sort_keys=True),
            'synthetic_value_per_input_copper': probe.get('valueCopperPerInput'),
            'visible_in_compact_breakdown': visible,
            'reason': reason if visible or mean is None else reason + '; row may be beyond twelve-row compact display limit',
        })

    for layer, dataset in [('historical-reference', data['reference']['frozen']),
                           ('legacy', data['reference']['legacy']), ('v3-evidence-import', data['v3']),
                           ('other-evidence-import', data['evidence']), ('calculator', data['calculators'])]:
        for record in items(dataset.get('processing')):
            for material in record['materials']:
                add(layer, record, material)
    for record in data['research']['processing']:
        material = {'id': record['outputItemID'], 'expectedQuantity': record['expectedQuantity'],
                    'dropChance': record['dropChance'], 'minQuantity': record['yieldMin'], 'maxQuantity': record['yieldMax']}
        add('research-snapshot', record, material,
            'Pinned research row not admitted; inspect unsupported/multi-reagent method or unresolved quality alternative')
    for table, method in [('mill', 'Mill'), ('prospect', 'Prospect')]:
        for inp, materials in data['reference']['frozen']['rawTables'][table].items():
            for material in materials:
                # Raw mean is explicitly per input. This is a nominal five-input
                # reference conversion, never an invented observed cast count.
                normalized = {'id': material['id'],
                    'expectedQuantity': {'value': material['amountOfMats'] * 5},
                    'dropChance': {'value': material['matRate']},
                    'minQuantity': {'value': material['minAmount']}, 'maxQuantity': {'value': material['maxAmount']}}
                add('raw-historical-quality-variant', {'recordID': f"raw:{method}:{inp}:{material['id']}",
                    'method': method, 'inputItemID': int(inp), 'inputCount': 5}, normalized,
                    'Unresolved processing input or quality family; raw source preserved')
    return rows


def report(data, baseline):
    probes = data['probes']
    previous = {p['key']: p for p in baseline.get('probes', [])}
    compiled = data['compiled']['processing']
    return {
        'methodology': 'source-to-tooltip/1', 'profile': data['probeProfile'],
        'primary_actionable_coverage': None,
        'primary_coverage_reason': 'Eligible-item inventory and real character/price environment not supplied; these are offline source profiles.',
        'compiled_processing_records': len(compiled),
        'compiled_sources': dict(Counter(r['sourceKey'] for r in compiled)),
        'compiled_material_entries': sum(len(r['materials']) for r in compiled),
        'legacy_records': len(data['compiled']['legacy']['processing']),
        'reference_mean_corrections': len(data['compiled']['buildReport']['referenceCorrections']),
        'reference_quality_pools': data['compiled']['buildReport']['referenceRankPools'],
        'calculator_input_records': len(data['calculators']['processing']),
        'calculator_material_entries': sum(len(r['materials']) for r in data['calculators']['processing']),
        'calculator_held': data['calculators']['held'],
        'offline_profiles': len(probes),
        'baseline_profiles': len(previous),
        'added_profiles': [p['key'] for p in probes if p['key'] not in previous],
        'offline_states_before': dict(Counter(p['state'] for p in previous.values())),
        'offline_states_after': dict(Counter(p['state'] for p in probes)),
        'offline_states_after_comparable': dict(Counter(p['state'] for p in probes if p['key'] in previous)),
        'new_numeric_profiles': [p['key'] for p in probes if p['state'] in ('value', 'partial_value')
            and previous.get(p['key'], {}).get('state') == 'no_model'],
        'newly_complete_profiles': [p['key'] for p in probes if p['state'] == 'value'
            and previous.get(p['key'], {}).get('state') == 'partial_value'],
        'regressed_numeric_profiles': [p['key'] for p in probes if p['state'] not in ('value', 'partial_value')
            and previous.get(p['key'], {}).get('state') in ('value', 'partial_value')],
        'remaining_no_model': [{'key': p['key'], 'reason': p.get('reason')} for p in probes if p['state'] == 'no_model'],
        'remaining_partial_profiles': [p['key'] for p in probes if p['state'] == 'partial_value'],
        'runtime_errors': [p for p in probes if p['state'] == 'runtime_error'],
        'token_catalog_records': len(data['compiled']['tokenRewards']),
        'token_reward_relations': sum(len(r['rewards']) for r in data['compiled']['tokenRewards']),
    }


def write_reports(data, baseline, folder):
    folder.mkdir(parents=True, exist_ok=True)
    rows = make_ledger(data)
    with (folder / 'processing-ledger.csv').open('w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=list(rows[0]), lineterminator='\n'); writer.writeheader()
        writer.writerows({k: ('unknown' if v is None else 'none' if v == '' else v)
                          for k, v in row.items()} for row in rows)
    tokens = {r['tokenID']: r for r in data['compiled']['tokenRewards']}
    token_rows = []
    for token, record in sorted(tokens.items()):
        token_rows.append({'item': token, 'kind': 'compiled-token', 'recordID': record['recordID'],
            'rewardIDs': [r['itemID'] if isinstance(r, dict) else r for r in record['rewards']],
            'redemption': record['kind'], 'sourceOrigin': record.get('sourceOrigin', 'research'),
            'costsComplete': record.get('costsComplete', record['kind']=='open'),
            'sourceRevision': record['sourceRevision'],
            'status': ('Reward relationships visible; full exchange costs unresolved, no available redemption action'
                if record.get('costsComplete') is False else
                'Shared runtime route covered by integration fixtures; actual class, inventory, variant and prices resolved in client'),
            'rewardRequirements': record.get('rewardRequirements', {}),
            'costs': record.get('costs', {})})
    candidates = data['compiled']['compat'].get('ResearchTokenCandidates', {})
    for item in sorted(candidates, key=int):
        if int(item) not in tokens:
            token_rows.append({'item': int(item), 'kind': 'unverified-exchange-discovery-hint',
                'status': 'No validated reward relationship. Includes reagents/currencies; do not assume every hint is a gear token.'})
    (folder / 'token-ledger.json').write_text(json.dumps(token_rows, indent=2) + '\n')
    summary = report(data, baseline)
    summary['processing_source_rows'] = len(rows)
    summary['unverified_exchange_hints'] = len(token_rows) - len(tokens)
    summary['runtime_artifact_sha256'] = hashlib.sha256(Path('LootLiquidator/ItemDBRuntime.lua').read_bytes()).hexdigest()
    (folder / 'summary.json').write_text(json.dumps(summary, indent=2, sort_keys=True) + '\n')
    # Keep each actual offline rendering once, instead of duplicating it for
    # every source transcription in the processing ledger.
    with (folder / 'runtime-probes.jsonl').open('w') as file:
        for probe in data['probes']:
            file.write(json.dumps(probe, sort_keys=True) + '\n')
    return summary


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--data', type=Path, help='Reuse an export_pipeline_audit.lua --probe JSON file')
    parser.add_argument('--baseline', type=Path, default=Path('docs/usable-data-audit/baseline-probes.json'))
    parser.add_argument('--output', type=Path, default=Path('docs/usable-data-audit'))
    parser.add_argument('--validate', action='store_true', help='Fail on runtime errors or loss of a baseline numeric profile')
    args = parser.parse_args()
    baseline = json.loads(args.baseline.read_text()) if args.baseline.exists() else {}
    with tempfile.TemporaryDirectory() as temp:
        path = args.data or Path(temp) / 'data.json'
        if not args.data:
            executable = shutil.which('lua5.1') or '/workspace/.loot-liquidator-tools/lua/usr/bin/lua5.1'
            subprocess.run([executable, 'tools/export_pipeline_audit.lua', str(path), '--probe'], check=True)
        summary = write_reports(json.loads(path.read_text()), baseline, args.output)
    print('USABLE DATA AUDIT:', summary['processing_source_rows'], 'source rows;',
          summary['offline_profiles'], 'offline profiles;', summary['offline_states_after'],
          ';', len(summary['new_numeric_profiles']), 'new numeric profiles; actual actionable coverage unmeasured')
    if args.validate and (summary['runtime_errors'] or summary['regressed_numeric_profiles']):
        raise SystemExit('Source-to-tooltip audit has runtime errors or unexplained numeric regressions')


if __name__ == '__main__':
    main()
