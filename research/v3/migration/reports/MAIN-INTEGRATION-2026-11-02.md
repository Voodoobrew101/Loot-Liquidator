# Reviewed research and addon integration

The owner authorized resolving the reviewed PR conflicts, validating functional
implementation, and merging into main. This candidate combines #22, #23, #25,
the explicit SoD exclusions in #26, and corrected addon replacement #27.
Research development is frozen at `331a905` for this candidate. Later hourly
worker evidence requires its own reviewed reconciliation.

## Source decisions

- Preserve the S21 output-material and S26 quality-rank guards. Matching totals
  alone never prove identity. Eleven later rankless Cowl/Cuisses transcriptions
  explicitly duplicate the older ranked rows: retain all eleven original hit
  fields with the original 154/121 operation denominators. Their hit probability
  is measured; average quantity remains estimated because totals are unknown.
- Jallfo's later workbook transcription repeats 216 original output rows. The
  retained corpus has six original ore/skill profiles, each with 37 outputs:
  the original 216 and six additional Draconium stone/glass totals (1036/769,
  947/1079, 986/1225). Append-only corrections record each excluded row's retained
  counterpart. Keep completed casts unknown and clear the six unsupported
  Prismatic Ore rank-1 annotations. No EXPECTED formula values are imported.
- The six new Draconium fields resolve the previous six imported-versus-agent
  stone/glass mismatches. They do not authorize completed-operation estimates.
- Two copies of zkay8v's original 1,000-completed-prospect study and two copies
  of its separate 50,000-nominal-ore comment are canonicalized through explicit
  row crosswalks. Retain 25 and 22 output fields respectively; preserve sourced
  exact IDs from the richer transcription. Never infer 10,000 completed casts
  for the second cohort. Preserve the source's 132-unit/13.4% inconsistency.
- Exclude the two explicitly Season of Discovery Brown Linen Robe records from
  the Retail estimator; retain their raw evidence and other historical cohorts.
- Search records remain outside the importer's URL and author-text holdings.
  At `37cc605`, y3e8ek was search-only. The later workbook transcription now
  supplies actual drop rows, so the held-source corpus transition is explicitly
  reviewed. One additional source-context mismatch remains queued, rather than
  being silently treated as resolved.
- Keep source-correction history and original worker JSONL files intact. The
  addon snapshot remains the separately validated immutable `4df9ae8` pin.

## Main compatibility and reproducibility

Main's consolidated addon removed the legacy root GameData, StatYieldProfiles
and ResearchDB files. Their original `331a905` Git blobs are preserved byte for
byte under `research/legacy-addon-v0.9.70/`, with provenance and SHA-256 hashes.
The importer records the actual archived source path. Research JS compilation
uses those same pinned bytes. The current addon never loads these archives.

The inventory now includes 1,250 historical files, versus 1,244 before integration:
three legacy files move; five main research documents/tests and the archive's
provenance file are added. All paths remain individually inventoried, hashed and
disposed. The held-source conflict count grows from 81 to 82; the six now-linked
Jallfo cooutput mismatches leave that exception class. Remaining validator and
source-identity issues stay visible in the generated unresolved register.

The original PLAN's URL baseline (165 mentioned sources) uses the original M01
registry at `f7ca506`. Current before/after coverage uses the expanded current
registry. This prevents newly added historical URLs from changing the definition
of the old baseline. Confidence-band movements are recalculated by each pinned
historical stage's estimator and the current corrected corpus; they are not new
current-Retail measurements or a calibrated increase in confidence.

## Functional validation

The full addon `tests/run.sh` and research completion pipeline `--check` passed
locally on the consolidated tree using Lua 5.1. The controlled addon census has
367 offline profiles: 360 numeric and seven conditional/partial, including the
50 formerly unvalued baseline profiles. Token reward identities, exact variants,
cost conservation, source controls and actual tooltip formatting are exercised.
Final full migration reproduction and native GitHub CI are required on the final
candidate commit. No live WoW session, character eligibility census, live prices
or exhaustive Retail coverage is claimed.
