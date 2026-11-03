# Loot Liquidator Midnight — q30 Batch028 evidence-first selector audit
**2026-10-29 04:10 PDT · research/processing-confidence · RESEARCH ONLY**

## Scope and verified outcome
Read live queue revision **30**, exact worker assignment `2026-10-29-batch028-midnight`, latest Master batch027 verdict, source-memory snapshot, research lessons, previous q27/q29 source reviews and submissions, canonical itemdb schema/ledger and main GameData identities. **8/8 assigned stable keys** matched and **16/16 exact candidate tuples** audited. These are unadmitted leads, not confirmed conversions. **0 newly admitted exact selector mappings; 0 pair-specific numeric fields; 0 gold-ready expected quantities; 64/64 fields null**. No source supplied zero-inclusive actual completed-cast histograms or exact output rank for any assigned input.

## Substantive finding
A **2026-10-16 patch 12.1.5** Czech retail guide explicitly describes Crushing as **three of the same gem → 1–3 Glimmering Gemdust**. This aligns with firsthand April 11 Blizzard forum **three-of-a-kind** and April 18 Reddit **three equal gemstones** accounts. This is stronger **family-level same-item selector corroboration** than a generic “three Midnight gems” description, but **does not prove which of the eight item IDs/ranks the actual in-client selector accepts**, or which dust rank is produced. Sources:
- https://svetwarcraftu.cz/profese/jewelcrafting/retail/ (new secondary current-patch guide, no original cast log)
- https://us.forums.blizzard.com/en/wow/t/jc-glimmering-gemdust-is-disgusting/2272506 (reused URL, original 2026-04-11 player comment)
- https://www.reddit.com/r/wow/comments/1sp0dax/jewelcrafting/ (reused URL, original 2026-04-18 post)

**Important cost condition:** Wowhead spell `1231132` explicitly displays **Dusk-Shrouded Stone ×1**, in addition to salvage value 3 for selected gems. For a proven exact input, model **three identical gem units + one stone**, never three mixed gems and never a free stone. Stone rank `242788/242789` substitution remains unverified. The guide also mentions one-gem-to-stone processing; that is a **separate unassigned relationship**, not free output from the 3-gem dust spell. Gemdust `242620` and `242621` are output-quality alternatives.

## Independent vs derivative and numeric limits
The 12.1.5 guide is a **new secondary source**, not an independent experiment. The two player reports are firsthand qualitative evidence on **already indexed URLs**, not newly counted cohorts. A new June 20 player report of 35–40 dust from 1,000 gross ore is **not a Crushing cast denominator**, exact gem or dust-rank histogram: https://www.reddit.com/r/wow/comments/1ub8pxv/worst_profession_in_midnight/ . It supplies **zero** exact pair-level fields. The guide's family 1–3 bounds remain a **conservative tooltip-only candidate** with no pair-level promotion. No P(hit), E, max-stat inflation, skill coefficient, TSM rate, or valuation flip was inferred.

## QA and exact next IDs
All 8 unique keys, 16 unique (input,output) tuples and 64 field objects checked: **64 numeric null**, **0 false zero**, **0 economic-eligible fields**, **0 tooltip-only fields promoted**, **0 output-rank double-count**, **0 gross-input-as-casts**, **0 invented patch bridge**. Source-review events preserve new/reused status and missing fields. No master ledger, source-memory, production, main, schedules or compiler edits.

**Exact next in-client selector targets:** `242553,242723,242554,242722,242607,242720,242606,242721`; output quality IDs `242620/242621`; stone rank IDs `242788/242789`; spell `1231132`. Capture a selected **three-identical-gem** recipe (and an attempted mixed-gem selection), actual accepted input ID/rank, selected stone ID/rank, skill/knowledge/equipment/concentration, per-cast dust rank/count including zero outcomes, Resourcefulness refunds and build/patch. If no such original evidence appears, recommend **source-triggered pause/reassignment by Master** instead of repeated source-only audits.

Accompanying files: `research/coordination/submissions/loot-liquidator-midnight/2026-10-29-0410-midnight-q30-batch028-16tuple-fourfield-eligibility-audit.jsonl`, `research/evidence/observations/2026-10-29-0410-midnight-q30-batch028-same-gem-selector-corroboration-SOURCE-ONLY.md`, `research/coordination/source-reviews/loot-liquidator-midnight-2026-10-29-0410-midnight-q30-batch028.jsonl`.
