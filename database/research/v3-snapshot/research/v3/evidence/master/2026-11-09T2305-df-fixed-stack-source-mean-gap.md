# Dragonflight Aberrus gear: fixed-positive-stack source means, not new casts
Checked UTC: 2026-11-09T23:05Z. Owner T0041 source/field identity audit; research-only manager note. Do not import to the protected three-pass implementation.

## New precisely scoped field gap
The Dragonflight worker's fresh `2026-11-09T2241-four-aberrous-gear-original-looter-cohorts.jsonl` has 12 genuine source-transcribed output rows over four distinct item-side Wowhead Looter denominators. Three rows have **fixed positive stack exactly 2** explicitly printed in their original item-side tables. The worker correctly retained `castsWithDrop` and `minSeen=maxSeen=2`, but `totalQuantity` and `averageShown` are null. The compiler's current `research/v3/tools/build_estimates.py::row_use` (read-only static inspection) will not directly produce a source-backed unconditional output mean without those fields; any later chance-plus-range midpoint fallback is a separately labeled heuristic rather than the simpler **exact source-implied count**. No code/estimator/runtime result was executed here.

Independent original page reads, as of this note:
- [Skullstrap of the Sinister Savant, 202530](https://www.wowhead.com/ptr-2/item=202530/skullstrap-of-the-sinister-savant?bonus=7982): 97 item-side disenchants, Chromatic Dust 194123 reported in 2 operations at **2 each**.
- [Kinslayer's Gaiters, 202526](https://www.wowhead.com/ptr-2/item=202526/kinslayers-gaiters): 14 item-side disenchants, Vibrant Shard 194124 reported in 5 operations at **2 each**, Chromatic Dust 194123 in 1 operation at **2**.
- [Wristwraps of the Sinister Savant, 202529](https://www.wowhead.com/ptr/item=202529/wristwraps-of-the-sinister-savant) and [Underlight Conjurer's Treads, 202553](https://www.wowhead.com/item=202553/underlight-conjurers-treads?bonus=6652:9332:1491&class=8&ilvl=434&spec=64): rows have unknown quantity for Resonant Crystal or positive ranges of 1–2 / 1–3; **do not convert those ranges to observed totals**.

| Input item ID | Output | Source positive hits / source denominator | Source positive stack | Arithmetic total units | Arithmetic mean units per reported DE |
| --- | --- | ---: | ---: | ---: | ---: |
| 202530 | 194123 (Chromatic Dust) | 2/97 | 2 | 4 | 0.04123711 |
| 202526 | 194124 (Vibrant Shard) | 5/14 | 2 | 10 | 0.71428571 |
| 202526 | 194123 (Chromatic Dust) | 1/14 | 2 | 2 | 0.14285714 |

These totals are **arithmetic implied by source row counts and the source-displayed fixed stack of 2**, not newly collected raw player events or independent studies. This is a reproducible **original-source candidate** that can price the per-output quantity at synthetic prices only after its eligibility/context gate passes. Do not label sample character, build, original operation dates, bonus variants, skill/specialization, current Retail applicability or full model coverage as verified. No current auction prices, costs, gold recommendation or tooltip rendering was checked.

## Multiple output rows cannot be interpreted as mutually exclusive

Per independent original page, positive material occurrence counts for the three named materials exceed the item-side event denominator:
- 202529: `66+50+4=120 > 110` (10 surplus positive material-incidences).
- 202530: `59+48+2=109 > 97` (12 surplus).
- 202526: `9+5+1=15 > 14` (1 surplus).
- 202553: `61+57+7=125 > 107` (18 surplus).

If all three rows per item describe the same underlying operation cohort, their reported margins **require some joint material hits**, or else highlight a mixed-count/denominator inconsistency; the marginal counts alone do not identify which events or output combinations. Never force a single exclusive outcome distribution, infer an event-level covariance, treat excess counts as new casts, or sum overlapping source snapshots as independent studies. Sum independently supported expected *units* for linear EV only after context and compatible input/price checks.

## Suggested controlled follow-up

1. Verify the 3 fixed-stack source rows against their original pages and record source-implied `totalQuantity` values (4, 10, 2) in an **auditable correction/derived-field layer** rather than editing worker originals. Keep denominator, item ID and unknown source epoch attached; do not generalize to all Dragonflight epic gear or current Retail character.
2. Add a research-only fixed-positive-stack `hits × fixed quantity` fixture with provenance and no invented zero bins; ensure independent chance/average confidence and multi-material marginals. Leave optional addon integration to owner-controlled `implementation/usable-data-tooltips` three-pass work.
3. Continue highest-priority current Midnight T0005/T0039/T0045 per-operation evidence without re-asking for the already-transcribed reference/table studies.

**Validation in this checkpoint:** fetched and independently read four original indexed Wowhead item-side tables, compared their visible counts/stacks to the checked-in Dragonflight worker JSONL, inspected exact compiler `row_use` lines, and performed the displayed arithmetic. **Not executed:** estimator CLI, synthetic-price Lua valuation or tooltip, current Retail client/character, research tests, new PR, merge, or release.
