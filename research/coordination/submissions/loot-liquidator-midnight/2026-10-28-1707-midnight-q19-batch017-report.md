# Loot Liquidator Midnight — queue19 batch017 research handoff

**2026-10-28 · research-only · assignment `2026-10-28-batch017-midnight` · queue revision 19**

## Result and scope
- Audited **35/35 exact master-assigned keys**: 16 Crushing gem-ID candidates and 19 Midnight prospect output records. All 19 pinned GameData output ID/line matches passed at blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`.
- 140 independent four-field slots: **14 reused provisional historical expectedQuantity references** and **126 UNKNOWN**; no numeric field promoted from a new current-Retail completed-cast sample. Five assigned Eversong Diamond expectedQuantity cells remain UNKNOWN, never fabricated zero. The 16 Crushing candidates retain all four fields UNKNOWN at exact output-rank level.
- **Zero newly verified exact-ID Crushing mappings, zero new measured current-Retail cast cohorts, zero newly approved current-Retail numeric fields, zero immutable errata.** Two newly indexed original player statements (not cast cohorts) and two reused source records.

## P0 — Exact recipe vector and eligibility
[Midnight Crushing spell 1231132](https://www.wowhead.com/spell=1231132/midnight-crushing) describes **3 selected Midnight gems** as salvage inputs and **1 Dusk-Shrouded Stone** as a separate reagent. Source record's Salvage Item Crafting Data(105), Value 3 confirms the family operation, not each exact gem ID's whitelist. Candidate stone item `242788` is rank-provisional; higher stone rank `242789` and exact eligible combination remain unconfirmed. All 16 assigned gem IDs are distinct game item identities across eight same-name pairs; do not collapse them by name. Candidate output dust IDs `242620` and `242621` must be modeled as rank alternatives, not two guaranteed simultaneous outputs. No exact-ID salvage eligibility or output quality distribution confirmed in the source pages.

The [March 5 Method guide](https://www.method.gg/guides/midnight-jewelcrafting-profession-guide) says the variety/quality of gems does not affect the **family-level** quantity and suggests 1–3 Gemdust. This is a secondary qualitative range, **not independently measured per-output-ID positive min/max**. The same guide mentions one-gem-to-stone processing without a corresponding spell ID; keep this a separate unresolved operation and never treat stone as free output of 1231132.

## P1 — Newly indexed July estimate and historical comparison
A [July 24, 2026 first-hand player statement](https://www.reddit.com/r/woweconomy/comments/1v5esk0/midnight_jc/) reports **0.83925 dust per gem** with max prospecting/dusting/resourcefulness and purple tools. No input gem IDs, ranks, cast count, output rank, date of actual measurements or patch. Three-gem equivalent is **2.51775** dust per *nominal* batch, not a per-completed-cast E. Reused Cardinalai original: 330/480 = **0.6875** per gem, or 2.0625 per nominal batch at 40.7% Resourcefulness. The July estimate is **22.07% higher** than the older mixed-input figure, but contexts are not matched. Neither rate can be assigned to all 16 exact gem IDs or split across dust ranks.

A [March 12 first-hand report](https://www.reddit.com/r/woweconomy/comments/1rrn6of/resourcefulness_in_crushingprospecting/) distinguishes Resourcefulness *display* from gem units returned; the small sample lacks a denominator. Gem/stone savings belong on the **cost side**, not in output E. Do not interpret displayed 29% Resourcefulness as 29% saved units or apply a universal multiplier.

## P1 — Prospecting records
Fourteen non-Diamond rows preserve the GameData.low provisional E as source references (seven from Tin R1 transferred rank context, seven from Tin R2/Copper R2); these are not newly measured 2026 exact-rank cast averages. All 19 P(hit), positive min and max are UNKNOWN. Five Eversong Diamond rows `237359,237361,237362,237363,237364 → 242608` require ore-specific Proficient Processor eligibility and remain E UNKNOWN. The source `low/high` values are alternative historical context estimates, **not** positive min/max yields. No current patch/rank-matched TSM numeric table was found for promotion.

## P2 — Gold decision risks
1. Full Crushing cost per nominal craft = opportunity cost of **3 exact selected gem units + 1 stone**, before time and possible Resourcefulness savings; actual savings require measured distribution. Use 5% AH cut only when enabled by addon settings, not embedded in yield evidence.
2. 0.83925 versus 0.6875 dust/gem is a **22.07% contextual rate discrepancy**, large enough to prioritize matched experiments; no AH prices or actual optimal-action flip established.
3. R1/R2 Gemdust must be valued as mutually exclusive output rank distributions, conditional on skill/gear and material rank. Do not sum copied family E into both dust IDs.
4. Prospecting Diamond E remains unknown, not zero; do not recommend against prospecting solely because the specialization-gated Diamond value is missing.

## Source lineage and next exact IDs
- NEW original player statement: https://www.reddit.com/r/woweconomy/comments/1v5esk0/midnight_jc/ (no cast denominator).
- NEW original player observation: https://www.reddit.com/r/woweconomy/comments/1rrn6of/resourcefulness_in_crushingprospecting/ (small unspecified sample, refund ambiguity).
- REUSED game record: https://www.wowhead.com/spell=1231132/midnight-crushing; REUSED secondary guide: https://www.method.gg/guides/midnight-jewelcrafting-profession-guide; REUSED original Cardinalai: https://www.wowhead.com/item=242620/glimmering-gemdust. Two Reddit URLs were absent from live source-memory before this run; source-review events are append-only and master owns replay.
- Next exact Crushing input IDs: `242553, 242554, 242606, 242607, 242610, 242611, 242612, 242613, 242720, 242721, 242722, 242723, 242724, 242725, 242726, 242727`; outputs `242620,242621`; stone ranks `242788,242789`; spell `1231132`. Obtain in-client `CanSalvage` or equivalent legal eligibility per item ID and capture rank-specific output histograms with actual completedOperations, zero counts, profession skill, knowledge nodes, gear, Resourcefulness refunds and client build. Prospect priorities: `237361→242786/242788`, `237362/237363→242606/242607/242610/242611/242786/242788`, and `237359/237361/237362/237363/237364→242608`.

**Master QA:** candidate v0.5.0 remains 994 provisional mappings, 801 four-field-complete and 435 unknown cells before this submission. Exhaustive Retail universe not verified. No production Lua/TOC, main, master assignments, shared ledgers, canonical registry, source-memory cache or schedules touched. Node CLI, independent Lua and WoW client tests not executed.
