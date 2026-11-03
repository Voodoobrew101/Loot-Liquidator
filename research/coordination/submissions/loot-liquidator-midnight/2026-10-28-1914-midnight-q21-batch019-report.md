# Midnight q21 Batch 019 — exact-key audit and salvage identity QA
**2026-10-28 19:14 PDT · branch `research/processing-confidence` · worker-only research**

## Scope
Live queue revision **21**, assignment **2026-10-28-batch019-midnight**. **35/35** exact master-owned stable keys, **24** prospecting GameData source-line rows and **11** Crushing salvage candidates; zero cross-scope claims. Read live assignments, master batch018 verdict, research lessons, source memory and prior Midnight source-review events before this run. All **24/24** GameData source-line IDs and output IDs matched the pinned main source.

## P0 findings
- **0 new legitimate input→output mappings.** The 24 prospecting relationships are already in GameData. All 11 Crushing candidate item identities were individually checked against live item pages, including the paired distinct IDs 242606/242721, 242613/242724, 242612/242727, 242610/242726 and 242611/242725. A shared item name is not evidence of interchangeable quality or whitelist eligibility.
- Spell 1231132 specifies **3 selected gems + 1 Dusk-Shrouded Stone**, not three stone-free gems. Exact 11-ID salvage selector eligibility and Gemdust output rank remain **UNKNOWN**. No unsupported conversion was admitted.
- **Five assigned GameData `low > high` scenario pairs:** midnight:237361:242786:L738, midnight:237362:242611:L754, midnight:237363:242611:L765, midnight:237359:242553:L729, midnight:237361:242553:L740. These are not min/max yield contradictions: the labels are low-skill versus high-skill profile estimates, not ordered positive-outcome bounds. Do not reinterpret them as `yieldMin/yieldMax`.

## P1 four independent fields
**140/140 exact-context numeric slots remain UNKNOWN**, with confidence 0 for unknown: dropChance, positive yieldMin, positive yieldMax and zero-inclusive expectedQuantity. No current-Retail exact-rank completed-cast histogram was discovered. Historical low/high values are preserved in separate `sourceProfileReference` objects and cannot silently become measured probabilities, expected quantities or positive bounds. A historical 800-cast Silver Diamond study has unspecified input rank; original Thorium 200-craft '20%' is an ambiguous self-report, not a measured exact-context hit histogram.

## P2 decision risk
- Highest: Diamond rows 237359/237361/237362/237363/237364/237365/237366→242608 with ore-specific specialization gates, especially Silver R2 and Thorium; an unverified zero-low profile does **not** prove zero possible output.
- Tin R1/R2 gem and byproduct rank transfer and five inverted low/high scenario labels could lead to a false gold-optimal recommendation if treated as actual bounds or universal skill multipliers.
- Crushing requires stone cost plus three selected gem units, with rank-specific Gemdust outputs and Resourcefulness savings modeled separately. Without exact salvage whitelist and cost vector, **fail closed** rather than choose Crushing.
- No current AH price check or confirmed liquidation-action flip.

## Continuous improvement
Source-memory checked before fetching: 11 item URLs and spell 1231132 are **REUSED**. The October 3 2026 Reddit discussion is **NEW_QUALITATIVE**, separate commenters but **0 measured cohorts**. Avoided re-fetching previously archived JD3K, Cardinalai and Headtrip source tables; re-opened item pages only to validate exact q21 IDs. Source-review events retain missing fields and duplication ancestry. No reward scores were altered; source review points do not affect confidence.

## Outcomes / handoff
**New valid mappings: 0. New current-Retail numeric fields: 0. New independent measured cohorts: 0.** Reconciled 11 item identities; 5 explicit scenario-label hazards; 1 newly indexed qualitative October discussion; 35 exact keys audited. Next exact priority IDs: `237365→242608`, `237366→242608`, `237359/237361→242553`, `237362/237363→242606/242607/242610/242611`, then `242720/242721/242724/242725/242726/242727` Crushing selector eligibility, `242620/242621` Gemdust rank outcomes and Dusk-Shrouded Stone `242788`. Collect original completed casts with zeros, actual sampling date/build, input rank, skill/knowledge, Resourcefulness saved units, and exact output IDs. Master owns all promotions and next assignments.

No main, production Lua/TOC, canonical registry, master assignments, ledgers, source-memory or schedules changed. No Node/Lua/client execution; static JSONL, key, line and numeric checks only. Candidate baseline at read: v0.6.0, 1,003 provisional mappings, 801 four-field complete, 462 missing cells; not exhaustive Retail coverage.
