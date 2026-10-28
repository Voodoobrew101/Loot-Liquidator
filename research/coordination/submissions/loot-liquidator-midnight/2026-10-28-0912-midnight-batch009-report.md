# Loot Liquidator — Midnight worker Batch 009 (2026-10-28)

**Branch:** `research/processing-confidence` · **Master queue revision:** 11 · **Assignment:** `2026-10-28-batch008-midnight` (retained 35 keys). Initial Midnight scope was redirected by master to **21 Shadowlands + 14 Dragonflight milling TSM output rows**. All 35 unique keys matched actual `GameData.lua` lines and `NEVER_EXAMINED` master ledger status; this is a **worker submission pending master acceptance**, not an accepted central count. Source GameData blob SHA: `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`.

## Original evidence — six new Jiyao cohorts

Recovered a self-described original player table from [Wowhead's Tranquil Pigment comments](https://www.wowhead.com/item=175788/tranquil-pigment). The commenter Jiyao reports **310 actual Shadowlands mass-milling operations across six herbs** with output-specific *rounded means per 20-herb cast*. This is **one original study**, not six independent studies. Archived six source-preserving schema-shaped observations under `research/evidence/observations/2026-10-28-0912-midnight-batch009-jiyao-six-mass-mill-cohorts.jsonl`.

| Herb (input ID) | Reported mass casts | Umbral 173056 | Luminous 173057 | Tranquil 175788 |
|---|---:|---:|---:|---:|
| Death Blossom (169701) | 145 | 2.98 | 2.77 | 0.12 |
| Marrowroot (168589) | 25 | 3.76 | 1.96 | 0.00 |
| Rising Glory (168586) | 44 | 2.05 | 3.43 | 0.11 |
| Vigil's Torch (170554) | 24 | 1.17 | 4.67 | 0.08 |
| Widowbloom (168583) | 10 | 3.90 | 1.90 | 0.20 |
| Nightshade (171315) | 62 | 5.21 | 4.81 | 6.05 |

The [six mass-mill recipes](https://www.wowhead.com/spell=311413/mass-mill-deathblossom) consume **20 herbs per operation**; specific recipe IDs checked were 311413 Death Blossom, 311416 Marrowroot, 311417 Rising Glory, 311414 Vigil's Torch, 311415 Widowbloom, and 311418 Nightshade. Exact integer output totals, positive-only minima/maxima, zero-inclusive histograms, profession skill/gear and build are **unreported**. Do not reconstruct integer totals from rounded means.

**Independent comparison:** reused the previously archived original [November 25, 2020 Shadowlands study](https://www.reddit.com/r/woweconomy/comments/k12a5o), reporting 23,720 herbs across six input cohorts. Its 18 output totals can be compared on a descriptive **per-20-herb equivalent** basis; its actual completed mass-cast denominator is not independently confirmed. Across 18 same-herb/pigment comparisons, mean absolute difference was **0.198 units per 20 herbs**. Largest disagreement: Vigil's Torch → Umbral, **1.937** (2020 ore-normalized) versus **1.17** (Jiyao rounded per mass cast). Different unknown patch/skill conditions and missing raw cast logs prohibit formal weighted synthesis or current-Retail normalization.

**First Flower source reuse:** [March 7, 2022 original 4,000 First Flower study](https://www.reddit.com/r/woweconomy/comments/t8lubc) already in source memory reports 200 mass casts and 972 Umbral / 1,031 Luminous / 1,984 Tranquil = **4.860 / 5.155 / 9.920 units per 20-herb mass cast**. Three assigned TSM rows were audited against this independent original, but not counted as a new study. The TSM `amountOfMats` values are per herb and their five-herb equivalents are **not** actual mass-cast observations.

## Dragonflight quality-rank arithmetic hazard

The 14 assigned rows cover Hochenblume R1–R3 and Saxifrage R1–R2. TSM repeats **0.7 pigment per herb for every quality-rank output**, producing an apparent **3.5 per five herbs per rank**. Naively adding all three quality ranks produces **10.5** per five-herb operation for four complete rank groups; the fifth partial assigned group already sums to **7.0**. The [October 22, 2022 beta analysis preserved by Wowhead](https://www.wowhead.com/news/crafting-work-orders-are-here-wowhead-economy-weekly-wrap-up-251-329620) instead reports **2–5 total pigments per mill**, with rank selected by effective skill. Its original Reddit post is deleted; count the reproduction as one derivative source, not independent corroboration. These are historical findings, not proof of current 2026 probabilities.

Reused [January 27, 2023 Hochenblume original study](https://www.reddit.com/r/woweconomy/comments/10me1e7): 1,500 R1 + 9,000 R2 purchased herbs, with 8,733 R2/R3 pigments total and 35% Resourcefulness. Because reagent refunds alter actual completed cast count, **do not use 8,733/10,500 as per-cast E** or invent quality-specific occurrence probabilities. Rank-3 herb lacks a comparable original cohort.

## Separate numeric mechanics — Midnight March 31 hotfix

**BLOCKED: 0 approved numerical coefficients.** [Blizzard's March 31, 2026 hotfix](https://worldofwarcraft.blizzard.com/en-us/news/24266320/hotfixes-march-9-2026) says gems are found more frequently in Midnight ore, without a multiplier. New original [prehotfix old-rate table](https://www.reddit.com/r/woweconomy/comments/1sfds1u/did_prospecting_change/) reports **21,000 ore across six named ore/rank columns** as rounded percentages; it is **one study**, not six independent studies. Item IDs, actual cast logs, exact profession context and a matched posthotfix cohort are missing. A separate [March 26 forum report](https://us.forums.blizzard.com/en/wow/t/prospecting-needs-buff/2280780) describes 40 attempts and eight unspecified gems, also unmapped. Both preserved in source-only note `research/evidence/observations/2026-10-28-0912-midnight-batch009-prehotfix-gem-table-SOURCE-ONLY.md`, not invented JSONL item mappings. Earlier same-author pre/post anecdotes remain unmatched.

The numeric candidate is **fail-closed** with null formula/parameters, empty unverified ID scope, no master review and `applyPolicy=BLOCKED`. Exact next experiment: same ore ID/rank, recipe, skill/spec/gear, patch/build, per-cast gem IDs/ranks including zero outcomes, saved reagent counts, and independent matched pre/post comparison.

## Field confidence, source reuse and QA

All **35** audited TSM rows have four **separate provisional worker scores below 70** (zero >=90, zero 70–89, zero complete records >=90). Shadowlands: P=25, min/max=25, E=45 (First Flower E=50); Dragonflight: P=15, min/max=25, E=20. These are conservative **current-applicability scores** for TSM five-herb rows; source-level historical mass-cast evidence remains preserved separately. Baseline inventory P=40, range=45, E=55; negative proposed field deltas reflect newly identified denominator/quality incompatibilities, not data deletion. Master owns final scoring and chart aggregation. Evidence confidence 0–100 measures **support strength, not statistical accuracy probability**.

**Source memory:** one newly analyzed original Jiyao study with six cohorts, two newly inspected original prehotfix leads, reused 2020 Shadowlands / 2022 First Flower / 2023 Hochenblume studies, and avoided duplicate [TSM string repost](https://www.reddit.com/r/woweconomy/comments/k1zd4o) explicitly derived from the 2020 original. A Wowhead 100k combined summary has unresolved ancestry and was not pooled. Unique worker-owned review events are in `research/coordination/source-reviews/loot-liquidator-midnight-2026-10-28-0912-midnight-batch009.jsonl`; no self-awarded QA points.

**Actually tested:** 35/35 exact source lines and assigned keys; 35/35 original NEVER_EXAMINED ledger statuses; 35/35 necessary historical TSM per-five arithmetic inequalities; six Jiyao observation structural checks; 310 cast-count sum; five Dragonflight rank-group anti-doublecount flags; blocked numeric formula; JSON/JSONL serialization. **Not executed:** full external JSON Schema validator, repository Node tests, in-game WoW tests or independent master QA.

**Master handoff:** [35-row audit](https://github.com/Voodoobrew101/Loot-Liquidator/blob/research/processing-confidence/research/coordination/submissions/loot-liquidator-midnight/2026-10-28-0912-midnight-batch009-35key-synthesis-audit.csv), validation JSON, numeric candidate, chart-data JSON and this report. Central master baseline was **1,193 examined / 544 never-examined of 1,737** before this pending submission; do not subtract 35 until accepted. Zero verified current-Retail output corrections, zero verified numeric rules, zero production edits. Next: master acceptance, then explicitly assigned disjoint keys; controlled 20-vs-5 herb milling and zero-inclusive DF quality experiments; matched Midnight pre/post prospecting. No queue, master PROGRESS, ledger, addon Lua/TOC, main, merge, release or schedule modified.
