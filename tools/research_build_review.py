"""Deterministic build review using the existing evidence/counting policy.

This is automatic identity, arithmetic and applicability review, not an invented
independent scientific approval. Raw rows, reported denominators and lineage
remain in the pinned snapshot. Eligible copies still share one cohort in the
authoritative baseline generator; review row counts are never sample counts.
"""
from collections import Counter, defaultdict
from hashlib import sha256
import json
from pathlib import Path
from research_methods import processing_reasons, operation_scope, GENERIC_METHODS

POLICY = 'automatic-build-study-review/1'
IDENTITIES = ('inputItemID', 'outputItemID', 'recipeID')


def identity_reasons(row):
    reasons = []
    for key in IDENTITIES:
        value = row.get(key)
        if value is not None and not (type(value) is int and 0 < value <= 2**53 - 1):
            reasons.append(key + ' must be a positive exact integer identity')
    return reasons


def automatic_admission(rows):
    """Reject malformed explicit identities; unknown identities remain resolvable."""
    admitted, notes = [], Counter()
    for row in rows:
        reasons = identity_reasons(row) + processing_reasons(row)
        if reasons:
            for reason in reasons:
                notes['Automatic admission: ' + reason] += 1
        else:
            admitted.append(row)
    return admitted, notes


def canonical(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(',', ':'), allow_nan=False)


def raw_rows(snapshot):
    rows, files = [], {}
    for path in sorted((snapshot / 'research/v3/evidence').rglob('*.jsonl')):
        relative = path.relative_to(snapshot).as_posix()
        files[relative] = sha256(path.read_bytes()).hexdigest()
        for line_number, line in enumerate(path.read_text(encoding='utf-8-sig').splitlines(), 1):
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except ValueError:
                row = None
            rows.append((relative, line_number, row))
    return rows, files


def scope_keys(module, row, names, families):
    identity = module.key_of(row, names)
    if not identity:
        return []
    method, item, output = identity
    if item.startswith('gear:'):
        import research_v3_to_baselines as v3
        item = v3.gear_key(item)
    elif item.startswith('family:'):
        return []
    else:
        try:
            item = int(item)
        except (ValueError, TypeError):
            return []
        if item <= 0:
            return []
    if not item:
        return []
    outputs = [output] if type(output) is int else families.get(str(output).removeprefix('family:').strip().lower(), [])
    return [(method, item, value, operation_scope(row)) if method in GENERIC_METHODS else (method, item, value)
            for value in outputs if type(value) is int and value > 0]


