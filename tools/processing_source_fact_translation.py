"""Adapt reviewed processing context to the actual informational Lua consumer.

This module never creates a priced model, sample size, probability denominator,
item identity or source-to-target profile transform.  Unsupported contexts stay
in a precise rejection receipt rather than an unreachable compiled fact.
"""
from __future__ import annotations

from collections import Counter
from copy import deepcopy
import hashlib
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

CATALOGUE = Path('research/v3/evidence/master/backlog-catalogue-20261120')
SUPPORTED = {
    'conditionalMeanUnitsPerPositiveEvent', 'sourceOccurrenceFraction',
    'conditionalStackRange', 'rankUnitShare', 'referenceMeanUnitsPerInput',
    'referenceMeanUnitsPerOperation', 'sourceProfileMeanUnitsPerInput',
    'sourceProfileMeanUnitsPerOperation', 'sourceProfileMeanUnitsPerInputRange',
    'sourceProfileMeanUnitsPerOperationRange', 'sourceProfileMeanUnitsPerInputLowerBound',
    'sourceProfileMeanUnitsPerOperationLowerBound', 'sourceReportedChanceRange',
    'sourceReportedChanceLowerBound', 'sourceKnowledgePointsPerOperation',
    'reportedPositiveOutcome', 'conditionalStackLowerBound', 'sourceReportedMaterialUnits',
    'sourceRefundFractionOfReportedInputBudget', 'sourceModeledReturnFractionPerResourcefulnessEvent',
    'sourceReturnFractionPerAcceptedResourcefulnessEvent', 'sourceNominalEventsPerInput',
    'sourceNominalEventsPerOperation',
}


class NotQueryable(ValueError):
    """A source fact has no truthful current item-tooltip representation."""


def finite(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value) and value >= 0


def item_ids(values):
    return sorted({x for x in values or [] if isinstance(x, int) and not isinstance(x, bool) and x > 0})


def _review_rows(research_root):
    path = Path(research_root) / CATALOGUE / 'processing-review.json'
    if not path.exists():
        return {}
    review = json.loads(path.read_text(encoding='utf-8'))
    return {r['locator']: r for source in review['sources'] for cohort in source['cohorts']
            for r in cohort['rowDecisions']}


def _source_rows(research_root, fact, cache):
    rows = []
    for ref in fact.get('sourceRows', []):
        filename = ref.get('sourceFile')
        if filename not in cache:
            path = Path(research_root) / filename
            cache[filename] = [json.loads(line) if line.strip() else None for line in path.read_text(encoding='utf-8').splitlines()]
        index = ref.get('line', 0) - 1
        if not 0 <= index < len(cache[filename]):
            raise ValueError('Source reference has no physical row: ' + str(ref))
        row = cache[filename][index]
        if not row or row.get('id') != ref.get('sourceRecordID'):
            raise ValueError('Source reference ID differs from physical row: ' + str(ref))
        rows.append(row)
    return rows


def _identity_name(identity):
    return identity.get('nativeName') or identity.get('sourceName')


def _output(fact, identity=None, ids=None, name=None, rank=None):
    identity = identity or fact.get('details', {}).get('outputIdentity') or fact.get('consumerOutputIdentity', {})
    ids = item_ids(ids if ids is not None else fact.get('outputItemIDs') or identity.get('itemIDs') or [fact.get('outputItemID')])
    for key in ('outputItemID', 'outputName', 'outputRank'):
        fact.pop(key, None)
    fact['outputItemIDs'] = ids
    if len(ids) == 1:
        fact['outputItemID'] = ids[0]
    text = name or _identity_name(identity)
    if text:
        fact['outputName'] = text
    if len(ids) > 1:
        # The family total is not one observed count for each rank/species.
        fact['referenceConditions']['outputIdentity'] = 'Pooled source family; output ranks/species are not individually allocated'
        if not text:
            raise NotQueryable('Verified output pool has no source-backed family name; selecting one item would invent the allocation.')
    if not ids and not text:
        raise NotQueryable('No verified numeric output identity or source-backed output name for the item-tooltip fact.')
    if rank is not None:
        if not isinstance(rank, int) or not 1 <= rank <= 5:
            raise NotQueryable('Reported output quality rank is outside the consumer rank contract.')
        fact['outputRank'] = rank
    return fact


