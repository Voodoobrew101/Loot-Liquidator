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


## 2026-10-28 — 28 new distinct TSM anomaly source audits + deduplicated first-pass ledger
- Source of truth: main GameData SHA `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`, Issue #2 and current itemdb v1.1 creation prompt, mechanics/API registries, evidence schema. Future shipped database is `itemdb.lua`, main untouched. Existing first-milestone creation prompt already independently reviewed; no repeated rewrite.
- **Universe:** 1,001 processing + 255 supplemental = 1,256 source rows; 85 duplicate logical source/context keys -> **1,171 distinct scoped logical output records**, six critical fields each = **7,026**. 92 legacy overlay entries separately inventoried (62 numeric mappings, 30 dynamic/profile rules); full non-processing GameData semantic inventory still incomplete.
- **Unique first-pass coverage:** 12 prior Northrend + **28 NEW** (12 Pandaria Trillium, 6 Legion Felslate, 9 Dragonflight Draconium/Illimited Diamond rank combinations, 1 Dragonflight milling) = **40 cumulative**, **1,131 never examined**. **25 BLOCKED, 15 EXAMINED_INSUFFICIENT, 0 CORRECTED, 0 independently >=90**. Source row bands: >=90 0, 70–89 0, <70 1256, lowest 0. Scoped logical record bands: >=90 0, 70–89 0, <70 1171, lowest 0. Evidence score 90 is NOT 90% measured statistical accuracy.
- **Independent numeric findings:** Under UNVERIFIED historical TSM matRate-as-occurrence interpretation, 12 Trillium tuples remain impossible after raw precision rounding (p<=.165 vs E>=.17025); 6 Felslate and 9 DF Illimited Diamond tuples *could* reconcile through rounding; milling 200061->190322 only meets at boundary and recipe eligibility remains unknown. No replacement of TSM raw evidence, no invented 2026 Retail rates, no measured numeric correction.
- **Research files:** `research/ledger/tsm-anomalies-batch2-field-review-2026-10-28.csv`, `research/ledger/first-pass-coverage-v1.csv`, `research/ledger/overlay-first-pass-inventory-v1.csv`, `research/evidence/observations/tsm-anomaly-source-audit-2026-10-28.jsonl`, `research/tests/test_tsm_batch2_and_coverage.js`, `research/reviews/2026-10-28-28row-anomaly-and-firstpass-coverage.md`. **16 static QA checks passed, 0 failed**. No WoW client tests. Independent read-back verified each new file.
- **Rolling 3-run unique first-pass rate:** unavailable (only two attributable batches, 12 then 28). Provisional 2-run mean 20/run, 1131/20≈57 hourly runs (~2.4 days) for scoped first-pass only. Complete itemdb universe and all-fields >=90 completion ETA unknown; gate **NOT MET**.
- **EXACT NEXT 30 logical keys (first-pass unexamined):** source|prospect|72094|76131|-|-|-, source|prospect|72094|76138|-|-|-, source|prospect|72094|76139|-|-|-, source|prospect|72094|76140|-|-|-, source|prospect|72094|76141|-|-|-, source|prospect|72094|76142|-|-|-, source|prospect|72103|76131|-|-|-, source|prospect|72103|76138|-|-|-, source|prospect|72103|76139|-|-|-, source|prospect|72103|76140|-|-|-, source|prospect|72103|76141|-|-|-, source|prospect|72103|76142|-|-|-, source|prospect|123919|130172|-|-|-, source|prospect|123919|130173|-|-|-, source|prospect|123919|130174|-|-|-, source|prospect|123919|130175|-|-|-, source|prospect|123919|130176|-|-|-, source|prospect|123919|130177|-|-|-, source|mill|200061|190320|-|-|-, source|mill|200061|190328|-|-|-, source|mill|200061|198412|1|1|-, source|mill|200061|198413|1|2|-, source|mill|200061|198414|1|3|-, source|mill|200061|198415|1|1|-, source|mill|200061|198416|1|2|-, source|mill|200061|198417|1|3|-, source|mill|200061|198418|1|1|-, source|mill|200061|198419|1|2|-, source|mill|200061|198420|1|3|-, source|mill|200061|198421|1|1|-.
- Next investigate TSM exporter semantics and 200061 recipe/identity; verify per-cast skill/quality conditions; expand TWW/Midnight families. No production release.

---

## 2026-10-28 — hourly batch: 34 NEW first-pass source records, source backed

