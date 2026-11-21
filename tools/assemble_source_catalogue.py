"""Assemble reviewed lane receipts without inventing scientific decisions.

The assigned backlog is finite. Lane curators supply every proposal's explicit
consumer/disposition; this tool only joins identities, hashes and exact scopes.
It fails if any candidate row lacks a substantive review or proposal decision.
"""
import argparse
from collections import defaultdict
from hashlib import sha256
import json
from pathlib import Path

from reviewed_source_catalogue import CATALOGUE, canonical_hash

PROPOSALS = ('processing-proposal-definitions.json', 'disenchant-a-proposals.json',
             'disenchant-a-supplemental-proposals.json',
             'disenchant-a-field-audit-proposals.json',
             'disenchant-a-current-addendum-proposals.json', 'disenchant-b-leads-proposals.json',
             'disenchant-b-leads-current-addendum-proposals.json',
             'aure-cutoff-addendum-proposals.json', 'astroid-gnarm-cutoff-addendum-proposals.json',
             'eoghals-cutoff-addendum-proposals.json')
REVIEWS = ('processing-review.json', 'disenchant-a-review.json',
           'disenchant-a-current-addendum-review.json', 'disenchant-b-leads-review.json',
           'disenchant-b-leads-current-addendum-review.json',
           'aure-cutoff-addendum-review.json', 'astroid-gnarm-cutoff-addendum-review.json',
           'eoghals-cutoff-addendum-review.json')
LANES = ('processing', 'disenchant-a', 'disenchant-b',
         'aure-cutoff-addendum', 'astroid-gnarm-cutoff-addendum', 'eoghals-cutoff-addendum')


def walk(value, pointer=''):
    if isinstance(value, dict):
        yield pointer, value
        for key, child in value.items():
            yield from walk(child, pointer + '/' + key.replace('~', '~0').replace('/', '~1'))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from walk(child, pointer + '/' + str(index))


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def write(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, sort_keys=True, indent=2) + '\n', encoding='utf-8', newline='\n')