def _base(original, raw_rows):
    fact = deepcopy(original)
    detail = fact.get('details', {})
    ids = item_ids(fact.get('inputItemIDs') or [fact.get('inputItemID')])
    if not ids:
        raise NotQueryable('The reviewed source lacks an exact verified processing input or enumerated native input family; era/method alone cannot select a current item tooltip.')
    fact.pop('inputItemID', None)
    fact.pop('inputFamilyIDs', None)
    if len(ids) == 1:
        fact['inputItemID'] = ids[0]
    else:
        fact['inputFamilyIDs'] = ids
    provider = fact.get('sourceKey')
    fact['sourceKey'] = 'itemdb'
    fact['reviewedSourceKey'] = provider
    fact['sourceStudyKey'] = fact.get('sourceStudyKey') or detail.get('sourceStudyKey') or provider
    source = (raw_rows[0].get('source') or {}) if raw_rows else {}
    if source.get('url'):
        fact['sourceURL'] = source['url']
    profile = deepcopy(fact.get('sourceConditions') or detail.get('sourceProfile', {}).get('raw') or {})
    if source.get('published'):
        profile['published'] = source['published']
    fact['sourceProfile'] = profile
    conditions = deepcopy(fact.get('referenceConditions') or {})
    if len(ids) > 1:
        conditions['inputScope'] = 'Source pooled/unknown-rank input family; informational source context, not a per-item measured allocation'
    source_profile = detail.get('sourceProfile', {})
    if source_profile.get('normalizationConstraint'):
        conditions['profileBasis'] = source_profile['normalizationConstraint']
    if detail.get('sourceNotes'):
        # Retain full notes below; keep the visible source context concise.
        fact['sourceNotes'] = detail['sourceNotes']
    if detail.get('sourceQuantityBasis'):
        conditions['quantityBasis'] = detail['sourceQuantityBasis']
    fact.update(referenceConditions=conditions, confidence0to100=0,
                sourceSupportConfidence=min(20, original.get('sourceSupportConfidence', 0)),
                sourceContextOnly=True, targetProfileAdjusted=False,
                economicPolicy='informational-source-reference', observedSamplesAdded=0)
    fact['originalMetric'] = original['metric']
    for key in ('value', 'lower', 'upper'):
        fact.pop(key, None)
    return fact


def _scalar(fact, metric, value, unit):
    if not finite(value):
        raise NotQueryable('The reviewed field has no finite nonnegative scalar in the claimed source unit.')
    fact.update(metric=metric, value=value, unit=unit)
    return fact


def _range(fact, metric, values, unit):
    if not isinstance(values, (list, tuple)) or len(values) != 2 or not all(finite(v) for v in values) or values[0] > values[1]:
        raise NotQueryable('The reviewed field has no ordered finite source bounds in a compatible unit.')
    fact.update(metric=metric, lower=values[0], upper=values[1], unit=unit)
    return fact


def _mean(fact, value, unit, detail):
    per_input = unit in {'input', 'material units per input', 'gross-input', 'net-input'}
    per_operation = unit in {'cast', 'operation', 'material units per source operation'}
    if not per_input and not per_operation:
        raise NotQueryable('The source quantity unit cannot be identified as input or source operation without a new denominator assumption.')
    target_unit = 'net-input' if detail.get('sourceQuantityBasis') == 'net-input' else 'input' if per_input else 'operation'
    return _scalar(fact, 'sourceProfileMeanUnitsPerInput' if per_input else 'sourceProfileMeanUnitsPerOperation', value, target_unit)


