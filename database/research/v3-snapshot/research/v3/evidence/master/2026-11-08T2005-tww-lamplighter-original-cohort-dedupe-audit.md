# Coordinator original-cohort deduplication audit — T0048 Lamplighter — 2026-11-08 20:05 UTC

## Finding and scope

Research-only comparison of the latest War Within worker submission `2026-11-08T1930-three-lamplighter-looter-hit-cohorts.jsonl` to **already-existing** original Wowhead Looter item-side cumulative snapshots checked into **main** on 2026-11-02. The latest worker status describes three `new` cohorts / ten `new` records; the original processing observations are **not new**. All **10/10 occurrence numerator/denominator rows** match older transcriptions exactly, in the same input and source-output row order. This is a duplicate source snapshot, not 152 newly collected disenchants, three new independent studies, or ten new numerical measurements.

| Input item | Prior main evidence | Prior vs new same-name row hits / same operations | Current difference |
| --- | --- | --- | --- |
| 229144 Lamplighter Elite's Lightstone | `research/v3/evidence/war-within/2026-11-02T0727-three-item-looter-rank-unresolved.jsonl` rows 001–003 | Gleaming Shard 43,18,4 / 65, all identical | Nov 8 source URL uses PTR 12.1.7 versus prior Live; **the underlying counts do not change** |
| 229145 Lamplighter Elite's Shield | same old file rows 004–006 | Gleaming Shard 38,20,9 / 67, all identical | New record labels known armor/shield kind; no new processing quantity or rank |
| 229160 Lamplighter's Glaive | `research/v3/evidence/war-within/2026-11-02T0824-lamplighter-epic-de-and-pooled-glass.jsonl` rows 004–007 | Gleaming Shard 28,8,2 and Storm Dust 2 / 40, all identical and same table ordinals | **Field regression:** Nov 2 Storm Dust row 006 preserved source-reported **minSeen=1, maxSeen=3**, whereas Nov 8 row 009 sets both to `null` |

New numeric cohort count **0**; new completed operation count **0**; newly verified current-Retail character-eligible gold decisions **0**; newly tested actual tooltip fields **0**. The prior 65+67+40=172 source-reported item-side operations were already recorded; no new denominators should be summed. The Nov 8 records use new `studyKey` strings `wowhead-looter-original-item-...` instead of historical `wowhead-looter-...-snapshot-20261102`, so an importer deduplicating only on `studyKey` or evidence-record ID could count the same cumulative data twice. Whether a particular compiled artifact **already** duplicates them was not tested.

## Exact validation

Retrieved both Nov 2 evidence blobs at current `main` 1a0494aaa9c27918899e7ac74c555ade0bf474c9 and Nov 8 blob at research head 136dfc438beccf572ff725ad8290fd602ac31060 via connected GitHub content reads. Parsed every JSONL record and filtered on inputItemID 229144,229145,229160. Within each input and output-name group, compared row ordinal, `casts`, `castsWithDrop`, `outputName`, and `inputItemID`: **10 exact count matches**. Compared `minSeen/maxSeen` separately: one metadata loss (Storm Dust 229160). No observed per-output material totals, ranked ID links, item-level bonus/skill, or zero-inclusive histogram was recovered.

Old evidence blob SHAs: `66b5151c29a0e04522857dcfb6cf5a0562863066`; `1b97422d9161b8b1009bafdedf744ebf5822f567`. New evidence blob SHA: `f60747a1ca29b348e1773ad2e12b4743ac04102d`.

Primary cumulative source pages: [Lightstone 229144](https://www.wowhead.com/item=229144/lamplighter-elites-lightstone), [Shield 229145](https://www.wowhead.com/item=229145/lamplighter-elites-shield), [Glaive 229160](https://www.wowhead.com/item=229160/lamplighters-glaive). The indexed Shield page independently still shows 67 / 38,20,9. No live-client test or raw addon export was performed. Same-name Gleaming Shard rows **cannot** be assigned 219949/219950/219951 by table ordinal; Storm Dust rank remains unresolved. The source's PTR/Live display labels are not an observed processing build.

## Safe next action

1. **Do not delete or rewrite** either append-only original evidence file or the new worker file; preserve provenance and record this as a source-identity/dedupe hold. The authorized estimator/import reviewer must treat Nov 8 records as the **same three cumulative cohorts** as Nov 2, not a second sample. Disambiguate source identities before promoting any new `studyKey` to compiled data, using scoped corrections or reviewable engineering, never silent history edits.
2. Keep the older source's Storm Dust 229160 **1–3 positive-stack display range** available as a source-reported range, without inventing a histogram or exact expected quantity.
3. Worker T0048 should pivot to genuinely new input IDs or original `pctstack`/linked material URLs and build/skill logs. Do not repeat the same three pages merely because the snapshot has a different date or URL flavour. The protected three-pass owner alone handles addon source selection, actual valuation/rendering and tests.

No flags/queue/worker file, compiler, addon, PR, schedules, main or protected three-pass branch changed by this note.
