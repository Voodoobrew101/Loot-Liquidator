# T0041 original-source checkpoint: eight Dragonflight item-side Looter cohorts and forced output co-occurrence

Checked at **2026-11-13T16:08:17.040Z UTC** on research branch `c8c97c34683892fffbca5022eef748d736460b86`; worker source blob `2f22a3cda1cd361ebdcbbb82bcfbf048fbbb051e`.

## Source readback and newly verified fields

Independently re-opened source-indexed original Wowhead item-side Looter **Disenchanting** tables for all eight worker-reported input items (200414, 200416, 200420, 202484, 207195, 207196, 207197, 207202), using both live/PTR indexed displays where accessible. The original search-indexed source text explicitly states the item-specific disenchants and material "X out of N"; **all 17 material occurrence numerators, 8 shared denominators, material names and displayed rounded percentages agree with** [worker's archived 15:34Z evidence](../../v3/evidence/dragonflight/2026-11-13T1534-eight-unindexed-gear-looter-hit-cohorts.jsonl). This is **verification of an existing cumulative source**, not 17 new independent studies, 325 newly witnessed operations, or current-build/player measurements. Some direct item page HTML blocked JavaScript access, but the source-indexed Looter tables were readable via search.

| Original item ID | Source-reported item disenchants N | Material occurrence counts (material item ID: hits/N) | Extra positive material occurrences above N | Minimum crystal–shard same-operation intersection* |
| --- | ---: | --- | ---: | ---: |
| [200414](https://www.wowhead.com/item=200414/virtuous-silver-breastplate) | 82 | 194124 50/82; 200113 47/82 | 15 | 15 |
| [200416](https://www.wowhead.com/item=200416/virtuous-silver-gauntlets) | 85 | 194124 58/85; 200113 40/85 | 13 | 13 |
| [200420](https://www.wowhead.com/ptr/item=200420/virtuous-silver-faulds) | 28 | 200113 19/28; 194124 16/28 | 7 | 7 |
| [202484](https://www.wowhead.com/ptr/item=202484/scalebands-of-obsidian-secrets) | 18 | 200113 13/18; 194124 7/18; 194123 1/18 | 3 | 2 |
| [207195](https://www.wowhead.com/item=207195/shroud-of-the-risen-nightmare) | 27 | 200113 15/27; 194124 14/27 | 2 | 2 |
| [207196](https://www.wowhead.com/item=207196/vambraces-of-the-risen-nightmare) | 21 | 194124 14/21; 200113 13/21 | 6 | 6 |
| [207197](https://www.wowhead.com/item=207197/seal-of-the-risen-nightmare) | 28 | 194124 15/28; 200113 14/28 | 1 | 1 |
| [207202](https://www.wowhead.com/item=207202/graveboots-of-the-risen-nightmare) | 36 | 194124 21/36; 200113 19/36 | 4 | 4 |
| **Across eight distinct input IDs** | **325** | **376 positive material occurrences** | **51** | **50** |

*The bound is **max(0, crystal_hits + shard_hits − N)** for `200113 Resonant Crystal` and `194124 Vibrant Shard`, valid **only if** source X/N are event-aligned per-operation material-presence counts from the same original Looter sample. These are inclusion-exclusion lower bounds, **not observed paired event logs**, unconditional expected output quantities, or probabilities. For 202484 there is a third `194123 Chromatic Dust: 1/18` row, so all-material excess is 3 although the crystal–shard bound is 2. No claims about correlations beyond these conditional arithmetic constraints.

For **every** item, total material occurrences exceed the common reported item count. Thus under the page's per-operation interpretation a model treating the rows as *exclusive* disenchant outcomes is mathematically incompatible with the source. The counts are source-positive-hit **occurrences**; they are **not** material quantity totals. The site's "1–2" or "2" display does not establish an observed positive-stack distribution or a fixed conditional mean. In particular do not sum hit ratios as a one-outcome categorical distribution, interpret the unused denominator as whole-operation no-drop outcomes, price `200113` or `194124` using an assumed observed E[quantity], or treat a material not seen as a fully logged zero across all outputs.

## Estimator / valuation handoff (code inspection, not a test)

At the research head reviewed, `research/v3/tools/build_estimates.py` treats a row `sourceKind=study` with non-null `casts` and `castsWithDrop` as a chance evidence pair in `usable_fields` (around line 305), then adds those to `casts_p` (around line 831) and labels the resulting chance `measured` (around lines 895 and 944). That is **a classification risk for undated cumulative web aggregates**: the original is an authentic source-reported Looter count, but its sample build/bonuses, character profile, event completeness and cross-snapshot independence are unverified. The same source type was transcribed earlier in the day as `castsWithDrop=null` and `percentMeaning=unclear` in `2026-11-13T0236-seven-unique-gear-looter-cohorts.jsonl`. These are different input items; this comparison highlights **inconsistent evidentiary treatment**, not duplicate study identities or proof that either source is false.

**Disposition:** retain original numeric columns and website provenance, with source-aggregated/undated applicability caveat and explicit event-count provenance; do not recode them as new coordinator player observations, assign current-patch live confidence, or create a per-cast expected-quantity estimate without measured unit totals or a separately labeled defensible reference assumption. An implementation owner should test a pair of **non-exclusive** material outputs through the actual selection/tooltip path at synthetic prices, including unknown average/range and site-source flags, only when the three-pass implementation branch is ready. **No production code or shared worker evidence edited by manager.**

## What remains unknown

Original data dates and character build; itemLink bonus/ilevel at disenchant time; eligible current-Retail variant, profession skill/spec; exact output material units and 0/1/2+ stack histograms; independent verification of no duplicate cumulative Looter snapshots; prices and actual-character/synthetic-price engine valuations. These source cohorts can be useful **conditional reference information**, but 0 new independent operation-level cohorts, 0 newly measured chance distributions, 0 current gold decisions, and 0 actual Lua/compiler/engine/tooltip/client runs were produced in this coordinator checkpoint.

**Next original-source request for Dragonflight T0041:** an event-level sample or original Looter export tying each one of these gear input itemLinks to **both** material outputs, stack counts, event date, skill/build and possible all-zero outcomes. The broader urgent unsatisfied T0005/T0039/T0045 Midnight rank-linked zero-inclusive prospect/mill/refund gaps remain first for worker searches. Avoid rescraping these eight same-site cumulative tables as fresh samples.
