# Manager research QA — exact-item gearGroup override and untyped crystal rank alternatives

Checked 2026-11-15 04:07 UTC against research head `76b2cdc1c85e52384926f0b98839c3bdac662cdd`. **Research-only source-to-estimator static audit; no compiler, native Lua, offline gold/tooltip or WoW client run. No new independent source cohort, Retail character eligibility, or verified gold decision.**

## Newly inspected worker evidence

[War Within 03:19 UTC original evidence](../war-within/2026-11-15T0319-living-weapon-epic-de-looter.jsonl) contains **14 source-reported positive occurrence rows from five distinct item-side cumulative Looter tables**, *not* 14 independent experiments: Living Weapon's Chain `237607` (**12** source operations; row hits **9, 3**), Ramparts `237608` (**22**; **12, 6, 2**), Legs `237609` (**23**; **13, 5, 4**), Grips `237611` (**24**; **14, 8, 1**), and Boots `237612` (**8**; **4, 3, 1**). There are **89** source-reported operations across the five item tables; never sum that denominator across material rows or treat it as an independently verified present-build sample. The `237611` index was marked PTR 12.1.5 by its worker; exact live source build, at-cast item bonuses, skill and eligibility remain unknown. These are previously collected worker records, not manager-created measurements.

Each of the 14 rows has a known, distinct `inputItemID` among those five, but also has `gearGroup={expansion:"The War Within", quality:"epic", kind:"armor", itemLevelRange:null}`. Every row has `outputItemID:null`, `outputRank:null`, identical `outputName:"Refulgent Crystal"`, `sourceKind:"reference"`, `castsWithDrop` and `casts`, but **no** `percentShown`, `averageShown`, `totalQuantity`, observed positive stack range or per-cast histogram. Source order is explicitly *not* a quality rank identifier. Sum of displayed material hits being below the denominator in some item tables is not evidence of zero-yield operations, mutually exclusive ranks or unreported material amounts. Source URLs are preserved in the 14 original rows; they were not independently re-opened in this audit.

## Deterministic static compiler handoff: exact gear identity discarded

At current [v3 estimator](../../tools/build_estimates.py) `key_of` (lines ~188–203), the presence of *any* `gearGroup` unconditionally overrides `inputItemID`. Projecting the source rows through that exact key expression produces **one** grouping key across all 14 records, despite **five** source-specific input IDs:

```
("Disenchant", "gear:The War Within:epic:armor", "family:Refulgent Crystal")
```

The output name-based family fallback is the same for all 14 ranked-but-unidentified material alternatives, so rows from separate input items and distinct unknown output qualities lose their identity in the estimate group. This is **additional to** the previously documented missing `gearGroup.itemLevelRange` key; here the source already supplies an **exact item ID which is discarded**. It does **not** prove a currently priced wrong decision: the records are reference-only, with hit counts but no reference numerical `percentShown`/unconditional mean. The current `analyze` reference path (lines ~793–800, ~875–914) recognizes reference `percentShown(perCast)` and `averageShown` but not `castsWithDrop`, yielding `reference:noUsableValue` for each row, not a new valid estimate. It is correct to leave current gold EV and exact ranked fields unknown pending source identity/quantity resolution rather than invent a rate.

The checked-in `research/v3/output/estimates.json` had **zero** matching exact input IDs or above gear-group key at read time, but it is a checked-in artifact, **not proof that a fresh compiler run has occurred on this new evidence**. The one-key projection was calculated against the worker's file and directly inspected Python source; no Python compiler execution was claimed.

## Acceptance / next action for reviewed, disjoint engineering

1. Introduce a narrowly tested identity rule: use a valid exact gear `inputItemID` as the primary discriminator even when `gearGroup` metadata exists; preserve group quality, version, ilvl band and any eligibility conditions as context, with explicit group-key support only for genuinely unidentifiable item classes. Verify existing historical generic groups are not lost.
2. Preserve all three or two same-name crystal **unresolved rank alternatives** per original source item. Do not assign rank by row order, collapse them into a single material result, add their hit counts as exclusive, create zero counts, infer positive stack totals, or treat PTR sources as live Retail.
3. Compare old/current `estimates.json` and `unused.json` with a no-loss original-source fixture and synthetic-price/tooltip field checks **on the owner-designated three-pass branch or a separately reviewed non-overlapping engineering branch**; no manager write to owner integration or production addon. Price only after an output ID/rank or vetted family-pricing policy and defensible unconditional material quantity; do not treat an occurrence count as output quantity.

**Result:** new verified *structural identity and field-admission gaps* in recently added TWW evidence, not new observed drops or a verified numerical recommendation. Source population, uncertain build, rank alternatives and source-reported denominators remain explicit.
