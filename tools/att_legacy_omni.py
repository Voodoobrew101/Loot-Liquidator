"""Read the bounded Retail ATT legacy omni-token snapshot without executing Lua."""

from collections import defaultdict
import json
from pathlib import Path
import re


SOURCE = Path('database/research/att-legacy-omni-snapshot.json')
FORLORN = {66998}
CURSED = set(range(105857, 105869))
IRON = {119310, 119316, 119323, *range(120206, 120212), *range(120277, 120286)}
EXISTING_CURSED = {99713, 99723, 99725}
FACTION = {'1': 'Horde', '2': 'Alliance'}

OFFER = re.compile(r'i\((\d+),\{b=2,c=a\[(\d+)\],cost=\{\{"i",(\d+),1\}\},lvl=(\d+),spellID=(\d+)\}\)')
VENDOR_GEAR = re.compile(r's\((\d+),(\d+),\{b=1,(?:c=a\[(\d+)\],)?'
                         r'cost=(\{\{"i",\d+,1\}(?:,\{"i",\d+,1\})*\}),f=\d+,loc=\d+,lvl=(\d+)\}\)')
QUEST = re.compile(r'q\((\d+),\{c=a\[(\d+)\],lvl=40,qss=\{(\d+)\},r=([12]),repeatable=1,g=\{(.*)\}\}\)')
QUEST_SLOT = re.compile(r'i\((\d+),\{b=2,c=a\[(\d+)\],lvl=40,spellID=(\d+),'
                        r'sym=\{\{"select","itemID",(\d+(?:,\d+)*)\},\{"where","modID",([356])\}\}\}\)')
QUEST_GEAR = re.compile(r's\((\d+),(\d+),\{b=1,c=a\[(\d+)\],f=\d+,loc=\d+,lvl=40,modID=([356])\}\)')


def match_row(pattern, row):
    match = pattern.fullmatch(row['lua'])
    if not match or any(type(row[key]) is not int or row[key] <= 0 for key in ('line', 'column')):
        raise ValueError(f"Unsupported legacy token source at {row['line']}:{row['column']}")
    return match.groups()


def class_mask(aliases, key):
    classes = aliases.get(key)
    if not classes or len(set(classes)) != len(classes) or any(
            type(class_id) is not int or not 1 <= class_id <= 13 for class_id in classes):
        raise ValueError(f'Unsupported ATT class alias {key}')
    return sum(1 << (class_id - 1) for class_id in classes)


def proof(row, reward_id, **fields):
    return {'line': row['line'], 'column': row['column'], 'rewardID': reward_id, **fields}


def item_cost(item_id):
    return {'kind': 'item', 'id': item_id, 'quantity': 1}


def item_costs(text):
    costs = [int(item) for item in re.findall(r'\{"i",(\d+),1\}', text)]
    if not all(costs) or len(set(costs)) != len(costs):
        raise ValueError('Invalid or duplicate legacy exchange cost')
    return [item_cost(item) for item in costs]


def record(data, category, token, kind, reward_rows, assumption, **metadata):
    rewards = sorted(reward_rows)
    requirements = {}
    masks = {}
    sources = {}
    evidence = []
    for reward in rewards:
        row = reward_rows[reward]
        key = str(reward)
        requirements[key] = row['requirement']
        if row.get('classMask') is not None:
            masks[key] = row['classMask']
        if row.get('sourceID') is not None:
            sources[key] = row['sourceID']
        evidence.append(row['evidence'])
    path = data['sources'][category]['path']
    source = f"https://github.com/{data['repository']}/blob/{data['revision']}/{path}"
    result = {
        'recordID': f'att-legacy-omni:{token}', 'tokenID': token,
        'kind': kind, 'gameMode': 'Retail', 'requirements': {}, 'requirementsReviewed': False,
        'rewardSelection': 'choice' if kind == 'exchange' else 'class',
        'patchStartBuild': 1, 'patchEndBuild': 2147483647, 'listComplete': True,
        'evidenceStatus': 'RESEARCH_RELATIONSHIP', 'independentReview': 'NOT_REVIEWED',
        'confidence0to100': 60, 'sourceOrigin': 'ATT',
        'sourceRevision': data['revision'], 'sourceURLs': [source],
        'licenseSPDX': 'MIT', 'licenseText': data['licenseText'],
        'rewards': rewards, 'sourceEvidence': evidence,
        'rewardClassMasks': masks, 'rewardRequirements': requirements,
        'sourceAssumption': assumption, **metadata,
    }
    if sources:
        result['rewardSources'] = sources
    return result


def add_unique(group, key, value):
    if key in group:
        raise ValueError(f'Duplicate legacy token evidence for {key}')
    group[key] = value


