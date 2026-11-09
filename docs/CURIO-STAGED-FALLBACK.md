# Keep staged curio membership separate from direct destinations

This guard changes future research refreshes, not the shipped snapshot or runtime.

## Defect and evidence

At research commit `598f4aadf7b53c243aa6111429a94410caf74a45`, record
`midnight-20261108T1819-001` enumerates 20 intermediate Tier 36 tokens exchanged
from Slumbering Coil Curio 270909. The existing staged fallback contains 65 final
armor pieces. The generator previously combined these into 85 direct destinations.
These are different levels of the redemption chain, not 85 direct vendor offers.

Exact unmodified source files are in `tests/fixtures/curio-direct-enumeration/`.
The manifest records immutable commit URLs, Git blob IDs and SHA256 hashes.
The November 9 secondary one-curio claim and earlier source bonus strings are
included for replacement/context coverage, not admitted as full costs or live
reward variants. No source file or staged research list is modified.

## Narrow behavior

Only a staged entry marked `candidateOnly` can have its fallback suppressed.
At least one surviving source must explicitly claim a complete nonempty list
with positive integer item IDs. Complete lists must agree as sets; additional
partial lists must be subsets. Unknown IDs, duplicate/self IDs, contradictory
name-to-ID claims and conflicting or empty complete lists prevent suppression.
Excluded/replaced records are filtered by the existing importer before this
check. Existing replacement/correction semantics are not redesigned here.

The resulting source-enumerated destinations remain **candidates**:
`candidateRewards=true`, `listComplete=false`, `requirementsReviewed=false`,
`independentReview=NOT_REVIEWED`, confidence 20 and `costsComplete=false` remain.
An enumerated source list is not proof of vendor inventory, current character
eligibility, exact bonus variants, economic readiness or completeness of costs.
The descriptive note now identifies source-enumerated possible direct rewards.
URLs attached only to removed staged reward claims no longer count as their
provenance; remaining source URLs follow the existing sorting/20-URL bound.
No prices, probabilities, reward links or costs are introduced.

## Scope boundaries

All 237 current pinned token records and generator notes/conflicts remain
identical. The complete generated baseline and compiled database checks must
remain byte-identical. Future research 598f4aad changes only 270909: 85→20
relationships, source-assumption text and associated source URLs. It does not
upgrade candidate/review/confidence/cost metadata.

Hungering Void Curio 237602 remains 85 listed destinations: its 65 final pieces
and 20 intermediate tokens come from two research records, not staged fallback.
Resolving those source-to-source semantics requires separate review and a
current-data decision. This is not a general graph normalization patch.
The historical vendor/open 45661 future-refresh issue also remains separately
held. PR 50 mappings and current data are unchanged.

## Validation

`python tests/test_token_staged_fallback.py` checks immutable-source replay,
all 237 pinned records plus notes/conflicts against the original canonical hash,
strict/partial/empty/contradictory identities, source replacements/exclusions,
and unchanged ordinary non-candidate staged enrichment. The immutable-source
regression fails on original main because 65 extra final pieces are present.
The test is mandatory in `tests/run.sh`.

No live client transaction, vendor snapshot, WoW bonus mapping or economic
eligibility was validated. Full-suite execution results are reported separately
for the exact proposed commit/tree; these focused tests are not a full pass.
