"""One hash-bound, owner-reviewed retained DE subset; no general coverage waiver.

Raw receipts and the censored gap remain offline. The existing evidence compiler
alone calculates numerical fields from this subset's integer counts.
"""
import collections
import copy
import hashlib
import json
from pathlib import Path

import evidence_check
import evidence_to_baselines
from validate_craft_export import unpack_transfer, validate

ROOT = Path(__file__).resolve().parents[1]
RELATIVE = Path('research/integration/measured-captures/2026-11-22-reviewed-disenchant-subset')
PROFILE_FIELDS = ('profession', 'baseSkill', 'bonusSkill', 'effectiveSkill', 'preSpecializationSkill',
                  'maxSkill', 'skillLineID', 'specialization', 'specializationKnown',
                  'specializationPoints', 'learnedSpecializations', 'buffsKnown', 'buffs', 'buffStacks')


def compact_profile(context):
    result = {key: copy.deepcopy(context[key]) for key in PROFILE_FIELDS if key in context}
    result.update(skill=context['baseSkill'], expansionID=context['inputExpansionID'],
                  simulated=False, profileKind='measured')
    result['fieldStatus'] = {key: value for key, value in context['fieldStatus'].items()
                             if key in ('baseSkill', 'bonusSkill', 'effectiveSkill', 'specialization', 'operationStats')}
    return result


def reviewed_counts(folder=None):
    folder = Path(folder) if folder else ROOT / RELATIVE
    review_bytes = (folder / 'coverage-review.json').read_bytes()
    review = json.loads(review_bytes)
    if review.get('schemaVersion') != 'loot-liquidator.reviewed-retained-disenchants/1':
        raise ValueError('Unknown retained-subset review schema')
    if review.get('sourceFile') != 'source-transfer.json':
        raise ValueError('Reviewed source must be the pinned compact wire')
    wire_bytes = (folder / review['sourceFile']).read_bytes()
    if hashlib.sha256(wire_bytes).hexdigest() != review['sourceWireSHA256']:
        raise ValueError('Reviewed disenchant wire checksum changed')
    wire = json.loads(wire_bytes)
    import base64
    import zlib
    page = unpack_transfer(wire)
    decoded = zlib.decompress(base64.b64decode(wire['payload'], validate=True))
    if hashlib.sha256(decoded).hexdigest() != review['sourceDecodedWireSHA256']:
        raise ValueError('Reviewed disenchant decoded checksum changed')
    records, contexts, studies = validate([page])
    study = studies[review['studyID']]
    gap = study.get('coverageGaps', {}).get('Disenchant:13262')
    if (len(records) != review['recordCount'] or review['recordCount'] != 119
            or study.get('coverageVersion') != 2 or study.get('truncated')
            or study.get('globalCoverageGap') or study.get('censored') is not True
            or gap != review['originalCoverageGap'] or review['wholeStudyComplete'] is not False
            or review['unbiasedWholeStudyClaim'] is not False):
        raise ValueError('Reviewed retained-subset coverage changed')
    by_id = {record['operationID']: record for record in records}
    selected, cohorts = set(), []
    expected = {'gear:9:4:armor': 66, 'gear:9:4:weapon': 17,
                'gear:11:4:armor': 9, 'gear:11:4:weapon': 1}
    if {g['category']: g['operations'] for g in review['groups']} != expected or len(review['groups']) != 4:
        raise ValueError('Reviewed category/profile cohorts changed')
    for group in review['groups']:
        cohort, profile = [], group['baselineProfile']
        if group['profileKey'] != f"effective:{profile['effectiveSkill']:g};specialization:none;buffs:":
            raise ValueError('Reviewed measured profile key changed')
        lo, hi, band_ids = group['nativeBand']
        if (lo, hi) != (1, 999) or not band_ids:
            raise ValueError('Reviewed native category band changed')
        for operation in group['operationIDs']:
            if operation in selected or operation not in by_id:
                raise ValueError('Duplicate or unknown reviewed operation')
            selected.add(operation)
            record = by_id[operation]
            context = contexts[record['contextID']]
            inputs = record.get('nominalInputs', record['inputs'])
            if (record['studyID'] != review['studyID'] or str(record['build']) != str(review['build'])
                    or record.get('clientVersion') != review['clientVersion']
                    or record['method'] != 'Disenchant' or record['recipeID'] != 13262
                    or record['outputCoverage'] != 'complete' or len(inputs) != 1
                    or inputs[0]['quantity'] != 1 or compact_profile(context) != profile):
                raise ValueError('Reviewed operation/profile membership changed')
            item = inputs[0]
            kind = {2: 'weapon', 4: 'armor'}.get(item.get('classID'))
            category = f"gear:{item.get('expansionID')}:{item.get('rarity')}:{kind}"
            if category != group['category'] or not lo <= item.get('itemLevel', -1) <= hi:
                raise ValueError('Reviewed source era/rarity/class/level changed')
            cohort.append(record)
        if len(cohort) != group['operations']:
            raise ValueError('Reviewed cohort denominator changed')
        counts = {}
        held_outputs = set(review['heldOutputItemIDs'])
        ids = sorted({item['itemID'] for record in cohort for item in record['outputs']} - held_outputs)
        for item in ids:
            quantities = [next((o['quantity'] for o in record['outputs'] if o['itemID'] == item), 0)
                          for record in cohort]
            positive = [quantity for quantity in quantities if quantity > 0]
            counts[item] = {'hits': len(positive), 'units': sum(quantities),
                            'min': min(positive), 'max': max(positive),
                            'histogram': dict(sorted(collections.Counter(map(str, quantities)).items()))}
        cohorts.append((group, counts))
    held = set(review['heldOperationIDs'])
    if (len(selected) != review['admittedOperations'] or len(selected) != 93
            or len(held) != review['heldOperations'] or len(held) != 26
            or selected & held or selected | held != set(by_id)):
        raise ValueError('Reviewed selected/held partition changed')
    return review, cohorts, hashlib.sha256(review_bytes).hexdigest()


