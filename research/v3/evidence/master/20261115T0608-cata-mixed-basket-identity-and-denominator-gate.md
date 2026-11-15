# Mixed Cataclysm prospect / four-gear disenchant original-source identity gate — 2026-11-15 06:08 UTC

**Disposition: original-source-verified pooled material quantities, not item-specific Retail valuation evidence.** This checkpoint reviews Legacy's new append-only [15-row source transcription](../legacy/2026-11-15T0548-mixed-cata-prospect-and-disenchant-originals.jsonl) (blob `68c91b28312d3644687fd9ed0118bee02d46c66b`) against the two original 2011 posts and current v3 compiler source. No manager-created study or current-patch measured cohort; no compiler, synthetic-price engine, Lua tooltip or live-WoW test executed.

## Original source A: two ores, one inseparable gem receipt

The [August 3, 2011 original blog post](https://beyondthenumbers2011.blogspot.com/2011/08/making-gold-with-holy-trinity-alchemy.html) says it began with **300 Elementium Ore (52185)** and **180 Obsidium Ore (53038)**, and then prospected *all the ore*, listing one pooled gem receipt **before** transmuting, crafting jewelry or disenchanting. The source does not split gem quantities by ore. Legacy IDs `legacy-20261115-91701..91712` retain exactly these initial results:

| Source material ID | Original item | Pooled material units |
| --- | --- | ---: |
| 52193 | Ember Topaz | 2 |
| 52194 | Demonseye | 6 |
| 52190 | Inferno Ruby | 4 |
| 52192 | Dream Emerald | 3 |
| 52191 | Ocean Sapphire | 5 |
| 52195 | Amberjewel | 1 |
| 52179 | Alicite | 21 |
| 52178 | Zephyrite | 22 |
| 52177 | Carnelian | 16 |
| 52180 | Nightstone | 22 |
| 52181 | Hessonite | 24 |
| 52182 | Jasper | 12 |

The 12 source lines total **138 pooled gem units** (21 rare, 117 uncommon) for **480 source-mentioned ore items**. At a nominal 5 ore per prospect this is **96 five-ore input equivalents**, and **138/96 = 1.4375 pooled gem units per nominal equivalent**. This is *aggregate basket arithmetic*, **not** a measured number of completed prospect casts, an unconditional estimate for Elementium alone or Obsidium alone, a quality-specific output, an occurrence probability, or a current-build Retail rate. Because the source has no allocation by ore, **do not infer or apportion either of the two input-specific rate vectors**. The source's later transmute/jewelry/enchant output tables are downstream transformations and must not be re-added as independently prospected gems. Pre-existing **Elementium-only** Agrathus source studies mentioned in queue T0042 are different cohorts, not a denominator for the mixed receipt.

## Original source B: four purchased items, one inseparable DE receipt

The [August 5, 2011 original blog](https://beyondthenumbers2011.blogspot.com/2011/08/making-gold-with-enchanting.html) lists one Gallant Flamberge of the Tiger, one Bladefist Dagger of the Beast, **two** Mighty Gauntlets of the Monkey; outputs are **2 Greater Celestial Essence (52719), 1 Greater Eternal Essence (16203), 5 Illusion Dust (16204)**. Legacy IDs `legacy-20261115-91801..91803` preserve the three exact material totals. The **8 output units** are a pooled four-input receipt, not item-level allocations or a logged four-cast per-item histogram. Source-specific variants, effective item level, build and current Retail eligibility are unverified. Never attribute 5 dust to any one purchased item or price its independent DE outcome from these data.

## Static v3 admission trace / regression gate

At current research head `0c5d74345429a591a77ca64e94774e5758dde61e`, `research/v3/tools/build_estimates.py`:
- `key_of` (lines 188–203) maps the deliberate `inputItemID:null` and verbose `inputName` to a synthetic `family:Mixed ...` key. Such records are **placed by key**, so a low `unplaced` count does not mean they are economically usable for a real-item input.
- `row_use` (266–328) needs completed cast/typed `inputsProcessed` or a source-defined normalized average to admit a `totalQuantity` as an expectation. All 15 new rows have `totalQuantity` but `casts:null`, `inputsProcessed` absent and `averageShown:null`; the reviewed static disposition is `totalWithoutCasts`. `analyze` (893–914) cannot produce an estimate from these rows alone. **This is a static code-path prediction, not a freshly generated `unused.json` or a runtime test.**
- Do **not** add `casts:96`, `inputsProcessed:480`, `casts:4`, or per-input material shares to these source rows. The first two numbers describe a mixed basket; the latter is purchased items, not explicit per-operation DE outcomes.

**Research/engineering acceptance fixture** (reviewed, not executed): retain all 15 original source rows and original IDs, classify them as `mixed-input/pooled receipt; item allocation unknown` rather than missing data or a new exact-item gold recommendation, and prevent family/record counts from implying eligibility. Independently verify any future source that separates **each input item ID**, **batch consumed**, **completed operations**, **quality**, **source epoch**, and **output totals/hits**; preserve unknown chance/zeros. On the owner-controlled three-pass branch, any future admission must pass source → compiler → actual resolver/valuation/tooltip at synthetic prices without losing the independent Elementium studies. No import/snapshot PR or owner branch edit authorized here.

## Verification performed and limits

Performed: opened original August 3 and August 5 2011 articles; read back worker source JSONL and all 15 rows; cross-checked each source-given quantity and ID against the two original source listings; recomputed 21+117=138, 300+180=480 and 480/5=96 in a deterministic JavaScript check; reviewed `key_of`, `row_use`, `analyze` and current queue T0042; checked current branch/PR/Actions heads and all worker quiet statuses. Not performed: new gameplay observations, current Retail source validation, full v3 Python compiler/unused-report generation, local addon tests, actual Lua or synthetic-price tooltip test, or CI on this manager commit.

**Priority:** seek source-separated 52185 / 53038 prospect receipts or exact-item DE operation logs only if original records exist; do not request another copy of these two articles. Preserve higher-priority contemporary Midnight T0045/T0039 and TWW rank/eligibility gaps; leave all worker files, owner integration, PRs, main and schedules alone.
