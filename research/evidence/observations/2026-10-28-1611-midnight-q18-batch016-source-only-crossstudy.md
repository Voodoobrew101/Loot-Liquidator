# Source-only cross-study reconciliation — Midnight queue18
Date 2026-10-28; worker loot-liquidator-midnight. **No new experiment.** The original Cardinalai, Thorium and JD3K cohorts were archived in prior worker batches. This is a comparison and negative-inference record, not a new schema observation or first-pass mapping.

## Reused original Silver 800-cast study
Original: https://www.wowhead.com/item=237364/brilliant-silver-ore (Cardinalai). Previously archived at `research/coordination/submissions/loot-liquidator-midnight/2026-10-28-batch002-silver-800cast-source-only.json`.

Reported 800 completed prospect operations; 3,285 ore consumed + 715 ore saved = 4,000 nominal ore = 800×5. Resourcefulness stat 39.6%; savings per cast = 0.89375 ore; net ore cost = 4.10625 ore/cast. These are INPUT costs, not extra output. Original totals are from one study, not seven independent cohorts. Actual input ore quality rank, observation date/build and full specialization details are unreported. Source-page anchor `237364` does NOT establish processed input was `237364` rather than `237365`.

| Output | Reported total | Observed unconditional units / 800 reported casts | GameData historical Silver `high` | Ratio source/high |
|---|---:|---:|---:|---:|
| Eversong Diamond `242608` | 43 | 0.05375 | 0.01000 | 5.375× |
| Flawless Sanguine Garnet `242613` | 111 | 0.13875 | 0.12500 | 1.110× |
| Flawless Amani Lapis `242612` | 114 | 0.14250 | 0.12500 | 1.140× |
| Sanguine Garnet `242553` | 153 | 0.19125 | 0.12500 | 1.530× |
| Amani Lapis `242554` | 145 | 0.18125 | 0.12500 | 1.450× |
| Crystalline Glass `242786` | 671 | 0.83875 | 0.75000 | 1.118× |
| Duskshrouded Stone `242788` | 874 | 1.09250 | 1.20000 | 0.910× |

Diamond E=0.05375 is **5.375×** GameData's `high=0.01` for Silver. Other differences are also contextual: not a matched skill/rank/patch experiment. Do not transfer these means to either specific input quality rank, and do not treat `high` as a positive yield maximum.

## Reused Thorium 200-craft occurrence report
Original https://www.reddit.com/r/woweconomy/comments/1sfds1u/did_prospecting_change/ (April 8, 2026 discussion). A commenter reports ~20% Eversong Diamond occurrence in 200 Dazzling Thorium crafts and clarifies this is per craft, not per ore. This supports **contextual approximate P(hit)=0.20**, confidence 55/100, original integer hit count not supplied. It does NOT support unconditional expected quantity E=0.20, nor a positive min/max. Never invent 40 hits or assume each positive cast yielded exactly one diamond. The `GameData.lua` Thorium `high=0.2` is a chance-derived estimate, not a measured E.

## Reused JD3K source and patch note
https://www.wowhead.com/spell=1231127/midnight-prospecting reports 50 R2 ore of each family with aggregate outputs. The normalized 10 five-ore equivalents per family are **not** independently reported completed casts, so occurrence chance and positive min/max remain unknown. R1 ore copies have no exact-rank experiment.

Blizzard official https://worldofwarcraft.blizzard.com/en-us/news/24266320 states that Midnight gems were made more frequent, but publishes no universal numeric multiplier. A guide updated October 16, 2026 (https://dving.net/guides/wow-midnight-jewelcrafting-guide) confirms two reagent ranks and specialization-gated Diamond eligibility, but is **secondary context, not a measured cohort**.

## Reuse accounting and unresolved gaps
Independent new source cohorts: **0**. Reused original studies: **Cardinalai, Thorium commenter, JD3K** (3 distinct cohorts). Reused official mechanic note: 1. New secondary contextual guide: 1, zero cast evidence. No newly approved exact mappings or numeric fields.

Next client capture: separate `237364` versus `237365`; `237366→242608` with actual 0/1/2+ hit histogram, build/date, skill/Proficient Processor nodes, saved inputs, and exact output IDs; also Copper `237359/237361` per-rank results. Do not derive P from E, conditional ranges from averages, or zeros from missing Diamond observations.
