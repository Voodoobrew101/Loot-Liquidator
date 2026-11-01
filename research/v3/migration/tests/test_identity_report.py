#!/usr/bin/env python3
"""M05: tests for migration/tools/identity_report.py and the shared source_keys module."""
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "tools"))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
import identity_report as ir  # noqa: E402
import inventory  # noqa: E402
import source_keys  # noqa: E402
from test_build_estimates import drop  # noqa: E402

URL = "https://reddit.com/r/x/comments/abc"


def study(key, numbers, path="a.jsonl", casts=100, url=URL):
    return [drop(f"{key}-{o}", url=url, casts=casts, studyKey=key, outputItemID=o, outputName=f"Gem {o}",
                 totalQuantity=n, _file=path) for o, n in numbers.items()]


class Classification(unittest.TestCase):
    def test_legacy_merge_of_different_numbers_is_differing(self):
        d = ir.report(study("alpha", {2001: 4, 2002: 9}) + study("beta", {2001: 6, 2002: 2}))
        self.assertEqual(d["legacy"]["groups"], 2)
        self.assertEqual(d["legacy"]["differing"], 2)
        self.assertEqual(d["legacy"]["droppedMaterialCasts"], 200)

    def test_current_identity_keeps_independent_cohorts_apart(self):
        d = ir.report(study("alpha", {2001: 4, 2002: 9}) + study("beta", {2001: 6, 2002: 2}))
        self.assertEqual(d["current"]["groups"], 0)
        self.assertEqual(d["cohortsRestored"], ["alpha", "beta"])

    def test_true_copy_is_identical_in_both(self):
        rows = study("alpha", {2001: 4, 2002: 9}) + study("copy", {2001: 4, 2002: 9}, path="b.jsonl")
        d = ir.report(rows)
        self.assertEqual(d["legacy"]["identical"], 2)
        self.assertEqual(d["current"]["identical"], 2)

    def test_partial_and_near_copies_are_listed(self):
        rows = (study("alpha", {2001: 4, 2002: 9, 2003: 1}) + study("some", {2001: 4, 2002: 9}, path="b.jsonl")
                + study("beta", {2001: 4, 2002: 9, 2003: 7}, path="c.jsonl"))
        d = ir.report(rows)
        self.assertEqual([p["copy"] for p in d["partialCopies"]], ["some"])
        self.assertIn(("alpha", "beta"), [(n["a"], n["b"]) for n in d["nearCopies"]])

    def test_equal_numbers_under_two_sources_are_listed_not_merged(self):
        rows = study("alpha", {2001: 4, 2002: 9}) + study("beta", {2001: 4, 2002: 9}, url="https://example.org/x")
        d = ir.report(rows)
        self.assertEqual(d["current"]["groups"], 0)
        self.assertEqual(d["crossSourceMatches"][0]["studies"], ["alpha", "beta"])

    def test_report_is_deterministic(self):
        rows = study("alpha", {2001: 4, 2002: 9}) + study("beta", {2001: 6, 2002: 2})
        self.assertEqual(ir.report(rows), ir.report(list(rows)))


class SharedModule(unittest.TestCase):
    def test_inventory_uses_the_shared_normalizer(self):
        self.assertIs(inventory.normalize_url, source_keys.normalize_url)


if __name__ == "__main__":
    unittest.main()
