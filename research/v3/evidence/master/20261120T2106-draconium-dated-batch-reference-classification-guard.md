# 2026-11-20 — Xenastro Draconium Q3 three dated batches: effective source-classification guard

**Scope:** Independent repository-record arithmetic and provenance cross-check of 27 newly transcribed rows from three dated batches by the same author, plus code-path inspection. Not a fresh look at original XLSX cells, a new Retail observational cohort, ItemDB generation, synthetic-price tooltip rendering, or in-game verification.

## Original data retained (Draconium Q3, input 190311)

| Original worksheet date | Evidence file | Nominal ore | Refunded ore | Green grade-1/2/3 | Blue grade-1/2/3 | Illimited Diamond 192869/192870/192871 | Total reported gem units | Before effective classification |
| --- | --- | ---: | ---: | --- | --- | --- | ---: | --- |
| 2023-02-02 (index 61) | research/v3/evidence/dragonflight/2026-11-20T2032-xenastro-draconium-r3-feb02-feb04-held-original.jsonl | 30,000 | 4,157 | 22 / 1,327 / 9,256 | 57 / 165 / 6,807 | 1 / 3 / 127 | 17,765 | reference |
| 2023-02-03 (earlier index) | research/v3/evidence/dragonflight/2026-11-20T1733-xenastro-original-draconium-r3-feb03-batch.jsonl | 14,000 | unknown (blank) | 6 / 605 / 4,357 | 22 / 86 / 3,122 | 1 / 0 / 48 | 8,247 | **study**, despite explicit HELD notes |
| 2023-02-04 (index 63) | research/v3/evidence/dragonflight/2026-11-20T2032-xenastro-draconium-r3-feb02-feb04-held-original.jsonl | 30,000 | unknown (blank) | 12 / 1,286 / 9,411 | 65 / 191 / 6,850 | 0 / 1 / 109 | 17,925 | reference |

**Cross-record check:** 27 unique record IDs, nine per dated study key, three distinct timestamps, 43,937 source-reported gem units across **74,000 nominal ore**. This is a sum of original reports, **not an unconditional ore-stage yield or independently observed cast denominator**. Eighteen pooled green/blue rows lack species item IDs; nine diamond rows have rank-qualified IDs. All 27 rows have `casts=null`, `castsWithDrop=null`, `histogram=null`. Named Diamond units are not per-cast hits; a source-reported zero-unit bucket is not a zero-outcome event. Skill 283, Inspiration 19.80% and Resourcefulness 30.60% are the original February context, not a universal formula.

## Material mismatch found and bounded correction

The Feb 3 file's **nine rows had `sourceKind=study`** even though each raw row's notes explicitly said held due to missing actual operations and unresolved ore-then-secondary Prismatic/Crumbled Stone stage. The Feb 2/4 rows already had `sourceKind=reference`. Appended nine **file-scoped `sourceKind=reference` corrections** in `research/v3/corrections.jsonl`; the original worker file remains unchanged. The documented `build_estimates.py` overlay admits `sourceKind` in CORRECTABLE and `apply_corrections` applies file-scoped changes; main `research_v3_to_baselines.py` excludes `REFERENCE_KINDS` from measured study counting. This guards against any future denominator-derived accidental promotion; it does **not** establish actual generated-build disposition in this run. The original row-level `totalQuantity`, input identity/rank, source URL, dated study keys and diamond rank alternatives are preserved and can be revisited when stage identity is recovered.

## Remaining gate and checks

Obtain an original **stage-separated ore-output and secondary-output ledger** with species/item IDs, source build/skill, truly completed ore and secondary operations, per-event 0/1/2+ including zeros, plus ore refunds and reprocessing. Do not request another copy of the same aggregate workbook or create new samples. Reconcile all three dated runs and other Xenastro batches under the same author; batch separation is not independent source-family multiplicity.

Performed in this manager run: 27 JSONL rows parsed; group-by original dated source and nine graded outputs per batch; per-batch totals recomputed; IDs and null operation fields checked; main build-review and source correction handling inspected statically. Not performed: original XLSX re-open, exact-SHA preparation/review, ItemDB generation, native Lua/Lupa, actual tooltip/price, WoW client. No gold outcome or new observed casts claimed. No addon, main, owner's three-pass branch, PR, release or schedules changed.

Sources: [original workbook](https://drive.google.com/file/d/1jW-vz25Mha9GzeCe6qX9viuLyFsgDf2m/view), [author's two-stage explanation](https://www.reddit.com/r/woweconomy/comments/10vz6jh/prospecting_calculator_not_for_squids/), [build review code](https://github.com/Voodoobrew101/Loot-Liquidator/blob/4190fe93cadfeda361445829750bb46d4fccc9f3/tools/research_build_review.py).
