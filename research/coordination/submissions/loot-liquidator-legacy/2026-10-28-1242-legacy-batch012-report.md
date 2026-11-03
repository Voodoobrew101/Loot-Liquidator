# Loot Liquidator Legacy — Batch012 P0 material-coverage submission
**Run:** 2026-10-28-1242-legacy-batch012; **branch:** `research/processing-confidence`; **master queue:** revision 14, assignment `2026-10-28-batch012-legacy`. **Queue blob:** `3e957fb2fdb8bf8fdc2fb4c5f928ba3b28d690f6`; **ledger blob:** `3e2bb784dc832d90584eebd8620148caf2133fbd`; **production GameData blob (read only):** `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`. Research-only, no production or master writes.

## Highest-priority P0: legitimate Titanium Powder conversion absent
**NEW UNASSIGNED mapping candidate for master, NOT claimed as an assigned first-pass record:** `Titanium Ore 36910 --Prospect 5 ore--> Titanium Powder 46849`. `46849` occurs **zero** times in current main `GameData.lua`, `StatYieldProfiles.lua`, `ConversionEngine.lua`, the processing/supplemental source ledgers and the generated research `itemdb.lua` (six separately checked files). Original [Titanium Powder Retail item page](https://www.wowhead.com/item=46849/titanium-powder) explicitly lists Titanium Ore as its prospect source; [Titanium Ore reference](https://warcraft.wiki.gg/wiki/Titanium_Ore) also lists the powder. Do not count source-profile audit as a new output mapping.

**Primary modern experiment:** Wowhead commenter globalmenace explicitly reports **Retail 12.0.5**, 1000 Titanium Ore consumed and 143 Titanium Powder received. This establishes `143/1000*5 = 0.715` **units per nominal five-ore equivalent**, *not* P(hit) and not an observed actual-cast denominator. Propose provisional E=0.715 (field confidence **62/100 for reported 12.0.5 gross-input context**, not 2026-10-28 neutral baseline). Identity 82/100. Keep dropChance, positive yieldMin and yieldMax **null**. Patch 12.1/current, profession skill/gear, actual cast count and exact study date remain unknown. [Source](https://www.wowhead.com/item=46849/titanium-powder).

**Independent historical comparisons (NOT pooled across patches):** codiferous87 patch 10.1: 764 powder/4500 ore = **0.848889 per nominal five**; Ssateneth patch 8.1.5: reported 14.426% powder per ore across 26,000 ore = **0.7213 per five**; January 17, 2022 [Reddit original](https://www.reddit.com/r/woweconomy/comments/s6bfrl): 152 powder/1000 ore = **0.7600 per five**. Each is a distinct author/cohort; same Wowhead page and translated mirrors are not new independent studies. These are original aggregate reports, not current 12.1 measurements.

**P2 actual decision-risk demonstration using only the original author's *historical* price snapshot:** input 1000 ore cost **51,591g**, powder unit price **494.92g**, other gem sales value **4,303.95g**. Assuming a 5% AH sale cut, full sell-through, and ignoring deposit/time, **gem-only** net = **-47502.25g**; **including omitted powder** net = **+19732.63g**. The omitted output contributes **336.17g per nominal five ore** at that snapshot's price. This is a demonstrable historical *decision reversal*, **not a live auction quote or 2026-10-28 profitability claim**. Source [globalmenace 12.0.5](https://www.wowhead.com/item=46849/titanium-powder).

## 40/40 exact assigned material records audited
- **30** mathematically contradictory historical TSM records: 12 Cobalt/Titanium uncommon, 12 MoP ore outputs, 6 Felslate rare outputs. Never silently widen positive maxima, treat unknown as zero, or multiply unconditional E by P again.
- **7** BfA Ultramarine output records: compiled P=0.56540179 is a historical/Poisson proxy, **not** measured occurrence; preserve the historically reported E with its source, leave P/min/max null. Three independent author families (Baadkitty, Kidneph, Jiyao) exist, but different recipe units/skill contexts forbid automatic pooling.
- **3** otherwise arithmetically consistent historical TSM milling rows; no current patch/skill normalization established.
- **6** assigned Titanium uncommon rows gain independently sourced *historical* E per nominal five-ore equivalent from ZeRoTaCtIcS (66 stacks, approximately 264 standard prospects). They are NOT approved current-Retail E. **0 new independently verified current-Retail output fields** and **0 newly measured per-cast P or positive ranges**.

### Titanium uncommon: original 66-stack experiment versus invalid TSM E
[Original ZeRoTaCtIcS historical comment](https://www.wowhead.com/wotlk/item=46849/titanium-powder) reports 66 stacks of Titanium Ore, approximately 264 prospects, and exact aggregate gem counts. Author-reported actual casts are approximate; per-cast zero/hit logs absent. The TSM 2.5 *per output* is incompatible with source P=0.235 and positive [1,2] (max compatible E=0.47).

| Output | Original units | Historical E / nominal five ore | TSM E |
|---|---:|---:|---:|
| Bloodstone `36917` | 69 | 0.26136 | 2.5000 |
| Sun Crystal `36920` | 60 | 0.22727 | 2.5000 |
| Chalcedony `36923` | 77 | 0.29167 | 2.5000 |
| Shadow Crystal `36926` | 64 | 0.24242 | 2.5000 |
| Huge Citrine `36929` | 59 | 0.22348 | 2.5000 |
| Dark Jade `36932` | 71 | 0.26894 | 2.5000 |

Do not assign these six rates to Cobalt or infer P(hit) from aggregate counts. The original historical wiki reports approximately 25% chance and 1–2 positive units per uncommon, but these are unverified source estimates rather than a current matched experiment.

### BfA Ultramarine: independent original aggregate source comparison
[Baadkitty and Kidneph on original pigment page](https://www.wowhead.com/item=153669/viridescent-pigment) each report herb-input totals and output counts; Baadkitty 200 herbs per family, Kidneph 1000 per family except Anchor Weed. Values below are **per nominal five herbs**, not actual completed standard operations. Jiyao separately reports 20-herb mass casts, so no unverified 4x operation conversion is treated as an observed cast count.

| Input | Compiled historical E | Baadkitty | Kidneph |
|---|---:|---:|---:|
| Sea Stalk `152511` | 4.1292 | 3.9500 | 4.1650 |
| Akunda's Bite `152507` | 4.1042 | 3.8250 | 4.1600 |
| Winter's Kiss `152508` | 4.0583 | 4.0000 | 4.0700 |
| Riverbud `152505` | 4.0208 | 3.7750 | 4.0700 |
| Star Moss `152506` | 4.0125 | 3.8750 | 4.0400 |
| Siren's Pollen `152509` | 3.9917 | 3.9750 | 3.9950 |
| Anchor Weed `152510` | 3.9250 | 3.9250 | — |

### Legion independent original-source checks
[Queendom 3000 Starlight Rose mass-milling report](https://www.wowhead.com/spell=209662/mass-mill-starlight-rose): 3635 Roseate, **6.058333 per nominal five herbs** vs historical TSM **6.0600**. 150 Sallow from 3000 herbs is **1.0000 per nominal 20-herb mass cast**; source also writes “1.0400 per mill”, an internal arithmetic mismatch. Preserve original totals, flag stated mean, do not fabricate cast logs. [Felwort original beta report](https://www.wowhead.com/item=129034/sallow-pigment): 40 Felwort yielded 89 Sallow, **11.125 per nominal five** versus TSM **10.74**. No source-specific current-Retail patch bridge; Felwort is a separate study family.

## Validation, confidence and blockers
**Static assertions:** exact 40 unique stable keys, all 40 exact source-record matches, no disjoint assignment claims, 30 flagged TSM contradictions, seven BfA proxy-P unknowns, six original historical Titanium expected means, zero invalid candidate full four-field tuples, missing never coerced to zero, no double P multiplication. Numeric confidence means **strength of support (0–100)**, not probability of correctness. Original cohorts and derivative mirrors remain separate.

**No complete current neutral baseline** was verified. Pending: master acceptance of the **unassigned** `36910 -> 46849` P0 candidate, current patch eligibility/recipe probe, actual cast/hit/positive histograms, P/min/max, exact character conditions, and pricing test with current TSM. Current first-pass master baseline **1643/1737** is not exhaustive Retail conversion coverage. No source cache, central ledgers, master assignments, production Lua/TOC, merges or schedule changes.

**Next exact assigned high-impact keys:** `output-main:tsm:prospect:36909:36917:L887` through `L897` for new Cobalt cast-level data; `output-main:tsm:prospect:72094:76130:L1005` through `72103:76137:L1025` for MoP rate/unit reconciliation; `output-main:tsm:prospect:123919:130178:L1053` through `L1058` for labeled Felslate standard-cast outputs. **New master-claim target:** `36910:Prospect:46849`, with full output ID, five-ore batch and original 12.0.5 aggregate. Do not self-claim a new queue key.

## Reuse / new source learning
New source family: Retail 12.0.5 globalmenace Titanium Powder with distinct 10.1 and 8.1.5 author cohorts on same item page; old 66-stack ZeRoTaCtIcS historical cohort. Reused Reddit 2022 titanium, historical wiki Cobalt/Titanium, original BfA Baadkitty/Kidneph, Queendom Starlight. New Felwort original beta source, not a duplicate of Queendom. Avoided translated Wowhead mirrors, WoWWiki copies, and refetch of already fully archived Reddit source. Source review events are separate worker-owned immutable JSONL.
