# Stoneguard Band (43248): 500-DE source yield units, reference conflict and Retail gate

**Checked 2026-11-18 09:07 UTC by research manager. Research-only.** Worker owns original `research/v3/evidence/legacy/2026-11-18T0854-stoneguard-band-500-completed-de-cohort.jsonl`; do not rewrite its original records. Original source and additional reference checks below are independently inspected; this is not a new independent experiment or a live WoW measurement.

## Source lineage and supported arithmetic

The [MMOWTS original first-person article, published 2024-03-16](https://www.mmowts.com/news/wotlk-classic-best-strategy-to-get-richer-while-afking-disenchant-stoneguard-band) says 500 Stoneguard Band rings were crafted and disenchanted, yielding **2,095 Infinite Dust (34054) units from 381 dust-positive operations; 163 Greater Cosmic Essence (34055) units from 106 essence-positive operations; 13 Dream Shard (34052) units from 13 shard-positive operations**. One reported 500-operation cohort, three output rows, not 1,500 independent casts. Its reported conditional dust/essence averages ~5.5/1.54 divide totals by positive casts, **not** by all 500.

| Output ID | Source units | Source positive operations | Observed cohort hit fraction (not Retail P) | Conditional units / positive | Unconditional units / reported operation | Algebraic output-nonhit count (not raw zero-bin ledger) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Infinite Dust 34054 | 2095 | 381 | 0.762 | 5.498687664 | **4.190** | 119 |
| Greater Cosmic Essence 34055 | 163 | 106 | 0.212 | 1.537735849 | **0.326** | 394 |
| Dream Shard 34052 | 13 | 13 | 0.026 | 1.0 | **0.026** | 487 |

The three reported hit-category counts sum to 500, consistent with the article's mutually exclusive description, **not proof of audited event-by-event 0..N histograms**. The per-output nonhit counts follow from the reported aggregate denominator; do not label them separately observed zeros. Unknown: per-cast histogram, exact skill/spec, patch/build/bonuses, raw event export, itemLink/effective item level and Retail processing eligibility. No sale-price/profit data from this 2024 Classic guide is a current Retail valuation.

## Newly identified contradictory historical reference — do not silently blend

The old [WoWWiki Stoneguard Band item stub](https://wowwiki-archive.fandom.com/wiki/Stoneguard_Band) displays **Infinite Dust 2–5 (22%); Greater Cosmic Essence 1–2 (75%); Dream Shard 1 (3%)**, with an explicit site warning that the archive is inaccurate/out of date. The Classic cohort instead reports **76.2% dust and 21.2% essence**, essentially opposite roles; the cohort's conditional dust mean **5.4987 exceeds** the stub's nominal *maximum* 5. If that 5-unit ceiling applied to every one of the 381 positive rings, total Dust could not exceed **1,905**, yet the article claims **2,095**—a discrepancy of **190 units**. A separately authored [historical Wowhead item comment](https://www.wowhead.com/wotlk/item=43248/stoneguard-band) states a *reference profit formula*, **0.75 × 4 × Dust price + 0.22 × 1.5 × Essence price + 0.03 × Shard price − 2 × Eternal Earth price**; this qualitatively agrees with the cohort's **dust-majority/essence-minority** ordering, and contradicts WoWWiki's category labels. It is a *reference formula*, not an independent completed-operation measurement. The stub may be erroneous, from incompatible conditions or misassigned labels; **cause is unknown**. Do not erase either source, infer new bins, force the older range onto this cohort, or average incompatible percent/range tables. Request independent patch/era reference confirmation before any source reconciliation.

## Retail version and frozen-audit gates

[WotLK Classic item 43248](https://www.wowhead.com/wotlk/item=43248/stoneguard-band) is cataloged at **iLvl 162**; the [current Retail crafting spell](https://www.wowhead.com/spell=58145/stoneguard-band) displays its result at **iLvl 14**, and the Retail recipe still uses 2 Eternal Earth. Item ID is not enough to map Classic disenchant material distribution to modern Retail. Actual Retail itemLink/effective ilvl and disenchant result would be needed. No live-client action verified.

Pinned `research/v3/output/estimates.json` has **zero exact 43248 IDs** (read-only string check). That proves only absence of exact-input records, **not** a failure in the addon's fallback resolver, value, tooltip or character eligibility. Do not alter the owner's `implementation/usable-data-tooltips` three-pass branch or the immutable `4df9ae8` source snapshot. Revisit actual offline valuation/rendering only if a Retail-applicable, identified source advances.

## Validation actually performed

- Read-back worker original file blob `9954a33d0f95b843ab05b6415c3ae62c5387307a` and frozen estimates blob `15ae8c5b7f7b2587ceff1dcd3e8b9d13d4351d1e`.
- Opened original 2024 MMOWTS report and archived WoWWiki stub; checked Retail recipe and Classic item catalog.
- **31/31 in-process JavaScript assertions**: 4 worker rows, unique studyKey/output IDs, single shared 500-cast denominator, exact positive counts/totals, distinct conditional and unconditional means, unknown histogram/skill/build/rank, original file state, frozen exact-item absence and reference max conflict.
- **Not run**: Python estimator, migration/importer, Lua addon/valuation engine, tooltip renderer, live game, automated CI trigger. Previously generated CI on independent worker head does not constitute validation of this note.

**Outcome:** historical cohort's measured aggregate arithmetic verified with a material discrepancy against an older reference, no new current Retail gold decision or user-visible supported field. **Priority:** worker-owned current Retail T0005/T0039 Umbral Tin 237362 0..N/rank/refund/skill exports and T0045 Tranquility Bloom 236761 input-coupled 10-herb mills remain higher impact than reconciling this historical 2024 conflict. No worker scope or schedule changes.
