# Dragonflight Batch 018 — queue revision 20
2026-10-28 18:30 PDT · loot-liquidator-dragonflight · research-only

## Assignment and static QA
Read live queue20 assignments, master batch017 verdict, source-memory, research lessons, q18/q19 source reviews, itemdb and observation schemas, historical GameData and previous worker reports. **40/40 exact disjoint assigned stable keys** independently reconciled against GameData blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`, including exact output ID, original source line and enclosing input group. No source-line mismatches. 38 Dragonflight rows plus **2 master-assigned Shadowlands First Flower overflow**. All four fields independently represented per row.

## Field-level results
Across 160 field slots: **80 historical TSM family-level positive range proxies** (40 min and 40 max, confidence 30/100, not exact-rank measurements), **3 descriptive historical sample expected quantities** (Serene R2 198413 = 3/3 = 1; Flourishing R2 198416 = 5/3; Flourishing R3 198417 = 2/3; confidence 34/100, 3-cast Primer cohort), **77 unknown** (40 P and 37 E). Exactly **one newly in-scope historical E** for 200061→198413; the two Flourishing E were previously reported in q18. Zero newly measured current-Retail numeric fields; zero new legitimate output mappings; zero new rank-specific positive bounds. Historical TSM estimates are reference-only, not current AH quotes or measured occurrence.

## New original author lead
Original Reddit comment by **tired_and_fed_up** in https://www.reddit.com/r/woweconomy/comments/yaxw94/a_look_at_dragonflight_milling/ describes “about 2k” Prismatic Leapers milled, approximately **3.8 pigments per mill**, and rare unspecified Rousing drops. This is an original separate-author **historical qualitative/aggregate cohort**, not a valid exact-output field: “2k” denominator is ambiguous (fish or casts), pigment output ranks and exact Rousing IDs absent, profession/patch unknown. Parent Liqourice5 post is deleted and was previously indexed through derivative Wowhead; do not count derivative as an additional experiment. See accompanying source-only observation.

## P2: Gold decision risk
- Fish 200061 source rows repeat `matRate=0.2462`, `amountOfMats=0.1723` over 12 pigment ranks; naïve 12-row nominal E sum = **10.338**, versus four-family nominal proxy **3.446** (3×). The new player 3.8 is **~10.27% above 3.446**, but lacks matching context and does not validate a replacement.
- Bubble Poppy 191467–191469 and Writhebark 191470–191472 repeat family 3.5 pigments per five herbs across three rank alternatives, risking 10.5 per mill if summed. Actual rank-specific P/E remain unknown.
- Draconium 188658 rows copy source family gem rates across ranks, and source `matRate` and `amountOfMats` must not be read as measured P and E. In particular for 192837–192845, raw matRate=0.19 > nominal E proxy=0.2005? They are not the same denominator/meaning and no field promotion is justified.
- Shadowlands First Flower original **20-herb mass** 200-cast sample has E=4.86 Umbral, 5.155 Luminous per mass operation; dividing by four is a contextual five-herb input normalization, **not** an observed standard five-herb E. Do not replace assigned 187699→173056/173057 TSM rows with mass results.
- Resourcefulness returns input materials and must not be added to output quantities. Fish sourceQuality pseudo-rank is not real item rank. No verified gold-optimal method flip without current AH prices and exact current-Retail yields.

## Independent vs derivative source accounting
New separate-author historical report: 1 (in existing parent thread; unverified denominator). Reused original cohorts: Primer three mills; BullDozzer 200 mass mills. Reused derivative/context: GameData/TSM, Wowhead parent-post quotation, Warcraft Wiki and old Reddit discussion. Avoided counting source reposts as new experiments or re-fetching already archived full datasets. No source memory cache changes.

## Exact next targets
1. `tsm:mill:200061:190322:L1996`: direct per-cast Rousing Order hit and yield histogram, current patch and item ID; distinguish from fishing loot.
2. `tsm:mill:200061:198413:L1999`, `tsm:mill:200061:198416:L2002`, `tsm:mill:200061:198417:L2003`: 2026 skill/rank-matched actual cast histograms to replace 3-cast historical E.
3. `tsm:mill:191468:198412:L1970` / `198413:L1971` / `198414:L1972`: Bubble Poppy rank separation and zero-inclusive per-operation E.
4. `tsm:prospect:188658:192837:L1174` through `192845:L1182`: exact-rank Draconium output histograms and source-semantic interpretation.
5. `tsm:mill:187699:173056:L1930` and `173057:L1931`: separate standard 5-herb versus mass 20-herb client outcomes.

## QA and constraints
All 40 original line/input/output identities and 160 field structures validated; all populated bounds positive, min<=max, 0<=P<=1 when known, and E>=P where jointly known (no exact-context P known). No invented zeros or ranks. No current-client, Lua, or Node CLI execution; only source/static verification. Master must accept or reject claims before compilation. No production Lua/TOC, main, master ledgers, canonical registry, assignments, source-memory or schedules changed.
