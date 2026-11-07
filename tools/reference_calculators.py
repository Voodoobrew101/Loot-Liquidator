#!/usr/bin/env python3
"""Compile archived Retail calculator formulas as labeled fallback estimates.

Never evaluate workbook code, cached zero outputs, prices or profit cells. The
supported prospecting formula exposes a constant per five inputs at explicitly
zero Resourcefulness. Reviewed milling data exposes its base yield per completed
operation. Output-quality sections are alternatives, not extra drops.
"""
import hashlib
import json
import math
from pathlib import Path
import re
import sys

from evidence_to_baselines import lua

SOURCE = Path('database/reference-calculators.json')
FAMILIES = Path('database/research/rank-families.json')
OUTPUT = Path('database/reference-calculator-baselines.lua')
FORMULA = re.compile(r'^=SUM\(\(\(\(\(Materials!E2\*0\.3\)/100\)\*G(\d+)\)/5\)\+\(G\1/5\)\*([0-9]+(?:\.[0-9]+)?)\)$')
DIRECT_MODE = 'DIRECT_BASE_YIELD_PER_OPERATION'
GAM_BLOCK = re.compile(r'GAM_RECIPES_GENERATED\[#GAM_RECIPES_GENERATED\+1\] = \{\n(.*?)\n\}', re.S)


def constant(formula):
    match = FORMULA.fullmatch(formula)
    if not match:
        raise ValueError('Unrecognized calculator formula; review its units before import')
    return float(match[2])


def field(value=None):
    return {'status': 'unknown', 'confidence': 0} if value is None else {
        'value': value, 'status': 'modeled', 'confidence': 10,
        'assumption': 'Calculator base coefficient at zero Resourcefulness; not an observed mean'}


def archive_path(source):
    path = Path(source['archive'])
    if path.parent != Path('database/research') or path.suffix != '.json':
        raise ValueError('Calculator archive must be a checked database/research JSON file')
    return path


def source_archive(source, archives=None):
    path = archive_path(source)
    archive = json.loads(path.read_text()) if archives is None else archives[path.as_posix()]
    commit = archive.get('pinnedCommit', '')
    if (archive.get('schemaVersion') != 1
            or archive.get('archiveKind') != 'REVIEWED_PINNED_SOURCE_EXCERPT'
            or archive.get('sourceFormat') != 'GAM_GENERATED_MILLING_LUA_DATA_EXCERPT'
            or archive.get('realStudy') is not False
            or not re.fullmatch(r'[a-f0-9]{40}', commit)
            or archive.get('sourceURL') != source['url']
            or '/blob/' + commit + '/' not in source['url']):
        raise ValueError('Milling calculator needs its reviewed pinned source archive')
    return archive


def one_match(pattern, text):
    matches = re.findall(pattern, text, re.M)
    if len(matches) != 1:
        raise ValueError('Archived calculator field missing or ambiguous: ' + pattern)
    return matches[0]


def numeric_field(name, text):
    value = float(one_match(r'^\s+' + name + r' = ([0-9]+(?:\.[0-9]+)?),$', text))
    if not math.isfinite(value) or value <= 0:
        raise ValueError('Invalid archived per-operation calculator quantity')
    return value


def id_field(text):
    raw = one_match(r'^\s+itemIDs = \{ ([0-9, ]+) \},$', text)
    if not re.fullmatch(r'[1-9][0-9]*(?:, [1-9][0-9]*)*', raw):
        raise ValueError('Invalid archived calculator item IDs')
    ids = [int(value) for value in raw.split(', ')]
    if len(ids) != len(set(ids)):
        raise ValueError('Duplicate archived calculator item ID')
    return ids


