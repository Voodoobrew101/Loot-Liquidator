"""Import bounded Retail equipment token records from an attributed ATT snapshot."""

import argparse
import hashlib
import json
from pathlib import Path
import re


SOURCE = Path('database/research/att-modern-gear-snapshot.json')
REPOSITORY = 'ATTWoWAddon/AllTheThings'
REVISION = 'f3e3ad3d0b03b5787258f8f3a0e3da61554733b3'
RELEASE_URL = f'https://github.com/{REPOSITORY}/releases/tag/5.4.8'
VOID_IDS = range(281405, 281430)
DREAMBOUND_IDS = (208909, 208910, 208922, 208923, 208924, 208926)
DREAMBOUND_NAMES = ('Plate Bracers', 'Plate Belt', 'Cloak', 'Ring', 'Necklace', 'Weapon')
NIGHTFALL = 238920
SLOT_NAMES = ('Boots', 'Legs', 'Belts', 'Gloves', 'Bracers', 'Chest', 'Cloak',
              'Shoulder', 'Head', 'Weapons', 'Necklaces', 'Rings')
SLOT_KEYS = ('FEET', 'LEGS', 'WAIST', 'HAND', 'WRIST', 'CHEST', 'CLOAK',
             'SHOULDER', 'HEAD', 'WEAPONS', 'NECK', 'FINGER')
ARMOR_LOCATIONS = {
    40: 'HEAD', 41: 'SHOULDER', 42: 'CHEST', 43: 'WRIST',
    44: 'HAND', 45: 'WAIST', 46: 'LEGS', 47: 'FEET',
}
WEAPON_FILTERS = {1, 8, *range(20, 36)}
NO_APPEARANCE = {51, 52, 53}
VOID_PATCH_BUILD = 69214


def call_at(text, start):
    """Return one complete quoted-string-safe Lua invocation, without evaluating it."""
    depth, quoted, escaped = 0, False, False
    for pos in range(start, len(text)):
        char = text[pos]
        if quoted:
            if escaped:
                escaped = False
            elif char == '\\':
                escaped = True
            elif char == '"':
                quoted = False
        elif char == '"':
            quoted = True
        elif char == '(':
            depth += 1
        elif char == ')':
            depth -= 1
            if depth == 0:
                return text[start:pos + 1]
    raise ValueError('Unclosed Lua invocation')


def source_row(text, offset, path):
    return {'path': path, 'line': text.count('\n', 0, offset) + 1,
            'column': offset - text.rfind('\n', 0, offset),
            'lua': call_at(text, offset)}


def extract_snapshot(att_dir):
    manifest = (att_dir / 'AllTheThings.toc').read_text(encoding='utf-8-sig')
    if not re.search(r'^## Version:\s*5\.4\.8\s*$', manifest, re.M):
        raise ValueError('Use the installed ATT 5.4.8 Retail release to reproduce the snapshot')
    files = {}
    data = {'schemaVersion': 1, 'gameMode': 'Retail', 'repository': REPOSITORY,
            'revision': REVISION, 'sourceReleaseURL': RELEASE_URL, 'licenseSPDX': 'MIT',
            'sourceOrigin': 'Extracted from the installed generated Retail files of ATT 5.4.8. The revision identifies the release.',
            'licenseText': SOURCE.with_name('ATT-LICENSE.txt').read_text(encoding='utf-8'),
            'sources': files, 'tokenRows': {}, 'emblemRows': []}
    targets = {
        'ExpansionFeatures.lua': (*VOID_IDS, *DREAMBOUND_IDS),
        'NeverImplemented.lua': (208925,),
        'Zones.lua': (274272,),
        'PVP.lua': (271991,),
    }
    for name, ids in targets.items():
        path = f'db/Standard/Categories/{name}'
        raw = (att_dir / path).read_bytes()
        files[path] = hashlib.sha256(raw).hexdigest()
        text = raw.decode('utf-8-sig')
        for token in ids:
            matches = list(re.finditer(rf'\bi\({token},', text))
            if len(matches) != 1:
                raise ValueError(f'Expected one record for item {token} in {path}')
            data['tokenRows'][str(token)] = source_row(text, matches[0].start(), path)
        if name == 'Zones.lua':
            for match in re.finditer(r'\{"i",238920,1\}', text):
                offset = max(text.rfind('s(', 0, match.start()), text.rfind('i(', 0, match.start()))
                data['emblemRows'].append(source_row(text, offset, path))
    return data


