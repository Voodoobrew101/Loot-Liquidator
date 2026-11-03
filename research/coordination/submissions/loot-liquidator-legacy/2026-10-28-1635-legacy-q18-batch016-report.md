# Loot Liquidator Legacy — Batch016, queue revision 18
2026-10-28 · research/processing-confidence · worker-owned additive files only

## Assignment and actual output
- Read live master assignment `2026-10-28-batch016-legacy`, queue revision **18**; audited **40/40 exact disjoint keys**. **31** previously audited historical prospecting records reused without duplicate research; **9** newly assigned compiled milling records (6 WoD Cerulean, 3 BfA Riverbud pigments) checked against exact GameData.lua lines. Source line identity checks **9/9**.
- **0 new legitimate conversion mappings; 0 new current-Retail measured P/E/ranges; 0 numeric promotions into canonical database.** This is an evidence and decision-risk audit, not a completion claim.
- Field slots: **34 historical/provisional populated** of 160; **126 unknown**. Breakdown: P=0, min=0, max=0, E=34. All current-Retail exact-context baselines remain unverified.
- Newly indexed **one original independent historical Titanium source** (Almar) with raw 121 powder and six assigned uncommon-gem totals. Its ore count, completed casts and patch are absent: **no denominator, no normalized rate**. Source was absent from source-memory at read time.

## P0 — Six WoD Cerulean rows: mass-mill denominator guard
Original commenter 516803 on [Mass Mill Nagrand Arrowbloom](https://www.wowhead.com/spell=190385/mass-mill-nagrand-arrowbloom) reports about 2,000 of each herb and six pigment totals. Same original source already archived as WOD-516803-2000-EACH; no independent-source credit this run. [Mass Mill Frostweed](https://www.wowhead.com/spell=190381/mass-mill-frostweed) uses **20 herbs**, whereas compiled GameData entries are nominal **5-herb** profiles. The figures below are **historical gross-herb equivalents**, NOT verified outcomes per standard five-herb cast:

| Input ID / herb | Original pigment total | Nominal E per five herbs (already in GameData) |
|---|---:|---:|
| 109124 Frostweed | 848 | 2.1200 |
| 109125 Fireweed | 842 | 2.1050 |
| 109126 Gorgrond Flytrap | 833 | 2.0825 |
| 109127 Starflower | 845 | 2.1125 |
| 109128 Nagrand Arrowbloom | 843 | 2.1075 |
| 109129 Talador Orchid | 843 | 2.1075 |

All six source `chance=0.917915001` entries are historical/Poisson proxies, not observed P(hit); positive min/max and actual standard-cast E unknown. Recipe learned-state and current Retail eligibility still require verification. Do not multiply E by P.

## P0/P2 — Riverbud three-output historical reference disagreement
[Original Jiyao revised table](https://www.wowhead.com/item=153669/viridescent-pigment) reports **44 Mass Mill Riverbud operations** with average output **16.16 Ultramarine, 6.91 Crimson, 2.05 Viridescent per 20-herb operation**. [Mass Mill Riverbud](https://www.wowhead.com/spell=256217/mass-mill-riverbud) requires **20 Riverbud**, learned at BfA Inscription 50. Historical compiled 5-herb values disagree with the later source snapshot:

| Output ID | GameData nominal E5 | Jiyao revised mean /4 (comparison only) | Relative difference |
|---|---:|---:|---:|
| 153635 Ultramarine | 4.0208 | 4.0400 | 0.48% |
| 153636 Crimson | 1.5083 | 1.7275 | 14.53% |
| 153669 Viridescent | 0.6500 | 0.5125 | -21.15% |

Jiyao's earlier **39-cast** Riverbud snapshot on the recipe page and later **44-cast** revision on the pigment page are the SAME author/cohort, not independent studies. Other original authors Baadkitty (200 herbs) and Kidneph (1,000 herbs) are independent, already archived. The compiled 0.56540179 `chance` repeated for all three outputs is not a measured occurrence probability. Source revisions, 20-versus-5 recipe units, and reported profession-skill effects prohibit directly replacing current Retail per-cast expected quantities. **Decision risk:** Crimson and Viridescent differences may change optimal liquidation, but no live prices or action flip are claimed.

## P0 — New independent historical Titanium raw aggregate (source only)
[Almar's first-person Titanium prospecting account](https://almarsguides.com/wow/farming/wotlk/otherlocations/Prospecting/) preserves **121 Titanium Powder** and exact six assigned uncommon gem totals: Bloodstone 35, Sun Crystal 40, Chalcedony 39, Shadow Crystal 40, Huge Citrine 45, Dark Jade 36. It also reports 11 other named gem totals, preserved without self-claiming their keys. The former video was removed; its written itemized results remain.
**Critical negative result:** no original ore input count, completed casts, zeros, skill or patch. Therefore none of these raw totals can supply P, positive yield bounds or unconditional per-cast E. This is an independent source, NOT independent measured current Retail numeric evidence. Do not assume the author's "stack" was 1,000 ore or 200 casts. It is distinct from archived globalmenace, 2022 Reddit and ZeRoTaCtIcS sources.

## P1/P2 — Assigned 31 prospecting records
- 36910→46849 powder: preserve original 12.0.5 143/1,000 gross-ore E5=.715 as historical provisional, not actual cast E; original 2022 152/1,000 is already archived.
- Felslate 123919→130178–130183: six reused historical source tuples; original mass/prospect skill cohorts differ, no current Retail transfer.
- Cobalt 36909 and Titanium 36910 → six uncommon gems each: twelve historical TSM source tuples contain incompatible P=.235, [1,2], nominal E=2.5. Since P×max=.47, source tuple fails; quarantine P, do not invent bounds.
- Black/White Trillium 72094/72103 → six assigned gems each: twelve historical TSM source tuples contain P=.16, positive [1,1], E=.1705; P×max=.16. Preserve contradictory source data, P unknown; no zero-filled repair.
- None of these 31 records gained a new valid output mapping or 2026 matched cast study. All original numeric source values and ancestry remain in the audit.

## Source review / quality improvement
- **New:** Almar raw original Titanium source; original totals captured once, numeric fields blocked by absent denominator.
- **Reused without refetch inflation:** WOD-516803, Jiyao revised, Baadkitty, Kidneph, ZeRoTaCtIcS, globalmenace, 2022 Titanium Reddit and TSM-derived tuples. Jiyao's older and newer table versions count as one author study.
- **Negative conclusion:** 20-herb mass milling is not automatically a standard 5-herb cast; a ratio of gross herbs is only a comparison basis. Exact per-operation reagent units and learned recipes matter.
- **Prior QA applied:** batch015 master rejected automatic historical-to-current promotion; no mandatory unrelated mechanics audit; no rewards assigned; reward never modifies evidence confidence.
- **Next IDs:** `36910→46849` (current Retail powder cast histogram), `36909/36910→36917,36920,36923,36926,36929,36932` (matched cast histograms), `72094/72103→76130,76133,76134,76135,76136,76137` (matched cast histograms), `109124–109129→114931` (mass versus standard mill and actual casts), `152505→153635/153636/153669` (2026 five-herb/mass cast and skill stratification). All remain master-owned assignment scope.

**Pre-review master baseline:** 994 provisional mappings / 167 inputs, 801 four-field complete, 435 unknown numeric cells, zero independently verified current-Retail unskilled baselines. This run does not change master totals. No production, main, master ledgers, source-memory cache, canonical registry or schedule touched.
