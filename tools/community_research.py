#!/usr/bin/env python3
"""Stage public cast exports, record an explicit review, and compile counted cohorts.

No downloaded code is executed. Raw pages are immutable offline evidence. The
existing validator and evidence compiler own eligibility/counts/confidence.
Running without arguments regenerates the reviewed community database only.
"""
from __future__ import annotations

import argparse
import collections
import copy
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import tempfile

import evidence_check
import evidence_to_baselines
from validate_craft_export import compile_baselines, observation_signature, unpack_transfer, vector, validate as validate_raw

ROOT = Path(__file__).resolve().parents[1]
SUBMISSIONS = Path('research/community/submissions')
CAPTURES = Path('research/integration/measured-captures')
OUTPUT = Path('database/community-capture-baselines.lua')
SCHEMA = 'loot-liquidator.community-submission/1'
REVIEW_SCHEMA = 'loot-liquidator.community-review/1'
POLICY = 'community-complete-measured-cohort/1'
MAX_BYTES = 16 * 1024 * 1024
KEY = re.compile(r'^issue-[1-9][0-9]*-[0-9a-f]{16}$')
PROFILE_FIELDS = ('profession', 'baseSkill', 'bonusSkill', 'effectiveSkill', 'preSpecializationSkill',
                  'maxSkill', 'skillLineID', 'specialization', 'specializationKnown',
                  'specializationPoints', 'learnedSpecializations', 'buffsKnown', 'buffs', 'buffStacks',
                  'specializationEncoding', 'specializationSignatureEncoding',
                  'operationStats', 'stats', 'fieldStatus', 'inputExpansionID',
                  'skillBasis', 'operationBaseSkill', 'operationBonusSkill',
                  'operationStatsIncludeSpecialization', 'skillIncludesSpecialization', 'statCalibration',
                  'applyConcentration', 'allocationKnown', 'allocationVerified',
                  'operationInputItemID', 'operationInputQualityRank', 'craftingQuality',
                  'baseDifficulty', 'bonusDifficulty', 'lowerSkillThreshold', 'upperSkillTreshold')


def require(value, reason):
    if not value:
        raise ValueError(reason)


def validate(pages):
    """Use the existing validator, reporting malformed untrusted shapes clearly."""
    try:
        return validate_raw(pages)
    except (AttributeError, IndexError) as exc:
        raise ValueError('Malformed export field shape') from exc


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True, allow_nan=False)


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def hashed(value):
    return digest(canonical(value).encode('utf-8'))


def no_duplicate_keys(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, 'Duplicate JSON object key')
        result[key] = value
    return result


def read_json(path):
    path = Path(path)
    require(path.stat().st_size <= MAX_BYTES, 'Source file exceeds 16 MiB limit')
    raw = path.read_bytes()
    require(len(raw) <= MAX_BYTES, 'Source file exceeds 16 MiB limit')
    value = json.loads(raw.decode('utf-8-sig'), object_pairs_hook=no_duplicate_keys)
    return raw, value


def within(root, relative):
    root = Path(root).resolve()
    result = (root / relative).resolve()
    require(result.is_relative_to(root), 'Path escapes project root')
    return result


def submission_folder(root, key):
    require(isinstance(key, str) and KEY.fullmatch(key), 'Invalid submission key')
    return within(root, SUBMISSIONS / key)


def load_pages(paths):
    sources = []
    for path in paths:
        raw, wire = read_json(path)
        require(isinstance(wire, dict), 'Export must be a JSON object')
        page = unpack_transfer(wire)
        sources.append((raw, page))
    require(sum(len(raw) for raw, _ in sources) <= 4 * MAX_BYTES, 'Combined export exceeds 64 MiB limit')
    # Validate the whole snapshot before writing anything or filtering records.
    validate([page for _, page in sources])
    return sorted(sources, key=lambda source: source[1]['page'])


def existing_operations(root):
    """Index all archived owners' captures, including the reviewed compact source.

    Historical context conflicts remain visible. They must never let a new
    submission masquerade as an independent cast just because filenames changed.
    """
    found = collections.defaultdict(set)
    folder = within(root, CAPTURES)
    for capture in sorted(folder.glob('*')):
        sets = []
        for pattern in ('cast-page-*.json', 'export-page-*.json'):
            paths = sorted(capture.glob(pattern))
            if paths:
                sets.append(paths)
        for name in ('source-transfer.json', 'compact-transfer.json', 'compact-export.json'):
            if (capture / name).is_file():
                sets.append([capture / name])
        for paths in sets:
            sources = load_pages(paths)
            records, contexts, _ = validate([p for _, p in sources])
            for record in records:
                found[record['operationID']].add(hashed(observation_signature(record, contexts[record['contextID']])))
    return found


