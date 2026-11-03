# Master QA verdict — four worker batch002 submissions (2026-10-28)

**Research branch only; production GameData.lua blob 1d47c4a961c5dc5af626e659f7d96d1490d3cf9e untouched.** Canonical prompt v1.2, mechanics/API registries, evidence README/schema, source/coverage ledgers, worker reports, current TOC and runtime Lua, and Issue #2 reviewed. Worker raw evidence immutable.

| Worker | Accepted unique first-pass | Output/overlay | Profile identity | Next disjoint queue |
|---|---:|---:|---:|---:|
| Midnight | 34 | 17 | 17 | 8 Midnight then 27 Dragonflight |
| TWW | 30 | 15 | 15 | 23 TWW then 12 Dragonflight |
| Dragonflight | 40 | 40 | 0 | 40 Dragonflight |
| Legacy | 30 | 18 | 12 | 40 Legacy |
| **Total** | **134** | **90** | **44** | **150** |

All 134 worker keys exactly matched disjoint assignments and were NEVER_EXAMINED in central coverage. Coverage now **328/1737**; **1409 never**, **315 insufficient**, **13 blocked**, **0 corrected Retail output**, **0 >=90**. Partial universe = 1001 main outputs +255 supplemental outputs +92 overlays +389 profiles. **5392** potential output material slots; independently scored **264 output records/1056 fields**: >=90 **0**, 70–89 **3** (historical First Flower E only), <70 **1053**. All 264 weakest-field records <70. Profiles are identity audits, not four-field output records. Full nonprocessing GameData inventory incomplete.

## Independent source-level QA

- **Midnight:** Cardinalai Wowhead 800 prospect casts: 3285 ore consumed +715 saved = 800*5 nominal; output totals 43/111/114/153/145/671/874 yield per cast .05375/.13875/.1425/.19125/.18125/.83875/1.0925. Input rank and build unspecified: **do not assign to 237364 vs 237365**. Resourcefulness is reagent-cost saving, not output multiplier. [Original comment](https://www.wowhead.com/item=237364/brilliant-silver-ore). [Blizzard March 31 gem hotfix](https://worldofwarcraft.blizzard.com/en-us/news/24266320) has no numeric coefficient.
- **TWW:** DobberSH's one five-Null-Stone prospect reports one ruby, one emerald, one pebble, one glass, **not** legacy overlay's claimed 2 pebbles + sapphire + onyx. Original-source **provenance transcription mismatch**, not a proven rate or impossible alternative output. [Original comment](https://www.wowhead.com/spell=434018/algari-prospecting).
- **Dragonflight:** Dec 9 2022 20,000 rank-3 Serevite study after Dec 6 reset: 476 Queen's Ruby, 424 Mystic Sapphire, 471 Vibrant Emerald /4000 five-ore equivalents = .119/.106/.11775. Legacy final high .126 for each is a TSM-low clamp, not measured high-skill output; R3 cohort cannot price rank-1 gem IDs. [Original source](https://www.reddit.com/r/woweconomy/comments/zh53dd).
- **Legacy:** 2020 source's six herb counts 8360+3200+5900+2220+2400+1640 = **23720**, despite '20k' title; all 18 independently normalized five-herb means match audit. Three First Flower historical expectedQuantity scores 72, but P/min/max unknown. [2020 source](https://www.reddit.com/r/woweconomy/comments/k12a5o) and [2022 First Flower](https://www.reddit.com/r/woweconomy/comments/t8lubc).

**Static checks actually run:** 128 named structural/score/key/normalization gates PASS, 0 FAIL; 18/18 Legacy E arithmetic and 9/9 Dragonflight provisional P*min<=E<=P*max checked. TSM tuple consistency does **not** validate source semantics. New worker JSONL sets parsed and required top-level fields inspected separately (4 Midnight, 1 TWW, 1 DF, 8 Legacy); full external JSON Schema and in-client tests **NOT RUN**. Current Retail numeric transformations proved **0**; blocked families **4** (Midnight hotfix, TWW milling quality, Dragonflight rank/TSM, Legacy patch bridge). No confidence inflation.

**Queue revision 4:** 150 distinct next keys; home-expansion work first, then disjoint Dragonflight overflow for Midnight/TWW. No schedule changes. Two completed worker cycles 140,134 (mean 137): 1409/137 ≈ 11 additional hourly cycles (~0.46 days) for **known first-pass scope only**. Rolling three master accepted batches 0,140,134. Full inventory and all-fields >=90 ETA unknown. All-fields >=90 gate **NOT MET**.
