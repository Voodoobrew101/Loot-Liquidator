# Dragonflight Batch025 — queue27 exact milling and fish numeric gap audit
**2026-10-29 · worker loot-liquidator-dragonflight · research/processing-confidence · RESEARCH ONLY**

## Live assignment and provenance
Read queue revision **27**, exact assignment **2026-10-29-batch025-dragonflight**, Master QA batch024 verdict, master research-lessons, 213-source/372-review source-memory, q26 Dragonflight and Legacy submissions and source reviews, compiler v0.7.0, pinned GameData.lua blob **1d47c4a961c5dc5af626e659f7d96d1490d3cf9e**, missing-fields ledger and staged itemdb. Checked no assigned stable key overlaps another worker. **14/14 source lines and parent input IDs match exactly**. The 14 assigned keys are 12 herb rank-specific rows (Bubble Poppy R3 and Writhebark R1/R2/R3) plus Prismatic Leaper 200061→Rousing Order 190322 and Serene Pigment R1 198412.

## P0: exact data state and high-impact guard
- **0 new legitimate mappings; 0 corrected IDs; 0 new verified current-Retail numeric fields.** The 14 current-context P(hit) remain unknown. **13/14 economic expectedQuantity cells are already null** in compiler v0.7.0. The 14th, fish→Rousing Order, retains a low-confidence historical TSM proxy **E=0.005 per five fish**; it is **not** an independently validated current-Retail gold input. Do not promote or silently treat that proxy as a measured expectation.
- **12 herb rows** retain source-stated 2–5 positive pigment range, but this is a **2022 beta pigment-family** statement, not measured 2026 per-output-quality bounds. Do not overwrite stronger measurements or compute P/E from the bounds. The fish→Rousing Order source has min=max 1; fish→Serene R1 has 2–5; both only historical TSM references with unknown sample and skill.
- **Fish→Rousing Order 190322:** confirmed output item identity via Retail Wowhead (https://www.wowhead.com/item=190322), but no independently observed fish milling source. The pinned GameData row at L1996 is the only mapping support in this batch. Its TSM matRate=0.002 and per-five-source proxy E=0.005 are not directly comparable without proven units. The compiler flags P/E inconsistency and suppresses P. Do not delete the candidate on absence of corroboration, nor treat the proxy as current economic evidence.
- **Fish→Serene R1 198412:** Primer's reused original 3-cast/15-fish study on https://www.wowhead.com/item=200061 reports Serene **R2 198413**, Flourishing R2/R3; **not** R1 198412. No zero-inclusive R1 histogram, and no inference of P=0.
- **12/12 herb source identities** map Bubble Poppy R3 191469→Serene 198412/198413/198414 and Writhebark 191470/191471/191472→Flourishing 198415/198416/198417, with 5 herbs per operation. Source GameData quality ranks are claims to audit, not measured current-client availability.

## P1 numeric invariants and rank grouping
The source assigns matRate=1, amountOfMats=.7 and 2–5 positive family bounds to **each** of the three rank variants of one herb. If all three are treated as simultaneous and the unverified 5×.7 scaling is used, this yields 3×3.5=**10.5 pigments** instead of one family's illustrative **3.5**. This **3× decision-risk** is not proof of a production defect or a verified EV; keep ranks mutually exclusive where current game behavior confirms this. The compiler already quarantines 12 rank-specific E fields. The fish row 190322 has min=max1 but no matched zero-inclusive P and no valid E denominator; exact numeric values stay unknown.

Newly indexed **2023-01-24 firsthand anecdote** https://www.reddit.com/r/woweconomy/comments/10k8158 recalls (“IIRC”) skill 250 to guarantee R3 pigment. This is **not** a completed-cast study and cannot validate the old 2022 beta thresholds for 2026. It is a distinct author, not a second measured cohort. Prior source 2022 beta and Wowhead reproduction remain one original lineage. No new original zero-inclusive cohort found. Exact cast-level plot grouping by skill, input/output rank, Inspiration and patch remains required for a validated model.

## Source status and continuous improvement
- New indexed source: 2023 anecdotal rank-threshold thread (one author, no casts); new Retail item-identity source: Rousing Order 190322 (identity only).
- Reused without independent-count inflation: Liqourice5 beta report via Wowhead and Primer three-fish-cast comment. Existing source-memory consulted before re-fetch; no repeat fetch of already-absent fish loot tab. New source review events: 4, using supported statuses DISCOVERED/PARTIAL.
- Novel accepted-value yield pending master review: **0**. Useful negative: historical fish three-cast study is not a measured zero for 190322 or 198412; 2023 rank threshold lacks denominator; 2–5 family range cannot fill exact-rank 2026 E.
- TSM decision risk: all-rank sum could overstate pigment value 3×; fish→Rousing Order low-confidence E could be misused without an explicit economic-eligibility guard. No current AH prices or liquidation flips were measured.

## Next exact targets and master handoff
1. Herb 191469→198412/198413/198414, and 191470/191471/191472→198415/198416/198417: actual 2026 **five-herb completed-operation** zero-inclusive output-ID histograms stratified by skill, Inspiration, profession specialization and patch.
2. Fish 200061→190322: verify eligibility and count actual Rousing Order hits per completed five-fish mill. Separate fishing catches from milling casts.
3. Fish 200061→198412: verify Serene **R1**, not historical Primer's R2 198413.
4. Master QA: ensure low-confidence TSM E=0.005 for 200061→190322 is not mistaken for verified current-Retail economic E; test rank-exclusive valuation and tooltip-only channel isolation.

**No production Lua/TOC, main, master assignments, shared ledgers, source-memory or schedules were modified.**
