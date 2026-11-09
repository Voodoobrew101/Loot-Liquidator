# T0048: two R2 Storm Dust cumulative snapshot duplicates cross model-group boundaries

Reviewed 2026-11-09T20:04:15.793Z UTC; **static source and estimator review only**. No new cast evidence or current Retail eligibility claim.

## Newly closed source-identity gaps

The war-within worker's Nov 9 18:25 snapshot audit marked 237867 and 245737 as *possible* duplicates after independently identifying six other repeated original cohorts. Comparison against the original **Nov 1 17:21** worker evidence confirms two exact earlier fingerprints on the same original cumulative Wowhead PTR Storm Dust rank-2 page:

| Input | Earlier record | Nov 9 record | Operations reported | Rank-2 Storm Dust material hits |
|---|---|---|---:|---:|
| Oathsworn Defender's Breeches (237867) | `war-within-20261101-1721-008` | `war-within-20261109-1825-004` | 101 | 40 |
| Ritualbreaker's Band (245737) | `war-within-20261101-1721-010` | `war-within-20261109-1825-006` | 215 | 81 |

Both dates refer to anonymous cumulative Wowhead Looter *transcriptions*, not two independent dated cohorts; original sample/build/bonus/skill and stack quantities remain unknown. Exactly matching material/operation numerators and denominator, item/output IDs, and original URL establish duplicated *published source figures*, **not** proven identity of individual player casts. Treat the Nov 9 records as duplicate snapshots until distinct original operation evidence exists. Do not add 101+215 apparent operations to the independently measured cohort count, or convert 40/101 and 81/215 into output stack quantity.

Original source: https://www.wowhead.com/ptr/item=219947/storm-dust

Prior file: [2026-11-01T1721-wowhead-r2-stormdust-item-cohorts.jsonl](../../evidence/war-within/2026-11-01T1721-wowhead-r2-stormdust-item-cohorts.jsonl)

New file: [2026-11-09T1825-eight-original-r2-dust-items.jsonl](../../evidence/war-within/2026-11-09T1825-eight-original-r2-dust-items.jsonl)

## New selection/estimator risk exposed by the duplication

The **old two rows have `gearGroup=null` and exact `inputItemID`**. The **new rows carry nonnull `gearGroup={expansion:"The War Within", quality:null, kind:"armor", itemLevelRange:null}`** despite retaining those same exact item IDs.

In current [build_estimates.py](../../tools/build_estimates.py), `key_of` prefers `gearGroup` over `inputItemID`; the old rows therefore route to input-specific estimate keys while the new ones route to the broad `gear:The War Within:None:armor` key. `study_identity` normalizes PTR and live Wowhead page URLs and can identify the same reported study; however `misplaced_copies` suppresses cross-group rows only when one has *strictly higher* `group_specificity`. The current `group_specificity` counts all non-`family:` components, including `gear:`, so these two keys appear equally specific even though one is a broad gear family. Per-group `seen` dedupe cannot by itself prevent the same source figures entering different groups.

**Risk, not demonstrated production regression:** the Nov 9 append-only records may contribute to a broad TWW gear estimate as well as the prior exact-item estimate if rebuilt. This is not proof that the current compiled ItemDB or actual tooltip includes both; no estimator, compiler, Lua, or synthetic-price runtime was run. A reviewed isolated test should exercise real `analyze()` with both records and assert duplicate suppression across exact-item/gear-group keys, preserving existing legitimate gear-family evidence.

Separate eligibility flags in the Nov 1 [WowDB source records](../../evidence/war-within/2026-11-01T1819-wowdb-disenchant-eligibility-conflicts.jsonl) already mark 237867 and 245737 **Cannot be disenchanted**, conflicting with the historical Looter material tables. Do not translate historical rates to current eligible Disenchant EV without itemLink/bonus and live-build reconciliation. Do not delete raw originals or invent zero-output disenchants.

## Disposition / handoff

- Close worker's *possible source duplicate* classification for 237867 and 245737 as **confirmed repeated published counts**; six other rows were already identified by worker as earlier repeats. Do not claim 8 new studies or any new casts.
- Route the gearGroup-versus-exact-ID cross-group collision for **scoped research-only estimator validation** (not the protected three-pass addon implementation). If a true regression is reproduced, submit a reviewed isolated fix with a deterministic two-row fixture; only PR Director may merge.
- Keep source study rank-2 hit data and exact item identity, preserve conflicting noDE context, leave observed stack units/other outcomes and actual Retail eligibility unknown.

**Validation executed:** exact old/new evidence rows fetched and compared field-by-field for IDs 237867 and 245737, source URL, reported operation denominator, material hit numerator and rank; estimator `study_identity`, `key_of`, `group_specificity` and `misplaced_copies` inspected statically. **Not executed:** estimator, offline valuation/tooltip renderer, native Lua, Github Actions trigger, real-character test. **New independent casts 0; new supported Retail gold decisions 0; new actual rendered tooltip fields 0.**
