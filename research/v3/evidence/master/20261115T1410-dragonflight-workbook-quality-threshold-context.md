# Dragonflight JC workbook: quality-threshold applicability check (source context, not Retail measurement)

**Checked:** 2026-11-15 UTC. **Scope:** historical Dragonflight source-only numeric/identity reconciliation. No new study, casts, Retail eligibility verification, estimate generation, valuation, or client QA.

## Primary workbook and source coordinates

- Original, read as a native Google Sheet (both formula and numeric/value views): [DRAGONFLIGHT JC YIELD CALCULATOR, Sheet1](https://docs.google.com/spreadsheets/d/1B_CjPU0AUlJkbogauPTdo0W4dUZiP1hxZ8KMZX7qp3Q/edit).
- Existing independent [2026-11-02 manager workbook review](../../reviews/2026-11-02-dragonflight-jc-workbook-context.md) already documents the `$F$7` projection error, arithmetic mismatch in effective skill 228 versus 218, original source context, and **444 previously pinned transcriptions**. This is a distinct, additional **cross-profile quality-threshold contradiction check**, **not a second import**.
- Source `A4:B5` calls prospecting quality thresholds **Two Star = 150** and **Three Star = 250**. `F2/I2/L2` and `P2/S2/V2` label effective skills **68, 113, 228** (the 228 decomposition disputes itself: 100+63+55=218). `D5`/block input rows mark input quality **3**; each source block lists **5,000 nominal input ore** in row 6. No actual completed cast ledger or refunds is supplied.
- Output `D19:D55` supplies quality names **One / Two / Three**. Raw material quantities are in columns `F,I,L,P,S,V`; the percent and EXPECTED columns must **not** be treated as probability or original measurements.

## Direct source value check, all rows 19–55

| Workbook input | Stated effective skill | Raw-YIELD column | Positive quality-Three rows | Sum of quality-Three source quantities | Positive quality-Two rows |
|---|---:|---|---:|---:|---:|
| Serevite | 68 | F | 0 | 0 | 10 |
| Serevite | 113 | I | 0 | 0 | 10 |
| Serevite | 228 (arithmetic disputed) | L | 10 | 95 | 10 |
| Draconium | 68 | P | **11** | **149** | 0 |
| Draconium | 113 | S | **11** | **80** | 0 |
| Draconium | 228 (arithmetic disputed) | V | 11 | 212 | 11 |

**Concrete Draconium below-threshold cells:** `P22=10`, `S22=6` for quality-Three Mystic Sapphire; `P28=7`, `S28=9` for quality-Three Eternity Amber; `P54=1`, `S54=1` for quality-Three Illuminated Diamond. Every row's rank label was read from the same workbook; no item-ID assignment was inferred.

## Finding and conservative use

**The workbook's own Draconium quality-Three positive source quantities at effective skills 68 and 113 conflict with interpreting its headline 250 threshold as a universal hard gate on quality-Three output for all listed ore profiles.** The source may instead mix ore families with different rules, use mismatched labels, or contain author errors. These alternatives are *unresolved*. The internal contradiction alone neither validates the under-threshold rows as current Retail behavior nor proves that the addon presently makes this mistake.

The source may still provide **historical context-specific raw output quantities** at 5,000 nominal ore per profile, with explicit context and provenance. It **cannot** establish a general skill curve, current-character eligibility, per-cast occurrence probability, exact output rank item IDs, completed-operation denominators, Resourcefulness-adjusted net consumption, or current Retail values. Do not fit or apply a 150/250 blanket hard gate to this workbook without corroborated recipe/ore-specific scope. Do not promote the 37x6 raw rows as new independent experiments; the owner implementation already pinned 444 source transcriptions. Do not interpret zeros outside their individual profiles as universal impossibility.

## Follow-up and validation boundary

- **Dragonflight T0020 / T0041 / T0046**, within existing worker ownership: seek original-author clarification of what the thresholds condition, Draconium 68/113 quality-Three identities, profile rank and patch; match output item IDs from an independent original source and determine whether columns reflect independent observations or projections. Do **not** ask to redo the sheet's already-pinned extraction.
- Any reviewed import/tooltip test should check all six quality alternatives without summing mutually exclusive ranks, use supported mean/value without inventing P(hit), and separately gate actual Retail recipe/character eligibility. Only owner-controlled three-pass integration may change addon ingestion, valuation or tooltip behavior.
- **Actually executed here:** read native workbook values and formulas, checked source metadata, grouped all 37 rows by quality for six raw-YIELD columns, compared with prior review, refreshed research queue and status, and verified prewrite GitHub heads/CI. **Not executed:** Python compiler, full migration validation, Lua synthetic-price engine/formatter, current-game runtime, live client or source-author interview.
