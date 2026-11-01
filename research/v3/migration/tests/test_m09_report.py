#!/usr/bin/env python3
"""M09 (MIG-010) tests for research/v3/migration/tools/report.py.

Unit tests drive the pure functions with small hand-made inputs. The Corpus class runs the whole report twice on the real repository
(with_tests=False: main() runs this suite, so collect() here must not) and recomputes a sample of the figures from the files.

Run from the repository root:
  python3 -m unittest discover -s research/v3/migration/tests -v
"""
import collections
import copy
import json
import os
import re
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
sys.path.insert(0, os.path.join(HERE, "..", "tools"))
import build_estimates as b  # noqa: E402
import report  # noqa: E402

MIG = os.path.join(REPO, "research", "v3", "migration")
MANI = os.path.join(MIG, "manifest")


def est(out="1", conf=40, method="Prospect", inp="10", conditional=False, source="measured", casts=100.0):
    return {"method": method, "input": inp, "outputItemID": out, "confidence": conf, "conditional": conditional,
            "chanceSource": source, "studyCasts": casts}


class Bands(unittest.TestCase):
    def test_boundaries(self):
        self.assertEqual([report.band(est(conf=c)) for c in (49, 50, 74, 75, 89, 90)],
                         ["under 50%", "50-74%", "50-74%", "75-89%", "75-89%", "90%+"])

    def test_conditional_sits_apart_whatever_its_confidence(self):
        self.assertEqual(report.band(est(conf=95, conditional=True)), "conditional")

    def test_counts_match_the_estimator_summary(self):
        rows = [est("1", 95), est("2", 80), est("3", 60), est("4", 10), est("5", 95, conditional=True)]
        text = b.summary(rows, 0, 5)
        counts = report.band_counts(rows)
        self.assertIn(f"| 90% or more | {counts['90%+']} |", text)
        self.assertIn(f"| 75-89% | {counts['75-89%']} |", text)
        self.assertIn(f"| 50-74% | {counts['50-74%']} |", text)
        self.assertIn(f"| under 50% | {counts['under 50%']} |", text)
        self.assertEqual(counts["conditional"], 1)

    def test_coverage_counts(self):
        m = {"records": 9, "dropRows": 3, "studyRows": 2, "referenceRows": 1, "studyKeys": 1, "unplaced": 4,
             "estimates": [est("1", source="measured", casts=10.5), est("2", source="estimated", casts=None), est("3", method="Mill")]}
        c = report.coverage(m)
        self.assertEqual(c["estimates"], 3)
        self.assertEqual(c["studyCastsTotal"], 110.5)
        self.assertEqual(c["estimatesWithMeasuredChance"], 2)
        self.assertEqual(c["estimatesByMethod"], {"Mill": 1, "Prospect": 2})


class Moves(unittest.TestCase):
    def test_a_move_names_the_stage_it_happened_in(self):
        moves = report.band_moves([("a", None, [est(conf=60)]), ("b", "identity", [est(conf=60)]), ("c", "units", [est(conf=40)])])
        self.assertEqual(len(moves), 1)
        self.assertEqual(moves[0]["causes"], ["units"])
        self.assertEqual(moves[0]["direction"], "down")
        self.assertEqual(moves[0]["steps"], [{"stage": "c", "cause": "units", "from": "50-74%", "to": "under 50%"}])

    def test_two_steps_give_both_causes(self):
        moves = report.band_moves([("a", None, [est(conf=40)]), ("b", "x", [est(conf=60)]), ("c", "y", [est(conf=95)])])
        self.assertEqual(moves[0]["causes"], ["x", "y"])
        self.assertEqual(moves[0]["direction"], "up")

    def test_same_band_is_no_move_even_after_a_detour(self):
        self.assertEqual(report.band_moves([("a", None, [est(conf=40)]), ("b", "x", [est(conf=60)]), ("c", "y", [est(conf=41)])]), [])

    def test_an_estimate_that_leaves_and_returns_shows_both_steps(self):
        moves = report.band_moves([("a", None, [est(conf=60)]), ("b", "x", []), ("c", "y", [est(conf=40)])])
        self.assertEqual([(s["from"], s["to"]) for s in moves[0]["steps"]], [("50-74%", None), (None, "under 50%")])

    def test_added_or_removed_is_not_a_move(self):
        self.assertEqual(report.band_moves([("a", None, [est("1")]), ("b", "x", [est("2")])]), [])

    def test_stage_changes(self):
        seq = [("a", None, [est("1", 60), est("2", 40)]), ("b", "x", [est("1", 40), est("3", 40)])]
        self.assertEqual(report.stage_changes(seq), [{"stage": "b", "cause": "x", "added": 1, "removed": 1, "movedBand": 1}])


