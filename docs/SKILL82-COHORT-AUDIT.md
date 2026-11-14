# Preserved Evercore Shade cohort audit

This is an offline review gate, not numerical admission. It changes no raw capture,
research snapshot, runtime database, importer or rate. It needs neither a new capture
nor a live WoW client. The new research rows remain reference-only pending independent
review; structural staging is not scientific or production approval.

## Run

From any directory:

```sh
python3 /path/to/repo/tools/audit_skill82_cohorts.py
python3 /path/to/repo/tools/audit_skill82_cohorts.py --output /tmp/skill82-audit.json
```

The optional report includes original operation IDs, complete native contexts,
source-file hashes, material histograms, study coverage and the censored comparison.
The tool writes only the explicitly requested report. Its checks remain active with
`python -O`. It is not a general importer or source-admission manifest.

`python3 tests/test_skill82_cohort_audit.py` runs the focused regressions, also included
in `bash tests/run.sh`. Semantic tests bypass byte pins and regenerate staging before
checking mutated measurements, so a hash mismatch cannot mask those failures. Raw,
review and fixture pins are independently tested. Recipe/global/truncation gaps and
unrelated Craft gaps have distinct tests.

## Source and reproduction

Raw captures are pinned to main
[b661084](https://github.com/Voodoobrew101/Loot-Liquidator/tree/b6610848604f68f8f3b40834397b79ce53eb8fb5/research/integration/measured-captures).
The exact, unedited 18-row research evidence fixture comes from
[71a9b434](https://github.com/Voodoobrew101/Loot-Liquidator/blob/71a9b43462111b670bafefe09e2d3f0f180215a1/research/v3/evidence/midnight/2026-11-09T1518-evercore-shade-skill82-104-source-cohorts.jsonl).
Its fixture README and tool constants record hashes. Copies of research claims are
not new observations. The original worker still owns research evidence; this gate
only independently checks its claims against preserved native operations.

- The 194 update and 200 additional records are disjoint: 394 casts, two studies,
  eight study/context cells, 359 R1 and 35 R2 outputs.
- Earlier97 is a strict subset of194, never an additional cohort.
- The rod-transition archive has11 separate measured82 casts (9 R1/2 R2) and12
  records without native measured82. Thus the historical clean82 total is405,
  with368 R1/37 R2. Neither394 nor405 should be added to its constituent cohorts.
- Every one of394 casts has one input and exactly one output unit of one rank.
  A zero means absence of that material on a completed cast yielding the other
  rank, not a zero-output/failed cast. Positive ranges1..1 do not erase zero bins.

| Study suffix | Context | Casts | R1 | R2 |
| --- | --- | ---: | ---: | ---: |
| 23 (194 update) | 78 | 45 | 41 | 4 |
| 23 | 79 | 49 | 46 | 3 |
| 23 | 80 | 42 | 40 | 2 |
| 23 | 81 | 58 | 51 | 7 |
| 25 (200 additional) | 78 | 58 | 52 | 6 |
| 25 | 79 | 47 | 42 | 5 |
| 25 | 80 | 48 | 45 | 3 |
| 25 | 81 | 47 | 42 | 5 |

All394 inputs are244752 Evercore Shade, ilvl165, rarity3, leather armor4/2,
Disenchant13262, RETAIL build70783, addon ecd189a794a8b2c0318389766638b36cf2416e81,
recorder5/capture2. Native Enchanting2909 measures64+18=82, specialization `none`.
Full equipment and item links are preserved. Contexts78/79/80/81 differ at input
modifier29 values40/32/49/36. Output243602 has native rank1;243603 rank2.
Input numeric qualityRank is absent, though its full link displays Tier1 and
modifier38:4. The research inputRank stays null. Operation stats are absent/unknown,
not zero. `none` is a recorded specialization declaration, not a newly measured
node-effect model. No minimum-skill baseline, skill-effect coefficient or scientific
confidence is inferred.

The194 study retains its censored Craft:1229863 gap. Strict recipe-scoped staging
admits its Disenchant13262 records without rewriting that raw flag. An unresolved
Disenchant13262 gap, global gap or truncation excludes the corresponding cohort.

The separate104 batch remains200 owner-confirmed completions,199 classified native
records (179 R1/20 R2), one unclassified result. Its DE gap still excludes all199
from strict staging. R2 incidence is bounded20/200–21/200, or10–10.5%, with no inferred
missing outcome, full-batch histogram or point estimate20/199. Review files and all
classified IDs are pinned; unknown item IDs, ranks and quantities remain null.

## Actual production boundaries

- `validate_craft_export.py` stages AWAITING_REVIEW/NO_NUMERIC_TRANSFORM with unknown
  operation-stat and not-minimum-skill blockers. This audit does not remove them.
- `capture_observations.py` scans cast-page files, not these export-page archives.
  Do not widen the glob. The independently source-bound Recycling compiler likewise
  admits none of394 IDs, verified by executing both compiler APIs.
- `research_v3_to_baselines.is_counted` rejects all18 reference rows, verified using
  the actual production predicate. New research also requires an explicit snapshot
  refresh. The broader published-range pass is distinct from counted means; this
  audit does not claim every possible future range contribution is excluded.
- Do not change sourceKind to study merely because these descriptive histograms
  match. Exact-context runtime applicability and any shared admission need separate
  design/review. No snapshot refresh is part of this change.

## Separate generic Disenchant importer limitation

Main's `LootLiquidator/ImportedResults.lua` lines146–188 validates individual records
but discards native skill/study/context. Lines226–245 key the aggregate by physical
gear category, nominal batch and build. Lines295–315 emit a provisional fixedReference
with empty referenceConditions. This generic DE behavior is distinct from PR51's
verified salvage path and is not changed here.

A minimal diagnostic takes one unchanged original record and original contexts from
each of the194 skill82 and199 skill104 exports, in separate small JSON envelopes
(`schemaVersion`, `sampleKind`, `records`, `contexts`, `studies`), imports both into an
empty LL.db and asks `ImportedEvidenceRecords('Disenchant:gear:11:3:armor')`. The existing
runtime produces one2-cast record with empty referenceConditions instead of preserving
two measured profiles. This was reproduced under Lua5.1. It is not an approved exact
82-skill admission path. Trimming the diagnostic envelope is only to stay within the
personal importer's500000-character limit; original archives and records are not
modified. A future fix needs separate scope and must not duplicate PR51.

## Validation and limits

The focused audit verifies source hashes, exact original membership and contexts,
all16 histograms/means, cumulative scope, zero semantics, censored104 nulls/bounds,
reference-only exclusion and compiler admission membership. Full mandatory addon
suite remains required for the candidate, including deterministic ItemDB output and
package validation. No live-client UI/performance test, new measurement, native CI,
merge or release is implied by this offline gate.
