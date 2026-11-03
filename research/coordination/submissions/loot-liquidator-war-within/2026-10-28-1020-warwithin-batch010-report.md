# Loot Liquidator — War Within Worker Batch010

**2026-10-28 · research/processing-confidence · master queue revision 12 · research ONLY.**

Master reassigned this worker to **35 distinct cross-expansion overflow keys**, all `NEVER_EXAMINED` when audited: 8 deterministic smelting outputs, 6 Midnight disenchant outputs, 1 Dragonflight Crumbled Stone self-return, 1 Ulduar choice token, 18 disenchant fallback scenarios, and 1 Silverleaf milling source profile. Exact [35-key source and field-confidence audit](2026-10-28-1020-warwithin-batch010-35key-audit.csv) is additive; central master coverage is NOT updated by this worker.

## P0 finding — synthetic Dragonflight rare-quality disenchant output

Actual `GameData.lua` blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e` contains **no `gd.disenchant[9][3]["armor"]` or `["weapon"]` source table**. Yet `StatYieldProfiles.lua:273–319` contains a `deFallback` path that, when called for either context, constructs material **194124 (Vibrant Shard)** with **chance=1** and unobserved expected quantity **1.0 for armor / 1.5 for weapons**, then applies a speculative slider-driven upper scenario. Both assigned overlay keys are source-absent; the other 16 assigned overlays have compiled source tables but their slider increases remain unmeasured.

This is a **source-code/model QA finding, not proof of any actual disenchant drop**. Do not promote the synthetic `chance=1` or quantity as observed, current-Retail, or an approved formula. Master should prioritize fail-closed treatment in a future reviewed integration, without changing production in this research task. The output material identity is consistent with [Dragonflight Enchanting documentation](https://www.wowhead.com/guide/professions/enchanting/overview-dragonflight), but that does not establish its drop rate.

## Eight static smelting recipes corroborated

All eight `GameData.lua:675–682` rows have fixed, documented output counts conditional on successful execution: **Smelt Bronze (2659) creates 2 Bronze Bars**, and the other seven recipes create 1 bar each. Exact reagent identities/quantities were audited and preserved in [static source-only evidence](../../evidence/observations/2026-10-28-1020-warwithin-batch010-static-recipe-source-only.md). Retail recipe sources include [Felsteel](https://www.wowhead.com/spell=29360/smelt-felsteel), [Hardened Khorium](https://www.wowhead.com/spell=46353/smelt-hardened-khorium), [Titansteel](https://www.wowhead.com/spell=55208/smelt-titansteel), [Hardened Elementium](https://www.wowhead.com/spell=74537/smelt-hardened-elementium), and [Trillium](https://www.wowhead.com/spell=102167/smelt-trillium).

**Metadata correction:** The supplemental ledger describes all eight as "multi-reagent"; **Smelt Fel Iron (29356) consumes one reagent type, Fel Iron Ore ×2**, not multiple types. The actual `GameData.lua` recipe already has the correct single reagent. No production correction was made. Exact current-build learned/forge/recipe eligibility still requires in-game validation.

## Six Midnight disenchant output audits

Exact source lines **656, 661, 666, 667, 672, 673** matched the six assigned output IDs. The q3 mixed-source armor/weapon profiles report 51/56 samples; q4 armor 31 samples; q4 weapon only **3**. Each row passes the necessary invariant `P(hit) × positive min ≤ unconditional E ≤ P(hit) × positive max`. The q4 armor probabilities 0.580645 + 0.419355 = 1.000000 and weapon 0.666667 + 0.333333 = 1.000000 are source-table arithmetic, not proof of current-Retail distributions. No exact equipment, patch, skill or independently replicated 2026 Retail samples were established.

## Crumbled Stone self-return: derived denominator is not measured casts

[Mgnta's original Dragonflight report](https://www.wowhead.com/item=192880/crumbled-stone) describes **3,125 Crumbled Stone, 160 self-return, 564 Eternity Amber and 65 Nozdorite**, with **16% Resourcefulness**. The source's 0.256 self-return "per prospecting" equals `160/(3125/5)`; **625 is derived five-stone equivalents**, not independently documented actual completed casts. Actual saved stones, consumed stones and whether returned stones were reprocessed are unknown.

A separate original commenter, LavingRunatic, reports **60 actual casts and 11 returned Crumbled Stone** (`11/60=0.183333`). This cohort was already archived by Midnight in corrected form; its gem quality ranks are unreported. The two studies are independent by author but not demonstrated patch/stat/denominator-compatible, so no weighted current-Retail synthesis or invented output rank was submitted.

## Silverleaf (765) historical original study reused

The compiled `gd.mill[765]` candidate has an empty materials array. This means **missing compiled evidence, not measured zero output**. The existing archive `legacy-b004-ptr180977-765-20261028` records original [2008 PTR Wowhead commenter 180977](https://www.wowhead.com/mop-classic/item=39151/alabaster-pigment): **48 actual five-herb casts**, 30 yielding two Alabaster Pigment (39151) and 18 yielding three, zero within the enumerated histogram. Thus historical observed `P(hit)=48/48=1`, positive sample range `[2,3]`, unconditional `E=(30×2+18×3)/48=2.375`. This is **historical PTR**, not a verified 2026 Retail result. The [current item guide](https://warcraft.wiki.gg/wiki/Alabaster_Pigment) supports Silverleaf's eligibility but not a numerical Retail bridge. One existing study reused; zero newly discovered original studies claimed.

## Ulduar token is a choice, not a probability

Item **45634**, Breastplate of the Wayward Vanquisher, can be exchanged for item **46123**, Conqueror's Terrorblade Breastplate, for a Rogue. [Warcraft Wiki](https://warcraft.wiki.gg/wiki/Conqueror%27s_Terrorblade_Breastplate) directly identifies the exchange. It is a **one-of-many class-constrained reward**; do not attach an RNG occurrence rate or combine all selectable rewards into one sale. Live Retail class/loot-spec/vendor action not tested.

## Separate TWW Resourcefulness numerical hypothesis

`tww-prospect-resourcefulness-savings` remains **BLOCKED**. The original [1,040-click Aqirite report](https://www.reddit.com/r/woweconomy/comments/1f83cnd) mentions 5,200 initially purchased ore; `1040×5=5200` gross input does **not** reveal actual refunded ore. [Stack-queue reports](https://www.reddit.com/r/woweconomy/comments/1g8kbaq) explain why queued operations are not identical to net consumption. A [community 30% explanation](https://www.reddit.com/r/woweconomy/comments/1fdvkmy) is not a matched prospecting experiment. There are no actual saved-ore-per-cast measurements, matched Resourcefulness rating/percent, or independent replication; no input-cost coefficient and no material-output multiplier was approved.

**Required experiment:** same TWW Algari Prospecting recipe (spell 434018), same Aqirite rank, exact build, skill/specializations/gear, two or more Resourcefulness contexts, actual completed casts, per-cast ore saved including zero, starting/ending inventories, and independently reproducible calculations. Use enough casts to distinguish meaningful input-cost outcomes; 200+ per context is a practical starting target, not a proof threshold.

## Confidence, source memory, and validation

| Scope | Audited | Four-field outputs |
|---|---:|---:|
| Static smelt | 8 | 8 |
| Midnight disenchant | 6 | 6 |
| Dragonflight self-return | 1 | 1 |
| Token choice | 1 | 0 |
| DE scenario overlays | 18 | 0 |
| Silverleaf profile | 1 | 0 |
| **Total** | **35** | **15** |

Each of the four material fields has **7 rows scored below 70, 8 in 70–89, and 0 at ≥90** (28/32/0 across 60 field slots). No score was inflated to meet the gate; these are the existing source-ledger field scores, not accuracy percentages. Token, scenario and profile audits are excluded from four-field denominators. All **35 distinct keys** were `NEVER_EXAMINED` in the read-only master ledger. The master baseline is **1,343/1,737** examined with **394** awaiting first pass; the 35 new submissions are **not yet accepted**. No complete four-field record meets ≥90.

Source-memory reuse: the archived Silverleaf PTR histogram, two Crumbled Stone commenters, and original TWW Aqirite/stack reports were referenced without counting copies as new studies. Nine newly inspected static recipe/token relationships are documentation, **not new independent player experiments**. Worker-owned [source-review events](../../source-reviews/loot-liquidator-war-within-2026-10-28-1020-warwithin-batch010.jsonl) retain missing fields and explicit revisit reasons. No self-awarded rewards or master feedback changes.

**QA:** 35 key/status/source checks, 8 deterministic recipe-count checks, 6 DE probability/expected-yield invariants, exact 2 missing q3 overlay conditions, Silverleaf 48-cast histogram arithmetic, token source identity, and output-vs-nonoutput classification passed. The [validation JSON](2026-10-28-1020-warwithin-batch010-validation.json) records test scope. **External JSON Schema, repository Node suites and actual WoW client tests were not run.** No changes to main, production `GameData.lua`, TOC, master assignments/ledgers, source-memory cache, or schedules.

## Next exact targets

1. `overlay:DE conditional fallback:exp9/q3/armor:depends on existing DE table or fallback` and its weapon counterpart — acquire real current-Retail source output profiles or block synthetic guaranteed yields.
2. `output-supp:dragonflight:192880:192880:2` — obtain actual Mgnta cast count, Resourcefulness refunds and gem-rank IDs; compare with Laving's 60-cast original.
3. `profile:compiled:mill:765` — current-Retail Silverleaf five-herb milling, zero-inclusive Alabaster Pigment IDs and actual cast logs.
4. `output-supp:de:11:4:weapon:243605:L672` and `...243606:L673` — increase the three-sample epic-weapon evidence under matched character conditions.
5. All eight smelt recipe keys — verify current-build learned recipe, forge requirement, exact reagent set and output count in game.

**Submission for independent master acceptance only. No production or central ledger changes.**