class Parsing(unittest.TestCase):
    TEXT = "\n".join(["# t", "", "## For the Master", "", "1. First item", "   continues here.", "2. **Second** item.", "",
                      "A closing paragraph.", "", "3. Late item.", "", "## Next", "", "4. Not this one."])

    def test_numbered_items_stop_at_the_next_heading(self):
        items = report.parse_numbered_items(self.TEXT, r"^## For the Master")
        self.assertEqual([i["number"] for i in items], [1, 2, 3])
        self.assertEqual(items[0]["text"], "First item continues here.")
        self.assertEqual(items[1]["line"], 7)

    def test_a_missing_heading_is_an_error(self):
        with self.assertRaises(ValueError):
            report.parse_numbered_items(self.TEXT, r"^## Absent")

    def test_title_is_the_first_sentence_without_emphasis(self):
        self.assertEqual(report.title_of("**Output policy** here. More text."), "Output policy here.")

    def test_title_keeps_decimals_and_colons(self):
        self.assertEqual(report.title_of("Approve the 0.5 weight: yes or no? Then go."), "Approve the 0.5 weight: yes or no?")

    def test_long_title_is_cut(self):
        self.assertLessEqual(len(report.title_of("x" * 400)), 160)


class Items(unittest.TestCase):
    def test_every_entry_is_well_formed(self):
        for key, e in report.ITEMS.items():
            if "closedBy" in e:
                self.assertTrue(os.path.exists(os.path.join(MIG, e["closedBy"])), key)
                continue
            self.assertIn(e["m10"], ("blocks", "handle", "none"), key)
            self.assertTrue(e["kind"] and e["action"], key)
            if e["m10"] != "none":
                self.assertTrue(e.get("m10Why"), key)

    def test_see_targets_exist(self):
        kinds = {r["kind"] for r in report.jl(os.path.join(MANI, "exceptions.jsonl"))}
        rows = list(report.ITEMS.items()) + [(h["id"], h) for h in report.HANDOFF_ITEMS]
        for key, e in rows:
            see = e.get("see")
            if see and see.startswith("exceptions:"):
                self.assertIn(see.split(":", 1)[1], kinds, key)
            elif see:
                self.assertIn(see, report.ITEMS, key)
                self.assertNotIn("closedBy", report.ITEMS[see], key)

    def test_actions_carry_no_hand_typed_figures(self):
        for key, e in report.ITEMS.items():
            self.assertNotRegex(re.sub("[MS][0-9]+", "", e.get("action", "")), "[0-9]", key)   # M05, S14 name a task or a thread

    def test_reason_text_covers_the_closed_vocabulary(self):
        self.assertEqual(set(report.REASON_TEXT), set(b.REASON_CODES))

    def test_a_report_item_without_an_entry_fails(self):
        saved = report.ITEMS.pop("M08-estimator/master#6")
        try:
            with self.assertRaises(ValueError):
                report.register({})
        finally:
            report.ITEMS["M08-estimator/master#6"] = saved

    def test_an_entry_without_a_report_item_fails(self):
        report.ITEMS["M08-estimator/master#99"] = {"closedBy": "PLAN.md"}
        try:
            with self.assertRaises(ValueError):
                report.register({})
        finally:
            del report.ITEMS["M08-estimator/master#99"]


