"""A catalogue requires explicit dispositions, never a generic old hold."""
from pathlib import Path
import sys
import tempfile
import unittest
import json

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import assemble_source_catalogue as assembly
from source_catalogue_review import review_source_catalogue
from reviewed_source_catalogue import canonical_hash


class AssemblyTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.folder = self.root / assembly.CATALOGUE
        self.folder.mkdir(parents=True)
        self.assignment = self.root / 'assignment.json'
        assembly.write(self.assignment, {'sources': [{'sourceKey': 'primary:one', 'candidateRows': []}]})
        for name in assembly.PROPOSALS:
            assembly.write(self.folder/name, {'proposals': []})
        for name in assembly.REVIEWS:
            assembly.write(self.folder/name, {'sources': []})
        self.source = {'sourceKey': 'primary:one', 'rows': [], 'leadDecision': {
            'decision': 'METADATA_REFERENCE',
            'facts': 'The original reports an interrupted planned queue, with no actual output quantities or completed-operation denominator.',
            'futureEvidenceTrigger': 'An original quantified output/operation report for this exact source.'}}
        assembly.write(self.folder/assembly.REVIEWS[0], {'sources': [self.source]})
        for lane in assembly.LANES:
            assembly.write(self.folder/(lane+'-admitted-models.json'), {'models': [], 'facts': []})
            assembly.write(self.folder/(lane+'-proposal-dispositions.json'), {'decisions': []})

    def test_metadata_lead_gets_a_precise_numerical_disposition_without_fake_data(self):
        result = assembly.assemble(self.root, [self.assignment])
        self.assertEqual(result, {'sources': 1, 'scopes': 1, 'models': 0, 'facts': 0, 'proposals': 0})
        verified = review_source_catalogue(self.root, consumer_model_ids=[], consumer_fact_ids=[])
        self.assertTrue(verified['complete'], verified['errors'])
        self.assertFalse(verified['scientificApproval'])
        decision = assembly.read(self.folder/'final-source-decisions.json')['sources'][0]['scopes'][0]['fieldDecisions'][0]
        self.assertIn('interrupted planned queue', decision['reason'])
        self.assertEqual(decision['proposalIDs'], [])

    def test_unreviewed_scope_does_not_become_a_generic_rejection(self):
        self.source.pop('leadDecision')
        assembly.write(self.folder/assembly.REVIEWS[0], {'sources': [self.source]})
        with self.assertRaisesRegex(ValueError, 'require explicit adjudication'):
            assembly.assemble(self.root, [self.assignment])
        self.assertFalse((self.folder/'manifest.json').exists())

    def test_missing_proposal_decision_fails_before_catalogue_creation(self):
        assembly.write(self.folder/assembly.PROPOSALS[0], {'proposals': [{'proposalID': 'one', 'sourceKey': 'primary:one'}]})
        with self.assertRaisesRegex(ValueError, 'Proposal decisions differ'):
            assembly.assemble(self.root, [self.assignment])
        self.assertFalse((self.folder/'manifest.json').exists())

    def test_same_source_addendum_merges_disjoint_rows_and_keeps_each_receipt(self):
        relative = 'research/v3/evidence/rows.jsonl'
        path = self.root/relative
        path.parent.mkdir(parents=True, exist_ok=True)
        rows = [{'id': 'first'}, {'id': 'additional-variant'}]
        path.write_text(''.join(json.dumps(row)+'\n' for row in rows), encoding='utf-8')
        additional = self.root/'additional.json'
        for index, assignment in enumerate((self.assignment, additional)):
            locator = relative+':'+str(index+1)
            assembly.write(assignment, {'sources': [{'sourceKey': 'primary:one',
                'candidateRows': [{'locator': locator}]}]})
            assembly.write(self.folder/assembly.REVIEWS[index], {'sources': [{
                'sourceKey': 'primary:one', 'rows': [{'locator': locator,
                    'rawSHA256': canonical_hash(rows[index]),
                    'fieldRejections': [{'reason': 'The reported item variant lacks an identifiable current game context.'}]}]}]})
        result = assembly.assemble(self.root, [self.assignment, additional])
        self.assertEqual((result['sources'], result['scopes']), (1, 2))
        verified = review_source_catalogue(self.root, consumer_model_ids=[], consumer_fact_ids=[])
        self.assertTrue(verified['complete'], verified['errors'])
        scopes = assembly.read(self.folder/'final-source-decisions.json')['sources'][0]['scopes']
        self.assertEqual([scope['fieldDecisions'][0]['receiptPath'] for scope in scopes],
                         [(assembly.CATALOGUE/name).as_posix() for name in assembly.REVIEWS[:2]])
        with self.assertRaisesRegex(ValueError, 'row assigned twice'):
            assembly.assemble(self.root, [self.assignment, self.assignment])


if __name__ == '__main__':
    unittest.main()
