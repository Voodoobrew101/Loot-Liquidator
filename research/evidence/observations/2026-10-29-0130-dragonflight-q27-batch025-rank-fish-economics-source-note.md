# Dragonflight q27 Batch025 — exact rank/expectedQuantity audit and source identity note
**2026-10-29 · RESEARCH ONLY · assignment 2026-10-29-batch025-dragonflight**

## Source-line and item identity
Pinned GameData.lua blob 1d47c4a961c5dc5af626e659f7d96d1490d3cf9e. Exactly 14/14 assigned parent/input/output lines match. All five-herb and five-fish operations are *source-derived* operation sizes; fish five supported by Primer and 2023 original player discussion. No skill-matched 2026 completed-cast dataset was located.

| Input ID | Family / rank | Output IDs | Assigned keys | Missing current economic E |
|---|---|---|---:|---:|
| 191469 | Bubble Poppy R3 / Serene R1–R3 | 198412, 198413, 198414 | 3 | 3 |
| 191470 | Writhebark R1 / Flourishing R1–R3 | 198415, 198416, 198417 | 3 | 3 |
| 191471 | Writhebark R2 / Flourishing R1–R3 | 198415, 198416, 198417 | 3 | 3 |
| 191472 | Writhebark R3 / Flourishing R1–R3 | 198415, 198416, 198417 | 3 | 3 |
| 200061 | Prismatic Leaper / Rousing Order | 190322 | 1 | 0 (proxy present, NOT gold-validated) |
| 200061 | Prismatic Leaper / Serene R1 | 198412 | 1 | 1 |

## Source/provenance and actual observations
1. **Historical source only:** https://www.wowhead.com/news/crafting-work-orders-are-here-wowhead-economy-weekly-wrap-up-251-329620 reproduces original Liqourice5 October 22, 2022 **beta** 2–5 family pigments per five-herb mill and quality/skill hypothesis. Original Reddit https://www.reddit.com/r/woweconomy/comments/yaxw94/a_look_at_dragonflight_milling/ is deleted. One author, not two independent studies. No zero-inclusive per-output-rank histogram. Maxstat/skill is a tooltip profile label, not an actually measured maximum.
2. **New weak historical anecdote:** https://www.reddit.com/r/woweconomy/comments/10k8158 (January 24, 2023) recalls (“IIRC”) skill 250 for guaranteed R3 pigment; no actual casts, no exact input rank, no 2026 patch. Do not use for numerical rank probability or skill coefficient.
3. **Fish original reused:** https://www.wowhead.com/item=200061/prismatic-leaper Primer's **3 completed mills / 15 fish**, pooled 3 Serene R2, 5 Flourishing R2, 2 Flourishing R3. Assigned Serene **R1** and Rousing Order not reported. No inference of zero; cast denominator 3 applies to reported pooled results, NOT exact assigned output-specific zero-inclusive counts.
4. **New item identity check:** https://www.wowhead.com/item=190322 confirms **Rousing Order**, but no evidence of Prismatic Leaper milling on that reciprocal item page. GameData.lua L1996 lists 200061→190322 with matRate=.002, amountOfMats=.001, min=max1. TSM original cohort, rate units and completed casts unknown. Source proxy 5×.001=.005 is already present in compiled itemdb; confidence 10/100, P absent due conflict. It must not be treated as a measured current gold expectation.
5. **Herb identity:** Retail Wowhead pages https://www.wowhead.com/item=191469, /191470, /191471, /191472 confirm Bubble Poppy and Writhebark names, but did not expose original exact-rank cast histograms. Source review intentionally does not count four item identity pages as four new experiments.

## Numeric invariants
- Four herb input groups × three rank outputs = 12 source mappings. Source matRate=1 copied per rank implies sum=3, impossible as simultaneous per-operation probabilities if ranks exclusive; not a proof that TSM rate semantics are P(hit).
- Historical hypothetical per-five-unit E: 5×.7=3.5 each rank, 10.5 if three ranks naively summed; quality-exclusive grouping 3.5. These are illustrative arithmetic only, not observed current-Retail E.
- Fish Rousing Order min=max1 means any true per-cast P and E on the same operation basis must satisfy E=P; current historical source matRate .002 and derived E .005 cannot both be treated as such. Unit semantics not proven; flag **source unit/denominator ambiguity**, not fabricated repair.
- **Gold isolation:** every exact current 2026 P, positive yieldMin/max, economic E remains null in this audit. Existing compiler's 190322 E=.005 is recorded as a historical proxy only; tooltip-only fallback min/max never enter economic E.
- Output-rank eligibility and fish-specific byproduct identity require actual current-client verification; absence of a Wowhead tab is not evidence of impossibility.

## Progress accounting
**14/14** assigned identities, **0** new mappings, **0** current numeric field promotions, **0** corrections, **14** unresolved exact P, **13** absent E plus one present unverified proxy, **4** source-review events. Original author lineages: Liqourice5 beta (reused), Primer three-cast fish (reused), 2023 skill poster (new anecdote, no cast), TSM derivative (reused). Avoid counting identity pages as original processing studies.
