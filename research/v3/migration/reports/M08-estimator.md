# M08: the estimator consumes all usable evidence, and every record it does not use says why

Session MIG-009, 2026-11-01. Measured with `tools/estimator_effects.py` (data: `M08-estimator-data.json`) and
`tools/estimates_diff.py` (`M08-estimates-diff.md`). Evidence: the snapshot as of M07, 4,945 effective records.

## Result in one paragraph

Three guards and one new output. **No estimate moved**: `estimates.json` is byte-identical before and after
(1,205 estimates, 449 unplaced; sha256 `898790d5…` on the machine that ran this session, no SciPy). The three guards
touch **0 records** in the committed evidence, because the importer already moved prose dates out of `dataDate`
(M03), no record sets `unlockState` yet, and every percentage already states its meaning. They stop the next agent
record that does any of these from silently changing a number. The new `output/unused.json` accounts for all 4,945
records: **2,597 used, 2,348 unused, each with one reason code**.

## 1. Structured `unlockState`

`unlock_state(r)`: if the record has the field, it decides (`true`, `false`, or an explicit `null` meaning "the source
does not say"). Only a record without the field falls back to the phrases in `specialization`, `notes` and `stats`
(`unlock_state_from_text`). A value that is not `true`, `false` or `null` counts as absent.

| Measure | Before | After |
| --- | --- | --- |
| Records carrying `unlockState` | 0 | 0 |
| Records whose unlock state changes | n/a | **0** |
| Study rows whose unlock answer comes from text | 176 (133 false, 43 true) | same |
| ... of which only from `notes` or `stats`, not `specialization` | 5 | same |
| Study rows in conditional groups | 71: 60 unstated, 9 true and 1 false from `specialization`, 1 true from notes | same |

The notes-only fragility the plan worried about touches **one** row in a conditional group today. Tests: structured
`true` beats text that says no; `false` beats "max knowledge" in notes; explicit `null` ignores the text; absent field
falls back; a non-boolean value is treated as absent; a correction can set it.

**Hazard for the Master.** `evidence-format.md` tells agents to write every unknown as `null`. If `unlockState` is added
there as written, agents will write `unlockState: null` on every record, which now means "unknown" and switches the text
fallback off for them. A conditional study whose unlock is stated only in `notes` would then be left out. Recommended: do
not add the field to `evidence-format.md` until it says "omit unless the source states the unlock; never write null".
The alternative (treat `null` as absent) is a one-line change in `unlock_state()` if the Master prefers it. I followed the
task wording (fall back only when the field is absent).

## 2. ISO-only dates

`dataDate`, `observedOn` and `source.published` are read only through `iso_date()`: `YYYY-MM-DD`, `YYYY-MM`, a range or
timestamp starting with one. Impossible dates (`2026-02-30`, month 13) and prose are rejected. The old test accepted any
string starting `YYYY-` of ten or more characters, so `"2026-04 live realms"` passed as `2026-04 li`. Two further
consequences, both fixed:

- A prose `dataDate` no longer counts as "collection date known". The old `epoch_weight` tested `r.get("dataDate")` for
  truthiness, so prose plus a `published` date after a rate change returned "collection-dated" when the study was in fact
  dated by its post date. It now says "dated by post date only", as it does for an absent `dataDate`.
- A month-only date is placed only if the whole month is on one side of the change; `2026-03` against a 2026-03-31 change
  is "undated" (0.25), not a guess.

| Measure | Before | After |
| --- | --- | --- |
| `dataDate` / `observedOn` fields that are prose | 0 | 0 |
| Month-only date fields | 0 | 0 |
| Study dates that change | n/a | **0** |
| Epoch weights that change | n/a | **0** |

(MIG-001 counted 518 prose dates; M03.1 moved them to `dataDateText`.) Tests: ISO forms, rejected forms, prose
starting with a month, prose plus a post date, `observedOn`, month precision, day precision unchanged.

## 3. `percentMeaning` guard

`chance_from_percent()` accepts only `percentMeaning == "perCast"`; null was previously treated as per-cast.

| Meaning on rows with a percentage | Rows |
| --- | --- |
| `perCast` | 959 |
| `unclear` | 138 |
| `perInput` | 8 |
| null | **0** (study and reference) |

0 rows change. Tests pin null, `perInput`, `unclear` and unknown values as "not a chance", and show a null-meaning
reference value does not become a prior.

## 4. Per-record unused reason

**Where:** a new file `output/unused.json`, not a field in `estimates.json`. Reasons: `estimates.json` is the addon-facing
contract and `estimates_diff.py` keys on it, so adding 2,348 records or per-estimate arrays would change its shape for no
addon benefit; the question is per record, not per estimate; and a separate file lets a reviewer diff it on its own.
`summary.md` also gets the count table. `build()` keeps returning `(estimates, unplaced)`; the new `analyze()` returns the
usage as well, and both give identical estimates (a test).

**Definition.** A record is *used* when it adds casts, hits, a total, an average or a prior to an estimate (roles
`chance`, `average`, `prior`; `condition` for a condition record that tags an output). Widening a min-max range alone does
not count; such an unused row is flagged `range: true`. Every effective record has exactly one outcome (a test over the
committed evidence enforces it, and that each reason is in the closed vocabulary `REASON_CODES`).

| Reason | Records | Meaning |
| --- | --- | --- |
| *used* | 2,597 | average 1,536 · prior 1,044 · chance 104 · condition 15 (a row can have several; 950 also set a range) |
| `type:exchange` / `token` / `recipe` / `noDisenchant` / `rateChange` / `searched` | 315 / 244 / 130 / 124 / 16 / 7 | not a drop row; the estimator builds drop estimates only |
| `unplaced:noOutput` | 406 | no output item ID or name. 397 are M03's name-only rows with `rawOutputName` (stored on purpose, never placed by name) |
| `unplaced:noInput` / `noMethod` | 41 / 2 | cannot form a group |
| `totalWithoutCasts` | 320 | a total with no cast count and no input count (S16 backlog) |
| `duplicateStudy` | 148 | the same cohort already counted (M05 identity) |
| `duplicateRowInStudy` | 134 | a second row of one study in one estimate group (section 6) |
| `reference:noUsableValue` | 198 | a reference row with no percentage or average (TSM 86, compiled 47, reference 45, `unclear` percentages 20) |
| `copy:vaguerGroup` / `copy:pooledStudy` | 81 / 2 | M05: a copy that lost item IDs; a study that is the sum of its batches |
| `percentNotPerCast` | 56 | percentage whose meaning is `unclear`, `perInput` or null |
| `conditional:unlockUnstated` / `unlockFalse` | 55 / 1 | conditional output and the study does not state the unlock |
| `reference:priorSuperseded` | 28 | studies measured only the average, so the reference chance is not used |
| `noNumbers` | 35 | a study row with no number at all |
| `hitsWithoutCasts` | 3 | hits with no cast count |
| `condition:incomplete` | 2 | a condition record with no method or output ID |

**Reconciliation with M06.** M06's 626 "contribute nothing" rows are all here as unused: 414 with the same numeric reason
(`totalWithoutCasts` 320, `percentNotPerCast` 56, `noNumbers` 35, `hitsWithoutCasts` 3) and 212 that the estimator drops
first as a duplicate (177), an unlock skip (26) or a copy (9). No numeric-reason row is missing from M06's list (a test).

## 5. Estimate diff

| Change | Records affected | Estimates moved |
| --- | --- | --- |
| `unlockState` first | 0 | 0 |
| ISO-only dates | 0 | 0 |
| `percentMeaning` guard | 0 | 0 |
| `analyze()` / `unused.json` (no numeric change) | n/a | 0 |
| **All together** | | **0 added, 0 removed, 0 changed** (`M08-estimates-diff.md`) |

Each change was also checked alone: the per-function comparison in `estimator_effects.py` keeps the old function beside
the new one and counts records whose answer differs. Fixture tests cover the cases where it would differ.

## 6. Findings the unused list exposes

1. **`duplicateRowInStudy` hides nothing usable today, but the rule is latent.** 134 rows in 8 studies. 132 are the six
   Jallfo studies (22 rows each: rank-1/2/3 rows of one gem with null output IDs, so all three land in one `family:` group)
   and carry totals with no casts, so none could count anyway; they are already in the M04.1 exception queue. The other two
   (`dragonflight-20261031-309`, `war-within-20261031-823009`) have a total with no casts and no numbers. If a study with
   casts ever puts two rank rows into one family group, the estimator counts only the first. Not changed here: summing
   per-rank totals into a family average is a statistical rule for the Master.
2. **Ranges are collected before dedupe.** 140 unused rows still widened a min-max range: 127 are reference rows (their
   range is the reference range, by design), 13 are study rows (8 duplicates, 4 without numbers, 1 duplicate row). Without
   those 13, one estimate's observed range would change (Mill, Unspecified Khaz Algar herb → pigment, 9-15 → 11-15). Not
   changed (it would move an estimate; outside this task's three changes).
3. **`unplaced:noOutput` is almost all by design** (397 of 406 are M03's name-only rows). The 9 others are agent rows.

## 7. Decision on committing `output/`

Recommendation: **keep `output/` out of every migration and agent commit; let the reviewer regenerate it** (the reviewer
already commits it, last at 20:23 UTC on 2026-10-31 with 1,221 estimates), and make it reproducible first.

- *Never commit here.* The committed copy is stale by construction (1,221 estimates / 3,993 records against 1,205 / 4,945
  now); the plan's alternative, rebuild in the same commit as every data change, would put 4 generated files into each of
  the hourly agents' commits.
- *Reproducibility blocks any rule.* `confidence()` uses SciPy when installed and a normal approximation otherwise, so the
  same evidence gives different `estimates.json` bytes on different machines (this session: `898790d5…`; with SciPy
  `d959496a…`). Until one method is pinned, a committed copy flips whenever someone with the other setup rebuilds.
- *README says agents use `summary.md` to find weak items.* They can rebuild it (one command, seconds). Suggested README
  line: "run `build_estimates.py` first; do not commit `output/`; the reviewer commits it".
- `unused.json` is git-ignored for now so a stray `git add` cannot publish it before the owner decides; remove the
  `.gitignore` line if the owner wants the reviewer to commit it (it would be useful to agents: it names the records that
  did not count).

## For the Master

1. **Output policy and SciPy** (section 7): choose one confidence method (require SciPy, or drop the fallback), then decide
   whether the reviewer commits `output/` including `unused.json`.
2. **`unlockState` rollout** (section 1): do not add it to `evidence-format.md` with the "write unknowns as null" rule.
3. **Totals without casts: 320 rows** are the largest unused block (S16 backfill lists in `M06-units-data.json`); the 6
   Jallfo studies are 132 of the `duplicateRowInStudy` rows and need the exception decision first.
4. **Family groups and ranks** (section 6.1): when ranked rows lack item IDs they share a family group and only the first
   counts; decide whether per-rank totals should be summed there.
5. **Ranges before dedupe** (section 6.2): confirm that duplicates and no-number rows should not widen an observed range.
6. 2 `condition:incomplete` records and the 5 validator errors (M07) are the remaining schema cleanups; neither moves an estimate.

## Reproduce

```
python3 research/v3/tools/build_estimates.py            # also writes output/unused.json
python3 research/v3/migration/tools/estimator_effects.py --json research/v3/migration/reports/M08-estimator-data.json
python3 -m unittest discover -s research/v3/migration/tests
git checkout -- research/v3/output && rm -f research/v3/output/unused.json
```
