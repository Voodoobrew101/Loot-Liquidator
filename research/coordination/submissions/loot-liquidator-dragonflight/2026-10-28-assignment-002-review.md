# Dragonflight worker — assignment 002: 40-key research review
Date 2026-10-28. Assignment `2026-10-28-batch002-dragonflight`. Branch `research/processing-confidence`. **Worker-owned evidence, pending master QA.**

## Work
Examined **40/40 distinct assigned keys**: nine remaining rank-2 Draconium historical TSM output records; 14 rank-1 Serevite, 14 rank-2 Serevite and three rank-3 Serevite supplemental records. All keys found in source ledgers. Nine TSM candidate tuples pass `P*min <= (amountOfMats*5) <= P*max`, but this proves only dimensional consistency, NOT true source semantics or patch/skill accuracy. All 31 supplemental rows lack independently measured per-cast P(drop) and conditional positive min/max.

## Historical study recovered and independently checked
Source: https://www.reddit.com/r/woweconomy/comments/zh53dd (posted **December 9, 2022**; author says collection after **December 6, 2022** reset). Reported **20,000 rank-3 Serevite ore**, max prospecting skill and 265 rank-3 gem quality threshold. Source totals: Illimited Diamond=29; Nozdorite=715; Neltharite=233; Ysemerald=220; Alexstraszite=197; Malygite=232; Eternity Amber=1452; Mystic Sapphire=424; Queen's Ruby=476; Sundered Onyx=455; Vibrant Emerald=471; Fractured Glass=5132; Crumbled Stone=5804. Original totals preserved in canonical JSONL. Five-ore equivalent mean is `total/4000`, not an observed per-cast mean; completed operations and input resource savings were not reported, so `completedOperations=null`. No hit counts, zero-operation counts or conditional yield range can be inferred.

**New QA finding: legacy source-to-output-rank and clamp mismatch.** The historical source reports rank-3 gems. Supplemental rows for rank-3 Serevite instead anchor gem-family output IDs to rank 1. The historical highRaw source values and the resulting final high model are different:

| Assigned rank-1 anchor | Source's rank-3 gem candidate | Historical five-ore equivalent | Supplemental low/high |
|---|---|---:|---|
| Queen's Ruby 192837 | 192839 | **0.119** | 0.126 / 0.126 |
| Mystic Sapphire 192840 | 192842 | **0.106** | 0.126 / 0.126 |
| Vibrant Emerald 192843 | 192845 | **0.11775** | 0.126 / 0.126 |

The historical source's `highRaw` values for these three families match 0.119, 0.106 and 0.11775, but the legacy model's final high is **clamped upward to 0.126**, the TSM low. This is not an independently measured high-skill output and should not be represented as such. Rank-3 study values cannot be directly priced as rank-1 gem item IDs; neither can they be transferred to rank-1/rank-2 ore profiles without evidence. All three assigned R3 comparisons **differ from final high**.

The recipe uses five ores (spell 374627): https://www.wowhead.com/spell=374627/dragon-isles-prospecting . Another 2000-ore cohort report on that page notes output quality depends on skill/ore rank and Inspiration, not a universal multiplier.

## Confidence and blockers
- Assigned nine TSM rows: field confidence **P=25, min=30, max=30, E=30**; weakest 25. All historical original cohorts unknown.
- Assigned 31 supplemental rows: **P=0, min=0, max=0**, E=0 except three R3 family comparisons at E=20; weakest 0. No valid current-Retail 2026 source.
- Independent 20k raw source: source-only aggregate E evidence **65** for candidate R3 gem IDs, **72** for byproducts, P/min/max **0** (unobserved). These are evidence-strength scores, not statistical accuracy. The source post does not list item IDs, so mapping is explicitly provisional.
- **Zero records >=90**, zero approved production corrections. No numerical patch/skill transformations. TSM `matRate` occurrence semantics still unverified; no three-rank simultaneous payout assumption. The previously flagged milling 1.24 multiplier remains unverified.

## QA performed
Exactly 40 assigned keys, 40 unique ledger matches, 9/9 TSM candidate inequalities passed, 31/31 supplemental source rows located, 3/3 direct R3 family comparisons checked, 0/3 final-high matches. JSONL required top-level and per-output schema fields checked; 13 positive integer raw totals, no fabricated operation denominator, P, min/max. **Full JSON Schema validation and live WoW testing not performed.** Files committed and read back. Master-owned assignments, shared central ledgers, production GameData.lua and addon files unchanged.

Latest master baseline at queue read: **194/1737 first-pass accepted**, 1543 never examined. This batch's 40 keys are pending master acceptance; do not decrement the master count without refreshing latest ledger.

## Next master assignment preview
`output-supp:dragonflight:190394:192846:3`; `output-supp:dragonflight:190394:192849:4`; `output-supp:dragonflight:190394:192852:5`; `output-supp:dragonflight:190394:192856:6`; `output-supp:dragonflight:190394:192859:7`; `output-supp:dragonflight:190394:192862:8`; `output-supp:dragonflight:190394:192866:9`; `output-supp:dragonflight:190394:192869:10`. Seek rank-specific actual output IDs and 2026 patch/skill-matched cast histograms before promotion.
