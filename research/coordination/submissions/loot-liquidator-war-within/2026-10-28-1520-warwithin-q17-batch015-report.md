# Loot Liquidator — The War Within Batch015 (queue revision 17)
2026-10-28 · research-only worker submission · exact assignment 2026-10-28-batch015-war_within

## P0 — Eight missing specialization-conditional output candidates (NOT admitted)
**35/35 exact queue keys audited** (13 TWW ore-output fields, 8 fixed smelts, 14 master-directed Midnight overflow). A previously unindexed Method guide published **August 12, 2024** explicitly distinguishes the **unskilled baseline** from **Gem Finding specialization**: Bismuth normally yields Amber, Aqirite normally yields Amber/Sapphire/Emerald, Ironclaw normally yields Amber/Ruby/Onyx; selecting the four gem specializations can make **all ores yield all five raw gem families**. The staged v0.4.0 `itemdb.lua` has only 13 PeaEsk source output rows for these three rank-two ores, and no conditional gem-family expansion. The eight exact missing input/output candidates are:

| Input rank-two ore | Missing conditional output IDs | Evidence level |
|---|---|---|
| Bismuth `210931` | Ruby `212495`, Emerald `212505`, Sapphire `212508`, Onyx `212511` | Guide-only conditional mechanism |
| Aqirite `210934` | Ruby `212495`, Onyx `212511` | Guide + Oct 14 original Aqirite experiment; Onyx separate Wowhead player comment |
| Ironclaw `210937` | Emerald `212505`, Sapphire `212508` | Guide-only conditional mechanism |

Sources: [Method prospecting guide (Aug 12, 2024)](https://www.method.gg/guides/the-war-within-ore-prospecting-guide), [original Aqirite study (Oct 14, 2024)](https://www.reddit.com/r/woweconomy/comments/1g350pq), [Wowhead Onyx player comment](https://www.wowhead.com/item=212511/ostentatious-onyx), item identity [Ruby](https://www.wowhead.com/item=212495/radiant-ruby) · [Emerald](https://www.wowhead.com/item=212505/extravagant-emerald) · [Sapphire](https://www.wowhead.com/item=212508/stunning-sapphire) · [Onyx](https://www.wowhead.com/item=212511/ostentatious-onyx).

**Do not admit these as unconditional or unskilled mappings.** Exact gem-node point thresholds, actual character eligibility, output rank, current 2026 client status and all four numerical fields are unknown. These eight candidate keys are **not** claimed as assigned queue keys or as master-approved new mappings; request a master assignment and eligibility-gated compiler representation. Each has per-field unknown with no fabricated zero.

## P1 — Independent four-field audit
- 13 PeaEsk 100-*gross-ore* source rows: `dropChance`, positive `yieldMin` and `yieldMax` remain unknown. Historical gross-ore-normalized `expectedQuantity` references are preserved (48/100), but **not actual completed-cast E**. The GameData Poisson chance is a model proxy, not observed P(hit).
- 8 previously admitted fixed smelt vectors: conditional successful-cast P=1, min=max=E=1 except Bronze=2; 80/100 provisional recipe support, no fresh casts. Preserve all direct reagents, forge, learned spell, expansion Mining skill, and rare teaching item `35273` for Hardened Khorium `46353`. These are **reused**, not new numeric fields.
- 14 master-directed overflow records: retain earlier R2-transfer or guide-based expected references only when explicitly labeled provisional; occurrence P and positive yield bounds unknown. Do not infer rank-1 rates from rank-2 observations.
- 35 source identities and all 140 four-field slots audited, no new verified 2026 numeric fields, no invalid numerical inequalities. Individual source ancestry is retained in the companion audit.

## P2 — Decision risk and patch chronology
The original **October 14, 2024** Aqirite R2 10,000-gross-ore cohort reported Ruby 43.5 and Onyx 38.4 per 1,000 ore, which normalize to **0.2175 Ruby and 0.192 Onyx per nominal five ore**. Those two *conditional* outputs are absent from staged Aqirite R2, so ignoring them could understate historical output value by `0.95 × (0.2175 × RubyPrice + 0.192 × OnyxPrice)` per nominal five ore, before deposits, time and resource-savings. This is **not** a current-Retail cast E, live AH quote or proven gold-action flip. The original author did not document the exact gem specialization/skill/refunds. The Method guide supplies a plausible eligibility explanation, not a matched causal experiment.

[Blizzard's October 25, 2024 hotfix](https://worldofwarcraft.blizzard.com/en-us/news/24148555/hotfixes-october-25-2024) changed prospecting so byproducts occur on every action rather than a byproduct-or-gem choice, reduced gem drop rates and maximum byproduct yields, and repaired the 40/40 Amber specialization perk. It does **not** say each named output individually has P(hit)=1. This hotfix was already archived; it is reused to forbid mixing Oct 14 rates with later PeaEsk samples without observation-date proof. Publication date is not cast date. No universal coefficient is inferred.

## Source learning and master handoff
- **New source index:** Method Aug 12 guide (secondary mechanics, no sample); independent qualitative Wowhead Onyx-from-Aqirite comment (no denominator).
- **Reused, not counted again:** Oct 14 Aqirite original cohort, PeaEsk three ore cohorts, official Oct 25 hotfix, all 8 smelt recipe pages, JD3K Midnight historical family.
- **Avoided:** 8 repeat smelt-page fetches and re-downloading prior study archives. Negative conclusion: a baseline-only ore mapping cannot represent conditional Gem Finding outputs; `unknown` is not `0`.
- **Next exact candidate pairs:** `210931→212495/212505/212508/212511`; `210934→212495/212511`; `210937→212505/212508`. Master must assign and verify each Gem Finding node and in-game output, then obtain actual zero-inclusive per-cast histograms stratified by ore rank, patch, specialization and Resourcefulness.
- **Current staged master baseline:** 984 provisional mappings / 165 inputs / 799 four-field complete / 403 missing numeric cells / 0 verified unskilled 2026 baselines, unchanged by this worker. Exhaustive Retail universe unverified. No production, canonical registry, assignments, source-memory cache, master ledgers or schedules edited.

## Validation
Exact 35 assigned stable keys, 8 distinct conditional candidates, 13+8+14 partition, all four independent fields per record, P/E and positive bound invariants passed. GitHub read-back required; Node CLI, Lua interpreter and WoW client not executed.
