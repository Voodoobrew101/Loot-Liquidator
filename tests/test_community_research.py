"""Public export intake: immutable evidence, whole-cohort reviews and native counts."""
import base64
import copy
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import zlib

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import community_research as intake
from validate_craft_export import SCHEMA as CAST_SCHEMA


def sample():
    context = {'character': 'Example - Realm', 'simulated': False, 'profileKind': 'measured',
               'method': 'Disenchant', 'recipeID': 13262, 'profession': 'Enchanting',
               'baseSkill': 60, 'bonusSkill': 30, 'effectiveSkill': 90, 'skillLineID': 2909,
               'inputExpansionID': 11, 'specialization': 'none', 'specializationKnown': True,
               'specializationPoints': {}, 'buffsKnown': True, 'buffs': {}, 'buffStacks': {},
               'operationStats': [], 'fieldStatus': {'baseSkill': 'measured', 'bonusSkill': 'measured',
                                                    'effectiveSkill': 'measured', 'specialization': 'measured'}}
    provenance = {'sampleKind': 'RAW_CAST_LOG', 'numericTransformValidated': False,
                  'applyPolicy': 'NO_NUMERIC_TRANSFORM', 'independentReview': 'PENDING'}
    one = {'schemaVersion': CAST_SCHEMA, 'method': 'Disenchant', 'recipeID': 13262,
           'operationID': 'Cast-unique-1', 'successful': True, 'outputCoverage': 'complete',
           'contextID': 'context-1', 'studyID': 'study-1', 'character': 'Example - Realm', 'build': '70961',
           'gameMode': 'RETAIL', 'clientVersion': '12.1.5', 'provenance': provenance,
           'inputs': [{'itemID': 250001, 'quantity': 1, 'expansionID': 11, 'rarity': 4, 'classID': 4, 'itemLevel': 300}],
           'outputs': [{'itemID': 240001, 'quantity': 2, 'qualityRank': 1}]}
    zero = copy.deepcopy(one)
    zero.update(operationID='Cast-unique-2', outputs=[], zeroEvidence='operator-confirmed-empty', confirmedAt=42)
    return {'schemaVersion': one['schemaVersion'], 'artifactStatus': 'RESEARCH_ONLY_NOT_SHIPPED',
            'registryContract': 'profession-mechanics/0.2', 'automaticMechanicsPromotion': False,
            'page': 1, 'pages': 1, 'retainedRecords': 2, 'records': [one, zero],
            'contexts': {'context-1': context},
            'studies': {'study-1': {'character': 'Example - Realm', 'build': '70961', 'censored': False}}}


class CommunityIntakeTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.page = sample()
        self.source = self.root / 'user-export.json'

    def stage(self, page=None, issue=123):
        intake.write_json(self.source, page or self.page)
        return intake.stage(self.root, issue,
                            f'https://github.com/Voodoobrew101/Loot-Liquidator/issues/{issue}', [self.source])

    def review(self, manifest):
        staged = intake.load_submission(self.root, manifest['key'])[3]
        return {'schemaVersion': intake.REVIEW_SCHEMA, 'submissionSHA256': manifest['submissionSHA256'],
                'reviewer': 'daily review agent', 'rationale': 'Original complete Retail cast receipts, exact profile and saleable material verified.',
                'gameMode': 'RETAIL', 'scientificReviewComplete': True,
                'cohorts': [{'cohortID': b['communityCohortID'],
                    'outputs': {str(m['outputItemID']): {'decision': 'material', 'reason': 'Verified ordinary saleable enchanting material.'}
                                for m in b['materials']}} for b in staged['baselines']]}

    def approve(self, manifest, review=None):
        path = self.root / 'review-to-apply.json'
        intake.write_json(path, review or self.review(manifest))
        return intake.approve(self.root, manifest['key'], path)

    def test_reviewed_complete_counts_use_native_confidence_and_keep_profile(self):
        manifest = self.stage()
        source_bytes = self.source.read_bytes()
        self.assertEqual(intake.compile_reviewed(self.root)['processing'], [])
        self.approve(manifest)
        rows = intake.compile_reviewed(self.root)['processing']
        self.assertEqual(len(rows), 1)
        row, material = rows[0], rows[0]['materials'][0]
        self.assertEqual(row['baselineProfile']['effectiveSkill'], 90)
        self.assertEqual(row['baselineProfile']['specialization'], 'none')
        self.assertNotIn('character', row['baselineProfile'])
        self.assertEqual(row['observedOperations'], 2)
        self.assertEqual(row['samples'], 1)  # Native non-minimum weighting, no invented minimum.
        self.assertEqual(material['expectedQuantity']['value'], 1)
        self.assertEqual(material['dropChance']['value'], .5)
        self.assertEqual(material['minQuantity']['value'], 2)
        self.assertEqual(material['quantityCounts'], {'0': 1, '2': 1})
        self.assertEqual(material['expectedQuantity']['confidence'], intake.evidence_to_baselines.rate_confidence(.5, 1))
        self.assertEqual(row['sourceRecordIDs'], ['Cast-unique-1', 'Cast-unique-2'])
        self.assertEqual(row['patchBuild'], '70961')
        self.assertEqual(row['communityMeasuredProfile']['effectiveSkill'], 90)
        self.assertEqual(row['categoryItemLevelMin'], 300)
        self.assertEqual(row['categoryItemLevelMax'], 300)
        self.assertEqual(self.source.read_bytes(), source_bytes)
        self.assertEqual(self.approve(manifest), self.review(manifest))

    def test_actual_helper_output_matches_native_runtime(self):
        executable = os.environ.get('LUA51') or shutil.which('lua5.1')
        if not executable:
            self.skipTest('Lua 5.1 unavailable; full addon CI installs it for required runtime checks')
        manifest = self.stage()
        self.approve(manifest)
        output = self.root / 'compiled-community-fixture.lua'
        output.write_text(intake.render(intake.compile_reviewed(self.root)), encoding='utf-8')
        completed = subprocess.run([executable, 'tests/test_community_capture_runtime.lua', str(output)],
                                   cwd=intake.ROOT, text=True, capture_output=True)
        self.assertEqual(completed.returncode, 0, completed.stdout + completed.stderr)

    def test_stage_preserves_exact_bytes_and_is_idempotent(self):
        manifest = self.stage()
        folder = intake.submission_folder(self.root, manifest['key'])
        snapshot = {p.name: p.read_bytes() for p in folder.iterdir()}
        self.assertEqual((folder / 'source-page-001.json').read_bytes(), self.source.read_bytes())
        self.assertEqual(self.stage(), manifest)
        self.assertEqual({p.name: p.read_bytes() for p in folder.iterdir()}, snapshot)
        self.assertFalse(list(folder.glob('cast-page-*')))

    def test_missing_pages_and_duplicate_json_keys_leave_no_submission(self):
        self.page['pages'] = 2
        with self.assertRaisesRegex(ValueError, 'All pages'):
            self.stage()
        self.source.write_text('{"page":1,"page":2}', encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'Duplicate JSON'):
            intake.stage(self.root, 1, 'https://github.com/Voodoobrew101/Loot-Liquidator/issues/1', [self.source])
        self.assertFalse((self.root / intake.SUBMISSIONS).exists())

    def test_compact_and_multi_page_exports(self):
        raw = json.dumps(self.page).encode()
        compact = {'schemaVersion': 'loot-liquidator.cast-transfer/1', 'encoding': 'zlib-base64',
                   'uncompressedBytes': len(raw), 'payload': base64.b64encode(zlib.compress(raw)).decode()}
        manifest = self.stage(compact)
        self.approve(manifest)
        self.assertEqual(len(intake.compile_reviewed(self.root)['processing']), 1)
        first, second = copy.deepcopy(self.page), copy.deepcopy(self.page)
        first.update(pages=2, records=self.page['records'][:1])
        second.update(page=2, pages=2, records=self.page['records'][1:])
        path_one, path_two = self.root / 'one.json', self.root / 'two.json'
        intake.write_json(path_one, first); intake.write_json(path_two, second)
        result = intake.stage(self.root, 124, 'https://github.com/Voodoobrew101/Loot-Liquidator/issues/124', [path_two, path_one])
        self.assertEqual(result['duplicateOperationIDs'], ['Cast-unique-1', 'Cast-unique-2'])
        with self.assertRaisesRegex(ValueError, 'overlaps'):
            self.approve(result)

    def test_archived_capture_and_owner_transfer_cannot_be_recounted(self):
        folder = self.root / intake.CAPTURES / 'old-owner-capture'
        folder.mkdir(parents=True)
        intake.write_json(folder / 'source-transfer.json', self.page)
        manifest = self.stage()
        self.assertEqual(manifest['newOperationIDs'], [])
        self.assertEqual(len(manifest['duplicateOperationIDs']), 2)
        with self.assertRaisesRegex(ValueError, 'overlaps'):
            self.approve(manifest)

    def test_mutated_operation_is_conflict_not_new_measurement(self):
        original = self.stage()
        self.approve(original)
        self.page['records'][0]['outputs'][0]['quantity'] = 3
        changed = self.stage(issue=125)
        self.assertEqual(changed['conflictingOperationIDs'], ['Cast-unique-1'])
        self.assertEqual(changed['newOperationIDs'], [])
        with self.assertRaisesRegex(ValueError, 'overlaps'):
            self.approve(changed)

    def test_incomplete_or_censored_cohorts_stay_held(self):
        for modify in ('unresolved', 'censored'):
            page = copy.deepcopy(self.page)
            if modify == 'unresolved':
                page['records'][1]['outputCoverage'] = 'unresolved'
            else:
                page['studies']['study-1']['censored'] = True
            manifest = self.stage(page, issue=126 if modify == 'unresolved' else 127)
            staged = intake.load_submission(self.root, manifest['key'])[3]
            self.assertEqual(staged['baselines'], [])
            self.assertEqual(len(staged['excludedCohorts']), 1)

    def test_unresolved_output_holds_whole_cohort_and_verified_non_economic_does_not_enter(self):
        self.page['records'][0]['outputs'].append({'itemID': 227662, 'quantity': 1})
        manifest = self.stage()
        review = self.review(manifest)
        review['cohorts'][0]['outputs'].pop('227662')
        with self.assertRaisesRegex(ValueError, 'every observed output'):
            self.approve(manifest, review)
        review['cohorts'][0]['outputs']['227662'] = {'decision': 'hold', 'reason': 'Bound conditional knowledge reward, not saleable material.'}
        with self.assertRaisesRegex(ValueError, 'holds the whole cohort'):
            self.approve(manifest, review)
        review['cohorts'][0]['outputs']['227662'] = {'decision': 'non-economic', 'reason': 'Verified bound conditional knowledge reward, not saleable material.'}
        with self.assertRaisesRegex(ValueError, 'verifiedNonEconomic'):
            self.approve(manifest, review)
        review['cohorts'][0]['outputs']['227662']['verifiedNonEconomic'] = True
        self.approve(manifest, review)
        row = intake.compile_reviewed(self.root)['processing'][0]
        self.assertEqual([m['id'] for m in row['materials']], [240001])
        self.assertEqual(row['communityNonEconomicOutputItemIDs'], [227662])

    def test_input_refunds_stay_staged_until_net_consumption_is_supported(self):
        # A structurally valid returned input cannot silently be valued at its
        # nominal consumed quantity when the current runtime bypasses scaling.
        for record in self.page['records']:
            record['nominalInputs'] = copy.deepcopy(record['inputs'])
            record['inputs'][0]['quantity'] = 0
            record['resultMetadata'] = [{'operationID': 5 if record['operationID'].endswith('1') else 6,
                                        'resourcesReturned': [{'quantity': 1, 'reagent': {'itemID': 250001}}]}]
        manifest = self.stage()
        staged = intake.load_submission(self.root, manifest['key'])[3]
        self.assertEqual(staged['baselines'][0]['expectedInputsConsumed'][0]['expectedQuantity'], 0)
        with self.assertRaisesRegex(ValueError, 'Input refunds'):
            self.approve(manifest)
        self.assertFalse((intake.submission_folder(self.root, manifest['key']) / 'review.json').exists())

    def test_review_cannot_approve_wrong_hash_unknown_cohort_or_non_retail(self):
        manifest = self.stage()
        review = self.review(manifest)
        for key, value, reason in [('submissionSHA256', 'bad', 'checksum'),
                                   ('gameMode', 'CLASSIC', 'Retail'),
                                   ('scientificReviewComplete', False, 'Retail')]:
            changed = copy.deepcopy(review); changed[key] = value
            with self.assertRaisesRegex(ValueError, reason):
                self.approve(manifest, changed)
        review['cohorts'][0]['cohortID'] = 'cohort-unknown'
        with self.assertRaisesRegex(ValueError, 'Unknown'):
            self.approve(manifest, review)

    def test_source_or_staged_tampering_fails_compilation(self):
        manifest = self.stage()
        self.approve(manifest)
        path = intake.submission_folder(self.root, manifest['key']) / 'source-page-001.json'
        path.write_bytes(path.read_bytes() + b' ')
        with self.assertRaisesRegex(ValueError, 'checksum'):
            intake.compile_reviewed(self.root)

    def test_submission_paths_and_issue_urls_are_restricted(self):
        with self.assertRaisesRegex(ValueError, 'submission key'):
            intake.submission_folder(self.root, '../outside')
        intake.write_json(self.source, self.page)
        with self.assertRaisesRegex(ValueError, 'Source URL'):
            intake.stage(self.root, 123, 'https://example.com/issues/123', [self.source])

    def test_unknown_profile_and_unknown_de_item_level_stay_staged_only(self):
        for field in ('effectiveSkill', 'specializationKnown', 'buffsKnown', 'itemLevel'):
            page = copy.deepcopy(self.page)
            if field == 'itemLevel':
                for record in page['records']:
                    del record['inputs'][0][field]
            else:
                del page['contexts']['context-1'][field]
            manifest = self.stage(page, issue=200 + len(field))
            with self.assertRaises(ValueError):
                self.approve(manifest)
            self.assertFalse((intake.submission_folder(self.root, manifest['key']) / 'review.json').exists())

    def test_unknown_field_status_cannot_be_promoted_by_present_numbers(self):
        for field in ('effectiveSkill', 'baseSkill', 'bonusSkill', 'specialization'):
            page = copy.deepcopy(self.page)
            page['contexts']['context-1']['fieldStatus'][field] = 'unknown'
            manifest = self.stage(page, issue=300 + len(field))
            with self.assertRaisesRegex(ValueError, 'Known'):
                self.approve(manifest)

    def test_simulation_and_non_retail_source_are_never_approved(self):
        page = copy.deepcopy(self.page)
        page['contexts']['context-1']['simulated'] = True
        with self.assertRaisesRegex(ValueError, 'simulation'):
            self.stage(page)
        page = copy.deepcopy(self.page)
        for record in page['records']:
            record['gameMode'] = 'CLASSIC'
        manifest = self.stage(page)
        with self.assertRaisesRegex(ValueError, 'Retail'):
            self.approve(manifest)

    def test_malformed_untrusted_shapes_fail_without_writing_approval(self):
        page = copy.deepcopy(self.page)
        page['records'][0]['provenance'] = []
        with self.assertRaisesRegex(ValueError, 'Malformed'):
            self.stage(page)
        page = copy.deepcopy(self.page)
        page['contexts']['context-1']['fieldStatus'] = []
        manifest = self.stage(page)
        with self.assertRaisesRegex(ValueError, 'field status'):
            self.approve(manifest)

    def test_later_archival_cannot_silently_double_approved_operations(self):
        manifest = self.stage()
        self.approve(manifest)
        folder = self.root / intake.CAPTURES / 'later-owner-capture'
        folder.mkdir(parents=True)
        intake.write_json(folder / 'cast-page-001.json', self.page)
        with self.assertRaisesRegex(ValueError, 'overlaps'):
            intake.compile_reviewed(self.root)

    def test_bypassing_approve_with_two_reviews_cannot_double_count(self):
        one = self.stage()
        two = self.stage(issue=130)
        self.approve(one)
        # A manually copied/incorrectly reviewed second submission cannot evade
        # the compile-time operation-ID gate.
        intake.write_json(intake.submission_folder(self.root, two['key']) / 'review.json', self.review(two))
        with self.assertRaisesRegex(ValueError, 'overlaps'):
            intake.compile_reviewed(self.root)

    def test_scope_encodings_are_preserved_and_context_era_mismatch_is_held(self):
        self.page['contexts']['context-1']['specializationEncoding'] = 'invested-points'
        manifest = self.stage()
        self.approve(manifest)
        row = intake.compile_reviewed(self.root)['processing'][0]
        self.assertEqual(row['communityMeasuredProfile']['specializationEncoding'], 'invested-points')
        page = copy.deepcopy(self.page)
        page['contexts']['context-1']['inputExpansionID'] = 9
        for record in page['records']:
            record['operationID'] += '-other'
        second = self.stage(page, issue=131)
        with self.assertRaisesRegex(ValueError, 'expansion'):
            self.approve(second)

    def test_non_de_requires_measured_stats_and_preserves_native_stat_basis(self):
        context = self.page['contexts']['context-1']
        context.update(method='Mill', recipeID=51005, profession='Inscription',
                       operationStatsIncludeSpecialization=True, skillBasis='recipe-operation',
                       operationBaseSkill=60, operationBonusSkill=30, applyConcentration=False)
        for record in self.page['records']:
            record.update(method='Mill', recipeID=51005)
            record['inputs'][0]['quantity'] = 5
        manifest = self.stage()
        with self.assertRaisesRegex(ValueError, 'operation stats'):
            self.approve(manifest)
        context['fieldStatus']['operationStats'] = 'measured'
        second = self.stage(issue=132)
        self.approve(second)
        row = intake.compile_reviewed(self.root)['processing'][0]
        self.assertTrue(row['communityMeasuredProfile']['operationStatsIncludeSpecialization'])
        self.assertEqual(row['communityMeasuredProfile']['skillBasis'], 'recipe-operation')
        self.assertFalse(row['communityMeasuredProfile']['applyConcentration'])

    def test_actual_existing_recycling_and_de_source_ids_are_indexed(self):
        known = intake.existing_operations(intake.ROOT)
        recycling = json.loads((intake.ROOT / intake.CAPTURES / '2026-11-07-recycling-200-casts/coverage-review.json').read_text())
        disenchant = json.loads((intake.ROOT / intake.CAPTURES / '2026-11-22-reviewed-disenchant-subset/coverage-review.json').read_text())
        self.assertTrue(set(recycling['operationIDs']).issubset(known))
        self.assertTrue({op for group in disenchant['groups'] for op in group['operationIDs']}.issubset(known))


if __name__ == '__main__':
    unittest.main()
