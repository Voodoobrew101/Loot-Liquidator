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

    def test_exclusions_are_exact_and_file_scoped_not_a_classic_wide_rule(self):
        with (ROOT / 'research/v3/corrections.jsonl').open(encoding='utf-8') as stream:
            corrections = [json.loads(line) for line in stream if line.strip()]
        scoped = [row for row in corrections if row.get('recordID') in HELD
                  and row.get('field') == 'exclude' and row.get('value') is True]
        self.assertEqual(len(scoped), 9)
        self.assertEqual({row['recordID'] for row in scoped}, HELD)
        self.assertTrue(all(row.get('file') == SOURCE for row in scoped))
        mirrors = [dict(row, _file='research/v3/evidence/legacy/different-original.jsonl')
                   for row in self.original]
        self.assertEqual({row['id'] for row in estimator.apply_corrections(mirrors)},
                         HELD | {OTHER_HISTORIC})


    def test_actual_compiler_change_is_scoped_to_six_classic_inputs(self):
        # Synthetic pre-correction comparison: re-admit ONLY the nine original
        # archive rows in memory, never rewrite the append-only files.
        effective = estimator.load()
        classic_originals = [r for r in self.original if r["id"] in HELD]
        before, _ = estimator.build(effective + classic_originals)
        after, _ = estimator.build(effective)
        key = lambda v: (v["method"], v["input"], str(v["outputItemID"]))
        old = {key(v): v for v in before}
        new = {key(v): v for v in after}
        different = [k for k in old.keys() | new.keys() if old.get(k) != new.get(k)]
        scoped_inputs = {str(r["inputItemID"]) for r in classic_originals}
        unscoped = [k for k in different if k[1] not in scoped_inputs]
        self.assertFalse(unscoped, f"Unexpected collateral estimator changes: {unscoped[:8]}")
        # No absolute delta or change in Retail gold is claimed here: this is
        # compiler-level parity against an intentionally inadmissible baseline.


if __name__ == "__main__":
    unittest.main()
