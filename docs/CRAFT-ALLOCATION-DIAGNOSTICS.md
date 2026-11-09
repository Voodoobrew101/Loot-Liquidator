# Ordinary Craft allocation diagnostics

This change preserves information needed to diagnose a rejected ordinary Craft
capture. It does **not** repair the historical allocation mismatch, accept any
additional casts, admit generic Craft imports, reconstruct historical records,
or change numeric eligibility. Live-client verification is still pending.

## Why this is needed

At main `b6610848604f68f8f3b40834397b79ce53eb8fb5`, the retained raw/compact
exports under `research/integration/measured-captures` contain 425 distinct
ordinary Craft diagnostic operation IDs after excluding historic Craft-labeled
Recycling 1229930 and Radiant Shatter 1280394. There are 322 `Unknown reagent
allocation` and 103 `Inputs have not settled` diagnostics. All say
`allocationKnown=true`; none retains the allocation or schematic. That boolean
means only that the operation context received a table, not that the allocation
passed validation. The same sources retain 39 successful ordinary Evercore Shade
crafts (recipe 1229863, build 70783). Ordinary crafting is not uniformly broken.

Known rejected capture revisions are 4 and 5, not 6. The failing revision-5
commit `ecd189a794a8b2c0318389766638b36cf2416e81` has the same allocation parser
as that main. This is not proof of the exact present-client failure: the missing
historical request/schematic prevents a faithful replay. Do not infer an
allocation from overlapping bag windows or borrow an older successful cast's
allocation for a rejected cast. The separate Shatter repair is unchanged.

Representative evidence:
- `2026-11-07-disenchant-108-export-freeze/export-page-1.json`, operation
  `Cast-3-3883-0-108241-1229863-002E6F7364`, retains an actual typed Evercore Shade
  receipt and an allocation rejection, but not the allocation.
- `2026-11-07-pr49-82-skill-194-update/savedvariables-review.json` confirms the
  39 successful crafts were already archived; no additional successes recovered.

## Additive diagnostic contract

Only rejected, generic ordinary `Craft` captures receive `craftAllocation`.
Salvage definitions and static conversion paths are excluded. Successful records,
coverage semantics, current error messages, acceptance rules and recorder study
revision are unchanged. Diagnostic schema version is independently `1`.

The subrecord contains:
- `version` and `requestState`: `observed` or `missing-or-expired`. An observed
  request with nil allocation differs from an empty observed allocation table.
- `allocation`: the original observed request's sequential allocation entries,
  projected to slot index, quantity and reagent item ID, before the existing
  capture copy filters invalid values.
- `schematic`: only native reagent slot indices, required flags, required
  quantities and allowed reagent item IDs, snapshotted at capture start before
  the existing capture copy. It does not contain the full recipe API response.
- `failure`, only when the final reason is `Unknown reagent allocation`: the
  exact parser rejection branch (`invalid-allocation-entry`, `item-not-in-slot`,
  `required-quantity-mismatch`, `unallocated-required-slot`, or
  `unmatched-allocation-slot`). `missing-schematic` is an internal defensive
  return; normal generic capture requires a schematic and does not start without
  one. A prior transient parser result does not label a later different failure.

The parser still operates on its original copies, not on this lossy diagnostic
projection. Limits never impose a new limit on accepted allocations. Legacy
malformed-container parser behavior is not changed by this diagnostics patch.

## Data minimization, bounds and unknowns

There are at most 16 allocation entries, 16 schematic slots and 8 allowed reagent
entries per slot. Traversal stops at the first absent sequential entry, matching
the parser's sequential view. An immediately present entry beyond a limit sets
`truncated=true`; the retained prefix is not represented as a full allocation.
Sparse entries beyond the parser's first gap are not traversed or reconstructed.

Only finite nonnegative numeric fields up to 2,147,483,647 and native booleans
are retained as values. Other values retain a fixed type/status marker, not
strings or arbitrary nested payloads. Negative/nonfinite, out-of-range, missing,
secret and wrong-type states are distinguishable. Unknown native fields are
ignored. Native secret values are never serialized. Empty retained arrays export
as JSON arrays, not objects.

The added subtree is bounded below 32 KiB per diagnostic by its fixed caps and
allowlisted fields; the unchanged 50-diagnostic cap bounds the additional
retained data below 1.6 MiB even for maximal pathological snapshots. Typical
single-slot diagnostics are much smaller. This bounds only the **new** subtree;
existing context/receipt/bag snapshots and native-input copies have their prior
behavior and limits. This patch does not claim to harden all legacy capture data.

No new character/account identifiers, order/customer IDs, GUIDs, hyperlinks,
recipe names, arbitrary strings or extra API reads are introduced. Raw request
and native schematic mutations after observation/start cannot change the stored
projection. Full/latest export snapshots are detached and preserve deepest fields.

## Validation and limits

`tests/test_craft_allocation_diagnostics.lua` exercises original-main failing
preservation, parser discriminators, mutation isolation, missing/malformed
values, unknown native fields, secret markers, array limits, >16 valid allocation
entries, unchanged successful/default allocations, stale-reason isolation,
customer/recraft boundaries, 50-row retention and export snapshot depth.

`tests/test_craft_allocation_compatibility.lua` runs actual synthetic event-path
successes, rejections and refunds. Running the same fixture on original main and
this change produces byte-identical complete exports after removing only the
new diagnostic field. This checks contexts, receipts, coverage and existing
record data, not just a helper's return value.

`tests/test_craft_allocation_diagnostics.py` checks the Lua-produced JSON's bounds,
allowlist, empty arrays and deep fields, then an actual portable zlib/base64
roundtrip through the existing offline decoder. This is not live WoW native-codec
validation. All three tests are in `tests/run.sh`.

No historical acceptance failure is claimed reproduced. Synthetic tests establish
the information-loss defect and preservation behavior only. A small targeted
actual-client pilot may eventually supply the missing request/schematic before
an allocation-rule fix is proposed. Do not request bulk collection or declare
ordinary Craft repaired on the strength of these tests.
