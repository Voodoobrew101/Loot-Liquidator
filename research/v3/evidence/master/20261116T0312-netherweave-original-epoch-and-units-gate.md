# Research Manager — Netherweave original-source epoch and units gate
**Checked at:** 2026-11-16T03:12Z
**Role:** coordinator; research-only evidence / no addon integration
**Worker evidence verified:** [Legacy 02:46Z original-source rows](../../evidence/legacy/2026-11-16T0246-netherweave-de-feliron-originals.jsonl)
**Research source head before this audit:** `60ca1caf76c3bf990d0d4c1e2c3236f7dbbc0af6`

## Original-source reconciliation

I compared the 11 newly recorded output rows (five studyKeys: four Netherweave disenchant cohorts, one Fel Iron prospect cohort) against the original Wowhead/archived comments and the worker report. Historical comments remain historical even though they appear on a modern Retail/PTR item page. Original pages:

- [Netherweave Pants item 21852 — original comments by 70404, tarsakh / 124141, darkmagi91](https://www.wowhead.com/ptr/item=21852/netherweave-pants)
- [Alternate accessible preserved original comment text](https://www.wowhead.com/it/item=21852/pantaloni-di-telafatua)
- [Fel Iron original Thottbot comment mirrored under Adamantite Powder](https://www.wowhead.com/wotlk/item=24243/adamantite-powder)

| Original cohort, distinct process group | Source operations | Confirmed output total units | Original event/hit quantity | What remains unknown |
| --- | ---: | --- | --- | --- |
| 70404, Netherweave Pants 21852 | 30 disenchants | 22446 Greater Planar Essence: 14; 22445 Arcane Dust: 71 | Per-material hit counts, zero buckets and stack sizes absent | Date/patch/ilvl/skill, current Retail eligibility |
| tarsakh (worker's 124141), Pants 21852 | 34 disenchants | 22446 Greater Planar Essence: 1; dust amount **not stated** | 1 positive Greater Planar Essence outcome; remaining 33 disenchants described as dust outcomes | Dust unit total, zero/stack histogram, historical patch/skill |
| darkmagi91, Bracers 21849 | 100 disenchants | 22445 Arcane Dust: 165; **22447 Lesser** Planar Essence: 158 | Per-material hit counts absent | Date/patch/ilvl/skill, current Retail eligibility |
| darkmagi91, Pants 21852 | 100 disenchants | 22445 Arcane Dust: 190; **22447 Lesser** Planar Essence: 45 | Per-material hit counts absent | Date/patch/ilvl/skill, current Retail eligibility |
| Archived Thottbot, Fel Iron Ore 23424 | Five unspecified-size *stacks*, not casts | Star of Elune 23438: 2; Dawnstone 23440: 2; Nightseye 23441: 1 | Cast denominator, hits/zeros, common-gem outputs absent | Stack size, refunds, era and skill |

The four Netherweave source operations sum to **264 completed disenchants**, NOT 264 per-output events and NOT a current-Retail study. The 100 Bracers and 100 Pants are separate batches by the *same* author; do not interpret these as independent player samples. The 30- and 34-Pants batches are from other authors and may be historically or mechanically incompatible.

### Exact source-supported arithmetic

- Pants dust quantity mean: 71/30 = **2.366667 per completed operation** in the 30-cast source vs. 190/100 = **1.900000** in darkmagi91's 100-cast source, a **19.72% difference** in the arithmetic means. It is **not** proof of an official rate nerf or of present-Retail values.
- 30-Pants Greater Planar Essence observed units: 14/30 = **0.466667 per operation**; 100-Pants later commenter reports **Lesser** Planar Essence 45/100 = **0.450000 per operation**. The almost similar scalar means are **different item IDs**, not interchangeable material values. Do not pool or remap their outputs.
- 100-Bracers dust 165/100 = **1.65** units per operation; Lesser Planar Essence 158/100 = **1.58** units per operation. Both are *quantity* means, not occurrence probabilities.
- In the 34-Pants comment, 33 described dust-positive operations cannot become `totalQuantity=33`: the number of Arcane Dust units remains **unknown**. Nor may the separate 100-Pants quantity mean be transferred into its historical cohort.
- Fel Iron's five stacks give a sourced **five rare-gem units**, but with **unknown casts**; “five stacks” is not 5 casts or 5 × a presumed stack size.

The source commenters explicitly discuss an apparent disenchanting-rate change but do **not** supply a verifiable game build, collection date, current item bonus or profession condition. An anecdotal relative chronology is not a validated patch boundary. The modern display of item ID 21852 as item-level 14 likewise does not prove the historical disenchanting input item-level or version.

## Checks and research-to-addon decision

**93/93 guarded JavaScript source-row/schema/unit/context assertions passed** on the latest worker JSONL, against exact original-comment numeric tuples, original item IDs, expected cohort structure and explicit nulls; no failed assertion. I also opened source page text to independently check comments; this is NOT an automated original HTML parse or game replay. The 11 source rows and 264 operations are the worker's, **not** additional independent observations authored by the coordinator.

Preserve every original separately and distinguish source era, input identity, output family/quality, per-cast units, per-cast hit counts and unknown fields. Allow existing historical evidence as properly labelled reference/provisional input where compatible with applicable Retail processing context under owner policy; do not force a pooled unconditional modern mean without source/patch/eligibility reconciliation. Exact gold/tooltip effect is unknown; no source prices, synthetic price run, Python estimator, Lua addon tests or live WoW QA were run for this audit.

**Highest-priority evidence gap:** independently establish which exact Retail item and build supports historical-era 21849/21852 disenchant results, or locate a new post-era **zero-inclusive itemLink/bonus/skill-tagged, 0/1/2+ stack ledger**. For Fel Iron, recover actual per-cast input and output ledger; do not ask workers to duplicate the five-stack quote. Keep owner's three-pass implementation untouched.
