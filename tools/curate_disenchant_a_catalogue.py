"""Translate the frozen DE-A field reviews into explicit producer admissions.

This adapter does no research or classification of unread sources. It consumes
the completed, scoped human reviews, retains their exact immutable evidence
locators, and assigns every proposal an actual model/fact ID or a precise
current numerical rejection. Conditional Q/H and website counters never become
unconditional quantities, measured N, or current-patch probabilities.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from copy import deepcopy
from hashlib import sha256
import json
import math
from pathlib import Path
import re

from reviewed_source_catalogue import canonical_hash, model_record, source_rows

ROOT = Path(__file__).resolve().parents[1]
RELATIVE = Path('research/v3/evidence/master/backlog-catalogue-20261120')
INPUTS = [('disenchant-a-proposals.json', 'disenchant-a-review.json'),
          ('disenchant-a-current-addendum-proposals.json', 'disenchant-a-current-addendum-review.json')]
REVISION = 'reviewed-disenchant-a/1'
MEANS = {'meanUnitsPerCast', 'meanUnitsPerNominalInputPrior',
         'reportedApproximateMeanUnitsPerCast', 'sourceTableMeanUnitsPerReportedOperation'}
QUALITY_FAMILIES = ((219946, 219947, 219948), (219949, 219950, 219951),
                    (219952, 219954, 219955), (243599, 243600),
                    (243602, 243603), (243605, 243606))
METRIC_MAP = {
    'conditionalMeanUnitsPerPositiveEvent': ('conditionalMeanUnitsPerPositiveEvent', 'positive-material-event'),
    'conditionalStackRange': ('conditionalStackRange', 'positive-material-event'),
    'rankUnitShare': ('rankUnitShare', 'material-unit-fraction'),
    'sourceOccurrenceFraction': ('sourceOccurrenceFraction', 'source-occurrence-fraction'),
    'sourceDisplayedFraction': ('sourceOccurrenceFraction', 'source-displayed-fraction'),
    'reportedApproximateOccurrenceFraction': ('sourceOccurrenceFraction', 'source-reported-occurrence-fraction'),
    'reportedPerCastChance': ('sourceOccurrenceFraction', 'source-reported-operation-fraction'),
    'meanUnitsPerCast': ('sourceProfileMeanUnitsPerOperation', 'operation'),
    'reportedApproximateMeanUnitsPerCast': ('sourceProfileMeanUnitsPerOperation', 'nominal-operation'),
    'meanUnitsPerNominalInputPrior': ('sourceProfileMeanUnitsPerInput', 'nominal-stock-budget'),
    'sourceTableMeanUnitsPerReportedOperation': ('sourceProfileMeanUnitsPerOperation', 'source-reported-operation'),
    'meanUnitsPerCastLowerBound': ('sourceProfileMeanUnitsPerOperationLowerBound', 'operation'),
    'reportedMeanUnitsPerCastRange': ('sourceProfileMeanUnitsPerOperationRange', 'operation'),
    'reportedMeanUnitsPerNominalInputRange': ('sourceProfileMeanUnitsPerInputRange', 'nominal-stock-budget'),
    'reportedMeanUnitsPerNominalInputLowerBound': ('sourceProfileMeanUnitsPerInputLowerBound', 'nominal-stock-budget'),
    'reportedPerCastChanceRange': ('sourceReportedChanceRange', 'source-reported-operation-fraction'),
    'reportedPerCastChanceLowerBound': ('sourceReportedChanceLowerBound', 'source-reported-operation-fraction'),
    'reportedAllPositiveAnecdote': ('reportedPositiveOutcome', 'qualitative-outcome'),
    'knowledgePointsPerOneTimeDisenchant': ('sourceKnowledgePointsPerOperation', 'knowledge-points-per-operation'),
    'sourceReportedMaterialUnits': ('sourceReportedMaterialUnits', 'source-material-units'),
}
RARITIES = {'uncommon': 2, 'green': 2, 'rare': 3, 'blue': 3, 'epic': 4, 'purple': 4}
ERAS = {'midnight': 11, 'the war within': 10, 'war-within': 10, 'khaz algar': 10,
        'dragonflight': 9, 'shadowlands': 8, 'battle for azeroth': 7,
        'legion': 6, 'warlords of draenor': 5, 'mists of pandaria': 4,
        'cataclysm': 3, 'wrath of the lich king': 2, 'wotlk': 2, 'northrend': 2,
        'wod': 5, 'bfa': 7,
        'the burning crusade': 1, 'outland': 1, 'classic': 0}


def read(path):
    return json.loads(Path(path).read_text(encoding='utf-8-sig'))


def encoded(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2, allow_nan=False) + '\n'


def exact_number(value):
    return type(value) in (int, float) and math.isfinite(value) and value >= 0


def item_id(value):
    return type(value) is int and value > 0


def uid(prefix, value):
    return prefix + sha256(json.dumps(value, ensure_ascii=False, sort_keys=True,
                                    separators=(',', ':'), allow_nan=False).encode()).hexdigest()[:24]


def era(value):
    if type(value) is int and 0 <= value <= 11:
        return value
    text = str(value or '').lower()
    for key, number in ERAS.items():
        if key in text:
            return number
    return None


def reviewed_rows(document):
    return {row['locator']: row for source in document['sources']
            for cohort in source['cohorts'] for row in cohort['rowDecisions']}


class Curator:
    def __init__(self, research, native):
        self.research = Path(research)
        self.base = self.research / RELATIVE
        self.native = native['items']
        self.source_cache = {}
        self.proposals = []
        self.reviews = {}
        self.review_paths = {}
        self.all_review_rows = []
        self.assigned_source_keys = set()
        self.raw = {}
        self.refs = {}
        self.facts = {}
        self.models = {}
        self.decisions = []
        self.model_reasons = {}
        self.facts_by_proposal = {}
        self.models_by_proposal = defaultdict(list)
        self.cohorts = defaultdict(list)
        self.scope_receipts = defaultdict(list)
        for proposals_file, review_file in INPUTS:
            proposals = read(self.base / proposals_file)['proposals']
            document = read(self.base / review_file)
            rows = reviewed_rows(document)
            self.all_review_rows.extend(rows.values())
            self.assigned_source_keys.update(s['sourceKey'] for s in document['sources'])
            for proposal in proposals:
                self.proposals.append(proposal)
                self.reviews[proposal['proposalID']] = rows[proposal['locator']]
                self.review_paths[proposal['proposalID']] = (RELATIVE / review_file).as_posix()
        assert len(self.proposals) == 2365, 'Frozen 1972+393 proposal assignment changed'
        self.supplement = read(self.base / 'disenchant-a-supplemental-proposals.json')
        self.field_audit = read(self.base / 'disenchant-a-field-audit-proposals.json')
        original_rows = {r['locator']: r for r in self.all_review_rows}
        for p in self.supplement['proposals']:
            self.proposals.append(p)
            self.reviews[p['proposalID']] = original_rows[p['locator']]
            self.review_paths[p['proposalID']] = (RELATIVE / 'disenchant-a-supplemental-proposals.json').as_posix()
        audit_rows = {r['locator']: r for r in self.field_audit['rowReviews']}
        for p in self.field_audit['proposals']:
            self.proposals.append(p)
            self.reviews[p['proposalID']] = audit_rows[p['locator']]
            self.review_paths[p['proposalID']] = (RELATIVE / 'disenchant-a-field-audit-proposals.json').as_posix()
        assert len({p['proposalID'] for p in self.proposals}) == len(self.proposals), 'Duplicate proposal ID'
        for p in self.proposals:
            self.load_proof(p)
            self.cohorts[p['canonicalCohortKey']].append(p)
        assert len(self.assigned_source_keys) == 246
        assert len(self.all_review_rows) == 2273
        assert len({r['locator'] for r in self.all_review_rows}) == 2273
        for row in self.all_review_rows:
            assert row['sourceEvidenceExamined']
            assert row['proposalRefs'] or (row['fieldRejections'] and all(r.get('reason') and r.get('futureEvidenceTrigger')
                for r in row['fieldRejections'])), 'Unexplained original row rejection: ' + row['locator']

    def load_proof(self, p):
        locator = p['locator']
        if locator not in self.raw:
            filename, line = locator.rsplit(':', 1)
            if filename not in self.source_cache:
                self.source_cache[filename] = (self.research / filename).read_text(encoding='utf-8-sig').splitlines()
            row = json.loads(self.source_cache[filename][int(line) - 1])
            review = self.reviews[p['proposalID']]
            assert row['id'] == p['recordID'], locator
            assert canonical_hash(row) == review['rawSHA256'], 'Changed frozen review row: ' + locator
            effective = deepcopy(row)
            for correction in review.get('currentCorrections', []):
                assert correction['recordID'] == row['id'] and correction['file'] == filename
                effective[correction['field']] = deepcopy(correction['value'])
            self.raw[locator] = row
            self.refs[locator] = {'sourceFile': filename, 'line': int(line), 'sourceRecordID': row['id'],
                                  'rawSHA256': canonical_hash(row), 'effectiveSHA256': canonical_hash(effective)}
        return self.raw[locator]

    def direct_scope(self, p):
        raw = self.raw[p['locator']]
        inp = p['input']
        group = inp.get('gearGroup') or raw.get('gearGroup') or {}
        native = self.native.get(str(inp.get('inputItemID')), {})
        expansion = era(group.get('expansion'))
        if expansion is None:
            expansion = era(raw.get('agent'))
        if expansion is None:
            expansion = era(inp.get('inputName'))
        if expansion is None and item_id(inp.get('inputItemID')):
            expansion = native.get('expansionID')
        text = str(inp.get('inputName') or raw.get('inputName') or '').lower()
        quality = RARITIES.get(str(group.get('quality') or '').lower())
        if quality is None:
            words = re.findall(r'\b(uncommon|rare|epic|green|blue|purple)\b', text)
            if len({RARITIES[w] for w in words}) == 1:
                quality = RARITIES[words[0]]
        kind = str(group.get('kind') or '').lower()
        class_id = 2 if kind in {'weapon', 'weapons'} else 4 if kind in {'armor', 'armour'} else None
        if class_id is None:
            if re.search(r'\b(weapons?|hammers?|swords?|daggers?|claymores?)\b', text):
                class_id = 2
            elif re.search(r'\b(armor|armour|bracers?|cuffs?|cloaks?|belts?|robes?|pants|tunics?|headbands?|helms?|shoulders?|rings?)\b', text):
                class_id = 4
        scope = {}
        if item_id(inp.get('inputItemID')):
            scope['inputItemID'] = inp['inputItemID']
        elif p.get('applicability', {}).get('inputFamilyIDs'):
            family = p['applicability']['inputFamilyIDs']
            if all(item_id(i) for i in family):
                scope['inputFamilyIDs'] = list(family)
        elif text.startswith('tidespray linen bracers'):
            # The report names the item but omits faction. Native ItemSparse
            # has exactly these two verified faction versions; preserve the
            # two-item SOURCE pool instead of guessing either one or a rarity.
            family = [154692, 161984]
            assert all(self.native[str(i)]['name'] == 'Tidespray Linen Bracers' for i in family)
            scope['inputFamilyIDs'] = family
            expansion = 7
        elif '30568' in text and '30570' in text:
            # Both names/IDs are explicitly supplied in this mixed Halaa
            # source. Its mean/range describes that pool, never either item's
            # independent outcome distribution.
            assert self.native['30568']['name'] == 'The Sharp Cookie'
            assert self.native['30570']['name'] == 'Arkadian Claymore'
            scope['inputFamilyIDs'] = [30568, 30570]
            expansion = 1
        elif expansion is not None and (quality is not None or class_id is not None):
            scope['gearScope'] = {'expansionID': expansion}
            if quality is not None:
                scope['gearScope']['rarity'] = quality
            if class_id is not None:
                scope['gearScope']['classID'] = class_id
        if expansion is None and scope.get('inputFamilyIDs'):
            eras = {self.native.get(str(i), {}).get('expansionID') for i in scope['inputFamilyIDs']}
            if None not in eras and len(eras) == 1:
                expansion = next(iter(eras))
        if expansion is not None:
            scope['expansionID'] = expansion
        return scope, native, quality, class_id

    def scope(self, p):
        result = self.direct_scope(p)
        scope, native, quality, class_id = result
        if any(k in scope for k in ('inputItemID', 'inputFamilyIDs', 'gearScope')):
            return result
        # Explicit canonical-cohort lineage can carry a more complete source
        # scope from another retained transcription, but only without a scope
        # conflict. Every additional proof row is retained in sourceRows.
        candidates = []
        for other in self.cohorts[p['canonicalCohortKey']]:
            candidate = self.direct_scope(other)
            if any(k in candidate[0] for k in ('inputItemID', 'inputFamilyIDs', 'gearScope')):
                candidates.append((other, candidate))
        signatures = {canonical_hash(c[1][0]) for c in candidates}
        if len(signatures) == 1:
            other, adopted = candidates[0]
            self.scope_receipts[p['proposalID']] = [self.refs[x['locator']] for x, _ in candidates]
            return deepcopy(adopted)
        return result

    def source_fact(self, p):
        mapped = METRIC_MAP.get(p['metric'])
        if mapped is None:
            return None, 'No dimension-preserving runtime metric exists for ' + p['metric']
        scope, native, _, _ = self.scope(p)
        if not any(k in scope for k in ('inputItemID', 'inputFamilyIDs', 'gearScope')):
            return None, ('Original source identifies ' + repr(p['input']) +
                          '; neither an exact input/family nor expansion plus rarity/armor-or-weapon category is established. '
                          'Applying this source fact to every disenchantable item would invent input applicability.')
        output = p['output']
        if not item_id(output.get('itemID')) and not str(output.get('name') or '').strip():
            return None, 'No verified output item identity or source-backed outcome name is available.'
        metric, unit = mapped
        context = {'sourceInput': p['input'].get('inputName') or str(p['input'].get('gearGroup')),
                   'sourceMetric': p['metric'], 'quantityBasis': p.get('basis', p['unit'])}
        context.update(deepcopy(p.get('additionalReferenceConditions', {})))
        for key, value in p.get('applicability', {}).items():
            if value not in (None, False) and key in ('oneTime', 'catchupOrWeeklyStateRelevant',
                    'requiresIwenRod', 'requiresReportedActiveBuff'):
                context[key] = deepcopy(value)
        if p.get('assumptions'):
            context['sourceAssumptions'] = '; '.join(p['assumptions'])
        if 'inputFamilyIDs' in scope:
            context['inputPool'] = 'Mixed or unidentified source variant within the listed family; not a measured separate distribution for each target item.'
        raw = self.raw[p['locator']]
        variant = p.get('nativeInputVariant')
        if not variant:
            verification = self.reviews[p['proposalID']].get('nativeSourceVerification') or {}
            if verification.get('table') == 'EnchantedLocal':
                variant = verification.get('key')
            if not variant:
                match = re.search(r'EnchantedLocal[^\n]{0,80}?(\d+:\d+:\d+)', str(raw.get('notes', '')))
                if match:
                    variant = match.group(1)
        fact = dict(scope, method='Disenchant', metric=metric, unit=unit,
                    confidence0to100=0, sourceSupportConfidence=20, sourceKey='itemdb',
                    sourceURL=p['sourceURL'], sourceStudyKey=p['canonicalCohortKey'],
                    sourceProfile=deepcopy(p['sourceProfile']), referenceConditions=context,
                    sourceRows=[deepcopy(self.refs[p['locator']])],
                    reportedObservationCounts={k: p.get(k) for k in
                        ('measuredCasts', 'sourceTableDenominator', 'sourcePositiveEvents', 'sourceMaterialUnits')},
                    sourceFacts=deepcopy(p.get('sourceFacts', {})),
                    modelingAssumptions=deepcopy(p.get('assumptions', [])),
                    economicPolicy=p.get('economicPolicy'), sourceContextOnly=True, targetProfileAdjusted=False)
        if item_id(output.get('itemID')):
            fact['outputItemID'] = output['itemID']
        if output.get('name'):
            fact['outputName'] = output['name']
        if output.get('rank') is not None:
            fact['outputRank'] = output['rank']
        if variant:
            fact['nativeInputVariant'] = variant
        for ref in self.scope_receipts[p['proposalID']]:
            if ref not in fact['sourceRows']:
                fact['sourceRows'].append(deepcopy(ref))
        if metric == 'reportedPositiveOutcome':
            pass  # The proposal's 1 is qualitative, not a calibrated 100% rate.
        elif 'Range' in metric or metric == 'conditionalStackRange':
            if not exact_number(p.get('lower')) or not exact_number(p.get('upper')) or p['lower'] > p['upper']:
                return None, 'Original proposal has no finite, dimension-compatible source interval.'
            fact.update(lower=p['lower'], upper=p['upper'])
        else:
            if not exact_number(p.get('value')):
                return None, 'Original proposal has no finite source value in the supported metric dimension.'
            fact['value'] = p['value']
        if p.get('exclusive'):
            fact['exclusive'] = True
        if metric == 'sourceKnowledgePointsPerOperation':
            fact['oneTime'] = True
            fact['economicPolicy'] = 'nontradable'
        semantic = {k: fact.get(k) for k in ('method', 'metric', 'unit', 'inputItemID', 'inputFamilyIDs',
                    'gearScope', 'expansionID', 'outputItemID', 'outputName', 'outputRank', 'value',
                    'lower', 'upper', 'exclusive', 'nativeInputVariant', 'sourceStudyKey')}
        if fact.get('outputItemID'):
            semantic.pop('outputName', None)
        fact_id = uid('source-fact:dea:', semantic)
        fact['factID'] = fact_id
        old = self.facts.get(fact_id)
        if old:
            for ref in fact['sourceRows']:
                if ref not in old['sourceRows']:
                    old['sourceRows'].append(ref)
            old.setdefault('proposalIDs', []).append(p['proposalID'])
        else:
            fact['proposalIDs'] = [p['proposalID']]
            self.facts[fact_id] = fact
        return fact_id, None

    def profile(self, p, expansion):
        reported = p['sourceProfile']
        skill = reported.get('skill')
        if expansion == 10 and p['canonicalCohortKey'] == 'reddit-1f9qado-blood-elf-297-hammers':
            assert p.get('measuredCasts') == 297
            assert re.search(r'105\s*\+\s*40', str(skill))
            assert p['output']['itemID'] in (219946, 219947, 219948)
            native_path = ROOT / 'database/research/profession-effect-catalog-70961.json'
            native = read(native_path)
            nodes = {n['nodeID']: n for n in native['nodes'] if n['nodeID'] in (99890, 99889)}
            assert nodes[99890]['name'] == 'Designated Disenchanter' and nodes[99890]['maxInvestedRank'] == 30
            assert nodes[99889]['name'] == 'Uncommon Utilitarian' and nodes[99889]['maxInvestedRank'] == 30
            profile = {'skill': 145, 'preSpecializationSkill': 145, 'stats': {},
                       'specializationPoints': {'99890': 30, '99889': 30},
                       'learnedSpecializations': {'99890': True, '99889': True},
                       'profileKind': 'manual-simulation', 'simulated': True,
                       'sourceReportedProfile': deepcopy(reported),
                       'nativeMappingProvenance': {'path': native_path.relative_to(ROOT).as_posix(),
                           'sha256': sha256(native_path.read_bytes()).hexdigest(), 'nodeIDs': [99890, 99889]}}
            assumptions = ['Reported105+40 is modeled as145 native skill before specialization; equipped skill is included once.',
                'The named max uncommon source is mapped to the verified current native Designated Disenchanter30 and Uncommon Utilitarian30 caps. Historical node amounts/build are not observed and this transfer has confidence0.',
                'Complete three-rank source means are normalized with a declared source-anchored quality prior; max-source shares remain the source anchor rather than a zero-profile study.',
                'The reported297 operations remain provenance only; no observed samples or hit probabilities are added by this model.']
            return (profile, True, assumptions), None, None
        # A plain source Enchanting number is retained. Intervals, tool/racial
        # ambiguity, and minimum requirements are not silently exact values.
        value = None
        if exact_number(skill):
            value = skill
        elif isinstance(skill, str):
            m = re.fullmatch(r'(?:Shadowlands Tailoring \d+ / )?Enchanting (\d+)(?: \(reported\))?', skill)
            if m:
                value = int(m.group(1))
            elif not re.search(r'\d+\s*[-–]\s*\d+|less than|more than|[<>]', skill, re.I):
                m = re.search(r'\bEnchanting\s+(\d+)\b', skill)
                if m:
                    value = int(m.group(1))
        profile = {'skill': value or 0, 'preSpecializationSkill': value or 0, 'stats': {},
                   'specializationPoints': {}, 'learnedSpecializations': {},
                   'profileKind': 'manual-simulation', 'simulated': True,
                   'sourceReportedProfile': deepcopy(reported)}
        assumptions = ['Historical source units are an explicit current-applicability prior with modeling confidence 0.',
                       'No observed operations, zero outcomes or probability are synthesized from this mean.',
                       'The native base input identity does not prove the historical bonus variant or current eligibility.']
        assumed = value is None
        if value is None:
            assumptions.append('Source effective skill is unknown; zero is an explicit normalization reference assumption, not a measured source skill.')
        if expansion >= 9:
            nonzero = str(reported.get('specialization') or '').strip()
            if nonzero and not re.search(r'\bno\b.*specialization|\bzero\b', nonzero, re.I):
                return None, None, 'Known source specialization is not numerically identifiable for this exact model scope; preserve the source-profile mean without pretending it is the minimum profile.'
            if reported.get('stats'):
                return None, None, 'Source equipment/stat contribution is reported but lacks an identified numeric inverse; preserve the unadjusted source-profile mean.'
        elif reported.get('stats') or reported.get('specialization'):
            return None, None, 'Historical equipment, buff or specialization changes output and has no verified source-profile inverse; preserve source-context quantities without double applying its effect.'
        elif value is not None and value > 0:
            return None, None, 'The historical source explicitly reports nonzero Enchanting skill, but this era has no supported skill-yield normalization curve. Preserve its exact source-profile mean rather than treating it as the zero-profile baseline.'
        return (profile, assumed, assumptions), None, None

    def model_candidate(self, p):
        if p['metric'] not in MEANS:
            return None, 'This metric is a source fact, not an unconditional expected material quantity.'
        if not item_id(p['output'].get('itemID')):
            return None, 'Source-backed output name/rank is retained unpriced; no verified output item ID can enter priced model materials.'
        if p.get('economicPolicy') == 'nontradable' or any(p.get('applicability', {}).get(k) for k in
                ('oneTime', 'catchupOrWeeklyStateRelevant', 'requiresIwenRod', 'requiresReportedActiveBuff')):
            return None, 'One-time, weekly/catch-up, nontradable or explicitly buffed source outcome requires its source conditions; it is not an unconditional sale-value material prior.'
        scope, native, quality, class_id = self.scope(p)
        expansion = scope.get('expansionID')
        if expansion is None:
            return None, 'The source and verified input identity do not identify an expansion for numeric model dispatch.'
        if 'inputItemID' in scope:
            if native.get('classID') not in (2, 4):
                return None, 'Exact source input has no verified native armor/weapon class for numerical disenchant dispatch.'
            class_id = class_id or native['classID']
            quality = quality or native.get('rarity')
            if quality not in (2, 3, 4):
                return None, 'Current native input is not uncommon/rare/epic gear, and no verified target-variant eligibility is available; historical source quantity remains informational.'
            if native.get('expansionID') is not None and native['expansionID'] != expansion:
                return None, 'Source era and current native base-item expansion differ; no historical variant-to-target eligibility bridge is verified.'
            model_scope = {'inputItemID': scope['inputItemID'], 'inputClassID': class_id, 'inputRarity': quality}
        elif 'inputFamilyIDs' in scope:
            return None, 'The report is a mixed/unidentified source input family, not a separate mean for each item or a full profession-wide category. Preserve the pooled source mean only.'
        elif quality in (2, 3, 4) and class_id in (2, 4):
            model_scope = {'gearKey': f'gear:{expansion}:{quality}:' + ('weapon' if class_id == 2 else 'armor'),
                           'inputClassID': class_id, 'inputRarity': quality,
                           'isDisenchantCategory': True}
        else:
            return None, 'The reported gear pool lacks a full expansion+rarity+armor/weapon category; source-only scope cannot be promoted into a priced category.'
        profile, _, reason = self.profile(p, expansion)
        if reason:
            return None, reason
        return (model_scope, expansion, profile), None

    def build_models(self):
        grouped = defaultdict(list)
        for p in self.proposals:
            candidate, reason = self.model_candidate(p)
            self.model_reasons[p['proposalID']] = reason
            if candidate:
                scope, expansion, profile = candidate
                semantic_profile = {k: v for k, v in profile[0].items() if k != 'sourceReportedProfile'}
                key = (p['canonicalCohortKey'], canonical_hash(scope), expansion,
                       canonical_hash(semantic_profile), p['metric'])
                grouped[key].append((p, scope, expansion, profile))
        for key, entries in sorted(grouped.items()):
            selected = defaultdict(list)
            for p, *_ in entries:
                selected[p['output']['itemID']].append(p)
            if any(len({p['value'] for p in values}) != 1 for values in selected.values()):
                for p, *_ in entries:
                    self.model_reasons[p['proposalID']] = 'Same declared cohort/output has conflicting source means; no averaging or fabricated separation is used. Source means remain individually queryable.'
                continue
            expansion = entries[0][2]
            present = set(selected)
            incomplete = [family for family in QUALITY_FAMILIES if present.intersection(family) and not set(family) <= present]
            if expansion >= 9 and incomplete:
                for p, *_ in entries:
                    self.model_reasons[p['proposalID']] = 'Incomplete known native quality family; missing ranks are unknown rather than fabricated zero means. Source-profile quantities are retained without unidentified quality inversion.'
                continue
            p, scope, expansion, (profile, assumed, assumptions) = entries[0]
            refs = sorted({p['locator'] for p, *_ in entries})
            model_id = uid('evidence:reviewed-backlog:dea:', key)
            spec = dict(scope, recordID=model_id, method='Disenchant', recipeID=13262,
                        inputCount=1, expansionID=expansion, profession='Enchanting',
                        sourceKey=p['sourceKey'], sourceStudyKey=p['canonicalCohortKey'],
                        sourceURL=p['sourceURL'], sourceTitle='Reviewed DE source catalogue',
                        baselineProfile=profile, baselineProfileAssumed=assumed,
                        baselineProfileConfidence=0, assumptions=deepcopy(assumptions),
                        sourceRows=[deepcopy(self.refs[x]) for x in refs],
                        supersedesSourceFields=[dict(deepcopy(self.refs[x]), fields=['expectedQuantity']) for x in refs],
                        sourceQuantityBasis='nominal-stock-budget' if p['metric'] == 'meanUnitsPerNominalInputPrior' else 'operation',
                        sourceEpoch=deepcopy(p['sourceProfile']),
                        referenceConditions={'sourceProfile': deepcopy(p['sourceProfile']),
                                             'sourceBasis': p.get('basis'),
                                             'sourceInput': deepcopy(p['input'])},
                        reportedObservationCounts={proposal['proposalID']: {name: proposal.get(name) for name in
                            ('measuredCasts', 'nominalInputCount', 'sourceMaterialUnits', 'sourceTableDenominator')}
                            for proposal, *_ in entries}, materials=[])
            if expansion == 11:
                spec.update(requiresSourceNormalization=True, reviewedDisenchantProjection='source-anchored')
            elif expansion >= 9:
                spec.update(requiresSourceNormalization=True, reviewedQualityProjection='source-anchored')
            for output_id, values in sorted(selected.items()):
                representative = values[0]
                derivation = {'kind': 'explicit-source-value', 'basis': representative.get('basis'),
                              'proposalID': representative['proposalID'], 'unit': representative['unit']}
                denominator = representative.get('nominalInputCount') if representative['metric'] == 'meanUnitsPerNominalInputPrior' else representative.get('measuredCasts')
                numerator = representative.get('sourceMaterialUnits')
                if exact_number(numerator) and exact_number(denominator) and denominator > 0 and math.isclose(representative['value'], numerator / denominator):
                    derivation.update(kind='ratio', numerator=numerator, denominator=denominator,
                                      denominatorMeaning='nominal-reported-stock-budget' if representative['metric'] == 'meanUnitsPerNominalInputPrior' else 'reported-operations')
                spec['materials'].append({'id': output_id, 'expectedQuantity': {'value': representative['value'],
                    'sourceSupportConfidence': 20, 'modelConfidenceCap': 0, 'derivation': derivation}})
                for v in values:
                    spec['assumptions'].extend(x for x in v.get('assumptions', []) if x not in spec['assumptions'])
            # Reuse the production field validator before producing any record.
            model_record(spec, spec['sourceRows'], REVISION)
            self.models[model_id] = spec
            for proposal, *_ in entries:
                self.models_by_proposal[proposal['proposalID']].append(model_id)

    def build(self):
        self.build_models()
        for p in self.proposals:
            fact_id, fact_reason = self.source_fact(p)
            model_ids = self.models_by_proposal[p['proposalID']]
            decision = {'proposalID': p['proposalID'], 'sourceKey': p['sourceKey'],
                        'sourceStudyKey': p['canonicalCohortKey'], 'locator': p['locator'],
                        'metric': p['metric'], 'modelIDs': model_ids, 'factIDs': [fact_id] if fact_id else [],
                        'receiptPath': self.review_paths[p['proposalID']]}
            if model_ids:
                decision['decision'] = 'MODEL_AND_SOURCE_FACT' if fact_id else 'MODEL'
                decision['reason'] = 'Exact scoped source mean admitted as a zero-active-sample, confidence-zero model prior; original source-profile quantity separately retained.'
            elif fact_id:
                decision['decision'] = 'SOURCE_FACT'
                decision['reason'] = self.model_reasons[p['proposalID']]
                if p['metric'] == 'reportedAllPositiveAnecdote':
                    decision['numericalInterpretationRejected'] = 'Unspecified operation denominator and amount do not establish a calibrated100% probability or unconditional quantity; only qualitative positive outcome is rendered.'
            else:
                decision.update(decision='REJECTED_CURRENT_NUMERICAL', reason=fact_reason,
                    futureEvidenceTrigger='A source-backed exact input/family or expansion+rarity/armor-or-weapon scope, plus verified outcome identity/name and a finite value in its stated denominator dimension. Existing source facts and quotes remain in the frozen field review.')
            self.decisions.append(decision)
            self.facts_by_proposal[p['proposalID']] = fact_id
        self.validate()
        exclusions = []
        for scope in self.field_audit['sourceFieldExclusions']:
            exclusion = deepcopy(scope)
            locator = exclusion.pop('locator')
            proposal = next(p for p in self.proposals if p['proposalID'] == exclusion['proposalIDs'][0])
            exclusion.update(sourceKey=proposal['sourceKey'], sourceStudyKey=proposal['canonicalCohortKey'],
                sourceRows=[dict(deepcopy(self.refs[locator]), fields=exclusion['fields'])],
                factIDs=[self.facts_by_proposal[pid] for pid in exclusion['proposalIDs']],
                receiptPath=(RELATIVE / 'disenchant-a-field-audit-proposals.json').as_posix(),
                reason=exclusion['reason'] + ' Source profile: ' + json.dumps(proposal['sourceProfile'], sort_keys=True),
                confidence0to100=0, method='Disenchant')
            assert all(f in self.facts for f in exclusion['factIDs'])
            exclusions.append(exclusion)
        summary = {'assignedProposals': len(self.proposals), 'originalAssignedProposals': 2365,
                   'supplementalFieldReviewProposals': len(self.supplement['proposals']),
                   'existingSourceFieldAuditProposals': len(self.field_audit['proposals']),
                   'additionalSameSourceRowsReviewed': len(self.field_audit['rowReviews']),
                   'sourceFieldExclusions': len(exclusions),
                   'sourceKeys': len(self.assigned_source_keys),
                   'candidateRowLocators': len(self.all_review_rows),
                   'proposalBearingSourceKeys': len({p['sourceKey'] for p in self.proposals}),
                   'proposalBearingRowLocators': len({p['locator'] for p in self.proposals}),
                   'preciselyRejectedOriginalRowsWithoutProposals': sum(r['locator'] not in {p['locator'] for p in self.proposals}
                       for r in self.all_review_rows),
                   'models': len(self.models), 'facts': len(self.facts),
                   'proposalDecisions': dict(sorted(Counter(d['decision'] for d in self.decisions).items())),
                   'factMetrics': dict(sorted(Counter(f['metric'] for f in self.facts.values()).items())),
                   'observedSamplesAdded': 0, 'scientificApprovalInvented': False,
                   'runtimeConsumerVerified': False}
        policy = {'schemaVersion': 1, 'revision': REVISION, 'lane': 'disenchant_a', 'summary': summary,
                  'models': sorted(self.models.values(), key=lambda x: x['recordID']),
                  'facts': sorted(self.facts.values(), key=lambda x: x['factID']),
                  'sourceFieldExclusions': exclusions}
        dispositions = {'schemaVersion': 1, 'revision': REVISION, 'lane': 'disenchant_a',
                        'summary': summary, 'decisions': self.decisions}
        return policy, dispositions

    def validate(self):
        assert len(self.decisions) == 2365 + len(self.supplement['proposals']) + len(self.field_audit['proposals'])
        assert {d['proposalID'] for d in self.decisions} == {p['proposalID'] for p in self.proposals}
        for d in self.decisions:
            assert all(i in self.models for i in d['modelIDs'])
            assert all(i in self.facts for i in d['factIDs'])
            assert d['reason']
            assert d['modelIDs'] or d['factIDs'] or d.get('futureEvidenceTrigger')
        for f in self.facts.values():
            assert f['confidence0to100'] == 0 and f['sourceSupportConfidence'] <= 20
            assert f['sourceContextOnly'] and not f['targetProfileAdjusted']
            proof, reason = source_rows(self.research, f['sourceRows'])
            assert proof and not reason, (f['factID'], reason)
        for m in self.models.values():
            record = model_record(m, m['sourceRows'], REVISION)
            assert record['samples'] == 0 and record['sampleSizeKnown'] is False
            assert all('value' not in row['dropChance'] for row in record['materials'])
            if m['expansionID'] == 11:
                assert record['reviewedDisenchantProjection'] == 'source-anchored'
                assert record['baselineProfileAssumed'] is True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--research-root', type=Path, default=ROOT / 'database/research/v3-snapshot')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    base = args.research_root / RELATIVE
    native = read(base / 'disenchant-a-support/native-item-identities.json')
    policy, dispositions = Curator(args.research_root, native).build()
    for name, content in [('disenchant-a-admitted-models.json', policy),
                          ('disenchant-a-proposal-dispositions.json', dispositions)]:
        path = base / name
        text = encoded(content)
        if args.check:
            if not path.exists() or path.read_text(encoding='utf-8') != text:
                raise SystemExit('Stale DE-A admission artifact: ' + str(path))
        else:
            path.write_text(text, encoding='utf-8', newline='\n')
    print(json.dumps(policy['summary'], sort_keys=True))


if __name__ == '__main__':
    main()
