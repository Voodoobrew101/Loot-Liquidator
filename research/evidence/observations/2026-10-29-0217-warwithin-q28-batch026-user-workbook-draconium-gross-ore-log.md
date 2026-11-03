# Dragonflight Draconium original-log candidate: user-supplied workbook (research only)

**Audit date:** 2026-10-29. **Source:** user-attached `Prospecting Calculator V1.xlsx`, sheet `Prospecting Log`, rows 28, 52–56, 58, 60, 62–67; local source SHA-256 `847caa75c43c1227a29eb0939c80cc0d077c997c3321d3bd76dc640a519bb4ca`. **Study dates:** Excel serial timestamps correspond to 2023-01-03 through 2023-02-06. This is a **historical Dragonflight log**, not a 2026 Retail measurement. Authorship/independence from the 2022-12-31 Reddit prospecting author is unverified; do **not** count the workbook and that post as independent cohorts until lineage is established.

## Primary sheet fields
`Ore Type`, `Quality`, `Quantity` (gross ore reported), `Epic Q1`, `Epic Q2`, `Epic Q3`, `Skill`, `Inspiration`, `Resourcefulness`, `Datetime`. `Ore Refund` column is blank on all 14 Draconium rows. The sheet does **not** contain completed-cast counts, zero-inclusive cast histograms, per-cast yields, or explicit refunded ore totals.

| Excel row | Ore rank | Gross ore | Illimited Q1 | Illimited Q2 | Illimited Q3 | Effective skill | Inspiration | Resourcefulness |
|---:|---|---:|---:|---:|---:|---:|---:|---:|
| 28 | Q2 | 8,543 | 0 | 15 | 9 | 237 | 33.9% | 5.1% |
| 52 | Q2 | 15,000 | 1 | 39 | 10 | 248 | 34.8% | 13.3% |
| 53 | Q3 | 10,000 | 0 | 2 | 37 | 281 | 19.8% | 30.6% |
| 54 | Q2 | 13,000 | 1 | 21 | 20 | 248 | 36.8% | 13.3% |
| 55 | Q2 | 21,000 | 2 | 37 | 22 | 249 | 34.8% | 13.3% |
| 56 | Q3 | 22,000 | 1 | 1 | 82 | 282 | 19.8% | 30.6% |
| 58 | Q3 | 10,000 | 0 | 1 | 37 | 283 | 19.8% | 30.6% |
| 60 | Q3 | 15,000 | 1 | 2 | 60 | 283 | 19.8% | 30.6% |
| 62 | Q2 | 13,000 | 0 | 26 | 19 | 250 | 36.8% | 13.3% |
| 63 | Q3 | 30,000 | 1 | 3 | 127 | 283 | 19.8% | 30.6% |
| 64 | Q3 | 14,000 | 1 | 0 | 48 | 283 | 19.8% | 30.6% |
| 65 | Q3 | 30,000 | 0 | 1 | 109 | 283 | 19.8% | 30.6% |
| 66 | Q3 | 19,000 | 0 | 0 | 78 | 283 | 19.8% | 30.6% |
| 67 | Q3 | 20,000 | 0 | 0 | 72 | 283 | 19.8% | 30.6% |
| **Q2 sum (5 rows)** | Q2 | **70,543** | **4** | **138** | **80** | 237–250 | 33.9–36.8% | 5.1–13.3% |
| **Q3 sum (9 rows)** | Q3 | **170,000** | **4** | **10** | **650** | 281–283 | 19.8% | 30.6% |
| **All (14 rows)** | mixed | **240,543** | **8** | **148** | **730** | mixed | mixed | mixed |

All 14 rows pass independent within-row epic-total, green-gem-total, and blue-gem-total arithmetic checks (0 mismatches). The sheet's `Start Here` lists Illimited Diamond Q1/Q2/Q3 separately; the sheet does not distinguish which individual cast generated a diamond.

## Explicit non-E comparison — **do not compile**
For research comparison only, Q2 gross-ore-equivalent Q1 diamonds = `4 / 70543 * 5 = 0.000283515`; Q3 = `4 / 170000 * 5 = 0.000117647`. These are **per five gross ore proxy units**, NOT per actual completed prospecting cast, NOT `expectedQuantity`, and NOT a P(hit). Resourcefulness, the original cast denominator, patch/skill bridge, and within-cast multiplicity are unresolved. The existing historical TSM `192869` rank-1 candidate is `0.014` per five-input operation, nominally ~49×/119× higher than these historical proxies; the comparison is not controlled and is **not evidence of a current 49×/119× pricing error**. Do not use either side for 2026 gold EV.

Source identity references: https://www.wowhead.com/item=192869/illimited-diamond ; Dragon Isles Prospecting https://www.wowhead.com/spell=374627/dragon-isles-prospecting (five ores per operation); user-linked original discussion https://www.reddit.com/r/woweconomy/comments/zzyjzu/results_from_prospecting_large_quantities_of/ . That Reddit post may share a lineage with this workbook, so **no independent corroboration credit** is asserted.

## Previously archived Crumbled Stone evidence (reused, no new study)
https://www.wowhead.com/item=192880/crumbled-stone : LavingRunatic describes **60 actual completed prospects** of five stones each, 55 Eternity Amber, 5 Nozdorite, 11 returned stones, but no output rank. Mgnta describes 3,125 stones with 16% Resourcefulness and totals, without actual cast count. These are two distinct authors already indexed in source-memory; no new credit. Neither permits mapping a measured rate to exact `192849` or `192866` quality-specific economic E.

**Outcome:** New auditable historical user-file row-level evidence, 0 verified current Retail `expectedQuantity`, 0 new exact-rank P(hit), 0 defensible exact-rank tooltip bounds. Master should keep all economic fields unknown pending actual current-client completed-cast logs with output item IDs, skill, spec, refunds, and zero-inclusive histograms.
