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

    def test_total_without_casts_or_input_count_unused(self):
        # M06: was test_known_defect_totals_without_casts_unused. A total counts once the row states
        # inputsProcessed (test_m06_units); an input count only in notes is not read, so this row stays
        # unused, now with the reason "totalWithoutCasts" (row_use).
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

    def test_independent_batches_both_count(self):
        # M05: was test_known_defect_identity_collapses_independent_batches. Two batches from one post
        # with equal casts but different results are independent cohorts.
        a = drop("a", url="https://reddit.com/r/x/comments/abc", casts=2000, castsWithDrop=100, studyKey="batch01")
        c = drop("c", url="https://reddit.com/r/x/comments/abc", casts=2000, castsWithDrop=140, studyKey="batch02")
        e = self.one([a, c])
        self.assertEqual(e["studies"], 2)
        self.assertEqual(e["studyCasts"], 4000)
        self.assertAlmostEqual(e["chance"], 0.06)

    def test_bugy_shape_equal_casts_other_numbers_both_count(self):
        url = "https://www.wowhead.com/spell=374627"
        rows = [drop(f"{k}-{o}", url=url, casts=400.0, studyKey=k, outputItemID=o, outputName=f"Gem {o}",
                     averageShown=v, averagePer="cast")
                for k, vals in (("bugy-ore-1", {2001: 0.303, 2002: 0.244}), ("bugy-ore-2", {2001: 0.3025, 2002: 0.254}))
                for o, v in vals.items()]
        e = self.one(rows)
        self.assertEqual(e["studies"], 2)
        self.assertEqual(e["studyCasts"], 800)

    def test_numbered_batches_with_equal_numbers_both_count(self):
        # Reddit 10u5ao8 batches 1 and 6 both report 7 and 13 diamonds; small batches can match by chance.
        url = "https://reddit.com/r/x/comments/abc"
        rows = [drop(f"{k}-{o}", url=url, casts=2000, studyKey=k, outputItemID=o, outputName=f"Gem {o}",
                     totalQuantity=n, _file="batches.jsonl")
                for k in ("r2-batch01", "r2-batch06") for o, n in ((2001, 7), (2002, 13))]
        e = self.one(rows)
        self.assertEqual(e["studies"], 2)
        self.assertEqual(e["studyCasts"], 4000)

    def test_pooled_study_is_not_added_to_its_batches(self):
        # df-q21-b019 is the sum of the ten 10u5ao8 batches; adding it would count 20,000 casts twice.
        url = "https://reddit.com/r/x/comments/abc"
        rows = [drop(f"{k}-{o}", url=url, casts=2000, studyKey=k, outputItemID=o, outputName=f"Gem {o}",
                     totalQuantity=n, _file="batches.jsonl")
                for k, vals in (("r2-batch01", {2001: 7, 2002: 13}), ("r2-batch02", {2001: 11, 2002: 26}))
                for o, n in vals.items()]
        rows += [drop(f"pool-{o}", url=url, casts=4000, studyKey="pool", outputItemID=o, outputName=f"Gem {o}",
                      totalQuantity=n, _file="old.jsonl") for o, n in ((2001, 18), (2002, 39))]
        e = self.one(rows)
        self.assertEqual(e["studies"], 2)
        self.assertEqual(e["studyCasts"], 4000)
        self.assertAlmostEqual(e["average"], 18 / 4000)

    def test_copy_across_files_with_different_keys_and_urls_counts_once(self):
        def study(prefix, key, url, path):
            return [drop(f"{prefix}-{o}", url=url, casts=500, studyKey=key, outputItemID=o, outputName=f"Gem {o}",
                         totalQuantity=n, _file=path) for o, n in ((2001, 40), (2002, 60))]
        rows = study("a", "reddit-abc", "https://www.reddit.com/r/x/comments/abc/some_title/", "a.jsonl")
        rows += study("c", "agent-recheck", "https://old.reddit.com/r/x/comments/abc", "b.jsonl")
        e = self.one(rows)
        self.assertEqual(e["studies"], 1)
        self.assertEqual(e["studyCasts"], 500)

    def test_original_source_links_a_copy_to_its_study(self):
        url = "https://reddit.com/r/x/comments/abc"
        a = drop("a", url=url, casts=100, castsWithDrop=10, studyKey="study")
        c = drop("c", url="https://example.org/guide", originalSource=url, casts=100, castsWithDrop=10, studyKey="guide")
        self.assertEqual(self.one([a, c])["studies"], 1)

    def test_same_numbers_from_unrelated_sources_both_count(self):
        a = drop("a", casts=100, castsWithDrop=10, studyKey="first")
        c = drop("c", casts=100, castsWithDrop=10, studyKey="second")
        self.assertEqual(self.one([a, c])["studyCasts"], 200)

    def test_copy_with_null_ranked_ids_matches_by_name(self):
        # S17: the copy has no output IDs, so it lands in a family row the per-group dedupe never sees.
        url = "https://reddit.com/r/x/comments/abc"
        ranked = [drop(f"a{rank}", url=url, casts=1000, studyKey="import", outputItemID=2000 + rank,
                       outputName="Test Gem", outputRank=rank, totalQuantity=n, _file="i.jsonl")
                  for rank, n in ((1, 315), (2, 72))]
        copy = [drop(f"c{rank}", url=url, casts=1000, studyKey="recheck", outputItemID=None, outputName="Test Gem",
                     outputRank=rank, totalQuantity=n, _file="c.jsonl") for rank, n in ((1, 315), (2, 72))]
        res, _ = self.build(ranked + copy)
        self.assertEqual(sorted(k[2] for k in res), [2001, 2002])
        self.assertEqual(res[("Prospect", "1001", 2001)]["studies"], 1)

    def test_copy_keeps_numbers_when_a_field_is_null(self):
        # Reddit 108782r: one record adds averageShown to the same totals.
        url = "https://reddit.com/r/x/comments/abc"
        a = [drop(f"a{o}", url=url, casts=8000, studyKey="a", outputItemID=o, outputName=f"Gem {o}", totalQuantity=n,
                  _file="a.jsonl") for o, n in ((2001, 800), (2002, 400))]
        c = [drop(f"c{o}", url=url, casts=8000, studyKey="c", outputItemID=o, outputName=f"Gem {o}", totalQuantity=n,
                  averageShown=n / 8000, averagePer="cast", _file="c.jsonl") for o, n in ((2001, 800), (2002, 400))]
        e = self.one(a + c)
        self.assertEqual(e["studies"], 1)
        self.assertEqual(e["studyCasts"], 8000)

    def test_relabeled_copy_counts_once_and_is_listed(self):
        # "Titanium Dust" vs "Titanium Powder": same numbers, another name for one output.
        url = "https://reddit.com/r/x/comments/abc"
        a = [drop(f"a{i}", url=url, casts=136, studyKey="a", outputItemID=None, outputName=n, totalQuantity=q,
                  _file="a.jsonl") for i, (n, q) in enumerate((("Titanium Dust", 97), ("Gem", 40)))]
        c = [drop(f"c{i}", url=url, casts=136, studyKey="c", outputItemID=None, outputName=n, totalQuantity=q,
                  _file="c.jsonl") for i, (n, q) in enumerate((("Titanium Powder", 97), ("Gem", 40)))]
        vectors, partial, _ = b.study_vectors(a + c)
        self.assertEqual(len(partial), 1)
        self.assertEqual(b.study_identity(a[1], vectors), b.study_identity(c[1], vectors))
        self.assertEqual(self.one(a + c, key=("Prospect", "1001", "family:Gem"))["studies"], 1)

    def test_zero_hit_material_does_not_merge_independent_batches(self):
        # Both batches saw 0 of one material; the other material shows they are different cohorts.
        url = "https://reddit.com/r/x/comments/abc"
        rows = [drop(f"{k}-{o}", url=url, casts=500, studyKey=k, outputItemID=o, outputName=f"Gem {o}",
                     castsWithDrop=n, totalQuantity=n)
                for k, vals in (("alpha", {2001: 0, 2002: 30}), ("beta", {2001: 0, 2002: 44})) for o, n in vals.items()]
        zero = self.one(rows)
        self.assertEqual(zero["studies"], 2)
        self.assertEqual(zero["studyCasts"], 1000)
        self.assertEqual(zero["chance"], 0)

    def test_partial_copy_counts_once_and_is_listed(self):
        url = "https://reddit.com/r/x/comments/abc"
        full = [drop(f"a{o}", url=url, casts=100, studyKey="full", outputItemID=o, outputName=f"Gem {o}",
                     totalQuantity=n, _file="a.jsonl") for o, n in ((2001, 9), (2002, 5), (2003, 3))]
        part = [drop(f"c{o}", url=url, casts=100, studyKey="some", outputItemID=o, outputName=f"Gem {o}",
                     totalQuantity=n, _file="c.jsonl") for o, n in ((2001, 9), (2002, 5))]
        e = self.one(full + part)
        self.assertEqual(e["studies"], 1)
        self.assertEqual(b.study_vectors(full + part)[1], [(("c.jsonl", "some"), ("a.jsonl", "full"))])

    def test_subset_with_one_non_zero_output_stays_independent(self):
        url = "https://reddit.com/r/x/comments/abc"
        full = [drop(f"a{o}", url=url, casts=100, studyKey="full", outputItemID=o, outputName=f"Gem {o}",
                     totalQuantity=n, _file="a.jsonl") for o, n in ((2001, 9), (2002, 5))]
        one = drop("c", url=url, casts=100, studyKey="one", totalQuantity=9, _file="c.jsonl")
        self.assertEqual(self.one(full + [one])["studies"], 2)

    def test_chance_match_of_a_few_numbers_in_a_big_study_is_not_a_copy(self):
        url = "https://reddit.com/r/x/comments/abc"
        big = [drop(f"a{o}", url=url, casts=100, studyKey="big", outputItemID=o, outputName=f"Gem {o}",
                    totalQuantity=o - 2000, _file="a.jsonl") for o in range(2001, 2007)]
        small = [drop(f"c{o}", url=url, casts=100, studyKey="small", outputItemID=o + 10, outputName=f"Other {o}",
                      totalQuantity=o - 2000, _file="c.jsonl") for o in (2001, 2002)]
        self.assertEqual(b.study_vectors(big + small)[1], [])

    def test_cohort_key_overrides_the_fingerprint(self):
        url = "https://reddit.com/r/x/comments/abc"
        a = drop("a", url=url, casts=100, castsWithDrop=10, studyKey="s1", cohortKey="reddit:abc#1")
        same_numbers = drop("c", url=url, casts=100, castsWithDrop=10, studyKey="s2", cohortKey="reddit:abc#2")
        self.assertEqual(self.one([a, same_numbers])["studyCasts"], 200)
        other_numbers = drop("d", url=url, casts=100, castsWithDrop=70, studyKey="s3", cohortKey="reddit:abc#1")
        e = self.one([a, other_numbers])
        self.assertEqual(e["studies"], 1)
        self.assertAlmostEqual(e["chance"], 0.1)

    def test_cohort_key_can_be_set_by_correction(self):
        self.assertIn("cohortKey", b.CORRECTABLE)
        self.put("evidence/t/a.jsonl", [drop("a", casts=10, castsWithDrop=1)])
        self.put("corrections.jsonl", [{"recordID": "a", "field": "cohortKey", "value": "x#1", "reason": "t"}])
        self.assertEqual(b.load()[0]["cohortKey"], "x#1")


