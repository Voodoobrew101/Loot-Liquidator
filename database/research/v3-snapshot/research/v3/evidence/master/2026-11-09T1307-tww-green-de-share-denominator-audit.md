# TWW September 2024 uncommon disenchant rank-percent unit-basis audit

Checked UTC: 2026-11-09T13:07:25.382Z. Research parent: `19da10c531c7f935dfb6e3761d46c06524af34cf`.

## Primary source and original archived rows
- [Original firsthand Reddit discussion](https://www.reddit.com/r/woweconomy/comments/1fc2j1m), comment dated 2024-09-09: author gives R1 **35.42%**, R2 **44.28%**, R3 **20.30%**, and separately **2.85 dust units per disenchant** for a max-level enchanter with **60 points** in uncommon/green disenchanting. The author references iLvl 558 vs 561 weapons, and anecdotal **1x R1** and **6x R3** outcomes. The post does **not** explicitly define whether each rank percentage is a **fraction of disenchants**, **fraction of material units**, or another tracking basis.
- Worker records [001–004](../../war-within/2026-11-09T1235-green-de-original-rank-share.jsonl) accurately preserve the quoted numbers but **assert** “percent of pooled dust material quantity” in notes; the source snippet does not establish that denominator. This is a **source-unit ambiguity for review**, not evidence that the worker fabricated numbers.
- The three percentages sum to **100.00%**; this does **not** distinguish material-unit shares from categorical per-operation rank shares. No independent raw tracker, spreadsheet formula, total units by rank, completed-operation count, or per-cast rank/stack histogram was found in the inspected original-thread text. Unknowns remain unknown.

## Calculation boundary
Only **if** the source author confirms the three percentages are shares of the *same pooled output-unit total* whose mean is 2.85, then hypothetical rounded unconditional rank means per disenchant are:
- R1 Storm Dust 219946: `2.85 * 0.3542 = 1.00947` units/cast.
- R2 Storm Dust 219947: `2.85 * 0.4428 = 1.26198` units/cast.
- R3 Storm Dust 219948: `2.85 * 0.2030 = 0.57855` units/cast.
- Sum = `2.85` units/cast, consistent arithmetically; **these are conditional hypotheses and are NOT validated estimates or import recommendations.**

If instead the percentages are rank-outcome *event frequencies*, multiplying `2.85 * rank event fraction` is **generally invalid**, because conditional per-rank stack sizes can differ (the original author even describes a 1-unit R1 event and a 6-unit R3 event). If rank output co-occurrence is possible, even event probabilities need an explicitly defined event denominator.

## Disposition, exact remaining gaps
- **Usable but unverified field:** source-stated **pooled mean 2.85** dust units per green disenchant, historical **September 2024** and skill/spec conditional, with **unknown cohort size, exact item IDs/gear mix and current patch applicability**. It is not three independently observed per-rank means.
- **Not supported:** rank-specific P(hit), average units/rank/cast, per-output histograms, zero-output counts, raw quantities, current Retail 2026 per-item gold decision. No zero-inclusive sample is established.
- Seek the original tracking spreadsheet or author clarification: what did the 35.42/44.28/20.30 percentages divide by; were mixed-rank outputs counted together; can original per-rank material totals, actual completed DE count, equipment skill and weapon/armor iLvl breakdown be recovered?
- Keep original worker JSONL immutable; ask its owning worker/validation engineer for append-only denominator correction once independently sourced. Do not infer coefficients, measured P(hit), or silently change the owner's protected three-pass addon branch.
- This audit read source text, existing evidence and performed arithmetic only. It did **not** run estimator, ItemDB build, synthetic-price actual-engine valuation/tooltip, or in-game WoW checks. New independent casts, verified current gold decisions and rendered tooltip fields: **0, 0, 0**.
