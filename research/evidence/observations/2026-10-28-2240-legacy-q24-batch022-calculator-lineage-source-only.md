# Legacy q24 batch022 — source-only reconciliation and spreadsheet discovery
**2026-10-28 · original evidence remains immutable; no 2026 Retail numeric promotion**

## NEW: publicly readable Google Sheets calculator, not a measured experiment
- Original sheet: https://docs.google.com/spreadsheets/d/1Kx2qPiGXGqS5_zla1sSN69yxrYlGdEVTzR4bypP8yJU/edit
- Discovery/attribution: https://gunnydelight.github.io/mozzletoff-wow-goldfarm-site/bfa-inscription-milling-shuffle.html (page last updated 2020-08-21; credits Canadia_TV).
- Sheet title **Milling herbs BFA**. Public text view exposes editable/default **1000 herbs**, **310 Crimson Pigment**, **130 Viridescent Pigment**, AH price inputs, 25.40% ROI, and estimated profit 2540. These are explicitly labelled **estimated quantities**, NOT measured output totals or 2026 Retail probabilities. The text view does not reveal formulas or underlying sample counts; original spreadsheet cells and calculation logic require separate inspection.
- Descriptive arithmetic only: 310/1000 = 0.31 Crimson per herb and 130/1000 = 0.13 Viridescent per herb; five-herb equivalents 1.55 and 0.65. **Do not promote either to an unconditional E per completed cast.** This is a calculator-default model, not an independent player study. Ultramarine output is not supplied in the visible sheet.
- New source status: PARTIAL / new to source-memory cache. Recheck trigger: export/read formulas, locate author source study, identify assumptions and sample patch.

## REUSED: 2022 original First Flower mass-mill cohort
- https://www.reddit.com/r/woweconomy/comments/t8lubc, original Reddit author, published 2022-03-07. Already in source memory; NOT a new independent cohort.
- Author reports **4000 First Flower** mass milled, with **972 Umbral (173056), 1031 Luminous (173057), 1984 Tranquil (175788)**. Published table divides by 20 herbs per mass mill.
- Raw gross-input ratios: 0.243, 0.25775, 0.496 per herb. Five-herb **equivalents**: 1.215, 1.28875, 2.48. These exactly match GameData.lua L225–L227, which incorrectly/ambiguously labels them as "per consumed input" even though the values are five-herb equivalents. **Do not treat 4000/20 or 4000/5 as independently reported actual completed operation counts** or transfer mass-20 distributions to standard-5 P/min/max.
- Source-line chance values are 1-exp(-E) Poisson proxies, not measured P(hit). GameData source attribution points to Wowhead while the original lineage is Reddit; retain explicit primary source URL.
- Separate imported TSM amountOfMats*5 hypothesis yields 1.25/1.25/2.50, within -2.8%, +3.1%, -0.8% of the source equivalents, but this does not prove TSM units or independent ancestry.

## REUSED: BfA original authors and imported source rows
- https://www.wowhead.com/item=153669/viridescent-pigment contains already indexed original authors Jiyao, Baadkitty, Kidneph, and an unnamed skill-150 anecdote. **Do not count locale mirrors, republished calculators or these authors as new.**
- q24 GameData L158–L190 has 19 BfA compiled material rows with "v0.32 observed material mean per consumed input"; exact original standard-five cast denominator and unit bridge are not supplied in these rows. Keep values in sourceReference rather than independently verified current-Retail E.
- Example potential TSM valuation divergence under **hypothetical** per-input-to-five conversion: 152507→153669 source 0.733333 vs TSM 0.555 (+32.1%); 152510→153636 source 1.775 vs TSM 1.36 (+30.5%). Different cohorts and uncertain source units prevent declaring a 2026 gold-decision flip.

## NEW qualitative source lead: Progenium Ore
- https://www.wowhead.com/item=187700/progenium-ore, commenter Qoko: approximate "1/150 on Essences" compared to Laestrite, versus Elethium "1/15". **No denominator unit, completed casts, raw counts, exact essence breakdown, skill or patch window** is provided. This is an anecdotal rate comparison, not a measured numeric field. It cannot establish any specific 187700→173170/171/172/173 rate. Source was absent from indexed cache at review time.

## Invariants and source-lineage conclusions
- Source-only document; no observation.schema.json row is invented for the calculator or Qoko anecdote.
- No patch-time normalization, source cohort merging, five-to-twenty cast equivalence, or chance-from-aggregate conversion.
- Follow-up: original sheet formulas and sampling lineage; current Retail standard-5 actual cast histograms with zero outcomes, separate from mass-20 studies.
