# Master QA batch017 — recipe-scoped BfA mass milling and queue19 independent review
**2026-10-28 · research/processing-confidence · research-only**

## P0 actual compiler/build
Compiled research/proposed/itemdb.lua v0.6.0 twice in isolated JavaScript; deterministic, static invariants passed, 1,202 source-line identities verified. Committed generated Lua and 27 new missing-field cells. Nine distinct historical BfA 20-herb mass-milling output records added, preserving recipe spell IDs, full reagent vectors, operationVariant, per-cast rounded expectedQuantity, sampleOperations, field uncertainty and unknown P/min/max. Sources: https://www.wowhead.com/item=153669/viridescent-pigment and recipes https://www.wowhead.com/spell=256218/mass-mill-star-moss, https://www.wowhead.com/spell=256223/mass-mill-sea-stalk, https://www.wowhead.com/spell=256221/mass-mill-sirens-pollen. Original Jiyao revised study: 177 Star Moss, 106 Sea Stalk and 103 Siren's Pollen mass casts, ONE original author. Per 20-herb cast output means respectively (15.48,5.89,2.87), (16.39,5.96,2.57), (15.89,5.85,2.12) for Ultramarine/Crimson/Viridescent. Values are rounded historical means, not current Retail or observed standard five-herb cast means.

## Worker QA
150/150 queue19 stable keys checked; 19+23+39+39=120 original GameData output-line identities independently checked, zero mismatches. Four-field slots: 159 historical/provisional references, 441 unknown, zero newly verified current-Retail numeric fields. Midnight Crushing exact salvage whitelist and Gemdust ranks blocked despite spell confirming 3 selected gems + one stone. July 0.83925 vs older 0.6875 dust per gem is contextual, not exact completed-cast E. TWW samples=100 cannot be treated as cast denominator. Dragonflight beta skill 250 GUARANTEES R3, does not forbid low-skill R3; immutable worker erratum accepted, zero numerical promotions. Jallfo beta original and derivative Wowhead narrative are one study, not two.

## Coverage and evidence
A) 1003/1003 compiler-admitted mappings represented across 167 inputs; not exhaustive.
B) 801/1003 four-field complete (79.86%), 462 unknown numeric cells/4012 slots: P189, min85, max85, E103; E present 900. All 1003 provisional. Candidate field bands: >=90:0, 70–89:40, below70:3972. Evidence score is not a statistical accuracy percentage.
C) Exhaustive Retail universe NOT audited. 16 Midnight Crushing families remain uncompiled, 52 generic disenchant profiles have no concrete input IDs, 54 quarantined legacy source rows (including those profiles), 227 overlapping source alternatives. Historical first-pass inventory 1643/1737, 94 never examined, not exhaustive.

## Persistence and limits
Master QA feedback: seven unique claimIDs. Source memory incrementally replayed 17 q19 review events and seven QA events; 0 new invalid events. New cache 152 sources, 183 review events, 58 QA events. FULL Node rebuild was attempted but blocked by per-run tool-call ceiling for 95 JSONL files; not claimed complete. Node CLI, independent Lua interpreter and actual WoW client tests were not executed. Queue revision20 assigns 35 Midnight, 35 War Within/DF overflow, 40 Dragonflight and 40 Legacy disjoint exact keys, prioritizing 68 previously unassigned numeric gaps, 9 new mass recipes and source conflicts. No production/main/TOC, PR #3 or schedules modified.

## Next priority
Obtain current 2026 exact-rank completed-cast histograms for 103 missing E cells, verify BfA mass versus standard client eligibility, prove Midnight Crushing exact input/stone/dust rank whitelist, and audit TWW Gem Finding displacement without invented coefficients.
