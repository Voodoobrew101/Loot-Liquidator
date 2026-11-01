#!/usr/bin/env python3
"""M02.2: characterization tests for research/v3/tools/build_estimates.py.

They pin what the estimator does TODAY on small synthetic fixtures, so later migration changes
(M05 identity, M06 denominators, M08 integration) show up as deliberate test edits, never as silent
drift. Tests whose names start with `test_known_defect_` describe behaviour the plan intends to change;
the task that changes it must update the test and say so in SESSION_LOG.md.

Run from the repository root:
  python3 -m unittest discover -s research/v3/migration/tests -v
"""
import json
import os
import shutil
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
import build_estimates as b  # noqa: E402


def drop(rid, **kw):
    r = {"id": rid, "type": "drop", "agent": "t", "recordedOn": "2026-10-31",
         "source": {"url": kw.pop("url", f"https://example.org/{rid}"), "title": None, "author": None,
                    "published": kw.pop("published", None)},
         "originalSource": None, "dataDate": None, "patch": None, "quote": None, "notes": None,
         "replaces": None, "studyKey": kw.pop("studyKey", rid), "sourceKind": "study", "method": "Prospect",
         "inputItemID": 1001, "inputName": "Test Ore", "inputRank": None, "gearGroup": None,
         "outputItemID": 2001, "outputName": "Test Gem", "outputRank": None, "casts": None,
         "inputsPerCast": 5, "totalQuantity": None, "castsWithDrop": None, "percentShown": None,
         "percentMeaning": None, "averageShown": None, "averagePer": None, "minSeen": None, "maxSeen": None,
         "histogram": None, "skill": None, "specialization": None, "stats": None}
    r.update(kw)
    return r


