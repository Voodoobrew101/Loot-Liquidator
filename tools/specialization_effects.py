"""Compile reviewed effects of named specialization point sliders.

The UI catalog supplies identity/rank bounds. This separate, sourced contract
supplies calculations: per-point recipe skill, conserved gem replacement, and a
separately observed complete-specialization reference. An explicit, low-confidence
model contract supplies assumed interpolation without inventing observations.
No description is parsed at runtime.
"""
import argparse
import copy
from datetime import date
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


def build_described_effects(document, catalog, sources):
    """Validate researched descriptions without granting numeric execution."""
    entries = document.get('describedEffects', [])
    if not isinstance(entries, list):
        raise ValueError('Described specialization effects must be a list')
    allowed = {'effectID', 'method', 'profession', 'expansionID', 'build', 'clientVersion',
               'nodeID', 'nodeName', 'maxRank', 'inputRarity', 'inputClassID', 'recipeID',
               'description', 'sourceClaimIDs'}
    result, identities, scopes = [], set(), set()
    for original in entries:
        if not isinstance(original, dict) or set(original) - allowed:
            raise ValueError('Described specialization effects cannot carry numeric transforms or unknown fields')
        effect = copy.deepcopy(original)
        identity = effect.get('effectID')
        if not isinstance(identity, str) or not identity or identity in identities:
            raise ValueError('Invalid or duplicate described specialization effect identity')
        identities.add(identity)
        if (effect.get('method') not in PROFESSIONS
                or effect.get('profession') != PROFESSIONS[effect['method']]
                or not whole(effect.get('expansionID')) or effect.get('build') != document['build']
                or not whole(effect.get('build'), 1)
                or not isinstance(effect.get('clientVersion'), str)
                or not re.fullmatch(r'(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)', effect['clientVersion'])):
            raise ValueError(f'{identity}: Invalid described effect scope/build')
        if (not isinstance(effect.get('description'), str) or not effect['description'].strip()
                or not isinstance(effect.get('nodeName'), str) or not effect['nodeName'].strip()):
            raise ValueError(f'{identity}: Described effect name/text required')
        refs = effect.get('sourceClaimIDs')
        if (not isinstance(refs, list) or not refs or any(not isinstance(ref, str) for ref in refs)
                or len(set(refs)) != len(refs) or any(ref not in sources for ref in refs)):
            raise ValueError(f'{identity}: Missing or invalid described effect source lineage')
        if effect.get('inputRarity') is not None and (not whole(effect['inputRarity'], 2) or effect['inputRarity'] > 8):
            raise ValueError(f'{identity}: Invalid described effect physical rarity')
        if effect.get('inputClassID') is not None and effect['inputClassID'] not in (2, 4):
            raise ValueError(f'{identity}: Invalid described effect physical class')
        if effect.get('recipeID') is not None and not whole(effect['recipeID'], 1):
            raise ValueError(f'{identity}: Invalid described effect recipe')
        key = f'{effect["profession"]}:{effect["expansionID"]}'
        nodes = {node['id']: node for node in catalog.get('catalogs', {}).get(key, {}).get('nodes', [])}
        node_id = effect.get('nodeID')
        if (not whole(node_id, 1) or node_id not in nodes
                or not whole(effect.get('maxRank'), 1) or effect['maxRank'] != nodes[node_id]['maxRank']
                or effect['nodeName'] != nodes[node_id]['name']):
            raise ValueError(f'{identity}: Invalid described effect catalog node/cap/name')
        scope = (key, effect['method'], effect.get('recipeID'), node_id,
                 effect.get('inputRarity'), effect.get('inputClassID'))
        if scope in scopes:
            raise ValueError(f'{identity}: Duplicate described specialization effect scope')
        scopes.add(scope)
        result.append(effect)
    return sorted(result, key=lambda effect: effect['effectID'])


