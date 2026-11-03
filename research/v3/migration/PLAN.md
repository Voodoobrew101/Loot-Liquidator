# Historical research migration into v3: plan

Owner: Voodoobrew101. Started 2026-10-31 (session MIG-001).
Branch: `migration/v3-historical-research`, cut from `implementation/five-agent-completion` at
`575b2529d02820ca4ad77851624dc7ecd7f8d740` (the **migration snapshot**). The hourly research agents keep
writing to `implementation/five-agent-completion`; anything they add after the snapshot is reconciled in M10. Historical (non-v3) content last changed at
`a023181` (2026-10-30 18:15 PDT); `manifest/snapshot.json` records that commit.

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
   - 10 records with no `type` (real observations written in a different field layout, e.g. `sourceURL`) in `evidence/midnight/2026-10-31-midnight-refining-shattering-decks.jsonl`,
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
   *Corrected by M05 (MIG-002):* the 168 / 90 / 78 script was not committed and could not be reproduced;
   `tools/identity_report.py` measures **160 / 77 / 83** (236,076 material-level casts). Only 29,056 of those
   were independent cohorts; the rest were copies with fields filled differently. See `reports/M05-identity.md`.
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
  changes or not committed at all. *(M08: recommendation is never commit it from migration or agent branches; the reviewer
  regenerates it, after one confidence method is pinned. `reports/M08-estimator.md` section 7.)*
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
  tools/validate.py         M02  schema validator for all v3 evidence (done)
  tools/estimates_diff.py   M02  before/after estimates comparison (done)
  tools/identity_report.py  M05  which studies merge, before/after, and what needs review (done)
  tools/import_historical.py M03 adapters: old-observation JSON(L), v2 JSON, leads, submissions, GameData tables
  tools/link_sources.py     M04  deterministic URL/ID/number linking of notes to v3 records
  tools/extract_batch.py    M04  batch prompts, validator, checkpoints and writer for residual Markdown (done)
  tools/dispositions.py     M07  final dispositions, exception queue, scope gap (done)
  tools/report.py           M09  before/after metrics, dispositions, unresolved register (done)
  tests/                    unit + regression tests (python -m unittest)
  manifest/                 generated: inventory, url registry, validation, dispositions, checkpoints
  reports/                  per-task before/after diffs and notes for the Master
