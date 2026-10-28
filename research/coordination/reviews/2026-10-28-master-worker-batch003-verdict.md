# Master QA — batch003 and parallel numeric mechanics (2026-10-28)

Research branch reviewed at `1491887680fe8e9051ee45894dfc350077f4c423`. Production GameData blob remains `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`. No main, TOC or addon changes.

| Worker | New accepted | Cumulative | Material rows | Next assignment |
|---|---:|---:|---:|---|
| Midnight | 35 | 104 | 27 | 35 Dragonflight |
| War Within | 35 | 104 | 25 | 6 TWW DE + 29 Dragonflight |
| Dragonflight | 40 | 116 | 40 | 40 Dragonflight |
| Legacy | 40 | 100 | 38 | 40 Legacy |
| **Total** | **150** | **424** | **130** | **150 disjoint keys** |

**Independent QA:** 1036 in-memory JavaScript assertions passed before commit. Verified all assigned keys unique and previously NEVER_EXAMINED; all source line/ID mappings; four field scores and weakest-field logic; 13 TWW historical means from 100 ore (20 five-ore equivalents, not proven 20 actual casts); 7 Osmenite PTR means from 8000 casts, six colored totals sum to 8000; 29 Dragonflight and 4 Midnight historical TSM P×conditional-yield bounds; 14 historical JSONL objects' required structure. This is **not** an actual execution of repository Node suites or external full JSON Schema validation. No WoW client testing.

Original sources independently cross-checked: [TWW PeaEsk study and five-ore recipe](https://www.wowhead.com/spell=434018/algari-prospecting); [Jan 2023 8000 R3 Serevite casts and 2650 saved ore](https://www.reddit.com/r/woweconomy/comments/108782r); [Dec 2022 1000 R2 Serevite casts, 132/1000 = 13.2% typo](https://www.reddit.com/r/woweconomy/comments/zkay8v); [Osmenite PTR 8000-cast study](https://www.wowhead.com/item=168185/osmenite-ore); [standard Felslate five ore](https://warcraft.wiki.gg/wiki/Prospect); [Mass Felslate 225904 twenty ore and unlabeled 113-cast outputs](https://www.wowhead.com/spell=225904/mass-prospect-felslate).

**Coverage:** 1737 stable records, 478 first-pass examined = 465 insufficient + 13 blocked, 1259 never examined; zero current Retail numeric corrections, zero records independently >=90. Independently scored 394 material output records ×4 = 1576 field scores: **>=90 0; 70–89 17; <70 1559**. New 14 medium scores apply to historical expectedQuantity only, not complete current Retail evidence. Potential source/overlay field slots 5392 tracked separately; nonprocessing GameData inventory incomplete. No current-Retail transformation proved.

**Numerical mechanics separate from item coverage:** VERIFIED_NUMERIC **0**, approved EMPIRICAL **0**, BLOCKED for compilation **4**. Legacy explicitly submitted one hypothesis: standard Felslate 5 vs mass spell 225904 20 is independently confirmed as a recipe distinction, but the 113 mass-cast outputs are unlabeled and no matched standard cohort exists, so no 4× yield or other coefficient is approved. Midnight hotfix 2026-03-31 lacks matched pre/post; TWW Resourcefulness lacks per-cast input-savings cohorts; Dragonflight Inspiration lacks controlled gem-rank transition histograms. No output unlock, patch factor, universal slope or conversion of saved inputs to output quantity accepted. Three workers have not yet supplied controlled numeric candidate reports. Required experiments in assignments.json#mechanicsTrack. `test_numeric_rules.js`, `test_mechanics_compiler.js` and `itemdb.schema.json` were inspected but **not executed under Node**. No compilation approval.

**Rolling 3 master cycles:** 140, 134, 150 unique records (mean 141.33). 1259/141.33 ≈ **8.91**, about **9 hourly cycles / 0.38 days** for current first-pass inventory only, not the >=90 completion gate. First-pass inventory excludes unenumerated nonprocessing records. Next targets are 6 TWW DE brackets, high-value Dragonflight rank-specific ore/gem outputs, then Legacy TSM unit issues. All-verifiable-fields >=90 gate **NOT MET**.