GEAR_SOURCE = re.compile(r'\bs\(([1-9]\d*),([1-9]\d*),\{f=(\d+)(?:,loc=(\d+))?\}\)')
ACCESSORY = re.compile(r'\bi\(([1-9]\d*),\{f=(51|52)\}\)')
VOID_SLOT = re.compile(r'i\((\d+),\{awp=120100,cost=\{\{"c",3405,(200|750)\}\},'
                       r'sym=\{\{"select","itemID",281429\},\{"pop"\},\{"extract","itemID"\},'
                       r'\{"invtype",("INVTYPE_[A-Z0-9]+"(?:,"INVTYPE_[A-Z0-9]+")*)\}\}\}\)')


def void_pool(row):
    lua = row['lua']
    if not lua.startswith('i(281429,{awp=120100,cost={{"c",3405,500}},g={'):
        raise ValueError('Unexpected random Void-Touched cache row')
    pool = {}
    for match in GEAR_SOURCE.finditer(lua):
        source, item, category, location = map(int, match.groups(default='0'))
        if location in ARMOR_LOCATIONS and category in {4, 5, 6, 7}:
            slot = ARMOR_LOCATIONS[location]
        elif location == 0 and category == 3:
            slot = 'CLOAK'
        elif location == 0 and category in WEAPON_FILTERS:
            slot = 'WEAPONS'
        else:
            raise ValueError(f'Unexpected inventory filter for Void-Touched reward {item}')
        if item in pool:
            raise ValueError(f'Duplicate Void-Touched reward {item}')
        pool[item] = (slot, source)
    for match in ACCESSORY.finditer(lua):
        item, category = map(int, match.groups())
        if item in pool:
            raise ValueError(f'Duplicate Void-Touched accessory {item}')
        pool[item] = ('NECK' if category == 51 else 'FINGER', None)
    if len(pool) != len(re.findall(r'\b[si]\(', lua)) - 1:
        raise ValueError('Unparsed equipment leaf in the Void-Touched reward pool')
    return pool


def slot_pool(token, row, pool):
    match = VOID_SLOT.fullmatch(row['lua'])
    if not match or int(match[1]) != token or int(match[2]) != (200 if token < 281417 else 750):
        raise ValueError(f'Unsupported Void-Touched slot row for {token}')
    filters = set(re.findall(r'"INVTYPE_([A-Z0-9]+)"', match[3]))
    if filters == {'BODY', 'CHEST', 'ROBE'}:
        slot = 'CHEST'
    elif filters == {'WEAPON', 'SHIELD', '2HWEAPON', 'WEAPONMAINHAND', 'RANGED',
                     'RANGEDRIGHT', 'WEAPONOFFHAND', 'HOLDABLE'}:
        slot = 'WEAPONS'
    elif len(filters) == 1:
        slot = filters.pop()
    else:
        raise ValueError(f'Unsupported Void-Touched inventory filter for {token}')
    if slot != SLOT_KEYS[(token - 281405) % len(SLOT_KEYS)]:
        raise ValueError(f'Wrong Void-Touched inventory filter for {token}')
    rewards = {item: source for item, (item_slot, source) in pool.items() if item_slot == slot}
    if not rewards:
        raise ValueError(f'Empty Void-Touched reward slot for {token}')
    return rewards


def evidence(row):
    return {key: row[key] for key in ('path', 'line', 'column', 'upstreamLine') if key in row}