def _translate(original, raw_rows, review_rows):
    metric = original['metric']
    if metric in SUPPORTED and original.get('sourceKey') == 'itemdb':
        return [deepcopy(original)]
    if metric == 'supersededUnitTranscription':
        raise NotQueryable('This numerical transcription was explicitly superseded by the reviewed unit correction; displaying its old value would restore the rejected factor-of-ten quantity.')
    fact = _base(original, raw_rows)
    first = (original.get('sourceRows') or [{}])[0]
    first_locator = str(first.get('sourceFile')) + ':' + str(first.get('line'))
    fact['consumerOutputIdentity'] = deepcopy(review_rows.get(first_locator, {}).get('outputIdentity', {}))
    detail = fact.get('details', {})
    field = detail.get('sourceField', {})
    original_value = original.get('value')
    if metric == 'resourcefulnessReturnMagnitude':
        ids = item_ids(original.get('inputItemIDs') or [original.get('inputItemID')])
        # Saved ore is the original input, not the first gem in the source row.
        name = (raw_rows[0].get('inputName') if raw_rows else None) or 'Returned source input'
        _output(fact, {}, ids, name=name)
        if finite(detail.get('observedReturnedInputFraction')):
            _scalar(fact, 'sourceRefundFractionOfReportedInputBudget', detail['observedReturnedInputFraction'],
                    'returned-input-per-nominal-input')
            fact['referenceConditions']['refundBudget'] = str(detail['sourceReturnedInputUnits']) + ' returned input units / ' + str(detail['sourceNominalInputs']) + ' source nominal input units'
            child = deepcopy(fact)
            _scalar(child, 'sourceModeledReturnFractionPerResourcefulnessEvent', detail.get('conditionalSavedFractionModel'),
                    'modeled-returned-input-fraction-per-resourcefulness-event')
            child['referenceConditions']['coefficientBasis'] = 'Modeled conditional return fraction using stable displayed Resourcefulness ' + str(detail.get('sourceResourcefulnessPercent')) + '%; not an observed proc probability or proc denominator'
            return [fact, child]
        _scalar(fact, 'sourceReturnFractionPerAcceptedResourcefulnessEvent', detail.get('returnFractionPerAcceptedResourcefulnessProc'),
                'returned-input-fraction-per-accepted-resourcefulness-event')
        fact['referenceConditions']['coefficientBasis'] = detail.get('formula', '') + '; accepted produced-output records only, not all attempts; no Resourcefulness occurrence probability inferred'
        return [fact]
    if metric == 'sourceNominalEventIntensity' or field.get('decision') == 'RETAIN_MODELED_NOMINAL_EVENT_RATE':
        _output(fact)
        if metric == 'sourceNominalEventIntensity':
            _scalar(fact, 'sourceNominalEventsPerInput', detail.get('eventsPerModeledInput'), 'events-per-modeled-input')
        else:
            _scalar(fact, 'sourceNominalEventsPerOperation', field.get('value'), 'events-per-modeled-operation')
        fact['referenceConditions']['nominalBudget'] = (detail.get('formula') or field.get('formula') or '') + '; full20-herb-stack assumption, no observed all-attempt cast denominator; not a measured probability'
        return [fact]
    if metric == 'qualityUnitShare':
        result = []
        for rank_units in detail.get('reportedRankUnits', []):
            rank = rank_units.get('rank')
            share = detail.get('unitShares', {}).get(str(rank))
            row = review_rows.get(rank_units.get('sourceLocator'), {})
            identity = row.get('outputIdentity', {})
            if not identity.get('itemIDs') and not _identity_name(identity):
                raise NotQueryable('A reported quality share lacks the reviewed rank-specific output identity; do not assign all rank shares to the first source row item.')
            child = deepcopy(fact)
            _scalar(child, 'rankUnitShare', share, 'source-material-unit-fraction')
            if share > 1:
                raise NotQueryable('Reported quality share exceeds one.')
            _output(child, identity, identity.get('itemIDs', []), rank=rank)
            child['referenceConditions']['shareBasis'] = 'Reported units of this rank / reported units in this source material family; not probability per operation'
            result.append(child)
        if not result:
            raise NotQueryable('Quality composition contains no reported rank-unit rows.')
        return result
    if metric == 'sourceOutputComposition':
        result = []
        if finite(detail.get('reportedOutputUnitShare')):
            _output(fact)
            _scalar(fact, 'rankUnitShare', detail['reportedOutputUnitShare'], 'source-material-unit-fraction')
            if fact['value'] > 1:
                raise NotQueryable('Reported output-unit share exceeds one.')
            fact['referenceConditions']['shareBasis'] = 'Reported source colour/material-unit share; physical unit denominator unspecified; not probability per operation'
            return [fact]
        for outcome in detail.get('outcomes', []):
            row = review_rows.get(outcome.get('sourceLocator'), {})
            identity = row.get('outputIdentity', {})
            child = deepcopy(fact)
            _scalar(child, 'rankUnitShare', outcome.get('share'), 'source-material-unit-fraction')
            if child['value'] > 1:
                raise NotQueryable('Reported output-unit share exceeds one.')
            rank = identity.get('sourceRank') or identity.get('nativeRank')
            _output(child, identity, outcome.get('itemIDs'), name=_identity_name(identity), rank=rank)
            child['referenceConditions']['shareBasis'] = 'Reported units of this output / reported source output-pool units; not probability per operation'
            result.append(child)
        if not result:
            raise NotQueryable('Output composition contains no reported outcomes.')
        return result
    _output(fact)
    if metric in {'knownInvestedSourceMean', 'sourceOperationMean', 'sourceReportedMean', 'sourceQuantityContext'}:
        value = original_value if finite(original_value) else detail.get('value')
        unit = detail.get('quantity', {}).get('unit', detail.get('unit', original['unit']))
        band = detail.get('sourceReportedQuantityBandPerInput')
        if band:
            _range(fact, 'sourceProfileMeanUnitsPerInputRange', band, 'input')
        else:
            _mean(fact, value, unit, detail)
        if detail.get('admissionDecision') == 'RETAIN_SELECTED_BATCH_RATIO_CONTEXT_ONLY':
            fact['referenceConditions']['selection'] = 'Selected high-output source batch; quantity ratio describes that batch only'
        elif detail.get('admissionDecision') == 'USE_HISTORICAL_COMPOSITION_CALIBRATION':
            fact['referenceConditions']['epoch'] = 'Historical source quantity; source post-change transfer is not asserted'
    elif metric == 'sourceCompleteAbsence':
        _mean(fact, 0, detail.get('quantity', {}).get('unit'), detail)
        fact['referenceConditions']['absence'] = 'No reported units in this finite source input budget; unlock eligibility and zero target probability are not inferred'
    elif metric == 'reportedExpectedQuantity':
        _mean(fact, original_value, field.get('unit'), detail)
        fact['referenceConditions']['absence'] = field.get('reason', 'Conditional source zero; target unlock eligibility is not asserted')
    elif metric == 'reportedDropChance':
        _scalar(fact, 'sourceOccurrenceFraction', original_value, 'source-occurrence-fraction')
        if fact['value'] > 1:
            raise NotQueryable('Source occurrence fraction exceeds one.')
        fact['referenceConditions']['occurrenceBasis'] = 'Reported source event frequency / reference assertion in its original source conditions'
        if field.get('reportedCasts') is not None:
            fact['referenceConditions']['reportedEvents'] = str(field.get('hits')) + '/' + str(field['reportedCasts'])
        elif field.get('decision') == 'USE_REFERENCE_PROBABILITY_ONLY':
            fact['referenceConditions']['sourceRole'] = 'Source probability reference; not new independently measured casts'
    elif metric == 'reportedConditionalYieldRange':
        _range(fact, 'conditionalStackRange', [field.get('minimum'), field.get('maximum')], 'positive-material-event')
        if fact['lower'] <= 0:
            raise NotQueryable('A zero-inclusive observed operation range cannot be labeled a positive-result range without positive-event bin evidence.')
        fact['referenceConditions']['rangeBasis'] = 'Reported positive-source-result bounds, not guaranteed outcomes or target bounds'
    elif metric == 'reportedHistogram':
        bins = field.get('sourceBins', {})
        positive = [(float(n), count) for n, count in bins.items() if finite(float(n)) and float(n) > 0 and finite(count) and count > 0]
        if not positive:
            if bins and all(float(n) == 0 for n in bins):
                _scalar(fact, 'sourceReportedMaterialUnits', 0, 'source-material-units')
                fact['referenceConditions']['histogram'] = 'Only zero-output source bins were reported; no positive-event mean exists'
            else:
                raise NotQueryable('The retained histogram has no finite positive-result bins from which to describe a conditional quantity.')
        else:
            value = sum(n * count for n, count in positive) / sum(count for _, count in positive)
            _scalar(fact, 'conditionalMeanUnitsPerPositiveEvent', value, 'positive-material-event')
            fact['referenceConditions']['histogramBasis'] = 'Weighted reported positive bins only; zero bins omitted from this conditional mean; original bins remain retained'
    elif metric == 'mixedInputScenarioQuantity':
        _range(fact, 'sourceProfileMeanUnitsPerInputRange', detail.get('quantityRangePerInput'), 'input')
        fact['referenceConditions']['quantityBasis'] = 'Pooled mixed-input source budget interval; not an independently measured mean for each selected input'
    elif metric == 'conditionalAcceptedQuantity':
        _scalar(fact, 'sourceProfileMeanUnitsPerOperation', detail.get('conditionalUnitsPerAcceptedRun'), 'operation')
        fact['referenceConditions']['selection'] = 'Per accepted produced-output source operation; recorder omits no-output attempts. Not an all-attempt mean or a positive-event mean for each particular output'
    elif metric == 'unnamedSourceRangeScenario':
        raise NotQueryable('The scenario lacks an attributable input/output identity or a supported denominator for the quoted source range; retain its original interval rather than invent a per-item lookup.')
    else:
        raise NotQueryable('No reviewed dimensional translation is defined for source metric ' + metric + '.')
    return [fact]


