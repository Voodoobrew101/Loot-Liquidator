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

    def test_ranked_family_copy_with_two_outputs_is_not_a_false_conflict(self):
        rows = []
        for key, path in (("original", "a.jsonl"), ("copy", "b.jsonl")):
            for rank, units in ((2, 315), (3, 72)):
                rows.append(drop(f"{key}-{rank}", url=URL, studyKey=key, _file=path,
                                 outputItemID=None, outputName="Eternity Amber",
                                 outputRank=rank, casts=1000, totalQuantity=units))
        d = ir.report(rows)
        self.assertEqual(d["current"]["differing"], 0)
        self.assertEqual(d["current"]["identical"], 1)

    def test_same_name_unknown_rank_variants_match_as_a_multiset(self):
        rows = []
        for key, path in (("original", "a.jsonl"), ("copy", "b.jsonl")):
            for index, hits in enumerate((13, 8)):
                rows.append(drop(f"{key}-{index}", url=URL, studyKey=key, _file=path,
                                 method="Disenchant", gearGroup={"expansion": "Midnight",
                                 "quality": None, "kind": "armor", "itemLevelRange": None},
                                 outputItemID=None, outputName="Dawn Crystal",
                                 casts=34, castsWithDrop=hits))
        d = ir.report(rows)
        self.assertEqual(d["current"]["differing"], 0)
        self.assertEqual(d["current"]["identical"], 1)
        # The absence of output ranks still blocks a rank-specific ItemDB import.

    def test_forced_merge_of_different_variant_counts_is_still_flagged(self):
        rows = []
        for key, path, hits in (("original", "a.jsonl", (13, 8)),
                                ("other", "b.jsonl", (13, 9))):
            for index, count in enumerate(hits):
                rows.append(drop(f"{key}-{index}", url=URL, studyKey=key, _file=path,
                                 outputItemID=None, outputName="Dawn Crystal",
                                 casts=34, castsWithDrop=count))
        found = ir.collisions(rows, lambda r: "forced")
        self.assertEqual(len(found), 1)
        self.assertEqual(found[0]["kind"], "differing")

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
