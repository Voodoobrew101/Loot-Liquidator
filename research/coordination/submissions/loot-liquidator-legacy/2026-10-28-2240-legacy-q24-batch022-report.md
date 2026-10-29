# Loot Liquidator Legacy — Batch022, queue revision 24
**2026-10-28 22:40 America/Los_Angeles · research-only · loot-liquidator-legacy**

## Assignment and validated scope
Read live master queue revision 24, master batch021 verdict, source-memory, research-lessons and prior Legacy q23 submission. Audited **45/45 exact q24 stable keys**; all **45/45** input/output identities and numbered GameData.lua lines matched pinned blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`. 30 milling and 15 prospecting records; 28 legacy compiled source lines and 17 TSM-import source lines; 15 distinct input IDs. No q23 self-reassignment, no production or shared-ledger modifications.

## Four independent fields
180 field slots: **34 provisional TSM source-stated positive min/max references** (17 pairs, confidence 25/100, original cast denominator unknown) and **146 unknown**. Every P(hit) and per-completed-operation unconditional E is **UNKNOWN** for matched 2026 Retail context. The 28 compiled historical E values and 17 imported TSM `amountOfMats` figures are preserved in `sourceReference`, NOT promoted to measured current-Retail E. Legacy `chance` values are Poisson/proxy; `matRate` is not independently verified occurrence P. No fabricated zeros, midpoints, rank transfers or inferred P.

## P0 — mapping and recipe
- 45 existing input/output source rows verified, **0 new legitimate mappings** and **0 current Retail selector-verified mappings**. The sources list candidate output identities but do not prove each recipe/skill eligibility in the current client.
- Shadowlands First Flower 187699→173056/173057/175788; Progenium 187700→173108/173109/173110/173170; Legion Empyrium 151564→151579/151718/151719/151720; Astral Glory 151565→129032/129034; BfA herbs 152505–152511 and ores 152512/152513 covered.
- Ordinary five-herb/ore reagent unit is provisionally indicated; First Flower original study is **mass milling 20 herbs**, and the two operation types must not be conflated.

## New calculator discovery — useful but not an empirical dataset
Public Canadia_TV `Milling herbs BFA` Google Sheet: https://docs.google.com/spreadsheets/d/1Kx2qPiGXGqS5_zla1sSN69yxrYlGdEVTzR4bypP8yJU/edit, linked by https://gunnydelight.github.io/mozzletoff-wow-goldfarm-site/bfa-inscription-milling-shuffle.html. Its public text view shows **1000 herbs, estimated 310 Crimson and 130 Viridescent**, and configurable AH inputs. Five-herb equivalents 1.55 and 0.65 are calculator defaults, **not original cast observations**. Formulas, original data and profession context remain unavailable from the text view. One new derivative calculator source, **zero new measured cohorts or verified numeric fields**.

## P1/P2 — original First Flower lineage and denominator correction
The already-indexed original https://www.reddit.com/r/woweconomy/comments/t8lubc reports 4000 First Flower mass milled, 972 Umbral, 1031 Luminous, 1984 Tranquil. Source gross-input arithmetic exactly matches GameData compiled E=**1.215/1.28875/2.48 per nominal five-herb equivalent**. GameData's `per consumed input` wording is misleading for these three lines; original source is Reddit although GameData's source URL points to Wowhead. **Do not treat equivalent units as actual five-herb casts.** The legacy Poisson P proxies 0.703289986/0.724729217/0.916256774 are not measured P(hit).
Hypothetical imported TSM per-five E=**1.25/1.25/2.50**, relative differences -2.8%/+3.1%/-0.8%; denominator interpretation is unverified and may share ancestry with the original study.

## P2 — higher-risk mismatches (hypothetical, not current AH decisions)
- BfA 152507→153669: compiled historical E **0.733333** versus TSM `amountOfMats*5` **0.555** (+32.1%).
- BfA 152510→153636: compiled historical E **1.775** versus TSM hypothetical **1.36** (+30.5%).
- BfA 152508→153636: compiled historical E **1.658333** versus TSM hypothetical **1.36** (+21.9%).
These discrepancies could affect liquidation EV if matching current Retail rates and prices, but **neither source-unit semantics nor patch/skill applicability is established**, so no gold-optimal flip is claimed.
All 17 TSM rows have raw `matRate > amountOfMats`; **17/17** pass `P*positiveMin <= hypothetical 5*amountOfMats <= P*positiveMax` under the explicitly **unverified** assumption `P=matRate`. This is a consistency check, not evidence that TSM rates are observed probabilities.

## New qualitative lead
Wowhead Progenium Ore commenter Qoko compares approximate "1/150 on Essences" for Progenium/Laestrite with "1/15" for Elethium. https://www.wowhead.com/item=187700/progenium-ore . Original sample denominator, unit and exact output totals are absent; **not promoted to per-output P or E**. Independent author not established as measured study.

## Source reuse and continuous improvement
Reused source memory for First Flower original and existing BfA Jiyao/Baadkitty/Kidneph studies, avoiding re-counting them as new cohorts. The newly discovered spreadsheet and linked guide are one derivative calculator lineage; Qoko is a new qualitative lead, not an independent measured cohort. Six immutable source-review events record statuses, missing fields and recheck triggers. Recurrent failure: interpreting gross herb ratios or imported TSM quantities as actual per-cast yields, plus assigning Poisson proxies as observed P.

## Validation and handoff
**45/45** source line identities matched, **45 unique stable keys**, 0 mismatches, 0 negative fields, 0 invalid min>max; 34 provisional bounds, 146 unknown. Full P/E invariants cannot be tested because those fields remain unknown. No Node CLI/Lua/client test performed. No accepted numeric fields or reward points self-awarded.

**Exact next IDs for master:** current Retail completed-cast histograms and recipe-selector checks for `187700→173108/173109/173110/173170`; `187699→173056/173057/175788` (standard-5 versus mass-20 separately); `152507→153669`, `152510→153636`, `152508→153636`; original spreadsheet formula/source-lineage review. q24 assigned keys complete; master should reassign fresh disjoint keys.
