# Historical research migration into v3: plan

Owner: Voodoobrew101. Started 2026-10-31 (session MIG-001).
Branch: `migration/v3-historical-research`, cut from `implementation/five-agent-completion` at
`575b2529d02820ca4ad77851624dc7ecd7f8d740` (the **migration snapshot**). The hourly research agents keep
writing to `implementation/five-agent-completion`; anything they add after the snapshot is reconciled in M10.

Companion files: `CHECKLIST.md` (task list, the source of truth for status), `SESSION_LOG.md`
(append-only), `HANDOFF.md` (how to resume), `manifest/` (generated inventory and source registry).

---

## 1. Measured baseline (snapshot 575b252)

All numbers below were measured in session MIG-001 by running code, not copied from older notes.

### v3 today

| Metric | Value | How measured |
| --- | --- | --- |
| v3 evidence files / records | 132 files, 4,404 records after corrections and `replaces` | `build_estimates.load()` |
| Record types | drop 3,556 · exchange 307 · token 244 · recipe 123 · noDisenchant 124 · condition 17 · rateChange 16 · searched 7 · **no type 10** | same |
| Drop rows: studies vs reference values | 2,364 study rows in 426 study keys · 1,192 reference rows (TSM table, compiled research, GameData) | `sourceKind` |
| Estimates | 1,238 (35 records unplaced) | `build_estimates.py` (deterministic: two runs byte-identical) |
| Study audit | 426 studies, 140 with no findings | `audit_studies.py` |
| Corrections | 643 lines | `corrections.jsonl` |
| Committed `output/` | **stale**: says 3,993 records / 1,221 estimates | committed `summary.md` vs rebuild |
| v3 automated tests | **none** | repo search |
| Old JS test suite (`research/tests/*.js`) | 12 pass, 8 fail (pre-v3 pipeline; not maintained) | `node` each file |

### Historical material outside v3

`tools/inventory.py` scanned every file under `research/` except `research/v3/`, plus `GameData.lua`,
`StatYieldProfiles.lua` and `ResearchDB.lua`: **1,244 files, 18.5 MB, 0 unparseable JSON**.
Distinct source URLs cited: **543**, of which **165** are already cited by v3 evidence and **378 are not**.
(URL coverage is a proxy: a Wowhead item page can host several independent comment studies.)

Preliminary dispositions (`manifest/inventory-summary.md` has the per-category table):

| Disposition | Files | Meaning |
| --- | --- | --- |
| imported | 42 | consumed by `import_existing.py` |
| reference-imported-partial | 2 | `GameData.lua` (only disenchant/smelt/tokens imported), `proposed/itemdb.lua` |
| candidate-unmigrated | 165 | holds observational numbers and cites ≥1 URL not in v3 (124 Markdown, 27 JSON, 8 JSONL, 5 CSV) |
| candidate-no-url | 35 | holds numbers but cites no URL (mostly ledger CSVs and TSM assignment files) |
| covered-by-url | 65 | holds numbers; every URL it cites is already in v3 (needs cohort-level confirmation) |
| source-links-only | 220 | cites uncited URLs but holds no numbers (source reviews, reports) |
| no-observational-content | 441 | no numbers, no new URLs |
| process-artifact | 248 | tests, tools, prompts, QA feedback, confidence snapshots, v2 coordination |
| derived-model | 22 | `research/models/v2` statistical model outputs (derived, not observations) |
| mechanics-knowledge | 4 | `research/mechanics/` registries (feed `mechanics.md`, not estimates) |

### What the importer did and did not do

`import_existing.py` is idempotent (rerun → no diff). It converted 42 of 56 `evidence/observations/*.jsonl`
files into 652 rows / 148 study keys (skipping 22 model/TSM rows, 14 duplicates and 28 records whose
outputs had no item ID), plus 1,018 ItemDB reference rows and GameData disenchant (52), smelting (8) and
token (1) records. It never read: the 11 `.json` and 58 `.md` observation files, `evidence/v2/`,
`evidence/leads/`, worker submissions, reviews, ledgers, or GameData's `gd.mill`, `gd.prospect` and
`gd.tsmRetail` tables (the last may be covered by `itemdb.lua`; unverified).

---

## 2. Critical reassessment

### Answers to the ten assessment questions

