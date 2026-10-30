#!/usr/bin/env python3
"""Static, fail-closed checks for the proposed profession mechanics registry.
Run from repository root: python3 research/tests/test_profession_mechanics_contract.py
These do NOT establish that gameplay coefficients or effects are validated.
"""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
REGISTRY = ROOT / "research/mechanics/ProfessionMechanicsRegistry-v0.2-PROPOSAL.json"

class RegistryContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data = json.loads(REGISTRY.read_text(encoding="utf-8"))

    def test_source_claims_referenced(self):
        claims = {x["claimID"] for x in self.data["sourceClaims"]}
        self.assertEqual(len(claims), len(self.data["sourceClaims"]))
        for rule in self.data["mechanicRules"] + self.data["patchEvents"]:
            self.assertTrue(rule["sourceClaimIDs"])
            self.assertTrue(set(rule["sourceClaimIDs"]).issubset(claims), rule)

    def test_no_duplicate_rule_ids(self):
        for key, id_key in [("mechanicRules", "ruleID"), ("patchEvents", "eventID")]:
            ids = [row[id_key] for row in self.data[key]]
            self.assertEqual(len(ids), len(set(ids)), key)

    def test_no_unverified_numeric_formula(self):
        numeric = "VERIFIED_NUMERIC"
        for rule in self.data["mechanicRules"]:
            if rule["evidenceStatus"] != numeric:
                self.assertIsNone(rule["formulaID"], rule["ruleID"])
            if rule["formulaID"] is not None:
                self.assertEqual(rule["evidenceStatus"], numeric)
                self.assertEqual(rule["applies"], "VERIFIED_APPLIES")
                self.assertTrue(rule["sourceClaimIDs"])

    def test_unknown_hotfix_cannot_be_normalized(self):
        event = next(x for x in self.data["patchEvents"]
                     if x["eventID"] == "midnight-gem-hotfix-2026-03-31")
        self.assertIsNone(event["numericTransformID"])
        self.assertIn("OUTPUT_OCCURRENCE", event["affectedFields"])
        self.assertIn("OUTPUT_UNCONDITIONAL_EXPECTATION", event["affectedFields"])
        fixture = next(x for x in self.data["negativeFixtures"]
                       if x["test"] == "midnight-pre-mar31-to-post-hotfix-gem")
        self.assertEqual(fixture["expectedDecision"], "BLOCKED_UNKNOWN_PATCH_EFFECT")

    def test_versioned_chronology_contract(self):
        self.assertEqual(self.data["patchEvents"][0]["effectiveDate"], "2026-03-31")
        contract = self.data["mechanicsChronology"]
        self.assertEqual(contract["path"], "research/mechanics/mechanics-chronology.json")
        chrono = json.loads((ROOT / contract["path"]).read_text(encoding="utf-8"))
        self.assertEqual(chrono["events"][0]["firstAffectedDate"], "2026-03-31")
        self.assertIsNone(chrono["events"][0]["numericParameters"])
        self.assertFalse(chrono["events"][0]["numericallyBridgeable"])
        self.assertEqual(chrono["revisionHistory"][0]["previousDate"], "2026-04-01")

    def test_independent_material_fields(self):
        fields = self.data["dataDefinitions"]["outputQuantities"]
        self.assertEqual({x["field"] for x in fields},
                         {"dropChance", "yieldMin", "yieldMax", "expectedQuantity"})
        self.assertTrue(self.data["normalization"]["neverCoerceUnknownToZero"])

    def test_summary_statistics_not_full_distribution(self):
        self.assertIn("histogram", self.data["dataDefinitions"]["rawDistribution"].lower())
        fixture = next(x for x in self.data["negativeFixtures"]
                       if x["test"] == "same-p-min-max-E-different-histograms")
        self.assertEqual(fixture["expectedDecision"], "BLOCKED_NO_RULE")

    def test_example_unit_arithmetic(self):
        samples = next(x for x in self.data["negativeFixtures"]
                       if x["test"] == "only-aggregate-totals")
        self.assertEqual(samples["rawOutputTotals"] / samples["completedOperations"],
                         samples["expectedQuantity"])
        self.assertIsNone(samples["expectedDropChance"])
        self.assertIsNone(samples["expectedYieldMin"])
        self.assertIsNone(samples["expectedYieldMax"])
        milling = next(x for x in self.data["negativeFixtures"]
                       if x["test"] == "ten-herb-milling")
        per_op = milling["rawOutputTotals"] / milling["completedOperations"]
        self.assertEqual(per_op, milling["expectedQuantityPerOperation"])
        self.assertEqual(per_op / milling["batchInputs"],
                         milling["expectedQuantityPerHerb"])

    def test_non_verified_rules_fail_closed(self):
        diamond = next(x for x in self.data["mechanicRules"]
                       if x["ruleID"] == "midnight-ore-node-diamond")
        self.assertEqual(diamond["applies"], "UNKNOWN")
        self.assertIsNone(diamond["formulaID"])
        self.assertEqual(diamond["effectTarget"], "OUTPUT_OCCURRENCE")
        self.assertFalse(self.data["reviewStatus"]["passedProductionReadiness"])

if __name__ == "__main__":
    unittest.main()