class Trees(unittest.TestCase):
    def test_snapshot_fix_changes_only_that_line(self):
        with tempfile.TemporaryDirectory() as tmp:
            tools = os.path.join(tmp, "research", "v3", "tools")
            os.makedirs(tools)
            path = os.path.join(tools, "build_estimates.py")
            with open(path, "w", encoding="utf-8", newline="") as f:
                f.write('a = 1\n            r["_file"] = os.path.relpath(path, ROOT)\nb = 2\n')
            report.fix_snapshot_estimator(tmp)
            with open(path, encoding="utf-8", newline="") as f:
                self.assertEqual(f.read(), 'a = 1\n            r["_file"] = os.path.relpath(path, ROOT).replace(os.sep, "/")\nb = 2\n')

    def test_snapshot_fix_refuses_a_file_without_the_line(self):
        with tempfile.TemporaryDirectory() as tmp:
            tools = os.path.join(tmp, "research", "v3", "tools")
            os.makedirs(tools)
            with open(os.path.join(tools, "build_estimates.py"), "w", encoding="utf-8") as f:
                f.write("a = 1\n")
            with self.assertRaises(RuntimeError):
                report.fix_snapshot_estimator(tmp)

    def test_source_counts_tell_a_mention_from_a_source(self):
        with tempfile.TemporaryDirectory() as tmp:
            ev = os.path.join(tmp, "research", "v3", "evidence")
            os.makedirs(ev)
            with open(os.path.join(ev, "a.jsonl"), "w", encoding="utf-8") as f:
                f.write(json.dumps({"id": "x", "source": {"url": "https://example.com/a"}, "notes": "see https://example.com/b"}) + "\n")
            import inventory
            keys = [{"key": inventory.normalize_url(u)} for u in ("https://example.com/a", "https://example.com/b", "https://example.com/c")]
            self.assertEqual(report.source_counts(tmp, keys), {"registry": 3, "mentioned": 2, "citedAsSource": 1})


def history_available():
    p = subprocess.run(["git", "-C", REPO, "cat-file", "-e", report.SNAPSHOT], capture_output=True)
    return p.returncode == 0


