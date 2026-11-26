import collections
from pathlib import Path
import sys
import unittest
sys.path.insert(0, 'tools')
from shared_disenchant_captures import compile_records, ROOT, SOURCES


class SharedCaptureTests(unittest.TestCase):
    def test_real_category_counts_and_deduplication(self):
        before = {p: p.read_bytes() for name in SOURCES
                  for p in (ROOT / 'research/integration/measured-captures' / name).glob('*.json')}
        row = compile_records()[0]
        self.assertEqual(row['gearKey'], 'gear:11:3:armor')
        self.assertNotIn('inputItemID', row)
        self.assertEqual(row['observedOperations'], 544)
        self.assertEqual(len(set(row['sourceRecordIDs'])), 544)
        self.assertEqual(sum(p['operations'] for p in row['sharedSourceProfiles']), 544)
        skill82 = next(p for p in row['sharedSourceProfiles'] if p['effectiveSkill'] == 82)
        self.assertEqual(skill82['operations'], 405)
        totals = {}
        for m in row['materials']:
            histogram = m['quantityCounts']
            self.assertEqual(sum(histogram.values()), 544)
            totals[m['id']] = sum(int(q) * count for q, count in histogram.items())
            self.assertAlmostEqual(m['expectedQuantity']['value'], totals[m['id']] / 544, places=6)
            self.assertGreater(m['expectedQuantity']['confidence'], 0)
        self.assertEqual(totals, {243602: 500, 243603: 44})
        self.assertEqual(before, {p: p.read_bytes() for p in before})

    def test_all_usable_uploaded_gear_categories(self):
        rows = compile_records()
        self.assertEqual({r['gearKey']: r['observedOperations'] for r in rows},
                         {'gear:11:3:armor': 544, 'gear:11:3:weapon': 3,
                          'gear:11:4:armor': 17, 'gear:11:4:weapon': 6})
        ids = [op for r in rows for op in r['sourceRecordIDs']]
        self.assertEqual(len(ids), 570)
        self.assertEqual(len(set(ids)), 570)
        for row in rows:
            self.assertNotIn('inputItemID', row)
            self.assertGreater(row['materials'][0]['expectedQuantity']['confidence'], 0)


if __name__ == '__main__':
    unittest.main()