def cohort_id(baseline):
    return 'cohort-' + hashed({'study': baseline['studyID'], 'context': baseline['referenceContext'],
                               'recipe': baseline['recipeSpellID'], 'operations': sorted(baseline['sourceRecordIDs'])})[:24]


def payload(pages):
    records, contexts, studies = validate(pages)
    staged = compile_baselines(pages)
    for baseline in staged['baselines']:
        baseline['communityCohortID'] = cohort_id(baseline)
    signatures = {r['operationID']: hashed(observation_signature(r, contexts[r['contextID']])) for r in records}
    return records, contexts, studies, staged, signatures


def accepted_operations(root, exclude=None):
    found = {}
    folder = within(root, SUBMISSIONS)
    for path in sorted(folder.glob('issue-*')):
        if path.name == exclude or not (path / 'review.json').is_file():
            continue
        manifest, _, _, staged, signatures = load_submission(root, path.name)
        review = read_json(path / 'review.json')[1]
        approved = check_review(manifest, staged, review)
        for baseline in staged['baselines']:
            if baseline['communityCohortID'] not in approved:
                continue
            for op in baseline['sourceRecordIDs']:
                require(op not in found, 'Approved community cohorts overlap: ' + op)
                found[op] = {signatures[op]}
    return found


def stage(root, issue, source_url, paths):
    require(type(issue) is int and issue > 0, 'A positive GitHub issue number is required')
    expected = f'https://github.com/Voodoobrew101/Loot-Liquidator/issues/{issue}'
    require(source_url == expected or source_url.startswith(expected + '#issuecomment-'),
            'Source URL must identify this repository issue or its comment')
    sources = load_pages(paths)
    pages = [page for _, page in sources]
    records, contexts, studies, staged, signatures = payload(pages)
    page_meta = [{'file': f'source-page-{n:03}.json', 'sha256': digest(raw), 'bytes': len(raw)}
                 for n, (raw, _) in enumerate(sources, 1)]
    source_hash = hashed([p['sha256'] for p in page_meta])
    key = f'issue-{issue}-{source_hash[:16]}'
    folder = submission_folder(root, key)
    known = existing_operations(root)
    for op, sig in accepted_operations(root, exclude=key).items():
        known.setdefault(op, set()).update(sig)
    duplicates = sorted(op for op, sig in signatures.items() if known.get(op) == {sig})
    conflicts = sorted(op for op, sig in signatures.items() if op in known and known[op] != {sig})
    manifest = {'schemaVersion': SCHEMA, 'key': key, 'issue': issue, 'sourceURL': source_url,
                'intakePolicy': POLICY,
                'submissionSHA256': source_hash, 'pages': page_meta,
                'retainedRecords': len(records), 'operationSignatures': signatures,
                'duplicateOperationIDs': duplicates, 'conflictingOperationIDs': conflicts,
                'newOperationIDs': sorted(set(signatures) - set(known)),
                'stagedSHA256': hashed(staged), 'automaticMechanicsPromotion': False}
    if folder.exists():
        original, _, _, original_staged, original_signatures = load_submission(root, key)
        require(original['submissionSHA256'] == source_hash and original_staged == staged
                and original_signatures == signatures, 'Immutable staged submission changed')
        return original
    folder.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='.community-stage-', dir=folder.parent) as temporary:
        temporary = Path(temporary)
        for metadata, (raw, _) in zip(page_meta, sources):
            (temporary / metadata['file']).write_bytes(raw)
        write_json(temporary / 'staged-baselines.json', staged)
        write_json(temporary / 'submission.json', manifest)
        os.replace(temporary, folder)
    return manifest


