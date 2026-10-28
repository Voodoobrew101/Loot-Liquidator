# Latest database copy and profession-scaling audit

## Copy and runtime status

The latest `research/proposed/itemdb.lua` found on the fetched research branch was copied **byte-for-byte** into `LootLiquidator/itemdb.lua`.

- Research branch snapshot: `83f146cee0caff8037e8b260751544942ad2c629`.
- Commit last changing the file: `58d3e7698a69572670e96c045135c6634fda6cc2`, October 28, 2026, **1:06:58 p.m. Pacific**.
- SHA-256: `8a735c379c4d391c4b816ec9e27a8dc713497f78e9128d064e2506bed70a8022`.
- Research compiler version 0.2.0; returned artifact schema `0.1.0`; status `RESEARCH_ONLY_NOT_SHIPPED`.
- 976 input/output records, 938 known expected quantities, 38 unknown expected quantities, and **zero approved numerical mechanics rules**.
- Expected-quantity evidence labels: 929 proxy, 8 modeled, 1 community-reported, 38 unknown. A numeric field is not proof of a verified profession formula.

Multiple item databases are intentionally retained during development. The previously working schema-1 compiled database is preserved as `LootLiquidator/ItemDBRuntime.lua`; the TOC loads that file before Database.lua. It contains 267 grouped source records and zero executable rules. The new research file is not TOC-loaded: its single-output records and returned table are incompatible with the current grouped-record/namespace API. Copying it over the active file without separation would leave `LL.ItemDB` unset and break database initialization. No research branch was modified and no research coefficients were promoted.

`database/research-itemdb-source.json` records provenance. Package checks verify the copied file's hash. The runtime compiler, reproducibility tests and benchmark target ItemDBRuntime.lua, preventing regeneration from silently replacing the copied research file. There are 16 TOC-loaded Lua files plus one unloaded development database snapshot.

## Scaling verdict

**Actual profession-dependent yield scaling is not active in either database.** The engine has a guarded numeric adapter and synthetic tests, but there are no approved coefficients to execute. Neither database has a populated `patchBuild`, `referenceContextID` or numeric skill reference on its current processing records. Only 19 active records and 8 research records identify a recipe. Those missing reference fields also prevent the adapter from applying future rules until the relevant data is populated.

Actual skill-20 versus skill-100 baseline equality, scoped synthetic scaling, reference immutability, missing-coefficient rejection and preventing duplicate application were verified. Economic valuation uses unconditional expected quantities without multiplying occurrence again. Current/manual/offline profile support and source weights exist, but those controls must not be advertised as verified gameplay yield scaling.

## Reproduced findings and recommendations

### P1 — Fresh base skill can be combined with an obsolete gear bonus

Location: `LootLiquidator/ConversionEngine.lua`, `ProcessingPlayerConditions`, saved-bonus fallback (approximately lines 98–107).

Reproduction: the current profession API returns skill 70 and modifier 0. An earlier snapshot has bonusSkill 10. When trait/operation information is unavailable, the current code reports effectiveSkill **80**, retaining the obsolete bonus. `RefreshResearchSkillLines` has already obtained the fresh modifier but the calculation reads the old research profile instead.

Recommendation: build the context from one coherent, timestamped read. Prefer the fresh skill-line modifier or verified recipe-operation bonus. If the current bonus cannot be established, keep it unknown and identify a stale fallback; never mix a fresh base with an unverified older bonus.

### P1 — Old specialization can be labeled live and complete

Locations: `LootLiquidator/Professions.lua`, `GetResearchProfessionSnapshot` (approximately lines 216–223); `LootLiquidator/ConversionEngine.lua`, current-character freshness (approximately lines 104–108).

When current trait APIs are unavailable, an old specialization string is reused. The context is labeled `live`, `stale=false`, and complete even if the stored specialization is months old. A future rule could therefore match knowledge points that are no longer allocated.

Recommendation: track freshness per field, particularly specialization and equipment. Invalidate their verification after trait/equipment events. Cached data may remain visible as a snapshot, but cannot satisfy live numeric-rule prerequisites without fresh validation. Add tests for respecs and gear changes followed by nil API responses.

### P1 — A probability transform can produce an impossible model

