# Loot Liquidator — War Within q21 / batch019

**2026-10-28, research-only.** Read live queue revision 21, master batch018 verdict, source-memory, research-lessons, previous source reviews, GameData and source schema. Assignment 2026-10-28-batch019-war_within. **35/35 exact disjoint keys** (21 TWW native and 14 explicitly assigned Dragonflight overflow). **22/22 pinned GameData source line/output ID checks** (13 TWW + nine Dragonflight milling).

## P0/P1 — actual numeric evidence
**0 new legitimate mappings; 0 newly verified current Retail per-cast numeric fields; 0 new matched cast histograms.** Across 140 four-field slots: **18 estimated low-confidence positive min/max TSM source references** (20/100, not measured exact-rank bounds) and **122 unknown**. The 13 TWW compiled expected quantities are retained as *historical nominal-five-ore equivalents* outside the per-completed-cast expectedQuantity field. Original PeaEsk source reported 100 ore, not 100 casts; source chance values are Poisson proxies, not observed P(hit). Unknown values remain null, not zero.

## P2 — new original 50,000-ore source lead
First-hand Adreymar on https://www.wowhead.com/item=213399/glittering-glass reports approximately **50,000 mixed ores**, max Resourcefulness and **80 Glittering Glass per 1,000 ores**, or 0.4 per nominal five initial ore. PeaEsk's reused R2 100-ore Glass totals are 22 Bismuth, 13 Aqirite, 11 Ironclaw, nominal equivalents 1.10/0.65/0.55. Differences 2.75x/1.625x/1.375x are NOT matched experiments; ore mixture, original cast denominator, profession context, sample date and patch are unknown. No item-specific E promotion or gold-action flip. Source-memory had no Adreymar source at read, so this is one new indexed original pooled aggregate, not one new 2026 verified cohort.

## Official mechanics guard
Blizzard https://worldofwarcraft.blizzard.com/en-us/news/24148555/hotfixes-october-25-2024 says byproducts occur on each Prospecting action after October **25**, 2024, fixes Prospecting 40/40 Amber perk, and reduces gem and maximum byproduct yield rates. This does not prove P(Glass)=1 or P(Pebbles)=1 separately; only the joint byproduct mechanic is described. Do not infer hotfix applicability from an undated study's publication or page ordering.

## P0 — eligibility and rank guards
Algari Prospecting spell 434018 consumes **five same-rank ore**; eight assigned Gem Finding candidates require Ruby/Emerald/Sapphire/Onyx node selection, with exact points and current character state unresolved. Gems may replace Amber rather than be additive. Five curated Dragonflight candidates lack pinned GameData lines. LavingRunatic's 60 real Crumbled Stone casts support family totals but not 192849/192866 exact output ranks. Nine assigned Dragonflight TSM milling rows repeat the same family rate across rank-one/two/three pigment alternatives (matRate=1, amountOfMats=0.7, positive reference bounds 2–5); never triple-count all three.

## Research learning and next IDs
New source: one independent original author pooled aggregate; reused sources: PeaEsk, Blizzard, LavingRunatic/Mgnta, Saxifrage Aary and TSM/GameData. Six source-review events log novelty and missing fields; no reward points alter confidence. Highest-priority exact IDs: **210931/210934/210937 → 213398/213399** with actual posthotfix casts; eight Gem Finding output candidates **210931→212495/212505/212508/212511, 210934→212495/212511, 210937→212505/212508** with node thresholds; **192880→192849/192866** rank-labelled casts; **191461/191462→198421/198422/198423** and **191464/191465→198418/198419/198420** with quality-specific milling histograms.

## Validation and safety
35 unique keys, 22 source-line matches, 140 field slots, 13 separated historical E references, 18 low-confidence source bounds, 122 unknown, nine rank-copy warnings; numeric invariants passed. No Node CLI, Lua interpreter or in-client test. No edits to main, production Lua/TOC, shared ledgers, assignments, registry, source-memory or schedules.
