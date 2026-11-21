import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest
from collections import Counter

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import reviewed_source_catalogue as catalogue


class ReviewedCatalogueTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.source_file = 'research/v3/evidence/legacy/source.jsonl'
        self.source = {'id': 'original', 'method': 'Mill', 'inputItemID': 765,
                       'outputItemID': 39151, 'totalQuantity': 20,
                       'casts': None, 'studyKey': 'one-original-cohort',
                       'source': {'url': 'https://example.org/original'}}
        self.write_source()
        self.ref = {'sourceFile': self.source_file, 'sourceRecordID': 'original', 'line': 1,
                    'rawSHA256': catalogue.canonical_hash(self.source)}
        self.model = {'recordID': 'evidence:reviewed-backlog:one', 'method': 'Mill',
                      'inputItemID': 765, 'inputCount': 1, 'expansionID': 0,
                      'sourceKey': 'example.org/original', 'sourceStudyKey': 'one-original-cohort',
                      'sourceURL': 'https://example.org/original',
                      'baselineProfile': {'skill': 0, 'stats': {}, 'specializationPoints': {}},
                      'baselineProfileAssumed': True,
                      'assumptions': ['Current applicability is an explicit zero-confidence source prior'],
                      'sourceRows': [self.ref],
                      'materials': [{'id': 39151, 'expectedQuantity': {'value': .4,
                          'derivation': {'kind': 'ratio', 'numerator': 20, 'denominator': 50,
                                         'denominatorMeaning': 'reported-net-input-stock'}}}]}

    def tearDown(self):
        self.temp.cleanup()

    def write_source(self):
        path = self.root / self.source_file
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(self.source) + '\n', encoding='utf-8')

    def policy(self, models=None, facts=None):
        path = self.root / catalogue.CATALOGUE / 'admitted-models.json'
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps({'schemaVersion': 1, 'revision': 'reviewed-backlog/1',
                                    'models': models if models is not None else [self.model],
                                    'facts': facts or []}), encoding='utf-8')

    def build(self, rows=None):
        records, notes = [], Counter()
        source = dict(self.source, _file=self.source_file)
        catalogue.preserve_reviewed_backlog(rows or [source], records, notes, self.root)
        return records, notes

    def test_explicit_input_mean_does_not_create_observed_counts_or_probability(self):
        before = copy.deepcopy(self.source)
        self.policy()
        records, _ = self.build()
        record = records[0]
        self.assertEqual(record['materials'][0]['expectedQuantity']['value'], .4)
        self.assertEqual(record['samples'], 0)
        self.assertFalse(record['sampleSizeKnown'])
        self.assertTrue(record['materials'][0]['dropChance']['inferenceBlocked'])
        self.assertEqual(record['materials'][0]['expectedQuantity']['modelConfidenceCap'], 0)
        self.assertEqual(self.source, before)

    def test_scoped_field_replacement_preserves_source_and_other_fields(self):
        self.model['supersedesSourceFields'] = [dict(self.ref, fields=['expectedQuantity'])]
        self.policy()
        row = dict(self.source, _file=self.source_file)
        before = copy.deepcopy(row)
        result = catalogue.apply_reviewed_field_replacements([row], self.root, Counter())
        self.assertEqual(result[0]['_reviewedSupersededFields'], ['expectedQuantity'])
        self.assertEqual(row, before)
        self.assertEqual(result[0]['totalQuantity'], 20)
        self.assertEqual(len(self.build()[0]), 1)

    def test_json_pointer_preserves_exact_lead_scope(self):
        path = self.root / 'lead.json'
        path.write_text(json.dumps({'leads': [self.source, {'id': 'unrelated'}]}, indent=2))
        ref = {'sourceFile': 'lead.json', 'jsonPointer': '/leads/0',
               'rawSHA256': catalogue.canonical_hash(self.source)}
        proof, reason = catalogue.source_rows(self.root, [ref])
        self.assertIsNone(reason)
        self.assertEqual(proof[0]['sourceRecordID'], 'original')
        changed = copy.deepcopy(self.source); changed['totalQuantity'] = 21
        path.write_text(json.dumps({'leads': [changed]}))
        self.assertEqual(catalogue.source_rows(self.root, [ref])[1], 'reviewed source row changed')

    def test_changed_replacement_proof_keeps_original_baseline_active(self):
        self.model['supersedesSourceFields'] = [dict(self.ref, fields=['expectedQuantity'], rawSHA256='0'*64)]
        self.policy()
        row = dict(self.source, _file=self.source_file)
        result = catalogue.apply_reviewed_field_replacements([row], self.root, Counter())
        self.assertNotIn('_reviewedSupersededFields', result[0])
        self.assertEqual(self.build()[0], [])

    def test_replacement_cannot_mask_a_field_without_replacement_value(self):
        self.model['supersedesSourceFields'] = [dict(self.ref, fields=['dropChance'])]
        self.policy()
        with self.assertRaisesRegex(ValueError, 'replacement value'):
            catalogue.apply_reviewed_field_replacements([dict(self.source, _file=self.source_file)], self.root, Counter())

    def test_nontransferable_field_remains_a_source_fact_without_old_numeric_use(self):
        fact = {'factID': 'source-profile-only', 'metric': 'sourceProfileMeanUnitsPerInput',
                'value': .4, 'unit': 'gross-input', 'confidence0to100': 0,
                'sourceSupportConfidence': 20, 'sourceRows': [self.ref]}
        self.policy(models=[], facts=[fact])
        path = self.root / catalogue.CATALOGUE / 'admitted-models.json'
        policy = json.loads(path.read_text())
        policy['sourceFieldExclusions'] = [{'sourceRows': [self.ref], 'fields': ['expectedQuantity'],
            'factIDs': [fact['factID']], 'reason': 'The source mean has an identified invested profile without a supported current-profile inverse.',
            'futureEvidenceTrigger': 'A source allocation/operation curve identifying this exact profile transfer.'}]
        path.write_text(json.dumps(policy))
        row = dict(self.source, _file=self.source_file)
        result = catalogue.apply_reviewed_field_replacements([row], self.root, Counter())
        self.assertEqual(result[0]['_reviewedSupersededFields'], ['expectedQuantity'])
        self.assertNotIn('_reviewedSupersededFields', row)
        self.assertEqual(catalogue.reviewed_context_facts(self.root)['facts'][0]['value'], .4)
        self.assertEqual(self.build()[0], [])
        policy['sourceFieldExclusions'][0]['factIDs'] = ['missing-fact']
        path.write_text(json.dumps(policy))
        with self.assertRaisesRegex(ValueError, 'retained source facts'):
            catalogue.apply_reviewed_field_replacements([row], self.root, Counter())

    def test_changed_source_expires_only_its_admission(self):
        other = copy.deepcopy(self.model)
        other['recordID'] += ':other'
        other['sourceRows'] = [dict(self.ref, rawSHA256='0' * 64)]
        self.policy([self.model, other])
        records, notes = self.build()
        self.assertEqual([r['recordID'] for r in records], [self.model['recordID']])
        self.assertEqual(sum(notes.values()), 2)
        self.assertTrue(any('source row changed' in reason for reason in notes))

    def test_correction_change_expires_affected_model(self):
        self.model['sourceRows'][0]['effectiveSHA256'] = catalogue.canonical_hash(self.source)
        self.policy()
        changed = dict(self.source, _file=self.source_file, inputsProcessed=70)
        records, notes = self.build([changed])
        self.assertEqual(records, [])
        self.assertEqual(notes['reviewed backlog model held: reviewed source correction layer changed'], 1)

    def test_source_path_cannot_leave_snapshot(self):
        self.model['sourceRows'][0]['sourceFile'] = '../outside.jsonl'
        self.policy()
        with self.assertRaisesRegex(ValueError, 'leaves its pinned snapshot'):
            self.build()

    def test_positive_conditional_ratio_cannot_be_unconditional_ev(self):
        self.model['materials'][0]['expectedQuantity']['derivation']['denominatorMeaning'] = 'positive-material-events'
        self.policy()
        with self.assertRaisesRegex(ValueError, 'not unconditional EV'):
            self.build()

    def test_reported_ratio_is_recalculated(self):
        self.model['materials'][0]['expectedQuantity']['value'] = .5
        self.policy()
        with self.assertRaisesRegex(ValueError, 'does not reproduce'):
            self.build()

    def test_source_table_fraction_has_zero_active_samples(self):
        self.model['materials'] = [{'id': 39151, 'dropChance': {'value': .2,
            'derivation': {'kind': 'source-table-fraction', 'numerator': 2, 'denominator': 10,
                           'denominatorMeaning': 'source-table-count'}}}]
        self.policy()
        records, _ = self.build()
        field = records[0]['materials'][0]['dropChance']
        self.assertEqual(field['value'], .2)
        self.assertEqual(field['samples'], 0)
        self.assertFalse(field['sampleSizeKnown'])
        self.assertNotIn('value', records[0]['materials'][0]['expectedQuantity'])

    def test_uniform_positive_stack_prior_requires_explicit_formula(self):
        self.model['materials'][0]['expectedQuantity'] = {'value': .4,
            'derivation': {'kind': 'uniform-positive-stack-reference', 'sourceFraction': .2,
                           'lower': 1, 'upper': 3}}
        self.policy()
        self.assertEqual(self.build()[0][0]['materials'][0]['expectedQuantity']['value'], .4)

    def test_unknown_or_duplicate_identities_are_rejected(self):
        for field in ('inputItemID', 'expansionID'):
            with self.subTest(field=field):
                model = copy.deepcopy(self.model)
                model[field] = None
                self.policy([model])
                with self.assertRaises(ValueError):
                    self.build()
        self.policy([self.model, self.model])
        with self.assertRaisesRegex(ValueError, 'Duplicated'):
            self.build()

    def test_context_facts_are_not_inserted_into_processing_records(self):
        fact = {'factID': 'positive-units', 'method': 'Disenchant', 'inputItemID': 99,
                'outputItemID': 100, 'metric': 'conditionalMeanUnitsPerPositiveEvent',
                'value': 2, 'unit': 'positive-material-event', 'confidence0to100': 0,
                'sourceRows': [self.ref]}
        self.policy(models=[], facts=[fact])
        self.assertEqual(self.build()[0], [])
        self.assertEqual(catalogue.reviewed_context_facts(self.root)['facts'][0]['value'], 2)
        self.source['totalQuantity'] = 100
        self.write_source()
        self.assertEqual(catalogue.reviewed_context_facts(self.root)['facts'], [])

    def test_provenance_retains_real_source_counts_without_promoting_them(self):
        self.model['reportedObservationCounts'] = {'actualReportedCasts': 1146, 'outputEventsUnknown': True}
        self.policy()
        record = self.build()[0][0]
        self.assertEqual(record['reviewedPublishedPrior']['reportedObservationCounts']['actualReportedCasts'], 1146)
        self.assertEqual(record['samples'], 0)
        self.assertEqual(record['reviewedPublishedPrior']['observedSamplesAdded'], 0)


if __name__ == '__main__':
    unittest.main()
