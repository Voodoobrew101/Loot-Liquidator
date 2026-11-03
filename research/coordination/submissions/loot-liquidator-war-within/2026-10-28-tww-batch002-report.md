# The War Within — worker batch 002 (2026-10-28)

**Assignment:** `2026-10-28-batch002-war_within`; 30/30 distinct assigned stable keys audited. **Research-only**. No edits to main, production addon Lua, master-owned assignment queue or central ledgers.

## Coverage and provenance
- 12 TWW milling output overlays, 3 Null Stone prospecting overlays, 15 compiled source profiles. 30 unique first-pass examinations submitted for master acceptance; all 30 were NEVER_EXAMINED in the fetched central ledger. Do not count as centrally accepted until master QA.
- **All 30 EXAMINED_INSUFFICIENT**, none independently substantiated >=90. Output occurrence probability, true positive conditional yield bounds and current-Retail unconditional mean remain unsupported (0 evidence confidence for at least one field). Scores in CSV are evidence-strength judgments, NOT statistical accuracies.
- Compared `GameData.lua` SHA `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`, `StatYieldProfiles.lua` SHA `1d80df8304acaa75a5b507089ef163696381b2ff`, queue SHA `54b2a838f6a461a9ac688d0d9fe0c0bdc433adea`, coverage ledger SHA `f69b5818584abdf69912aa4438591e2f01f6af05`. No source modification.

## Findings

### 1. Twelve TWW milling overlays — rank conflation and modeled yields
Method's [Aug 10 2024 milling guide](https://www.method.gg/guides/the-war-within-herb-milling-and-pigment-guide) identifies Mycobloom -> Nacreous, Luredrop -> Luredrop, Orbinid -> Orbinid, Blessing Blossom -> Blossom pigments. The guide explicitly states **three pigment qualities** and that output rank depends on herb quality **plus Inscription skill and knowledge**, not input rank alone. It also states higher input herb rank does not increase pigment **count**.

The existing `StatYieldProfiles.lua` helper maps rank-1, -2, -3 input directly to matching pigment item ID (one output each). It sets **low E=10 and high E=12 pigments/10 herbs**, with provisional 8–12 and 10–15 ranges. Those figures are not verified measured per-cast distributions. A [Wowhead Nacreous Pigment community comment](https://www.wowhead.com/item=222618/nacreous-pigment) instead reports, under specified illustrative skill increments, 4–6 / 5–7 / 6–8 pigments per ten-herb cast, and distinct effective-skill quality thresholds. These are **unreplicated player claims** with unspecified patch/spec details; preserve as research leads only. The comments do NOT establish a universal mean or true game min/max, nor authorize replacing existing numbers.

The [Method TWW Inscription leveling guide](https://www.method.gg/guides/the-war-within-inscription-profession-leveling-guide) independently confirms **10 herbs per milling operation**, so no five-herb conversion is appropriate. A [Blizzard player bug report from Sep 5 2024](https://us.forums.blizzard.com/en/wow/t/anyone-else-having-issues-getting-mycobloom-to-mill-via-create-all/1944679) likewise references ten Mycobloom per craft.

### 2. Arathor's Spear — two assigned compiled source profiles
`GameData.lua` contains candidate profiles 210808 and 210809, but `StatYieldProfiles.lua` explicitly removes 210808–210810 from milling. The [Mar 27 2025 Blizzard-hosted forum report](https://us.forums.blizzard.com/en/wow/t/inscription-arathors-spear-not-on-milling-list/2083666) describes no milling option for Arathor's Spear; Method's four-pigment mapping also excludes it. This strongly supports historical exclusion, but is **not a 2026 in-client eligibility check**. Do not ship or restore a fictional Arathor milling output. The unassigned third rank 210810 was noted but not counted as new first-pass coverage.

### 3. Null Stone — source-versus-overlay contradiction
The original [Wowhead Algari Prospecting DobberSH comment](https://www.wowhead.com/spell=434018/algari-prospecting) reports **one five-Null-Stone operation** yielding 1 Radiant Ruby (212495), 1 Extravagant Emerald (212505), 1 Handful of Pebbles (213398), and 1 Glittering Glass (213399). The current `StatYieldProfiles.lua` narrative instead says 2 pebbles + Sapphire (212508) + Onyx (212511), and its three output rows reflect that unsupported story. **That is a concrete source transcription mismatch.** The single cast does not prove Sapphire/Onyx impossible; it simply cannot substantiate the claimed observed outcome. Archive the original four-output cast and request master QA to quarantine the wrong provenance. A cast of one cannot yield reliable population P(drop), conditional game bounds or current-Retail expected quantities.

### 4. Prospecting patch boundary
A [Wowhead economy hotfix summary](https://www.wowhead.com/ptr/news/recent-prospecting-changes-wowhead-economy-weekly-wrap-up-351-349956) describes the October 25 2024 changes to prospecting byproducts and gem rates. The Null Stone comment has no reliable date, so **current patch applicability is BLOCKED**. No historical mean was promoted to current Retail.

## QA performed
- Exact 30 stable keys, 15 overlays + 15 profiles, unique and source-present: PASS.
- All 30 central ledger statuses `NEVER_EXAMINED` at read time: PASS.
- Four-output single-cast JSONL: exact input count=5, operations=1, four total output units, each histogram `{"1":1}` and hit+zero=1: PASS.
- Observation required-key and field-evidence structural checks against current observation schema: PASS. Full JSON Schema/AJV validation and WoW-client tests: NOT RUN.
- No artificial E=P×E, min/max midpoint, five-herb normalization, invented per-rank yield, or source-to-current-patch transformation.
- Raw study sample: one operation; its per-cast extrema are *observed sample extrema only*, not the true conditional game bounds.

## Master QA actions
1. Review and accept/reject 30 distinct first-pass keys; reconcile ledger (baseline 1543 NEVER_EXAMINED, if no competing submissions and all accepted then 1513).
2. Independently review Null Stone transcription mismatch; keep unverified sapphire/onyx possibility distinct from *reported* one-cast outputs. Reject unsupported legacy 2/1/1 source provenance.
3. Treat TWW milling output rank as conditional on effective skill and knowledge, not fixed input rank; require current Retail test.
4. Seek patch-matched 2026 cast-by-cast ten-herb studies with exact skill, talents, equipment, herb rank, pigment rank, histograms and counts. Confirm 2026 Arathor eligibility.

**Next assignment preview from master:** `profile:compiled:prospect:210931`, `profile:compiled:prospect:210932`, `profile:compiled:prospect:210933`, `profile:compiled:prospect:210934`, `profile:compiled:prospect:210935`, `profile:compiled:prospect:210936`, `profile:compiled:prospect:210937`, `profile:compiled:prospect:210938`. Do not self-claim outside this assignment.

**Overall all-material-fields >=90 gate:** NOT MET.
