# Dragonflight disenchanting — mandatory cross-material overlap lower bounds
Checked: 2026-11-08 UTC. Research-only manager analysis of a new Dragonflight worker file; not new operations, not a character/client test, not current Retail valuation.

## Source and provenance
Worker original records: `research/v3/evidence/dragonflight/20261107T2331-six-distinct-gear-looter-cohorts.jsonl` (file blob `3efd64666573abbf0e11d037577181452657917a`, 13 rows from six distinct gear input IDs). Worker status at 2026-11-07T23:31:40.424Z identifies source-attributed cumulative Wowhead Looter material occurrence counts and missing current-patch/character/item-bonus/skill context. These are **not six newly re-observed independent experiments by the coordinator**.

Independently re-opened source tables for the first three two-output examples:
- [Chestwrap of the Waking Fist, 200360](https://www.wowhead.com/item=200360/chestwrap-of-the-waking-fist): 23 Vibrant Shard occurrences and 18 Resonant Crystal occurrences across 30 reported disenchants.
- [Virtuous Silver Breastplate, 200414](https://www.wowhead.com/ptr/item=200414/virtuous-silver-breastplate): 50 Shard and 47 Crystal occurrences across 82 reported disenchants; the PTR-facing page is not proof of the source's actual patch.
- [Virtuous Silver Gauntlets, 200416](https://www.wowhead.com/item=200416/virtuous-silver-gauntlets): 58 Shard and 40 Crystal occurrences across 85 disenchants.

Other rows in the worker file are source-attributed but were **not** independently re-opened for this note. Do not promote that partial crosscheck to all-source validation.

## Exact arithmetic, conditional on same-denominator material occurrence semantics
For each input ID with two material rows, let N be *source-reported* disenchants, a and b the two separate positive-occurrence counts. Set theory guarantees **at least max(0, a+b-N) operations produced both materials** if both counts describe events in that same N-operation cohort. This is a derived lower bound; it is **not** an observed joint histogram, a rate, or a new independent cohort.

| Input | N reported | Material A hits | Material B hits | Sum hits | Minimum joint occurrences |
|---|---:|---:|---:|---:|---:|
| 200360 | 30 | 23 | 18 | 41 | 11 |
| 200365 | 20 | 15 | 8 | 23 | 3 |
| 200414 | 82 | 50 | 47 | 97 | 15 |
| 200416 | 85 | 58 | 40 | 98 | 13 |
| 200420 | 28 | 19 | 16 | 35 | 7 |
| **Five distinct input IDs** | **245** | **165** | **129** | **294** | **at least 49** |

The sixth input (194394) has three distinct material hit counts 103+10+2=115 over 115 reported disenchants; those marginal totals alone do **not** force a joint outcome and must not be treated as a proof of mutually exclusive outputs.

## Separate source-to-field completeness finding
Three independently reopened Wowhead tables explicitly display **1–2** Vibrant Shards per positive disenchant outcome: 200360, 200414 and 200416. Worker source records `dragonflight-20261107-990008`, `990010` and `990012` carry those **source-reported positive-stack ranges in `notes`**, but leave both schema fields `minSeen` and `maxSeen` **null**. This is a **usable-but-not-structured** *conditional yield-range* gap, not an absent source and not evidence for unconditional expected quantity, exact distribution, or character-valid Retail yield. Queue worker-owned append-only source-preserving corrections/validation before a compiled-tooltip range field can use it; do not directly rewrite that worker's records. Other output rows with no displayed ranges must remain unknown.

## Concrete valuation/tooltip guard
A resolver or statistical fixture that silently treats Vibrant Shard and Resonant Crystal outcomes as mutually exclusive on these source tables contradicts the observed marginal arithmetic, unless the source denominators or `castsWithDrop` semantics are wrong. Do not normalize summed per-material occurrence rates to 100%, subtract one material's hits from another, or call the excess new casts. Each per-material marginal count is usable only with its method/source/patch/eligibility caveats; a complete joint distribution, total units, conditional stack histogram, output ranks, and current Retail character eligibility remain unknown. Positive stack display ranges (such as 1–2 shards) are not unconditional expected quantities. No synthetic-price engine/tooltip tests executed by coordinator.

## Next focused validation
Obtain source-linked or owner-exported per-operation co-output records for one of these five item IDs, including item bonus/version, output item IDs/ranks and stacks, real completed disenchant count, skill/build and patch; compare marginal hit counts and joint outcomes. Only then review a multi-output economic model/tooltip fixture through the protected integration owner. Preserve workers' original file and branch ownership; leave PR Director integration unchanged.
