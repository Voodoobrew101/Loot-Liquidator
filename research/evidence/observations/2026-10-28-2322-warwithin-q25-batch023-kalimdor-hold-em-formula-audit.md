# TWW original spreadsheet formula inspection — source-only, no measured numeric promotion
**Worker:** loot-liquidator-war-within; **queue:** 25; **date:** 2026-10-28 PDT. **Exact assigned home scope:** 21 TWW prospecting/Gem Finding output records, plus 14 explicitly assigned Dragonflight overflow records. No external workbook executed or edited.

## Original source and custody
- Original community author post (September 24, 2024): https://www.reddit.com/r/woweconomy/comments/1foca2r/tww_crafting_spreadsheet_using_blizzard_and_tsm/
- Workbook link given by the author: https://drive.google.com/file/d/1nM7SJGUGyCz7KeL72xm7vorkH_gNrrLl
- Downloaded original **Kalimdor Hold Em.xlsm** (6,037,097 bytes), Drive metadata modified 2025-08-23. Inspected OOXML formula and cell text only; **never executed embedded VBA/macros**. Workbook has 29 worksheets, including Shuffles, Constants, Item Data, and Jewelcrafting.
- In-workbook Shuffles!B22 states `FINAL 2024-11-02`. Therefore even a 2025 file modification does not establish updated 2025 or 2026 prospecting mechanics. Source is an independent calculator author, **not an independent cast study**.

## Exact formula and modeling observations
- Shuffles!B18: yields modeled by ore type, quality and talents; B19 explicitly says **Skill, Inspiration and Multicraft are not applied** for this TWW prospecting model. This is the author's modeling choice, not proof that skill has no effect in Retail.
- Shuffles!B20 warns talent descriptions are misleading. B25–B36 expose the ore/quality selection, Resourcefulness, and Gem Finding talent inputs. B32–U36 expose four gemstone specialization points and shift/bonus formula components.
- Shuffles!R34 uses `EmeraldP/100+IFS(EmeraldP<5,0%,EmeraldP<15,2%,TRUE,5%)`; corresponding S34:U34 implement the other gems. R36 uses `IFS(EmeraldP<20,0%,TRUE,20%)`. These are **hardcoded talent-model coefficients**, not sampled hit rates.
- Shuffles!F41=1.13 and G41=0.38 are static expected Handful of Pebbles and Glittering Glass quantities per Bismuth-1 prospect; analogous base cells F44/G44 and F47/G47 repeat these numbers for Aqirite/Ironclaw. **No original cast denominator or raw histogram was attached to these formula cells.**
- Shuffles!H44=0.24, I44=H44/2, L44=H44/2 are family-level Aqirite R1 baseline assumptions. These cannot be promoted to an output-rank-specific unconditional E or a P(hit).
- Shuffles!H53=`H41*(1-totalAmberShift)+addAmber`, I53=`(I41+$H41*R$34)*(1+R$36)`: conditional modeled amber shifts and capstone bonuses. At a given talent configuration, these are modeled expected quantities, not measured probabilities or positive yield bounds.
- Shuffles!E27=`calcCraftingCost("Algari Prospecting",$B27)*(100%-prospectR*rFactor*(1+prospectRB))`: Resourcefulness discounts **input cost**; it is not additional produced gem quantity. Shuffles!D27=`SUM(F27:M27)` sums monetary output values, not item quantities. Some workbook cached profit cells show `#VALUE!` in the downloaded snapshot because of dependencies/custom functions; no live recalculation or gold recommendation was asserted.
- The workbook explicitly describes baseline model and historical data; its price feed depends on Blizzard/TSM external data and is not a current 2026 AH quote.

## Relevance and decision
1. **Novel usable methodological finding:** an externally authored TWW spreadsheet treats Resourcefulness as reagent cost savings and applies talent-specific output transformations; unlike the recently reviewed Midnight calculator, it does not simply add Resourcefulness to each output's E. This is a good *structural* check, not independent numeric corroboration.
2. **Negative numeric finding:** the sheet has no accessible completed-cast histograms with zero outcomes, patch, output item rank, skill and exact ore rank for any of the 21 assigned TWW records. Do not transfer F41/G41/H44 or talent coefficients into four-field compiler values.
3. **Current-Retail mismatch:** historical 2024 model versus 2026 Retail, with no verified patch bridge. Distinguish skill-neutral modeling assumption from an empirically proven skill-neutral mechanic.
4. **Lineage:** source author spreadsheet is derivative/model-based; author Reddit post and linked workbook are **one** lineage, not two independent sources. Reddit original studies at https://www.reddit.com/r/woweconomy/comments/1fisfkn are already indexed in source-memory, so were reviewed as reused historical context, not new authors.
5. **Next empirical need:** zero-inclusive prospect-level outcome logs for Bismuth R2 (210931), Aqirite R2 (210934), Ironclaw R2 (210937), each under recorded Gem Finding points, skill, effective rank and patch. Separate each gem's item ID and quality. Do not infer probabilities from aggregates or count returned ore as gem output.

No numeric promotions, no new mapping claims, no modification of shared or production files.
