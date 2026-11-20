# Xenastro five Q3 Serevite batches: direct original-workbook check (2026-11-20 11:02 UTC)

Research-only owner-approved scientific source review for T0046/T0041; not an addon/tooling or main change.

## Primary source and exact lineage
- Retrieved original author-hosted [Prospecting Calculator V1.xlsx](https://drive.google.com/file/d/1jW-vz25Mha9GzeCe6qX9viuLyFsgDf2m/view) through read-only Google Drive access. Complete 70,052-byte original SHA-256: `847caa75c43c1227a29eb0939c80cc0d077c997c3321d3bd76dc640a519bb4ca`; worksheet `Prospecting Log`, A:AC. Workbook original unchanged.
- Worker append-only transcription [2026-11-20T1040](../dragonflight/2026-11-20T1040-xenastro-five-original-serevite-r3-batches.jsonl), Git blob `d5d803dc5a83d9563fdad96938d67165ade2d171`, consists of exactly **45 output rows / five different workbook batch rows**, all from **one Xenastro author**. Five batches are not five independent authors, and the same author workbook may have other pre-existing transcripts.
- Original spreadsheet row indexes below are one-based human-visible Excel rows; worker CSV index = Excel row minus 2. Historical Dragonflight Inspiration-era, not evidence for new Retail patch, calibrated skill scaling or live tooltip eligibility.

| Excel row / CSV index | Date in source | Input | Source Quantity (nominal Q3 Serevite ore) | Source Ore Refund (units) | Source Skill | Original Q1/Q2/Q3 green unit totals | Original Q1/Q2/Q3 blue unit totals | Original Q1/Q2/Q3 Illimited Diamond units |
| --- | --- | --- | ---: | ---: | ---: | --- | --- | --- |
| 46 / 44 | 2023-01-15 | 190394 Q3 | 13,000 | 1,631 | 277 | 0 / 611 / 2,696 | 24 / 74 / 1,262 | 1 / 1 / 17 |
| 47 / 45 | 2023-01-16 | 190394 Q3 | 15,000 | 2,162 | 277 | 7 / 673 / 3,184 | 25 / 93 / 1,462 | 0 / 0 / 21 |
| 50 / 48 | 2023-01-19 | 190394 Q3 | 14,000 | 1,944 | 279 | 11 / 623 / 2,919 | 21 / 76 / 1,407 | 0 / 2 / 21 |
| 51 / 49 | 2023-01-20 | 190394 Q3 | 14,000 | **blank / unknown** | 280 | 11 / 686 / 3,011 | 23 / 90 / 1,317 | 1 / 0 / 11 |
| 57 / 55 | 2023-01-26 | 190394 Q3 | 16,000 | 2,091 | 283 | 12 / 672 / 3,366 | 19 / 112 / 1,566 | 0 / 1 / 23 |

The five `Quantity` cells total **72,000 nominal ore**; four known `Ore Refund` cells total **7,828 returned ore** and the fifth is missing, **not zero**. Aggregated category output-unit totals across five batches: green Q1/Q2/Q3 `41/3265/15176`; blue `112/445/7014`; Illimited Diamond `2/4/93`. These are sums for *source transcription integrity only*, **not independent casts or Retail market-price EV**.

## Actual bounded validation completed
1. Imported original Excel with a workbook reader and inspected `Prospecting Log!A40:AC61`. **90/90** source-cell/category checks passed: input/name/quality, source Quantity, refunds including literal blank, skill, nine quality-bucket totals, three subtotal arithmetics and final total for each of five batches.
2. Fetched worker JSONL directly from research branch. **450/450** comparison assertions passed against original workbook values: nine material totals, null completed operations/hits, Q3 input 190394, skill, input Quantity, refundable ore or explicit `Ore Refund=blank`, rank/identity/pooled-output handling across 45 rows. **45 unique worker IDs**.
3. Previous same-author Serevite transcriptions from Nov 8/15/16 were sampled for workbook row/date overlap; no duplicate of these **five row indexes** found within the checked files. This is **not exhaustive global deduplication**, and source rows do not create new independent studies when copied elsewhere.
4. Verification is primary-source workbook ↔ research source only. **No automatic build review, Python estimator, ItemDB generation, Lua test, synthetic-price resolver/tooltip or client test executed.** No current-build gold decision verified.

## Admission and remaining research gaps
- **Source-verified**: exact historical numeric quantities for the five original batches and separate ore-refund counts, with original workbook SHA, source row/date and worker records preserved. The three rank-specific Illimited Diamond outcomes use independently corroborated rank IDs 192869/192870/192871; the original workbook itself lists *rank-bucket totals*, not item hyperlinks.
- **Held for per-operation probability or yield**: `Quantity` does not establish *actual completed prospect casts*, refund-reprocessing basis, material hit count, zero-inclusive 0..N histogram or controlled patch/character profile. Do not divide by five and promote synthetic 14,400 completed casts. A source bucket with `totalQuantity=0` is **zero reported output units**, not zero casts.
- **Held for priced species outcomes**: six green/blue buckets pool multiple gem item species, and cannot be assigned a fabricated specific item ID; keep named quality buckets unpriced until original species IDs/ranks are verified. One batch refund blank must stay unknown.
- **Next**: request the workbook author/source to clarify whether `Quantity` is gross purchased/used ore or completed input consumed, how `Ore Refund` was reused, and any actual event ledger. Separately build-test the exact pinned research SHA using current main's `tools/prepare_build_research.py`; ensure the reviewer does not classify `casts=null` or pooled species as measured current Retail probabilities. Code/runtime fixes belong to owner-reviewed implementation, not routine data PRs.
