"""Compile a bounded snapshot of Retail gear token relationships without evaluating Lua."""

import json
from pathlib import Path
import re


SOURCE = Path('database/research/att-legacy-gear-snapshot.json')
SEPULCHER_TOKEN = re.compile(
    r'i\((\d+),\{b=2,c=\{([\d,]+)\},lvl=(\d+),modID=([3456]),spellID=(\d+),g=\{'
)
SEPULCHER_REWARD = re.compile(
    r's\((\d+),(\d+),\{b=1,c=\{(\d+)\},f=([4-7]),loc=(\d+),lvl=(\d+),modID=([3456])\}\)'
)
ARMOR_CLASSES = {3: range(1, 14), 4: (5, 8, 9), 5: (4, 10, 11, 12),
                 6: (3, 7, 13), 7: (1, 2, 6)}
EQUIPMENT = re.compile(
    r's\((\d+),(\d+),\{b=1,(?:customCollect=\{"(!?HOA)"\},)?'
    r'f=(\d+),(?:loc=(\d+),)?lvl=(\d+)(?:,minReputation=\{2470,3000\})?'
    r'(?:,spellID=\d+)?\}\)[)}]*,?'
)
ACCESSORY = re.compile(
    r'i\((\d+),\{b=1,f=(5[23]),lvl=(\d+),minReputation=\{2470,3000\}'
    r'(?:,spellID=\d+)?\}\)[)}]*,?'
)
TIER_TOKEN = re.compile(
    r'i\((\d+),\{b=2,c=\{([\d,]+)\},(?:description="([^"]+)",)?lvl=32,spellID=(\d+)'
    r'(?:,sym=\{\{"select","itemID",([\d,]+)\}\})?\}\),'
)
TIER_REWARD = re.compile(
    r's\((\d+),(\d+),\{b=1,c=\{(\d+)\},(?:cost=(\{\{"i",\d+,1\}(?:,\{"i",\d+,1\})?\}),)?'
    r'f=[4-7],loc=(\d+),lvl=32\}\)[)}]*,'
)
KORTHIAN_SLOT_LOCS = {
    'INVTYPE_HEAD': {40}, 'INVTYPE_SHOULDER': {41},
    'INVTYPE_CHEST': {42}, 'INVTYPE_ROBE': {42},
    'INVTYPE_WRIST': {43}, 'INVTYPE_HAND': {44}, 'INVTYPE_WAIST': {45},
    'INVTYPE_LEGS': {46}, 'INVTYPE_FEET': {47},
}


def source_url(data, category):
    path = data['sources'][category]['path']
    return f"https://github.com/{data['repository']}/blob/{data['revision']}/{path}"


def record(data, family, token, name):
    return {
        'recordID': f'att-legacy-token:{token}', 'tokenID': token, 'tokenName': name,
        'kind': 'open', 'gameMode': 'Retail', 'requirements': {}, 'requirementsReviewed': False,
        'rewardSelection': 'class', 'listComplete': False, 'costsComplete': False,
        'protectCollection': True,
        'evidenceStatus': 'RESEARCH_RELATIONSHIP', 'independentReview': 'NOT_REVIEWED',
        'confidence0to100': 60, 'patchStartBuild': 1, 'patchEndBuild': 2147483647,
        'sourceRevision': data['revision'], 'sourceOrigin': 'ATT',
        'sourceURLs': [source_url(data, family['source']), family['documentation']],
        'licenseSPDX': data['licenseSPDX'],
        'licenseText': data['licenseText'],
    }


def sepulcher_records(data, family):
    tokens = family['tokens']
    if set(map(int, tokens)) != set(range(191002, 191022)):
        raise ValueError('Incomplete Sepulcher token family')
    for key, entry in sorted(tokens.items()):
        token = int(key)
        variants, masks, requirements, evidence = {}, {}, {}, []
        for row in entry['rows']:
            header, *children = row['lua'].splitlines()
            match = SEPULCHER_TOKEN.fullmatch(header)
            if not match or int(match[1]) != token or len(children) != 3 or not children[-1].endswith('})}}),'):
                raise ValueError(f'Invalid Sepulcher token row {token}')
            classes = {int(c) for c in match[2].split(',')}
            context = match[4]
            if len(classes) != 3 or not 368663 <= int(match[5]) <= 368667 or context in variants:
                raise ValueError(f'Invalid Sepulcher context or use spell for {token}')
            rewards = {}
            child_classes = set()
            for offset, line in enumerate(children, 1):
                reward_match = SEPULCHER_REWARD.fullmatch(line.removesuffix('}}),') if offset == 3 else line.removesuffix(','))
                if not reward_match or reward_match[7] != context:
                    raise ValueError(f'Invalid Sepulcher equipment for {token}')
                source, reward, cls, _, _, level, _ = map(int, reward_match.groups())
                mask = 1 << (cls - 1)
                reward_key = str(reward)
                requirement = {'minimumLevel': level}
                if (cls not in classes or cls in child_classes or reward_key in rewards
                        or masks.setdefault(reward_key, mask) != mask
                        or requirements.setdefault(reward_key, requirement) != requirement):
                    raise ValueError(f'Conflicting Sepulcher class rewards for {token}')
                child_classes.add(cls)
                rewards[str(reward)] = source
                evidence.append({'line': row['line'] + offset, 'rewardID': reward,
                                 'sourceID': source, 'itemContext': int(context)})
            variants[context] = rewards
        if set(variants) != {'3', '4', '5', '6'} or len(masks) != 3:
            raise ValueError(f'Incomplete Sepulcher difficulty coverage for {token}')
        result = record(data, family, token, entry['name'])
        result.update(
            listComplete=True, rewards=sorted(map(int, masks)), rewardVariants=variants,
            rewardClassMasks=masks, rewardRequirements=requirements, sourceEvidence=evidence,
            sourceAssumption='Retail use creates a class set piece. Appearance source depends on raid difficulty.',
        )
        yield result