def record(data, token, name, kind, rewards, rows, note, *, start=1, costs=None, no_appearance=()):
    reward_ids = sorted(rewards)
    no_appearance = set(no_appearance)
    urls = sorted({f"https://github.com/{REPOSITORY}/blob/{REVISION}/{row['path']}" for row in rows})
    result = {
        'recordID': f'att-modern-gear:{token}', 'tokenID': token, 'tokenName': name,
        'gameMode': 'Retail', 'kind': kind, 'requirements': {}, 'requirementsReviewed': False,
        'rewardSelection': 'choice' if kind == 'exchange' else 'class', 'costsComplete': costs is not None,
        'listComplete': False, 'evidenceStatus': 'RESEARCH_RELATIONSHIP', 'independentReview': 'NOT_REVIEWED',
        'confidence0to100': 60, 'patchStartBuild': start, 'patchEndBuild': 2147483647,
        'sourceRevision': REVISION, 'sourceOrigin': 'ATT', 'sourceURLs': [RELEASE_URL, *urls],
        'licenseSPDX': 'MIT', 'licenseText': data['licenseText'], 'rewards': reward_ids,
        'rewardRequirements': {str(item): {'unverified': True, **(
            {'hasAppearance': False} if item in no_appearance else {})} for item in reward_ids},
        'sourceEvidence': [evidence(row) for row in rows], 'sourceAssumption': note,
        'protectCollection': any(item not in no_appearance for item in reward_ids),
    }
    if costs is not None:
        result['costs'] = costs
    else:
        result['candidateRewards'] = True
    sources = {str(item): source for item, source in rewards.items() if source is not None}
    if sources:
        result['rewardSources'] = sources
    return result


EMBLEM_LEAF = re.compile(
    r'([si])\(([1-9]\d*),(?:([1-9]\d*),)?\{b=1,cost=\{\{"i",238920,1\}\},'
    r'f=(\d+)(?:,loc=\d+)?,lvl=(\d+)(?:,spellID=\d+)?\}\)')
DREAMBOUND_LEAF = re.compile(
    r'i\((\d+),\{b=2,(?:c=a\[329\],)?cost=\{\{"i",207026,100\}\},lvl=70,'
    r'spellID=\d+,sym=\{\{"select","itemID",([1-9]\d*(?:,[1-9]\d*)*)\}\}\}\)')