class Fixture(unittest.TestCase):
    """Points build_estimates at an empty temporary repository for each test."""

    def setUp(self):
        self.root = tempfile.mkdtemp()
        os.makedirs(os.path.join(self.root, "research", "v3", "evidence", "t"))
        self._saved = (b.ROOT, b.EVIDENCE)
        b.ROOT = self.root
        b.EVIDENCE = os.path.join(self.root, "research", "v3", "evidence")

    def tearDown(self):
        b.ROOT, b.EVIDENCE = self._saved
        shutil.rmtree(self.root)

    def put(self, rel, rows):
        path = os.path.join(self.root, "research", "v3", rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as fh:
            for r in rows:
                fh.write(json.dumps(r) + "\n")

    def build(self, rows):
        results, unplaced = b.build(rows)
        return {(r["method"], r["input"], r["outputItemID"]): r for r in results}, unplaced

    def one(self, rows, key=("Prospect", "1001", 2001)):
        res, _ = self.build(rows)
        self.assertIn(key, res)
        return res[key]


class Basics(Fixture):
    def test_casts_hits_totals(self):
        e = self.one([drop("a", casts=100, castsWithDrop=20, totalQuantity=30)])
        self.assertAlmostEqual(e["chance"], 0.2)
        self.assertAlmostEqual(e["average"], 0.3)
        self.assertEqual(e["chanceSource"], "measured")
        self.assertEqual(e["averageSource"], "measured")
        self.assertEqual(e["studyCasts"], 100)

    def test_percent_only_counts_as_small_study(self):
        e = self.one([drop("a", percentShown=25, percentMeaning="perCast")])
        self.assertAlmostEqual(e["chance"], 0.25)
        self.assertEqual(e["studyCasts"], b.SMALL_STUDY_CASTS)

    def test_unclear_percent_is_not_used(self):
        res, _ = self.build([drop("a", percentShown=25, percentMeaning="unclear")])
        self.assertEqual(res, {})

    def test_per_input_average_scaled_by_batch(self):
        e = self.one([drop("a", casts=100, castsWithDrop=50, averageShown=0.1, averagePer="input")])
        self.assertAlmostEqual(e["average"], 0.5)

    def test_derived_average_is_provisional(self):
        e = self.one([drop("a", percentShown=50, percentMeaning="perCast", minSeen=1, maxSeen=3)])
        self.assertAlmostEqual(e["average"], 1.0)
        self.assertTrue(e["provisionalValuation"])
        self.assertEqual(e["averageSource"], "estimated")

    def test_reference_is_prior_not_casts(self):
        ref = drop("r", sourceKind="tsm-table", percentShown=50, percentMeaning="perCast")
        e = self.one([ref, drop("a", casts=20, castsWithDrop=2)])
        self.assertAlmostEqual(e["chance"], (2 + 0.5 * b.PRIOR_CASTS) / (20 + b.PRIOR_CASTS), places=4)
        self.assertEqual(e["studies"], 1)
        self.assertEqual(e["referenceValues"], 1)

    def test_reference_only_confidence_capped(self):
        e = self.one([drop("r", sourceKind="tsm-table", percentShown=50, percentMeaning="perCast")])
        self.assertLessEqual(e["confidence"], b.GUESS_ONLY_MAX_CONFIDENCE)
        self.assertTrue(e["basis"].startswith("starting guess only"))

    def test_known_defect_totals_without_casts_unused(self):
        # S16 / M06: a total with no cast count contributes nothing today.
        res, _ = self.build([drop("a", totalQuantity=300, notes="10,000 ore, not casts")])
        self.assertEqual(res, {})

    def test_unplaced_without_ids_or_names(self):
        _, unplaced = self.build([drop("a", inputItemID=None, inputName=None, casts=10, castsWithDrop=1)])
        self.assertEqual(unplaced, 1)


class Ranks(Fixture):
    def test_s13_ranked_name_only_stays_family(self):
        ranked = drop("a", outputItemID=2001, outputName="Test Gem", outputRank=1, casts=10, castsWithDrop=1)
        nameonly = drop("b", outputItemID=None, outputName="Test Gem", casts=10, castsWithDrop=2)
        res, _ = self.build([ranked, nameonly])
        self.assertIn(("Prospect", "1001", 2001), res)
        self.assertIn(("Prospect", "1001", "family:Test Gem"), res)

    def test_unranked_name_only_matched_to_id(self):
        withid = drop("a", casts=10, castsWithDrop=1)
        nameonly = drop("b", outputItemID=None, casts=10, castsWithDrop=2)
        res, _ = self.build([withid, nameonly])
        self.assertEqual(list(res), [("Prospect", "1001", 2001)])
        self.assertEqual(res[("Prospect", "1001", 2001)]["studies"], 2)


class Conditions(Fixture):
    def setUp(self):
        super().setUp()
        self.put("conditions.jsonl", [{"method": "Prospect", "outputItemID": 2001, "inputItemIDs": None,
                                       "requires": "Test unlock"}])

    def test_unlock_unstated_is_skipped(self):
        res, _ = self.build([drop("a", casts=100, castsWithDrop=5)])
        self.assertEqual(res, {})

    def test_unlock_stated_is_counted_and_tagged(self):
        e = self.one([drop("a", casts=100, castsWithDrop=5, specialization="unlock: yes")])
        self.assertTrue(e["conditional"])
        self.assertEqual(e["requires"], "Test unlock")
        self.assertAlmostEqual(e["chance"], 0.05)

    def test_known_defect_unlock_read_from_notes_text(self):
        # M08: unlock state is guessed from free text, so a note mentioning "max knowledge" counts as unlocked.
        e = self.one([drop("a", casts=100, castsWithDrop=5, notes="author had max knowledge in mining")])
        self.assertTrue(e["conditional"])


class Epochs(Fixture):
    def setUp(self):
        super().setUp()
        self.put("rate-changes.jsonl", [{"date": "2026-03-31", "method": "Prospect", "affects": "Midnight ore"}])

    def test_before_change_counts_quarter(self):
        e = self.one([drop("a", inputItemID=237359, casts=100, castsWithDrop=10, dataDate="2026-01-01")],
                     key=("Prospect", "237359", 2001))
        self.assertEqual(e["studyCasts"], 25.0)

    def test_after_change_counts_full(self):
        e = self.one([drop("a", inputItemID=237359, casts=100, castsWithDrop=10, dataDate="2026-04-02")],
                     key=("Prospect", "237359", 2001))
        self.assertEqual(e["studyCasts"], 100.0)

    def test_known_defect_free_text_date_is_undated(self):
        # M03.1/M08: imported prose dates (old hotfixWindow) count as undated -> quarter weight.
        e = self.one([drop("a", inputItemID=237359, casts=100, castsWithDrop=10,
                           dataDate="post-hotfix 2026-04 live realms")], key=("Prospect", "237359", 2001))
        self.assertEqual(e["studyCasts"], 25.0)


class Identity(Fixture):
    def test_copy_in_two_files_counted_once(self):
        a = drop("a", url="https://reddit.com/r/x/comments/abc", casts=100, castsWithDrop=10, studyKey="s1")
        c = dict(a, id="c", studyKey="s1-copy", _file="other.jsonl")
        e = self.one([a, c])
        self.assertEqual(e["studies"], 1)
        self.assertEqual(e["studyCasts"], 100)

    def test_distinct_cast_counts_both_count(self):
        a = drop("a", url="https://reddit.com/r/x/comments/abc", casts=100, castsWithDrop=10, studyKey="b1")
        c = drop("c", url="https://reddit.com/r/x/comments/abc", casts=200, castsWithDrop=30, studyKey="b2")
        e = self.one([a, c])
        self.assertEqual(e["studyCasts"], 300)

    def test_known_defect_identity_collapses_independent_batches(self):
        # M05: two batches from one post with equal casts but different results are independent
        # cohorts, yet study_identity() merges them and only the first counts.
        a = drop("a", url="https://reddit.com/r/x/comments/abc", casts=2000, castsWithDrop=100, studyKey="batch01")
        c = drop("c", url="https://reddit.com/r/x/comments/abc", casts=2000, castsWithDrop=140, studyKey="batch02")
        e = self.one([a, c])
        self.assertEqual(e["studies"], 1)
        self.assertEqual(e["studyCasts"], 2000)


class LoadAndCorrections(Fixture):
    def test_replaces_and_corrections(self):
        self.put("evidence/t/a.jsonl", [
            drop("old", casts=10, castsWithDrop=1),
            drop("new", casts=10, castsWithDrop=2, replaces="old"),
            drop("gone", casts=10, castsWithDrop=9, studyKey="g"),
            drop("fix", casts=None, castsWithDrop=3, studyKey="f"),
        ])
        self.put("corrections.jsonl", [
            {"recordID": "gone", "field": "exclude", "value": True, "reason": "t", "by": "t", "date": "x"},
            {"recordID": "fix", "field": "casts", "value": 30, "reason": "t", "by": "t", "date": "x"},
            {"recordID": "fix", "field": "notAField", "value": 1, "reason": "t", "by": "t", "date": "x"},
        ])
        rows = b.load()
        ids = {r["id"] for r in rows}
        self.assertEqual(ids, {"new", "fix"})
        fix = next(r for r in rows if r["id"] == "fix")
        self.assertEqual(fix["casts"], 30)
        self.assertTrue(fix["_corrected"])
        self.assertNotIn("notAField", fix)

    def test_lines_without_json_are_skipped(self):
        path = os.path.join(self.root, "research", "v3", "evidence", "t", "bad.jsonl")
        with open(path, "w") as fh:
            fh.write("{oops\n" + json.dumps(drop("ok", casts=1, castsWithDrop=1)) + "\n")
        self.assertEqual([r["id"] for r in b.load()], ["ok"])


if __name__ == "__main__":
    unittest.main()
