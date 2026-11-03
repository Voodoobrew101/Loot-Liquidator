# Loot Liquidator — War Within worker batch011 research submission

**Date:** 2026-10-28. **Branch:** `research/processing-confidence`. **Queue revision:** 13. **Research only**. Branch head read before work: `a9424e6579aed39eb1d45c7e9b678fdc113ab199`. GameData.lua blob: `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`. Supplemental ledger blob: `397e589598102d42c774899399f9d607f44828a1`.

## Scope and real throughput

All **35/35** master-assigned `profile:de:<expansion>:<quality>:<gearKind>` source-profile keys were audited. These are **source profiles**, not 35 newly measured output records. Their existing compiled tables contain **44 material-output rows**, with all four source-ledger confidence scores copied unchanged into the output QA file. No new independent 2026 material-field measurement was made; no score promoted. The accepted master baseline remains **1,493/1,737 first-pass** until review, 0 four-field records >=90, 0 approved numerical rules.

## Static findings

- **Three profiles with nonzero claimed sample metadata but ZERO compiled outputs:** `profile:de:9:4:armor` (n=631), `profile:de:3:4:armor` (n=313), `profile:de:3:4:weapon` (n=686). These cannot be valued as known output distributions from their sample metadata alone.
- **Eight borrowed-other-gear-kind profiles** have unverified gear-kind transfer, and **24 of 35** profiles report fewer than 10 samples. These risk groups overlap.
- **Nine of 44 material rows** lack positive conditional min/max; they are **unknown, not zero**. All 44 existing P/E rows pass necessary bounds when ranges are present; necessary consistency is NOT source validity or current-build eligibility.
- Existing `GameData.lua` lacks **q3 Dragonflight armor and weapon** profiles entirely (outside these 35 assigned keys). As previously identified, `StatYieldProfiles.lua` synthesizes Vibrant Shard 194124 P=1, E=1/1.5 for missing q3 profiles; no independent cast evidence justifies this. This is a priority future migration regression, not a production edit.

## Original-study reconciliation and numeric track

Original 2022 Blizzard forum reports document Dragonflight rare equipment yielding Shadowlands or Classic enchanting materials. They establish historical context/patch risk, not a generic 2026 output rate. A special Mystic item yielding Vibrant Shard is not ordinary rare gear. Source-only evidence and exact links: [source note](../../evidence/observations/2026-10-28-1116-warwithin-batch011-source-only.md).

The separate **`tww-prospect-resourcefulness-savings`** hypothesis remains **BLOCKED**: the archived 2024 TWW Aqirite study reports nominal clicks, not actual saved ore. A newly found 2023 Dragonflight Serevite report gives 17.9% Resourcefulness and 0.26 ore saved per prospect across 10,000 ore, but it is a different expansion and lacks zero-inclusive per-cast refunds. The 2024 Aqirite rank study explicitly excludes saved ore from processed ore totals. No TWW formula, input-savings rate, or neutral-baseline inverse was promoted.

## Source memory and learning

Reused archived `1f83cnd` and `1fdvkmy` studies without repeat fetches; revisited `1g350pq` for the author's explicit saved-ore exclusion; three newly discovered original historical source families (two Blizzard threads, one Dragonflight Serevite report) plus one special-item applicability check. All newly found sources remain PARTIAL; none is FULLY_ANALYZED or current Retail matched. The six source-review events are in a unique worker-owned JSONL. Prior master QA feedback on synthetic DE and Resourcefulness denominator errors was applied; no self-awarded points.

## Validation, blockers and next exact targets

Eight deterministic static gates passed, 0 failed; 44/44 necessary P/E bounds pass; 44/44 rows linked to existing master source ledger. **Not run:** full JSON Schema validator, repository Node suite, WoW client. No historical studies were pooled across incompatible patch/gear/recipe conditions. No confidence deltas were awarded: 0 newly scored material fields, 0 >=90 promotions, 0 verified numerical mechanisms.

Next source-specific research targets for master QA: `profile:de:9:4:armor`, `profile:de:3:4:armor`, `profile:de:3:4:weapon` (empty profiles despite n metadata); `overlay:DE conditional fallback:exp9/q3/armor:depends on existing DE table or fallback` (exact current-build q3 equipment cast logs); `output-supp:dragonflight:192880:192880:2` (actual output versus refunded input); `tww-prospect-resourcefulness-savings` (Algari Prospecting spell 434018, rank-specific saved-ore histogram, exact build/skill/gear and 200+ casts per matched stratum). These are **QA/experiment targets**, not unauthorized overflow assignments.

**Production changes:** zero. **Master-owned queue/ledgers:** unchanged. **Merges/releases/schedules:** unchanged. Master must independently accept first-pass status and numeric conclusions.
