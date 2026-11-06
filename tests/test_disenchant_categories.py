"""Category scope broadens research eligibility without changing counting math."""
import copy
import json
import sys
import unittest

sys.path.insert(0, 'tools')
import disenchant_categories as categories
import evidence_check


def mapping(item, rarity=3, class_id=4, expansion=11):
    return {'inputItemID': item, 'expansionID': expansion, 'inputRarity': rarity,
            'inputClassID': class_id,
            'gearKey': f'gear:{expansion}:{rarity}:' + ('weapon' if class_id == 2 else 'armor'),
            'classificationBasis': 'Test reviewed catalog category', 'provenanceURLs': [],
            'studyConditionVerified': False, 'provisional': True, 'itemSpecificException': False}


def cohort(study, item, casts, outputs, **extra):
    return {'studyKey': study, 'inputItemID': item, 'completedCastsReported': casts,
            'outputs': outputs, 'method': 'Disenchant', 'inputsPerCast': 1,
            'expansionID': 11, 'sourceID': 'source', **extra}


def review(*cohorts):
    return {'sources': [{'id': 'source', 'url': 'https://example.com/original',
                         'sourceType': 'WOWHEAD_LOOTER_AGGREGATE'}], 'cohorts': list(cohorts)}


def output(item, hits=None, units=None, **extra):
    row = {'outputItemID': item, **extra}
    if hits is not None:
        row['hitCasts'] = hits
    if units is not None:
        row['totalUnitsReported'] = units
    return row


def material(record, item):
    return next(row for row in record['materials'] if row['id'] == item)


