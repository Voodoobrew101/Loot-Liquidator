# Radiant Shatter uses a selected salvage target

The owner's revision-5 export preserves 50 rejected Radiant Shatter captures
(recipe1280394):42 reagent-consumption mismatches and eight unsettled-input
diagnostics. Each retains a distinct server result receipt for three R1 dust.
The character measured Enchanting64, bonus0, no specialization, no Concentration
and zero recorded Resourcefulness. This is a separate processing phase from
the unchanged104-skill disenchant batch earlier in the same study.

Radiant Shard is the input reagent; Radiant Shatter is the processing recipe
cast as a spell. The native UI passes its shard target to `CraftSalvage`
separately from ordinary recipe reagent allocations. Recording never requires
a profession skill-up. Whether a recipe awards skill and the skill value used
by an operation are distinct facts.

## Cause and repair

Revision5 observed the native target/GUID but registered only Engineering's
Recycling recipe as salvage. Radiant Shatter fell into the generic Craft path,
whose ordinary-slot allocation omitted the selected shard. It then rejected
the legitimate one-shard inventory change because it was absent from that
expected allocation. This was recorder bookkeeping, not evidence of failed
game casts or free results.

Revision6 registers Radiant Shatter as `Craft`, Enchanting, Midnight, one input
per operation. The existing native-list/target/GUID and typed-result path is
shared between verified salvage recipes, with their own methods and batch
sizes: Recycling1229930 consumes five; Radiant Shatter1280394 consumes one.
Eligibility still comes from the current client's salvage list and a learned,
enabled, own-character recipe. No shard item ID, probability curve or presumed
output tier replaces native input/output evidence.

Consecutive same-recipe salvage casts retain their individual typed receipts
until the shared bag change reconciles. Explicit Resourcefulness returns can
reduce net consumption to zero while preserving the one-input nominal cost.
Unsupported recipes, unknown targets, conflicting/duplicate result packets,
inventory interference and unmatched aggregate changes remain errors. Ordinary
Craft allocation checks are not relaxed. The offline validator accepts only
the two declared method/recipe/batch combinations for this reconciliation
contract; other Craft records cannot claim this evidence format.

The recorder revision change starts a fresh study when necessary after an
older blocked recording session. It does not reset or erase older records,
diagnostics, owner-confirmed aggregate reviews or coverage flags.

## Preserved evidence and validation

The original export, hashes and 50 native receipts are retained in
`research/integration/measured-captures/2026-11-07-pr49-radiant-shatter-diagnostics-update/`.
There are31 windows with exactly one shard removed and three dust added; the
other windows contain delayed/cross-cast inventory updates. Summing those
overlapping windows would incorrectly turn150 native dust units into153 or
assign six dust to one three-dust cast. They are useful regression evidence,
not a newly fabricated set of successful historical cast-log records or a
complete historical sampling denominator.

The focused regression replays the actual exported native receipts and tests
batched/delayed inventory, one-input nominal consumption, explicit refunds,
duplicate/conflicting packets, unverified targets and extra unmatched inventory
changes. The Python contract checks validate the generated records and reject
unsupported recipe/batch combinations and corrupt reconciliation evidence.
The complete existing Lua/Python suite also checks the unchanged Engineering
Recycling, Disenchant, export, coverage and valuation behavior.

No historical result ranks or counts are filled by guesswork, and no future
gameplay batch is required merely to exercise these already captured cases.
Other salvage recipes need their own verified definitions, input quantities
and side-reagent support before sharing the path; this is not a wildcard
approval of every item-processing spell.
