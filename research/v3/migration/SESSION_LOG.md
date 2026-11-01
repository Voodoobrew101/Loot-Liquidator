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
