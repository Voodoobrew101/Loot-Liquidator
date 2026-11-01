#!/usr/bin/env python3
"""M08: structured unlockState, ISO-only dates, the percentMeaning guard, and the per-record unused reason.

The rules under test (research/v3/tools/build_estimates.py):
  * unlock_state(): the structured `unlockState` (true, false or an explicit null) decides when the record
    has the field; only a record without it falls back to phrases in specialization, notes and stats;
  * dates: dataDate, observedOn and source.published are read only when ISO (YYYY-MM-DD, YYYY-MM, a range
    or timestamp starting with one); free text is never parsed; a month-only date is placed only if the
    whole month is on one side of a rate change;
  * chance_from_percent(): a percentage is a per-cast chance only with percentMeaning "perCast";
  * analyze(): every record is either used (roles) or has one reason from REASON_CODES.

Run from the repository root:
  python3 -m unittest discover -s research/v3/migration/tests -v
"""
import contextlib
import io
import json
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "tools"))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
import build_estimates as b  # noqa: E402
import estimator_effects as effects  # noqa: E402
import units_report  # noqa: E402
from test_build_estimates import Fixture, drop  # noqa: E402

URL = "https://reddit.com/r/x/comments/abc"
REPO = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))


class Unlock(Fixture):
    def setUp(self):
        super().setUp()
        self.put("conditions.jsonl", [{"method": "Prospect", "outputItemID": 2001, "inputItemIDs": None,
                                       "requires": "Test unlock"}])

    def test_structured_true_beats_text_that_says_no(self):
        r = drop("a", casts=100, castsWithDrop=5, unlockState=True, specialization="unlock: no")
        self.assertIs(b.unlock_state(r), True)
        self.assertEqual(self.one([r])["studyCasts"], 100)

    def test_structured_false_beats_text_that_says_yes(self):
        r = drop("a", casts=100, castsWithDrop=5, unlockState=False, notes="author had max knowledge")
        self.assertIs(b.unlock_state(r), False)
        res, _ = self.build([r])
        self.assertEqual(res, {})

    def test_explicit_null_means_not_stated_and_ignores_the_text(self):
        # null is a structured answer ("the source does not say"), not an absent field.
        r = drop("a", casts=100, castsWithDrop=5, unlockState=None, notes="author had max knowledge")
        self.assertIsNone(b.unlock_state(r))
        res, _ = self.build([r])
        self.assertEqual(res, {})

    def test_absent_field_falls_back_to_the_text(self):
        r = drop("a", casts=100, castsWithDrop=5, notes="author had max knowledge")
        self.assertNotIn("unlockState", r)
        self.assertIs(b.unlock_state(r), True)
        self.assertIs(b.unlock_state(drop("b", specialization="no unlock")), False)
        self.assertIsNone(b.unlock_state(drop("c")))

    def test_a_value_that_is_not_true_false_or_null_is_treated_as_absent(self):
        self.assertIs(b.unlock_state(drop("a", unlockState="yes", specialization="unlock: yes")), True)
        self.assertIsNone(b.unlock_state(drop("b", unlockState="yes")))
        self.assertIsNone(b.unlock_state(drop("c", unlockState=1)))

    def test_unlock_reasons_in_the_unused_report(self):
        rows = [drop("f", casts=100, castsWithDrop=5, studyKey="f", unlockState=False),
                drop("n", casts=100, castsWithDrop=5, studyKey="n"),
                drop("y", casts=100, castsWithDrop=5, studyKey="y", unlockState=True, url=URL)]
        _, _, usage = b.analyze(rows)
        self.assertEqual([usage[id(r)].get("reason") for r in rows],
                         ["conditional:unlockFalse", "conditional:unlockUnstated", None])
        self.assertEqual(usage[id(rows[0])]["detail"], "Test unlock")

    def test_correction_can_set_unlock_state(self):
        self.assertIn("unlockState", b.CORRECTABLE)
        self.put("evidence/t/a.jsonl", [drop("a", casts=10, castsWithDrop=1, notes="max knowledge")])
        self.put("corrections.jsonl", [{"recordID": "a", "field": "unlockState", "value": False, "reason": "t"}])
        self.assertIs(b.unlock_state(b.load()[0]), False)


