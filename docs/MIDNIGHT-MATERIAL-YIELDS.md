# Midnight pigment and disenchanting quantities

Reviewed 2026-11-06. These source estimates are part of the normal ItemDB build
and tooltip calculation. Original studies and frozen references are retained.

## Compatible pigment totals

The pinned [GoldAdvisorMidnight source data](https://github.com/crystaltech/GoldAdvisorMidnight/blob/5b0b253c7039b2379942951166b0cbb41b525fe3/GoldAdvisorMidnight/Data/RecipesGenerated.lua)
contains an explicit base yield per completed Midnight Milling operation:

| Input, either quality | Nominal input per mill | Output family | Estimated family total |
| --- | ---: | --- | ---: |
| Tranquility Bloom | 10 | Powder Pigment | 13 |
| Argentleaf | 10 | Argentleaf Pigment | 13 |
| Sanguithorn | 10 | Sanguithorn Pigment | 13 |
| Mana Lily | 10 | Mana Lily Pigment | 13 |

Its [pricing derivation](https://github.com/crystaltech/GoldAdvisorMidnight/blob/5b0b253c7039b2379942951166b0cbb41b525fe3/GoldAdvisorMidnight/PricingDerivation.lua)
separates the base quantity from Resourcefulness. The source contains a single
family output with alternative quality IDs, rather than 13 units of each rank.
It does not provide measured cast counts, occurrence probabilities, positive
quantity ranges or a controlled skill comparison. The addon therefore admits it
as a **low-confidence calculator reference**, with confidence 10 and no invented
samples, drop chances or ranges.

The import archives the actual source-data excerpt and derives the coefficient
from its `baseYieldPerCraft` field. It does not execute the archived Lua or borrow
workbook shopping amounts as sample counts. Changing the reviewed source changes
the generated estimate through the existing calculator compiler.

For Powder, Argentleaf and Sanguithorn pigments, the existing exact-input skill
threshold rule can now choose a supported rank and price. Mana Lily's total is
usable as a family reference, while its disputed ordered rank mapping remains
unselected. Reference estimates stay under **Database & Accuracy → Reference
tables and calculators**. The old modeled 4.5-unit milling profiles remain
fallback references; they no longer block the sourced family estimate.

The [pigment research record](../research/mechanics/midnight-pigment-totals-2026-11-06.json)
also retains a separate 12.5-per-mill player estimate and raw herb-batch totals.
Those are not combined with the calculator as independent measured casts.

## Midnight enchanting probabilities and yields

Disenchant observations contribute to their **expansion + rarity + armor/weapon**
category. A studied item's ID is source provenance, not a requirement for using
the research. Matching gear receives the category estimates even if its item ID
has never appeared in a study. Current Midnight research supplies uncommon armor,
rare armor, rare weapons, epic armor and epic weapons. No counted uncommon-weapon
study was found, so that group continues to use its existing eligible references.

The following are individual source observations, before category aggregation:

| Source input/cohort | Output | Chance per disenchant | Average units per disenchant | Positive observed range |
| --- | --- | ---: | ---: | --- |
| Tarnished Dawnlit Sentinel's Cover, 1,485 reported operations | Eversinging Dust R1 | 896/1,485 = 60.34% | 1,838/1,485 ≈ 1.238 | 1–3 |
| Same cohort | Eversinging Dust R2 | 348/1,485 = 23.43% | 693/1,485 ≈ 0.467 | 1–3 |
| Wretched Scholar's Gilded Robe, 318 reported operations | Dawn Crystal R1 | 190/318 = 59.75% | 190/318 ≈ 0.597 | 1 |
| Same cohort | Dawn Crystal R2 | 117/318 = 36.79% | 117/318 ≈ 0.368 | 1 |
| Courtly Wrists, separate 1,000-item max-specialization study | Radiant Shard R1 | Unknown | 629/1,000 = 0.629 | Unknown |
| Same Courtly study | Radiant Shard R2 | Unknown | 660/1,000 = 0.660 | Unknown |

Sources: [Sentinel's Cover](https://www.wowhead.com/item=258931),
[Gilded Robe](https://www.wowhead.com/item=250456),
[Courtly Wrists comment](https://www.wowhead.com/item=239671/courtly-wrists#comments).
The counted Looter rows were retained in the pinned November 1 research snapshot;
the Courtly comment was directly re-read on November 6. Full per-stack counts and
source limitations are in the [enchanting research record](../research/mechanics/midnight-enchanting-yields-2026-11-06.json).

The [category mapping](../database/research/midnight-disenchant-categories.json)
records each source item's default rarity and armor/weapon classification. Catalog
classifications inferred for a historical variant remain provisional; that
uncertainty does not withhold the category estimate. Trinkets use armor class.
Different expansion, rarity and item classes never share a category.

The Courtly source lists seven material-unit totals sharing the same 1,000 casts,
including five bonus-material outputs. It reports maxed Disenchanting Delegate
and Shard Supplier, but no hit counts, histogram, actual skill or item level.
Its rare-armor scope is inferred from that path and the shard results. The same
Courtly item ID can have an epic variant, which receives its epic-armor category.
The max-specialization study is a separate rare-armor reference context; its
means are not combined with ordinary Looter probabilities or treated as measured
specialization multipliers. Ordinary gear uses the pooled ordinary category.
In the Simulated editor, 30 points in both Disenchanting Delegate and Shard
Supplier select that researched max-specialization reference for matching rare
armor. Lower allocations retain the ordinary category; no intermediate yield
curve is invented. Source policy continues to control eligibility.

The research review covers 23 counted Looter cohorts already in the pinned
snapshot. Their reviewed counts enter the category compiler once per study
lineage. Preserved exact-item rows cannot override or add a second copy to the
category estimate. An item-specific exception needs a documented reason and a
supporting source; none were found in this set. New studies that state expansion,
rarity and class join their category without an item-ID allowlist.

The new counted Courtly study enters the existing evidence pipeline, which supports units-only studies
without requiring a made-up probability. Independently published means without
sample sizes can also carry explicitly weak prior support without claiming real
casts. Unknown input variants and source conditions remain documented limitations.
Personal disenchant observations and classified imports also use these categories,
while retaining their existing character, build, profession-context and source
boundaries. Older observations without enough classification metadata remain
available by their original item ID.

## Tooltip behavior and build checks

Existing tooltip levels and profession visibility settings control which rows
appear. At **Breakdown**, the **Show average quantities** setting controls averages
for every method and profile, including disenchanting and hypothetical profiles.
When enabled, a row can show both a chance and a different average: for example,
60.3% occurrence with 1.238 average units. Disabling averages does not change the
research or valuation. When only a mean is known, its chance and range remain
unavailable. Missing research must be addressed through the data pipeline rather
than by bypassing display settings.

Reproducible paths:

- Calculator archive → `tools/reference_calculators.py` → calculator baselines.
- Reviewed Courtly totals → `tools/import_midnight_enchanting.py` → existing
  evidence checker/baseline builder.
- Reviewed disenchant studies and category metadata → `tools/disenchant_categories.py`
  → the same evidence builder → category baselines.
- Baselines → `tools/compile_itemdb.lua` → ItemDB → normal resolver, valuation and
  tooltip renderer.

The tests exercise actual compiled data and normal conversion discovery, source
preferences, quality selection without double-counting family quantities,
rarity/class isolation, cohort separation, and distinct probability/mean display.