def build_review(snapshot, evidence_folder=Path('research/evidence/v3')):
    import evidence_check
    import research_v3_evidence as evidence
    import research_v3_to_baselines as v3

    snapshot = Path(snapshot)
    source = json.loads((snapshot / 'SNAPSHOT.json').read_text())
    raw, source_hashes = raw_rows(snapshot)
    module = v3.load_calculator(snapshot)
    effective = v3.resolve_ranked_outputs(v3.preserve_reference_range(module.load()))
    effective, _ = automatic_admission(effective)
    effective, _ = v3.retail_admission(effective)
    effective_by_id = defaultdict(list)
    for row in effective:
        effective_by_id[(row.get('_file'), row.get('id'))].append(row)
    names = module.name_maps(effective)
    families = v3.load_families()
    for name, ids in families.items():
        if len(ids) == 1:
            names.setdefault(name, ids[0])
    records, notes, total, counted, unplaced = v3.build(snapshot)
    reviewed_priors = {}
    prior_scopes = set()
    for record in records:
        prior = record.get('reviewedPublishedPrior')
        if prior:
            for source_prior in prior.get('sourceRows', [prior]):
                reviewed_priors[(source_prior['sourceFile'], source_prior['sourceRecordID'])] = source_prior
            prior_scopes.update((record['method'], str(record['inputItemID']), material['id']) for material in record['materials'])
    source_conditions = module.load_conditions(effective)
    built_fields = defaultdict(dict)
    for record in records:
        item = record.get('inputItemID', record.get('gearKey'))
        for material in record['materials']:
            fields = [field for field in evidence.FIELDS if material[field].get('value') is not None]
            key = (record['method'], item, material['id'])
            if record.get('sourceOperationScope'):
                key += (canonical(record['sourceOperationScope']),)
            built_fields[key][record['inputCount']] = fields
    counted_rows = [row for row in effective if v3.is_counted(row, module)]
    vectors, _, pooled = module.study_vectors(counted_rows)
    copies = module.misplaced_copies(counted_rows, names, vectors, pooled)
    reviews, study_identities = [], set()
    for file, line, raw_row in raw:
        entry = {'locator': f'{file}:{line}', 'sourceFile': file, 'line': line}
        if not isinstance(raw_row, dict):
            entry.update(disposition='HELD_INVALID_ROW', reasons=['Evidence line is not a JSON object'])
            reviews.append(entry)
            continue
        entry['rawSHA256'] = sha256(canonical(raw_row).encode()).hexdigest()
        entry['recordID'] = raw_row.get('id')
        entry['studyKey'] = raw_row.get('cohortKey') or raw_row.get('studyKey')
        entry['method'] = raw_row.get('method')
        entry['sourceURL'] = raw_row.get('originalSource') or (raw_row.get('source') or {}).get('url')
        study_identities.add(canonical([file, entry['studyKey'] or entry['recordID'] or line]))
        reasons = identity_reasons(raw_row)
        method_reasons = processing_reasons(raw_row)
        candidates = effective_by_id.get((file, raw_row.get('id')), [])
        if reasons:
            entry.update(disposition='HELD_INVALID_IDENTITY', reasons=reasons)
        elif method_reasons:
            entry.update(disposition='PRESERVED_UNRESOLVED_OPERATION_SCOPE', reasons=method_reasons)
        elif not candidates:
            # A source remains reviewable even when a correction, replacement
            # or reviewed Retail applicability rule removes its numeric use.
            entry.update(disposition='PRESERVED_CORRECTED_OR_HELD',
                         reasons=['Excluded or superseded by existing corrections, replacement or applicability policy'])
        else:
            row = candidates[0]
            entry['effectiveSHA256'] = sha256(canonical({k: v for k, v in row.items() if not k.startswith('_')}).encode()).hexdigest()
            identity = module.key_of(row, names)
            prior = reviewed_priors.get((file, row.get('id')))
            if prior and entry['rawSHA256'] == prior['rawSHA256']:
                entry.update(disposition='ADMITTED_AS_REVIEWED_PUBLISHED_PRIOR', supportedFields=['expectedQuantity'],
                             observedSamplesAdded=0, modeledSourceProfileConfidence=0,
                             reasons=['Exact reviewed source mean; unknown source profile uses a zero-confidence modeling prior, with no empirical conditional-gate bypass'])
            elif (identity in prior_scopes and module.condition_for(source_conditions, *identity) is not None
                  and module.unlock_state(row) is not True):
                entry.update(disposition='PRESERVED_UNRESOLVED_CONDITIONAL_SCOPE',
                             reasons=['The reviewed published-prior exception does not admit other conditional source cohorts'])
            elif not module.is_study_row(row):
                entry.update(disposition='PRESERVED_METADATA', reasons=['Separate metadata/token/restriction adapter; no processing cast samples'])
            elif not v3.is_counted(row, module):
                entry.update(disposition='PRESERVED_REFERENCE', reasons=['Reference or existing addon copy; not additional independent observed casts'])
            elif id(row) in copies:
                entry.update(disposition='MERGED_SOURCE_COPY', reasons=['Existing cohort/pooled-source deduplication'])
            else:
                operations = {}
                for key in scope_keys(module, row, names, families):
                    operations.update(built_fields.get(key, {}))
                stated = evidence.batch_for(row, row.get('method'), str(row.get('inputItemID')))
                if row.get('inputsPerCast') is not None:
                    operations = {batch: fields for batch, fields in operations.items() if batch == stated}
                fields = set()
                for batch, available in operations.items():
                    support = evidence.row_support(module, row, batch, 1, Counter())
                    fields.update(set(support) & set(available))
                if fields:
                    entry.update(disposition='ADMITTED_TO_BASELINE_PIPELINE', supportedFields=sorted(fields),
                                 reasons=['Automatically eligible; existing cohort deduplication and field confidence determine contribution'])
                else:
                    entry.update(disposition='PRESERVED_UNRESOLVED_SCOPE_OR_FIELDS',
                                 reasons=['No supported compiled operation/identity/field after existing applicability, arithmetic and confidence policies'])
        reviews.append(entry)
    legacy = evidence_check.check_folder(evidence_folder)
    local_reviews = []
    for entry in legacy['usable']:
        local_reviews.append({'recordID': entry['id'], 'kind': entry['kind'],
                              'disposition': 'ADMITTED_TO_EXISTING_CHECKER_PIPELINE',
                              'source': entry['record'].get('source'), 'lineage': entry['record'].get('lineage')})
    for entry in legacy['setAside']:
        local_reviews.append(dict(entry, disposition='HELD_BY_EXISTING_CHECKER'))
    dispositions = Counter(entry['disposition'] for entry in reviews + local_reviews)
    return {'schemaVersion': 1, 'policy': POLICY, 'reviewType': 'AUTOMATIC_BUILD_REVIEW',
            'independentScientificApproval': False, 'sourceSnapshot': source,
            'sourceFileSHA256': source_hashes, 'reviewedRows': len(reviews) + len(local_reviews),
            'reviewedStudyIdentities': len(study_identities),
            'countsMeaning': 'Review rows and study identities are not observed operations; all source sample arithmetic remains in existing baseline generators',
            'dispositions': dict(sorted(dispositions.items())),
            'baselineRecords': len(records), 'baselineMaterials': sum(len(row['materials']) for row in records),
            'generatorInputRows': total, 'generatorCandidateRows': counted, 'unplacedRows': unplaced,
            'generatorNotes': dict(sorted(notes.items())),
            'rows': reviews, 'localEvidenceRows': sorted(local_reviews, key=lambda entry: entry['recordID'])}


