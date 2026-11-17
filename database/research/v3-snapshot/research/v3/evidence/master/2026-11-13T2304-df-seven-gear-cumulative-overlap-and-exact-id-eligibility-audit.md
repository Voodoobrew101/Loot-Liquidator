# T0041/T0046 coordinator audit — seven Dragonflight item-side Looter references
Checked 2026-11-13 23:04 UTC. Scope is source identity, displayed field semantics and a deterministic arithmetic guard, **not** newly gathered player casts or live Retail item eligibility.

## Pinned repository source and independent arithmetic
Worker source: [dragonflight 2026-11-13 22:34Z evidence](../dragonflight/2026-11-13T2234-seven-gear-looter-hits.jsonl), fetched as blob `5fe278d39313dda8407152d7e14883c9a9acd2d7` on research head `fa1aa9fdb0c922c3bad16a7e6d7049d8e350ccbb`. Parsed 15 JSONL lines: 14 `drop` records covering 7 exact inputs and one non-drop searched record; **do not include the searched record as a study**. The 14 entries have `castsWithDrop` and an exact output identity (194124 Vibrant Shard or 200113 Resonant Crystal), but each leaves `totalQuantity` and `histogram` null.

If each of the two source-reported material-hit counts for an input shares the same original item-operation denominator, inclusion–exclusion requires at least `max(0, shardHits + crystalHits - itemOps)` operations where both materials occurred. This is a conditional *lower bound* on overlap, not observed joint outcomes, and cannot give unknown stack quantities or all-material zero operations.

| Exact input | Source-reported item operations | Vibrant Shard hits | Resonant Crystal hits | Conditional minimum co-occurrences |
| --- | ---: | ---: | ---: | ---: |
| 200394 Wristguards | 26 | 18 | 13 | 5 |
| 200388 Sabatons | 39 | 17 | 26 | 4 |
| 200391 Greaves | 67 | 31 | 45 | 9 |
| 200387 Cuirass | 61 | 42 | 27 | 8 |
| 200389 Handguards | 60 | 36 | 34 | 10 |
| 200326 Grips | 162 | 100 | 90 | 28 |
| 200377 Camouflage | 6 | 4 | 3 | 1 |
| **Totals from seven source-specific tables only** | **421** | **248** | **238** | **65** |

Thus 486 per-material source-reported hits are not 486 distinct disenchant operations, and the at-least-65 overlap is conditional on the **source reports' cohort denominators really matching**, not a new measurement. Do not renormalize percentages to 100%, invent 0 yields, assume a 1-unit stack, sum independently copied snapshots, or import an unconditional current-Retail EV.

## Independently read exact-ID catalog and source-field evidence
Read LIVE WoWDB pages for exact base IDs [200326](https://www.wowdb.com/items/200326-draconic-hierophants-grips), [200377](https://www.wowdb.com/items/200377-vault-delvers-camouflage), [200387](https://www.wowdb.com/items/200387-stormwing-harriers-cuirass), [200389](https://www.wowdb.com/items/200389-stormwing-harriers-handguards), and [200391](https://www.wowdb.com/items/200391-stormwing-harriers-greaves). Each lists **Cannot be disenchanted**, despite the matching exact-ID Wowhead Looter source claiming 162, 6, 61, 60 and 67 aggregated operations respectively. These are **five new catalog-versus-Looter eligibility conflicts**, not proof the live client actually rejects those versions. WoWDB [BETA exact ID 200388](https://beta.wowdb.com/items/200388-stormwing-harriers-sabatons) also says cannot disenchant; the [LIVE page](https://www.wowdb.com/items/200388-stormwing-harriers-sabatons) timed out, so classify its live eligibility **unknown**. Exact ID 200394 live/beta WoWDB URLs could not be read; mark **unknown**, not eligible or prohibited. Do not mistake [different item ID 203565](https://www.wowdb.com/items/203565-stormwing-harriers-greaves), which has the same Greaves name, for the worker's exact 200391.

Independently retrieved the current Wowhead indexed original exact-ID tables for [200394](https://www.wowhead.com/item=200394/stormwing-harriers-wristguards), [200391](https://www.wowhead.com/item=200391/stormwing-harriers-greaves), [200389](https://www.wowhead.com/item=200389/stormwing-harriers-handguards), and [200377](https://www.wowhead.com/item=200377/vault-delvers-camouflage): their displayed hit counts match the worker's transcription; each displays a **1–2** *table range* beside Vibrant Shard. This is a new source-displayed positive-stack interval candidate, **not an independently observed 0/1/2 histogram, mean, per-operation totalQuantity, current-character yield or rate**. Other Wowhead raw pages returned bot/JavaScript blocks; their worker counts were checked only for arithmetic consistency.

Wowhead currently presents a scaled item level **72** for some of these exact IDs (e.g. 200394, 200389, 200377), whereas WoWDB shows archive item levels **389–395**. Source snapshots/selected versions do not disclose the itemLink bonus, level, game build, enchant skill, provenance or date of the aggregated Looter submissions. These contextual differences must not be silently combined into a current Retail eligibility or rate assertion.

## Disposition and next useful evidence
- **Identity/eligibility gate:** hold these seven cumulative item-side references outside unqualified current-action recommendations pending original at-cast itemLink/bonus/build plus a witnessed successful or rejected client action; five exact LIVE catalog conflicts, one BETA-only conflict, one catalog-unavailable base ID.
- **Possible supported field:** preserve Wowhead's displayed Shard 1–2 interval as a labeled *reference-table range* when traceably compatible, without upgrading to measured minimum/maximum or inventing event histogram/quantity. Keep Crystal positive range unknown absent source data.
- **Numeric gate:** request original item-specific 0..N material distributions, counted operations including zeros, source revision/patch and skill/spec. If not available, prioritize original current Midnight T0005/T0039/T0045 and Dragonflight T0041 paired-sheet denominators rather than copying more cumulative gear tables.
- **Validation actually executed:** GitHub evidence fetch; parsed 15 lines, grouped 14 material rows by exact input; checked arithmetic and non-drop exclusion; opened five exact LIVE and one BETA catalog pages, four indexed exact Wowhead material tables and separately noted source fetch failures. **Not executed:** Lua/ItemDB compiler, offline synthetic-price actual resolver or tooltip, WoW client, new measured operation, verified gold EV, PR edit or merge.
