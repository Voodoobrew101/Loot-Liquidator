"""A new condition row cannot silently erase two exact reviewed source means."""
from collections import Counter
import copy
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
import warnings

sys.path.insert(0, 'tools')
import research_build_review as review
import research_published_priors as priors
import research_v3_to_baselines as v3


class PublishedMillingPriors(unittest.TestCase):
    def setUp(self):
        warnings.simplefilter('ignore', ResourceWarning)
        self.policy = json.loads(priors.POLICY.read_text(encoding='utf-8'))
        path = v3.DEFAULT_SNAPSHOT / self.policy['priors'][0]['sourceFile']
        wanted = {p['sourceRecordID'] for p in self.policy['priors']}
        self.rows = [json.loads(line) for line in path.read_text(encoding='utf-8').splitlines()
                     if line.strip() and json.loads(line).get('id') in wanted]

    def snapshot(self, root, rows):
        snapshot = root / 'snapshot'
        data = snapshot / 'research/v3'
        shutil.copytree(v3.DEFAULT_SNAPSHOT / 'research/v3/tools', data / 'tools')
        path = snapshot / self.policy['priors'][0]['sourceFile']
        path.parent.mkdir(parents=True)
        path.write_text(''.join(json.dumps(row) + '\n' for row in rows), encoding='utf-8')
        (data / 'evidence/conditions.jsonl').write_text(json.dumps({'id': 'new-condition', 'type': 'condition',
            'method': 'Mill', 'outputItemID': 222619, 'inputItemIDs': [210796, 210797],
            'requires': 'Unverified community milling quality skill band', 'requiresSkill': 253}) + '\n')
        for name in ('corrections.jsonl', 'conditions.jsonl', 'rate-changes.jsonl'):
            (data / name).write_text('')
        (snapshot / 'SNAPSHOT.json').write_text(json.dumps({'commit': 'c' * 40, 'branch': 'fixture', 'paths': v3.SNAPSHOT_PATHS}))
        return snapshot

    def test_exact_means_survive_while_conditional_empirical_control_stays_held(self):
        measured = dict(self.rows[0], id='unmatched-measured-cohort', studyKey='unmatched-measured-cohort',
                        casts=10, totalQuantity=500, averageShown=None, averagePer=None,
                        source={'url': 'https://example.test/independent-conditional-study'})
        matching = dict(measured, id='verified-matching-conditional-cohort', studyKey='verified-matching-conditional-cohort',
                        unlockState=True, source={'url': 'https://example.test/verified-unlock-study'})
        raw = copy.deepcopy(self.rows + [measured, matching])
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            snapshot = self.snapshot(root, raw)
            records, notes, *_ = v3.build(snapshot)
            self.assertEqual(len(records), 2)
            self.assertTrue(any('conditional cohort lacks matching unlock' in reason for reason in notes))
            for record in records:
                material = record['materials'][0]
                expected = 11.5 if record['inputItemID'] == 210796 else 13.5
                self.assertEqual(record['recordID'], 'evidence:v3:Mill:' + str(record['inputItemID']) + ':x10')
                self.assertEqual((record['inputCount'], record['recipeID'], material['id']), (10, 444181, 222619))
                self.assertEqual(material['expectedQuantity']['value'], expected)
                self.assertEqual(material['expectedQuantity']['samples'], 0)
                self.assertFalse(material['expectedQuantity']['sampleSizeKnown'])
                self.assertEqual(record['samples'], 0)
                self.assertTrue(record['baselineProfileAssumed'])
                self.assertEqual(record['baselineProfileConfidence'], 0)
                self.assertFalse(record['reviewedPublishedPrior']['conditionalEmpiricalGateBypassed'])
                for field in ('dropChance', 'minQuantity', 'maxQuantity'):
                    self.assertEqual(material[field]['status'], 'unknown')
                    self.assertNotIn('value', material[field])
            report = review.build_review(snapshot, root / 'no-local')
            by_id = {r['recordID']: r for r in report['rows']}
            for row in self.rows:
                self.assertEqual(by_id[row['id']]['disposition'], 'ADMITTED_AS_REVIEWED_PUBLISHED_PRIOR')
                self.assertEqual(by_id[row['id']]['observedSamplesAdded'], 0)
            self.assertEqual(by_id[measured['id']]['disposition'], 'PRESERVED_UNRESOLVED_CONDITIONAL_SCOPE')
            self.assertNotEqual(by_id[matching['id']]['disposition'], 'PRESERVED_UNRESOLVED_CONDITIONAL_SCOPE')
            self.assertEqual(by_id[matching['id']]['disposition'], 'ADMITTED_TO_BASELINE_PIPELINE')
        self.assertEqual(self.rows + [measured, matching], raw)

    def test_changed_source_hash_and_wrong_source_identity_never_get_the_exception(self):
        rows = [dict(row, _file=self.policy['priors'][0]['sourceFile']) for row in self.rows]
        rows[0]['averageShown'] += .01
        rows[1]['_file'] = 'unreviewed-copy.jsonl'
        records, notes = [], Counter()
        self.assertEqual(priors.preserve_published_priors(rows, records, notes), [])
        self.assertFalse(records)
        self.assertEqual(sum(notes.values()), 1)

    def test_existing_usable_records_are_never_overwritten_or_counted_again(self):
        rows = [dict(row, _file=self.policy['priors'][0]['sourceFile']) for row in self.rows]
        records = [{'recordID': prior['recordID'], 'materials': [{'id': 222619, 'expectedQuantity': {'value': 7}}]}
                   for prior in self.policy['priors']]
        original = copy.deepcopy(records)
        self.assertEqual(priors.preserve_published_priors(rows, records, Counter()), [])
        self.assertEqual(records, original)


if __name__ == '__main__':
    unittest.main()
