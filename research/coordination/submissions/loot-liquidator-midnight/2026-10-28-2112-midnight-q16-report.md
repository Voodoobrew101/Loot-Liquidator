# Loot Liquidator Midnight — queue 16 assigned audit + P0 omitted refining recipe

**Date:** 2026-10-28 · **Assignment:** `2026-10-28-batch014-midnight` · **Queue revision:** 16 · **Branch:** `research/processing-confidence` · **Research only**

## P0 newly identified omitted recipe (unassigned discovery, NO first-pass credit)

**Refine Crystalline Glass**, spell **1307462**, introduced in **patch 12.1.0**: LIVE WoWDB describes **10 rank-one Crystalline Glass -> 1 rank-two Crystalline Glass**, learned at Midnight Jewelcrafting 50, requiring Jeweler's Tools and Jeweler's Bench. Item IDs **242786 (rank one) -> 242787 (rank two)** are plausible, but the rendered recipe does not expose both IDs unambiguously: require exact game recipe reagent/output ID verification. See [LIVE spell](https://www.wowdb.com/spells/1307462-refine-crystalline-glass-a-professions-chaticon), [Wowhead 2026-08-18 guide](https://www.wowhead.com/guide/midnight/professions/jewelcrafting-overview-trainer-locations-recipes-tools), [item 242786](https://www.wowdb.com/items/242786-crystalline-glass), [item 242787](https://www.wowdb.com/items/242787-crystalline-glass).

**Important build discrepancy:** [PTR WoWDB](https://ptr.wowdb.com/spells/1307462-refine-crystalline-glass-a-professions-chaticon) displays **5 + 10** glass reagents, whereas LIVE displays **10 only**. Do not sum these or invent a 15-glass live recipe. Resolve against the 12.1.0+ client before master acceptance. Conditional on a legal successful deterministic craft, proposed **P=1, positive min=1, max=1, unconditional E=1** (each provisional confidence 82/100 from recipe description; **0 measured casts**). This is not a newly approved numeric field.

The spell and rank-two glass ID are absent from actual main GameData SHA `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e` and the current research-stage itemdb.lua; the source-memory cache also has no 1307462. **Request master assign this one recipe key** and add full reagent/skill/bench eligibility to compiler. No self-claim of another worker's keys.

**Second unassigned P0 lead:** rank-two **Crystalline Glass 242787** and **Dusk-Shrouded Stone 242789** are absent from staged prospecting output mappings, although [March 2026 firsthand discussion](https://www.reddit.com/r/woweconomy/comments/1s3hnzo/thoughts_on_crushing/) reports R2 glass from skilled R2 ore and [April 2026 discussion](https://www.reddit.com/r/woweconomy/comments/1szcgff/prospecting/) reports R2 stone and glass. These do **not** establish exact ore IDs, output probability, rank-conditioned E, or all-ore eligibility. Master should assign exact candidate pairs for verification, not auto-generate a cartesian product.

## Assigned P1 material-field audit — 35/35 exact stable keys

- **35/35** exact source-line item-ID matches on pinned main GameData; 7 Eversong Diamond keys, 16 rank-one ore transferred-reference rows, 11 rank-two ore rows using the *same* JD3K original aggregate study family, and 1 guide-proxy row. No overlap counted as an independent study.
- All **35** occurrence probabilities and **70** conditional yield bound fields remain UNKNOWN; there are **28 existing provisional E references**, not 28 new measured numeric cells. The 7 diamond E fields remain UNKNOWN, not measured zero, because ore-specific Proficient Processor eligibility is required. Historical high-skilled `high` source numbers are comparison data, not a universal skill coefficient.
- Original JD3K [Midnight Prospecting](https://www.wowhead.com/spell=1231127/midnight-prospecting) reports **50 gross R2 ore each** for Copper, Tin, Silver, with aggregate material names and totals. Actual completed cast denominators, output item quality-rank IDs, per-cast zeros, skill numeric and patch window are not reported. Its family means per nominal five ore are *not* measured exact-item per-cast P or E. The original source was already in source memory as PARTIAL; reuse, no new study credit.
- R1 ore references are copied from R2 cohorts; report confidence 22 and transfer blocker. R2 JD3K-family source references confidence 30 with item-rank/denominator blocker; guide-only R2 Tin Peridot confidence 20. All below 90 and explicitly provisional, not current neutral baselines.

## P2 gold decision risk and invariant checks

- For Refine Glass, a single recipe consumes **10** rank-one glass, not one. Compare net proceeds from 1 rank-two glass to the net proceeds/opportunity cost of 10 rank-one glass plus deposit and time. With equal 5% auction cut and ignoring other costs, break-even price ratio is **R2/R1 > 10**. No current AH quote or actual recommendation flip asserted.
- An addon using only 242786/242788 under high-skill R2 prospecting may misprice rank-two output items; leave missing rank-specific E UNKNOWN rather than pretending they are zero or copying R1 rates.
- **Static tests:** assigned=35; matched=35; diamond=7; r1Proxies=16; r2JD3K=11; r2Guide=1; provisionalE=28; unknownP=35; unknownBounds=35. Exact source IDs, unique keys, E nonnegativity and null denominators independently checked. Node/Lua/in-game tests **not run**.

## Source ancestry and next exact targets

**New original measured cast cohorts:** 0. **New primary game-record family:** 1 (spell 1307462). **Guide corroborations:** 1 derivative. **PTR variant:** 1 same underlying recipe with conflicting reagent rendering. **Reused original study families:** 1 (JD3K). **New qualitative player comments:** 2, no denominators. **New master-accepted mappings/fields:** 0. **Actual new discovered legitimate recipe family candidate:** 1, pending assignment/approval. Source-review events are immutable and status PARTIAL/NEEDS_RECHECK, not FULLY_ANALYZED.

**Exact next targets:** master-assign `recipe-candidate:midnight:refine:242786:242787:1307462`; verify 1307462 reagent ID and 10-vs-PTR-15 conflict in client; separately assign `Prospect:237361/237363/237365 -> 242787/242789` only after verifying each ore-specific output/rank; capture >=100 actual completed operations per exact ore/quality/skill with zero-inclusive output IDs, saved-input events and spec nodes. Do not self-claim overflow. Master owns compiler, queue and acceptance.

**Baseline at review:** 976 research-staged provisional mappings, 791 four-field complete, 396 unknown numeric cells (P172/min68/max68/E88), zero current-Retail neutral verified. Exhaustive Retail universe **NOT COMPLETE**. Evidence confidence is strength of support (0–100), not measured probability of correctness.

No production Lua/TOC, main, master ledgers, assignments, registry, source-memory, or automation schedule changed.
