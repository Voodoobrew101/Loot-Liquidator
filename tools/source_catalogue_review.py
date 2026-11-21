"""Check a finite, human-reviewed source catalogue against its build consumers.

This proves coverage/provenance/adaptation, not independent scientific approval.
New research outside assigned scopes is deliberately not an implicit backlog.
Source JSONL appends do not expire an unchanged, individually hashed row.
"""
from collections import Counter
from hashlib import sha256
import argparse
import json
from pathlib import Path
import re

CATALOGUE = Path('research/v3/evidence/master/backlog-catalogue-20261120')
POLICY = 'source-catalogue-completion/1'
SHA = re.compile(r'^[0-9a-fA-F]{64}$')
KINDS = {
    'MODEL': 'model', 'ADMITTED': 'model', 'ADMITTED_MODEL_PRIOR': 'model',
    'SOURCE_FACT': 'fact', 'SOURCE_CONTEXT_FACT': 'fact', 'METADATA_REFERENCE': 'fact',
    'MODEL_AND_SOURCE_FACT': 'mixed', 'MIXED_CATALOGUED': 'mixed',
    'ALREADY_REPRESENTED': 'represented',
    'REJECTED_CURRENT_NUMERICAL': 'rejected', 'REJECTED_CURRENT_NUMERICAL_USE': 'rejected',
    'REJECTED_CURRENT_USE': 'rejected',
}
ZERO_COUNTS = ('samples', 'empiricalSamples', 'compiledObservedSamplesAdded', 'observedSamplesAdded')
GENERIC_REJECTIONS = {
    'held', 'needs review', 'needs_review', 'no usable data', 'missing n', 'missing profile',
    'no supported compiled operation/identity/field after existing applicability, arithmetic and confidence policies',
}


def canonical_hash(row):
    value = {k: v for k, v in row.items() if not k.startswith('_')} if isinstance(row, dict) else row
    return sha256(json.dumps(value,
                            sort_keys=True, ensure_ascii=False, separators=(',', ':'),
                            allow_nan=False).encode()).hexdigest()


def _strings(value):
    return isinstance(value, list) and all(isinstance(x, str) and x for x in value)


def _safe_path(root, value):
    if not isinstance(value, str) or not value:
        raise ValueError('Missing relative catalogue path')
    value = value.replace('\\', '/')
    if len(value)>1 and value[1]==':':
        raise ValueError('Catalogue path must be relative: ' + value)
    path = (root / value).resolve()
    if not path.is_relative_to(root.resolve()):
        raise ValueError('Catalogue path leaves pinned snapshot: ' + value)
    return path


def _definitions(value):
    """Proposal definitions can live in main, lead, workbook or nested arrays."""
    if isinstance(value, dict):
        if 'proposalID' in value:
            yield value
        for key, child in value.items():
            if key != 'proposalID':
                yield from _definitions(child)
    elif isinstance(value, list):
        for child in value:
            yield from _definitions(child)


def _consumer_index(value, id_key):
    if value is None:
        return None, []
    values = list(value.values()) if isinstance(value, dict) else list(value)
    ids, duplicates = {}, []
    for item in values:
        identity = item.get(id_key) if isinstance(item, dict) else item
        if identity in ids:
            duplicates.append(identity)
        ids[identity] = item
    return ids, duplicates


