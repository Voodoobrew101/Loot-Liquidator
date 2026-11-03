# Loot Liquidator Legacy — Batch017 / queue revision 19
**Date:** 2026-10-28 · **Branch:** research/processing-confidence · **Worker:** loot-liquidator-legacy · research-only

## Executive QA
- Audited **40/40** exact master-owned assigned keys under `2026-10-28-batch017-legacy`: 31 historical prospecting records reused, plus 9 BfA compiled Star Moss / Sea Stalk / Siren's Pollen output rows.
- **39/39** source-line item identities verified against live GameData.lua blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`. One Titanium Powder curated record has no GameData line; not falsely counted as a match.
- Numeric field slots 160: **34 historical/provisional E, 126 unknown**; measured current-Retail P=0, positive min/max=0, current-Retail per-cast E=0. The 34 E values are NOT 34 verified Retail baselines.
- **0 new legitimate mappings, 0 new 2026 Retail measured numeric fields, 0 new independent original studies**. Three previously archived independent BfA author cohorts were reconciled; their source ancestry is retained.
- Nine Jiyao original reported historical **per actual 20-herb mass-cast means** are recorded separately from nine compiled historical **nominal five-herb** estimates. No replacement of a standard five-herb record with a mass-20 cast rate.

## P0/P1 — BfA three-herb / nine-output evidence comparison
Primary historical author Jiyao's **revised** [Viridescent Pigment comment](https://www.wowhead.com/item=153669/viridescent-pigment) reports 177 Star Moss, 106 Sea Stalk and 103 Siren's Pollen **actual mass milling operations**, each consuming 20 herbs. The original [Star Moss recipe](https://www.wowhead.com/spell=256218), [Sea Stalk recipe](https://www.wowhead.com/spell=256223) and [Siren's Pollen recipe](https://www.wowhead.com/spell=256221) independently document 20-herb reagent units and BfA Inscription 50. Current client recipe eligibility is not proven.

| Herb | Pigment | GameData E / nominal 5 | Jiyao E / actual mass-20 cast | Jiyao / nominal 5 | Difference | Baadkitty / nominal 5 | Kidneph / nominal 5 |
|---|---|---:|---:|---:|---:|---:|---:|
| Star Moss `152506` | Ultramarine `153635` | 4.0125 | 15.48 | 3.8700 | -3.55% | 3.8750 | 4.0400 |
| Star Moss `152506` | Crimson `153636` | 1.4125 | 5.89 | 1.4725 | 4.25% | 1.5000 | 1.3950 |
| Star Moss `152506` | Viridescent `153669` | 0.4500 | 2.87 | 0.7175 | 59.44% | 0.4250 | 0.4550 |
| Sea Stalk `152507` | Ultramarine `153635` | 4.1042 | 16.39 | 4.0975 | -0.16% | 3.9500 | 4.1650 |
| Sea Stalk `152507` | Crimson `153636` | 1.5625 | 5.96 | 1.4900 | -4.64% | 1.6250 | 1.3400 |
| Sea Stalk `152507` | Viridescent `153669` | 0.7333 | 2.57 | 0.6425 | -12.39% | 0.4500 | 0.5900 |
| Siren's Pollen `152508` | Ultramarine `153635` | 4.0583 | 15.89 | 3.9725 | -2.11% | 3.9750 | 3.9950 |
| Siren's Pollen `152508` | Crimson `153636` | 1.6583 | 5.85 | 1.4625 | -11.81% | 1.8000 | 1.5550 |
| Siren's Pollen `152508` | Viridescent `153669` | 0.6417 | 2.12 | 0.5300 | -17.40% | 0.7500 | 0.5750 |

**Critical unit guard:** Jiyao's actual mass-20 E is supported as a *historical mass recipe* estimate. Dividing by four gives a gross-herb comparison only, **not** an observed five-herb standard milling expectedQuantity. The source's means are rounded; do not reconstruct exact integer totals or per-output P(hit) from rounded averages. The archived GameData five-herb E values are preserved as provisional context only. All P, positive min and positive max for the 40 assigned keys remain unknown.

**Source lineage:** Jiyao's 177/106/103 casts are one author/dataset spanning three herb cohorts, not three independent studies. Baadkitty reports 200 herbs per type; Kidneph reports 1,000 herbs per type. Their per-nominal-five values are input-normalized descriptive ratios, not observed five-herb cast E. Neither independent commenter reports full zero-inclusive histograms or exact cast denominators. Source-memory already indexes all three authors; no new independent-source credit.

## P2 — Decision-sensitive discrepancies
- **Star Moss → Viridescent `152506→153669`:** Jiyao 0.7175 per nominal five versus compiled 0.4500 (**+59.44%**). Independent Baadkitty 0.425 and Kidneph 0.455 per nominal five align more closely with compiled 0.450. This is **cohort/skill heterogeneity**, not grounds for automatically raising current-Retail E.
- **Sea Stalk → Viridescent `152507→153669`:** Jiyao 0.6425 vs compiled 0.7333 (**−12.39%**). Baadkitty 0.450 and Kidneph 0.590 gross-equivalent.
- **Siren's Pollen → Crimson `152508→153636`:** Jiyao 1.4625 vs compiled 1.6583 (**−11.81%**). Independent Baadkitty 1.800 and Kidneph 1.555.
- Original [Viridescent Pigment](https://www.wowhead.com/item=153669/viridescent-pigment) commenter 1917247 describes Viridescent changes after reaching 150/150 BfA Inscription across large herb volumes; source memory already knows it. No per-herb controlled before/after cast histograms: **do not create a universal skill coefficient**.
- Earlier TSM source P/E/range contradictions for Felslate, Cobalt, Titanium and Trillium remain quarantined as described in q18 audit. No AH price snapshots or demonstrated gold-action flips; compare output price × independently supported unconditional E only.

## P3, invariant and workflow results
- Checked all 40 stable-key identities, all 39 applicable GameData output IDs, 160 field slots and nonnegative historical means; no new promoted numeric tuple violates P × min ≤ E ≤ P × max because **P and bounds are explicitly unknown**.
- Reused q18 original audits and already-indexed Jiyao/Baadkitty/Kidneph evidence rather than re-fetching identical studies. Current web indexed source pages were checked to verify recipe units and the revised Jiyao table.
- No claim of current Retail equivalence, exhaustive mapping coverage, independent replication from translated/mirrored Wowhead pages or reward-based confidence inflation.
- No changes to main, Lua/TOC, canonical registry, master ledgers, assignments, source-memory or automation schedules.

## Master handoff and exact next IDs
1. **P0** Verify current Retail standard milling eligibility and zero-inclusive actual 5-herb cast histograms for inputs `152506`, `152507`, `152508` with outputs `153635`, `153636`, `153669` and profession skill explicitly recorded. Separate 20-herb mass recipe spell IDs `256218`, `256223`, `256221`.
2. **P1** Revisit `152506→153669` first: Jiyao versus independent authors has the largest 59.44% nominal discrepancy; estimate expected gold-decision delta only with actual contemporary prices and skill-matched E.
3. **P1** Obtain zero-inclusive Retail cast histograms for `36910→46849` Titanium Powder and six `36909` Cobalt gems `36917/36920/36923/36926/36929/36932`. Existing original Titanium Almar totals lack a denominator; do not invent one.
4. **P2** Verify `72094/72103→76130/76133/76134/76135/76136/76137` Trillium rank-independent gem outcomes and `123919→130178–130183` Felslate rare-gem mechanics; source TSM tuple contradictions remain unresolved.

**Assignment status:** All 40 q19 keys examined; no additional overflow claimed. Master decides whether to reassign on next queue.
