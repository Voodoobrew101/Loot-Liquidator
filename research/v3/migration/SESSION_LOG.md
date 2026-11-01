# Migration session log

Append one entry per session. Never edit earlier entries. Only list commands and tests that actually ran.

---

## MIG-001 — 2026-10-31 (Claude Opus 5.5, run from the owner's master prompt)

**Tasks:** M00 audit and plan · M01 inventory · M02 test harness, validator, schema extension

**Starting commit:** `575b2529d02820ca4ad77851624dc7ecd7f8d740` on `implementation/five-agent-completion`
(this is the migration snapshot). New branch `migration/v3-historical-research`.

**Files examined:** `research/v3/{README,evidence-format,mechanics,strategy,log}.md`,
`research/v3/tools/{import_existing,build_estimates,audit_studies}.py`, `research/v3/output/*`,
`research/v3/corrections.jsonl`, samples from `research/evidence/observations` (jsonl/json/md),
`research/evidence/v2`, `research/coordination/{submissions,source-reviews,v2}`, `research/ledger`,
`research/proposed/itemdb.lua`, `GameData.lua`, `StatYieldProfiles.lua`, `research/tests/*.js`.

**Created:** `research/v3/migration/{PLAN,CHECKLIST,SESSION_LOG,HANDOFF,SCHEMA-EXTENSION}.md`;
`tools/{inventory,validate,estimates_diff}.py`; `tests/{test_inventory,test_build_estimates,test_validate_and_diff}.py`;
`manifest/{inventory.jsonl,url-registry.jsonl,snapshot.json,inventory-summary.md,validation.json}`;
`research/v3/.gitignore`.
**Modified/removed:** untracked three committed `.pyc` files (`research/v3/tools/__pycache__/…`, two under migration).
No evidence file, correction, estimator, output or addon file was changed.

**Commands actually run (all from repo root):**
- `python3 research/v3/tools/build_estimates.py` (twice; outputs byte-identical → deterministic) → 4,404 records, 1,238 estimates, 35 unplaced. Restored committed `output/` afterwards.
- `python3 research/v3/tools/audit_studies.py` → 426 studies, 140 clean.
- `python3 research/v3/tools/import_existing.py` → 652 / 1,018 / 52 / 8 / 1 records; `git diff` empty → idempotent.
- `node research/tests/<each>.js` → 12 pass, 8 fail (pre-v3 suite; not fixed, recorded as baseline).
- `python3 research/v3/migration/tools/inventory.py` (twice, sha256 identical) → 1,244 files, 543 URLs (165 in v3).
- `python3 research/v3/migration/tools/validate.py` → 4,497 records (4,404 effective), 15 errors, 693 warnings.
- `python3 research/v3/migration/tools/estimates_diff.py output/estimates.json <rebuild>` → committed output is stale (1,221 → 1,238 rows, 56 changed).
- `python3 -m unittest discover -s research/v3/migration/tests` → **41 tests, OK**.
- Ad-hoc measurement scripts (not committed) for: cast-basis counts of imported rows, totals-only rows, identity collisions.

**Measured results:**
- Imported rows with nominal casts: 258 from "equivalent operations" + 33 from inputs ÷ batch = 291, while equivalent new agent rows leave casts null.
- Totals-only unused rows: 529 in 92 studies (S16 said 451 / 71).
- **Identity defect:** 168 estimate groups where distinct study keys share one `study_identity()`; 90 have differing numbers (independent cohorts dropped, ≈288k material-level casts), 78 identical (true copies).
- 10 typeless records in `evidence/midnight/2026-10-31-midnight-refining-shattering-decks.jsonl` hold real observations in another field layout and are ignored.
- 518 effective records carry free text in `dataDate`.

**Problems:** shallow clone made `git log` report a boundary commit as the last historical change; fixed by
deepening to 1,000 commits and making `inventory.py` keep the previous snapshot commit on a shallow boundary.
`build_estimates.py` leaves files unclosed (ResourceWarnings in tests; harmless, not changed).

**Decisions:**
- Hybrid strategy (PLAN §3); tests before any estimator change; M05 identity fix promoted ahead of bulk import.
- Schema additions are optional fields documented in `SCHEMA-EXTENSION.md`; `evidence-format.md` (owner-only) untouched.
- Do not commit regenerated `research/v3/output/` from this branch; per-task diffs go to `migration/reports/`.
- `strategy.md` is Master/Claude-owned: migration notes for the Master go to `migration/reports/`.

**Ending commit:** see `git log` on `migration/v3-historical-research` (two commits this session: M00/M01, then M02 + docs).

**Remaining:** M05, M03, M06, M04, M07, M08, M09, M10.

---

## MIG-002 — 2026-10-31 (Claude Opus 5.5, Claude Code on the owner's Windows machine)

**Tasks:** M05 study identity and deduplication

**Starting commit:** `45011e2f2aaff1960deeafb23eeafa517567e444` on `migration/v3-historical-research`.

**Environment:** no local clone existed, so the branch was cloned with `--depth=1000`, `core.longpaths=true`
and `core.autocrlf=false` to a short temp path. Python 3.15.2 (`python`, not `python3`). **SciPy not
installed** and not added, so `confidence()` used its normal-approximation fallback throughout; before and
after used the same code path. `/tmp/before.json` was kept in the session's temp folder instead.

**Created:** `research/v3/tools/source_keys.py`; `migration/tools/identity_report.py`;
`migration/tests/test_identity_report.py`; `migration/reports/{M05-identity.md,M05-identity-data.json,M05-estimates-diff.md}`.
**Modified:** `research/v3/tools/build_estimates.py`; `migration/tools/inventory.py` (imports the moved
`normalize_url`); `migration/tests/test_build_estimates.py`; `migration/{PLAN,CHECKLIST,HANDOFF,SESSION_LOG}.md`.
No evidence file, `corrections.jsonl`, `strategy.md`, committed `output/` or addon file was changed.

**Test edit, as the test-file header requires:** `test_known_defect_identity_collapses_independent_batches`
became `test_independent_batches_both_count`.

