"""S21: preserve distinct material totals while counting copied cohorts once."""
import sys
import unittest

sys.path.insert(0, 'tools')
import research_v3_to_baselines as v3


class MaterialIdentityTests(unittest.TestCase):
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
        self.assertEqual(amber['dropChance']['status'], 'provisional')
        self.assertAlmostEqual(diamond['expectedQuantity']['value'], 0.05)


if __name__ == '__main__':
    # The immutable upstream calculator leaves read handles to garbage collection.
    # Keep that known ResourceWarning noise separate from numerical assertions.
    unittest.main(warnings='ignore')