**Canonical main unchanged:** `GameData.lua` SHA `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`; future single shipped `itemdb.lua` not generated/approved. Original former v0.9.70 ZIP path remains 404; source is extracted Lua. Reviewed live Issue #2, creation prompt v1.1, mechanics/API registries, evidence schemas, raw observations, original ledgers and tests.

- **Source-record universe inventoried and deduplicated:** 1,737 stable keys (1,001 main processing output, 255 supplemental, 92 runtime overlays, 389 source profiles), 0 duplicate keys. This is not every nonprocessing semantic field in the 2,034-line GameData source. `research/ledger/first-pass-coverage-2026-10-28.csv`.
- **New distinct first-pass:** 34 (12 Pandaria Trillium gem rows 72094/72103; six Legion Felslate rare 123919; nine Dragonflight Draconium diamond quality rows 189143/188658/190311; one unresolved milling 200061; six additional Felslate uncommon gem rows). No repeat row counted as new.
- **Original player study preserved:** source Wowhead Legion Jewelcrafting guide, Felslate 3,200 ore, six rare + six uncommon gem output totals and 742 unidentified-color Gem Chips; 640 five-ore *equivalents*, actual Mass Prospect recipe cast count NOT specified. Updated observation schema to permit `completedOperations=null` rather than inventing a cast denominator. Historical decimal E for 12 gems recovered, **not** 2026 Retail-normalized. `research/evidence/observations/legion-felslate-3200ore-community.jsonl`.
- **Other evidence:** a Wowhead White Trillium comment cites ~17% each rare gem vs TSM p=.16 and E=.1705; Dragonflight Wowhead diamond family two distinct 2,000-ore cohorts (3/8 diamond units) lack quality-specific ID allocation and are leads only; milling input 200061 eligibility/item identity unresolved, with E=.005 vs p*max=.002 under assumed five-input batch. Source details: `research/reviews/2026-10-28-first-pass-34-source-backed-study.md`.
- **Field-level score and dispositions**: `research/ledger/first-pass-34-critical-field-scores-2026-10-28.csv` (34 distinct rows, each P, conditional yieldMin, yieldMax, unconditional decimal E scored independently, minimum record score). 13 record floors 0, 21 floors 12; 0 >=70. Original source-confidence ledgers unchanged, none promoted to 90.
- **QA:** `research/tests/test_first_pass_tsm_other28.js`, 27 source/normalization/coverage checks PASS, 0 FAIL after fixing the intermediate CSV newline test bug. Existing second bundled processing overlay issue remains unresolved, no game client or full JSON Schema validator used. Raw TSM evidence retained; no unsupported patches or stat transformation.
- **Coverage now:** 54 cumulative distinct first-pass, 1,683 never-examined, 41 examined-insufficient, 13 blocked, zero corrected current Retail, zero independently substantiated >=90. Original 1,256 material source-output ledger bands: >=90 0, 70–89 0, <70 1,256; min 0. ALL-records-at-90 gate NOT MET.
- **3-run observed new unique** = (8,12,34), average 18/run. At currently configured hourly cadence, 1683/18 -> about 94 runs / 3.9 days for FIRST PASS of only the known partial source-row universe if that rate continues; not an all-fields-confidence completion estimate. Larger source scope means actual timeline uncertain.
- **Exact next 39 unexamined keys**: `research/next-batch-39-tww-prospect-keys-2026-10-28.txt` (TWW Prospect 210930–210938, 39 output IDs). Follow with DF rank evidence, 200061 eligibility, and full nonprocessing GameData semantic inventory. Never modify `main` or create a second bundled database.


### Final independent end-of-run score and regression reconciliation (2026-10-28)
- Re-fetched and re-executed three persisted static research tests against unchanged canonical main source: **16 previous Midnight candidate + 9 previous Northrend + 27 current source/coverage = 52 PASS, 0 FAIL**. These are source/JavaScript tests, NOT in-game WoW client tests, not release qualification.
- Published `research/ledger/field-scorecard-2026-10-28.json` (commit `334a01d93d28667ff92a411d7235bca20b06adbf`, GitHub read-back verified). Across original 1,256 source-output rows, five **legacy** evidence dimensions each = 6,280 scored slots: **0 >=90, 24 at 70–89, 6,256 <70**. The combined old min/max dimension is not the desired separately scored min and max. All original source records still have worst-field <70.
- New 34 source records have **136 independently scored required numerical fields** (P, conditional min, conditional max, E): **0 >=90, 0 at 70–89, all 136 <70**. All 34 new record minima <70 (13 minimum 0, 21 minimum 12). No unsupported score promotions; no current Retail normalizations claimed.
- Deduplicated known source universe remains **1,737 stable keys**, 54 unique first-pass examined cumulatively, 1,683 never examined, 41 examined insufficient, 13 blocked, 0 corrected current Retail, 0 independently substantiated >=90. The whole-file nonprocessing semantic field census is still incomplete; the all-fields-90 gate remains **NOT MET**.
- Run throughput 34 previously unexamined source rows; last 3 record-review batches = **8, 12, 34**, mean 18/run. 1,683 / 18 => **94 additional hourly runs ≈3.9 days** for FIRST PASS of known partial universe only, conditional on sustained rate; not an all-confidence completion estimate. Next 39 exact TWW prospecting overlay keys already persisted at `research/next-batch-39-tww-prospect-keys-2026-10-28.txt`.

