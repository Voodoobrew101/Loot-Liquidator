# Loot Liquidator Legacy — batch 002 independent historical evidence audit (2026-10-28)

**Assignment:** 2026-10-28-batch002-legacy; research branch only; 30 DISTINCT assigned stable keys, all checked against NEVER_EXAMINED in the latest master ledger before this submission. **No production or master-owned files changed.**

## Summary
- **18 Shadowlands source-output records + 12 source profiles** examined, 30 first-pass candidate reviews pending master acceptance.
- **8 canonical JSONL cohorts** preserved: 6 original 2020 Shadowlands herb studies, 2022 First Flower, and 2019 Zin'anthid, totaling **22 mapped output totals** (6×3 + 3 + 1). None contain per-cast hit/zero histograms.
- The November 25 2020 Reddit post is titled "20k" but its six listed denominators sum to **23,720 herbs** (8360+3200+5900+2220+2400+1640), not 20,000. Normalize each herb independently; do NOT divide pooled totals by 20,000.
- **Zin'anthid (168487) is an empty `gd.mill` candidate profile** despite a 2019 player report of **30,356 herbs → 18,171 Maroon Pigment (168662)**; independently corroborated output identity from Wowhead and Icy Veins. Historical E per five herbs = **2.992983265**, per twenty = **11.971933061**. This is a NEW research candidate only; do not silently populate production.
- The 2022 **4,000 First Flower** study gives 972 Umbral, 1,031 Luminous, 1,984 Tranquil; the existing three five-herb EV rows match exactly.
- **15 of 18 assigned Shadowlands output records** differ from the independent 2020/2022 source cohort beyond 1e-6; these are **historical cross-study differences, not approved corrections**. (The previous GameData values often mirror Melch1337's rounded per-100-herb table.)
- WoD mass mill recipes and Shadowlands mass mill recipes consume **20 herbs**, while `GameData.lua` profiles use **5-herb reference equivalents**; never treat a reference unit as a completed mass-mill cast.

## Source citations and dates
1. **2020-11-25**: Reddit original 6-herb per-input totals: https://www.reddit.com/r/woweconomy/comments/k12a5o
2. **2022-03-07**: Reddit First Flower 4000-herb output table: https://www.reddit.com/r/woweconomy/comments/t8lubc ; independent recipe https://www.wowhead.com/spell=359490/mass-mill-first-flower
3. **2019-08-08**: Reddit Zin'anthid 30356-herb output: https://www.reddit.com/r/woweconomy/comments/cnnagg ; Maroon Pigment item ID https://www.wowhead.com/item=168662/maroon-pigment ; source mapping https://www.icy-veins.com/wow/patch-8-2-inscription-profession-changes
4. **2020-11-27**: independent rounded aggregate Melch1337 source and mass-mill 20-herb recipe: https://www.wowhead.com/spell=311414/mass-mill-vigils-torch
5. WoD mass-mill 20-herb source: https://www.wowhead.com/spell=190383/mass-mill-gorgrond-flytrap ; First Flower spell 359490 source https://www.wowhead.com/spell=359490/mass-mill-first-flower
6. Source code: `GameData.lua` blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`; assignment blob `54b2a838f6a461a9ac688d0d9fe0c0bdc433adea`; original coverage ledger blob `f69b5818584abdf69912aa4438591e2f01f6af05`.

## Assigned output comparisons (unconditional E per FIVE herbs; not per mass cast)
| Herb ID | Output ID | Existing | Independent source | Delta |
|---:|---:|---:|---:|---:|
| 168586 | 173056 | 0.495000 | 0.461017 | -0.033983 |
| 168586 | 173057 | 0.970000 | 1.011017 | 0.041017 |
| 168586 | 175788 | 0.025000 | 0.021186 | -0.003814 |
| 168589 | 173056 | 0.980000 | 1.020312 | 0.040312 |
| 168589 | 173057 | 0.495000 | 0.456250 | -0.038750 |
| 168589 | 175788 | 0.025000 | 0.021875 | -0.003125 |
| 169701 | 173056 | 0.720000 | 0.701555 | -0.018445 |
| 169701 | 173057 | 0.735000 | 0.750000 | 0.015000 |
| 169701 | 175788 | 0.025000 | 0.023325 | -0.001675 |
| 170554 | 173056 | 0.485000 | 0.484234 | -0.000766 |
| 170554 | 173057 | 1.025000 | 1.024775 | -0.000225 |
| 170554 | 175788 | 0.020000 | 0.020270 | 0.000270 |
| 171315 | 173056 | 1.315000 | 1.317073 | 0.002073 |
| 171315 | 173057 | 1.160000 | 1.161585 | 0.001585 |
| 171315 | 175788 | 1.525000 | 1.527439 | 0.002439 |
| 187699 | 173056 | 1.215000 | 1.215000 | 0.000000 |
| 187699 | 173057 | 1.288750 | 1.288750 | 0.000000 |
| 187699 | 175788 | 2.480000 | 2.480000 | 0.000000 |

## Four independent field scores
- `dropChance`: 0/100 for all 18 outputs; **no observed number of casts containing at least one output**.
- `yieldMin`, `yieldMax`: 0/100 for all 18; no positive-hit histograms or proven game extrema.
- `expectedQuantity`: historical source confidence 68/100 (2020 cohort) or 72/100 (First Flower). Exact aggregate arithmetic is independently verified, but patch/context and original casts are unknown. Record confidence = weakest field = **0**.
- Profile rows are **identity/recipe/context audits**, not independent output field score promotions. Their field-score columns intentionally blank.

## QA performed
- Latest master queue contains 30 assigned distinct keys, all **NEVER_EXAMINED** in current central coverage ledger; no duplicate first-pass claim.
- All 18 source-output keys match exact existing GameData input/output mapping; all 12 profile IDs exist in GameData.
- Eight JSONL observation records satisfy canonical required fields, evidence status and numeric domain checks; 22 output totals preserved as nonnegative integers; **completedOperations = null**, because source gives aggregate herb counts rather than explicitly measured completed mass-mill casts.
- Exact normalization check: `reportedTotal * 5 / reportedHerbs`; no chance multiplier, no midpoint, no invented conditional extrema.
- Structural schema fields and required enum checks passed. **Full external JSON Schema validator and in-game client tests not executed**.
- 2019, 2020, 2022 studies are historical; no current Retail 2026 bridge, profession skill, talent/gear context or operation histogram. No >=90 substantiation; no production correction.

## Next exact targets and blockers
1. Master QA should accept/reject these 30 first-pass keys, audit the 2020 "20k" title/23,720 denominator discrepancy and review Zin'anthid (168487 → 168662) for an additive candidate mapping, never auto-ship.
2. Next queue preview: `profile:compiled:mill:171315`, `profile:compiled:mill:187699`; independently validate Nightshade and First Flower recipe IDs and current Retail availability.
3. Prioritize unexamined legacy prospecting/disenchant records in Classic–Legion after master assigns disjoint keys.
4. For >=90: collect actual per-cast output histograms with zero counts, positive integer extrema, build/skill/gear/specialization, and current Retail samples.

**First-pass candidate throughput:** 30 distinct assigned records; cumulative accepted remains master-owned and unchanged by worker. **Current Retail numerical corrections:** 0. **New >=90:** 0. **Main and addon files:** untouched.
