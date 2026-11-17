# T0048 — 227635 War Within Anniversary Looter cross-snapshot duplicate hold (2026-11-13 UTC)

**New finding: same original item-side sample is transcribed twice under different `studyKey` values.** This is a source-lineage check, not an added drop study, verified real-character output, output-quality mapping, or gold valuation.

## Exact original-row comparison

Two archived War Within research files describe **Malevolent Gladiator's Cord of Accuracy**, input item **227635**, with exactly the same source-reported total **22** item-side disenchants and the same ordered four material occurrence counts **11 / 5 / 4 / 2**:

| Field | Original Nov 8 record | Nov 13 repeat |
| --- | --- | --- |
| File | `research/v3/evidence/war-within/2026-11-08T1635-anniversary-looter-de-unresolved-ranks.jsonl` | `research/v3/evidence/war-within/2026-11-13T0325-undermine-anniversary-original-de-looter.jsonl` |
| Row record IDs | `war-within-20261108-1635-004..007` | `war-within-20261113-0007-227635..0010-227635` |
| `studyKey` | `wowhead-looter-227-227635-one-cumulative-itemside-snapshot` | `wowhead-looter-item-227635-cumulative-de-20261113` |
| Source URL mode | [PTR item 227635](https://www.wowhead.com/ptr/item=227635/malevolent-gladiators-cord-of-accuracy) | [Live-index item 227635](https://www.wowhead.com/item=227635/malevolent-gladiators-cord-of-accuracy) |
| Item-side denominator | 22 in each of four rows | 22 in each of four rows |
| Ordered occurrences | 11 Refulgent Crystal; 5 Refulgent Crystal; 4 Sha Crystal; 2 Refulgent Crystal | exact same 11 / 5 / 4 / 2 |
| Output IDs | all four unknown in worker original; manager separately verified direct source links on Nov 8 | Sha Crystal row is 74248; three Refulgent IDs remain unknown in this worker file |
| Original event logs, 0–N stack histograms, skill/bonus/build | absent | absent |

**Identity disposition:** source-side input, denominator and ordered four-output vector match exactly; different URL modes and new `studyKey` do not authenticate two independent groups of 22 completed disenchants. Hold Nov 13's four rows as a **repeat of the previously archived original item-side table** for study-count/weighting purposes, pending original event IDs or proof of disjoint upload windows. Do not sum them as 44 verified operations or eight independent observation rows. Direct original [indexed source table](https://www.wowhead.com/item=227635/malevolent-gladiators-cord-of-accuracy) confirms the 22 denominator and 11/5/4/2 vector; a raw player ledger does not exist here.

Previous manager source-link verification [Nov 8 identity audit](2026-11-08T1711-anniversary-looter-original-linked-output-identities.md) independently resolved this original item's three Refulgent Crystal outputs to distinct IDs **219952 / 219954 / 219955** and Sha Crystal to **74248**, using direct links, **not a rank guess from table order**. That mapping is a previously recorded candidate correction, **not new proof** on this run and not authorization to treat same-name Nov 13 rows as identical ranks absent linked-row capture.

## Adjacent nonduplicated / context checks

The new Nov 13 file also includes item-side 229239 (66 operations; 38/18/7 three Refulgent rows) and 229240 (50; 30/14/5). Their direct [cloak](https://www.wowhead.com/item=229239/aureate-sentrys-gilded-cloak) and [clasps](https://www.wowhead.com/item=229240/aureate-sentrys-clasps) source tables corroborate row-level occurrence totals. Sum of three listed material hit rows is **63 of 66** and **49 of 50** respectively. This leaves at least **3** and **1** item-side events outside the union of *these listed rows*; it does **not** show that any disenchant had zero total material or that all rows are mutually exclusive. Identical Refulgent display names have unresolved linked IDs and material quantities; no per-rank EV.

A separate prior manager audit already documented 227625's **22; 13/6/2 Refulgent + 1 Sha** [anniversary variant hold](2026-11-08T0500-tww-refulgent-variant-aggregation-and-unlisted-outcome-bounds.md). Newer 227628 and 227649 likewise show mixed Sha Crystal and Refulgent Crystal outcomes; the indexed [handguards](https://www.wowhead.com/item=227628/malevolent-gladiators-silk-handguards) (31; 22/5/3/1) and [legplates](https://www.wowhead.com/item=227649/malevolent-gladiators-ornamented-legplates) (7; 5/2) tables support source counts, **not** current Retail eligible-output rules for their exact item versions. The 227635/227625 cross-era mixed-outcome issue and unknown bonus/context persist. None was processed in-game by the manager.

## Status and requested worker-owned correction

- **New independently measured cohorts/casts: 0.** **Duplicate source table spotted: 1 original, 4 repeated rows, 22 repeated source-reported operations.** No measured yields, original event histograms, independent source dates, live-client gold decisions, importer/estimator or tooltip tests.
- T0048 War Within worker should append a provenance/replacement or source-alias correction linking `war-within-20261113-0007-227635..0010-227635` to `war-within-20261108-1635-004..007`, preserving both append-only originals. Do **not** edit this worker evidence from coordinator scope. Validate downstream original-source dedupe in an isolated research-only test before claiming cumulative study counts.
- Other new source cohorts remain **provisional source-only** until exact output links/ranks, per-hit quantity, original at-cast item variant/bonus, build/epoch, skill/spec and independent event capture are obtained. Distinguish gap-only reference from admitted usable rates.
- `main`, three-pass integration branch, worker files, addon, production, PR state and schedules untouched; no merges, releases or live WoW checks.

Read/verification scope: fetched both exact GitHub JSONL files and Nov 8 manager identity note; compared the eight exact original row records and their study keys/source URLs; read current indexed original item-side pages. This evidence note is research-only.