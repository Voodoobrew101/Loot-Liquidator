#!/usr/bin/env python3
"""M03.0 / M03.1 / M03.5 tests for research/v3/tools/import_existing.py and the fields it adds.

One test per adapter and per rule on small synthetic inputs, plus checks on the real repository:
IDs import-study-00001..00652 unchanged, a rerun is byte-identical to the committed files, the ten
typeless agent records map to the agent's own numbers, and no reference row reaches study counts.

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
import build_estimates as b  # noqa: E402
import import_existing as ie  # noqa: E402
import validate as v  # noqa: E402
from test_build_estimates import Fixture, drop  # noqa: E402

IMPORTED = os.path.join(REPO, "research", "v3", "evidence", "imported")


def old_record(**kw):
    """A record in the old research/evidence/observations schema."""
    d = {"observationID": kw.pop("observationID", "obs-1"), "evidenceStatus": kw.pop("evidenceStatus", "RAW_PUBLISHED"),
         "source": {"url": kw.pop("url", "https://example.org/study"), "sourceType": kw.pop("sourceType", "PLAYER_STUDY"),
                    "reportedObservationDate": kw.pop("observed", None), "publishedDate": kw.pop("publishedDate", None),
                    "originalDocumentRef": "doc", "sampleClaim": None},
         "game": {"hotfixWindow": kw.pop("hotfixWindow", None), "clientBuild": None},
         "processing": dict({"method": "Prospect", "inputItemID": 1001, "inputQualityRank": None,
                             "batchInputsPerOperation": 5, "completedOperations": None}, **kw.pop("processing", {})),
         "characterContext": {},
         "outputs": kw.pop("outputs", [{"outputItemID": 2001, "totalUnits": 30, "hitOperations": 20}])}
    d.update(kw)
    return d


class ImporterFixture(unittest.TestCase):
    """A temporary repository holding only what the importer reads."""

    def setUp(self):
        self.root = tempfile.mkdtemp()
        self._saved = ie.ROOT
        ie.ROOT = self.root
        ie._SHA.clear()
        os.makedirs(os.path.join(self.root, ie.OBS_DIR))
        os.makedirs(os.path.join(self.root, "research", "v3", "evidence", "agent"))

    def tearDown(self):
        ie.ROOT = self._saved
        ie._SHA.clear()
        shutil.rmtree(self.root)

    def obs(self, name, records):
        with open(os.path.join(self.root, ie.OBS_DIR, name), "w", encoding="utf-8") as fh:
            for r in records:
                fh.write(json.dumps(r) + "\n")

    def agent(self, rows):
        with open(os.path.join(self.root, "research", "v3", "evidence", "agent", "a.jsonl"), "w", encoding="utf-8") as fh:
            for r in rows:
                fh.write(json.dumps(r) + "\n")

    def studies(self):
        rows, skipped, log = ie.import_studies()
        return rows, skipped, log


class CastBasis(unittest.TestCase):
    """M03.1 a: every casts value carries its basis; computed ones carry a derivation."""

    def test_reported(self):
        casts, _, basis, der = ie.cast_count({"completedOperations": 200, "batchInputsPerOperation": 5})
        self.assertEqual((casts, basis, der), (200, "reported", []))

    def test_nominal_equivalent(self):
        casts, _, basis, der = ie.cast_count({"fiveOreEquivalentOperations": 2000, "batchInputsPerOperation": 5})
        self.assertEqual((casts, basis), (2000, "nominalEquivalent"))
        self.assertEqual(der[0]["field"], "casts")
        self.assertIn("fiveOreEquivalentOperations", der[0]["formula"])

    def test_counted_from_inputs(self):
        casts, _, basis, der = ie.cast_count({"reportedInputsConsumed": 1000, "batchInputsPerOperation": 5})
        self.assertEqual((casts, basis), (200, "countedFromInputs"))
        self.assertIn("1000 / 5", der[0]["formula"])

    def test_no_casts(self):
        casts, _, basis, der = ie.cast_count({"batchInputsPerOperation": 5})
        self.assertEqual((casts, basis, der), (None, None, []))


class RawInputs(unittest.TestCase):
    """M03.1 b: raw quantities copied by old field name, never computed."""

    def test_processed_purchased_refunded(self):
        d = old_record(processing={"reportedInputsConsumed": 8998, "resourcefulnessOreSaved": 36},
                       reportedInitialHerbs=9000)
        raw, keys = ie.raw_inputs(d)
        self.assertEqual(raw, {"inputsProcessed": 8998, "inputsPurchased": 9000, "inputsRefunded": 36})
        self.assertEqual(keys["inputsPurchased"], "reportedInitialHerbs")

    def test_initial_ore_is_purchased_not_processed(self):
        raw, _ = ie.raw_inputs(old_record(processing={"reportedInitialOre": 10000}))
        self.assertEqual((raw["inputsProcessed"], raw["inputsPurchased"]), (None, 10000))

    def test_derived_old_fields_not_read(self):
        raw, _ = ie.raw_inputs(old_record(processing={"derivedInputsConsumedIfNoRefunds": 2260,
                                                      "nominalInputsRequired": 5000}))
        self.assertEqual(set(raw.values()), {None})

    def test_ore_saved_in_extra(self):
        raw, _ = ie.raw_inputs(old_record(originalUnmappedExtra={"Prismatic Ore": 26, "oreSaved": 36}))
        self.assertEqual(raw["inputsRefunded"], 36)


class Dates(ImporterFixture):
    """M03.1 c: ISO dataDate only; prose to dataDateText; observation date to observedOn."""

    def test_text_and_observed(self):
        self.obs("a.jsonl", [old_record(hotfixWindow="BfA historical, exact build unknown", observed="2019-07-03",
                                        publishedDate="2019-07-29")])
        r = self.studies()[0][0]
        self.assertIsNone(r["dataDate"])
        self.assertEqual(r["dataDateText"], "BfA historical, exact build unknown")
        self.assertEqual(r["observedOn"], "2019-07-03")
        self.assertEqual(r["source"]["published"], "2019-07-29")

    def test_iso_kept(self):
        self.obs("a.jsonl", [old_record(hotfixWindow="2022-12-07")])
        r = self.studies()[0][0]
        self.assertEqual((r["dataDate"], r["dataDateText"], r["observedOn"], r["source"]["published"]),
                         ("2022-12-07", None, None, None))

    def test_iso_with_prose_is_text(self):
        self.obs("a.jsonl", [old_record(hotfixWindow="2020-12-04 Shadowlands")])
        r = self.studies()[0][0]
        self.assertIsNone(r["dataDate"])
        self.assertEqual(r["dataDateText"], "2020-12-04 Shadowlands")


class Provenance(ImporterFixture):
    """M03.1 d: migratedFrom on every row, with the file hash."""

    def test_migrated_from(self):
        self.obs("a.jsonl", [old_record(), old_record(observationID="obs-2", url="https://example.org/2")])
        rows = self.studies()[0]
        with open(os.path.join(self.root, ie.OBS_DIR, "a.jsonl"), "rb") as fh:
            sha = hashlib.sha256(fh.read()).hexdigest()
        self.assertEqual([r["migratedFrom"] for r in rows],
                         [{"path": f"{ie.OBS_DIR}/a.jsonl", "sha256": sha, "recordRef": f"line {n}"} for n in (1, 2)])


class NameOnlyRows(ImporterFixture):
    """M03.1 e: outputs without an item ID become name-only rows after the existing IDs."""

    def test_single_material_placed_category_not(self):
        self.obs("a.jsonl", [old_record(outputs=[], processing={"completedOperations": 100}, unmappedReportedOutputs=[
            {"materialFamily": "Powder Pigment", "reportedTotalUnits": 1305, "mappingStatus": "FAMILY_ONLY_QUALITY_RANK_UNRESOLVED"},
            {"materialFamily": "green gems Q2", "reportedTotalUnits": 50, "mappingStatus": "AGGREGATE_FAMILY_RANK_ONLY_ITEM_ID_UNKNOWN"},
            {"reportedIndex": 3, "reportedTotalUnits": 7, "mappingStatus": "UNMAPPED_INDEX_ONLY"}])])
        rows, skipped, _ = self.studies()
        self.assertEqual([(r["outputName"], r["rawOutputName"], r["totalQuantity"]) for r in rows],
                         [("Powder Pigment", "Powder Pigment", 1305), (None, "green gems Q2", 50), (None, "output #3", 7)])
        self.assertEqual(skipped["no outputs"], 1)
        self.assertTrue(all(r["outputItemID"] is None and r["castsBasis"] == "reported" for r in rows))

    def test_raw_named_counts_skip_mapped_totals(self):
        self.obs("a.jsonl", [old_record(outputs=[{"outputItemID": 2001, "totalUnits": 56}, {"outputItemID": 2002, "totalUnits": 9}],
                                        rawNamedCounts={"Tiger Opal": 56, "Primordial Ruby": 9, "Sparkling Shard": 303})])
        rows = self.studies()[0]
        self.assertEqual([r["rawOutputName"] for r in rows], [None, None, "Sparkling Shard"])

    def test_new_rows_numbered_after_existing(self):
        self.obs("a.jsonl", [old_record(outputs=[], unmappedReportedOutputs=[
            {"materialFamily": "Nozdorite", "reportedTotalUnits": 5, "mappingStatus": "NAME_ONLY_OUTSIDE_WORKER_ASSIGNED_KEYS"}])])
        self.obs("b.jsonl", [old_record(url="https://example.org/b")])
        rows, _, log = self.studies()
        self.assertEqual([(r["id"], r["rawOutputName"]) for r in rows],
                         [("import-study-00001", None), ("import-study-00002", "Nozdorite")])
        self.assertEqual(log["existingRows"], 1)

    def test_not_placed_when_agents_cite_url(self):
        self.agent([drop("ag-1", url="https://example.org/study")])
        self.obs("a.jsonl", [old_record(outputs=[], unmappedReportedOutputs=[
            {"materialFamily": "Nozdorite", "reportedTotalUnits": 5, "mappingStatus": "NAME_ONLY_OUTSIDE_WORKER_ASSIGNED_KEYS"}])])
        r = self.studies()[0][0]
        self.assertIsNone(r["outputName"])
        self.assertIn("already cites this source URL", r["notes"])

    def test_not_placed_when_agent_row_has_same_numbers(self):
        self.agent([drop("ag-1", url="https://elsewhere.example/x", inputItemID=1001, casts=200,
                         outputItemID=None, outputName="Sparkling Shard", totalQuantity=303)])
        self.obs("a.jsonl", [old_record(processing={"completedOperations": 200}, outputs=[{"outputItemID": 2001, "totalUnits": 56}],
                                        rawNamedCounts={"Sparkling Shard": 303})])
        r = self.studies()[0][1]
        self.assertIsNone(r["outputName"])
        self.assertIn("same input, casts, output name and total", r["notes"])

    def test_duplicates_and_models_stay_skipped_with_reason(self):
        dup = old_record()
        self.obs("a.jsonl", [dup, old_record(observationID="m", evidenceStatus="MODEL_ESTIMATE", url="https://example.org/m")])
        self.obs("b.jsonl", [dup, old_record(observationID="t", sourceType="TSM_HISTORICAL", url="https://example.org/t")])
        rows, skipped, log = self.studies()
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["migratedFrom"]["path"], f"{ie.OBS_DIR}/b.jsonl")  # later copy kept
        self.assertEqual((skipped["duplicate"], skipped["model/TSM"]), (1, 2))
        self.assertEqual(sorted(x["reason"].split(" ")[0] for x in log["skipped"]), ["TSM", "duplicate", "model"])

    def test_no_cohort_key(self):
        self.obs("a.jsonl", [old_record()])
        self.assertNotIn("cohortKey", self.studies()[0][0])


class Typeless(ImporterFixture):
    """M03.0: typeless agent records mapped through importer output that replaces them."""

    def put(self, records):
        path = os.path.join(self.root, ie.TYPELESS_FILE)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as fh:
            for r in records:
                fh.write(json.dumps(r) + "\n")

    def test_exchange_and_drop(self):
        self.put([
            {"id": "m-1", "sourceKind": "exchange", "sourceURL": "https://x/1", "sourceName": "Site", "sourceAuthor": None,
             "date": None, "notes": "n", "giveName": "A", "giveItemID": None, "giveCount": 10, "getName": "B",
             "getItemID": None, "getCount": 1, "where": "use", "requirements": None},
            {"id": "m-2", "sourceKind": "study", "sourceURL": "https://x/2", "sourceName": "Site", "sourceAuthor": "au",
             "date": "2026-04-08", "notes": "n", "method": "Prospect", "inputName": "Ore", "inputItemID": 7,
             "outputName": "Gem", "outputItemID": None, "casts": 200, "outputTotal": None, "percentShown": 20,
             "percentMeaning": "per prospecting craft (author clarified); not per ore", "averageShown": None,
             "averagePer": None, "histogram": None},
            {"id": "m-3", "type": "drop"}])
        rows, log = ie.import_typeless()
        self.assertEqual([(r["type"], r["replaces"]) for r in rows], [("exchange", "m-1"), ("drop", "m-2")])
        ex, dr = rows
        self.assertEqual((ex["giveCount"], ex["getCount"], ex["source"]["url"]), (10, 1, "https://x/1"))
        self.assertEqual((dr["casts"], dr["percentShown"], dr["percentMeaning"], dr["castsBasis"]), (200, 20, "perCast", "reported"))
        self.assertEqual(dr["source"]["published"], "2026-04-08")
        self.assertEqual(v.check_record({k: x for k, x in dr.items()}), [])

    def test_unestablished_input_is_kept_unplaced(self):
        self.put([{"id": "m-4", "sourceKind": "study", "sourceURL": "https://x/4", "date": "2026-04-01", "notes": "n",
                   "method": "Disenchant", "inputName": "Darkmoon Deck (suit unspecified)", "inputItemID": None,
                   "outputName": "Dawn Crystal", "outputItemID": None, "casts": 1, "outputTotal": 1}])
        r = ie.import_typeless()[0][0]
        self.assertIsNone(r["inputName"])
        self.assertEqual(r["rawInputName"], "Darkmoon Deck (suit unspecified)")
        self.assertIsNone(b.key_of(r, {}))


class GameDataTables(ImporterFixture):
    """M03.5: only GameData rows missing from itemdb are imported, all as reference."""

    def setUp(self):
        super().setUp()
        os.makedirs(os.path.join(self.root, "research", "proposed"))
        stat = lambda val: [val, 2, 40, False, False, [], False]  # noqa: E731
        rows = [["tsm:prospect:10:20:L1", 1, 0, 10, 20, False, 5, False, False, stat(0.5), stat(1), stat(2), stat(0.5)],
                ["compiled:prospect:10:21:L2", 1, 0, 10, 21, False, 5, False, False, stat(False), stat(1), stat(1), stat(0.3)],
                ["tsm:prospect:10:22:L3", 1, 0, 10, 22, False, 5, False, False, stat(0.4), stat(1), stat(1), stat(0.4)]]

        def lua(x):
            if x is False:
                return "false"
            if isinstance(x, list):
                return "{" + ",".join(lua(y) for y in x) + "}"
            if isinstance(x, str):
                return '"' + x + '"'
            return repr(x)
        with open(os.path.join(self.root, "research", "proposed", "itemdb.lua"), "w") as fh:
            fh.write("local raw=" + lua(rows) + "\n")
        with open(os.path.join(self.root, "GameData.lua"), "w") as fh:
            fh.write('gd.prospect[10]={method="Prospect",batch=5,kind="mean",evidence="e",samples=1000,source="https://s",materials={\n'
                     ' {id=21,chance=0.2,expectedQuantity=0.3,minQuantity=nil,maxQuantity=nil,quantityBasis="q",probabilityBasis="NOT MEASURED"},\n'
                     ' {id=22,chance=0.3,expectedQuantity=0.9,minQuantity=nil,maxQuantity=nil,quantityBasis="q",probabilityBasis="NOT MEASURED"},\n'
                     ' {id=20,chance=0.5,expectedQuantity=0.5,minQuantity=nil,maxQuantity=nil,quantityBasis="q",probabilityBasis="NOT MEASURED"},\n'
                     '}}\n'
                     'gd.tsmRetail={prospect={},mill={}}\n'
                     'gd.tsmRetail.prospect[10]={\n {id=20,matRate=0.5,amountOfMats=0.1,minAmount=1,maxAmount=2},\n}\n')

    def test_only_missing_imported_as_reference(self):
        rows, rep = ie.import_gamedata_tables()
        self.assertEqual([(r["outputItemID"], r["sourceKind"], r["averageShown"], r["percentShown"]) for r in rows],
                         [(22, "reference", 0.9, None)])   # 21: compiled row present; 20: equals the TSM row
        self.assertEqual((rep["tsmRetail"]["present"], len(rep["tsmRetail"]["missing"])), (1, 0))
        self.assertEqual((rep["millProspect"]["present"], len(rep["millProspect"]["missing"])), (2, 1))
        self.assertIsNone(rows[0]["casts"])


class EstimatorFields(Fixture):
    """Estimator changes the new fields require (and nothing else)."""

    def test_reference_rows_never_reach_study_counts(self):
        ref = drop("g", sourceKind="reference", averageShown=5.0, averagePer="cast")
        e = self.one([ref, drop("a", casts=100, castsWithDrop=20, totalQuantity=30)])
        self.assertEqual((e["studyCasts"], e["studies"], e["referenceValues"]), (100, 1, 1))
        self.assertFalse(b.is_study_row(ref))

    def test_observed_on_dates_a_study(self):
        r = drop("a", observedOn="2026-04-22", published=None)
        self.assertEqual(b.study_date(r), "2026-04-22")
        self.assertEqual(b.study_date(drop("a", dataDate="2026-01-01", observedOn="2026-04-22")), "2026-01-01")

    def test_observed_on_is_not_post_date_only(self):
        self.put("rate-changes.jsonl", [{"date": "2026-03-31", "method": "Prospect", "affects": "Midnight ores"}])
        w, why = b.epoch_weight(drop("a", observedOn="2026-04-22", published="2026-04-23"), "Prospect", "237361",
                                b.load_rate_changes())
        self.assertEqual((w, why), (1.0, None))

    def test_new_fields_correctable(self):
        self.assertTrue({"castsBasis", "inputsProcessed", "inputsPurchased", "inputsRefunded", "unlockState",
                         "dataDateText", "observedOn"} <= b.CORRECTABLE)


class ValidatorRules(unittest.TestCase):
    def codes(self, r):
        return {c for _, c, _ in v.check_record(r)}

    def test_basis_rules(self):
        self.assertIn("CASTS_BASIS_UNKNOWN", self.codes(drop("a", casts=1, castsBasis="guess")))
        self.assertIn("DERIVATION_MISSING", self.codes(drop("a", casts=1, castsBasis="countedFromInputs")))
        self.assertNotIn("DERIVATION_MISSING", self.codes(drop("a", casts=1, castsBasis="countedFromInputs",
                                                               derivations=[{"field": "casts", "formula": "f", "assumption": None}])))
        self.assertIn("CASTS_BASIS_MISSING", self.codes(drop("a", casts=1, agent="import")))
        self.assertNotIn("CASTS_BASIS_MISSING", self.codes(drop("a", casts=1)))   # agent records: not yet
        self.assertIn("DATE_NOT_ISO", self.codes(drop("a", observedOn="April 2026")))


class RealRepository(unittest.TestCase):
    """Checks on the committed importer output."""

    @classmethod
    def setUpClass(cls):
        cls.rows = {}
        for name in sorted(os.listdir(IMPORTED)):
            with open(os.path.join(IMPORTED, name), encoding="utf-8") as fh:
                cls.rows[name] = [json.loads(l) for l in fh if l.strip()]

    def test_existing_ids_stable(self):
        with open(os.path.join(HERE, "fixtures", "pre-m03-study-ids.jsonl"), encoding="utf-8") as fh:
            before = [json.loads(l) for l in fh]
        now = self.rows["old-studies.jsonl"][:len(before)]
        self.assertEqual(len(before), 652)
        self.assertEqual([{k: r[k] for k in b0} for r, b0 in zip(now, before)], before)
        ids = [r["id"] for r in self.rows["old-studies.jsonl"]]
        self.assertEqual(ids, [f"import-study-{i:05d}" for i in range(1, len(ids) + 1)])

    def test_every_casts_value_has_basis_and_derivation(self):
        for name, rows in self.rows.items():
            for r in rows:
                if r.get("casts") is not None:
                    self.assertIn(r.get("castsBasis"), v.CASTS_BASES, (name, r["id"]))
                if r.get("castsBasis") in v.COMPUTED_BASES:
                    self.assertTrue(any(d["field"] == "casts" for d in r["derivations"]), (name, r["id"]))
                self.assertTrue(r.get("migratedFrom"), (name, r["id"]))
                self.assertNotIn("cohortKey", r)
                dd = r.get("dataDate")
                self.assertTrue(dd is None or v.ISO_DATE.match(dd), (name, r["id"], dd))

    def test_gamedata_rows_are_reference(self):
        rows = self.rows["gamedata-mill-prospect-reference.jsonl"]
        self.assertTrue(rows)
        self.assertTrue(all(r["sourceKind"] == "reference" and r["casts"] is None for r in rows))
        self.assertFalse(any(b.is_study_row(r) for r in rows))

    def test_typeless_numbers_match_agent_records(self):
        with open(os.path.join(REPO, ie.TYPELESS_FILE), encoding="utf-8") as fh:
            agent = {d["id"]: d for d in map(json.loads, fh) if "type" not in d}
        mapped = {r["replaces"]: r for r in self.rows["typeless-agent-records.jsonl"]}
        self.assertEqual(set(mapped), set(agent))
        for rid, a in agent.items():
            r = mapped[rid]
            self.assertEqual(r["source"]["url"], a["sourceURL"])
            if a["sourceKind"] == "exchange":
                for k in ("giveItemID", "giveName", "giveCount", "getItemID", "getName", "getCount", "where", "requirements"):
                    self.assertEqual(r[k], a[k], (rid, k))
            else:
                self.assertEqual((r["method"], r["casts"], r["totalQuantity"], r["percentShown"], r["outputName"],
                                  r["outputItemID"]),
                                 (a["method"], a["casts"], a["outputTotal"], a["percentShown"], a["outputName"],
                                  a["outputItemID"]), rid)

    def test_rerun_byte_identical(self):
        out = tempfile.mkdtemp()
        saved = ie.OUT
        try:
            ie.OUT = out
            ie._SHA.clear()
            ie.main([])
            first = {n: open(os.path.join(out, n), "rb").read() for n in sorted(os.listdir(out))}
            ie.main([])
            second = {n: open(os.path.join(out, n), "rb").read() for n in sorted(os.listdir(out))}
        finally:
            ie.OUT = saved
            shutil.rmtree(out)
        self.assertEqual(first, second)
        for n, data in first.items():
            with open(os.path.join(IMPORTED, n), "rb") as fh:
                self.assertEqual(fh.read(), data, n)


if __name__ == "__main__":
    unittest.main()