class DisenchantCategoryTests(unittest.TestCase):
    def test_counted_cohorts_pool_by_operations_not_rows_or_item_mean(self):
        data = review(cohort('a', 100, 100, [output(1, 10, 20), output(2, 50, 50)]),
                      cohort('b', 101, 300, [output(1, 150, 450)]))
        records, notes = categories.build(data, {'schemaVersion': 1, 'mappings': [mapping(100), mapping(101)]})
        self.assertEqual(len(records), 1)
        record = records[0]
        self.assertNotIn('inputItemID', record)
        self.assertEqual(record['gearKey'], 'gear:11:3:armor')
        self.assertEqual(record['memberInputItemIDs'], [100, 101])
        self.assertEqual(record['categorySourceStudyIDs'], ['a', 'b'])
        self.assertEqual(record['categoryObservedCasts'], 400)
        self.assertEqual(record['samples'], 200)  # existing unknown-skill half weight
        one = material(record, 1)
        self.assertEqual(one['dropChance']['value'], .4)
        self.assertEqual(one['expectedQuantity']['value'], 1.175)
        self.assertEqual(one['dropChance']['samples'], 200)
        # b did not report output2: its 300 casts are not a zero observation.
        two = material(record, 2)
        self.assertEqual(two['dropChance']['value'], .5)
        self.assertEqual(two['dropChance']['samples'], 50)
        self.assertEqual(two['expectedQuantity']['samples'], 50)
        self.assertEqual(notes['used'], 2)

    def test_repeat_lineage_counts_once_and_largest_snapshot_wins(self):
        data = review(cohort('same-study', 100, 10, [output(1, 1, 1)]),
                      cohort('same-study', 100, 20, [output(1, 8, 16)]))
        records, notes = categories.build(data, {'schemaVersion': 1, 'mappings': [mapping(100)]})
        self.assertEqual(notes['duplicates'], 1)
        self.assertEqual(records[0]['categoryObservedCasts'], 20)
        self.assertEqual(records[0]['categorySourceStudyIDs'], ['same-study'])
        self.assertEqual(material(records[0], 1)['dropChance']['value'], .4)

    def test_expansion_rarity_and_armor_weapon_each_separate_categories(self):
        scopes = [mapping(100), mapping(101, rarity=4), mapping(102, class_id=2), mapping(103, expansion=10)]
        data = review(*(cohort(str(scope['inputItemID']), scope['inputItemID'], 10, [output(1, 5, 5)],
                              expansionID=scope['expansionID']) for scope in scopes))
        records, _ = categories.build(data, {'schemaVersion': 1, 'mappings': scopes})
        self.assertEqual({record['gearKey'] for record in records},
                         {'gear:11:3:armor', 'gear:11:4:armor', 'gear:11:3:weapon', 'gear:10:3:armor'})

    def test_max_specialization_units_are_separate_and_do_not_invent_chance(self):
        data = review(cohort('looter', 100, 100, [output(1, 80, 80)]),
                      cohort('max-spec', 100, 100, [output(1, units=150)],
                             specialization='Delegate and Shard Supplier maxed'))
        records, _ = categories.build(data, {'schemaVersion': 1, 'mappings': [mapping(100)]})
        ordinary = next(record for record in records if not record['categoryReferenceOnly'])
        skilled = next(record for record in records if record['categoryReferenceOnly'])
        self.assertEqual(ordinary['categoryObservedCasts'], 100)
        self.assertEqual(material(ordinary, 1)['dropChance']['value'], .8)
        self.assertEqual(skilled['gearKey'], ordinary['gearKey'])
        self.assertEqual(skilled['categoryContext'], 'max-specialization')
        self.assertEqual(material(skilled, 1)['expectedQuantity']['value'], 1.5)
        self.assertEqual(material(skilled, 1)['dropChance']['status'], 'unknown')
        self.assertEqual(material(skilled, 1)['minQuantity']['status'], 'unknown')

    def test_future_explicitly_scoped_cohort_needs_no_item_mapping(self):
        data = review(cohort('future', 999, 50, [output(1, 20, 30)],
                             inputRarity=2, inputClassID=2))
        records, _ = categories.build(data, {'schemaVersion': 1, 'mappings': []})
        self.assertEqual(records[0]['gearKey'], 'gear:11:2:weapon')
        self.assertEqual(records[0]['memberInputItemIDs'], [999])
        self.assertFalse(records[0]['categoryScopeProvisional'])

    def test_future_explicit_native_evidence_joins_and_mismatch_is_respected(self):
        native = {'method': 'Disenchant', 'input': 777, 'inputPerCast': 1, 'casts': 100,
                  'outputs': [{'item': 1, 'castsWithDrop': 40, 'totalQuantity': 80}],
                  'source': 'https://example.com/native', 'lineage': 'future-native',
                  'observedDate': None, 'patch': None, 'stale': False,
                  'expansionID': 0, 'inputRarity': 4, 'inputClassID': 2}
        report = {'usable': [{'kind': 'evidence', 'id': 'future.json#0', 'record': native}]}
        records, _ = categories.build(review(), {'schemaVersion': 1, 'mappings': []}, report)
        self.assertEqual(evidence_check.check_evidence(native), [])
        self.assertEqual(records[0]['gearKey'], 'gear:0:4:weapon')
        self.assertEqual(material(records[0], 1)['expectedQuantity']['value'], .8)
        report['usable'].append({'kind': 'check', 'id': 'check.json#0',
                                 'record': {'recordId': 'future.json#0', 'result': 'mismatch'}})
        self.assertEqual(categories.build(review(), {'schemaVersion': 1, 'mappings': []}, report)[0], [])

    def test_native_copy_of_reviewed_study_does_not_double_category_counts(self):
        data = review(cohort('same', 100, 100, [output(1, 40, 80)]))
        mappings = {'schemaVersion': 1, 'mappings': [mapping(100)]}
        entries, _, _ = categories.native_records(data, mappings)
        native = copy.deepcopy(entries[0]['record'])
        native['input'] = 100
        native['referenceContextID'] = 'same'
        records, notes = categories.build(data, mappings,
                                         {'usable': [{'kind': 'evidence', 'id': 'native#0', 'record': native}]})
        self.assertEqual(len(records), 1)
        self.assertEqual(records[0]['categoryObservedCasts'], 100)
        self.assertEqual(notes['duplicates'], 1)

    def test_invalid_counts_and_inconsistent_categories_fail(self):
        mappings = {'schemaVersion': 1, 'mappings': [mapping(100)]}
        for bad_output in (output(1, 101, 20), output(1, 20, 1.5)):
            with self.assertRaises(ValueError):
                categories.build(review(cohort('bad', 100, 100, [bad_output])), mappings)
        bad_mappings = copy.deepcopy(mappings)
        bad_mappings['mappings'][0]['gearKey'] = 'gear:11:3:weapon'
        with self.assertRaises(ValueError):
            categories.build(review(), bad_mappings)

    def test_reviewed_artifact_has_all_23_inputs_and_generated_file_is_current(self):
        data = json.loads(categories.SOURCE.read_text())
        mappings = json.loads(categories.MAPPINGS.read_text())
        records, notes = categories.build(data, mappings, evidence_check.check_folder())
        ordinary = [record for record in records if not record['categoryReferenceOnly']]
        self.assertEqual(len(ordinary), 5)
        self.assertEqual(sum(len(record['memberInputItemIDs']) for record in ordinary), 23)
        self.assertEqual(notes['used'], 24)
        self.assertEqual(sum(record['categoryObservedCasts'] for record in ordinary),
                         sum(cohort['completedCastsReported'] for cohort in data['cohorts']
                             if cohort['studyKey'].startswith('wowhead-looter-')))
        self.assertEqual(categories.OUTPUT.read_text(), categories.render(records))


if __name__ == '__main__':
    unittest.main()
