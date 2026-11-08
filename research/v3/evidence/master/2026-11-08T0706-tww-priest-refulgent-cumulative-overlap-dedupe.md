# TWW Dying Star priest Refulgent: same-source duplicate and PTR/live cohort identity (2026-11-08, coordinator)

**Scope and status:** Research-only original-source *lineage and source-transcription* comparison of two existing, worker-owned evidence files. No new player casts, no new per-cast units or measured probability, no same-row-output-ID inference from rank ordering, no character-eligible Retail gold decision, no compiler/tooltip execution. Identified while checking the War Within worker's current 2026-11-08T06:34 report (which already flagged possible overlap), then independently read both relevant original-source transcriptions and the current estimator identity code. Do not add these as independent samples.

## Source match: item 237707

Both files identify exactly **the same original base-item Wowhead Looter source**:
<https://www.wowhead.com/item=237707/dying-stars-pyrelights>.

| Row | 2026-11-06 original-HTML-linked record | 2026-11-08 indexed-row record | Source denominator | Material-positive occurrences | Old source-linked output identity |
| --- | --- | --- | ---: | ---: | --- |
| 1 | `war-within-20261106-1725-020` | `war-within-20261108-0527-007` | 121 | 61 | 219952 / rank 1 |
| 2 | `war-within-20261106-1725-021` | `war-within-20261108-0527-008` | 121 | 40 | 219954 / rank 2 |
| 3 | `war-within-20261106-1725-022` | `war-within-20261108-0527-009` | 121 | 17 | 219955 / rank 3 |

The older records explicitly report checking original Wowhead linked output item IDs; the newer records leave output ID and rank `null` because their *indexed snippet* lacked links. All three ordered hit counts, denominators, base input, and source URL are **identical**. These six rows describe at most **one source-reported 121-operation cumulative cohort**, not two separate 121-operation cohorts. The three material row counts sum to 118 reported positive events; they are **not** a 118-unit yield or 118 unique disenchant clicks, and the remaining 3 cannot be called zero-output disenchants. Per-output quantities, joint-event overlaps, upload patch, actual item bonus, profession build and live eligibility remain unknown.

This is a copy with **information lost**, not new numerical coverage. No fields from the richer source-linked 2026-11-06 record should be replaced by rankless 2026-11-08 counts.

## Related, distinct ambiguity: item 237712

For <https://www.wowhead.com/item=237712/dying-stars-cassock>, older source-linked live records `war-within-20261106-1725-023/024/025` report **130** item operations with Refulgent rank-specific hits **68/41/19** (219952/219954/219955). The newer **PTR** item page <https://www.wowhead.com/ptr/item=237712/dying-stars-cassock> was copied into `war-within-20261108-0527-010/011/012` with **122** operations and three rank-unknown hit rows **65/38/17**. A later-indexed smaller PTR denominator is not evidence of 122 independent new operations or of a `130 - 122 = 8` fresh/removed-casts observation. Site/view, collection window and individual upload lineage are missing. Preserve the two snapshots for audit but do not pool either as an independent cohort or transfer output-rank IDs to the PTR source without original linked-row validation.

## Compiler identity risk to regression-test

At current research branch head `6488e5150430107843336c296328c198800971d7`, `research/v3/tools/build_estimates.py` computes `study_identity` from normalized source, input rank, cast count, and study numeric vector, and `misplaced_copies` uses `same_output` to suppress a more-vague copy in a separate output group. `same_output` explicitly refuses **rank-known vs rank-unknown name-only** equivalence unless both rows have the exact same output ID. That correctly avoids guessing a rank, but it also means this source-identical 237707 copy can evade the cross-group suppression of a family-only row. **This is a code-path risk, not a proven compiler regression:** no fresh estimator or offline runtime test was executed on the new evidence. The generated `research/v3/output/summary.md` is a previous build, not proof that these latest records were compiled.

Required isolated engineering fixture: two source-identical three-output studies, first with 219952/219954/219955 known and the second with matching exact 121 and 61/40/17 but output IDs/ranks missing; verify one independent lineage, preserve known per-rank output fields and do not admit an extra family fallback/EV, while an unrelated same-name material with different source data remains separate. For PTR/live differing snapshots, demand independent upload IDs/epochs before pooling, and do not use mere row order to derive quality IDs.

## Disposition and handoff

- **Category:** duplicate source cohort plus loss of output identity (237707); ambiguous independent cohort/context and rank IDs (237712). Not price absence or tooltip display.
- **Owner:** War Within evidence owner/T0048 to add a clearly linked `replaces`/non-independent source-note or propose an additive reviewed correction for the 2026-11-08 237707 rows; preserve both append-only originals. Research estimator reviewer to test source-identical rankless/ranked copy suppression before integration. No overwrite to worker files or shared corrections made here.
- **Next evidence:** original linked PTR row output IDs, raw upload dates and variant-specific individual disenchant logs for 237712; independently verified current Retail character bonus/eligibility and actual valuation/rendering needed for actionable results.
- **Observed work:** compared all six 237707 and six 237712 worker records by exact item ID, URL, denominator, row hits, output identity, and study keys; examined `build_estimates.py` `study_ref`, `study_vector`, `study_identity`, `same_output`, `misplaced_copies`; checked no 237707/237712 ID-specific additive entries in current `flags.jsonl` or `corrections.jsonl`. No independent source-page live HTML, compiler, Lua suite, or price simulation run.

Sources: [rank-linked original 2026-11-06 transcription](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/five-agent-completion/research/v3/evidence/war-within/2026-11-06T1725-wowhead-linked-refulgent-identity.jsonl); [newer source-indexed 2026-11-08 transcription](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/five-agent-completion/research/v3/evidence/war-within/2026-11-08T0527-dying-star-priest-epic-looter-source-hits.jsonl); [estimator identity implementation](https://github.com/Voodoobrew101/Loot-Liquidator/blob/6488e5150430107843336c296328c198800971d7/research/v3/tools/build_estimates.py).
