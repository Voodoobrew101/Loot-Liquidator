"""Compile reviewed effects of named specialization point sliders.

The UI catalog supplies identity/rank bounds. This separate, sourced contract
supplies calculations: per-point recipe skill, conserved gem replacement, and a
separately observed complete-specialization reference. No description is parsed
at runtime and no universal skill/yield curve is manufactured.
"""
import argparse
import copy
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'database/research/specialization-effects.json'
CATALOG = ROOT / 'database/wago-professions-70783.json'
OUTPUT = ROOT / 'database/specialization-effects.lua'
KINDS = {'skill-per-point', 'replace-family', 'reference-context'}
PROFESSIONS = {'Disenchant': 'Enchanting', 'Mill': 'Inscription', 'Prospect': 'Jewelcrafting'}


def no_duplicate_keys(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f'Duplicate JSON key: {key}')
        result[key] = value
    return result


def whole(value, minimum=0):
    return isinstance(value, int) and not isinstance(value, bool) and value >= minimum


def finite(value, minimum=0, maximum=None):
    return (isinstance(value, (int, float)) and not isinstance(value, bool)
            and value == value and minimum <= value < float('inf')
            and (maximum is None or value <= maximum))


def build(document, catalog):
    if document.get('schemaVersion') != 1 or not whole(document.get('build'), 1):
        raise ValueError('Unsupported specialization effect schema/build')
    if not isinstance(document.get('revision'), str) or not document['revision']:
        raise ValueError('Specialization revision required')
    if not str(catalog.get('build', '')).endswith('.' + str(document['build'])):
        raise ValueError('Specialization/catalog build mismatch')
    claims = document.get('sourceClaims')
    if not isinstance(claims, list) or not claims:
        raise ValueError('Source claims required')
    sources = {}
    for source in claims:
        if (not isinstance(source.get('id'), str) or not source['id'] or source['id'] in sources
                or not isinstance(source.get('url'), str) or not re.fullmatch(r'https://\S+', source['url'])
                or not isinstance(source.get('support'), str) or not source['support']):
            raise ValueError('Invalid or duplicate source claim')
        sources[source['id']] = source
    result, identities, scopes, reservoirs = [], set(), set(), {}
    for original in document.get('rules', []):
        rule = copy.deepcopy(original)
        identity, kind = rule.get('ruleID'), rule.get('kind')
        if not isinstance(identity, str) or not identity or identity in identities:
            raise ValueError('Invalid or duplicate specialization rule identity')
        identities.add(identity)
        if kind not in KINDS:
            raise ValueError(f'{identity}: Unsupported specialization effect')
        if (rule.get('method') not in PROFESSIONS
                or rule.get('profession') != PROFESSIONS[rule['method']]
                or not whole(rule.get('expansionID')) or rule.get('build') != document['build']
                or not finite(rule.get('confidence0to100'), 1, 100)
                or rule.get('evidenceStatus') != 'SOURCED_PROVISIONAL'
                or rule.get('applyPolicy') != 'EXECUTE'):
            raise ValueError(f'{identity}: Invalid scope, evidence or confidence')
        refs = rule.get('sourceClaimIDs')
        if (not isinstance(refs, list) or not refs or len(set(refs)) != len(refs)
                or any(source not in sources for source in refs)):
            raise ValueError(f'{identity}: Missing or invalid source lineage')
        for key in ('samples', 'casts', 'effectiveSamples', 'skillFactors', 'quantityMultiplier', 'inputItemID'):
            if key in rule:
                raise ValueError(f'{identity}: Unsupported empirical claim or item-specific gate: {key}')
        if rule.get('inputRarity') is not None and (not whole(rule['inputRarity'], 2) or rule['inputRarity'] > 8):
            raise ValueError(f'{identity}: Invalid physical rarity')
        if rule.get('inputClassID') is not None and rule['inputClassID'] not in (2, 4):
            raise ValueError(f'{identity}: Invalid physical class')
        if rule.get('recipeID') is not None and not whole(rule['recipeID'], 1):
            raise ValueError(f'{identity}: Invalid recipe')
        key = f'{rule["profession"]}:{rule["expansionID"]}'
        nodes = {node['id']: node for node in catalog.get('catalogs', {}).get(key, {}).get('nodes', [])}
        if not nodes:
            raise ValueError(f'{identity}: No matching catalog')
        if kind == 'reference-context':
            required = rule.get('requiredNodes')
            if not isinstance(required, dict) or not required:
                raise ValueError(f'{identity}: Required point allocations missing')
            for node_id, rank in required.items():
                if (not isinstance(node_id, str) or not node_id.isdigit() or int(node_id) not in nodes
                        or not whole(rank, 1) or rank > nodes[int(node_id)]['maxRank']):
                    raise ValueError(f'{identity}: Invalid reference point requirement')
            if rule['method'] != 'Disenchant' or rule.get('inputRarity') is None or rule.get('inputClassID') is None:
                raise ValueError(f'{identity}: Reference context requires a physical category')
            expected = f'de-category:gear:{rule["expansionID"]}:{rule["inputRarity"]}:'
            expected += 'weapon:' if rule['inputClassID'] == 2 else 'armor:'
            if not isinstance(rule.get('referenceContextID'), str) or not rule['referenceContextID'].startswith(expected):
                raise ValueError(f'{identity}: Reference category mismatch')
            scope = (kind, key, rule['inputRarity'], rule['inputClassID'], tuple(sorted(required.items())))
        else:
            node_id = rule.get('nodeID')
            if (not whole(node_id, 1) or node_id not in nodes
                    or rule.get('maxRank') != nodes[node_id]['maxRank']
                    or not whole(rule['maxRank'], 1) or not finite(rule.get('perPoint'), .00000001)):
                raise ValueError(f'{identity}: Invalid node/point coefficient or catalog cap')
            scope = (kind, key, rule['method'], rule.get('recipeID'), node_id, rule.get('inputRarity'))
            if kind == 'replace-family':
                if rule['method'] != 'Prospect':
                    raise ValueError(f'{identity}: Replacement scope must be prospecting')
                for family in ('sourceFamily', 'targetFamily'):
                    entry = rule.get(family)
                    if not isinstance(entry, dict) or not whole(entry.get('id'), 1):
                        raise ValueError(f'{identity}: Exact unranked source/target family identity required')
                    if 'rankIDs' in entry:
                        raise ValueError(f'{identity}: Unverified rank routing')
                if rule['sourceFamily']['id'] == rule['targetFamily']['id']:
                    raise ValueError(f'{identity}: Source and replacement must differ')
                if (rule.get('quantityPolicy') != 'CONSERVE_TOTAL_GEM_UNITS'
                        or rule.get('reservoirPolicy') != 'shared-original-source-quantity'):
                    raise ValueError(f'{identity}: Replacement must conserve the shared source reservoir')
                reservoir = (key, rule.get('recipeID'), rule['sourceFamily']['id'])
                reservoirs[reservoir] = reservoirs.get(reservoir, 0) + rule['perPoint'] * rule['maxRank']
        if scope in scopes:
            raise ValueError(f'{identity}: Duplicate specialization rule scope')
        scopes.add(scope)
        result.append(rule)
    if any(total > 1 + 1e-12 for total in reservoirs.values()):
        raise ValueError('Combined replacement fractions exceed source reservoir')
    return {'schemaVersion': 1, 'revision': document['revision'], 'build': document['build'],
            'specializationRules': sorted(result, key=lambda rule: rule['ruleID']),
            'sourceClaims': copy.deepcopy(claims), 'held': copy.deepcopy(document.get('held', []))}


