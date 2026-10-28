## Research-only batch 010 — queue revision 12
**Branch:** `research/processing-confidence`; assigned exact keys: **35** (20 BfA milling historical TSM source rows, 15 Dragonflight supplemental prospecting outputs). This worker obeyed the cross-expansion overflow assignment rather than default Midnight scope.

**Results:** 35/35 exact unique first-pass targets audited; 140 provisional material-field scores (all <70); **0** complete >=90 records; **0** current-Retail numeric corrections; **0** approved numeric rules. Submit for master acceptance only. Master-accepted baseline before this submission: 1343/1737 first-pass, 394 never examined, 0 all-four-field >=90. These 35 are NOT added to master baseline until accepted.

### Independent historical source synthesis
1. **BfA original Jiyao mass milling:** updated seven-herb table totals **694 explicitly reported 20-herb mass casts**, with rounded per-cast means. This is ONE study; an earlier Riverbud 39-cast snapshot overlaps the updated 44-cast Riverbud row. Original https://www.wowhead.com/item=153669/viridescent-pigment ; recipe verification examples https://www.wowhead.com/spell=256223/mass-mill-sea-stalk and https://www.wowhead.com/spell=256218/mass-mill-star-moss . Original means are NOT raw integer totals, no per-cast hit histograms, no current 2026 patch bridge.
2. **BfA original Baadkitty:** independently reports 200 herbs of each of seven BfA herbs and exact three-pigment totals (1,400 herbs total). Actual completed 5/20-herb cast counts and character skill unreported; do not convert five-herb-equivalent into measured casts. Original same Wowhead page, distinct author/comment.
3. **BfA Kidneph:** original six 1000-herb cohorts (6,000 herbs) already archived in `research/evidence/observations/2026-10-28-legacy-milling-batch01.jsonl`; REUSED, not new study or new independent observations. Original same Wowhead page.
4. **DF original superbondez:** 400 Prismatic Ore, **80 actual five-ore prospects**; reported exact rank-specific counts and 119 Crumbled Stone / 108 Fractured Glass / 6 diamonds total (ranks 1/2/3). **Eternity Amber rank-1/rank-2 text is corrupted**; no fabricated values or complete family sum. Source https://www.wowhead.com/item=194545/prismatic-ore . Historical 6/80=**0.075 Illimited Diamonds per actual prospect across all ranks**, close to historical family-level TSM proxy **0.070**; Q1 alone is **1/80=0.0125**. Do NOT value three TSM rank-alternative rows as simultaneous output or compare Q1-only to family E.
5. **DF original Crumbled Stone:** LavingRunatic 60 actual five-stone casts -> 55 Eternity Amber, 5 Nozdorite, 11 returned Crumbled Stone; ranks unreported. Mgnta 3,125 reported stone with 564 rank-2 Amber, 65 rank-2 Nozdorite, 160 stone and 16% Resourcefulness; **625 derived five-stone equivalents are NOT actual completed casts**. Neither can validate assigned rank-1 outputs. Source https://www.wowhead.com/item=192880/crumbled-stone .

### BfA Viridescent comparisons (five-herb equivalent, NOT measured five-herb casts)
| Herb | Jiyao 20-herb mass casts | Jiyao E5 equivalent | Baadkitty E5 equivalent | Kidneph E5 equivalent |
|---|---:|---:|---:|---:|
| Akunda's Bite | 19 | 0.5275 | 0.6500 | 0.7500 |
| Anchor Weed | 20 | 1.9625 | 1.6000 | not sampled |
| Riverbud | 44 | 0.5125 | 0.5000 | 0.6800 |
| Sea Stalk | 106 | 0.6425 | 0.4500 | 0.5900 |
| Siren's Pollen | 103 | 0.5300 | 0.7500 | 0.5750 |
| Star Moss | 177 | 0.7175 | 0.4250 | 0.4550 |
| Winter's Kiss | 225 | 0.7600 | 0.6500 | 0.6400 |

Different original authors show genuine differences, particularly Star Moss (Jiyao 0.7175 vs Baadkitty 0.4250 vs Kidneph 0.4550) and Anchor Weed (Jiyao 1.9625 vs Baadkitty 1.6000). This is not a verified time/skill effect. An original commenter reported Viridescent output rising after reaching BfA Inscription 150, but no matched cast-level skill experiment permits a numerical coefficient.

