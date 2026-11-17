# Coordinator original-source QA: Crystalline Glass Refine rank-direction inversion (2026-11-08 11:05 UTC)

## Scope / result
**New cross-layer research integrity finding, no new player casts or current addon regression proven.** Midnight Retail recipe **Refine Crystalline Glass**, spell **1307462**, consumes **10 quality-rank-1 Crystalline Glass** and produces **1 quality-rank-2 Crystalline Glass** for an eligible, successful craft. Two independently linked Retail commodity catalog entries show the IDs have a counterintuitive order:

| Role | Correct item ID | Catalog quality |
| --- | --- | --- |
| Reagent, 10 consumed | **242787** | R1 |
| Product, 1 nominal | **242786** | R2 |

**Primary/current sources read this run**:
- [WoWDB live spell 1307462](https://www.wowdb.com/spells/1307462-refine-crystalline-glass-a-professions-chaticon): 10 lower-quality glass -> one higher-quality glass, Midnight Jewelcrafting trainer 50, Jeweler's Tools and Bench; patch 12.1.0. Spell page describes nominal recipe output, *not* a 10-cast measured study.
- [GoldCap Retail commodity 242787](https://goldcap.gg/retail/us/items/242787): **quality rank 1 of 2**, exact item ID.
- [GoldCap Retail commodity 242786](https://goldcap.gg/retail/us/items/242786): **quality rank 2 of 2**, exact item ID.
- Current main [database/research/skill-quality-rules.json](https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/database/research/skill-quality-rules.json) (blob `932ae2accd969e3cbfc1c6382ef0a7a374f8f065`; reviewed November 6) explicitly identifies R1=242787 / R2=242786 in `glass-refine-ordered-quality-1307462`. Main [docs/SKILL-YIELD-RESEARCH.md](https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/docs/SKILL-YIELD-RESEARCH.md) lines 55-57 agrees.

## Precisely traced incompatible historical research identities

1. Preserved original [master-20261030-007](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/five-agent-completion/research/v3/evidence/master/2026-10-30T2310-refine-recipes-glass-stone.jsonl), blob `d67bfafd83a005a84ee2f5b2d2cce541cf868fd6`, instead asserts `inputItemID=242786, outputItemID=242787, inputsPerCast=10, outputCount=1`, labeling the ranks backwards. Its note says item IDs were supplied from older compiled reference rather than from the recipe page. This **historical original is left unchanged**.
2. Still-staged research [research/proposed/itemdb-curated-additions.json](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/five-agent-completion/research/proposed/itemdb-curated-additions.json), blob `af10e392b7e4fc26db131bbecfc073fb9cb92bfb`, `recordID=retail12.1:refine:242786:242787:spell1307462` repeats the **reversed** 10×242786 -> 1×242787 and records input R1/output R2. It is labeled **PROVISIONAL_CANDIDATE**, not a live applied recipe.

**Do not conflate with stone**: Refine Dusk-Shrouded Stone 1307466 is independently described as 18×242788 R1 -> 1×242789 R2; no direction inversion identified for this separate recipe. Current `database/research/rank-families.json` explicitly describes family IDs as unordered sets; their order cannot safely dictate rank.

## Disposition and next safe fix

**Category:** Invalid input/output identity and quality-rank direction in *old/staged research*, not absent evidence, AH price, output randomness, or observed casts. Main's current skill-to-output quality mapping is already corrected; the three-pass [PASS-3](https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/docs/usable-data-audit/PASS-3.md) reports refining recipes outside the shipped four-method adapter. Therefore **zero current actionable gold decisions, valuation changes, or tooltip regressions are established by this audit**. Misimport of the staged candidate later could invert costs/benefits, so it warrants scoped prevention.

Owner/research evidence reviewer should add an **append-only correction** citing `master-20261030-007` (no rewriting original), correct the staged candidate's ID/rank orientation and any linked downstream fixtures on a separate authorized engineering branch, and add a specific identity regression: recipe 1307462, cost 10×242787 R1 and result 1×242786 R2; exact learned-recipe/profession/bench/tool eligibility; no charging only one unit or pricing both ranks as simultaneous outputs. Assess the previously documented live-vs-PTR reagent display discrepancy (PTR rendered 5+10) before any full economic admission. Keep pending exact real-client eligibility and source validity labeled. No fabricated per-cast hit rate, output rank distribution, skill coefficient, or Resourcefulness effect. No use of MoP Classic.

**Actual work this run:** read repository charter, three-pass plan/checkpoints, current heads and worker statuses, research schema/queue/mechanics/strategy/flags, two separate older research source records, two live catalog entries and current source-linked live recipe, and protected current-quality policy; compared exact source path/blob values. Created this **research-only coordinator note**. Did **not** run Lua/addon, compiler/estimator, synthetic-price valuation/formatter, actual Retail client, PR changes, merge or release.