## 2026-10-28 — Master QA coordination handoff (no worker submissions yet)
- Verified current research head `29d44d5b6ccc744478d9f27a8d73a5fc49e68a7f`, current main source blob, live Issue #2, prompt/spec v1.1, registries, original evidence and coverage ledgers. All four worker automations enabled, none with a completed run.
- Independent QA rechecked 12 Felslate output totals against Wowhead Deckven study and recalculated their five-ore-equivalent E, preserving unknown actual Mass Prospect casts, hit rates, conditional ranges, patch and profession context. Checked 34 modern score floors and 1,737 unique coverage keys; no assertions failed. Official April 1 Midnight hotfix confirms date but not coefficient. 20-ore Osmenite mass recipe independently documents recipe-specific batch warning.
- Assigned 35 Midnight, 39 TWW, 36 Dragonflight, 30 Legacy = 140 distinct unexamined keys; 0 assigned overlaps; queue and master verdict committed atomically. No first-pass coverage credited before worker evidence acceptance. No source files in production changed; no new >=90 promotions or current Retail transformations.
- Existing master known universe 1,737, first-pass 54, remaining 1,683; 41 insufficient, 13 blocked. Full semantic universe incomplete; gate NOT MET. Rolling historical 8,12,34 = 18/run, provisional 94 single-worker-equivalent runs; worker-adjusted ETA not estimable before their first reports.


## 2026-10-28 — Master QA: Felslate 20-ore recipe and raw evidence schema guard
- Independently verified Legion Mass Prospect Felslate spell 225904 consumes 20 Felslate Ore (123919), supported by Wowhead and Warcraft Wiki; registry records recipe-specific metadata at evidence strength 88, **no output probability/yield coefficient**. The 3,200-ore prior study remains 160 conditional mass equivalents, not 160 observed casts.
- Archived separate 113-reported-cast, 13-unlabeled-total historical Felslate study with 13 exact total/113 arithmetic means; no invented item IDs, drop chances, ranges, current Retail rates or rank mapping. Raw prior study unchanged.
- Fixed evidence schema mismatch: existing historical aggregate status was rejected. Guarded unmapped-only study support now preserves source totals while rejecting empty evidence. Queue revision 2 retains 140 disjoint unexamined assigned keys and 32 distinct next-preview keys; no worker submissions yet.
- New master QA **27 PASS / 0 FAIL**, structural only. Universe 1,737; first-pass 54; remaining 1,683; insufficient 41; blocked 13; current Retail corrections 0; >=90 records 0; modern scored fields 136 all <70; all-fields gate NOT MET. Rolling latest 34/0/0 is not a meaningful four-worker ETA. Full nonprocessing inventory incomplete. See `research/coordination/reviews/2026-10-28-master-qa-schema-and-legion-recipe.md`.
- Next exact worker record keys remain in `research/coordination/assignments.json`; do not replace them with unlabeled historical indices. Production files unchanged.


