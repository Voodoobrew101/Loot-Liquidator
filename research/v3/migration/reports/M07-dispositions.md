# M07: final dispositions and the exception queue (MIG-008)

Tool: `tools/dispositions.py` (tests: `tests/test_dispositions.py`, 37). Outputs, all deterministic and byte-identical on a rerun:
`manifest/dispositions.jsonl` (1,244 rows), `manifest/exceptions.jsonl` (134 rows), `manifest/scope-gap.jsonl` (47 sources),
`manifest/dispositions-summary.json`. No network, no AI extraction, no evidence written.

## Result: all 1,244 files have a final disposition and a reason

| Disposition | Files | What it says |
| --- | --- | --- |
| no-observational-content | 432 | no numbers and no URL v3 lacks |
| process-artifact | 313 | tests, tools, prompts, QA, coordination (248); field audits by name (33); audit, coverage, score or report tables that cite nothing (32) |
| held-sources-only | 129 | no observational numbers of its own; every source it cites is held by v3 or is reference (the agents' own reviews) |
| linked | 131 | cited cohorts match v3 rows (87) or the cited sources are held (44) |
| exception-queued | 65 | a held source's numbers differ from v3's rows (one or more of the 83 citation groups); listed in `exceptions.jsonl` |
| imported | 55 | the importer wrote rows from the file (53), or reference tables from it (2: `GameData.lua`, `proposed/itemdb.lua`) |
| extracted-null | 47 | a source cited here was read in M04.3 and holds no usable cohort; the reason names source and code |
| reference-only | 32 | cites only reference hosts or sources M03 decided to skip |
| derived-model | 22 | `research/models/v2` outputs |
| source-links-only | 10 | cites sources v3 does not hold, with no count beside them: leads in `url-registry.jsonl` |
| extracted | 4 | `extract_batch.py` wrote rows from a source in the file |
| mechanics-knowledge | 4 | `research/mechanics/` registries |
| **Total** | **1,244** | |

No file keeps `preliminary`, `candidate-*`, `covered-by-url` or `reference-imported-partial` (a test scans the committed file for
them). `covered-by-url` became `held-sources-only` where it applies, because "the URL is held" is not a statement about numbers.

### From the inventory's preliminary names to the final ones

| Preliminary (M01) | Files | Final |
| --- | --- | --- |
| imported | 42 | imported 42 |
| reference-imported-partial | 2 | imported 2 |
| candidate-unmigrated | 165 | linked 89, exception-queued 44, extracted-null 21, reference-only 5, imported 4, extracted 2 |
| candidate-no-url | 35 | process-artifact 31, linked 2, reference-only 2 |
| covered-by-url | 65 | linked 40, exception-queued 21, imported 2, extracted 1, process-artifact 1 |
| source-links-only | 220 | held-sources-only 121, process-artifact 33, extracted-null 26, reference-only 25, source-links-only 10, imported 4, extracted 1 |
| no-observational-content | 441 | no-observational-content 432, held-sources-only 8, imported 1 |
| process-artifact | 248 | process-artifact 248 |
| derived-model | 22 | derived-model 22 |
| mechanics-knowledge | 4 | mechanics-knowledge 4 |

### Rules, in order (first match wins; `dispositions.py` docstring has the same list)

1. **exception-queued**: a citation group of a held source whose numbers differ (links.jsonl `exception`), or the s6bfrl ledger.
   A file that also has imported or extracted rows keeps this disposition; its reason says how many rows were written and its
   pointers name them (3 files). Files that also cite a null-extracted source name it (21 files).
2. **imported** / 3. **extracted**: rows whose `migratedFrom.path` is this file (evidence/imported/*.jsonl), by writer.
4. **extracted-null**: a residue source with a null checkpoint. The reason lists `source (code)` for every such source.
5. **linked** / disposed by the linker: a disposed file with no citation is a `process-artifact`; one with only reference or
   decided-skip citations is `reference-only`.
6. Files the linker never read: inventory `process-artifact`, `derived-model`, `mechanics-knowledge`; importer reasons
   ("process artifact: field audit…", M03b) and field audits by name; then the citations decide (`source-links-only` if a cited
   source is an unheld lead, `extracted-null` if it is a checkpointed null, `held-sources-only` if all are held, else `reference-only`).

Reason codes in use: `NO_OBSERVATIONAL_CONTENT` 432, `PROCESS_ARTIFACT` 248, `ALL_CITED_SOURCES_HELD` 129, `LINKED_NUMBERS_MATCH` 87,
`HELD_SOURCE_NUMBERS_DIFFER` 65, `IMPORTED_ROWS` 53, `EXTRACTED_NULL` 47, `LINKED_SOURCES_HELD` 44, `FIELD_AUDIT_BY_NAME` 33,
`ONLY_REFERENCE_OR_DECIDED_SKIPS` 32, `NO_SOURCE_AUDIT_OR_REPORT` 32, `DERIVED_MODEL` 22, `SOURCE_LINKS_ONLY` 10, `EXTRACTED_ROWS` 4,
`MECHANICS_KNOWLEDGE` 4, `IMPORTED_REFERENCE_PARTIAL` 2.

## The 46 null extraction sources

The linker still calls their 42 files `residue` (unchanged, by design). Final: **21 `extracted-null`** and **21 `exception-queued`**
(these also cite a held source whose numbers differ; their reason names the null sources too). All 46 null sources appear in some
disposition reason with their code (test `test_all_46_null_sources_are_named_with_their_code_somewhere`). Beyond the 42 files,
**26 more files** that the linker never read cite a null source and are `extracted-null` too (source-review JSONL, audit CSVs,
`source-memory.json` notes: the "114 file mentions outside the queue entries" of M04).

## Scope gap (M04.3 finding 1)

Measured by scanning every inventory file for an unheld source with a number of 20 or more beside the citation, with the CSV
row cut from the URL:

| | Count |
| --- | --- |
| Raw keys in out-of-scope files (the M04.3 figure) | **23** (reproduced exactly) |
| After cutting the CSV row from the key (`...table-inscription,55,12,0`) | **16** distinct sources |
| Already queue sources with a checkpoint | 9 (`r80lkp`, `k1zd4o`, `10k8158`, `1s3hnzo`, `1szcgff`, `1ub8pxv`, wowace `millingdata.lua`, Cataclysm and MoP tables) |
| Not queue sources, decided here | **7** |
| In-scope citations that read as `lead-only` yet carry a count | 18 sources, **all** with a checkpoint |

The 7 decisions (`manifest/scope-gap.jsonl`, none needs an extraction checkpoint):
`blizzforum:1499506` patch-thread date support (the numbers belong to cohorts whose sources v3 holds); `blizzforum:2277117` and
`reddit:1s1dtuh` qualitative, no denominator (the 21 and 23 beside them are dates); the 1smgllg workbook `gdoc:1jBMg…` a derivative
calculator (15,356 is its byte size); `wowdayday…1230462` and `wowwiki-archive…breastplate…` item IDs only; and
`wow-professions.com/…khaz-algar-inscription-leveling-guide`, a published table whose values are not in the repository text.
The polluted raw keys fold into the 16 clean ones; for four of them (`milling-table-inscription`, `midnight/jewelcrafting-guide`, the
WotLK table and `tbc/prospecting`) the clean URL is a source v3 already holds, so they drop out once the row is cut off. The cohorts
beside `blizzforum:1499506` are `reddit:10bngi7`, `wowhead:item=194545` and `wowhead:item=192869`, all held (checked).

**Decision on the linker pattern: not widened.** The linker only reads files the inventory marks as candidates, and the 18 in-scope
`lead-only` citations with counts are all already read. Widening the unit-word pattern would change the classification of in-scope
files without finding a new source, so there was nothing for a pinning test to pin. The scan itself is now a tested part of
`dispositions.py` (`scope_gap()`), and a new unheld source with counts fails `test_scope_gap_is_fully_decided` until someone
decides it (add a checkpoint through `EXTRA_FILES`, or an entry in `SCOPE_GAP_DECISIONS`).

## v2 source reviews and audit CSVs

- **37 `v2/source-reviews` files** (no study objects): held-sources-only 28, reference-only 5, source-links-only 2, linked 1, no-observational-content 1.
  Only two cite an unheld lead (`reddit:1s1dtuh`, `blizzforum:1499506`, both decided above). None is queued: every cohort number in them
  belongs to a source v3 holds. The reason of each says so.
- **Audit CSVs.** The handoff's "21 submission audit CSVs" cannot be reproduced by name; there are **42** CSVs with "audit" in the
  path, all disposed: process-artifact 19, no-observational-content 15, exception-queued 5, linked 3. The 5 exception-queued ones are
  queued because a held source's numbers differ (not because they are audits). Across all formats, 109 worker-submission files carry
  "audit" in the name: process-artifact 43, no-observational-content 48, exception-queued 10, linked 8.

## Exception queue (`manifest/exceptions.jsonl`, 134 rows, 1,070 distinct record IDs named)

| Kind | Rows | Record IDs | What a person decides |
| --- | --- | --- | --- |
| held-source-numbers-differ | 83 | every record the held source has | the 83 citation groups in 65 files: other cohort, or a restated ratio |
| imported-vs-agent-totals-differ | 6 | import row + 3 agent rows each | the six Jallfo Crumbled Stone / Fractured Glass cohorts (1,000 casts each) |
| unverified-output-count | 1 | the 25 held s6bfrl records + 6 ledger lines | s6bfrl uncommon gems (Bloodstone 53, Sun Crystal 44, Chalcedony 49, Shadow Crystal 53, Huge Citrine 47, Dark Jade 59 per 1,000 ore) |
| unplaced-name-only-cohort | 1 | 22 | zkay8v 10,000-ore rows: place by name, or an agent records them |
| placement-proposal | 1 | 14 | 1smgllg rates: 11 with unambiguous output IDs, 3 aggregate labels |
| total-differs-from-source | 1 | `import-study-00967`, `-01041` | Felslate 2016: ten batch totals add up to 101, both copies say 97 |
| ambiguous-doubt-source | 12 | none (nothing was written; the checkpoint is the ref) | store as `reference` with `unclear`, or leave null |
| validator-error | 5 | one each | below |
| cross-source-identity-pair | 9 | studies of each pair | M05: set `originalSource` on the copy, or leave |
| identity-merge-with-conflict | 3 | studies of each merge | M05: R3 Serevite labels (Reddit zh53dd, 108782r) |
| single-row-subset | 12 | the subset and its parent | M05: exclude the single row if it restates the study |

Every row has a stable `EX-<KIND>-<hash>` ID; every file with an exception carries the IDs in its disposition (78 files).

### The validator's 5 errors, each with a fix path (proposed; `corrections.jsonl` is not touched)

| Record | Code | File | Fix path |
| --- | --- | --- | --- |
| `dragonflight-20261030-041` | METHOD_UNKNOWN (`Prospect and Mill`) | `evidence/dragonflight/2026-10-30T1910-inspiration-transition.jsonl:1` | A `rateChange` carries no estimator method. Correction `{"field":"method","value":null}` (the method stays in notes), or an agent flag asking for a correcting record |
| `dragonflight-20261031-7010` | METHOD_UNKNOWN (`Dye Crafting`) | `evidence/dragonflight/2026-10-31T0533-dragonflight-herbs-housing-dye-exchanges.jsonl:10` | same |
| `war-within-20261031-18028` | METHOD_UNKNOWN (`Dye Crafting`) | `evidence/war-within/2026-10-31T1819-housing-dye-tww-herbs-12-1.jsonl:28` | same; or the owner adds `Dye Crafting` to `METHODS` in `evidence-format.md` (proposal below) |
| `import-ref-00697` | METHOD_MISSING | `evidence/imported/itemdb-reference-values.jsonl:697` | quarantined ItemDB row, all four fields unknown: correction `{"field":"exclude","value":true}` (precedent `import-ref-01009`). A method is never guessed |
| `import-ref-00698` | METHOD_MISSING | `evidence/imported/itemdb-reference-values.jsonl:698` | same |

The exact correction line for each is in the row's `proposedCorrection`. Applying all five takes the validator to 0 errors. Checked
in-process (rows edited in memory, nothing written): `build_estimates.build()` returns the same 1,205 estimates; the two excluded ItemDB
rows leave the unplaced list (449 -> 447); the three `method: null` rateChange records change nothing.

## Counts before and after

| | Before (start of MIG-008) | After |
| --- | --- | --- |
| Files with a final disposition | 0 (1,244 preliminary) | **1,244** |
| Dispositions in use | 10 preliminary names | 12 final, closed |
| Linker file outcomes (265 in scope) | linked 140, exception 44, residue 42, disposed 39 | unchanged (the linker was not touched) |
| Effective records | 4,945 | 4,945 |
| Estimates | 1,205 (449 unplaced) | 1,205 (449 unplaced) |
| Tests | 267 | **304** (37 new) |
| Validator | 5 errors, 175 warnings | 5 errors, 175 warnings (each queued) |
| Corrections | 643 lines, 333 corrected records | 643 lines, 333 corrected records |

### Estimate check

SciPy 1.18.1 installed, same code path as MIG-003 to MIG-007. `estimates.json` sha256 `d959496aa6fb78b007136383d1d0c9e478dc44462bd904162b717fd4dc378e8f`,
`summary.md` `fbf8e3b26d8bb12be21219ce956b83f322e1a1684ea01a3f8214b805c2623d6f`, identical before the work and after two rebuilds.
`estimates_diff.py` against `before.json`: 0 added, 0 removed, 0 changed. The importer ran twice with identical reports and no
change under `evidence/imported/`. `link_sources.py` and `extract_batch.py write --check` reproduced their committed files.

## For the Master (proposals only)

1. **Approve the five validator fixes** above (three `method: null` corrections, two `exclude`), or send the three rateChange records
   back to their agents. Proposal for `evidence-format.md` (owner-only): either list `Dye Crafting` in `METHODS`, or state that a
   `rateChange` takes `method: null`.
2. **The 83 citation groups** are a lower-value queue than they look: most are notes quoting a ratio or an audit count beside a held
   source. The biggest sources are wowhead spell 374627 (8), item 200061 (7) and reddit 1f83cnd (5). A pass by source, not by file,
   is the cheapest way through. Decide whether a closed group can be recorded (a line in `corrections.jsonl` has no field for it; a
   `closedExceptions` list in the manifest would be a tool change for M09).
3. **Needs the original post, cannot be settled offline:** the six Jallfo cohorts, s6bfrl uncommon gems, Felslate 2016 (101 vs 97),
   the R3 Serevite labels.
4. **Placement by name:** zkay8v's 22 rows and 1smgllg's 11 rates. The rule "never place by name" stands; the choice is an agent
   recording with IDs, or a documented exception for unique names.
5. **12 ambiguous-doubt sources** (Stormvine first): whether any becomes a `reference` row with an `unclear` meaning.
6. **M05 proposals still open:** `originalSource` on the 9 cross-source pairs, the 3 merges with conflicts, the 12 single-row subsets.
7. **M06 backfills (832 agent rows)** and the 0.5 equivalent-cast weight are policy questions, not record-level exceptions, so they stay in
   `M06-units.md` and are not in `exceptions.jsonl`.
8. **`held-sources-only` is a statement about sources, not cohorts.** A source is held at page or thread level (rule 5), so a note that
   cites another Wowhead comment on a held page lands here. The 129 files carry no observational numbers of their own, which is why
   nothing is lost, but comment-level source keys (M04.3 item 6) would make the label stricter.
