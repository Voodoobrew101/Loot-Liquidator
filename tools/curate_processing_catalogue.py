#!/usr/bin/env python3
"""Translate the frozen processing review into scoped, sample-free model specs.

No source row, source count or shared producer is edited.  Admissions cite exact
physical/effective rows.  The final owner integrates this lane's standalone
models/facts and dispositions with the other backlog lanes.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from copy import deepcopy
import csv
from hashlib import sha256
import json
import math
from pathlib import Path
import re
import sys

sys.dont_write_bytecode = True
import profession_profile_rules as native_rules
import research_v3_to_baselines as bridge
import reviewed_source_catalogue as catalogue_consumer
from research_v3_evidence import build_field_support, identified_cohort
from research_build_review import automatic_admission
from reviewed_source_catalogue import CATALOGUE, model_record, source_rows
from processing_source_fact_translation import (
    normalize_processing_facts, normalize_processing_dispositions,
    verify_processing_fact_consumer,
)

ROOT = Path(__file__).resolve().parents[1]
PINS = {
    'processing-review.json': 'b2c12242d0267905e87048676eb4268730087c05f14b895232257533ab207f80',
    'processing-proposals.json': '6d6358c127e3bd67c3fd8a10b08e5053edfa9063a1fccf715467974587eaf674',
    'processing-notes.md': '0b72cc869e9234279e3ba1704028284fb7c3cc463d4557759b06418a7f1f6736',
}
PROFESSION = {'Mill': 'Inscription', 'Prospect': 'Jewelcrafting', 'Crush': 'Jewelcrafting',
              'Recycle': 'Engineering', 'Smelt': 'Mining', 'Unravel': 'Tailoring',
              'Thaumaturgy': 'Alchemy'}
CURRENT_RECIPES = {('Mill', 9): 382981, ('Mill', 10): 444181, ('Mill', 11): 1269575,
                   ('Prospect', 9): 374627, ('Prospect', 10): 434018, ('Prospect', 11): 1231127}
# Source-specific improved transcriptions, not a whole-page exclusion.
PREFERRED_COHORT = {'p013-004': 'p013-001', 'p156-000': 'p156-004', 'p156-001': 'p156-005'}
# These two purported base returns are a comment reference with Resourcefulness
# explicitly excluded, not an independent compatible cohort to blend with the
# firsthand 1.15/1.35 averages in the same thread. Preserve their quantities on
# the informational source path rather than altering those active means.
BASE_RETURN_REFERENCES = {
    'war-within-20261101-2108': (210796, 1.1),
    'war-within-20261101-2109': (210797, 1.3),
}
TERMINAL = {'ADMITTED_MODEL_PRIOR', 'ALREADY_REPRESENTED', 'METADATA_REFERENCE',
            'REJECTED_CURRENT_NUMERICAL_USE'}


def load(path):
    return json.loads(Path(path).read_text(encoding='utf-8'))


def digest(value):
    return sha256(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode()).hexdigest()


def json_write(path, value):
    Path(path).write_text(json.dumps(value, ensure_ascii=False, indent=1, allow_nan=False) + '\n', encoding='utf-8', newline='\n')


class Curator:
    def __init__(self, research):
        self.research = Path(research).resolve()
        self.directory = self.research / CATALOGUE
        for name, pin in PINS.items():
            if sha256((self.directory / name).read_bytes()).hexdigest() != pin:
                raise ValueError('Frozen processing review changed: ' + name)
        self.review = load(self.directory / 'processing-review.json')
        self.proposals = load(self.directory / 'processing-proposals.json')
        self.index = load(self.directory / 'processing-evidence-index.json')
        self.row = {}; self.entry = {}; self.group = {}; self.source = {}; self.row_pointer = {}
        for si, source in enumerate(self.review['sources']):
            for gi, group in enumerate(source['cohorts']):
                self.group[group['cohortID']] = group
                for ri, row in enumerate(group['rowDecisions']):
                    self.row[row['locator']] = row
                    self.source[row['locator']] = source
                    self.row_pointer[row['locator']] = f'/sources/{si}/cohorts/{gi}/rowDecisions/{ri}'
        for source in self.index:
            for group in source['groups']:
                for entry in group['rows']:
                    self.entry[entry['locator']] = entry
        if len(self.source) != 2845 or len(self.review['sources']) != 224:
            raise ValueError('Incomplete processing partition')
        self.native_source = native_rules.load_source()
        self.items = {int(k): v for k, v in self.native_source['recipeRouting']['items'].items()}
        self.families = {int(k): v for k, v in self.native_source['recipeRouting']['qualityFamilies'].items()}
        self.recipes, _ = native_rules.build_recipes(self.native_source, self.items, self.families)
        self.catalogs = load(ROOT / 'database/wago-professions-70783.json')['catalogs']
        self.names = {}
        sparse = ROOT.parent / '.validation/de-formula-data/ItemSparse-70961.csv'
        with sparse.open(encoding='utf-8-sig') as stream:
            for item in csv.DictReader(stream):
                self.names[int(item['ID'])] = {'name': item['Display_lang'], 'expansionID': int(item['ExpansionID'])}
        self.model = []; self.fact = []; self.disposition = []; self.integration = []; self.field_decisions = []; self.extra_definitions = []; self.exclusions = []
        self.fact_ids = set(); self.disposition_ids = set(); self.ref_cache = {}
        self.calculator = bridge.load_calculator(self.research)
        self.loaded = self.calculator.load()
        self.effective = {(r['_file'], r['id']): r for r in self.loaded}
        # Compare against the actual pre-catalogue producer, never this lane's
        # own previous generated admissions or masks. Isolated process only.
        admission = catalogue_consumer.preserve_reviewed_backlog
        replacements = catalogue_consumer.apply_reviewed_field_replacements
        try:
            catalogue_consumer.preserve_reviewed_backlog = lambda *args, **kwargs: []
            catalogue_consumer.apply_reviewed_field_replacements = lambda rows, *args, **kwargs: rows
            self.existing, _, *_ = bridge.build(self.research)
        finally:
            catalogue_consumer.preserve_reviewed_backlog = admission
            catalogue_consumer.apply_reviewed_field_replacements = replacements
        self.existing_fields = defaultdict(list)
        for record in self.existing:
            for material in record['materials']:
                if 'value' in material.get('expectedQuantity', {}):
                    self.existing_fields[(record['method'], record.get('inputItemID'), material['id'])].append((record, material))
        admitted, _ = automatic_admission(bridge.resolve_ranked_outputs(self.loaded))
        admitted, _ = bridge.retail_admission(admitted)
        counted = [r for r in admitted if bridge.is_counted(r, self.calculator)]
        self.counted = {(r['_file'], r['id']): r for r in counted}
        names = self.calculator.name_maps(admitted)
        self.names_map = names
        self.vectors, _, _ = self.calculator.study_vectors(counted)
        estimates, _, _ = build_field_support(self.calculator, counted, names)
        self.ordinary_supports = { (e['method'], e['input'], e['outputItemID'], e['inputsPerCast']): e['fieldSupport']
                                   for e in estimates if not e.get('conditional') }
        self.represented = {}
        for estimate in estimates:
            field = estimate['fieldSupport'].get('expectedQuantity')
            if field and not estimate.get('conditional'):
                self.represented[(estimate['method'], estimate['input'], estimate['outputItemID'], estimate['inputsPerCast'])] = field
        self.alias_members = defaultdict(set)
        self.proposal_by_id = {p['proposalID']: p for p in self.proposals['proposals']}
        for alias in self.proposals['canonicalAliasReceipts']:
            for member in alias['members']:
                self.alias_members[member].update(alias['members'])

    def refs(self, locators):
        result = []
        for locator in sorted(set(locators)):
            row = self.row[locator]
            result.append({'sourceFile': row['currentPhysicalSourcePath'], 'sourceRecordID': row['recordID'],
                           'line': row['currentPhysicalLine'], 'rawSHA256': row['currentPhysicalRowSHA256'],
                           'effectiveSHA256': row['effectiveSHA256']})
        return result

    def decision(self, proposal, status, reason, *, models=(), facts=(), **extra):
        pid = proposal['proposalID']
        if pid in self.disposition_ids:
            raise ValueError('Duplicated disposition ' + pid)
        self.disposition_ids.add(pid)
        if 'futureEvidenceTrigger' not in extra:
            extra['futureEvidenceTrigger'] = ('Changed exact source row/profile/identity/epoch reopens only this field.' if status in {'ADMITTED_MODEL_PRIOR', 'ALREADY_REPRESENTED'} else proposal.get('recheckTrigger') or 'Source-specific complete input denominator, native output identity, actual matching source allocation or independent non-overlapping quantity evidence for this exact cohort.')
        if status == 'REJECTED_CURRENT_NUMERICAL_USE' and facts:
            extra['pricedRejection'] = {'reason': reason, 'futureEvidenceTrigger': extra['futureEvidenceTrigger']}
            status = 'METADATA_REFERENCE'
        source_key = proposal.get('sourceKey')
        if not source_key and proposal.get('sourceLocator') in self.source:
            source_key = self.source[proposal['sourceLocator']]['sourceKey']
        if not source_key:
            gid = proposal.get('cohortID') or pid.split(':')[0]
            source_key = self.source[self.group[gid]['rowDecisions'][0]['locator']]['sourceKey']
        self.disposition.append({'proposalID': pid, 'status': status,
                                 'sourceKey': source_key,
                                 'decision': {'ADMITTED_MODEL_PRIOR': 'MODEL', 'ALREADY_REPRESENTED': 'ALREADY_REPRESENTED',
                                              'METADATA_REFERENCE': 'SOURCE_FACT', 'REJECTED_CURRENT_NUMERICAL_USE': 'REJECTED_CURRENT_NUMERICAL'}[status],
                                 'reason': reason, 'receiptPath': str(CATALOGUE / 'processing-review.json'),
                                 'modelIDs': sorted(set(models)), 'factIDs': sorted(set(facts)), **extra})

    def fact_for(self, proposal, metric, unit, *, value=None, locators=None):
        pid = proposal['proposalID']; fid = 'reviewed-backlog:processing:fact:' + digest([pid, metric])[:24]
        if fid in self.fact_ids:
            return fid
        if locators is None:
            locators = [proposal['sourceLocator']] if proposal.get('sourceLocator') else []
        if not locators and proposal.get('cohortID') in self.group:
            locators = [r['locator'] for r in self.group[proposal['cohortID']]['rowDecisions']]
        if not locators and proposal.get('reportedRankUnits'):
            locators = [r['sourceLocator'] for r in proposal['reportedRankUnits']]
        if not locators and proposal.get('outcomes'):
            locators = [r['sourceLocator'] for r in proposal['outcomes']]
        if not locators:
            raise ValueError('Context fact lacks original source rows: ' + pid)
        refs = self.refs(locators)
        proof, why = source_rows(self.research, refs, self.effective, self.ref_cache)
        if why:
            raise ValueError(why + ': ' + pid)
        fact = {'factID': fid, 'metric': metric, 'unit': unit, 'confidence0to100': 0,
                'sourceSupportConfidence': min(20, proposal.get('sourceSupportMaximum', 5)),
                'sourceRows': refs, 'sourceKey': self.source[locators[0]]['sourceKey'],
                'method': self.entry[locators[0]]['effective'].get('method'),
                'details': deepcopy(proposal), 'observedSamplesAdded': 0}
        original = self.entry[locators[0]]['effective']
        source_row = self.row[locators[0]]
        for side in ('input', 'output'):
            ids = proposal.get(side + 'Identity', source_row[side + 'Identity']).get('itemIDs', [])
            if ids:
                fact[side + 'ItemIDs'] = deepcopy(ids)
                if len(ids) == 1:
                    fact[side + 'ItemID'] = ids[0]
        fact['profession'] = PROFESSION.get(fact['method'])
        fact['sourceStudyKey'] = original.get('studyKey')
        fact['sourceConditions'] = {key: deepcopy(original.get(key)) for key in ('skill', 'specialization', 'stats', 'patch', 'dataDate')}
        eras = {self.names[i]['expansionID'] for i in fact.get('inputItemIDs', []) if i in self.names}
        if len(eras) == 1:
            fact['expansionID'] = next(iter(eras))
        if value is not None:
            fact['value'] = value
        self.fact.append(fact); self.fact_ids.add(fid)
        return fid

    def profile(self, proposal, method, era):
        reported = deepcopy(proposal.get('sourceProfile') or {})
        raw = reported.get('raw', {}); text = str(raw.get('specialization') or '')
        context = {'skill': 0, 'preSpecializationSkill': 0, 'stats': deepcopy(reported.get('stats', {})),
                   'specializationPoints': {}, 'learnedSpecializations': {},
                   'specializationPointsEncoding': 'normalized-points-v1'}
        assumptions = ['Unknown source allocations/stats remain unknown; neutral unspecified quantities are an explicit confidence-zero reference coordinate, never measured zero-investment observations.']
        known = False
        catalog = self.catalogs.get(PROFESSION.get(method, '') + ':' + str(era), {}).get('nodes', [])
        # Exact source-named maxed nodes only. No blanket all-profession max.
        full = bool(re.search(r'full|max(?:ed|imum)?|complete', text, re.I))
        for node in catalog:
            names = [node['name']]
            if node['id'] == 28672 and era == 9:
                names.append('Toolset Mastery')  # Unique native Jeweler's Toolset Mastery suffix.
            for name in names:
                match = re.search(r'(?<!\w)' + re.escape(name) + r'(?!\w)', text, re.I)
                if not match:
                    continue
                clause = next((part for part in re.split(r';|\n', text) if re.search(re.escape(name), part, re.I)), text)
                before = re.search(r'(\d+)\s*(?:/\s*\d+\s*)?(?:points?\s*(?:in\s*)?)?' + re.escape(name), clause, re.I)
                after = re.search(re.escape(name) + r'\s*[:=]?\s*(\d+)\s*(?:/\s*\d+|points?)', clause, re.I)
                points = int((before or after)[1]) if before or after else node['maxRank'] if full and re.search(r'full|max(?:ed|imum)?|complete', clause, re.I) and not re.search(r'not max|rest.*(?:into|in)', clause, re.I) else None
                if points is None:
                    continue
                if not 0 <= points <= node['maxRank']:
                    context.setdefault('sourceAllocationMismatch', []).append({'nodeID': node['id'], 'sourceName': name,
                        'sourcePoints': points, 'currentNativeMaximum': node['maxRank']})
                    continue
                context['specializationPoints'][str(node['id'])] = points
                context['learnedSpecializations'][str(node['id'])] = points > 0
                known = True
                break
        if context['specializationPoints']:
            assumptions.append('Only source-explicit full named nodes are joined to pinned native caps; all unnamed nodes remain unreported.')
        if reported.get('effectiveSkill') is not None:
            context.update(effectiveSkill=reported['effectiveSkill'], skill=reported['effectiveSkill'],
                           skillIncludesSpecialization=True)
            context.pop('preSpecializationSkill', None); known = True
        elif reported.get('preSpecializationSkill') is not None:
            context.update(skill=reported['preSpecializationSkill'], preSpecializationSkill=reported['preSpecializationSkill'],
                           skillIncludesSpecialization=False)
            known = True
        elif reported.get('reportedSkill') is not None:
            context.update(skill=reported['reportedSkill'], preSpecializationSkill=reported['reportedSkill'],
                           skillIncludesSpecialization=False)
            assumptions.append('Unscoped numeric source skill is modeled as pre-specialization skill; original inclusion ambiguity remains in source conditions.')
        else:
            skill = str(raw.get('skill') or '')
            profession = PROFESSION.get(method, '')
            numeric = (re.search(r'\bSkill\s*(\d+(?:\.\d+)?)\b', skill, re.I)
                       or re.search(re.escape(profession) + r'\s+(\d+(?:\.\d+)?)\b', skill, re.I)
                       or re.search(r'\b(\d+(?:\.\d+)?)\s+(?:total\s+)?' + re.escape(profession), skill, re.I)) if profession else None
            if numeric:
                value = float(numeric[1]); context.update(skill=value, preSpecializationSkill=value, skillIncludesSpecialization=False)
                assumptions.append('Explicit numeric source Skill/profession figure is retained as a pre-specialization reference assumption when its effective-operation inclusion is unresolved; it is never replaced by0.')
        if context['stats']:
            context.update(operationStatsIncludeSpecialization=True, skillFromAllocation=False)
            assumptions.append('Reported source stat percentages already include source talent ratings; skip adding the same stat grants again while retaining independent saved-return effects.')
        # Unresolved known investment cannot be quietly renamed a zero profile.
        unresolved_max = (bool(re.search(r'maxed|full.*tree|maximum|complete.*branch', text, re.I)) and not context['specializationPoints']) or bool(context.get('sourceAllocationMismatch'))
        return context, not known, assumptions, unresolved_max

    def represented_by_existing(self, proposal, input_id, output_ids, quantity):
        if len(output_ids) != 1:
            return []
        exact = self.existing_fields.get((proposal['method'], input_id, output_ids[0]), [])
        raw = self.entry[proposal['sourceLocator']]['effective']
        record_key = (raw['_file'], raw['id'])
        existing = []
        for record, material in exact:
            mean = material['expectedQuantity']['value'] / record['inputCount']
            published = record.get('reviewedPublishedPrior')
            if published and math.isclose(mean, quantity, rel_tol=1e-10, abs_tol=1e-12):
                if record.get('sourceURL') == (raw.get('source') or {}).get('url') or published.get('sourceRecordID') == raw['id']:
                    existing.append(record['recordID']); continue
            counted = self.counted.get(record_key)
            if counted is None:
                continue
            key = self.calculator.key_of(counted, self.names_map)
            if not key or key[1] != str(input_id) or key[2] != output_ids[0]:
                continue
            field = self.represented.get((*key, record['inputCount']))
            if not field:
                continue
            cohort = identified_cohort(self.calculator, counted, self.vectors)
            if cohort in field.get('_countedCohorts', ()) or (not field.get('sampleSizeKnown') and math.isclose(mean, quantity, rel_tol=1e-10, abs_tol=1e-12)):
                existing.append(record['recordID'])
        return sorted(set(existing))

    def ordinary_active_fields(self, proposal):
        """Locate actual pre-catalogue source fields, not a generic row gate."""
        raw = self.entry[proposal['sourceLocator']]['effective']
        current = self.counted.get((raw['_file'], raw['id']))
        if current is None:
            return []
        key = self.calculator.key_of(current, self.names_map)
        if not key or not str(key[1]).isdigit():
            return []
        cohort = identified_cohort(self.calculator, current, self.vectors)
        active = []
        for scope, fields in self.ordinary_supports.items():
            if scope[:3] != key:
                continue
            records = [r for r in self.existing if r['method'] == key[0] and r.get('inputItemID') == int(key[1]) and r['inputCount'] == scope[3]]
            for field, support in fields.items():
                if field not in {'expectedQuantity', 'dropChance', 'minQuantity', 'maxQuantity'}:
                    continue
                if support.get('_countedCohorts') and cohort not in support['_countedCohorts']:
                    continue
                for record in records:
                    for material in record['materials']:
                        output_matches = material['id'] == key[2] if isinstance(key[2], int) else bool(material.get('rankIDs'))
                        if output_matches and 'value' in material.get(field, {}):
                            active.append({'field': field, 'recordID': record['recordID'], 'outputItemID': material['id']})
        return active

    def exclude_nontransferable(self, proposal, fact_id, reason, trigger):
        active = self.ordinary_active_fields(proposal)
        if not active:
            return
        # Known profile mismatch makes its occurrence/bounds nontransferable as
        # well; do not let runtime inference reconstruct the rejected mean.
        self.exclusions.append({'sourceRows': self.refs([proposal['sourceLocator']]),
            'fields': ['expectedQuantity', 'dropChance', 'minQuantity', 'maxQuantity'],
            'factIDs': [fact_id], 'proposalIDs': [proposal['proposalID']],
            'reason': reason, 'futureEvidenceTrigger': trigger,
            'preCatalogueActiveFields': active,
            'inferenceBlockedFields': ['expectedQuantity'],
            'policy': 'Exact incompatible source-profile fields only; raw evidence/counts remain immutable and retained as source facts.'})

    def primary(self):
        pending = defaultdict(list)
        for proposal in self.proposals['proposals']:
            pid = proposal['proposalID']; gid = pid.split(':')[0]
            locator = proposal.get('sourceLocator')
            original = self.entry[locator]['effective'] if locator in self.entry else {}
            if original.get('id') in BASE_RETURN_REFERENCES:
                input_id, value = BASE_RETURN_REFERENCES[original['id']]
                assert original.get('sourceKind') == 'reference'
                assert original.get('studyKey') == 'reddit-1fdmzwy-base-return-comment'
                assert original.get('inputItemID') == input_id and original.get('outputItemID') == 222619
                assert original.get('averageShown') == value and original.get('averagePer') == 'input'
                assert original.get('quote') == 'without accounting for resourcefulness the base returns are 1.1 and 1.3'
                fid = self.fact_for(proposal, 'sourceProfileMeanUnitsPerInput', 'gross-input', value=value)
                fact = next(f for f in self.fact if f['factID'] == fid)
                fact.update({
                    'sourceKey': 'itemdb', 'originalSourceKey': proposal['sourceKey'],
                    'sourceURL': original['source']['url'], 'outputName': original['outputName'],
                    'sourceProfile': {'skill': original.get('skill'), 'specialization': original.get('specialization'),
                                      'stats': 'Resourcefulness excluded from the quoted base-return reference',
                                      'patch': original.get('patch'), 'dataDate': original.get('dataDate'),
                                      'published': original['source'].get('published')},
                    'referenceConditions': {'quantityBasis': 'Quoted base material units per herb; Resourcefulness excluded',
                                            'nativeBatchEquivalent': f'{value * 10:g} material units per 10 native recipe inputs; unit conversion only',
                                            'sourceRole': 'Comment reference, not another firsthand measured cohort'},
                    'sourceFacts': {'quote': original['quote'], 'notes': original['notes']},
                    'reportedObservationCounts': {'measuredCasts': None, 'sourceMaterialUnits': None,
                                                  'sourceProcessedInputs': None, 'observedSamplesAdded': 0},
                    'sourceContextOnly': True, 'targetProfileAdjusted': False,
                    'economicPolicy': 'informational-source-reference',
                })
                reason = ('The source explicitly excludes Resourcefulness from a purported base return and supplies no underlying casts, '
                          'units or matching source profile. Its quantity remains an informational reference, not an independent '
                          'compatible cohort to blend with firsthand 1.15/1.35 averages whose refund/input basis is unresolved.')
                receipt = str(CATALOGUE / 'processing-base-return-reference-addendum.md')
                self.decision(proposal, 'METADATA_REFERENCE', reason, facts=[fid], receiptPath=receipt,
                              pricedRejection={'reason': reason,
                                  'futureEvidenceTrigger': 'Primary source clarification of matching gross/net input and Resourcefulness/profile basis, plus independent original quantities if claiming another measured cohort.'})
                continue
            if gid in PREFERRED_COHORT:
                self.decision(proposal, 'ALREADY_REPRESENTED', 'Source-specific improved transcription of this same herb/ore cohort is preferred; no cross-rank/unknown-rank alias weight.', preferredCohortID=PREFERRED_COHORT[gid]); continue
            canonical = proposal.get('canonicalRepresentativeProposalID')
            if canonical and canonical != pid:
                self.decision(proposal, 'ALREADY_REPRESENTED', 'Same physical cohort and normalized field alias; canonical proposal adds this source once.', canonicalProposalID=canonical); continue
            if proposal['admissionDecision'] != 'USE_BASELINE_QUANTITY_PRIOR':
                superseded = proposal['admissionDecision'] == 'REJECT_SUPERSEDED_UNIT_TRANSCRIPTION'
                fact = self.fact_for(proposal, 'supersededUnitTranscription' if superseded else 'sourceQuantityContext',
                                     proposal['quantity']['unit'], value=None if superseded else proposal['quantity']['value'])
                self.decision(proposal, 'REJECTED_CURRENT_NUMERICAL_USE' if proposal['admissionDecision'].startswith('REJECT') else 'METADATA_REFERENCE', proposal.get('rejectionReason') or proposal['quantity']['reason'], facts=[fact]); continue
            method = proposal['method']; inputs = proposal['inputIdentity'].get('itemIDs', []); outputs = proposal['outputIdentity'].get('itemIDs', [])
            if method not in PROFESSION or not inputs or not outputs:
                fact = self.fact_for(proposal, 'unattributedSourceMean', proposal['quantity']['unit'], value=proposal['quantity']['value'])
                self.decision(proposal, 'METADATA_REFERENCE', 'Quantity retained but exact supported processing input/output identity or method is unresolved.', facts=[fact]); continue
            eras = {self.names[i]['expansionID'] for i in inputs if i in self.names}
            if len(eras) != 1:
                raise ValueError('Native input expansion unresolved ' + pid)
            era = next(iter(eras)); value = proposal['quantity']['value']
            if proposal['quantity']['unit'] != 'input':
                source = self.entry[proposal['sourceLocator']]['effective']; batch = source.get('inputsPerCast')
                if not batch:
                    fact = self.fact_for(proposal, 'sourceOperationMean', 'material units per source operation', value=value)
                    self.decision(proposal, 'METADATA_REFERENCE', 'Per-source-operation mean is valid, but normal/mass source input count is missing; cannot linearly rescale it to native per-input economics.', facts=[fact]); continue
                value /= batch
            context, assumed, assumptions, unresolved_max = self.profile(proposal, method, era)
            if proposal.get('gapOnly') and value == 0:
                positive = any(other['quantity'].get('value', 0) > 0
                               and set(inputs) & set(other['inputIdentity'].get('itemIDs', []))
                               and set(outputs) & set(other['outputIdentity'].get('itemIDs', []))
                               for other in self.proposals['proposals'])
                if positive:
                    fact = self.fact_for(proposal, 'sourceCompleteAbsence', 'reported zero material units per positive source input budget', value=0)
                    self.decision(proposal, 'METADATA_REFERENCE', 'Gap-only zero quantity prior is not activated where compatible positive quantity evidence exists; original source absence, eligibility and profile remain a scoped fact.', facts=[fact],
                                  futureEvidenceTrigger='An identified condition/profile that deterministically excludes this outcome, rather than one finite zero-output sample, or a genuinely missing positive-evidence gap.'); continue
            if unresolved_max:
                fact = self.fact_for(proposal, 'knownInvestedSourceMean', 'material units per input', value=value)
                mismatch = context.get('sourceAllocationMismatch')
                reason = ('Reported historical allocation conflicts with current native node cap: ' + json.dumps(mismatch, sort_keys=True) + '. No historical-to-current point scaling or zero-source profile is invented.' if mismatch else 'Maxed-knowledge statement does not identify actual matching branches, source effective skill, or separate base versus spec output factors. This specific source-factor inverse is unidentified; source0 would double count target bonuses.')
                trigger = ('Original source clarification of named node/point count, or pinned historical native node-cap/effect evidence establishing an explicit historical-to-current allocation transform.' if mismatch else 'Original source named point allocations/effective operation profile, or compatible independent base-profile output vector/known quantity modifier identifying this maxed-source inverse.')
                self.integration.append({'proposalID': pid, 'status': 'REJECTED_CURRENT_NUMERICAL_USE_SOURCE_FACT_RETAINED', 'reason': 'Maxed-knowledge statement does not identify actual matching branches, source effective skill, or separate base versus spec output factors. This specific source-factor inverse is unidentified; source0 would double count target bonuses.', 'sourceLocator': proposal['sourceLocator'], 'value': value, 'sourceProfile': proposal['sourceProfile'], 'factID': fact,
                                         'futureEvidenceTrigger': trigger})
                self.integration[-1]['reason'] = reason
                self.exclude_nontransferable(proposal, fact, reason, trigger)
                self.decision(proposal, 'REJECTED_CURRENT_NUMERICAL_USE', reason, facts=[fact], futureEvidenceTrigger=trigger); continue
            for input_id in inputs:
                represented = self.represented_by_existing(proposal, input_id, outputs, value)
                needs_normalization = bool(context['specializationPoints'] or context['stats'] or context.get('effectiveSkill') or context.get('preSpecializationSkill'))
                if represented and not needs_normalization:
                    # Defer disposition until all input-family members have been considered.
                    pending[('represented', pid)].append((input_id, represented)); continue
                group = (proposal.get('sourceIdentityKey') or proposal['sourceStudyKey'], input_id,
                         proposal.get('sourceQuantityBasis') == 'net-input',
                         context.get('effectiveSkill'), context.get('preSpecializationSkill'), digest(context['stats']),
                         digest(context['specializationPoints']),
                         proposal.get('modeledNominalInputDenominator') or proposal['quantity'].get('sourceDenominator'))
                pending[group].append((proposal, value, outputs, context, assumed, assumptions, represented))
        emitted = defaultdict(list)
        represented_inputs = defaultdict(list)
        for key, members in pending.items():
            if key[0] == 'represented':
                represented_inputs[key[1]].extend(members); continue
            self.emit_group(key, members, emitted)
        for proposal in self.proposals['proposals']:
            pid = proposal['proposalID']
            if pid in self.disposition_ids:
                continue
            if emitted[pid]:
                self.decision(proposal, 'ADMITTED_MODEL_PRIOR', 'Exact reviewed per-input mean, known profile inverse or explicit unknown-profile reference prior; zero active samples and no duplicate aliases.', models=emitted[pid], alreadyRepresentedInputs=represented_inputs[pid])
            elif represented_inputs[pid]:
                self.decision(proposal, 'ALREADY_REPRESENTED', 'Same source quantity is already represented by the actual producer output; no additional observation weight.', representedInputs=represented_inputs[pid],
                              compiledRecordIDs=sorted({rid for _, ids in represented_inputs[pid] for rid in ids}))
            else:
                raise ValueError('Primary proposal lost its terminal route: ' + pid)

    def emit_group(self, key, members, emitted):
        input_id = key[1]; base = members[0][0]; method = base['method']; era = self.names[input_id]['expansionID']
        context = members[0][3]; assumptions = list(members[0][5])
        material_by_id = {}; pool = []; selected = []
        for proposal, value, outputs, _, _, _, represented in members:
            if len(outputs) > 1:
                pool.append((proposal, value, outputs, represented)); continue
            item = outputs[0]
            if item in material_by_id:
                old = material_by_id[item]
                if not math.isclose(old[1], value, rel_tol=1e-9, abs_tol=1e-12):
                    fact = self.fact_for(proposal, 'conflictingSameCohortMean', 'material units per input', value=value)
                    if proposal['proposalID'] not in self.disposition_ids:
                        self.decision(proposal, 'METADATA_REFERENCE', 'Same current cohort has conflicting normalized means for one exact output; retain both without creating two independent sources.', facts=[fact], requiresIntegrationResolution=True)
                    self.integration.append({'proposalID': proposal['proposalID'], 'reason': 'Conflicting same-cohort normalized field', 'competingProposalID': old[0]['proposalID']}); continue
                selected.append(proposal); continue
            material_by_id[item] = (proposal, value, represented); selected.append(proposal)
        for proposal, value, outputs, represented in pool:
            if re.search(r'^other\b', str(proposal['outputIdentity'].get('sourceName') or ''), re.I):
                outputs = [item for item in outputs if item not in material_by_id]
                if outputs:
                    assumptions.append('Source explicitly labels this residual pool Other; exclude separately enumerated named species from its legal family instead of double-attributing their units.')
            overlap = set(outputs) & set(material_by_id)
            if overlap and math.isclose(sum(material_by_id[i][1] for i in overlap), value, rel_tol=1e-9, abs_tol=1e-12):
                if proposal['proposalID'] not in self.disposition_ids:
                    self.decision(proposal, 'ALREADY_REPRESENTED', 'Pooled/unknown-rank transcription equals already selected same-cohort exact material quantity; no second family total.', canonicalProposalID=material_by_id[next(iter(overlap))][0]['proposalID'])
                continue
            if overlap:
                fact = self.fact_for(proposal, 'overlappingPooledMean', 'material units per input', value=value)
                if proposal['proposalID'] not in self.disposition_ids:
                    self.decision(proposal, 'METADATA_REFERENCE', 'Pooled total overlaps exact-rank fields but does not reconcile to their sum; retains pool constraint instead of duplicating its units.', facts=[fact], requiresIntegrationResolution=True)
                self.integration.append({'proposalID': proposal['proposalID'], 'status': 'REJECTED_CURRENT_NUMERICAL_USE_SOURCE_FACT_RETAINED', 'reason': 'Pooled total overlaps exact material quantities with no identified residual allocation; a unique source vector cannot be formed.',
                                         'futureEvidenceTrigger': 'Original source clearly identifies pooled total versus additional residual and corresponding named material scope.'}); continue
            # Separate pooled quantities so exact quality-family anchors need not invent a pool rank split.
            self.emit_record(key, [(proposal, value, outputs, represented)], context, assumptions, False, emitted)
        if material_by_id:
            exact = [(p, value, [item], represented) for item, (p, value, represented) in material_by_id.items()]
            self.emit_record(key, exact, context, assumptions, True, emitted, alias_proposals=selected)

    def emit_record(self, key, entries, context, assumptions, exact, emitted, alias_proposals=()):
        base = entries[0][0]; method = base['method']; input_id = key[1]; era = self.names[input_id]['expansionID']
        record_id = 'evidence:reviewed-backlog:processing:' + digest([key, [(p['proposalID'], ids) for p, _, ids, _ in entries]])[:24]
        locators = [p['sourceLocator'] for p, _, _, _ in entries]
        materials = []
        for p, value, ids, represented in entries:
            support = min(20, p['quantity'].get('sourceSupportMaximum', 20))
            if len(p['inputIdentity'].get('itemIDs', [])) > 1:
                support = min(support, 5); assumptions.append('Input rank unknown: this same source mean is a zero-confidence transferable quantity prior for each verified native input-family member, not independently measured rank cohorts.')
            item = min(ids, key=lambda i: (self.items.get(i, {}).get('qualityRank') or 99, i))
            formula = p['quantity']['formula']
            if p['proposalID'].startswith('p085-009:'):
                value /= 2
                formula = '(' + formula + ')/2'
                assumptions.append('This source says at least50stacks. Its2/(50*20) ratio is an upper bound, not an observed mean; use an explicit uniform0-to-upper-bound quantity prior, midpoint half the bound, confidence0 and no finite observed input count.')
            material = {'id': item, 'expectedQuantity': {'value': value, 'sourceSupportConfidence': support,
                'modelConfidenceCap': 0, 'derivation': {'kind': 'reviewed-model-formula',
                'formula': formula, 'sourceUnit': p['quantity']['unit'], 'targetUnit': 'material units per input',
                'sourceProposalID': p['proposalID'], 'assumptions': deepcopy(p['quantity'].get('assumptions', []))}}}
            if item == 194545:
                material['economicPolicy'] = 'nontradable'
                assumptions.append('PrismaticOre194545 is the native nontradable unlock output; retain units without treating them as an ordinary auction-sale material.')
            if len(ids) > 1:
                material['rankIDs'] = sorted(ids)
                assumptions.append('This legal output pool has one total quantity, priced once at the cheapest available family member; no observed quality/species allocation is invented.')
            materials.append(material)
            locators.extend(self.proposal_by_id[a]['sourceLocator'] for a in self.alias_members[p['proposalID']])
        native_family_ids = set(); filled = []
        if exact and era >= 9 and method in {'Mill', 'Prospect'}:
            present = {m['id'] for m in materials}
            for item in list(present):
                family_id = self.items.get(item, {}).get('qualityFamilyID')
                family = self.families.get(family_id)
                if family and len(family.get('rankItemIDs', [])) > 1:
                    native_family_ids.add(family_id)
                    for sibling in family['rankItemIDs']:
                        if sibling not in present:
                            materials.append({'id': sibling, 'expectedQuantity': {'value': 0, 'sourceSupportConfidence': 5,
                                'modelConfidenceCap': 0, 'derivation': {'kind': 'reviewed-model-formula',
                                'formula': '0 modeled units for unreported sibling rank in this source-quality anchor',
                                'assumption': 'Missing rank is a model completion only, not an observed zero/drop failure. Only the reported family total is conserved.'}}})
                            present.add(sibling); filled.append(sibling)
            if native_family_ids:
                assumptions.append('Complete native quality-family vector uses explicitly modeled zero units for unreported ranks. Unknown-source reference skill0 preserves the original reported rank shares; already-highest quality is saturated, not forced to respond by assuming a high source skill.')
                assumptions.append('Processing quality endpoint at maximum modeled skill is all highest native rank; interpolation is confidence0 and conserves the source-reported family quantity.')
        profile_assumed = any(p.get('sourceProfile', {}).get('unreportedNodesRemainUnknown') for p, _, _, _ in entries)
        spec = {'recordID': record_id, 'method': method, 'profession': PROFESSION[method], 'inputCount': 1,
                'inputItemID': input_id, 'expansionID': era, 'sourceKey': base['sourceKey'],
                'sourceStudyKey': 'reviewed-processing:' + digest(key)[:24],
                'sourceURL': (self.entry[base['sourceLocator']]['effective'].get('source') or {}).get('url') or base['sourceKey'],
                'sourceTitle': 'Reviewed published processing quantities', 'baselineProfile': deepcopy(context),
                'baselineProfileAssumed': profile_assumed, 'baselineProfileConfidence': 0,
                'assumptions': sorted(set(assumptions + [a for p, _, _, _ in entries for a in p['quantity'].get('assumptions', [])])),
                'sourceRows': self.refs(locators), 'materials': materials,
                'sourceQuantityBasis': 'net-input' if key[2] else 'nominal-stock-budget' if any(p['sourceQuantityBasis'] in {'reported-input-budget', 'modeled-full-stack-input-budget'} for p, _, _, _ in entries) else 'gross-input',
                'requiresSourceNormalization': True, 'quantityBasis': 'per-input',
                'referenceConditions': {'sourceProfile': deepcopy(base.get('sourceProfile', {})),
                    'sourceQuantityBasis': base['sourceQuantityBasis'], 'sourceProposalIDs': [p['proposalID'] for p, _, _, _ in entries],
                    'modeledMissingRankZeroItemIDs': filled, 'historicalApplicabilityConfidence': 0},
                'reportedObservationCounts': {'observedSamplesAdded': 0,
                    'sourceReportedCasts': sorted(set(p['reportedSourceCasts'] for p, _, _, _ in entries if p.get('reportedSourceCasts') is not None))}}
        if CURRENT_RECIPES.get((method, era)):
            spec['recipeID'] = CURRENT_RECIPES[(method, era)]
            spec['assumptions'].append('Current operation recipe/labels are native routing, not a claim that the historical author used this exact recipe ID or operation count.')
            batch = self.recipes[spec['recipeID']].get('inputCount')
            if isinstance(batch, int) and batch > 0:
                spec['inputCount'] = batch
                spec['referenceConditions']['reportedMeanUnit'] = 'per input'
                spec['referenceConditions']['compiledQuantityUnit'] = f'per {batch} native recipe inputs'
                spec['assumptions'].append(f'Compile each per-input mean times{batch} to match the verified native input batch. This is a unit conversion, not a source operation count or sample size.')
                for material in spec['materials']:
                    field = material['expectedQuantity']; field['value'] *= batch
                    derivation = field['derivation']; derivation['formula'] = '(' + derivation['formula'] + f') * {batch}'
                    derivation['targetUnit'] = f'material units per {batch} native recipe inputs'
        prismatic = next((m for m in spec['materials'] if m['id'] == 194545), None)
        if prismatic and spec.get('recipeID') == 374627 and context['specializationPoints'].get('28609', 0) >= 25:
            spec['reviewedEffectOverrides'] = {'entry:36397:extraOutput:1': {
                'entryID': 36397, 'metric': 'extraOutput', 'mechanism': 'qualitative-extra-output-prior',
                'unit': 'quantity', 'operator': 'add', 'inputCount': spec['inputCount'],
                'amount': prismatic['expectedQuantity']['value'], 'confidence': 0}}
            spec['assumptions'].append('Calibrate only the confidence-zero native PrismaticOre unlock quantity to this same reported unlocked source mean per native input batch. Native locked quantity remains0; no proc probability, samples or unchanged empirical coefficients are invented.')
        if self.items.get(input_id, {}).get('qualityRank'):
            spec['inputQualityRank'] = self.items[input_id]['qualityRank']
        if native_family_ids:
            spec['reviewedQualityProjection'] = 'source-anchored'
        replacement_locs = set()
        for p, _, _, represented in entries:
            if represented:
                replacement_locs.add(p['sourceLocator'])
                replacement_locs.update(self.proposal_by_id[a]['sourceLocator'] for a in self.alias_members[p['proposalID']])
        if replacement_locs:
            spec['supersedesSourceFields'] = [dict(ref, fields=['expectedQuantity']) for ref in self.refs(replacement_locs)]
        proof, why = source_rows(self.research, spec['sourceRows'], self.effective, self.ref_cache)
        if why:
            raise ValueError(why + ': ' + record_id)
        record = model_record(spec, proof, 'processing-backlog/2026-11-20')
        assert record['samples'] == 0 and all(m['expectedQuantity']['samples'] == 0 for m in record['materials'])
        self.model.append(spec)
        for p in list(alias_proposals) + [e[0] for e in entries]:
            emitted[p['proposalID']].append(record_id)

    def nested(self):
        definitions = {
            'qualityShareProposals': ('qualityUnitShare', 'output-unit share'),
            'recoveredSourceWordMeanProposals': ('sourceReportedMean', 'material units per input'),
            'distributionModelProposals': ('sourceDistributionMean', 'material units per input'),
            'mixedInputScenarioProposals': ('mixedInputScenarioQuantity', 'material units per mixed input budget'),
            'acceptedRecordConditionalProposals': ('conditionalAcceptedQuantity', 'material units per accepted run'),
            'resourcefulnessCoefficientProposals': ('resourcefulnessReturnMagnitude', 'returned input fraction'),
            'reportedOutputCompositionProposals': ('sourceOutputComposition', 'reported output-unit share'),
            'unnamedRangeScenarioProposals': ('unnamedSourceRangeScenario', 'material units per input'),
            'nominalEventRateProposals': ('sourceNominalEventIntensity', 'positive events per modeled input'),
        }
        for section, (metric, unit) in definitions.items():
            for proposal in self.proposals.get(section, []):
                # The mixed-scenario list can point to a primary proposal already disposed.
                pid = proposal['proposalID']
                if pid in self.disposition_ids:
                    continue
                if section == 'distributionModelProposals' and proposal['admissionDecision'] == 'USE_SCOPED_DISTRIBUTION_MODEL_PRIOR':
                    row = self.row[proposal['sourceLocator']]
                    p = {'proposalID': pid, 'sourceKey': proposal['sourceKey'], 'sourceStudyKey': self.entry[proposal['sourceLocator']]['effective'].get('studyKey'),
                         'sourceLocator': proposal['sourceLocator'], 'method': 'Mill', 'sourceQuantityBasis': 'gross-input',
                         'inputIdentity': {'itemIDs': proposal['inputItemIDs']}, 'outputIdentity': {'itemIDs': proposal['outputItemIDs']},
                         'quantity': {'value': proposal['meanPerInput'], 'unit': 'input', 'formula': proposal['formula'], 'sourceSupportMaximum': 5,
                                      'assumptions': [proposal['distributionAssumption'], proposal['conditions']]},
                         'sourceProfile': self.group[pid.split(':')[0]]['sourceProfile'], 'reportedSourceCasts': None}
                    emitted = defaultdict(list)
                    for input_id in proposal['inputItemIDs']:
                        context, assumed, assumptions, unresolved = self.profile(p, 'Mill', self.names[input_id]['expansionID'])
                        key = (pid, input_id, False, None, 0, digest({}), digest({}))
                        self.emit_record(key, [(p, proposal['meanPerInput'], proposal['outputItemIDs'], [])], context, assumptions, False, emitted)
                    self.decision(proposal, 'ADMITTED_MODEL_PRIOR', 'Declared range distribution prior for the verified native herb/pigment family; no empirical N or observed rank allocation.', models=emitted[pid]); continue
                fact = self.fact_for(proposal, metric, unit)
                self.decision(proposal, 'METADATA_REFERENCE', 'Dimensioned source context/composition/conditional information preserved for the context consumer; it is not another independent absolute quantity observation.', facts=[fact])

    def resolve_aliases(self):
        by_id = {d['proposalID']: d for d in self.disposition}
        for _ in range(4):
            for decision in self.disposition:
                if decision['status'] != 'ALREADY_REPRESENTED' or decision.get('compiledRecordIDs'):
                    continue
                targets = []
                if decision.get('canonicalProposalID') in by_id:
                    targets = [by_id[decision['canonicalProposalID']]]
                elif decision.get('preferredCohortID'):
                    targets = [d for d in self.disposition if d['proposalID'].startswith(decision['preferredCohortID'] + ':')]
                models = sorted({mid for target in targets for mid in target.get('modelIDs', []) + target.get('compiledRecordIDs', [])})
                facts = sorted({fid for target in targets for fid in target.get('factIDs', [])})
                if models:
                    decision['compiledRecordIDs'] = models
                elif facts:
                    decision.update(status='METADATA_REFERENCE', decision='SOURCE_FACT', factIDs=facts,
                                    reason=decision['reason'] + ' Canonical field is source context, not a numerical compiled record.')
        for decision in self.disposition:
            if decision['status'] == 'ALREADY_REPRESENTED' and not decision.get('compiledRecordIDs'):
                raise ValueError('Already-represented field lacks actual compiled/canonical model identity: ' + decision['proposalID'])
            if decision['status'] == 'ALREADY_REPRESENTED':
                decision['modelIDs'] = sorted(set(decision['modelIDs'] + decision['compiledRecordIDs']))

    def row_context(self):
        """Carry every retained chance/range/histogram/conditional-zero field.

        These fields never acquire quantity or N by being copied to the typed
        context consumer.  Empirical-mean rejections stay distinct from modeled
        quantity admissions in the frozen review.
        """
        for locator, row in self.row.items():
            for field in ('expectedQuantity', 'dropChance', 'conditionalYieldRange', 'histogram'):
                spec = row['fields'][field]
                use = spec['decision'].startswith(('USE_', 'RETAIN_'))
                if field == 'expectedQuantity' and (row.get('proposalID') or row.get('modeledQuantityProposalID')):
                    ids = [d for d in self.disposition if d['proposalID'] in {row.get('proposalID'), row.get('modeledQuantityProposalID')}]
                    self.field_decisions.append({'sourceLocator': locator, 'sourceKey': self.source[locator]['sourceKey'], 'field': field,
                        'decision': 'MODEL_OR_EXPLICIT_PROPOSAL_DISPOSITION', 'proposalIDs': [d['proposalID'] for d in ids],
                        'sourceFieldDecision': spec['decision']})
                    continue
                if use:
                    p = {'proposalID': 'source-field:' + digest([locator, field])[:24], 'sourceLocator': locator,
                         'sourceKey': self.source[locator]['sourceKey'],
                         'field': field, 'sourceField': deepcopy(spec), 'sourceFacts': deepcopy(row['sourceFacts']),
                         'inputIdentity': deepcopy(row['inputIdentity']), 'outputIdentity': deepcopy(row['outputIdentity']),
                         'sourceSupportMaximum': 5}
                    fact = self.fact_for(p, 'reported' + field[0].upper() + field[1:],
                                         {'expectedQuantity': 'source material units per stated basis', 'dropChance': 'source event probability',
                                          'conditionalYieldRange': 'conditional positive material units', 'histogram': 'reported operation outcome bins'}[field],
                                         value=spec.get('value'))
                    decision = {'decision': 'SOURCE_FACT', 'factIDs': [fact], 'reason': spec.get('reason', 'Source field retained within its original condition and units.')}
                    p['originalArtifactReferences'] = [{'artifact': str(CATALOGUE / 'processing-review.json'),
                        'jsonPointer': self.row_pointer[locator] + '/fields/' + field,
                        'role': 'explicit-reviewed-source-field-definition', 'artifactSHA256': PINS['processing-review.json']}]
                    self.extra_definitions.append(p)
                    self.decision(p, 'METADATA_REFERENCE', decision['reason'], facts=[fact])
                else:
                    decision = {'decision': 'REJECTED_CURRENT_NUMERICAL', 'factIDs': [], 'reason': spec['reason'],
                                'futureEvidenceTrigger': spec.get('recheckTrigger') or row['recheckTrigger']}
                self.field_decisions.append({'sourceLocator': locator, 'sourceKey': self.source[locator]['sourceKey'], 'field': field,
                                             'sourceFieldDecision': spec['decision'], **decision})

    def run(self):
        self.primary(); self.nested(); self.resolve_aliases(); self.row_context()
        all_ids = {p['proposalID'] for p in self.proposals['proposals']}
        for value in self.proposals.values():
            if isinstance(value, list):
                all_ids.update(p['proposalID'] for p in value if isinstance(p, dict) and 'proposalID' in p)
        original_proposal_count = len(all_ids)
        all_ids.update(p['proposalID'] for p in self.extra_definitions)
        if all_ids != self.disposition_ids or not all(d['status'] in TERMINAL for d in self.disposition):
            raise ValueError('Proposal coverage is incomplete: ' + repr(all_ids - self.disposition_ids))
        definitions = {}
        for section, values in self.proposals.items():
            if not isinstance(values, list):
                continue
            for index, value in enumerate(values):
                if not isinstance(value, dict) or 'proposalID' not in value:
                    continue
                pid = value['proposalID']; pointer = '/' + section.replace('~', '~0').replace('/', '~1') + '/' + str(index)
                reference = {'artifact': str(CATALOGUE / 'processing-proposals.json'), 'jsonPointer': pointer,
                             'role': 'full-field-definition' if value.get('sourceKey') else 'partial-reference-alias'}
                if pid not in definitions:
                    definitions[pid] = deepcopy(value)
                    definitions[pid]['originalArtifactReferences'] = []
                definitions[pid]['originalArtifactReferences'].append(reference)
                if not definitions[pid].get('sourceKey'):
                    loc = value.get('sourceLocator')
                    gid = value.get('cohortID') or pid.split(':')[0]
                    if not loc and gid in self.group:
                        loc = self.group[gid]['rowDecisions'][0]['locator']
                    if not loc and value.get('reportedRankUnits'):
                        loc = value['reportedRankUnits'][0]['sourceLocator']
                    if not loc and value.get('outcomes'):
                        loc = value['outcomes'][0]['sourceLocator']
                    if not loc:
                        raise ValueError('Cannot resolve canonical proposal source: ' + pid)
                    definitions[pid]['sourceKey'] = self.source[loc]['sourceKey']
                    definitions[pid]['sourceKeyResolution'] = 'Exact reviewed row locator within frozen processing partition; not an inferred new source.'
        if set(definitions) != self.disposition_ids:
            for value in self.extra_definitions:
                definitions[value['proposalID']] = deepcopy(value)
        if set(definitions) != self.disposition_ids:
            raise ValueError('Canonical processing proposal index differs from dispositions')
        json_write(self.directory / 'processing-proposal-definitions.json', {
            'schemaVersion': 1, 'lane': 'processing', 'reviewPins': PINS,
            'definitionPolicy': 'Each proposalID denotes one field. Partial repeated scenario references add provenance pointers, never independent proposals/observations. Additional retained probability/range/histogram definitions point to the exact original frozen review field and add no new source evidence.',
            'proposals': [definitions[pid] for pid in sorted(definitions)]})
        manifest = {'schemaVersion': 1, 'revision': 'processing-backlog/2026-11-20',
                    'reviewPins': PINS, 'models': sorted(self.model, key=lambda m: m['recordID']),
                    'facts': sorted(self.fact, key=lambda f: f['factID']),
                    'sourceFieldExclusions': self.exclusions}
        receipt = {'schemaVersion': 1, 'lane': 'processing', 'status': 'TRANSLATED_PENDING_RUNTIME_ROUNDTRIP_AND_OWNER_INTEGRATION',
                   'reviewPins': PINS, 'coverage': {'sourceKeys': 224, 'candidateRows': 2845,
                   'originalUniqueProposalIDs': original_proposal_count, 'retainedReviewFieldDefinitions': len(self.extra_definitions),
                   'uniqueProposalIDs': len(all_ids), 'terminalDispositions': len(self.disposition),
                   'models': len(self.model), 'facts': len(self.fact),
                   'sourceFieldExclusions': len(self.exclusions),
                   'reviewedRowFields': len(self.field_decisions), 'sourceKeysWithFieldDecisions': len({d['sourceKey'] for d in self.field_decisions}),
                   'statuses': dict(Counter(d['status'] for d in self.disposition))},
                   'reasonedCurrentNumericalRejections': self.integration,
                   'legacyProducerExclusionAudit': {'checked': True, 'exclusionCount': len(self.exclusions),
                        'noExclusionsRequired': not self.exclusions,
                        'basis': 'Actual pre-catalogue build field support plus emitted record/material IDs; already held/unplaced/conditional sources are not blanket-masked.'},
                   'decisions': sorted(self.disposition, key=lambda d: d['proposalID']),
                   'fieldDecisions': self.field_decisions}
        manifest, fact_report = normalize_processing_facts(manifest, self.research, ROOT)
        receipt = normalize_processing_dispositions(receipt, fact_report)
        receipt['sourceFactTranslationReport'] = str(CATALOGUE / 'processing-source-fact-translation.json')
        json_write(self.directory / 'processing-source-fact-translation.json', fact_report)
        json_write(self.directory / 'processing-admitted-models.json', manifest)
        json_write(self.directory / 'processing-proposal-dispositions.json', receipt)
        print(json.dumps(receipt['coverage'], sort_keys=True))
        print('Reasoned current numerical rejections with source facts:', len(self.integration))
        return manifest, receipt

    def validate_runtime(self, manifest, receipt):
        """Check actual pinned Lua5.1 inverse/forward without writing build data."""
        sys.path.insert(0, str(ROOT.parent / '.tools/python313'))
        from lupa.lua51 import LuaRuntime
        lua = LuaRuntime(unpack_returned_tuples=True)
        payload = (ROOT / 'database/profession-profile-rules.lua').as_posix()
        module = (ROOT / 'LootLiquidator/ProfessionCalculations.lua').as_posix()
        lua.execute('LL={ItemDB={professionProfiles=assert(loadfile(' + json.dumps(payload) + '))()}}; assert(loadfile(' + json.dumps(module) + '))("LootLiquidator",LL)')
        verify = lua.eval('''function(spec)
            local option={name=spec.method,recipeID=spec.recipeID,inputCount=spec.inputCount,profession=spec.profession,
                reviewedEffectOverrides=spec.reviewedEffectOverrides}
            local facts={id=spec.inputItemID,expansionID=spec.expansionID,reagentQuality=spec.inputQualityRank}
            local source=spec.baselineProfile
            local params=LL:ProfessionProfileParameters(spec.profession,spec.expansionID,source,option,facts)
            local model={inputCount=spec.inputCount,materials={},sourceQuantityBasis=spec.sourceQuantityBasis,
                reviewedBacklogModel=true,reviewedQualityProjection=spec.reviewedQualityProjection,
                reviewedQualityZeroShares=spec.reviewedQualityZeroShares}
            for _,m in ipairs(spec.materials) do model.materials[#model.materials+1]={
                id=m.id,rankIDs=m.rankIDs,economicPolicy=m.economicPolicy,expectedQuantity=m.expectedQuantity.value,confidence=0} end
            local normalized,why=LL:NormalizeProfessionBaseline(model,params,option)
            if not normalized then return false,'normalize: '..tostring(why) end
            local projected,error=LL:ProjectProfessionBaseline(normalized,params,option)
            if not projected then return false,'forward: '..tostring(error) end
            local byID={};for _,m in ipairs(projected.materials) do byID[m.id]=(byID[m.id] or 0)+m.expectedQuantity end
            local factor=spec.sourceQuantityBasis=='net-input' and params.inputFactor or 1
            for _,m in ipairs(model.materials) do
                local expected=m.expectedQuantity*factor
                if math.abs((byID[m.id] or 0)-expected)>1e-8*math.max(1,expected) then
                    return false,'source quantity '..m.id..' '..tostring(byID[m.id])..' ~= '..expected
                end
                if m.expectedQuantity~=spec.materials[_].expectedQuantity.value then return false,'source mutated' end
            end
            -- Replaying an already-normalized source cannot add the modifiers twice.
            local replay=LL:ProjectProfessionBaseline(projected,params,option)
            if not replay then return false,'idempotent replay missing' end
            for _,m in ipairs(replay.materials) do
                if math.abs(m.expectedQuantity-(byID[m.id] or 0))>1e-8*math.max(1,m.expectedQuantity) then
                    return false,'replay changed quantity '..m.id
                end
            end
            local zero=LL:ProfessionProfileParameters(spec.profession,spec.expansionID,
                {skill=0,preSpecializationSkill=0,specializationPoints={},stats={}},option,facts)
            local baseline=LL:ProjectProfessionBaseline(normalized,zero,option)
            if not baseline then return false,'zero target missing' end
            return true,'source roundtrip, immutable input and replay passed'
        end''')
        failures = []
        debug = lua.eval('''function(spec)
            return LL:ProfessionProfileParameters(spec.profession,spec.expansionID,spec.baselineProfile,
                {name=spec.method,recipeID=spec.recipeID,inputCount=spec.inputCount,profession=spec.profession,
                 reviewedEffectOverrides=spec.reviewedEffectOverrides},
                {id=spec.inputItemID,expansionID=spec.expansionID,reagentQuality=spec.inputQualityRank})
        end''')
        for spec in manifest['models']:
            accepted, reason = verify(lua.eval(bridge.lua(spec)))
            if not accepted:
                params = debug(lua.eval(bridge.lua(spec)))
                failures.append({'recordID': spec['recordID'], 'reason': reason,
                                 'sourceProposalIDs': spec['referenceConditions']['sourceProposalIDs'],
                                 'sourceParams': {key: dict(params[key].items()) if hasattr(params[key], 'items') else params[key]
                                                  for key in ('skill', 'inputFactor', 'outputFactor', 'extraOutputs', 'minimumOutputs', 'sameOutputExtra', 'relativeExtraOutputs')}})
        result = {'runtime': 'Lua5.1 (lupa.lua51)', 'models': len(manifest['models']),
                  'passed': len(manifest['models']) - len(failures), 'failures': failures,
                  'sourceProofsValidated': True, 'sourceRowsMutated': False, 'compiledArtifactsWritten': False}
        fact_result = verify_processing_fact_consumer(manifest, ROOT)
        result['sourceFactConsumerValidation'] = fact_result
        if fact_result['failures']:
            result['failures'].extend(dict(failure, kind='source-fact-consumer') for failure in fact_result['failures'])
        fact_report = load(self.directory / 'processing-source-fact-translation.json')
        fact_report['consumerValidation'] = fact_result
        json_write(self.directory / 'processing-source-fact-translation.json', fact_report)
        receipt['sourceFactConsumerTranslation']['consumerValidation'] = fact_result
        receipt['runtimeValidation'] = result
        receipt['status'] = 'SOURCE_PROOF_AND_LUA51_ROUNDTRIP_PASSED_PENDING_OWNER_INTEGRATION' if not failures else 'LUA51_ROUNDTRIP_FAILURES_REQUIRE_RESOLUTION'
        json_write(self.directory / 'processing-proposal-dispositions.json', receipt)
        print(json.dumps(result, ensure_ascii=False))
        return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--research-root', type=Path, default=ROOT.parent / 'catalogue-backlog-research-20261120')
    parser.add_argument('--validate-runtime', action='store_true', help='Run actual pinned Lua5.1 source-profile inverse/forward checks without generating ItemDB.')
    args = parser.parse_args()
    curator = Curator(args.research_root)
    manifest, receipt = curator.run()
    if args.validate_runtime:
        result = curator.validate_runtime(manifest, receipt)
        if result['failures']:
            raise SystemExit(1)


if __name__ == '__main__':
    main()
