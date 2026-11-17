# Coordinator source-cell and rank identity audit — Xenastro historical diamond batches — 2026-11-09 00:02 UTC

**Scope:** Independent research-only readback of Dragonflight worker's latest `2026-11-08T2349-original-xenastro-ranked-epic-ore-logs.jsonl`. This is validation of nine existing historical 2023 author batches, **not new casts**, a new worker study, import approval, current-character gold valuation, a reconstructed chance distribution, or a runtime tooltip test. Original source and all worker records remain append-only and unchanged.

## Original workbook check performed

Fetched the original stored [Prospecting Calculator V1.xlsx](https://docs.google.com/spreadsheets/d/1jW-vz25Mha9GzeCe6qX9viuLyFsgDf2m/edit) using connected Google Drive's readable Excel extraction. Selected its **Prospecting Log** sheet (the third extracted sheet; not the price/reference sheet). Parsed the source CSV row index; compared **all 26/26** worker rows with source `Epic Q1` / `Epic Q2` / `Epic Q3` unit cells, ore name, input quality, original date, reported nominal inputs and refund fields. **All 26 values and linked source-row identities match**, with no source-cell numerical mismatches. Nine distinct dated original workbook rows from one author account for the 26 output-rank measurements. Positive rank-unit totals: **Q1 = 3; Q2 = 33; Q3 = 118; all ranks = 154 units**. Blank Khaz'gorite Q1 is **not** a measured zero and was correctly omitted. Explicit zero-valued Serevite unit cells are source tabulations, **not** cast-level zero-outcome counts.

| Source CSV index | Original batch | Source Epic Q1 | Q2 | Q3 | Original nominal ore | Catalog input ID (rank) |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| 28 | Khaz'gorite Q2, Jan 3 | blank | 7 | 1 | 1,000 | 190313 (Q2) |
| 31 | Serevite Q2, Jan 6 | 0 | 12 | 6 | 15,000 | 190396 (Q2) |
| 33 | Serevite Q2, Jan 7 | 1 | 6 | 3 | 9,000 | 190396 (Q2) |
| 34 | Serevite Q2, Jan 8 | 0 | 4 | 1 | 8,050 | 190396 (Q2) |
| 35 | Serevite Q3, Jan 8 | 1 | 0 | 10 | 6,090 | 190394 (Q3) |
| 40 | Serevite Q3, Jan 10 | 0 | 1 | 13 | 8,523 | 190394 (Q3) |
| 41 | Serevite Q3, Jan 11 | 0 | 0 | 19 | 16,859 | 190394 (Q3) |
| 42 | Serevite Q3, Jan 12 | 1 | 0 | 22 | 13,000 | 190394 (Q3) |
| 43 | Serevite Q3, Jan 13 | 0 | 3 | 43 | 30,000 | 190394 (Q3) |
| **Total** | **Nine existing batches** | **3** | **33** | **118** | **107,522** | |

**Independent secondary catalog cross-check, not original spreadsheet claim:** [Khaz'gorite Q2 = 190313](https://goldcap.gg/retail/us/items/190313); [Serevite Q2 = 190396](https://goldcap.gg/retail/us/items/190396); [Serevite Q3 = 190394](https://goldcap.gg/retail/kr/items/190394). The original workbook explicitly labels output "Illimited Diamond" Q1/Q2/Q3 on the first sheet, and current Retail catalogs confirm [192869 = Q1](https://goldcap.gg/retail/us/items/192869), [192870 = Q2](https://goldcap.gg/retail/us/items/192870), [192871 = Q3](https://goldcap.gg/retail/us/items/192871). This closes the *catalog identity lookup* for all nine input cohorts, but **does not turn catalog IDs into a source-observed original itemLink**, validate material output eligibility in current Retail, or authorize worker-file editing. Original worker `inputItemID=null` remains intact for controlled source/model review.

### Collision guard: CSV index is not Excel worksheet row

The readable extraction's source index `28` is **Khaz'gorite Q2**, while a previously audited **Excel worksheet row 28** is **Draconium Q2** (CSV index 26). The 2026-11-08T1908 coordinator audit established **worksheet row = CSV index + 2** for this workbook. Source identities must retain explicit `csvIndex` versus `excelRow`; a generic "row 28" risks cross-ore contamination and duplicate weighting. In particular, new CSV 28 is Excel 30; CSV 31 = Excel 33; CSV 33 = Excel 35. The new nine index values are not the prior Draconium Q2 spreadsheet rows 28/52/54/55/62. Verify all future `studyKey` aliases by original workbook batch date + ore + quality + nominal quantity, not solely a row-number string.

## What remains unknown / disposition

- All **completed operation counts, per-material castsWithDrop, zero-inclusive histograms, positive stack ranges, original patch/build, talent specification, refund-reprocessing semantics, and live-game validation** remain unknown. The 107,522 nominal ore cannot be divided by 5 into measured casts. Individual original source transactions were not available.
- **154 reported diamond output units are historical original quantities**, not a new measured cast population, occurrence chance, or a present-day actionable EV. No custom rank/scaling/Resourcefulness coefficient was derived. All 26 worker rows remain unmodified.
- This checkpoint performed native XLSX readable-source comparison and six Retail catalog ID page checks; **no addon source, importer, estimator, Lua suite, synthetic-price valuation, tooltip renderer, live WoW QA, PR merge/closure/release, or schedule** was executed.
- **Next:** preserve source CSV vs worksheet offsets in the worker's provenance and confirm input rank-to-item IDs through an authoritative itemLink/Item API where possible, then seek cast logs/refund reuse before any per-operation valuation. The protected three-pass owner alone controls addon integration.
