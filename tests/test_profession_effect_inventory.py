"""Source-inventory guards for scope routing and complete milestone accounting."""
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("profession_effect_inventory", ROOT / "tools/profession_effect_inventory.py")
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class ProfessionEffectInventoryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = json.loads(MODULE.SNAPSHOT.read_text(encoding="utf-8"))
        cls.coverage = json.loads(MODULE.COVERAGE.read_text(encoding="utf-8"))
        cls.nodes = {node["nodeID"]: node for node in cls.source["nodes"]}
        cls.spells = {spell["spellID"]: spell for spell in cls.source["recipeRouting"]["spells"]}

    def test_every_catalog_node_and_actual_milestone_is_accounted_for(self):
        catalog = MODULE.read_json(MODULE.CATALOG)
        expected = {node["id"] for tree in catalog["catalogs"].values() for node in tree["nodes"]}
        self.assertEqual(set(self.nodes), expected)
        self.assertEqual(len(self.nodes), len(self.source["nodes"]))
        actual_perks = {(node["nodeID"], milestone["perkNodeID"])
                        for node in self.source["nodes"] for milestone in node["milestones"]}
        covered_perks = {(node["nodeID"], milestone["perkNodeID"])
                         for node in self.coverage["nodes"] for milestone in node["milestones"]}
        self.assertEqual(covered_perks, actual_perks)
        self.assertFalse(self.source["importIssues"])
        for node in self.source["nodes"]:
            self.assertTrue(node["milestones"])
            for milestone in node["milestones"]:
                self.assertGreaterEqual(milestone["investedPoints"], 0)
                self.assertLessEqual(milestone["investedPoints"], node["maxInvestedRank"])

    def test_crystal_bonus_perks_do_not_gain_fictitious_proc_coefficients(self):
        crystal = self.nodes[107646]
        perks = {milestone["investedPoints"]: milestone for milestone in crystal["milestones"]}
        self.assertEqual(perks[20]["perkNodeID"], 107620)
        self.assertEqual(perks[30]["perkNodeID"], 107618)
        self.assertEqual(perks[20]["entries"][0]["effects"], [])
        effects = perks[30]["entries"][0]["effects"]
        self.assertEqual([(effect["effectID"], effect["amount"]) for effect in effects], [(150, 20)])
        self.assertIn("native magical essences", perks[20]["entries"][0]["description"])

    def test_recipe_scope_distinguishes_void_and_light_potions(self):
        void_labels = self.spells[1230867]["labels"]
        light_labels = self.spells[1230858]["labels"]
        self.assertIn(4880, void_labels)
        self.assertNotIn(4881, void_labels)
        self.assertIn(4881, light_labels)
        self.assertNotIn(4880, light_labels)
        routes = self.source["recipeRouting"]["labelSpellIDs"]
        self.assertIn(1230867, routes["4880"])
        self.assertNotIn(1230867, routes["4881"])

    def test_generic_disenchant_does_not_inherit_crafting_quality_pointer(self):
        disenchant = self.spells[13262]
        self.assertEqual(disenchant["labels"], [])
        self.assertEqual([effect["Effect"] for effect in disenchant["effects"]], [99])
        self.assertFalse(any("craftingDataID" in effect for effect in disenchant["effects"]))
        self.assertIn("separate item-rarity context", self.source["recipeRouting"]["semantics"])

    def test_crafting_and_salvage_pointers_use_distinct_native_effect_layouts(self):
        potion = self.spells[1230867]["effects"][0]
        prospect = self.spells[1231127]["effects"][0]
        self.assertEqual((potion["Effect"], potion["craftingDataID"]), (288, 3249))
        self.assertEqual((prospect["Effect"], prospect["craftingDataID"]), (296, 3402))
        data = {row["ID"]: row for row in self.source["recipeRouting"]["craftingData"]}
        self.assertEqual(data[3402]["CraftingDifficulty"], 365)

    def test_enum25_is_not_a_universal_skill_term(self):
        found_extra_proc = False
        for node in self.source["nodes"]:
            if node["profession"] != "Alchemy":
                continue
            for milestone in node["milestones"]:
                for entry in milestone["entries"]:
                    if "transmutagen" in entry["description"].lower() and any(effect["typeEnum"] == 25 for effect in entry["effects"]):
                        found_extra_proc = True
        self.assertTrue(found_extra_proc)
        self.assertIn("not universally Skill", self.source["effectUnits"]["enum25Warning"])

    def test_secondary_professions_and_legacy_eras_are_explicit(self):
        cells = {(cell["profession"], cell["expansionID"]): cell for cell in self.coverage["professionEraCoverage"]}
        self.assertEqual(len(cells), 13 * 12)
        self.assertEqual(cells["Cooking", 11]["status"], "NO_BUNDLED_MODERN_TREE")
        self.assertEqual(cells["Fishing", 11]["status"], "NO_BUNDLED_MODERN_TREE")
        self.assertTrue(cells["Blacksmithing", 0]["requiredWork"])
        parameters = {row["profession"]: row for row in self.source["professionParameters"]}
        self.assertEqual(parameters["Fishing"]["professionRecord"]["MaxCraftExtraQtyPct"], 0)
        self.assertEqual(parameters["Cooking"]["professionRecord"]["ResourcefulEffectLow"], 20)

    def test_coverage_rebuild_is_deterministic_and_explicit_about_pending_terms(self):
        rebuilt = MODULE.build_coverage(self.source, MODULE.read_json(MODULE.RULES))
        self.assertEqual(rebuilt, self.coverage)
        self.assertEqual(sum(self.coverage["summary"]["entryCoverageStatuses"].values()), self.coverage["summary"]["actualEntries"])
        for node in self.coverage["nodes"]:
            entries = node["baseEntries"] + [entry for milestone in node["milestones"] for entry in milestone["entries"]]
            for entry in entries:
                self.assertTrue(entry["status"])
                self.assertTrue(entry["reason"])


if __name__ == "__main__":
    unittest.main()
