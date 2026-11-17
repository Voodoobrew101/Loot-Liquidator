"""S21: preserve distinct material totals while counting copied cohorts once."""
import sys
import unittest

sys.path.insert(0, 'research/v3/tools')

sys.path.insert(0, 'tools')
import research_v3_to_baselines as v3


class MaterialIdentityTests(unittest.TestCase):
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

    def test_case_variant_unknown_family_is_one_original(self):
        # The March 15 Tranquility Bloom report was transcribed twice with
        # different study keys and capitalization, not two experiments.
        import build_estimates as live
        def row(file, key, name, rank=None):
            return dict(_file=file, studyKey=key, type='drop', sourceKind='study',
                        method='Mill', inputName='Tranquility Bloom', inputRank=2,
                        outputName=name, outputRank=rank, outputItemID=None,
                        source={'url': 'https://www.reddit.com/r/woweconomy/comments/1rteoqr/'},
                        casts=None, totalQuantity=1473, inputsPerCast=None)
        first = row('research/v3/evidence/midnight/a.jsonl', 'one-source-a', 'Pigment (unspecified)')
        second = row('research/v3/evidence/midnight/b.jsonl', 'one-source-b', 'pigment (unspecified)')
        rows = [first, second]
        names = live.name_maps(rows)
        vectors, _, pooled = live.study_vectors(rows)
        dropped = live.misplaced_copies(rows, names, vectors, pooled)
        self.assertEqual(dropped, {id(second): 'copy:caseVariantGroup'})
        # Missing cast denominators cannot be priced as observed means.
        estimated, _, usage = live.analyze(rows)
        self.assertFalse(any(e.get('averageSource') == 'measured' for e in estimated))
        self.assertEqual(usage[id(second)]['reason'], 'copy:caseVariantGroup')
        # An explicitly different material quality cannot be merged.
        ranked = [row('a.jsonl', 'one-source-a', 'Pigment', 1),
                  row('b.jsonl', 'one-source-b', 'pigment', 2)]
        v2, _, p2 = live.study_vectors(ranked)
        self.assertFalse(live.misplaced_copies(ranked, live.name_maps(ranked), v2, p2))
        # Numbered independent batches are protected even with equal totals.
        batches = [row('a.jsonl', 'same-batch-1', 'Pigment (unspecified)'),
                   row('a.jsonl', 'same-batch-2', 'pigment (unspecified)')]
        vb, _, pb = live.study_vectors(batches)
        self.assertFalse(live.misplaced_copies(batches, live.name_maps(batches), vb, pb))


if __name__ == '__main__':
    # The immutable upstream calculator leaves read handles to garbage collection.
    # Keep that known ResourceWarning noise separate from numerical assertions.
    unittest.main(warnings='ignore')
