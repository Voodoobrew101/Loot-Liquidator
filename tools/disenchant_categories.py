#!/usr/bin/env python3
"""Project reviewed disenchant observations onto their default gear categories.

This is a scope adapter for the existing evidence compiler, not a second rate
calculator. Exact input IDs remain source observations. The native compiler
deduplicates study lineages and independently combines reported hit counts and
unit totals. Missing outputs never become zero observations, and several rows
from one study never multiply that study's completed-operation denominator.

Catalog rarity/class mappings are provisional when the historic item variant
was not reported. That uncertainty is recorded; it does not withhold the
category. Explicitly different character conditions form separate contexts.
"""
import argparse
import copy
import hashlib
import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import evidence_check
import evidence_to_baselines

SOURCE = Path('research/mechanics/midnight-enchanting-yields-2026-11-06.json')
MAPPINGS = Path('database/research/midnight-disenchant-categories.json')
OUTPUT = Path('database/disenchant-category-baselines.lua')


def whole(value, minimum=0):
    return isinstance(value, int) and not isinstance(value, bool) and value >= minimum


def condition_context(cohort):
    """Keep reported character scenarios apart without inventing numeric ranks."""
    conditions = {key: cohort[key] for key in
                  ('skill', 'minimumSkill', 'specialization', 'professionEquipment', 'stats', 'patch', 'referenceConditions')
                  if cohort.get(key) is not None}
    conditions = {key: value for key, value in conditions.items() if value != {}}
    if not conditions:
        return 'unknown-character', conditions
    label = 'max-specialization' if 'maxed' in str(cohort.get('specialization', '')).lower() else 'reported-conditions'
    digest = hashlib.sha256(json.dumps(conditions, sort_keys=True).encode()).hexdigest()[:12]
    return label + ':' + digest, conditions


def explicit_mapping(cohort, item=None):
    """New studies with complete scope do not need an item-ID allowlist."""
    expansion, rarity, class_id = (cohort.get(key) for key in ('expansionID', 'inputRarity', 'inputClassID'))
    if any(value is None for value in (expansion, rarity, class_id)):
        return None
    if not (whole(expansion) and whole(rarity) and class_id in (2, 4)):
        raise ValueError('Invalid explicit study category')
    return {'inputItemID': item, 'expansionID': expansion, 'inputRarity': rarity,
            'inputClassID': class_id, 'gearKey': f'gear:{expansion}:{rarity}:' + ('weapon' if class_id == 2 else 'armor'),
            'classificationBasis': 'Expansion, input rarity and item class explicitly supplied by the study.',
            'provenanceURLs': [], 'studyConditionVerified': True, 'provisional': False}


