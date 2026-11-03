# Midnight q20 Batch 018 — exact-key material audit and reused original cohort reconciliation
**2026-10-28 · branch research/processing-confidence · worker-only research**

## Assignment and safety
Live queue revision **20**, assignment **2026-10-28-batch018-midnight**; **35/35 disjoint keys**, consisting of **30 prospecting source-line identities** and **five Crushing exact-item eligibility candidates**. All 30 GameData.lua line identities matched input/output IDs and item names. Re-read master batch017 verdict, source-memory, research lessons and prior worker source reviews. No production Lua/TOC, main, master assignments, canonical registry, shared ledgers or source-memory modified.

## P0 — mapping and recipe results
**New legitimate output mappings: 0.** All 30 assigned prospecting identities already exist in GameData.lua; five Crushing IDs have archived item identities but no in-client proof that the salvage selector accepts those exact IDs. Spell **1231132** supports three selected Midnight gems plus one Dusk-Shrouded Stone, but this is a multi-reagent salvage recipe, not a verified five-input whitelist or a one-gem conversion. Candidate Gemdust outputs **242620/242621** are not rank-matched. The five exact candidate inputs are **242553, 242723, 242554, 242722, 242607**. Their exact eligibility remains **UNKNOWN**. Reference: https://www.wowhead.com/spell=1231132/midnight-crushing.

## P1 — independently scoped four-field evidence
Audited **140 field slots** across 35 records. **0 new verified current-Retail P, positive min, positive max or unconditional E**. All 140 remain unknown for exact current-context numeric promotion. Existing GameData low/high figures are retained as *historical source-profile references*, not silently treated as completed-cast E or bounds. In particular, 12 assigned rank-one Copper/Silver rows inherit rank-two 50-ore results; rank transfer is not independent measurement. Thorium low values are guide proxies. Two assigned Diamond rows have low=0, which is **not a measured zero** and must not erase specialization-gated upside.

### Original rank-separated source, reused without duplicate-source inflation
HeadtripVee's April 8 Reddit discussion includes original ore-quality-separated tables for **3,000 Copper R1; 3,500 Copper R2; 4,500 Silver R1; 2,000 Silver R2** (the author labels them "Ignot total"). This run preserved **23 assigned exact input/output percentage cells** in four schema-compatible SOURCE_ONLY_UNCONVERTED observations. These are original author-reported percentages, **not** P(hit). The nominal per-five-ore comparison is percent × 5/100, *not* E per actual completed cast. Actual casts, resource savings, skill and collection dates are absent. The author discusses old rates around the April 2026 prospecting change; the actual sample window is unverified. Source: https://www.reddit.com/r/woweconomy/comments/1sfds1u/did_prospecting_change/.

| Assigned output | GameData low reference | Original gross-five-ore equivalent | Comparison only |
|---|---:|---:|---:|
| Copper R1 → Sanguine Garnet 242553 | 0.3000 | 0.0715 | 4.20× |
| Copper R2 → Sanguine Garnet 242553 | 0.3000 | 0.0845 | 3.55× |
| Silver R2 → Eversong Diamond 242608 | 0.0000 | 0.0625 | low=0 is not evidence of impossibility |
| Silver R2 → Duskshrouded Stone 242788 | 0.9000 | 1.2850 | 0.70× |

These are cross-context source differences, **not** validated current-Retail errors or replacements.

### Independent Cardinalai cohort, reused
Cardinalai reports **800 actual Brilliant Silver prospects**, **43 Diamonds**, **3,285 ore used** and **715 saved**: 3,285+715 = 800×5. This supports a historical unconditional mean **43/800 = 0.05375 Diamonds/cast** under that player's conditions, but the exact input quality rank is not stated, so it cannot fill assigned **237365→242608**. Compare with the original Headtrip Silver R2 gross equivalent 0.0625 and GameData high 0.01; differences are potentially material to gold recommendations, but no current price/action flip is established. Source: https://www.wowhead.com/item=237364/brilliant-silver-ore.

### Thorium context
An April 8 Reddit commenter states **20% per craft over 200 Thorium crafts**; absent explicit hit counts and total Diamond units, this is a reported rate with unresolved P-versus-E interpretation, not a validated P(hit) or unconditional E. Source: https://www.reddit.com/r/woweconomy/comments/1sfds1u/did_prospecting_change/.

## P2 — valuation and TSM decision risk
The largest audit risks are **Copper Sanguine Garnet rank-transfer mismatch**, **Silver Diamond low/high proxy versus independent historical Diamond means**, and **Crushing omitting one Dusk-Shrouded Stone or copying family Gemdust E to both ranks**. Existing TSM-derived or GameData profile values are historical practical references, not current AH quotes or independently measured outcomes. Do not apply a universal skill multiplier. Ore refunds reduce input cost, not output quantity. No current AH prices or optimal-action flips were tested.

## Continuous improvement and master handoff
**Source statuses:** reused Headtrip original (four contextual cohorts), reused JD3K 50-ore study, reused independent Cardinalai 800-cast study, reused spell record, secondary Wowhead specialization guide. **New independent original studies: 0; new current numeric promotions: 0; source re-fetch avoided:** JD3K, Cardinalai, GameData, source-memory metadata. Four source-only observations and five append-only review events record missing fields, provenance and patch ambiguity. **Useful negative conclusions:** original percentages cannot become per-cast P; Silver Diamond cannot be assigned to an unspecified ore rank; rank-one proxies cannot inherit rank-two confidence; exact Crushing salvage eligibility cannot be inferred from item identity.

**Next exact keys:** Silver R2 **237365→242608**, Copper R1/R2 **237359/237361→242553**, Thorium **237366→242608**, and Crushing **242553/242723/242554/242722/242607→242620/242621** with stone **242788/242789** and spell **1231132**. Capture actual completed casts, zero-inclusive output histograms, input rank, knowledge nodes, skill, patch, ore refunds, and gem/stone eligibility. The master owns acceptance and compiler promotion.

**Master baseline read:** v0.6.0 = 1003 provisional mappings, 801 four-field-complete, 462 missing cells; no claims of exhaustive Retail coverage. No Node CLI, Lua interpreter or in-game testing performed in this research-only run.