**Commands actually run (from the repo root; `python` on this machine):**
- `python research/v3/tools/build_estimates.py` before any change → 4,407 records, 1,181 estimates, 90 unplaced. Wrong: see Problems.
- Same after the `_file` fix → **4,404 records, 1,238 estimates, 35 unplaced** (matches MIG-001). Copied to `before.json`, sha256 `407e3954…`. Output restored.
- `python -m unittest discover -s research/v3/migration/tests` → 41 OK at baseline, **67 OK** at the end.
- `python research/v3/tools/build_estimates.py` twice after the change → 4,404 records, **1,203 estimates**, 35 unplaced; estimates.json and summary.md sha256 identical (`9b9923e7…`, `8173671b…`). Output restored.
- `python research/v3/migration/tools/estimates_diff.py <before> research/v3/output/estimates.json --md research/v3/migration/reports/M05-estimates-diff.md`
- `python research/v3/migration/tools/identity_report.py --json research/v3/migration/reports/M05-identity-data.json`
- `python research/v3/tools/audit_studies.py` → 426 studies, 140 clean (unchanged). Output restored.
- `python research/v3/migration/tools/validate.py` → `manifest/validation.json` unchanged.
- `python research/v3/migration/tools/inventory.py` → 1,244 files, 543 URLs, manifest unchanged by `git status`, so the normalizer move changed nothing.

**Measured results:**
- Collision groups (legacy → current): 160 → 127; differing **77 → 0**; identical 83 → 124; inside listed partial copies 0 → 3.
- 23 partial copies, 1 pooled study, 79 copy rows out of vaguer groups.
- Estimates diff: 35 removed, 0 added, 79 changed; 50 chance values moved, largest 0.0989; 2 rows moved 5+ points, 15 moved 2+, 24 moved 1+.
- Material-level casts: +29,056 restored independent cohorts, -4,000 pool, -57,106 family duplicates.
- All 10 Reddit 10u5ao8 batches count (`188658 → 192870` 22,030 → 20,030). Both Bugy Serevite cohorts count (400 → 800). All 7 Aqirite pairs share an identity.

**Problems:**
- **168 / 90 / 78 could not be reproduced**, which the prompt asked for first. The MIG-001 script was never committed. Variants tried: study by studyKey or file + studyKey; 2 to 10 compared fields including `histogram`; raw or corrected rows; normalized or raw source; with or without the null-casts key. Closest are 160 / 77 / 83 and 160 / 82 / 78. Moved on with 160 / 77 / 83 as the documented baseline; the "≈288k" figure is also superseded.
- **Windows bug:** `load()` wrote `_file` with backslashes, so all 610 file-scoped corrections were ignored. Fixed with `.replace(os.sep, "/")`, the idiom `validate.py` and `inventory.py` already use. No effect on Linux. Outside the prompt's scope, but no baseline was possible without it.
- A literal reading of the prompt's fingerprint failed on real data three ways; each was found by inspecting pairs and fixed with a test. Exact tuples double-counted copies (`df-r3…`, `ww-b006…`, Superbondez). Batches 1/6 and 5/9 merged despite being separate batches. Counting all ten batches plus `df-q21-b019` gave 40,030 casts for 20,030 real ones.

**Decisions:** rule refinements in PLAN §3 rule 1 and `reports/M05-identity.md`. Estimator handles the pooled
study (rather than a correction) because this task forbade editing `corrections.jsonl`. Single-row subsets
stay separate, as the prompt's 2-output bar requires; they are listed for review. `reports/M05-identity-data.json`
is committed because the review lists are longer than the report shows.

**Ending commit:** see `git log` on `migration/v3-historical-research` ("v3 migration M05: …").

**Remaining:** M03, M06, M04, M07, M08, M09, M10.

---

## MIG-003 — 2026-10-31 (Claude Opus 5.5, Claude in a cloud session)

**Tasks:** M03.0 typeless records · M03.1 deterministic re-import with castsBasis · M03.5 GameData tables

**Starting commit:** `5d993421eca6794f8b40b40d71cc94dddbe7b652` on `migration/v3-historical-research`.

**Environment:** Linux, Python 3.13 (`python3`), **SciPy installed** (MIG-002 had none), so confidence values and the
estimates hash differ from MIG-002. Before and after used the same code path here. Shallow clone of the branch;
`before.json` and the M05 identity copy were kept outside the repo. Push access was missing at the start of the
session and was granted partway through.

**Created:** `research/v3/evidence/imported/{typeless-agent-records,gamedata-mill-prospect-reference}.jsonl`;
`migration/tests/test_m03_import.py`; `migration/tests/fixtures/pre-m03-study-ids.jsonl`;
`migration/reports/{M03-import.md,M03-import-data.json,M03-estimates-diff.md,M03-identity-data.json}`.
**Modified:** `research/v3/tools/import_existing.py` (rewritten around the old code path); `research/v3/tools/build_estimates.py`
(`CORRECTABLE` + 7 fields; `study_date`/`epoch_weight` read `observedOn`); `research/v3/tools/audit_studies.py`
(`observedOn` counts as a date); `migration/tools/validate.py` (castsBasis/derivation/inputs/observedOn checks);
all five existing files in `evidence/imported/` (new fields only on existing rows); `migration/manifest/validation.json`;
`migration/{SCHEMA-EXTENSION,PLAN,CHECKLIST,HANDOFF,SESSION_LOG}.md`.
Not changed: any agent evidence file, `corrections.jsonl`, `strategy.md`, `GameData.lua`, committed `output/`, addon files.
**Tests:** none of the 67 existing tests was edited.

