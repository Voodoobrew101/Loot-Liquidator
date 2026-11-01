#!/usr/bin/env python3
"""M04.3 (MIG-007) tests for research/v3/migration/tools/extract_batch.py.

Synthetic repositories in a temp directory cover the prompt, the answer validator (accepts and rejects), each
arithmetic check, checkpoints and resume, and the deterministic writer. The last class checks the committed
checkpoints and the committed evidence file against a fresh run on the real repository.

Run from the repository root:
  python3 -m unittest discover -s research/v3/migration/tests -v
"""
import copy
import hashlib
import json
import os
import shutil
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
sys.path.insert(0, os.path.join(HERE, "..", "tools"))
import extract_batch as eb  # noqa: E402
import validate as val  # noqa: E402

URL = "https://www.reddit.com/r/woweconomy/comments/abc123/title/"
OTHER = "https://www.reddit.com/r/woweconomy/comments/zzz999/other/"
NOTE = "research/notes/a.md"
TEXT = "\n".join([
    "# Notes on herbs",
    "",
    "## Studies",
    f"- [Post]({URL}): author milled 1,000 herbs in 200 casts and got 130 pigment; 120 casts gave at least one (60%). "
    "Largest stack seen was 2, smallest 1.",
    f"- [Other]({OTHER}): 77 casts gave 5 pigment.",
    "",
    "Loose line: histogram of 200 casts: 80 gave 0, 70 gave 1, 50 gave 2, so 170 pigment in all. Ranks: 40 R1 + 60 R2 + 30 R3 = 130.",
    "A 3000 herb comment, no batch size. Stated on 2021-05-30 at patch 9.0.5.",
    "",
])


