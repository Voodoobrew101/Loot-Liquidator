"""Preserve explicitly reviewed, hash-pinned source means without fake studies."""
from copy import deepcopy
from hashlib import sha256
import json
from pathlib import Path

POLICY = Path(__file__).resolve().parent.parent / 'database/research/reviewed-published-milling-priors.json'
ROOT = Path(__file__).resolve().parent.parent


def canonical_hash(row):
    raw = {key: value for key, value in row.items() if not key.startswith('_')}
    return sha256(json.dumps(raw, sort_keys=True, ensure_ascii=False, separators=(',', ':'), allow_nan=False).encode()).hexdigest()


def preserve_published_priors(rows, records, notes, snapshot=None):
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
        if 'expectedQuantity' in row.get('_reviewedSupersededFields', []):
            notes['reviewed published prior replaced by a scoped normalized source model'] += 1
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
    preserved.extend(_preserve_per_input_groups(rows, records, notes, policy, snapshot))
    return preserved


def _json_lines(path):
    result = []
    for line in path.read_text(encoding='utf-8').splitlines():
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(row, dict):
            result.append(row)
    return result


def _preserve_per_input_groups(rows, records, notes, policy, snapshot):
    """One grouped, unranked reference vector per exact archived herb cohort.

    The reviewed whole generated-file hash is provenance, not a blanket hold
    on unrelated later rows. Exact target rows and the immutable archive are
    admission authority; physical source bytes independently verify the loader.
    """
    sources = {(row.get('_file'), row.get('id')): row for row in rows}
    existing = {record['recordID'] for record in records}
    preserved = []
    for group in policy.get('perInputGroups', []):
        if group['recordID'] in existing:
            continue
        candidates = [sources.get((group['sourceFile'], output['sourceRecordID'])) for output in group['outputs']]
        if not any(candidates):
            continue
        if snapshot is None or not all(candidates):
            notes['reviewed per-input prior requires its complete physical source group'] += 1
            continue
        source_path = Path(snapshot) / group['sourceFile']
        archive_path = ROOT / group['archivePath']
        if not source_path.is_file() or not archive_path.is_file():
            notes['reviewed per-input prior physical source or archive missing'] += 1
            continue
        if sha256(archive_path.read_bytes()).hexdigest() != group['archiveSHA256']:
            notes['reviewed per-input prior immutable archive changed'] += 1
            continue
        source_fingerprint = sha256(source_path.read_bytes()).hexdigest()
        physical = _json_lines(source_path)
        archive = _json_lines(archive_path)
        evidence = []
        for row, output in zip(candidates, group['outputs']):
            matching = [raw for raw in physical if raw.get('id') == output['sourceRecordID']]
            if (canonical_hash(row) != output['rawSHA256'] or len(matching) != 1
                    or canonical_hash(matching[0]) != output['rawSHA256']):
                notes['reviewed per-input prior exact source row changed'] += 1
                break
            old = archive[output['archiveLine'] - 1]
            migration = row.get('migratedFrom') or {}
            old_source = old.get('source') or {}
            if (group['method'] != 'Mill' or group['profession'] != 'Inscription' or group['inputCount'] != 1
                    or group['baselineProfileConfidence'] != 0 or group['modelConfidence0to100'] != 0
                    or row.get('sourceKind') != 'reference' or row.get('method') != group['method']
                    or row.get('studyKey') != group['sourceStudyKey'] or row.get('inputItemID') != group['inputItemID']
                    or row.get('outputItemID') != output['outputItemID'] or row.get('inputRank') is not None
                    or row.get('outputRank') is not None or row.get('averagePer') != 'input'
                    or row.get('inputsPerCast') != group['reportedInputsPerCast']
                    or row.get('inputsProcessed') != group['inputsProcessed']
                    or row.get('totalQuantity') != output['reportedOutputTotal']
                    or row.get('averageShown') != output['reportedOutputTotal'] / group['inputsProcessed']
                    or any(row.get(key) is not None for key in ('casts', 'castsBasis', 'castsWithDrop', 'percentShown',
                                                             'percentMeaning', 'minSeen', 'maxSeen', 'histogram'))
                    or row.get('source', {}).get('author') != group['sourceAuthor']
                    or row.get('source', {}).get('url') != group['sourceURL']
                    or migration.get('path') != group['archivePath'] or migration.get('sha256') != group['archiveSHA256']
                    or migration.get('recordRef') != output['archiveRecordRef']
                    or old.get('recordKey') != output['archiveRecordKey'] or old.get('inputItemId') != group['inputItemID']
                    or old.get('outputItemId') != output['outputItemID']
                    or old_source.get('originalHerbsConsumed') != group['inputsProcessed']
                    or old_source.get('reportedOutputTotal') != output['reportedOutputTotal']
                    or old_source.get('observedMassMillReagentCount') != group['reportedInputsPerCast']
                    or old_source.get('commentAuthor') != group['sourceAuthor'] or old_source.get('url') != group['sourceURL']
                    or not 0 < group['sourceSupportConfidence'] <= 20
                    or old.get('fieldEvidence', {}).get('expectedQuantity', {}).get('confidence') != group['archivedSourceSupportConfidence']):
                raise ValueError('Reviewed per-input source no longer matches its exact archive identity, totals or units')
            evidence.append({'policy': policy['revision'], 'sourceRecordID': row['id'], 'sourceFile': group['sourceFile'],
                'sourceStudyKey': group['sourceStudyKey'], 'rawSHA256': output['rawSHA256'],
                'reviewedSourceFileSHA256': group['reviewedSourceFileSHA256'], 'snapshotSourceFileSHA256': source_fingerprint,
                'archivePath': group['archivePath'], 'archiveSHA256': group['archiveSHA256'],
                'archiveRecordRef': output['archiveRecordRef'], 'inputItemID': group['inputItemID'],
                'outputItemID': output['outputItemID'], 'inputsProcessed': group['inputsProcessed'],
                'reportedOutputTotal': output['reportedOutputTotal'], 'reportedMean': row['averageShown'], 'reportedUnit': 'input',
                'reportedInputsPerCast': group['reportedInputsPerCast'],
                'reportedSourceSupportConfidence': group['archivedSourceSupportConfidence'],
                'activeSourceSupportConfidence': group['sourceSupportConfidence'], 'supportPolicy': group['supportPolicy'],
                'conditionalEmpiricalGateBypassed': False})
        else:
            output_ids = [output['outputItemID'] for output in group['outputs']]
            if len(output_ids) != 3 or len(set(output_ids)) != 3:
                raise ValueError('Reviewed per-input herb group must retain three distinct pigment identities')
            provenance = dict(evidence[0], kind='ARCHIVED_PER_INPUT_TOTALS', sourceRows=evidence)
            unknown = {'status': 'unknown', 'confidence': 0, 'inferenceBlocked': True}
            record = {key: deepcopy(group[key]) for key in ('recordID', 'method', 'profession', 'expansionID',
                      'inputItemID', 'inputCount', 'baselineProfileConfidence')}
            record.update(studyID='published:' + group['sourceStudyKey'], sourceKey='itemdb',
                source='Reviewed published milling reference; per input, actual casts unknown', sourceURL=group['sourceURL'],
                sourceKind='reviewed-published-per-input-reference', samples=0, sampleSizeKnown=False, provisional=True,
                supersedesResearch=False, fieldSpecificEvidence=True, fixedReference=True,
                quantityBasis='per-input', operationUnverified=True, reviewedPublishedPrior=provenance, sourceEvidence=evidence,
                referenceContextID='reviewed-published-prior:' + group['sourceStudyKey'], referenceConditions={},
                baselineProfile={'skill': 0, 'preSpecializationSkill': 0, 'effectiveSkill': 0,
                    'stats': {}, 'specializationPoints': {}, 'learnedSpecializations': {}}, baselineProfileAssumed=True,
                baselineStatus='Historical per-input reference; actual operation count, recipe, ranks and source profile unknown',
                materials=[{'id': output['outputItemID'], 'expectedQuantity': {
                    'value': output['reportedOutputTotal'] / group['inputsProcessed'], 'status': 'historical',
                    'confidence': group['sourceSupportConfidence'], 'modelConfidenceCap': 0,
                    'samples': 0, 'sampleSizeKnown': False, 'independentConfidence': True,
                    'confidenceBasis': 'Historical support capped at 20; archived support retained separately; modeled current-profile confidence is zero'},
                    'dropChance': deepcopy(unknown), 'minQuantity': deepcopy(unknown), 'maxQuantity': deepcopy(unknown)}
                    for output in group['outputs']])
            records.append(record);preserved.append(record);existing.add(record['recordID'])
            notes['+reviewed archived per-input reference group preserved without observed casts'] += 1
    return preserved