**Commands actually run (repo root):**
- `python3 research/v3/tools/build_estimates.py` at HEAD → 4,404 records, 1,203 estimates, 35 unplaced; copied to `before.json` (sha256 `0ec7f0e7…`, SciPy). Output restored.
- `python3 research/v3/tools/import_existing.py` at HEAD → 652 / 1,018 / 52 / 8 / 1, `git status` clean (idempotent baseline).
- `python3 research/v3/tools/import_existing.py --report research/v3/migration/reports/M03-import-data.json` → 1,055 old-study rows (652 kept IDs + 403 name-only), 10 typeless, 1,018 itemdb, 52/8/1 GameData, 75 GameData mill/prospect reference rows. Run twice: `diff -r` of `evidence/imported/` and `cmp` of the report identical.
- `python3 research/v3/tools/build_estimates.py` twice → 4,882 records, **1,205 estimates, 433 unplaced**; estimates.json sha256 `1081c316…` and summary.md `3b9d8120…` both times.
- `python3 research/v3/migration/tools/estimates_diff.py before.json research/v3/output/estimates.json --md research/v3/migration/reports/M03-estimates-diff.md` → 2 added, 0 removed, 67 changed; largest chance move 0.0053.
- `python3 research/v3/migration/tools/identity_report.py --json research/v3/migration/reports/M03-identity-data.json` → differing groups 0; groups 128; partial copies 24; near copies 23; small subsets 11; cross-source 10; misplaced rows 81; pooled 1.
- `python3 research/v3/tools/audit_studies.py` → 454 studies, 40 clean (HEAD, run in a worktree: 426 / 140). Output restored.
- `python3 research/v3/migration/tools/validate.py` → 4,985 records (4,882 effective), **5 errors** (3 METHOD_UNKNOWN, 2 METHOD_MISSING), **175 warnings** (55 FIELDS_MISSING, 120 ID_REUSED_ACROSS_FILES). Was 15 / 693.
- Correction check (ad-hoc script, HEAD worktree vs branch): 643 lines all matching a record; 333 corrected records (45 import-study, 52 import-ref) both sides.
- `python3 -m unittest discover -s research/v3/migration/tests` → **99 tests OK** (67 + 32).

**Measured results:** in `reports/M03-import.md`. Key: TYPE_MISSING 10 → 0; DATE_NOT_ISO 518 → 0; effective kept rows
by basis: 310 reported, 258 nominalEquivalent, 33 countedFromInputs, 19 none; 78 observation dates moved to `observedOn`;
GameData tsmRetail 903/903 present, mill/prospect 75 of 98 rows missing and imported as reference.

**Problems:**
- First run placed every single-material name-only row: Kyparite `family:Sparkling Shard` went 438 → 876 study casts
  (legacy agent copies under a differently normalizing URL). Fixed with an agent-copy check by numbers. A draft would
  also have placed 222 Jallfo sheet rows that agents had deliberately recorded without casts.
- The study audit's clean count fell 140 → 34: the audit read only `dataDate`. It now also accepts `observedOn` (40
  clean). The other 98 studies were never really dated; their prose had passed the audit's truthiness check.

**Decisions:** name-only placement rule (PLAN §3 rule 4); `reportedInitialOre`/`reportedOrePurchasedOrProcessed` go to
`inputsPurchased`, not processed; GameData mill/prospect chance not carried (Poisson/proxy, "NOT MEASURED");
`rawInputName` added to the schema for the unplaceable deck record; mapped typeless rows use `replaces`.

**Ending commit:** see `git log` ("v3 migration M03: …").

**Remaining:** M03.2–M03.4, M03.6, M06, M04, M07, M08, M09, M10.

---

## MIG-004 — 2026-10-31 (Claude Opus 5.5, Claude in a cloud session)

**Tasks:** M03.2 observation `.json` archives · M03.3 `evidence/v2` and `evidence/leads` · M03.4 worker submissions and the
43 other-schema JSONL records · M03.6 ledger CSVs. M03 complete.

**Starting commit:** `c86870907e92c5c1b5ccb8d5224095ae6effa01f` on `migration/v3-historical-research`.

**Environment:** Linux, Python 3.13.18 (`python3`), **SciPy 1.18.1 installed** (same code path as MIG-003, so hashes compare).
Clone deepened with `git fetch --depth=1000 origin migration/v3-historical-research`. `before.json` and the M03 identity copy
kept outside the repo. No network access was used for evidence; every number comes from files in the branch.

**Created:** `research/v3/evidence/imported/{historical-archive-cohorts,v2-report-cohorts,legacy-milling-cohorts}.jsonl`;
`migration/tests/test_m03b_import.py`; `migration/tests/fixtures/m03b-ids.jsonl`;
`migration/reports/{M03b-import.md,M03b-import-data.json,M03b-estimates-diff.md,M03b-identity-data.json}`.
**Modified:** `research/v3/tools/import_existing.py` (new section 4, `main()` writes the new families and the `historical`
report key); `migration/manifest/validation.json` (record counts); `migration/{PLAN,CHECKLIST,HANDOFF,SESSION_LOG}.md`.
Not changed: any agent evidence file, `corrections.jsonl`, `strategy.md`, `build_estimates.py`, `GameData.lua`, committed
`output/`, addon files. **Tests:** none of the 99 existing tests was edited.

**Commands actually run (repo root):**
- `python3 research/v3/tools/build_estimates.py` at HEAD → 4,882 records, 1,205 estimates, 433 unplaced; `estimates.json` sha256 `1081c316…` (= MIG-003). Copied to `before.json`; `M03-identity-data.json` copied; output restored.
- `python3 -m unittest discover -s research/v3/migration/tests` at HEAD → 99 OK.
- Scoping and inspection scripts kept outside the repo: inventory selection, a v3 URL index, per-file claim context.
- `python3 research/v3/tools/import_existing.py --report research/v3/migration/reports/M03b-import-data.json`, run twice → `diff -r` of `evidence/imported/` and `cmp` of the report identical. Output: archives 8, v2 reports 16, legacy milling 27, leads 0, submissions 0.
- `python3 research/v3/tools/build_estimates.py` twice → 4,933 records, **1,205 estimates, 447 unplaced**; `estimates.json` `3861b696…`, `summary.md` `0ed83dd3…` both times.
- `python3 research/v3/migration/tools/estimates_diff.py before.json research/v3/output/estimates.json --md research/v3/migration/reports/M03b-estimates-diff.md` → 0 added, 0 removed, 36 changed (chance 8, studies 28); largest chance move 0.0150; no `studyCasts` change.
- `python3 research/v3/migration/tools/identity_report.py --json research/v3/migration/reports/M03b-identity-data.json` → differing 0; groups 128; partial copies 24; near copies 24 (+1); everything else equal to M03.
- `python3 research/v3/migration/tools/validate.py` → 5,036 records (4,933 effective), 5 errors, 175 warnings (unchanged).
- `python3 research/v3/tools/audit_studies.py` → 473 studies, 40 clean. Output restored.
- Correction check (`build_estimates.load()`, branch and a HEAD worktree): 643 lines all matching; 333 corrected records (45 import-study, 52 import-ref) both sides.
- `python3 -m unittest discover -s research/v3/migration/tests -v` → **125 tests OK** (99 + 26).

