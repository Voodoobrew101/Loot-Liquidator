#!/usr/bin/env python3
"""Tests for tools/validate.py (M02.1) and tools/estimates_diff.py (M02.3)."""
import json
import os
import shutil
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "tools"))
import estimates_diff as ed  # noqa: E402
import validate as v  # noqa: E402
from test_build_estimates import drop  # noqa: E402


class CheckRecord(unittest.TestCase):
    def codes(self, r):
        return {c for _, c, _ in v.check_record(r)}

    def test_clean_drop(self):
        self.assertEqual(self.codes(drop("a", casts=10, castsWithDrop=2, totalQuantity=3)), set())

    def test_missing_type(self):
        self.assertEqual(self.codes({"id": "x", "sourceURL": "u"}), {"TYPE_MISSING"})

    def test_bad_values(self):
        r = drop("a", casts=5, castsWithDrop=6, minSeen=3, maxSeen=1, inputRank=0, percentMeaning="per craft",
                 method="Dye Crafting", totalQuantity="12")
        self.assertTrue({"HITS_EXCEED_CASTS", "RANGE_INVERTED", "RANK_INVALID", "PERCENT_MEANING_UNKNOWN",
                         "METHOD_UNKNOWN", "NOT_A_NUMBER"} <= self.codes(r))

    def test_free_text_date_warns(self):
        self.assertIn("DATE_NOT_ISO", self.codes(drop("a", dataDate="2022 Retail Shadowlands era")))
        self.assertNotIn("DATE_NOT_ISO", self.codes(drop("a", dataDate="2026-04-02/2026-04-10")))

    def test_missing_documented_keys_is_warning(self):
        r = drop("a")
        del r["histogram"]
        res = v.check_record(r)
        self.assertEqual([(s, c) for s, c, _ in res], [("warning", "FIELDS_MISSING")])

    def test_correctable_matches_estimator(self):
        sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
        import build_estimates as b
        self.assertEqual(v.CORRECTABLE, b.CORRECTABLE)


class ValidateRepo(unittest.TestCase):
    def setUp(self):
        self.root = tempfile.mkdtemp()
        d = os.path.join(self.root, "research", "v3", "evidence", "t")
        os.makedirs(d)
        with open(os.path.join(d, "a.jsonl"), "w") as fh:
            fh.write(json.dumps(drop("a", method=None)) + "\n")
            fh.write(json.dumps(drop("a", casts=1)) + "\n")       # duplicate id in file
            fh.write("{broken\n")
            fh.write(json.dumps({"id": "z"}) + "\n")              # no type
        with open(os.path.join(self.root, "research", "v3", "corrections.jsonl"), "w") as fh:
            fh.write(json.dumps({"recordID": "a", "field": "method", "value": "Prospect"}) + "\n")
            fh.write(json.dumps({"recordID": "nope", "field": "casts", "value": 1}) + "\n")
            fh.write(json.dumps({"recordID": "a", "field": "type", "value": "drop"}) + "\n")

    def tearDown(self):
        shutil.rmtree(self.root)

    def test_repo_findings(self):
        res = v.validate(self.root)
        codes = {f["code"] for f in res["findings"]}
        self.assertIn("BAD_JSON", codes)
        self.assertIn("ID_DUPLICATE_IN_FILE", codes)
        self.assertIn("TYPE_MISSING", codes)
        self.assertIn("CORRECTION_TARGET_MISSING", codes)
        self.assertIn("CORRECTION_FIELD_NOT_CORRECTABLE", codes)
        # the method correction is applied before checking, so METHOD_MISSING is gone
        self.assertNotIn("METHOD_MISSING", codes)
        self.assertEqual(res["records"], 3)

    def test_deterministic(self):
        self.assertEqual(json.dumps(v.validate(self.root), sort_keys=True),
                         json.dumps(v.validate(self.root), sort_keys=True))


class Diff(unittest.TestCase):
    def test_diff(self):
        mk = lambda i, c, n: {"method": "Prospect", "input": str(i), "outputItemID": 2001, "chance": c,  # noqa: E731
                              "average": c, "confidence": 50, "studyCasts": n, "studies": 1}
        before = {ed.key(e): e for e in [mk(1, 0.2, 100), mk(2, 0.5, 10)]}
        after = {ed.key(e): e for e in [mk(1, 0.25, 300), mk(3, 0.1, 5)]}
        d = ed.diff(before, after)
        self.assertEqual(d["added"], [["Prospect", "3", "2001"]])
        self.assertEqual(d["removed"], [["Prospect", "2", "2001"]])
        self.assertEqual(len(d["changed"]), 1)
        self.assertEqual(d["changed"][0]["dChance"], 0.05)
        self.assertIn("studyCasts", d["fieldChangeCounts"])
        self.assertIn("0.2 → 0.25", ed.render_md(d))


if __name__ == "__main__":
    unittest.main()
