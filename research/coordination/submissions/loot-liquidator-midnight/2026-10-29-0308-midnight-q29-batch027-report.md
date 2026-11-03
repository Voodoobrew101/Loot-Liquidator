# Loot Liquidator Midnight Batch 027 — queue29 TWW milling overflow
**2026-10-29 · branch `research/processing-confidence` · assignment `2026-10-29-batch027-midnight` · RESEARCH ONLY**

## Exact assigned scope and outcome
**6/6** assigned stable keys audited: Mycobloom R1 `210796`→Nacreous Pigment R2 `222619`, Mycobloom R2 `210797`→R2 `222619`, Mycobloom R3 `210798`→R1 `222618`, and Luredrop R1/R2/R3 `210799/210800/210801`→Luredrop Pigment `222612/222613/222614`. The first two have 2024 original-player **historical cross-rank/same-rank eligibility** support; the other four have family-level support but no exact rank-selector proof.

**0 newly admitted material mappings; 0 new current-Retail economic numeric fields; 0 new exact-rank tooltip numeric fields.** All **24/24** exact-context P(hit), positive yield min/max and unconditional E fields remain **unknown**, not zero. No actual 2026 completed-cast sample, exact skill/stat cohort, or defensible per-cast rank histogram was found. No gold recommendation flip was priced.

## Material finding: historical R1→R2 provenance erratum
The original September 10 2024 Mycobloom author (https://www.reddit.com/r/woweconomy/comments/1fdmzwy) explicitly states R1 Mycobloom yielded **R2** Nacreous at sufficient skill; prior q27 **source-review event** mistakenly describes R1→R1. This run preserves an immutable correction in the evidence note, without altering the prior worker's file. The author's 1.15 vs 1.35 pigments per herb over 20k+ combined herbs are gross-input historical averages with unknown actual casts/refunds. Nominal 11.5 vs 13.5 per ten herbs is **not** gold-ready E. Same original author, not a newly independent study.

## New source discovery and P2 risks
Two previously unindexed firsthand **2024** source anecdotes were identified: a beta test reports 11–15 R1 versus 9–13 R2 pigment per mill under different skill conditions (https://www.reddit.com/r/woweconomy/comments/1ey4dkl); another player recalls 11–17 Luredrop pigment per mill (https://www.reddit.com/r/woweconomy/comments/1fb0vv5). Neither identifies an exact assigned output-rank/skill cohort with a valid sample denominator; **do not promote them into tooltip ranges or gold E**. A third newly located 2024 milling calculator post (https://www.reddit.com/r/woweconomy/comments/1g6jcfr) is a model lead, not a verified measured study. Previously indexed Method/LotzBoi/recipe/Mycobloom sources were reused without duplicate source credit.

**Production-risk flag for Master QA:** `StatYieldProfiles.lua` still contains `210796→222616` and `210797→222617` modeled milling outputs, but both output IDs are **Apricate Ink**, not Nacreous Pigment. This was already noted in q27 and remains present in the inspected source; never compile these into itemdb. No production edit is permitted in this worker. The Luredrop same-rank profile also remains conditional on skill. The overlay's modeled 10–12 high quantity conflicts contextually with historical 11–17 anecdote, but **no matched TSM/2026 economic decision flip** is proven.

## Queue/source efficiency and QA
Read live q29 assignment, q26 Master verdict and feedback, source-memory, research-lessons, q27 War Within original study/source review, q28 Midnight report, GameData, StatYieldProfiles, and current itemdb schema context. **All six exact input/output pairs had earlier q27 attention** (two under lead keys and four candidate keys); q29's "untouched" label is not a first-pass novelty guarantee. Do not award six first-pass credits. Kept 2 new firsthand sources and 1 new calculator lead distinct from 1 reused 2024 author. Refrained from re-fetching old cohorts for novelty.

**Validation:** 6 distinct assigned keys, 6 unique exact tuples, 24 null economic field values, 0 nonzero fabricated values, 0 tooltip-to-gold leakage, 0 cast-denominator substitutions, 0 unverified current patch claim, 0 writes to master ledgers/source-memory/assignments, main, production Lua/TOC or schedules. All records include exact source links, patch limitations, field-level blockers and rank context.

**Master next IDs:** `210796→222619` and `210797→222619` first (skill-gated R2 pigment), then `210798→222618` and `210799→222612`, `210800→222613`, `210801→222614`. Seek 2026 Retail actual completed-cast counts, per-output zero-inclusive results, skill/spec, Resourcefulness and current patch. When six assigned gaps are resolved or master deems evidence exhausted, request reassignment through master; do not self-claim other worker keys.

See accompanying exact-key audit JSONL, source-review events and immutable evidence/erratum note. **No staged compiler or client tests claimed.**