**Measured results:** in `reports/M03b-import.md`. 99 files in scope (11 + 38 + 1 + 38 + 3 + 8) hold 700 claims plus 43
other-schema records and 8 ledgers. Imported: 51 rows from 5 new sources (8 TBC reference rows, zzyjzu, the Luredrop range,
14 unplaced 1smgllg rates, 27 legacy milling rows). Skipped: 375 held claims (173 with matching numbers), 274 reference or
identity links, 44 new sources with a written reason, 3 legacy-milling copies, 8 recipes present, 5 reconciliation copies,
8 ledgers.

**Problems:**
- A first legacy-milling pass counted Kidneph's 1,000 herbs as 200 five-herb casts (the old record's normalization). It moved 15 BfA chances by up to 0.335, because those groups already mix 20-herb mass-mill means with five-herb equivalents. The rows now keep `casts: null` for M06.
- A first 1smgllg pass named studies by ore family. Identity read Silver as a partial copy of Tin (equal rounded rates; 24 → 25 partial copies). Numbering the claims as a batch family fixed it.
- noriiju (Blizzard forum 2280780) was first mapped as a new source because a manual lookup used the raw URL, not the normalized key. The agent already holds it. The mapper guard (no import once v3 holds a source) caught it. The row was unplaced, so no estimate saw it.
- `claims_in` first read only URL fields named like `url`/`source`, missing 5 URLs (e.g. `originalPost`, `additionalCoverage`). It also took the nested `source` object, not its parent, as the claim, so Felslate 2016 compared no numbers. Both fixed and tested.

**Decisions:** PLAN §3 rule 5 (historical claims). Families with no imported rows write no file. Reference hosts and
Wowhead identity pages are links, not cohorts. The 37 `v2/source-reviews` files and 21 submission audit CSVs are outside
M03 (no study objects); they are left for M04/M07 dispositions. s6bfrl uncommon gems and the Felslate 101-vs-97 total
are listed for the Master and not imported.

**Ending commit:** see `git log` ("v3 migration M03: …").

**Remaining:** M06, M04, M07, M08, M09, M10.

---

## MIG-005 — 2026-10-31 (Claude Opus 5.5, Claude in a cloud session)

**Tasks:** M06 units, denominators and cast-basis weighting (S16). M06 complete.

**Starting commit:** `98893b8` on `migration/v3-historical-research`.

**Environment:** Linux, Python 3.13.18 (`python3`), **SciPy 1.18.1 installed** (same code path as MIG-003/004). Repo
attached with push access on the first request. Clone deepened with `git fetch --depth=1000 origin
migration/v3-historical-research`. `before.json` and the M03b identity copy kept outside the repo. No network for evidence,
no AI extraction. The session was interrupted once and resumed; nothing was lost (all work was on disk).

**Created:** `migration/tools/units_report.py`; `migration/tests/test_m06_units.py`;
`migration/reports/{M06-units.md,M06-units-data.json,M06-estimates-diff.md,M06-identity-data.json}`.
**Modified:** `research/v3/tools/build_estimates.py` (`row_unit`, `group_unit`, `same_unit`, `unit_average`, `row_use`,
four constants; the study loop and reference priors use them; estimates gain `inputsPerCast`; basis text names
equivalent and converted casts); `migration/tests/test_build_estimates.py`, `migration/tests/test_m03b_import.py` (one test
each, below); `migration/{PLAN,SCHEMA-EXTENSION,CHECKLIST,HANDOFF,SESSION_LOG}.md`.
Not changed: any evidence file, `corrections.jsonl`, `strategy.md`, `evidence-format.md`, `import_existing.py`,
committed `output/`, addon files.

**Test edits, as the test-file header requires:**
- `test_build_estimates.Basics.test_known_defect_totals_without_casts_unused` → `test_total_without_casts_or_input_count_unused`
  (assertion unchanged: the row states no `inputsProcessed`; S16 is resolved only for rows that do).
- `test_m03b_import.EstimatorEffect.test_totals_without_casts_add_no_casts` → `test_totals_without_casts_count_from_inputs`
  (behaviour changed on purpose: 1,000 herbs at 20 per mass mill now count as 200 five-herb casts; studyCasts 100 → 300).

**Commands actually run (repo root):**
- `python3 research/v3/tools/build_estimates.py` at HEAD → 4,933 records, 1,205 estimates, 447 unplaced; `estimates.json` `3861b696…`, `summary.md` `0ed83dd3…` (= MIG-004). Copied to `before.json`; `M03b-identity-data.json` copied; output restored.
- `python3 -m unittest discover -s research/v3/migration/tests` at HEAD → 125 OK.
- Ad-hoc measurement scripts kept outside the repo (basis × fields, row shapes, contribution today, mixed groups, cast unit consistency `casts × inputsPerCast` vs `inputsProcessed`, agent note patterns, group review); the committed `units_report.py` reproduces their counts.
- `python3 research/v3/tools/build_estimates.py` twice after the change → 4,933 records, 1,205 estimates, 447 unplaced; `estimates.json` `6976d1bd…`, `summary.md` `c16d76e6…` both times (`sha256sum -c`).
- `python3 research/v3/migration/tools/estimates_diff.py before.json research/v3/output/estimates.json --md research/v3/migration/reports/M06-estimates-diff.md` → 0 added, 0 removed, 112 changed; largest chance move 0.6753.
- `python3 research/v3/migration/tools/identity_report.py --json research/v3/migration/reports/M06-identity-data.json` → differing 0; groups 128; partial copies 24; near copies 24; pooled 1. File identical to `M03b-identity-data.json`.
- `python3 research/v3/migration/tools/units_report.py --json research/v3/migration/reports/M06-units-data.json` (twice, `cmp` identical).
- Sensitivity run (ad hoc): backfilling the 398 agent counted-cast rows as `countedFromInputs` → 18 estimates change, confidence ≤ 3 points, no chance or average.
- Output restored (`git checkout -- research/v3/output`).
- `python3 research/v3/migration/tools/validate.py` → 5 errors (3 METHOD_UNKNOWN, 2 METHOD_MISSING), 175 warnings; `manifest/validation.json` unchanged.
- `python3 research/v3/tools/audit_studies.py` → 473 studies, 40 clean. Output restored.
- `python3 research/v3/tools/import_existing.py --report <tmp>` twice → `evidence/imported/` unchanged by `git status`, `diff -r` and report `cmp` identical.
- Correction check (`build_estimates.load()`): 643 lines all matching; 333 corrected records (45 import-study, 52 import-ref).
- `python3 -m unittest discover -s research/v3/migration/tests -v` → **148 tests OK** (125 + 23).

