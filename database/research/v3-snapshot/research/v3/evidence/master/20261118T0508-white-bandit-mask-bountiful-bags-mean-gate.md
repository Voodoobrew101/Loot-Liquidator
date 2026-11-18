# Original-source audit: White Bandit Mask, Bountiful Bags, and historical means — 2026-11-18 05:08 UTC

**Scope:** research-only source/field audit. No Retail client, importer, Lua, current valuation engine or tooltip run. No owner integration, worker original, immutable snapshot or main changes.

## Original-source verification

1. **Newly surfaced VBishop source not in latest ten-row Legacy worker file:** The original Vision Dust Wowhead comment reports **100 completed White Bandit Mask (10008) disenchants** and **295 Vision Dust (11137), 29 Lesser Nether Essence (11174), 5 Small Radiant Shard (11177)**. Its crucial qualification is that **Bountiful Bags bonus materials were NOT separated from the totals**. The words Bountiful Bags are visible on Cataclysm/MoP Classic source renderings, but silently omitted in a Retail-page text extraction. Naive 295/100=2.95, 29/100=0.29 and 5/100=0.05 are **bonus-inclusive source quotients, NOT perk-neutral Retail disenchant E**. Preserve the original counts, source author and context; never invent independent per-material hits or subtract a conjectured flat percentage. Original: https://www.wowhead.com/cata/item=11137/vision-dust ; corroborating cross-render: https://www.wowhead.com/mop-classic/it/item=11137/vision-dust . Do not infer an independent Alayea cohort merely from a reference in this comment.
2. **Specific metadata omission in fresh Legacy source:** The original comment by **1129489** explicitly reports that the guild had **Bountiful Bags** during a **120 White Bandit Mask craft** that yielded **17 stacks of Vision Dust** (other output units approximate). Worker record legacy-20261118-00007 does not state this perk context. The 120 are crafted items, not confirmed 120 DE casts, and 17 stacks is not an exact output unit count. A worker-owned append-only correction can add the documented historical perk without changing this original. Same source: https://www.wowhead.com/mop-classic/it/item=11137/vision-dust .
3. **Mechanic provenance:** Bountiful Bags provided a chance for **extra material stacks when disenchanting** and was **removed in Retail patch 6.0.2 on 2014-10-14**. It is not a supported present-Retail Resourcefulness rule or a universal deterministic bonus. Source: https://warcraft.wiki.gg/wiki/Bountiful_Bags .
4. **One defensible historical unconditional E:** Pegleg's 16 completed **Black Mageweave Gloves (10003)** DEs yielded exactly **2 Lesser Nether Essence (11174)**, so aggregate **E=2/16=0.125 essence units per reported historical DE**. Chance, per-hit stack quantity, skill, patch, perk status, and current-Retail eligibility are unknown. Other dust is about three stacks and has no exact total. Preserve that distinct source value with a historical/unknown-condition label; do not claim a Retail actionable gold decision. Original: https://www.wowhead.com/tbc/item=11137/vision-dust .
5. **Craft-versus-operation control:** Commenter 1001850 reports crafting 20 White Bandit Masks and obtaining **16 Essence, 33 Dust, 1 Shard**, but does not independently log 20 completed DE casts. The worker's three rows correctly retain casts, castsWithDrop and histograms as null; do not derive E using 20 crafts. Source: https://www.wowhead.com/item=11174/lesser-nether-essence .

## Exact supported-field disposition

| Source | Input/output | Denominator | Quantity | Hit P | Current Retail valuation |
| --- | --- | --- | --- | --- | --- |
| VBishop | 10008 -> 11137/11174/11177 | 100 completed DEs | 295/29/5 **bonus-inclusive**; base E unknown | Unknown | Hold context |
| 1129489 | 10008 -> 11137 | 120 crafts only | 17 stacks, exact units unknown; perk active | Unknown | Hold units/context |
| Pegleg | 10003 -> 11174 | 16 DEs | 2 total -> historical E=0.125 | Unknown | Historical only |
| 1001850 | 10008 -> 11137/11174/11177 | 20 crafts, DE casts unknown | 33/16/1 totals | Unknown | No priceable E |

The research v3 frozen output/estimates.json (1,180 entries) lacks input 10003 and 10008; owner frozen database/research-v3-baselines.lua lacks these exact input IDs and material 11174. This is **not** a claim that all personal, historical, TSM or user sources lack them. Pinned owner snapshot 4df9ae8 remains unmodified.

## Validation and ownership

**30/30 in-process JavaScript assertions passed** against newly published ten-row Legacy worker evidence blob 4a6fb2a, frozen research estimates blob 15ae8c5 and owner frozen Lua blob ae953ff. Assertions inspected source record IDs, material totals, nil hit fields, cohort dedup, 16-cast arithmetic, the missing 1129489 perk annotation, and exact frozen-source omission. Original Wowhead pages and historical perk wiki independently inspected, not included in that executable assertion count. **No Python compiler, Lua, importer, current valuation/tooltip fixture, price source, new CI run or live WoW test.**

No new measured current-Retail yields or supported gold decisions. The owner integration branch, main, source originals and worker schedules remain untouched. Next: source-qualified worker-owned append-only correction of historical Bountiful context if not already in full worker corpus; primary current-Retail focus stays **T0005/T0039 Umbral Tin** and **T0045 Tranquility Bloom** original completed-operation, output ID/rank, 0-N, refund and skill logs.