1. **Correctly migrated.** The 42 imported observation files, the ItemDB reference rows (kept out of study
   counts via `sourceKind`), and GameData disenchant/smelt/token rows. Hourly agents have additionally
   re-recorded many historical studies directly (e.g. the `legacy` agent's original Titanium/Saronite cohorts).
2. **Never migrated.** Everything in the "candidate" rows above: 200 files with numbers, 378 uncited URLs.
   Biggest blocks: 124 Markdown reconciliation notes, 27 v2/observation JSON archives, worker submission
   reports, GameData mill/prospect tables.
3. **Import mistakes / altered interpretations.**
   - **Nominal casts treated as completed casts.** 291 imported study rows got `casts` from
     `fiveOreEquivalentOperations` (258) or `inputs / batch` (33). New agents record the same situation
     with `casts: null` ("10,000 ore, not casts"), so identical evidence is treated two different ways:
     counted at full weight when imported, ignored when freshly recorded. The derivation is only in free-text `notes`.
   - **Free-text dates.** 487 imported rows have prose in `dataDate` (old `hotfixWindow`), so the epoch
     logic sees them as undated and down-weights them to 25% wherever a rate change applies.
   - **Observation date stored as `source.published`** (78 rows); semantically different fields.
   - **Raw quantities lost to notes.** Ore purchased/consumed/refunded, unmapped outputs and
     `unmappedReportedOutputs` are not carried as fields.
4. **Stored but unused by the estimator.**
   - 529 totals-only drop rows in 92 studies (S16; was 451/71 when S16 was opened).
   - 41 study drop rows with no numbers; 35 unplaced rows; 59 unlock-unstated rows skipped for
     conditional outputs (correct by S6).
   - 10 records with no `type` in `evidence/midnight/2026-10-31-midnight-refining-shattering-decks.jsonl`,
     silently ignored (no schema validation exists).
5. **Measurement vs reference.** `sourceKind` separates them correctly for ItemDB/TSM rows. Two soft spots:
   GameData `personal-pooled` disenchant rows rebuild totals as `chance × samples` and count as study casts;
   `compiled-research` rows include old "proxy, modeled" values (S14) used as priors.
6. **Deduplication — the largest defect found.** `study_identity()` is `(originalSource or url or studyKey,
   inputRank, casts, …)`. Independent cohorts from one URL with equal cast counts collapse into one: in
   **168 estimate groups** distinct study keys share an identity and only the first counts. In **90** of
   them the numbers differ (independent cohorts, e.g. ten 2,000-cast Draconium R2 batches from Reddit
   10u5ao8, Bugy's two 400-cast Serevite cohorts), dropping roughly 288k material-level casts. In the other
   **78** the numbers are identical (true copies, correctly merged). Meanwhile copies with null ranked IDs
   still slip through (S17). S7 called for a batch identity; it was never implemented.
7. **Schema sufficiency.** Close, but missing: an explicit cast basis (`castsBasis`), the inputs the source
   counted (`inputsProcessed`, S16), a cohort identity (`cohortKey`), raw-vs-derived separation for
   quantities, and validation. `CORRECTABLE` cannot set new fields. All can be added as optional fields
   without breaking readers.
8. **Deterministic vs AI vs hybrid.** Hybrid, decided per source category (table in §3). About 80% of
   files need no AI at all (process artifacts, models, files with no numbers, URL/ID-linked files).
9. **Consolidation.** Yes: one historical importer with per-format adapters replaces ad-hoc agent
   re-recording; one registry (`manifest/url-registry.jsonl`) replaces repeated source hunting; the study
   audit becomes the exception queue. Hourly agents should stop re-recording historical studies (S17).
10. **Fastest safe path.** Tests first (v3 has none), then fix study identity and cast basis in the
    estimator behind regression tests, then bulk-import structured sources, then AI only for the residual
    Markdown that links to uncited sources.

### Other design flaws noted

- Committed `output/` is stale relative to evidence; outputs should be rebuilt in the same commit as data
  changes or not committed at all (decide in M08).
- `research/v3/tools/__pycache__/*.pyc` is committed and changes on every run; should be git-ignored.
- `unlock_state()` reads free text in `notes`, so any note mentioning "max knowledge" flips a study to
  unlocked. Fragile; a structured `unlockState` field is safer (M02 schema).
- `chance_from_percent()` accepts `percentMeaning: null` as per-cast (currently 0 affected rows; guard it).
- S14 (milling 4.5 guess), S15, S16, S17 are open with no Master reply since Oct 30; this plan implements
  the engineering parts of S16 and S17 and leaves queue decisions to the Master.

---

## 3. Revised strategy

**Principle:** a small, tested, repeatable pipeline; AI only where text must be read.

| Source category | Files | Method |
| --- | --- | --- |
| process-artifact, derived-model, no-observational-content | 711 | Bulk disposition by rule; no reading. |
| imported (old observations JSONL) | 42 | Re-import with corrected cast basis, structured dates and raw-quantity fields (deterministic). |
| observation `.json`, `evidence/v2`, `leads`, structured submission JSON/JSONL | ~50 | Deterministic adapters per schema family (the old schemas are few and consistent). |
| GameData `gd.mill`/`gd.prospect`/`gd.tsmRetail`, ledger CSVs | ~10 | Deterministic: diff against existing reference rows; import only rows not already present, as `reference`. |
| covered-by-url | 65 | Deterministic cohort check (numbers equal → link; differ → exception). |
| Markdown / report notes with uncited URLs and numbers | ~124 | Deterministic link pass first (URL + study ID + numbers); **AI extraction only for the residue**, batched by source URL, one study per prompt, output validated by schema + arithmetic checks. |
| source-links-only | 220 | Add uncited URLs to the registry as leads; no record unless numbers exist. |
| mechanics-knowledge | 4 | Diff against `mechanics.md`; propose additions via flags (Master owns `mechanics.md`). |

### Architecture

```
research/v3/migration/
  tools/inventory.py        M01  file inventory + URL registry (done)
  tools/validate.py         M02  schema validator for all v3 evidence
  tools/import_historical.py M03 adapters: old-observation JSON(L), v2 JSON, leads, submissions, GameData tables
  tools/link_sources.py     M04  deterministic URL/ID/number linking of notes to v3 records
  tools/extract_batch.py    M04  batch prompts + validators for residual Markdown (AI)
  tools/report.py           M09  before/after metrics, dispositions, unresolved register
  tests/                    unit + regression tests (python -m unittest)
  manifest/                 generated: inventory, url registry, dispositions, checkpoints
research/v3/evidence/imported/   written only by importers (existing rule)
research/v3/tools/build_estimates.py  changed only in M05/M06/M08, behind tests
```

Every tool is idempotent, writes sorted output, records input file hashes in `manifest/` and can be
rerun from scratch. AI batches checkpoint per source URL (`manifest/extraction/<key>.json`) so a stopped
run resumes without repeating work.

### Schema extension (M02, all optional, readers unaffected)

- `castsBasis`: `reported` | `countedFromInputs` | `nominalEquivalent` | `derived` | `null`
- `inputsProcessed`, `inputsPurchased`, `inputsRefunded`: raw input counts as the source states them
- `cohortKey`: identity of one independent measurement (author + source + batch/cohort label)
- `unlockState`: `true` | `false` | `null` (structured replacement for free-text detection)
- `derivations`: list of `{field, formula, assumption}` for any computed value
- `migratedFrom`: `{path, sha256, recordRef}` provenance for migrated rows
- Extend `CORRECTABLE` with the new fields.

### Statistical rules carried forward (unchanged unless stated)

S5–S13 stand. Changes this plan introduces, each behind tests:
1. **Identity (M05):** count once per `cohortKey`; when absent, derive a cohort fingerprint from
   (normalized source, input, rank, casts, and the study's numeric vector). Same fingerprint = copy;
   same source but different numbers = independent cohort.
2. **Denominators (M06, S16):** casts with `castsBasis` `countedFromInputs` or `nominalEquivalent` count
   toward the **average** (quantity per cast is bounded and Resourcefulness only blurs it) but enter the
   **chance** confidence at a reduced, documented weight; reported casts count fully. Same rule for
   imported and new records, so the inconsistency in §2.3 disappears.
3. Dates: structured `dataDate` only; free text moves to `notes`/`dataDateText`.

### Risks and safeguards

| Risk | Safeguard |
| --- | --- |
| Estimator change silently shifts thousands of estimates | Golden before/after diff report per change; every behavioural change has a fixture test; owner-visible summary in SESSION_LOG |
| AI extraction invents numbers | Extract only numbers present in quoted text; arithmetic cross-checks; null on doubt; sample 10% for manual review |
| Hourly agents change evidence during migration | Fixed snapshot; M10 re-runs the pipeline on the new head and reconciles |
| Double counting copies | M05 fingerprint + regression tests on known copy pairs (zkay8v, Aqirite 701..707) |
| Merging independent cohorts | M05 tests on Reddit 10u5ao8 batches and Bugy cohorts |
| Breaking agent rules | Never edit agent evidence files; fixes go through `corrections.jsonl` or new importer output |

### Validation approach

Schema validator over all evidence; unit tests for each adapter and estimator rule; golden regression
(estimates diff) reviewed per behavioural change; reproducibility check (clean rerun → byte-identical);
random spot-checks against sources for AI-extracted rows.

### Definition of project completion

As in the master prompt §10: every historical file has a final disposition in
`manifest/dispositions.jsonl`; every recoverable observation is migrated or linked to a v3 record; no
fabricated values; copies counted once; profession conditions preserved; the estimator consumes all usable
evidence and every unused record has a machine-readable reason; tests pass; before/after reports exist; the
pipeline reruns byte-identically; changes are committed and a PR is open for review.