def native_records(review, mapping_document, native_report=None):
    """Translate counted cohorts into checked, category-scoped native evidence."""
    if mapping_document.get('schemaVersion') != 1:
        raise ValueError('Unsupported disenchant category mapping schema')
    mappings = {}
    for mapping in mapping_document['mappings']:
        item = mapping['inputItemID']
        if item in mappings:
            raise ValueError(f'Duplicate category mapping for {item}')
        expansion, rarity, class_id = (mapping[key] for key in ('expansionID', 'inputRarity', 'inputClassID'))
        if not (whole(item, 1) and whole(expansion) and whole(rarity) and class_id in (2, 4)):
            raise ValueError(f'Invalid category mapping for {item}')
        kind = 'weapon' if class_id == 2 else 'armor'
        if mapping['gearKey'] != f'gear:{expansion}:{rarity}:{kind}':
            raise ValueError(f'Inconsistent category key for {item}')
        if mapping.get('itemSpecificException'):
            raise ValueError(f'Item-specific exception for {item} requires a separate reviewed exception adapter')
        mappings[item] = mapping
    sources = {source['id']: source for source in review['sources']}
    entries, metadata, held = [], {}, []
    for index, cohort in enumerate(review['cohorts']):
        if cohort.get('method') != 'Disenchant':
            continue
        study = cohort['studyKey']
        item = cohort.get('inputItemID')
        mapping = explicit_mapping(cohort, item) or mappings.get(item)
        if item is None and mapping is None:
            held.append((study, 'No reported armor/weapon category or counted input scope'))
            continue
        if mapping is None:
            raise ValueError(f'Counted item {item} has no reviewed category mapping')
        casts = cohort.get('completedCastsReported')
        if not whole(casts, 1):
            raise ValueError(f'{study}: positive completed-operation count required')
        if cohort.get('inputsPerCast') != 1 or cohort.get('expansionID') != mapping['expansionID']:
            raise ValueError(f'{study}: input or expansion contradicts category mapping')
        source = sources[cohort['sourceID']]
        if not source.get('url', '').startswith('https://'):
            raise ValueError(f'{study}: HTTPS source required')
        context, conditions = condition_context(cohort)
        context_id = f'de-category:{mapping["gearKey"]}:{context}'
        outputs = []
        for original in cohort['outputs']:
            output = {'item': original['outputItemID']}
            hits = original.get('hitCasts')
            if hits is not None:
                if not whole(hits) or hits > casts:
                    raise ValueError(f'{study}: invalid hit count')
                output['castsWithDrop'] = hits
            reported = original.get('totalUnitsReported')
            reconstructed = original.get('totalUnitsReconstructed')
            if reported is not None and reconstructed is not None and reported != reconstructed:
                raise ValueError(f'{study}: contradictory total units')
            units = reported if reported is not None else reconstructed
            if units is not None:
                if not whole(units):
                    raise ValueError(f'{study}: whole-number total units required')
                output['totalQuantity'] = units
            for original_key, native_key in (('positiveMinObserved', 'min'), ('positiveMaxObserved', 'max')):
                if original.get(original_key) is not None:
                    output[native_key] = original[original_key]
            if source.get('sourceType') == 'PRIMARY_FIRSTHAND_TOTALS' and units is not None:
                # Same editorial source-support cap as the native exact study.
                output['fieldConfidence'] = {'expectedQuantity': 75}
            outputs.append(output)
        record = {
            'method': 'Disenchant', 'input': mapping['gearKey'], 'inputPerCast': 1,
            'casts': casts, 'outputs': outputs, 'source': source['url'], 'lineage': study,
            'observedDate': cohort.get('dataDate'), 'patch': cohort.get('patch'), 'stale': False,
            'recipeID': 13262, 'expansionID': mapping['expansionID'],
            'inputRarity': mapping['inputRarity'], 'inputClassID': mapping['inputClassID'],
            'referenceContextID': context_id, 'referenceConditions': {},
        }
        for key in ('skill', 'minimumSkill', 'stats'):
            if cohort.get(key) is not None:
                record[key] = cohort[key]
        if cohort.get('skill') is not None:
            record['referenceConditions']['skill'] = cohort['skill']
        reasons = evidence_check.check_evidence(record)
        if reasons:
            raise ValueError(f'{study}: invalid native category evidence: ' + '; '.join(reasons))
        entry_id = f'disenchant-category:{study}:{index}'
        entries.append({'kind': 'evidence', 'id': entry_id, 'record': record})
        metadata[entry_id] = {'cohort': cohort, 'mapping': mapping, 'context': context,
                              'conditions': conditions, 'source': source}
    # Native evidence with an explicit category joins automatically. Copies of
    # reviewed studies retain the same context so the native lineage dedupe
    # counts them once, rather than treating the adapter as a new observation.
    known_lineages = {entry['record']['lineage']: metadata[entry['id']] for entry in entries}
    known_records = {entry['record']['lineage']: entry['record'] for entry in entries}
    native_mismatches = {entry['record']['recordId'] for entry in (native_report or {}).get('usable', [])
                         if entry['kind'] == 'check' and entry['record'].get('result') == 'mismatch'}
    for entry in (native_report or {}).get('usable', []):
        if entry['kind'] != 'evidence' or entry['record'].get('method') != 'Disenchant':
            continue
        original = entry['record']
        if entry['id'] in native_mismatches:
            held.append((original['lineage'], 'Native evidence Checker found a mismatch with its source'))
            continue
        item = original.get('input') if isinstance(original.get('input'), int) else None
        mapping = explicit_mapping(original, item)
        if mapping is None:
            continue
        study = original['lineage']
        record = copy.deepcopy(original)
        record['input'] = mapping['gearKey']
        if study in known_lineages:
            info = copy.deepcopy(known_lineages[study])
            record['referenceContextID'] = known_records[study]['referenceContextID']
            record['referenceConditions'] = known_records[study]['referenceConditions']
        else:
            context, conditions = condition_context(original)
            # A named source context with no numeric ranks is still distinct.
            if original.get('referenceContextID') and context == 'unknown-character':
                conditions = {'sourceContextID': original['referenceContextID']}
                context = 'reported-conditions:' + hashlib.sha256(json.dumps(conditions, sort_keys=True).encode()).hexdigest()[:12]
            record['referenceContextID'] = f'de-category:{mapping["gearKey"]}:{context}'
            record.setdefault('referenceConditions', {})
            info = {'cohort': {'studyKey': study, 'inputItemID': item,
                               'outputs': [{'recordID': entry['id']}]},
                    'mapping': mapping, 'context': context, 'conditions': conditions,
                    'source': {'url': original['source']}}
        entry_id = 'disenchant-category:native:' + entry['id']
        entries.append({'kind': 'evidence', 'id': entry_id, 'record': record})
        metadata[entry_id] = info
    return entries, metadata, held


