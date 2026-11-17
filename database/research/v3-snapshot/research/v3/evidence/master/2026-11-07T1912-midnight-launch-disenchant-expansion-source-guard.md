# Research-only original-source guard: launch-era Midnight item disenchanting into older-expansion materials

**Checked UTC:** 2026-11-07T19:11:55.440Z  
**Original dated report:** [March 18, 2026 r/wow firsthand item screenshot and discussion](https://www.reddit.com/r/wow/comments/1rx9nvh/disenchanting_midnight_wand_receiving_war_within/)  
**Related owner queue:** T0026 (Midnight disenchant item/rarity mapping), T0049 (specific Midnight eligibility); this is an **identity/context candidate**, not a verified numbered output cohort.

## What the original source actually reports

The screenshot post is titled **"Disenchanting midnight wand, receiving war within mats"** and identifies the wand as a Midnight item. A commenter reports a **blue gear item obtained while leveling in Midnight** disenchanting into a **The War Within shard**. Another commenter says it happened with the **"time blossoming rootwarden wand"**; a separate commenter says an item-level-240 world-quest epic yielded an older-expansion material. Several others report Classic-era materials from unspecified greens. These are separate author anecdotes and must **not** be counted as verified completed-cast cohorts, numeric sample sizes, or evidence of a current-patch percentage.

**Identity pending:** a potentially related public catalog item is `259349` (Blossoming Rootwarden's Focus), but the original comment does not provide an inspectable itemLink/bonus ID. Therefore **do not assign 259349 to the screenshot or attach any output material ID to it**. The source text does not establish exact enchanting output item ID, quality/rank, output units, consumed itemLink, bonus ID, player skill/specialization, precise build/patch, or whether the original launch behavior still occurs in November 2026.

## Engineering/economic consequence

A Midnight-origin item's expansion is not sufficient proof that it disenchanting into Midnight dust/shard/crystal material family in all patches/variants. This historical inconsistency is an eligibility/source-context watchpoint, **not** a hardcoded current Retail exclusion or evidence that every such wand always yields older materials. Do **not** publish an older-expansion material model, current gold estimate, probability or yield solely from these anecdotes. Preserve existing usable values under source precedence and flag a scoped source-context discrepancy when inspecting exact item variants in offline evaluation.

To close: secure an exact original itemLink and output itemLink with quantities, date/build, gear quality/ilvl, enchanting skill/specialization and completed operation; independently verify whether the same variant behaves this way on a later Retail build. Until then the input/output IDs and current-applicability remain unknown. The owner three-pass integration branch remains untouched.

## New worker readbacks at this checkpoint (not coordinator measurements)

- [War Within worker status](../../coordination/quiet-status/war-within.json), reported 2026-11-07T18:33:38.129Z: parsed all 8 new [green disenchant rank-share evidence lines](../war-within/2026-11-07T1833-green-disenchant-source-rank-shares.jsonl) (SHA 320b53dc2123883be260160836197843fe7155ac). Original 100+24 skill/60 KP source reports **35.42/44.28/20.30 percent share** for three Storm Dust quality ranks; same original is retold elsewhere with 2.85 pooled dust/DE. **Not P(hit), not independently logged cast denominators**. Forum three-green batch gives material quantities but no per-material hit counts. Preserve rank/item alternatives and deduplicate the retelling.
- [Dragonflight worker status](../../coordination/quiet-status/dragonflight.json), reported 2026-11-07T19:06:38.960Z: parsed 1 new [searched/corroboration record](../dragonflight/2026-11-07T1908-independent-draconium-rank-crosscheck-and-numeric-search.jsonl) (SHA 19f6e23fe96fe82bfd16b0fd6ad4de80fb88a50f). GoldCap and WoW Price Hub independently label Draconium Ore **189143=R1, 188658=R2, 190311=R3**; source is third-party **rank identity**, not original Blizzard/client confirmation or new processing quantities.

Other statuses read: [Legacy](../../coordination/quiet-status/legacy.json) 2026-11-07T18:18:59.929Z; [Midnight](../../coordination/quiet-status/midnight.json) 2026-11-07T18:23:15.160Z. No worker acknowledgment fabricated. No new numerical operation, price/valuation decision, estimator build, offline engine tooltip execution or real-client QA was performed by this coordinator checkpoint.