def normalize_processing_facts(policy, research_root, code_root=None):
    """Return an independent normalized policy and exhaustive source-fact receipt."""
    result = deepcopy(policy)
    review_rows = _review_rows(research_root)
    raw_cache = {}
    emitted = []
    decisions = []
    seen = set()
    for original in policy.get('facts', []):
        fact_id = original['factID']
        if fact_id in seen:
            raise ValueError('Duplicate input fact ID: ' + fact_id)
        seen.add(fact_id)
        try:
            translated = _translate(original, _source_rows(research_root, original, raw_cache), review_rows)
            for index, child in enumerate(translated):
                if index:
                    identity = [child.get('outputItemID'), child.get('outputItemIDs'), child.get('outputName'), child.get('outputRank'), child['metric']]
                    suffix = hashlib.sha256(json.dumps(identity, sort_keys=True).encode()).hexdigest()[:12]
                    child['factID'] = fact_id + ':' + suffix
                    # The original fact retains the complete reviewed proposal.
                    # Derived shares point to it instead of copying a large
                    # whole-cohort table into every output/quality row.
                    child['details'] = {'originalFactID': fact_id,
                                        'proposalID': original.get('details', {}).get('proposalID'),
                                        'originalMetric': original['metric']}
                    child.pop('sourceNotes', None)
                if child['factID'] in {x['factID'] for x in emitted}:
                    raise ValueError('Derived output fact ID collision: ' + child['factID'])
                emitted.append(child)
            decisions.append({'originalFactID': fact_id, 'originalMetric': original['metric'],
                'proposalID': original.get('details', {}).get('proposalID'),
                'decision': 'QUERYABLE_SOURCE_FACT', 'factIDs': [f['factID'] for f in translated],
                'sourceRows': deepcopy(original.get('sourceRows', [])),
                'reason': 'Dimensioned original source context translated to the supported informational consumer; no EV, access, new samples or target-profile transform.'})
        except NotQueryable as exc:
            decisions.append({'originalFactID': fact_id, 'originalMetric': original['metric'],
                'proposalID': original.get('details', {}).get('proposalID'),
                'decision': 'REJECTED_CURRENT_LOOKUP', 'factIDs': [], 'reason': str(exc),
                'futureEvidenceTrigger': 'Exact verified source input/output lookup identity and compatible source-unit consumer, or a source clarification identifying the missing denominator/scope; reopens this field only.',
                'sourceRows': deepcopy(original.get('sourceRows', [])), 'retainedSourceFact': deepcopy(original)})
    result['facts'] = sorted(emitted, key=lambda f: f['factID'])
    report = {'schemaVersion': 1, 'policy': 'Source-only adapter; original facts/rejections retain raw/effective proofs. No priced models, source rows or measured samples changed.',
        'inputFacts': len(policy.get('facts', [])), 'outputFacts': len(emitted),
        'queryableOriginalFacts': sum(d['decision'] == 'QUERYABLE_SOURCE_FACT' for d in decisions),
        'rejectedOriginalFacts': sum(d['decision'] == 'REJECTED_CURRENT_LOOKUP' for d in decisions),
        'inputMetrics': dict(Counter(f['metric'] for f in policy.get('facts', []))),
        'outputMetrics': dict(Counter(f['metric'] for f in emitted)), 'decisions': decisions,
        'observedSamplesAdded': 0, 'pricedModelsChanged': result.get('models', []) != policy.get('models', [])}
    assert report['inputFacts'] == report['queryableOriginalFacts'] + report['rejectedOriginalFacts']
    assert not report['pricedModelsChanged']
    return result, report