def assemble(snapshot, assignment_files):
    snapshot = Path(snapshot)
    folder = snapshot / CATALOGUE
    assignments = {}
    for path in assignment_files:
        for source in read(Path(path))['sources']:
            key = source['sourceKey']
            if key in assignments:
                prior = assignments[key]
                old = {row['locator'] for row in prior.get('candidateRows', [])}
                added = source.get('candidateRows', [])
                if old.intersection(row['locator'] for row in added):
                    raise ValueError('Source row assigned twice: ' + key)
                prior.setdefault('candidateRows', []).extend(added)
            else:
                assignments[key] = dict(source, candidateRows=list(source.get('candidateRows', [])))
    proposals, proposal_pointers = {}, {}
    for name in PROPOSALS:
        for pointer, item in walk(read(folder / name)):
            if 'proposalID' not in item:
                continue
            identity = item['proposalID']
            if identity in proposals:
                raise ValueError('Duplicate proposal definition: ' + identity)
            proposals[identity] = item
            proposal_pointers[identity] = (name, pointer)
    dispositions, models, facts, exclusions = {}, [], [], []
    for lane in LANES:
        policy = read(folder / (lane + '-admitted-models.json'))
        models.extend(policy['models'])
        facts.extend(policy['facts'])
        exclusions.extend(policy.get('sourceFieldExclusions', []))
        values = read(folder / (lane + '-proposal-dispositions.json'))
        for item in values['decisions']:
            identity = item['proposalID']
            if identity in dispositions:
                raise ValueError('Duplicate proposal disposition: ' + identity)
            dispositions[identity] = item
    if set(proposals) != set(dispositions):
        raise ValueError('Proposal decisions differ: missing=' + str(sorted(set(proposals)-set(dispositions)))
                         + ' extra=' + str(sorted(set(dispositions)-set(proposals))))
    reviewed_rows = defaultdict(dict)
    source_receipts = {}
    for name in REVIEWS:
        document = read(folder / name)
        for source_index, source in enumerate(document['sources']):
            key = source['sourceKey']
            if key not in source_receipts or source.get('leadDecision'):
                source_receipts[key] = (name, source, source_index)
            for pointer, item in walk(source):
                locator = item.get('locator')
                # Proposal references themselves are not a review of a row.
                if locator and any(k in item for k in ('fieldRejections', 'fields', 'fieldDecisions', 'disposition', 'decision')):
                    reviewed_rows[key][locator] = (item, name)
    if set(assignments) != set(source_receipts):
        raise ValueError('Source review coverage differs from the assigned backlog')
    by_locator = defaultdict(list)
    for identity, proposal in proposals.items():
        by_locator[(proposal['sourceKey'], proposal.get('locator') or proposal.get('sourceLocator'))].append(identity)
    assigned, final, unresolved = [], [], []
    physical_files = {}
    raw_cache = {}
    for source_key, source in sorted(assignments.items()):
        scopes, reviewed = [], []
        consumed = set()
        receipt_name, receipt, receipt_index = source_receipts[source_key]
        for candidate in source.get('candidateRows', []):
            locator = candidate['locator']
            relative, line = locator.rsplit(':', 1)
            path = snapshot / relative
            if relative not in raw_cache:
                raw_cache[relative] = path.read_text(encoding='utf-8-sig').splitlines()
                physical_files[relative] = sha256(path.read_bytes()).hexdigest()
            raw = json.loads(raw_cache[relative][int(line)-1])
            digest = canonical_hash(raw)
            row_receipt = reviewed_rows[source_key].get(locator)
            if row_receipt is None:
                unresolved.append({'sourceKey': source_key, 'locator': locator, 'reason': 'Exact row review receipt absent'})
                continue
            row, row_receipt_name = row_receipt
            declared = row.get('currentPhysicalRowSHA256') or row.get('rawSHA256') or row.get('frozenRawSHA256')
            if declared != digest:
                unresolved.append({'sourceKey': source_key, 'locator': locator,
                                   'reason': 'Reviewed physical row fingerprint does not match the integration snapshot'})
                continue
            ids = sorted(by_locator[(source_key, locator)])
            fields = []
            required = []
            for identity in ids:
                decision = dict(dispositions[identity], field='proposal:' + identity, proposalIDs=[identity])
                fields.append(decision)
                required.append(decision['field'])
                consumed.add(identity)
            if not ids:
                # The reviewer must provide a precise rejection; do not promote
                # a generic old hold to a completed scientific decision.
                reasons = []
                for _, node in walk(row):
                    for key in ('reason', 'rejectionReason'):
                        if isinstance(node.get(key), str):
                            reasons.append(node[key])
                reasons.extend(x for x in row.get('currentNumericalLimits', []) if isinstance(x, str))
                if not reasons:
                    unresolved.append({'sourceKey': source_key, 'locator': locator, 'reason': 'No explicit field rejection or consumer proposal'})
                    continue
                required = ['numerical-use']
                fields = [{'field': 'numerical-use', 'decision': 'REJECTED_CURRENT_NUMERICAL',
                           'reason': ' '.join(dict.fromkeys(reasons)),
                           'futureEvidenceTrigger': row.get('recheckTrigger') or row.get('futureEvidenceTrigger')
                               or 'Published source evidence resolving the specific units, identity or scope listed in this field receipt.',
                           'proposalIDs': [], 'receiptPath': (CATALOGUE / row_receipt_name).as_posix()}]
            scope = {'scopeID': locator, 'locator': locator, 'rawSHA256': digest, 'requiredFields': required}
            decision = {'scopeID': locator, 'rawSHA256': digest, 'fieldDecisions': fields}
            effective = row.get('currentEffectiveSHA256') or row.get('effectiveSHA256')
            if effective:
                scope['effectiveSHA256'] = effective
                decision['effectiveSHA256'] = effective
            scopes.append(scope)
            reviewed.append(decision)
        # New fields recovered directly from a reviewed original/workbook are
        # pinned to their precise reviewed object instead of fictitious JSONL.
        extra = sorted(identity for identity, proposal in proposals.items()
                       if proposal['sourceKey'] == source_key and identity not in consumed)
        for identity in extra:
            name, pointer = proposal_pointers[identity]
            proposal = proposals[identity]
            scope_id = 'reviewed-proposal:' + identity
            scopes.append({'scopeID': scope_id, 'sourceFile': (CATALOGUE / name).as_posix(), 'jsonPointer': pointer,
                           'rawSHA256': canonical_hash(proposal), 'requiredFields': ['numerical-use']})
            reviewed.append({'scopeID': scope_id, 'rawSHA256': canonical_hash(proposal), 'fieldDecisions': [
                dict(dispositions[identity], field='numerical-use', proposalIDs=[identity])]})
        if not scopes and isinstance(receipt.get('leadDecision'), dict):
            lead = receipt['leadDecision']
            facts_text = lead.get('facts') or receipt.get('sourceConclusion')
            if isinstance(facts_text, str) and len(facts_text.strip())>=20:
                scope_id = 'lead-review:' + source_key
                digest = canonical_hash(lead)
                scopes.append({'scopeID': scope_id, 'sourceFile': (CATALOGUE / receipt_name).as_posix(),
                    'jsonPointer': f'/sources/{receipt_index}/leadDecision', 'rawSHA256': digest,
                    'requiredFields': ['additional-numerical-yield']})
                reviewed.append({'scopeID': scope_id, 'rawSHA256': digest, 'fieldDecisions': [{
                    'field': 'additional-numerical-yield', 'decision': 'REJECTED_CURRENT_NUMERICAL',
                    'reason': 'No additional numerical yield is admitted from this lead: ' + facts_text,
                    'futureEvidenceTrigger': lead.get('futureEvidenceTrigger')
                        or 'Published operation quantities with identifiable units and input/output scope beyond the preserved metadata.',
                    'receiptPath': (CATALOGUE / receipt_name).as_posix(), 'proposalIDs': []}]})
        if not scopes:
            unresolved.append({'sourceKey': source_key, 'reason': 'No candidate row or recovered field has a terminal consumer/rejection'})
        assigned.append({'sourceKey': source_key, 'scopes': scopes})
        final.append({'sourceKey': source_key, 'reviewStatus': 'REVIEWED', 'scopes': reviewed})
    if unresolved:
        write(folder / 'assembly-unresolved.json', {'unresolved': unresolved})
        raise ValueError(str(len(unresolved)) + ' source scopes still require explicit adjudication; see assembly-unresolved.json')
    write(folder / 'assigned-sources.json', {'schemaVersion': 1, 'sources': assigned})
    write(folder / 'final-source-decisions.json', {'schemaVersion': 1, 'sources': final})
    write(folder / 'proposal-dispositions.json', {'decisions': [dispositions[k] for k in sorted(dispositions)]})
    write(folder / 'admitted-models.json', {'schemaVersion': 1, 'revision': 'reviewed-backlog-20261120/1',
                                         'models': models, 'facts': facts, 'sourceFieldExclusions': exclusions})
    names = list(PROPOSALS) + list(REVIEWS) + ['assigned-sources.json', 'final-source-decisions.json',
                                             'proposal-dispositions.json', 'admitted-models.json']
    names += [lane+suffix for lane in LANES for suffix in
              ('-admitted-models.json', '-proposal-dispositions.json')]
    names += [path.name for path in sorted(folder.glob('*.md'))]
    names += [path.name for path in sorted(folder.glob('*.json'))
              if path.name not in ('manifest.json', 'assembly-unresolved.json')]
    manifest = {'schemaVersion': 1, 'catalogueID': 'backlog-20261120',
                'scopeCutoffResearchCommit': '0cd0bad8867e7a8d909b4ecae74f6136a3e23d42',
                'assignedSourcesFile': 'assigned-sources.json', 'decisionsFile': 'final-source-decisions.json',
                'proposalFiles': list(PROPOSALS), 'proposalDispositionsFile': 'proposal-dispositions.json',
                'admittedModelsFile': 'admitted-models.json', 'sourceFiles': physical_files,
                'files': {(CATALOGUE / name).as_posix(): sha256((folder/name).read_bytes()).hexdigest() for name in sorted(set(names))}}
    write(folder / 'manifest.json', manifest)
    stale = folder / 'assembly-unresolved.json'
    if stale.is_file():
        stale.unlink()
    return {'sources': len(assignments), 'scopes': sum(len(s['scopes']) for s in assigned),
            'proposals': len(proposals), 'models': len(models), 'facts': len(facts)}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('snapshot', type=Path)
    parser.add_argument('assignments', nargs='+', type=Path)
    args = parser.parse_args()
    print(json.dumps(assemble(args.snapshot, args.assignments), sort_keys=True))
