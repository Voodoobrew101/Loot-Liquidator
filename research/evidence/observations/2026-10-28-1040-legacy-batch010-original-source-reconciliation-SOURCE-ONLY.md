# 2026-10-28-1040-legacy-batch010: original-source reconciliation, SOURCE-ONLY, not a new independent study

**Study lineage:** Original Wowhead commenter 180977, one 2008 PTR author across multiple pigment pages; prior original observations already exist under `research/evidence/observations/` and source-memory study `wowhead-180977-2008-ptr-milling-histograms`. This file rechecks arithmetic and 16 assigned TSM milling profiles; it does **not** create 16 new independent experiments, new cast logs, or 2026 Retail coefficients. Original comments: [Alabaster](https://www.wowhead.com/mop-classic/item=39151/alabaster-pigment), [Dusky](https://www.wowhead.com/mop-classic/item=39334/dusky-pigment), [Golden](https://www.wowhead.com/mop-classic/item=39338/golden-pigment), [Emerald](https://www.wowhead.com/mop-classic/item=39339/emerald-pigment), [Violet](https://www.wowhead.com/mop-classic/item=39340/violet-pigment).

Each historical mean below = sum(quantity * histogram count) / sum(histogram count). TSM comparison = 5 * historical `amountOfMats` (source's per-input units), not a patch-matched modern correction. Histogram entries are **reported positive operations**, not an independent audit of zero operations.

| Herb (ID) | Histogram entries | Pigment units | PTR units/reported operation | TSM units/5 herbs | PTR minus TSM |
|---|---:|---:|---:|---:|---:|
| Peacebloom (`2447`) | 78 | 193 | 2.4744 | 2.8900 | -0.4156 |
| Silverleaf (`765`) | 48 | 114 | 2.3750 | 2.8900 | -0.5150 |
| Earthroot (`2449`) | 29 | 76 | 2.6207 | 3.0000 | -0.3793 |
| Bruiseweed (`2453`) | 26 | 73 | 2.8077 | 3.0000 | -0.1923 |
| Swiftthistle (`2452`) | 20 | 47 | 2.3500 | 2.9275 | -0.5775 |
| Mageroyal (`785`) | 46 | 118 | 2.5652 | 2.8300 | -0.2648 |
| Briarthorn (`2450`) | 26 | 65 | 2.5000 | 2.8825 | -0.3825 |
| Kingsblood (`3356`) | 33 | 103 | 3.1212 | 3.0000 | +0.1212 |
| Liferoot (`3357`) | 18 | 55 | 3.0556 | 3.0000 | +0.0556 |
| Wild Steelbloom (`3355`) | 20 | 52 | 2.6000 | 2.8825 | -0.2825 |
| Fadeleaf (`3818`) | 9 | 23 | 2.5556 | 2.5000 | +0.0556 |
| Goldthorn (`3819`) | 26 | 66 | 2.5385 | 2.8600 | -0.3215 |
| Khadgar's Whisker (`3358`) | 22 | 78 | 3.5455 | 2.8600 | +0.6855 |
| Gromsblood (`8846`) | 6 | 20 | 3.3333 | 3.0000 | +0.3333 |
| Purple Lotus (`8831`) | 21 | 52 | 2.4762 | 2.8750 | -0.3988 |
| Sungrass (`8838`) | 21 | 49 | 2.3333 | 2.8750 | -0.5417 |

**Concrete contradiction — Earthroot `2449`:** Original commenter lists `11×2 + 18×3` = **29 positive histogram entries / 76 pigment units**, but also reports **12 full stacks**, implying **240 herbs / 5 = 48 five-herb equivalents**. Thus **19 operations are unaccounted for if stacks are complete**; they must NOT be fabricated as zero-pigment casts. Author's stated mean **3.1** does not equal 76/29 (**2.6207**) or 76/48 (**1.5833**). Flag `OBSERVATION_NEEDS_CLARIFICATION`; preserve raw counts and do not promote occurrence probability or current-Retail expectedQuantity.

**Other caveat:** Source `Sungrass` rare-pigment total includes a two-unit proc; rare total units do not establish rare-hit operation count. Other rare pigment totals also lack hit counts. The PTR build and profession skill were not reported, and 2008 PTR is not 2026 Retail.

## Independent original historical Outland cohort reused — Kaliope (2008)

Original [Kaliope table](https://kaliope.wordpress.com/2008/10/09/inscription-a-look-at-pigment-drop-rates-for-milling/) reports input herb quantities and common/rare pigment totals. The five assigned herb comparisons below are descriptive **per five-herb equivalents**, not independently reported completed casts. All five are from **one author/study**, not five independent studies.

| Herb | Herbs reported | Five-herb equivalents | Nether pigment per equivalent / TSM | Ebon pigment per equivalent / TSM |
|---|---:|---:|---:|---:|
| Felweed (`22785`) | 170 | 34 derived | 2.3824 / 2.8000 | 0.3235 / 0.4375 |
| Ragveil (`22787`) | 60 | 12 derived | 2.6667 / 2.8000 | 0.5000 / 0.4375 |
| Ancient Lichen (`22790`) | 120 | 24 derived | 3.0000 / 3.0000 | 0.5833 / 0.5375 |
| Netherbloom (`22791`) | 80 | 16 derived | 2.7500 / 3.0000 | 0.7500 / 0.5375 |
| Nightmare Vine (`22792`) | 100 | 20 derived | 2.8000 / 3.0000 | 0.7000 / 0.5375 |

**Evidence classification:** historical original aggregates, patch/context incomplete, source observation unchallenged except explicit Earthroot arithmetic discrepancy; 0 current-Retail verified field promotions. No min/max, P(hit) or neutral unskilled baseline is inferred for Kaliope from these totals.
