"""S21: preserve distinct material totals while counting copied cohorts once."""
import sys
import unittest
from collections import Counter

sys.path.insert(0, 'tools')
import research_v3_to_baselines as v3
from research_v3_evidence import build_field_support


class MaterialIdentityTests(unittest.TestCase):
    def test_lone_replacement_cannot_delete_an_unrelated_reused_id(self):
        module = v3.load_calculator(v3.DEFAULT_SNAPSHOT)
        original = dict(id='reused', method='Prospect', inputItemID=194545, outputItemID=192851)
        for changes in ({'method': 'Disenchant'}, {'inputItemID': 190311}):
            replacement = dict(original, id='repair', replaces='reused')
            replacement.update(changes)
            notes = Counter()
            self.assertEqual(v3.resolve_replacements([original, replacement], module, notes), [original])
            self.assertEqual(notes, {'replacement method or input does not match source': 1})

    def test_lone_replacement_can_enrich_or_correct_item_identity(self):
        module = v3.load_calculator(v3.DEFAULT_SNAPSHOT)
        original = dict(id='original', method='Prospect', inputItemID=None, inputName='Prismatic',
                        outputItemID=192849, outputName='Eternity Amber')
        correction = dict(original, id='correction', replaces='original', inputItemID=194545,
                          inputName='Prismatic Ore', outputItemID=192851)
        for same_input in (False, True):
            source = dict(original, inputItemID=correction['inputItemID']) if same_input else original
            notes = Counter()
            self.assertEqual(v3.resolve_replacements([source, correction], module, notes), [correction])
            self.assertFalse(notes)

    def test_cohort_key_links_an_unlabelled_copy_but_not_independent_studies(self):
        def row(study, cohort=None, total=5, source='https://www.reddit.com/r/woweconomy/comments/zkay8v'):
            return dict(id=study, studyKey=study, _file=study + '.jsonl',
                        type='drop', sourceKind='study', source={'url': source},
                        inputItemID=190396, inputRank=2, outputItemID=192861,
                        outputName='Ysemerald', outputRank=3, casts=1000,
                        totalQuantity=total, cohortKey=cohort)

        module = v3.load_calculator(v3.DEFAULT_SNAPSHOT)
        labelled, copy = row('labelled', 'first'), row('copy')
        changed = row('changed', total=6)
        other_source = row('other-source', source='https://www.reddit.com/r/woweconomy/comments/other')
        rows = [labelled, copy, changed, other_source]
        vectors = module.study_vectors(rows)[0]
        identity = lambda r: module.study_identity(r, vectors)
        self.assertEqual(identity(labelled), identity(copy))
        self.assertNotEqual(identity(labelled), identity(changed))
        self.assertNotEqual(identity(labelled), identity(other_source))
        self.assertIsNone(copy['cohortKey'])

        # Identical numbers cannot resolve a copy to either of two explicitly
        # independent cohorts. Also verifies aliases reset between builds.
        second = row('second', 'second')
        vectors = module.study_vectors(rows + [second])[0]
        self.assertNotEqual(identity(labelled), identity(second))
        self.assertNotEqual(identity(copy), identity(labelled))
        self.assertNotEqual(identity(copy), identity(second))

    def test_equal_nonzero_totals_are_not_material_identity(self):
        module = v3.load_calculator(v3.DEFAULT_SNAPSHOT)
        amber = dict(outputName='Eternity Amber', outputItemID=None, totalQuantity=4)
        diamond = dict(outputName='Illimited Diamond', outputItemID=192870, totalQuantity=4)
        self.assertFalse(module.same_output(amber, diamond, {}))
        self.assertTrue(module.same_output(amber, dict(amber, outputItemID=192851), {}))
        self.assertFalse(module.same_output(amber, dict(diamond, totalQuantity=0), {}))

    def test_real_duplicated_eighty_cast_cohort_retains_both_materials(self):
        module = v3.load_calculator(v3.DEFAULT_SNAPSHOT)
        rows = module.load()
        # Two verbatim recordings of superbondez's 39-output Prismatic study.
        originals = [r for r in rows if r.get('id') == 'dragonflight-20261031-50044']
        self.assertEqual(len(originals), 1)
        results, _, _ = module.analyze(rows)
        amber = next(e for e in results if e['method'] == 'Prospect' and e['input'] == '194545'
                     and e['outputItemID'] == 'family:Eternity Amber')
        self.assertEqual(amber['studyCasts'], 80)
        self.assertAlmostEqual(amber['average'], 4 / 80)
        self.assertEqual(amber['averageSource'], 'measured')
        self.assertEqual(amber['chanceSource'], 'estimated')
        self.assertEqual(amber['rangeSource'], 'estimated')
        self.assertEqual(amber['studies'], 1)
        # Neither recording is rewritten to insert an unsupported output rank.
        self.assertIsNone(originals[0]['outputItemID'])

    def test_import_restores_family_without_changing_diamond(self):
        records = v3.build(v3.DEFAULT_SNAPSHOT)[0]
        record = next(r for r in records if r['recordID'] == 'evidence:v3:Prospect:194545:x5')
        outputs = {m['id']: m for m in record['materials']}
        amber, diamond = outputs[192849], outputs[192870]
        self.assertEqual(amber['rankIDs'], [192849, 192850, 192851])
        self.assertAlmostEqual(amber['expectedQuantity']['value'], 0.05)
        self.assertEqual(amber['expectedQuantity']['status'], 'measured')
        self.assertEqual(amber['dropChance']['status'], 'unknown')
        self.assertTrue(amber['dropChance']['inferenceBlocked'])
        self.assertAlmostEqual(diamond['expectedQuantity']['value'], 0.05)

    def test_runecloth_headband_classic_mirrors_share_the_same_five_casts(self):
        module = v3.load_calculator(v3.DEFAULT_SNAPSHOT)
        same_source = [
            ('wowhead-illusiondust-1115352-runecloth-headband-5', 'mop-classic',
             ('legacy-20261108-001', 'legacy-20261108-002')),
            ('wowhead-16204-1115352-five-headband-source-explicit-outcomes', 'cata',
             ('legacy-20261109-220005', 'legacy-20261109-220006')),
        ]
        outcomes = [(16204, 4, 'Rune Cloth Headband gave me Illusion Dust 4 out of 5 time'),
                    (16203, 1, 'the other was Greater Eternal Essance')]
        rows = []
        for study, flavor, record_ids in same_source:
            source = {'url': f'https://www.wowhead.com/{flavor}/item=16204/illusion-dust', 'author': '1115352'}
            for record_id, (output, hits, quote) in zip(record_ids, outcomes):
                rows.append(dict(id=record_id, _file=flavor + '.jsonl', studyKey=study, method='Disenchant',
                                 type='drop', sourceKind='study', inputItemID=13866, inputsPerCast=1, casts=5,
                                 source=source, outputItemID=output, castsWithDrop=hits, quote=quote))
        rows.append(dict(rows[1], id='independent', _file='independent.jsonl', studyKey='independent',
                         source={'url': 'https://www.wowhead.com/item=16203', 'author': '470030'},
                         casts=10, castsWithDrop=0, quote='nothing but Light Illusion Dust'))
        supported, _, _ = build_field_support(module, rows, module.name_maps(rows))
        occurrence = {e['outputItemID']: e['fieldSupport']['dropChance'] for e in supported}
        self.assertEqual((occurrence[16203]['hits'], occurrence[16203]['casts']), (1, 15))
        self.assertEqual((occurrence[16204]['hits'], occurrence[16204]['casts']), (4, 5))

    def test_magma_thresher_needs_a_verified_prospect_batch(self):
        module = v3.load_calculator(v3.DEFAULT_SNAPSHOT)
        source = {'url': 'https://www.wowhead.com/item=199344#comments:id=1234567', 'author': 'Test'}
        rough = dict(id='rough', _file='rough.jsonl', studyKey='same-source', method='Prospect', type='drop',
                     sourceKind='study', inputItemID=199344, outputItemID=192849, casts=20,
                     totalQuantity=4, source=source, cohortKey='fish-source')
        estimates, notes, _ = build_field_support(module, [rough], {})
        self.assertEqual(estimates, [])
        self.assertEqual(notes['batch size (inputs per cast) not stated or invalid'], 1)

        exact = dict(rough, id='exact', _file='exact.jsonl', inputsPerCast=5,
                     inputsProcessed=100, totalQuantity=None)
        estimates, notes, _ = build_field_support(module, [rough, exact], {})
        self.assertEqual(len(estimates), 1)
        self.assertEqual(estimates[0]['inputsPerCast'], 5)
        self.assertEqual(estimates[0]['fieldSupport']['expectedQuantity']['casts'], 20)
        self.assertEqual(notes['+operation size recovered from matching source'], 1)

        estimates, _, _ = build_field_support(module, [dict(exact, totalQuantity=4)], {})
        self.assertEqual(estimates[0]['inputsPerCast'], 5)


if __name__ == '__main__':
    # The immutable upstream calculator leaves read handles to garbage collection.
    # Keep that known ResourceWarning noise separate from numerical assertions.
    unittest.main(warnings='ignore')
