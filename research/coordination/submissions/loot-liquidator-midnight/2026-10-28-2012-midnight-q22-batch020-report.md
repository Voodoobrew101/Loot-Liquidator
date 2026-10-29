# Midnight q22 Batch 020 — exact material gaps, byproduct guarantee check and Crushing selector ancestry
**2026-10-28 20:12 PDT · research-only · queue revision 22 · assignment 2026-10-28-batch020-midnight**

## Assignment and source QA
- Audited **35/35 disjoint exact master keys**: 30 prospecting source rows and 5 previously unassigned Crushing candidates. 30/30 GameData source-line output IDs matched pinned production blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e` (read-only).
- Read live assignments, master batch019 verdict, research lessons, source-memory, prior Midnight source reviews and canonical observation schema before source discovery.
- No new source-backed Retail conversion was admitted to canonical itemdb. **Three R1 Crushing inputs have newly articulated provisional item-specific family support**, but still lack a verified selector whitelist and are deliberately not promoted.
- Four independent numeric fields per assigned record remain null: **140/140 unknown exact-context fields**. No zero was substituted. The 60 low/high scenario references for 30 prospect rows remain separate from numeric evidence.

## P0 — five assigned Crushing inputs and lineage
The spell [Midnight Crushing 1231132](https://www.wowhead.com/spell=1231132/midnight-crushing) requires **3 selected gems plus 1 Dusk-Shrouded Stone**, with salvage data value 3. Exact selected-gem whitelist is not exposed on this page.
- `242553` Sanguine Garnet (R1), `242554` Amani Lapis (R1), `242607` Harandar Peridot (R1): **provisional family-level eligibility support**. The already archived original [Cardinalai mixed-crushing report](https://www.wowhead.com/item=242620/glimmering-gemdust) explicitly lists 63 Garnet, 87 Lapis and 150 Peridot among 480 **silver-quality** gems crushed, with 180 Amethyst, 160 stones and 330 Gemdust. The report does **not** show per-gem individual operations, a salvage selector screenshot, exact gem item IDs, or Gemdust output-rank histogram. The item identities were independently cross-checked on Wowhead. Provisional evidence confidence 55/100 applies **only to family-level eligibility**, not a numeric yield or approved mapping.
- `242723` Sanguine Garnet (R2) and `242722` Amani Lapis (R2): distinct IDs from their R1 counterparts; **exact-rank eligibility remains unverified** (weak family-level guide support only; 20/100). Do not transfer the Cardinalai silver-quality sample to these IDs.
- The 480/3=160 nominal input groups and 330/160=2.0625 nominal three-gem-equivalent dust are arithmetic references only. **160 actual completed operations were not independently reported**; Resourcefulness 40.7% and possible saved gem/stone units prohibit promotion of 2.0625 to per-cast E. Neither 330/480 nor a guide's ~0.67 dust per gem is a verified same-context per-cast E.
- Preserve source as one reused Cardinalai author cohort, not four independent gem studies. Do not award a new independent cohort.

## P0/P2 — purported guaranteed prospecting byproducts conflict with original aggregate
The current [WoW-Professions guide](https://www.wow-professions.com/midnight/jewelcrafting-guide) describes Duskshrouded Stone and Crystalline Glass as guaranteed per prospect. The already archived original [JD3K quality-2 50-ore tests](https://www.wowhead.com/spell=1231127/midnight-prospecting) report:
| Input R2 cohort | Glass | Stone | Nominal five-ore groups |
|---|---:|---:|---:|
| Refulgent Copper (50 ore) | 12 | **9** | 10 |
| Brilliant Silver (50 ore) | **8** | **9** | 10 |
| Umbral Tin (50 ore) | **7** | 11 | 10 |

If all 50 ore were processed in standard five-ore casts, the Glass and Stone counts below 10 would contradict a per-cast minimum of one. Actual completed operations, whether any ore remained, and historical patch timing are not independently reported, so this is a **high-priority contradiction candidate**, NOT proof that the current guide or present Retail is wrong. Never fill P(hit)=1 or positive yieldMin=1 merely from a generic guide claim; retain the original source counts, cast-denominator ambiguity and patch mismatch. The q22 R1 rows must not inherit R2 numeric confidence.

## P1 — independent field status
Every q22 output has `dropChance=null`, `yieldMin=null`, `yieldMax=null`, `expectedQuantity=null`, each with confidence 0 and NOT_OBSERVED status for the exact current-Retail input rank / patch / skill. The 30 GameData source scenario low/high numbers are **not** positive conditional yield bounds. Diamond `242608` has seven assigned ore/rank rows; ore-specific Proficient Processor nodes condition eligibility. A low-profile zero is not evidence of zero output for a skilled character, and an upper scenario estimate is not a measured probability.

## P2 — gold decision risk
1. **Highest:** Seven Diamond keys `237359/237361/237362/237363/237364/237365/237366→242608` require ore-specific knowledge gating; otherwise high-value Diamond EV could be falsely included.
2. **High:** Crushing three gems plus stone `242788` requires a multi-reagent input cost vector and rank-aware Gemdust output; omitting stone or double-counting resource savings can flip a gold-optimal choice.
3. **High:** The generic guaranteed-byproduct claim versus JD3K's 7/8/9 source counts can overstate Glass/Stone returns. Do not infer current-P=1 from the guide without patch-matched casts.
4. **Medium:** Rank-one profiles borrowed from rank-two tests, and inverted scenario labels (e.g. Copper glass low 1.2/high 0.75), are not min/max observations.
No current AH snapshot or confirmed liquidation action flip was established.

## Source efficiency and QA lessons
- **Reused original studies:** JD3K and Cardinalai. **Reused game record:** Crushing 1231132. **Reused derivative guides:** Method and WoW-Professions, not independent measurements. No redundant original-cohort credit.
- **Newly indexed original qualitative lead:** March–April 2026 [Blizzard forum Jewelcrafting discussion](https://us.forums.blizzard.com/en/wow/t/jc-glimmering-gemdust-is-disgusting/2272506) includes separate players comparing blue/green dust and a rough 15–20 gems per 100 mixed ore. Neither gives exact item/rank/zero-inclusive cast histograms, so no numerical promotion.
- All 30 GameData line IDs checked, 35 exact keys unique, null/confidence invariant passed, output-rank alternatives not summed, and all five Crushing reagent vectors include stone. No in-client/Node/Lua runtime tests.

## Master handoff and exact next work
**New admitted valid mappings 0; new exact-context numeric fields 0; independent measured current-Retail cohorts 0; 3 stronger provisional R1 Crushing eligibility candidates; 2 R2 Crushing candidates still rank-unverified.**
Prioritize selector screenshots or original recipe records for `242553,242554,242607,242723,242722` under spell `1231132`, recording actual completed casts, Gemdust output rank `242620/242621`, stone rank and Resourcefulness savings. Next prospecting histograms: `237365→242608`, `237366→242608`, `237361→242786/242788`, `237365→242786/242788`. Master alone may promote mappings or reassign scope.

No production Lua/TOC, main, master ledgers, assignments, canonical registry, source-memory or schedules modified.