**Measured results:** in `reports/M06-units.md`. Key: placed study rows contributing nothing 654 → 626 (every one with a
reason code); totals without casts unused 551 rows / 105 studies → 526 / 92; mixed-batch groups without conversion 58 → 0;
373 rows now count at the 0.5 chance weight; 38 chance moves of 5+ points, all from per-20 mass casts converted to
five-input casts (BfA/SL/Legion milling, SL prospecting) or WoD totals that now count; 65 studyCasts rises, none from copies.

**Problems:**
- 58 imported nominalEquivalent rows say `inputsPerCast` 20 while their casts are five-input units. A first unit rule
  that used `inputsPerCast` there would have divided them by 4; `row_unit()` reads nominal casts as 5 (tested).
- The first `group_unit()` counted nominal units as stated batches, so a Midnight 10-herb group with a nominal row would
  have become a 5-herb group (caught by `test_midnight_ten_herb_unit`); it now reads stated batches only.
- The first `row_use()` tagged a conversion only for rows with casts; averages without casts and mass-mill rows counted
  from inputs were converted silently and `units_report.py` listed 24 groups as "unconverted". Fixed: every conversion
  carries `converted:<own>-><unit>`.
- An ad-hoc script named `inspect.py` shadowed the standard library module; renamed (outside the repo).
- Agents write counted casts (README rule 2) without `castsBasis`, so the field-based rule reads them as reported. Not
  fixed in code (no new free-text parsing; M08 removes it); listed for backfill.

**Decisions:** PLAN §3 rule 2 implemented as written there and detailed in `reports/M06-units.md` (weight 0.5; normalize
per input inside one group rather than splitting groups; other-batch chances left out; refunds never change counts;
notes never read). `units_report.py` is the machine-readable "unused reason" source until M08 moves per-record reasons
into the estimator output. Schema proposals 7 and 8 added to `SCHEMA-EXTENSION.md`.

**Ending commit:** see `git log` ("v3 migration M06: …").

**Remaining:** M04, M07, M08, M09, M10.

---

## MIG-006 — 2026-11-01 (Claude Sonnet 5.5, Claude in a cloud session)

**Tasks:** M04.1 deterministic linking of Markdown and irregular notes · M04.2 residual queue. M04.3 and M04.4 not started.

**Starting commit:** `eb1db7b` on `migration/v3-historical-research`.

**Environment:** Linux, Python 3.13.18 (`python3`), **SciPy 1.18.1 installed** (same code path as MIG-003 to MIG-005, so hashes compare).
The first attach-with-push-access request was denied by the session's permission check; the retry the prompt prescribes was
granted. The clone landed on `main`, so the branch was fetched (`git fetch --depth=1000 origin migration/v3-historical-research`)
and checked out. `before.json` kept outside the repo. No network for evidence, no AI extraction.

**Created:** `migration/tools/link_sources.py`; `migration/tests/test_link_sources.py`;
`migration/manifest/{links.jsonl,extraction-queue.jsonl,links-summary.json}`; `migration/reports/M04-links.md`.
**Modified:** `migration/{CHECKLIST,SESSION_LOG,HANDOFF,PLAN}.md`.
Not changed: any evidence file, `corrections.jsonl`, `strategy.md`, `evidence-format.md`, `SCHEMA-EXTENSION.md`,
`build_estimates.py`, `import_existing.py`, committed `output/`, addon files. **Tests:** none of the 148 existing tests was edited.

**Commands actually run (repo root):**
- `python3 research/v3/tools/build_estimates.py` at HEAD → 4,933 records, 1,205 estimates, 447 unplaced; `estimates.json` sha256 `6976d1bd…`, `summary.md` `c16d76e6…` (= MIG-005). Copied to `before.json`; output restored (`git checkout -- research/v3/output`).
- `python3 -m unittest discover -s research/v3/migration/tests` at HEAD → 148 OK.
- Ad-hoc inspection scripts kept outside the repo (inventory row shape, name-only rows, v3 names for the 1smgllg labels, the s6bfrl rows, the zkay8v agent file and its corrections).
- `python3 research/v3/migration/tools/link_sources.py` (scratch and in-repo runs while developing; final run) → 265 files: linked 133, exception 44, residue 49, disposed 39; 55 queue sources. Three `sha256sum -c` reruns identical.
- `python3 -m unittest discover -s research/v3/migration/tests` after the work → **197 tests OK** (148 + 49).
- `python3 research/v3/migration/tools/validate.py` → 5,036 records (4,933 effective), 5 errors, 175 warnings (unchanged; `validation.json` untouched).
- `python3 research/v3/tools/build_estimates.py` twice → 4,933 records, 1,205 estimates, 447 unplaced; `estimates.json` `6976d1bd…`, `summary.md` `c16d76e6…` both times; `cmp` with `before.json` identical; `estimates_diff.py` → 0 added, 0 removed, 0 changed.
- `python3 research/v3/tools/audit_studies.py` → 473 studies, 40 clean (unchanged). Output restored.
- `python3 research/v3/tools/import_existing.py --report <tmp>` twice → `evidence/imported/` unchanged by `git status`, report `cmp` identical.
- Correction check (`build_estimates.load()`): 643 lines; 333 corrected records (236 agent, 52 import-ref, 45 import-study).

**Measured results:** in `reports/M04-links.md`. Key: 265 in-scope files → linked 133, exception 44, residue 49, disposed 39
(each with a reason); the 124 Markdown candidates → 58 / 18 / 45 / 3. Citation groups: linked 266 (191 strong, 75 weak),
source-held 340, exception 91, residue 70, skipped-decided 63, reference 317. Queue: 55 sources, 49 files, 138 anchors.
Known candidates: 86 name-only rows → 58 linked, 6 exception, 22 unlinked; 1smgllg 11 of 14 linked by name; s6bfrl 6 exceptions.
Registry (543 URLs): 162 held by a record's source, 16 mentioned in notes only, 365 not in v3.

**Problems:**
- A first exception rule flagged any observational claim with no matching result, including claims whose only number was a
  batch size (JSON `sources[]` entries with "1040"): 121 exception groups. Now an exception needs a number that is not a held
  batch size; the rest are `source-held` (91 groups).
