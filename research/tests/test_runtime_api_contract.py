#!/usr/bin/env python3
"""Contract tests for research-only API capture manifest, not WoW live tests."""
from pathlib import Path
import json
import unittest

ROOT = Path(__file__).resolve().parents[2]
API_PATH = ROOT / "research/mechanics/WoWRuntimeAPIRegistry.json"
PROPOSED_PATH = ROOT / "research/mechanics/ProfessionMechanicsRegistry-v0.2-PROPOSAL.json"

class RuntimeApiManifestTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.api = json.loads(API_PATH.read_text(encoding="utf-8"))
        cls.proposed = json.loads(PROPOSED_PATH.read_text(encoding="utf-8"))
        cls.entries = {r["key"]: r for r in cls.api["entries"]}

    def test_manifest_unique_and_linked(self):
        self.assertEqual(len(self.entries), len(self.api["entries"]))
        self.assertGreaterEqual(len(self.entries), 20)
        self.assertEqual(self.proposed["runtimeApiManifestPath"],
                         "research/mechanics/WoWRuntimeAPIRegistry.json")
        for ref in self.proposed["normalization"]["liveFieldCollection"]:
            self.assertIn(ref["apiKey"], self.entries)
            self.assertTrue(ref["unknownOnNil"])

    def test_required_categories(self):
        required = {
            "client_patch","recipe_skillline","expansion_skillline_window",
            "profession_skill_by_id","specialization_ranks","specialization_perks",
            "recipe_info","recipe_schematic","operation_info","quality_rank",
            "profession_equipment","equipment_stats","active_buffs","concentration",
            "processing_result_event","processing_fallback_events","offline_alt_snapshots",
            "undocumented_rates",
        }
        self.assertTrue(required.issubset(self.entries.keys()))

    def test_public_api_is_not_a_drop_rate_model(self):
        self.assertEqual(self.proposed["normalization"]["apiProvidedNumericModel"],
                         "NO_PUBLIC_API_FOR_HIDDEN_DROP_RATES")
        rates = self.entries["undocumented_rates"]
        self.assertIn("external-research", rates["scope"])
        self.assertFalse(self.api["liveValidation"]["status"] == "VERIFIED_IN_WOW")

    def test_important_known_app_gaps(self):
        self.assertIn("not implemented", self.entries["quality_rank"]["status"])
        self.assertIn("partial", self.entries["operation_info"]["status"])
        self.assertIn("not implemented", self.entries["profession_equipment"]["status"])
        self.assertIn("no confirmed LL usage", self.entries["processing_result_event"]["currentAddon"])

    def test_live_validations_not_claimed(self):
        self.assertEqual(self.api["liveValidation"]["status"], "NOT_TESTED_IN_WOW")
        for row in self.api["entries"]:
            self.assertTrue(row["source"].startswith("https://"))
            self.assertNotEqual(row["status"], "LIVE_VERIFIED")

    def test_parent_child_and_alt_fixtures(self):
        f = {e["test"]:e for e in self.proposed["negativeFixtures"]}
        for key in ("parent-profession-vs-expansion-child-id",
                    "api-operation-result-nil",
                    "item-rarity-not-reagent-quality",
                    "offline-alt-current-gear"):
            self.assertEqual(f[key]["expectedDecision"], "BLOCKED_MISSING_CONTEXT")

    def test_event_coverage_remains_unverified(self):
        row = self.entries["processing_result_event"]
        self.assertIn("unverified", row["scope"].lower())
        self.assertIn("Unknown".lower(), row["caveat"].lower())

if __name__ == "__main__":
    unittest.main()