def write_review(snapshot, output=Path('database/research/build-study-review.json'), evidence_folder=Path('research/evidence/v3'), check=False):
    from evidence_to_baselines import lua
    report = build_review(snapshot, evidence_folder)
    text = json.dumps(report, sort_keys=True, ensure_ascii=False, indent=2, allow_nan=False) + '\n'
    output = Path(output)
    summary = {key: report[key] for key in ('schemaVersion', 'policy', 'reviewType', 'independentScientificApproval',
                                          'reviewedRows', 'reviewedStudyIdentities', 'dispositions',
                                          'baselineRecords', 'baselineMaterials')}
    summary.update(sourceRevision=report['sourceSnapshot']['commit'], reviewSHA256=sha256(text.encode()).hexdigest())
    compact = '-- Generated automatic build review; source evidence remains immutable.\nreturn ' + lua(summary) + '\n'
    if check:
        if not output.with_suffix('.lua').exists() or output.with_suffix('.lua').read_text(encoding='utf-8') != compact:
            raise ValueError('Compact study review is stale; run python3 tools/research_build_review.py')
        if output.exists() and output.read_text(encoding='utf-8') != text:
            raise ValueError('Full study review is stale; run python3 tools/research_build_review.py')
    else:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(text, encoding='utf-8', newline='\n')
        output.with_suffix('.lua').write_text(compact, encoding='utf-8', newline='\n')
    return summary


def main(argv=None):
    import argparse
    import research_v3_to_baselines as v3
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--snapshot', type=Path, default=v3.DEFAULT_SNAPSHOT)
    parser.add_argument('--evidence-folder', type=Path, default=Path('research/evidence/v3'))
    parser.add_argument('--output', type=Path, default=Path('database/research/build-study-review.json'))
    parser.add_argument('--check', action='store_true', help='Verify compact summary and any existing full report without writing')
    args = parser.parse_args(argv)
    try:
        summary = write_review(args.snapshot, args.output, args.evidence_folder, args.check)
    except ValueError as error:
        parser.exit(1, str(error) + '\n')
    print(f"STUDY REVIEW: {summary['reviewedRows']} rows classified; {summary['baselineRecords']} baseline records; "
          f"research {summary['sourceRevision'][:12]}")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