def sha(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def line_of(text, needle):
    for n, line in enumerate(text.splitlines(), 1):
        if needle in line:
            return n
    raise AssertionError(needle)


class Repo(unittest.TestCase):
    """A temporary repository with one note file and a queue entry for reddit:abc123."""

    text = TEXT

    def setUp(self):
        self.root = tempfile.mkdtemp()
        self.write(NOTE, self.text)
        self.entry = self.make_entry("reddit:abc123", [URL], NOTE, self.text)
        self.write_queue([self.entry])

    def tearDown(self):
        shutil.rmtree(self.root, ignore_errors=True)

    def write(self, rel, text):
        path = os.path.join(self.root, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8", newline="") as fh:
            fh.write(text)

    def make_entry(self, source, urls, rel, text, anchors=(4,), proximity="citation"):
        return {"source": source, "rawUrls": urls, "expectedTypes": ["drop"], "methodHints": ["Mill"],
                "v3Mentions": False, "fileCount": 1, "note": "hints",
                "files": [{"path": rel, "sha256": sha(text), "category": "observation", "proximity": proximity,
                           "anchorCount": len(anchors), "anchors": [{"line": n, "numbers": [], "text": ""} for n in anchors]}]}

    def write_queue(self, entries):
        self.write(eb.QUEUE, "".join(json.dumps(e, sort_keys=True) + "\n" for e in entries))

    def add_line(self, line, tie=True):
        """Append a line (under this source's URL unless tie=False) and return its evidence span."""
        prefix = f"- [Q]({URL}): " if tie else ""
        text = self.text.rstrip("\n") + "\n" + prefix + line + "\n"
        self.write(NOTE, text)
        self.text = text
        n = len(text.splitlines())
        self.entry = self.make_entry("reddit:abc123", [URL], NOTE, text, anchors=(4, n))
        self.write_queue([self.entry])
        return {"line": n, "text": line}

    def holder(self, url, rel="research/v3/evidence/legacy/a.jsonl", rid="legacy-1"):
        self.write(rel, json.dumps({"id": rid, "type": "drop", "source": {"url": url}}) + "\n")

    def span(self, needle, text=None):
        text = text or self.text
        n = line_of(text, needle)
        return {"line": n, "text": needle}

    def answer(self, **rec):
        record = {"studyLabel": "post", "method": "Mill", "casts": 200, "castsBasis": "reported", "totalQuantity": 130,
                  "castsWithDrop": 120, "percentShown": 60, "percentMeaning": "perCast", "minSeen": 1, "maxSeen": 2,
                  "inputsProcessed": 1000}
        record.update(rec)
        record = {k: v for k, v in record.items() if v != "DROP"}
        return {"source": "reddit:abc123", "result": "rows",
                "rows": [{"path": NOTE, "type": "drop", "record": record, "evidence": [
                    self.span("author milled 1,000 herbs in 200 casts and got 130 pigment; 120 casts gave at least one (60%)"),
                    self.span("Largest stack seen was 2, smallest 1")]}]}

    def check(self, ans):
        problems, info = eb.validate_answer(ans, self.entry, self.root)
        return list(problems), info

    def reject(self, ans, fragment):
        problems, _ = self.check(ans)
        self.assertTrue(problems, "expected a rejection")
        self.assertTrue(any(fragment in p for p in problems), f"{fragment!r} not in {problems}")


class PromptTests(Repo):
    def test_prompt_names_the_source_and_quotes_numbered_lines(self):
        p = eb.build_prompt(self.entry, self.root)
        self.assertIn("EXTRACTION TASK - source reddit:abc123", p)
        self.assertIn(URL, p)
        self.assertIn(f"sha256 {sha(self.text)}", p)
        n = line_of(self.text, "author milled")
        self.assertIn(f">>{n:4d}| - [Post]({URL})", p)

    def test_prompt_carries_the_rules_and_the_schema(self):
        p = eb.build_prompt(self.entry, self.root)
        for needle in ("Null on doubt", "No invented numbers", "Quote the text", "VERBATIM", "Never guess an item ID",
                       "castsBasis", "derivations", "reasonCode", "proposals"):
            self.assertIn(needle, p)

    def test_brief_prompt_leaves_out_rules_and_schema(self):
        p = eb.build_prompt(self.entry, self.root, brief=True)
        self.assertNotIn("RULES", p)
        self.assertNotIn("TARGET SCHEMA", p)
        self.assertIn("author milled", p)

    def test_window_is_the_anchor_plus_context_and_full_shows_everything(self):
        text = "\n".join(f"line {i}" for i in range(1, 41)) + "\n"
        self.write("research/notes/long.md", text)
        entry = self.make_entry("reddit:abc123", [URL], "research/notes/long.md", text, anchors=(20,))
        window = eb.build_prompt(entry, self.root, brief=True)
        self.assertIn("  18| line 18", window)
        self.assertIn(">>  20| line 20", window)
        self.assertNotIn("line 10", window)
        self.assertIn("line 10", eb.build_prompt(entry, self.root, full=True, brief=True))

    def test_citation_lines_are_marked(self):
        text = "x\n" * 10 + f"see {URL} here\n" + "y\n" * 10
        self.write("research/notes/c.md", text)
        entry = self.make_entry("reddit:abc123", [URL], "research/notes/c.md", text, anchors=(2,), proximity="file")
        p = eb.build_prompt(entry, self.root, brief=True)
        self.assertIn("@@  11| see", p)
        self.assertIn("elsewhere in the file", p)

    def test_json_files_are_shown_whole(self):
        text = '{\n  "a": 1,\n  "url": "%s"\n}\n' % URL
        self.write("research/notes/j.json", text)
        entry = self.make_entry("reddit:abc123", [URL], "research/notes/j.json", text, anchors=())
        p = eb.build_prompt(entry, self.root, brief=True)
        self.assertIn('   2|   "a": 1,', p)


class ValidatorAccepts(Repo):
    def test_a_clean_row_is_accepted(self):
        problems, info = self.check(self.answer())
        self.assertEqual(problems, [])
        self.assertEqual(info["rows"], 1)

    def test_null_answer_with_code_and_reason(self):
        ans = {"source": "reddit:abc123", "result": "null", "reasonCode": "qualitative",
               "reason": "The post is cited for a description in words only."}
        self.assertEqual(self.check(ans)[0], [])

    def test_derived_casts_are_accepted_when_the_formula_checks(self):
        span = self.add_line("1,000 herbs at 5 herbs per mill gave 40 pigment")
        ans = {"source": "reddit:abc123", "result": "rows", "rows": [{
            "path": NOTE, "type": "drop", "evidence": [span],
            "record": {"studyLabel": "b", "method": "Mill", "inputsProcessed": 1000, "inputsPerCast": 5, "casts": 200,
                       "castsBasis": "countedFromInputs", "totalQuantity": 40,
                       "derivations": [{"field": "casts", "formula": "inputsProcessed / inputsPerCast", "assumption": "no refunds"}]}}]}
        self.assertEqual(self.check(ans)[0], [])

    def test_item_id_in_the_evidence_keeps_its_name(self):
        span = self.add_line("Ore 36910 gave 12 Sun Crystal 36921 in 50 casts")
        ans = {"source": "reddit:abc123", "result": "rows", "rows": [{
            "path": NOTE, "type": "drop", "evidence": [span],
            "record": {"studyLabel": "s", "method": "Prospect", "inputItemID": 36910, "inputName": "Ore",
                       "outputItemID": 36921, "outputName": "Sun Crystal", "casts": 50, "castsBasis": "reported",
                       "totalQuantity": 12}}]}
        self.assertEqual(self.check(ans)[0], [])

    def test_recipe_row(self):
        span = self.add_line("Mass Mill X uses 20 herbs, spell 9999")
        ans = {"source": "reddit:abc123", "result": "rows", "rows": [{
            "path": NOTE, "type": "recipe", "evidence": [span],
            "record": {"method": "Mill", "recipeSpellID": 9999, "inputsPerCast": 20}}]}
        self.assertEqual(self.check(ans)[0], [])

    def test_condition_is_a_proposal_not_a_row(self):
        ans = self.answer()
        ans["proposals"] = [{"type": "condition", "path": NOTE, "evidence": [self.span("Largest stack seen was 2, smallest 1")],
                             "record": {"method": "Mill", "requires": "a specialisation"}}]
        problems, info = self.check(ans)
        self.assertEqual(problems, [])
        self.assertEqual(info["proposals"], 1)
        ans["rows"][0]["type"] = "condition"
        self.reject(ans, "type must be drop, recipe or exchange")


class ValidatorRejects(Repo):
    def test_wrong_source(self):
        ans = self.answer()
        ans["source"] = "reddit:zzz999"
        self.reject(ans, "is not the queue entry")

    def test_unknown_top_level_key_and_unknown_field(self):
        ans = self.answer()
        ans["extra"] = 1
        self.reject(ans, "unknown key")
        self.reject(self.answer(foo=1), "unknown drop field")

    def test_file_not_in_the_entry(self):
        ans = self.answer()
        ans["rows"][0]["path"] = "research/notes/other.md"
        self.reject(ans, "is not one of the entry's files")

    def test_changed_file_is_refused(self):
        self.write(NOTE, self.text + "changed\n")
        self.reject(self.answer(), "no longer has the sha256")

    def test_quote_must_be_verbatim_and_on_the_named_line(self):
        ans = self.answer()
        ans["rows"][0]["evidence"][0]["text"] = "author milled 1,000 herbs in 200 casts and received 130 pigment"
        self.reject(ans, "not a verbatim part of the line")
        ans = self.answer()
        ans["rows"][0]["evidence"][1]["line"] = 3
        self.reject(ans, "not a verbatim part of the line")
        ans = self.answer()
        ans["rows"][0]["evidence"][1]["line"] = 99
        self.reject(ans, "is outside")

    def test_invented_number_is_rejected(self):
        self.reject(self.answer(totalQuantity=131), "is not written in the evidence")

    def test_item_id_not_in_the_evidence_is_rejected(self):
        self.reject(self.answer(outputItemID=173056), "outputItemID 173056 is not written in the evidence")

    def test_null_answer_needs_a_code_and_a_reason(self):
        self.reject({"source": "reddit:abc123", "result": "null", "reasonCode": "qualitative", "reason": "short"},
                    "at least 20 characters")
        self.reject({"source": "reddit:abc123", "result": "null", "reasonCode": "because",
                     "reason": "a perfectly long enough reason"}, "reasonCode must be one of")
        self.reject({"source": "reddit:abc123", "result": "maybe"}, "result must be")

    def test_source_v3_already_holds_is_refused_even_as_a_language_variant(self):
        self.holder("https://www.reddit.com/r/woweconomy/comments/abc123/another_title/")
        self.reject(self.answer(), "v3 holds this source already")
        shutil.rmtree(os.path.join(self.root, "research", "v3", "evidence"))
        self.assertEqual(eb.strip_lang("wowhead:news=a-1@es"), "wowhead:news=a-1")
        self.assertEqual(eb.strip_lang("wowhead:item=5@cata"), "wowhead:item=5@cata")
        self.holder("https://www.wowhead.com/es/news/a-1", rid="x")
        wh = self.make_entry("wowhead:news=a-1@fr", ["https://www.wowhead.com/fr/news/a-1"], NOTE, self.text)
        self.write_queue([wh])
        problems, _ = eb.validate_answer(
            {"source": "wowhead:news=a-1@fr", "result": "rows", "rows": [{"path": NOTE, "type": "drop", "evidence": [], "record": {}}]},
            wh, self.root)
        self.assertTrue(any("holds this source" in p for p in problems))

    def test_evidence_under_another_sources_url_needs_a_linking_quote(self):
        ans = self.answer()
        ans["rows"][0]["evidence"] = [self.span("77 casts gave 5 pigment")]
        ans["rows"][0]["record"] = {"studyLabel": "o", "method": "Mill", "casts": 77, "castsBasis": "reported", "totalQuantity": 5}
        self.reject(ans, "not under this source's own URL")

    def test_link_evidence_must_name_the_source(self):
        span = self.add_line("Elsewhere: 3000 herbs gave 100 pigment", tie=False)
        rec = {"studyLabel": "e", "method": "Mill", "inputsProcessed": 3000, "totalQuantity": 100}
        row = {"path": NOTE, "type": "drop", "evidence": [dict(span, text="3000 herbs gave 100 pigment")], "record": rec}
        ans = {"source": "reddit:abc123", "result": "rows", "rows": [row]}
        self.reject(ans, "not under this source's own URL")
        row["linkEvidence"] = dict(span, text="Elsewhere: 3000 herbs")
        self.reject(ans, "must name the source")
        row["linkEvidence"] = {"line": 4, "text": "abc123"}
        self.reject(ans, "within 3 lines")

    def test_quote_must_be_short_and_inside_the_evidence(self):
        long_quote = "author milled 1,000 herbs in 200 casts and got 130 pigment; 120 casts gave at least one (60%). Largest stack seen"
        self.reject(self.answer(quote=long_quote), "under 25 words")
        self.reject(self.answer(quote="words that are not there"), "under 25 words")

    def test_dates_must_be_written_in_the_evidence(self):
        self.reject(self.answer(dataDate="2021-05-30"), "dataDate '2021-05-30' is not written in the evidence")
        span = self.add_line("Stated on 2021-05-30 at patch 9.0.5")
        ans = self.answer(dataDate="2021-05-30", patch="9.0.5")
        ans["rows"][0]["evidence"].append(span)
        self.assertEqual(self.check(ans)[0], [])

    def test_percent_needs_a_meaning_and_casts_a_basis(self):
        self.reject(self.answer(percentMeaning=None), "needs an explicit percentMeaning")
        self.reject(self.answer(castsBasis="DROP"), "casts and castsBasis go together")

    def test_reported_casts_cannot_carry_a_derivation(self):
        d = [{"field": "casts", "formula": "inputsProcessed / 5", "assumption": "x"}]
        self.reject(self.answer(derivations=d), "reported casts cannot carry a casts derivation")


class Arithmetic(Repo):
    """Each cross-check, with the evidence holding every number so only the arithmetic can fail."""

    def with_text(self, line, rec, extra=None):
        span = self.add_line(line)
        record = {"studyLabel": "t", "method": "Mill"}
        record.update(rec)
        ans = {"source": "reddit:abc123", "result": "rows",
               "rows": [{"path": NOTE, "type": "drop", "evidence": [span], "record": record}]}
        if extra:
            ans.update(extra)
        return ans

    def test_hits_cannot_exceed_casts(self):
        ans = self.with_text("In 50 casts, 60 casts gave a drop.", {"casts": 50, "castsBasis": "reported", "castsWithDrop": 60, "totalQuantity": 70})
        self.reject(ans, "exceeds casts")

    def test_percent_must_match_hits_over_casts(self):
        ans = self.with_text("In 100 casts, 40 casts gave a drop (50%).",
                             {"casts": 100, "castsBasis": "reported", "castsWithDrop": 40, "percentShown": 50, "percentMeaning": "perCast"})
        self.reject(ans, "does not match castsWithDrop/casts")
        ok = self.with_text("In 100 casts, 40 casts gave a drop (40%).",
                            {"casts": 100, "castsBasis": "reported", "castsWithDrop": 40, "percentShown": 40, "percentMeaning": "perCast"})
        self.assertEqual(self.check(ok)[0], [])

    def test_average_must_match_total_over_casts(self):
        ans = self.with_text("100 casts, 250 pigment, average 3.1 per cast.",
                             {"casts": 100, "castsBasis": "reported", "totalQuantity": 250, "averageShown": 3.1, "averagePer": "cast"})
        self.reject(ans, "does not match total/denominator")
        ok = self.with_text("100 casts, 250 pigment, average 2.5 per cast.",
                            {"casts": 100, "castsBasis": "reported", "totalQuantity": 250, "averageShown": 2.5, "averagePer": "cast"})
        self.assertEqual(self.check(ok)[0], [])

    def test_total_is_bounded_by_casts_times_max_and_hits_times_min(self):
        ans = self.with_text("10 casts gave 50 pigment, at most 3 per cast.",
                             {"casts": 10, "castsBasis": "reported", "totalQuantity": 50, "maxSeen": 3})
        self.reject(ans, "exceeds casts x maxSeen")
        ans = self.with_text("10 casts, 4 gave a drop, 5 pigment, at least 2 each.",
                             {"casts": 10, "castsBasis": "reported", "castsWithDrop": 4, "totalQuantity": 5, "minSeen": 2})
        self.reject(ans, "below castsWithDrop x minSeen")

    def test_total_cannot_be_less_than_the_casts_that_dropped(self):
        ans = self.with_text("20 casts, 15 gave a drop and 9 pigment in all.",
                             {"casts": 20, "castsBasis": "reported", "castsWithDrop": 15, "totalQuantity": 9})
        self.reject(ans, "every hit gives at least one")

    def test_histogram_sums(self):
        line = "Histogram of 200 casts: 80 gave 0, 70 gave 1, 50 gave 2, so 170 pigment in all and 120 casts gave a drop."
        good = {"casts": 200, "castsBasis": "reported", "totalQuantity": 170, "castsWithDrop": 120,
                "histogram": {"0": 80, "1": 70, "2": 50}}
        self.assertEqual(self.check(self.with_text(line, good))[0], [])
        bad = dict(good, histogram={"0": 80, "1": 70, "2": 40})
        self.reject(self.with_text(line, bad), "histogram")
        self.reject(self.with_text(line, dict(good, totalQuantity=171)), "histogram amounts add to 170")
        self.reject(self.with_text(line, dict(good, castsWithDrop=70)), "zero bucket")

    def test_counted_casts_must_equal_inputs_over_batch(self):
        line = "1,000 herbs at 5 herbs per mill gave 40 pigment."
        d = [{"field": "casts", "formula": "inputsProcessed / inputsPerCast", "assumption": "no refunds"}]
        ok = {"inputsProcessed": 1000, "inputsPerCast": 5, "casts": 200, "castsBasis": "countedFromInputs", "totalQuantity": 40, "derivations": d}
        self.assertEqual(self.check(self.with_text(line, ok))[0], [])
        bad = dict(ok, casts=250)
        self.reject(self.with_text(line, bad), "derivation for casts")
        self.reject(self.with_text(line, dict(ok, derivations=[{"field": "casts", "formula": "1000 / 5", "assumption": "x"}])),
                    "countedFromInputs needs a casts derivation over inputsProcessed and inputsPerCast")

    def test_derivation_constants_must_be_in_the_evidence(self):
        line = "1,000 herbs gave 40 pigment."
        rec = {"inputsProcessed": 1000, "inputsPerCast": 5, "casts": 200, "castsBasis": "derived", "totalQuantity": 40,
               "derivations": [{"field": "casts", "formula": "inputsProcessed / 5", "assumption": "x"}]}
        self.reject(self.with_text(line, rec), "constant 5 is not in the evidence")

    def test_casts_times_batch_cannot_exceed_inputs(self):
        line = "In 300 casts of 5 herbs, 1,000 herbs gave 40 pigment."
        rec = {"inputsProcessed": 1000, "inputsPerCast": 5, "casts": 300, "castsBasis": "reported", "totalQuantity": 40}
        self.reject(self.with_text(line, rec), "exceeds inputsProcessed")

    def test_rank_rows_sum_to_the_stated_total(self):
        span = self.add_line("Ranks: 40 R1 + 60 R2 + 30 R3 = 130, and 70 R1 casts")
        rows = []
        for name, v in (("R1", 40), ("R2", 60), ("R3", 30)):
            rows.append({"path": NOTE, "type": "drop", "evidence": [span],
                         "record": {"studyLabel": "ranks", "method": "Mill", "outputName": name, "totalQuantity": v}})
        ans = {"source": "reddit:abc123", "result": "rows", "rows": rows,
               "checks": [{"kind": "sum", "field": "totalQuantity", "rows": [0, 1, 2], "stated": 130,
                           "evidence": dict(span, text="30 R3 = 130")}]}
        self.assertEqual(self.check(ans)[0], [])
        ans["rows"][2]["record"]["totalQuantity"] = 70
        self.reject(ans, "adds to 170, stated 130")

    def test_one_study_shares_casts_and_outputs_are_unique(self):
        base = {"studyLabel": "s", "method": "Mill", "casts": 200, "castsBasis": "reported", "totalQuantity": 130}
        ev = [self.span("author milled 1,000 herbs in 200 casts and got 130 pigment; 120 casts gave at least one (60%)")]
        r1 = {"path": NOTE, "type": "drop", "evidence": ev, "record": dict(base, outputName="A")}
        r2 = {"path": NOTE, "type": "drop", "evidence": ev, "record": dict(base, outputName="A")}
        self.reject({"source": "reddit:abc123", "result": "rows", "rows": [r1, r2]}, "appears 2 times")
        r2 = {"path": NOTE, "type": "drop", "evidence": ev, "record": dict(base, outputName="B", casts=120, totalQuantity=130)}
        self.reject({"source": "reddit:abc123", "result": "rows", "rows": [r1, r2]}, "rows disagree on casts")


class Checkpoints(Repo):
    def submit(self, ans):
        return eb.submit(ans, self.root)

    def test_accepted_answer_writes_a_checkpoint_and_rejected_writes_nothing(self):
        problems, _ = self.submit(self.answer(totalQuantity=131))
        self.assertTrue(problems)
        self.assertFalse(os.path.exists(eb.ckpt_path(self.root, "reddit:abc123")))
        problems, ck = self.submit(self.answer())
        self.assertEqual(problems, [])
        self.assertTrue(os.path.exists(eb.ckpt_path(self.root, "reddit:abc123")))
        self.assertEqual(ck["status"], "rows")
        self.assertEqual(ck["entrySha"], eb.entry_sha(self.entry))

    def test_dry_run_writes_nothing(self):
        eb.submit(self.answer(), self.root, dry_run=True)
        self.assertFalse(os.path.exists(os.path.join(self.root, eb.CKPT_DIR)))

    def test_unknown_source_is_refused(self):
        problems, _ = eb.submit({"source": "reddit:nope"}, self.root)
        self.assertIn("not in the queue", problems[0])

    def test_resume_only_the_missing_sources_are_open(self):
        text2 = "Second source\n" + f"- [B]({OTHER}): 77 casts gave 5 pigment.\n"
        self.write("research/notes/b.md", text2)
        e2 = self.make_entry("reddit:zzz999", [OTHER], "research/notes/b.md", text2, anchors=(2,))
        self.write_queue([self.entry, e2])
        self.submit(self.answer())
        states = {e["source"]: eb.load_checkpoint(self.root, e)[1] for e in eb.load_queue(self.root)}
        self.assertEqual(states, {"reddit:abc123": "current", "reddit:zzz999": "missing"})
        self.submit({"source": "reddit:zzz999", "result": "null", "reasonCode": "qualitative",
                     "reason": "Described in words only in this test note."})
        states = {e["source"]: eb.load_checkpoint(self.root, e)[1] for e in eb.load_queue(self.root)}
        self.assertEqual(set(states.values()), {"current"})
        # submitting the first source again leaves the second checkpoint byte-identical
        p2 = eb.ckpt_path(self.root, "reddit:zzz999")
        before = open(p2, "rb").read()
        self.submit(self.answer())
        self.assertEqual(open(p2, "rb").read(), before)

    def test_checkpoint_goes_stale_when_the_queue_entry_or_the_file_changes(self):
        self.submit(self.answer())
        self.assertEqual(eb.load_checkpoint(self.root, self.entry)[1], "current")
        moved = copy.deepcopy(self.entry)
        moved["files"][0]["anchors"].append({"line": 5, "numbers": [], "text": ""})
        moved["note"] = "other hints"
        self.assertEqual(eb.load_checkpoint(self.root, moved)[1], "current")     # anchors and hints are not inputs
        changed = copy.deepcopy(self.entry)
        changed["files"][0]["sha256"] = "0" * 64
        self.assertEqual(eb.load_checkpoint(self.root, changed)[1], "stale")      # the live entry reads another file
        self.write(NOTE, self.text + "more\n")
        self.assertEqual(eb.load_checkpoint(self.root, self.entry)[1], "invalid")  # the file on disk changed

    def test_checkpoint_names_are_safe_and_distinct(self):
        a = eb.ckpt_name("gdoc:1Kx2qPiGXG")
        b = eb.ckpt_name("gdoc:1kx2qpigxg")
        self.assertNotEqual(a, b)
        self.assertRegex(a, r"^[a-z0-9.\-=@]+\.json$")
        self.assertNotIn("/", eb.ckpt_name("drive.google.com/file/d/abc"))

    def test_checkpoint_file_is_deterministic(self):
        self.submit(self.answer())
        first = open(eb.ckpt_path(self.root, "reddit:abc123"), "rb").read()
        self.submit(self.answer())
        self.assertEqual(open(eb.ckpt_path(self.root, "reddit:abc123"), "rb").read(), first)


class Writer(Repo):
    def submit_ok(self, ans=None):
        problems, _ = eb.submit(ans or self.answer(), self.root)
        self.assertEqual(problems, [])

    def test_rows_carry_provenance_basis_and_pass_the_validator(self):
        self.submit_ok()
        rows, report = eb.run_writer(self.root)
        self.assertEqual(len(rows), 1)
        r = rows[0]
        self.assertEqual(val.check_record(r), [])
        self.assertEqual(r["migratedFrom"]["path"], NOTE)
        self.assertEqual(r["migratedFrom"]["sha256"], sha(self.text))
        self.assertIn("line 4", r["migratedFrom"]["recordRef"])
        self.assertEqual(r["castsBasis"], "reported")
        self.assertEqual(r["agent"], "import")
        self.assertEqual(r["recordedOn"], eb.EXTRACT_DATE)
        self.assertEqual(r["source"]["url"], URL)
        self.assertEqual(eb.normalize_url(r["source"]["url"]), "reddit:abc123")
        self.assertTrue(r["studyKey"].startswith("extract-reddit-abc123-"))
        self.assertEqual(report[0]["written"], 1)

    def test_derivations_are_written(self):
        span = self.add_line("1,000 herbs at 5 herbs per mill gave 40 pigment")
        d = [{"field": "casts", "formula": "inputsProcessed / inputsPerCast", "assumption": "no refunds"}]
        ans = {"source": "reddit:abc123", "result": "rows", "rows": [{
            "path": NOTE, "type": "drop", "evidence": [span],
            "record": {"studyLabel": "b", "method": "Mill", "inputsProcessed": 1000, "inputsPerCast": 5, "casts": 200,
                       "castsBasis": "countedFromInputs", "totalQuantity": 40, "derivations": d}}]}
        self.submit_ok(ans)
        r = eb.run_writer(self.root)[0][0]
        self.assertEqual(r["derivations"], d)
        self.assertEqual(r["castsBasis"], "countedFromInputs")
        self.assertEqual(val.check_record(r), [])

    def test_names_without_ids_go_to_raw_fields_and_the_row_stays_unplaced(self):
        self.submit_ok(self.answer(inputName="Nightshade", outputName="Umbral"))
        r = eb.run_writer(self.root)[0][0]
        self.assertIsNone(r["inputName"])
        self.assertIsNone(r["outputName"])
        self.assertEqual((r["rawInputName"], r["rawOutputName"]), ("Nightshade", "Umbral"))
        self.assertIsNone(r["inputItemID"])
        self.assertIn("unplaced", r["notes"])

    def test_writer_is_deterministic_and_independent_of_submission_order(self):
        text2 = "Second\n" + f"- [B]({OTHER}): 77 casts gave 5 pigment, smallest 1.\n"
        self.write("research/notes/b.md", text2)
        e2 = self.make_entry("reddit:zzz999", [OTHER], "research/notes/b.md", text2, anchors=(2,))
        self.write_queue([self.entry, e2])
        a2 = {"source": "reddit:zzz999", "result": "rows", "rows": [{
            "path": "research/notes/b.md", "type": "drop", "evidence": [{"line": 2, "text": "77 casts gave 5 pigment"}],
            "record": {"studyLabel": "b", "method": "Mill", "casts": 77, "castsBasis": "reported", "totalQuantity": 5}}]}
        self.submit_ok(self.answer())
        self.submit_ok(a2)
        first = eb.render(eb.run_writer(self.root)[0])
        shutil.rmtree(os.path.join(self.root, eb.CKPT_DIR))
        self.submit_ok(a2)
        self.submit_ok(self.answer())
        second = eb.render(eb.run_writer(self.root)[0])
        self.assertEqual(first, second)
        ids = [json.loads(l)["id"] for l in first.splitlines()]
        self.assertEqual(ids, sorted(ids, key=lambda i: ids.index(i)))
        # a source's IDs do not move when another source is added or removed
        only = [r["id"] for r in eb.run_writer(self.root)[0] if "abc123" in r["id"]]
        os.remove(eb.ckpt_path(self.root, "reddit:zzz999"))
        self.assertEqual([r["id"] for r in eb.run_writer(self.root)[0]], only)

    def test_rows_survive_the_source_leaving_the_live_queue(self):
        """link_sources.py drops a source from the queue once its rows make it held; the rows must stay."""
        self.submit_ok()
        before = eb.render(eb.run_writer(self.root)[0])
        self.write_queue([])
        self.assertEqual(eb.render(eb.run_writer(self.root)[0]), before)
        self.assertTrue(before)
        self.assertEqual(eb.cmd_status(self.root), {})

    def test_held_source_writes_nothing_and_is_reported(self):
        self.submit_ok()
        self.holder("https://www.reddit.com/r/woweconomy/comments/abc123/x")
        rows, report = eb.run_writer(self.root)
        self.assertEqual(rows, [])
        self.assertEqual(report[0]["status"], "held")
        self.assertEqual(report[0]["written"], 0)

    def test_own_output_never_counts_as_a_holding(self):
        self.submit_ok()
        rows, _ = eb.run_writer(self.root)
        eb.write_output(rows, self.root)
        again, report = eb.run_writer(self.root)
        self.assertEqual(eb.render(again), eb.render(rows))
        self.assertEqual(report[0]["written"], 1)

    def test_stale_checkpoints_write_nothing(self):
        self.submit_ok()
        self.write(NOTE, self.text + "more\n")
        rows, report = eb.run_writer(self.root)
        self.assertEqual(rows, [])
        self.assertEqual(report[0]["state"], "invalid")

    def test_output_file_is_removed_when_no_rows_remain(self):
        self.submit_ok()
        eb.write_output(eb.run_writer(self.root)[0], self.root)
        path = os.path.join(self.root, eb.OUT_REL)
        self.assertTrue(os.path.exists(path))
        eb.write_output([], self.root)
        self.assertFalse(os.path.exists(path))

    def test_writer_changes_no_other_file(self):
        self.write("research/v3/evidence/legacy/keep.jsonl", '{"id":"k"}\n')
        before = {p: open(os.path.join(self.root, p), "rb").read()
                  for p in ("research/v3/evidence/legacy/keep.jsonl", NOTE, eb.QUEUE)}
        self.submit_ok()
        eb.write_output(eb.run_writer(self.root)[0], self.root)
        for p, data in before.items():
            self.assertEqual(open(os.path.join(self.root, p), "rb").read(), data)


class ExtraFilesAndFallback(Repo):
    """EXTRA_FILES (sibling archive notes the linker never queued) and re-extraction after a source leaves the queue."""

    def setUp(self):
        super().setUp()
        self.note = "research/evidence/observations/sibling.md"
        self.sib = f"# Archive\n- {URL} (2021-05-30): author milled **3000 Nightshade** item `171315` into **781 Umbral `173056`**.\n"
        self.write(self.note, self.sib)
        self._saved = dict(eb.EXTRA_FILES)
        eb.EXTRA_FILES["reddit:abc123"] = [self.note]

    def tearDown(self):
        eb.EXTRA_FILES.clear()
        eb.EXTRA_FILES.update(self._saved)
        super().tearDown()

    def sibling_answer(self):
        span = {"line": 2, "text": "author milled **3000 Nightshade** item `171315` into **781 Umbral `173056`**"}
        link = {"line": 2, "text": "(2021-05-30)"}
        return {"source": "reddit:abc123", "result": "rows", "rows": [{
            "path": self.note, "type": "drop", "evidence": [span, link],
            "record": {"studyLabel": "n", "method": "Mill", "inputItemID": 171315, "inputName": "Nightshade",
                       "outputItemID": 173056, "outputName": "Umbral", "inputsProcessed": 3000, "totalQuantity": 781,
                       "published": "2021-05-30"}}]}

    def test_the_sibling_note_joins_the_entry_with_its_sha(self):
        entry = eb.load_queue(self.root)[0]
        paths = [f["path"] for f in entry["files"]]
        self.assertEqual(paths, [NOTE, self.note])
        self.assertEqual(entry["files"][1]["sha256"], sha(self.sib))
        self.assertEqual(entry["fileCount"], 2)
        self.assertEqual(eb.with_extras(self.root, entry), entry)          # idempotent

    def test_a_row_can_quote_the_sibling_note_and_carries_ids_and_date(self):
        problems, ck = eb.submit(self.sibling_answer(), self.root)
        self.assertEqual(problems, [])
        r = eb.run_writer(self.root)[0][0]
        self.assertEqual((r["inputItemID"], r["inputName"], r["outputItemID"], r["outputName"]), (171315, "Nightshade", 173056, "Umbral"))
        self.assertEqual(r["source"]["published"], "2021-05-30")
        self.assertEqual(r["migratedFrom"]["path"], self.note)
        self.assertEqual(r["migratedFrom"]["sha256"], sha(self.sib))
        self.assertEqual(val.check_record(r), [])

    def test_an_id_that_is_only_in_the_sibling_note_is_refused_without_it(self):
        ans = self.sibling_answer()
        ans["rows"][0]["path"] = NOTE
        ans["rows"][0]["evidence"] = [self.span("Largest stack seen was 2, smallest 1")]
        problems, _ = self.check(ans)
        self.assertTrue(any("not written in the evidence" in p for p in problems), problems)

    def test_resubmitting_works_after_the_source_left_the_live_queue(self):
        self.assertEqual(eb.submit(self.sibling_answer(), self.root)[0], [])
        self.write_queue([])                                                  # link_sources.py dropped it: now held
        self.assertIsNone(next((e for e in eb.load_queue(self.root) if e["source"] == "reddit:abc123"), None))
        self.assertEqual(eb.find_entry(self.root, "reddit:abc123")["source"], "reddit:abc123")
        self.assertEqual(eb.submit(self.sibling_answer(), self.root)[0], [])
        self.assertIn("not in the queue", eb.submit({"source": "reddit:nope"}, self.root)[0][0])


class Numbers(unittest.TestCase):
    def test_number_reading(self):
        n = eb.numbers_of("1,040 ore, 17.9%, .5 each, 11k, two casts, R2, 2021-05-30")
        for want in (1040, 17.9, 0.5, 11000, 2, 2021, 5, 30):
            self.assertTrue(eb.has_number(float(want), n), want)
        self.assertFalse(eb.has_number(1041.0, n))

    def test_formulas_are_arithmetic_only(self):
        env = {"a": 10.0, "b": 4.0}
        self.assertEqual(eb.eval_formula("a / b", env, set())[0], 2.5)
        self.assertEqual(eb.eval_formula("round(100 * a / 3, 1)", env, {3.0})[0], 333.3)
        self.assertIn("not in the evidence", eb.eval_formula("a / 3", env, set())[1])
        self.assertIn("not a supported number", eb.eval_formula("c + 1", env, set())[1])
        self.assertIsNotNone(eb.eval_formula("__import__('os')", env, set())[1])
        self.assertIsNotNone(eb.eval_formula("a ** b", env, set())[1])
        self.assertIsNotNone(eb.eval_formula("a / (b - 4)", env, set())[1])
        self.assertIsNotNone(eb.eval_formula("a +", env, set())[1])

    def test_slug_and_record_id(self):
        e = {"source": "wowhead:spell=190381"}
        self.assertEqual(eb.slug("wowhead:spell=190381"), "wowhead-spell-190381")
        rid = eb.record_id(e, 3)
        self.assertTrue(rid.startswith("import-extract-wowhead-spell-190381-"))
        self.assertTrue(rid.endswith("-03"))


class CommittedFiles(unittest.TestCase):
    """The committed checkpoints and evidence file against the real repository."""

    @classmethod
    def setUpClass(cls):
        cls.queue = eb.load_queue(REPO)
        cls.live = {e["source"]: eb.load_checkpoint(REPO, e) for e in cls.queue}
        cls.cks = eb.all_checkpoints(REPO)
        cls.states = {c["source"]: (c, eb.check_checkpoint(REPO, c)) for c in cls.cks}

    def test_all_55_extraction_sources_have_a_current_checkpoint(self):
        """The queue M04.2 produced had 55 sources; rerunning link_sources.py drops the extracted ones."""
        self.assertEqual(len(self.cks), 55)
        self.assertEqual({s for _, s in self.states.values()}, {"current"})

    def test_every_source_still_in_the_live_queue_has_a_current_checkpoint(self):
        bad = {k: s for k, (_, s) in self.live.items() if s != "current"}
        self.assertEqual(bad, {})
        self.assertLessEqual(set(self.live), set(self.states))

    def test_every_checkpoint_is_rows_or_null_with_a_reason(self):
        for key, (ck, _) in self.states.items():
            ans = ck["answer"]
            self.assertIn(ck["status"], ("rows", "null"), key)
            self.assertTrue(ans.get("reason") and len(ans["reason"]) >= 20, key)
            if ck["status"] == "null":
                self.assertIn(ans["reasonCode"], eb.NULL_CODES, key)

    def test_committed_evidence_file_equals_a_fresh_writer_run(self):
        rows, _ = eb.run_writer(REPO)
        path = os.path.join(REPO, eb.OUT_REL)
        have = open(path, encoding="utf-8").read() if os.path.exists(path) else ""
        self.assertEqual(have, eb.render(rows))

    def test_every_written_row_is_valid_quoted_and_traceable(self):
        rows, _ = eb.run_writer(REPO)
        self.assertTrue(rows)
        for r in rows:
            self.assertEqual(val.check_record(r), [], r["id"])
            self.assertEqual(eb.normalize_url(r["source"]["url"]).split("#")[0], r["migratedFrom"]["recordRef"].split("source ")[1], r["id"])
            if r["quote"]:
                self.assertLess(len(r["quote"].split()), 25)
            mf = r["migratedFrom"]
            with open(os.path.join(REPO, mf["path"]), "rb") as fh:
                self.assertEqual(hashlib.sha256(fh.read()).hexdigest(), mf["sha256"], r["id"])
            if r["type"] == "drop":
                self.assertTrue(r["castsBasis"] is None or r["casts"] is not None)
                self.assertTrue(r["inputName"] is None or r["inputItemID"] is not None, r["id"])
                self.assertTrue(r["outputName"] is None or r["outputItemID"] is not None, r["id"])

    def test_ids_are_unique_and_do_not_collide_with_existing_evidence(self):
        rows, _ = eb.run_writer(REPO)
        ids = [r["id"] for r in rows]
        self.assertEqual(len(ids), len(set(ids)))
        import glob
        for p in glob.glob(os.path.join(REPO, "research", "v3", "evidence", "**", "*.jsonl"), recursive=True):
            if os.path.relpath(p, REPO).replace(os.sep, "/") == eb.OUT_REL:
                continue
            for line in open(p, encoding="utf-8"):
                self.assertNotIn(json.loads(line).get("id"), ids) if line.strip() else None

    def test_no_extracted_source_is_held_by_another_file(self):
        by_key, by_thread, thread = eb.held_keys(REPO)
        for key, (ck, _) in self.states.items():
            if ck["status"] == "rows":
                self.assertNotIn(eb.strip_lang(key), by_key, key)
                self.assertNotIn(thread(key), by_thread, key)


if __name__ == "__main__":
    unittest.main()