def load_submission(root, key):
    folder = submission_folder(root, key)
    manifest = read_json(folder / 'submission.json')[1]
    require(isinstance(manifest, dict), 'Submission manifest must be an object')
    require(manifest.get('schemaVersion') == SCHEMA and manifest.get('key') == key,
            'Unsupported or mismatched submission manifest')
    require(manifest.get('intakePolicy') == POLICY and manifest.get('automaticMechanicsPromotion') is False,
            'Unsupported community intake policy')
    issue = manifest.get('issue')
    require(type(issue) is int and issue > 0, 'Invalid submission issue identity')
    expected_url = f'https://github.com/Voodoobrew101/Loot-Liquidator/issues/{issue}'
    require(manifest.get('sourceURL') == expected_url
            or isinstance(manifest.get('sourceURL'), str) and manifest['sourceURL'].startswith(expected_url + '#issuecomment-'),
            'Submission source URL changed to an unsupported location')
    sources = []
    for n, metadata in enumerate(manifest['pages'], 1):
        require(metadata['file'] == f'source-page-{n:03}.json', 'Unexpected submission page path')
        raw, wire = read_json(folder / metadata['file'])
        require(digest(raw) == metadata['sha256'] and len(raw) == metadata['bytes'], 'Submission source checksum changed')
        sources.append(unpack_transfer(wire))
    require(hashed([p['sha256'] for p in manifest['pages']]) == manifest['submissionSHA256'],
            'Submission page inventory changed')
    require(key == f'issue-{issue}-{manifest["submissionSHA256"][:16]}', 'Submission key checksum changed')
    records, contexts, studies, staged, signatures = payload(sources)
    require(signatures == manifest['operationSignatures'] and hashed(staged) == manifest['stagedSHA256']
            and staged == read_json(folder / 'staged-baselines.json')[1], 'Staged cohort facts changed')
    return manifest, records, contexts, staged, signatures


def check_review(manifest, staged, review):
    require(isinstance(review, dict), 'Review must be a JSON object')
    require(review.get('schemaVersion') == REVIEW_SCHEMA and review.get('submissionSHA256') == manifest['submissionSHA256'],
            'Review must bind the exact submission checksum')
    require(all(isinstance(review.get(k), str) and review[k].strip() for k in ('reviewer', 'rationale')),
            'A named reviewer and review rationale are required')
    require(review.get('gameMode') == 'RETAIL' and review.get('scientificReviewComplete') is True,
            'An explicit Retail scientific review is required')
    require(isinstance(review.get('cohorts'), list) and review['cohorts'], 'Review must select whole qualifying cohorts')
    by_id = {b['communityCohortID']: b for b in staged['baselines']}
    approved = {}
    for choice in review['cohorts']:
        require(isinstance(choice, dict), 'Reviewed cohort must be an object')
        identity = choice.get('cohortID')
        require(identity in by_id and identity not in approved, 'Unknown or duplicate reviewed cohort')
        outputs = choice.get('outputs')
        expected = {str(m['outputItemID']) for m in by_id[identity]['materials']}
        require(isinstance(outputs, dict) and set(outputs) == expected,
                'Review must classify every observed output as material, non-economic or hold')
        for decision in outputs.values():
            require(isinstance(decision, dict) and decision.get('decision') in ('material', 'non-economic', 'hold')
                    and isinstance(decision.get('reason'), str) and decision['reason'].strip(),
                    'Every output decision needs an explicit material/non-economic/hold reason')
            require(decision['decision'] != 'hold',
                    'Unresolved output holds the whole cohort; unknown economic output cannot be discarded')
            if decision['decision'] == 'non-economic':
                require(decision.get('verifiedNonEconomic') is True,
                        'Non-economic output needs explicit verifiedNonEconomic confirmation and source-backed reason')
        require(any(v['decision'] == 'material' for v in outputs.values()), 'Cohort has no reviewed economic material')
        approved[identity] = choice
    return approved


def approve(root, key, review_path):
    manifest, records, _, staged, signatures = load_submission(root, key)
    review = read_json(review_path)[1]
    approved = check_review(manifest, staged, review)
    known = existing_operations(root)
    for op, sigs in accepted_operations(root, exclude=key).items():
        known.setdefault(op, set()).update(sigs)
    by_op = {r['operationID']: r for r in records}
    for baseline in staged['baselines']:
        if baseline['communityCohortID'] not in approved:
            continue
        for op in baseline['sourceRecordIDs']:
            require(op not in known, 'Reviewed cohort overlaps archived observations; request a clean batch: ' + op)
            require(by_op[op].get('gameMode') == 'RETAIL', 'Source cast is not explicitly Retail')
    # Exercise the real counted adapter before persisting approval.
    native_records(manifest, records, staged, review)
    path = submission_folder(root, key) / 'review.json'
    if path.exists():
        require(read_json(path)[1] == review, 'Existing review is immutable; stage a corrected submission')
    else:
        write_json(path, review)
    return review


