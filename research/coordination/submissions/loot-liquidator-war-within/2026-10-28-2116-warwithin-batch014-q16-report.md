# Loot Liquidator — The War Within Batch014 research submission
**2026-10-28 · queue revision 16 · branch `research/processing-confidence` · worker-only additive evidence.**

## P0: Exact assignment and meaningful new eligibility evidence

**35/35 exact assigned keys audited**: 13 TWW prospecting outputs, 14 master-directed Midnight overflow outputs, 8 fixed smelting recipes. **No newly discovered legitimate output mappings and no new current-Retail measured cast outcomes.** Eight distinct expansion-specific minimum Mining skill floors were recovered from Retail recipe/item pages; all eight smelting operations require a forge and the learned recipe. Seven are trainer recipes; **Hardened Khorium spell 46353 requires the rare BoP item 35273 Study of Advanced Smelting from Sunwell Plateau**, requiring Outland Mining 75 to learn. A miner having 75 skill is NOT sufficient to assume the spell is known. This is a material eligibility correction for the master candidate compiler. [Item 35273](https://www.wowhead.com/item=35273/study-of-advanced-smelting).

| Recipe spell → output ID | Exact DIRECT reagent vector | Minimum expansion Mining skill | Acquisition | Fixed output |
|---|---|---|---|---:|
| 102167 → 72095 | 72094 ×2 + 72103 ×2 | Pandaria Mining 75 | trainer | 1 |
| 2659 → 2841 | 2840 ×1 + 3576 ×1 | Classic Mining 50 | trainer | 2 |
| 29356 → 23445 | 23424 ×2 | Outland Mining 1 | trainer | 1 |
| 29360 → 23448 | 23445 ×3 + 23447 ×2 | Outland Mining 50 | trainer | 1 |
| 3569 → 3859 | 3575 ×1 + 3857 ×1 | Classic Mining 125 | trainer | 1 |
| 46353 → 35128 | 23449 ×3 + 23573 ×1 | Outland Mining 75 | Sunwell rare Study of Advanced Smelting item 35273 | 1 |
| 55208 → 37663 | 41163 ×3 + 35624 ×1 + 35627 ×1 + 36860 ×1 | Northrend Mining 75 | trainer | 1 |
| 74537 → 53039 | 52186 ×10 + 52327 ×4 | Cataclysm Mining 50 | trainer | 1 |

Source: [Retail recipe pages](https://www.wowhead.com/spell=102167/smelt-trillium) and `GameData.lua` exact direct reagent vectors. Do NOT mistake nested alternative production chains shown on Wowhead for additional direct recipe reagents. **Fel Iron 29356 consumes a single reagent type (Fel Iron Ore 23424 ×2), not two reagent types.** All eight require full reagent-vector accounting and learned-spell eligibility. Seven are genuinely multi-type; the single-reagent Fel Iron still needs two units. None was inserted into the single-input compiler, and current 2026 in-game learn/cast behavior is unverified.

## P1: Four independent output fields

- **13 TWW rank-2 ore output rows:** The original PeaEsk comment reports **100 ore per ore type, not 100 actual prospecting casts**. The 13 archived source means are normalized to **20 nominal five-ore equivalents** per ore cohort. Actual completed casts, Resourcefulness refunds, patch, specialization and effective skill are unknown. Existing GameData `1-exp(-E)` values are Poisson occurrence *proxies*, not observed P(hit). Therefore each assigned dropChance, positive conditional yieldMin and yieldMax remains **null**, while historical gross-ore-normalized E is retained at source-context confidence 48/100 (not promoted to a current unskilled completed-cast baseline).
- **14 Midnight overflow output rows:** Archived JD3K 50-ore rank-2 observations and guide transfers do not supply per-cast zero-inclusive hits or positive conditional ranges. All four neutral baseline fields remain **null** for these rows; source-context low/high expected-quantity alternatives remain in the audit as historical *E references*, **not** min/max yields or necessarily ordered numerical bounds. The `input_rank=0` metadata for ore 237366 is a source sentinel, not quality rank zero.
- **8 fixed smelts:** 32 previously known provisional numeric claims: P=1, positive min=max=E=1 (except Bronze 2659: 2). They are conditional on an eligible, learned, successful cast, not independently measured 2026 observations. Evidence support for fixed amounts remains 80/100; minimum-skill evidence from live Retail recipe pages is separately supported at 82/100 (Hardened Khorium item 35273 at 84/100). These are **eight new skill-floor source reconciliations**, not 32 new numeric measurements.

## P2: Decision-risk reconciliation

For Aqirite rank-2, the independent October 14 2024 10,000-ore experiment reported historical gross-ore-equivalent Glittering Glass 213399 E=0.1375 and Handful of Pebbles 213398 E=0.3625 per five ore. The unmatched PeaEsk 100-ore cohort reported E=0.65 and 1.75, respectively: approximately **4.73× and 4.83×**. Neither cohort provides matched patch/build, actual cast denominator, specialization and Resourcefulness context. Do not infer a numeric hotfix coefficient or claim a current gold-optimal action flip. [Original October 14 study](https://www.reddit.com/r/woweconomy/comments/1g350pq) · [PeaEsk comment](https://www.wowhead.com/spell=434018/algari-prospecting).

The smelting eligibility and reagent-vector gap can also reverse a gold decision: pricing only one ingredient of a two-plus-reagent recipe systematically understates cost. No current AH price quote was obtained.

## Source ancestry and learning

Reused archived PeaEsk three ore cohorts as **one author's original study family** and JD3K as **one original study family**, avoiding duplicate external fetches. Purposefully revisited eight previously PARTIAL recipe sources to resolve exact minimum expansion Mining skill, forge and acquisition. The item 35273 source independently clarifies rare-learned recipe gating. All 10 source-review events remain PARTIAL pending 2026 client validation; none was marked FULLY_ANALYZED merely because a page was discovered. No self-awarded reward points or inflated evidence confidence. This directly addresses master batch013 `RECIPE_VECTOR_GUARD` feedback.

## Master handoff — exact next targets

1. Implement **full reagent vectors and learned-recipe/forge/skill gating** in the research compiler; handle rare item 35273 explicitly; validate all eight spells in 2026 Retail client before release.
2. Collect actual zero-inclusive prospecting casts for **210931→212498/213398/213399**, **210934→212498/212505/212508/213398/213399**, and **210937→212495/212498/212511/213398/213399**. Log actual casts, all zero outcomes, ore quality, profession profile, Resourcefulness refunds, and patch.
3. Master-assigned Midnight overflow: **237364→242786/242788**, **237365→242553/242554/242612/242613/242786/242788**, **237366→242610/242611/242612/242613/242786/242788**. Require rank-specific outputs and cast denominators.
4. Prioritize Aqirite valuation differences only after patch and denominator reconciliation; no fabricated probability or universal coefficient.

## Status and tests

Master baseline (unchanged): **976 provisional mappings / 159 input IDs; 791 four-field complete; 396 unknown numeric cells** (P172/min68/max68/E88); **0 current unskilled baselines verified**. Source inventory **1643/1737** first-pass reviewed is not exhaustive Retail coverage. This batch submits no newly admitted mappings and makes no shared or production edits. Static 35-key/source-vector/arithmetic QA and GitHub readback performed. Node CLI, independent Lua and WoW in-game tests **not run**. Confidence 0–100 represents strength of evidence, not statistical probability of correctness.
