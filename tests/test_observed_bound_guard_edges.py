"""Independent boundary checks for observed-range versus hard-cap evidence.

These controlled cohorts exercise consistency rules; they are not game rates.
"""
import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import research_v3_to_baselines as producer


def cohort_fields(*, chance=1, mean=3, minimum=1, maximum=2):
    mean_cohort = {('cohort', 'recorded-mean')}
    bounds_cohort = {('cohort', 'other-observed-range')}
    fields = {
        'dropChance': {'value': chance, 'casts': 7, 'hits': chance * 7,
                       'status': 'measured', '_countedCohorts': mean_cohort},
        'expectedQuantity': {'value': mean, 'casts': 7, 'total': mean * 7,
                             'status': 'measured', '_countedCohorts': mean_cohort},
    }
    for name, value in [('minQuantity', minimum), ('maxQuantity', maximum)]:
        fields[name] = {'value': value, 'casts': 6, 'status': 'measured',
                        'basis': 'observed-sample', '_observedCohorts': bounds_cohort}
    return fields


def convert(fields):
    return producer.material(34054, [{'fieldSupport': fields}])


class ObservedRangeGuardEdges(unittest.TestCase):
    def assert_conflict_remains(self, fields):
        result = convert(fields)
        self.assertNotIn('observedBoundIndependence', result)
        self.assertTrue('heldExpectedQuantity' in result or 'heldDropChance' in result)
        held_name = 'expectedQuantity' if 'heldExpectedQuantity' in result else 'dropChance'
        self.assertTrue(result[held_name]['inferenceBlocked'])

    def test_disjoint_observed_max_preserves_both_estimates_and_original_range(self):
        fields = cohort_fields()
        original = copy.deepcopy(fields)
        result = convert(fields)
        self.assertEqual(result['expectedQuantity']['value'], 3)
        self.assertEqual(result['dropChance']['value'], 1)
        self.assertEqual(result['minQuantity']['value'], 1)
        self.assertEqual(result['maxQuantity']['value'], 2)
        self.assertEqual(result['observedBoundIndependence']['field'], 'maxQuantity')
        self.assertEqual(fields, original)

    def test_disjoint_observed_min_can_be_independent_of_another_cohort_mean(self):
        result = convert(cohort_fields(mean=1, minimum=2, maximum=3))
        self.assertEqual(result['expectedQuantity']['value'], 1)
        self.assertEqual(result['dropChance']['value'], 1)
        self.assertEqual(result['observedBoundIndependence']['field'], 'minQuantity')

    def test_positive_output_unit_minimum_is_never_a_cross_cohort_exception(self):
        self.assert_conflict_remains(cohort_fields(mean=.5, minimum=2, maximum=3))

    def test_zero_probability_and_zero_mean_conflicts_are_never_exempted(self):
        self.assert_conflict_remains(cohort_fields(chance=0, mean=1))
        self.assert_conflict_remains(cohort_fields(chance=1, mean=0))

    def test_same_cohort_or_missing_cohort_provenance_is_not_independent(self):
        for ids in [{('cohort', 'recorded-mean')}, set()]:
            fields = cohort_fields()
            fields['maxQuantity']['_observedCohorts'] = ids
            self.assert_conflict_remains(fields)
        fields = cohort_fields()
        fields['expectedQuantity']['_countedCohorts'] = set()
        self.assert_conflict_remains(fields)

    def test_declared_or_untyped_caps_keep_the_original_conflict_rules(self):
        for basis in ['declared-hard-cap', None]:
            fields = cohort_fields()
            if basis is None:
                fields['maxQuantity'].pop('basis')
            else:
                fields['maxQuantity']['basis'] = basis
            self.assert_conflict_remains(fields)

    def test_unmeasured_occurrence_quantity_or_bound_is_not_exempted(self):
        for field in ['dropChance', 'expectedQuantity', 'maxQuantity']:
            fields = cohort_fields()
            fields[field]['status'] = 'provisional'
            self.assert_conflict_remains(fields)


if __name__ == '__main__':
    unittest.main()
