# M06: units, denominators and cast-basis weighting (S16)

Session MIG-005, 2026-10-31. Every number comes from running code on the migration branch (Linux, Python 3.13.18,
**SciPy 1.18.1 installed**, the same code path as MIG-003/004, so hashes compare). No network, no AI extraction.
Machine-readable lists: `M06-units-data.json` (`python3 research/v3/migration/tools/units_report.py --json …`: every
unused row with its reason, the mixed-batch groups, the backfill lists). Estimates diff: `M06-estimates-diff.md`.
Identity lists: `M06-identity-data.json`.

## Summary

| Measure | Before (HEAD `98893b8`) | After |
| --- | --- | --- |
| Evidence records (effective) / estimates / unplaced | 4,933 / 1,205 / 447 | 4,933 / 1,205 / 447 |
| Estimates changed | — | 112 (0 added, 0 removed); 38 chance moves of 5+ points, all reviewed below |
| Placed study rows that contribute nothing | 654 | **626**, each with a reason code |
| Totals without casts, unused (placed study rows) | 551 rows / 105 studies | **526 rows / 92 studies** (all with reason `totalWithoutCasts`: no structured input count) |
| Estimate groups whose contributing rows mix batch sizes unconverted | **58** | **0** (64 groups now convert per input) |
| Casts counting at reduced chance weight | 0 | 373 rows (290 imported countedFromInputs/nominalEquivalent, 25 counted from `inputsProcessed`, 58 converted mass casts) |
| Identity report vs M03b | — | **identical** (`M06-identity-data.json` = `M03b-identity-data.json` byte for byte) |
| Validator errors / warnings | 5 / 175 | 5 / 175 |
| Corrections matching / corrected records | 643 / 333 (45 import-study, 52 import-ref) | 643 / 333 (45 / 52) |
| Study audit | 473 studies, 40 clean | 473, 40 |
| Migration tests | 125 | 148 (125 + 23 in `test_m06_units.py`; 2 renamed, see below) |
| `estimates.json` sha256 (SciPy) | `3861b696…` | `6976d1bd…` (`summary.md` `c16d76e6…`); two rebuilds identical |

## 1. Measured before any code change

**Drop rows: 4,087** (2,812 study rows, 1,275 reference rows). By origin, `castsBasis` and casts:

| Kind | Origin | castsBasis | Casts | Rows |
| --- | --- | --- | --- | --- |
| study | imported | reported | yes | 398 |
| study | imported | nominalEquivalent | yes | 549 |
| study | imported | countedFromInputs | yes | 79 |
| study | imported | none | no | 70 |
| study | agent | (field absent) | yes | 1,073 |
| study | agent | (field absent) | no | 643 |
| reference | imported / agent | none | no / yes | 1,123 + 143 / 9 |

Agents never write `castsBasis`, `inputsProcessed`, `inputsPurchased` or `inputsRefunded`; imported rows carry
`inputsProcessed` on 668, `inputsRefunded` on 64, `inputsPurchased` on 19. The commonest study-row shapes (full table in
`M06-units-data.json`, `studyRowShapes`): casts + total, batch 5 (803 agent rows); total only, batch 5 (408); nominal
casts + total (443); total only with no batch (123); casts + average per input (84); percent "unclear" only (62).

**Batch sizes.** Study rows state `inputsPerCast` 5 (2,301), 20 (169), 10 (14), 1 (66) or nothing (260).
**58 imported nominalEquivalent rows say `inputsPerCast` 20 while their casts are five-input equivalents**
(`casts × 5 = inputsProcessed` in all 314 nominal rows that state inputs). 77 imported *reported* rows and 8 agent
rows count 20-input mass casts.

