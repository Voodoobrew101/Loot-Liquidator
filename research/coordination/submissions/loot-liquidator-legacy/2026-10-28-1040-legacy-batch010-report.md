# Loot Liquidator Legacy Batch010 — 40 TSM milling profile audits

**Run:** 2026-10-28-1040-legacy-batch010. **Branch:** `research/processing-confidence`. **Queue revision:** 12, exact assigned `profile:tsm:mill:...` keys. **Starting SHA:** `12216251d9a54880503bd8266c0032ac797c1943`. **Production GameData blob:** `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`. No production Lua, main, master ledgers, assignment or schedule changes.

## Throughput and coverage

**40/40 distinct master-assigned profile keys** examined; each was `NEVER_EXAMINED` at the ledger read. **All 40 compiled `gd.mill` material lists are empty** in GameData.lua; all 40 have historical `gd.tsmRetail.mill` rows, totaling **77 input/output source rows** (3 single-output Alabaster profiles; 37 two-output profiles). All 77 satisfy the *necessary* `0<=P<=1`, positive integer min/max and `P*min <= E <= P*max` inequalities when `E=5*amountOfMats`. This does **not** prove the TSM chance and expected quantities share a measured denominator, and is not current-Retail verification. Source sample counts, patch, skill and profession conditions are absent. See [40-profile CSV](2026-10-28-1040-legacy-batch010-40profile-audit.csv) and [77-row JSONL](2026-10-28-1040-legacy-batch010-77row-tsm-field-audit.jsonl).

**Runtime source-selection observation:** `StatYieldProfiles.lua:237-269` fills empty compiled lists from TSM at load time, with `provisional=true`. `ConversionEngine.lua:493-524` separately returns TSM-native data before compiled `gd.mill` lookup. Thus future itemdb migration must regression-test whether newly researched compiled rows can be bypassed by historical TSM selection. This is a verified static code-path observation, not an in-game reproduced valuation error.

**Profile-only assignment:** 40 proposed `EXAMINED_INSUFFICIENT` statuses for master review; **0 newly scored material output fields**, 0 current-Retail corrections, 0 complete >=90 records, 0 approved numeric rules. Do not add 40 to output-field verification counts. Master baseline remains 1343/1737 examined, 394 never, 0 fully verified until independent acceptance.

## Original-study synthesis and concrete source correction

Revisited original 2008 PTR Wowhead commenter `180977` for a **specific arithmetic gap**, reusing the existing archived study rather than creating 16 independent experiments. Recomputed **16 assigned herb histograms, 449 listed positive operations**, from Alabaster, Dusky, Golden, Emerald and Violet pigment pages. All are pre-release historical evidence with unreported skill/build and no verified current-Retail bridge. The per-operation original means differ from historical TSM; examples:

| Input | 2008 PTR mean | TSM per 5 herbs | Difference |
|---|---:|---:|---:|
| Silverleaf `765` | 114/48 = 2.3750 | 2.8900 | -0.5150 |
| Khadgar's Whisker `3358` | 78/22 = 3.5455 | 2.8600 | +0.6855 |
| Swiftthistle `2452` | 47/20 = 2.3500 | 2.9275 | -0.5775 |