class IsoDates(Fixture):
    def setUp(self):
        super().setUp()
        self.put("rate-changes.jsonl", [{"date": "2026-03-31", "method": "Prospect", "affects": "Midnight ore"}])

    def weight(self, **kw):
        r = drop("a", inputItemID=237359, casts=100, castsWithDrop=10, **kw)
        return b.epoch_weight(r, "Prospect", "237359", b.load_rate_changes())

    def test_iso_forms_are_read(self):
        for text, expected in (("2026-04-02", "2026-04-02"), ("2026-04", "2026-04"),
                               ("2026-04-02/2026-04-10", "2026-04-02"), ("2026-04-02T10:30:00Z", "2026-04-02")):
            self.assertEqual(b.iso_date(text), expected, text)

    def test_free_text_and_impossible_dates_are_not_dates(self):
        for text in ("2026-04 live realms", "post-hotfix 2026-04", "April 2026", "20260402", "2026-13-01",
                     "2026-02-30", "2026-4-2", "", "2026", None, 20260402, ["2026-04-02"]):
            self.assertIsNone(b.iso_date(text), text)

    def test_prose_starting_with_a_month_no_longer_dates_the_study(self):
        # Before M08 the first ten characters of "2026-04 live realms ..." passed as a date string.
        self.assertIsNone(b.study_date(drop("a", dataDate="2026-04 live realms (post-hotfix)")))
        self.assertEqual(self.weight(dataDate="2026-04 live realms (post-hotfix)"), (0.25, "undated vs 2026-03-31"))

    def test_prose_data_date_falls_through_to_the_post_date_and_says_so(self):
        w, why = self.weight(dataDate="post-hotfix live realms", published="2026-04-23")
        self.assertEqual((w, why), (1.0, "dated by post date only, after 2026-03-31"))

    def test_observed_on_is_a_collection_date(self):
        self.assertEqual(self.weight(observedOn="2026-04-22", published="2026-04-23"), (1.0, None))
        self.assertEqual(self.weight(observedOn="2026-01-22", published="2026-04-23"), (0.25, "before 2026-03-31"))

    def test_month_only_dates_are_placed_only_when_the_whole_month_is_on_one_side(self):
        self.assertEqual(self.weight(dataDate="2026-04"), (1.0, None))
        self.assertEqual(self.weight(dataDate="2026-02"), (0.25, "before 2026-03-31"))
        self.assertEqual(self.weight(dataDate="2026-03"), (0.25, "undated vs 2026-03-31"))

    def test_unusable_collection_date_does_not_hide_a_usable_one_after_it(self):
        self.assertEqual(b.dated_by(drop("a", dataDate="sometime", observedOn="2026-04-22")), ("2026-04-22", "observedOn"))

    def test_day_precision_is_unchanged(self):
        self.assertEqual(self.weight(dataDate="2026-03-31"), (1.0, None))
        self.assertEqual(self.weight(dataDate="2026-03-30"), (0.25, "before 2026-03-31"))


class PercentMeaning(Fixture):
    def test_unstated_meaning_is_not_a_per_cast_chance(self):
        r = drop("a", percentShown=25, percentMeaning=None)
        self.assertIsNone(b.chance_from_percent(r))
        res, _ = self.build([r])
        self.assertEqual(res, {})

    def test_only_per_cast_is_a_chance(self):
        for meaning, expected in (("perCast", 0.25), ("perInput", None), ("unclear", None), (None, None), ("other", None)):
            self.assertEqual(b.chance_from_percent(drop("a", percentShown=25, percentMeaning=meaning)), expected, meaning)

    def test_a_reference_percentage_with_no_meaning_is_not_a_prior(self):
        ref = drop("r", sourceKind="tsm-table", percentShown=50, percentMeaning=None)
        e = self.one([ref, drop("a", casts=20, castsWithDrop=2)])
        self.assertAlmostEqual(e["chance"], 0.1)

    def test_reason_codes(self):
        rows = [drop("n", percentShown=25, percentMeaning=None, studyKey="n"),
                drop("u", percentShown=25, percentMeaning="unclear", studyKey="u"),
                drop("o", percentShown=250, percentMeaning="perCast", studyKey="o")]
        _, _, usage = b.analyze(rows)
        self.assertEqual([usage[id(r)]["reason"] for r in rows],
                         ["percentNotPerCast", "percentNotPerCast", "percentOutOfRange"])


