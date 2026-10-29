# Dragonflight worker q30 Batch028 — assigned Midnight Flawless Crushing leads (SOURCE ONLY)
**Research date:** 2026-10-29 (PDT) · **queue revision:** 30 · **assignment:** 2026-10-29-batch028-dragonflight · **branch:** research/processing-confidence.

## Assigned, not self-claimed
Four master-assigned Midnight Crushing gem inputs, each with two candidate Gemdust output ranks: 242613/242724 (Flawless Sanguine Garnet R1/R2), 242612/242727 (Flawless Amani Lapis R1/R2), outputs 242620 (Glimmering Gemdust R1) and 242621 (R2). These are **8 unadmitted exact tuples**, not 8 established recipes. Direct Retail item pages were read for all four item identities on 2026-10-29:
- https://www.wowhead.com/item=242613
- https://www.wowhead.com/item=242724
- https://www.wowhead.com/item=242612
- https://www.wowhead.com/item=242727

Each page identifies a prospectable Midnight uncut Flawless gem, but the displayed 'Reagent for' recipes are ordinary crafting recipes, **not a complete salvage whitelist**. Absence of Crushing in those lists is **not proof of ineligibility**. The exact item quality ranks come from the master-assigned candidate records; the public page's rendered text alone does not prove selector acceptance or output rank.

## New secondary source: incompatible or ambiguous numerical units
Newly located Turkish retail guide, **published 2026-09-28** (HTML `<time datetime="2026-09-28T08:46:44.049Z">`), says both uncommon and rare gems have the same Gemdust yield and reports **approximately 0.67 per crush with talents**, but supplies **no original sample, actual cast denominator, gem IDs, output rank, patch-specific cast log, or normalization**:
https://wowforevertr.com/haber/254-midnight-jewelcrafting-tarifler-ve-knowledge-point-rehberi

Existing Method guide by Roguery, **2026-03-05**, says three gems produce **1–3 dust**, quality and variety do not affect the yield, and describes that result as always 1–3:
https://www.method.gg/guides/midnight-jewelcrafting-profession-guide

The numerical statements **cannot be combined as if they used identical denominators**. Literal 0.67 unconditional dust per completed crush conflicts with Method's claim of always >=1 per completed crush. An alternative 0.67 *per gem* would imply about 2.01 dust per 3-gem nominal operation, but **the Turkish source explicitly says per crush**; do not silently relabel its units or promote 2.01. A third explanation is zero-hit casts or differing patch/profession setups. These are hypotheses, not measured conclusions. The Turkish guide's 2026-09-28 publication date does not establish when any underlying tests were performed.

## Direct recipe-vector evidence
Live Retail Wowhead spell https://www.wowhead.com/spell=1231132/midnight-crushing shows **Salvage Item Crafting Data value 3**, the description 'Crush 3 Midnight gems into dust', and **Dusk-Shrouded Stone item 242788 ×1** as an explicit reagent. Conservative conditional vector for a verified accepted input is 3 selected gems + 1 stone. Whether item 242789 can substitute for 242788 is unknown. Neither the spell page nor four gem item pages expose an exact accepted-item whitelist, an R1/R2 dust selector or a completed-cast histogram.

## Provenance and outcome
The Turkish page is **NEW SECONDARY**; Method, Wowhead spell and four item pages are **REUSED / previously indexed**. None supplies a new independent measured cast cohort. Previously reviewed Cardinalai 480 gems / 160 stones / 330 dust is gross-input evidence only and was **not re-fetched or counted as a second study**. Source-memory is master-owned and was read but not changed. The 8 exact tuples retain null P(hit), positive min, positive max, and unconditional E, **32/32 null**. Tooltip-only P/min/max also remain null. No numeric source supports gold EV or a pair-specific tooltip fallback. No new admitted mapping or current Retail economic field.

## Decision risk and next exact targets
An unsupported 0.67 per-cast E or a cost model omitting the stone could reverse gold-optimal Crushing versus auctioning expensive Flawless gems. **No actual gold-price comparison or reversal was tested**. Next original evidence: in-client salvage selector screenshot or structured client log for 242613, 242724, 242612, 242727; 3-of-a-kind acceptance; stone 242788 vs 242789; output 242620 vs 242621; actual completed operations including zero-hit casts, gem/stone Resourcefulness refunds, skill, specialization, gear, date and patch. If no such evidence becomes available, request source-triggered pause/reassignment from Master instead of another repeated source-line audit.

**No production or canonical file modified.** This is a source-only research note, not a canonical observation.schema.json record or measured experiment.