def normalize_processing_dispositions(receipt, report):
    """Resolve every legacy fact reference to actual consumer facts or rejection."""
    result = deepcopy(receipt)
    by_id = {d['originalFactID']: d for d in report['decisions']}
    for decision in result.get('decisions', []):
        original_ids = decision.get('factIDs', [])
        translated = []
        rejected = []
        for fid in original_ids:
            if fid not in by_id:
                raise ValueError('Disposition references unaccounted processing fact: ' + fid)
            row = by_id[fid]
            translated.extend(row['factIDs'])
            if row['decision'] == 'REJECTED_CURRENT_LOOKUP':
                rejected.append({key: deepcopy(row[key]) for key in ('originalFactID', 'reason', 'futureEvidenceTrigger', 'sourceRows')})
        decision['factIDs'] = sorted(set(translated))
        if rejected:
            decision['sourceFactLookupRejections'] = rejected
            if not translated and not decision.get('modelIDs') and not decision.get('compiledRecordIDs'):
                decision.update(status='REJECTED_CURRENT_NUMERICAL_USE', decision='REJECTED_CURRENT_NUMERICAL',
                                reason=' '.join(d['reason'] for d in rejected),
                                futureEvidenceTrigger=rejected[0]['futureEvidenceTrigger'])
    # Row field receipts are not another fact source; keep references consistent.
    for decision in result.get('fieldDecisions', []):
        rejected = [by_id[fid] for fid in decision.get('factIDs', []) if by_id[fid]['decision'] == 'REJECTED_CURRENT_LOOKUP']
        decision['factIDs'] = sorted({new for fid in decision.get('factIDs', []) for new in by_id[fid]['factIDs']})
        if rejected and not decision['factIDs']:
            decision.update(decision='REJECTED_CURRENT_NUMERICAL', reason=rejected[0]['reason'],
                            futureEvidenceTrigger=rejected[0]['futureEvidenceTrigger'])
    coverage = result.setdefault('coverage', {})
    coverage.update(facts=report['outputFacts'], sourceFactOriginalContexts=report['inputFacts'],
                    sourceFactCurrentLookupRejections=report['rejectedOriginalFacts'])
    coverage['statuses'] = dict(Counter(d['status'] for d in result.get('decisions', [])))
    result['sourceFactConsumerTranslation'] = {key: value for key, value in report.items() if key != 'decisions'}
    return result


