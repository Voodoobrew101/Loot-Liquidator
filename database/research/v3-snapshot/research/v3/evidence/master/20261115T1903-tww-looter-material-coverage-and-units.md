# Research-only audit: TWW green-gear Looter rank/quantity completeness — 2026-11-15 19:03 UTC

**Scope/priority:** T0048 and T0040; recently contributed War Within item-side Looter *reference-only* records, not new gameplay observations. Audit source is the worker's append-only `research/v3/evidence/war-within/2026-11-15T1830-five-green-gear-original-looter.jsonl` (blob `3e70f857ff403c902011a47e8263239db11ebf3a`), plus the worker's `quiet-status/war-within.json`. Do not alter worker originals. GitHub source pages are linked in that file. Source counts and stack percentages were transcribed by that worker; **this audit independently checks internal arithmetic and identities, not the current page's JavaScript Looter table against a fresh authenticated upload/event export**.

## Exactly verified numeric reconciliation

Five distinct input-item groups, 25 distinct `(inputItemID, outputItemID)` rows. The denominator `N` belongs to the input cohort; it must not be multiplied by material rows or treated as 25 independent studies. `H` counts per-material positive appearances. `Q` is the worker-reconstructed sum of stack-size × positive-bin frequency, **not a source-stated measured total**.

| Input item | Looter reported item operations N | Ranked material rows | Sum material H | Reconstructed Q | N - sum H |
|---|---:|---:|---:|---:|---:|
| 217150 Algari Competitor's Plate Armguards | 36 | 4 | 36 | 67 | 0 |
| 217145 Algari Competitor's Plate Gauntlets | 24 | 4 | 24 | 44 | 0 |
| 224595 Deep-Dweller's Slippers | 5,712 | 6 | 5,699 | 10,559 | **13** |
| 224598 Deep-Dweller's Leggings | 5,591 | 6 | 5,580 | 10,285 | **11** |
| 223546 Algari Spear | 58 | 5 | 58 | 112 | 0 |
| **Five input cohorts, not 25** | **11,421** | **25** | **11,397** | **21,067** | **24** |

**New completeness/identity bound:** If each material row's `outof` denotes the *same exact N operations* for that input item, the union of operations producing one of the listed materials is no larger than `sum H`. Therefore **at least 13 Slippers observations and at least 11 Leggings observations lack any of the six *listed* material outcomes**. These are mathematically bounded *unlisted-material appearances*, **not 24 proven empty disenchanting results**. Other unlisted output items, skipped recorder rows, pooled item variants and multi-output event overlap remain possible; event IDs and joint outcome logs are missing. The 0 bin in each material histogram is only absence of *that material*, not an operation with zero total disenchant output. Zero gaps in the other three items do not establish exclusivity or completeness.

**Recoverable source-model per-operation units (explicitly conditional on the pooled source denominator):** Slippers' Storm Dust rank 1 (219946) Q/N=6,433/5,712 = 1.1262 and rank 2 (219947) = 2,259/5,712 = 0.3955; Leggings' corresponding values = 6,330/5,591 = 1.1322 and 2,102/5,591 = 0.3760. These are derived model/reference quantities in exact output-ID scope, **not controlled current-patch character means or independently observed stack totals**. Pooled reporting may mix patches, item-level/bonus variants, skill, specialization and players. The apparent similarity of the two cloth rows cannot be counted as independent controlled confirmations. Do not price an unknown-rank family twice or assume omitted shard ranks have probability zero.

**Validation executed:** 187/187 guarded JavaScript assertions passed on all 25 committed source records: histogram counts total N; positive bins total H; reconstructed units total Q; per-material zero bin equals N−H; every transcribed conditional percentage (4-decimal or exact) equals 100×bin/H within 0.000055 percentage points; all records are `sourceKind=reference` and use a shared denominator within their exact item cohort. No Python estimator, generated ItemDB, addon Lua, actual offline gold valuation, tooltip renderer or live WoW test was executed. The estimator source was inspected: `REFERENCE_KINDS = {"tsm-table","compiled-research","reference"}`, and reference rows feed provisional priors rather than measured study-cast counts. The source percentages were not independently reacquired from live embedded JavaScript during this audit.

## Admission and next action

Preserve ranks and 25 per-output histograms as one provisional Looter reference source per input; keep patch/bonus/skill provenance unknown and no fabricated study confidence. Before admitting any as current-character Retail economic outcomes, obtain an original time-bounded itemLink+bonus/ilvl, build, character-spec/skill and event-ID ledger proving the N denominator and output unit stacks, including previously unlisted outcomes for the 13+11 records. Do not transform the derived per-material absent bins into total zero-yield disenchant casts. If engineering later consumes this evidence, test `source -> reference fallback -> item/quality/rank eligibility -> offline valuation -> tooltip` at synthetic prices on the owner-controlled integration path only, without modifying `implementation/usable-data-tooltips` here. No merges, releases, addon snapshot changes, queue rewrites or worker evidence modifications.
