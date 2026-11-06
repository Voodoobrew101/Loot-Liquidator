#!/usr/bin/env python3
"""Compile sourced quality rules; never infer a skill-to-quantity multiplier.

The client must supply an exact-input Blizzard operation snapshot. Research
explains how to use its quality boundary; it does not hardcode recipe difficulty,
invent output counts, or turn conditional unlocks into measured rates.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path

SOURCE = Path('database/research/skill-quality-rules.json')
OUTPUT = Path('database/skill-quality-rules.lua')
FORMULA = 'EXACT_INPUT_QUALITY_THRESHOLD'
QUANTITY_POLICY = 'PRESERVE_SELECTED_FAMILY_EXPECTATION'


def lua(value):
    """Deterministic Lua 5.1 data literals; unknown JSON fields remain nil."""
    if value is None:
        return 'nil'
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if isinstance(value, (int, float)):
        if not math.isfinite(value):
            raise ValueError('Nonfinite number cannot enter compiled research')
        return repr(value)
    if isinstance(value, str):
        encoded = []
        for character in value:
            if character in ('\\', '"'):
                encoded.append('\\' + character)
            elif ord(character) < 32:
                encoded.append('\\%03d' % ord(character))
            else:
                encoded.append(character)
        return '"' + ''.join(encoded) + '"'
    if isinstance(value, list):
        return '{' + ','.join(lua(item) for item in value) + '}'
    if isinstance(value, dict):
        return '{' + ','.join('[' + lua(key) + ']=' + lua(value[key]) for key in sorted(value) if value[key] is not None) + '}'
    raise ValueError('Unsupported research value type: ' + type(value).__name__)


def integer(value):
    return isinstance(value, int) and not isinstance(value, bool) and value > 0


def unique_positive(values, label):
    if not isinstance(values, list) or not values or any(not integer(v) for v in values):
        raise ValueError('Invalid ' + label)
    if len(values) != len(set(values)):
        raise ValueError('Duplicate ' + label)
    return list(values)


def claims(values, available, label):
    if not isinstance(values, list) or not values or any(
            not isinstance(v, str) or not v or v not in available for v in values):
        raise ValueError('Missing or unknown source claim: ' + label)
    if len(values) != len(set(values)):
        raise ValueError('Duplicate source claim: ' + label)
    return list(values)


def build(data):
    if not isinstance(data, dict) or data.get('schemaVersion') != 1:
        raise ValueError('Unsupported skill-quality research schema')
    if not isinstance(data.get('revision'), str) or not data['revision']:
        raise ValueError('Missing skill-quality revision')
    sources = {}
    for source in data.get('sourceClaims', []):
        if not isinstance(source, dict) or not isinstance(source.get('id'), str) or not source['id']:
            raise ValueError('Invalid source claim identity')
        if source['id'] in sources:
            raise ValueError('Duplicate source claim identity: ' + source['id'])
        if not isinstance(source.get('url'), str) or not source['url'].startswith('https://'):
            raise ValueError('Source claim needs a published HTTPS URL')
        if not isinstance(source.get('support'), str) or not source['support']:
            raise ValueError('Source claim needs its supporting observation')
        sources[source['id']] = dict(source)
    if not isinstance(data.get('rules'), list):
        raise ValueError('Missing skill-quality research rules')
    rules, held, seen, scopes = [], [], set(), set()
    for original in data['rules']:
        if not isinstance(original, dict) or not isinstance(original.get('ruleID'), str) or not original['ruleID']:
            raise ValueError('Invalid skill-quality rule identity')
        rule_id = original['ruleID']
        if rule_id in seen:
            raise ValueError('Duplicate skill-quality rule identity: ' + rule_id)
        seen.add(rule_id)
        source_ids = claims(original.get('sourceClaimIDs'), sources, rule_id)
        confidence = original.get('confidence0to100')
        if isinstance(confidence, bool) or not isinstance(confidence, (int, float)) or not math.isfinite(confidence) or not 0 < confidence <= 100:
            raise ValueError('Invalid skill-quality confidence: ' + rule_id)
        recipe = original.get('recipeID')
        if not integer(recipe):
            raise ValueError('Invalid skill-quality recipe ID: ' + rule_id)
        ranks = unique_positive(original.get('inputQualityRanks'), 'input quality ranks')
        if sorted(ranks) != [1, 2]:
            raise ValueError('This quality model requires explicit input ranks 1 and 2')
        input_ids = None
        if 'inputItemIDs' in original:
            input_ids = unique_positive(original['inputItemIDs'], 'input item IDs')
        scope = (original.get('method'), recipe, original.get('expansionID'))
        if scope in scopes:
            raise ValueError('Ambiguous duplicate quality rule scope: ' + rule_id)
        scopes.add(scope)
        reason = None
        if original.get('applyPolicy') != 'EXECUTE':
            reason = 'Rule is not enabled for execution'
        elif original.get('evidenceStatus') != 'SOURCED_PROVISIONAL':
            reason = 'Unsupported evidence status'
        elif original.get('formulaID') != FORMULA or original.get('quantityPolicy') != QUANTITY_POLICY:
            reason = 'Unsupported formula or quantity policy'
        elif original.get('method') not in ('Prospect', 'Mill') or original.get('expansionID') != 11 or original.get('maxQuality') != 2:
            reason = 'Only sourced Midnight two-quality milling/prospecting is supported'
        elif original.get('requireExactOperationContext') is not True:
            reason = 'Exact-input operation context is required'
        elif any(key in original for key in ('skillThreshold', 'baseDifficulty', 'recipeDifficulty', 'thresholds', 'skillFactors', 'expectedQuantityMultiplier')):
            reason = 'Difficulty comes from the exact-input operation, never a fixed research constant or quantity multiplier'
        if reason:
            held.append({'ruleID': rule_id, 'reason': reason, 'sourceClaimIDs': source_ids})
            continue
        families, output_ids, names = [], set(), set()
        for family in original.get('outputFamilies', []):
            name = family.get('name') if isinstance(family, dict) else None
            label = rule_id + ':' + str(name or '?')
            try:
                if not isinstance(name, str) or not name or name in names:
                    raise ValueError('Missing or duplicate output family name')
                if family.get('rankMappingStatus') != 'SOURCE_CHECKED_ORDER':
                    raise ValueError('Ordered quality mapping is not source checked')
                if family.get('conditional'):
                    raise ValueError('Conditional unlock outputs need their own measured model')
                ids = unique_positive(family.get('rankItemIDs'), 'ordered rank item IDs')
                if len(ids) != original['maxQuality']:
                    raise ValueError('Output family must name every quality exactly once')
                if output_ids.intersection(ids):
                    raise ValueError('Output rank overlaps another family')
                family_sources = claims(family.get('sourceClaimIDs'), sources, label)
            except ValueError as error:
                held.append({'ruleID': rule_id, 'outputFamily': name or '?', 'reason': str(error)})
                continue
            names.add(name)
            output_ids.update(ids)
            families.append({'name': name, 'rankItemIDs': ids, 'sourceClaimIDs': family_sources})
        if not families:
            held.append({'ruleID': rule_id, 'reason': 'No usable source-checked output families'})
            continue
        rule = {key: original[key] for key in (
            'ruleID', 'method', 'recipeID', 'expansionID', 'formulaID', 'maxQuality',
            'applyPolicy', 'evidenceStatus', 'requireExactOperationContext', 'quantityPolicy')}
        rule.update(inputQualityRanks=sorted(ranks), confidence0to100=confidence,
                    confidenceBasis='Editorial research-rule confidence; not a measured drop probability',
                    sourceClaimIDs=source_ids, outputFamilies=sorted(families, key=lambda f: f['name']))
        if input_ids is not None:
            rule['inputItemIDs'] = sorted(input_ids)
        rules.append(rule)
    for pending in data.get('held', []):
        if not isinstance(pending, dict) or not isinstance(pending.get('reason'), str):
            raise ValueError('Invalid held research entry')
        held.append(dict(pending))
    held_numeric = []
    for reference in data.get('heldResearchArtifacts', []):
        if not isinstance(reference, str) or not reference.startswith('research/mechanics/') or '..' in Path(reference).parts or Path(reference).suffix != '.json':
            raise ValueError('Held research artifact must be a local mechanics JSON file')
        evidence = json.loads(Path(reference).read_text(), object_pairs_hook=no_duplicate_keys)
        evidence_sources = {source['id']: source for source in evidence.get('sources', [])}
        for candidate in evidence.get('narrowRuleCandidates', []):
            if candidate.get('runtimeAdmissible') is not False:
                raise ValueError('Held research artifact cannot enable an executable rule')
            ids = candidate.get('supportingSourceIDs', [])
            if any(source_id not in evidence_sources for source_id in ids):
                raise ValueError('Held numeric candidate has an unknown evidence source')
            held_numeric.append({**candidate, 'status': 'HELD', 'runtimeAdmissible': False,
                                 'researchArtifact': reference,
                                 'sourceURLs': [evidence_sources[source_id]['url'] for source_id in ids]})
    return {'schemaVersion': 1, 'revision': data['revision'],
            'skillQualityRules': sorted(rules, key=lambda r: r['ruleID']),
            'sourceClaims': [sources[k] for k in sorted(sources)], 'held': held,
            'heldNumericCandidates': held_numeric}


def render(data, source_bytes):
    compiled = build(data)
    digest = hashlib.sha256(source_bytes)
    # Held candidates are part of the reproducible research export too. A
    # changed supporting artifact must make --check detect stale output.
    for reference in data.get('heldResearchArtifacts', []):
        digest.update(reference.encode())
        digest.update(Path(reference).read_bytes())
    compiled['sourceSHA256'] = digest.hexdigest()
    text = '-- Generated by tools/skill_quality_to_rules.py; never hand-edit.\nreturn ' + lua(compiled) + '\n'
    return text, compiled


def no_duplicate_keys(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError('Duplicate JSON object key: ' + key)
        result[key] = value
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=SOURCE)
    parser.add_argument('--output', type=Path, default=OUTPUT)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    source_bytes = args.source.read_bytes()
    data = json.loads(source_bytes, object_pairs_hook=no_duplicate_keys)
    text, compiled = render(data, source_bytes)
    if args.check:
        if not args.output.exists() or args.output.read_text() != text:
            parser.exit(1, 'Skill-quality rules stale: run python3 tools/skill_quality_to_rules.py\n')
    else:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text)
    print('SKILL QUALITY RULES: %d rules, %d output families; %d held entries' % (
        len(compiled['skillQualityRules']),
        sum(len(rule['outputFamilies']) for rule in compiled['skillQualityRules']), len(compiled['held'])))


if __name__ == '__main__':
    main()
