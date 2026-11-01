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
