# Original-source observations — Legacy 2026-10-28-1242-legacy-batch012
This is **source-only** evidence, not an approved itemdb baseline or a JSON observation pretending to meet a cast-level schema.

## P0 missing Titanium Powder
- Item: Titanium Ore `36910` to Titanium Powder `46849` by Northrend Prospecting, nominal batch 5 ore. Source: https://www.wowhead.com/item=46849/titanium-powder; patch 12.0.5 reported by commenter globalmenace; actual date, skill, spec, gear, cast logs unknown.
- Raw modern source: **1000 ore input, 143 powder output**; 18 gem types listed only as counts/prices without gem IDs. Gross input-equivalent `143/1000*5=0.715`. **P(hit), positive min/max, actual operations = unknown**. Historical snapshot ore cost 51,591g, powder 494.92g each, other gem value 4,303.95g.
- Historical separate author codiferous87 patch 10.1: 4500 ore, 764 powder, `764/4500*5=0.8488889` per nominal five.
- Historical separate author Ssateneth patch 8.1.5: 26,000 ore, reported 14.426% powder per ore, `0.14426*5=0.7213` per nominal five. Raw integer total not stated; do not fabricate it.
- Historical separate author Reddit 2022: 1000 ore, 152 powder, `152/1000*5=0.76`; https://www.reddit.com/r/woweconomy/comments/s6bfrl.
- Original historical ZeRoTaCtIcS: 66 full stacks / approximately 264 standard prospects, 202 powder; `202/264=0.7651515` per nominal five. Raw per-output gem totals: Bloodstone 69, Sun Crystal 60, Chalcedony 77, Shadow Crystal 64, Huge Citrine 59, Dark Jade 71; source https://www.wowhead.com/wotlk/item=46849/titanium-powder. Author's operation count is approximate, no zero-inclusive histogram. Patch/skill not established.
- Historical Classic/PTR comments may have changed rates and are **not** a current-Retail multiplier. Item `46849` absent from GameData, overlay, engine, source ledgers and staged candidate, verified by exact ID search in each file.

## P0/P1 other original cohort reuse
- https://www.wowhead.com/item=153669/viridescent-pigment: Baadkitty 200 herbs each: Riverbud 151, Star Moss 155, Akunda 153, Winter 160, Siren 159, Anchor 157, Sea Stalk 158 Ultramarine. Kidneph 1000 herbs each excluding Anchor: Riverbud 814, Star Moss 808, Akunda 832, Winter 814, Siren 799, Sea Stalk 833. Their per-five equivalents do NOT supply observed actual casts or P(hit). Independent authors, different conditions.
- https://www.wowhead.com/spell=209662/mass-mill-starlight-rose: Queendom 3000 Starlight Rose, 3635 Roseate, 150 Sallow, 128 seeds; nominal 20-herb mass cast basis. Source reports Sallow `1.0400/mill` but 150/(3000/20)=1.0. No adjustment of original totals.
- https://www.wowhead.com/item=129034/sallow-pigment: original Legion beta author 40 Felwort, 17 Roseate, 89 Sallow, no exact actual cast log; `89/(40/5)=11.125` per nominal five. Same page also contains other authors; source ID must include commenter and cohort.

## Invariant and source-unit caveats
TSM `36910 -> 36917`: p=.235, min=1, max=2, E=2.5; `p*max=.47`, incompatible. Historical ZeRoTaCtIcS aggregate E=69/264=.26136, plausible but not current patch matched. For MoP source p=.16,min=max=1,E=.1705 violates E<=.16; for Felslate p=.01,min=2,E=.01 violates E>=.02. Never repair by inventing a new max, casting missing as zero, or reusing a mass recipe's denominator as a standard operation.
