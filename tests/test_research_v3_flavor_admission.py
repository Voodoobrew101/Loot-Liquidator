"""Research-only Retail admission regression for nine 2026-11-15 MoP Classic Looter rows.

The original observations remain append-only. This does not assert that any
unqualified historical source is valid for a modern Retail character.
Run: python3 -m unittest tests.test_research_v3_flavor_admission
"""
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "research" / "v3" / "tools"))
import build_estimates as estimator  # noqa: E402

SOURCE = (
    "research/v3/evidence/legacy/"
    "2026-11-15T1047-tbc-ilvl97-rare-armor-looter-and-original.jsonl"
)
HELD = {f"legacy-20261115-10470{i:02d}" for i in range(1, 10)}
OTHER_HISTORIC = "legacy-20261115-1047010"


class ClassicRetailAdmissionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with (ROOT / SOURCE).open(encoding="utf-8") as file:
            cls.original = [dict(json.loads(line), _file=SOURCE)
                            for line in file if line.strip()]

    def test_originals_remain_append_only_and_provenance_visible(self):
        self.assertEqual(len(self.original), 10)
        classic = [r for r in self.original if r["id"] in HELD]
        self.assertEqual(len(classic), 9)
        self.assertEqual(len({r["inputItemID"] for r in classic}), 6)
        for row in classic:
            self.assertEqual(row.get("sourceKind"), "study")
            self.assertIn("/mop-classic/", row["source"]["url"])
            self.assertIsNone(row.get("originalSource"))
            self.assertIsNone(row.get("patch"))

    def test_scoped_corrections_exclude_only_nine_from_estimator(self):
        processed = estimator.apply_corrections(self.original)
        self.assertEqual({r["id"] for r in processed}, {OTHER_HISTORIC})
        self.assertEqual(len(self.original), 10, "Do not rewrite the original study archive")

    def test_full_loader_does_not_admit_held_rows_as_retail(self):
        loaded_ids = {r.get("id") for r in estimator.load()}
        self.assertFalse(HELD & loaded_ids)
        self.assertIn(OTHER_HISTORIC, loaded_ids)
        # A TBC historical observation still needs its own context review;
        # this patch does not automatically promote it to Retail.


if __name__ == "__main__":
    unittest.main()
