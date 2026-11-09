# Imported Disenchant evidence: preservation, not numeric admission

Imported Disenchant results, including existing SavedVariables sets, no longer
contribute to yield estimates, gold values or recommendation confidence. The old
importer pooled different skill/context profiles into one category/build set and
erased the fields needed to establish applicability. An exact item ID fallback
is not safe either. No legacy set can be certified from the remaining counts.
Existing stored sets, seen IDs and import history are retained without rewriting
or deleting them. Other imported methods and their source controls are unchanged.

New valid Disenchant receipts are retained as reference-only archives, separated
by character, build, study, context, recipe and exact captured input metadata.
Canonical JSON retains null versus missing fields and empty array/object types.
It preserves full input hyperlinks, native skill, equipment, specialization,
field status and original receipt provenance. Unknown operation stats stay
unknown. No input rank is inferred from a hyperlink, and no skill coefficient is
introduced. Records retain original operation IDs and cannot be imported again
or counted as someone else's when already present in the local recorder.

Native records with missing, malformed or contradictory contextual identity are
rejected, not rerouted into legacy pools. Context-free old-format records can be
retained, but remain explicitly held. New receipt JSON is bounded to 64 KiB,
context JSON to 64 KiB, input JSON to 32 KiB, and study JSON to 64 KiB. Existing
paste, transfer, record and seen-ID limits remain; DE fails closed when the
seen-ID capacity cannot preserve deduplication.

Study truncation, global gaps, same-recipe gaps and unscoped censor flags are
retained as hold reasons. An unrelated recipe gap does not falsely make a DE
receipt incomplete. Even duplicate-only later exports can add study warnings
or mark conflicting metadata. A later apparently clean export does not clear
these warnings. A parsed receipt/page never establishes a complete study or
admits a rate. In particular the skill104 cohort's 199 classified receipts are
not a reconstructed 200-outcome histogram.

The import popup and settings explain the hold. The import result reports
`retainedOnly` separately, even though `accepted` still means stored records for
API compatibility. “Held Disenchant imports” reports the current held count and
explains preservation through a SavedVariables backup. There is no imported-data
export window in this slice: the existing copy window is bounded to 64 KiB and
cannot display a full cohort archive. Existing recorded-results exports concern
the player's own recorder, not imported evidence. An internal archive serializer
returns a clearly labeled reference archive for tests/inspection, not an
importable raw cast log. Legacy aggregate sets remain aggregates; no missing
original receipts are invented.

This safety slice does not introduce live, offline or simulated applicability.
All three exclude imported DE numerics, regardless of source toggle or apparent
skill match. Personal recordings, bundled research and legacy/reference source
estimates are separate paths and are not changed here. The generic build-time
v3 importer is also unchanged. PR51 salvage behavior and fixed40 compatibility
must be tested independently on combined code, without weakening their guards.

## Validation

The focused regression uses untouched native records from the November 7
skill82 and skill104 archives in representative one-record envelopes. Separately,
the full original compact archives preserve 194 + 200 + 199 classified receipts
through the ordinary size-limited importer. Python verifies the archived
zlib/base64 bytes and decoded contents; Lua uses an exact-byte codec bridge.
This tests the application transfer path, not WoW's native codec implementation.
No source file is changed, no rates are promoted and no new gameplay data is
requested. Full tests/run.sh covers deterministic generation and packaging.
Live UI/codec QA remains an owner review gate.