## 2026-10-28 — Master independently accepts first worker batches (140 unique first-pass)
- Four worker submissions read from live research branch and independently cross-checked against all original assignments, source lines, overlay rows and arithmetic. **35 Midnight +39 TWW +36 Dragonflight +30 Legacy = 140 new accepted first-pass keys**, no overlaps, all below evidence 70. Coverage ledger advanced to **194/1,737 examined, 1,543 never, 181 insufficient, 13 blocked, 0 corrected current Retail output records, 0 >=90**. Worker raw evidence preserved.
- **Corrected material research metadata:** official gem prospecting hotfix is under **March 31, 2026**, not April 1. [Official Blizzard cumulative hotfix](https://worldofwarcraft.blizzard.com/en-us/news/24266320) and [archived Blizzard post](https://www.bluetracker.gg/wow/topic/us-en/2260898-world-of-warcraft-midnight-hotfixes-april-17/) independently confirm the subsection. Research mechanics event/model corrected; old source claim retained as deprecated alias. No numerical coefficient published, transformation BLOCKED. Current GameData.lua/Issue #2 unchanged.
- **QA quarantines:** Midnight 3 JD3K observations have 17 invalid field-basis enums and infer 10 observed casts from 50/5; require new corrected evidence with completedOperations=null unless source confirms cast count. Legacy 30 JSONL entries are per-record QA, not canonical observation schema. TWW/DF rates remain historical/proxy. First-pass examination can be accepted without numeric field promotion.
- New modern field scores **140 records/560 slots**, all <70; combined **174/696 slots** all <70. 18 historical Legacy E discrepancies and 12 Dragonflight quality-rank aggregation traps flagged, not adopted as current Retail corrections. **19 static integration checks pass, 0 fail**, no WoW client tests. See `research/coordination/reviews/2026-10-28-master-worker-batch001-verdict.md` and `research/ledger/master-worker-batch001-four-field-scores-2026-10-28.csv`.
- Queue revision 3 assigns next **134 disjoint never-examined keys** (34/30/40/30); exact next IDs and previews in `research/coordination/assignments.json`. Single first worker cycle 140 accepted; 1,543/140≈12 hourly worker cycles at unchanged throughput, **optimistic first-pass-only**. All-fields>=90 and full-universe completion ETA unknown. Production files untouched.


## 2026-10-28 — Master worker batch002 independent integration
- Reviewed live head 8b8eba58cf608497500b649d053d88bc52060773 and production SHA 1d47c4a961c5dc5af626e659f7d96d1490d3cf9e, canonical prompt, registries, Issue #2, evidence, source ledgers and four batch002 worker submissions.
- Accepted 134 unique first-pass keys (34/30/40/30); 90 material output records plus 44 identity profiles; no >=90 promotion. Coverage 328/1737, 1409 never, 315 insufficient, 13 blocked. Modern scored 264 output records/1056 fields, 0 >=90, 3 historical E 70–89, 1053 <70.
- Rechecked original Silver 800-cast ore cost/output math, Null Stone source mismatch, DF R3 20k cohort and clamp, Legacy 23720 herb denominator. 18 Legacy E and 9 DF tuple checks passed. 128 named QA gates PASS; no in-client WoW or external JSON Schema run.
- Queue revision 4 with 150 disjoint keys, home first then Dragonflight overflow. Rolling 0/140/134, mean 137 per complete worker cycle; optimistic 11 hourly cycles for partial first-pass only. No production changes, no approved current-Retail numeric transforms, all-fields >=90 gate NOT MET.

### 2026-10-28 — Master QA batch003
- Independently reviewed four worker CSV submissions, 14 historical observation objects, original TWW/DF/Legacy sources; 1036 in-memory JS assertions passed. 150 new unique first-pass accepted, 478/1737 cumulative, 1259 unexamined, zero all-field >=90.
- Verified 100 ore vs 20 five-ore equivalents, R3-vs-R1 Dragonflight rank mismatch, PTR Osmenite 8000-cast means and Felslate 5 vs 20 recipe distinction; no current-Retail numerical correction.
- Numeric track: 0 verified, 0 empirical approved, 4 blocked for compile; one explicit Legacy hypothesis reviewed. Assigned next 150 nonoverlapping item keys. Production unchanged. Node and WoW client tests not run.

### 2026-10-28 — Master QA batch004
- Read head 0438d8858d376dcf69360a50a95195f73cfac573 and original worker evidence; accepted 150 unique first-pass keys, 628/1737 cumulative. No current Retail corrections or >=90 promotions. Four numeric rules blocked.
- 864 source/coverage/assignment assertions and 372 static schema/histogram checks passed; Node and WoW tests not run. Queue revision 7 next 150 disjoint keys. Review research/coordination/reviews/2026-10-28-master-worker-batch004-verdict.md. No main/production/schedule changes.

## 2026-10-28 — master batch005 independent review
- Source branch head dac3740773d7822275782f8a61df8df3ddaeb94a, GameData blob 1d47c4a961c5dc5af626e659f7d96d1490d3cf9e; 150 exact first-pass source output keys accepted; 150 source ID/input/rate/E/bound checks and score gates.
- Classic/TBC 19 guide/TSM rate differences; 14 invalid hybrid P/E inequalities, five Thorium cases. Independent 2016 Felslate raw batches sum 560 first15 and **97** last10, correcting worker's 101. No current Retail coefficient.
- Numeric 0 verified, 0 empirical approved, 4 blocked. Modern four-field 694 records / 2776 fields, 0 >=90. Coverage 778/1737, remaining 959. Next 150 disjoint keys. Static JS checks only, no Node or WoW client.
- research/coordination/reviews/2026-10-28-master-worker-batch005-verdict.md; research/evidence/observations/2026-10-28-master-legacy-thorium-felslate-source-audit.jsonl; research/ledger/master-worker-batch005-four-field-scores-2026-10-28.csv.

## 2026-10-28 — master batch006 independent review
- Live branch 49821faacb512d50837d6ebbb42a5ae4851ab731, production GameData blob 1d47c4a961c5dc5af626e659f7d96d1490d3cf9e. Independently accepted 150 disjoint exact source output keys; 2649 in-memory structural, tuple, necessary-bound, four-field, numeric schema and next-assignment checks passed.
- Coverage 928/1737 examined, 809 unexamined, 915 insufficient, 13 blocked; modern field scores 0/17/3359 (>=90/70–89/<70) across 3376 fields. 12 worker-rediscovered Northrend anomalies already blocked; no new blocked or current-Retail corrections.
- Original 1000-Titanium-ore study: 104 gem units, 0.520 per derived 5-ore equivalent; TSM aggregate proxy 0.516. Cobalt rare six 1.5% vs guide 1.3%; Pyrite common six 16.5% vs guide 17%. Historical source disagreement only.
- Numeric hypotheses 0 VERIFIED, 0 EMPIRICAL approved, 4 BLOCKED; no coefficients. Queue rev9 assigns 150 distinct next keys (Dragonflight 45, Legacy 105). No repository Node suite or WoW client execution. No main, addon or schedule changes.
- research/coordination/reviews/2026-10-28-master-worker-batch006-verdict.md

## 2026-10-28 — master batch007

Independent review of 150 exact disjoint worker batch007 source-output keys; original GameData blob 1d47c4a961c5dc5af626e659f7d96d1490d3cf9e unchanged. Coverage 1078/1737, 659 never, 1065 insufficient, 13 blocked. 994 output records /3976 fields: 0 >=90, 17 moderate, 3959 low. 15 original source observations in five immutable JSONL files, including 222 unmapped DF beta output cells, two Felslate historical arms, three BfA and three Kyparite cohorts. Static QA 619 assertions passed (150 source ID, 150 assignment, 150 arithmetic, 165 observation, four blocked candidate). Four numeric hypotheses remain blocked. Node suites and WoW client not run. Queue rev10 next 150 disjoint keys, known first-pass ETA ~5 hourly cycles; 90-gate ETA unknown. No production/schedule edits.

## 2026-10-28 — Master batch008

Accepted 115 new disjoint first-pass keys; Midnight numeric-only 0. Corrected 26 historical BfA source associations from Tontons original; confirmed Snurp PTR 8000-cast partition. 1193/1737 reviewed, 544 never; 4436 scored fields, 0 >=90, 17 moderate, 4419 low. Numeric verified 0/4. Queue rev11 new disjoint 35/40/40 and retained Midnight 35. Node tests and source-memory full rebuild pending checkout, no WoW client tests. No production/schedule changes.

### Batch008 source-memory cache follow-up

Committed deterministic JS-port source-memory rebuild: 153 archived observation rows, 4 worker source reviews, 8 master QA feedback events, 51 unique canonical sources (47 discovered, 4 partial, 0 fully analyzed). 6 in-memory builder tests passed; Node test suite not executed, WoW client not executed. Source memory and feedback are research-only; no confidence promotions.

## 2026-10-28 — Master batch009

Accepted 150 unique worker first-pass output keys, independently checked original Jiyao, Stormvine, Whiptail and Carnelian comments. Historical correction of two nubi conditional means, one Stormvine denominator contradiction; no current Retail numerical rule. 1343/1737 first-pass, 394 never. 0/17/5019 field bands; 4 mechanics BLOCKED. Source memory incremental replay completed from previously verified cache plus 32 new observations, 29 source reviews and 9 master QA feedback events; 72 sources and 17 QA events. Node builder/test scripts not executed. No production changes; no repository Node or live WoW tests.
