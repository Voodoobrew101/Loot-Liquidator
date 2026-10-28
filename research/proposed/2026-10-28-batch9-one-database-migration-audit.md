# Batch 9 — One-database migration audit (2026-10-28)

Source of truth: main/GameData.lua blob 1d47c4a961c5dc5af626e659f7d96d1490d3cf9e; main/StatYieldProfiles.lua blob 1d80df8304acaa75a5b507089ef163696381b2ff; main/Professions.lua blob 442c84c4e2cc287de9ccc0aaf6f55f82c641a107; Issue #2. Previous research ledger 1,256 rows, 389 profiles, 92 supplemental runtime mappings. Main ZIP former path 404; extracted source inspected. No production edits.

## Concrete migration inventory
- StatYieldProfiles lines 30-61: 3 TWW ore families x 3 quality IDs = 9 input profiles; output row counts 3+5+5 per family, repeated across qualities = 39 output mapping rows. These are player-batch anchors plus modeled high, not verified current-condition probabilities.
- Lines 64-99: TWW milling 4 herb families x 3 quality IDs = 12 profiles; Midnight milling 4 herb families x 2 quality IDs = 8 profiles. One output row per input profile = 20 output mapping rows. Low/high scenarios are assumptions; do not promote to observed.
- Lines 101-107: 3 Arathor's Spear quality IDs and 2 unverified herb IDs deleted from gd.mill at load. Migration must represent eligibility/exclusion in GameData with source and evidence rather than runtime deletion.
- Lines 110-116: Null Stone ID 210939 has 3 output mapping rows, one reported operation only.
- Lines 119-138: Dragonflight milling profile generator creates per-input material mappings from existing TSM rows; preserve raw TSM and distinguish modeled high.
- Lines 213-273: runtime loops mutate compiled gd.prospect and gd.mill empty candidates from stat profiles or TSM. Preserve evidence but remove load-order-dependent database mutation after migration.
- Lines 276-279: 3 expansion IDs x 3 item rarities = 9 disenchant fallback material anchors, outside GameData. Lines 280-320 model fallback quantities and skill upgrades. Must migrate mapping and retain explicit uncertainty.
- Lines 10-24: rangeFor adjusts/invents tooltip occurrence and integer bounds from expectedQuantity; this is a display heuristic, not independently measured drop chance/range. Any contradictory fields must retain raw values and be flagged; do not treat altered ranges as evidence.

## Valuation and conditions contract
Keep one authoritative GameData mapping per method/input/output/condition. Real character expansion-specific skill and verifiable stats first; explicitly simulated settings context second; documented low-skill fallback third. Do not assume uniform linear slider effects. Store P(at least one output), conditional integer min/max, and unconditional decimal expected units separately. Only unconditional expected units enter gold valuation; normalize batch once. Existing runtime source precedence and personal blending unit mismatch remain separate integration blockers.

## Independent QA
Re-read original code around each claim; counted 9+20+3+9 direct profile/fallback groups, 5 deletions, and the dynamic DF generator separately to avoid counting duplicates as unique output pairs. This report is a static source audit; no WoW client tests or new measured yields. No score promotion. Existing ledger remains 0/1256 at >=90, 0 at 70-89, 1256 below 70, lowest 0. This is source-row coverage, not complete inventory of every non-processing gameplay field in GameData. Full all-field gate NOT MET.

## Next
1. Move static TWW/Midnight/Null Stone/DE output mappings into a proposed GameData-only schema on research branch, preserving exact item IDs and evidence labels.
2. Add source-based checks for no static output mappings or gd table mutation outside GameData and for expectedQuantity/occurrence/range independence.
3. Verify eligibility of Arathor's Spear, then compare TWW/DF milling profiles against authentic sources and character skill/quality context.
