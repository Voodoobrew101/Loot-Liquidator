#!/usr/bin/env python3
"""Audit preserved skill-82 Disenchant cohorts without changing any source or rate.

The immutable v3 fixture is a claim to verify, not production admission. Run from
any directory; optional --output writes a detailed JSON report to the given path.
"""
import argparse
import collections
import hashlib
import importlib.util
import json
import sys
from pathlib import Path
sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
from validate_craft_export import validate, compile_baselines
from capture_observations import compile_observations
from recycling_capture_baselines import compile_capture
DEFAULT_ROOT = Path(__file__).resolve().parents[1]
FIXTURE_PATH = Path('tests/fixtures/skill82-cohort-audit/2026-11-09T1518-evercore-shade-skill82-104-source-cohorts.jsonl')
MAIN = 'b6610848604f68f8f3b40834397b79ce53eb8fb5'
RESEARCH = '71a9b43462111b670bafefe09e2d3f0f180215a1'
REVIEW_PINS = {'intake-review.json': '1e008d6ba49079713abc2a884c064384e67cb3d5da8190333fe9d1f67c5fd526', 'complete-batch-review.json': '325db7959e58ad2d55799c76dc4a4c3b66ae79d4d8e2421bf589a47e53f5ebb7', 'reviewed-comparison.json': 'a1a2ce8fc3740bc7d987630578c32a4a8100144a46db6a5f6221582fd60928fa'}
EVIDENCE_HASH = '6ab826fa602c16e20970c3f6b885426ba8d520d98dd176af3ebfd1b71f901c6a'
PINS = {'82-skill-194-update': 'd1d5cbd46abc1a2a278914e800a5f21b7c07b1dc5571c106f5918ecdf2108afb', '82-skill-200-additional': '942efe015f5770bda444090279f97cb307590b6f84699f09720c56229c48fe9d', '82-skill-97-clean': '906b3466e2ad119b5fa0317d89be9d287e73db52c2051be2f8a79ca3495b9633', 'rod-transition': 'aa9a3dd7fa0035a7579aa41de8437472cee8a57a3db6b02341b10b756ff0be11', '104-skill-199-casts': 'de62ae600c5de44d5c7d30e572ad1d900693091b85e0f25d306de48481b51b65'}

MEMBERSHIP_PINS={'82-skill-194-update': '93fd27bdd7408027bdd45e6a899309b9cc64b81401da6b8a378ce1b601967abe', '82-skill-200-additional': '9b642e7abb4e27c87787ab00590cbab5f9a6c21b86ad12ef7522e5b4412c3dac', '82-skill-97-clean': '52b0f6542689c7230d6c45549d64cc12c977970fb5ee38db75deeb39007392e4', 'rod-transition': 'c1c7214c167eccb81e1fe094b7646f824f56717cd1060b336a152ea0adc1ee5f', '104-skill-199-casts': '36280f4f47773417496b785b0d73c540b17db7ab3eaf6102a00893f45eb06967'}
CONTEXT_PINS={'82-skill-194-update': 'a0e9b758dbbf973bc69ba147f0e1df4203b4575ea88e3c749592766ecb2477bb', '82-skill-200-additional': 'a0e9b758dbbf973bc69ba147f0e1df4203b4575ea88e3c749592766ecb2477bb', '82-skill-97-clean': 'a0e9b758dbbf973bc69ba147f0e1df4203b4575ea88e3c749592766ecb2477bb', 'rod-transition': '22a3f8d47b0b69975bb9b49fdb20fe35ffff43b22823397b32ff183bc968b60c', '104-skill-199-casts': 'efc0e16700cf581653c603b8ec1855c8b20d7b27844f93e72f7ea9037da47246'}

def semantic_digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode()).hexdigest()

def require(condition, message):
    if not condition:
        raise ValueError(message)

