# Legion prospecting Gem Chip: original-sheet formula is not an observed yield (2026-11-08 UTC)

**Disposition:** Source-identity/numerical provenance correction candidate; zero new measured casts or per-cast histograms; no direct current Retail valuation or in-game tooltip claim. This note independently resolves an existing *open* flag without altering the append-only original research or worker-owned evidence.

## Primary-source verification (native Google Sheets CellData, not copied values)

Original [Glizzerd/Wubbits Legion Prospecting workbook](https://docs.google.com/spreadsheets/d/1a415g8FlUJ_EdC8TlA6U2Yzz8KSh9PA2WvV0dAsPLnM/edit), tab `Sheet1`, was read directly in both value and formula form:

| Cohort | Source operations | Cell | Native stored expression | What it means |
| --- | ---: | --- | --- | --- |
| Leystone Ore 123918 | `K2=6674` (literal) | `E16` Gem Chip count | **`=K2`** | Gem Chip count copied from number of prospects, not an independently entered observation |
| Leystone Ore 123918 | same | `H16` Gem Chip rate | **`=E16/$K$2`** | Rate algebraically fixed at 1 |
| Felslate 123919 | `K19=2112` (literal) | `E33` Gem Chip count | **`=K19`** | Gem Chip count copied from number of prospects, not an independently entered observation |
| Felslate 123919 | same | `H33` Gem Chip rate | **`=E33/$K$19`** | Rate algebraically fixed at 1 |

Independent cross-check: non-chip gem total cells `E2=33`, `E9=210`, `E19=47` and `E26=220` are entered **numeric literals**, unlike the Gem Chip total cells. The source's `J1=K2*5` (33,370 ore) and `J18=K19*5` (10,560 ore) are likewise formulas; `K2/K19` are the supplied prospect counts. Neither `E16` nor `E33` is a raw per-operation Gem Chip histogram or independently counted yield.

## Exact stored evidence and risk

Original research-only worker file: [`research/v3/evidence/legacy/2026-10-31T0039-legion-prospecting-original-studies.jsonl`](../../evidence/legacy/2026-10-31T0039-legion-prospecting-original-studies.jsonl), records `legacy-20261031-013` and `legacy-20261031-026`. These currently encode `sourceKind:"study"` with `totalQuantity:6674` and `totalQuantity:2112` and have null `castsWithDrop`/histograms. The counts **8,786 combined** are worksheet-derived arithmetic, not 8,786 separately observed Gem Chips. This exact concern was raised, but not source-resolved, in `research/v3/flags.jsonl` on 2026-10-31; no corresponding correction for these IDs was found in the current `corrections.jsonl`.

**Do not erase or rewrite these records.** For statistical measured-yield use, propose audited `totalQuantity:null` corrections via the approved additive correction layer after the Legacy owner reviews the source. Separately, the workbook provides an **explicit formula-level assumption** of one Gem Chip per prospect. It may be considered only as a labeled *reference/fixed-quantity candidate* if the ItemDB mapping, original processing rules and Retail applicability support it; do not represent it as a measured P(hit)=100% or unconditional observed output. A distinct source elsewhere reportedly contains 742 chips / 3,200 Felslate ore and may have a different observation/refund basis; do not combine or force its denominators to match without inspecting that original.

## Research handoff and validation limits

**T0042 / Legacy evidence owner:** verify the workbook as above; append auditable corrections for these two numeric fields or a new qualifying source/reference record preserving `=K2` / `=K19` provenance, source-era and processing conditions. Check whether other materials in the two studyKeys are recorded literals and whether multiple source copies would multiply evidence weight. Do not request new observational studies until this original-workbook reconciliation is performed. The separately owned three-pass implementation decides actual supported ItemDB/tooltip value selection after deterministic offline engine validation.

**Performed here:** native Google Sheets bounded value and CellData formula reads; direct GitHub read-back of both worker records, schema, source flag and corrections lookup; exact arithmetic `6674+2112=8786`. **Not performed:** Lua/tooltips/pricing tests, live WoW-client confirmation, independent Gem Chip drop-rate measurement, current Retail method eligibility, or new addon commits. Original workbook, worker evidence, main and owner implementation branch unchanged.