@unittest.skipUnless(history_available(), "needs the branch's git history")
class Corpus(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        output = os.path.join(REPO, "research", "v3", "output")
        before = {n: report.sha256(os.path.join(output, n)) for n in os.listdir(output)}
        cls.data = report.collect(with_tests=False)
        cls.second = report.collect(with_tests=False)
        cls.output_after = {n: report.sha256(os.path.join(output, n)) for n in os.listdir(output)}
        cls.output_before = before
        cls.md = report.render(cls.data)
        cls.rows = b.load()

    def test_two_runs_are_byte_identical(self):
        self.assertEqual(json.dumps(self.data, sort_keys=True), json.dumps(self.second, sort_keys=True))
        self.assertEqual(self.md, report.render(self.second))

    def test_the_report_writes_nothing_to_output(self):
        self.assertEqual(self.output_before, self.output_after)

    def test_snapshot_rebuild_agrees_with_the_plan(self):
        self.assertEqual(self.data["baselineCheck"]["differs"], {})

    def test_every_stage_commit_exists_and_the_first_is_the_snapshot(self):
        self.assertEqual(self.data["bands"]["stages"][0]["stage"], "snapshot")
        self.assertEqual(len(self.data["bands"]["stages"]), len(report.STAGES) + 1)

    def test_after_recomputed_from_the_estimator(self):
        results, unplaced = b.build(self.rows)
        after = self.data["coverage"]["after"]
        self.assertEqual((after["records"], after["estimates"], after["unplaced"]), (len(self.rows), len(results), unplaced))
        self.assertEqual(self.data["bands"]["after"], report.band_counts(results))
        self.assertEqual(after["estimatesWithMeasuredChance"], sum(1 for e in results if e["chanceSource"] == "measured"))

    def test_usage_recomputed_from_the_estimator(self):
        _, _, usage = b.analyze(self.rows)
        u = b.unused_report(self.rows, usage)
        for key in ("records", "used", "unused", "unusedByReason", "usedByRole"):
            self.assertEqual(self.data["usage"][key], u[key])
        top = [t["records"] for t in self.data["usage"]["topReasons"]]
        self.assertEqual(top, sorted(u["unusedByReason"].values(), reverse=True)[:5])

    def test_dispositions_equal_the_manifest_summary(self):
        d = self.data["dispositions"]
        self.assertTrue(d["equalsSummary"])
        self.assertEqual(d["files"], d["inventoryFiles"])
        self.assertEqual(sum(d["byDisposition"].values()), d["files"])

    def test_capped_estimates_recomputed(self):
        results, _ = b.build(self.rows)
        capped = [e for e in results if not e["conditional"] and e["chanceSource"] == "estimated" and e["confidence"] == 50]
        self.assertEqual(self.data["bands"]["afterCappedAt50"], len(capped))
        self.assertLessEqual(max(e["confidence"] for e in results if e["chanceSource"] == "estimated" and not e["conflict"]), 50)

    def test_every_band_move_has_a_cause_and_adds_up(self):
        bands = self.data["bands"]
        self.assertTrue(all(m["steps"] and m["causes"] for m in bands["moves"]))
        self.assertEqual(sum(bands["byCauses"].values()), bands["moved"])
        self.assertEqual(bands["up"] + bands["down"], bands["moved"])

    def test_exceptions_are_all_in_the_register_once(self):
        rows = report.jl(os.path.join(MANI, "exceptions.jsonl"))
        ids = [r["id"] for r in self.data["register"]["rows"] if r["origin"] == "exception"]
        self.assertEqual(sorted(ids), sorted(r["id"] for r in rows))
        self.assertEqual(self.data["register"]["exceptionsByKind"], dict(sorted(collections.Counter(r["kind"] for r in rows).items())))
        self.assertEqual(self.data["register"]["recordIDsNamed"], sum(len(r["recordIDs"]) for r in rows))

    def test_validator_and_scope_gap_counts_match_the_manifests(self):
        rows = {r["id"]: r for r in self.data["register"]["rows"]}
        v = report.read_json(os.path.join(MANI, "validation.json"))
        self.assertEqual(sum(r["count"] for r in rows.values() if r["origin"] == "validator"), v["errors"])
        gap = report.jl(os.path.join(MANI, "scope-gap.jsonl"))
        self.assertEqual(sum(r["count"] for r in rows.values() if r["origin"] == "scope-gap"), len(gap))

    def test_validator_rows_are_the_queued_validator_errors(self):
        rows = self.data["register"]["rows"]
        named = {i for r in rows if r["origin"] == "validator" for i in r["recordIDs"]}
        queued = {i for r in rows if r["kind"] == "validator-error" and r["origin"] == "exception" for i in r["recordIDs"]}
        self.assertEqual(named, queued)

    def test_every_register_row_cites_a_file(self):
        for r in self.data["register"]["rows"] + self.data["register"]["closed"]:
            self.assertTrue(os.path.exists(os.path.join(REPO, r["source"])), r["id"])
            if r.get("line"):
                with open(os.path.join(REPO, r["source"]), encoding="utf-8") as f:
                    self.assertTrue(f.read().split("\n")[r["line"] - 1].strip(), r["id"])

    def test_report_rows_quote_their_line(self):
        for r in self.data["register"]["rows"]:
            if r["id"].startswith("M") and r["line"]:
                with open(os.path.join(REPO, r["source"]), encoding="utf-8") as f:
                    line = f.read().split("\n")[r["line"] - 1]
                self.assertRegex(line, r"^\d+\. ", r["id"])

    def test_m10_blockers_are_marked_in_the_markdown(self):
        for r in self.data["register"]["rows"]:
            if r["blocksM10"]:
                self.assertIn(f"- **{r['id']}**", self.md)
        self.assertIn(f"**M10 blockers: {self.data['register']['blocksM10']}.**", self.md)

    def test_scipy_setting_is_stated(self):
        self.assertIn("SciPy", self.md.split("## 1.")[0])

    def test_markdown_figures_all_come_from_the_data(self):
        def numbers(text):
            return {x.replace(",", "") for x in re.findall(r"(?<![\w.])\d[\d,]*(?:\.\d+)?", text)}

        def walk(o):
            if isinstance(o, dict):
                for k, v in o.items():
                    yield k
                    yield from walk(v)
            elif isinstance(o, list):
                for v in o:
                    yield from walk(v)
            else:
                yield o
        known = set()
        for v in walk(copy.deepcopy(self.data)):
            known |= numbers(str(v))
        body = re.sub(r"`[^`]*`", "", self.md)
        body = re.sub(r"^#+ .*$", "", body, flags=re.M)   # section numbers
        self.assertEqual(numbers(body) - known - {"1"}, set())   # "PLAN section 1"

    def test_committed_report_is_current(self):
        path = report.OUT_JSON
        if os.environ.get("M09_REPORT_RUNNING") or not os.path.exists(path):
            self.skipTest("the report is being regenerated")
        committed = report.read_json(path)
        if committed["scipy"] != self.data["scipy"]:
            self.skipTest("confidence values depend on the SciPy setting")
        tests = committed["reproducibility"].pop("tests")
        fresh = copy.deepcopy(self.data)
        fresh["reproducibility"].pop("tests")
        self.assertEqual(json.dumps(committed, sort_keys=True), json.dumps(fresh, sort_keys=True))
        committed["reproducibility"]["tests"] = tests
        with open(report.OUT_MD, encoding="utf-8", newline="") as f:
            self.assertEqual(f.read(), report.render(committed))


if __name__ == "__main__":
    unittest.main()