def review_source_catalogue(snapshot, *, consumer_model_ids=None, consumer_fact_ids=None,
                            current_rows=None, catalogue_path=CATALOGUE):
    """Return a JSON-safe summary; no files or observations are mutated.

    Consumers can be ID iterables or actual record dictionaries (preferred, for
    no-new-observation assertions). current_rows can map exact locators to raw
    row dictionaries or canonical SHA256 strings. Otherwise rows are read from
    the pinned snapshot. Lead/workbook scopes use their explicit content hash.
    """
    root = Path(snapshot)
    folder = _safe_path(root, str(catalogue_path))
    manifest_path = folder / 'manifest.json'
    result = dict(policy=POLICY, active=manifest_path.exists(), complete=False,
                  scientificApproval=False, reviewBasis='Human field/cohort catalogue; automatic completeness checks only',
                  catalogueReviewedCount=0, assignedSourceCount=0, assignedScopeCount=0,
                  numericalModelCount=0, sourceFactCount=0, numericallyAdmittedSourceCount=0,
                  rejectedCurrentFieldCount=0, proposalCount=0, proposalDecisionCount=0,
                  reopenedScopes=[], errors=[], sourceFileDrift=[])
    if not manifest_path.exists():
        result['status'] = 'inactive'
        return result
    errors = result['errors']

    def error(code, **details):
        errors.append(dict(code=code, **details))

    def load(relative, *, catalogue=True):
        try:
            path = _safe_path(folder if catalogue else root, relative)
            return json.loads(path.read_text(encoding='utf-8-sig'))
        except (ValueError, OSError) as exc:
            error('INVALID_CATALOGUE_FILE', path=relative, reason=str(exc))
            return {}

    manifest = load('manifest.json')
    if not isinstance(manifest, dict):
        error('MANIFEST_NOT_OBJECT')
        result['status'] = 'incomplete'
        return result
    if manifest.get('schemaVersion') != 1:
        error('UNSUPPORTED_MANIFEST_SCHEMA')
    result['catalogueID'] = manifest.get('catalogueID')
    result['researchSnapshot'] = manifest.get('researchSnapshot')
    assigned = load(manifest.get('assignedSourcesFile', 'assigned-sources.json'))
    decisions = load(manifest.get('decisionsFile', 'final-source-decisions.json'))
    dispositions = load(manifest.get('proposalDispositionsFile', 'proposal-dispositions.json'))
    policy = load(manifest.get('admittedModelsFile', 'admitted-models.json'))
    for name, value in [('assigned', assigned), ('decisions', decisions), ('dispositions', dispositions), ('policy', policy)]:
        if not isinstance(value, dict):
            error('CATALOGUE_DOCUMENT_NOT_OBJECT', document=name)
    assigned = assigned if isinstance(assigned, dict) else {}
    decisions = decisions if isinstance(decisions, dict) else {}
    dispositions = dispositions if isinstance(dispositions, dict) else {}
    policy = policy if isinstance(policy, dict) else {}
    # Catalogue artifacts are frozen receipts. Original evidence-file drift is
    # informational here: the individual assigned row hash controls reopening.
    file_hashes = manifest.get('files', {})
    if not isinstance(file_hashes, dict):
        error('FILE_HASHES_NOT_OBJECT')
        file_hashes = {}
    source_file_hashes = manifest.get('sourceFiles', {})
    if not isinstance(source_file_hashes, dict):
        error('SOURCE_FILE_HASHES_NOT_OBJECT')
        source_file_hashes = {}
    for relative, expected in sorted({**source_file_hashes, **file_hashes}.items()):
        try:
            path = _safe_path(root, relative)
            if not SHA.fullmatch(str(expected)):
                raise ValueError('Expected file SHA256 is invalid')
            actual = sha256(path.read_bytes()).hexdigest()
            if actual != expected.lower():
                if relative in source_file_hashes or path.suffix.lower() == '.jsonl':
                    result['sourceFileDrift'].append(relative)
                else:
                    error('CATALOGUE_ARTIFACT_CHANGED', path=relative)
        except (ValueError, OSError) as exc:
            error('INVALID_RECEIPT_FILE', path=relative, reason=str(exc))

    def unique(rows, key, code):
        if not isinstance(rows, list):
            error(code + '_NOT_ARRAY')
            return {}
        out = {}
        for row in rows:
            identity = row.get(key) if isinstance(row, dict) else None
            if not isinstance(identity, str) or not identity:
                error(code + '_MISSING_ID')
            elif identity in out:
                error(code + '_DUPLICATE_ID', identity=identity)
            else:
                out[identity] = row
        return out

    assigned_sources = unique(assigned.get('sources'), 'sourceKey', 'ASSIGNED_SOURCE')
    reviewed_sources = unique(decisions.get('sources'), 'sourceKey', 'REVIEWED_SOURCE')
    result['assignedSourceCount'] = len(assigned_sources)
    for key in sorted(reviewed_sources.keys() - assigned_sources.keys()):
        error('UNASSIGNED_SOURCE_REVIEW', sourceKey=key)
    proposal_files = manifest.get('proposalFiles')
    if not _strings(proposal_files):
        error('PROPOSAL_FILES_NOT_DECLARED')
        proposal_files = []
    proposal_defs = []
    for relative in proposal_files:
        proposal_defs.extend(_definitions(load(relative)))
    proposals = unique(proposal_defs, 'proposalID', 'PROPOSAL')
    proposal_decisions = unique(dispositions.get('decisions'), 'proposalID', 'PROPOSAL_DECISION')
    models = unique(policy.get('models', []), 'recordID', 'ADMITTED_MODEL')
    facts = unique(policy.get('facts', []), 'factID', 'ADMITTED_FACT')
    consumer_models, duplicates = _consumer_index(consumer_model_ids, 'recordID')
    for identity in duplicates:
        error('DUPLICATE_CONSUMER_MODEL_ID', identity=identity)
    consumer_facts, duplicates = _consumer_index(consumer_fact_ids, 'factID')
    for identity in duplicates:
        error('DUPLICATE_CONSUMER_FACT_ID', identity=identity)
    result['proposalCount'] = len(proposals)
    result['proposalDecisionCount'] = len(proposal_decisions)
    result['numericalModelCount'] = len(models)
    result['sourceFactCount'] = len(facts)
    referenced_models, referenced_facts, scoped_proposals = set(), set(), set()
    field_proposal_uses = []
    assigned_locators = {}
    raw_cache = {}
    bad_sources = set()

    def current_hashes(scope):
        locator = scope.get('locator')
        if current_rows is not None:
            current = current_rows.get(locator or scope.get('scopeID'))
            if isinstance(current, dict) and SHA.fullmatch(str(current.get('rawSHA256'))):
                return current['rawSHA256'], current.get('effectiveSHA256')
            if current is not None:
                return (canonical_hash(current), None) if isinstance(current, (dict, list)) else (current, None)
            if locator:
                return None, None
        if not locator:
            try:
                if scope.get('sourceFile') and isinstance(scope.get('jsonPointer'), str):
                    path = _safe_path(root, scope['sourceFile'])
                    cache_key = (path, 'parsed-json')
                    if cache_key not in raw_cache:
                        raw_cache[cache_key] = json.loads(path.read_text(encoding='utf-8-sig'))
                    value = raw_cache[cache_key]
                    pointer = scope['jsonPointer']
                    if pointer and not pointer.startswith('/'):
                        return None, None
                    for key in pointer.split('/')[1:] if pointer else []:
                        key = key.replace('~1', '/').replace('~0', '~')
                        value = value[int(key)] if isinstance(value, list) else value[key]
                    return canonical_hash(value), None
                if 'rawValue' in scope:
                    return canonical_hash(scope['rawValue']), None
            except (ValueError, OSError, IndexError, KeyError, TypeError):
                pass
            return None, None
        try:
            relative, line = locator.rsplit(':', 1)
            path = _safe_path(root, relative)
            if path not in raw_cache:
                raw_cache[path] = path.read_text(encoding='utf-8-sig').splitlines()
            line = int(line)
            if line < 1:
                return None, None
            return canonical_hash(json.loads(raw_cache[path][line - 1])), None
        except (ValueError, OSError, IndexError, TypeError):
            return None, None

    def terminal(item, scope_label, *, source_key=None):
        kind = KINDS.get(item.get('decision'))
        if not kind:
            error('NONTERMINAL_DECISION', scope=scope_label, decision=item.get('decision'))
            return False
        model_ids, fact_ids = item.get('modelIDs', []), item.get('factIDs', [])
        if not _strings(model_ids) or not _strings(fact_ids):
            error('INVALID_CONSUMER_REFERENCES', scope=scope_label)
            return False
        if len(set(model_ids)) != len(model_ids) or len(set(fact_ids)) != len(fact_ids):
            error('DUPLICATE_CONSUMER_REFERENCE', scope=scope_label)
            return False
        valid = True
        if kind == 'rejected':
            reason, trigger = item.get('reason'), item.get('futureEvidenceTrigger')
            if not isinstance(reason, str) or len(reason.strip()) < 20 or not isinstance(trigger, str) or not trigger.strip():
                error('REJECTION_NEEDS_SCOPE_FACTS_AND_TRIGGER', scope=scope_label)
                valid = False
            if isinstance(reason, str) and reason.strip().lower().rstrip('. ') in GENERIC_REJECTIONS:
                error('GENERIC_OLD_HOLD_IS_NOT_A_REVIEW_DECISION', scope=scope_label)
                valid = False
            if model_ids or fact_ids:
                error('REJECTION_HAS_ADMITTED_REFERENCES', scope=scope_label)
                valid = False
            result['rejectedCurrentFieldCount'] += scope_label.startswith('field:')
        else:
            if not model_ids and not fact_ids:
                error('ADMISSION_HAS_NO_CONSUMER', scope=scope_label)
                valid = False
            if kind == 'model' and not model_ids or kind == 'fact' and not fact_ids:
                error('ADMISSION_REFERENCE_KIND_MISMATCH', scope=scope_label)
                valid = False
            if kind == 'represented' and not item.get('receiptPath'):
                error('REPRESENTED_SCOPE_NEEDS_RECEIPT', scope=scope_label)
                valid = False
            elif kind == 'represented':
                try:
                    if not _safe_path(root, item['receiptPath']).is_file():
                        raise ValueError('Represented receipt is missing')
                except (OSError, ValueError) as exc:
                    error('REPRESENTED_SCOPE_RECEIPT_INVALID', scope=scope_label, reason=str(exc))
                    valid = False
        for identity, registry, consumed, typ in [(i, models, consumer_models, 'MODEL') for i in model_ids] + [(i, facts, consumer_facts, 'FACT') for i in fact_ids]:
            if identity not in registry and kind != 'represented':
                error('ADMITTED_' + typ + '_MISSING_FROM_PRODUCER', scope=scope_label, identity=identity)
                valid = False
            if consumed is None or identity not in consumed:
                error('ADMITTED_' + typ + '_MISSING_FROM_CONSUMER', scope=scope_label, identity=identity)
                valid = False
            if typ == 'MODEL':
                referenced_models.add(identity)
            else:
                referenced_facts.add(identity)
        return valid

    for source_key, assignment in sorted(assigned_sources.items()):
        source_valid = True
        reviewed = reviewed_sources.get(source_key)
        if not reviewed:
            error('ASSIGNED_SOURCE_NOT_REVIEWED', sourceKey=source_key)
            bad_sources.add(source_key)
            continue
        if reviewed.get('reviewStatus') != 'REVIEWED':
            error('SOURCE_REVIEW_NOT_TERMINAL', sourceKey=source_key, status=reviewed.get('reviewStatus'))
            source_valid = False
        wanted = unique(assignment.get('scopes'), 'scopeID', 'ASSIGNED_SCOPE')
        found = unique(reviewed.get('scopes'), 'scopeID', 'REVIEWED_SCOPE')
        result['assignedScopeCount'] += len(wanted)
        if not wanted:
            error('SOURCE_HAS_NO_ASSIGNED_SCOPE', sourceKey=source_key)
            source_valid = False
        for scope_id in sorted(found.keys() - wanted.keys()):
            error('UNASSIGNED_REVIEW_SCOPE', sourceKey=source_key, scopeID=scope_id)
            source_valid = False
        for scope_id, scope in sorted(wanted.items()):
            actual = found.get(scope_id)
            expected_hash = scope.get('rawSHA256')
            locator = scope.get('locator')
            if locator:
                if locator in assigned_locators:
                    error('DUPLICATE_ASSIGNED_LOCATOR', sourceKey=source_key, locator=locator,
                          firstSourceKey=assigned_locators[locator])
                    source_valid = False
                assigned_locators[locator] = source_key
            if not SHA.fullmatch(str(expected_hash)):
                error('ASSIGNED_SCOPE_HASH_INVALID', sourceKey=source_key, scopeID=scope_id)
                source_valid = False
                continue
            if not actual:
                error('ASSIGNED_SCOPE_NOT_REVIEWED', sourceKey=source_key, scopeID=scope_id)
                source_valid = False
                continue
            current_hash, current_effective = current_hashes(scope)
            expected_effective = scope.get('effectiveSHA256')
            effective_changed = expected_effective is not None and (
                not SHA.fullmatch(str(expected_effective)) or actual.get('effectiveSHA256') != expected_effective
                or current_effective != expected_effective)
            if actual.get('rawSHA256') != expected_hash or current_hash != expected_hash or effective_changed:
                result['reopenedScopes'].append(dict(sourceKey=source_key, scopeID=scope_id,
                    locator=scope.get('locator'), expectedSHA256=expected_hash, currentSHA256=current_hash,
                    expectedEffectiveSHA256=expected_effective, currentEffectiveSHA256=current_effective))
                error('ASSIGNED_SCOPE_CHANGED', sourceKey=source_key, scopeID=scope_id)
                source_valid = False
                continue
            fields = scope.get('requiredFields')
            if not _strings(fields) or not fields or len(set(fields)) != len(fields):
                error('ASSIGNED_SCOPE_FIELDS_INVALID', sourceKey=source_key, scopeID=scope_id)
                source_valid = False
                continue
            field_decisions = unique(actual.get('fieldDecisions'), 'field', 'FIELD_DECISION')
            for missing in sorted(set(fields) - field_decisions.keys()):
                error('ASSIGNED_FIELD_NOT_REVIEWED', sourceKey=source_key, scopeID=scope_id, field=missing)
                source_valid = False
            for field, decision in sorted(field_decisions.items()):
                if not terminal(decision, 'field:' + source_key + ':' + scope_id + ':' + field, source_key=source_key):
                    source_valid = False
                refs = decision.get('proposalIDs', [])
                if not _strings(refs):
                    error('INVALID_FIELD_PROPOSAL_REFERENCES', sourceKey=source_key, scopeID=scope_id, field=field)
                    source_valid = False
                    continue
                for identity in refs:
                    scoped_proposals.add(identity)
                    if identity not in proposals or proposals[identity].get('sourceKey') != source_key:
                        error('FIELD_PROPOSAL_SOURCE_MISMATCH', sourceKey=source_key, scopeID=scope_id, proposalID=identity)
                        source_valid = False
                field_proposal_uses.append(dict(sourceKey=source_key, scopeID=scope_id, field=field,
                    kind=KINDS.get(decision.get('decision')), proposalIDs=refs,
                    modelIDs=decision.get('modelIDs', []), factIDs=decision.get('factIDs', [])))
        if source_valid:
            result['catalogueReviewedCount'] += 1
        else:
            bad_sources.add(source_key)

    for identity in sorted(proposal_decisions.keys() - proposals.keys()):
        error('UNDEFINED_PROPOSAL_DECISION', proposalID=identity)
    for identity, proposal in sorted(proposals.items()):
        if proposal.get('sourceKey') not in assigned_sources:
            error('PROPOSAL_SOURCE_NOT_ASSIGNED', proposalID=identity)
        decision = proposal_decisions.get(identity)
        if not decision:
            error('PROPOSAL_NOT_DISPOSITIONED', proposalID=identity)
        else:
            terminal(decision, 'proposal:' + identity)
        if identity not in scoped_proposals:
            error('PROPOSAL_NOT_LINKED_TO_REVIEW_SCOPE', proposalID=identity)
    accepted_scope_models, accepted_scope_facts = set(), set()
    for use in field_proposal_uses:
        if use['kind'] == 'rejected':
            continue
        permitted_models, permitted_facts = set(), set()
        for identity in use['proposalIDs']:
            decision = proposal_decisions.get(identity, {})
            permitted_models.update(decision.get('modelIDs', []))
            permitted_facts.update(decision.get('factIDs', []))
            accepted_scope_models.update((identity, value) for value in use['modelIDs'])
            accepted_scope_facts.update((identity, value) for value in use['factIDs'])
        for identity in set(use['modelIDs']) - permitted_models:
            error('FIELD_MODEL_NOT_IN_PROPOSAL_DISPOSITION', scopeID=use['scopeID'], identity=identity)
        for identity in set(use['factIDs']) - permitted_facts:
            error('FIELD_FACT_NOT_IN_PROPOSAL_DISPOSITION', scopeID=use['scopeID'], identity=identity)
    for identity, decision in proposal_decisions.items():
        for value in decision.get('modelIDs', []):
            if (identity, value) not in accepted_scope_models:
                error('PROPOSAL_MODEL_NOT_LINKED_TO_ACCEPTED_SCOPE', proposalID=identity, identity=value)
        for value in decision.get('factIDs', []):
            if (identity, value) not in accepted_scope_facts:
                error('PROPOSAL_FACT_NOT_LINKED_TO_ACCEPTED_SCOPE', proposalID=identity, identity=value)
    # Every producer record is a concrete destination of a reviewed proposal;
    # orphaned records do not count as catalogue completion.
    def observation_claims(record, identity, prefix, path=''):
        if not isinstance(record, dict):
            if isinstance(record, list):
                for index, child in enumerate(record):
                    observation_claims(child, identity, prefix, path + '/' + str(index))
            return
        provenance = {'sourceRows', 'sourceEvidence', 'sourceFacts', 'reportedObservationCounts',
                      'sourceReportedCounters', 'rawRow', 'originalEvidenceRow',
                      'sourceProfile', 'baselineProfile', 'referenceConditions'}
        for key, value in record.items():
            if key in provenance:
                continue
            location = path + '/' + key
            if key in ZERO_COUNTS and (type(value) not in (int, float) or value != 0):
                error(prefix + '_INVENTS_OBSERVATIONS', identity=identity, field=location)
            elif key == 'sampleSizeKnown' and value is True:
                error(prefix + '_PRIOR_CLAIMS_KNOWN_SAMPLE_SIZE', identity=identity, field=location)
            elif key in {'histogram', 'quantityCounts', 'personalHistogram'} and value:
                error(prefix + '_PRIOR_HAS_TARGET_COUNTS', identity=identity, field=location)
            elif key == 'status' and 'value' in record and value in {'verified', 'measured', 'observed'}:
                error(prefix + '_PRIOR_CLAIMS_MEASUREMENT', identity=identity, field=location)
            elif isinstance(value, (dict, list)):
                observation_claims(value, identity, prefix, location)

    for registry, referenced, typ in ((models, referenced_models, 'MODEL'), (facts, referenced_facts, 'FACT')):
        for identity, record in sorted(registry.items()):
            if identity not in referenced:
                error('ORPHAN_ADMITTED_' + typ, identity=identity)
            for key in ZERO_COUNTS:
                if key in record and (type(record[key]) not in (int, float) or record[key] != 0):
                    error('NEW_OBSERVATIONS_IN_REVIEWED_PRIOR', identity=identity, field=key)
            if record.get('sampleSizeKnown') is True:
                error('REVIEWED_PRIOR_CLAIMS_KNOWN_SAMPLE_SIZE', identity=identity)
            observation_claims(record, identity, 'PRODUCER')
            for ref in record.get('proposalIDs', []):
                if ref not in proposals:
                    error('PRODUCER_PROPOSAL_NOT_DEFINED', identity=identity, proposalID=ref)
    for registry, typ in ((consumer_models, 'MODEL'), (consumer_facts, 'FACT')):
        for identity, record in (registry or {}).items():
            if identity not in (models if typ == 'MODEL' else facts) or not isinstance(record, dict):
                continue
            for key in ZERO_COUNTS:
                if key in record and (type(record[key]) not in (int, float) or record[key] != 0):
                    error('CONSUMER_INVENTS_OBSERVATIONS', identity=identity, field=key)
            if record.get('sampleSizeKnown') is True:
                error('CONSUMER_PRIOR_CLAIMS_KNOWN_SAMPLE_SIZE', identity=identity)
            proof = record.get('reviewedPublishedPrior', {})
            if proof.get('observedSamplesAdded', 0) != 0:
                error('CONSUMER_INVENTS_OBSERVATIONS', identity=identity, field='reviewedPublishedPrior.observedSamplesAdded')
            observation_claims(record, identity, 'CONSUMER')
    numerical_sources = set()
    for identity, decision in proposal_decisions.items():
        if KINDS.get(decision.get('decision')) in ('model', 'mixed', 'represented') and decision.get('modelIDs'):
            source_key = proposals.get(identity, {}).get('sourceKey')
            if source_key:
                numerical_sources.add(source_key)
    result['numericallyAdmittedSourceCount'] = len(numerical_sources)
    result['errorCounts'] = dict(sorted(Counter(e['code'] for e in errors).items()))
    result['reopenedScopeCount'] = len(result['reopenedScopes'])
    result['complete'] = not errors and result['catalogueReviewedCount'] == len(assigned_sources) and bool(assigned_sources)
    result['status'] = 'complete' if result['complete'] else 'incomplete'
    return result


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--snapshot', type=Path, default=Path('database/research/v3-snapshot'))
    parser.add_argument('--catalogue-path', type=Path, default=CATALOGUE)
    parser.add_argument('--consumer-receipt', type=Path)
    parser.add_argument('--output', type=Path)
    parser.add_argument('--check', action='store_true', help='Exit nonzero if an active catalogue is incomplete')
    args = parser.parse_args(argv)
    receipt = json.loads(args.consumer_receipt.read_text(encoding='utf-8-sig')) if args.consumer_receipt else {}
    summary = review_source_catalogue(args.snapshot, catalogue_path=args.catalogue_path,
        consumer_model_ids=receipt.get('models', receipt.get('modelIDs')),
        consumer_fact_ids=receipt.get('facts', receipt.get('factIDs')), current_rows=receipt.get('currentRows'))
    text = json.dumps(summary, ensure_ascii=False, sort_keys=True, indent=2) + '\n'
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text, encoding='utf-8')
    else:
        print(text, end='')
    return 1 if args.check and summary['active'] and not summary['complete'] else 0


if __name__ == '__main__':
    raise SystemExit(main())
