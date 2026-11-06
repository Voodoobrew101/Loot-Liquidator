# Synthetic benchmark and profession research

Reviewed **2026-11-06**. The simulated profession editor retains the named
specialization point sliders from main commit `efeeb8ca1188cd87b5bd3a1f8807eb270ad3df51`.
Sourced point effects now feed the selected baseline, effective recipe skill and
output valuation. There is no additional baseline-output slider in this editor.

## Research to baseline pathway

1. Original studies, corrections, conditions and rate changes live in `research/v3/`.
2. `tools/research_v3_to_baselines.py --refresh` pins those inputs and the research
   calculator in `database/research/v3-snapshot/`; the snapshot records its commit.
3. The pinned calculator produces estimates. The bridge excludes reference tables
   and duplicate Legacy contributions, unresolved item/rank families, unknown
   operation batches and conditional outputs from ordinary baseline values.
4. `database/research-v3-baselines.lua` feeds `tools/compile_itemdb.lua`; generated
   ItemDB records reach `LootLiquidator/Database.lua` for source selection and
   `LootLiquidator/ProfessionModels.lua` for compatible context transformations.

The bridge discounts studies not known to be at minimum skill. The result is a
provisional source estimate, often from mixed or incompletely recorded skill and
specialization conditions. It is **not** a measured unskilled yield. Multiplying it
by an assumed talent bonus may count a bonus already present in the source study.
Original casts, counts, ranks, patch boundaries and conditional outputs must remain
unchanged by benchmark settings.

`MIDNIGHT_MODEL_README.txt` documents an older 0.9.67 low/high manual model. Its
interpolation endpoints are design history, not current validated talent effects.
The mechanics registry also predates the current sourced lower-confidence rule
path; consult executable rule validation in `ProfessionModels.lua` when assessing
which imported rules can run.

## Documented specialization information

The following **Midnight** datamined main tooltips explicitly describe skill per
point. Each linked live page was retrieved on 2026-11-06. These values are skill
bonuses; they supply no universal percentage increase to output quantity.

