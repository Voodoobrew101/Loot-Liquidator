"""Reproduce the bounded Aure/Lava/rbutera cutoff conditional-fact catalogue.

Existing immutable contributor bytes and raw/effective row proofs only. Native
positive events are not completed operations. No addon source is edited here.
"""
from collections import Counter, defaultdict
from hashlib import sha256, sha1
import argparse
import json
from pathlib import Path
import re
import sys

HERE = Path(__file__).resolve().parent
RESEARCH = HERE.parents[4]
RELATIVE = HERE.relative_to(RESEARCH)
CODE = RESEARCH.parent / 'catalogue-backlog-pipeline-20261120'
sys.path.insert(0, str(CODE / 'tools'))
from reviewed_source_catalogue import canonical_hash, source_rows
from research_v3_to_baselines import load_calculator
from research_v3_evidence import row_support

REVISION = 'reviewed-aure-lava-rbutera-cutoff/1'
PIN = '0cd0bad8867e7a8d909b4ecae74f6136a3e23d42'
FILES = [
    ('2026-11-20T1749-aure-original-classic-native-counters.jsonl', 'aure', 'EnchantedLocal', 859),
    ('2026-11-19T2142-aure-original-classic-raw-groups.jsonl', 'aure', 'EnchantedItemTypes', 28),
    ('2026-11-20T1538-lavasalesmans-original-enchantrix-positives.jsonl', 'lavasalesmans', 'EnchantedLocal', 678),
    ('2026-11-15T1643-original-classic-enchantrix-raw-hit-quantities.jsonl', 'lavasalesmans', 'EnchantedItemTypes', 17),
    ('2026-11-18T1845-zeropositive-classic-original-enchantrix.jsonl', 'rbutera', 'EnchantedLocal', 38),
]
ARCHIVES = {'aure': 'aure-cutoff-native-source.lua.txt',
            'lavasalesmans': 'aure-cutoff-native-lavasalesmans.lua.txt',
            'rbutera': 'aure-cutoff-native-rbutera.lua.txt'}
ORIGINALS = {
    'aure': 'https://github.com/alex-berliner/wow_classic_de_table/blob/5918ca3e44f6e4bba9071731ab28be3189498001/dbfiles/aure.lua',
    'lavasalesmans': 'https://github.com/alex-berliner/wow_classic_de_table/blob/5918ca3e44f6e4bba9071731ab28be3189498001/dbfiles/lavasalesmans_log.lua',
    'rbutera': 'https://github.com/rbutera/modernclassicmac/blob/b8871f80894a3df52467b0306d209db2dc0794a5/WTF/Account/ZEROPOSITIVE/SavedVariables/Enchantrix.lua',
}
PRIOR = {
    'aure': 'research/v3/evidence/master/20261119T2201-aure-enchantrix-group-unit-and-game-flavor-gate.md',
    'lavasalesmans': 'research/v3/evidence/master/20261120T1600-lavasalesmans-original-enchantrix-678-row-unit-identity-review.md',
    'rbutera': 'research/v3/evidence/master/20261118T1900-zeropositive-original-variant-positive-only-unit-gate.md',
}


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def dump(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2, allow_nan=False) + '\n'


def identity(prefix, values):
    return prefix + sha256(json.dumps(values, ensure_ascii=False, sort_keys=True).encode()).hexdigest()[:24]


def native_table(text, name):
    match = re.search(r'^' + name + r'\s*=\s*\{(.*?)^\}', text, re.M | re.S)
    assert match, 'Missing native table ' + name
    values = re.findall(r'\["([0-9:]+)"\]\s*=\s*"([0-9:;]+)"', match.group(1))
    assert len({key for key, _ in values}) == len(values)
    return {key: {int(parts[0]): tuple(map(int, parts)) for entry in encoded.split(';')
                  if (parts := entry.split(':'))} for key, encoded in values}


