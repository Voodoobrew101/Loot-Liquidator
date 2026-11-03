# Loot Liquidator — The War Within Batch017 / queue19

**Date:** 2026-10-28. **Assignment:** `2026-10-28-batch017-war_within`. **Branch:** `research/processing-confidence`. Research-only; no master-owned/production edits.

## Assignment and evidence outcome
- Exact assigned keys audited: **35/35**, disjoint scope preserved. 21 TWW native (8 specialization-conditional, 13 compiled) and 14 explicitly assigned Dragonflight overflow (4 curated candidates, 10 TSM source rows).
- GameData.lua output-ID/source-line checks: **23/23** (13 TWW + 10 Dragonflight), source blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`. Curated/conditional keys have no pinned GameData row and were not falsely counted.
- Four independent numeric fields per record: **140** slots; **33 historical provisional** (13 TWW gross-ore E, 20 Dragonflight TSM family min/max bounds) and **107 unknown**. P(hit) **35/35 unknown**; current 2026 cast-based E promotions **0**.
- Newly supported exact conversion mappings **0**; new exact current-Retail cast histograms **0**; numerical corrections/promotions **0**. The master baseline at read was 994 provisional mappings, 801 four-field-complete, 435 unknown candidate cells; no worker change.

## P0: Rank/specialization eligibility and reagent units
- Algari Prospecting spell **434018** consumes **5 of the same ore quality per operation**. Conditional Bismuth R2 `210931`, Aqirite R2 `210934`, and Ironclaw R2 `210937` Gem Finding outputs remain gated by the appropriate Ruby/Emerald/Sapphire/Onyx node. Exact point thresholds and current-client state remain unknown. No independent unconditional additive gem output assumed.
- Historical PeaEsk **100 ore** per rank-two ore type is not 100 observed casts. The source GameData entries have `samples=100` and `provisional=false` alongside `probabilityBasis=POISSON_EVENT_COUNT_PROXY`; the worker audit explicitly treats these as historical gross-input references, not 100 measured operations or measured P(hit). This metadata ambiguity is a **master QA follow-up**, not a production edit.
- Official Oct 25, 2024 hotfix changed the byproduct/gem mechanics. Prior sources cannot establish post-hotfix probabilities or exact expected quantities. Source: https://worldofwarcraft.blizzard.com/en-us/news/24148555/hotfixes-october-25-2024

## P1: Independent four-field result
- All eight conditional specialist outputs: `dropChance`, `yieldMin`, `yieldMax`, `expectedQuantity` **unknown** until a 2026 zero-inclusive completed-cast cohort records node state, input/output ranks, skill, gear, Resourcefulness and patch.
- Thirteen compiled TWW outputs: only the prior PeaEsk *nominal-five-ore* E reference is preserved at historical confidence; three other numeric fields unknown. Do not double-multiply E by P or use the GameData Poisson estimate as measured P.
- Ten Draconium R2 `188658` historical TSM rows `L1183-L1192`: retain only positive family-level min/max reference at **24/100** each. Exact-rank P and E remain unknown; the rank triplets `192846-192848`, `192849-192851`, `192852/192853/192855` repeat family rates and must not be added as simultaneous outputs.
- Four curated Dragonflight keys `189143→192869`, `190311→192869`, `192880→192849`, `192880→192866` remain eligibility/rank/expectedQuantity unknown. An unreported R1 Diamond in a historical study is not proof of impossibility.

## P2: New contextual source and gold-decision risk
- **NEW first-hand claim discovered via search-index only:** https://www.reddit.com/r/woweconomy/comments/1k78h4v (published April 25, 2025) reports R2 Aqirite/Ironclaw gems about **8% more valuable** than R1 *by gems obtained*, without sample denominators or price snapshot. The same report's 4.1 Bismuth/gem concerns **Crushing input savings**, not produced gem outputs. Direct retrieval was blocked, so it is a source lead, not a verified study.
- **REUSED independent October 14, 2024 Aqirite cohort:** https://www.reddit.com/r/woweconomy/comments/1g350pq reports historical 26,543g vs 22,660g per 1,000 R1/R2 initial ore using *all outputs*. These price-based claims measure different things under different patch/price conditions; neither establishes a current AH action flip. Do not use 2024 gold prices as live TSM quotes.
- Conditional gems may replace baseline Amber. Correct EV requires a joint distribution and matching character specialization; no unsupported additive value. Resourcefulness reduces consumed inputs, never creates produced material units.

## Source-selection learning and negative findings
- Reused existing Method, PeaEsk, official hotfix, original 2024 Aqirite source and 2023 Dragonflight cohort rather than re-counting them as independent new samples. The 2025 post-hotfix qualitative claim is newly indexed but **not an independent cast histogram**. No new numeric output field supported.
- Avoided repeat web retrieval of already archived 2024 cohort and TSM profiles; Reddit direct fetch blocked, recorded explicitly. No reward points applied to evidence confidence.
- Master follow-up: prioritize exact 2026 R2 `210931/210934/210937` zero-inclusive cast histograms with node states, especially `210934→212498/212505/212508/213398/213399`, then Dragonflight `188658→192846-192855` rank-exclusive outcomes and `189143/190311→192869` eligibility.

## Validation
Queue revision 19 and assignment ID re-read before write; all 35 keys unique and in master order; 23 source-line item IDs checked against current GameData blob; 140 four-field slots checked; no invalid numeric P, positive-bound or E invariants. GitHub read-back verification is recorded separately. Node CLI, Lua interpreter and WoW client not executed.