### Dragonflight Prismatic Ore rank-family comparison
| Family | Original 80-cast total across ranks | E per actual cast across ranks |
|---|---:|---:|
| Queen's Ruby | 31 | 0.3875 |
| Mystic Sapphire | 27 | 0.3375 |
| Vibrant Emerald | 34 | 0.4250 |
| Sundered Onyx | 24 | 0.3000 |
| Alexstraszite | 68 | 0.8500 |
| Malygite | 62 | 0.7750 |
| Neltharite | 48 | 0.6000 |
| Ysemerald | 56 | 0.7000 |
| Nozdorite | 59 | 0.7375 |
| Illimited Diamond | 6 | 0.0750 |
Eternity Amber rank 1/2 totals excluded because source string is corrupted. Original reported Silken Gemdust, Khaz'gorite and Prismatic Ore outputs are archived as **unassigned source-only leads**, not credited as additional first-pass keys.

### Numeric mechanics (separate from 35 item keys)
Hypothesis `midnight-gem-hotfix-2026-03-31-quantification`: **BLOCKED**. Blizzard's March 31, 2026 note states gems became more frequent when prospecting Midnight ore (https://worldofwarcraft.blizzard.com/en-gb/news/24266320/), but does NOT quantify gem-specific rates. Earlier 21,000-ore pre-hotfix historical source remains unpaired with same ore/rank/skill/recipe post-hotfix zero-inclusive cast observations. **No multiplier, quality unlock, or formula approved.** Required next experiment: matched pre/post same-build-era recipe/rank/skill/spec/gear, output ID/rank and actual cast-level zeros, or independently quantified source bridge.

### Confidence, QA, and source-memory
Field scoring is research-proposed evidence support 0–100, NOT percent chance of accuracy. Assigned 35 records: P/min/max/E each 35 scores below 70; record-wide >=90 zero. See audit CSV for individual proposed scores and prior source-score deltas (NOT master-approved changes). Original source families newly recovered: **4** (Baadkitty, superbondez, LavingRunatic, Mgnta). Reused: **2** (Jiyao, Kidneph). Seven source-review events preserve source ancestry and gaps; one Blizzard official qualitative reuse. No duplicate independent-count inflation.

**Validation:** 18 local deterministic JS assertions passed; canonical required-key structural checks passed. Full external JSON Schema validation, repository Node test suites and WoW in-client testing were NOT executed. No production Lua/TOC, master assignments, master PROGRESS, central ledgers, registry or schedule edited.

### Exact next targets
- Master independently accept/reject these exact 35 stable keys; flag source rank-family versus rank-specific semantics.
- Obtain original superbondez comment text for corrupted Eternity Amber rank 1/2 counts; never infer 8/42 from broken rendering without corroboration.
- 2026 Retail five-herb BfA milling and DF Prismatic/Crumbled Stone casts with exact output ranks, zero-inclusive histograms, skill/spec/gear and saved inputs.
- March 31 Midnight prospecting pre/post controlled cohort to resolve the separate blocked numeric hypothesis.

### Worker files
- `research/evidence/observations/2026-10-28-1008-midnight-batch010-original-bfa-df-cohorts.jsonl` (17 canonical-format observation objects)
- `research/coordination/submissions/loot-liquidator-midnight/2026-10-28-1008-midnight-batch010-35key-synthesis-audit.csv`
- `research/coordination/submissions/loot-liquidator-midnight/2026-10-28-1008-midnight-batch010-report.md`
- `research/coordination/submissions/loot-liquidator-midnight/2026-10-28-1008-midnight-batch010-midnight-hotfix-numeric-candidate.json`
- `research/coordination/submissions/loot-liquidator-midnight/2026-10-28-1008-midnight-batch010-validation.json`
- `research/coordination/submissions/loot-liquidator-midnight/2026-10-28-1008-midnight-batch010-chart-data.json`
- `research/coordination/source-reviews/loot-liquidator-midnight-2026-10-28-1008-batch010.jsonl`

**Safety:** immutable additive research-only files; no main merge or production modifications.
