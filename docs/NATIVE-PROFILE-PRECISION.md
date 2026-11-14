# Native profile numeric precision

This code-only candidate is stacked on published PR51, immutable commit
`484c4e05e5f9f18df04975fc0abac750a16cde7e`. It does not admit any new
cohort, modify a capture compiler or generated runtime, or depend on the pending
fixed40 or geared admission candidates.

## Defect and boundary

Lua 5.1 `tostring` rounds numeric values: unequal doubles differing by `1e-13`
can produce the same profile signature. Native signatures now encode numbers
with `string.format('%.17g', value)`, sufficient to round-trip finite binary64
numbers, with both signed zeros canonicalized to the same numeric identity. All captured profile fields remain part of the existing exact matching
contract. Labels and descriptions remain opaque strings; this is not portable
stat identity, locale translation, skill projection or statistical calibration.
Missing native context remains ineligible. Recipe, method, build, input rank,
receipt, refund, reconciliation and duplicate guards are unchanged.

## Existing SavedVariables

Existing sets remain readable immediately. On importing an unseen salvage cast,
the importer can derive its original rounded storage key. If the new key has no
set, and the old set has matching method, recipe, study, input, batch, rank,
build, concentration and complete retained observation context, it moves that
same aggregate to the new key. Its recorded totals, lineage and existing
reference context identifier are preserved. Query rows derive their routing
reference ID from the full retained native profile using the current precision,
and separately expose the original saved reference ID. This prevents old/new
independent studies with an identical exact profile from being incorrectly
excluded by the resolver; stored provenance is not rewritten or certified.
A disjoint same-study continuation
then appends to the existing aggregate; old and new replays remain duplicates.
Legacy signatures are cached per normalized context during each bounded import.
There is no new persistence schema or unconditional rewrite.

An old key belonging to an unequal retained profile is not moved or pooled.
If both keys already contain sets with the same full context and metadata,
complete unique and mutually disjoint cast lineage, and consistent numeric
aggregates, their counts, materials and lineage are combined into the existing
exact-key object before appending the new cast. This avoids downstream same-study
deduplication dropping legitimate unique samples. No target is overwritten. The same bounded reconciliation runs when rebuilding
the imported evidence index, so a valid disjoint pair is usable immediately after
loading SavedVariables, before another cast arrives. This also reconciles two
old keys differing only in the sign of zero, even without a new exact-key set;
a lone legacy set is left in place. The complete encoded keys
are verified as an exact/legacy pair; no context ID is guessed.
Missing, duplicated or overlapping lineage and malformed aggregates prevent
consolidation; both original sets remain stored and the new cast appends only to
the exact-key set. Both rows are explicitly marked held and excluded from live
eligibility, rather than letting downstream same-study deduplication pick an
arbitrary aggregate. They remain visible through the unfiltered evidence query
with a held reason, and remain part of the stored import count. Per-cast outputs
cannot be recovered from aggregate totals. Original raw exports are needed to
rebuild such history; no complete evidence claim is made.

Old versions could already combine colliding profiles while retaining only the
first native context. The new code preserves that aggregate, but cannot certify
or reconstruct lost per-cast attribution. Original raw exports are needed to
reassess that history. New exact grouping prevents future aliases; migration
is not historical provenance repair. Nothing is silently deleted or promoted.

## Regression evidence

`tests/test_native_profile_precision.lua` uses the existing published PR51
Recycling export. Synthetic renamed operation/receipt identities exercise
continuations and collisions, not additional empirical evidence. It loads the
actual immutable old importer, retains its SavedVariables, then reloads the new
module. It covers the old 200-cast set, unique continuation, duplicate replay,
subprecision profile isolation and cached live eligibility, unequal legacy
collisions, valid old/new coexistence including full evidence weight and valuation, unsafe
coexistence holds, independent old/new study evidence and valuation, actual
public ConversionOptions cache transitions, and actual old historical aliasing.

The full-suite hook verifies the frozen old module's SHA256 before loading it
from `tests/fixtures/pr51/ImportedResults.lua`. That code-only fixture is exactly
the published PR51 Git blob, independent of future branch deletion, squash,
shallow history or network access. No source export is added. Live WoW, native
codecs and SavedVariables UI behavior still require owner testing; embedded Lua
tests are not live-client QA.
