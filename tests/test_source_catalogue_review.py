"""Finite review coverage and actual producer/consumer linkage, not science votes."""
import copy
from hashlib import sha256
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, 'tools')
import source_catalogue_review as review


class SourceCatalogueCompletion(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.folder = self.root / review.CATALOGUE
        self.folder.mkdir(parents=True)
        self.rows = [{'id': 'row-a', 'totalQuantity': 2}, {'id': 'row-b', 'castsWithDrop': 3, 'totalQuantity': 9}]
        self.raw = self.root / 'research/v3/evidence/legacy/raw.jsonl'
        self.raw.parent.mkdir(parents=True, exist_ok=True)
        self.write_raw()
        self.workbook = {'leads': [{'source': 'lead', 'priceOnly': 12}], 'worksheet': [[1, 'item name', 'currency only']]}
        self.book = self.root / 'research/v3/evidence/master/source-workbook.json'
        self.book.parent.mkdir(parents=True, exist_ok=True)
        self.book.write_text(json.dumps(self.workbook))
        self.manifest = {'schemaVersion': 1, 'catalogueID': 'finite-fixture', 'researchSnapshot': 'a' * 40,
                         'proposalFiles': ['lane-a-proposals.json', 'lane-b-proposals.json'],
                         'sourceFiles': {self.raw.relative_to(self.root).as_posix(): sha256(self.raw.read_bytes()).hexdigest(),
                                         self.book.relative_to(self.root).as_posix(): sha256(self.book.read_bytes()).hexdigest()}}
        scopes = [dict(scopeID='row-a', locator=self.locator(1), rawSHA256=review.canonical_hash(self.rows[0]), requiredFields=['quantity']),
                  dict(scopeID='row-b', locator=self.locator(2), rawSHA256=review.canonical_hash(self.rows[1]), requiredFields=['conditional-quantity']),
                  dict(scopeID='lead', sourceFile=self.book.relative_to(self.root).as_posix(), jsonPointer='/leads/0',
                       rawSHA256=review.canonical_hash(self.workbook['leads'][0]), requiredFields=['numerical-use']),
                  dict(scopeID='workbook-row', sourceFile=self.book.relative_to(self.root).as_posix(), jsonPointer='/worksheet/0',
                       rawSHA256=review.canonical_hash(self.workbook['worksheet'][0]), requiredFields=['numerical-use'])]
        self.assigned = {'sources': [dict(sourceKey='source:a', scopes=[scopes[0]]),
                                     dict(sourceKey='source:b', scopes=[scopes[1]]),
                                     dict(sourceKey='source:lead', scopes=scopes[2:])]}
        self.decisions = {'sources': []}
        for source in self.assigned['sources']:
            reviewed = dict(sourceKey=source['sourceKey'], reviewStatus='REVIEWED', scopes=[])
            for scope in source['scopes']:
                index = {'row-a': 1, 'row-b': 2, 'lead': 3, 'workbook-row': 4}[scope['scopeID']]
                field = dict(field=scope['requiredFields'][0], proposalIDs=[f'p{index}'])
                if index == 1:
                    field.update(decision='MODEL', modelIDs=['model:1'])
                elif index == 2:
                    field.update(decision='SOURCE_FACT', factIDs=['fact:1'])
                else:
                    field.update(self.rejection())
                reviewed['scopes'].append(dict(scopeID=scope['scopeID'], rawSHA256=scope['rawSHA256'], fieldDecisions=[field]))
            self.decisions['sources'].append(reviewed)
        self.proposal_a = {'proposals': [{'proposalID': 'p1', 'sourceKey': 'source:a'}]}
        self.proposal_b = {'fieldProposals': [{'proposalID': 'p2', 'sourceKey': 'source:b'}],
                           'leadModelProposals': [{'proposalID': 'p3', 'sourceKey': 'source:lead'}],
                           'workbookFieldProposals': [{'proposalID': 'p4', 'sourceKey': 'source:lead'}]}
        self.dispositions = {'decisions': [dict(proposalID='p1', decision='MODEL', modelIDs=['model:1']),
                                          dict(proposalID='p2', decision='SOURCE_FACT', factIDs=['fact:1']),
                                          dict(proposalID='p3', **self.rejection()), dict(proposalID='p4', **self.rejection())]}
        self.admitted = {'models': [dict(recordID='model:1', proposalIDs=['p1'], samples=0, sampleSizeKnown=False)],
                         'facts': [dict(factID='fact:1', proposalIDs=['p2'], confidence0to100=0)]}
        self.consumer_models = [dict(recordID='model:1', samples=0, sampleSizeKnown=False,
                                     reviewedPublishedPrior={'observedSamplesAdded': 0})]
        self.consumer_facts = [dict(factID='fact:1', confidence0to100=0)]

    def locator(self, line):
        return self.raw.relative_to(self.root).as_posix() + ':' + str(line)

    def rejection(self):
        return dict(decision='REJECTED_CURRENT_NUMERICAL', reason='The original source reports only currency; no material-unit quantity or matching operation denominator is supplied.',
                    futureEvidenceTrigger='A published material-unit tally and a matching processed-input denominator.')

    def write_raw(self):
        self.raw.write_text(''.join(json.dumps(row) + '\n' for row in self.rows))

    def write(self):
        for name, document in [('manifest.json', self.manifest), ('assigned-sources.json', self.assigned),
                               ('final-source-decisions.json', self.decisions), ('proposal-dispositions.json', self.dispositions),
                               ('admitted-models.json', self.admitted), ('lane-a-proposals.json', self.proposal_a),
                               ('lane-b-proposals.json', self.proposal_b)]:
            (self.folder / name).write_text(json.dumps(document))

    def run_review(self, **kwargs):
        self.write()
        return review.review_source_catalogue(self.root, consumer_model_ids=self.consumer_models,
                                              consumer_fact_ids=self.consumer_facts, **kwargs)

    def fails(self, code, **kwargs):
        result = self.run_review(**kwargs)
        self.assertFalse(result['complete'])
        self.assertIn(code, result['errorCounts'], result)
        return result

    def test_complete_counts_separate_reviews_models_facts_and_rejections(self):
        result = self.run_review()
        self.assertTrue(result['complete'], result)
        self.assertEqual((result['catalogueReviewedCount'], result['assignedSourceCount'], result['assignedScopeCount']), (3, 3, 4))
        self.assertEqual((result['numericalModelCount'], result['sourceFactCount'], result['numericallyAdmittedSourceCount']), (1, 1, 1))
        self.assertEqual((result['proposalCount'], result['proposalDecisionCount'], result['rejectedCurrentFieldCount']), (4, 4, 2))
        self.assertFalse(result['scientificApproval'])

    def test_no_catalogue_is_inactive_and_does_not_break_old_builds(self):
        result = review.review_source_catalogue(self.root)
        self.assertFalse(result['active'])
        self.assertFalse(result['complete'])
        self.assertEqual(result['errors'], [])
        self.assertEqual(review.main(['--snapshot', str(self.root), '--check', '--output', str(self.root / 'summary.json')]), 0)

    def test_missing_source_scope_field_and_decision_are_not_completion(self):
        original = copy.deepcopy(self.decisions)
        self.decisions['sources'].pop()
        self.fails('ASSIGNED_SOURCE_NOT_REVIEWED')
        self.decisions = copy.deepcopy(original)
        self.decisions['sources'][0]['scopes'] = []
        self.fails('ASSIGNED_SCOPE_NOT_REVIEWED')
        self.decisions = copy.deepcopy(original)
        self.decisions['sources'][0]['scopes'][0]['fieldDecisions'] = []
        self.fails('ASSIGNED_FIELD_NOT_REVIEWED')
        self.decisions = original
        self.decisions['sources'][0]['scopes'][0]['fieldDecisions'][0]['decision'] = 'ADMIT_PROPOSAL'
        self.fails('NONTERMINAL_DECISION')

    def test_every_main_lead_workbook_proposal_has_a_terminal_disposition(self):
        self.dispositions['decisions'].pop()
        self.fails('PROPOSAL_NOT_DISPOSITIONED')
        self.dispositions['decisions'].append(dict(proposalID='p4', decision='NEEDS_REVIEW'))
        self.fails('NONTERMINAL_DECISION')

    def test_duplicate_source_scope_locator_proposal_and_destination_ids_fail(self):
        self.proposal_b['fieldProposals'].append(dict(proposalID='p1', sourceKey='source:a'))
        self.fails('PROPOSAL_DUPLICATE_ID')
        self.proposal_b['fieldProposals'].pop()
        self.assigned['sources'].append(copy.deepcopy(self.assigned['sources'][0]))
        self.fails('ASSIGNED_SOURCE_DUPLICATE_ID')
        self.assigned['sources'].pop()
        self.admitted['facts'].append(copy.deepcopy(self.admitted['facts'][0]))
        self.fails('ADMITTED_FACT_DUPLICATE_ID')
        self.admitted['facts'].pop()
        self.assigned['sources'][1]['scopes'][0]['locator'] = self.locator(1)
        self.fails('DUPLICATE_ASSIGNED_LOCATOR')

    def test_admitted_model_or_fact_must_exist_in_producer_and_actual_consumer(self):
        self.consumer_models = []
        self.fails('ADMITTED_MODEL_MISSING_FROM_CONSUMER')
        self.consumer_models = ['model:1']
        self.consumer_facts = []
        self.fails('ADMITTED_FACT_MISSING_FROM_CONSUMER')
        self.consumer_facts = ['fact:1']
        self.admitted['models'] = []
        self.fails('ADMITTED_MODEL_MISSING_FROM_PRODUCER')

    def test_absent_consumer_receipts_cannot_close_an_active_catalogue(self):
        self.write()
        result = review.review_source_catalogue(self.root)
        self.assertFalse(result['complete'])
        self.assertIn('ADMITTED_MODEL_MISSING_FROM_CONSUMER', result['errorCounts'])

    def test_no_source_page_or_date_wide_credit(self):
        self.decisions['sources'][0]['reviewStatus'] = 'FULLY_REVIEWED_OLD_PAGE'
        self.fails('SOURCE_REVIEW_NOT_TERMINAL')
        self.decisions['sources'][0]['reviewStatus'] = 'REVIEWED'
        self.decisions['sources'][0]['scopes'][0]['fieldDecisions'][0]['proposalIDs'] = ['p2']
        self.fails('FIELD_PROPOSAL_SOURCE_MISMATCH')

    def test_generic_old_held_reason_is_not_a_precise_current_rejection(self):
        self.dispositions['decisions'][2]['reason'] = 'No supported compiled operation/identity/field after existing applicability, arithmetic and confidence policies'
        self.fails('GENERIC_OLD_HOLD_IS_NOT_A_REVIEW_DECISION')
        self.dispositions['decisions'][2] = dict(proposalID='p3', **self.rejection())
        del self.dispositions['decisions'][2]['futureEvidenceTrigger']
        self.fails('REJECTION_NEEDS_SCOPE_FACTS_AND_TRIGGER')

    def test_fabricated_n_is_rejected_but_original_reported_counts_are_preserved(self):
        self.admitted['models'][0]['sourceReportedCompletedOperations'] = 1000
        self.assertTrue(self.run_review()['complete'])
        self.admitted['models'][0]['samples'] = 1000
        self.fails('NEW_OBSERVATIONS_IN_REVIEWED_PRIOR')
        self.admitted['models'][0]['samples'] = 0
        self.consumer_models[0]['reviewedPublishedPrior']['observedSamplesAdded'] = 1
        self.fails('CONSUMER_INVENTS_OBSERVATIONS')

    def test_unrelated_append_and_new_research_do_not_expire_assigned_reviews(self):
        self.rows.append({'id': 'unrelated-new', 'totalQuantity': 800})
        self.write_raw()
        self.workbook['worksheet'].append(['a wholly new worksheet row'])
        self.book.write_text(json.dumps(self.workbook))
        unrelated = self.raw.parent / 'new-unassigned.jsonl'
        unrelated.write_text('{"id":"new-source"}\n')
        result = self.run_review()
        self.assertTrue(result['complete'], result)
        self.assertEqual(result['reopenedScopeCount'], 0)
        self.assertEqual(len(result['sourceFileDrift']), 2)

    def test_nested_model_counts_and_scientific_status_are_not_fabricated(self):
        self.admitted['models'][0]['materials'] = [{'expectedQuantity': {'value': 2, 'samples': 90}}]
        self.fails('PRODUCER_INVENTS_OBSERVATIONS')
        self.admitted['models'][0]['materials'][0]['expectedQuantity'] = {'value': 2, 'status': 'measured', 'samples': 0}
        self.fails('PRODUCER_PRIOR_CLAIMS_MEASUREMENT')
        self.admitted['models'][0]['materials'][0]['expectedQuantity']['status'] = 'historical'
        self.admitted['models'][0]['sourceRows'] = [{'rawRow': {'casts': 100, 'samples': 100, 'histogram': {'1': 100}}}]
        self.assertTrue(self.run_review()['complete'], 'original observations remain preserved in provenance')

    def test_changed_raw_row_reopens_only_its_assigned_scope(self):
        self.rows[0]['totalQuantity'] = 3
        self.write_raw()
        result = self.fails('ASSIGNED_SCOPE_CHANGED')
        self.assertEqual(result['reopenedScopeCount'], 1)
        self.assertEqual(result['reopenedScopes'][0]['scopeID'], 'row-a')
        self.assertEqual(result['catalogueReviewedCount'], 2)

    def test_changed_effective_correction_reopens_only_its_scope(self):
        expected = 'c' * 64
        self.assigned['sources'][0]['scopes'][0]['effectiveSHA256'] = expected
        self.decisions['sources'][0]['scopes'][0]['effectiveSHA256'] = expected
        receipts = {self.locator(i + 1): {'rawSHA256': review.canonical_hash(row)} for i, row in enumerate(self.rows)}
        receipts[self.locator(1)]['effectiveSHA256'] = expected
        self.assertTrue(self.run_review(current_rows=receipts)['complete'])
        receipts[self.locator(1)]['effectiveSHA256'] = 'd' * 64
        result = self.fails('ASSIGNED_SCOPE_CHANGED', current_rows=receipts)
        self.assertEqual(result['reopenedScopeCount'], 1)

    def test_field_proposal_destination_disagreement_fails(self):
        self.dispositions['decisions'][0] = dict(proposalID='p1', **self.rejection())
        self.fails('FIELD_MODEL_NOT_IN_PROPOSAL_DISPOSITION')
        self.dispositions['decisions'][0] = dict(proposalID='p1', decision='MODEL', modelIDs=['model:1'])
        self.decisions['sources'][0]['scopes'][0]['fieldDecisions'][0].update(self.rejection())
        self.decisions['sources'][0]['scopes'][0]['fieldDecisions'][0].pop('modelIDs')
        self.fails('PROPOSAL_MODEL_NOT_LINKED_TO_ACCEPTED_SCOPE')

    def test_unlinked_proposal_or_orphan_model_is_not_completion(self):
        self.decisions['sources'][1]['scopes'][0]['fieldDecisions'][0]['proposalIDs'] = []
        self.fails('PROPOSAL_NOT_LINKED_TO_REVIEW_SCOPE')
        self.admitted['models'].append(dict(recordID='orphan', samples=0))
        self.fails('ORPHAN_ADMITTED_MODEL')

    def test_paths_must_stay_in_the_pinned_snapshot(self):
        self.manifest['proposalFiles'] = ['../../../../../../outside.json']
        self.fails('INVALID_CATALOGUE_FILE')

    def test_precise_rejections_can_complete_without_numerical_admissions(self):
        self.admitted = {'models': [], 'facts': []}
        for source in self.decisions['sources']:
            for scope in source['scopes']:
                for field in scope['fieldDecisions']:
                    field.pop('modelIDs', None)
                    field.pop('factIDs', None)
                    field.update(self.rejection())
        for decision in self.dispositions['decisions']:
            decision.pop('modelIDs', None)
            decision.pop('factIDs', None)
            decision.update(self.rejection())
        self.write()
        result = review.review_source_catalogue(self.root)
        self.assertTrue(result['complete'], result)
        self.assertEqual(result['catalogueReviewedCount'], 3)
        self.assertEqual(result['numericalModelCount'], 0)
        self.assertEqual(result['rejectedCurrentFieldCount'], 4)

    def test_reused_existing_result_requires_exact_receipt_and_consumer(self):
        self.admitted['models'] = []
        for decision in [self.dispositions['decisions'][0], self.decisions['sources'][0]['scopes'][0]['fieldDecisions'][0]]:
            decision['decision'] = 'ALREADY_REPRESENTED'
            decision['receiptPath'] = self.book.relative_to(self.root).as_posix()
        self.consumer_models[0]['samples'] = 50  # authentic old observations are not newly added modelN
        self.assertTrue(self.run_review()['complete'])
        self.dispositions['decisions'][0].pop('receiptPath')
        self.fails('REPRESENTED_SCOPE_NEEDS_RECEIPT')

    def test_validation_does_not_mutate_inputs_or_producer_records(self):
        original = copy.deepcopy((self.assigned, self.decisions, self.admitted, self.consumer_models, self.consumer_facts))
        self.assertTrue(self.run_review()['complete'])
        self.assertEqual(original, (self.assigned, self.decisions, self.admitted, self.consumer_models, self.consumer_facts))


if __name__ == '__main__':
    unittest.main()