**Mixed groups.** 58 estimate groups mixed per-20 and per-5 casts under one per-cast figure, all in BfA, SL and
Legion milling and SL prospecting (Jiyao's per-mass-mill means, `ww-b008-osmenite-live-mass-200casts`, Thurgos's 50
mass prospects, Queendom's 3,000-herb Starlight Rose) next to five-herb or five-ore rows and per-5 TSM values. Example:
Riverbud → Ultramarine Pigment showed **9.04 per cast**. Three independent sources say about 4 per five herbs
(Baadkitty 157 / 40, Kidneph 814 per 1,000 herbs, Jiyao's mass-mill mean ÷ 4).

**Unused rows (placed study rows contributing nothing): 654.** 551 totals without casts (105 studies: dragonflight
364 rows / 50 studies, war-within 78 / 25, legacy 57 / 5, imported 41 / 20, midnight 10 / 4, master 1 / 1), 62
percentages of unclear meaning, 35 rows with no numbers, 3 per-input averages with no batch, 3 hit counts with no
casts. MIG-001's "529 rows in 92 studies" was measured before M03 added rows, with an uncommitted script; this count is
reproducible with `units_report.py`.

## 2. The rule (PLAN §3 rule 2, now implemented)

1. **Unit.** Each estimate is per cast of its group's unit, now written as `inputsPerCast` on every estimate.
   Prospecting: 5 (mechanics G1, verified; mass prospecting is 4 casts). Other methods: the smallest batch any row in
   the group states (studies and reference values), because mass casts are multiples of the single cast; Midnight
   milling comes out at 10 (M6). If no row states a batch the unit is null and rows are used as stated, as before.
   Result: Prospect 5 (1,108 groups), Mill 5 (236), Mill 10 (38), Disenchant 1 (73), Smelt various (10), none 21.
2. **Normalize per input, never split groups.** A row of another batch size is converted: casts × own/unit, an
   average per cast × unit/own, per-input averages × unit. Expected yield is linear in inputs. A per-cast *chance* (hit
   counts, percent per cast) from another batch size is **left out**, because P(at least one) is not linear in inputs;
   the reason `chanceNotConvertible` is recorded (0 such rows in today's data: the 8 mass-cast percentages are
   "perInput"). Separate groups were rejected: the addon expects one estimate per method, input and material, and the
   per-input average converts exactly.
3. **Weights.** Reported casts in the unit (or an absent `castsBasis`) count fully. Casts with basis
   `countedFromInputs`, `nominalEquivalent` or `derived`, casts counted from `inputsProcessed`, and converted casts count
   **fully toward the average** and at **`EQUIVALENT_CAST_WEIGHT` = 0.5 toward the chance**: its pooled estimate and its
   confidence, including a chance estimated from the average. 0.5 is a documented heuristic, the same size as S5's
   halved confidence, not a calibrated value. Why: these numbers count inputs, and Resourcefulness refunds (M9, M10, W2)
   may or may not have been processed again, so the true cast count is blurred by up to the refund rate (Cardinalai:
   715 of 4,000 ore, 18%).
4. **Rows with no casts.** `inputsProcessed` with a known unit gives casts = inputsProcessed ÷ unit (= ÷ inputsPerCast
   when the row's batch is the unit), weight 0.5 in the chance. `inputsRefunded` never changes a count: sources do not
   say whether refunds were processed again. `inputsPurchased` alone is not a count of inputs processed (M03 decision).
5. **Same rule for every row.** `row_use()` reads fields only, never the file or agent. An agent record without
   `castsBasis` is read as reported. Input counts and cast derivations written only in `notes` are **not read** (free
   text is what M08 is removing from `unlock_state()`); those rows are listed for the Master (section 4).
6. **Reference rows** convert the same way and stay starting guesses only (`test_reference_rows_never_reach_study_counts`).

Code: `build_estimates.py` (`row_unit`, `group_unit`, `same_unit`, `unit_average`, `row_use`, constants
`EQUIVALENT_CAST_WEIGHT`, `EQUIVALENT_BASES`, `NOMINAL_UNIT`, `PROSPECT_UNIT`). Identity (`study_identity`) is unchanged:
derived casts are never written back to rows, so fingerprints and copies are exactly as in M05/M03.

## 3. After

**Totals-only rows.** 25 now contribute (24 legacy mass-milling rows: 516803 2,000 WoD herbs ×6, Kidneph 1,000 BfA
herbs ×18; zzyjzu ~28,000 R3 Serevite) plus Melch1337's 3 per-input Widowbloom averages. The other 526 carry
`totalWithoutCasts`: agents' 510 rows (no structured input count) and 16 imported rows whose source states none.
Remaining unused reasons: `totalWithoutCasts` 526, `percent:unclear` 62, `noNumbers` 35, `hitsWithoutCasts` 3.

**Units.** 0 groups mix batch sizes without conversion; 64 groups convert (the 58 above plus the 6 WoD groups whose
mass-mill rows now count).

## 4. Backfill candidates for the Master (S16: who backfills?)

Not edited here (agent files and `corrections.jsonl` are out of scope). Lists with record IDs in
`M06-units-data.json` → `backfill`. The hints are pattern matches for a person to check, never estimator input.

- **Agent totals whose input count is only in notes: 434 rows / 67 studies** (e.g. the ten 10u5ao8 R2 Draconium
  batches, "10k rank-2 Draconium Ore"; Hochenblume 1,500 / 9,000 herbs; Aary 10,000 Hochenblume; Xenastro workbook
  quantities). **92 of these rows say not to infer casts** ("do not infer cast denominator from herbs consumed"),
  usually because refunds were re-processed. Under the M06 rule such a row would count with weight 0.5 in the chance and
  full weight in the average; whether that honours the agents' intent is the Master's call. The fix, if agreed, is one
  `inputsProcessed` correction line per row (`inputsPerCast` too where null).
- **Agent cast counts that notes say were counted from inputs: 398 rows / 49 studies** (e.g. `dragonflight-20261031-901..920`
  "Nominal casts = 10,000 ore / 5"; legacy "casts derived as 5,000 / 5"; `master-20261030-002/003` "nominal five-ore").
  These count fully today, while equivalent imported rows count at 0.5 in the chance: the inconsistency of PLAN §2.3 now
  sits in the data, not the code. A `castsBasis: countedFromInputs` correction per row would close it. Measured effect
  of backfilling all 398: 18 estimates change, confidence by at most 3 points, no chance or average moves. Some hits are
  reported counts that merely mention arithmetic (e.g. `master-20261030-004`, 43 completed prospects from 200 ore).

## 5. Estimates diff review (`M06-estimates-diff.md`)

112 rows changed: average 65, chance 54, confidence 86 (73 down, 13 up), studyCasts 65 (**all up, none down**), range
17, rangeSource 17, conflict 2, chance/average source 6. Every 5+ point chance move (38) and every studyCasts rise (65)
was checked row by row (`row_use` reasons per contributing row):

| Cause | Groups | Example |
| --- | --- | --- |
| Per-20 mass-mill means converted to five-herb casts (BfA, SL, Legion milling) | 14 BfA + 7 SL + 3 Legion of the 38 | Riverbud → Ultramarine 9.04 → 4.02 per mill; Anchor Weed → Crimson 2.82 → 1.61 (Baadkitty alone: 1.78) |
| Mass prospects converted (SL Oxxein/Phaedrum, Thurgos 50 × 20 ore; Laestrite `ww-b008` 200 mass casts) | 8 of the 38 | Oxxein → 173109: average 0.82 → 0.54, chance (estimated) 0.54 → 0.36; TSM table 0.50 |
| Totals that now count, so the chance comes from studies instead of the 20-cast starting guess (existing rule) | 6 WoD | Cerulean Pigment chance 1.0 → 0.84 (estimated from the average 2.08, range 2–3), average 2.11 → 2.12, confidence 30 → 47 |

- **Copies:** none. The 28 newly contributing rows have no other v3 row with the same input, output and total or
  input count, and their authors (516803, Kidneph, Melch1337) appear in no other record; zzyjzu's 28,000 / 24 matches
  nothing (the thread's 54,137 R2 comment is the held 108782r copy). Converted rows already counted before M06; only
  their unit changed, so identity is untouched (identity data identical to M03b: 0 groups dropping differing numbers,
  24 partial copies, 24 near copies, 1 pooled study).
- **Ranges and conflicts:** 17 estimated ranges stop being widened to fit inflated averages (Starlight Rose → Roseate
  Pigment 5–23 → 5–8, now the reference range). Laestrite → 168191/168192 lose their chance/average conflict, so the
  halving stops: confidence 50 → 100 (8,000+ hit-counted casts).
- **Confidence-only moves** (47 rows, 1–10 points down): groups whose chance is estimated from nominal or counted
  casts (TBC/WotLK/MoP/TWW prospecting, Midnight Kyzenbka pigments) now use the 0.5 weight.
- No estimate was added or removed; no `studyCasts` fell.

## 6. Tests

New `tests/test_m06_units.py` (23): one per basis (reported, absent = reported, countedFromInputs, nominalEquivalent
incl. the ipc-20 case, derived), the confidence of a derived chance, imported vs agent rows, casts from inputs, totals
with no input count and inputsPurchased only, hits without casts, refunds (counted and reported), mass-mill
normalization, mixed batch chance left out, per-input averages via the unit, Midnight 10-herb unit, prospecting unit,
unchanged single-unit groups, reference rows never in study counts, reference conversion.

Two existing tests changed on purpose:
- `test_build_estimates.test_known_defect_totals_without_casts_unused` → `test_total_without_casts_or_input_count_unused`
  (same assertion; the S16 defect is resolved for rows that state `inputsProcessed`, this row states none).
- `test_m03b_import.EstimatorEffect.test_totals_without_casts_add_no_casts` → `test_totals_without_casts_count_from_inputs`
  (MIG-004 pinned "M06 decides"; now 1,000 herbs of 20-herb mass mills = 200 five-herb casts, studyCasts 300).

## For the Master (proposals only)

1. Approve the 0.5 equivalent-cast weight and the unit rule, or set another value (one constant).
2. Decide the two backfills in section 4, in particular whether the 92 "do not infer" rows should count.
3. S14: Kyzenbka's Midnight pigments keep their ~13 per 10-herb mill (unit 10 confirmed); only their confidence fell.
4. 16 disenchant groups and 1 mill group have no stated batch (`inputsPerCast` null in the output). Disenchanting one
   item per cast is not in `mechanics.md`; add it if wanted.
