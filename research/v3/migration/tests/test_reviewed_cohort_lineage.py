"""Real-source regressions for reviewed transcription copies, not new measurements."""
import collections
import json
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "research/v3/tools"))
import build_estimates as b


def read(name):
    return [json.loads(line) for line in (ROOT / "research/v3/evidence" / name).read_text(encoding="utf-8").splitlines() if line.strip()]


class ReviewedCohortLineage(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.loaded = b.load()

    def test_miststalker_copies_preserve_every_ranked_hit_without_family_weight(self):
        old = read("midnight/2026-11-01T1715-miststalker-looter-cohorts.jsonl")
        new = read("midnight/2026-11-02T1105-miststalker-and-courtly-de-milling.jsonl")
        for item, casts, hits in ((272242, 154, [62, 42, 21, 19, 4, 1]),
                                  (272243, 121, [41, 33, 26, 15, 3])):
            prior = [r for r in old if r.get("inputItemID") == item and r.get("type") == "drop"]
            copies = [r for r in new if r.get("inputItemID") == item and r.get("type") == "drop"]
            self.assertEqual([r["castsWithDrop"] for r in prior], hits)
            self.assertEqual([r["castsWithDrop"] for r in copies], hits)
            # Linkage is independently checked before asserting exclusion.
            for original, copy in zip(prior, copies):
                self.assertEqual(b.source_key(original), b.source_key(copy))
                self.assertEqual(original["studyKey"], copy["studyKey"])
                self.assertEqual(original["outputName"], copy["outputName"])
                self.assertEqual((original["casts"], copy["casts"]), (casts, casts))
                self.assertIsNone(copy["outputItemID"])
                self.assertIsNone(copy["outputRank"])
            ids = {r["id"] for r in prior + copies}
            kept = [r for r in self.loaded if r.get("id") in ids]
            self.assertEqual({r["id"] for r in kept}, {r["id"] for r in prior})
            estimates, _ = b.build(kept)
            self.assertEqual(len(estimates), len(hits))
            self.assertEqual({r["outputItemID"] for r in estimates}, {r["outputItemID"] for r in prior})
            for estimate in estimates:
                self.assertEqual(estimate["studies"], 1)
                self.assertEqual(estimate["studyCasts"], casts)
                self.assertEqual(estimate["chanceSource"], "measured")
                self.assertEqual(estimate["averageSource"], "estimated")

    def test_jallfo_duplicates_match_the_same_source_profile_and_raw_total(self):
        old = read("dragonflight/2026-10-30T2131-jallfo-beta-six-prospecting-cohorts.jsonl")
        new = read("dragonflight/2026-11-02T1430-jallfo-beta-six-profile-prospecting.jsonl")
        workbook = "1B_CjPU0AUlJkbogauPTdo0W4dUZiP1hxZ8KMZX7qp3Q"
        self.assertTrue(all(workbook in r["source"]["url"] for r in old + new))
        def signature(r):
            material = r["outputName"].lower().replace("'", "")
            if material == "khazgorite":
                material += " ore"
            rank = None if material == "prismatic ore" else r.get("outputRank")
            skill = re.search(r"(68|113|228)", r["skill"]).group(1)
            return (r["inputName"].lower(), r["inputRank"], skill, material, rank, r["totalQuantity"])
        old_signatures = collections.Counter(map(signature, old))
        new_signatures = collections.Counter(map(signature, new))
        self.assertEqual(sum((old_signatures & new_signatures).values()), 216)
        self.assertEqual(sum((new_signatures - old_signatures).values()), 6)
        ids = {r["id"] for r in old + new}
        kept = [r for r in self.loaded if r.get("id") in ids]
        self.assertEqual(len(kept), 222)
        profiles = collections.Counter(r["cohortKey"] for r in kept)
        self.assertEqual(len(profiles), 6)
        self.assertEqual(set(profiles.values()), {37})
        self.assertTrue(all(r.get("casts") is None for r in kept))
        self.assertTrue(all(r.get("castsWithDrop") is None for r in kept))
        self.assertTrue(all(r.get("outputRank") is None for r in kept if r["outputName"].lower() == "prismatic ore"))
        self.assertEqual(b.build(kept)[0], [])  # no fabricated completed-cast denominator

    def test_six_additional_draconium_outputs_survive_with_unknown_casts(self):
        expected = {"dragonflight-20261102-143112": 1036, "dragonflight-20261102-143113": 769,
                    "dragonflight-20261102-143149": 947, "dragonflight-20261102-143150": 1079,
                    "dragonflight-20261102-143186": 986, "dragonflight-20261102-143187": 1225}
        kept = {r["id"]: r for r in self.loaded if r.get("id") in expected}
        self.assertEqual({rid: r["totalQuantity"] for rid, r in kept.items()}, expected)
        for r in kept.values():
            self.assertIsNone(r.get("inputItemID"))
            self.assertIsNone(r.get("casts"))
            self.assertIsNone(r.get("castsWithDrop"))
            self.assertIsNone(r.get("averageShown"))

    def test_zkay8v_original_and_independent_comment_stay_two_cohorts(self):
        rows = [r for r in self.loaded if r.get("type") == "drop" and "zkay8v" in str(r.get("studyKey", ""))]
        self.assertEqual(len(rows), 47)
        by_cohort = collections.defaultdict(list)
        for r in rows:
            by_cohort[r["cohortKey"]].append(r)
        measured = by_cohort["zkay8v-original-1000-completed-prospects"]
        nominal = by_cohort["zkay8v-independent-50000-nominal-ore-comment"]
        self.assertEqual((len(measured), len(nominal)), (25, 22))
        self.assertEqual({r["casts"] for r in measured}, {1000})
        self.assertEqual({r["casts"] for r in nominal}, {None})
        self.assertEqual(b.build(nominal)[0], [])
        self.assertEqual(sorted(r["totalQuantity"] for r in measured if r["outputName"] == "Eternity Amber"), [72, 315])


if __name__ == "__main__":
    unittest.main()
