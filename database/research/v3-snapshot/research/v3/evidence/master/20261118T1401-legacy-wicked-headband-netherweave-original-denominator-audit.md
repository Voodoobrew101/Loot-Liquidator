# Original-source DE denominator/epoch gate — 2026-11-18 14:01 UTC

**Scope:** Read-only manager validation of the newest Legacy worker report against independently accessed source comments. **No new owner Retail pricing, addon numeric compilation, source edits, or in-game test.** Manager evidence and status are separate from worker ownership.

## Evidence and exact revision
- Worker: [2026-11-18 13:52 original TBC/Classic report](../legacy/2026-11-18T1352-tbc-classic-original-casts.jsonl), blob `64cfb9b7640c1520a81c91425d188d099212537b` (13 rows, six distinct study keys).
- Earlier [2026-11-02 Wicked Leather evidence](../legacy/2026-11-02T0243-wicked-leather-runecloth-cohorts-and-prospecting-patches.jsonl), blob `0e63bd2d6a72ad9c5a8dfe00d2ab887c405db1e9` (12 same-item rows; already holds 30/37/69 precise DE cohorts and approx-230 percentage-only histogram).
- Primary direct source text checked: [Arcane Dust TBC comments](https://www.wowhead.com/tbc/item=22445/arcane-dust) and [Wicked Leather Headband Classic comments](https://www.wowhead.com/classic/item=15086/wicked-leather-headband). Sources describe **historical TBC/Classic**, not verified current Retail character item variants or drop rates.

## Verified original-source fields — no double counts
1. **Netherweave Gloves 21851, TBC:** one original commenter says five *completed* disenchants for nine Arcane Dust 22445 units. Historic unconditional units/de = 9/5 = **1.8**; material occurrence hits, zeros and positive stack sizes unknown.
2. **Wicked Leather Headband 15086, Classic:** distinct commenter says **15** headbands processed for 11 Illusion Dust 16204 units, eight Greater Eternal Essence 16203 units and two Large Brilliant Shard 14344 units. Historic unconditional material units/de = **11/15**, **8/15** and **2/15**, respectively. These **three rows share one 15-cast cohort**; no per-material hits/histograms.
3. **Wicked Leather Headband 15086:** third commenter explicitly narrates three disenchants producing a shard in one operation and dust in the other two. Thus **three completed operations**, shard hit **1/3** with two material-specific nonhits, dust hit **2/3** with one material-specific nonhit. **Material quantities are NOT stated**; neither result implies the whole disenchant yielded nothing, and neither hit count is a unit total.
4. The **147 crafted rings** with raw pooled totals 265/31/6 have no confirmed disenchant denominator and no uniquely identified ring input (24074 or 24075). The **10 purchased headbands** and separate **10 nominal headbands** are not counted completed operations. **Do not divide those output totals by fabricated casts** or assign ring outcomes to either item ID.

## Results and admission
- In-process connected-GitHub JSONL assertions **30/30 passed**, zero failed: row/cohort identifiers, exact raw units, actual completed operations vs crafting/purchases, hit-only distinction, duplicate historical cohort guards against prior pinned 30/37/69/~230 entries. Fresh primary web pages visually/textually cross-checked. This was **not** a Python estimator, Lua, price engine, tooltip renderer or WoW test.
- Exactly **23** separately described completed historical DE operations (5 + 15 + 3) are newly in this worker report relative to its six bounded source keys. **Not** 23 current-Retail operations; no current gold coverage advance. Old ~230 proportions are already in November 2 evidence, so not a new source or reconstructed integer histogram.
- Do not admit pre-2008 WoW Classic/TBC yields into current Retail absent an applicable patch/item-link/bonus/skill context bridge and actual runtime fixture. If useful for historic reference, preserve provenance and unknown fields independently of any current Retail valuation.
- Owner integration branch `implementation/usable-data-tooltips`, immutable `4df9ae8` snapshot, workers' original evidence, addon paths and PRs left untouched.

**Next source priority:** post-release `T0005/T0039` Umbral Tin 237362 ranked completed prospect/export and material hits/zeros/refunds/skill; `T0045` Tranquility Bloom 236761 true 10-herb mill outcome ledger. Legacy `T0047/T0042` should seek a source-original Warmaul 24995 live-context DE or Cobalt 36909/Fel Iron 23424 casts, not more repeats of already indexed headband commenters.
