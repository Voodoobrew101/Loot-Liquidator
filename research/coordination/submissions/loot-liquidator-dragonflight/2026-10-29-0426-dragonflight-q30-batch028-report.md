# Loot Liquidator Dragonflight worker — q30 Batch028 source-triggered audit
**2026-10-29 04:26 PDT · branch research/processing-confidence · RESEARCH ONLY**

## Scope and result
Read LIVE `research/coordination/assignments.json` **queue revision 30** and exact `2026-10-29-batch028-dragonflight`, master QA batch027 verdict, source-memory snapshot, research lessons, newest q30 Midnight source review, existing source evidence, canonical itemdb schema, main `GameData.lua`, and the uncompiled lead ledger. Master explicitly assigned this Dragonflight worker **four Midnight Crushing overflow stable keys**, eight disjoint candidate tuples: inputs 242613/242724 (Flawless Sanguine Garnet R1/R2), 242612/242727 (Flawless Amani Lapis R1/R2), outputs 242620/242621 (Glimmering Gemdust R1/R2). No self-claimed Dragonflight or other worker keys.

**Audited 4/4 stable keys, 8/8 candidate tuples. Admitted new exact mappings: 0. Numeric field values supplied: 0. All 32/32 four-field values null. Tooltip-only numeric fields supplied: 0. No current Retail economic baseline.** Candidate eligibility and both output-rank mappings remain unverified.

## Substantive new finding: 2026-09-28 secondary rate inconsistency
A previously unindexed Turkish Jewelcrafting guide dated 2026-09-28 states uncommon/rare gem crushing has approximately **0.67 Gemdust per crush with talents**, without raw sample or denominator: https://wowforevertr.com/haber/254-midnight-jewelcrafting-tarifler-ve-knowledge-point-rehberi. The previously indexed Method 2026-03-05 guide states a **three-gem crush always gives 1–3 dust**, irrespective of gem quality/variety: https://www.method.gg/guides/midnight-jewelcrafting-profession-guide. Literal same-unit readings conflict. **Do not assume** 0.67 is per gem, infer 2.01 per cast, or overwrite current unknown E. Different normalization, zero-hit events, or mechanic/patch differences remain unresolved possibilities, not conclusions. This is a source-quality conflict with potential gold-decision risk, **not** a measured TSM mismatch.

## Direct item and recipe checks
All four Retail Wowhead item pages resolve to the expected Flawless uncut gem family and are source-reused, not fresh studies. The item pages' 'Reagent for' list does not include a salvage whitelist, so no conclusion of crushing eligibility or ineligibility follows. The Retail spell https://www.wowhead.com/spell=1231132/midnight-crushing explicitly requires **Dusk-Shrouded Stone 242788 ×1** and a **three-gem salvage selector**; rank-two stone 242789 substitution and exact input whitelist are unverified. `GameData.lua` contains some prospect output references for 242613/242612, **not a Crushing output proof** for any of these 8 tuples. The rank-two input IDs 242724/242727 are not present in the pinned main GameData source. Candidate item ranks are master-ledger metadata, not proof of exact selector.

## QA and lineage
- 4 distinct master stable keys, 8 unique (input,output) tuples; no overlap with Midnight's 8 q30 keys.
- 32 independent economic field objects null; all 24 tooltip-only field objects null; no fabricated zeros, no positive-bound midpoint valuation, no E×P, no rank-double-count.
- Recipe vector explicitly models 3 selected identical gems **plus one 242788 stone**; no Resourcefulness refund counted as output.
- New independent measured cohorts: **0**; new secondary source pages: **1**; reused primary item/spell pages: **5**; reused Method guide: **1**; prior Cardinalai aggregate deliberately not re-fetched.
- Source review records use master-compatible PARTIAL status and NEW/REUSED provenance. New evidence is source-only Markdown, not a falsely measured JSONL observation.
- No gold-price scenario was run; TSM decision-risk remains hypothetical and potentially material, not a demonstrated flip.

## Exact next IDs and disposition
**Next in-client capture:** inputs **242613, 242724, 242612, 242727**; outputs **242620, 242621**; required stone **242788** (test 242789 substitution separately); spell **1231132**. Record exact accepted item/rank, same-gem selection, actual completed casts including zeros, dust rank/count, patch, skill/knowledge/gear and Resourcefulness refunds. Without such a source trigger, Master should pause/reassign rather than repeatedly audit known source-only candidates. Worker did not edit assignments, shared ledgers, source-memory, registry, itemdb.lua, production Lua/TOC, main or schedule.

Deliverables: this report; 8-row four-field JSONL; source-only evidence note; source-review events.
