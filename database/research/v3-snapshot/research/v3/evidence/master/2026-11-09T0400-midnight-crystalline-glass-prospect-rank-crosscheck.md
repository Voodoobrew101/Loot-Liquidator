# Coordinator cross-source audit — five Midnight prospecting Crystalline Glass rank/ID conflicts

Checked at 2026-11-09T04:02:06.807Z UTC (research-only). This audit compares **existing** immutable original transcriptions to their **original player wording** and independently indexed item-quality catalogs. It is an ID/quality-rank integrity finding, **not** a new cohort, observed cast, measured chance, or demonstrated shipped-addon regression.

## Catalog source and conditionality

- [Retail commodity 242787](https://goldcap.gg/retail/us/items/242787) is Crystalline Glass quality **rank 1 of 2**.
- [Retail commodity 242786](https://goldcap.gg/retail/us/items/242786) is Crystalline Glass quality **rank 2 of 2**.
- These opposite-to-naïve-ID-order identities were already independently documented in [the earlier refine-direction audit](2026-11-08T1105-crystalline-glass-refine-rank-identity-inversion.md). The NEW finding here is their mismatch in **five historical prospecting study rows**; it is separate from the refine recipe error.

## Two rank-two source rows with wrong output item ID

The [original player Stormwarning July 3, 2026 Blizzard forum report](https://us.forums.blizzard.com/en/wow/t/sunglass-vial-1-hour-material-test/2323248) lists **rank-2 (gold) Crystalline Glass** and says the test used two Jewelcrafters. Existing worker-owned source file [2026-10-31T1911-stormwarning-r2-prospecting.jsonl](../midnight/2026-10-31T1911-stormwarning-r2-prospecting.jsonl), original blob `44a2868470e15a3f03778c5ffcccac685ddcad29`, has:

| Original evidence ID | Source context | Original total | Existing outputItemID/outputRank | Sourced rank-specific candidate |
| --- | --- | ---: | --- | --- |
| `midnight-20261031-191102` | Refulgent Copper Ore R2 `237361`; 67 source-reported ore | 8 glass units | `242787` / 2, **inconsistent** | `242786` / 2 |
| `midnight-20261031-191107` | Brilliant Silver Ore R2 `237365`; 66 source-reported ore | 16 glass units | `242787` / 2, **inconsistent** | `242786` / 2 |

Together these are **24 reported material units already present in original evidence**, **not 24 new measured units**. The source does **not** state completed prospecting operations, used/refunded/reprocessed inputs, separate itemLinks, per-output positive-operation counts, zeros, patch/build or skill/spec of each Jewelcrafter. Do **not** turn 67/66 gathered ore into sample denominators. The exact item-ID crosswalk is based on the source's quality label plus separate commodity catalogs, not original output hyperlinks.

## Three rank-one source rows with wrong output item ID

The [original HeadtripVee Reddit rank-separated table](https://www.reddit.com/r/woweconomy/comments/1sfds1u/did_prospecting_change/) labels its **Crystalline Glass 1** line. Existing worker-owned [2026-10-30T1906-headtripvee-rank-percentages-and-diamond-unlocks.jsonl](../midnight/2026-10-30T1906-headtripvee-rank-percentages-and-diamond-unlocks.jsonl), original blob `31795a5b5762c26a99829dfdb79dee6d03f2eaeb`, has:

| Original evidence ID | Ore input/rank | Original percentShown | Existing outputItemID/outputRank | Sourced rank-specific candidate |
| --- | --- | ---: | --- | --- |
| `midnight-20261030-950` | Refulgent Copper R1 `237359` | 19.93 | `242786` / 1, **inconsistent** | `242787` / 1 |
| `midnight-20261030-951` | Brilliant Silver R1 `237364` | 15.71 | `242786` / 1, **inconsistent** | `242787` / 1 |
| `midnight-20261030-952` | Umbral Tin R1 `237362` | 16.28 | `242786` / 1, **inconsistent** | `242787` / 1 |

These are pre-hotfix historical source percentages with **ambiguous meaning/denominator**. They are **not confirmed P(output in one cast)**, no measured casts or expected units are inferred, and they must not be promoted to current Retail gold EV merely because their item IDs can be normalized. Same original table, not three newly independent player studies.

## Correct disposition and validation boundary

**Category:** invalid quality-rank/output-item identity in stored historical source records. Potential downstream consequence is **incorrect rank-specific material price lookup** if an importer uncritically selects the contradictory ID; however the shipped ItemDB/engine/tooltip path has **not been shown** to consume these five records wrongly. No source-absent conclusion and no live-character eligibility or prices are established.

**Safe action for the three-pass implementation owner / append-only correction reviewer:** preserve these five original worker records byte-for-byte; attach source-linked correction records in an authorized disjoint review path, enforce 242787=R1 and 242786=R2 without merging quality alternatives or adding duplicate cohorts, and test two rank-distinct synthetic material prices through actual ItemDB resolver, valuation, formatter and source selection. Honor profile, Resourcefulness, unlock and historical date gates. Do not confuse the separate refine recipe correction with this prospect audit. No main/three-pass/worker edits were made by the coordinator.

**Completed operations this checkpoint:** source comparison of two immutable evidence files, two original sources and catalog mappings; five exact field inconsistencies documented. **New independent casts 0; independently confirmed per-output occurrence denominators 0; new current-context gold decisions 0; actual tooltip fields verified 0.** No offline engine, compiler, Lua, GitHub check, or WoW client test was executed for this note. The research-branch CI result recorded separately predates this new note.
