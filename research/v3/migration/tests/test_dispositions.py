#!/usr/bin/env python3
"""M07 (MIG-008) tests for research/v3/migration/tools/dispositions.py.

Unit tests drive `decide()` with small hand-made inputs (one rule at a time). The last class checks the committed manifest files
against a fresh run on the real repository: closed vocabulary, one row per inventory file, no preliminary value left, reasons
present, exception rows carry IDs, every validator error and every link exception is queued, idempotency, byte identity.

Run from the repository root:
  python3 -m unittest discover -s research/v3/migration/tests -v
"""
import collections
import json
import os
import sys
import tempfile
import types
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
sys.path.insert(0, os.path.join(HERE, "..", "tools"))
import dispositions as dp  # noqa: E402
import link_sources as ls  # noqa: E402

MANI = os.path.join(REPO, "research", "v3", "migration", "manifest")


def jl(path):
    with open(path, encoding="utf-8") as f:
        return [json.loads(l) for l in f if l.strip()]


def inv(path, disposition="no-observational-content", category="worker-submission", fmt="md", urls_not_in_v3=()):
    return {"path": path, "disposition": disposition, "category": category, "format": fmt, "sha256": "x",
            "urlsNotInV3": list(urls_not_in_v3)}


def src(path, key, status, reason="r", records=(), lines=(1,), numbers=(100.0,)):
    return {"kind": "source", "path": path, "source": key, "status": status, "reason": reason,
            "records": [{"id": i} for i in records], "recordCount": len(records), "lines": list(lines),
            "claimNumbers": list(numbers), "denominatorMatched": []}


def file_row(path, outcome, counts, reason="why", study_ids=0):
    return {"kind": "file", "path": path, "outcome": outcome, "statusCounts": counts, "reason": reason, "studyIds": study_ids}


def checkpoint(source, status="null", code="qualitative", files=()):
    return ("research/v3/migration/manifest/extraction/" + source.replace(":", "-") + ".json",
            {"source": source, "status": status, "answer": {"reasonCode": code, "reason": "because"},
             "entry": {"files": [{"path": p} for p in files]}})


def inputs(rows=(), file_rows=(), imported=None, checkpoints=None, candidates=(), importer_reason=None):
    by = collections.defaultdict(list)
    for r in rows:
        by[r["path"]].append(r)
    return types.SimpleNamespace(
        src_rows=by, file_rows={r["path"]: r for r in file_rows}, imported=imported or {}, candidates=list(candidates),
        checkpoints=checkpoints or {}, importer_reason=importer_reason or {},
        links=[r for r in rows if r["kind"] == "study"])


class FakeIndex:
    mentions = frozenset()

    def held(self, key):
        return None


def run(row, ins, scans=None, exc=None, index=None):
    return dp.decide(row, ins, scans or {}, exc or {}, index or FakeIndex())


class TestHelpers(unittest.TestCase):
    def test_clean_key_cuts_a_csv_row_from_the_url(self):
        self.assertEqual(dp.clean_key("wow-professions.com/tbc/prospecting,no,12"), "wow-professions.com/tbc/prospecting")
        self.assertEqual(dp.clean_key("reddit:abc123"), "reddit:abc123")

    def test_exception_ids_are_stable_and_distinct(self):
        self.assertEqual(dp.ex_id("LINK", "a", "b"), dp.ex_id("LINK", "a", "b"))
        self.assertNotEqual(dp.ex_id("LINK", "a", "b"), dp.ex_id("LINK", "a", "c"))
        self.assertTrue(dp.ex_id("LINK", "a").startswith("EX-LINK-"))

    def test_vocabulary_is_closed_and_has_no_preliminary_name(self):
        self.assertEqual(len(set(dp.VOCAB)), len(dp.VOCAB))
        for name in dp.FORBIDDEN:
            self.assertNotIn(name, dp.VOCAB)


