# Dragonflight cumulative Looter research audit — 2026-11-08 20:55 UTC

**Scope:** Coordinator-only cross-file source identity and numerical integrity audit, not a new cast study or addon implementation. Read the worker's 2026-11-08 20:29 UTC JSONL and the earlier 01:41 UTC JSONL on the live research branch. Rechecked all five indexed original Wowhead item-side Looter tables. Both original evidence files remain append-only and unchanged.

- Earlier original: [01:41 file](../dragonflight/2026-11-08T0141-four-unindexed-shaman-looter-cohorts.jsonl), blob `413df57ee07be3c1a6de0f853524fb73eb3e5d1d`
- Later original: [20:29 file](../dragonflight/2026-11-08T2029-five-distinct-gear-looter-cohorts.jsonl), blob `66bd17dc38b0401c37228f81356731469f54c8e9`

## Directly confirmed source-identity duplicates

Two of the five purportedly new input-item cohorts in the later file are already in the earlier file, with the **same original item URL, denominator, per-material numerator, output item IDs, and conditional source stack display** despite *different studyKey values*:

| Input item | Old records | New records | Source operations | Shard 194124 hits | Crystal 200113 hits |
| --- | --- | --- | ---: | ---: | ---: |
| 200397 Treads of Infused Earth | 013404/013403 | 202907/202908 | 26 | 11 | 19 |
| 200403 Cuffs of Infused Earth | 013407/013408 | 202905/202906 | 19 | 12 | 11 |

**Four of the later ten numeric drop rows repeat two old original source cohorts**, not four fresh measurements. The 26+19=45 source-reported operations are **not new independent operations**. Importers must dedupe by original URL/input item/cohort material-row identity and source epoch, not by `studyKey` alone; preserve both originals and do not quietly combine/reweight duplicates. The prior [coordinator source overlap note](2026-11-08T0204-dragonflight-shaman-looter-overlap-and-shard-e-bounds.md) already analyzed these two cohorts' hit overlaps, so do **not** claim their overlap arithmetic as newly discovered.

## Three other worker item-side cohorts source-matched today

The indexed original Wowhead pages reproduce the 20:29 worker's material hit pairs for the three remaining item IDs:

| Source / link | N source-reported disenchants | Shard 194124 hits | Crystal 200113 hits | Pair sum - N | If same-N cast-level cohort, minimum overlapping hits |
| --- | ---: | ---: | ---: | ---: | ---: |
| [200339 Scalesworn Cultist's Girdle](https://www.wowhead.com/item=200339/scalesworn-cultists-girdle) | 55 | 34 | 28 | 7 | 7 |
| [200388 Stormwing Harrier's Sabatons](https://www.wowhead.com/item=200388/stormwing-harriers-sabatons) | 39 | 17 | 26 | 4 | 4 |
| [207205 Greatwolf Outcast's Wristguards](https://www.wowhead.com/item=207205/greatwolf-outcasts-wristguards) | 27 | 22 | 7 | 2 | 2 |

These 3 item-side source entries (6 material rows, 121 source-reported operations in total) were **not present in the compared earlier 01:41 file**; this comparison does not establish global source originality or new sample collection. Source pages also show a **1–2 positive-stack range** for Vibrant Shard, not an observed output stack histogram. If every occurrence is one positive operation and its true stack belongs to that displayed range, bounded shard units per source-reported operation are: **200339 [34/55, 68/55], 200388 [17/39, 34/39], 207205 [22/27, 44/27]**. These are purely **conditional bounds**, not measured means or current Retail gold values; neither exact output total nor crystal quantity can be inferred.

The **7 / 4 / 2 overlap minima** are inclusion–exclusion *conditional on both source rows sharing one genuine N-operation cohort*; without a joint operation ledger, different item variants/snapshot provenance or shared collection semantics could explain excess. Do not label simultaneous outcomes as observed, normalize material rows into exclusive rates, infer complete zero bins, claim live eligibility, or infer a skill coefficient. Current gear bonus, source collection patch, profession skill/spec and actual totals are missing.

## Verification and safe handoff

- Exact `inputItemID/outputItemID/casts/castsWithDrop` tuples compared programmatically from the two GitHub JSONL blobs: **4 duplicates out of 10 later material rows**.
- Five current indexed Wowhead table hit pairs cross-checked against the 20:29 worker transcriptions. This is external source indexing, **not** a live WoW test, actual client capture, or full Retail population proof.
- Numerically new proven *cast observations*: **0**. Newly actionable current-character gold recommendations: **0**. Actual ItemDB valuation or tooltip runtime tests performed: **0**.
- Review priority: verify source/collector epoch, original item bonuses and rank/context; prevent source-cohort duplicate weighting in research import, without changing the protected three-pass implementation branch or worker evidence files. The Dragonflight worker retains T0041 source ownership; any estimator/valuation changes require separately authorized integration review.
