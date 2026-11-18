# Dragonflight Jan 2023 Serevite / R3 Illimited Diamond: repeated 5-unit cohort and original-source unit gate

**Coordinator audit:** 2026-11-18T13:04:22.484Z UTC. **Scope:** research-only, source-lineage and numerical admission audit; **not** new verified current-Retail rates, gold recommendations, or tooltip coverage. Original worker files and frozen 4df9ae8 snapshot unchanged.

## Bounded identity comparison

The Dragonflight worker's 2026-11-18 12:38Z file contains three lines from the same January 3–4, 2023 weekly Reddit discussion ([original discussion](https://www.reddit.com/r/woweconomy/comments/102436o)). They are not three independently new studies.

| New record | Source assertion, units, context | Prior lineage / admission |
| --- | --- | --- |
| `dragonflight-20261118-12371` | One 1,000-*nominal-ore* Serevite batch → **5 rank-3 Illimited Diamond item units** (`192871`); input rank unstated; completed 5-ore operations, hits, refunds and 0..N bins unknown | **Already transcribed** as `dragonflight-20261101-133007` in `2026-11-01T1330-milling-beta-reference-and-serevite-block-zeros.jsonl`, present even at the frozen snapshot commit `4df9ae8`. Both quote the same firsthand statement at the same source URL, input family/output rank and total of 5; changed `studyKey` and newly supplied mechanical `inputsPerCast=5` are **not** a new experiment. Do not count twice. |
| `dragonflight-20261118-12372` | A different commenter claims **1 rank-3 diamond per 1,000 nominal rank-3 Serevite ore on average**, input item `190394`, output `192871`; self-reported ~83 JC /266 effective skill and prospecting specializations | Candidate **distinct reference-quality self-reported mean**, not a single exact 1-unit 1,000-ore trial and not measured per-cast occurrence. Completed operations, number of batches, output hit count, zero bins and Resourcefulness basis unknown. Bounded previous-evidence checks found no matching old exact claim; source author/permalink and source-era applicability still need confirmation. |
| `dragonflight-20261118-12373` | Another commenter reports **1 rank-3 diamond item** in their *first* 1,000-nominal-ore Serevite batch; other tries/total sample size unknown, input rank unspecified | Candidate **distinct firsthand first-batch quantity report**, not a measurement of chance, total lifetime operations or mean; current Retail comparison and dedupe against non-indexed archives still pending. |

The original 2023 thread uses nominal **ore** as its unit. A five-ore recipe is documented by mechanics G1; dividing a claimed nominal 1,000 ore by five would produce 200 *nominal five-ore equivalents*, **not a verified count of completed casts** with refunds/reprocessing. `totalQuantity=5` and `1` are output **item units**, not `castsWithDrop` or a 5%/1% chance. `averageShown=1, averagePer="1000 inputs"` may be converted arithmetically to **0.005 units per nominal five-ore equivalent**, but that is a source-reported, character-conditioned historical mean with missing sample denominator, not an observed per-cast unconditional rate on a current Retail character.

## Compiler/admission consequence (static inspection only)

`research/v3/tools/build_estimates.py` forms study identity from normalized source, input rank, cast count and numeric study vector; `studyKey` alone does not confer independence. The repeated 5-unit cohort has the same source and bounded numeric fingerprint, despite `studyKey` and `inputsPerCast` differences. The total-only rows have no `casts` or `inputsProcessed` and therefore lack an estimator-eligible denominator for `totalQuantity`.

The compiler's `row_use` and `SMALL_STUDY_CASTS=20` path can assign **model weight** to a self-reported average without observed cast counts; do **not** describe those 20 modeled units as player operations or statistical evidence. No complete compiler run, offline actual valuation/rendering, Lua, or in-client QA was executed, so no compiled double-count or gold effect has been proven.

Prior research [2026-10-30 rank-identity audit](../../../evidence/v2/2026-10-30T1825Z-F004-df-serevite-rank-id-and-diamond-cross-quality.json) places R3 Serevite at `190394` and R3 Illimited Diamond at `192871`; confirm primary itemLink/quality before any rank-specific current Retail transfer. January 2023 character skill and patch epoch cannot be treated as current Retail (2026). Because all three rows share a **thread-level URL** and `source.author=null`, recover exact comment permalinks/authors before independent weighting; do not dedupe separate commenters merely because they share a thread.

## Verification and limits

**21/21 in-process JavaScript assertions passed**, checking old/new JSONL content, shared identity, 5-item match, distinct candidate numeric definitions, missing denominators, batch units, and static compiler source. The historical source was cross-referenced by two repository transcriptions; **direct Reddit fetch was blocked in this run**. No Python estimator, imported snapshot refresh, actual valuation engine, tooltip renderer, WoW client, CI trigger or addon build was executed. This is a **bounded evidence-file comparison**, not exhaustive cross-archive source deduplication.

**Priority:** pursue T0005/T0039 original post-release Umbral Tin 237362 rank-specific zero-inclusive event logs/skill/refunds; T0045 236761 ten-herb mill event ledger; Dragonflight T0046 source-permalink/actual 5-ore completed operations without recycling this already-pinned 5-diamond study. Source and worker originals remain append-only. PR Director-only merge; owner three-pass branch untouched.
