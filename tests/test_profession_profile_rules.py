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

    def test_all_actual_nodes_entries_effects_and_milestones_are_typed(self):
        self.assertEqual(self.audit["summary"]["nodes"], 727)
        self.assertEqual(self.audit["summary"]["entries"], 6275)
        self.assertEqual(self.audit["summary"]["milestones"], 4821)
        self.assertEqual(self.audit["summary"]["unmappedSourceEffects"], 0)
        expected = {(node["nodeID"], entry["entryID"])
                    for node in self.source["nodes"]
                    for entry in node["baseEntries"] + [entry for milestone in node["milestones"] for entry in milestone["entries"]]}
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
            elif effect["mechanism"] == "client-effect-14":
                self.assertEqual((effect["metric"], effect["unit"]), ("craftingSpeed", "percent"))

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
        self.assertTrue(effects)
        self.assertTrue(all(effect["metric"] == "nonOutput" for effect in effects))

    def test_resourcefulness_prose_changes_input_savings_not_drop_quantities(self):
        entry_ids = {24520, 24518, 24516, 24514, 54893, 54891, 54889, 54887, 87415, 87413, 87411, 87409, 124509}
        effects = [effect for effect in self.all_effects() if effect["entryID"] in entry_ids]
        self.assertTrue(effects)
        self.assertTrue(any(effect["metric"] == "resourcefulnessSaved" for effect in effects))
        self.assertFalse(any(effect["metric"] in {"extraOutput", "dropChance", "yieldMultiplier"} for effect in effects))

    def test_specific_loot_relative_chance_does_not_boost_arbitrary_crafting(self):
        effects = [effect for effect in self.all_effects() if effect["entryID"] == 125760]
        drops = [effect for effect in effects if effect["metric"] == "dropChance"]
        self.assertEqual(len(drops), 1)
        effect = drops[0]
        self.assertEqual(effect["amount"], 50)
        self.assertEqual(effect["operator"], "multiply")
        self.assertEqual(effect["scope"]["method"], "Loot")
        self.assertEqual(effect["targetFamily"], "Darkmoon Cards")
        self.assertFalse(effect["baselineOutputFallback"])

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

    def test_gathering_and_overload_have_explicit_scope_and_state(self):
        effects = list(self.all_effects())
        gathering = [effect for effect in effects if effect["scope"].get("method") == "Gather"]
        self.assertTrue(gathering)
        overload = [effect for effect in gathering if effect.get("condition", {}).get("contextFlags", {}).get("overload")]
        self.assertTrue(overload)
        self.assertFalse(any(effect["scope"].get("method") == "Smelt" for effect in overload))
        buffs = [effect for effect in effects if effect["mechanism"] == "conditional-stat-buff"]
        self.assertTrue(any(effect.get("condition", {}).get("requiresActiveBuff") for effect in buffs))
        self.assertTrue(all(effect["condition"]["manualStateKey"] == effect["entryID"] for effect in buffs))

    def test_native_gathering_target_has_only_explicit_unit_prior_not_observed_yield(self):
        target = self.rules["gatheringTargets"][1223138]
        self.assertEqual(target["profession"], "Herbalism")
        self.assertEqual(target["primaryOutputIDs"], [236776, 236777])
        self.assertEqual(target["baseline"]["materials"], [{"id": 236776, "expectedQuantity": 1, "confidence": 0}])
        self.assertEqual(target["nativeDifficultyParameter"], 120)
        self.assertFalse(target["baseline"]["observedYield"])
        self.assertNotIn("samples", target["baseline"])
        self.assertEqual(target["difficultyConfidence"], 0)
        self.assertEqual(target["targetID"], "native-gather-spell:1223138")
        self.assertEqual(target["nativeTargetID"], "spell:1223138")
        self.assertEqual(target["method"], "Gather")
        self.assertEqual(target["label"], "Argentleaf")
        for profession in ("Herbalism", "Mining", "Skinning"):
            for expansion in (9, 10, 11):
                self.assertTrue(any(row["profession"] == profession and row["expansionID"] == expansion
                                    for row in self.rules["gatheringTargets"].values()), (profession, expansion))

    def test_static_cast_time_preserves_native_milliseconds_to_seconds(self):
        recipe = self.rules["recipes"][1230867]
        self.assertGreater(recipe["baseDuration"], 0)
        self.assertEqual(recipe["baseDuration"], recipe["baseDurationSource"]["baseMilliseconds"] / 1000)
        self.assertGreater(recipe["baseDurationSource"]["spellCastTimesID"], 0)

    def test_discovery_only_decay_perk_does_not_create_materials(self):
        effects = [effect for effect in self.all_effects() if effect["entryID"] == 24528]
        self.assertTrue(effects)
        self.assertFalse(any(effect["metric"] in {"extraOutput", "dropChance"} for effect in effects))

    def test_mystic_loot_context_overrides_mention_of_disenchanting_results(self):
        for entry in (87397, 87396):
            effects = [effect for effect in self.all_effects() if effect["entryID"] == entry]
            self.assertTrue(effects)
            self.assertTrue(all(effect["scope"]["method"] == "Loot" for effect in effects))

    def test_secondary_professions_have_parameters_without_fictitious_trees(self):
        self.assertEqual(len(self.rules["profiles"]), 39)
        self.assertEqual(len(self.rules["professionParameters"]), 13)
        for expansion in (9, 10, 11):
            fishing = self.rules["profiles"][f"Fishing:{expansion}"]
            cooking = self.rules["profiles"][f"Cooking:{expansion}"]
            self.assertEqual(fishing["nodes"], {})
            self.assertEqual(cooking["nodes"], {})
            self.assertNotIn("multicraft", fishing["statKeys"])
            self.assertIn("multicraft", cooking["statKeys"])

    def test_compilation_is_deterministic_and_carries_no_sample_counts(self):
        rebuilt, audit = MODULE.build(self.source)
        self.assertEqual(rebuilt, self.rules)
        self.assertEqual(audit, self.audit)
        for effect in self.all_effects():
            self.assertNotIn("samples", effect)
            self.assertNotIn("casts", effect)


if __name__ == "__main__":
    unittest.main()