def build_published_references(document, catalog, sources):
    """Keep historical reports as text; they cannot become output transforms."""
    entries = document.get('publishedReferences', [])
    if not isinstance(entries, list):
        raise ValueError('Published specialization references must be a list')
    allowed = {'referenceID', 'method', 'profession', 'expansionID', 'build',
               'clientVersion', 'inputRarity', 'requiredNodes', 'displayPolicy',
               'applyPolicy', 'displayText', 'notes', 'sourceClaimIDs'}
    result, identities, scopes = [], set(), set()
    for original in entries:
        if not isinstance(original, dict) or set(original) != allowed:
            raise ValueError('Published references are text-only; numeric transforms, sample counts and unknown fields are forbidden')
        entry = copy.deepcopy(original)
        identity = entry.get('referenceID')
        if not isinstance(identity, str) or not identity or identity in identities:
            raise ValueError('Invalid or duplicate published reference identity')
        identities.add(identity)
        if (entry.get('method') != 'Disenchant' or entry.get('profession') != 'Enchanting'
                or entry.get('expansionID') != 11
                or not whole(entry.get('build'), document['build'])
                or not isinstance(entry.get('clientVersion'), str)
                or not re.fullmatch(r'(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)', entry['clientVersion'])
                or entry.get('displayPolicy') != 'MAX_INVESTMENT_SCENARIO_ONLY'
                or entry.get('applyPolicy') != 'DISPLAY_ONLY'
                or not whole(entry.get('inputRarity'), 2) or entry['inputRarity'] not in (2, 4)):
            raise ValueError(f'{identity}: Invalid published reference display scope/policy')
        if (not isinstance(entry.get('displayText'), str) or not entry['displayText'].strip()
                or not isinstance(entry.get('notes'), list) or not entry['notes']
                or any(not isinstance(note, str) or not note.strip() for note in entry['notes'])):
            raise ValueError(f'{identity}: Published reference text/notes required')
        refs = entry.get('sourceClaimIDs')
        if (not isinstance(refs, list) or not refs or any(not isinstance(ref, str) for ref in refs)
                or len(set(refs)) != len(refs) or any(ref not in sources for ref in refs)):
            raise ValueError(f'{identity}: Invalid published reference source lineage')
        for ref in refs:
            source = sources[ref]
            try:
                date.fromisoformat(source.get('sourcePublishedOn', ''))
            except (TypeError, ValueError):
                raise ValueError(f'{identity}: Published reference source date required') from None
            if source.get('displayReviewedBuild') != entry['build']:
                raise ValueError(f'{identity}: Published reference display build has no matching review')
        key = f'{entry["profession"]}:{entry["expansionID"]}'
        nodes = {node['id']: node for node in catalog.get('catalogs', {}).get(key, {}).get('nodes', [])}
        required = entry.get('requiredNodes')
        child = 107648 if entry['inputRarity'] == 2 else 107646
        if not isinstance(required, dict) or set(required) != {'107649', str(child)}:
            raise ValueError(f'{identity}: Published reference needs the matching root/child display scenario')
        for node_id, points in required.items():
            if (not whole(points, 1) or int(node_id) not in nodes
                    or points != nodes[int(node_id)]['maxRank']):
                raise ValueError(f'{identity}: Published reference requires catalog maximum point caps')
        scope = (entry['method'], entry['expansionID'], entry['inputRarity'], entry['build'],
                 entry['clientVersion'], tuple(sorted(required.items())))
        if scope in scopes:
            raise ValueError(f'{identity}: Duplicate published reference display scope')
        scopes.add(scope)
        result.append(entry)
    return sorted(result, key=lambda entry: entry['referenceID'])


