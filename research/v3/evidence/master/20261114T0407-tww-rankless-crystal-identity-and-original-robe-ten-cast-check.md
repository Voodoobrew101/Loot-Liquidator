# Coordinator source and estimator identity audit — 2026-11-14T04:07:14.693Z

Scope: new 2026-11-14 worker reports only. This is a **research-only original-source and static-code check**, NOT a new experiment, compiled rebuild, addon fixture, market-price test or current Retail/client proof.

## T0048: two fresh same-name, three-row Refulgent Crystal input tables

Source comparison, directly checked against original indexed item pages:

| Gear item | Source-reported item disenchants | Three source-reported Refulgent Crystal row appearances | Sum | Material item/rank per row |
| --- | ---: | --- | ---: | --- |
| [212017 Lightless Scavenger's Bonegirdle](https://www.wowhead.com/item=212017/lightless-scavengers-bonegirdle) | 35 | 21, 12, 2 | 35 | **unknown**, **unknown**, **unknown** |
| [212043 Gatecrasher's Armguards](https://www.wowhead.com/ptr/item=212043/gatecrashers-armguards) | 27 | 17, 6, 4 | 27 | **unknown**, **unknown**, **unknown** |

The page figures agree with **six** rows in worker file [2026-11-14T0326-lightless-gatecrasher-eligibility.jsonl](../war-within/2026-11-14T0326-lightless-gatecrasher-eligibility.jsonl), representing **two** item-side cumulative source tables, **not six independent experiments**. The numerators sum to the item-page denominator in each table. That arithmetic does **not** establish mutually exclusive rank drops, zero-overlap, one unit per occurrence, a full 0–N cast ledger or separate original uploaders.

Three genuine Refulgent Crystal quality-item alternatives exist independently: [219952](https://www.wowhead.com/item=219952/refulgent-crystal) (quality 1), [219954](https://www.wowhead.com/item=219954/refulgent-crystal) (quality 2), and [219955](https://www.wowhead.com/item=219955/refulgent-crystal) (quality 3). The original gear-page **text extraction does not reveal which of its three rows links to which material ID**, so neither rank/order nor a weighted gold expected value may be assigned from page order. External descriptions of the individual quality-item IDs corroborate alternatives, not the three source-row joins.

**New exact import/estimator gate from static source inspection:** In [build_estimates.py](../../tools/build_estimates.py), `key_of` maps all rankless same-name rows for a fixed input to the same `family:Refulgent Crystal` output key; `analyze` keeps only the first occurrence of a given `study_identity` in each output group (`seen`, `duplicateRowInStudy`). Thus for these six *as currently represented*, two valid separate ranked outcomes for each gear item may be skipped as duplicate rows if admitted to the estimator. The retained first row alone may be offered as a non-rank-specific family chance. This is a static flow finding, **not** an executed compiled/tooltip or source-price assertion. Do not solve it by summing hits into an invented rank, treating source-row order as quality, or claiming the total equals a guaranteed material drop. Hold rank-specific gold valuation until source material hyperlinks/at-cast build/stack quantities/eligibility are resolved; retain all three original rows as labeled contextual evidence. This is an instance of existing S26, pinned here to new exact item IDs, not a newly established general policy.

## T0052: separate higher-fidelity historical numeric source

Independently checked original [Netherweave Robe 21854 commenter 128008](https://www.wowhead.com/tbc/item=21854/netherweave-robe), transcribed in [legacy 03:48 record 002](../legacy/2026-11-14T0348-sharp-cookie-netherweave-and-originals.jsonl): the person explicitly says **10 robes disenchanted**, **two 1-unit** and **three 2-unit** Greater Planar Essence 22446 outcomes. For **this material in this historical ten-operation cohort only**, the directly countable histogram is **{0:5, 1:2, 2:3}**, hits **5**, total units **8**, mean **8/10 = 0.8 units per operation**; other disenchant output materials are not disproven by the five essence-zero results. Comment date, enchanting skill, gear variant and actual Retail transfer are unknown. Keep TBC Classic as historical/reference, never assert that this cohort predicts current Retail yields, prices or eligibility.

Independently verified original [Khorium Plated Bludgeon 25122](https://www.wowhead.com/tbc/item=25122/khorium-plated-bludgeon) text gives a single **of the Monkey** disenchant into **three Arcane Dust 22445** (one positive outcome, no calibrated population rate). Original [The Sharp Cookie 30568](https://www.wowhead.com/tbc/item=30568/the-sharp-cookie) Thottbot-migrated comments support three individual three-cookie narratives, but anonymous commenters, patch and possible overlap are unresolved. The third outcome in the last narrative says only *usual essence*: its exact output ID/quantity must remain unknown, and it must not become a priced `family:Unspecified essence` output.

## Disposition and next action

- **Usable-but-not-imported:** historical 21854 source-scoped ten-cast numerator/denominator/quantity and 25122 single positive stack are retained by legacy worker. A controlled, Retail-applicable transfer has not been demonstrated.
- **Identity/units blocker:** 212017 / 212043 each has three **unmapped** material-rank alternatives and no output stack quantity; source-listed cumulative appearance counts are not per-rank gold EV.
- **Eligibility/context/price/display:** source game build, actual item bonus, enchanting profile, current eligibility, real AH prices and tooltip rendering remain unverified independently of rank identity. Historical source alone is not a current character decision.
- **Priority:** obtain original material row hyperlinks/export with 219952/219954/219955 mappings and a single at-cast bonus/build/profile plus stack ledger; preserve source distinctions. Keep current Midnight T0005/T0039/T0045 first for economic action coverage; do not duplicate workers' comments or re-scrape exhausted generic sources.

No new measured Retail casts, source-linked rank joins, synthetic-price valuation, addon execution, Lua suite, CI for this audit or live game checks were performed. No worker/queue/flags/rules/immutable snapshot/integration/main changes.
