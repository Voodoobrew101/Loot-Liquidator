# Loot Liquidator Legacy — Batch013 research submission
**Run** 2026-10-28-1340-legacy-batch013; research branch `research/processing-confidence`; master queue rev 15, assignment `2026-10-28-batch013-legacy`. Worker-only files, no production or master state writes.

## Actual results
**40/40** exact assigned keys reviewed; **39/39** existing GameData output IDs matched their exact source lines; one Titanium Powder mapping was **already accepted** in master batch012. **Zero new output mappings, zero verified current-Retail per-cast rates, zero accepted confidence deltas.** All 40 have historical per-five-gross-input expected quantity references, but no measured per-five standard-cast P, positive integer min/max or 2026 unskilled baseline.

**P0/P2 numeric bug: 8 direct contradictions** where `GameData.lua` existing P > existing E. For any positive integer material output, P(at least one) <= unconditional E. These eight fail necessary arithmetic. All 39 existing chances are explicitly labeled historical/proxy, not measured, and should be quarantined by master, even when arithmetic passes. IDs and historical E must be preserved.

**Source differences:** 27 archived original-cohort E5 values differ from compiled mixed historical source E by up to 0.0475 units per five gross herbs. These are alternate cohorts, NOT evidence the compiled E is arithmetically wrong. Keep both provenance and context, do not silently overwrite or pool. The largest difference is Sea Stalk 152511→Crimson 153636: archived Kidneph E5=1.34 vs compiled E5=1.3875.

## P0 identity/recipe
- **WoD (6 rows):** Frostweed 109124, Fireweed 109125, Gorgrond Flytrap 109126, Starflower 109127, Nagrand Arrowbloom 109128, Talador Orchid 109129 → Cerulean Pigment 114931. Original Wowhead 516803, 2000 herbs per type, 20-herb mass recipe; actual standard casts unreported. https://www.wowhead.com/spell=190385/mass-mill-nagrand-arrowbloom
- **BfA (14 rows):** 152505–152511 → Crimson 153636 / Viridescent 153669. Original Kidneph 1000 herbs per six types and Baadkitty 200 Anchor Weed; Jiyao separately reported skill 150 changes. Exact standard versus mass output distribution unknown. https://www.wowhead.com/item=153669/viridescent-pigment
- **Shadowlands (19 rows):** 168583/168586/168589/169701/170554/171315 and First Flower 187699 → Umbral 173056, Luminous 173057, Tranquil 175788. 20-herb mass and five-herb standard recipes must not be treated as identical without testing. Original https://www.reddit.com/r/woweconomy/comments/k12a5o and https://www.reddit.com/r/woweconomy/comments/t8lubc .
- **Titanium Powder (1 row):** 36910→46849, 1000 ore→143 powder on reported Retail 12.0.5, E5=0.715 historical gross-input equivalent. Already accepted, no new mapping credit; P/min/max and current 12.1 cast denominator unknown. https://www.wowhead.com/item=46849/titanium-powder

## NEW independent primary Nightshade cohort
May 30, 2021 original https://www.reddit.com/r/woweconomy/comments/nohny2 : **3000 Nightshade → 781 Umbral, 712 Luminous, 884 Tranquil**. Compare Nov 25, 2020 original https://www.reddit.com/r/woweconomy/comments/k12a5o : **1640 Nightshade → 432 Umbral, 381 Luminous, 501 Tranquil**. Different authors/dates, not copies; recipe, skill and patch unmatched. Do not pool as current Retail.
| Output | 2020 E per nominal five herbs | 2021 E per nominal five herbs | Relative difference |
|---|---:|---:|---:|
| Umbral `173056` | 1.31707 | 1.30167 | -1.17% |
| Luminous `173057` | 1.16159 | 1.18667 | 2.16% |
| Tranquil `175788` | 1.52744 | 1.47333 | -3.54% |

## P1 fields and decision risks
Companion JSONL preserves independent field objects for all 40 keys: `dropChance=null`, `yieldMin=null`, `yieldMax=null`, and **historical E5 with source-specific confidence 52–68** (Titanium 62). This does not erase the existing source P; it records it separately as an unverified claim and flags eight invariant failures. No fake zero, midpoint EV, or P×E. Current Retail unskilled E remains unverified for all.

**High-impact examples:** Rising Glory 168586→Tranquil 175788 has P=0.56540179 and E=0.025 (P > E by 22.6×). Star Moss 152506→Viridescent 153669 P=0.56540179 > E=0.45. Nightshade Tranquil historical E5~1.5 vs ordinary Shadowlands herbs ~0.02–0.025 can strongly affect milling decisions. A real gold-method flip cannot be calculated without live TSM prices and matched current rates.

## Source learning and next exact IDs
Reused 2020 original Reddit, 2018 BfA Kidneph/Baadkitty, WoD 516803, First Flower BullDozzer and already-accepted Titanium report; one **new independent** 2021 Nightshade source. Suppressed derivative https://www.reddit.com/r/woweconomy/comments/k1zd4o and translated copies. No repeat source credited as a new experiment. New source archived as source-only Markdown because its cast denominator is unknown.

**Master action requests:** quarantine 39 unmeasured P cells, prioritize eight contradictions; retain legitimate mappings and historical E; obtain 2026 zero-inclusive actual cast logs for `171315→173056/173057/175788`, `168586→175788`, `152506→153669`, and `36910→46849`; compare standard 5-herb with mass 20-herb recipes and actual skill.

Master batch012 baseline: 976 staged provisional mappings, 840 numeric-complete source tuples, 294 unknown numeric cells; 1643/1737 source first-pass, not exhaustive Retail universe. These figures are **pre-review**, not updated by this worker. Evidence confidence is strength of support (0–100), not percent accuracy.
