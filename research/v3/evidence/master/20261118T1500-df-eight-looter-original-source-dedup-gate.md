# Dragonflight Looter cumulative-source dedup: seven repeated inputs, one new candidate

**Checked:** 2026-11-18T15:05:44.841Z UTC (tool-clock timestamp). **Scope:** original-source identity and unit gate for worker's 2026-11-18 14:34Z eight-input/16-row report; no new experimental operations, new unconditional expected quantities, current Retail EV or addon import.

## Direct cross-file results

| Input | Reported item operations | Material occurrence numerators (output ID: hits) | Prior pin comparison | Conditional minimum shared-hit bound* |
| --- | ---: | --- | --- | ---: |
| 200333 | 157 | 194124:92, 200113:90 | No prior numeric occurrence row found in examined pinned index | 25 |
| 200334 | 62 | 194124:39, 200113:39 | Exact same original cumulative counts already pinned | 16 |
| 200339 | 55 | 194124:34, 200113:28 | Exact same original cumulative counts already pinned | 7 |
| 200396 | 62 | 200113:36, 194124:34 | Exact same original cumulative counts already pinned | 8 |
| 200398 | 46 | 194124:27, 200113:26 | Exact same original cumulative counts already pinned | 7 |
| 200399 | 52 | 200113:31, 194124:25 | Exact same original cumulative counts already pinned | 4 |
| 200401 | 51 | 200113:33, 194124:24 | Exact same original cumulative counts already pinned | 6 |
| 204461 | 692 | 194123:653, 194124:58 | Exact same original cumulative counts already pinned | 19 |

**Conclusion:** Seven of the eight input-side cumulative vectors (14 of 16 material rows) are **exact duplicates of existing pinned `main` original-source snapshots**, even though the new worker file uses different `studyKey` strings, shorter URL paths or new record IDs. These are not seven independent new disenchant studies, and the 1,020 previously indexed reported input operations must not be counted again. 200333 is the **one first-seen candidate in the compared pinned material vectors**: 157 Wowhead Looter-reported item disenchants, with Vibrant Shard 194124 positive on 92 and Resonant Crystal 200113 positive on 90. Its original [PTR item source](https://www.wowhead.com/ptr/item=200333/scalesworn-cultists-frock) was independently opened in indexed source text; 157, 92, 90 and the displayed rounded 59%/57% match. The historical cohort collection epoch, item bonus, skill/spec and client build are unknown; current PTR page is not an at-cast live Retail record.

All seven repeated vectors were compared by **(input item ID, output item ID, common operation denominator, material-hit numerator)**; not by filename, date, record ID, studyKey or display language. Known examples include the 200334 39/62 and 200339 34/55 plus 28/55 datasets previously independently audited in pinned `master` evidence. Changed presentation URL (`/ptr`, `/ptr-2`, `/item`) is not an independent source.

## Original pinned files compared
- 200334: [2026-11-06T1707-new-sandals-disenchant-hits.jsonl](https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/database/research/v3-snapshot/research/v3/evidence/dragonflight/2026-11-06T1707-new-sandals-disenchant-hits.jsonl)
- 200339: [20261113T1341-looter-200339-and-material-side-crosschecks.jsonl](https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/database/research/v3-snapshot/research/v3/evidence/dragonflight/20261113T1341-looter-200339-and-material-side-crosschecks.jsonl)
- 200396: [2026-11-15T1030-eight-unindexed-gear-looter-counts.jsonl](https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/database/research/v3-snapshot/research/v3/evidence/dragonflight/2026-11-15T1030-eight-unindexed-gear-looter-counts.jsonl)
- 200398: [2026-11-15T1540-six-vault-shaman-looter-hit-cohorts.jsonl](https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/database/research/v3-snapshot/research/v3/evidence/dragonflight/2026-11-15T1540-six-vault-shaman-looter-hit-cohorts.jsonl)
- 200399: [2026-11-15T1540-six-vault-shaman-looter-hit-cohorts.jsonl](https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/database/research/v3-snapshot/research/v3/evidence/dragonflight/2026-11-15T1540-six-vault-shaman-looter-hit-cohorts.jsonl)
- 200401: [2026-11-15T1030-eight-unindexed-gear-looter-counts.jsonl](https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/database/research/v3-snapshot/research/v3/evidence/dragonflight/2026-11-15T1030-eight-unindexed-gear-looter-counts.jsonl)
- 204461: [2026-11-17T0336-five-live-item-looter-cohorts.jsonl](https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/database/research/v3-snapshot/research/v3/evidence/dragonflight/2026-11-17T0336-five-live-item-looter-cohorts.jsonl)

Current worker file: [2026-11-18T1434-eight-unique-df-gear-looter-occurrences.jsonl](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/five-agent-completion/research/v3/evidence/dragonflight/2026-11-18T1434-eight-unique-df-gear-looter-occurrences.jsonl) (blob `f41877364bbc69b126965cde12c8a96fd7e61208`).

## Numerator, units and population cautions

* A per-material `castsWithDrop / casts` is a reported material-specific occurrence proportion, **not** observed total stack units, unconditional expected quantity, rank-qualified probability, current Retail character rate, or eight independent source denominators. Every row has `totalQuantity=null`; no verified per-event 0..N or matched rank/build/refund ledger was added.
* In **every** two-output pair, the material hit sum exceeds the common N. *If* both reports refer to the same N underlying events, the minimum joint-positive intersection is `max(0, hitsA + hitsB - N)` by inclusion–exclusion. For new 200333, 92+90−157 = **25**. This is a **conditional arithmetic bound**, not 25 observed dual-output casts. Inconsistent Looter denominator semantics are another possibility. Do not infer globally empty disenchants from per-output missing hits.
* Source item quality and item-level variants can change (notably 204461). A currently displayed scaled item level on a source page does not establish the disenchant-time bonus/version. Missing data remains unknown; no fake probabilities, output totals, gold EV or copied skill coefficients.
* The 200333 row can be retained as a clearly labeled cumulative occurrence reference once lineage/patch context is resolved. Do not promote duplicate rows to independent confidence weight or request another copy of the same Wowhead table. Prioritize post-release Midnight Umbral Tin 237362 output-ranked completed cast/quantity/refund receipts; this DF source audit prevents false numerical confidence rather than producing a new current-Retail recommendation.

## Validation done

**36/36** deterministic in-process JavaScript structural/identity/unit assertions passed over the exact 16-row worker blob and seven pinned original-source snapshot files. Assertions checked per-input shared denominator, positive row count, missing total quantities, exact (ID, output, N, hits) matches and split of 14 repeated versus two first-seen rows. Independent web-indexed inspection checked 200333's 157/92/90 item-side table. No estimator, compiled ItemDB, valuation engine, Lua, tooltip, CI trigger, or live WoW client was run; prior pre-existing CI checks do not validate this audit.

Owner-scope controls: no changes to main, integration branch, worker evidence/status, append-only originals, other PRs, merges, releases or schedules.
