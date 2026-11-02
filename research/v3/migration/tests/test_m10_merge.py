#!/usr/bin/env python3
"""M10 (MIG-011): the one estimator change the merge with implementation/five-agent-completion needed.

The reviewer's S7 fix (commit 40d9f76, `norm_source`) made a Wowhead page under a language prefix or /ptr/ count as the same page
(Tontons' BfA table had been counted three times). M05 had already replaced `study_identity`, so the merge kept M05's `source_key`
and ported that one rule into it (`same_page`, `SAME_PAGE_SUFFIXES`). Game flavours (@cata, @wotlk, @tbc, @mop-classic) are other
games and stay apart.

Run from the repository root:
  python3 -m unittest discover -s research/v3/migration/tests -v
"""
import json
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
sys.path.insert(0, os.path.join(HERE, "..", "tools"))
import build_estimates as b  # noqa: E402
from test_build_estimates import Fixture, drop  # noqa: E402

SPELL = "https://www.wowhead.com/{}spell=31252/prospecting"


class SamePage(unittest.TestCase):
    def key(self, url):
        return b.source_key({"source": {"url": url}})

    def test_language_and_ptr_prefixes_are_the_same_page(self):
        base = self.key(SPELL.format(""))
        for prefix in ("ru/", "cn/", "de/", "fr/", "es/", "pt/", "ptr/", "ptr-2/", "beta/", "ko/", "tw/", "mx/", "it/"):
            self.assertEqual(self.key(SPELL.format(prefix)), base, prefix)

    def test_game_flavours_are_other_pages(self):
        base = self.key(SPELL.format(""))
        keys = {self.key(SPELL.format(p)) for p in ("cata/", "wotlk/", "tbc/", "mop-classic/")}
        self.assertEqual(len(keys), 4)
        self.assertNotIn(base, keys)

    def test_a_flavour_with_a_language_keeps_the_flavour(self):
        self.assertEqual(b.same_page("wowhead:spell=1@wotlk@ru"), "wowhead:spell=1@wotlk")

    def test_a_comment_is_kept(self):
        self.assertEqual(b.same_page("wowhead:item=1@ru#c55"), "wowhead:item=1#c55")
        self.assertNotEqual(b.same_page("wowhead:item=1@ru#c55"), b.same_page("wowhead:item=1@ru#c56"))

    def test_other_hosts_are_untouched(self):
        for k in ("reddit:abc@ru", "blizzforum:123", "wow-professions.com/tbc/prospecting"):
            self.assertEqual(b.same_page(k), k)

    def test_a_row_without_a_url_still_stands_alone(self):
        self.assertEqual(b.source_key({"id": "x", "studyKey": "k"}), "k")


class Counting(Fixture):
    def tontons(self, prefix, key):
        return drop(key, url=SPELL.format(prefix), casts=253, totalQuantity=500, studyKey=key, outputItemID=2001)

    def test_one_study_under_three_spellings_counts_once(self):
        # Tontons' BfA table: /ru/, /ptr/ and plain (reviewer log, 2026-11-01). Same numbers, so one study.
        e = self.one([self.tontons("", "a"), self.tontons("ru/", "b"), self.tontons("ptr/", "c")])
        self.assertEqual(e["studies"], 1)
        self.assertEqual(e["studyCasts"], 253)

    def test_the_same_page_in_two_game_flavours_counts_twice(self):
        e = self.one([self.tontons("wotlk/", "a"), self.tontons("tbc/", "b")])
        self.assertEqual(e["studies"], 2)
        self.assertEqual(e["studyCasts"], 506)

    def test_other_numbers_under_the_same_page_stay_independent(self):
        # M05's fingerprint still decides copy versus cohort; the page key only stops a spelling from hiding a copy.
        a = self.tontons("", "a")
        c = drop("c", url=SPELL.format("ru/"), casts=253, totalQuantity=611, studyKey="c", outputItemID=2001)
        e = self.one([a, c])
        self.assertEqual(e["studies"], 2)


class Corpus(unittest.TestCase):
    """The reviewer reports 253 / 322 / 555 casts for Monelite, Platinum and Storm Silver after the fix."""

    def test_tontons_bfa_casts_match_the_reviewers_numbers(self):
        rows = b.load()
        results, _ = b.build(rows)
        casts = {e["input"]: e["studyCasts"] for e in results if e["method"] == "Prospect" and e["outputItemID"] == 153700}
        self.assertEqual({k: casts[k] for k in ("152512", "152513", "152579")}, {"152512": 253.0, "152513": 322.0, "152579": 555.0})

    def test_the_identity_reports_differing_groups_are_one_pair_of_copies(self):
        """After the merge identity_report.py lists 10 `differing` groups, all family:* groups of Prospect 194545 and all the same two
        studies: Superbondez's 400-ore Prismatic Ore cohort recorded twice by the dragonflight agent (S17). The report compares a group's
        rows one by one, and a family group holds one row per input rank per study, so it pairs rows of different ranks. At study level
        every numeric row of each copy has its own row in the other (the copy has two extra labelled rows with no numbers) and the two
        have one canonical vector, so nothing is dropped. Any other differing group fails this test and needs a look."""
        import identity_report as ir
        rows = b.load()
        differing = ir.report(rows)["stillDiffering"]
        self.assertEqual(
            len(differing), 10,
            "Unexpected identity groups; inspect study/cohort provenance before changing the assertion:\n"
            + json.dumps(differing, indent=2, sort_keys=True),
        )
        pair = {"wowhead-prismatic-ore-superbondez-400-80", "wowhead-superbondez-prismatic-ore-400"}
        for g in differing:
            self.assertEqual((g["method"], g["input"]), ("Prospect", "194545"))
            self.assertTrue(g["output"].startswith("family:"), g)
            self.assertEqual(set(g["studies"]), pair)
        ids = b.item_names(rows)
        studies = {}
        for r in rows:
            if b.is_study_row(r) and r.get("studyKey") in pair:
                studies.setdefault(r["studyKey"], []).append(r)
        a, c = (b.study_vector(v, ids) for v in studies.values())
        self.assertTrue(b.rows_covered(a, c, labelled=False) and b.rows_covered(c, a, labelled=False))
        canonical = b.study_vectors(rows)[0]
        self.assertEqual(len({canonical[b.study_ref(v[0])] for v in studies.values()}), 1)

    def test_no_wowhead_page_is_split_by_a_language_prefix(self):
        rows = [r for r in b.load() if b.is_study_row(r)]
        import re
        pages = {}
        for r in rows:
            k = b.source_key(r)
            self.assertIsNone(re.search(r"@(?:%s)(?=@|#|$)" % "|".join(b.SAME_PAGE_SUFFIXES), k), k)
            pages.setdefault(k, 0)


if __name__ == "__main__":
    unittest.main()
