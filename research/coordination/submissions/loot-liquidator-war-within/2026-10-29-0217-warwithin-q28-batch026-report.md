# War Within worker — q28 batch026 Dragonflight overflow audit

**2026-10-29; research-only; assignment `2026-10-29-batch026-war_within`; queue revision 28.** Read live assignments, source-memory, research-lessons, Master batch025 verdict, current itemdb v0.7.1 schema/build report, 2026-10-29 Dragonflight q27 reviews, and pinned GameData source. Master explicitly assigned this worker **20 disjoint Dragonflight missing-E keys** as overflow. Do not claim home-expansion keys or another worker's assignments.

## P0 / P1 exact scope and findings
- **20/20 exact assigned keys audited**, all still missing `expectedQuantity`; 3 Draconium→Illimited Diamond R1, 2 Crumbled Stone→gem quality-specific records, 15 Dragonflight herb→pigment quality-specific records.
- **15/15 TSM GameData source line + parent input + output item ID independently matched** in `main/GameData.lua`; the other five are existing research-curated Dragonflight mappings and are not incorrectly claimed as GameData line identities.
- **0 new legitimate material mappings**, **0 corrected mapping IDs**, **0 verified 2026 economic numeric fields**, **0 new exact-rank tooltip probability/yield fields**. Exact current-context four-field unknowns: **80/80** (not numeric zeros). Historical TSM proxy fields are preserved separately from economic-ready fields in the attached audit.
- New useful source candidate: user-supplied **`Prospecting Calculator V1.xlsx`** contains 14 dated 2023 Draconium aggregate log rows (240,543 gross ore, 8 Q1 + 148 Q2 + 730 Q3 Illimited Diamonds); 5 Q2 rows and 9 Q3 rows, with recorded skill, Inspiration, and Resourcefulness. All 14 within-row gem-total arithmetic checks pass. **This is a newly inspected workbook, not proof of a new independent author** relative to the user's linked 2022 Reddit post.
- Q2 ore: 70,543 gross, 4 Q1 diamonds, skill 237–250; Q3 ore: 170,000 gross, 4 Q1 diamonds, skill 281–283. Ore refund quantity and completed cast count are missing. **Never substitute gross ore / 5 for completed casts**, and do not derive P(hit), economic E, or tooltip P from these aggregate counts.
- Q1 Draconium `189143` is absent from the workbook; no applicable Q1-ore sample.
- Crumbled Stone LavingRunatic/Mgnta studies **already exist in source-memory**; reused rather than re-fetched for novelty. 60-cast author lacks output quality ranks, so no exact rank-specific `192849` / `192866` values.
- 15 milling rows are TSM **rank-alternative** profiles with `matRate=1` for all R1/R2/R3 outputs and nominal 2–5 family yield; these do not imply simultaneous 100% probability for all three ranks. No zero-inclusive output-rank cast histogram or skill-matched E. The 2023 Method herb→pigment family identities are qualitative only.

## P2 TSM decision-risk
Existing `GameData.lua` TSM-derived Illimited R1 candidate `0.014` per 5 ore conflicts sharply with the historical workbook's **gross-ore-equivalent** Q1 diamond proxies (`0.000283515` Q2, `0.000117647` Q3). Apparent ~49×/~119× ratios are **uncontrolled comparisons, not current-Retail correction factors**. Source TSM P/E/range also flagged `INCONSISTENT_P_RANGE_EV` in ledger. This is a high-priority economic validation risk, not a demonstrated 2026 auction-vs-prospecting flip. The rank-summed milling alternative would also risk up to triple-counting the same pigment family; no current gold flip was priced.

## Provenance / QA / efficiency
- Source workbook local SHA-256 `847caa75c43c1227a29eb0939c80cc0d077c997c3321d3bd76dc640a519bb4ca`, sheet `Prospecting Log`, rows 28/52–56/58/60/62–67; dates 2023-01-03 to 2023-02-06. Original workbook author and independence not verified. Historical player source https://www.reddit.com/r/woweconomy/comments/zzyjzu/results_from_prospecting_large_quantities_of/ is a possible shared lineage; no double credit.
- Source-memory already indexed Crumbled Stone 60-cast and 3,125-gross-stone authors; avoided duplicate source promotion and re-fetch. Method 2023 mapping reused. Source reviews include novel workbook inspection, reused Crumbled Stone, and reused Method/TSM identity.
- 20 unique stable keys, no duplicate; no negative counts, P outside [0,1], or fabricated zeros. Workbook row subtotal invariants 14/14. No tooltip-only field is economic eligible. No changes to main, production Lua/TOC, shared assignments/ledgers, canonical registry, or source-memory.
- Research output: **1 useful previously unindexed local workbook lineage candidate, 14 validated historical log rows, 0 current accepted-value yields**, one high-impact TSM discrepancy flag, 0 redundant old-source claims.

## Next exact targets for Master QA
1. `dragonflight:188658:192869:10` and `dragonflight:190311:192869:10`: obtain actual **2026 completed casts**, explicit output IDs and per-cast histograms, rank/skill/spec, Resourcefulness refunds; check historical TSM mismatch.
2. `dragonflight:189143:192869:10`: obtain rank-1 Draconium cohort; workbook has none.
3. `dragonflight:192880:192849:0` and `dragonflight:192880:192866:1`: obtain **output quality rank** from 60-cast source or new current-client per-cast logs.
4. `tsm:mill:191461:198423:L1942`, `tsm:mill:191462:198421:L1945`, `tsm:mill:191464:198418:L1950`, `tsm:mill:191467:198412:L1965`: prioritize four herb-family/skill strata with exact R1/R2/R3 counts before filling the remaining assigned 15 rank-specific E cells.

**Research-only deliverables:** `research/coordination/submissions/loot-liquidator-war-within/2026-10-29-0217-warwithin-q28-batch026-20key-fourfield-audit.jsonl`, `research/evidence/observations/2026-10-29-0217-warwithin-q28-batch026-user-workbook-draconium-gross-ore-log.md`, and `research/coordination/source-reviews/loot-liquidator-war-within-2026-10-29-0217-warwithin-q28-batch026.jsonl`. Master alone may compile staged itemdb.lua. No schedule changes.
