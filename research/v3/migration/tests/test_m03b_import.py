#!/usr/bin/env python3
"""M03.2, M03.3, M03.4, M03.6 (MIG-004) tests for the historical-source adapters in
research/v3/tools/import_existing.py: observation .json archives, evidence/v2 reports, leads, worker
submissions, the other-schema JSONL records and the ledger CSVs.

One test per adapter and rule on small synthetic inputs, plus checks on the real repository: every new
source in scope has a decision, every in-scope file is in the report, the new IDs are pinned, and no
reference row reaches study counts. (Rerun byte-identity of every imported file, these included, is
test_m03_import.Committed.test_rerun_byte_identical.)

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
REPO = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
sys.path.insert(0, os.path.join(HERE, "..", "tools"))
import build_estimates as b  # noqa: E402
import import_existing as ie  # noqa: E402
import validate as v  # noqa: E402
from test_build_estimates import Fixture, drop  # noqa: E402

IMPORTED = os.path.join(REPO, "research", "v3", "evidence", "imported")
NEW_FILES = ("historical-archive-cohorts.jsonl", "legacy-milling-cohorts.jsonl", "v2-report-cohorts.jsonl")


class Repo(unittest.TestCase):
    """A temporary repository holding only what the adapters read."""

    def setUp(self):
        self.root = tempfile.mkdtemp()
        self._saved = ie.ROOT
        ie.ROOT = self.root
        ie._SHA.clear()
        os.makedirs(os.path.join(self.root, "research", "v3", "evidence", "agent"))

    def tearDown(self):
        ie.ROOT = self._saved
        ie._SHA.clear()
        shutil.rmtree(self.root)

    def put(self, rel, content):
        path = os.path.join(self.root, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as fh:
            if isinstance(content, str):
                fh.write(content)
            elif rel.endswith(".jsonl"):
                fh.writelines(json.dumps(r) + "\n" for r in content)
            else:
                json.dump(content, fh)

    def agent(self, rows, name="a.jsonl"):
        self.put(f"research/v3/evidence/agent/{name}", rows)


class Rules(Repo):
    """Shared machinery: holdings, claims, decisions."""

    def test_holdings_never_read_importer_output(self):
        self.put("research/v3/evidence/imported/v2-report-cohorts.jsonl", [drop("import-v2report-00001", url="https://reddit.com/r/x/comments/abc")])
        self.agent([drop("ag-1", url="https://reddit.com/r/x/comments/def")])
        h = ie.Holdings([])
        self.assertTrue(h.held("reddit:def"))
        self.assertFalse(h.held("reddit:abc"))   # a rerun must not see its own earlier output

    def test_prior_rows_of_this_run_are_held(self):
        h = ie.Holdings([drop("import-study-00001", url="https://www.wowhead.com/item=1/x")])
        self.assertTrue(h.held("wowhead:item=1"))

    def test_thread_match(self):
        self.agent([drop("ag-1", url="https://us.forums.blizzard.com/en/wow/t/some-title/2276246")])
        self.assertTrue(ie.Holdings([]).held("blizzforum:2276246:16"))   # a post of a held thread is held
        self.assertEqual(ie.thread_of("reddit:abc:def"), "reddit:abc")

    def test_held_claim_is_never_imported(self):
        self.agent([drop("ag-1", url="https://www.reddit.com/r/w/comments/zzyjzu", totalQuantity=24, casts=None)])
        data = {"observations": [{"id": "DF-20230102-SEREVITE-R3-28000-24R3DIAMONDS", "source": "https://www.reddit.com/r/w/comments/zzyjzu",
                                  "reportedR3DiamondUnits": 24, "reportedOreUnitsApprox": 28000}]}
        rows, e = ie.assess_file("f.json", data, ie.Holdings([]), {})
        self.assertEqual(rows, [])
        self.assertEqual(e["outcomes"], {"held: numbers match": 1})
        self.assertEqual(e["held"][0]["matched"], [24.0])

    def test_mapped_source_stops_importing_once_agents_hold_it(self):
        data = {"observations": [{"id": "DF-20230102-SEREVITE-R3-28000-24R3DIAMONDS", "source": "https://www.reddit.com/r/w/comments/zzyjzu",
                                  "reportedR3DiamondUnits": 24, "reportedOreUnitsApprox": 28000}]}
        self.put("v.json", data)
        rows, e = ie.assess_file("v.json", data, ie.Holdings([]), {"reddit:zzyjzu": ie.map_zzyjzu})
        self.assertEqual((len(rows), e["outcomes"]), (1, {"imported": 1}))
        self.agent([drop("ag-1", url="https://www.reddit.com/r/w/comments/zzyjzu/x/", totalQuantity=24)])
        rows, e = ie.assess_file("v.json", data, ie.Holdings([]), {"reddit:zzyjzu": ie.map_zzyjzu})
        self.assertEqual((rows, e["outcomes"]), ([], {"held: numbers match": 1}))   # M10 rerun: no double count

    def test_new_source_without_decision_is_flagged_not_dropped(self):
        rows, e = ie.assess_file("f.json", {"claims": [{"url": "https://www.reddit.com/r/w/comments/neverseen", "total": 5}]},
                                 ie.Holdings([]), {})
        self.assertEqual(e["outcomes"], {"UNDECIDED new source": 1})
        self.assertIn("UNDECIDED", e["skippedNew"][0]["reason"])

    def test_reference_and_skipped_new_sources(self):
        data = {"a": {"url": "https://warcraft.wiki.gg/wiki/Prospect"}, "b": {"url": "https://www.reddit.com/r/w/comments/1fdvkmy"},
                "c": {"sourceURL": "https://www.wowhead.com/spell=1231132/crushing"}}
        _, e = ie.assess_file("f.json", data, ie.Holdings([]), {})
        self.assertEqual(e["outcomes"], {"reference or identity link": 2, "new source skipped": 1})

    def test_file_without_url(self):
        _, e = ie.assess_file("f.json", {"x": 1}, ie.Holdings([]), {})
        self.assertEqual((e["claims"], e["reason"]), (0, "cites no source URL"))


class Archives(Repo):
    """M03.2: observation .json archives."""

    def test_tbc_guide_only_missing_rows_as_reference(self):
        data = {"source": {"url": "https://www.wow-professions.com/tbc/prospecting"}, "notes": "approximate",
                "records": [{"stableKey": "k1", "inputItemID": 2771, "outputItemID": 1529, "outputName": "Jade", "publishedChanceClaim": 0.0333, "sourceClaimID": "a"},
                            {"stableKey": "k2", "inputItemID": 2770, "outputItemID": 774, "outputName": "Malachite", "publishedChanceClaim": 0.5, "sourceClaimID": "b"}]}
        present = lambda inp, out, p, name=None: inp == 2770   # noqa: E731
        self.put("a.json", data)
        (r,) = ie.map_tbc_guide("a.json", data, present)
        self.assertEqual((r["outputItemID"], r["sourceKind"], r["percentShown"], r["casts"]), (1529, "reference", 3.33, None))
        self.assertEqual(r["derivations"][0]["field"], "percentShown")
        self.assertFalse(b.is_study_row(r))

    def test_tbc_presence_rule(self):
        tsm = drop("import-ref-1", sourceKind="tsm-table", url=None, method="Prospect", inputItemID=2772, outputItemID=7909, percentShown=5.0)
        named = drop("legacy-1", url="https://www.wow-professions.com/tbc/prospecting", method="Prospect", inputItemID=23424,
                     outputItemID=None, outputName="Living Ruby")
        self.agent([named])
        guide = {"source": {"url": "https://www.wow-professions.com/tbc/prospecting"}, "notes": None, "records": [
            {"inputItemID": 2772, "outputItemID": 7909, "outputName": "Aquamarine", "publishedChanceClaim": 0.05},   # = TSM: present
            {"inputItemID": 2772, "outputItemID": 1529, "outputName": "Jade", "publishedChanceClaim": 0.35},        # missing
            {"inputItemID": 23424, "outputItemID": 23436, "outputName": "Living Ruby", "publishedChanceClaim": 0.013}]}  # agent by name
        self.put(ie.TBC_GUIDE, guide)
        self.put(ie.INVENTORY, "")
        fams, _ = ie.import_historical([tsm])
        self.assertEqual([r["outputItemID"] for r in fams["historical-archive-cohorts.jsonl"]], [1529])


class V2Reports(Repo):
    """M03.3: evidence/v2 reports."""

    def test_zzyjzu_totals_without_casts(self):
        data = {"observations": [{"id": "DF-20230102-SEREVITE-R3-28000-24R3DIAMONDS", "source": "https://www.reddit.com/r/w/comments/zzyjzu",
                                  "publicationDate": "2023-01-02", "inputFamily": "Serevite Ore", "inputRank": 3, "inputItemID": 190394,
                                  "outputFamily": "Illimited Diamond", "outputRank": 3, "outputItemID": 192871,
                                  "reportedOreUnitsApprox": 28000, "reportedR3DiamondUnits": 24, "nominalInputPerCast": 5,
                                  "nominalCastEquivalentsApprox": 5600, "skillReported": 274, "uncertainty": "APPROXIMATE"}]}
        self.put("v.json", data)
        (r,) = ie.map_zzyjzu("v.json", data)
        self.assertEqual((r["casts"], r["castsBasis"], r["inputsProcessed"], r["totalQuantity"]), (None, None, 28000, 24))
        self.assertEqual((r["inputItemID"], r["outputItemID"], r["outputRank"]), (190394, 192871, 3))
        self.assertIsNone(r["derivations"])         # 5600 is the report's arithmetic, not copied

    def test_luredrop_range(self):
        data = {"source": {"url": "https://www.reddit.com/r/w/comments/1fb0vv5", "publishedDate": "2024-09-07", "verbatimExcerpt": "11-17",
                           "claim": {"minObservedClaim": 11, "maxObservedClaim": 17, "interpretation": "anecdotal"},
                           "context": {"inputName": "Luredrop", "outputName": "Luredrop Pigment"}}}
        self.put("v.json", data)
        (r,) = ie.map_luredrop("v.json", data)
        self.assertEqual((r["minSeen"], r["maxSeen"], r["casts"], r["totalQuantity"]), (11, 17, None, None))

    def test_1smgllg_rates_unplaced_and_batch_numbered(self):
        data = {"sourceLineage": {"canonicalURL": "https://www.reddit.com/r/w/comments/1smgllg", "publicationDate": "2026-04-17"},
                "commentContext": {"totalOreReported": "fewer than 5000"},
                "claimedRates": [{"inputFamily": "Tin", "outputNames": ["Peridot"], "eachGemPerProspectApprox": 0.125, "diamondPerProspectApprox": 0.01},
                                 {"inputFamily": "Silver", "outputNames": None, "eachGemPerProspectApprox": 0.125, "diamondPerProspectApprox": 0.01}]}
        self.put("v.json", data)
        rows = ie.map_1smgllg("v.json", data)
        self.assertEqual([(r["studyKey"], r["rawInputName"], r["rawOutputName"], r["percentShown"]) for r in rows],
                         [("reddit-1smgllg-claim1", "Tin", "Peridot", 12.5), ("reddit-1smgllg-claim1", "Tin", "Diamond", 1.0),
                          ("reddit-1smgllg-claim2", "Silver", "each of 'the others' (gems unnamed)", 12.5),
                          ("reddit-1smgllg-claim2", "Silver", "Diamond", 1.0)])
        self.assertTrue(all(b.key_of(r, {}) is None and r["derivations"] for r in rows))
        # one comment's per-ore claims are a batch family, so equal rounded rates never read as a copy (M05)
        self.assertEqual(b.batch_family(("f", "reddit-1smgllg-claim1")), b.batch_family(("f", "reddit-1smgllg-claim2")))


class OtherSchema(Repo):
    """The 43 other-schema JSONL records M03.1 left: legacy milling, recipe metadata, cohort reconciliation."""

    def mill(self, author, herbs, total, inp=152505, out=153635):
        return {"recordKey": f"k-{author}-{inp}", "inputItemId": inp, "inputName": "Riverbud", "outputItemId": out,
                "outputName": "Ultramarine Pigment", "normalization": {"referenceOperationInputCount": 5},
                "source": {"url": "https://www.wowhead.com/item=153669/viridescent-pigment", "commentAuthor": author,
                           "originalHerbsConsumed": herbs, "reportedOutputTotal": total, "sampleContext": "c",
                           "observedMassMillReagentCount": 20}}

    def test_legacy_milling(self):
        self.agent([drop("ag-1", url="https://www.wowhead.com/item=153669/x", inputItemID=152510, outputItemID=153635, totalQuantity=157),
                    drop("ag-2", url="https://elsewhere.example/y", notes="cohort by KnownAuthor")])
        self.put(ie.LEGACY_MILLING, [self.mill("Baadkitty", 200, 157, inp=152510), self.mill("KnownAuthor", 1000, 700),
                                     self.mill("Kidneph", 1000, 814), self.mill("Melch1337", None, 19.4, inp=168583)])
        rows, log = ie.import_legacy_milling(ie.Holdings([]))
        self.assertEqual([e["outcome"] for e in log], ["skipped", "skipped", "imported", "imported"])
        self.assertIn("copy", log[0]["reason"])
        self.assertIn("already appears", log[1]["reason"])
        k, m = rows
        self.assertEqual((k["casts"], k["castsBasis"], k["inputsProcessed"], k["inputsPerCast"], k["totalQuantity"]),
                         (None, None, 1000, 20, 814))   # herbs, not casts: M06 decides (S16)
        self.assertEqual((m["averageShown"], m["averagePer"], m["inputsPerCast"]), (0.194, "input", None))
        self.assertEqual(m["derivations"][0]["field"], "averageShown")
        self.assertIsNone(b.per_cast_average(m))      # not turned into a per-cast figure before M06

    def test_recipe_metadata_present(self):
        self.agent([{"id": "r-1", "type": "recipe", "recipeSpellID": 2659, "inputItemID": 2840, "inputsPerCast": 1,
                     "outputItemID": 2841, "outputCount": 2}])
        self.put(ie.RECIPE_METADATA, [{"observationID": "o1", "recipe": {"spellID": 2659, "outputItemID": 2841, "outputCount": 2,
                                                                          "exactDirectReagents": [{"itemID": 2840, "quantity": 1}]}},
                                      {"observationID": "o2", "recipe": {"spellID": 9, "outputItemID": 9, "outputCount": 1,
                                                                          "exactDirectReagents": [{"itemID": 8, "quantity": 1}]}}])
        out = ie.assess_recipe_metadata(ie.Holdings([]))
        self.assertEqual([e["outcome"] for e in out], ["skipped", "NOT PRESENT"])

    def test_cohort_reconciliation_copies(self):
        self.agent([drop("ag-1", url="https://www.reddit.com/r/w/comments/zkay8v", casts=1000, totalQuantity=1427)])
        self.put(ie.COHORT_RECONCILIATION, [{"id": "x", "sourceURL": "https://www.reddit.com/r/w/comments/zkay8v",
                                             "sourceStatus": "REUSED_ORIGINAL_NOT_NEW", "actualCompletedOperations": 1000, "outputTotal": 1427}])
        (e,) = ie.assess_cohort_reconciliation(ie.Holdings([]))
        self.assertEqual((e["outcome"], e["matched"]), ("skipped", [1000.0, 1427.0]))


class Ledgers(Repo):
    """M03.6: ledger CSVs with numbers."""

    def test_titanium_rows_checked(self):
        self.agent([drop("ag-1", url="https://www.wowhead.com/wotlk/item=36910/titanium-ore", inputItemID=36910, totalQuantity=250)])
        self.put("research/ledger/titanium-observed-yields.csv",
                 "input_id,output_id,output_name,observed_output_units,source_url\n"
                 "36910,36917,Bloodstone,250,https://www.wowhead.com/wotlk/item=36910/titanium-ore\n"
                 "36910,36917,Bloodstone,53,https://www.wowhead.com/wotlk/item=36910/titanium-ore\n"
                 "36910,36917,Bloodstone,53,https://www.reddit.com/r/w/comments/s6bfrl/\n")
        self.put(ie.INVENTORY, json.dumps({"category": "ledger", "format": "csv", "numericClaimLines": 3,
                                           "path": "research/ledger/titanium-observed-yields.csv", "records": 3}) + "\n")
        (e,) = ie.assess_ledgers(ie.Holdings([]))
        self.assertEqual([c["outcome"][:4] for c in e["rowChecks"]], ["copy", "held", "sour"])
        self.assertEqual(e["outcome"], "skipped")


class EstimatorEffect(Fixture):
    """The new rows reach the estimator only as the rules allow."""

    def test_reference_row_from_guide_stays_out_of_study_counts(self):
        ref = drop("import-archive-00001", sourceKind="reference", percentShown=3.33, percentMeaning="perCast")
        e = self.one([ref, drop("a", casts=100, castsWithDrop=20, totalQuantity=30)])
        self.assertEqual((e["studyCasts"], e["referenceValues"]), (100, 1))

    def test_totals_without_casts_add_no_casts(self):
        e = self.one([drop("a", casts=100, castsWithDrop=20, totalQuantity=30),
                      drop("import-legmill-00001", casts=None, castsBasis=None, inputsProcessed=1000, inputsPerCast=20, totalQuantity=814)])
        self.assertEqual(e["studyCasts"], 100)


class Committed(unittest.TestCase):
    """Checks on the committed importer output and a real run of the adapters."""

    @classmethod
    def setUpClass(cls):
        cls.rows = {n: [json.loads(l) for l in open(os.path.join(IMPORTED, n), encoding="utf-8") if l.strip()] for n in NEW_FILES}
        ie._SHA.clear()
        studies, _, _ = ie.import_studies()
        typeless, _ = ie.import_typeless()
        refs = ie.import_itemdb()
        de, recipes, tokens = ie.import_gamedata()
        gdrefs, _ = ie.import_gamedata_tables()
        cls.prior = studies + typeless + refs + de + recipes + tokens + gdrefs
        cls.fams, cls.report = ie.import_historical(cls.prior)

    def test_new_ids_stable(self):
        with open(os.path.join(HERE, "fixtures", "m03b-ids.jsonl"), encoding="utf-8") as fh:
            pinned = [json.loads(l) for l in fh]
        now = [{"file": n, "id": r["id"], "studyKey": r["studyKey"], "recordRef": r["migratedFrom"]["recordRef"],
                "path": r["migratedFrom"]["path"]} for n in NEW_FILES for r in self.rows[n]]
        self.assertEqual(now, pinned)

    def test_every_new_source_decided_and_every_decision_used(self):
        undecided, cited = [], {"wowhead:spell=190385"}   # the legacy milling URL, decided by author and numbers
        for fam in ("archives", "v2Reports", "leads", "submissions"):
            for e in self.report[fam]:
                undecided += [(e["path"], s["source"]) for s in e["skippedNew"] if s["reason"].startswith("UNDECIDED")]
                with open(os.path.join(REPO, e["path"]), encoding="utf-8") as fh:
                    txt = fh.read()
                data = [json.loads(l) for l in txt.splitlines() if l.strip()] if e["path"].endswith(".jsonl") else json.loads(txt)
                for obj in (data if isinstance(data, list) else [data]):
                    for _, key, _ in ie.claims_in(obj):
                        cited |= {key, ie.thread_of(key)}
        self.assertEqual(undecided, [])
        self.assertEqual(sorted(set(ie.NEW_SOURCES) - cited), [])   # no stale decision

    def test_no_decision_for_a_held_source(self):
        """A held source is classified as held before its decision is read, so a decision for it is dead;
        only row-checked mappers (the TBC table) may be held."""
        hold = ie.Holdings(self.prior)
        self.assertEqual(sorted(k for k in ie.NEW_SOURCES if hold.held(k) and k not in ie.ROW_CHECKED_SOURCES), [])

    def test_every_file_in_scope_reported(self):
        counts = {f: len(self.report[f]) for f in ("archives", "v2Reports", "leads", "submissions")}
        self.assertEqual(counts, {"archives": 11, "v2Reports": 38, "leads": 1, "submissions": 38})
        o = self.report["otherSchema"]
        self.assertEqual((len(o["legacyMilling"]), len(o["recipeMetadata"]), len(o["cohortReconciliation"])), (30, 8, 5))
        self.assertEqual(len(self.report["ledgers"]), 8)
        self.assertFalse([e for e in self.report["ledgers"] if e["reason"].startswith("UNDECIDED")])
        self.assertTrue(all(e["outcome"] == "skipped" for e in o["recipeMetadata"] + o["cohortReconciliation"]))

    def test_run_matches_committed_files(self):
        for n in NEW_FILES:
            self.assertEqual(self.fams[n], self.rows[n], n)
        self.assertEqual((self.fams["leads-cohorts.jsonl"], self.fams["submission-cohorts.jsonl"]), ([], []))

    def test_row_rules(self):
        for n, rows in self.rows.items():
            for r in rows:
                self.assertTrue(r["migratedFrom"]["sha256"], r["id"])
                self.assertNotIn("cohortKey", r)
                if r["casts"] is not None:
                    self.assertIn(r["castsBasis"], v.CASTS_BASES, r["id"])
                if r["sourceKind"] in b.REFERENCE_KINDS:
                    self.assertIsNone(r["casts"], r["id"])
                    self.assertFalse(b.is_study_row(r), r["id"])
                for f in ("dataDate", "observedOn"):
                    self.assertTrue(r[f] is None or v.ISO_DATE.match(r[f]), (r["id"], f))
                fields = {d["field"] for d in r["derivations"] or []}
                if r["percentShown"] is not None:
                    self.assertIn("percentShown", fields, r["id"])   # every one is a 0-1 fraction x 100 in the source
                if n == "legacy-milling-cohorts.jsonl" and r["averageShown"] is not None:
                    self.assertIn("averageShown", fields, r["id"])

    def test_reference_rows_never_reach_study_counts(self):
        refs = [r for rows in self.rows.values() for r in rows if r["sourceKind"] == "reference"]
        self.assertEqual(len(refs), 8)
        rows = b.load()
        groups = {}
        for r in rows:
            if r.get("id") in {x["id"] for x in refs}:
                self.assertFalse(b.is_study_row(r))
                groups[b.key_of(r, b.name_maps(rows))] = True
        self.assertEqual(len(groups), 8)


if __name__ == "__main__":
    unittest.main()