def audit(main=DEFAULT_ROOT, fixture=None):
    """Return a source-bound audit; fail on changed or inconsistent evidence."""
    main = Path(main).resolve()
    fixture = Path(fixture) if fixture else main / FIXTURE_PATH
    root = main / 'research/integration/measured-captures'
    bundle = {}
    for suffix, digest in PINS.items():
        p = root / ('2026-11-07-pr49-' + suffix)
        raw = (p / 'export-page-1.json').read_bytes()
        require(hashlib.sha256(raw).hexdigest() == digest, 'Raw source hash: ' + suffix)
        bundle[suffix] = {'raw': json.loads(raw), 'staged': json.loads((p / 'staged-baselines.json').read_text()), 'files': {f.name: hashlib.sha256(f.read_bytes()).hexdigest() for f in p.iterdir() if f.is_file()}}
    folder = root / '2026-11-07-pr49-104-skill-199-casts'
    for name, digest in REVIEW_PINS.items():
        require(hashlib.sha256((folder / name).read_bytes()).hexdigest() == digest, 'Review hash: ' + name)
    bundle['comparison'] = json.loads((folder / 'reviewed-comparison.json').read_text())
    bundle['completeReview'] = json.loads((folder / 'complete-batch-review.json').read_text())
    require(hashlib.sha256(fixture.read_bytes()).hexdigest() == EVIDENCE_HASH, 'Research fixture hash')
    evidence = [json.loads(l) for l in fixture.read_text().splitlines() if l.strip()]
    result = verify_measurements(bundle, evidence)
    spec = importlib.util.spec_from_file_location('skill82_audit_estimates', main / 'research/v3/tools/build_estimates.py')
    est = importlib.util.module_from_spec(spec)
    sys.path.insert(0, str(main / 'research/v3/tools'))
    try:
        spec.loader.exec_module(est)
    finally:
        sys.path.pop(0)
    import research_v3_to_baselines as importer
    require(all((not importer.is_counted(r, est) for r in evidence)), 'Reference rows became counted')
    identity = compile_observations(root)
    rates, _ = compile_capture()
    admitted = {i for r in identity['processing'] + rates['processing'] for i in r['sourceRecordIDs']}
    reviewed = {i for g in result['groups'] for i in g['operationIDs']}
    require(not admitted & reviewed, 'Unapproved cohort entered compiled capture data')
    result['gates'] = {'all18RowsRejectedByProductionIsCounted': True, 'none394AdmittedInCompiledCaptures': True}
    return result