| Specialization | Wowhead profession trait | Documented scope | Skill per point |
| --- | --- | --- | --- |
| [Proficient Processor](https://www.wowhead.com/profession-trait/proficient-processor-106983) | 106983 | Prospecting, Crushing and reagents | +1 |
| [Prospecting Pro](https://www.wowhead.com/profession-trait/prospecting-pro-106982) | 106982 | Prospecting | +1 |
| [Perfect Milling](https://www.wowhead.com/profession-trait/perfect-milling-109653) | 109653 | Pigment quality | +1 |
| [Disenchanting Delegate](https://www.wowhead.com/profession-trait/disenchanting-delegate-107649) | 107649 | Disenchanting Midnight equipment | +1 |
| [Dust Deliverer](https://www.wowhead.com/profession-trait/dust-deliverer-107648) | 107648 | Uncommon Midnight equipment | +1 |
| [Shard Supplier](https://www.wowhead.com/profession-trait/shard-supplier-107647) | 107647 | Rare Midnight equipment | +1 |

[Crystal Collector](https://www.wowhead.com/profession-trait/crystal-collector-107646)
(107646) describes improved epic disenchanting quality without an explicit numeric
coefficient in its main tooltip. The [Jewelcrafting specialization guide](https://www.wowhead.com/guide/midnight/professions/jewelcrafting-specializations)
reports additional gems at maximum Prospecting Pro investment, without a numeric
proc rate. This guide displays an update date of 2026-02-21 and patch 12.1.5 when
retrieved. Do not translate either description into an invented output multiplier.

Ore-specific diamond traits are
[Copper Consumer](https://www.wowhead.com/profession-trait/copper-consumer-106981),
[Tin-vestigator](https://www.wowhead.com/profession-trait/tin-vestigator-106980),
[Silver Scrapper](https://www.wowhead.com/profession-trait/silver-scrapper-106979) and
[Thorium Thresher](https://www.wowhead.com/profession-trait/thorium-thresher-106978).
They apply to their respective ore families. Their tooltips provide no diamond
drop rate. An unlocked node cannot turn an unknown conditional rate into a known
expectation. The pinned Wago catalog confirms these IDs as the spend nodes used
by the named point sliders. Spend points exclude the separate unlock-entry rank;
older scanned signatures are not assumed to use that convention.

## Profession stats and conflicting older notes

The current [Jewelcrafting build guide](https://www.wow-professions.com/midnight/jewelcrafting-specialization-guide-and-builds)
explicitly excludes Prospecting and Crushing from Multicraft and recommends
Resourcefulness for those operations. This conflicts with the older M11
"likely" entry in `research/v3/mechanics.md` and Wowhead's broad stat listing.
Treat Multicraft eligibility as requiring direct recipe verification; do not
automatically apply it to prospecting from M11.

The [Inscription build guide](https://www.wow-professions.com/midnight/inscription-specialization-guide-and-builds)
also excludes milling from Multicraft. Both sources were retrieved on 2026-11-06;
neither supplies an exact per-proc input-saving formula. The [Enchanting guide](https://www.wowhead.com/guide/midnight/professions/enchanting-specializations)
states that disenchanting uses skill and its dedicated specialization, without
Resourcefulness, Multicraft or Ingenuity effects. Never apply material savings to
disenchanting.

## Named specialization point calculations

Open **Professions (Simulated) → a profession → Advanced**. Existing tree and
branch sliders, stats and buffs remain available. Editing a control selects the
Simulated profile; selecting that profile again preserves the saved allocation.
Only **Reset to minimum** clears it. Scanned character data and profession access
remain independent of the editor.

The existing skill control is **Skill before specialization**. For an operation
with a sourced per-point bonus, effective recipe skill is that input plus the
bonuses from matching nodes. Expansion, method and rarity restrictions apply:
Disenchanting Delegate applies to Midnight gear, while Dust Deliverer adds skill
only for uncommon gear and Shard Supplier only for rare gear. A skill bonus can
cross an exact-input quality threshold captured from Blizzard; it does not imply
an arbitrary percentage increase in quantity. The raw source totals stay intact.

The generated data currently contains 19 scoped skill-per-point rules, four
The War Within gem-replacement rules and one observed Midnight specialization
reference. The [reviewed effect definitions](../database/research/specialization-effects.json)
contain source quotes, pinned code/catalog identities, point bounds, confidence
and held claims. The deterministic path is:

`specialization-effects.json → tools/specialization_effects.py → specialization-effects.lua → ItemDB.specializationRules → profession context/resolver → valuation/tooltip`.

### Gem Finding: multiply the existing material baseline

For The War Within prospecting, each point in Sapphire, Ruby, Onyx or Emerald
adds a **1% replacement chance** for the corresponding uncut gem instead of an
Ambivalent Amber. Each branch allows 20 points. With `A` equal to the selected
Amber mean and `p_color` equal to a branch's points:

- `Amber_simulated = A * (1 - 0.01 * sum(p_color))`.
- `Color_simulated = Color_selected + A * 0.01 * p_color`.

All four branches use the same original Amber reservoir. Total gem units are
conserved; subsequent branches do not compound against a smaller reservoir.
These are unranked TWW uncut gems, so no unverified rank routing is introduced.
Changed means do not supply new occurrence probabilities or conditional ranges.
The original allocation of a mixed research baseline remains an explicit
scenario limitation; it is never rewritten as a zero-point measurement.

### Midnight rare-armor specialization reference

At **30 Disenchanting Delegate points and 30 Shard Supplier points**, the selector
can use the separately researched 1,000-operation max-specialization reference
for the entire Midnight rare-armor category. Its Radiant Shard means are 0.629
and 0.660 units per operation, with five additional reported material means.
Its occurrence probabilities remain unknown. Matching source items and unseen
items use this same category; other rarities, expansions and weapons do not.

The reference remains a distinct cohort. It does not create a linear curve for
intermediate point allocations, and cannot bypass source preferences or
personal-only mode. Resetting the points restores the ordinary category model.

### Unsupported effects and preserved data

A trait that says it grants a chance at extra material without stating the
chance and stack size cannot honestly become a numerical total-yield multiplier.
Such claims remain in the effect export's held list. The independent rating and
percentage controls feed their typed context; an unsupported stat does not gain
an invented recipe effect. Resourcefulness never increases disenchanting output.

Older aggregate `benchmark` values remain readable by the compatibility backend;
the main branch's named point editor does not expose or require those generic
output-level or additional-yield controls. No point slider changes raw casts,
invents samples, raises confidence or grants a profession. Tooltip display and
source settings continue to govern presentation and eligibility.
