# Migration checklist

Status values: Not Started / In Progress / Blocked / Complete. A box is ticked only when every
acceptance criterion is met and the evidence column points at something checkable.
Model names follow the owner's table in the master prompt; availability in the Codex picker is unverified.

Recommended order: M02 ✓ → M05 → M03 → M06 → M04 → M07 → M08 → M09 → M10
(M04.1 linking may run in parallel with M05 once M02 is done.)

## Progress

| | Count |
| --- | --- |
| Top-level tasks | 11 |
| Complete | 3 (M00, M01, M02) |
| In progress | 0 |
| Blocked | 0 |
| Not started | 8 |
| Completion (verified top-level) | 27% |

---

## M00 — Architecture and historical-data audit
- [x] **M00 — Audit v3, reassess strategy, choose approach**
  - Priority: P0 · Depends on: — · Model: GPT-6 Astra, High
  - Acceptance: baseline measured by running code; ten assessment questions answered with numbers; strategy per source category chosen; recorded in PLAN.md
  - Status: Complete
  - Evidence: `PLAN.md` §1–3; SESSION_LOG MIG-001

## M01 — Full historical source inventory
- [x] **M01 — Deterministic inventory of every historical file**
  - Priority: P0 · Depends on: M00 · Model: GPT-6 Luna, Medium
  - Acceptance: every file under `research/` (excluding v3) plus addon data files listed with hash, category, counts, URLs, v3 coverage and a preliminary disposition; source URL registry; reruns byte-identical; tests pass
  - Status: Complete
  - Evidence: `tools/inventory.py`; `manifest/inventory.jsonl` (1,244 files), `manifest/url-registry.jsonl` (543 URLs); `tests/test_inventory.py` 10/10 pass; idempotency checked by sha256
  - [x] M01.1 inventory tool
  - [x] M01.2 unit tests (URL normalization, dispositions, registry, idempotency, read-only)
  - [x] M01.3 manifest generated at snapshot 575b252
  - Note: *final* per-file dispositions are produced by M07 (`manifest/dispositions.jsonl`).

## M02 — Test harness, validator and schema extension
- [x] **M02 — Make v3 testable before changing anything**
  - Priority: P0 · Depends on: M00 · Model: GPT-6.1 Sol, Medium
  - Acceptance: validator reports every off-schema record (expect the 10 typeless records in `evidence/midnight/2026-10-31-midnight-refining-shattering-decks.jsonl`); characterization tests pin current `build_estimates.py` behaviour; estimates diff tool exists; schema extension written up; `__pycache__` ignored; all tests pass
  - Status: Complete (MIG-001)
  - Evidence: `python3 -m unittest discover -s research/v3/migration/tests` → 41 tests OK; validator run → 4,497 records, 15 errors (10 TYPE_MISSING in the midnight shattering-decks file, 3 METHOD_UNKNOWN, 2 METHOD_MISSING), 693 warnings, written to `manifest/validation.json`; `build_estimates.py` output byte-identical to the pre-session rebuild (sha256)
  - [x] M02.1 `tools/validate.py` (read-only; types, required fields, enums, ID uniqueness per file, JSON errors) + tests
  - [x] M02.2 characterization tests for `build_estimates.build()` on small fixtures: totals+casts, percent-only, reference prior, conditional/unlock, epoch weight, S13 family rows, corrections/exclude, `replaces`, current identity collapse (documented as known defect)
  - [x] M02.3 `tools/estimates_diff.py`: compare two `estimates.json` → added/removed/changed rows, chance/average deltas, markdown summary + tests
  - [x] M02.4 `SCHEMA-EXTENSION.md`: optional fields (`castsBasis`, `inputsProcessed`, `inputsPurchased`, `inputsRefunded`, `cohortKey`, `unlockState`, `derivations`, `migratedFrom`, `dataDateText`) and `CORRECTABLE` additions (owner approves `evidence-format.md` change in the M10 PR)
  - [x] M02.5 `research/v3/.gitignore` for bytecode; three committed `.pyc` files untracked

## M05 — Study identity and deduplication
- [ ] **M05 — Count each independent cohort exactly once**
  - Priority: P0 · Depends on: M02 · Model: GPT-6 Astra, High
  - Acceptance: identity uses `cohortKey` or a cohort fingerprint (source + input + rank + casts + numeric vector); Reddit 10u5ao8 ten Draconium batches and Bugy Serevite ore-1/ore-2 all count; zkay8v and Aqirite 701..707/823001..007 copies count once; 168 collision groups re-measured (target: 0 groups where differing numbers are dropped); estimates diff reviewed and summarized; tests pass
  - Status: Not Started · Evidence: —
  - [ ] M05.1 fingerprint + `cohortKey` support in `study_identity()`
  - [ ] M05.2 regression tests for the known independent and copy cases
  - [ ] M05.3 collision report before/after; diff summary in SESSION_LOG
  - [ ] M05.4 proposal note for the Master in `reports/M05-identity.md` (strategy.md is Master/Claude-owned; do not edit it)