- Numbers under one URL's list item leaked into the next URL's window (a test caught it). A line now belongs to the nearest URL above it in its paragraph.
- The name-only candidates found no agent rows for zkay8v: corrections exclude them as duplicates of the import, so the effective
  index never saw them. Candidates now read raw agent rows (flagged `effective`); label resolution still reads effective rows,
  because a raw midnight row carried a wrong item ID (242721) that corrections fix.
- Same-name agent rows for the 10,000-ore zkay8v cohort first read as 22 exceptions; they are 1,000-cast rows, a different cohort. An exception now needs the same cast count.
- The first run left 26 files with unheld sources whose counts sat elsewhere in the file as leads only (no queue entry). They now enter the queue as `proximity: file` pieces (at most 3 sources per file); in the final run 30 pieces in 24 files, and no citation is left as a bare lead.
- The handoff's "92 agent-held name-only rows" is 86 in the data (83 by URL, 3 by numbers); the 6 placed rows make 92.

**Decisions:** linking by result numbers, never batch sizes; weak links kept and labelled; file-level residue capped at three
sources per file; `NEW_SOURCES` decisions reused as written; four reference hosts added to the linker only
(json-schema.org, wowpedia.fandom.com, wowpedia.org, URL templates); no importer or corrections change, so the 1smgllg
placements stay proposals. PLAN §3 rule 6 added.

**Ending commit:** see `git log` ("v3 migration M04.1-M04.2: …").

**Remaining:** M04.3, M04.4, M07, M08, M09, M10.


---

## MIG-007 — 2026-11-01 (Claude Sonnet 5.5, Claude in a cloud session)

**Tasks:** M04.3 batched extraction of the residual queue · M04.4 spot-check. M04 complete.

**Starting commit:** `bbe0516` on `migration/v3-historical-research`.

**Environment:** Linux, Python 3.13.18 (`python3`), **SciPy 1.18.1 installed** (same code path as MIG-003 to MIG-006, so hashes
compare). Repo attached with push access on the first request; the clone existed on `main`, so
`git fetch --depth=1000 origin migration/v3-historical-research` and a checkout of the branch. `before.json` kept in
`/home/claude/scratch`, outside the repo. No network for evidence. There is no model API in the workspace: the reader of each
prompt was Claude in the session, answering in the JSON shape the tool defines; the tool validates everything.

**Created:** `migration/tools/extract_batch.py`; `migration/tests/test_extract_batch.py` (69 tests);
`migration/manifest/extraction/*.json` (55 checkpoints); `research/v3/evidence/imported/extracted-historical-sources.jsonl`
(12 rows); `migration/reports/{M04-extraction.md,M04-extraction-data.json,M04-spot-check.md,M04-estimates-diff.md}`.
**Modified:** `migration/tools/link_sources.py` (recipe-only holdings, below); `migration/tests/test_link_sources.py` (+1 test, none
edited); regenerated `manifest/{links.jsonl,links-summary.json,extraction-queue.jsonl,validation.json}`;
`migration/{PLAN,CHECKLIST,SESSION_LOG,HANDOFF}.md`.
Not changed: any agent evidence file, `corrections.jsonl`, `strategy.md`, `evidence-format.md`, `build_estimates.py`,
`import_existing.py`, `SCHEMA-EXTENSION.md`, committed `output/`, addon files.

**Commands actually run (repo root):**
- `python3 research/v3/tools/build_estimates.py` at HEAD → 4,933 records, 1,205 estimates, 447 unplaced; `estimates.json` `6976d1bd…`,
  `summary.md` `c16d76e6…` (= MIG-006). Copied to `before.json`; `git checkout -- research/v3/output`.
- `python3 -m unittest discover -s research/v3/migration/tests` at HEAD → 197 OK.
- Ad-hoc scripts kept outside the repo (anchor and file sizes, the v3 holdings of each candidate cohort, the weak-link draw, the
  scan of out-of-scope files for citations with counts, the table generator for the report).
- `extract_batch.py prompt <source> [--brief]` for all 55 sources; `submit` for 55 answers (one rejected by the holdings rule, then
  accepted as `held-elsewhere` null); two answers resubmitted after the sibling notes were found; `status`, `verify`, `write
  [--report] [--check]`.
- `python3 research/v3/migration/tools/link_sources.py` three times (before and after the recipe-only amendment, and twice more for
  the byte-identity check, `sha256sum -c` OK) → 265 files: linked 140, exception 44, residue 42, disposed 39; 46 queue sources.
- `python3 -m unittest discover -s research/v3/migration/tests` → **267 tests OK** (197 + 69 + 1).
- `python3 research/v3/migration/tools/validate.py` → 5,048 records (4,945 effective), 5 errors, 175 warnings (unchanged; no finding
  on any extracted row).
- `python3 research/v3/tools/build_estimates.py` twice → 4,945 records, 1,205 estimates, 449 unplaced; `estimates.json`
  `d959496aa6fb78b007136383d1d0c9e478dc44462bd904162b717fd4dc378e8f`, `summary.md` `fbf8e3b26d8bb12be21219ce956b83f322e1a1684ea01a3f8214b805c2623d6f` both times.
- `python3 research/v3/migration/tools/estimates_diff.py before.json research/v3/output/estimates.json --md reports/M04-estimates-diff.md`
  → 0 added, 0 removed, 3 changed (Nightshade 171315 → 173056, 173057, 175788); largest chance move 0.0020.
- `python3 research/v3/tools/audit_studies.py` → 475 studies, 40 clean (was 473). Output restored (`git checkout -- research/v3/output`).
- `python3 research/v3/tools/import_existing.py --report <tmp>` twice → reports `cmp` identical, no change under `evidence/imported/`
  other than the new file.
- Correction check (`build_estimates.load()`): 643 lines; 333 corrected records.

**Measured results:** in `reports/M04-extraction.md` and `reports/M04-spot-check.md`. Key: 55 of 55 sources checkpointed; 9 with
rows (12 rows: 3 + 2 drop, 7 recipe), 46 null (ambiguous-doubt 12, qualitative 9, reference-table 8, numbers-not-this-source 8,
identity-link-only 4, needs-original-post 2, held-elsewhere 2, no-observational-numbers 1). Spot-check: 12 of 12 rows correct, 5 of
5 sampled nulls confirmed, 10 weak links (8 true, 1 right source with a coincidental number, 1 false).

