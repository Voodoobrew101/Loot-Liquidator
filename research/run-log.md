# Loot Liquidator research run log

## 2026-10-27 — source inventory, first confidence ledger, independent QA

### Actual source used
- Repository main now contains extracted addon Lua sources, **not** the previously referenced `LootLiquidator-v0.9.70-Unified-Low-High-Processing.zip` at its former path (404 when requested).
- Read current `GameData.lua` directly from GitHub main: blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`.
- Inspected `ConversionEngine.lua`, `StatYieldProfiles.lua`, `Professions.lua`, `Settings.lua`, `ResearchModel.lua` and `MIDNIGHT_MODEL_README.txt`.
- Research branch initially had only `research/PROGRESS.md`; no prior confidence ledger or run log was found.

### Material progress completed
- **389** source profiles enumerated: 179 compiled prospect/mill inputs, 140 TSM input profiles, 40 DE brackets, 8 smelt recipes, 1 token, 7 Midnight prospecting low/high profiles, 11 Dragonflight low/high profiles, and 3 Midnight condition cohorts.
- **1,256** source output rows enumerated and assigned preliminary per-field evidence scores: 98 compiled material rows, 903 TSM material rows, 52 DE output rows, 49 Midnight anchors, 142 Dragonflight anchors, 8 smelt outputs, 1 token reward, 3 condition observations. These are **source rows** with intentional overlap, not distinct live output pairs.
- **92** additional runtime-generated scenario/profile mappings catalogued in `runtime-overlay-map.csv` (39 TWW prospect, 12 TWW mill, 8 Midnight mill, 3 TWW Null Stone, 12 DF milling profile generators, 18 DE conditional fallback profiles). They are tracked separately and NOT counted in the 1,256 static-source output rows.
- **40** probability × conditional range versus unconditional mean contradictions detected in TSM's 903 source rows. **13 critical**, 18 moderate, 9 near-rounding by the audit's severity thresholds. Exact IDs and lines in CSV.
- **12** critical Cobalt Ore/Titanium Ore uncommon output rows independently checked against WoW sources: `matRate=0.235`, `[1,2]`, `amountOfMats=0.5 per ore` cannot all be true for a 5-ore operation. Preserve original raw source, flag pricing risk; do not invent replacement EV.
- **1** source-date correction supported: Midnight prospecting gem buff occurred in Blizzard's **April 1, 2026** hotfix section, NOT April 17 (the cumulative article update date). Proposed correction saved separately.
- **52** DE output rows tested for internal probability/range/mean consistency; **40** have min/max and **0** contradictions; **12** lack explicit ranges.
- **149** initial compiled prospect/mill input arrays have no inline material rows (102 mill, 47 prospect), but many are subsequently populated from TSM and `StatYieldProfiles.lua`; they are NOT all proven to lack runtime data.
- Existing engine correctly uses unconditional `expectedQuantity` once for price, but cannot rescue incorrect source values. Existing real profession scan does not automatically map actual skill/spec into the manual low/high slider endpoints; complete settings-defined simulated skill/stats are not yet implemented.
- Reviewed current Retail API field availability and confirmed that the skill-to-yield formula is NOT established by these APIs.

### First conservative evidence scorecard
- Source output records tracked: **1,256**.
- Records with all applicable critical fields scored **>=90**: **0** (0.0%).
- **70–89**: **0** (0.0%).
- **<70**: **1,256** (100.0%).
- Lowest score: **0** (missing field); **304** output rows currently have record confidence 0.
- Confidence improvements versus a prior scored baseline: **not measurable; this is the first ledger**. No fabricated claim of upgraded numerical accuracy.
- Source corrections proposed: **1 dated mechanic annotation**; **12 pricing-risk records** and 28 additional inconsistencies flagged. **0** production source rows overwritten.
- Evidence source register: 13 external links (including two measured Titanium cohorts) plus six inspected repository source files.
- No in-game validation. Source-scoped invariant checks and GitHub read-back passed. No numerical skill-to-yield formula verified.
- **ALL RECORDS >=90 gate: NOT MET.**

### Files committed to research branch
- `research/ledger/source-inventory.csv` (389)
- `research/ledger/processing-output-fields.csv` (1,001)
- `research/ledger/supplemental-output-fields.csv` (255)
- `research/ledger/runtime-overlay-map.csv` (92 supplemental runtime scenarios)
- `research/ledger/tsm-invariant-anomalies.csv` (40)
- `research/proposed/2026-10-27-corrections.md`
- `research/tests/QA_PROTOCOL.md`
- `research/research-sources.md`
- `research/run-log.md`

### Next highest-priority research targets
1. Recover authoritative original TSM rate definitions and compare 12 Cobalt/Titanium rows to current Retail sample means. Determine whether `amountOfMats=0.5` is a transcription/unit mismatch; do not price from it uncritically.
2. Audit the other 28 TSM contradictions, especially six Legion `p*min > E` and Dragonflight milling outlier.
3. Correct the Midnight hotfix metadata in a **reviewed proposed patch**, and stratify pre-/post-2026-04-01 sample cohorts before comparing rates.
4. Audit **all 92** runtime overlays for source, input/output quality and per-cast units, including TWW/Midnight 10-herb milling and Null Stone.
5. Research current Retail profession API behavior and design condition-aware real/simulated profession profiles. Do not finalize sliders or interpolate yields without evidence.
6. Verify high-impact Midnight and TWW ore/pigment outputs with independent post-hotfix, per-cast observations. Record P(drop), integer conditional range, and decimal unconditional expected units separately.
7. Continue checking all 1,256 source output rows and 389 source profiles, with explicit source-backed per-field improvements; add source and test results to ledger and re-score only when justified.

### Self-review / caveats
- Counts were independently re-read from committed CSVs: 1,001 + 255 = 1,256 output rows, 389 input/profile records, 40 anomalies. Every CSV row passed column-count parsing; no duplicate source files were overwritten.
- The 40 TSM conflicts are **consistency flags**, not 40 proven incorrect expected quantities. Incompatible historical p, min/max and E are possible; 9 are near-rounding differences.
- Source line numbers and counts are tied to the exact GameData blob SHA; next run must compare SHA before reuse.
- Conservative confidence scores are provisional *evidence assessments*; individual item IDs have not all been independently researched, and no field is automatically 90 because it appears in TSM.
- Original main Lua remains unchanged; do not merge the research branch automatically.

### Additional source-backed correction batch (same run)
- Recovered **two independently reported Titanium prospecting cohorts**, one from **Retail 2022** (1,000 ore = 200 casts) and one from **WotLK Classic PTR 2023-05-18** (5,000 ore = 1,000 casts). Both report raw output totals for the same six uncommon gems.
- Calculated **12 source-backed decimal expected yields** (six per cohort) and preserved sample counts, item IDs, provenance, game versions and limitations in `research/ledger/titanium-observed-yields.csv`.
- Six 2022 Retail per-cast means range **0.220–0.295** gems per five ore; six 2023 Classic means **0.227–0.263**. Existing TSM source values of **2.500** each per five ore are approximately 8–11 times these observed means.
- This **improves the evidence available for six economically risky output relationships**, but does NOT establish 2026 Retail matching conditions, occurrence probabilities, conditional integer distributions, or a 90/100 confidence score. The original 1,256 GameData source rows retain their baseline scores until a reviewed model selection is made.
- Original 2022 Retail source: https://www.reddit.com/r/woweconomy/comments/s6bfrl/ ; 2023 Classic source: https://www.wowhead.com/wotlk/item=36910/titanium-ore (Strath).
- Updated proposed corrections document with per-gem values. No production changes.


## 2026-10-28 — Batch 9 one-database audit
- Verified main/GameData.lua SHA 1d47c4a961c5dc5af626e659f7d96d1490d3cf9e; original v0.9.70 ZIP path still unavailable (404); extracted Lua inspected.
- Read Issue #2 integration contract. Reviewed StatYieldProfiles.lua mappings and mutations; documented 9 TWW ore quality profiles, 20 TWW/Midnight milling profiles, 3 Null Stone outputs, 9 DE fallback anchors, 5 runtime input deletions, plus dynamic Dragonflight TSM profiles.
- Static code QA found rangeFor adjusts chance/conditional bounds to fit expected values; these are inferred display fields, not independently measured evidence.
- Detailed report: research/proposed/2026-10-28-batch9-one-database-migration-audit.md, verified commit 57488d5b4e7b135fc6fc5f6b1c9f2146fbb932b7. No main changes; no live tests or field promotions. Gate remains 0/1256 >=90; this is processing output-row scope, not yet every non-processing gameplay field.
- Next: proposed GameData-only migration schema, static invariant tests, independent milling eligibility and yield source verification.


## 2026-10-28 — itemdb v1.1 milestone; eight-row Midnight Milling review; static QA

### Input provenance
Live fetch of research/PROGRESS.md, run-log, both source confidence ledgers (1,001 + 255), TSM 40-row anomaly ledger, 92-row overlay ledger, mechanics/API registries, user prompts, evidence observations, current Issue #2, and main GameData/StatYieldProfiles/TOC. Original main ZIP name 404; extracted source SHA `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e` unchanged.

### Original source research (not repeated Titanium Batch 5–8)
Four Midnight herb families with 8 input variant IDs mapped to independently corroborated pigment item IDs (Tranquility Bloom 236761/236767 -> Powder 245807; Argentleaf 236776/236777 -> Argentleaf 245804; Mana Lily 236778/236779 -> Mana Lily 245866; Sanguithorn 236770/236771 -> Sanguithorn 245864). Verified ten-herb batch by Warcraft Wiki and Method guide. Cross-checked Icy Veins and pigment item pages. Patch/current skill/spec/gear effects remain unknown for numeric scaling. Old 4.5 units/cast is a modeled scenario; approx occurrence 1.0 and conditional [3–6] are modelled display proxies, not measured. Review includes dates/sources and distinct scores. Azeroot 236775 unresolved; reported Arathor's Spear 210808-210810 exclusion documented with 2024-2025 forum evidence. No new measured operations.

### New research branch files / actual writes
- `research/proposed/itemdb.schema.json` — commit b32ca9e28ede195fa8dd1be92e91f97a683c7b25, field-type audit fix b2c253606f7e2f9a11d2ac9b112b1d1c062734dd
- `research/proposed/itemdb-midnight-milling-candidate.json` — commit 4bd9b2cf1c696f950a9a806c44fc41c3efc1bedb
- `research/tests/test_itemdb_candidate.js` — commit f056fd6dd1a10df7eae1eb1a3e287e86c61351e5
- `research/ledger/midnight-milling-field-review-2026-10-28.csv` — commit 15ec0fbf3418290f2c94a06669ae108befe8f557
- `research/reviews/2026-10-28-midnight-milling-source-qa.md` — commit c98162f078e45a999cde4746374a089d75807277
- `research/prompts/ITEMDB_CREATION_PROMPT.md` v1.1 review — commit c4a8fbb538dcb023b1020c810b391ea0ab8b0338
- `research/ledger/gamedata-lexical-key-census-2026-10-28.csv` — commit a918acc17327717c2585e5b6af589ebb7533628d
All created/updated paths fetched back and content verified.

### Independent end QA
Re-read all artifacts and exact main source. Executed stored JS test against live-fetched GameData and StatYieldProfiles: 16 passed / 0 failed. Checked 8 candidate records, 8 CSV rows, distinct numeric-field JSON schema refs, 10-herb normalization, conservative record score 12, duplicate/synthetic anomaly, and current TOC legacy name. **Known second-database runtime mutation remains an architectural defect.** No WoW client tests, no complete Lua AST coverage, no production edits, no unsupported confidence promotions.

### Field-confidence scorecard
Existing research source output rows 1256 (1001 processing + 255 supplementary), >=90 0, 70-89 0, <70 1256, minimum 0. Eight runtime-overlay candidate rows separately reviewed: 8/8 record score 12, 0 >=90. Existing 92 overlays not fully field-scored. All-record >=90 condition NOT MET.

### Exact continuation targets
Current Retail cast records with zero-inclusive per-output histograms for four Midnight milling families, plus rank/stat/skill matching; 2026 client eligibility of Azeroot and Arathor's Spear; remaining Cobalt/Titanium severe TSM denominator contradictions; all-field AST parser inventory with nonprocessing values; tested one-file itemdb generation and reversible migration. No automatic main changes.


## 2026-10-28 — Northrend 12-record economic anomaly re-audit
- Read current research ledgers, current extracted main/GameData.lua SHA 1d47c4a961c5dc5af626e659f7d96d1490d3cf9e, Issue #2, existing itemdb contracts. Original ZIP former pathname remains GitHub 404; source extracted Lua unchanged.
- **12 individual Cobalt 36909 and Titanium 36910 uncommon-gem output source rows rechecked against original TSM tuples**, Warcraft Wiki Cobalt/Titanium Prospecting references and existing distinct 2022 Retail/2023 Classic PTR Titanium experiments. Each TSM tuple p=.235, per-input amountOfMats=.5, conditional [1,2] implies E=2.5 units per five ore vs p*max=.47 (factor 5.319). Source values remain unmodified; ambiguous TSM field semantics under investigation.
- New **proposed** quarantine disposition table: `research/ledger/tsm-northrend-quarantine-proposal-2026-10-28.csv` (12 rows). No runtime gating implemented; original TSM evidence retained. Detailed review: `research/reviews/2026-10-28-northrend-tsm-math-and-source-audit.md`. Static source test: `research/tests/test_northrend_tsm_anomalies.js`, 9 passed / 0 failed when executed against fetched main Lua; no client test.
- Independent end audit confirms unchanged scoring in BOTH ledgers: 1,001 processing output source rows + 255 supplemental = 1,256; >=90 0; 70-89 0; <70 1,256; weakest 0. **12 reviewed/proposed dispositions, zero measured numerical field corrections, zero score promotions.** No production addon modified.
- Current next batch: original TSM rate/denominator implementation semantics, another 28 flagged anomalies (200061 milling and 123919 ore first), source-backed current Retail five-ore sampling, exact quality/spec profiles; all-GameData semantic inventory remains unfinished. Retain one-baseline `itemdb.lua` future filename under Issue #2, no addon main migration without approval.