class Used(Fixture):
    """Observed, derived, provisional, conditional and duplicate records, one fixture each."""

    def usage(self, rows):
        res, unplaced, usage = b.analyze(rows)
        return res, usage

    def test_observed_chance_and_average(self):
        r = drop("a", casts=100, castsWithDrop=20, totalQuantity=30)
        res, usage = self.usage([r])
        self.assertEqual(usage[id(r)], {"used": True, "roles": ["average", "chance"], "reason": None})
        self.assertEqual(res[0]["chanceSource"], "measured")

    def test_derived_chance_from_an_average_is_used_as_an_average(self):
        r = drop("a", casts=100, totalQuantity=50, minSeen=1, maxSeen=3)
        res, usage = self.usage([r])
        self.assertEqual(res[0]["chanceSource"], "estimated")
        self.assertEqual(usage[id(r)]["roles"], ["average", "range"])

    def test_provisional_average_from_a_percentage_is_used_as_a_chance(self):
        r = drop("a", percentShown=50, percentMeaning="perCast")
        res, usage = self.usage([r])
        self.assertTrue(res[0]["provisionalValuation"])
        self.assertEqual(usage[id(r)]["roles"], ["chance"])

    def test_conditional_study_with_stated_unlock_is_used(self):
        self.put("conditions.jsonl", [{"method": "Prospect", "outputItemID": 2001, "inputItemIDs": None,
                                       "requires": "Test unlock"}])
        r = drop("a", casts=100, castsWithDrop=5, specialization="unlock: yes")
        res, usage = self.usage([r])
        self.assertTrue(res[0]["conditional"])
        self.assertTrue(usage[id(r)]["used"])

    def test_copy_of_a_counted_study_is_a_duplicate_study(self):
        a = drop("a", url=URL, casts=100, castsWithDrop=10, studyKey="study")
        c = drop("c", url=URL, casts=100, castsWithDrop=10, studyKey="recheck", _file="other.jsonl")
        _, usage = self.usage([a, c])
        self.assertTrue(usage[id(a)]["used"])
        self.assertEqual(usage[id(c)]["reason"], "duplicateStudy")

    def test_second_row_of_one_study_in_one_group_is_a_duplicate_row(self):
        a = drop("a", url=URL, casts=100, castsWithDrop=10, studyKey="study", outputRank=1)
        c = drop("c", url=URL, casts=100, castsWithDrop=12, studyKey="study", outputRank=2)
        _, usage = self.usage([a, c])
        self.assertEqual(usage[id(c)]["reason"], "duplicateRowInStudy")

    def test_duplicate_that_widens_the_range_is_flagged(self):
        a = drop("a", url=URL, casts=100, castsWithDrop=10, studyKey="study", maxSeen=2)
        c = drop("c", url=URL, casts=100, castsWithDrop=10, studyKey="recheck", maxSeen=4, _file="other.jsonl")
        res, usage = self.usage([a, c])
        self.assertEqual(usage[id(c)], {"used": False, "reason": "duplicateStudy", "range": True})
        self.assertEqual(res[0]["observedRange"], [None, 4])

    def test_copy_in_a_vaguer_group_and_pooled_study(self):
        ranked = [drop(f"a{rank}", url=URL, casts=1000, studyKey="import", outputItemID=2000 + rank,
                       outputName="Test Gem", outputRank=rank, totalQuantity=n, _file="i.jsonl")
                  for rank, n in ((1, 315), (2, 72))]
        copy = [drop(f"c{rank}", url=URL, casts=1000, studyKey="recheck", outputItemID=None, outputName="Test Gem",
                     outputRank=rank, totalQuantity=n, _file="c.jsonl") for rank, n in ((1, 315), (2, 72))]
        _, usage = self.usage(ranked + copy)
        self.assertEqual({usage[id(r)]["reason"] for r in copy}, {"copy:vaguerGroup"})
        self.assertTrue(all(usage[id(r)]["used"] for r in ranked))

        batches = [drop(f"{k}-{o}", url=URL, casts=2000, studyKey=k, outputItemID=o, outputName=f"Gem {o}",
                        totalQuantity=n, _file="batches.jsonl")
                   for k, vals in (("r2-batch01", {2001: 7, 2002: 13}), ("r2-batch02", {2001: 11, 2002: 26}))
                   for o, n in vals.items()]
        pool = [drop(f"pool-{o}", url=URL, casts=4000, studyKey="pool", outputItemID=o, outputName=f"Gem {o}",
                     totalQuantity=n, _file="old.jsonl") for o, n in ((2001, 18), (2002, 39))]
        _, usage = self.usage(batches + pool)
        self.assertEqual({usage[id(r)]["reason"] for r in pool}, {"copy:pooledStudy"})

    def test_rows_with_nothing_to_count(self):
        rows = {"noNumbers": drop("n", studyKey="n"),
                "totalWithoutCasts": drop("t", studyKey="t", totalQuantity=300),
                "hitsWithoutCasts": drop("h", studyKey="h", castsWithDrop=4),
                "averageNoBatch": drop("v", studyKey="v", averageShown=0.2, averagePer="input", inputsPerCast=None, method="Mill"),
                "totalNoBatch": drop("w", studyKey="w", totalQuantity=300, inputsProcessed=1000, inputsPerCast=None,
                                     method="Mill")}
        _, usage = self.usage(list(rows.values()))
        got = {k: usage[id(r)]["reason"] for k, r in rows.items()}
        self.assertEqual(got["noNumbers"], "noNumbers")
        self.assertEqual(got["totalWithoutCasts"], "totalWithoutCasts")
        self.assertEqual(got["hitsWithoutCasts"], "hitsWithoutCasts")
        self.assertEqual(got["averageNoBatch"], "averageNoBatch")
        self.assertEqual(got["totalNoBatch"], "totalNoBatch")

    def test_unplaced_rows(self):
        rows = [drop("m", method=None, casts=10, castsWithDrop=1),
                drop("i", inputItemID=None, inputName=None, casts=10, castsWithDrop=1),
                drop("o", outputItemID=None, outputName=None, casts=10, castsWithDrop=1)]
        _, unplaced, usage = b.analyze(rows)
        self.assertEqual(unplaced, 3)
        self.assertEqual([usage[id(r)]["reason"] for r in rows], ["unplaced:noMethod", "unplaced:noInput", "unplaced:noOutput"])

    def test_reference_rows(self):
        used = drop("ru", sourceKind="tsm-table", percentShown=50, percentMeaning="perCast", studyKey="ru")
        empty = drop("re", sourceKind="tsm-table", studyKey="re")
        other_unit = drop("rb", sourceKind="tsm-table", percentShown=40, percentMeaning="perCast", studyKey="rb",
                          method="Mill", inputsPerCast=20)
        smaller = drop("rs", sourceKind="tsm-table", studyKey="rs", method="Mill", inputsPerCast=5)
        res, usage = self.usage([used, empty])
        self.assertEqual(usage[id(used)]["roles"], ["prior"])
        self.assertEqual(usage[id(empty)]["reason"], "reference:noUsableValue")
        _, usage = self.usage([other_unit, smaller])
        self.assertEqual(usage[id(other_unit)]["reason"], "reference:otherUnit")

    def test_reference_chance_is_superseded_by_studies_that_only_measured_the_average(self):
        ref = drop("r", sourceKind="tsm-table", percentShown=50, percentMeaning="perCast", studyKey="r")
        study = drop("a", casts=100, totalQuantity=30, studyKey="a")
        res, usage = self.usage([ref, study])
        self.assertEqual(usage[id(ref)]["reason"], "reference:priorSuperseded")
        self.assertEqual(res[0]["chanceSource"], "estimated")

    def test_non_drop_records(self):
        rows = [{"id": "x1", "type": "exchange"}, {"id": "x2", "type": "token"}, {"id": "x3", "type": "recipe"},
                {"id": "x4", "type": "noDisenchant"}, {"id": "x5", "type": "rateChange"}, {"id": "x6", "type": "searched"},
                {"id": "x7", "type": "condition", "method": "Prospect", "outputItemID": 2001},
                {"id": "x8", "type": "condition", "method": None}, {"id": "x9"}, {"id": "x10", "type": "weird"}]
        _, _, usage = b.analyze(rows)
        self.assertEqual([usage[id(r)].get("reason") or "used" for r in rows],
                         ["type:exchange", "type:token", "type:recipe", "type:noDisenchant", "type:rateChange",
                          "type:searched", "used", "condition:incomplete", "type:missing", "type:unknown"])

    def test_every_record_is_used_or_has_exactly_one_known_reason(self):
        rows = [drop("a", casts=100, castsWithDrop=20, totalQuantity=30, studyKey="a"),
                drop("b", studyKey="b"), drop("c", studyKey="c", totalQuantity=3),
                drop("d", method=None, studyKey="d", casts=5, castsWithDrop=1),
                drop("e", sourceKind="tsm-table", studyKey="e"), {"id": "x", "type": "token"}]
        _, _, usage = b.analyze(rows)
        self.assertEqual(set(usage), {id(r) for r in rows})
        for r in rows:
            u = usage[id(r)]
            self.assertEqual(u["used"], u.get("reason") is None)
            self.assertTrue(u["used"] or u["reason"] in b.REASON_CODES, u)

    def test_report_totals_and_determinism(self):
        rows = [drop("a", casts=100, castsWithDrop=20, studyKey="a"), drop("b", studyKey="b"),
                {"id": "x", "type": "token", "_file": "t.jsonl"}]
        _, _, usage = b.analyze(rows)
        report = b.unused_report(rows, usage)
        self.assertEqual((report["records"], report["used"], report["unused"]), (3, 1, 2))
        self.assertEqual(report["unusedByReason"], {"noNumbers": 1, "type:token": 1})
        self.assertEqual(report["usedByRole"], {"chance": 1})
        self.assertEqual(report, b.unused_report(list(rows), b.analyze(list(rows))[2]))
        self.assertEqual(sum(report["unusedByReason"].values()), len(report["unusedRecords"]))

    def test_build_and_analyze_agree(self):
        rows = [drop("a", casts=100, castsWithDrop=20, studyKey="a"), drop("b", studyKey="b")]
        self.assertEqual(b.build(rows), b.analyze(rows)[:2])

    def test_main_writes_unused_json_byte_identically(self):
        self.put("evidence/t/a.jsonl", [drop("a", casts=100, castsWithDrop=20), drop("b", studyKey="b")])
        out = os.path.join(self.root, "out")
        saved, b.OUT = b.OUT, out
        try:
            with contextlib.redirect_stdout(io.StringIO()):
                b.main()
            first = {n: open(os.path.join(out, n), "rb").read() for n in ("estimates.json", "unused.json", "summary.md")}
            with contextlib.redirect_stdout(io.StringIO()):
                b.main()
            second = {n: open(os.path.join(out, n), "rb").read() for n in first}
        finally:
            b.OUT = saved
        self.assertEqual(first, second)
        self.assertEqual(json.loads(first["unused.json"])["unusedByReason"], {"noNumbers": 1})
        self.assertIn("each have a reason in `unused.json`", first["summary.md"].decode())


