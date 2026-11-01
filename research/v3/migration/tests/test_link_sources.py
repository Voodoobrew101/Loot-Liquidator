#!/usr/bin/env python3
"""M04.1 / M04.2 (MIG-006) tests for research/v3/migration/tools/link_sources.py.

Synthetic repositories in a temp directory cover URL normalization, number reading, the link / exception /
residue rules, residue grouping, study-ID links, the known name-only candidates, idempotency and read-only
behaviour. The last class checks the committed manifest files against a fresh run on the real repository.

Run from the repository root:
  python3 -m unittest discover -s research/v3/migration/tests -v
"""
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
import link_sources as ls  # noqa: E402

AGENT_FILE = "research/v3/evidence/legacy/a.jsonl"
IMPORT_FILE = "research/v3/evidence/imported/old-studies.jsonl"
POST = "https://www.reddit.com/r/woweconomy/comments/abc123/some_title/"
OTHER = "https://www.reddit.com/r/woweconomy/comments/zzz999/other/"


def read(path):
    with open(path, "rb") as f:
        return f.read()


def drop(rid, url, total=None, casts=None, name="Sun Crystal", study="s1", file=AGENT_FILE, **kw):
    r = {"id": rid, "type": "drop", "studyKey": study, "source": {"url": url}, "originalSource": None,
         "outputName": name, "outputItemID": kw.pop("outputItemID", None), "totalQuantity": total, "casts": casts,
         "inputItemID": kw.pop("inputItemID", 36910), "_file": file}
    r.update(kw)
    return r