def source_profile(context):
    profile = {key: copy.deepcopy(context[key]) for key in PROFILE_FIELDS if key in context}
    profile.update(simulated=False, profileKind='measured')
    # Unknown remains absent. Never silently normalize unknown skill to zero.
    if context.get('baseSkill') is not None:
        profile['skill'] = context['baseSkill']
    if context.get('inputExpansionID') is not None:
        profile['expansionID'] = context['inputExpansionID']
    return profile


def native_records(manifest, records, staged, review):
    approved = check_review(manifest, staged, review)
    by_op = {r['operationID']: r for r in records}
    result = []
    for baseline in staged['baselines']:
        identity = baseline['communityCohortID']
        if identity not in approved:
            continue
        inputs = baseline['nominalInputs']
        require(len(inputs) == 1, 'Multi-input crafts require a separate reviewed valuation adapter')
        item, context = inputs[0], baseline['referenceContext']
        require('expansionID' in item, 'Captured input expansion is required')
        require(isinstance(context.get('fieldStatus'), dict), 'Measured field status map is required')
        require(all(type(context.get(k)) in (int, float) and context[k] >= 0
                    and context.get('fieldStatus', {}).get(k) == 'measured'
                    for k in ('baseSkill', 'bonusSkill', 'effectiveSkill')),
                'Known measured source skill is required for automatic numerical admission')
        require(context.get('specializationKnown') is True
                and isinstance(context.get('specializationPoints'), dict)
                and context.get('fieldStatus', {}).get('specialization') == 'measured'
                and context.get('buffsKnown') is True and isinstance(context.get('buffs'), dict)
                and isinstance(context.get('buffStacks'), dict),
                'Known source specialization and buffs are required for numerical admission')
        require(context.get('inputExpansionID') == item['expansionID'], 'Source context expansion disagrees with input')
        if baseline['method'] != 'Disenchant':
            require(isinstance(context.get('operationStats'), list)
                    and context.get('fieldStatus', {}).get('operationStats') == 'measured',
                    'Known measured operation stats are required for non-disenchant numerical admission')
        operations = [by_op[op] for op in baseline['sourceRecordIDs']]
        require(all(r.get('gameMode') == 'RETAIL' for r in operations), 'Source cast is not explicitly Retail')
        require(all(vector(r['inputs'], allow_zero=True) == vector(r.get('nominalInputs', r['inputs']))
                    and not any(receipt.get('resourcesReturned') for receipt in r.get('resultMetadata', []))
                    for r in operations),
                'Input refunds require a reviewed net-consumption valuation adapter; keep this cohort staged')
        versions = {r.get('clientVersion') for r in operations}
        require(len(versions) == 1 and next(iter(versions)) is not None, 'Exact source client version is required')
        source = {'method': baseline['method'], 'profession': context.get('profession'),
                  'input': item['itemID'], 'inputPerCast': item['quantity'],
                  'casts': baseline['operations'], 'outputs': [], 'source': manifest['sourceURL'],
                  'lineage': baseline['studyID'], 'observedDate': None,
                  'patch': next(iter(versions)), 'stale': False, 'recipeID': baseline['recipeSpellID'],
                  'expansionID': item['expansionID'], 'referenceContextID': 'community:' + manifest['key'] + ':' + identity,
                  'referenceConditions': {}, 'baselineProfile': source_profile(context)}
        for original, target in (('qualityRank', 'inputQualityRank'), ('rarity', 'inputRarity'), ('classID', 'inputClassID')):
            if item.get(original) is not None:
                source[target] = item[original]
        if context.get('baseSkill') is not None:
            source['skill'] = context['baseSkill']
        for material in baseline['materials']:
            if approved[identity]['outputs'][str(material['outputItemID'])]['decision'] != 'material':
                continue
            histogram = material['quantityHistogramIncludingZero']
            positive = [int(q) for q in histogram if int(q) > 0]
            require(positive, 'No material-positive observations')
            source['outputs'].append({'item': material['outputItemID'],
                'castsWithDrop': sum(n for q, n in histogram.items() if int(q) > 0),
                'totalQuantity': sum(int(q) * n for q, n in histogram.items()),
                'min': min(positive), 'max': max(positive)})
        reasons = evidence_check.check_evidence(source)
        require(not reasons, 'Invalid reviewed community evidence: ' + '; '.join(reasons))
        compiled, notes = evidence_to_baselines.build({'usable': [{'kind': 'evidence', 'id': identity, 'record': source}]})
        require(len(compiled) == 1 and notes['used'] == 1 and not notes['skipped'], 'Community cohort failed native compilation')
        row = compiled[0]
        row.update(recordID='evidence:community:' + manifest['key'] + ':' + identity,
                   studyID='community:' + baseline['studyID'] + ':' + identity,
                   sourceKind='reviewed-community-player-capture', sourceSHA256=manifest['submissionSHA256'],
                   communityIntakePolicy=POLICY,
                   sourceReviewSHA256=hashed(review), sourceRecordIDs=sorted(baseline['sourceRecordIDs']),
                   observedOperations=baseline['operations'], patchBuild=str(baseline['patchBuild']),
                   targetBuild=baseline['patchBuild'], clientVersion=source['patch'], fixedReference=True,
                   communityMeasuredProfile=source_profile(context),
                   communityNonEconomicOutputItemIDs=sorted(int(item_id) for item_id, decision in approved[identity]['outputs'].items()
                       if decision['decision'] == 'non-economic'),
                   baselineStatus='Reviewed complete community cohort at its recorded source profile; observed ranges are not guarantees')
        if baseline['method'] == 'Disenchant':
            require(type(item.get('itemLevel')) is int and item['itemLevel'] >= 1,
                    'Captured disenchant item level is required for exact-variant scope')
            row['categoryItemLevelMin'] = row['categoryItemLevelMax'] = item['itemLevel']
        for material in row['materials']:
            original = next(m for m in baseline['materials'] if m['outputItemID'] == material['id'])
            material['quantityCounts'] = original['quantityHistogramIncludingZero']
            material['boundsBasis'] = 'observed-positive-range-not-guaranteed'
        result.append(row)
    return result