class Effects(Fixture):
    """tools/estimator_effects.py compares the old and new rule on the same rows."""

    def test_it_counts_only_records_whose_result_changes(self):
        self.put("rate-changes.jsonl", [{"date": "2026-03-31", "method": "Prospect", "affects": "Midnight ore"}])
        rows = [drop("same", inputItemID=237359, casts=10, castsWithDrop=1, dataDate="2026-04-02", studyKey="same"),
                drop("prose", inputItemID=237359, casts=10, castsWithDrop=1, dataDate="2026-04 live realms", studyKey="prose",
                     published="2026-04-23"),
                drop("flag", casts=10, castsWithDrop=1, unlockState=True, specialization="unlock: no", studyKey="flag"),
                drop("pct", percentShown=10, percentMeaning=None, studyKey="pct")]
        d = effects.report(rows)
        self.assertEqual(d["unlock"]["recordsChanged"], ["flag"])
        self.assertEqual(d["dates"]["studyDateChanged"], ["prose"])
        self.assertEqual(d["dates"]["epochWeightChanged"], ["prose"])
        self.assertEqual(d["percent"]["rowsChanged"], ["pct"])
        self.assertEqual(d["dates"]["proseDateFields"], {"dataDate": 1})
        self.assertEqual(d["records"], 4)

    def test_it_agrees_with_the_estimator_on_the_corpus(self):
        d = effects.report(b.load())
        self.assertEqual((d["unlock"]["recordsChanged"], d["dates"]["studyDateChanged"], d["dates"]["epochWeightChanged"],
                          d["percent"]["rowsChanged"]), ([], [], [], []))
        self.assertEqual(d["usage"]["used"] + d["usage"]["unused"], d["records"])


