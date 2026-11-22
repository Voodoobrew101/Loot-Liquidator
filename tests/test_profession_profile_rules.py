"""Typed profile compiler coverage, units, conditional scope and identity guards."""
import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("profession_profile_rules", ROOT / "tools/profession_profile_rules.py")
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class ProfessionProfileRulesTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = MODULE.load_source()
        cls.rules, cls.audit = MODULE.build(cls.source)
        cls.native_nodes = {node["nodeID"]: node for node in cls.source["nodes"]}

    def all_effects(self):
        for profile in self.rules["profiles"].values():
            for node in profile["nodes"].values():
                yield from node["pointEffects"]
                yield from node["learningEffects"]
                for milestone in node["milestones"]:
                    yield from milestone["effects"]

    def test_all_retained_value_entries_and_milestones_are_typed(self):
        self.assertGreater(self.audit["summary"]["nodes"], 500)
        self.assertEqual(self.audit["summary"]["unmappedSourceEffects"], 0)
        expected = {(node["nodeID"], entry["entryID"])
                    for node in self.source["nodes"]
                    for entry in node["baseEntries"] + [entry for milestone in node["milestones"] for entry in milestone["entries"]]
                    if node["profession"] not in {"Herbalism", "Skinning"}
                    and any(MODULE.is_runtime_value_effect(effect)
                            for effect in MODULE.compile_entry(node, entry, self.native_nodes, self.rules["recipes"]))}
        self.assertEqual({(row["nodeID"], row["entryID"]) for row in self.audit["entries"]}, expected)
        for effect in self.all_effects():
            self.assertIn(effect["metric"], MODULE.METRICS)
            self.assertIn(effect["unit"], MODULE.UNITS)
            self.assertTrue(0 <= effect["confidence"] <= 100)
            self.assertNotIn("description", effect)

    def test_learning_effects_are_not_reapplied_as_zero_point_milestones(self):
        node = self.rules["profiles"]["Enchanting:11"]["nodes"][107647]
        zero = next(row for row in node["milestones"] if row["rank"] == 0)
        self.assertTrue(zero["learning"])
        self.assertEqual(zero["effects"], [])
        learned_skill = [effect for effect in node["learningEffects"] if effect["metric"] == "skill"]
        self.assertEqual([effect["amount"] for effect in learned_skill], [5])
        point_skill = [effect for effect in node["pointEffects"] if effect["metric"] == "skill"]
        self.assertEqual([effect["amount"] for effect in point_skill], [1])

    def test_flat_stat_and_percent_effects_retain_distinct_units(self):
        for effect in self.all_effects():
            if effect["mechanism"] == "client-effect-2":
                self.assertEqual((effect["metric"], effect["unit"]), ("resourcefulness", "rating"))
            elif effect["mechanism"] == "client-effect-10":
                self.assertEqual((effect["metric"], effect["unit"]), ("resourcefulness", "percent"))
        mechanisms = {effect["mechanism"] for effect in self.all_effects()}
        self.assertTrue({"client-effect-2", "client-effect-10", "client-effect-7"} <= mechanisms)
        self.assertNotIn("client-effect-14", mechanisms, "Retired speed projections are not runtime effects")

    def test_custom25_transmutagen_is_not_mapped_to_skill(self):
        candidates = []
        definitions = {entry["definitionID"] for node in self.source["nodes"]
                       if node["profession"] == "Alchemy" for milestone in node["milestones"] for entry in milestone["entries"]
                       if "additional transmutagen" in entry["description"].lower()}
        for effect in self.all_effects():
            if effect["definitionID"] in definitions:
                candidates.append(effect)
        self.assertTrue(candidates)
        self.assertFalse(any(effect["metric"] == "skill" for effect in candidates))
        self.assertTrue(any(effect["metric"] == "extraOutput" and effect["confidence"] == 0 for effect in candidates))

    def test_crystal_perk_keeps_skill_and_bonus_proc_separate(self):
        node = self.rules["profiles"]["Enchanting:11"]["nodes"][107646]
        milestone = next(row for row in node["milestones"] if row["rank"] == 30)
        self.assertTrue(any(effect["metric"] == "skill" and effect["amount"] == 20 for effect in milestone["effects"]))
        self.assertTrue(any(effect["metric"] == "extraOutput" and effect["confidence"] == 0 for effect in milestone["effects"]))
        for effect in milestone["effects"]:
            self.assertEqual(effect["scope"]["method"], "Disenchant")
            self.assertEqual(effect["scope"]["inputRarity"], 4)

    def test_non_economic_reliability_and_cooldowns_do_not_create_materials(self):
        definitions = {entry["definitionID"] for node in self.source["nodes"]
                       for milestone in node["milestones"] for entry in milestone["entries"]
                       if entry["resolvedDescription"] in {
                           "Your tinkers can no longer catastrophically malfunction.",
                           "Shorten the recovery time after crafting Arcanoweave Bolts."}}
        effects = [effect for effect in self.all_effects() if effect["definitionID"] in definitions]
        self.assertTrue(definitions, "The native non-economic source fixtures remain available offline")
        self.assertEqual(effects, [], "Convenience/cooldown handlers are not shipped as value effects")

    def test_resourcefulness_prose_changes_input_savings_not_drop_quantities(self):
        entry_ids = {24520, 24518, 24516, 24514, 54893, 54891, 54889, 54887, 87415, 87413, 87411, 87409, 124509}
        effects = [effect for effect in self.all_effects() if effect["entryID"] in entry_ids]
        self.assertTrue(effects)
        self.assertTrue(any(effect["metric"] == "resourcefulnessSaved" for effect in effects))
        self.assertFalse(any(effect["metric"] in {"extraOutput", "dropChance", "yieldMultiplier"} for effect in effects))

    def test_world_loot_relative_chance_is_not_shipped(self):
        effects = [effect for effect in self.all_effects() if effect["entryID"] == 125760]
        self.assertEqual(effects, [])

    def test_existing_exact_family_replacement_keeps_its_dedicated_handler(self):
        for identity in (98659, 98660, 98661, 98662):
            node = self.rules["profiles"]["Jewelcrafting:10"]["nodes"][identity]
            quantities = [effect for effect in node["pointEffects"] if effect["metric"] in {"extraOutput", "dropChance", "yieldMultiplier", "eligibility"}]
            self.assertTrue(quantities)
            self.assertTrue(all(effect["dedicatedHandler"] == "specialization-rule" for effect in quantities))
            self.assertTrue(all(effect["dedicatedRuleIDs"] for effect in quantities))

    def test_native_recipe_scope_does_not_cross_void_and_light(self):
        void = self.rules["recipes"][1230867]
        light = self.rules["recipes"][1230858]
        self.assertIn(4880, void["labels"])
        self.assertNotIn(4881, void["labels"])
        self.assertIn(4881, light["labels"])
        self.assertEqual(void["profession"], "Alchemy")
        self.assertEqual(void["requiredSkill"], 1)

    def test_salvage_batch_and_internal_item_proxy_are_not_output_quantities(self):
        recipe = self.rules["recipes"][1231127]
        self.assertEqual(recipe["inputCount"], 5)
        self.assertNotIn("outputCount", recipe)
        self.assertNotIn(194709, recipe["outputIDs"])

    def test_item_quality_join_verifies_reversed_item_id_order(self):
        recipe = self.rules["recipes"][1230867]
        self.assertEqual(set(recipe["outputIDs"]), {241302, 241303})
        self.assertTrue(recipe["qualityOrderVerified"])
        self.assertEqual(recipe["outputQualityItems"], {1: {"id": 241303}, 2: {"id": 241302}})
        self.assertEqual([(row["rank"], row["fraction"]) for row in recipe["qualityThresholds"]], [(1, 0), (2, 1)])
        self.assertEqual(recipe["outputCount"], 5)
        items, families = self.rules["items"], self.rules["qualityFamilies"]
        self.assertEqual((items[242787]["qualityRank"], items[242786]["qualityRank"]), (1, 2))
        self.assertEqual(families[items[242787]["qualityFamilyID"]]["rankItemIDs"], [242787, 242786])
        self.assertNotIn(0, families)

    def test_recipe_capabilities_distinguish_components_gear_and_native_flags(self):
        recipes = self.rules["recipes"]
        gear = [recipe for recipe in recipes.values() if recipe.get("outputKind") in {"gear-quality", "equipment"}]
        self.assertTrue(gear)
        self.assertTrue(all(recipe["supportsMulticraft"] is False for recipe in gear))
        single_components = [recipe for recipe in recipes.values() if recipe.get("outputKind") == "ranked-material-family"
                             and recipe.get("outputCount") == 1 and recipe["outputIDs"]
                             and all(self.rules["items"].get(item, {}).get("stackable", 0) > 1 for item in recipe["outputIDs"])]
        self.assertTrue(single_components)
        self.assertTrue(all(recipe["supportsMulticraft"] is True for recipe in single_components))
        self.assertTrue(all(recipe["capabilityConfidence"]["multicraft"] == 60 for recipe in single_components))
        self.assertTrue(all("MODEL" in recipe["capabilityEvidence"]["multicraft"] for recipe in single_components))
        nonstackable = [recipe for recipe in recipes.values() if recipe.get("capabilityEvidence", {}).get("multicraft") == "NATIVE_NONSTACKABLE_OUTPUT"]
        self.assertTrue(nonstackable)
        self.assertTrue(all(recipe["supportsMulticraft"] is False for recipe in nonstackable))
        self.assertNotIn("supportsMulticraft", recipes[13262])

    def test_item_processing_profiles_keep_real_craft_metadata_without_unrouted_scopes(self):
        effects = list(self.all_effects())
        self.assertFalse(any(effect["scope"].get("method") in {"Gather", "Skin", "Fish", "Loot", "Use"} for effect in effects))
        self.assertFalse(any(effect.get("outputBinding", {}).get("kind") == "gather-target-primary" for effect in effects))
        refining = [effect for effect in effects if effect["scope"].get("method") == "Refine"]
        self.assertEqual(refining, [], "Unrouted Refine scope effects are not active item-processing code")
        self.assertFalse(any(effect["scope"].get("method") == "Unravel" for effect in effects))
        self.assertEqual(self.rules["recipes"][2657]["outputIDs"], [2840], "Actual Smelt metadata remains")
        self.assertFalse(any(effect["scope"]["profession"] == "Skinning" for effect in effects))
        self.assertEqual(self.rules["recipes"][375773]["outputIDs"], [193893],
                         "A real Skinning item-craft identity survives removal of its simulated tree")
        buffs = [effect for effect in effects if effect["mechanism"] == "conditional-stat-buff"]
        self.assertTrue(any(effect.get("condition", {}).get("requiresActiveBuff") for effect in buffs))
        self.assertTrue(all(effect["condition"]["manualStateKey"] == effect["entryID"] for effect in buffs))

    def test_world_gathering_targets_and_metadata_are_not_generated(self):
        self.assertNotIn("gatheringTargets", self.rules)
        self.assertFalse(set(self.rules["metrics"]) & {"finesse", "finesseExtra", "perception", "deftness"})
        self.assertTrue(all("GatherTimeIncreasePct" not in row for row in self.rules["professionParameters"].values()))
        self.assertFalse(hasattr(MODULE, "build_gathering_targets"))
        spells = {row["spellID"]: row for row in self.source["recipeRouting"]["spells"]}
        for identity in self.rules["recipes"]:
            effects = spells.get(identity, {}).get("effects", [])
            if any(effect["Effect"] == 302 for effect in effects):
                self.assertTrue(any(effect["Effect"] in (24, 157, 288, 296) or effect.get("craftingDataID") for effect in effects))
        for profession in ("Herbalism", "Skinning", "Fishing"):
            for expansion in (9, 10, 11):
                self.assertNotIn(f"{profession}:{expansion}", self.rules["profiles"])
        for expansion in (9, 10, 11):
            self.assertEqual(self.rules["profiles"][f"Mining:{expansion}"]["statKeys"], ["skill"])

    def test_fishing_keeps_only_actual_item_crafting_recipes(self):
        recipes = {identity: row for identity, row in self.rules["recipes"].items()
                   if row["profession"] == "Fishing"}
        self.assertEqual(set(recipes), {1295922, 1302819, 1235486, 1226157, 1226159, 1226161})
        self.assertTrue(all(recipe["outputIDs"] for recipe in recipes.values()))

    def test_native_cast_time_stays_offline_without_runtime_projection_fields(self):
        native = next(row for row in self.source["recipeRouting"]["spells"] if row["spellID"] == 1230867)
        self.assertGreater(native["baseDuration"], 0)
        self.assertEqual(native["baseDuration"], native["castTimeSource"]["baseMilliseconds"] / 1000)
        self.assertGreater(native["castTimeSource"]["spellCastTimesID"], 0)
        self.assertNotIn("baseDuration", self.rules["recipes"][1230867])
        self.assertNotIn("baseDurationSource", self.rules["recipes"][1230867])

    def test_discovery_only_decay_perk_does_not_create_materials(self):
        effects = [effect for effect in self.all_effects() if effect["entryID"] == 24528]
        self.assertTrue(any(entry["entryID"] == 24528 for node in self.source["nodes"]
                            for milestone in node["milestones"] for entry in milestone["entries"]))
        self.assertEqual(effects, [], "Inert recipe-discovery controls do not become material output handlers")

    def test_mystic_loot_context_is_excluded_from_processing(self):
        for entry in (87397, 87396):
            effects = [effect for effect in self.all_effects() if effect["entryID"] == entry]
            self.assertEqual(effects, [])

    def test_secondary_professions_have_parameters_without_fictitious_trees(self):
        self.assertEqual(len(self.rules["profiles"]), 30)
        self.assertEqual(len(self.rules["professionParameters"]), 13)
        for expansion in (9, 10, 11):
            cooking = self.rules["profiles"][f"Cooking:{expansion}"]
            self.assertNotIn(f"Fishing:{expansion}", self.rules["profiles"])
            self.assertEqual(cooking["nodes"], {})
            self.assertIn("multicraft", cooking["statKeys"])

    def test_compilation_is_deterministic_and_carries_no_sample_counts(self):
        rebuilt, audit = MODULE.build(self.source)
        self.assertEqual(rebuilt, self.rules)
        self.assertEqual(audit, self.audit)
        for effect in self.all_effects():
            self.assertNotIn("samples", effect)
            self.assertNotIn("casts", effect)

    def test_unquantified_descriptions_never_supply_numeric_bonuses(self):
        effects = list(self.all_effects())
        unsupported = [effect for effect in effects if effect.get("numericUnsupported")]
        self.assertTrue(unsupported)
        for effect in unsupported:
            self.assertEqual(effect["amount"], 0, effect)
        unresolved = [effect for effect in effects if effect.get("requiresSemanticReview")]
        self.assertTrue(all(effect.get("numericUnsupported") for effect in unresolved))


if __name__ == "__main__":
    unittest.main()
