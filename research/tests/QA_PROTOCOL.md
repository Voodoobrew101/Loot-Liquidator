# Reproducible processing QA protocol — source snapshot 2026-10-27

## Source and scope
- GitHub main `GameData.lua` SHA `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e` (228,130 bytes reported by GitHub).
- `StatYieldProfiles.lua` is a separate runtime overlay and must be audited in addition to static GameData. It creates TWW/Midnight/Dragonflight milling and prospecting models.
- Research branch files do not alter the released addon. The originally referenced v0.9.70 ZIP was **not present** at the expected main path on this run; GitHub main contains the extracted Lua sources, which were read directly.
- Tests below were run as read-only JavaScript source scans against the actual fetched `GameData.lua`, not in the WoW client.

## 1. Inventory regression gate (passed)
- Static compiled `gd.mill`: 122 input records, 48 material rows, 102 empty initial arrays.
- Static compiled `gd.prospect`: 57 input records, 50 material rows, 47 empty initial arrays.
- `gd.tsmRetail.mill`: 98 inputs, 225 material rows.
- `gd.tsmRetail.prospect`: 42 inputs, 678 material rows.
- `gd.disenchant`: 40 expansion/rarity/gear-kind profiles, 52 output rows, 3 profiles without outputs, 12 output rows without integer min/max.
- `gd.smelt`: 8 recipe records.
- `gd.tokens`: 1 static reward association.
- `gd.midnightProspectingProfiles`: 7 ore/rank profiles, 49 output anchors.
- `gd.dragonflightProspectingProfiles`: 11 profiles, 142 output anchors.
- `gd.conditionModels`: 3 profiles, 3 positive output observations.
- **Total source profiles inventoried: 389.**
- **Total source output rows inventoried: 1,256** (1,001 compiled+TSM and 255 supplemental). These are source rows, not 1,256 unique live item-output pairs: duplicate sources and runtime overlays are intentionally tracked separately.

## 2. Three-field invariants (executed)
For each TSM output, define `p = matRate`, `E = amountOfMats * 5` for a five-input operation, `a = minAmount`, `b = maxAmount`. For genuinely condition-matched fields:
`0 <= p <= 1`, `a,b` are integers with `1 <= a <= b`, `E >= 0`, and `p*a <= E <= p*b`.
For a compiled source, `expectedQuantity` is already per `batch`, not per individual input; do NOT multiply by batch again. A source may have missing p/range without making E invalid.

- TSM rows with nonempty p, min, max, and E: **903/903**.
- **40/903 TSM rows violate** `p*min <= E <= p*max` with tolerance `1e-8`; full list in `tsm-invariant-anomalies.csv`.
- Among these, **12** Cobalt/Titanium uncommon gem rows are severe: `E=2.5` vs permitted `[0.235,0.470]`.
- The other 28 include plausible precision effects and other real mismatches; no silent numeric correction is made.
- All **52 disenchant output rows** checked; **0** violations among the **40** rows with both min/max present (tolerance `1e-6`); **12** have missing min/max and cannot pass that field's confidence gate.
- **98** compiled prospect/mill output rows have no explicit conditional min/max; runtime display annotations may be generated later, but those are not verified observed bounds.

## 3. Valuation correctness gate
For a five-ore cast, if TSM reports `amountOfMats = 0.0365` per ore, use `E = 0.1825` per five-ore cast; **not** `E * matRate` and **not** `(min+max)/2 * matRate`. For a per-ore item valuation use `0.0365 * netUnitPrice`. Do not multiply by five twice.
- `ConversionEngine.lua` lines 510–522 correctly preserves `expectedQuantity=amountOfMats` with `inputCount=1`, and lines 649–665 value it once per input.
- `StatYieldProfiles.lua` lines 247–260 builds a five-input fallback from `amountOfMats*batch`, with no extra matRate multiplication.
- However, source contradictions such as Cobalt/Titanium can still produce incorrect prices despite correct multiplication code.

## 4. Profession condition correctness gate
- Source `Professions.lua` scans real expansion-specific skill and traits, but `ConversionEngine.lua` low/high estimates currently depend on **manual percentage sliders**, not a proven skill-to-yield relationship.
- The current settings do **not** yet define a complete numeric simulated profession profile (skill/spec/stats) for a character lacking the profession.
- Do not claim the user's real/simulated profession goal is already implemented. Do not infer exact skill-to-yield math from the existence of Blizzard API fields.

## 5. Independent final audit and confidence rules
Scores are evidence-strength indices (0–100), NOT statistical confidence intervals or accuracy percentages.
- **Identity / eligibility**: 0 absent/contradicted, 25 unverified candidate, 55 single compiled source, 65 TSM historical, 80+ verified by current-version independent source and item IDs, 90+ multiple independent direct current-version checks.
- **Probability**: 0 absent, 10–20 assumed proxy or contradiction, 40 historical TSM aggregate, 60+ source-defined compatible occurrence counts, 90+ replicated current-version per-cast observations with denominators and conditions.
- **Conditional integer range**: 0 absent, 10 contradicted, 45 historical TSM ranges, 60+ per-operation documented outcomes, 90+ robust current-version bounds with independent corroboration.
- **Unconditional decimal expected units**: 0 absent, 10 contradicted, 35 proxy, 55 historical measured/TSM mean, 70+ current matched measured totals, 90+ independently replicated sufficiently powered matched samples with uncertainty.
- **Condition compatibility**: 0 unknown/unmodeled, 20–30 historical or transferred profiles, 60+ documented patch/skill/quality, 90+ direct matching live build and profession configuration.
- **Record confidence is MINIMUM of its applicable material field scores**, never an average. Do not increase a field score merely because another field has good evidence. Fixed recipes and token associations have only their applicable fields.
- Scores in the ledger are conservative provisional audit baselines, **not independent verification of every item ID**. Every row still needs source-by-source research. The **90+ gate is not met**.

## 6. Regression checks for future runs
1. Fetch fresh main SHA, compare with stored SHA; if changed, re-enumerate and diff rather than trust old line numbers.
2. Validate all unique input/method/output/quality keys, item IDs and batch sizes, plus source/provenance.
3. Recompute the `p*min <= E <= p*max` check **only for compatible operation units and conditions**; classify rounding separately from substantive conflict.
4. Independently verify every suspected correction against live Retail, not just historical Classic guides.
5. Check tooltip probability and conditional integer bounds separately from gold EV; use decimals for EV, never a midpoint.
6. Test actual character, offline alt, explicitly simulated profile and no-profile fallback; check transfer restrictions and profession unlocks.
7. Record exact rows reviewed, changed, source URLs and dates, self-review results and next priorities; commit to research branch and read back.
8. Never modify production main or release addon without authorization.