def build_modeled_disenchant_rules(document, catalog, sources):
    """Validate explicit scenario assumptions separately from measured rules."""
    entries = document.get('modeledDisenchantRules', [])
    if not isinstance(entries, list):
        raise ValueError('Modeled disenchant rules must be a list')
    if not entries:
        return []
    if len(entries) != 3:
        raise ValueError('Modeled disenchant rules require exactly three rarity scopes')
    common = {'ruleID', 'method', 'profession', 'expansionID', 'build', 'clientVersion',
              'inputRarity', 'inputClassIDs', 'rootNodeID', 'childNodeID', 'primaryRankIDs',
              'confidence0to100', 'crossClassConfidence', 'sourceKey', 'skillMaximum',
              'quantityMilestones', 'targetRank2Share', 'applyPolicy', 'evidenceStatus',
              'assumptions', 'sourceClaimIDs'}
    expected = {2: (107648, [243599, 243600], 'reference', 10, 5),
                3: (107647, [243602, 243603], 'itemdb', 30, 15),
                4: (107646, [243605, 243606], 'reference', 20, 20)}
    nodes = {node['id']: node for node in catalog.get('catalogs', {}).get('Enchanting:11', {}).get('nodes', [])}
    result, identities, rarities = [], set(), set()
    for original in entries:
        if not isinstance(original, dict):
            raise ValueError('Modeled disenchant rule must be an object')
        rarity = original.get('inputRarity')
        if not whole(rarity, 2) or rarity not in expected or rarity in rarities:
            raise ValueError('Invalid or duplicate modeled disenchant rarity scope')
        rarities.add(rarity)
        allowed = common | ({'targetPooledMean', 'baselineFallbackClassID'} if rarity == 2 else
                            {'targetPooledMean', 'endpointRecordID'} if rarity == 3 else
                            {'preservePrimaryTotal'})
        if set(original) != allowed:
            raise ValueError('Modeled disenchant rule has missing or unknown fields; observations and sample counts are forbidden')
        rule = copy.deepcopy(original)
        identity = rule.get('ruleID')
        if (not isinstance(identity, str) or not identity.startswith('simulation:11:Disenchant:')
                or identity in identities):
            raise ValueError('Invalid or duplicate modeled disenchant rule identity')
        identities.add(identity)
        child, rank_ids, source_key, confidence_cap, cross_cap = expected[rarity]
        if (rule.get('method') != 'Disenchant' or rule.get('profession') != 'Enchanting'
                or not whole(rule.get('expansionID')) or rule['expansionID'] != 11
                or not whole(rule.get('build')) or rule['build'] != 70961
                or rule.get('clientVersion') != '12.1.5'
                or rule.get('inputClassIDs') != [2, 4]
                or any(not whole(value, 1) for value in rule['inputClassIDs'])
                or not whole(rule.get('rootNodeID'), 1) or rule['rootNodeID'] != 107649
                or not whole(rule.get('childNodeID'), 1) or rule['childNodeID'] != child
                or rule.get('primaryRankIDs') != rank_ids
                or any(not whole(value, 1) for value in rule['primaryRankIDs'])
                or rule.get('sourceKey') != source_key
                or rule.get('applyPolicy') != 'EXECUTE' or rule.get('evidenceStatus') != 'MODELED'):
            raise ValueError(f'{identity}: Invalid modeled disenchant scope/identity/policy')
        if any(node_id not in nodes or nodes[node_id]['maxRank'] != 30 for node_id in (107649, child)):
            raise ValueError(f'{identity}: Modeled node identity/cap disagrees with catalog')
        if (not finite(rule.get('confidence0to100'), 1, confidence_cap)
                or not finite(rule.get('crossClassConfidence'), 1, cross_cap)
                or rule['crossClassConfidence'] > rule['confidence0to100']):
            raise ValueError(f'{identity}: Modeled confidence exceeds reviewed uncertainty caps')
        if (not finite(rule.get('skillMaximum'), 1) or rule['skillMaximum'] != 290
                or not finite(rule.get('targetRank2Share'), 0, 1)):
            raise ValueError(f'{identity}: Invalid modeled skill/quality interpolation endpoint')
        milestones = rule.get('quantityMilestones')
        if (not isinstance(milestones, list) or len(milestones) != 2
                or any(not isinstance(milestone, dict) or set(milestone) != {'rank', 'progress'}
                       or not whole(milestone.get('rank'), 1)
                       or not finite(milestone.get('progress'), .00000001, 1)
                       for milestone in milestones)
                or [m['rank'] for m in milestones] != [20, 30]
                or [m['progress'] for m in milestones] != [.5, .5]):
            raise ValueError(f'{identity}: Invalid modeled quantity milestone allocation')
        if rarity == 4:
            if rule.get('preservePrimaryTotal') is not True:
                raise ValueError(f'{identity}: Crystal model must preserve the existing primary total')
        elif not finite(rule.get('targetPooledMean'), .00000001):
            raise ValueError(f'{identity}: Modeled pooled quantity endpoint must be positive')
        if rarity == 2 and (not whole(rule.get('baselineFallbackClassID')) or rule['baselineFallbackClassID'] != 4):
            raise ValueError(f'{identity}: Dust fallback must use the existing armor baseline')
        if rarity == 3:
            endpoint = rule.get('endpointRecordID')
            references = {r.get('referenceContextID') for r in document.get('rules', [])
                          if r.get('kind') == 'reference-context' and r.get('method') == 'Disenchant'
                          and r.get('expansionID') == 11 and r.get('inputRarity') == 3
                          and r.get('inputClassID') == 4}
            if not isinstance(endpoint, str) or endpoint not in references:
                raise ValueError(f'{identity}: Supplier model needs the reviewed full-specialization endpoint')
        assumptions = rule.get('assumptions')
        if (not isinstance(assumptions, list) or not assumptions
                or any(not isinstance(text, str) or not text.strip() for text in assumptions)):
            raise ValueError(f'{identity}: Explicit modeled assumptions required')
        refs = rule.get('sourceClaimIDs')
        if (not isinstance(refs, list) or not refs or any(not isinstance(ref, str) for ref in refs)
                or len(set(refs)) != len(refs) or any(ref not in sources for ref in refs)):
            raise ValueError(f'{identity}: Invalid modeled source lineage')
        result.append(rule)
    return sorted(result, key=lambda rule: rule['ruleID'])


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
                or not whole(rule.get('expansionID')) or not whole(rule.get('build'), 1)
                or not finite(rule.get('confidence0to100'), 1, 100)
                or rule.get('evidenceStatus') != 'SOURCED_PROVISIONAL'
                or rule.get('applyPolicy') != 'EXECUTE'):
            raise ValueError(f'{identity}: Invalid scope, evidence or confidence')
        if 'clientVersion' in rule and (
                not isinstance(rule['clientVersion'], str)
                or not re.fullmatch(r'(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)', rule['clientVersion'])
                or not whole(rule.get('build'), 1)):
            raise ValueError(f'{identity}: Invalid client version/build scope')
        refs = rule.get('sourceClaimIDs')
        if (not isinstance(refs, list) or not refs or len(set(refs)) != len(refs)
                or any(source not in sources for source in refs)):
            raise ValueError(f'{identity}: Missing or invalid source lineage')
        # Catalog identity may be pinned to an older client than newly resolved
        # arithmetic. A later build needs an explicit matching evidence claim;
        # never silently stamp new evidence with the old catalog's build.
        def supports_build(value):
            return value == document['build'] or any(sources[ref].get('build') == value for ref in refs)
        if rule['build'] < document['build'] or not supports_build(rule['build']):
            raise ValueError(f'{identity}: Rule build has no matching source evidence')
        for key in ('samples', 'casts', 'effectiveSamples', 'skillFactors', 'quantityMultiplier', 'inputItemID',
                    'procChance', 'procRate', 'procProbability', 'bonusQuantity', 'yieldMultiplier', 'quantityMilestones'):
            if key in rule:
                raise ValueError(f'{identity}: Unsupported empirical claim or item-specific gate: {key}')
        skill_fields = {'learningSkill', 'skillMilestones', 'skillMilestoneBuild'} & set(rule)
        if skill_fields:
            if (kind != 'skill-per-point'
                    or not finite(rule.get('learningSkill'), .00000001)
                    or not whole(rule.get('skillMilestoneBuild'), rule['build'])
                    or not any(sources[ref].get('build') == rule['skillMilestoneBuild'] for ref in refs)
                    or not isinstance(rule.get('skillMilestones'), list) or not rule['skillMilestones']):
                raise ValueError(f'{identity}: Invalid sourced learning/milestone skill fields')
            previous = 0
            for milestone in rule['skillMilestones']:
                if (not isinstance(milestone, dict) or set(milestone) != {'rank', 'skill'}
                        or not whole(milestone.get('rank'), 1) or milestone['rank'] <= previous
                        or not whole(rule.get('maxRank'), 1) or milestone['rank'] > rule['maxRank']
                        or not finite(milestone.get('skill'), .00000001)):
                    raise ValueError(f'{identity}: Invalid or unordered skill milestone')
                previous = milestone['rank']
        replacement_fields = {'replacementMilestones', 'replacementMilestoneBuild'} & set(rule)
        if replacement_fields:
            if (kind != 'replace-family'
                    or not whole(rule.get('replacementMilestoneBuild'), rule['build'])
                    or not any(sources[ref].get('build') == rule['replacementMilestoneBuild'] for ref in refs)
                    or not isinstance(rule.get('replacementMilestones'), list)
                    or not rule['replacementMilestones']):
                raise ValueError(f'{identity}: Invalid sourced replacement milestone fields')
            previous = 0
            for milestone in rule['replacementMilestones']:
                if (not isinstance(milestone, dict) or set(milestone) != {'rank', 'fraction'}
                        or not whole(milestone.get('rank'), 1) or milestone['rank'] <= previous
                        or not whole(rule.get('maxRank'), 1) or milestone['rank'] > rule['maxRank']
                        or not finite(milestone.get('fraction'), .00000001, 1)):
                    raise ValueError(f'{identity}: Invalid or unordered replacement milestone')
                previous = milestone['rank']
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
                maximum = rule['perPoint'] * rule['maxRank']
                maximum += sum(milestone['fraction'] for milestone in rule.get('replacementMilestones', []))
                reservoirs[reservoir] = reservoirs.get(reservoir, 0) + maximum
        if scope in scopes:
            raise ValueError(f'{identity}: Duplicate specialization rule scope')
        scopes.add(scope)
        result.append(rule)
    if any(total > 1 + 1e-12 for total in reservoirs.values()):
        raise ValueError('Combined replacement fractions exceed source reservoir')
    compiled = {'schemaVersion': 1, 'revision': document['revision'], 'build': document['build'],
            'specializationRules': sorted(result, key=lambda rule: rule['ruleID']),
            'describedEffects': build_described_effects(document, catalog, sources),
            'publishedReferences': build_published_references(document, catalog, sources),
            'modeledDisenchantRules': build_modeled_disenchant_rules(document, catalog, sources),
            'sourceClaims': copy.deepcopy(claims), 'held': copy.deepcopy(document.get('held', []))}
    return compiled


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
            '-- Reviewed point effects and explicit modeled scenarios; no invented observations.\n'
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
    # The archived Crystal extras file contains an unverified cross-rarity
    # transfer, possible item identities and an equal-split guess. It is not
    # admitted into numerical rules. Native Crystal skill effects stay above.
    compiled = build(document, catalog)
    compiled['sourceSHA256'] = hashlib.sha256(args.source.read_bytes()).hexdigest()
    output = render(compiled)
    if args.check:
        if not args.output.exists() or args.output.read_text() != output:
            raise ValueError('Regenerate specialization effects')
    else:
        args.output.write_text(output, encoding='utf-8', newline='\n')
    counts = {kind: sum(rule['kind'] == kind for rule in compiled['specializationRules']) for kind in sorted(KINDS)}
    print(f'SPECIALIZATION EFFECTS: {len(compiled["specializationRules"])} rules; {counts}; {len(compiled["held"])} held claims')


if __name__ == '__main__':
    main()
