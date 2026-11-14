# Importing verified salvage results

The recorded-results Import button accepts Engineering Recycling (Recycle,
recipe 1229930, five nominal inputs) and Radiant Shatter (Craft, recipe 1280394,
one nominal input). Other Craft and salvage recipes remain unsupported.
Native input eligibility, result receipts and the complete shared inventory
reconciliation must agree. Explicit resource returns reduce measured net
consumption; nominal batch size and material output counts remain separate.
Refunded inputs are valued once as input savings.

Use the complete **Export recorded results** document or compact export. Raw
text has the existing 500,000-character limit; compact envelopes support a
decoded document up to 16 MiB. A split page that omits members of a shared
salvage reconciliation is rejected with instructions to copy the complete
export. It is not treated as a smaller successful experiment. No pending
partial pages or partial cohorts are accumulated.

Imported salvage remains a separate, provisional evidence source. Original
study IDs, cast IDs, recipe, measured context, material quality and net-input
counts are retained in study-specific aggregates. Compatible independent
studies can contribute together; repeated cast/native receipt identities and
the player's own recorded results cannot add another copy. Existing four-method
imports retain their previous behavior and saved records.

Salvage rates currently require an exact live measured profile and input rank
on the original game build. Matching rechecks the native operation before
using cached values. It compares all captured equipment, including other
profession slots, as well as skill, specialization, operation stats and
Concentration. This deliberately conservative match can exclude a different
player with otherwise similar stats or different equipment links. Offline
and simulated profiles are not projected from imported salvage rates. Unknown
or incompatible context remains unavailable; no new profession curve or stat
coefficient is inferred.

Each context is normalized once per document and must fit 4,096 tree nodes and
65,536 characters of string data. Shared contexts are reused across receipts.
The existing 50,000 remembered-cast limit also bounds native receipt identities;
new salvage imports stop at capacity until imported results are removed.

The focused regression uses the preserved 200-cast geared Recycling export
(396 R1 Evercores, 933 net pigment from 1,000 nominal pigment) and four live
revision-6 Shatter casts (12 R1 dust from four R1 shards). It exercises the real
resolver and Craft conversion option, source controls, exact-context/cache
changes, independent studies, refunds, malformed nested records and incomplete
reconciliations. These automated checks do not claim a new live-client test.
