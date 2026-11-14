# Xenastro original Excel: eight reported Dragonflight ore-refund totals — 2026-11-14 UTC

## Actual source inspection and source-lineage gate

Read the existing [Xenastro **Prospecting Calculator V1.xlsx**](https://drive.google.com/file/d/1jW-vz25Mha9GzeCe6qX9viuLyFsgDf2m/view) via the connected Drive file's **readable extracted workbook text** (stored Excel MIME; modified 2024-03-27 UTC); inspected its **Prospecting Log** column headers and 14 already-indexed Draconium batch rows, cross-checked against [the 2026-10-29 archived original-log review](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/five-agent-completion/research/evidence/observations/2026-10-29-0217-warwithin-q28-batch026-user-workbook-draconium-gross-ore-log.md), [five existing R2 cohorts](../dragonflight/2026-10-30T2027-xenastro-draconium-five-log-rows.jsonl), and [subsequent R3 cohorts](../dragonflight/2026-11-02T1025-xenastro-draconium-r3-original-batches.jsonl). **These are original workbook rows already present in research, not new independent studies or sampled casts.**

**New source-reconciliation correction:** The October 29 archived note asserted `Ore Refund` was blank in all 14 Draconium rows. That claim is contradicted by the original currently accessible Excel text: **8/14 rows report explicit refunded-ore quantities and six cells are blank.** The previously recorded R3 row 63 refund of **4,157** is independently reconfirmed, not a new measurement. The R2 first-five-cohort source transcriptions mention Resourcefulness rates but omit their four reported refund amounts. Do not edit that historical note or any worker-owned evidence; append only a reviewed correction/normalization after the worker confirms same source revision.

## Original `Prospecting Log` values (historical 2023)

Rows are original Excel row numbers (extracted CSV index + 2); `Quantity` is the author's reported ore quantity, *not* an independently measured completed-cast denominator. A dash in `Ore Refund` means blank, **not observed zero**.

| Excel row | Input | Reported ore quantity | Reported refunded ore | Skill | Insp. | Resourcefulness | Logged date |
|---:|---|---:|---:|---:|---:|---:|---|
| 28 | Draconium Q2 | 8,543 | 126 | 237 | 0.339 | 0.051 | 2023-01-03 |
| 52 | Draconium Q2 | 15,000 | 893 | 248 | 0.348 | 0.133 | 2023-01-22 |
| 53 | Draconium Q3 | 10,000 | 1,313 | 281 | 0.198 | 0.306 | 2023-01-22 |
| 54 | Draconium Q2 | 13,000 | 883 | 248 | 0.368 | 0.133 | 2023-01-22 |
| 55 | Draconium Q2 | 21,000 | — | 249 | 0.348 | 0.133 | 2023-01-23 |
| 56 | Draconium Q3 | 22,000 | 3,039 | 282 | 0.198 | 0.306 | 2023-01-24 |
| 58 | Draconium Q3 | 10,000 | 1,360 | 283 | 0.198 | 0.306 | 2023-01-28 |
| 60 | Draconium Q3 | 15,000 | — | 283 | 0.198 | 0.306 | 2023-01-29 |
| 62 | Draconium Q2 | 13,000 | 735 | 250 | 0.368 | 0.133 | 2023-02-01 |
| 63 | Draconium Q3 | 30,000 | 4,157 | 283 | 0.198 | 0.306 | 2023-02-02 |
| 64 | Draconium Q3 | 14,000 | — | 283 | 0.198 | 0.306 | 2023-02-03 |
| 65 | Draconium Q3 | 30,000 | — | 283 | 0.198 | 0.306 | 2023-02-04 |
| 66 | Draconium Q3 | 19,000 | — | 283 | 0.198 | 0.306 | 2023-02-05 |
| 67 | Draconium Q3 | 20,000 | — | 283 | 0.198 | 0.306 | 2023-02-06 |

Source-reported refund cells: Q2 **2,637** refunded ore over **49,543** corresponding reported ore input in four Q2 rows; Q3 **9,869** refunded over **72,000** in four Q3 rows; total **12,506** refunded units in eight explicitly populated cells. These are **input-savings totals**, not output gem quantities, refund *event counts*, measured proc probabilities, or Resourcefulness coefficients. Ratios 2637/49543 ≈ 5.323% and 9869/72000 ≈ 13.707% describe only the corresponding historical source-reported ore quantities; they do not establish current-character savings or whether refunded inputs were reused to perform additional operations.

The same original workbook's **Statistics** tab labels `Green Chance` as **0.2479000595** for Serevite Q2, but this equals **20,836 green gem units / 84,050 ore units**, whereas `Rate per 5 Ore` is **1.239500297**. It therefore represents a reported *output-unit rate per ore*, **not** the probability of at least one green output in a completed cast. Similarly, column `Distrib` in the price calculator is a conditional **gem-identity/quality share** (its category fractions sum to 1), not per-cast occurrence probability. Do not reuse such values as measured hits, zero bins, or skill coefficients. These source field labels are ambiguous and require explicit unit normalization.

## Decision and next integration gate

**New original-field reconciliation:** eight verified refund-quantity cells (including one already preserved in an R3 record), six null/blank refund cells, **zero new independent cohorts, zero new reported casts, zero new current-Retail supported gold decisions, and no runtime/price test**. Retain the XLSX's original dated 2023 Inspiration-era conditions, exact ore quality, per-row skill, Resourcefulness and input quantity, and any separately sourced output ranks. The original XLSX was inspected via **Drive readable text extraction, not a local raw-XLSX formula evaluation**. Do not infer `casts=Quantity/5`, subtract refunds twice, infer `P(refund)` from saved units or promote all eight inputs to exact modern 2026 Retail numeric values. Blank refunds remain `null`.

**Next priority:** Dragonflight worker-owned append-only *same-study* corrections for the four R2 source rows (28, 52, 54, 62), plus checking the four R3 refund rows (53, 56, 58, 63) against existing worker evidence. Inspect source definitions of `Quantity`, `Ore Refund` and re-used ore before deriving net consumed per prospect. Confirm provenance/version and source ID mapping before pricing; verify a real 0..N completed-operation record with original output IDs and independent live-context eligibility before claiming a Retail rate. Continue Midnight T0005/T0039/T0045 original-cast/rank/refund priority in parallel. **No worker originals, addon, integration branch, main, schedule or source file mutated**.
