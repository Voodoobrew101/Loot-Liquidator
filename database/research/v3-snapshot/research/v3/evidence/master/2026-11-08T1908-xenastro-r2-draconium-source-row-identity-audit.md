# Xenastro original Draconium R2 worksheet identity audit — 2026-11-08 19:08 UTC

**Scope:** Coordinator-only original-source and research queue reconciliation for T0019/T0041. Research validation, not a new study, correction of a worker's evidence, current Retail confirmation, ItemDB/tooltip verification or addon import.

## Original source verified

Read the original [Prospecting Calculator V1.xlsx](https://docs.google.com/spreadsheets/d/1jW-vz25Mha9GzeCe6qX9viuLyFsgDf2m/edit), **Prospecting Log** worksheet, through Google Drive's readable Excel extraction. The source file is an XLSX (not a native Google Sheet); its Drive metadata reports a 70,052-byte file modified 2024-03-27. Parsed the source's original per-batch `Ore Type`, `Quality`, `Quantity`, `Ore Refund`, `Skill`, `Inspiration`, `Resourcefulness`, date, and nine pooled material-quality totals. Compared each quantity against the 44 existing evidence rows in [2026-10-30T2027-xenastro-draconium-five-log-rows.jsonl](../dragonflight/2026-10-30T2027-xenastro-draconium-five-log-rows.jsonl).

**All 44/44 recorded source raw pooled-output totals match** their corresponding original workbook cells. The five evidence `studyKey` suffixes correctly name Excel worksheet rows **28, 52, 54, 55 and 62**. In the connector's exported CSV, the data index is *worksheet row minus two* (header and 0-based index), not the same row number. The evidence is already present; do not duplicate it, or claim another 70,543 processed ores as newly measured.

| Excel row / CSV index | Source ore and quality | Nominal input ore | Source refund | Reported skill | Pooled green units | Pooled blue units | Pooled epic units |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 28 / 26 | Draconium Q2 | 8,543 | 126 | 237 | 2,907 | 1,504 | 24 |
| 52 / 50 | Draconium Q2 | 15,000 | 893 | 248 | 5,304 | 2,824 | 50 |
| 54 / 52 | Draconium Q2 | 13,000 | 883 | 248 | 4,676 | 2,417 | 42 |
| 55 / 53 | Draconium Q2 | 21,000 | **unknown** | 249 | 7,587 | 3,803 | 61 |
| 62 / 60 | Draconium Q2 | 13,000 | 735 | 250 | 4,603 | 2,401 | 45 |
| **Source total** | Five existing historical batches | **70,543** | **2,637 known, one missing** | Different character profiles | **25,077** | **12,949** | **222** |

Totals are original-sheet material-unit totals across pooled gem families and output-quality alternatives; they do **not** provide separate gem item IDs, occurrence P(hit), independent cast logs, complete refund or present-character conversion EV. Source reports five dated batches from January 3 to February 1, 2023. Do not pool for a calibrated skill effect: skill and Inspiration/Resourcefulness conditions vary.

## Newly verified queue identity discrepancy

Current [queue.json](../../queue.json) **T0019** lists original Xenastro R2 Draconium rows **28, 33, 39, 54, 62**. The original XLSX and the existing worker-owned 44-row evidence both instead establish **28, 52, 54, 55, 62**. The two incorrect references are not harmless CSV offsets:

- Excel row **33** corresponds to source CSV index 31: **Serevite Q2**, 15,000 nominal ore.
- Excel row **39** corresponds to source CSV index 37: **Serevite Q3**, 11,000 nominal ore.
- Missing queue references are actual **Draconium Q2 rows 52 and 55** (15,000 and 21,000 nominal ore).

**Disposition:** this is an existing-queue *source-row identity/cross-ore contamination risk*, not a defect in the 44 historical worker observations. The queue's T0019 row list should be corrected by its authorized owner at a suitable research checkpoint. Do not migrate the incorrect Serevite lines into Draconium. Original researcher evidence and T0046 rank-ID work remain owned by Dragonflight; no worker evidence, queue, current addon branch, original spreadsheet, or compiled data was edited.

## Next original-source gaps and limits

Find actual completed-operation/refund/reprocessing logs and precise itemLink/quality IDs before deriving per-cast probabilities, per-rank character modeling or current Retail eligibility. The workbook has **nominal `Quantity` of ore**, not proven completed casts, and `Ore Refund` is missing in row 55. Do not divide nominal input by five and call the result measured casts. No original individual-gem output-ID distributions or source 0/1/2+ cast histograms were recovered. Existing source numbers are usable for labeled historical/reference totals only under supported units/context.

**Performed:** direct original XLSX extraction, 5 original source row identities, 44 record-to-cell numerical comparisons (44 match), source cohort-context scan, queue and schema read. **Not performed:** independent observations, current-client qualification, automated Lua suite, estimator/compiler run, synthetic-price valuation, actual rendered tooltip, production prices, GitHub Actions rerun or any merge/release.