def equipment_rows(row, allow_groups=False):
    group = None
    for line, content in enumerate(row['lua'].splitlines()[1:], row['line'] + 1):
        heading = re.fullmatch(r'(?:h\(-\d+|flt\([4-7]|flt\(5[23]),\{', content) if allow_groups else None
        if heading:
            group = content
            continue
        item = EQUIPMENT.fullmatch(content)
        if item:
            yield {
                'sourceID': int(item[1]), 'rewardID': int(item[2]), 'heart': item[3],
                'filter': int(item[4]), 'location': int(item[5] or 0), 'level': int(item[6]),
                'line': line, 'group': group,
            }
            continue
        item = ACCESSORY.fullmatch(content) if allow_groups else None
        if item:
            yield {'rewardID': int(item[1]), 'filter': int(item[2]), 'level': int(item[3]), 'line': line}
        else:
            raise ValueError(f'Unsupported direct equipment group or row at line {line}')


def add_direct_rewards(result, equipment, unresolved):
    masks, sources, requirements, evidence = {}, {}, {}, []
    for item in equipment:
        reward = item['rewardID']
        key = str(reward)
        if key in requirements:
            raise ValueError(f'Duplicate equipment reward {reward}')
        requirement = {'minimumLevel': item['level']}
        proof = {'line': item['line'], 'rewardID': reward}
        if 'sourceID' in item:
            sources[key] = item['sourceID']
            proof['sourceID'] = item['sourceID']
        else:
            requirement['hasAppearance'] = False
        if item.get('heart'):
            proof['heartOfAzeroth'] = item['heart'] == 'HOA'
        if unresolved or item.get('heart') or item.get('unverified'):
            requirement['unverified'] = True
        if 'class' in item:
            masks[key] = 1 << (item['class'] - 1)
        else:
            classes = ARMOR_CLASSES.get(item['filter'])
            if classes:
                masks[key] = sum(1 << (cls - 1) for cls in classes)
        requirements[key] = requirement
        evidence.append(proof)
    if not requirements:
        raise ValueError(f"No gear rewards found for {result['tokenID']}")
    result.update(rewards=sorted(map(int, requirements)), rewardSources=sources,
                  rewardClassMasks=masks, rewardRequirements=requirements, sourceEvidence=evidence)


def benthic_records(data, family):
    tokens = family['tokens']
    if set(map(int, tokens)) != set(range(169477, 169486)):
        raise ValueError('Incomplete Benthic token family')
    for key, entry in sorted(tokens.items()):
        token = int(key)
        row, = entry['rows']
        if row['lua'].splitlines()[0] != f'ah({token},{{providers={{{{"i",{token}}}}},type="i",g={{':
            raise ValueError(f'Invalid Benthic token row {token}')
        result = record(data, family, token, entry['name'])
        add_direct_rewards(result, equipment_rows(row), unresolved=False)
        result.update(listComplete=True, sourceAssumption='Account-bound armor token. The opening outcome depends on armor type and gear slot.')
        yield result


def black_empire_records(data, family):
    tokens = family['tokens']
    if set(map(int, tokens)) != (set(range(173393, 173421)) | set(range(173422, 173426))):
        raise ValueError('Incomplete Black Empire token family')
    for key, entry in sorted(tokens.items()):
        token = int(key)
        row, = entry['rows']
        header = re.fullmatch(r'i\((\d+),\{b=2,c=\{([\d,]+)\},lvl=50,g=\{', row['lua'].splitlines()[0])
        if not header or int(header[1]) != token:
            raise ValueError(f'Invalid Black Empire token row {token}')
        items = list(equipment_rows(row))
        classes = {int(cls) for cls in header[2].split(',')}
        filters = {item['filter'] for item in items}
        if len(filters) != 1 or classes != set(ARMOR_CLASSES.get(next(iter(filters)), ())):
            raise ValueError(f'Unexpected Black Empire armor class restrictions for {token}')
        result = record(data, family, token, entry.get('name', f'Black Empire gear token {token}'))
        add_direct_rewards(result, items, unresolved=False)
        result['sourceURLs'].append(family['conditionDocumentation'])
        result.update(listComplete=True,
                      sourceAssumption='Account-bound opening token. Azerite head, shoulder and chest rewards depend on Heart of Azeroth ownership.')
        yield result