def build_modern_gear(data=None):
    if data is None:
        data = json.loads(SOURCE.read_text(encoding='utf-8'))
    if (data.get('schemaVersion') != 1 or data.get('gameMode') != 'Retail'
            or data.get('repository') != REPOSITORY or data.get('revision') != REVISION
            or data.get('sourceReleaseURL') != RELEASE_URL or data.get('licenseSPDX') != 'MIT'
            or 'Permission is hereby granted' not in data.get('licenseText', '')):
        raise ValueError('Expected the attributed ATT 5.4.8 Retail snapshot')

    token_rows = data['tokenRows']
    pool_row = token_rows['281429']
    pool = void_pool(pool_row)
    records = []
    for token in VOID_IDS:
        row = token_rows[str(token)]
        random = token == 281429
        rewards = {item: source for item, (_, source) in pool.items()} if random else slot_pool(token, row, pool)
        accessory = {item for item in rewards if pool[item][0] in ('NECK', 'FINGER')}
        tier = 'Adventurer' if token < 281417 else 'Veteran'
        suffix = '' if random else ': ' + SLOT_NAMES[(token - 281405) % 12]
        records.append(record(data, token, f'{tier} Cache of Void-Touched Armaments{suffix}', 'open',
                              rewards, [row] if random else [row, pool_row],
                              'Possible equipment pool. The exact loot-specialization outcomes and gear variant are unverified.',
                              start=VOID_PATCH_BUILD, no_appearance=accessory))

    rewards, no_appearance, costs, requirements = {}, set(), {}, {}
    rows = data['emblemRows']
    for row in rows:
        match = EMBLEM_LEAF.fullmatch(row['lua'])
        if not match or (match[1] == 's') != bool(match[3]):
            raise ValueError('Unsupported Nightfall one-emblem equipment leaf')
        item = int(match[3] or match[2])
        if item in rewards:
            raise ValueError(f'Duplicate Nightfall emblem reward {item}')
        rewards[item] = int(match[2]) if match[1] == 's' else None
        if int(match[4]) in NO_APPEARANCE:
            no_appearance.add(item)
        costs[str(item)] = [{'kind': 'item', 'id': NIGHTFALL, 'quantity': 1}]
        requirements[str(item)] = int(match[5])
    if len(rewards) != 80:
        raise ValueError('Incomplete Nightfall emblem equipment pool')
    emblem = record(data, NIGHTFALL, 'Radiant Emblem of Service', 'exchange', rewards, rows,
                    'One emblem buys listed gear. Live merchant access and character eligibility are unverified.',
                    costs=costs, no_appearance=no_appearance)
    for item, level in requirements.items():
        emblem['rewardRequirements'][item]['minimumLevel'] = level
    records.append(emblem)

    for token, suffix in zip(DREAMBOUND_IDS, DREAMBOUND_NAMES):
        row = token_rows[str(token)]
        match = DREAMBOUND_LEAF.fullmatch(row['lua'])
        if not match or int(match[1]) != token:
            raise ValueError(f'Unsupported Dreambound opening record for {token}')
        ids = [int(item) for item in match[2].split(',')]
        if len(ids) != len(set(ids)):
            raise ValueError(f'Duplicate Dreambound reward for {token}')
        records.append(record(data, token, f'Dreambound {suffix}', 'open',
                              dict.fromkeys(ids), [row],
                              'The cache opens into gear. The acquisition payment is separate. Exact reward variants and current eligibility are unverified.',
                              no_appearance=ids if token in (208923, 208924) else ()))

    holds = {
        208925: 'The ATT Retail data lists Dreambound Trinket as never implemented.',
        271991: 'The Venomous Equipment Chest opening spell is confirmed, but its loot-spec reward pool is unverified.',
        274272: 'The Amani Equipment Chest opens into one loot-spec dungeon item, but its exact reward pool is unverified.',
    }
    held = []
    for token, reason in holds.items():
        row = token_rows[str(token)]
        if not row['lua'].startswith(f'i({token},'):
            raise ValueError(f'Missing ATT evidence for held item {token}')
        held.append({'tokenID': token, 'reason': reason, **evidence(row)})
    return sorted(records, key=lambda row: row['tokenID']), held


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--extract', type=Path, help='ATT 5.4.8 addon directory')
    args = parser.parse_args()
    if args.extract:
        snapshot = extract_snapshot(args.extract)
        if SOURCE.is_file():
            existing = json.loads(SOURCE.read_text(encoding='utf-8'))
            if snapshot['sources'] == existing['sources'] and snapshot['revision'] == existing['revision']:
                old_rows = [*existing['tokenRows'].values(), *existing['emblemRows']]
                new_rows = [*snapshot['tokenRows'].values(), *snapshot['emblemRows']]
                verified = {(row['path'], row['line'], row['column'], row['lua']): row['upstreamLine']
                            for row in old_rows if 'upstreamLine' in row}
                if len(verified) == len(new_rows):
                    for row in new_rows:
                        key = (row['path'], row['line'], row['column'], row['lua'])
                        row['upstreamLine'] = verified[key]
                    snapshot['sourceOrigin'] = existing['sourceOrigin']
                    snapshot['upstreamBlobs'] = existing['upstreamBlobs']
        build_modern_gear(snapshot)
        SOURCE.write_text(json.dumps(snapshot, indent=2) + '\n', encoding='utf-8', newline='\n')
    records, held = build_modern_gear()
    print(f'Modern gear: {len(records)} catalogs, {sum(len(row["rewards"]) for row in records)} relations, {len(held)} held')