def direct_models(archive):
    """Read only named scalar fields from data text; never execute archived Lua."""
    excerpt = archive['sourceExcerpt']
    models = {}
    for match in GAM_BLOCK.finditer(excerpt):
        body = match[1]
        strategy = one_match(r'^  id = "([a-z0-9_]+)",$', body)
        if strategy in models:
            raise ValueError('Duplicate archived calculator strategy')
        outputs = re.findall(r'^  outputs = \{\n    \{\n(.*?)^    \},\n  \},$', body, re.M | re.S)
        inputs = re.findall(r'^  reagents = \{\n    \{\n(.*?)^    \},\n  \},$', body, re.M | re.S)
        if len(outputs) != 1 or len(inputs) != 1 or '\n    {' in outputs[0] or '\n    {' in inputs[0]:
            raise ValueError('Direct milling source must describe one output family and one input family')
        output, reagent = outputs[0], inputs[0]
        recipe = int(one_match(r'^  recipeID = ([1-9][0-9]*),$', body))
        profession = one_match(r'^  profession = "([A-Za-z]+)",$', body)
        if recipe != 1269575 or profession != 'Inscription':
            raise ValueError('Unreviewed direct calculator recipe/profession')
        amount = numeric_field('baseYieldPerCraft', output)
        count = numeric_field('qtyPerCraft', reagent)
        per_input = numeric_field('baseYield', output)
        if count != 10 or not math.isclose(amount / count, per_input, rel_tol=1e-12):
            raise ValueError('Archived base yield units disagree')
        field_offset = body.index('baseYieldPerCraft = ')
        line = archive['sourceLineStart'] + excerpt[:match.start(1) + field_offset].count('\n')
        models[strategy] = {'recipeID': recipe, 'profession': profession,
            'inputIDs': id_field(reagent), 'outputIDs': id_field(output),
            'outputName': one_match(r'^\s+itemRef = "([A-Za-z ]+)",$', output),
            'inputCount': int(count), 'expectedQuantity': amount, 'sourceLine': line}
    if not models:
        raise ValueError('No reviewed direct milling data blocks in archive')
    return models


def direct_records(source, families, archives=None):
    archive = source_archive(source, archives)
    models = direct_models(archive)
    records, seen = [], set()
    for group in source['groups']:
        model = models[group['sourceStrategyID']]
        if group['method'] != 'Mill' or group['expansionID'] != 11:
            raise ValueError('Unreviewed direct calculator operation scope')
        family = families[model['outputName']]
        ranks = family.get('verifiedRanks', {})
        ids = [ranks.get('1'), ranks.get('2')]
        if (not family.get('source', '').startswith('https://')
                or None in ids or len(set(ids)) != 2
                or set(ids) != set(family['ids']) or set(ids) != set(model['outputIDs'])):
            raise ValueError('Direct milling needs source-verified ordered quality identities')
        quality = group['inputQualityRanksByID']
        if set(quality) != {str(item) for item in model['inputIDs']} or sorted(quality.values()) != [1, 2]:
            raise ValueError('Direct milling needs exact input quality scope')
        quantity = field(model['expectedQuantity'])
        quantity['assumption'] = 'Source calculator base family yield per completed operation before Resourcefulness; not an observed mean'
        material = {'id': ids[0], 'rankIDs': ids, 'outputName': model['outputName'],
            'sourceCells': [archive['sourcePath'] + ':' + str(model['sourceLine'])],
            'expectedQuantity': quantity, 'dropChance': field(),
            'minQuantity': field(), 'maxQuantity': field(), 'realStudy': False}
        for item in model['inputIDs']:
            if item in seen:
                raise ValueError('Repeated direct calculator input would double count family yield')
            seen.add(item)
            records.append({'recordID': f"reference:calculator:{source['sourceID']}:{item}",
                'studyID': source['lineage'], 'sourceKey': 'reference', 'method': 'Mill',
                'profession': model['profession'], 'inputItemID': item, 'inputCount': model['inputCount'],
                'recipeID': model['recipeID'], 'inputQualityRank': quality[str(item)],
                'expansionID': 11, 'source': source['url'], 'sourceKind': 'calculator',
                'sourceAssumption': source['assumption'], 'sourceRevision': archive['pinnedCommit'],
                'sourceArchive': archive_path(source).as_posix(), 'sourceStrategyID': group['sourceStrategyID'],
                'sourceQuantityField': 'baseYieldPerCraft', 'realStudy': False,
                'quantityBasis': 'per-completed-operation', 'provisional': True, 'fixedReference': True,
                'fallbackOnly': True, 'referenceApplicability': 'unverified-reference',
                'baselineStatus': 'Calculator family reference; sampled casts, skill and build unknown; before Resourcefulness',
                'materials': [material]})
    return records


