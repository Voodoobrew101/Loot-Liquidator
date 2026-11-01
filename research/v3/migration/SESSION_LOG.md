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
