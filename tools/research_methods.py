"""Shared processing-study identity contract; world targets use their own adapter."""
import json
from hashlib import sha256
from pathlib import Path

PROFESSIONS = {'Alchemy', 'Blacksmithing', 'Enchanting', 'Engineering', 'Herbalism',
               'Inscription', 'Jewelcrafting', 'Leatherworking', 'Mining', 'Skinning',
               'Tailoring', 'Cooking', 'Fishing'}
LEGACY_METHODS = {'Mill', 'Prospect', 'Disenchant', 'Smelt'}
METHOD_PROFESSIONS = {'Mill': 'Inscription', 'Prospect': 'Jewelcrafting',
    'Disenchant': 'Enchanting', 'Smelt': 'Mining', 'Recycle': 'Engineering',
    'Unravel': 'Tailoring', 'Crush': 'Jewelcrafting', 'Thaumaturgy': 'Alchemy',
    'Craft': None, 'Research': None, 'Refine': None}
WORLD_METHODS = {'Gather', 'Skin', 'Fish'}
GENERIC_METHODS = set(METHOD_PROFESSIONS) - LEGACY_METHODS


def exact_integer(value, minimum=1):
    return type(value) is int and minimum <= value <= 2**53 - 1


def profession_for(row):
    method = row.get('method')
    expected = METHOD_PROFESSIONS.get(method)
    stated = row.get('profession')
    if stated is not None and (not isinstance(stated, str) or stated not in PROFESSIONS or expected and stated != expected):
        return None
    return stated or expected


def processing_reasons(row, *, local=False):
    if row.get('_operationAliasBlocked'):
        return [row['_operationAliasBlocked']]
    if not local and row.get('type') not in (None, 'drop'):
        return []
    method = row.get('method')
    if not isinstance(method, str):
        return []
    if method in WORLD_METHODS:
        return ['World gathering studies require the dedicated native-target baseline pipeline']
    if method not in GENERIC_METHODS:
        return []
    reasons = []
    if not profession_for(row):
        reasons.append(f'method {method} requires an explicit compatible profession identity')
    for name in ('recipeID', 'expansionID'):
        if not exact_integer(row.get(name), 0 if name == 'expansionID' else 1):
            reasons.append(f'method {method} requires exact {name}')
    if exact_integer(row.get('expansionID'), 0) and row['expansionID'] > 11:
        reasons.append('expansionID is outside the supported client eras')
    if not exact_integer(row.get('input' if local else 'inputItemID')):
        reasons.append(f'method {method} requires an exact consumed item identity')
    if not exact_integer(row.get('inputPerCast' if local else 'inputsPerCast')):
        reasons.append(f'method {method} requires an explicit whole input batch')
    if row.get('baselineProfile') is not None and not isinstance(row['baselineProfile'], dict):
        reasons.append('baselineProfile must preserve an explicit source profile object')
    try:
        json.dumps(row, allow_nan=False)
    except (TypeError, ValueError):
        reasons.append('Operation scope must contain finite JSON source values')
    return reasons


def operation_scope(row):
    """Never combine distinct recipes, eras, source profiles or allocations."""
    fields = ('recipeID', 'expansionID', 'inputRank', 'inputQualityRank', 'inputRarity',
              'inputClassID', 'referenceContextID', 'referenceConditions', 'baselineProfile',
              'baselineProfileAssumed', 'baselineProfileConfidence',
              'skill', 'baseSkill', 'bonusSkill', 'effectiveSkill', 'specialization',
              'specializationPoints', 'learnedSpecializations', 'stats', 'buffs', 'equipment',
              'operationVariant', 'reagents', 'conditions', 'targetBuild', 'patchBuild', 'patch')
    scope = {key: row[key] for key in fields if row.get(key) is not None}
    scope['profession'] = profession_for(row)
    return json.dumps(scope, sort_keys=True, separators=(',', ':'), ensure_ascii=False, allow_nan=False)


def apply_reviewed_operation_aliases(rows):
    path = Path(__file__).resolve().parent.parent / 'database/research/reviewed-operation-aliases.json'
    policy = json.loads(path.read_text(encoding='utf-8'))
    if policy.get('schemaVersion') != 1:
        raise ValueError('Unsupported reviewed operation alias schema')
    aliases = {(r['sourceFile'], r['recordID']): r for r in policy['aliases']}
    result = []
    for row in rows:
        alias = aliases.get((row.get('_file'), row.get('id')))
        if not alias:
            result.append(row)
            continue
        native = {k: v for k, v in row.items() if not k.startswith('_')}
        digest = sha256(json.dumps(native, sort_keys=True, ensure_ascii=False, separators=(',', ':'), allow_nan=False).encode()).hexdigest()
        copied = dict(row)
        if digest != alias['rawSHA256']:
            copied['_operationAliasBlocked'] = 'Reviewed operation alias source changed; preserve for renewed review'
        else:
            for key in ('method', 'profession', 'recipeID', 'expansionID'):
                copied[key] = alias[key]
            for key in ('baselineProfile', 'baselineProfileAssumed', 'baselineProfileConfidence', 'sourceProfileAssumption'):
                if key in alias:
                    copied[key] = alias[key]
            copied['operationAlias'] = {'revision': policy['revision'], 'sourceMethod': row.get('method'),
                'sourceRecordID': row['id'], 'sourceFile': row['_file'], 'rawSHA256': digest,
                'denominatorPolicy': alias['denominatorPolicy']}
        result.append(copied)
    return result