**Problems and what they led to:**
- A first writer iterated the live queue. `link_sources.py` drops an extracted source from the queue once its rows make it
  held, so a rerun would have deleted the rows. Caught before the linker was rerun. Checkpoints now carry their queue entry, and the
  writer iterates checkpoints (test `test_rows_survive_the_source_leaving_the_live_queue`).
- A checkpoint for a source that v3 later holds was revalidated as "invalid", not "held". Found by a test; revalidation now skips
  the holdings check and the writer reports `held` (the M10 case).
- The 113-cast Felslate comment was about to be double counted: the French Wowhead page is the same page v3 holds under the
  English URL (`import-study-01027`). The holdings test now treats `@es @fr @de @ru @tw @cn @ko @pt @it @mx @br` as the same page.
- Recipe rows made seven Wowhead spell pages "held", which turned seven files from residue to exception (other sources' counts on
  the same line). `classify()` now calls a source held only by recipe records `source-held`. Exceptions went 44 → 44 files.
- The queue is incomplete: notes the inventory marked `source-links-only` were never in scope, and the observational-count pattern
  misses counts without a unit word ("3000 Nightshade"). Two sibling notes with item IDs and a date were added through
  `EXTRA_FILES`. A scan found 114 file mentions outside the queue entries and 23 unheld sources with counts in out-of-scope files.
- Test fixtures first appended lines in a paragraph with no URL, so the validator (correctly) refused them; fixed in the tests,
  not the tool. The first weak-link draw was on 75 links; the redraw on 76 moved two positions and both new ones were checked.

**Decisions:** the reader is the session itself (no API); conditions and rate changes are proposals, never evidence rows; a name
without an ID in the text is stored raw and unplaced (no placement by name); `casts` stays null unless the text states a cast count
or a batch size to divide by; `cohortKey` stays unset; recipe facts are written as `recipe` rows; weak links are reported, not
dropped. PLAN section 3 rule 6 amended, rule 7 added.

**Ending commit:** see `git log` ("v3 migration M04.3-M04.4: …").

**Remaining:** M07, M08, M09, M10.

## MIG-008 — 2026-11-01 (Claude Sonnet 5.5, Claude in a cloud session)

**Tasks:** M07 final dispositions and the exception queue. M07 complete.

**Starting commit:** `7e0ecba` on `migration/v3-historical-research` (the M04.3-M04.4 commit of MIG-007).

**Environment:** Linux, Python 3.13.18 (`python3`), **SciPy 1.18.1 installed** (same code path as MIG-003 to MIG-007, so hashes
compare). Repo attached with push access on the first request; the clone landed on `main`, so
`git fetch --depth=1000 origin migration/v3-historical-research` and `git checkout -b migration/v3-historical-research FETCH_HEAD`.
`before.json` kept in `/home/claude/work`, outside the repo. No network for evidence; no AI extraction.

**Created:** `migration/tools/dispositions.py`; `migration/tests/test_dispositions.py` (37 tests);
`migration/manifest/{dispositions.jsonl,exceptions.jsonl,scope-gap.jsonl,dispositions-summary.json}`;
`migration/reports/M07-dispositions.md`.
**Modified:** `migration/{CHECKLIST,SESSION_LOG,HANDOFF,PLAN}.md`.
Not changed: any agent evidence file, `corrections.jsonl`, `strategy.md`, `evidence-format.md`, `build_estimates.py`,
`import_existing.py`, `link_sources.py`, `extract_batch.py`, `SCHEMA-EXTENSION.md`, committed `output/`, addon files.

**Commands actually run (repo root):**
- `python3 research/v3/tools/build_estimates.py` at HEAD → 4,945 records, 1,205 estimates, 449 unplaced; `estimates.json`
  `d959496aa6fb78b007136383d1d0c9e478dc44462bd904162b717fd4dc378e8f`, `summary.md` `fbf8e3b26d8bb12be21219ce956b83f322e1a1684ea01a3f8214b805c2623d6f`
  (= MIG-007). Copied to `before.json`; `git checkout -- research/v3/output`.
- `python3 -m unittest discover -s research/v3/migration/tests` at HEAD → 267 OK. (`-s …/tests -t .` fails: the directory is not a package.)
- Ad-hoc scripts kept outside the repo: the scope-gap scan (out-of-scope and in-scope), a v2 source-review classifier, the overlap
  counts of exception / residue / imported files.
- `python3 research/v3/migration/tools/dispositions.py` (about 4 s) after each rule change; final: 1,244 files, 134 exceptions, 47 scope-gap sources.
- `python3 -m unittest discover -s research/v3/migration/tests` → **304 tests OK** (267 + 37).
- `python3 research/v3/migration/tools/link_sources.py` → 265 files: linked 140, exception 44, residue 42, disposed 39; 46 queue sources;
  no tracked file changed. `extract_batch.py write --check` → exit 0. `validate.py` → 5,048 records (4,945 effective), 5 errors, 175 warnings
  (unchanged); `validation.json` unchanged.
- `python3 research/v3/tools/build_estimates.py` twice → 4,945 records, 1,205 estimates, 449 unplaced; `estimates.json` `d959496a…`,
  `summary.md` `fbf8e3b2…` both times. `estimates_diff.py before.json research/v3/output/estimates.json` → 0 added, 0 removed, 0 changed.
  Output restored (`git checkout -- research/v3/output`).
- `python3 research/v3/tools/import_existing.py --report <tmp>` twice → reports `cmp` identical, no change under `evidence/imported/`.
- In-process check of the validator fixes: rows edited in memory (3 rateChange `method` → null, 2 ItemDB rows removed), `build_estimates.build()`
  → same 1,205 estimates; unplaced 449 → 447 with the two rows gone. Nothing written.
- Correction check (`build_estimates.load()`): 643 lines; 333 corrected records.

**Measured results:** in `reports/M07-dispositions.md`. Key: no-observational-content 432, process-artifact 313, linked 131,
held-sources-only 129, exception-queued 65, imported 55, extracted-null 47, reference-only 32, derived-model 22, source-links-only 10,
extracted 4, mechanics-knowledge 4. Exceptions 134 (83 link groups, 6 Jallfo, 12 ambiguous-doubt, 12 single-row subsets, 9 cross-source
pairs, 5 validator errors, 3 merges, 1 each of s6bfrl / zkay8v / 1smgllg / Felslate), 1,070 record IDs named. Scope gap: 23 raw keys
reproduced → 16 clean out-of-scope sources (9 queue sources, 7 decided), 18 in-scope lead-only citations with counts all checkpointed.

