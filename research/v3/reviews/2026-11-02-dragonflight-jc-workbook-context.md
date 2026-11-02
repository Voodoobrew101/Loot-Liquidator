# Research Manager source QA — Dragonflight JC paired-profile workbook

**Reviewed:** 2026-11-02. **Disposition:** research-only source/context audit; no compiled import, estimator edit, worker evidence rewrite, or Retail eligibility claim.

## Original source and provenance

- [DRAGONFLIGHT JC YIELD CALCULATOR](https://docs.google.com/spreadsheets/d/1B_CjPU0AUlJkbogauPTdo0W4dUZiP1hxZ8KMZX7qp3Q/edit), tab `Sheet1`; native Google Sheets cells and **formulas** read directly, bounded to `A1:X55`. Google Drive metadata reports creation **2022-10-13T17:47:08Z** and last modification **2022-11-30T03:09:50Z**.
- Existing [pass-1 source inventory at the reviewed addon commit](https://github.com/Voodoobrew101/Loot-Liquidator/blob/3d667d053db587c91401cfed7ecc56862b8340c9/docs/usable-data-audit/source-inventory.json) already identifies **444 pinned evidence transcriptions** for this workbook. The inventory is on the addon branch, not this research branch; the immutable link also survives the owner-requested main revert. This review does **not** add 444 new studies or duplicate any original cohort.
- The workbook provides names, input rank 3, six source-labelled character profiles and output-quality labels, but **not** exact input/output item IDs, verified completed-operation counts, refund accounting, per-output hit counts, 0/1/2/... histograms, sample collection date, or current Retail patch verification.
- Source is historical Dragonflight-era material. The owner's MoP Classic illustration is unrelated and remains excluded.

## Six source-labelled profiles (do not pool or fit a skill curve)

| Source block | Input name in sheet | Input quality | Listed effective skill | Sheet's skill decomposition | Nominal input quantity | `EXPECTED CALC` row 7 |
|---|---|---:|---:|---|---:|---:|
| F:H | SEVERITE | 3 | 68 | 5 base + 63 material | 5,000 ore | 500 |
| I:K | SEVERITE | 3 | 113 | 25 base + 63 material + 25 tree | 5,000 ore | 10,000 |
| L:N | SEVERITE | 3 | **228 (disputed)** | 100 base + 63 material + 55 tree = **218**, not 228 | 5,000 ore | 10,000 |
| P:R | DRACONIUM | 3 | 68 | 5 base + 63 material | 5,000 ore | 10,000 |
| S:U | DRACONIUM | 3 | 113 | 25 base + 63 material + 25 tree | 5,000 ore | 10,000 |
| V:X | DRACONIUM | 3 | **228 (disputed)** | 100 base + 63 material + 55 tree = **218**, not 228 | 5,000 ore | 10,000 |

The sheet calls the first profile **“ZERO SKILL”**, but its own effective-skill line is **68**, not zero. The third profile's printed arithmetic differs by ten points; do not silently repair its skill to 218 or assume an unstated +10 bonus. Skill, base skill and talents change together between blocks, so these six profiles **cannot identify a causal skill-only coefficient**.

## Verified spreadsheet-formula inconsistency

For all **37 output rows (19–55)** in each of the six `EXPECTED` columns **H, K, N, R, U, X**, the formula refers to the *same absolute* `$F$7` projection input (**500**), rather than the corresponding block's row-7 value. This was checked against the native `FORMULA` view: **222/222** populated expected formulas use `$F$7`.

Five of the six blocks label their `EXPECTED CALC` as **10,000**, yet their output formulas project at **500**. Thus **185 expected cells** are inconsistent with their own block headers by a factor of **20** *if* those headers are intended to control projection. This is a **source-workbook formula/header discrepancy**, **not evidence of a bug in the addon**, and does not invalidate the separately listed raw `YIELD` cells.

Example: `I19=1025` Crumbled Stone units and `I6=5000` nominal Serevite ore. `J19=I19/$F$6=0.205` is units **per nominal ore**, **not P(hit)**. `K19=$F$7*J19=102.5` uses 500. A purely arithmetic 10,000-nominal-ore projection would be 2,050, but **neither projection is measured expected units per completed prospect**.

## Raw-source cross-checks (not new independent studies)

| Output row | Serevite profile 68 / 113 / disputed 228 | Draconium profile 68 / 113 / disputed 228 | Unit |
|---|---|---|---|
| 19, Crumbled Stone | 980 / 1025 / 1016 | 1036 / 947 / 986 | Workbook-listed raw material units per 5,000 nominal input ore |
| 20, Fractured Glass | 790 / 1106 / 1162 | 769 / 1079 / 1225 | Same |
| 27, Eternity Amber, quality “One” | 273 / 280 / 0 | 458 / 463 / 0 | Same; rank name not yet linked to an exact output item ID |
| 28, Eternity Amber, quality “Three” | 0 / 0 / 18 | 7 / 9 / 26 | Same |

The displayed `%` fields are raw material units divided by the nominal **5,000 input ore**. They are not per-cast occurrence probabilities. The sheet's `EXPECTED` values are projections, not a measured denominator or measured expected yield. The source's literal zero cells are zeros in the listed workbook block; they do not prove impossible drops in other contexts or a complete zero-outcome histogram.

## Import and worker handoff

1. **Protect existing source records.** Cross-reference the already pinned 444 transcriptions and original workbook revision before normalization. Do not append the same source as an independent study or combine rank alternatives.
2. **Prefer the six raw `YIELD` columns** (`F, I, L, P, S, V`) with original output-name/quality and the explicit 5,000-nominal-ore unit. Never import `EXPECTED` columns (`H, K, N, R, U, X`) as observed totals or infer `casts=1000` from 5,000/5 without verifying refunds/reprocessing and operation semantics.
3. **Keep skill contexts distinct** (68, 113, and unresolved 228-versus-218). Confirm the third profile's missing +10 or typo from original author before skill scaling. “Zero skill” is a label, not an observed minimum-required-skill baseline.
4. **Map exact input/output IDs and rank alternatives** with independent item evidence. Do not confuse the sheet's `PRISMATIC ORE` output with a new independently measured Prismatic Ore input cohort; do not convert output totals into hit counts or source percentages into P(hit).
5. **Retail applicability and valuation:** only a defensible historical/reference estimate with explicit assumptions may fill a supported gap. Leave P(hit), conditional yield, cast histograms, patch comparability and skill coefficients unknown until sourced. Never import the workbook's cached `EXPECTED` projections or frozen prices as live EV.
6. **Integration handoff:** [PR #24](https://github.com/Voodoobrew101/Loot-Liquidator/pull/24) was merged and then reverted at the owner's request. Its repaired code is preserved in unmerged [replacement draft PR #27](https://github.com/Voodoobrew101/Loot-Liquidator/pull/27), `repair/pr24-restored`. This source audit does not authorize an addon snapshot refresh or another import PR. Existing S21 and migration PRs #22/#23 remain separate.

## Verification performed and limitations

Direct native Google Sheets **values** and **formulas** were read and cross-checked for six contexts and 37 output rows. Formula audit: six columns × 37 cells, 222 referencing `$F$7`; five block headers disagree with their formulas. The original sheet's source metadata was inspected. **No** local addon build, full migration regeneration, Lua tooltip execution, live WoW session, or current-patch measurement was performed in this source audit.

**Research priority:** original-author context/denominator confirmation and output-ID mapping; reuse the pinned source before asking workers for duplicate studies. Existing Dragonflight tasks T0020/T0041 can carry the source-context follow-up without changing worker ownership or open-task counts.