def build():
    calculator = load_calculator(RESEARCH)
    effective = {(r['_file'], r['id']): r for r in calculator.load_reviewed_source_rows()}
    archives, native, origins = {}, {}, {}
    for author, filename in ARCHIVES.items():
        path = HERE / filename
        data = path.read_bytes()
        text = data.decode('utf-8')
        archives[author] = {'archive': path.relative_to(RESEARCH).as_posix(),
            'archiveSHA256': sha256(data).hexdigest(), 'sourceURL': ORIGINALS[author],
            'originalCRLFBlobSHA1': sha1(b'blob ' + str(len(data.replace(b'\n', b'\r\n'))).encode()
                + b'\0' + data.replace(b'\n', b'\r\n')).hexdigest(),
            'archiveEncoding': 'UTF-8; original CRLF normalized to LF only',
            'priorReview': PRIOR[author]}
        native[author] = {name: native_table(text, name) for name in ('EnchantedLocal', 'EnchantedItemTypes')}
    assert archives['aure']['originalCRLFBlobSHA1'] == '62596d4deb2369132b948bd7199328039462f4aa'
    assert archives['lavasalesmans']['originalCRLFBlobSHA1'] == '480c1f5f5dad011f5626ea17e312210e56f4f5eb'
    sources, assignments = {}, {}
    proposals, facts, decisions, proofs = [], [], [], []
    seen, view_counts, native_used = set(), Counter(), defaultdict(set)
    unsupported_unconditional_fields = 0
    for filename, author, table, expected in FILES:
        file = Path('research/v3/evidence/legacy') / filename
        lines = (RESEARCH / file).read_text(encoding='utf-8-sig').splitlines()
        assert len(lines) == expected, filename
        for line, encoded in enumerate(lines, 1):
            raw = json.loads(encoded)
            locator = f'{file.as_posix()}:{line}'
            assert locator not in seen
            seen.add(locator)
            actual = effective.get((file.as_posix(), raw['id']))
            assert actual is not None, 'Missing current proof-stage row: ' + locator
            source_key = calculator.source_key(raw)
            source_url = raw.get('originalSource') or raw['source']['url']
            text = (raw.get('quote') or '') + '\n' + raw.get('notes', '')
            if table == 'EnchantedLocal':
                match = re.search(r'\["([0-9:]+)"\]', text) or re.search(r'input variant "([0-9:]+)"', text)
            else:
                match = re.search(r'\["([0-9:]+)"\]', text) or re.search(r'entry ([0-9:]+)', text)
            assert match, locator
            key = match.group(1)
            output = raw['outputItemID']
            values = native[author][table][key][output]
            assert len(values) == 4 and values[0] == output and values[1] == raw['castsWithDrop']
            assert values[2] == raw['totalQuantity'] and values[3] == 0
            assert values[1] > 0 and values[2] >= values[1]
            assert raw['casts'] is None and raw['histogram'] is None and raw['percentShown'] is None
            assert raw['minSeen'] is None and raw['maxSeen'] is None
            if table == 'EnchantedLocal':
                assert int(key.split(':')[0]) == raw['inputItemID']
            else:
                assert raw['inputItemID'] is None
            unsupported_unconditional_fields += len(row_support(calculator, actual, 1, 1, Counter()))
            ref = {'sourceFile': file.as_posix(), 'line': line, 'sourceRecordID': raw['id'],
                   'rawSHA256': canonical_hash(raw), 'effectiveSHA256': canonical_hash(actual)}
            checked, reason = source_rows(RESEARCH, [ref], effective)
            assert checked and not reason, (locator, reason)
            proof = dict(archives[author], table=table, key=key, tuple=':'.join(map(str, values)), result='EXACT_MATCH')
            native_used[(author, table)].add((key, output))
            view_counts[(author, table)] += 1
            proposal_id = identity('aure-cutoff:', [locator, 'conditionalMeanUnitsPerPositiveEvent'])
            cohort = f'native:{author}:{table}:{key}'
            value = values[2] / values[1]
            profile = {name: raw.get(name) for name in ('skill', 'specialization', 'stats', 'patch', 'dataDate')}
            proposal = {'proposalID': proposal_id, 'sourceKey': source_key, 'sourceURL': source_url,
                'studyKey': raw['studyKey'], 'canonicalCohortKey': cohort, 'recordID': raw['id'],
                'locator': locator, 'metric': 'conditionalMeanUnitsPerPositiveEvent', 'value': value,
                'arithmetic': f'{values[2]}/{values[1]}', 'unit': 'units-per-positive-material-event',
                'input': {'inputItemID': raw.get('inputItemID'), 'inputName': raw.get('inputName'),
                          'inputRank': None, 'gearGroup': raw.get('gearGroup')},
                'output': {'itemID': output, 'name': raw.get('outputName'), 'rank': raw.get('outputRank')},
                'sourceProfile': profile, 'nativeInputVariant': key if table == 'EnchantedLocal' else None,
                'nativeSourceGroup': key if table == 'EnchantedItemTypes' else None,
                'measuredCasts': None, 'sourcePositiveEvents': values[1], 'sourceMaterialUnits': values[2],
                'modelingConfidence': 0, 'sourceRecordKind': 'study', 'economicPolicy': 'source-context-only',
                'nativeSourceVerification': proof,
                'sourceFacts': {'quote': raw.get('quote'), 'notes': raw.get('notes')},
                'assumptions': [], 'constraints': ['Q/H is conditional on this material appearing; no EV or per-cast P follows.',
                    'The native trailing0 is not a zero-result observation.',
                    'Local and pooled group views share one contributor archive and are never independent sample weight.',
                    'Exact source flavor, epoch, historical skill and current variant equality remain unverified.']}
            proposals.append(proposal)
            unconditional = {'field': 'currentUnconditionalQuantityAndProbability', 'decision': 'CURRENT_NUMERICAL_REJECTION',
                'reason': f'Native {table}[{key}] output{output} contains{values[1]} material-positive events and{values[2]} units, not an all-operation ledger. No negatives, joint outcomes or independently verified exclusivity/completeness identify unconditional E or P. The valid Q/H quantity is retained separately.',
                'futureEvidenceTrigger': 'A complete exact-variant operation ledger including zeros and material attribution, with verified epoch/profile, or an independently supported compatible source probability.'}
            fact_ids = []
            if table == 'EnchantedLocal':
                fact_id = identity('source-fact:aure-cutoff:', [ORIGINALS[author], table, key, output, values[1], values[2]])
                fact = {'factID': fact_id, 'method': 'Disenchant', 'inputItemID': raw['inputItemID'],
                    'outputItemID': output, 'outputName': raw.get('outputName'),
                    'metric': 'conditionalMeanUnitsPerPositiveEvent', 'value': value, 'unit': 'positive-material-event',
                    'confidence0to100': 0, 'sourceSupportConfidence': 20, 'sourceKey': 'itemdb',
                    'sourceURL': source_url, 'sourceStudyKey': cohort, 'sourceProfile': profile,
                    'nativeInputVariant': key, 'sourceRows': [ref],
                    'reportedObservationCounts': {'measuredCasts': None, 'sourcePositiveEvents': values[1],
                                                   'sourceMaterialUnits': values[2]},
                    'referenceConditions': {'sourceEpoch': 'Historical contributor archive; exact client/flavor/date unverified',
                        'sourceVariantMatch': 'Source signature only; target variant/profile equality not asserted',
                        'nativeView': 'EnchantedLocal; overlaps same-archive pooled group counters'},
                    'sourceContextOnly': True, 'targetProfileAdjusted': False, 'economicPolicy': 'source-context-only',
                    'nativeSourceVerification': proof, 'proposalIDs': [proposal_id]}
                facts.append(fact)
                fact_ids = [fact_id]
                decision = 'SOURCE_FACT'
                current_reason = 'Exact source-native variant and output identity support Q/H as an informational conditional quantity; no all-operation EV, P, price or current eligibility is granted.'
            else:
                decision = 'REJECTED_CURRENT_NUMERICAL'
                current_reason = f'Historical group{key} has a known conditional Q/H={values[2]}/{values[1]}, but no exact input IDs, verified source client/flavor/era or historical-to-current level/category join. Setting expansion0 or matching modern item levels would invent lookup applicability. Keep the dimensioned quantity in this source receipt; no truthful current in-game matcher exists.'
            disposition = {'proposalID': proposal_id, 'decision': decision, 'factIDs': fact_ids, 'modelIDs': [],
                'sourceKey': source_key, 'sourceStudyKey': cohort, 'locator': locator, 'metric': proposal['metric'],
                'reason': current_reason, 'receiptPath': (RELATIVE / 'aure-cutoff-addendum-review.json').as_posix(),
                'futureEvidenceTrigger': 'Verified exact source flavor/era and historical group-to-item/category mapping; no fabricated operation denominator is requested.' if table == 'EnchantedItemTypes' else unconditional['futureEvidenceTrigger']}
            decisions.append(disposition)
            row_review = {'locator': locator, 'recordID': raw['id'], 'rawSHA256': ref['rawSHA256'],
                'effectiveSHA256': ref['effectiveSHA256'], 'sourceEvidenceExamined': True,
                'disposition': 'CATALOGUED_CONDITIONAL_QUANTITY' if fact_ids else 'CURRENT_NUMERICAL_REJECTION',
                'proposalRefs': [proposal_id], 'sourceFacts': dict(proposal['sourceFacts'], casts=None,
                    castsWithDrop=values[1], totalQuantity=values[2], conditionalMean=value, nativeKey=key),
                'nativeSourceVerification': proof, 'currentCorrections': [],
                'fieldRejections': [unconditional], 'scopeNotes': [current_reason]}
            if not fact_ids:
                row_review['fieldRejections'].append({'field': 'currentConditionalQuantityLookup',
                    'decision': 'CURRENT_NUMERICAL_REJECTION', 'reason': current_reason,
                    'futureEvidenceTrigger': disposition['futureEvidenceTrigger']})
            source = sources.setdefault(source_key, {'sourceKey': source_key, 'rawURLs': [],
                'decision': 'REVIEWED_ALL_ASSIGNED_SCOPES', 'coveredLocators': [], 'cohorts': [],
                'priorReviewFacts': [dict(path=PRIOR[author], sha256=sha256((RESEARCH / PRIOR[author]).read_bytes()).hexdigest(),
                    reusedFacts='Native positive-counter units, absent all-operation N, reserved trailing0 and overlapping storage views remain valid.')],
                'originFamily': ORIGINALS[author], 'independentContributorSource': author})
            if source_url not in source['rawURLs']:
                source['rawURLs'].append(source_url)
            source['coveredLocators'].append(locator)
            cohorts = {c['studyKey']: c for c in source['cohorts']}
            if cohort not in cohorts:
                source['cohorts'].append({'studyKey': cohort, 'decision': 'REVIEWED_ALL_ASSIGNED_FIELDS',
                    'coveredLocators': [], 'rowDecisions': []})
                cohorts[cohort] = source['cohorts'][-1]
            cohorts[cohort]['coveredLocators'].append(locator)
            cohorts[cohort]['rowDecisions'].append(row_review)
            assignment = assignments.setdefault(source_key, {'sourceKey': source_key, 'sourceURLs': [], 'candidateRows': []})
            if source_url not in assignment['sourceURLs']:
                assignment['sourceURLs'].append(source_url)
            assignment['candidateRows'].append(dict(ref, locator=locator, recordID=raw['id'], method='Disenchant',
                sourceURL=source_url, studyKey=raw['studyKey'], disposition='CURRENT_CUTOFF_CONDITIONAL_SOURCE_REVIEW',
                originalEvidenceRow=raw, effectiveEvidenceRow={k: v for k, v in actual.items() if not k.startswith('_')}))
            proofs.append({'locator': locator, **proof, 'sourceRef': ref})
    assert len(seen) == len(proposals) == len(decisions) == 1620
    assert len(facts) == len({f['factID'] for f in facts}) == 1575
    assert unsupported_unconditional_fields == 0
    for author in ARCHIVES:
        full = {(key, output) for key, values in native[author]['EnchantedLocal'].items() for output in values}
        assert native_used[(author, 'EnchantedLocal')] == full, 'Local native set not completely accounted: ' + author
    summary = {'physicalRowsReviewed': 1620, 'sourceKeys': len(sources), 'originalContributorArchives': 3,
        'nativeTupleMatches': 1620, 'exactInputConditionalFacts': 1575, 'historicalGroupLookupRejections': 45,
        'models': 0, 'proposals': 1620, 'terminalDecisions': 1620, 'coverageMissing': [],
        'coverageExtra': [], 'duplicateLocators': 0, 'observedSamplesAdded': 0,
        'unconditionalOldProducerSupportedFields': unsupported_unconditional_fields,
        'byView': {f'{author}:{table}': count for (author, table), count in sorted(view_counts.items())},
        'completeLocalVariantCounts': {author: len(native[author]['EnchantedLocal']) for author in ARCHIVES}}
    common = {'schemaVersion': 1, 'lane': 'aure_lavasalesmans_rbutera_cutoff_addendum',
        'revision': REVISION, 'researchSnapshot': PIN, 'reviewer': 'controlled_study_design', 'summary': summary}
    outputs = {
        'aure-cutoff-addendum-review.json': dict(common, sources=list(sources.values())),
        'aure-cutoff-addendum-proposals.json': dict(common, proposals=proposals),
        'aure-cutoff-addendum-admitted-models.json': dict(common, models=[], facts=facts, sourceFieldExclusions=[]),
        'aure-cutoff-addendum-proposal-dispositions.json': dict(common, decisions=decisions),
        'aure-cutoff-addendum-proof.json': dict(common, archives=archives, nativeTupleProofs=proofs,
            storageViewPolicy='One contributor archive has local and pooled views. No sum of their positive counts becomes independent operations, and identical small tuples across contributors are not duplicate proof.'),
    }
    assignment = {'researchSnapshot': PIN, 'lane': common['lane'], 'summary': summary, 'sources': list(assignments.values())}
    return outputs, assignment


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    outputs, assignment = build()
    targets = {HERE / name: value for name, value in outputs.items()}
    targets[RESEARCH.parent / '.validation/backlog-closure-20261120/inputs/aure-cutoff-addendum.json'] = assignment
    for path, value in targets.items():
        text = dump(value)
        if args.check:
            assert path.exists() and path.read_text(encoding='utf-8') == text, 'Stale Aure cutoff artifact: ' + str(path)
        else:
            path.write_text(text, encoding='utf-8', newline='\n')
    print(json.dumps(assignment['summary'], sort_keys=True))
