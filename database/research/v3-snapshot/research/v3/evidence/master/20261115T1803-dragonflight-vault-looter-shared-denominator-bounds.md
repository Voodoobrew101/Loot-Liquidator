# Vault of the Incarnates Looter shared-denominator / co-output source audit

Checked 2026-11-15T18:07:06.289Z. Research-only numerical/source-context verification, not an independent current Retail cohort or addon fix.

## Evidence sources
New Dragonflight worker original-source rows: [17:45Z JSONL](../dragonflight/20261115T1745-five-original-vault-looter-gear-counts.jsonl) (blob 91f07ae07c528dc47853b82f4003683549f9c7ce). All five Wowhead item-side Looter pages were independently checked by retrieved text, including the PTR-2 mirror for 200365, and their individual denominators and material hits matched the JSONL:
- 200347: https://www.wowhead.com/item=200347/skybound-avengers-ailerons
- 200350: https://www.wowhead.com/item=200350/skybound-avengers-cape
- 200360: https://www.wowhead.com/item=200360/chestwrap-of-the-waking-fist
- 200365: https://www.wowhead.com/ptr-2/item=200365/mantle-of-the-waking-fist
- 200392: https://www.wowhead.com/item=200392/stormwing-harriers-pinions

These are mutable pooled Wowhead Looter item summaries, not original event logs or dated, skill- or bonus-version-stratified observations. A live or PTR page rendering does not establish the build of submitted data.

## Independent marginal-event arithmetic
If positive counts a and b belong to one common set of N item-specific disenchant operations, their actual co-occurrence must satisfy max(0, a+b-N) <= joint <= min(a,b). These are *conditional mathematical bounds*, not measured joint-positive cast counts.

| Input ID | N reported operations | Shard 194124 hits | Crystal 200113 hits | Conditional minimum joint hits | Conditional maximum joint hits |
| --- | ---: | ---: | ---: | ---: | ---: |
| 200347 | 35 | 21 | 18 | 4 | 18 |
| 200350 | 11 | 5 | 7 | 1 | 5 |
| 200360 | 30 | 23 | 18 | 11 | 18 |
| 200365 | 20 | 8 | 15 | 3 | 8 |
| 200392 | 63 | 39 | 35 | 11 | 35 |
| **Across 5 distinct inputs** | **159** | **96** | **93** | **30** | **84** |

The ten output rows sum to 189 positive material appearances versus 159 source-reported item operations. Under a truly shared operation pool, at least 30 joint-material appearances are logically necessary across the five inputs. This is NOT evidence that 30 particular casts are independently observed to co-drop; Looter source-pool mixing/bookkeeping could instead explain a mismatch. Never partition these into mutually exclusive output outcomes, renormalize marginal percentages to sum to 100%, or treat each output row's denominator as additional independent casts. Individual per-cast co-output pattern, zero outcomes and sample independence remain unknown.

## Validity for current gold decisions
All ten JSONL rows have totalQuantity=null, averageShown=null, histogram=null, patch=null, skill=null, inputRank=null and outputRank=null. The source's 1-2 Shard display is an advertised range, not a sampled unit histogram. Therefore there is no verified unconditional expected output quantity per cast, no character/patch-conditioned current Retail chance or gold decision. A separately admitted provisional yield-one model is possible under owner policy only when the relevant source, unit, game and character assumptions are defensible and clearly labeled; it is not a newly observed quantity here. No skill curve, current eligibility or Multicraft may be assumed.

Estimator note: research/v3/tools/build_estimates.py structurally treats sourceKind=study drop rows as studies, and castsWithDrop/casts as a possible chance input when batch units align; this checkpoint did not run full Python analysis, migration, Lua addon processing or synthetic valuation. Impact on compiled estimates and actual tooltip remains unverified.

## Checks and next task
The worker's ten exact source records passed 56/56 earlier guarded JavaScript assertions for IDs, two-row study membership, denominators, units/unknown fields and group totals; 35/35 repeated exact per-item source-number checks passed during this commit. Original source-page counts for all five items were matched. No worker originals, immutable snapshot 4df9ae8, owner three-pass branch, PR or main were edited. New current Retail observed cohort count: zero.

Next: obtain contributor event-by-event Looter receipts or SavedVariables with exact itemLink, bonus/ilvl, source build, material stack units and co-occurrence; preserve one shared event identity and both marginal counts. Continue existing T0041 rank-linked current Retail processing queue, not duplicate page-mirror research.
