# Gold Forever Retail disenchant recording — original-source instrumentation lead (2026-11-23)

Status: **source-context lead only; no measured Retail study, new yield, admission or confidence.** Manager-discovered after the 2026-11-20 catalogue cutoff. Do not convert Forever/Classic tables into Retail observations.

## Original source and pinned revision

- Gold Forever 0.24.2, published 2026-11-20, lists WoW Retail 12.1.5 and Forever flavours: https://www.curseforge.com/wow/addons/gold-forever/files/9719862
- Upstream source repository (source-available, all rights reserved, **do not copy code**): https://github.com/gold-forever/addon
- Pinned source head reviewed: `f9ef5c118f39192a8e2faf7bf25c2668067ef604` (read on 2026-11-23 UTC).
- Source event correlation: https://github.com/gold-forever/addon/blob/f9ef5c118f39192a8e2faf7bf25c2668067ef604/GoldForever/Recording/Loot.lua#L14-L27 and #L443-L483
- Saved row schema: https://github.com/gold-forever/addon/blob/f9ef5c118f39192a8e2faf7bf25c2668067ef604/GoldForever/Store/Schema.lua#L12-L23
- Retail pricing limitation: https://github.com/gold-forever/addon/blob/f9ef5c118f39192a8e2faf7bf25c2668067ef604/GoldForever/API.lua#L1-L17 and https://github.com/gold-forever/addon/blob/f9ef5c118f39192a8e2faf7bf25c2668067ef604/GoldForever/ReadModels/Pricing.lua#L335-L347

## Source-verified fields (implementation, not player observations)

The addon has a live Retail TOC, a loot record with a source and item quantities, and a disenchant source marker `d<itemId>`. The marker is based on a recently clicked bag item (within 2 seconds of spellcast start) and the succeeding Disenchant spell ID 13262, matched to a loot window for up to 5 seconds. Thus **a recorded positive loot row can potentially associate an input base item ID and output item keys/quantities**. The current marker does not encode input item bonus/ilvl/link, profession skill/spec, or explicit completed-operation counters; source-to-loot correlation and instant/auto-loot capture need validation. Absence of a saved loot row is **not** an observed zero-cast or zero-output event. Captured loot rows are not automatically equivalent to independent casts. No original Retail SavedVariables containing any player's actual processing events were obtained or inspected.

The public `GoldForeverAPI.GetPrice` and `GetVendorPrice` expose copper-denominated prices, potentially useful for independently labeled price-source compatibility. The source explicitly states `GetDisenchantValue` is **nil on Retail** because the packaged disenchant valuation is Classic/Forever-only. Neither that table nor Classic drop rates can be imported as Retail numerical evidence. The release notes say Retail inventory catalogue entries now record expansion, but this is not the same as recording the target item's exact bonus/ilvl/skill at disenchant.

## Admission, dedupe and next verification

The 731-source owner catalogue on `implementation/five-agent-completion` was searched for `gold-forever` and `GoldForever` and showed no matching source record on 2026-11-23. This is a newly identified original instrumentation source, **not** a 732nd admitted numerical study; preserve the 731-source catalogue and Codex ownership.

Only consider numeric research if a legally/shareably accessible first-person **Retail** saved file/export supplies dated, same-patch input/output join, actual completed operations and material units; separately document missing bonus/ilvl, skill/spec, refunds, possible missing instant casts and zero events. A source reporting an unconditional per-operation mean may still be usable with unknown N when its units and context are explicit, but this recorder alone does not establish such a mean. Do not create synthetic casts, infer probabilities from positives or use personal/private exports without permission. No in-game experiments, addon runtime tests or purchases performed.
