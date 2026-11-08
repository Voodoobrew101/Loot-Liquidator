# Dragonflight five-cohort Looter positive-stack recovery — coordinator research-only audit

**Source checked:** 2026-11-08T18:15:10.167Z UTC. **Task handoff:** T0020/T0041 / Dragonflight worker. **Source format:** original current Wowhead/PTR item-specific JavaScript `Listview` data in the `disenchanting` tab, not cached search excerpts. **Independence:** five existing worker cohorts, **zero newly observed casts**; these are **newly source-recovered numerical output quantities** from those same original cohort snapshots. No worker JSONL or immutable evidence changed.

| Source item / mode | Output item | Reported disenchant operations | Output-positive hits | Source conditional stack distribution, counts of positive occurrences | Derived output units (sum) | Derived units per source operation |
| --- | ---: | ---: | ---: | --- | ---: | ---: |
| [197656 Shikaar Scout Pauldrons](https://www.wowhead.com/item=197656/shikaar-scout-pauldrons), live-index | 194123 Chromatic Dust | 90 | 87 | 1×45, 2×39, 3×3 | **132** | 132/90 = 1.466667 |
| 197656 | 194124 Vibrant Shard | 90 | 4 | 1×3, 2×1 | **5** | 5/90 = 0.055556 |
| [204461 Shalkeel's Remembrance](https://www.wowhead.com/item=204461/shalkeels-remembrance), live-index | 194123 Chromatic Dust | 692 | 653 | 1×316, 2×310, 3×27 | **1017** | 1017/692 = 1.469653 |
| 204461 | 194124 Vibrant Shard | 692 | 58 | 1×58 (source fixed stack 1–1) | **58** | 58/692 = 0.083815 |
| [207259 Screaming Torchfiend's Armlets](https://www.wowhead.com/item=207259/screaming-torchfiends-armlets), live-index | 194124 Vibrant Shard | 18 | 11 | 1×6, 2×5 | **16** | 16/18 = 0.888889 |
| 207259 | 200113 Resonant Crystal | 18 | 8 | 1×8 (source fixed stack 1–1) | **8** | 8/18 = 0.444444 |
| [207258 Screaming Torchfiend's Shawl](https://www.wowhead.com/ptr/item=207258/screaming-torchfiends-shawl), **PTR-index** | 194124 Vibrant Shard | 14 | 5 | 1×3, 2×2 | **7** | 7/14 = 0.500000 |
| 207258 | 200113 Resonant Crystal | 14 | 9 | 1×9 (source fixed stack 1–1) | **9** | 9/14 = 0.642857 |
| [207260 Screaming Torchfiend's Clasp](https://www.wowhead.com/item=207260/screaming-torchfiends-clasp), live-index | 194124 Vibrant Shard | 24 | 14 | 1×7, 2×7 | **21** | 21/24 = 0.875000 |
| 207260 | 200113 Resonant Crystal | 24 | 10 | 1×10 (source fixed stack 1–1) | **10** | 10/24 = 0.416667 |

## Reconstruction and independent cross-check

Read the original embedded `id: 'disenchanting'` listview `data` arrays for the five source URLs using a live page scrape. Extracted per output: linked `id`, `count` (positive occurrences), `outof` (source item disenchants), `stack` and `pctstack`. Compared all ten output IDs/positive-hit counts and five source denominators with [the Dragonflight worker's 2026-11-08T1742 original-preserving JSONL](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/five-agent-completion/research/v3/evidence/dragonflight/2026-11-08T1742-five-distinct-gear-disenchant-looter-cohorts.jsonl); all matched.

For each source percent `p` printed to `d` decimal places, enumerated all nonnegative integer bin counts `k` satisfying `|100k/hits - p| ≤ 0.5·10^(-d) + 10^(-9)`, and required **exactly one** count per bin, with all bins summing to `hits`. All six nontrivial `pctstack` source rows passed; the four source rows with `stack=[1,1]` have fixed quantity. Thus `totalQuantity = sum(stack_size × reconstructed_positive_count)` is uniquely determined **within the displayed table's rounding precision**. The 204461 dust row, for example, reconstructs 316/310/27 from 48.392%/47.4732%/4.13476% over 653 positive occurrences. All rows passed count/denominator checks. Each per-operation value is the derived source total divided by its own *historical source-reported* item denominator, **not an observed current-character mean**.

## Application limits and next handoff

These are **source-derived cumulative historical/reference quantities, not independent new experiments** and not a current Retail eligible gold/tooltip fixture. Neither the original collection epoch, source per-cast joint outcome associations, actual gear itemLink/bonus/version and rarity for 204461, profession skill/spec, nor current Retail disenchant legality is established. A PTR-indexed 207258 source is not live-client verification. The source's positive-stack distribution is *marginal per material*; per-output source-operation zero counts can be inferred arithmetically as `outof - hits` **only within that historical source snapshot**, never as evidence that a whole disenchant produced zero items or that material outcomes are mutually exclusive. Do not combine input cohorts, double-count copied Looter snapshots or apply skill scaling. Avoid converting these values into actionable gold recommendations until context/eligibility and representative resolver/formatter checks are separately verified by the three-pass implementation owner.

**Worker handoff:** Confirm current item bonus/version, source data epoch, exact rarity and live DE legality; maintain T0041 raw 0–N / joint-operation export search. An append-only corrective worker follow-up can cite this audit for supported source-attributed `totalQuantity` and conditional positive-stack evidence. No PR, addon, compiled ItemDB, queue, worker reports, merge/release or schedules changed.