## M03 — Deterministic bulk importer
- [ ] **M03 — Import every structured historical source without AI**
  - Priority: P1 · Depends on: M02 (M03.1 also feeds M06) · Model: GPT-6.1 Sol, High (M03.1), Medium (rest)
  - Acceptance: every `imported`, observation `.json`, `evidence/v2`, `leads` and structured submission file is either imported or given a reasoned skip; existing `import-*` IDs unchanged (corrections reference them); raw input quantities, cast basis, structured dates and `migratedFrom` preserved; reruns byte-identical; tests per adapter
  - Status: Not Started · Evidence: —
  - [ ] M03.0 the 10 typeless records in `evidence/midnight/2026-10-31-midnight-refining-shattering-decks.jsonl` are real observations in a different schema (e.g. genobeam's diamond comment); map them into valid records via the importer or a correction path, without editing the agent file
  - [ ] M03.1 re-import old observation JSONL with `castsBasis`, `inputsProcessed`, `dataDate`/`dataDateText` split, published vs observed dates, unmapped outputs kept as name-only rows (IDs stable)
  - [ ] M03.2 adapter: observation `.json` archives (11 files)
  - [ ] M03.3 adapter: `evidence/v2/*.json` (38) and `evidence/leads` (1)
  - [ ] M03.4 adapter: worker-submission JSON/JSONL that carry cohorts (list from manifest)
  - [ ] M03.5 GameData `gd.mill` / `gd.prospect` / `gd.tsmRetail` vs `itemdb.lua` rows: import only missing rows as `reference`
  - [ ] M03.6 ledger CSVs with numbers (`candidate-no-url`): classify; import or dispose

## M06 — Units, denominators and yield reconciliation
- [ ] **M06 — Use totals-only evidence correctly (S16) and unify cast bases**
  - Priority: P1 · Depends on: M02, M03.1, M05 · Model: GPT-6 Astra, High
  - Acceptance: one rule for `reported` vs `countedFromInputs`/`nominalEquivalent` casts applied to imported and new rows alike; the 529 totals-only rows (92 studies) either contribute or carry a reason; per-input/per-cast/per-hit/aggregate units checked; Resourcefulness treated per mechanics M9/M10/W2; tests for each basis; diff reviewed
  - Status: Not Started · Evidence: —

## M04 — Markdown and irregular sources
- [ ] **M04 — Link notes deterministically, extract the residue with batched AI**
  - Priority: P2 · Depends on: M01 (M04.1), M03 (M04.2+) · Model: GPT-6.1 Sol, Medium (linking); GPT-6.1 Sol, Medium (extraction); GPT-6 Astra, High (spot-check)
  - Acceptance: each of the ~124 Markdown candidates is linked to v3 records, extracted, or disposed with a reason; extracted rows quote their source text, pass validator + arithmetic checks, carry `migratedFrom`; 10% sample re-checked; checkpoints allow restart
  - Status: Not Started · Evidence: —
  - [ ] M04.1 `tools/link_sources.py` (URL + study ID + number matching)
  - [ ] M04.2 residual queue grouped by source URL
  - [ ] M04.3 extraction batches with schema/arithmetic validation and checkpoints
  - [ ] M04.4 spot-check sample

## M07 — Validation and exception review
- [ ] **M07 — Final dispositions and exception queue**
  - Priority: P1 · Depends on: M03, M04 · Model: GPT-6.1 Sol, Medium
  - Acceptance: `manifest/dispositions.jsonl` gives every one of the 1,244 files a final disposition; validator clean or every violation listed; contradictions and suspicious transformations queued with record IDs
  - Status: Not Started · Evidence: —

## M08 — Statistical estimator integration
- [ ] **M08 — Estimator consumes all usable evidence; every unused record has a reason**
  - Priority: P1 · Depends on: M05, M06 · Model: GPT-6.1 Sol, High
  - Acceptance: structured `unlockState` preferred over note text; ISO-only date parsing; `percentMeaning: null` guard; per-record `unusedReason` output; regression tests for observed, derived, provisional, conditional and duplicate records; decision on committing `output/`
  - Status: Not Started · Evidence: —

## M09 — Migration audit and reporting
- [ ] **M09 — Before/after metrics and unresolved-issues register**
  - Priority: P2 · Depends on: M07, M08 · Model: GPT-6 Luna, Medium
  - Acceptance: `tools/report.py` produces before/after coverage, confidence bands, disposition counts and an unresolved register from manifest + outputs; numbers reproducible
  - Status: Not Started · Evidence: —

## M10 — Final reconciliation and integration
- [ ] **M10 — Reconcile agent additions since the snapshot and open the PR**
  - Priority: P1 · Depends on: all · Model: GPT-6.1 Sol, High
  - Acceptance: branch updated with latest `implementation/five-agent-completion`; full pipeline rerun from scratch byte-identical; all tests pass; `evidence-format.md` change proposed; PR open against `implementation/five-agent-completion`
  - Status: Not Started · Evidence: —

## Planned sessions

| Session | Tasks | Notes |
| --- | --- | --- |
| MIG-001 | M00, M01, M02 | done |
| MIG-002 | M05 | next; biggest correctness gain |
| MIG-003 | M03.0, M03.1, M03.5 | |
| MIG-004 | M03.2–M03.4, M03.6 | |
| MIG-005 | M06 | |
| MIG-006 | M04.1, M04.2 | can run any time now (independent of M05) |
| MIG-007+ | M04.3 batches, M04.4 | parallel workers by source URL |
| later | M07, M08, M09, M10 | |
