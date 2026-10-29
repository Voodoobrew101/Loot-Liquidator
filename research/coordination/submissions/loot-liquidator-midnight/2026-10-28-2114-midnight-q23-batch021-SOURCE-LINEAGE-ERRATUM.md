# Immutable source-lineage erratum — Midnight q23 Batch 021
**2026-10-28, research-only. Original source-review events remain untouched.**

The original nine-line file `research/coordination/source-reviews/loot-liquidator-midnight-2026-10-28-2114-midnight-q23-batch021.jsonl` inadvertently populates the `observationIDs` array of **all nine events** with `2026-10-28-2114-midnight-q23-batch021-genyachris-nullstone-raw`.

**Correction:** This observation ID belongs **only** to the `https://www.wowhead.com/item=210939/null-stone` event (line 7, study `genyachris-nullstone-five-stones-reported-outcome`). For lines **1–6 and 8–9**, `observationIDs` should be treated as the **empty array**; these source assessments are independent source-identity/recipe reviews, NOT observations derived from Genyachris. Do not count those eight false references as evidence ancestry, new cohorts, or corroborations.

No other numeric values or q23 assignment keys change. The source-memory builder may replay the original malformed lineage until master QA applies this immutable erratum as a source-attribution correction or filters the eight references. No shared cache/ledger edits are authorized to this worker.

This is an **erratum to metadata**, not an independent new source, not a new accepted mapping and not a reason to increase confidence.