class Corpus(unittest.TestCase):
    """The committed evidence: the three guards change nothing there, and every record is accounted for."""

    @classmethod
    def setUpClass(cls):
        cls.rows = b.load()
        cls.results, cls.unplaced, cls.usage = b.analyze(cls.rows)

    def test_every_effective_record_is_used_or_has_a_reason(self):
        self.assertEqual(set(self.usage), {id(r) for r in self.rows})
        for r in self.rows:
            u = self.usage[id(r)]
            self.assertEqual(u["used"], u.get("reason") is None, r["id"])
            self.assertTrue(u["used"] or u["reason"] in b.REASON_CODES, (r["id"], u))

    def test_unplaced_matches_the_estimator_count(self):
        self.assertEqual(self.unplaced, sum(1 for u in self.usage.values() if str(u.get("reason")).startswith("unplaced:")))

    def test_analyze_matches_build(self):
        self.assertEqual((self.results, self.unplaced), b.build(self.rows))

    def test_no_record_sets_unlock_state_yet(self):
        # Measured in MIG-009: with no structured field anywhere, the text fallback decides everything.
        self.assertEqual(sum(1 for r in self.rows if "unlockState" in r), 0)

    def test_no_prose_dates_and_no_null_percent_meaning(self):
        for r in self.rows:
            for field in ("dataDate", "observedOn"):
                if r.get(field) is not None:
                    self.assertIsNotNone(b.iso_date(r[field]), (r["id"], field, r[field]))
            if r.get("type") == "drop" and r.get("percentShown") is not None:
                self.assertIsNotNone(r.get("percentMeaning"), r["id"])

    def test_numeric_reasons_reconcile_with_the_m06_unused_list(self):
        """Every row the M06 report says contributes nothing is unused here too, with the same code or because
        the estimator drops it first as a duplicate, a copy or a left-out unlock."""
        m06 = {(e["file"], e["id"]): e["reasons"][-1] for e in units_report.report(self.rows)["unusedRows"]}
        by_key = {(r["_file"], r["id"]): self.usage[id(r)] for r in self.rows}
        dedupe = {"duplicateRowInStudy", "duplicateStudy", "copy:vaguerGroup", "copy:pooledStudy",
                  "conditional:unlockFalse", "conditional:unlockUnstated"}
        same = {"totalWithoutCasts": "totalWithoutCasts", "noNumbers": "noNumbers",
                "hitsWithoutCasts": "hitsWithoutCasts", "percent:unclear": "percentNotPerCast",
                "percent:perInput": "percentNotPerCast"}   # perInput: 23 agent rows by M10
        for key, reason in m06.items():
            u = by_key[key]
            self.assertFalse(u["used"], key)
            self.assertIn(u["reason"], dedupe | {same[reason]}, (key, reason, u))
        numeric = {"totalWithoutCasts", "noNumbers", "hitsWithoutCasts", "percentNotPerCast", "percentOutOfRange",
                   "averageNoBatch", "totalNoBatch", "chanceNotConvertible"}
        mine = {k for k, u in by_key.items() if u.get("reason") in numeric}
        self.assertEqual(mine - set(m06), set())


if __name__ == "__main__":
    unittest.main()