def compile_reviewed(root):
    known = existing_operations(root)
    rows = []
    for folder in sorted(within(root, SUBMISSIONS).glob('issue-*')):
        if not (folder / 'review.json').is_file():
            continue
        manifest, records, contexts, staged, signatures = load_submission(root, folder.name)
        review = read_json(folder / 'review.json')[1]
        compiled = native_records(manifest, records, staged, review)
        for row in compiled:
            for op in row['sourceRecordIDs']:
                require(op not in known, 'Approved cohort overlaps other capture evidence: ' + op)
                known[op] = {signatures[op]}
        rows.extend(compiled)
    return {'schemaVersion': 1, 'processing': sorted(rows, key=lambda row: row['recordID'])}


def write_json(path, value):
    Path(path).write_text(json.dumps(value, sort_keys=True, indent=2, ensure_ascii=True, allow_nan=False) + '\n', encoding='utf-8', newline='\n')


def render(value):
    return '-- Generated by tools/community_research.py; reviewed whole cohorts, native evidence counts.\nreturn ' + evidence_to_baselines.lua(value) + '\n'


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT)
    parser.add_argument('--check', action='store_true')
    commands = parser.add_subparsers(dest='command')
    stage_parser = commands.add_parser('stage')
    stage_parser.add_argument('--issue', type=int, required=True)
    stage_parser.add_argument('--source-url', required=True)
    stage_parser.add_argument('pages', type=Path, nargs='+')
    approve_parser = commands.add_parser('approve')
    approve_parser.add_argument('key')
    approve_parser.add_argument('--review', type=Path, required=True)
    args = parser.parse_args(argv)
    try:
        if args.command == 'stage':
            value = stage(args.root, args.issue, args.source_url, args.pages)
            print(json.dumps({'key': value['key'], 'newOperations': len(value['newOperationIDs']),
                              'duplicates': len(value['duplicateOperationIDs']), 'conflicts': len(value['conflictingOperationIDs'])}))
        elif args.command == 'approve':
            approve(args.root, args.key, args.review)
            print('COMMUNITY REVIEW: exact submission approved; rerun the official build pipeline')
        else:
            value = compile_reviewed(args.root)
            text = render(value)
            path = within(args.root, OUTPUT)
            if args.check:
                require(path.read_text(encoding='utf-8') == text, 'Community capture database is out of date')
            else:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(text, encoding='utf-8', newline='\n')
            print(f"COMMUNITY CAPTURES: {len(value['processing'])} reviewed numerical cohorts")
    except (ValueError, KeyError, TypeError, OSError, RecursionError) as exc:
        parser.exit(1, f'Community capture rejected: {exc}\n')


if __name__ == '__main__':
    main()
