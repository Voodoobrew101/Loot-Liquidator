# Research source register (updated 2026-10-27)

## Verified this run

| Evidence | Source | Date/version and what it establishes | Limits |
|---|---|---|---|
| Midnight prospecting gem buff | https://worldofwarcraft.blizzard.com/en-us/news/24266320 | **April 1, 2026**, under Professions in Blizzard's cumulative April 17 article; explicitly states gems become more common | No quantitative multiplier or ore-specific drop probabilities |
| Midnight buff corroboration | https://us.forums.blizzard.com/en/wow/t/world-of-warcraft-midnight-hotfixes-april-17/2260898 | Blizzard forum cumulative hotfixes, April 1 subsection | Same primary publication, not independent experimental measurement |
| Contemporary response | https://www.reddit.com/r/woweconomy/comments/1sfds1u/did_prospecting_change/ | April 8, 2026 community discussion already responding to buff | Anecdotes and uncontrolled sample; not valid to infer uniform multiplier |
| Cobalt Ore 36909 | https://warcraft.wiki.gg/wiki/Cobalt_Ore | Prospecting yields 1–2 of six named uncommon gems at approximately 25% each | Historical/general Wiki estimates, not confirmed per-cast Retail 2026 distribution |
| Titanium Ore 36910 | https://warcraft.wiki.gg/wiki/Titanium_Ore | Six uncommon gems, rare/epic gems and powder; roughly 25% uncommon each | Historical/general Wiki, not confirmed Retail 2026 exact probabilities |
| Historical Cobalt/Saronite percentages | https://www.wow-professions.com/wotlk/prospecting-table-wotlk-classic | WotLK Classic table: ~23% each uncommon Cobalt, ~18% Saronite | Classic rates cannot be promoted to verified Retail rates |
| Prospecting batch | https://warcraft.wiki.gg/wiki/Prospecting | Generic prospecting consumes 5 ore; mass prospecting consumes 20 | Modern recipes can have different requirements; use recipe-specific batch |
| Cobalt Retail item identity | https://www.wowhead.com/item=36909/cobalt-ore | Retail item ID 36909 and prospectable status | Does not validate all output IDs or rates |
| Retail profession API | https://warcraft.wiki.gg/wiki/API_C_TradeSkillUI.GetProfessionInfoBySkillLineID | Expansion skill line info exposes skillLevel and skillModifier | May be unavailable/zero in some contexts; must verify live availability |
| Operation API | https://wowpedia.fandom.com/wiki/API_C_TradeSkillUI.GetCraftingOperationInfo | CraftingOperationInfo fields baseSkill, bonusSkill, craftingQuality, bonusStats | Older mirror; live Retail behavior and recipe argument requirements need testing |
| TSM rate use | https://blog.tradeskillmaster.com/category/tsm4/ | TSM notes updated Dragonflight conversion rates and profession stat variation | Does not independently prove every historical `matRate`/`amountOfMats` field's semantics |
| TSM code historical | https://github.com/Xurkon/TradeSkillMaster/blob/main/TradeSkillMaster.lua | Historical TSM uses conversion rate as price multiplier | Unofficial older fork; not authoritative current TSM source |

## Internal primary source

- https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/GameData.lua — SHA `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e` at time of scan.
- https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/ConversionEngine.lua — checked EV per-input arithmetic and current low/high context handling.
- https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/StatYieldProfiles.lua — checked generated low/high scenarios, tooltip probability/range estimates and TWW/Midnight runtime mappings.
- https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/Professions.lua — checked live profession snapshot logic.
- https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/Settings.lua — checked actual settings sliders and profession research toggles.
- https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/MIDNIGHT_MODEL_README.txt — explicitly states low/high slider is manual and current output quality selection remains incomplete.

## Evidence semantics
- `P(drop)`: occurrence probability **per operation**; never infer from aggregate output totals without cast-by-cast hit counts.
- `[min,max]`: **integer units conditional on a drop**; do not derive gold expectation from midpoint.
- `E[units]`: **decimal unconditional expected units per operation** including zero outcomes; for gold use this directly once.
- Source study conditions include expansion, live patch/hotfix era, input rank, output rank, effective skill, profession specializations, gear, resourcefulness, concentration/inspiration when applicable, batch size, and actual input consumed vs original ore purchased.
- The evidence-strength score (0–100) is NOT a statistical accuracy guarantee.
