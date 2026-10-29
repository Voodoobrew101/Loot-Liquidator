# Legacy q30 Batch028 — assigned Midnight Flawless Crushing leads: source-only provenance and eligibility
**Date:** 2026-10-29 PDT · **Queue:** 30 · **Worker:** loot-liquidator-legacy · **Assignment:** 2026-10-29-batch028-legacy · **Branch:** research/processing-confidence.

This is a SOURCE-ONLY review, **not** an observed cast study, schema-valid measured observation, accepted mapping, or numeric fallback.

## Four exact master-assigned gem identities (direct Retail item pages)

| Candidate input ID | Name | Master candidate quality rank | Direct item page |
| --- | --- | --- | --- |
| 242610 | Flawless Harandar Peridot | 1 | https://www.wowhead.com/item=242610 |
| 242726 | Flawless Harandar Peridot | 2 | https://www.wowhead.com/item=242726 |
| 242611 | Flawless Tenebrous Amethyst | 1 | https://www.wowhead.com/item=242611 |
| 242725 | Flawless Tenebrous Amethyst | 2 | https://www.wowhead.com/item=242725 |

All four pages identify Midnight uncut Flawless gems. Their normal **Reagent for** lists do not expose a salvage-input whitelist. This absence is **not** evidence that a gem cannot be crushed. Flawless is the gem-family rarity, while R1/R2 are separate quality ranks; do not conflate these.

The exact eight unadmitted candidate tuples are each of those four input IDs to **242620 (Glimmering Gemdust R1)** and **242621 (Glimmering Gemdust R2)**. No item page establishes the accepted input selector for spell 1231132, the output dust rank, or a positive-outcome cast range for an exact pair.

## Primary game-record recipe vector and unresolved rank gate

Retail https://www.wowhead.com/spell=1231132/midnight-crushing states **three Midnight gems**, salvage crafting data **value 3**, and explicitly **Dusk-Shrouded Stone 242788 ×1** as a reagent. The same-gem requirement is supported at family level by already indexed April 2026 first-person comments and the October 16 2026 Czech secondary guide, but exact four input IDs are not demonstrated by an in-client selector capture. **242789** as an alternative stone rank is unverified. Treat the cost as three identical selected gems **plus one stone** only if an exact input is later proven accepted; Resourcefulness refunds reduce input costs, not output Gemdust.

## Source-lineage finding: repeated ~0.67 per crush is not independent replication

- Existing https://www.wow-professions.com/midnight/jewelcrafting-guide says uncommon and rare gems yield the same, about **0.67 Gemdust per crush** with talents, and recommends cheaper uncommon gems. No original cast denominator, sample log, output-rank histogram or exact input item IDs are given.
- Newly checked https://boostmatch.gg/blog/wow/articles/wow-midnight-jewelcrafting-guide repeats the same unusual **0.67 per crush** claim, equal uncommon/rare output and cheaper uncommon preference. It offers no original dataset. It is **new secondary source discovery**, not a new independent numerical study.
- The September 28 2026 Turkish https://wowforevertr.com/haber/254-midnight-jewelcrafting-tarifler-ve-knowledge-point-rehberi reproduces the same three claims in closely matching sequence and translated phrasing. This source was already surfaced by Dragonflight q30. **Likely common ancestry; copying direction cannot be proved.** Count the three sites as **one unresolved source family**, not three confirmations of 0.67.

Method https://www.method.gg/guides/midnight-jewelcrafting-profession-guide claims **1–3 Gemdust per three-gem crush** independent of gem variety/quality. A literal 0.67 **per completed crush** conflicts with a guaranteed positive minimum of 1. Hypotheses such as 0.67 per gem, zero-result casts, changed patch mechanics, or incorrect guide wording cannot be selected without original units and matched casts. **Do not normalize by ×3 or infer E=2.01.** Neither rate is eligible for current-Retail economic E or exact-pair tooltip P/min/max.

Previously indexed July 2026 https://www.reddit.com/r/woweconomy/comments/1v5esk0/midnight_jc/ reports 0.83925 dust **per gem** at max specialization and Resourcefulness; this is a different self-reported unit and lacks an actual completed-cast denominator, item/rank breakdown and refunds. Do not treat as independent exact-pair verification or as an E. Previously indexed March 2026 https://www.reddit.com/r/woweconomy/comments/1s1dtuh/jc_prospecting_is_atrocious/ mentions selling Flawless Peridot/Amethyst while crushing lower-rarity gems; this is a liquidation preference, **not** proof that Flawless inputs are ineligible.

## Field and decision QA

**Four stable keys / eight unadmitted tuples / 32 four-field slots unknown.** For each exact tuple: P(>=1), positive yieldMin, positive yieldMax, and zero-inclusive unconditional expectedQuantity = **null (unknown)**. Tooltip-only P/min/max = **null**, because family-level bounds are not pair-specific evidence. Do not interpret unknown as zero, use min/max midpoints, multiply unconditional E by P, or sum R1 and R2 as guaranteed simultaneous outcomes. No gold-price scenario or actual liquidation flip was tested.

**Next evidence:** exact in-client selector accepts/rejects 242610, 242726, 242611, 242725 with three identical units; 242788 vs 242789 stone acceptance; actual completed spell 1231132 casts including zero outcomes; output 242620/242621 item ID, rank and per-cast count; patch/build, skill/spec, gear, concentration, gem/stone Resourcefulness refunds. Without an original trigger, request master source-triggered pause/reassignment rather than hourly re-fetches. No shared/production files changed.
