# Six Skybound Avenger Looter cohorts: existing-source duplicate gate — 2026-11-19 21:11 UTC

**Role/scope:** Research Manager source-identity QA for Dragonflight disenchant task T0041/T0020. This is a review of worker-owned evidence, **not** six new studies, changed output values, or an addon change.

## Reproducible source-record comparison

The newly archived [2026-11-19 20:39 UTC worker source rows](../../dragonflight/2026-11-19T2039-skybound-avenger-gear-looter-occurrences.jsonl) claim 12 new material-occurrence rows across six item IDs. Exact field-by-field comparison with two **earlier** append-only original files proves **12/12 are already recorded**:

- Ten rows for item IDs **200344, 200345, 200346, 200347 and 200350** match the [2026-11-09 original source file](../../dragonflight/2026-11-09T0948-five-skybound-gear-looter-hits.jsonl) with identical input/output item IDs, method, reported operations, hits, percent, units, rank nullability and missing quantities.
- Two rows for item **200343** match the [2026-11-16 original source file](../../dragonflight/2026-11-16T1311-new-boots-slippers-looter-and-cast-search.jsonl) on the same fields.
- **All 12 newer rows use a different studyKey** (prefix `wowhead-looter-df-item-` instead of `wowhead-looter-original-df-item-`). Visor/legguards link to `/ptr/` and carry a `?bonus=` query in the newer file, while the earlier original used live URLs. These are **alternate URLs for the same item-side Wowhead Looter cumulative rows**, not independent player outcomes. The source-key normalization code strips the query and canonicalizes PTR variants; the estimator's `study_identity` additionally fingerprints source, input rank, casts and all output rows. This makes duplicate suppression the intended behavior; actual estimator/compiled ItemDB output was **not run or asserted** in this check.
- The original [Wowhead Visor item-side results](https://www.wowhead.com/ptr/item=200345/skybound-avengers-visor?bonus=9003) were additionally spot-checked from accessible indexed source text: Vibrant Shard **29/34** and Resonant Crystal **17/34**, matching both files. One current item page can expose a PTR label without establishing the patch of the underlying uploads.

## Conditional mathematical sanity check (not a new observed cohort)

Under a **shared-population assumption** that both material-hit rows refer to the same N reported item disenchants, the two materials must have co-occurred in at least `max(0, hitsShard + hitsCrystal - N)` operations. This is a lower bound, **not** a measured joint histogram or proof of current Retail eligibility:

| Input | Item 200343 | 200344 | 200345 | 200346 | 200347 | 200350 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Reported N | 12 | 31 | 34 | 37 | 35 | 11 |
| Shard hits | 3 | 21 | 29 | 24 | 21 | 5 |
| Crystal hits | 10 | 13 | 17 | 18 | 18 | 7 |
| Minimum shared positive events **if** N is common | 1 | 3 | 12 | 5 | 4 | 1 |

Do not force the two output channels into mutually exclusive alternatives or treat their rounded per-output percentages as observed total quantities. Minimum one unit on a positive hit may give a **conditional lower-bound material quantity**, not a source-reported unconditional expected unit or measured full distribution. Source age, gear bonus/ilvl, skill, other outcomes, zero events, and output stack sizes remain unknown; no gold recommendation or model correction has been established.

## Verification, ownership and next steps

**Actual bounded verification:** 159/159 executable JavaScript assertions across 12 new and 12 pre-existing rows, including source identity, input/output ID, method, N/hits, percent, missing quantity/rank and distinct studyKeys; six per-item nonexclusive-outcome bounds. The two prior GitHub blobs were fetched directly from `implementation/five-agent-completion`; no spreadsheets were imported. **Not executed:** Python estimator, synthetic-priced actual engine/tooltip, Lua suite, live WoW client, or exact-head GitHub CI.

**Disposition:** 12 duplicate transcriptions; **zero new independent cohorts** and **zero new supported gold decisions** from these rows. Keep all original files append-only; protect the owner's `implementation/usable-data-tooltips` and immutable `4df9ae8` snapshot. Do not edit the Dragonflight worker's files/status. Continue T0020/T0018/T0015/T0041 on **new original operation/zero/rank/refund evidence**, not another six reindexed Looter pages. Review one actual estimator dedupe diagnostic on a safely isolated branch before making any claim that double-counting affects compiled output.