class TestDecide(unittest.TestCase):
    P = "research/x/note.md"

    def test_exception_beats_everything_and_keeps_the_other_facts(self):
        ins = inputs([src(self.P, "reddit:a", "exception", records=["r1"]), src(self.P, "reddit:b", "residue")],
                     [file_row(self.P, "residue", {"exception": 1, "residue": 1})],
                     imported={self.P: {"old-studies.jsonl": ["i1"]}},
                     checkpoints={"reddit:b": checkpoint("reddit:b", code="qualitative")})
        d, code, text, ptr = run(inv(self.P, "candidate-unmigrated"), ins, exc={self.P: ["EX-LINK-1"]})
        self.assertEqual((d, code), ("exception-queued", "HELD_SOURCE_NUMBERS_DIFFER"))
        self.assertIn("reddit:a", text)
        self.assertIn("reddit:b (qualitative)", text)
        self.assertIn("1 row(s) also written by the importer", text)
        self.assertEqual(ptr["exceptions"], ["EX-LINK-1"])

    def test_imported_rows_make_an_imported_file(self):
        ins = inputs(imported={self.P: {"old-studies.jsonl": ["a", "b"], "gamedata-tokens.jsonl": ["c"]}})
        d, code, text, ptr = run(inv(self.P, "imported", "observation", "jsonl"), ins)
        self.assertEqual((d, code), ("imported", "IMPORTED_ROWS"))
        self.assertEqual(ptr["recordCount"], 3)
        self.assertEqual(ptr["recordIDs"], ["a", "b", "c"])
        self.assertEqual(ptr["evidenceFiles"], {"gamedata-tokens.jsonl": 1, "old-studies.jsonl": 2})

    def test_partial_reference_import_has_its_own_code(self):
        ins = inputs(imported={self.P: {"gamedata-tokens.jsonl": ["a"]}})
        d, code, _, _ = run(inv(self.P, "reference-imported-partial", "addon-data", "lua"), ins)
        self.assertEqual((d, code), ("imported", "IMPORTED_REFERENCE_PARTIAL"))

    def test_extracted_rows_name_their_checkpoint(self):
        ins = inputs([src(self.P, "wowhead:item=1", "linked")], [file_row(self.P, "linked", {"linked": 1})],
                     imported={self.P: {dp.EXTRACTED_FILE: ["e1", "e2"]}},
                     checkpoints={"wowhead:item=1": checkpoint("wowhead:item=1", "rows", None, [self.P])})
        d, code, text, ptr = run(inv(self.P, "candidate-unmigrated"), ins)
        self.assertEqual((d, code), ("extracted", "EXTRACTED_ROWS"))
        self.assertIn("wowhead:item=1", text)
        self.assertTrue(ptr["checkpoints"][0].endswith("wowhead-item=1.json"))

    def test_null_extraction_says_which_source_and_which_code(self):
        ins = inputs([src(self.P, "reddit:r80lkp", "residue"), src(self.P, "reddit:zzz", "residue"), src(self.P, "reddit:r80lkp", "residue")],
                     [file_row(self.P, "residue", {"residue": 3})],
                     checkpoints={"reddit:r80lkp": checkpoint("reddit:r80lkp", code="ambiguous-doubt"),
                                  "reddit:zzz": checkpoint("reddit:zzz", code="reference-table")})
        d, code, text, ptr = run(inv(self.P, "candidate-unmigrated"), ins)
        self.assertEqual((d, code), ("extracted-null", "EXTRACTED_NULL"))
        self.assertIn("reddit:r80lkp (ambiguous-doubt)", text)
        self.assertIn("reddit:zzz (reference-table)", text)
        self.assertEqual(len(ptr["checkpoints"]), 2)

    def test_a_residue_source_without_a_checkpoint_is_an_error_not_a_guess(self):
        ins = inputs([src(self.P, "reddit:nope", "residue")], [file_row(self.P, "residue", {"residue": 1})])
        with self.assertRaises(KeyError):
            run(inv(self.P, "candidate-unmigrated"), ins)

    def test_linked_files(self):
        ins = inputs([src(self.P, "reddit:a", "linked", records=["r1", "r2"])], [file_row(self.P, "linked", {"linked": 1})])
        d, code, _, ptr = run(inv(self.P, "covered-by-url"), ins)
        self.assertEqual((d, code, ptr["recordCount"]), ("linked", "LINKED_NUMBERS_MATCH", 2))
        ins = inputs([src(self.P, "reddit:a", "source-held")], [file_row(self.P, "linked", {"source-held": 1})])
        self.assertEqual(run(inv(self.P, "covered-by-url"), ins)[1], "LINKED_SOURCES_HELD")
        ins = inputs([], [file_row(self.P, "linked", {}, study_ids=2)])
        self.assertEqual(run(inv(self.P, "candidate-no-url"), ins)[1], "LINKED_STUDY_IDS")

    def test_disposed_without_a_citation_is_a_process_artifact(self):
        ins = inputs([], [file_row(self.P, "disposed", {})])
        d, code, text, _ = run(inv(self.P, "candidate-no-url", "ledger", "csv"), ins)
        self.assertEqual((d, code), ("process-artifact", "NO_SOURCE_AUDIT_OR_REPORT"))

    def test_disposed_with_only_reference_citations_is_reference_only(self):
        ins = inputs([src(self.P, "bluetracker.gg/x", "reference", reason="reference host")], [file_row(self.P, "disposed", {"reference": 1})])
        d, code, _, ptr = run(inv(self.P, "candidate-unmigrated"), ins)
        self.assertEqual((d, code), ("reference-only", "ONLY_REFERENCE_OR_DECIDED_SKIPS"))
        self.assertEqual(ptr["sources"], ["bluetracker.gg/x"])

    def test_files_the_linker_never_read(self):
        ins = inputs()
        for disposition, want in (("process-artifact", "process-artifact"), ("derived-model", "derived-model"),
                                  ("mechanics-knowledge", "mechanics-knowledge")):
            self.assertEqual(run(inv(self.P, disposition, "test"), ins)[0], want)
        self.assertEqual(run(inv(self.P, "no-observational-content"), ins)[0], "no-observational-content")

    def test_field_audits_are_process_artifacts_by_name(self):
        ins = inputs()
        p = "research/coordination/submissions/x/2026-10-28-1914-midnight-q21-batch019-35key-fourfield-audit.jsonl"
        d, code, _, _ = run(inv(p, "source-links-only", "worker-submission", "jsonl"), ins, scans={p: []})
        self.assertEqual((d, code), ("process-artifact", "FIELD_AUDIT_BY_NAME"))
        # a source note is not an audit, whatever else it cites
        q = "research/evidence/observations/x-source-only.md"
        self.assertNotEqual(run(inv(q, "source-links-only", "observation"), ins, scans={q: []})[1], "FIELD_AUDIT_BY_NAME")

    def test_importer_reason_makes_a_process_artifact(self):
        ins = inputs(importer_reason={self.P: "process artifact: field audit, validation or confidence chart"})
        d, code, _, ptr = run(inv(self.P, "source-links-only", "worker-submission", "json"), ins)
        self.assertEqual((d, code), ("process-artifact", "PROCESS_ARTIFACT_IMPORTER_REASON"))
        self.assertEqual(ptr["reports"], ["reports/M03b-import.md"])

    def _cites(self, *pairs):
        return {self.P: [{"key": k, "status": s, "reason": "", "where": 1, "big": []} for k, s in pairs]}

    def test_source_notes_by_what_they_cite(self):
        row = inv(self.P, "source-links-only", "source-review", "jsonl")
        d = run(row, inputs(), self._cites(("reddit:a", "source-held"), ("x.org/y", "reference")))
        self.assertEqual((d[0], d[1]), ("held-sources-only", "ALL_CITED_SOURCES_HELD"))
        d = run(row, inputs(), self._cites(("reddit:a", "source-held"), ("reddit:new", "lead-only")))
        self.assertEqual((d[0], d[1]), ("source-links-only", "SOURCE_LINKS_ONLY"))
        self.assertEqual(d[3]["sources"], ["reddit:new"])
        d = run(row, inputs(), self._cites(("x.org/y", "reference"), ("reddit:s", "skipped-decided")))
        self.assertEqual(d[0], "reference-only")
        d = run(row, inputs(), {self.P: []})
        self.assertEqual(d[0], "no-observational-content")

    def test_an_out_of_scope_note_citing_a_null_source_is_extracted_null(self):
        ins = inputs(checkpoints={"reddit:r80lkp": checkpoint("reddit:r80lkp", code="ambiguous-doubt")})
        d, code, text, ptr = run(inv(self.P, "source-links-only", "source-review", "jsonl"), ins,
                                 self._cites(("reddit:r80lkp", "lead-only"), ("reddit:other", "lead-only")))
        self.assertEqual((d, code), ("extracted-null", "EXTRACTED_NULL"))
        self.assertIn("reddit:r80lkp (ambiguous-doubt)", text)
        self.assertIn("1 other lead", text)

    def test_shorthand_keys_from_the_inventory_count_as_citations(self):
        row = inv(self.P, "source-links-only", "source-review", "jsonl", urls_not_in_v3=["reddit:short1"])
        d = run(row, inputs(), {self.P: []})
        self.assertEqual(d[0], "source-links-only")
        self.assertEqual(d[3]["sources"], ["reddit:short1"])

    def test_a_format_the_citation_reader_skips_keeps_the_inventory_name(self):
        d = run(inv("ResearchDB.lua", "source-links-only", "addon-data", "lua"), inputs())
        self.assertEqual((d[0], d[1]), ("source-links-only", "SOURCE_LINKS_ONLY"))

    def test_a_disposition_the_rules_do_not_know_is_an_error(self):
        with self.assertRaises(ValueError):
            run(inv(self.P, "candidate-unmigrated"), inputs())


