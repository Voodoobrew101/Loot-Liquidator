# Master QA batch016 — source lineage correction, model rebuild and material-gap triage
**Date:** 2026-10-28 · **Branch:** research/processing-confidence · **Research-only, no production writes**

## P0: Actual candidate compiler execution
- Executed the committed pure-JavaScript compiler in an isolated V8 environment against the current live-branch ledger, GameData.lua, StatYieldProfiles.lua, curated additions and prior QA input files. **Generated Lua matched committed research/proposed/itemdb.lua byte-for-byte** (681,857 characters).
- Re-executed the full research/tests/test_compile_itemdb.js static regression in V8 using read-only repository fixtures and a minimal Node fs/assert/path shim: **PASS**. The separate source-memory unit suite also passed in V8 with a URL shim. These are NOT claims that Node CLI, Lua interpreter, or the WoW client were run.
- Compiler v0.5.0 unchanged: **994 source-admitted mappings / 167 inputs**, 1,202 GameData source-line identities checked, 801/994 four-field numeric complete, 193 incomplete records, 435 unknown numeric cells across 3,976 field slots (P180, min76, max76, E103). All 994 records provisional; zero current-Retail unskilled baselines independently verified. Field confidence >=90:0, 70-89:40, <70:3,936. No new mapping or numeric promotion was justified by the submitted q18 evidence.
- Source-inventory mapping coverage 994/994 applies **ONLY to compiler-admitted mappings**. Independent exhaustive Retail universe audit remains NOT COMPLETE. 16 Midnight Crushing families, 52 generic DE profiles without concrete gear IDs and other recipe/eligibility gaps remain outside the current candidate.

## P1: Four-worker independent QA (queue18, 150/150 disjoint keys)
| Worker | Assigned = reviewed | Source-line identities | New legitimate mapping | New current Retail cast field | Outcome |
|---|---:|---:|---:|---:|---|
| Midnight | 35 | 35 | 0 | 0 | ACCEPTED_REUSE; no rank/patch transfer |
| War Within | 35 | 27 | 0 | 0 | ACCEPTED_NEW_HISTORICAL_SOURCE_ONLY; 2 original 2024 commenters |
| Dragonflight | 40 | 39 | 0 | 0 | ACCEPTED_SOURCE_ID_CORRECTION; original Primer 3-cast source |
| Legacy | 40 | 39 | 0 | 0 | ACCEPTED_NEW_HISTORICAL_SOURCE_ONLY; Almar raw totals |
| **Total** | **150** | **140** | **0** | **0** | No duplicate assignment keys, no P/E/range invariant failures in submitted numeric cells |

All 150 stable keys match queue18 exactly. Original GameData output IDs at all 140 cited source lines were rechecked; the remaining 10 are curated/no-source-line candidates, not falsely counted as line matches. Four-field worker audits contain historical proxies and unknowns, not 150 newly verified conversion rates.

## P2: Source corrections and gold-decision implications
1. **Prismatic Leaper / Primer source attribution CORRECTED:** original commenter reports 15 fish / 5 per mill = 3 completed casts, with 3 Serene R2, 5 Flourishing R2, 2 Flourishing R3. Original source independently inspected: https://www.wowhead.com/item=200061/prismatic-leaper . The original Serene R2 item is **198413**, not Blazing R2 **198419**. Source-specific attribution is repaired by master-owned research/coordination/source-attribution-corrections.json, enforced in deterministic source-memory builder/tests. The possible TSM fish→198419 mapping remains separately unverified, not deleted. Historical descriptive E for Flourishing R2 = 5/3 and R3 = 2/3 per three reported operations; **no current-Retail candidate promotion** because sample n=3, skill/patch and per-cast hit histograms absent.
2. **Almar Titanium original independently inspected:** https://almarsguides.com/wow/farming/wotlk/otherlocations/Prospecting/ lists 121 powder and six uncommon gem totals, but **no ore or completed-cast denominator**. Accepted as a separate historical source, rejected for any numeric E/P promotion. Source-memory builder corrected so descriptive originalDocumentRef text cannot be misinterpreted as a canonical URL.
3. **TWW Ironclaw/Aqirite historical original commenters:** two distinct 2024-09-17 reported cohorts preserved source-only (https://www.reddit.com/r/woweconomy/comments/1fisfkn). Initial ore 10,000 each, but actual casts, refunded-ore recycling, output ranks, patch and spec differ. Their raw totals cannot be current-Retail E. The original thread was not independently retrievable in the public web session; worker source-only observations and arithmetic were reviewed without inflating confidence.
4. **Midnight Silver:** reused 800 actual operations, 43 diamonds => historical E=0.05375; 3,285 ore consumed + 715 saved = 4,000. Unknown exact ore rank and patch block assigning that E to either ranked input.
5. **Gold risk:** fish quality-rank double counting, specialist gem displacement versus Amber, TWW Resourcefulness, historical 20-herb mass milling versus five-herb standard, and excluded Crushing reagents can all change optimal liquidation. No current AH prices, current-patch matched casts or demonstrated gold-action flips were available.

## P0/P1 persistence, memory and assignment
- Corrected two stale mapping-gap rows: both Midnight refining recipes are **already staged provisionally**, not absent; client recipe/eligibility checks remain outstanding.
- Incrementally replayed **56 q17/q18 source-review events**, **3 source-only original observations**, and **13 q15/q16 master QA feedback events** into source-memory. Canonicalized/merged two duplicate URL slash variants. Result: **146 canonical source keys, 166 review events, 51 QA events**, 50 positively classified feedback events. This was an incremental replay, **not** a full Node directory rebuild. Legacy malformed review warnings remain visible, not silently erased.
- Approved one durable Primer source-ID correction and a URL-source parsing fix with regression tests. The research-stage Lua was rebuilt identically; no fake version bump or unsupported numeric value was introduced.
- Queue **revision 19** assigns **150 distinct exact material/recipe keys**: Midnight 16 Crushing + 19 output gaps; TWW 21 native + 14 Dragonflight overflow; Dragonflight 40 disjoint rank-specific gaps; Legacy 31 historical gaps + 9 milling comparisons. Worker-owned evidence only; master retains sole compiler/queue/registry authority.
- No numeric mechanics rule approved, no PR #3 merge, no production main/GameData.lua/TOC/addon changes, no schedule changes.

## Follow-up
Priority: (1) verify 16 Crushing exact gem input/reagent/output ranks, (2) obtain current 2026 zero-inclusive rank/spec/patch casts for TWW and Midnight, (3) fix 103 missing candidate expectedQuantity cells with actual operation denominators, (4) audit Dragonflight fish/pigment ranks, (5) run Node CLI, independent Lua interpreter and WoW client tests when executable repository environment is available.

**Completion gates:** A) admitted mapping coverage 994/994; B) four-field numeric completeness 801/994 = 80.58%; C) independently audited exhaustive Retail universe NOT COMPLETE. Evidence scores are support strength, not statistical accuracy.
