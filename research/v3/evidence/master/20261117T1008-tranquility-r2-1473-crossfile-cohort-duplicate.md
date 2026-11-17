# Tranquility Bloom R2 — duplicated 1,473-pigment original and case-sensitive family-key hazard

**Date:** 2026-11-17 UTC. **Scope:** research-only input/output identity and cohort lineage. **New independent casts or Retail gold decisions: 0.** No addon or shared worker files changed.

## Original evidence, not two independent experiments

[The original March 15 2026 commenter](https://www.reddit.com/r/woweconomy/comments/1rteoqr/no_money_gain_possible_with_inscription_mats/) reported buying **1,000 rank-2 Tranquility Bloom** and getting **1,473 unspecified pigments**. The count is a total for one reported transaction, **not** measured completed mills, consumed herbs net of Resourcefulness, an exact pigment ID/rank, or per-operation occurrences/histogram. It predates the March 31 Midnight prospecting hotfix; retain collection/patch uncertainty separately rather than extrapolating.

Two existing, append-only worker rows independently *transcribe the same commenter*, not independent cohorts:
- `research/v3/evidence/midnight/2026-11-03T0210-tranquility-bloom-r2-player-milling.jsonl`: `midnight-20261103-0210-001`, studyKey `reddit-1rteoqr-20260315-tranquility-r2-1473`, inputRank=2, totalQuantity=1473, outputName **`Pigment (unspecified)`**.
- `research/v3/evidence/midnight/2026-11-03T1310-tranquility-bloom-pooled-pigment.jsonl`: `midnight-20261103-1310-001`, studyKey `reddit-1rteoqr-tranquility-bloom-1473`, same URL/rank/1473 count, outputName **`pigment (unspecified)`** (lowercase p), source publication metadata says March 14 although its note says March 15. These are duplicated transcriptions, not two 1,473-unit outcomes.

Both rows explicitly retain `casts=null`, `inputsPerCast=null`, `castsWithDrop=null`, `inputItemID=null`, `outputItemID=null`. The existing independent catalog identity `midnight-20261109-1713-005` identifies rank-2 Tranquility Bloom as **item 236767** using [rank-2 commodity catalog](https://goldcap.gg/retail/us/items/236767), with nominal 10-herb milling recipe spell 1269575. This is a valid **input identity crosswalk**, not proof that the original commenter had this exact item link or actually completed 100 ten-herb mills. Existing powder-pigment rank identities 245807 and 245808 are **alternatives**; assigning either to the unspecified 1,473 pigments would be invented output-rank evidence.

## Compiled-model risk and actual disposition

At current research head, `research/v3/tools/build_estimates.py` `key_of` uses `"family:" + r["outputName"].strip()` without lowercasing the unknown-ID fallback, so the two source rows can form **distinct case-sensitive family output keys** if no exact output mapping is available. `study_vectors` uses the normalized source URL but marks equal-vector same-batch-family transcriptions separately by appending a `("batch", ...)` sentinel rather than globally suppressing them. A future naive backfill of a cast denominator or an output family could therefore create false distinct estimate groups or double weight the one original transaction. The current records lack denominator/processed-input context; **no numeric estimate or lost current gold value is established by this audit**. The actual compiler/renderer were not executed here.

**Safe follow-up:** retain both original rows unchanged; add a reviewed provenance-based alias/exclusion correction or compatible source-cohort dedupe in an isolated research engineering change **before** any denominator/ID promotion. Map the input rank 2 to catalog ID 236767 only as a supported identity with provenance. Obtain the original participant's actual consumed-herb quantity, completed 10-herb mills, all pigment output links/ranks, skill/spec and Resourcefulness history before computing expected units or output chance. Do not assume 1,473/100 is a measured per-cast yield, do not add both 1,473 counts, and do not add 245807 plus 245808 as two outputs.

**Validation actually performed:** 18/18 bounded JavaScript assertions on GitHub-fetched original JSONL rows, the catalog crosswalk and current compiler source; 0 failures. This is source and static-code inspection only: no local Python compiler, native Lua, actual runtime/tooltip, GitHub CI-on-new-head or live WoW run. The source files and compiler were not altered.

**Input blobs verified:** `0e8255b63e290bb9d94635f3072cb86a1493aa96`, `77cf5005b61585becaceb65e84af4f7dfa4f65e8`, catalog `64293d1ca735b4caab26cd0bc5b81c971cde99ba`, compiler `0b09b553fef4214af8aaa93f1c85061956643711`.
