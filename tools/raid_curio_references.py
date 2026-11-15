"""Compile independently documented one-curio vendor paths from a pinned snapshot."""

import json
from pathlib import Path
import re


SOURCE = Path('database/research/raid-curio-costs-snapshot.json')
TIER_ROW = re.compile(r'i\((\d+),\{[^{}]*?\bmodID=([3456]),spellID=\d+,g=\{'
                      r'((?:s\(\d+,\d+,\{[^{}]+\}\),?)+)\}\}\)')
REWARD = re.compile(r's\((\d+),(\d+),\{[^{}]+\bmodID=([3456])(?:,up=\d+)?\}\)')


def build_curio_proofs(data=None):
    if data is None:
        data = json.loads(SOURCE.read_text(encoding='utf-8'))
    if data['schemaVersion'] != 1 or not re.fullmatch('[0-9a-f]{40}', data['revision']):
        raise ValueError('Invalid raid curio evidence snapshot')
    records = []
    for family in data['families']:
        token = family['tokenID']
        children = set(family['slotTokenIDs'])
        offers, contexts = {}, {str(n): {} for n in (3, 4, 5, 6)}
        for row in family['tierRows']:
            match = TIER_ROW.fullmatch(row)
            if not match:
                raise ValueError(f'Invalid pinned tier row for curio {token}')
            child, context = int(match[1]), match[2]
            if child not in children or (child, context) in offers:
                raise ValueError(f'Unexpected or duplicate tier row for curio {token}')
            rewards = list(REWARD.finditer(match[3]))
            if match[3] != ','.join(m[0] for m in rewards) or len(rewards) not in (3, 4):
                raise ValueError(f'Unsupported equipment leaves for curio {token}')
            offers[child, context] = {int(m[2]) for m in rewards}
            for reward in rewards:
                if reward[2] in contexts[context] or reward[3] != context:
                    raise ValueError(f'Conflicting tier appearance for curio {token}')
                contexts[context][reward[2]] = int(reward[1])
        if (len(children) != 20 or len(offers) != 80
                or any(len(v) != 65 for v in contexts.values())
                or any(set(v) != set(contexts['3']) for v in contexts.values())
                or any(offers[child, context] != offers[child, '3']
                       for child in children for context in contexts)):
            raise ValueError(f'Incomplete tier family for curio {token}')
        if family['quantity'] != 1 or family['offerType'] not in ('tierToken', 'equipment'):
            raise ValueError(f'Unsupported direct merchant cost or offer type for curio {token}')
        expected = {str(child): sorted(offers[child, '3']) for child in sorted(children)}
        alternatives = {}
        for correction in family.get('slotAlternatives', []):
            child = str(correction['slotTokenID'])
            original = sorted(correction['alternativeRewards'])
            if child not in expected or original == expected[child] or len(original) != len(set(original)):
                raise ValueError(f'Invalid pinned tier alternative for curio {token}')
            alternatives[child] = original
        if alternatives and sorted(i for child, ids in expected.items() for i in alternatives.get(child, ids)) != sorted(map(int, contexts['3'])):
            raise ValueError(f'Tier alternatives change final reward membership for curio {token}')
        direct = sorted(children if family['offerType'] == 'tierToken' else map(int, contexts['3']))
        records.append({'tokenID': token, 'merchantName': family['merchantName'], 'rewards': direct,
                        'finalRewards': sorted(map(int, contexts['3'])),
                        'slotRewards': expected, 'slotAlternatives': alternatives,
                        'contexts': contexts, 'quantity': family['quantity'],
                        'sourceURLs': family['sources'], 'sourceRevision': data['revision']})
    if len({record['tokenID'] for record in records}) != len(records):
        raise ValueError('Duplicate raid curio evidence')
    return records
