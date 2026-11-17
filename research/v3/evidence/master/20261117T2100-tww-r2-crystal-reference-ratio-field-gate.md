# TWW rank-2 Refulgent Crystal: cumulative Looter counts vs reference-only field gate — 2026-11-17T21:06:53.450Z

**Scope:** new manager-only source-to-compiler review of the War Within worker's three 2026-11-17T2034 reference rows. No new independent experiment, actual Gold EV, addon import, synthetic-engine execution or live WoW proof. Do not change owner `implementation/usable-data-tooltips` or immutable `4df9ae8`.

## Original numeric identities retained

| Disenchanted source input | Output | Looter material occurrences / reported input events | Arithmetic source-row ratio | Context |
|---|---|---:|---:|---|
| 228870 Underboss's Tailored Mantle (cloth shoulder) | 219954 Refulgent Crystal rank 2 | 50/114 | 43.860% | cumulative source table; patch/skill/ilvl-at-cast unknown |
| 237545 Discarded Nutrient Shackles (plate wrist) | 219954 rank 2 | 25/56 | 44.643% | same limitations |
| 212453 Skyterror's Corrosive Organ (trinket) | 219954 rank 2 | 50/131 | 38.168% | same limitations |

Evidence: [original three worker rows](../war-within/2026-11-17T2034-new-r2-crystal-original-itemside-identities.jsonl), exact original source [219954 reverse-output table](https://www.wowhead.com/item=219954/refulgent-crystal). Indexed [12.1.7 PTR](https://www.wowhead.com/ptr/item=219954/refulgent-crystal) shows 228870 at 50/114 and 237545 at 25/56; indexed [12.1.5 PTR](https://www.wowhead.com/ptr-2/item=219954/refulgent-crystal) shows 212453 at 50/131. These mirrors corroborate displayed rows, **not three independent cohorts, exact LIVE epoch, or current Retail eligibility**. Historical ratios are descriptive of the source table only, not calibrated per-cast material probabilities.

## New compiler-field disposition

The current `research/v3/tools/build_estimates.py` explicitly separates `sourceKind=reference` from measured studies (the `REFERENCE_KINDS` / `is_study_row` gate). Its reference probability prior `ref_p_rows` reads **only `chance_from_percent`**, which requires a non-null `percentShown` and `percentMeaning=perCast`; its expected-quantity prior `ref_e_rows` reads `unit_average` from `averageShown` with valid units. All three newly reported reference rows have `casts` and `castsWithDrop` but **no `percentShown`, `averageShown`, `totalQuantity`, histogram or stated positive stack units**. Thus those raw ratios do not by themselves create a reference prior or expected-value estimate in this compiler and can receive `reference:noUsableValue` if otherwise placed and unsuperseded. This is a concrete **usable-looking original count / non-admitted reference field** disposition, not evidence of a broken current addon tooltip: owner integration uses a separately pinned corpus, and full compiler/engine has not been run on the new rows.

A deliberately proposed conversion of a cumulative `50/114` to `percentShown=43.86 perCast` would falsely elevate unverified source-pool denominators and epochs into supposedly comparable study-like rates. Do **not** make that automatic change. Source metadata/quality and cited original numerator/denominator can be shown as labeled provenance, but there is no supported unconditional mean to price, no known player profession context, no same-build original output-event histogram and no confirmed current-Retail recommendation.

## Validation / next action

**58/58 deterministic in-process JavaScript field/ratio/source-text assertions passed**, checking three worker records (blob `4dcf686106f5e0e2ec0faf3aadf79c1294f048fb`) and the exact research estimator source (blob `0b09b553fef4214af8aaa93f1c85061956643711`). This is *static code inspection*, **not** running Python estimation, Lua, the addon valuation/formatter or WoW. Existing source originals remain unchanged.

Worker T0048 keeps original-source ownership. Next highest-value step is to obtain a genuinely original single-build `228870`/`237545`/`212453` disenchant event export with item-version/at-cast ilvl, eligible profession context, exact rank-2 output item ID, stack quantities including 0 outcomes, and independent provenance; then validate conditional E and real-engine selection on the owner branch through review. If only the cumulative Looter table exists, retain as **gap-only** source field with explicit `source epoch unknown / quantity unknown` and do not multiply hit ratio by a fabricated yield-1 for gold value.
