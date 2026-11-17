# Cardinalai Umbral Tin Ore: original 4,000-ore denominator gate and seven exact output links

**Research-only primary-source/selected-tooltip audit — 2026-11-17T17:05:11.186Z.** This does not add a new experimental cohort or change the game's processing model. Original worker evidence and immutable `4df9ae8` snapshot remain intact.

## Firsthand source versus manager queue

[Cardinalai's live Wowhead comment for Umbral Tin Ore 237362](https://www.wowhead.com/item=237362/umbral-tin-ore#comments) says **“Prospecting 4000 Umbral Tin Ore”** with **39.6% Resourcefulness** and **maxed knowledge stats**, then gives seven material **output totals**. Unlike the author's *different* [Brilliant Silver source](https://www.wowhead.com/item=237364/brilliant-silver-ore#comments), this Tin comment **does not state 800 completed prospects, net ore consumed, exact number of resourcefulness refunds, per-cast logs or a 0-N histogram**. Five ore/operation is the documented base recipe, but dividing the source's 4,000 ore by five is at most a nominal 800-equivalent under an unverified input-consumption interpretation, **not 800 observed completed operations**. Do not invent an empirical per-cast denominator, new cast cohort, chances or calibrated confidence from this sentence.

This difference has a consequential **stale queue-description error**: as read at this checkpoint, open tasks `T0005` and `T0039` describe the same source as **800 completed** Cardinalai prospects. The original seven [research rows](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/five-agent-completion/research/v3/evidence/midnight/2026-10-30T1824-midnight-prospecting-studies.jsonl) correctly leave `casts=null` and explicitly state operation count unknown. Preserve those nulls; the worker-owned queue/task descriptions should be reconciled at an authorized normal review, not silently reinterpreted by a new measured baseline.

## Existing seven rows and the source's *exact linked* output IDs

The seven hyperlinks in the **original same comment** resolve directly to the following Retail item pages; all seven pre-existing evidence rows retain `outputItemID=null`:

| Existing original row | Source-linked output | Source-reported total units (same source) | Actual source hyperlink ID |
|---|---|---:|---|
| midnight-20261030-003 | Eversong Diamond | 30 | [242608](https://www.wowhead.com/item=242608) |
| midnight-20261030-004 | Flawless Harandar Peridot | 124 | [242610](https://www.wowhead.com/item=242610) |
| midnight-20261030-005 | Flawless Tenebrous Amethyst | 104 | [242611](https://www.wowhead.com/item=242611) |
| midnight-20261030-006 | Tenebrous Amethyst | 144 | [242606](https://www.wowhead.com/item=242606) |
| midnight-20261030-007 | Harandar Peridot | 147 | [242607](https://www.wowhead.com/item=242607) |
| midnight-20261030-008 | Crystalline Glass | 597 | [242787](https://www.wowhead.com/item=242787) |
| midnight-20261030-009 | Dusk-Shrouded Stone | 911 | [242788](https://www.wowhead.com/item=242788) |

The Glass link is **242787**, not the default lower/family identifier **242786**. Source-linked material identities are evidence of the author's selected hyperlinks, **not a measured quality distribution or proof of which exact item quality dropped in every event**. The Diamond is an observed source total but remains **character unlock-conditional**; maxed-knowledge prose does not supply an externally verified current patch, spell/ore-unlock assignment, or event receipt. Neither total quantity nor a 39.6% Resourcefulness *stat* provides material occurrence probability or per-operation yield. Input 237362 and the seven output identities are directly grounded; no output-rank probabilities, `castsWithDrop`, zeros or rank-based scaling are supported.

## Existing owner saved actual-engine fixture: separate source-to-selection issue

The owner's pre-existing [367-profile, synthetic-price runtime fixture](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/usable-data-tooltips/docs/usable-data-audit/runtime-probes.jsonl), blob `534b970d475d75e54b1d5bc4777e807384814372`, includes `Prospect:237362:x5` with `state=partial_value` and `eligibility="Not tested; source audit only"`. Its Glass material is keyed to **242786** with `rankIDs=[242786,242787]` and displays **“Material 242786 (rank unknown)”**; the exact original 597-unit **242787** link is not explicitly shown. The selected model includes a provisional **0.7462 chance** and **0.745514999 expected units** for the Glass family; those are **not newly verified per-cast Cardinalai measurements**. Its Diamond **242608** is shown separately as **0.045 conditional** and excluded from the current synthetic value pending unlock.

This identifies **usable linked-source output identity not placed in the research rows / not displayed exactly in the frozen selected family**, plus an **invalid operation denominator asserted in the manager queue**. It is *not* proof that the current addon calculates the wrong live gold action, that all 597 Glass units were necessarily rank-exclusive, that the 4,000 number means net inputs, or that the selected model was solely generated from these seven rows. Existing other source candidates must remain independently protected.

## Reviewed next actions and checks

1. Have the authorized Midnight source/identity worker or scoped research review place the seven **original hyperlink IDs** in a correction/normalization layer, preserving one original study key and never editing worker originals; keep output-rank/skill caveats.
2. Correct `T0005/T0039` **800-completed-prospects** wording during worker/queue owner's reviewed task update. Seek actual completed-op logs, net/reprocessed inputs, event-level refunds, per-output 0/1/2/... hits/zeros and exact itemLink/rank context, instead of requesting another transcription of Cardinalai.
3. Owner-controlled integration review: two different synthetic Glass-rank prices on exact output **242787** versus family **242786**, conditional Diamond unlock on/off, and actual resolver+formatter checks. Respect existing 4df9ae8 snapshot and source precedence; no direct addon integration by manager.

**Actual bounded validation:** **66/66 JavaScript assertions** against unchanged existing v3 original rows (blob `59833c90d040ce272aba0cffe132b551e4cb288e`), queue (blob `00acb644890dd37c88a53a59144ead47018e53fd`) and the owner's **previously executed** saved runtime fixture (blob `534b970d475d75e54b1d5bc4777e807384814372`). Source hyperlinks were separately opened and their item IDs checked on the public original Wowhead comment. This run did **not** execute the compiler, Lua addon tests, a new resolver/tooltip render, market-price checks or live WoW client. **Zero new independent casts, zero new measured probabilities, zero validated live gold decisions.**
