# Proposed v3 schema extension (M02.4)

Status: **proposed**. `research/v3/evidence-format.md` is owner-only, so these fields are documented
here, used by the migration importers and estimator changes on this branch, and offered to the owner
for `evidence-format.md` in the M10 pull request.

All fields are **optional**. A record without them is read exactly as today, so the hourly agents,
`build_estimates.py` and `audit_studies.py` keep working unchanged until each consumer opts in.

## New `drop` fields

| Field | Values | Why |
| --- | --- | --- |
| `castsBasis` | `reported` · `countedFromInputs` · `nominalEquivalent` · `derived` · `null` | Says where `casts` came from. Today 291 imported rows carry casts computed as inputs ÷ batch (only explained in `notes`), while new agent records in the same situation leave `casts` null (S16). One field lets the estimator apply one rule to both. `reported` = the source states completed operations; `countedFromInputs` = source states inputs processed, casts = inputs ÷ `inputsPerCast`; `nominalEquivalent` = the old pipeline's "five-ore-equivalent operations"; `derived` = any other computation (see `derivations`). |
| `inputsProcessed` | number or `null` | Ore/herbs/items the source says went through the process (S16 proposal). Raw, never computed. |
| `inputsPurchased` | number or `null` | Inputs bought/collected, when the source separates it from inputs processed. |
| `inputsRefunded` | number or `null` | Inputs returned by Resourcefulness or similar, when stated. |
| `cohortKey` | string or `null` | One independent measurement: same value = same cohort, even across files and copies. Format `<source-key>#<cohort label>`, e.g. `reddit:10u5ao8#batch03`. Needed because `study_identity()` merges different batches from one source that share a cast count (168 groups at the snapshot, 90 with differing numbers). |
| `unlockState` | `true` · `false` · `null` | Structured unlock status for conditional outputs (S6). Today the estimator scans `specialization`/`notes`/`stats` text for phrases such as "max knowledge". |
| `dataDateText` | string or `null` | Free-text period description that is not an ISO date (old `hotfixWindow`). Keeps `dataDate` machine-readable; 518 effective records currently put prose in `dataDate`. |
| `observedOn` | ISO date or `null` | When the player collected the data, if distinct from `source.published` (the old importer stored observation dates in `published`). |
| `rawOutputName` | string or `null` | The output exactly as the source names it, when it could not be mapped to an item (kept instead of dropping the output). |

## New fields on any record type

| Field | Values | Why |
| --- | --- | --- |
| `derivations` | list of `{"field", "formula", "assumption"}` or `null` | Every computed value names its formula and assumption, e.g. `{"field":"casts","formula":"inputsProcessed / inputsPerCast","assumption":"no refunds re-processed"}`. Replaces derivations hidden in `notes`. |
| `migratedFrom` | `{"path", "sha256", "recordRef"}` or `null` | Provenance for every migrated row: historical file, its hash at the migration snapshot, and the record/line/anchor inside it. |

## `corrections.jsonl`

Add to `CORRECTABLE` in `build_estimates.py`: `castsBasis`, `inputsProcessed`, `inputsPurchased`,
`inputsRefunded`, `cohortKey`, `unlockState`, `dataDateText`, `observedOn`. (The validator imports
`CORRECTABLE` from the estimator, so it follows automatically.)

## Rules that come with the fields

1. A record never gets `casts` without a `castsBasis` once M03.1 lands; the validator warns on new
   records that have `casts` and no basis.
2. Importers fill raw fields (`inputsProcessed`, `rawOutputName`, …) from the source and computed fields
   only with a matching `derivations` entry.
3. `cohortKey` is assigned by importers from source structure (batch labels, comment IDs). When absent, M05
   computes a fingerprint; `cohortKey` always wins over the fingerprint.
4. How each `castsBasis` is weighted for chance vs average is decided and tested in M06, not here.