def korthian_records(data, family):
    tokens = family['tokens']
    if set(map(int, tokens)) != ({187187} | set(range(188153, 188164))):
        raise ValueError('Incomplete Korthian token family')
    base, = tokens['187187']['rows']
    equipment = list(equipment_rows(base, allow_groups=True))
    for key, entry in sorted(tokens.items()):
        token = int(key)
        row, = entry['rows']
        header = row['lua'].splitlines()[0]
        if not header.startswith(f'i({token},{{') or not re.search(r',spellID=(?:356539|36169[5-9]|36170[023457]),', header):
            raise ValueError(f'Invalid Korthian token row {token}')
        if token == 187187:
            items = equipment
        elif token == 188162 and '"select","itemID",187187' in header and '"where","headerID",-101' in header:
            items = [item for item in equipment if item.get('group') == 'h(-101,{']
        else:
            slots = re.findall(r'\{"sub","korthian_armaments","(INVTYPE_[A-Z_]+)"\}', header)
            if not slots or any(slot not in KORTHIAN_SLOT_LOCS and slot not in {'INVTYPE_CLOAK', 'INVTYPE_FINGER', 'INVTYPE_TRINKET'} for slot in slots):
                raise ValueError(f'Unrecognized Korthian slot for {token}')
            locations = set().union(*(KORTHIAN_SLOT_LOCS.get(slot, set()) for slot in slots))
            include_cloaks = 'INVTYPE_CLOAK' in slots
            include_accessories = 'INVTYPE_FINGER' in slots and 'INVTYPE_TRINKET' in slots
            items = [item for item in equipment if (item.get('location') in locations
                     or include_cloaks and item['filter'] == 3
                     or include_accessories and item['filter'] in (52, 53))]
        result = record(data, family, token, entry['name'])
        add_direct_rewards(result, items, unresolved=True)
        result.update(candidateRewards=True,
                      sourceAssumption='Opens into loot-specialization gear. Exact specialization eligibility and output selection remain unresolved.')
        yield result


def cataclysm_records(data, family, title, expected):
    tokens = family['tokens']
    if set(map(int, tokens)) != expected:
        raise ValueError(f'Incomplete {title} token family')
    for key, entry in sorted(tokens.items()):
        token = int(key)
        token_row = entry['tokenRow']
        match = TIER_TOKEN.fullmatch(token_row['lua'])
        if not match or int(match[1]) != token or not 238187 <= int(match[4]) <= 238273:
            raise ValueError(f'Invalid {title} use spell for {token}')
        classes = {int(cls) for cls in match[2].split(',')}
        selected = {int(reward) for reward in match[5].split(',')} if match[5] else set()
        items = []
        for row in entry['rows']:
            leaf = TIER_REWARD.fullmatch(row['lua'])
            if not leaf:
                raise ValueError(f'Invalid {title} reward for {token}')
            source, reward, cls = map(int, leaf.groups()[:3])
            if (cls not in classes or (selected and (reward not in selected or leaf[4]))
                    or (not selected and f'{{"i",{token},1}}' not in (leaf[4] or ''))):
                raise ValueError(f'Unrelated {title} reward {reward} for {token}')
            items.append({'sourceID': source, 'rewardID': reward, 'class': cls, 'level': 32,
                          'line': row['line'], 'unverified': bool(match[3]) and cls == 2})
        if selected and selected != {item['rewardID'] for item in items}:
            raise ValueError(f'Incomplete {title} reward sources for {token}')
        if {item['class'] for item in items} != classes:
            raise ValueError(f'Incomplete {title} class coverage for {token}')
        result = record(data, family, token, entry.get('name', f'{title} gear token {token}'))
        add_direct_rewards(result, items, unresolved=False)
        result['sourceURLs'].append(source_url(data, family['supportingSource']))
        result.update(listComplete=True, sourceAssumption='Retail use creates gear for the selected loot specialization. Separate vendor routes may cost additional items.')
        yield result


def build_legacy_gear(data=None):
    if data is None:
        data = json.loads(SOURCE.read_text(encoding='utf-8'))
    if (data['schemaVersion'] != 1 or data['gameMode'] != 'Retail'
            or data['repository'] != 'ATTWoWAddon/AllTheThings' or data['licenseSPDX'] != 'MIT'
            or not re.fullmatch(r'[0-9a-f]{40}', data['revision'])
            or any(not re.fullmatch(r'[0-9a-f]{40}', s['blobSHA']) for s in data['sources'].values())):
        raise ValueError('Invalid legacy gear snapshot provenance')
    builders = {'sepulcher': sepulcher_records, 'benthic': benthic_records,
                'blackempire': black_empire_records, 'korthian': korthian_records}
    records = [r for name, builder in builders.items() for r in builder(data, data['families'][name])]
    records.extend(cataclysm_records(data, data['families']['firelands'], 'Firelands', set(range(71668, 71689))))
    records.extend(cataclysm_records(data, data['families']['dragonsoul'], 'Dragon Soul',
                                      set(range(78170, 78185)) | set(range(78847, 78877))))
    return sorted(records, key=lambda r: r['tokenID']), []