def _native_lua_command():
    """Find a working Lua5.1 CLI, without imposing a Python dependency on CI."""
    candidates = [os.environ.get('LUA_BIN')]
    candidates.extend(shutil.which(name) for name in ('lua5.1', 'lua51', 'lua'))
    candidates.append('/workspace/.loot-liquidator-tools/lua/usr/bin/lua5.1')
    seen = set()
    for candidate in candidates:
        if not candidate or candidate in seen:
            continue
        seen.add(candidate)
        try:
            probe = subprocess.run([candidate, '-e', "assert(_VERSION=='Lua 5.1');io.write('Lua51')"],
                                   capture_output=True, text=True, encoding='utf-8', timeout=10)
        except (OSError, subprocess.TimeoutExpired):
            continue
        if probe.returncode == 0 and probe.stdout == 'Lua51':
            return [candidate]
    return None


# A deliberately small result serializer, shared by both actual Lua backends.
# Empty result tables are arrays: the consumer audit's failures={} means [].
_LUA_RESULT_JSON = r'''
local function quoted(value)
    return '"'..value:gsub('[%z\1-\31\\"]',function(c)
        if c=='"' then return '\\"' end
        if c=='\\' then return '\\\\' end
        return ('\\u%04x'):format(c:byte())
    end)..'"'
end
local function encode(value)
    local kind=type(value)
    if kind=='nil' then return 'null' end
    if kind=='boolean' then return value and 'true' or 'false' end
    if kind=='number' then
        assert(value==value and math.abs(value)<math.huge,'Nonfinite Lua result')
        return ('%.17g'):format(value)
    end
    if kind=='string' then return quoted(value) end
    assert(kind=='table','Unsupported Lua result type '..kind)
    local count,sequence=0,true
    for key in pairs(value)do
        count=count+1
        if type(key)~='number' or key%1~=0 or key<1 or key>#value then sequence=false end
    end
    local out={}
    if sequence and count==#value then
        for _,child in ipairs(value)do out[#out+1]=encode(child) end
        return '['..table.concat(out,',')..']'
    end
    local keys={} for key in pairs(value)do keys[#keys+1]=key end
    table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
    for _,key in ipairs(keys)do out[#out+1]=quoted(tostring(key))..':'..encode(value[key]) end
    return '{'..table.concat(out,',')..'}'
end
'''


