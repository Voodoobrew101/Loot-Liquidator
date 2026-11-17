# Coordinator T0005/T0039 — already-preserved first-person R2 Diamond totals contradict a blanket “no rank-specific source” description

**Reviewed:** 2026-11-14 UTC. **Scope:** original-source and immutable-research-record reconciliation only. This is NOT a newly collected experiment, executed addon test or new current-character EV.

## What the July 3, 2026 original actually says

[Stormwarning, original Blizzard Forum report, 2026-07-03](https://us.forums.blizzard.com/en/wow/t/sunglass-vial-1-hour-material-test/2323248) explicitly reports:
- **67 gathered R2 (gold) Refulgent Copper Ore**, followed by **1 R2 (gold) Eversong Diamond** in its grouped prospect outputs.
- **66 gathered R2 (gold) Brilliant Silver Ore**, followed by **1 R2 (gold) Eversong Diamond** in that ore's grouped outputs.
- The author used **one miner and two Jewelcrafters**. Original does not assign either ore's processing to a particular Jewelcrafter or give each character's skill, detailed specialization/unlock, itemLink, input actually consumed, Resourcefulness refund, completed prospect cast counts, zero events or per-output occurrence histogram.
- [The author's 2026-07-14 follow-up in that same original thread](https://us.forums.blizzard.com/en/wow/t/sunglass-vial-1-hour-material-test/2323248/11) explicitly says character specifications were omitted, although appropriately specialized with racial skill help. **Do not infer a numeric skill threshold or unlock proof**.

## Existing source record, no duplicate cohort

The **already-preserved** worker file [2026-10-31T1911-stormwarning-r2-prospecting.jsonl](../midnight/2026-10-31T1911-stormwarning-r2-prospecting.jsonl) has original worker entries:
- `midnight-20261031-191103`: Copper `237361`, `inputRank=2`, Diamond `outputItemID=242712`, `outputRank=2`, `totalQuantity=1`, `casts=null`.
- `midnight-20261031-191108`: Silver `237365`, `inputRank=2`, Diamond `outputItemID=242712`, `outputRank=2`, `totalQuantity=1`, `casts=null`.

Both entries correctly retain **source-stated R2 totals, not observed cast probabilities**, and are one combined July 2026 author's report, **not two new independent cohorts**. The exact `242712` **item ID is inferred** from external [GoldCap R2 commodity identity](https://goldcap.gg/retail/us/items/242712), NOT present as an original output itemLink. There is still no live-game output itemLink or 242608-vs-242712 rank-specific full yield distribution.

## Corrected field-level disposition

The 2026-11-14 06:11Z Midnight worker checkpoint and earlier coordinator 07:05Z audit used the broad formulation “no original rank-linked prospect source.” **That formulation is too broad**: this pre-existing *first-person rank-two result* is already saved. Narrow the outstanding gap to **no verified result itemLink, complete cast denominator, per-character context and rank-specific P(hit)/0..N outcomes**. This July 3 post-hotfix anecdote provides limited R2 observational evidence against the two guides' quality-less description; it does **not** by itself prove both diamond ranks coexist in the same patch, the 242712 item-ID mapping, or any current-patch rate. Cross-source inconsistency remains open.

Import implications: **do not** duplicate these two evidence rows, synthesize casts by dividing 67/66 gathered ore by 5, mistake quantities for hits, pool two Jewelcrafters, or assign 242712 chance/expected quantity. Retain family unknown-rank evidence and separate rank-specific price eligibility. If a future consumer treats these rows as exact-ID pricing evidence, require original itemLink validation or transparent catalog-inferred rank labeling and synthetic divergent-quality price tests in the protected implementation owner's workflow. No worker queues, addon code, integration snapshot, research originals or main branch modified.

## Verification performed and limitations

Read the full original forum post and July 14 follow-up, exact two records in the immutable worker JSONL and prior coordinator 2026-11-09 crystalline-glass source audit; compared 2026-11-14 worker/coordinator quality-gap wording. **Actual verified progress:** correction to research gap classification and source lineage; **new original casts/cohorts = 0; new current Retail expected quantities or prices = 0; actual compiled/tooltip engine executions = 0; live-client verification = 0.** Next priority stays obtaining a post-hotfix event-linked itemLink with character and per-cast metadata for T0005/T0039/T0045.