class IdentityUnlock(Fixture):
    def setUp(self):
        super().setUp()
        self.put("conditions.jsonl", [{"method": "Prospect", "outputItemID": 2001, "inputItemIDs": None,
                                       "requires": "Test unlock"}])

    def test_skipped_copy_does_not_block_the_copy_that_states_the_unlock(self):
        url = "https://reddit.com/r/x/comments/abc"
        unknown = drop("a", url=url, casts=100, castsWithDrop=5, studyKey="study")
        stated = drop("c", url=url, casts=100, castsWithDrop=5, studyKey="recheck", specialization="unlock: yes")
        e = self.one([unknown, stated])
        self.assertEqual(e["studies"], 1)
        self.assertEqual(e["studyCasts"], 100)
        self.assertNotIn("left out", e["basis"])

    def test_unknown_batches_are_each_reported_as_left_out(self):
        url = "https://reddit.com/r/x/comments/abc"
        rows = [drop("a", url=url, casts=100, castsWithDrop=5, studyKey="s1"),
                drop("b", url=url, casts=100, castsWithDrop=9, studyKey="s2"),
                drop("c", url=url, casts=100, castsWithDrop=2, studyKey="s3", specialization="unlock: yes")]
        e = self.one(rows)
        self.assertEqual(e["studyCasts"], 100)
        self.assertIn("2 studies left out", e["basis"])

    def test_vaguer_copy_that_states_the_unlock_is_kept(self):
        url = "https://reddit.com/r/x/comments/abc"
        original = drop("a", url=url, casts=100, castsWithDrop=5, studyKey="study", outputRank=1)
        copy = drop("c", url=url, casts=100, castsWithDrop=5, studyKey="recheck", outputItemID=None, outputRank=1,
                    specialization="unlock: yes")
        res, _ = self.build([original, copy])
        self.assertIn(("Prospect", "1001", "family:Test Gem"), res)


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

    def test_file_scoped_correction_applies_on_every_platform(self):
        self.put("evidence/t/a.jsonl", [drop("a", casts=10, castsWithDrop=1)])
        self.put("corrections.jsonl", [{"recordID": "a", "file": "research/v3/evidence/t/a.jsonl", "field": "exclude",
                                        "value": True, "reason": "t"}])
        self.assertEqual(b.load(), [])

    def test_lines_without_json_are_skipped(self):
        path = os.path.join(self.root, "research", "v3", "evidence", "t", "bad.jsonl")
        with open(path, "w") as fh:
            fh.write("{oops\n" + json.dumps(drop("ok", casts=1, castsWithDrop=1)) + "\n")
        self.assertEqual([r["id"] for r in b.load()], ["ok"])


if __name__ == "__main__":
    unittest.main()
