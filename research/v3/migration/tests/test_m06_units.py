#!/usr/bin/env python3
"""M06: units, denominators and cast-basis weighting (S16, PLAN section 3 rule 2).

The rule under test (research/v3/tools/build_estimates.py, row_use / group_unit):
  * every estimate is per cast of its group's unit: prospecting 5 (mechanics G1), otherwise the smallest
    batch any of the group's rows states;
  * reported casts (or no castsBasis) in that unit count fully toward the chance and the average;
  * countedFromInputs / nominalEquivalent / derived casts, casts counted from inputsProcessed and casts
    converted from another batch size count fully toward the average and at EQUIVALENT_CAST_WEIGHT
    toward the chance (its estimate and its confidence);
  * a per-cast chance from another batch size is left out (not convertible); averages convert per input;
  * refunds never change a cast count; reference rows never reach study counts.

Run from the repository root:
  python3 -m unittest discover -s research/v3/migration/tests -v
"""
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
import build_estimates as b  # noqa: E402
from test_build_estimates import Fixture, drop  # noqa: E402

W = b.EQUIVALENT_CAST_WEIGHT
MILL = ("Mill", "1001", 2001)


def mill(rid, **kw):
    kw.setdefault("method", "Mill")
    return drop(rid, **kw)


class Bases(Fixture):
    """One test per castsBasis value."""

    def pair(self, basis, **kw):
        reported = drop("r", casts=100, castsWithDrop=10, totalQuantity=20)
        other = drop("o", casts=100, castsWithDrop=50, totalQuantity=80, castsBasis=basis, **kw)
        return self.one([reported, other])

    def test_reported_counts_fully(self):
        e = self.pair("reported")
        self.assertAlmostEqual(e["chance"], 60 / 200)
        self.assertAlmostEqual(e["average"], 100 / 200)
        self.assertEqual(e["studyCasts"], 200)

    def test_absent_basis_counts_as_reported(self):
        # Agent records carry no castsBasis: same rule, read as reported (the field decides, not the folder).
        e = self.one([drop("r", casts=100, castsWithDrop=10), drop("o", casts=100, castsWithDrop=50)])
        self.assertAlmostEqual(e["chance"], 0.3)

    def test_counted_from_inputs_full_average_reduced_chance(self):
        e = self.pair("countedFromInputs", inputsProcessed=500)
        self.assertAlmostEqual(e["chance"], (10 + 50 * W) / (100 + 100 * W), places=4)
        self.assertAlmostEqual(e["average"], 100 / 200)       # average: full weight
        self.assertEqual(e["studyCasts"], 200)
        self.assertIn("casts counted from inputs or equivalents", e["basis"])

    def test_nominal_equivalent_full_average_reduced_chance(self):
        e = self.pair("nominalEquivalent")
        self.assertAlmostEqual(e["chance"], (10 + 50 * W) / (100 + 100 * W), places=4)
        self.assertAlmostEqual(e["average"], 100 / 200)

    def test_nominal_equivalent_casts_are_five_input_units_whatever_the_batch_says(self):
        # 58 imported mass-milling rows say inputsPerCast 20 while casts = inputs / 5 (old pipeline).
        r = mill("n", casts=640, inputsProcessed=3200, inputsPerCast=20, castsBasis="nominalEquivalent", totalQuantity=64)
        self.assertEqual(b.row_unit(r), 5)
        e = self.one([r, mill("s", casts=10, totalQuantity=1)], key=MILL)
        self.assertEqual(e["inputsPerCast"], 5)
        self.assertEqual(e["studyCasts"], 650)
        self.assertAlmostEqual(e["average"], 65 / 650)

    def test_derived_basis_reduced_chance(self):
        e = self.pair("derived")
        self.assertAlmostEqual(e["chance"], (10 + 50 * W) / (100 + 100 * W), places=4)

    def test_reduced_weight_lowers_confidence_of_a_derived_chance(self):
        # totals only, so the chance is estimated from the average; confidence must follow the weight.
        rep = self.one([drop("a", casts=400, totalQuantity=40)])
        eq = self.one([drop("a", casts=400, totalQuantity=40, castsBasis="nominalEquivalent")])
        self.assertEqual(rep["chance"], eq["chance"])
        self.assertEqual(rep["average"], eq["average"])
        self.assertLess(eq["confidence"], rep["confidence"])
        self.assertEqual(eq["confidence"], b.confidence(eq["chance"], 400 * W) // 2)

    def test_same_rule_for_imported_and_agent_rows(self):
        kw = dict(casts=200, totalQuantity=30, castsWithDrop=25, castsBasis="countedFromInputs", inputsProcessed=1000)
        imported = drop("import-study-1", _file="research/v3/evidence/imported/old-studies.jsonl", **kw)
        agent = drop("dragonflight-1", _file="research/v3/evidence/dragonflight/x.jsonl", **kw)
        self.assertEqual(b.row_use(imported, 5), b.row_use(agent, 5))
        self.assertEqual({k: v for k, v in self.one([imported]).items()},
                         {k: v for k, v in self.one([agent]).items()})


class Denominators(Fixture):
    def test_casts_counted_from_inputs_processed(self):
        r = drop("t", inputsProcessed=1000, inputsPerCast=5, totalQuantity=50)
        use = b.row_use(r, 5)
        self.assertEqual(use["average"], (200, 50))
        self.assertEqual((use["weight"], use["reasons"]), (W, ["castsFromInputs"]))
        e = self.one([r])
        self.assertEqual(e["studyCasts"], 200)
        self.assertAlmostEqual(e["average"], 0.25)

    def test_total_without_any_input_count_has_a_reason(self):
        use = b.row_use(drop("t", totalQuantity=300, notes="10,000 ore, not casts"), 5)
        self.assertEqual((use["chance"], use["average"], use["reasons"]), (None, None, ["totalWithoutCasts"]))

    def test_inputs_purchased_alone_gives_no_casts(self):
        res, _ = self.build([drop("t", inputsPurchased=1000, totalQuantity=50)])
        self.assertEqual(res, {})

    def test_hits_without_casts_have_a_reason(self):
        self.assertEqual(b.row_use(drop("t", castsWithDrop=12), 5)["reasons"], ["hitsWithoutCasts"])


class Refunds(Fixture):
    def test_refunds_do_not_change_counted_casts(self):
        plain = drop("a", inputsProcessed=1000, totalQuantity=50)
        refunded = drop("a", inputsProcessed=1000, inputsRefunded=150, totalQuantity=50)
        self.assertEqual(b.row_use(plain, 5), b.row_use(refunded, 5))
        self.assertEqual(self.one([refunded])["studyCasts"], 200)

    def test_reported_casts_with_refunds_count_fully(self):
        e = self.one([drop("a", casts=200, castsWithDrop=40, inputsRefunded=150, castsBasis="reported")])
        self.assertEqual(e["studyCasts"], 200)
        self.assertEqual(e["confidence"], b.confidence(0.2, 200))


class Units(Fixture):
    def test_mass_mill_normalized_per_input(self):
        mass = mill("m", casts=50, inputsPerCast=20, averageShown=6.0, averagePer="cast", castsBasis="reported")
        single = mill("s", casts=100, inputsPerCast=5, totalQuantity=150)
        e = self.one([mass, single], key=MILL)
        self.assertEqual(e["inputsPerCast"], 5)
        self.assertEqual(e["studyCasts"], 300)                         # 50 mass mills = 200 five-herb mills
        self.assertAlmostEqual(e["average"], (6.0 / 4 * 200 + 150) / 300)
        self.assertIn("converted to 5-input casts", e["basis"])

    def test_mixed_batch_chance_from_other_batch_is_left_out(self):
        mass = mill("m", casts=50, inputsPerCast=20, castsWithDrop=45, totalQuantity=300)
        single = mill("s", casts=100, inputsPerCast=5, castsWithDrop=30, totalQuantity=150)
        e = self.one([mass, single], key=MILL)
        self.assertAlmostEqual(e["chance"], 0.3)                       # only the five-herb mills measure it
        self.assertAlmostEqual(e["average"], 450 / 300)
        self.assertIn("1 chance values from other batch sizes left out", e["basis"])
        self.assertIn("chanceNotConvertible:20->5", b.row_use(mass, 5)["reasons"])

    def test_per_input_averages_use_the_group_unit(self):
        per_input = drop("a", casts=None, inputsPerCast=None, averageShown=0.05, averagePer="input")
        per_1000 = drop("b", casts=None, inputsPerCast=None, averageShown=50, averagePer="1000 inputs")
        self.assertAlmostEqual(self.one([per_input])["average"], 0.25)   # prospecting: 5 ore (G1)
        self.assertAlmostEqual(self.one([per_1000])["average"], 0.25)

    def test_per_input_average_without_any_batch_has_a_reason(self):
        r = mill("a", inputsPerCast=None, averageShown=0.2, averagePer="input")
        res, _ = self.build([r])
        self.assertEqual(res, {})
        self.assertEqual(b.row_use(r, None)["reasons"], ["averageNoBatch:input"])

    def test_midnight_ten_herb_unit(self):
        ten = mill("t", casts=100, inputsPerCast=10, totalQuantity=1300)
        nominal = mill("n", casts=200, inputsPerCast=10, castsBasis="nominalEquivalent", totalQuantity=1200)
        e = self.one([ten, nominal], key=MILL)
        self.assertEqual(e["inputsPerCast"], 10)
        self.assertEqual(e["studyCasts"], 200)                         # 200 five-herb equivalents = 100 mills
        self.assertAlmostEqual(e["average"], 2500 / 200)

    def test_prospecting_unit_is_five_without_a_stated_batch(self):
        self.assertEqual(b.group_unit("Prospect", [drop("a", inputsPerCast=None)]), 5)
        self.assertIsNone(b.group_unit("Mill", [mill("a", inputsPerCast=None)]))

    def test_unchanged_when_every_row_shares_the_unit(self):
        rows = [drop("a", casts=100, castsWithDrop=20, totalQuantity=30),
                drop("b", casts=50, averageShown=0.1, averagePer="input")]
        e = self.one(rows)
        self.assertAlmostEqual(e["average"], (30 + 0.5 * 50) / 150, places=4)
        self.assertNotIn("converted", e["basis"])


class References(Fixture):
    def test_reference_rows_never_reach_study_counts(self):
        ref = drop("r", sourceKind="reference", casts=1000, castsWithDrop=300, inputsProcessed=5000, totalQuantity=400,
                   castsBasis="countedFromInputs", percentShown=30, percentMeaning="perCast")
        e = self.one([ref, drop("a", casts=20, castsWithDrop=2)])
        self.assertEqual((e["studyCasts"], e["studies"], e["referenceValues"]), (20, 1, 1))
        alone = self.one([ref])
        self.assertTrue(alone["basis"].startswith("starting guess only"))
        self.assertEqual(alone["studyCasts"], 0)

    def test_reference_average_converted_and_other_batch_chance_left_out(self):
        mass_ref = mill("r", sourceKind="compiled-research", inputsPerCast=20, averageShown=2.0, averagePer="cast",
                        percentShown=90, percentMeaning="perCast")
        single_ref = mill("t", sourceKind="tsm-table", inputsPerCast=5, averageShown=0.6, averagePer="cast",
                          percentShown=30, percentMeaning="perCast")
        e = self.one([mass_ref, single_ref], key=MILL)
        self.assertAlmostEqual(e["average"], (0.5 + 0.6) / 2)
        self.assertAlmostEqual(e["chance"], 0.3)


if __name__ == "__main__":
    unittest.main()
