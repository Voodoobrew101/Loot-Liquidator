# Dragonflight workbook material-skill versus quality-threshold contract — 2026-11-08T16:04Z

**Scope:** coordinator-only research/source consistency check for open Dragonflight tasks T0041/T0046/T0020. No new study or independent cast cohort, no source overwrite, no change to profession mechanics, ItemDB, actual valuation, eligibility or tooltip.

## Primary records read

- Original native [DRAGONFLIGHT JC YIELD CALCULATOR](https://docs.google.com/spreadsheets/d/1B_CjPU0AUlJkbogauPTdo0W4dUZiP1hxZ8KMZX7qp3Q/edit), `Sheet1`: direct bounded native cell values and raw CellData reads of `F2:X5`, `D18:X29` (and `A1:AD24`).
- Research [mechanics registry](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/five-agent-completion/research/v3/mechanics.md): Dragonflight **D1** lists approximate 150 and 250 skill quality thresholds, status **likely**; **D2** reports rank-1/rank-2/rank-3 ore adding **+25/+56/+83** prospecting skill, also **likely**.
- Existing [2026-11-02 original-workbook audit](https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/research/v3/reviews/2026-11-02-dragonflight-jc-workbook-context.md) already flagged the 228-vs-218 arithmetic inconsistency and the 222 `EXPECTED` formulas all using `$F$7`; **do not re-credit** these as new findings or import the workbook's 444 pinned transcriptions as independent experiments.
- Independent [Retail Serevite quality-3 item listing](https://goldcap.gg/retail/kr/items/190394) confirms input ID **190394** corresponds to quality **3**; this corroborates the existing provisional mapping, not a new source cast count.

## Newly isolated cross-source contract conflict

1. The original workbook explicitly labels *all six* nominal 5,000-input-ore profiles as **input quality 3**, including Serevite columns F/I/L and Draconium columns P/S/V (`F5,I5,L5,P5,S5,V5 = 3`). Every one of its `F2/I2/L2/P2/S2/V2` effective-skill strings uses **`+63 From Material`**. The current D2 mechanics reference uses **+83 for quality-3 ore**, a **20-point discrepancy** for the same purported input quality. These are two sources from different contexts; neither proves an in-game coefficient or justifies overwriting the other.
2. The high-talent source blocks `L2`/`V2` say `100 + 63 + 55 = 228`, but arithmetic equals **218**. Using D2's unverified +83 instead gives **238**. All three candidate readings (218, labeled 228, or 238) are *below* D1's approximate quality-3 threshold 250. Nonetheless the workbook lists **quality-3 outputs** under those blocks: Mystic Sapphire `L22=12,V22=23` and Eternity Amber `L28=18,V28=26` (source raw material units per 5,000 nominal ore). This does not establish which skill number is correct or whether inspiration/procs, different thresholds, formula errors, or other source context explain the observations. It **does establish that treating D1/D2 as a proven deterministic gate or inferring a coefficient from this workbook alone is unsupported**.
3. The source calls the first skill profile `ZERO SKILL` yet states effective skill **68**. The six profiles also vary base skill and specialization simultaneously. They are **not controlled paired skill experiments**. The already documented `EXPECTED` sheet projections are invalid as independent measured outcomes; use only raw source-labelled `YIELD` totals in their original nominal-ore units when their context is supported.

## Evidence disposition and decision impact

- **Gap class:** incompatible source skill context and unverified threshold/coefficient, **not** absent output numbers, AH-price failure, or evidence of an existing runtime tooltip defect.
- **No promotion:** do not derive a +20 modifier, exact P(hit), observed casts, output rank probabilities, or current-character quality gating. Do not convert 5,000 nominal ores to 1,000 observed completed prospects without the original cast/refund ledger.
- **Keep usable raw numbers:** historical source-attributed nominal-ore material totals may inform labeled provisional estimates under the explicit source policy; preserve original rank and talent alternatives and unknown applicability.
- **Worker follow-up:** T0041/T0046 request original author/patch, profession tooltip showing actual `+material skill`, inspiration/stat conditions, source-level skill 218/228 resolution and input/output IDs. Reuse the existing pinned 444 transcriptions, not duplicate studies.
- **Integration handoff:** protected three-pass addon owner (not this branch) tests a synthetic rank-3 input/low-skill profile without treating D1's *likely* 250 as a proved hard exclusion. Any modification to mechanics or baseline requires a separately supported, reviewed change.

**Verification:** direct original Google Sheets read, current research mechanics read, 2026-11-02 prior audit read and retail item-rank listing check. **Not performed:** raw-cast recovery, new study, estimation rebuild, Lua suite, actual resolver/valuation/formatter fixture, in-game QA or financial-price validation.