def vendor_family(data, family, omnis, slot_count, slots_per_omni, preserved=()):
    category = family['category']
    aliases = data['sources'][category]['classAliases']
    offers = defaultdict(dict)
    slots = {}
    for row in family['offers']:
        reward, alias, token, level, spell = match_row(OFFER, row)
        token, reward = int(token), int(reward)
        mask = class_mask(aliases, alias)
        add_unique(slots, reward, mask)
        add_unique(offers[token], reward, {
            'classMask': mask, 'requirement': {'minimumLevel': int(level)},
            'evidence': proof(row, reward, useSpellID=int(spell)),
        })
    if (set(offers) != omnis or len(slots) != slot_count
            or any(len(group) != slots_per_omni for group in offers.values())):
        raise ValueError('Legacy omni-token vendor coverage changed')

    leaf_rewards = defaultdict(dict)
    vendor_costs = defaultdict(dict)
    for row in family['gear']:
        source, reward, alias, raw_costs, level = match_row(VENDOR_GEAR, row)
        costs = item_costs(raw_costs)
        token_ids = [cost['id'] for cost in costs if cost['id'] in slots]
        if len(token_ids) != 1:
            raise ValueError('Legacy gear row needs exactly one matched armor token')
        token, reward, source = token_ids[0], int(reward), int(source)
        mask = class_mask(aliases, alias) if alias else None
        if mask is not None and mask & slots[token] != mask:
            raise ValueError(f'Legacy gear class is outside armor token group {token}')
        requirement = {'minimumLevel': int(level)}
        if mask is None:
            requirement['unverified'] = True
        add_unique(leaf_rewards[token], reward, {'classMask': mask, 'sourceID': source,
            'requirement': requirement, 'evidence': proof(row, reward, sourceID=source)})
        if len(costs) > 1:
            vendor_costs[token][str(reward)] = costs
    if set(leaf_rewards) != set(slots):
        raise ValueError('Missing equipment leaves for legacy slot tokens')

    output = []
    for token, rewards in sorted(offers.items()):
        output.append(record(data, category, token, 'exchange', rewards,
            'Exchange one essence for one class-group slot token, then use that token.',
            costsComplete=True, costs={str(reward): [item_cost(token)] for reward in rewards}))
    for token, rewards in sorted(leaf_rewards.items()):
        if token in preserved:
            continue
        assumption = 'Retail Use creates class/spec gear.'
        metadata = {}
        if token in vendor_costs:
            assumption += ' The separate vendor route requires the corresponding normal gear.'
            metadata['vendorCosts'] = vendor_costs[token]
        output.append(record(data, category, token, 'open', rewards, assumption, **metadata))
    return output


def iron_family(data, family):
    category = family['category']
    aliases = data['sources'][category]['classAliases']
    sources = {}
    for row in family['gear']:
        source, reward, alias, mod = match_row(QUEST_GEAR, row)
        reward, source = int(reward), int(source)
        add_unique(sources, (reward, mod), {
            'classMask': class_mask(aliases, alias), 'requirement': {'minimumLevel': 40},
            'sourceID': source, 'evidence': proof(row, reward, sourceID=source),
        })
    quests = {}
    slots = {}
    for row in family['quests']:
        quest, alias, token, faction, body = match_row(QUEST, row)
        token, quest = int(token), int(quest)
        class_group = class_mask(aliases, alias)
        choices = list(QUEST_SLOT.finditer(body))
        if len(choices) != 5 or ','.join(choice[0] for choice in choices) != body:
            raise ValueError(f'Blackhand quest {quest} needs five literal slot choices')
        rewards = {}
        for choice in choices:
            slot, slot_alias, spell, item_ids, mod = choice.groups()
            slot = int(slot)
            if class_group != class_mask(aliases, slot_alias):
                raise ValueError(f'Blackhand reward {slot} class group disagrees with its quest')
            equipment = {}
            for item_id in map(int, item_ids.split(',')):
                reward = sources[item_id, mod]
                if reward['classMask'] & class_group != reward['classMask']:
                    raise ValueError(f'Blackhand reward {item_id} is outside its quest class group')
                add_unique(equipment, item_id, reward)
            if slot in slots and slots[slot] != equipment:
                raise ValueError(f'Blackhand faction versions disagree about token {slot}')
            slots[slot] = equipment
            add_unique(rewards, slot, {'classMask': class_group,
                'requirement': {'minimumLevel': 40, 'faction': FACTION[faction]},
                'evidence': proof(row, slot, questID=quest, useSpellID=int(spell))})
        add_unique(quests, token, rewards)
    if (set(quests) != IRON or set(slots) != set(range(120212, 120257))
            or sum(len(rows) for rows in slots.values()) != len(sources)):
        raise ValueError('Blackhand tier family coverage changed')

    output = [record(data, category, token, 'exchange', rewards,
        'Bring the essence to its repeatable faction quest and choose a slot token. '
        'Current quest availability and complete costs remain unverified.',
        costsComplete=False) for token, rewards in sorted(quests.items())]
    output.extend(record(data, category, token, 'open', rewards,
        'Retail Use creates class gear at this token’s raid difficulty.')
        for token, rewards in sorted(slots.items()))
    return output


def build_legacy_omni():
    data = json.loads(SOURCE.read_text(encoding='utf-8'))
    if (data['schemaVersion'] != 1 or data['gameMode'] != 'Retail'
            or data['repository'] != 'ATTWoWAddon/AllTheThings' or data['licenseSPDX'] != 'MIT'
            or not re.fullmatch(r'[0-9a-f]{40}', data['revision'])
            or 'Permission is hereby granted' not in data['licenseText']):
        raise ValueError('Invalid legacy omni-token source scope or attribution')
    family = data['families']
    records = vendor_family(data, family['forlorn'], FORLORN, 15, 15)
    records.extend(vendor_family(data, family['cursed'], CURSED, 60, 5, EXISTING_CURSED))
    records.extend(iron_family(data, family['iron']))
    return sorted(records, key=lambda row: row['tokenID']), []