Location: `LootLiquidator/ConversionEngine.lua`, occurrence transform (approximately lines 236–245).

Synthetic reproduction: baseline chance 0.5 and expectedQuantity 2; an approved-form probability multiplier of 0 changes chance to **0** while retaining expectedQuantity **2**. The resulting model claims an output never occurs but still has positive unconditional yield. The database layer can remove inconsistent bounds without resolving the impossible probability/expectation pair.

Recommendation: validate the complete transformed distribution before valuation. A probability-only rule cannot establish a new unconditional mean without appropriate joint/conditional evidence. Withhold incompatible fields or reject the transformation and retain the labeled reference; do not infer a replacement mean from a range or invent a multiplier.

### P1 — Disenchant scaling is blocked by a mandatory reagent-quality rank

Location: `LootLiquidator/ConversionEngine.lua`, rule applicability (approximately line 163).

All rules require non-nil `inputQualityRank == f.reagentQuality`. Ordinary equipment has rarity, not a crafting reagent quality rank. Consequently a correctly gear-scoped disenchant rule without a reagent rank cannot execute.

Recommendation: use method-specific applicability. Require reagent rank where it exists; scope equipment by item identity, rarity, item level, gear class/type and recipe/reference conditions. Do not substitute rarity for reagent quality or make rank a universal wildcard.

### P2 — Invalid rule confidence values are accepted

Location: `LootLiquidator/ConversionEngine.lua`, rule confidence gate (approximately line 158).

Synthetic reproduction: confidence **101** passes the `>=80` check and applies a 1.5× expectation transform. Nonfinite values are also not explicitly excluded by that gate.

Recommendation: validate all mechanics rules on import and before execution: finite 0–100 scores, unique IDs, parameters, units, exact scope and independently approved provenance. Keep source confidence separate from transformation confidence and user preference.

## Integration recommendations

1. Fix field freshness and transformed-model consistency before enabling any real coefficients.
2. Add an explicit research-schema → runtime-schema adapter. Group single-output research rows by compatible operation/context and retain each field's confidence, provenance, unknowns and provisional/proxy status. Keep parallel development databases; do not require premature consolidation.
3. Reconcile the two mechanics contracts. Research compilation emits `VERIFIED_FOR_COMPILE`, nested `scope` / `referenceContext`, and formulas such as `RATIO_ADJUSTMENT`; the runtime consumes `EXECUTE`, flat recipe/build/context keys and `MULTIPLY` / `SET_VERIFIED_RANGE`. Approved research rules will need a validated translation, not a blind assignment.
4. Populate exact recipe, batch, input/output quality, build, reference-condition and independent-study identities before attempting character normalization. A minimum score alone is insufficient.
5. Add matched-condition studies and live Retail verification for each profession. Prefer Blizzard operation stats where applicable; do not treat the API as a source of hidden drop-rate coefficients. Expand coverage to discrete output-quality and eligibility effects only when a reviewed implementation exists.

## Checks performed

- `bash tests/run.sh`: **passed**, including deterministic active-database regeneration, Lua 5.1 syntax for both database files, copy checksum, TOC separation, XML/load order, preserved PR #4 fixtures, **2,603 modernization assertions**, and native settings interaction fixtures.
- `lua5.1 tools/audit_profession_scaling.lua`: **8 passed, 5 failed; exit 1**. The five failures above are intentionally exposed by the focused audit and remain unresolved recommendations. A passing baseline suite does not erase them. Synthetic numeric values in this audit are test fixtures, not claimed WoW mechanics.
- Checked API signatures and data fields against generated Retail UI documentation at public mirror `Gethe/wow-ui-source`, live revision `15881d522c44cd106d3d8660106ec9f9d2f44167`: `TradeSkillUIDocumentation.lua`, `TradeSkillUITypesDocumentation.lua`, `ProfessionSpecUIDocumentation.lua`. The existing four-argument operation call and zero-argument inventory-slot call match these definitions. Those signatures do not prove in-game availability or hidden yield behavior.
- **Not performed:** live WoW gameplay, actual equipment/respec transitions, drop-rate experiments or in-client UI QA.

This change copies the latest database, preserves the working runtime path, and adds audit evidence. It does not silently repair the five scaling defects or promote incomplete research into gameplay calculations.
