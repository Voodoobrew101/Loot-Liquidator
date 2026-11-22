# Midnight JD3K 50-ore nominal-operation denominator review — 2026-11-22T10:02:11.815Z
 
**Scope:** targeted source/unit correction of an already known lineage, not a new study, not a reopened Codex 731-source catalogue and not a runtime test.

## Independent primary-source check
[JD3K's original Midnight Prospecting comment](https://www.wowhead.com/spell=1231127/midnight-prospecting) reports three separate **50 quality-2 ore input** trials: Umbral Tin, Brilliant Silver and Refulgent Copper, with 17 named material output totals in all. It reports no profession specialization points, tools or accessories; it does **not** report successful completed cast count, refund ledger, per-operation zeros, event histogram, collection patch/date or output-quality item ID. The [spell itself](https://www.wowhead.com/spell=1231127/midnight-prospecting) consumes **5 ore per execution**. Thus 50 / 5 = **10 nominal five-ore operation equivalents per input type**; this is not independently witnessed successful operations.

The pre-existing [original F004 v2 source review](../../../../evidence/v2/2026-10-30T0333Z-F004-midnight-r2-prospecting-JD3K-totals.json) already correctly records `actualCompletedCasts: null`, `nominalOperationEquivalents: 10`, and unverified refund counts. The later v3 source transcriptions each set `casts: 10` without the supported `castsBasis` provenance field. This is a deterministic loss of denominator type across representations, **not** new observed samples.

## Exact source scope and correction
- `research/v3/evidence/midnight/2026-10-31T1611-jd3k-q2-prospecting.jsonl`: **17 output records** across three input IDs 237361/237363/237365. Source record IDs `midnight-20261031-001..017`.
- `research/v3/evidence/midnight/2026-11-01T0310-jd3k-rank2-prospecting.jsonl`: **17 output records** across the same three original source/input cohorts. Source record IDs `midnight-20261101-001..017`. This is a duplicate transcription, not an independent 30 additional casts.
- **34 file-qualified append-only corrections** add `castsBasis: countedFromInputs`; 17 existing output totals and their existing `casts` numeric values remain unchanged in *both* original evidence files. No new study, casts, occurrence, output-rank IDs, quality, or bonus assumed.
- Rank-2 input IDs are identified; named output ranks remain unresolved. No listed Eversong Diamond is **not** a proven zero. March 31, 2026 rate-change epoch remains unknown.

## Model/review implications
The existing v3 estimator's `row_use` handles `castsBasis=countedFromInputs` as **nominal-equivalent** in confidence accounting while retaining measured aggregate material totals for average calculations. This correction prevents treating nominal counts as independently counted observed operations when the field is preserved. It does **not** validate or claim a new gold valuation, per-cast chance, current Retail applicability, production ItemDB change or exact-SHA build admission. The two copied cohort sets must remain deduplicated by original source identity, not treated as independent measurements. Builder correctness with this correction requires a separate exact-SHA regression by the owner pipeline; none was executed here.

Manager QA: source outputs independently cross-checked against the original Wowhead comment; **2 files × 17 records = 34** file-scoped correction targets; exactly three source-original input cohorts, zero new cohorts, zero observed cast counts, zero new gold decisions. Research-original files preserved.

## Next scientific prerequisite
Seek actual zero-inclusive completed-operation log with ore-specific input rank/item link, refund ledger and skill/spec/patch metadata. Do not replace authentic per-input average with a fabricated P(hit) or infer output-quality IDs from item names.
