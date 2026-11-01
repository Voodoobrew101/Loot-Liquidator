# Historical research migration into v3 (M00-M10)

Base: `implementation/five-agent-completion`. Head: `migration/v3-historical-research`. Do not merge until the open decisions below are read.

## What this branch does

Moves the pre-v3 research (1,244 files under `research/` outside `research/v3/`, plus `GameData.lua`, `StatYieldProfiles.lua`, `ResearchDB.lua`)
into v3 with a tested, repeatable pipeline instead of ad-hoc re-recording, and fixes the estimator defects found on the way. Every historical file has
a final disposition and a reason (`research/v3/migration/manifest/dispositions.jsonl`). The research agents' work up to `0260584` is merged in.

- **Importer** (`research/v3/tools/import_existing.py`, deterministic, idempotent): old observations with `castsBasis`, raw input counts, ISO dates,
  `migratedFrom` provenance; archives, v2 reports, leads, submissions, GameData reference tables. No AI. Holdings rule: a source v3 already holds is never imported.
- **Estimator** (`research/v3/tools/build_estimates.py`): study identity counts each independent cohort once (M05), per-unit casts and cast-basis weighting
  (M06), structured `unlockState`, ISO-only dates, `percentMeaning` guard and a reason for every unused record (M08), and the reviewer's Wowhead page rule (M10).
- **Residue**: 55 sources read by batch extraction with validated, quote-checked output (M04); 134 contradictions queued with record IDs (`exceptions.jsonl`).
- **Audit**: `research/v3/migration/tools/report.py` rebuilds every stage from git and writes `reports/M09-audit.md` (coverage, bands, dispositions, usage,
  181-row unresolved register).

## Numbers (no SciPy; compare on one machine)

| | Snapshot `575b252` | This branch |
| --- | --- | --- |
| Effective records | 4,404 | 5,632 |
| Study rows / study keys | 2,364 / 426 | 3,282 / 595 |
| Estimates | 1,238 | 1,133 |
| Unplaced records | 35 | 451 (almost all name-only rows kept on purpose) |
| Estimates with a measured chance | 101 | 103 |
| Historical URLs mentioned in v3 | 165 of 543 | 187 of 543 |
| Migration tests | 0 | 402 |

Merging the agents' branch changed 1,205 estimates to 1,133: 84 are re-keying (their rows now sit under item IDs), 12 are new, 138 changed
(`reports/M10-merge.md`, `reports/M10-estimates-diff.md`). Two rebuilds and two importer runs are byte-identical; `report.py --check` is identical.

## One conflict, resolved

`research/v3/tools/build_estimates.py`: the reviewer's `norm_source` (S7) against M05's `study_identity`. Kept M05 and ported the one rule it lacked: a Wowhead page
under a language prefix or `/ptr/` is the same page. Tontons' BfA table counts once (253 / 322 / 555 casts), matching the reviewer's numbers.

## Not in this PR

- `research/v3/output/` is not regenerated here (the merge carries the reviewer's files). One confidence method (require SciPy, or drop the fallback) should be
  chosen before anyone commits it; `unused.json` is git-ignored.
- `evidence-format.md` is untouched; the proposal is `reports/M10-evidence-format-proposal.md`.
- `corrections.jsonl`, `strategy.md`, agent evidence files and all addon `.lua` files are untouched by the migration work.

## Decisions for the owner (full register: `reports/M09-audit.md` section 5)

1. `unlockState` in `evidence-format.md`: omit unless stated (recommended) or make `null` mean absent in the code. **Blocks that part of the format change only.**
2. METHODS wording for three `rateChange` records, and approve or decline the five validator fixes (three `method: null`, two `exclude`).
3. S19: Serevite rank IDs may be swapped across the database; nothing was changed.
4. M06: the 0.5 equivalent-cast weight and the two backfills (832 agent rows).
5. The exception queue (134 rows), name-only placement, and the 12 sources the extraction refused as ambiguous.
6. S18 record IDs and the S17 worker line.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