class Repo(unittest.TestCase):
    """A temporary repository: files, an inventory and effective rows."""

    def setUp(self):
        self.root = tempfile.mkdtemp()
        self.out = os.path.join(self.root, "out")
        self.inventory = []

    def tearDown(self):
        shutil.rmtree(self.root, ignore_errors=True)

    def add(self, rel, text, disposition="candidate-unmigrated", category="review"):
        path = os.path.join(self.root, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        data = text.encode("utf-8")
        with open(path, "wb") as fh:
            fh.write(data)
        self.inventory.append({"path": rel, "category": category, "format": rel.rsplit(".", 1)[-1],
                               "disposition": disposition, "sha256": hashlib.sha256(data).hexdigest()})

    def run_links(self, rows, out=None, raw_rows=None):
        links, queue, summary = ls.run(self.root, rows, out or self.out, inventory=self.inventory, raw_rows=raw_rows)
        return links, queue, summary

    @staticmethod
    def sources(links, path=None):
        return [e for e in links if e["kind"] == "source" and (path is None or e["path"] == path)]

    @staticmethod
    def file_entry(links, path):
        return next(e for e in links if e["kind"] == "file" and e["path"] == path)


class Urls(unittest.TestCase):
    def test_variants_collapse_to_one_key(self):
        cites = ls.text_citations(
            "see https://old.reddit.com/r/woweconomy/comments/abc123/x/ and https://www.reddit.com/r/woweconomy/comments/abc123.\n", "md")
        self.assertEqual([c["key"] for c in cites], ["reddit:abc123"])

    def test_wowhead_slug_and_comment_anchor(self):
        a = ls.text_citations("https://www.wowhead.com/item=52987/twilight-jasmine 1,000 casts", "md")[0]["key"]
        b = ls.text_citations("https://www.wowhead.com/item=52987/twilight-jasmine#comments:id=5 1,000 casts", "md")[0]["key"]
        self.assertEqual(a, "wowhead:item=52987")
        self.assertEqual(b, "wowhead:item=52987#c5")

    def test_forum_thread_and_trailing_punctuation(self):
        keys = [c["key"] for c in ls.text_citations(
            "(https://us.forums.blizzard.com/en/wow/t/prospecting-needs-buff/2280780/12). And https://warcraft.wiki.gg/wiki/Prospect.", "md")]
        self.assertEqual(keys, ["blizzforum:2280780:12", "warcraft.wiki.gg/wiki/prospect"])

    def test_one_citation_per_line_and_key(self):
        cites = ls.text_citations(f"{POST} and again {POST}\n", "md")
        self.assertEqual(len(cites), 1)

    def test_own_repository_links_are_ignored(self):
        self.assertEqual(ls.text_citations("https://github.com/Voodoobrew101/Loot-Liquidator/blob/x", "md"), [])


class Numbers(unittest.TestCase):
    def test_text_numbers(self):
        got = ls.text_numbers("1,040 casts gave 12.5% and 2k ore on 2026-10-28 (2022) at https://x.com/a/9999 batch 25")
        self.assertEqual(got, {1040.0, 12.5, 2000.0, 25.0})
        self.assertNotIn(9999.0, got)
        self.assertNotIn(2022.0, got)

    def test_year_kept_when_it_is_a_count(self):
        self.assertIn(2022.0, ls.text_numbers("2022 casts"))

    def test_hyphenated_token_numbers_skipped(self):
        self.assertEqual(ls.text_numbers("batch-024 and q-23"), set())

    def test_telling_filter(self):
        self.assertEqual(ls.telling_set({0.0, 1.0, 5.0, 6.0, 0.25}), {6.0, 0.25})

    def test_fraction_also_read_as_percent(self):
        self.assertEqual(ls.with_fractions({0.125, 30.0}), {0.125, 12.5, 30.0})

    def test_result_numbers_only(self):
        res, den = ls.record_numbers({"totalQuantity": 53, "casts": 200, "inputsProcessed": 1000, "percentShown": 12.5,
                                      "castsWithDrop": 3})
        self.assertEqual(res, {53.0, 12.5})
        self.assertEqual(den, {200.0, 1000.0})


class Rules(Repo):
    def test_same_source_matching_result_is_linked(self):
        self.add("research/a.md", f"Study of 1,000 ore: 53 Sun Crystal ({POST})\n")
        links, queue, _ = self.run_links([drop("r1", POST, total=53, casts=200)])
        s = self.sources(links)[0]
        self.assertEqual((s["status"], s["matched"]), ("linked", [53.0]))
        self.assertEqual(s["records"][0]["id"], "r1")
        self.assertEqual(self.file_entry(links, "research/a.md")["outcome"], "linked")
        self.assertEqual(queue, [])

    def test_batch_size_alone_is_not_a_link(self):
        self.add("research/a.md", f"Study of 1,000 ore: 53 Sun Crystal ({POST})\n")
        links, _, _ = self.run_links([drop("r1", POST, total=44, casts=1000)])
        s = self.sources(links)[0]
        self.assertEqual(s["status"], "exception")
        self.assertEqual(s["denominatorMatched"], [1000.0])
        self.assertEqual(self.file_entry(links, "research/a.md")["outcome"], "exception")

    def test_exception_on_differing_numbers(self):
        self.add("research/a.md", f"Study of 1,000 ore: 53 Sun Crystal ({POST})\n")
        links, queue, _ = self.run_links([drop("r1", POST, total=44, casts=200)])
        s = self.sources(links)[0]
        self.assertEqual(s["status"], "exception")
        self.assertEqual(s["matched"], [])
        self.assertEqual(queue, [])

    def test_source_held_only_as_a_recipe_fact_is_not_an_exception(self):
        """M04.3: a recipe row (20 herbs per mill) holds a Wowhead spell page; other sources' counts on the same
        line have no cohort to be compared with, so they are not an exception."""
        self.add("research/a.md", f"Study of 1,000 ore: 53 Sun Crystal ({POST})\n")
        recipe = {"id": "r1", "type": "recipe", "source": {"url": POST}, "originalSource": None,
                  "recipeSpellID": 9999, "inputsPerCast": 20, "_file": IMPORT_FILE}
        links, queue, _ = self.run_links([recipe])
        s = self.sources(links)[0]
        self.assertEqual(s["status"], "source-held")
        self.assertIn("recipe fact", s["reason"])
        self.assertEqual(queue, [])

    def test_only_batch_sizes_is_source_held_not_exception(self):
        self.add("research/a.md", f"The 1,000 ore post ({POST})\n")
        links, _, _ = self.run_links([drop("r1", POST, total=44, casts=1000)])
        self.assertEqual(self.sources(links)[0]["status"], "source-held")

    def test_fraction_matches_percent(self):
        self.add("research/a.md", f"1,000 ore, rate 0.125 per cast ({POST})\n")
        links, _, _ = self.run_links([drop("r1", POST, percentShown=12.5)])
        self.assertEqual(self.sources(links)[0]["status"], "linked")

    def test_thread_level_match(self):
        self.add("research/a.md", f"1,000 ore: 53 ({POST}def456/)\n")
        links, _, _ = self.run_links([drop("r1", POST, total=53)])
        s = self.sources(links)[0]
        self.assertEqual((s["status"], s["matchLevel"]), ("linked", "thread"))

    def test_source_not_in_v3_is_residue(self):
        self.add("research/a.md", f"Study of 1,000 ore: 53 Sun Crystal ({OTHER})\n")
        links, queue, _ = self.run_links([drop("r1", POST, total=53)])
        self.assertEqual(self.sources(links)[0]["status"], "residue")
        self.assertEqual(self.file_entry(links, "research/a.md")["outcome"], "residue")
        self.assertEqual([q["source"] for q in queue], ["reddit:zzz999"])
        self.assertEqual(queue[0]["files"][0]["anchors"][0]["line"], 1)
        self.assertEqual(queue[0]["files"][0]["proximity"], "citation")

    def test_mention_in_notes_is_not_holding(self):
        self.add("research/a.md", f"Study of 1,000 ore: 53 ({OTHER})\n")
        row = drop("r1", POST, total=53, notes=f"copied from {OTHER}")
        links, queue, _ = self.run_links([row])
        s = self.sources(links)[0]
        self.assertEqual(s["status"], "residue")
        self.assertTrue(s["v3Mentions"])
        self.assertTrue(queue[0]["v3Mentions"])

    def test_reference_host_and_identity_link_are_not_residue(self):
        self.add("research/a.md", "1,000 ore at https://warcraft.wiki.gg/wiki/Prospect\n"
                                  "See https://www.wowhead.com/item=36910/titanium-ore for the item\n"
                                  "Schema https://json-schema.org/draft/2020-12/schema 1,000 ore\n")
        links, queue, _ = self.run_links([])
        self.assertEqual({e["status"] for e in self.sources(links)}, {"reference"})
        self.assertEqual(queue, [])
        self.assertEqual(self.file_entry(links, "research/a.md")["outcome"], "disposed")

    def test_wowhead_comment_with_counts_is_residue(self):
        self.add("research/a.md", "2,000 ore gave 3 diamonds https://www.wowhead.com/item=192999#comments:id=77\n")
        links, _, _ = self.run_links([])
        self.assertEqual(self.sources(links)[0]["status"], "residue")

    def test_decided_skip_keeps_its_reason(self):
        self.add("research/a.md", "1,000 casts gave nothing https://www.reddit.com/r/woweconomy/comments/1fdvkmy/x/\n")
        links, _, _ = self.run_links([])
        s = self.sources(links)[0]
        self.assertEqual(s["status"], "skipped-decided")
        self.assertIn("30% Resourcefulness", s["reason"])

    def test_numbers_elsewhere_make_file_level_residue(self):
        self.add("research/a.md", f"Source: {OTHER}\n\nThe cohort was 2,000 casts with 14 hits.\n")
        links, queue, _ = self.run_links([])
        s = self.sources(links)[0]
        self.assertEqual((s["status"], s["proximity"]), ("residue", "file"))
        self.assertEqual(queue[0]["files"][0]["anchors"][0]["line"], 3)

    def test_source_list_with_many_sources_stays_a_lead(self):
        urls = "\n".join(f"- https://example.org/page{i}" for i in range(5))
        self.add("research/a.md", f"{urls}\n\nThe cohort was 2,000 casts.\n")
        links, queue, _ = self.run_links([])
        self.assertEqual({e["status"] for e in self.sources(links)}, {"lead-only"})
        self.assertEqual(queue, [])
        self.assertEqual(self.file_entry(links, "research/a.md")["outcome"], "disposed")

    def test_window_stops_at_other_sources_and_table_rows_stand_alone(self):
        text = (f"- {POST}\n  - 53 Sun Crystal from 1,000 ore\n- {OTHER}\n  - 44 Dark Jade from 1,000 ore\n"
                f"| a | {POST} | 12 |\n| b | {OTHER} | 99 |\n")
        cites = ls.text_citations(text, "md")
        by = {(c["key"], c["where"]): c["numbers"] for c in cites}
        self.assertEqual(by[("reddit:abc123", 1)], {53.0, 1000.0})
        self.assertEqual(by[("reddit:zzz999", 3)], {44.0, 1000.0})
        self.assertEqual(by[("reddit:abc123", 5)], {12.0})
        self.assertEqual(by[("reddit:zzz999", 6)], {99.0})

    def test_csv_row_is_its_own_window(self):
        csv_text = f"name,count,url\nA,53,{POST}\nB,99,{OTHER}\n"
        cites = ls.text_citations(csv_text, "csv")
        self.assertEqual([c["numbers"] for c in cites], [{53.0}, {99.0}])

    def test_json_claim_object_is_the_window(self):
        doc = {"studies": [{"source": {"url": POST}, "outputs": [{"totalUnits": 53}], "completedOperations": 200},
                           {"source": {"url": OTHER}, "outputs": [{"totalUnits": 77}], "completedOperations": 100}]}
        self.add("research/a.json", json.dumps(doc), category="observation")
        links, queue, _ = self.run_links([drop("r1", POST, total=53, casts=200)])
        status = {e["source"]: e["status"] for e in self.sources(links)}
        self.assertEqual(status, {"reddit:abc123": "linked", "reddit:zzz999": "residue"})
        self.assertEqual(queue[0]["files"][0]["anchors"][0]["path"].startswith("$.studies[1]"), True)

    def test_jsonl_lines_are_separate_claims(self):
        lines = [json.dumps({"source": {"url": POST}, "outputs": [{"totalUnits": 53}]}),
                 json.dumps({"source": {"url": OTHER}, "outputs": [{"totalUnits": 77}]})]
        self.add("research/a.jsonl", "\n".join(lines) + "\n", category="observation")
        links, _, _ = self.run_links([drop("r1", POST, total=53)])
        self.assertEqual({e["source"]: e["status"] for e in self.sources(links)},
                         {"reddit:abc123": "linked", "reddit:zzz999": "residue"})

    def test_study_id_link_without_url(self):
        self.add("research/a.md", "Audit of `legacy-b006-2022-titanium-1000ore` and nothing else, 40 casts.\n",
                 disposition="candidate-no-url")
        links, _, _ = self.run_links([drop("r1", POST, total=53, study="legacy-b006-2022-titanium-1000ore")])
        st = [e for e in links if e["kind"] == "study"]
        self.assertEqual([e["studyId"] for e in st], ["legacy-b006-2022-titanium-1000ore"])
        self.assertEqual(self.file_entry(links, "research/a.md")["outcome"], "linked")

    def test_no_url_no_id_is_disposed_with_reason(self):
        self.add("research/a.csv", "key,score\nx,40\n", disposition="candidate-no-url", category="ledger")
        links, queue, _ = self.run_links([])
        f = self.file_entry(links, "research/a.csv")
        self.assertEqual(f["outcome"], "disposed")
        self.assertIn("no source URL", f["reason"])
        self.assertEqual(queue, [])


class Queue(Repo):
    def test_residue_grouped_by_source_url(self):
        self.add("research/b.md", f"Run of 500 casts gave 12 hits ({OTHER})\n")
        self.add("research/a.md", f"Another 2,000 ore run: 31 hits see {OTHER}.\n")
        self.add("research/c.md", "Prospecting 1,000 ore: 9 https://www.reddit.com/r/woweconomy/comments/qqq111/x/\n")
        _, queue, summary = self.run_links([])
        self.assertEqual([q["source"] for q in queue], ["reddit:qqq111", "reddit:zzz999"])
        zzz = queue[1]
        self.assertEqual(zzz["fileCount"], 2)
        self.assertEqual([f["path"] for f in zzz["files"]], ["research/a.md", "research/b.md"])
        self.assertEqual(zzz["expectedTypes"], ["drop"])
        self.assertEqual(zzz["methodHints"], ["Prospect"])
        self.assertEqual(zzz["rawUrls"], sorted(zzz["rawUrls"]))
        self.assertEqual(summary["distinctResidueSources"], 2)

    def test_type_hints_from_text(self):
        self.add("research/a.md", f"Hotfix changed the milling rate from 2 to 3 per 5 herbs, 1,000 herbs tested ({OTHER})\n")
        _, queue, _ = self.run_links([])
        self.assertIn("rateChange", queue[0]["expectedTypes"])
        self.assertIn("Mill", queue[0]["methodHints"])


class NameOnly(Repo):
    def imported(self, rid, name, total, casts, url=POST):
        return drop(rid, url, total=total, casts=casts, name=None, file=IMPORT_FILE, rawOutputName=name,
                    notes="not placed ... " + ls.INDEX_MARKER)

    def candidates(self, rows, raw=None):
        return [e for e in ls.name_only_candidates(ls.V3Index(rows, raw)) if e["group"] == "nameOnlyRow"]

    def test_same_output_and_total_links(self):
        rows = [self.imported("i1", "Sun Crystal", 53, 200), drop("a1", POST, total=53, casts=200)]
        (e,) = self.candidates(rows)
        self.assertEqual((e["status"], [r["id"] for r in e["agentRecords"]]), ("linked", ["a1"]))

    def test_total_equal_to_sum_of_agent_rows_links(self):
        rows = [self.imported("i1", "Sun Crystal", 53, 200), drop("a1", POST, total=40, casts=200, outputRank=2),
                drop("a2", POST, total=13, casts=200, outputRank=3)]
        (e,) = self.candidates(rows)
        self.assertEqual(e["status"], "linked")
        self.assertIn("sum", e["reason"])

    def test_same_cast_count_other_total_is_exception(self):
        rows = [self.imported("i1", "Sun Crystal", 53, 200), drop("a1", POST, total=44, casts=200)]
        (e,) = self.candidates(rows)
        self.assertEqual(e["status"], "exception")

    def test_other_cohort_size_is_unlinked_not_exception(self):
        rows = [self.imported("i1", "Sun Crystal", 530, 2000), drop("a1", POST, total=44, casts=200)]
        (e,) = self.candidates(rows)
        self.assertEqual(e["status"], "unlinked")
        self.assertIn("other cohort sizes", e["reason"])

    def test_excluded_agent_row_still_links_and_says_so(self):
        agent = drop("a1", POST, total=53, casts=200)
        rows = [self.imported("i1", "Sun Crystal", 53, 200)]          # the agent row is not effective
        (e,) = self.candidates(rows, raw=[agent])
        self.assertEqual(e["status"], "linked")
        self.assertFalse(e["agentRecords"][0]["effective"])
        self.assertIn("excluded by corrections", e["reason"])

    def test_numbers_copy_under_another_url(self):
        rows = [self.imported("i1", "Sun Crystal", 53, 200, url="https://www.wowhead.com/mop-classic/item=72093/x"),
                drop("a1", "https://www.wowhead.com/item=72093", total=53, casts=200)]
        (e,) = self.candidates(rows)
        self.assertEqual((e["status"], e["heldBy"]), ("linked", "numbers"))

    def test_label_resolution(self):
        rows = [drop("a1", POST, outputName="Amani Lapis", outputItemID=242554, file="research/v3/evidence/midnight/x.jsonl"),
                drop("a2", POST, outputName="Flawless Amani Lapis", outputItemID=242612, file="research/v3/evidence/midnight/x.jsonl"),
                drop("a3", POST, outputName="Blood Garnet", outputItemID=23077, file="research/v3/evidence/legacy/x.jsonl"),
                drop("a4", POST, outputName="Sanguine Garnet", outputItemID=242553, file="research/v3/evidence/midnight/x.jsonl")]
        idx = ls.V3Index(rows)
        self.assertEqual(ls.resolve_label("Lapis", idx, "midnight"), [(242554, "Amani Lapis")])
        self.assertEqual(ls.resolve_label("Flawless Lapis", idx, "midnight"), [(242612, "Flawless Amani Lapis")])
        self.assertEqual(ls.resolve_label("Garnet", idx, "midnight"), [(242553, "Sanguine Garnet")])
        self.assertEqual(len(ls.resolve_label("Garnet", idx, "")), 2)
        self.assertEqual(ls.resolve_label("Nothing", idx, "midnight"), [])


class NamePool(Repo):
    def test_label_resolution_ignores_raw_rows_that_corrections_fix(self):
        good = drop("a1", POST, outputName="Tenebrous Amethyst", outputItemID=242606, file="research/v3/evidence/midnight/x.jsonl")
        bad = drop("a2", POST, outputName="Tenebrous Amethyst", outputItemID=242721, file="research/v3/evidence/midnight/y.jsonl")
        idx = ls.V3Index([good], raw_rows=[good, bad])      # `bad` is not effective: corrections.jsonl fixed its ID
        self.assertEqual(ls.resolve_label("Amethyst", idx, "midnight"), [(242606, "Tenebrous Amethyst")])
        self.assertEqual(idx.raw_agent("reddit:abc123")[1]["effective"], False)


class Behaviour(Repo):
    def test_rerun_is_byte_identical(self):
        self.add("research/b.md", f"Run of 500 casts gave 12 hits ({OTHER})\n")
        self.add("research/a.md", f"Study of 1,000 ore: 53 ({POST})\n")
        self.add("research/c.json", json.dumps({"source": {"url": POST}, "outputs": [{"totalUnits": 53}]}), category="observation")
        rows = [drop("r1", POST, total=53, casts=200)]
        out2 = os.path.join(self.root, "out2")
        self.run_links(rows)
        self.run_links(list(reversed(rows)), out=out2)
        for name in ("links.jsonl", "extraction-queue.jsonl", "links-summary.json"):
            self.assertEqual(read(os.path.join(self.out, name)), read(os.path.join(out2, name)), name)

    def test_read_only_on_the_inputs(self):
        self.add("research/a.md", f"Study of 1,000 ore: 53 ({POST})\n")
        evidence = os.path.join(self.root, AGENT_FILE)
        os.makedirs(os.path.dirname(evidence), exist_ok=True)
        with open(evidence, "w") as f:
            f.write(json.dumps(drop("r1", POST, total=53)) + "\n")
        before = self.tree()
        self.run_links([drop("r1", POST, total=53)])
        self.assertEqual(before, self.tree())

    def tree(self):
        out = {}
        for base, _, files in os.walk(self.root):
            if os.path.abspath(base).startswith(os.path.abspath(self.out)):
                continue
            for f in files:
                p = os.path.join(base, f)
                out[os.path.relpath(p, self.root)] = hashlib.sha256(read(p)).hexdigest()
        return out

    def test_only_scoped_dispositions_are_read(self):
        self.add("research/a.md", f"1,000 ore: 53 ({OTHER})\n", disposition="process-artifact")
        links, queue, summary = self.run_links([])
        self.assertEqual((links, queue, summary["inScopeFiles"]), ([], [], 0))

    def test_every_scoped_file_has_one_outcome_and_a_reason(self):
        self.add("research/a.md", f"1,000 ore: 53 ({POST})\n")
        self.add("research/b.md", "nothing here\n", disposition="candidate-no-url")
        self.add("research/c.md", f"1,000 ore: 53 ({OTHER})\n", disposition="covered-by-url")
        links, _, _ = self.run_links([drop("r1", POST, total=53)])
        files = [e for e in links if e["kind"] == "file"]
        self.assertEqual(len(files), 3)
        for f in files:
            self.assertIn(f["outcome"], ("linked", "exception", "residue", "disposed"))
            self.assertTrue(f["reason"])
            self.assertTrue(f["sha256InInventory"])


class Committed(unittest.TestCase):
    """The committed manifest files against a fresh run on the real repository."""

    @classmethod
    def setUpClass(cls):
        import build_estimates as be
        cls.tmp = tempfile.mkdtemp()
        cls.rows = be.load()
        cls.links, cls.queue, cls.summary = ls.run(REPO, cls.rows, cls.tmp, raw_rows=ls.load_raw_agent_rows(REPO))

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def test_committed_files_are_byte_identical_to_a_fresh_run(self):
        manifest = os.path.join(REPO, "research", "v3", "migration", "manifest")
        for name in ("links.jsonl", "extraction-queue.jsonl", "links-summary.json"):
            self.assertEqual(read(os.path.join(manifest, name)), read(os.path.join(self.tmp, name)),
                             name + " is stale: rerun link_sources.py")

    def test_every_in_scope_file_has_an_outcome_and_a_reason(self):
        inv_rows = [json.loads(l) for l in read(os.path.join(REPO, "research", "v3", "migration", "manifest", "inventory.jsonl")).decode().splitlines()]
        scope = {r["path"] for r in inv_rows if r["disposition"] in ls.SCOPE}
        files = {e["path"]: e for e in self.links if e["kind"] == "file"}
        self.assertEqual(set(files), scope)
        self.assertEqual(len(scope), 259)   # 265 until the M10 merge: agents recorded sources, so files left the candidate classes
        for e in files.values():
            self.assertIn(e["outcome"], ("linked", "exception", "residue", "disposed"))
            self.assertTrue(e["reason"], e["path"])
            self.assertTrue(e["sha256InInventory"], e["path"])

    def test_residue_files_are_all_in_the_queue_and_back(self):
        residue = {e["path"] for e in self.links if e["kind"] == "file" and e["outcome"] == "residue"}
        queued = {f["path"] for q in self.queue for f in q["files"]}
        self.assertEqual(residue, queued)
        self.assertEqual([q["source"] for q in self.queue], sorted(q["source"] for q in self.queue))

    def test_queue_sources_are_not_held_by_v3(self):
        index = ls.V3Index(self.rows)
        for q in self.queue:
            self.assertIsNone(index.held(q["source"]), q["source"])

    def test_known_candidate_groups_are_all_resolved_or_listed(self):
        groups = {}
        for e in self.links:
            if e["kind"] == "candidate":
                groups.setdefault(e["group"], []).append(e)
        self.assertEqual(sorted(groups), ["1smgllg", "nameOnlyRow", "s6bfrl-uncommon-gems"])
        self.assertEqual(len(groups["1smgllg"]), 14)
        self.assertEqual(len(groups["s6bfrl-uncommon-gems"]), 6)
        self.assertEqual(len(groups["nameOnlyRow"]), 88)   # 86 until the M10 merge: agents now hold two cohorts the importer had placed by name
        for g in groups.values():
            for e in g:
                self.assertTrue(e["reason"])
                self.assertIn(e["status"], ("linked", "exception", "unlinked", "listed"))
        self.assertEqual({e["status"] for e in groups["s6bfrl-uncommon-gems"]}, {"exception"})


if __name__ == "__main__":
    unittest.main()
