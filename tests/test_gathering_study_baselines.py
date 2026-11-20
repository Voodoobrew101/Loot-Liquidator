"""Native-world identity and denominator tests; all study rows are fixtures."""
import copy
import importlib.util
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
SPEC = importlib.util.spec_from_file_location("gathering_study_baselines", ROOT / "tools/gathering_study_baselines.py")
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class GatheringStudyBaselineTests(unittest.TestCase):
    def row(self, **values):
        result = {"id": "fixture-a", "type": "drop", "method": "Gather", "profession": "Herbalism",
            "expansionID": 11, "recipeID": 1223138,
            "nativeTarget": {"kind": "gameobject", "id": 987654, "zoneID": 2400, "name": "Fixture herb node"},
            "studyKey": "fixture-cohort", "source": {"url": "https://example.test/gather-study", "author": "Fixture"},
            "completedOperations": 10, "outputItemID": 236776, "totalQuantity": 30,
            "sourceProfile": {"skill": 50, "preSpecializationSkill": 50, "stats": {"finesse": {"percent": 10}}, "specializationPoints": {}}}
        result.update(values)
        return result

    def build(self, rows):
        return MODULE.compile_rows(rows, {236776, 236777})

    def target(self, result):
        self.assertEqual(len(result["gatheringTargets"]), 1)
        return next(iter(result["gatheringTargets"].values()))

    def test_world_identity_is_never_required_to_be_an_item(self):
        target = self.target(self.build([self.row()]))
        self.assertEqual(target["nativeTarget"], {"kind": "gameobject", "id": 987654, "zoneID": 2400})
        self.assertEqual(target["nativeTargetID"], "gameobject:987654:zone:2400")
        self.assertNotIn("inputItemID", target)
        self.assertEqual(target["baseline"]["materials"][0]["expectedQuantity"], 3)
        self.assertEqual(target["baseline"]["reportedCompletedOperations"], 10)

    def test_input_item_id_cannot_replace_native_target(self):
        row = self.row(inputItemID=987654)
        del row["nativeTarget"]
        result = self.build([row])
        self.assertFalse(result["gatheringTargets"])
        self.assertIn("inputItemID is not", " ".join(result["review"]["rows"][0]["reasons"]))

    def test_only_output_ids_are_validated_in_native_item_namespace(self):
        result = self.build([self.row(outputItemID=987654)])
        self.assertFalse(result["gatheringTargets"])
        self.assertIn("Output item ID", " ".join(result["review"]["rows"][0]["reasons"]))

    def test_same_original_cohort_copy_does_not_add_operations(self):
        first = self.row()
        second = self.row(id="copied-row")
        target = self.target(self.build([first, second]))
        self.assertEqual(target["baseline"]["reportedCompletedOperations"], 10)
        self.assertEqual(len(target["baseline"]["materials"]), 1)
        review = self.build([first, second])["review"]
        self.assertEqual(review["summary"]["MERGED_ORIGINAL_COHORT_COPY"], 1)

    def test_two_materials_share_one_denominator_not_twenty_operations(self):
        second = self.row(id="fixture-b", outputItemID=236777, totalQuantity=5)
        target = self.target(self.build([self.row(), second]))
        self.assertEqual(target["baseline"]["reportedCompletedOperations"], 10)
        self.assertEqual([row["expectedQuantity"] for row in target["baseline"]["materials"]], [3, .5])

    def test_unknown_denominator_is_not_fabricated_for_a_reported_mean(self):
        row = self.row(expectedQuantity=2.75)
        del row["completedOperations"];del row["totalQuantity"]
        target = self.target(self.build([row]))
        self.assertNotIn("reportedCompletedOperations", target["baseline"])
        self.assertIsNone(target["baseline"]["materials"][0]["reportedCompletedOperations"])
        self.assertEqual(target["baseline"]["materials"][0]["expectedQuantity"], 2.75)
        self.assertNotIn("samples", target["baseline"])

    def test_nominal_counts_ranges_and_hit_percentages_do_not_become_mean_yields(self):
        nominal = self.row(denominatorBasis="nominal input equivalents")
        range_only = self.row(dropChance=.5, minSeen=1, maxSeen=3)
        del range_only["totalQuantity"]
        result = self.build([nominal, range_only])
        self.assertFalse(result["gatheringTargets"])
        self.assertEqual(result["review"]["summary"]["HELD_WORLD_STUDY"], 2)

    def test_zero_output_and_single_operation_have_no_minimum_count_gate(self):
        target = self.target(self.build([self.row(completedOperations=1, totalQuantity=0)]))
        self.assertEqual(target["baseline"]["materials"][0]["expectedQuantity"], 0)
        self.assertEqual(target["baseline"]["reportedCompletedOperations"], 1)

    def test_conflicting_same_cohort_output_is_held_not_averaged(self):
        result = self.build([self.row(), self.row(id="conflict", totalQuantity=40)])
        self.assertFalse(result["gatheringTargets"])
        self.assertEqual(result["review"]["summary"]["HELD_CONFLICTING_COHORT_OUTPUT"], 2)

    def test_explicit_unverified_cast_count_is_not_used(self):
        result = self.build([self.row(castsVerified=False)])
        self.assertFalse(result["gatheringTargets"])

    def test_profile_or_cohort_contexts_remain_separate(self):
        changed = self.row(id="fixture-b")
        changed["sourceProfile"] = copy.deepcopy(changed["sourceProfile"])
        changed["sourceProfile"]["stats"]["finesse"]["percent"] = 20
        result = self.build([self.row(), changed])
        self.assertEqual(len(result["gatheringTargets"]), 2)
        self.assertEqual({row["baseline"]["reportedCompletedOperations"] for row in result["gatheringTargets"].values()}, {10})

    def test_fishing_zone_and_creature_targets_keep_typed_namespaces(self):
        fish = self.row(id="fish", method="Fish", profession="Fishing", recipeID=None,
                        nativeTarget={"kind": "fishing-zone", "id": 2400})
        skin = self.row(id="skin", method="Skin", profession="Skinning", recipeID=None,
                        nativeTarget={"kind": "creature", "id": 12345})
        result = self.build([fish, skin])
        self.assertEqual({target["nativeTarget"]["kind"] for target in result["gatheringTargets"].values()}, {"fishing-zone", "creature"})

    def test_unknown_or_partial_source_profile_is_an_explicit_confidence_zero_assumption(self):
        target = self.target(self.build([self.row(sourceProfile={"skill": 50})]))
        self.assertTrue(target["sourceProfileAssumed"])
        self.assertEqual(target["baseline"]["confidence"], 0)
        self.assertEqual(target["sourceProfile"], {"skill": 50})

    def test_nonworld_processing_is_not_reinterpreted_as_world_evidence(self):
        result = self.build([{"id": "ore", "method": "Prospect", "inputItemID": 236776, "outputItemID": 236777}])
        self.assertFalse(result["gatheringTargets"])
        self.assertEqual(result["review"]["summary"]["nonWorldRows"], 1)

    def test_build_preparation_registers_dedicated_native_target_generator(self):
        import prepare_build_research
        commands = prepare_build_research.command_plan("python")
        self.assertIn(["python", "tools/gathering_study_baselines.py"], commands)


if __name__ == "__main__":
    unittest.main()