def lua(value):
    if value is None:
        return 'nil'
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, list):
        return '{' + ','.join(lua(entry) for entry in value) + '}'
    return '{' + ','.join('[' + lua(key) + ']=' + lua(value[key]) for key in sorted(value)) + '}'


def render(compiled):
    return ('-- Generated by tools/specialization_effects.py; never hand-edit.\n'
            '-- Sourced point effects; no universal skill/yield curve or invented observations.\n'
            'return ' + lua(compiled) + '\n')


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=SOURCE)
    parser.add_argument('--catalog', type=Path, default=CATALOG)
    parser.add_argument('--output', type=Path, default=OUTPUT)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args(argv)
    document = json.loads(args.source.read_text(), object_pairs_hook=no_duplicate_keys)
    catalog = json.loads(args.catalog.read_text(), object_pairs_hook=no_duplicate_keys)
    if document.get('catalogSourceSHA256') != hashlib.sha256(args.catalog.read_bytes()).hexdigest():
        raise ValueError('Reviewed catalog checksum changed')
    compiled = build(document, catalog)
    compiled['sourceSHA256'] = hashlib.sha256(args.source.read_bytes()).hexdigest()
    output = render(compiled)
    if args.check:
        if not args.output.exists() or args.output.read_text() != output:
            raise ValueError('Regenerate specialization effects')
    else:
        args.output.write_text(output)
    counts = {kind: sum(rule['kind'] == kind for rule in compiled['specializationRules']) for kind in sorted(KINDS)}
    print(f'SPECIALIZATION EFFECTS: {len(compiled["specializationRules"])} rules; {counts}; {len(compiled["held"])} held claims')


if __name__ == '__main__':
    main()