@unittest.skipUnless(os.path.exists(os.path.join(MANI, "dispositions.jsonl")), "manifest not generated yet")
class TestCommittedManifest(unittest.TestCase):
    """The committed files against a fresh run on the real repository."""

    @classmethod
    def setUpClass(cls):
        import build_estimates as be
        cls.rows = be.load()
        cls.raw = ls.load_raw_agent_rows(REPO)
        cls.dispositions, cls.exceptions, cls.gap, cls.summary = dp.build(REPO, cls.rows, cls.raw)
        cls.inv = jl(os.path.join(MANI, "inventory.jsonl"))
        cls.links = jl(os.path.join(MANI, "links.jsonl"))
        cls.committed = jl(os.path.join(MANI, "dispositions.jsonl"))
        cls.committed_ex = jl(os.path.join(MANI, "exceptions.jsonl"))
        with open(os.path.join(MANI, "validation.json"), encoding="utf-8") as f:
            cls.validation = json.load(f)

    def test_every_inventory_file_has_exactly_one_row(self):
        paths = [r["path"] for r in self.committed]
        self.assertEqual(len(paths), 1244)
        self.assertEqual(len(set(paths)), 1244)
        self.assertEqual(set(paths), {r["path"] for r in self.inv})
        by_inv = {r["path"]: r for r in self.inv}
        for r in self.committed:
            self.assertEqual(r["sha256"], by_inv[r["path"]]["sha256"], r["path"])
            self.assertEqual(r["inventoryDisposition"], by_inv[r["path"]]["disposition"])

    def test_vocabulary_is_closed_and_no_preliminary_value_is_left(self):
        for r in self.committed:
            self.assertIn(r["disposition"], dp.VOCAB, r["path"])
            self.assertNotIn(r["disposition"], dp.FORBIDDEN)
            self.assertNotIn(r["reason"]["code"].lower(), [x.lower() for x in dp.FORBIDDEN])
        with open(os.path.join(MANI, "dispositions.jsonl"), encoding="utf-8") as f:
            text = f.read()
        for word in ('"disposition": "preliminary"', '"disposition": "candidate-', '"disposition": "covered-by-url"'):
            self.assertNotIn(word, text)

    def test_every_row_has_a_machine_readable_reason(self):
        for r in self.committed:
            self.assertRegex(r["reason"]["code"], r"^[A-Z0-9_]+$", r["path"])
            self.assertTrue(r["reason"]["text"].strip(), r["path"])
            self.assertIsInstance(r["pointers"], dict)

    def test_pointers_back_up_the_claim(self):
        for r in self.committed:
            d, p = r["disposition"], r["pointers"]
            if d == "imported":
                self.assertGreater(p["recordCount"], 0, r["path"])
                self.assertTrue(p["recordIDs"])
            if d in ("extracted", "extracted-null"):
                self.assertTrue(p["checkpoints"], r["path"])
                for c in p["checkpoints"]:
                    self.assertTrue(os.path.exists(os.path.join(REPO, c)), c)
            if d == "exception-queued":
                self.assertTrue(p["exceptions"], r["path"])

    def test_null_files_name_their_source_and_code(self):
        nulls = {s: ck for s, (slug, ck) in dp.Inputs(REPO).checkpoints.items() if ck["status"] == "null"}
        self.assertEqual(len(nulls), 46)
        text = {r["path"]: r["reason"]["text"] for r in self.committed}
        for r in self.committed:
            if r["disposition"] == "extracted-null":
                self.assertRegex(r["reason"]["text"], r"\(([a-z-]+)\)")
        # every null source that a historical file cites is named in that file's reason
        for row in self.links:
            if row["kind"] == "source" and row["status"] == "residue":
                code = nulls[row["source"]]["answer"]["reasonCode"]
                self.assertIn(f"{row['source']} ({code})", text[row["path"]], row["path"])

    def test_all_46_null_sources_are_named_with_their_code_somewhere(self):
        nulls = {s: ck for s, (slug, ck) in dp.Inputs(REPO).checkpoints.items() if ck["status"] == "null"}
        reasons = " | ".join(r["reason"]["text"] for r in self.committed)
        # M10: a null source that an agent has since recorded is held, so its files link to the agent's rows and the null
        # code is no longer the reason. Stormvine (item=52984@cata) is the one so far (agent file stormvine-wotlk-milling-cohorts).
        import build_estimates as be
        index = ls.V3Index(be.load())
        held = {s for s in nulls if index.held(s)}
        self.assertEqual(held, {"wowhead:item=52984@cata"})
        for source, ck in nulls.items():
            if source not in held:
                self.assertIn(f"{source} ({ck['answer']['reasonCode']})", reasons, source)

    def test_the_residue_files_are_all_disposed(self):
        residue = {r["path"] for r in self.links if r["kind"] == "file" and r["outcome"] == "residue"}
        self.assertEqual(len(residue), 41)   # 42 until the M10 merge: an agent recorded one source
        by = {r["path"]: r["disposition"] for r in self.committed}
        for p in residue:
            self.assertIn(by[p], ("extracted-null", "exception-queued", "extracted"), p)

    def test_every_linker_exception_file_is_queued(self):
        exc_files = {r["path"] for r in self.links if r["kind"] == "source" and r["status"] == "exception"}
        by = {r["path"]: r["disposition"] for r in self.committed}
        self.assertEqual(len(exc_files), 64)   # 65 until the M10 merge
        for p in exc_files:
            self.assertEqual(by[p], "exception-queued", p)

    def test_exception_rows_carry_ids(self):
        for e in self.committed_ex:
            self.assertTrue(e["recordIDs"] or e["refs"], e["id"])
            for k in ("id", "kind", "subject", "detail", "action"):
                self.assertTrue(e[k], e["id"])
        ids = [e["id"] for e in self.committed_ex]
        self.assertEqual(len(ids), len(set(ids)))
        with_ids = [e for e in self.committed_ex if not e["recordIDs"]]
        self.assertEqual({e["kind"] for e in with_ids}, {"ambiguous-doubt-source"})   # nothing was written for those, by design

    def test_the_known_exception_groups_are_all_queued(self):
        kinds = collections.Counter(e["kind"] for e in self.committed_ex)
        self.assertEqual(kinds["held-source-numbers-differ"], sum(1 for r in self.links if r["kind"] == "source" and r["status"] == "exception"))
        self.assertEqual(kinds["held-source-numbers-differ"], 81)   # 83 until the M10 merge: two wowhead:item=46849 groups went
        self.assertEqual(kinds["imported-vs-agent-totals-differ"], 6)
        self.assertEqual(kinds["unverified-output-count"], 1)
        self.assertEqual(kinds["unplaced-name-only-cohort"], 0)  # all 22 zkay8v rows now have explicit worker matches
        self.assertEqual(kinds["placement-proposal"], 0)  # 1smgllg copies superseded by held worker rows
        self.assertEqual(kinds["total-differs-from-source"], 1)
        self.assertEqual(kinds["ambiguous-doubt-source"], 12)
        by_kind = {e["kind"]: e for e in self.committed_ex}
        zkay = [r for r in self.links if r["kind"] == "candidate"
                and r.get("id") in {f"import-study-{i:05d}" for i in range(691, 713)}]
        self.assertEqual(len(zkay), 22)
        self.assertTrue(all(r["status"] == "linked" and r["agentRecordCount"] > 0 for r in zkay))
        self.assertEqual(by_kind["total-differs-from-source"]["recordIDs"], ["import-study-00967", "import-study-01041"])

    def test_every_validator_error_is_queued_with_a_fix_path(self):
        errors = [f for f in self.validation["findings"] if f["severity"] == "error"]
        queued = {e["recordIDs"][0]: e for e in self.committed_ex if e["kind"] == "validator-error"}
        self.assertEqual(len(errors), len(queued))
        self.assertEqual(len(errors), self.validation["errors"])
        for f in errors:
            e = queued[f["id"]]
            self.assertEqual(e["code"], f["code"])
            self.assertEqual(e["proposedCorrection"]["recordID"], f["id"])
            self.assertIn(e["proposedCorrection"]["field"], ("method", "exclude"))
            self.assertIn("corrections", e["action"] + json.dumps(e["proposedCorrection"]) + "corrections")

    def test_proposed_corrections_are_not_applied(self):
        # M07 proposes; corrections.jsonl is the Master's and the reviewer's. It had 643 lines when M07 ran and has grown (the
        # reviewer added lines), so the test is that no proposed correction has been written there by this migration.
        with open(os.path.join(REPO, "research", "v3", "corrections.jsonl"), encoding="utf-8") as f:
            lines = [json.loads(l) for l in f if l.strip()]
        self.assertGreaterEqual(len(lines), 643)
        for e in self.committed_ex:
            p = e.get("proposedCorrection")
            if p:
                self.assertFalse(any(c.get("recordID") == p["recordID"] and c.get("field") == p["field"] for c in lines), e["id"])

    def test_scope_gap_is_fully_decided(self):
        self.assertEqual(self.summary["scopeGap"]["undecided"], [])
        used = {g["source"] for g in self.gap}
        self.assertEqual(set(dp.SCOPE_GAP_DECISIONS) - used, set(), "a decision no longer used: remove it")
        for g in self.gap:
            self.assertIn(g["decision"], ("queue-source", "held", "reasoned-disposition"))
            self.assertTrue(g["reason"])
            if g["decision"] == "queue-source":
                self.assertTrue(os.path.exists(os.path.join(REPO, g["checkpoint"])))

    def test_summary_counts_add_up(self):
        s = self.summary
        self.assertEqual(sum(s["byDisposition"].values()), 1244)
        self.assertEqual(s["files"], 1244)
        self.assertEqual(s["sha256Mismatches"], [])
        self.assertEqual(s["exceptions"]["total"], len(self.committed_ex))
        for cell in s["byInventoryDisposition"].values():
            self.assertTrue(set(cell) <= set(dp.VOCAB))

    def test_a_fresh_run_is_idempotent(self):
        again = dp.build(REPO, self.rows, self.raw)
        self.assertEqual(json.dumps(again[0], sort_keys=True), json.dumps(self.dispositions, sort_keys=True))
        self.assertEqual(json.dumps(again[1], sort_keys=True), json.dumps(self.exceptions, sort_keys=True))
        self.assertEqual(json.dumps(again[2], sort_keys=True), json.dumps(self.gap, sort_keys=True))

    def test_committed_files_are_byte_identical_to_a_fresh_run(self):
        with tempfile.TemporaryDirectory() as tmp:
            dp.write(tmp, self.dispositions, self.exceptions, self.gap, self.summary)
            for name in ("dispositions.jsonl", "exceptions.jsonl", "scope-gap.jsonl", "dispositions-summary.json"):
                with open(os.path.join(tmp, name), "rb") as a, open(os.path.join(MANI, name), "rb") as b:
                    self.assertEqual(a.read(), b.read(), name)

    def test_the_tool_does_not_write_into_evidence(self):
        before = sorted(os.listdir(os.path.join(REPO, "research", "v3", "evidence", "imported")))
        dp.build(REPO, self.rows, self.raw)
        self.assertEqual(before, sorted(os.listdir(os.path.join(REPO, "research", "v3", "evidence", "imported"))))


if __name__ == "__main__":
    unittest.main()