def verify_measurements(bundle, evidence):
    """Semantic checks, separate from byte pins so adversarial tests exercise both."""
    sources = {}
    groups = []
    for suffix in ['82-skill-194-update', '82-skill-200-additional', '82-skill-97-clean', 'rod-transition', '104-skill-199-casts']:
        name = '2026-11-07-pr49-' + suffix
        raw = bundle[suffix]['raw']
        records, contexts, studies = validate([raw])
        staged = compile_baselines([raw])
        require(semantic_digest(sorted(r['operationID'] for r in records)) == MEMBERSHIP_PINS[suffix], 'Original operation membership changed: '+suffix)
        require(semantic_digest(contexts) == CONTEXT_PINS[suffix], 'Exact source context changed: '+suffix)
        require(staged == bundle[suffix]['staged'], "Cohort audit invariant failed: staged == bundle[suffix]['staged']")
        sources[suffix] = {'source': name, 'files': bundle[suffix]['files'], 'records': records, 'contexts': contexts, 'studies': studies, 'stagedOperations': sum((b['operations'] for b in staged['baselines'])), 'excluded': staged['excludedCohorts']}
        if suffix not in ['82-skill-194-update', '82-skill-200-additional']:
            continue
        for cid in sorted(contexts):
            rs = [r for r in records if r['contextID'] == cid]
            if not rs:
                continue
            c = contexts[cid]
            require((c['baseSkill'], c['bonusSkill'], c['effectiveSkill']) == (64, 18, 82), "Cohort audit invariant failed: (c['baseSkill'], c['bonusSkill'], c['effectiveSkill']) == (64, 18, 82)")
            require(c['specialization'] == 'none' and c['fieldStatus']['operationStats'] == 'unknown' and (c.get('operationStats') is None), "Cohort audit invariant failed: c['specialization'] == 'none' and c['fieldStatus']['operationStats'] == 'unknown' and (c.get('operationStats') is None)")
            require(all((c['fieldStatus'][k] == 'measured' for k in ('baseSkill', 'bonusSkill', 'effectiveSkill', 'specialization', 'skillLineID', 'equipment'))), "Cohort audit invariant failed: all((c['fieldStatus'][k] == 'measured' for k in ('baseSkill', 'bonusSkill', 'effectiveSkill', 'specialization', 'skillLineID', 'equipment')))")
            require(c['skillLineID'] == 2909 and c['profileKind'] == 'measured' and (c['simulated'] is False), "Cohort audit invariant failed: c['skillLineID'] == 2909 and c['profileKind'] == 'measured' and (c['simulated'] is False)")
            for r in rs:
                require(r['successful'] and r['outputCoverage'] == 'complete' and (r['build'] == '70783') and (r['recipeID'] == 13262), "Cohort audit invariant failed: r['successful'] and r['outputCoverage'] == 'complete' and (r['build'] == '70783') and (r['recipeID'] == 13262)")
                require(r['addonCommit'] == 'ecd189a794a8b2c0318389766638b36cf2416e81' and r['recorderRevision'] == 5, "Cohort audit invariant failed: r['addonCommit'] == 'ecd189a794a8b2c0318389766638b36cf2416e81' and r['recorderRevision'] == 5")
                require(len(r['inputs']) == len(r['outputs']) == 1, "Cohort audit invariant failed: len(r['inputs']) == len(r['outputs']) == 1")
                i, o = (r['inputs'][0], r['outputs'][0])
                require((i['itemID'], i['quantity'], i['itemLevel'], i['rarity'], i['classID'], i['subClassID']) == (244752, 1, 165, 3, 4, 2), "Cohort audit invariant failed: (i['itemID'], i['quantity'], i['itemLevel'], i['rarity'], i['classID'], i['subClassID']) == (244752, 1, 165, 3, 4, 2)")
                require(r['gameMode'] == 'RETAIL' and r['captureVersion'] == 2, "Cohort audit invariant failed: r['gameMode'] == 'RETAIL' and r['captureVersion'] == 2")
                require(i['hyperlink'] == c['inputIdentity'][0]['hyperlink'] and i.get('qualityRank') is None, "Cohort audit invariant failed: i['hyperlink'] == c['inputIdentity'][0]['hyperlink'] and i.get('qualityRank') is None")
                require(':29:' + {'context:78': '40', 'context:79': '32', 'context:80': '49', 'context:81': '36'}[cid] + ':' in i['hyperlink'], "Cohort audit invariant failed: ':29:' + {'context:78': '40', 'context:79': '32', 'context:80': '49', 'context:81': '36'}[cid] + ':' in i['hyperlink']")
                require(r['studyID'] == {'82-skill-194-update': 'Voodoobrew - Grizzly Hills:70783:1794089584:23', '82-skill-200-additional': 'Voodoobrew - Grizzly Hills:70783:1794094434:25'}[suffix], "Cohort audit invariant failed: r['studyID'] == {'82-skill-194-update': 'Voodoobrew - Grizzly Hills:70783:1794089584:23', '82-skill-200-additional': 'Voodoobrew - Grizzly Hills:70783:1794094434:25'}[suffix]")
                require(r['provenance']['applyPolicy'] == 'NO_NUMERIC_TRANSFORM' and r['provenance']['independentReview'] == 'PENDING' and (r['provenance']['numericTransformValidated'] is False), "Cohort audit invariant failed: r['provenance']['applyPolicy'] == 'NO_NUMERIC_TRANSFORM' and r['provenance']['independentReview'] == 'PENDING' and (r['provenance']['numericTransformValidated'] is False)")
                require((o['itemID'], o['qualityRank']) in [(243602, 1), (243603, 2)] and o['quantity'] == 1, "Cohort audit invariant failed: (o['itemID'], o['qualityRank']) in [(243602, 1), (243603, 2)] and o['quantity'] == 1")
            b = next((b for b in staged['baselines'] if b['referenceContextID'] == cid))
            require(b['status'] == 'AWAITING_REVIEW' and b['applyPolicy'] == 'NO_NUMERIC_TRANSFORM' and (b['numericTransformValidated'] is False), "Cohort audit invariant failed: b['status'] == 'AWAITING_REVIEW' and b['applyPolicy'] == 'NO_NUMERIC_TRANSFORM' and (b['numericTransformValidated'] is False)")
            require('UNKNOWN_OPERATIONSTATS' in b['blockers'] and b['completeZeroOperations'] == 0, "Cohort audit invariant failed: 'UNKNOWN_OPERATIONSTATS' in b['blockers'] and b['completeZeroOperations'] == 0")
            require(set(b['sourceRecordIDs']) == {r['operationID'] for r in rs}, "Cohort audit invariant failed: set(b['sourceRecordIDs']) == {r['operationID'] for r in rs}")
            row = {'source': name, 'studyID': rs[0]['studyID'], 'contextID': cid, 'context': c, 'operationIDs': [r['operationID'] for r in rs], 'casts': len(rs), 'outputs': {}}
            for oid in (243602, 243603):
                counts = [sum((o['quantity'] for o in r['outputs'] if o['itemID'] == oid)) for r in rs]
                hist = dict(sorted(collections.Counter(counts).items()))
                total = sum(counts)
                hits = sum((x > 0 for x in counts))
                m = next((m for m in b['materials'] if m['outputItemID'] == oid))
                require(m['quantityHistogramIncludingZero'] == {str(k): v for k, v in hist.items()}, "Cohort audit invariant failed: m['quantityHistogramIncludingZero'] == {str(k): v for k, v in hist.items()}")
                require(m['expectedQuantity']['value'] == total / len(rs) and m['dropChance']['value'] == hits / len(rs), "Cohort audit invariant failed: m['expectedQuantity']['value'] == total / len(rs) and m['dropChance']['value'] == hits / len(rs)")
                row['outputs'][str(oid)] = {'histogram': {str(k): v for k, v in hist.items()}, 'totalQuantity': total, 'castsWithDrop': hits, 'mean': total / len(rs)}
            groups.append(row)

    def ids(k):
        return {r['operationID'] for r in sources[k]['records']}
    a, b = (ids('82-skill-194-update'), ids('82-skill-200-additional'))
    require(len(a) == 194 and len(b) == 200 and (not a & b), 'Cohort audit invariant failed: len(a) == 194 and len(b) == 200 and (not a & b)')
    require(ids('82-skill-97-clean') < a and len(ids('82-skill-97-clean')) == 97, "Cohort audit invariant failed: ids('82-skill-97-clean') < a and len(ids('82-skill-97-clean')) == 97")
    rod = sources['rod-transition']
    r82 = [r for r in rod['records'] if rod['contexts'][r['contextID']].get('effectiveSkill') == 82]
    require(len(r82) == 11 and (not {r['operationID'] for r in r82} & (a | b)), "Cohort audit invariant failed: len(r82) == 11 and (not {r['operationID'] for r in r82} & (a | b))")
    require(collections.Counter((r['outputs'][0]['itemID'] for r in r82)) == {243602: 9, 243603: 2}, "Cohort audit invariant failed: collections.Counter((r['outputs'][0]['itemID'] for r in r82)) == {243602: 9, 243603: 2}")
    comp = sources['104-skill-199-casts']
    require(len(comp['records']) == 199 and comp['stagedOperations'] == 0, "Cohort audit invariant failed: len(comp['records']) == 199 and comp['stagedOperations'] == 0")
    require(collections.Counter((r['outputs'][0]['itemID'] for r in comp['records'])) == {243602: 179, 243603: 20}, "Cohort audit invariant failed: collections.Counter((r['outputs'][0]['itemID'] for r in comp['records'])) == {243602: 179, 243603: 20}")
    comparison = bundle['comparison']
    require(comparison['R2OutputIncidenceBounds'] == {'numeratorLower': 20, 'numeratorUpper': 21, 'denominator': 200, 'lower': 0.1, 'upper': 0.105}, "Cohort audit invariant failed: comparison['R2OutputIncidenceBounds'] == {'numeratorLower': 20, 'numeratorUpper': 21, 'denominator': 200, 'lower': 0.1, 'upper': 0.105}")
    require(len(evidence) == 18, 'Cohort audit invariant failed: len(evidence) == 18')
    complete = bundle['completeReview']
    require(set(complete['classifiedNativeRecordIDs']) == ids('104-skill-199-casts'), "Cohort audit invariant failed: set(complete['classifiedNativeRecordIDs']) == ids('104-skill-199-casts')")
    require(complete['operatorConfirmedCompletedCasts'] == comparison['operatorConfirmedCompletedCasts'] == 200, "Cohort audit invariant failed: complete['operatorConfirmedCompletedCasts'] == comparison['operatorConfirmedCompletedCasts'] == 200")
    require(complete['classifiedNativeRecords'] == comparison['classifiedNativeRecords'] == 199, "Cohort audit invariant failed: complete['classifiedNativeRecords'] == comparison['classifiedNativeRecords'] == 199")
    require(complete['unclassifiedCompletedResults'] == comparison['unclassifiedCompletedResults'] == 1, "Cohort audit invariant failed: complete['unclassifiedCompletedResults'] == comparison['unclassifiedCompletedResults'] == 1")
    require(complete['sourceDecodedSHA256'] == comparison['sourceDecodedSHA256'] == PINS['104-skill-199-casts'], "Cohort audit invariant failed: complete['sourceDecodedSHA256'] == comparison['sourceDecodedSHA256'] == PINS['104-skill-199-casts']")
    require(complete['runtimePromotion'] is False and comparison['sharedRateApproved'] is False, "Cohort audit invariant failed: complete['runtimePromotion'] is False and comparison['sharedRateApproved'] is False")
    require(complete['fullBatchQuantityPointEstimateAdmissible'] is False, "Cohort audit invariant failed: complete['fullBatchQuantityPointEstimateAdmissible'] is False")
    require(complete['pointEstimateFromClassifiedOnly199IsCompleteBatchRate'] is False, "Cohort audit invariant failed: complete['pointEstimateFromClassifiedOnly199IsCompleteBatchRate'] is False")
    require(all((complete['unclassifiedResult'][k] is None for k in ('itemIDs', 'quantities', 'outputRanks'))), "Cohort audit invariant failed: all((complete['unclassifiedResult'][k] is None for k in ('itemIDs', 'quantities', 'outputRanks')))")
    require(all((comparison[k] is None for k in ('unclassifiedOutputQuantity', 'fullBatchExpectedQuantity', 'fullBatchQuantityDistribution', 'fullBatchR2PointEstimate'))), "Cohort audit invariant failed: all((comparison[k] is None for k in ('unclassifiedOutputQuantity', 'fullBatchExpectedQuantity', 'fullBatchQuantityDistribution', 'fullBatchR2PointEstimate')))")
    require(comparison['knownOutputUnits'] == {'243602': 179, '243603': 20}, "Cohort audit invariant failed: comparison['knownOutputUnits'] == {'243602': 179, '243603': 20}")
    require(complete['classifiedOutputUnits'] == comparison['knownOutputUnits'], "Cohort audit invariant failed: complete['classifiedOutputUnits'] == comparison['knownOutputUnits']")
    for r in comp['records']:
        c = comp['contexts'][r['contextID']]
        require((c['baseSkill'], c['bonusSkill'], c['effectiveSkill']) == (64, 40, 104), "Cohort audit invariant failed: (c['baseSkill'], c['bonusSkill'], c['effectiveSkill']) == (64, 40, 104)")
        require(c['specialization'] == 'none', "Cohort audit invariant failed: c['specialization'] == 'none'")
        require(len(r['outputs']) == 1 and r['outputs'][0]['quantity'] == 1, "Cohort audit invariant failed: len(r['outputs']) == 1 and r['outputs'][0]['quantity'] == 1")
        require(r['outputs'][0]['qualityRank'] == {243602: 1, 243603: 2}[r['outputs'][0]['itemID']], "Cohort audit invariant failed: r['outputs'][0]['qualityRank'] == {243602: 1, 243603: 2}[r['outputs'][0]['itemID']]")
    require(len(groups) == 8 and len({g['studyID'] for g in groups}) == 2, "Cohort audit invariant failed: len(groups) == 8 and len({g['studyID'] for g in groups}) == 2")
    require(sum((g['outputs']['243602']['totalQuantity'] for g in groups)) == 359, "Cohort audit invariant failed: sum((g['outputs']['243602']['totalQuantity'] for g in groups)) == 359")
    require(sum((g['outputs']['243603']['totalQuantity'] for g in groups)) == 35, "Cohort audit invariant failed: sum((g['outputs']['243603']['totalQuantity'] for g in groups)) == 35")
    require(len({r['id'] for r in evidence}) == 18, "Cohort audit invariant failed: len({r['id'] for r in evidence}) == 18")
    seen = set()
    for row in evidence[:16]:
        g = next((g for g in groups if g['source'] in row['originalSource'] and row['studyKey'].endswith(g['contextID'].replace(':', '-'))))
        actual = g['outputs'][str(row['outputItemID'])]
        key = (g['studyID'], g['contextID'], row['outputItemID'])
        require(key not in seen, 'Cohort audit invariant failed: key not in seen')
        seen.add(key)
        require(row['outputRank'] == {243602: 1, 243603: 2}[row['outputItemID']], "Cohort audit invariant failed: row['outputRank'] == {243602: 1, 243603: 2}[row['outputItemID']]")
        require(row['inputRank'] is None and row['inputItemID'] == 244752 and (row['inputsPerCast'] == 1), "Cohort audit invariant failed: row['inputRank'] is None and row['inputItemID'] == 244752 and (row['inputsPerCast'] == 1)")
        require(row['specialization'] == 'none' and row['stats'] is None, "Cohort audit invariant failed: row['specialization'] == 'none' and row['stats'] is None")
        require(row['minSeen'] == row['maxSeen'] == 1, "Cohort audit invariant failed: row['minSeen'] == row['maxSeen'] == 1")
        require(row['skill'] == 'Midnight Enchanting 82 (base 64, bonus 18)', "Cohort audit invariant failed: row['skill'] == 'Midnight Enchanting 82 (base 64, bonus 18)'")
        for f in ['totalQuantity', 'castsWithDrop', 'histogram']:
            require(row[f] == actual[f], (row['id'], f))
        require(row['casts'] == g['casts'] and row['sourceKind'] == 'reference', "Cohort audit invariant failed: row['casts'] == g['casts'] and row['sourceKind'] == 'reference'")
    require({r['outputItemID'] for r in evidence[16:]} == {243602, 243603}, "Cohort audit invariant failed: {r['outputItemID'] for r in evidence[16:]} == {243602, 243603}")
    for row in evidence[16:]:
        require(row['outputRank'] == {243602: 1, 243603: 2}[row['outputItemID']], "Cohort audit invariant failed: row['outputRank'] == {243602: 1, 243603: 2}[row['outputItemID']]")
        require(row['skill'] == 'Midnight Enchanting 104 (base 64, bonus 40)' and row['stats'] is None, "Cohort audit invariant failed: row['skill'] == 'Midnight Enchanting 104 (base 64, bonus 40)' and row['stats'] is None")
        require(all((row[k] is None for k in ('minSeen', 'maxSeen', 'averageShown', 'averagePer', 'inputRank'))), "Cohort audit invariant failed: all((row[k] is None for k in ('minSeen', 'maxSeen', 'averageShown', 'averagePer', 'inputRank')))")
        require(row['casts'] == 200 and all((row[f] is None for f in ['histogram', 'totalQuantity', 'castsWithDrop'])) and (row['sourceKind'] == 'reference'), "Cohort audit invariant failed: row['casts'] == 200 and all((row[f] is None for f in ['histogram', 'totalQuantity', 'castsWithDrop'])) and (row['sourceKind'] == 'reference')")
    result = {'main': MAIN, 'research': RESEARCH, 'evidenceSHA256': EVIDENCE_HASH, 'groups': groups, 'sources': sources, 'comparison': comparison, 'reconciliation': {'newEvidenceDistinctCasts': 394, 'separateRodTransitionSkill82Casts': 11, 'allCleanSkill82': 405, 'earlier97IsSubsetOf194': True, 'materialSpecificZeroNotNoOutputCast': True, 'R1': 359, 'R2': 35, 'allCleanR1': 368, 'allCleanR2': 37}}
    return result

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, help='Optional detailed JSON audit report')
    args = parser.parse_args()
    result = audit()
    if args.output:
        args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print('PASS: 16 histograms; 394 = 194 + 200; 405 = 394 + 11; 97 subset only; 104-skill censor and reference-only gates preserved. No rates promoted.')
if __name__ == '__main__':
    main()
