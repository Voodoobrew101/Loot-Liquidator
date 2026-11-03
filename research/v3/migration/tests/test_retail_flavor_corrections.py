#!/usr/bin/env python3
"""Retail source-flavor guard: preserve original SoD evidence, exclude its two rows from estimates.

This test is intentionally narrow. A Classic/WotLK URL alone does NOT prove a historical
observation was made in Classic rather than original-era Retail; the Labyras comment
explicitly identifies Season of Discovery, which is a different game flavor.
"""
import json
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "research", "v3", "tools"))
import build_estimates as estimator  # noqa: E402

SOURCE = os.path.join(ROOT, "research", "v3", "evidence", "legacy",
                      "2026-11-02T0835-brown-linen-and-netherweave-de-cohorts.jsonl")
SOD_IDS = {"legacy-20261102-835007", "legacy-20261102-835008"}


class RetailFlavorCorrections(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with open(SOURCE, encoding="utf-8") as fh:
            cls.original = [json.loads(line) for line in fh if line.strip()]
        cls.loaded = estimator.load()

    def test_original_sod_measurements_are_preserved(self):
        rows = {r["id"]: r for r in self.original}
        self.assertTrue(SOD_IDS <= set(rows))
        self.assertEqual(rows["legacy-20261102-835007"]["casts"], 73)
        self.assertEqual(rows["legacy-20261102-835007"]["totalQuantity"], 20)
        self.assertEqual(rows["legacy-20261102-835008"]["casts"], 73)
        self.assertEqual(rows["legacy-20261102-835008"]["totalQuantity"], 95)
        self.assertIn("Season of Discovery", rows["legacy-20261102-835007"]["notes"])

    def test_sod_only_rows_are_not_in_retail_estimator_input(self):
        ids = {r.get("id") for r in self.loaded}
        self.assertFalse(SOD_IDS & ids)

    def test_other_historical_brown_linen_and_tbc_rows_remain_usable(self):
        ids = {r.get("id") for r in self.loaded}
        self.assertIn("legacy-20261102-835005", ids)  # 2,086-robe historical cohort
        self.assertIn("legacy-20261102-835009", ids)  # Netherweave Bracers
        self.assertIn("legacy-20261102-835010", ids)


if __name__ == "__main__":
    unittest.main()