def build(review, mapping_document, native_report=None):
    entries, metadata, held = native_records(review, mapping_document, native_report)
    records, notes = evidence_to_baselines.build({'usable': entries})
    by_entry = {entry['id']: entry['record'] for entry in entries}
    for record in records:
        members = [metadata[key] for key in record['evidenceRecordIDs']]
        contexts = {member['context'] for member in members}
        if len(contexts) != 1:
            raise ValueError('Native compiler combined incompatible category contexts')
        context = contexts.pop()
        context_label = context.split(':', 1)[0]
        record['recordID'] = record['recordID'].replace('evidence:', 'evidence:category:', 1)
        record['studyID'] = record['recordID']
        record.update({
            'isDisenchantCategory': True,
            'categoryContext': context_label,
            'categoryReferenceOnly': context_label != 'unknown-character',
            'categorySourceStudyIDs': sorted({member['cohort']['studyKey'] for member in members}),
            'memberInputItemIDs': sorted({member['cohort']['inputItemID'] for member in members
                                         if member['cohort'].get('inputItemID') is not None}),
            'categoryObservedCasts': sum(by_entry[key]['casts'] or 0 for key in record['evidenceRecordIDs']),
            'categoryScopeProvisional': any(member['mapping'].get('provisional') or
                                            not member['mapping'].get('studyConditionVerified')
                                            for member in members),
            'categoryMappingSources': sorted({url for member in members
                                              for url in member['mapping'].get('provenanceURLs', [])}),
            'categoryScopeBasis': sorted({member['mapping']['classificationBasis'] for member in members}),
            'categorySourceRecordIDs': sorted({out['recordID'] for member in members
                                               for out in member['cohort']['outputs'] if out.get('recordID')}),
            'categoryGeneralizationBasis': 'Default expansion, rarity and armor/weapon category; input IDs are source provenance, not an eligibility restriction.',
        })
        if context_label != 'unknown-character':
            record['categoryConditionDescription'] = json.dumps(members[0]['conditions'], sort_keys=True)
        if any(member['cohort'].get('independenceLimit') for member in members):
            record['categoryIndependenceNotes'] = sorted({member['cohort']['independenceLimit'] for member in members
                                                         if member['cohort'].get('independenceLimit')})
    notes['held'] = held
    return records, notes


def render(records):
    return ('-- Generated by tools/disenchant_categories.py; never hand-edit.\n'
            '-- Category scopes use the native evidence compiler; exact observations remain preserved.\n'
            'return {schemaVersion=1,processing={\n' +
            ''.join(evidence_to_baselines.lua(record) + ',\n' for record in records) + '}}\n')


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=SOURCE)
    parser.add_argument('--mappings', type=Path, default=MAPPINGS)
    parser.add_argument('--output', type=Path, default=OUTPUT)
    parser.add_argument('--evidence-folder', type=Path, default=evidence_check.DEFAULT_FOLDER)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args(argv)
    records, notes = build(json.loads(args.source.read_text()), json.loads(args.mappings.read_text()),
                           evidence_check.check_folder(args.evidence_folder))
    generated = render(records)
    if args.check:
        if not args.output.exists() or args.output.read_text() != generated:
            parser.exit(1, f'{args.output} is out of date: run python3 tools/disenchant_categories.py\n')
    else:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(generated)
    primary = sum(not record['categoryReferenceOnly'] for record in records)
    print(f'DISENCHANT CATEGORIES: {primary} category baselines, {len(records) - primary} separate condition reference(s); '
          f'{notes["used"]} studies, {notes["duplicates"]} duplicate lineage(s), {len(notes["held"])} unclassified reference(s)')
    return 0


if __name__ == '__main__':
    sys.exit(main())
