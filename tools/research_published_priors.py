"""Preserve explicitly reviewed, hash-pinned source means without fake studies."""
from copy import deepcopy
from hashlib import sha256
import json
from pathlib import Path

POLICY = Path(__file__).resolve().parent.parent / 'database/research/reviewed-published-milling-priors.json'


def canonical_hash(row):
    raw = {key: value for key, value in row.items() if not key.startswith('_')}
    return sha256(json.dumps(raw, sort_keys=True, ensure_ascii=False, separators=(',', ':'), allow_nan=False).encode()).hexdigest()


def preserve_published_priors(rows, records, notes):
    policy = json.loads(POLICY.read_text(encoding='utf-8'))
    if policy.get('schemaVersion') != 1:
        raise ValueError('Unsupported reviewed published-prior schema')
    sources = {(row.get('_file'), row.get('id')): row for row in rows}
    existing = {record['recordID'] for record in records}
    preserved = []
    for prior in policy['priors']:
        row = sources.get((prior['sourceFile'], prior['sourceRecordID']))
        if not row or prior['recordID'] in existing:
            continue
        if canonical_hash(row) != prior['rawSHA256']:
            notes['reviewed published prior source changed; preserved for renewed review'] += 1
            continue
        if (row.get('casts') is not None or row.get('castsWithDrop') is not None or row.get('totalQuantity') is not None
                or row.get('averagePer') != 'input' or row.get('inputsPerCast') != prior['inputCount']
                or row.get('inputItemID') != prior['inputItemID'] or row.get('outputItemID') != prior['outputItemID']
                or row.get('averageShown') != prior['reportedMean']
                or row['averageShown'] * prior['inputCount'] != prior['meanPerOperation']):
            raise ValueError('Reviewed source prior no longer matches its original units/identity')
        unknown = {'status': 'unknown', 'confidence': 0, 'inferenceBlocked': True}
        provenance = {'policy': policy['revision'], 'sourceRecordID': row['id'], 'sourceFile': row['_file'],
                      'sourceStudyKey': row.get('studyKey'), 'rawSHA256': prior['rawSHA256'],
                      'reportedMean': row['averageShown'], 'reportedUnit': row['averagePer'],
                      'reportedSourceSupportConfidence': prior['sourceSupportConfidence'],
                      'conditionalEmpiricalGateBypassed': False}
        record = {key: deepcopy(prior[key]) for key in ('recordID', 'method', 'profession', 'recipeID',
                  'expansionID', 'inputItemID', 'inputQualityRank', 'inputCount', 'baselineProfileConfidence')}
        record.update(studyID=record['recordID'], sourceKey='itemdb',
            source='research team v3 (research/v3 on implementation/five-agent-completion)',
            sourceURL=row['source']['url'], samples=0, sampleSizeKnown=False, provisional=True,
            supersedesResearch=True, fieldSpecificEvidence=True,
            reviewedPublishedPrior=provenance, sourceEvidence=[provenance],
            referenceContextID='reviewed-published-prior:' + prior['rawSHA256'], referenceConditions={},
            baselineProfile={'skill': 0, 'preSpecializationSkill': 0, 'effectiveSkill': 0,
                             'stats': {}, 'specializationPoints': {}, 'learnedSpecializations': {}},
            baselineProfileAssumed=True,
            baselineStatus='Published rank-specific mean; unknown historical source profile uses an explicit zero-profile modeling prior',
            materials=[{'id': prior['outputItemID'], 'quality': prior['outputQualityRank'],
                'expectedQuantity': {'value': prior['meanPerOperation'], 'status': 'provisional',
                    'confidence': prior['sourceSupportConfidence'], 'samples': 0, 'sampleSizeKnown': False,
                    'independentConfidence': True, 'confidenceBasis': 'Published source support; normalized profile confidence is zero'},
                'dropChance': deepcopy(unknown), 'minQuantity': deepcopy(unknown), 'maxQuantity': deepcopy(unknown)}])
        records.append(record)
        preserved.append(record)
        notes['+reviewed published source mean preserved under zero-confidence profile assumption'] += 1
    return preserved
