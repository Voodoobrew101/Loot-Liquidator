# Coordinator review: 20th-Anniversary item-side Looter linked output identities

Read directly from four original Wowhead item-side *Disenchanting* tables on 2026-11-08 UTC; original source URLs preserved below. This is a **research-only identity correction proposal** for the worker's append-only 2026-11-08T1635 records (all outputItemID and outputRank null). These are the **same 14 historical source rows, zero new studies/casts**. Do not edit the worker's originals. This is not live-client Retail eligibility.

| Worker record | Exact input ID | Page realm | Source occurrence hits / item-side operations | Direct linked output item ID |
| --- | ---: | --- | ---: | ---: |
| `war-within-20261108-1635-001` | 227618 | PTR-2 | 5/8 | [219952](https://www.wowhead.com/item=219952) |
| `war-within-20261108-1635-002` | 227618 | PTR-2 | 2/8 | [219954](https://www.wowhead.com/item=219954) |
| `war-within-20261108-1635-003` | 227618 | PTR-2 | 1/8 | [219955](https://www.wowhead.com/item=219955) |
| `war-within-20261108-1635-004` | 227635 | PTR | 11/22 | [219952](https://www.wowhead.com/item=219952) |
| `war-within-20261108-1635-005` | 227635 | PTR | 5/22 | [219954](https://www.wowhead.com/item=219954) |
| `war-within-20261108-1635-006` | 227635 | PTR | 4/22 | [74248](https://www.wowhead.com/item=74248) |
| `war-within-20261108-1635-007` | 227635 | PTR | 2/22 | [219955](https://www.wowhead.com/item=219955) |
| `war-within-20261108-1635-008` | 227591 | live-index page | 15/22 | [219952](https://www.wowhead.com/item=219952) |
| `war-within-20261108-1635-009` | 227591 | live-index page | 3/22 | [219954](https://www.wowhead.com/item=219954) |
| `war-within-20261108-1635-010` | 227591 | live-index page | 2/22 | [80433](https://www.wowhead.com/item=80433) |
| `war-within-20261108-1635-011` | 227591 | live-index page | 2/22 | [219955](https://www.wowhead.com/item=219955) |
| `war-within-20261108-1635-012` | 227591 | live-index page | 2/22 | [74248](https://www.wowhead.com/item=74248) |
| `war-within-20261108-1635-013` | 227588 | PTR | 16/24 | [219952](https://www.wowhead.com/item=219952) |
| `war-within-20261108-1635-014` | 227588 | PTR | 8/24 | [219954](https://www.wowhead.com/item=219954) |

Original item-side pages, each directly read in the stated realm mode: [227588](https://www.wowhead.com/ptr/item=227588/sha-skin-gloves), [227591](https://www.wowhead.com/item=227591/gloves-of-the-burning-scroll), [227618](https://www.wowhead.com/ptr-2/item=227618/malevolent-gladiators-ringmail-gauntlets), [227635](https://www.wowhead.com/ptr/item=227635/malevolent-gladiators-cord-of-accuracy).

## What is established and what is not

- Direct original output *hrefs*, not merely identical item names, distinguish 219952, 219954, and 219955 (all displayed **Refulgent Crystal**), 74248 (**Sha Crystal**), and 80433 (**Blood Spirit**). Do not collapse the three Refulgent outputs into one family or guess numeric rank from page order; verify rank-specific quality independently before assigning outputRank.
- All four source tables' positive occurrence-count numerators and item-side denominators match the 14 worker transcriptions: 227618 (8 reported operations), 227635 (22), 227591 (22), 227588 (24). These are cumulative source-side reports, not newly performed experiments. 227591 has 24 summed positive material occurrences over 22 input-side operations, compatible with multi-output operations or aggregation ambiguity; not a missing/zero-cast proof.
- Both 227635 and 227591 mix current-era Refulgent Crystal links with legacy Sha Crystal (74248), and 227591 adds Blood Spirit (80433). Wowhead lists these items as introduced in patch **11.0.5 (20th Anniversary)**. The mixed outcomes must be held as **context/variant/epoch conflicts** until original item bonus/build and source semantics are established. The PTR/PTR-2 tables are not live-2026 validation.
- These item-side tables state **occurrence counts**, not source stack quantities, casts with zero **total output**, per-cast 0–N quantity histograms, or source profession skill. Do not infer unconditional expected units, precise current-context probabilities, Auction/DE gold or observed output rank from them. Do not treat 76 source-reported item-side operations as new independent coordinator experiments.
- For follow-up, the War Within worker owns T0048 evidence and can append corrections/mappings with this provenance; the three-pass addon owner alone may admit compatible data after source/character eligibility and synthetic-price resolver+tooltip checks. No coordinator edits to worker evidence, v3 queue, migrations, main or addon.

## Exact read/verification scope

GitHub v3 worker source: [2026-11-08T1635-anniversary-looter-de-unresolved-ranks.jsonl](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/five-agent-completion/research/v3/evidence/war-within/2026-11-08T1635-anniversary-looter-de-unresolved-ranks.jsonl) (blob `8a6637a5727aff06cf93aad05ad066e55e7faf9b`). Read the original four Wowhead item pages as markdown including embedded item hrefs and per-output occurrence tables; compared all fourteen source rows in ordinal page order against the recorded worker rows. No probability/mean estimates, local compiler/Lua tests, current-addon formatter, synthetic valuation, or WoW client tests performed.
