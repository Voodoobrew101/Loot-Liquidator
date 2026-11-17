# Research-only admission gate: new MoP Classic Looter observations cannot silently become Retail measured baselines

**Checked:** 2026-11-15 11:08 UTC. **Scope:** newest Legacy evidence, current v3 estimator and correction ledger, not a new source cohort, code change, compiler execution, addon runtime test or Retail result.

## Newly isolated source-to-estimator identity defect

The newly filed append-only [Legacy ilvl-97 source transcription](../../evidence/legacy/2026-11-15T1047-tbc-ilvl97-rare-armor-looter-and-original.jsonl) contains **nine `drop` lines from six distinct item-side Wowhead `/mop-classic/` Looter pages**, all stamped `sourceKind="study"`, with exact `casts` and `castsWithDrop` but **no game-flavor/build/patch verification for current Retail**. The six page-level totals are 29 + 28 + 145 + 192 + 13 + 144 = **551 source-reported cumulative item disenchants**; do not add the repeated denominators for second output lines. They are not 551 fresh Retail operations, nor verified per-character current-patch samples.

| Classic page / input | Page-level reported operations | Source rows / outputs |
| --- | ---: | --- |
| [Cryo-Mitts 29327](https://www.wowhead.com/mop-classic/item=29327/cryo-mitts) | 29 | 1: Small Prismatic Shard 22448 |
| [Haramad's Linked Chain Pantaloons 29344](https://www.wowhead.com/mop-classic/item=29344/haramads-linked-chain-pantaloons) | 28 | 1: 22448 |
| [Haramad's Leg Wraps 29345](https://www.wowhead.com/mop-classic/item=29345/haramads-leg-wraps) | 145 | 2: 22448 and Nexus Crystal 20725 |
| [Consortium Prince's Wrap 29328](https://www.wowhead.com/mop-classic/item=29328/consortium-princes-wrap) | 192 | 2: 22448 and 20725 |
| [Consortium Mantle of Phasing 29326](https://www.wowhead.com/mop-classic/item=29326/consortium-mantle-of-phasing) | 13 | 1: 22448 |
| [Flesh Beast's Metal Greaves 29325](https://www.wowhead.com/mop-classic/item=29325/flesh-beasts-metal-greaves) | 144 | 2: 22448 and Arcane Dust 22445 |

A tenth line, `legacy-20261115-1047010`, is a distinct firsthand [TBC-era 31190 single disenchant](https://www.wowhead.com/tbc/item=31190/the-dreamers-shoulderpads); it is **not** one of the nine MoP Classic Looter lines and likewise is not a modern Retail qualification.

## Directly checked ingestion pathway, not a claimed compiler outcome

- [Current `build_estimates.py`](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/five-agent-completion/research/v3/tools/build_estimates.py) at blob `0b09b553fef4214af8aaa93f1c85061956643711`: `load()` recursively loads **all** v3 evidence JSONL rows. `REFERENCE_KINDS` is `tsm-table/compiled-research/reference`, **not** `study`; `analyze()` groups positioned `drop` lines into its study path. `row_use()` accepts supplied cast-and-hit pairs. No `gameMode` test exists in this estimator. The `source_key()` comment deliberately retains `@mop-classic` as a distinct page **for duplicate identity**, but this is not an eligibility or game-flavor veto.
- [Current corrections ledger](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/five-agent-completion/research/v3/corrections.jsonl) at blob `80f37dbb74e3444585f7a63a3272a6c0989494f7` has no `exclude` correction for those nine new IDs. Both `key_of()` and the record fields provide exact numeric input/output IDs, so missing ID alone would not protect them. Historic epoch weighting is not a Retail flavor check.
- Guarded in-tool JavaScript assertions against the **actual fetched nine rows** and fetched estimator/corrections code all passed: nine explicit Classic URLs, six unique `studyKey` item cohorts, 551 deduplicated per-item denominators, nine `study` types and nonnull cast/hit pairs, no per-row `gameMode`, no existing exclusion, recursive load, no flavor check. **No fresh Python compiler was executed**; a generated estimate or current addon recommendation for these inputs has **not** been proven. The checked-in `output/estimates.json` is older and contains no direct matches for these new IDs.

## Decision and next validation

**Block promotion to Retail-measured confidence/EV until game flavor, source era, variant and applicable mechanics have an explicit supported bridge.** Keep original Classic observations as provenance and potentially historical reference, but do not silently classify their page-level hit counts as **Retail empirical casts** or borrow Classic frequency/confidence into a present Retail recommendation. Historical TSM/reference numbers may remain independently available under the owner's labeled fallback policy; this gate specifically concerns *cross-flavor observed-study weights*, not a ban on all historical context.

A reviewable research-only engineering follow-up should add an explicit source-flavor disposition (or a narrowly scoped reviewed exclusion for the nine new IDs if a general tag cannot be supported), preserve originals, and test both (a) new Classic rows cannot alter Retail baseline casts/chance/EV and (b) eligible independently validated Retail records continue to compile. A fresh compiler + synthetic-priced **real resolver/valuation/tooltip** check is needed after implementation, with source selection and current-character eligibility treated separately. Do not mutate the owner's three-pass addon branch or assume its old immutable snapshot includes this new evidence.

**Actual work:** source, correction and estimator readback; exact 11 static assertions. **Not done:** original Wowhead per-event raw export, current-client verification, native compiler/CI, addon runtime or original spreadsheet reopening; none was required to identify this flavor-classification defect. Continue workers on truly new T0039/T0045 and T0009/T0010 original rank-specific operations, not duplicate historical page harvesting.
