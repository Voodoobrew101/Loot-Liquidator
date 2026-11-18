# Fresh Legacy source gate: 11 absent frozen no-DE identities and two historical chest-to-shard casts

Checked 2026-11-18T04:10:32.139Z UTC. **Research-only source/identity audit, not in-game proof, a new Retail valuation, or an accepted probability.** Compare the current 2026-11-18T0348 Legacy worker source against the owner's untouched 12.1.7.70493 DB2 snapshot and 4df9ae8 frozen source on `implementation/usable-data-tooltips`. All tests below were executed as in-memory JavaScript source assertions; no Python, Lua, economic engine, rendering, CI job trigger or WoW client execution.

## Newly examined source and exact old-to-new gap

Worker original: [13-row new Legacy evidence](../legacy/20261118T0348-imbued-robe-and-classic-no-de.jsonl) (blob `bba61e8e8b27f9568952ebe8791b1b2489fa168c`, commit at read-time research head `cf639a4a54d25b16b91ec4e31574aff8a5130e9b`). Eleven unique `noDisenchant` item IDs:
- `5092 Charred Razormane Wand`
- `21040 Narain's Robe`
- `2615 Chromatic Robe`
- `5110 Dalaran Wizard's Robe`
- `5238 Pitchwood Wand`
- `2612 Plain Robe`
- `2618 Silver Dress Robes`
- `40018 Wand of Onyx`
- `5239 Blackbone Wand`
- `2617 Burning Robes`
- `6144 Neophyte's Robe`

All **11 of 11** are **absent as exact IDs** from the owner's pinned Retail `database/sources/DB2Restrictions.lua` `NO_DISENCHANT` integer array (21,061 IDs, blob `e03c7b0c302b1ef718b62b7de9c364e2c0b6ea03`) **and** the frozen `database/research-v3-baselines.lua` explicit no-DE collection (blob `ae953ffde49a27c0270408d0facbf6d96ee7955c`). This proves *source-to-frozen exact-ID omission*, **not** that the addon currently offers a wrong action: runtime may reject an item by other rules, and an old catalog flag does not prove current-character eligibility.

Independent **Retail catalog** source checks found `Cannot be disenchanted` for 5238 [Pitchwood Wand](https://www.wowhead.com/item=5238/pitchwood-wand), 5239 [Blackbone Wand](https://www.wowhead.com/item=5239/blackbone-wand), 5110 [Dalaran Wizard's Robe](https://www.wowhead.com/item=5110/dalaran-wizards-robe), and 2617 [Burning Robes](https://www.wowhead.com/item=2617/burning-robes), with ordinary sale/vendor or drop listings. Retail `5092` [Charred Razormane Wand](https://www.wowhead.com/item=5092/charred-razormane-wand) has the label **but says no longer available**. Retail `21040` [Narain's Robe](https://www.wowhead.com/item=21040/narains-robe) says item source removed. `40018` [Wand of Onyx](https://www.wowhead.com/wotlk/item=40018/wand-of-onyx) and `6144` [Neophyte's Robe](https://www.wowhead.com/tbc/item=6144/neophytes-robe) were verified only in WotLK/TBC Classic catalogs during this audit; do not infer current Retail variants. `6144` is **not** same ID as present Retail vendor robe `52547`, nor Classic `6119`/`20891`. Current Retail catalog status for 2612/2615/2618 was not independently checked in this run.

**Disposition:** four higher-confidence Retail-catalog **reference-only omission candidates** `5110/5238/5239/2617`, two labeled but removed/unobtainable `5092/21040`; five remaining `2612/2615/2618/40018/6144` held for exact current-Retail source/availability verification. The worker's all-eleven original flags remain append-only; do not manufacture a live DE restriction or add an addon overlay in the owner-controlled three-pass branch.

## Newly observed numeric source, without false 100%-chance promotion

The same original [archived Thottbot comment on the Imbued Netherweave Robe](https://www.wowhead.com/wotlk/item=21861/imbued-netherweave-robe) explicitly says the author disenchanted **one 21861 Robe** and **one 21862 Tunic**, getting **one 22449 Large Prismatic Shard from each**. Independent [search-indexed original text](https://www.wowhead.com/mop-classic/item=21861/imbued-netherweave-robe) corroborates this statement. These are **two completed distinct item operations by the same author**, not two independent studies, nor a cohort covering all rare armor. Each exact input supports `casts=1`, `castsWithDrop=1`, `totalQuantity=1`, observed positive `{"1":1}`. Original build, source age, profession skill, and modern eligibility remain unknown; **one positive hit is not a calibrated 100% future occurrence probability** and unobserved alternative outputs are not ruled out.

Both `21861` and `21862` are absent as exact input processing keys in the inspected frozen owner v3 Lua. A separate historical [reference catalog for the robe](https://worldofwarcraft.fandom.com/et/wiki/Imbued_Netherweave_Robe) lists Large Prismatic Shard and Void Crystal alternatives; its percentages are reference numbers, not the two-cast observation and must never be added to the observed denominators. The two rare cloth chest records might inform labeled low-sample exact-item reference fields after modern scope checks, **not** the full TBC rare-armor group `Disenchant:gear:1:3:armor:x1` or current Retail gold recommendation.

## Checks and priorities

Executed **106/106** JS assertions, 0 failures: exact count/type, 11 unique IDs and HTTPS source strings, 21,061-item DB2 parse, 11 absent exact DB2/frozen identities, two separated one-cast shard totals/histograms, duplicate-author original lineage, unknown build/skill and exact frozen input absence. Checked 6 specific Retail catalog labels and two historical-only catalogs through web results. **No current WoW test, engine/tooltip fixture, Python compiler, Lua test or newly priced output.**

**Next:** current-build Midnight T0005/T0039 Umbral Tin `237362` and T0045 Tranquility Bloom `236761` completed-operation 0-N/rank/skill/refund records remain the high-value worker-owned priorities. A future controlled eligibility fixture can test the four current Retail-labeled no-DE IDs against the actual resolver/tooltip; do not touch the protected owner integration branch, original worker files, PRs or schedules in this audit.