def execute_processing_lua(body, code_root):
    """Execute one assertion body with native Lua5.1, falling back to Lupa.

    The body returns a JSON-compatible Lua result table. Both backends execute
    precisely the same body, serializer and Lua5.1-version assertion.
    """
    code_root = Path(code_root)
    script = "assert(_VERSION=='Lua 5.1','Lua5.1 is required')\nlocal function operation()\n" + body + '\nend\n' + _LUA_RESULT_JSON
    command = _native_lua_command()
    if command:
        marker = '__LL_PROCESSING_RESULT__'
        with tempfile.TemporaryDirectory(prefix='ll-processing-facts-') as temporary:
            path = Path(temporary) / 'assertions.lua'
            path.write_text(script + '\nio.write(' + json.dumps(marker) + '..encode(operation()).."\\n")\n',
                            encoding='utf-8', newline='\n')
            completed = subprocess.run([*command, str(path)], cwd=code_root, capture_output=True,
                                       text=True, encoding='utf-8', timeout=180)
        if completed.returncode:
            raise AssertionError('Lua5.1 processing assertions failed:\n' + completed.stdout + completed.stderr)
        payload = next((line[len(marker):] for line in completed.stdout.splitlines() if line.startswith(marker)), None)
        if payload is None:
            raise AssertionError('Lua5.1 processing assertions produced no result:\n' + completed.stdout + completed.stderr)
    else:
        import sys
        sys.path.insert(0, str(code_root.parent / '.tools/python313'))
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError as exc:
            raise RuntimeError('A native Lua5.1 executable or the existing local Lupa runtime is required; no test was skipped.') from exc
        payload = LuaRuntime(unpack_returned_tuples=True).execute(script + '\nreturn encode(operation())')
    return json.loads(payload)


def verify_processing_fact_consumer(policy, code_root):
    """Execute the shipped public Lua query/renderer for literal emitted facts.

    This is a compatibility check, not independent scientific source approval.
    The native audit reads each fact's own actual scope; no item identity is
    injected into the compiled source fact to make it pass.
    """
    code_root = Path(code_root)
    import research_v3_to_baselines as bridge
    module = code_root / 'LootLiquidator/ReviewedSourceFacts.lua'
    body = ('local LL={ItemDB={reviewedSourceFacts={schemaVersion=1,facts=' + bridge.lua(policy.get('facts', [])) + '}},db={}}\n'
            'function LL:EvidenceSourceWeight(source,mode) '
            'return mode~=2 and self.db.source_itemdb_enabled~=false and 1 or 0 end\n'
            'assert(loadfile(' + json.dumps(module.as_posix()) + '))("LootLiquidator",LL)\n'
            'local audit=assert(loadfile(' + json.dumps((code_root / 'tools/reviewed_source_fact_audit.lua').as_posix()) + '))()\n'
            'return audit(LL)')
    result = execute_processing_lua(body, code_root)
    return {'runtime': 'Lua5.1', 'literalFacts': len(policy.get('facts', [])),
            'queriedFacts': result['queriedFacts'], 'renderedFacts': result['renderedFacts'],
            'policyNegativeChecks': result['policyNegativeChecks'],
            'failures': result['failures'],
            'verificationType': 'ACTUAL_INFORMATIONAL_CONSUMER_COMPATIBILITY',
            'scientificApprovalClaimed': False, 'observedSamplesAdded': 0}