**Important correction:** Earthroot `2449` source reports `11×2+18×3=76` Alabaster Pigment from **29 enumerated positive operations**, but also **12 stacks** (48 five-herb equivalents), and claims mean **3.1**. Neither 76/29=2.6207 nor 76/48=1.5833 equals 3.1. Preserve all three original claims; **do not fill the missing 19 with zero**, infer P(hit), or approve a modern correction. Source is `OBSERVATION_NEEDS_CLARIFICATION`, not invalidated wholesale. Original [Alabaster comment](https://www.wowhead.com/mop-classic/item=39151/alabaster-pigment).

Reused Kaliope's independent 2008 Outland study for five assigned herb profiles (Felweed, Ragveil, Ancient Lichen, Netherbloom, Nightmare Vine), **530 reported herbs**, 106 *derived* five-herb equivalents; actual casts and hit/zero histograms not reported. Source [original 2008 table](https://kaliope.wordpress.com/2008/10/09/inscription-a-look-at-pigment-drop-rates-for-milling/). All five are one study family; no independent current-Retail pooling. The [source reconciliation](2026-10-28-1040-legacy-batch010-original-source-reconciliation-SOURCE-ONLY.md) is saved under `research/evidence/observations/` and preserves full arithmetic.

**Source memory:** 2 pre-existing original quantitative study families reused, 0 new independent quantitative study families, 1 new mixed-ore Felslate player lead (unusable as isolated Felslate rate), 1 existing Felslate worksheet re-used without re-fetch, 5 source-review events, 0 source reward points self-awarded. Translated mirrors and same-author pigment pages were not double-counted. One purposeful 2008 PTR revisit was justified by the Earthroot denominator/mean contradiction.

## Separate assigned numeric hypothesis — Felslate standard vs mass

**`legacy-felslate-standard-mass-compare`: BLOCKED.** Documented standard Prospect `31252` nominally consumes five Felslate `123919`; Mass Prospect `225904` consumes 20. [Warcraft Wiki mass recipe](https://warcraft.wiki.gg/wiki/Design:_Mass_Prospect_Felslate). Existing original [2017 worksheet](https://www.scribd.com/document/359130779/full-legion-worksheet) reports 10,000 ore per arm, standard 2063 uncommon/341 rare and mass 2070 uncommon/334 rare. Rare totals per five-ore equivalent 0.1705 vs 0.1670 are descriptive only, not matched per-cast probabilities or a verified coefficient. A new [2017 Wowhead player comment](https://www.wowhead.com/item=123919/felslate) mixes 880 Leystone and 240 Felslate and cannot identify Felslate-only gem yields. **No numeric formula, multiplier, current-Retail bridge or confidence promotion.** Required: same-build matched character and gear, >=200 actual operations per recipe, exact output IDs and zero-inclusive histograms, with independent replication. [Blocked schema candidate](2026-10-28-1040-legacy-batch010-felslate-mechanics-candidate.json).

## Field confidence and next targets

**All four output fields remain unscored in this *profile-only* audit.** Historical TSM `matRate` and `amountOfMats` are preserved in the 77-row source audit, not self-approved as measured current P/E. Source confidence is not source prestige; observed original histograms are retained despite missing target-context covariates. Evidence confidence 0–100 measures **strength of support, not the probability a number is correct**. No independent master field-level delta is claimed. Per-expansion and per-field charts are unavailable for this run because only master central ledgers supply those breakdowns; [chart JSON](2026-10-28-1040-legacy-batch010-chart-data.json) records known master totals and local audit counts.

**Exact next targets:** master QA of `profile:tsm:mill:765`, `profile:tsm:mill:2449`, `profile:tsm:mill:2452`, `profile:tsm:mill:3358`, `profile:tsm:mill:22785` and source row identity for `39342/43108`; investigate Earthroot original histogram gap, and test current Retail same-character five-herb milling on Silverleaf and Khadgar's Whisker with per-cast output IDs/zeros and skill context. For Felslate, gather matched standard/mass observations before any numeric mechanism promotion. Do not self-claim additional overflow beyond queue rev12.

## Validation

303 deterministic in-memory assertions passed: 40 disjoint assigned keys, all `NEVER_EXAMINED`, 40 compiled-empty source identities, 77 per-row numeric inequalities, 16 historical histogram arithmetic checks, five Outland cohort denominator checks, blocked mechanic required fields. This is **not** repository Node, external JSON Schema, or WoW-client execution. [Validation JSON](2026-10-28-1040-legacy-batch010-validation.json). All new files are worker-owned, additive, research-only.