def build(data=None, families=None, archives=None):
    data = json.loads(SOURCE.read_text()) if data is None else data
    families = json.loads(FAMILIES.read_text())['families'] if families is None else families
    families = {**families, **data.get('outputIdentities', {})}
    aliases = {'Duskshrouded Stone': 'Dusk-Shrouded Stone'}
    records, held = [], list(data.get('unplaced', []))
    for source in data['sources']:
        if source['gameMode'] != 'Retail':
            held.append({'sourceID': source['sourceID'], 'reason': 'Non-Retail source'})
            continue
        if source.get('formulaMode') == DIRECT_MODE:
            records.extend(direct_records(source, families, archives))
            continue
        if source.get('formulaMode') is not None:
            raise ValueError('Unrecognized calculator formula mode')
        for group in source['groups']:
            outputs = {}
            for row in group['rows']:
                if row.get('conditional'):
                    held.append({'sourceID': source['sourceID'], **row, 'reason': 'Unlock mapping required'})
                name = aliases.get(row['outputName'], row['outputName'])
                family = families.get(name)
                if not family or not family.get('source', '').startswith('https://'):
                    held.append({'sourceID': source['sourceID'], **row, 'reason': 'Output identity mapping required'})
                    continue
                value = constant(row['formula'])
                if name in outputs:
                    if value != outputs[name]['expectedQuantity']['value']:
                        if not row.get('conditional'):
                            raise ValueError('Different quality sections need separate conditions: ' + name)
                        # Show a conservative conditional scenario without
                        # choosing a rank or adding both quality sections.
                        outputs[name]['expectedQuantity']['value'] = min(value, outputs[name]['expectedQuantity']['value'])
                    outputs[name]['sourceCells'].append(row['cell'])
                    outputs[name].setdefault('sourceConstants', []).append(value)
                    continue
                ids = family['ids']
                outputs[name] = {'id': ids[0], 'rankIDs': ids if len(ids) > 1 else None,
                    'outputName': name, 'sourceCells': [row['cell']],
                    'sourceConstants': [value], 'conditionalReference': row.get('conditional'),
                    'expectedQuantity': field(value), 'dropChance': field(),
                    'minQuantity': field(), 'maxQuantity': field()}
            materials = [{k: v for k, v in m.items() if v is not None}
                         for m in sorted(outputs.values(), key=lambda m: m['id'])]
            for item in group['inputItemIDs']:
                if not isinstance(item, int) or isinstance(item, bool) or item <= 0:
                    raise ValueError('Invalid input item ID')
                records.append({'recordID': f"reference:calculator:{source['sourceID']}:{item}",
                    'studyID': source['lineage'], 'sourceKey': 'reference', 'method': group['method'],
                    'profession': 'Jewelcrafting', 'inputItemID': item, 'inputCount': group['inputCount'],
                    'expansionID': group['expansionID'], 'source': source['url'], 'sourceKind': 'calculator',
                    'sourceAssumption': source['assumption'], 'provisional': True, 'fixedReference': True,
                    'fallbackOnly': True, 'referenceApplicability': 'unverified-reference',
                    'baselineStatus': 'Calculator reference; input rank/skill unspecified; no saved price or stat bonus',
                    'materials': materials})
    return records, held


def render():
    records, held = build()
    inputs = SOURCE.read_bytes()
    for source in json.loads(inputs)['sources']:
        if source.get('formulaMode') == DIRECT_MODE:
            path = archive_path(source)
            inputs += b'\0' + path.as_posix().encode() + b'\0' + path.read_bytes()
    digest = hashlib.sha256(inputs).hexdigest()
    return '-- Generated by tools/reference_calculators.py; never hand-edit.\nreturn ' + lua({
        'schemaVersion': 1, 'sourceSHA256': digest, 'processing': records, 'held': held,
        'rankFamilies': [{'name': name, 'ids': row['ids'], 'source': row['source']} for name, row in sorted(
            json.loads(FAMILIES.read_text())['families'].items())]}) + '\n'


if __name__ == '__main__':
    text = render()
    if '--check' in sys.argv:
        if not OUTPUT.exists() or OUTPUT.read_text() != text:
            sys.exit('Calculator baselines stale: run python3 tools/reference_calculators.py')
    else:
        OUTPUT.write_text(text)
    records, held = build()
    print(f'REFERENCE CALCULATORS: {len(records)} input records, '
          f'{sum(len(r["materials"]) for r in records)} material entries; {len(held)} held entries with reasons')
