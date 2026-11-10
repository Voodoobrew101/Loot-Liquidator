# Newly discovered Drive prospecting source: Silver denominator and reference-matrix gates — 2026-11-10 10:14 UTC

**Research-only provenance/units review.** No new measured completed casts, output occurrence counts, rank-linked itemLinks, live prices, compiled figures, or actionable current-Retail gold decisions were established. Do not import this as a cast study, overwrite existing reference means, or alter the separate usable-data integration branch. New findings are source inventory and seven *formula-described candidate unit ratios*, **not** verified player outcomes.

## A. Previously uninventoried original native sheet, “prospecting”

Source: [native Google Sheet, tab “prospecting example”](https://docs.google.com/spreadsheets/d/1f-d39_TW0MARV5Egib2IPuW8kTU5-_C8PIgAkz2A4IU/edit), retrieved via connected Drive native CellData/formula read 2026-11-10, original sheet last modified 2026-07-03. It also contains a separate “alloy example” tab, not an ore prospecting sample. This document is **not listed** in the four spreadsheet entries of the previously reviewed `docs/usable-data-audit/source-inventory.json` on `implementation/usable-data-tooltips`; inventory omission is not proof of a runtime defect.

The sheet's `C1` says **“Brilliant Silver”**, and `A10` says **“R2 Brilliant Silver”**. Queue candidate is Brilliant Silver Ore `237364`, but **the sheet contains no input itemID or player itemLink**, so `237364` is a *candidate*, not a verified source identity. The material shorthand contains no output item IDs or quality-linked output itemLinks.

Direct original **H1:H7 formulas** and displayed results (formula numerator is an unlabelled total, not an authenticated player receipt; `/2000` is an arithmetic denominator, not an observed cast count):

| Original row | Source shorthand | Original formula | Formula result |
|---|---|---|---:|
| 1 | Stone | `=2734/2000` | 1.367 |
| 2 | Glass | `=1810/2000` | 0.905 |
| 3 | Diamond | `=127/2000` | 0.0635 |
| 4 | Lapis | `=437/2000` | 0.2185 |
| 5 | Flaw Lapis | `=386/2000` | 0.193 |
| 6 | Garnet | `=445/2000` | 0.2225 |
| 7 | Flaw Garnet | `=367/2000` | 0.1835 |

These seven *conditional source-ratio expressions* sum to 3.153 units per formula denominator **only if** all source numerators share one compatible population and processing unit; this is a mathematical projection, not a supported unconditional expected-quantity estimate. The sheet separately labels `E6` **“Casts”** and `E7=1000`, whereas all H formulas divide by **2000**. The `B10` and `C10` profitability formulas multiply the H ratios by `E7`, and assume `5 × E7` input ore and manually entered item prices. This is **two different denominators in one example**, not evidence of 1,000 nor 2,000 independent completed original casts, or an automatically diagnosable 2× error. It may simply project one sample/rate over a different scenario size. Neither period, collector, event log, refunds nor provenance of the numerators is stated. `Diamond` must additionally be subject to ore-specific Eversong specialization unlock and its exact output rank; cannot price it for an unverified player.

**Do not** treat H=0.0635 as P(hit) or infer a positive-yield histogram. `inputsPerCast=5` is a general Midnight Prospecting rule, but this sheet does not contain actual operation receipts. The sheet's source prices and post-AH profits are scenario figures, not market-value observations. Compare to existing independent June 10 Cardinalai Silver 800-cast total in [previous cross-study source note](../../../evidence/observations/2026-10-28-1611-midnight-q18-batch016-source-only-crossstudy.md); that author reported 43 diamonds over 800 completed operations with 715 refunded ore, while **this sheet does not identify its data source**. Similar outputs/names alone do not establish shared original identity or justify pooling.

**Classification:** original spreadsheet present; seven *computable but unverified provenance/unit ratios*; `sourceKind=reference / calculator` at most, not `study`. Source exact input identity/rank, row-output rank IDs, true denominator basis, observation epoch, profession spec, raw casts, P(hit), zeros, refunds and current-game applicability remain unknown. No owner-approved evidence has justified overriding the already supported data.

## B. Additional previously uninventoried 2026 workbook (historical/mixed modes)

Source: [`wow_prospecting_database_incomplete.xlsx`](https://docs.google.com/spreadsheets/d/11kVrPOVY0Jei3xmBL1q_I9fsFAl3QY6d/edit), user-accessible Excel workbook; Drive file created 2026-10-27. Retrieved original readable extraction via Drive connector. Its guide tab explicitly dates the compilation **2026-10-27**, describes **387 ore-to-output matrix rows spanning 41 ores / 11 expansions**, gives **212** reference probability rows and **104** empirical-per-five-output rows, and points to historical/Classic/PTR/general guides. These are workbook self-reported table summary counts, **not independent research studies**. Separate tabs document excluded ores and a guide to uncertainty. The current integration inventory does not list this workbook, so the source's row-level lineage/admission status merits a *bounded* inventory audit.

Concrete worksheet examples: TBC Adamantite `23425 → Adamantite Powder 24243` lists **65%** with minimum 1 and unknown maximum; Wrath Titanium `36910 → Titanium Powder 46849` lists **57%**, min 1/max 5; Midnight Dazzling Thorium `237366 → Eversong Diamond 242608` lists **“~22%”**, nominal positive unit 1. **None are claimed measured 2026 Retail rates**. Probabilities, if retained as source-stated percentages, need original reference lineage/denominator semantics before being used. Diamond is conditional on specialization; a source's displayed yield-1 approximation is not an observed positive stack histogram. Main worksheet output ID may be just one reference variant rather than a verified full rank mapping (its own guide explicitly warns of this). Workbook cites a **MoP Classic** prospecting table among sources: under the owner’s explicit instruction, neither the MoP Classic illustration nor Classic-only rates may be promoted as Retail evidence. Do not infer live Retail context from worksheet title. Treat reference-only data as gap-only with label, never overwrite a better measured estimate. No spreadsheet instructions, prices, or generic profit projections were imported.

## Direct validations and remaining work

- Read native `prospecting example!A1:J12` with user-entered **formulas**, not just displayed values, read `alloy example!A1:J13`, and independently inspected existing integration source inventory and earlier Cardinalai source-specific research note.
- Retrieved complete readable extraction of the Excel workbook and checked its first/last rows, modern output rows, guide, per-expansion self-summary and non-prospectable-ore notes. Did not execute a source-to-addon compiler/estimator or native Lua/tooltip tests.
- New independent measured cohorts **0**; newly verified formula-field relationships **7**; new source files identified outside existing integration inventory **2**; output IDs validated as event receipts **0**; Retail gold decisions added **0**.
- **Next T0002/T0006/T0039 source gate:** request or locate original event log for the Silver sheet's unlabelled 2,000-denominator numerators, identify whether source population is 1,000 vs 2,000 operations or separate projection, input rank and output itemLinks, time/build, skill/unlock and refund-adjusted five-ore batches; dedupe against Cardinalai by author/study before admission. For workbook 387-row matrix, inspect author/source provenance *per row* and determine overlap with frozen reference tables before any import, prioritizing missing values rather than its raw volume. Preserve unknown fields; no worker assignment/schedule change.

Protected: `main`, `implementation/usable-data-tooltips`, original sheets, existing research studies, queue, and worker files unchanged.