def compile_records(folder=None):
    review, cohorts, review_hash = reviewed_counts(folder)
    entries, metadata = [], {}
    source = 'https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/' + RELATIVE.as_posix() + '/source-transfer.json'
    for group, counts in cohorts:
        key = hashlib.sha256(json.dumps({'category': group['category'], 'profile': group['baselineProfile']},
                                       sort_keys=True).encode()).hexdigest()[:16]
        identity = 'reviewed-retained-de:' + key
        expansion, rarity, kind = group['category'].split(':')[1:]
        record = {'method': 'Disenchant', 'profession': 'Enchanting', 'input': group['category'],
                  'inputPerCast': 1, 'casts': group['operations'], 'outputs': [], 'source': source,
                  'lineage': review['studyID'], 'observedDate': '2026-11-22',
                  'patch': review['clientVersion'], 'stale': False, 'recipeID': 13262,
                  'expansionID': int(expansion), 'inputRarity': int(rarity),
                  'inputClassID': 2 if kind == 'weapon' else 4,
                  'referenceContextID': identity, 'referenceConditions': {},
                  'baselineProfile': group['baselineProfile'], 'skill': group['baselineProfile']['baseSkill']}
        for item, values in counts.items():
            record['outputs'].append({'item': item, 'castsWithDrop': values['hits'],
                                      'totalQuantity': values['units'], 'min': values['min'], 'max': values['max']})
        reasons = evidence_check.check_evidence(record)
        if reasons:
            raise ValueError('Invalid reviewed category evidence: ' + '; '.join(reasons))
        entries.append({'kind': 'evidence', 'id': identity, 'record': record})
        metadata[identity] = (group, counts)
    records, notes = evidence_to_baselines.build({'usable': entries})
    if len(records) != 4 or notes['used'] != 4 or notes['duplicates'] or notes['skipped']:
        raise ValueError('Reviewed retained cohorts did not compile independently')
    for record in records:
        group, counts = metadata[record['evidenceRecordIDs'][0]]
        record['recordID'] = record['recordID'].replace('evidence:', 'evidence:category:', 1)
        record['studyID'] = record['recordID']
        record.update(isDisenchantCategory=True, categoryReferenceOnly=False, fixedReference=True,
                      retainedSourceProfileKey=group['profileKey'], sourceRecordIDs=group['operationIDs'],
                      categoryContext='reviewed-retained-measured-profile',
                      categorySourceStudyIDs=[review['studyID']], categoryObservedCasts=group['operations'],
                      categoryItemLevelMin=group['nativeBand'][0], categoryItemLevelMax=group['nativeBand'][1],
                      categoryNativeBandIDs=group['nativeBand'][2], patchBuild=str(review['build']),
                      targetBuild=review['build'], clientVersion=review['clientVersion'],
                      sourceKind='reviewed-player-retained-subset', sourceSHA256=review['sourceWireSHA256'],
                      sourceReviewSHA256=review_hash, studyCoverageCensored=True,
                      coverageSelection='complete-retained-known-profile-records',
                      observedOperations=group['operations'],
                      sourceObservedItemLevelMin=group['sourceItemLevelRange'][0],
                      sourceObservedItemLevelMax=group['sourceItemLevelRange'][1],
                      baselineStatus='Measured retained subset at the recorded profile; not a whole-study or minimum-skill claim')
        for material in record['materials']:
            material['quantityCounts'] = counts[material['id']]['histogram']
            material['boundsBasis'] = 'observed-positive-range-not-guaranteed'
    return records