**Problems and what they led to:**
- A first pass classed every inventory `source-links-only` note by its citations and put 136 of 220 in a label I had called
  "covered-by-held-sources". Held means page or thread level (rule 5), so the label overclaimed; renamed `held-sources-only` and
  defined as a statement about sources, with the files holding no observational numbers of their own.
- 16 `source-links-only` audit and validation files first came out as `no-observational-content` (their URLs were shorthand keys such as
  `reddit:abc` that the citation reader does not see) and then as `reference-only`. Fixed with the inventory's `urlsNotInV3` keys
  (CSV rows cut off the key) and the importer's own "process artifact" reasons; 33 audit files are process artifacts by name.
- Out-of-scope notes citing a null-extracted source (26 files) were `source-links-only` at first; they are `extracted-null`, the same
  fact the 42 in-scope residue files carry.
- A test found three colliding exception IDs (two merges with different outputs, two subsets with different parents): the hash input now
  includes input / output / method and the parent study.
- Three decisions written for CSV-row sources (`milling-table-inscription`, midnight guide, WotLK table) were unused once the key was
  cut at the comma (the URLs are held); removed, and a test now fails on any decision no scan uses.
- The handoff's "21 submission audit CSVs" is not reproducible by name; 42 CSVs carry "audit" in the path and all are disposed.

**Decisions:** a file with an exception keeps `exception-queued` even if rows were also written from it (its pointers say how many);
a `process-artifact` is a thing about the process (tests, audits, coverage, reports citing nothing); policy questions (M06 weight and
backfills, name-only rule) are in the report's For the Master, not `exceptions.jsonl`; the validator fixes are proposed correction
lines in the exception rows, not applied (`corrections.jsonl` is the Master's); the linker's count pattern was not widened.

**Ending commit:** see `git log` ("v3 migration M07: …").

**Remaining:** M08, M09, M10.

---

## MIG-009 — 2026-11-01 (Claude Sonnet 5.5, Claude Code on the owner's Windows machine)

**Tasks:** M08 estimator integration

**Starting commit:** `d4390b87a5a7872f0a36e852bc6246a4031a10eb` (M07) on `migration/v3-historical-research`, fast-forwarded from the
M05-era local clone with `git fetch --depth=1000` and `git merge --ff-only`.

**Environment:** Windows, clone at a short temp path (`core.longpaths=true`, `core.autocrlf=false`), `python`. **SciPy not installed**
(expected hash with SciPy `d959496a…` could not be checked; baseline here is `898790d5…`). Before and after ran on the same machine.

**Created:** `migration/tools/estimator_effects.py`; `migration/tests/test_m08_estimator.py` (44 tests);
`migration/reports/{M08-estimator.md,M08-estimator-data.json,M08-estimates-diff.md}`.
**Modified:** `research/v3/tools/build_estimates.py` (the one task allowed to); `research/v3/.gitignore` (`output/unused.json`);
`migration/{PLAN,CHECKLIST,SCHEMA-EXTENSION,SESSION_LOG,HANDOFF}.md`. No evidence file, `corrections.jsonl`, `strategy.md`, committed
`output/` or addon file changed.

**Commands actually run (repo root):**
- `python research/v3/tools/build_estimates.py` at HEAD → 4,945 records, 1,205 estimates, 449 unplaced; `estimates.json` `898790d5…`
  (no SciPy). Copied to `before.json` outside the repo; `git checkout -- research/v3/output`.
- `python -m unittest discover -s research/v3/migration/tests` at HEAD → 304 OK; at the end → **348 OK** (304 + 44).
- Measurement scripts kept outside the repo, then folded into `estimator_effects.py`: unlockState / percentMeaning / date shapes;
  cross-check of the new reasons against M06's `unusedRows`; the `duplicateRowInStudy` and range-leak breakdowns.
- After the three guards only: build → `cmp` with `before.json` identical. After usage tracking: identical again.
- `python research/v3/tools/build_estimates.py` twice → `estimates.json` `898790d5…`, `summary.md` `c94b042f…`, `unused.json` `cf8597e4…` both times.
- `python research/v3/migration/tools/estimates_diff.py before.json research/v3/output/estimates.json --md reports/M08-estimates-diff.md` → 0 added, 0 removed, 0 changed.
- `python research/v3/migration/tools/estimator_effects.py --json reports/M08-estimator-data.json`.
- `python research/v3/tools/audit_studies.py` → 475 studies, 40 clean. Output restored; `unused.json` removed.
- `python research/v3/migration/tools/validate.py` → 5,048 records (4,945 effective), 5 errors, 175 warnings (unchanged).
- `python research/v3/migration/tools/link_sources.py` → 265 files: linked 140, exception 44, residue 42, disposed 39 (no tracked file changed).
- `python research/v3/migration/tools/dispositions.py --check` → identical to the committed files (exit 0).
- `python research/v3/tools/import_existing.py --report <tmp>` twice → reports `cmp` identical.
- Correction check: 643 lines; 333 corrected records.

**Measured results:** in `reports/M08-estimator.md`. Key: the three guards (unlockState first, ISO-only dates, percentMeaning must be
perCast) each affect **0 records** in the committed evidence and move 0 estimates; 2,597 of 4,945 records are used and 2,348 carry one
reason code; M06's 626 contribute-nothing rows reconcile exactly (414 same reason + 212 dropped earlier as duplicate, unlock skip or copy).

**Problems:**
- Local clone was at the M05 commit; fetched and fast-forwarded 8 commits before starting.
- No SciPy, so the expected hash could not be compared.
- The first design had a `groupNoEstimate` reason; it is unreachable (a row that adds a number always yields an estimate), so it was removed.

**Decisions:** `unused.json` is a separate file in `output/`, not a field of `estimates.json`. `unlockState: null` means "not stated" and
does not fall back to text (task wording); the hazard with `evidence-format.md` is recorded for the Master. Month-only dates are placed
only when the whole month is on one side of a rate change. Duplicate-row-in-study and ranges-before-dedupe are reported, not changed
(each would move an estimate). `unused.json` is git-ignored until the owner decides the `output/` policy.

**Ending commit:** see `git log` ("v3 migration M08: …").

**Remaining:** M09, M10.
