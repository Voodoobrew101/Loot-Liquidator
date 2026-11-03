# Legacy worker — historical milling evidence batch 01 (2026-10-28)

**Assignment:** 2026-10-28-init-legacy-001; branch `research/processing-confidence`. **Review scope:** 30 distinct assigned output records, 14 inputs: 6 Warlords, 21 Battle for Azeroth, 3 Shadowlands. These are candidate source reviews, not accepted central-ledger changes.

## Sources and extraction
- WoD Wowhead Mass Mill Nagrand Arrowbloom comment by **516803**: 2,000 herbs of each of six species; Cerulean totals 848 Frostweed, 842 Fireweed, 833 Gorgrond Flytrap, 845 Starflower, 843 Nagrand Arrowbloom, 843 Talador Orchid. https://www.wowhead.com/spell=190385/mass-mill-nagrand-arrowbloom
- BfA Wowhead Viridescent Pigment comment by **Kidneph**: six herb cohorts of 1,000 herbs each, separate Ultramarine/Crimson/Viridescent totals. **Baadkitty**: 200 Anchor Weed, totals 157/71/64. https://www.wowhead.com/item=153669/viridescent-pigment
- Shadowlands Wowhead Tranquil Pigment comment by **Melch1337**: pooled study claiming over 100,000 herbs, with per-100-herb Widowbloom 19.4 Umbral, 9.6 Luminous, 0.5 Tranquil; **Widowbloom-specific denominator unknown**. https://www.wowhead.com/item=175788/tranquil-pigment
- Source identity corroboration: https://www.wow-professions.com/guides/milling-table-inscription ; https://repos.curseforge.com/wow/prospect-me/comparison/f9b6c0305908/Modules/ProspectMe_Tables.lua?style=paper ; https://www.wowhead.com/item=152506/star-moss ; https://www.wowhead.com/item=152508/winters-kiss .
- Source capture date: 2026-10-28; original comment dates/game builds not established. No claim of current-Retail verification.

## Quantitative method and QA
Every aggregate output count is normalized to a **5-herb-equivalent expected quantity** as `observed output total × 5 / consumed herbs`. The source's Mass Mill recipe is 20 herbs; per-20 equivalent is four times the per-five estimate, **not** a claim that 5-herb cast distributions were observed. The per-100 Widowbloom published rate is multiplied by 5/100. No midpoint, drop chance or conditional range was inferred.

- 30/30 assigned stable keys matched source rows in main `GameData.lua`; all nonnegative finite quantities; all arithmetic normalization checks passed.
- 18 historical candidate EV rows differ from existing `GameData.lua` numerical estimates. Differences are **not** approved corrections; cohorts may differ in profession skill, era, patch, and measurement protocol. Preserve both until master review.
- 6 WoD and 3 Shadowlands source-normalized EV rows match existing quantities to precision. BfA values should be investigated rather than blindly replaced.
- All 30 occurrence chances remain unverified (existing proxy chance is not a cast-frequency observation). Conditional positive integer min/max also unverified. **All 30 conservative record scores remain 0** because three material fields have no independently supported measurements. EV-only historical evidence confidence: 68 for 1,000/2,000-herb cohorts; 57 for 200-herb Anchor; 52 for pooled Widowbloom without species-specific denominator.
- A key source caveat: 2026 current Retail mechanics and skill dependence were not demonstrated; do not treat historical aggregate rates as current-live values. No in-game tests executed.

## Candidate differences requiring QA
| Input | Output | Existing E/5 | Historical E/5 | Difference |
|---|---|---:|---:|---:|
| Riverbud (152505) | Ultramarine Pigment (153635) | 4.020833333 | 4.07 | 0.049166667 |
| Riverbud (152505) | Crimson Pigment (153636) | 1.508333333 | 1.515 | 0.006666667 |
| Riverbud (152505) | Viridescent Pigment (153669) | 0.65 | 0.68 | 0.03 |
| Star Moss (152506) | Ultramarine Pigment (153635) | 4.0125 | 4.04 | 0.0275 |
| Star Moss (152506) | Crimson Pigment (153636) | 1.4125 | 1.395 | -0.0175 |
| Star Moss (152506) | Viridescent Pigment (153669) | 0.45 | 0.455 | 0.005 |
| Akunda's Bite (152507) | Ultramarine Pigment (153635) | 4.104166667 | 4.16 | 0.055833333 |
| Akunda's Bite (152507) | Crimson Pigment (153636) | 1.5625 | 1.565 | 0.0025 |
| Akunda's Bite (152507) | Viridescent Pigment (153669) | 0.733333333 | 0.75 | 0.016666667 |
| Winter's Kiss (152508) | Ultramarine Pigment (153635) | 4.058333333 | 4.07 | 0.011666667 |
| Winter's Kiss (152508) | Crimson Pigment (153636) | 1.658333333 | 1.66 | 0.001666667 |
| Winter's Kiss (152508) | Viridescent Pigment (153669) | 0.641666667 | 0.64 | -0.001666667 |
| Siren's Pollen (152509) | Ultramarine Pigment (153635) | 3.991666667 | 3.995 | 0.003333333 |
| Siren's Pollen (152509) | Crimson Pigment (153636) | 1.595833333 | 1.555 | -0.040833333 |
| Siren's Pollen (152509) | Viridescent Pigment (153669) | 0.604166667 | 0.575 | -0.029166667 |
| Sea Stalk (152511) | Ultramarine Pigment (153635) | 4.129166667 | 4.165 | 0.035833333 |
| Sea Stalk (152511) | Crimson Pigment (153636) | 1.3875 | 1.34 | -0.0475 |
| Sea Stalk (152511) | Viridescent Pigment (153669) | 0.566666667 | 0.59 | 0.023333333 |

## Continuation
Master should reconcile source cohort provenance and decide whether any candidate should replace existing fallback only after context/patch checks. Next assigned legacy keys: `output-main:compiled:mill:168586:173056:L200`, `output-main:compiled:mill:168586:173057:L201`, `output-main:compiled:mill:168586:175788:L202`, `output-main:compiled:mill:168589:173056:L205`, `output-main:compiled:mill:168589:173057:L206`, `output-main:compiled:mill:168589:175788:L207`, `output-main:compiled:mill:169701:173056:L210`, `output-main:compiled:mill:169701:173057:L211`. Other old expansions remain in the unexamined ledger. No production or master-owned files changed.

## Research data
Machine-readable per-field observations: `research/evidence/observations/2026-10-28-legacy-milling-batch01.jsonl`. Distinct newly first-pass examined proposed: **30**, pending master acceptance; independently substantiated >=90: **0**; numeric corrections committed to production: **0**; sources cross-checked: **5** source URLs, three primary study authors plus supporting identity sources.