research/v3/evidence/imported/   written only by importers (existing rule)
research/v3/tools/build_estimates.py  changed only in M05/M06/M08, behind tests
```

Every tool is idempotent, writes sorted output, records input file hashes in `manifest/` and can be
rerun from scratch. AI batches checkpoint per source URL (`manifest/extraction/<key>.json`) so a stopped
run resumes without repeating work.

### Schema extension (M02, all optional, readers unaffected; full text in `SCHEMA-EXTENSION.md`)

- `castsBasis`: `reported` | `countedFromInputs` | `nominalEquivalent` | `derived` | `null`
- `inputsProcessed`, `inputsPurchased`, `inputsRefunded`: raw input counts as the source states them
- `cohortKey`: identity of one independent measurement (author + source + batch/cohort label)
- `unlockState`: `true` | `false` | `null` (structured replacement for free-text detection)
- `derivations`: list of `{field, formula, assumption}` for any computed value
- `migratedFrom`: `{path, sha256, recordRef}` provenance for migrated rows
- Extend `CORRECTABLE` with the new fields.

### Statistical rules carried forward (unchanged unless stated)

S5–S13 stand. Changes this plan introduces, each behind tests:
1. **Identity (M05, done):** count once per `cohortKey`; when absent, derive a cohort fingerprint from
   (normalized source, rank, casts, and the numeric vector of the whole study). Same fingerprint = copy;
   same source but different numbers = independent cohort. Refinements forced by the data, all tested
   (`reports/M05-identity.md`): outputs compare by name first; partial copies count once when rows agree
   wherever both state a number (2+ non-zero rows; under half the original's size, labels must match too);
   numbered batches in one file never merge, even with equal numbers; a study that is the exact sum of a
   batch family is left out; copy rows in a vaguer `family:` group are left out.
2. **Denominators (M06, S16):** casts with `castsBasis` `countedFromInputs` or `nominalEquivalent` count
   toward the **average** (quantity per cast is bounded and Resourcefulness only blurs it) but enter the
   **chance** confidence at a reduced, documented weight; reported casts count fully. Same rule for
   imported and new records, so the inconsistency in §2.3 disappears.
   *Implemented in M06 (MIG-005), `reports/M06-units.md`:* weight `EQUIVALENT_CAST_WEIGHT` = 0.5 in the chance (its
   estimate and confidence), full in the average, for bases countedFromInputs / nominalEquivalent / derived, casts
   counted from `inputsProcessed` ÷ unit, and casts converted from another batch size. Every estimate is per cast of its
   group's unit (`inputsPerCast` in the output: prospecting 5 by G1, otherwise the smallest stated batch); other batch
   sizes convert per input for averages, and their per-cast chances are left out (not convertible). Refunds never change
   a count; inputs written only in notes are not read. Agents' counted casts without `castsBasis` read as reported, so the
   remaining inconsistency is in the data (398 agent rows listed for backfill), not in the code.
3. Dates: structured `dataDate` only; free text moves to `notes`/`dataDateText`. *(Done for imported rows in M03.1: free text
   in `dataDateText`, the old observation date in `observedOn`, which the estimator reads after `dataDate`.)*
4. **Name-only outputs (M03.1, new):** an output without an item ID is always stored (`rawOutputName`), but placed
   by name only when it names one material and no v3 agent record already holds that cohort (same source URL, or
   same input, casts, output name and total). Categories, aggregates, unnamed indexes and agent-held cohorts stay
   unplaced with the reason in `notes`, for M04.1 linking. A first pass without the agent check counted the Kyparite
   Sparkling Shard cohorts twice (`reports/M03-import.md`).
5. **Historical claims (M03.2-M03.4, new):** in archives, v2 reports, leads and submissions, every object citing a
   source URL is a claim. A claim whose source v3 already holds (agent evidence, or rows the importer wrote earlier in
   the same run; matched by normalized key or thread) is never imported, only compared and listed. A new source is
   imported only through a mapper listed in `NEW_SOURCES`, and only while v3 does not hold it, so an M10 rerun cannot
   double count once agents record it. Reference tables are the exception: they check presence row by row (M03.5's
   rule). Totals whose source counts inputs, not casts, keep `casts: null` (S16, M06), even when an old record
   carries its own normalization (`reports/M03b-import.md`).

6. **Linking notes to v3 (M04.1-M04.2, new):** a Markdown, CSV or irregular note is linked to v3 by source (normalized key,
   same thread counts), then by a *result* number next to the citation (total, hit count, percent, average, min/max). A
   matching batch size (casts, inputs processed) alone is not a link. Same source with other observational numbers is an
   exception (listed, never imported); a source v3 does not hold, with observational counts next to the citation or
   elsewhere in the file (at most three such sources per file), is residue, grouped by source URL for AI extraction. A URL
   only mentioned in v3 notes is not held. Reference hosts, entity pages without counts and M03 `NEW_SOURCES` skips are
   disposed with their reason. The linker reads effective rows (corrections applied) for matching and raw agent rows for
   name-only candidates, so a row excluded as a duplicate still links. `reports/M04-links.md` has the counts.
   *Amended in M04.3 (MIG-007):* a source held only by `recipe` records is `source-held`, never an exception: a recipe fact has no
   cohort to compare the citation's other counts with (7 files had turned from residue to exception when recipe rows landed). The
   observational-count pattern needs a unit word after the number, so a citation such as "3000 Nightshade ... 781 Umbral" reads
   as `lead-only`; M01's `source-links-only` notes can therefore hide cohorts the queue never saw (`reports/M04-extraction.md`).
7. **Extraction of the residue (M04.3, new):** a queue source is read in a prompt that shows its files as numbered lines, answered
   in a fixed JSON shape, and accepted only if `tools/extract_batch.py` validates it: every evidence span is a verbatim substring of
   the named line (under the source's own URL, or tied by a quoted line); every number is in the evidence or computed by a
   formula the validator evaluates; hits, percents, averages, histograms, batch sizes and rank sums agree; the finished record
   passes `validate.check_record` with no finding; names move to `rawInputName` / `rawOutputName` unless the ID is in the text, so
   nothing is placed by name and no ID is guessed; `condition` and `rateChange` readings stay proposals. Each source gets a
   checkpoint (`manifest/extraction/*.json`) with rows or a null with a reason code. Checkpoints carry their queue entry and the
   writer reads checkpoints, so rows survive `link_sources.py` dropping the source from the queue. A source v3 holds is never
   written (rule 5), and a translated copy of a Wowhead page counts as the same page. The tool reads the queue's files plus the
   sibling notes listed in `EXTRA_FILES`.

8. **Final dispositions (M07, new):** every inventory file ends in one of 12 dispositions (`tools/dispositions.py`, reasons in
   `manifest/dispositions.jsonl`): `imported`, `extracted`, `linked`, `extracted-null`, `exception-queued`, `reference-only`,
   `held-sources-only`, `source-links-only`, `process-artifact`, `derived-model`, `mechanics-knowledge`,
   `no-observational-content`. Precedence: an open exception first, then rows written (importer, extractor), then a null
   extraction, then the linker's outcome, then the inventory's own class. `held-sources-only` is a statement about *sources*
   (page or thread level, rule 5): the file has no observational numbers of its own. A contradiction or a suspicious transformation
   goes to `manifest/exceptions.jsonl` with record IDs; fixes are proposed as correction lines, never applied by a tool. A new
   unheld source with a count of 20 or more beside the citation, in any file, fails `test_scope_gap_is_fully_decided` until it has a
   checkpoint or a reasoned decision (`reports/M07-dispositions.md`).

9. **Estimator guards and unused reasons (M08, new):** `unlock_state()` reads the structured `unlockState` first (true, false, or
   an explicit null = not stated) and falls back to note text only when the field is absent; `dataDate`, `observedOn` and
   `source.published` are read only as ISO dates (month-only dates are placed only when the month lies wholly on one side of a rate
   change); `percentMeaning` must be `perCast` for a percentage to be a chance. Every effective record is either used (adds casts,
   hits, a total, an average or a prior) or carries one reason code in `output/unused.json` (closed vocabulary `REASON_CODES`). None
   of the three guards changes an estimate on today's evidence (`reports/M08-estimator.md`).

10. **Same Wowhead page (M10, new):** in the estimator's identity key (`source_key`), a Wowhead page under a language prefix or `/ptr/` is one page
   (`SAME_PAGE_SUFFIXES`), so a study recorded under `/ru/`, `/ptr/` and plain counts once. Game flavours (`@cata`, `@wotlk`, `@tbc`, `@mop-classic`) are
   other pages. This is the reviewer's S7 rule (commit `40d9f76`) carried into M05's fingerprint; `normalize_url`, the URL registry, the linker and the
   importer's holdings keep their own rules (language suffixes are stripped there only by `extract_batch.strip_lang`) (`reports/M10-merge.md`).

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
