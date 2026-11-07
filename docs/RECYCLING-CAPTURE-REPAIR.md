# Recycling capture and input discovery

PR49 follow-up, November 6, 2026. Existing disenchant capture and native export
popup changes remain part of the same PR.

## Recorded pilot and failure

The owner's two export pages contain 20 successful Recycling diagnostics for
recipe 1229930, classified as `Craft`. Sixteen report reagent-consumption
mismatches and four report unsettled inputs. Their distinct typed result
operations report 44 rank-1 Evercores: three one-unit, ten two-unit and seven
three-unit results. The context records Engineering skill 1–19, bonus skill 0
and specialization `none`.

Both pages and the derived intake/diagnostic files are retained under
`research/integration/measured-captures/2026-11-06-recycling-pilot/`. The old
diagnostics remain censored and are not turned into complete baseline records.
The regression replays their actual result payloads against synthetic,
independently checked input inventories and event timing. It proves the new
recorder path; it does not claim the old inventory history has been recovered.

## Runtime changes

- Recognize the learned Midnight Recycling salvage recipe explicitly, with its
  five-item batch and Engineering profession. Observe the actual selected item
  and inventory GUID from the player's salvage request.
- Capture input eligibility from `GetSalvagableItemIDs` at cast start. The recipe
  scan uses the complete returned list, including quality-specific IDs and
  items absent from bags. It does not hardcode a copied 41-name list.
- Show eligible inputs as Recycle options, including a clear unavailable reason
  when fewer than five inputs are held. A missing yield model shows Insufficient
  Data and supplies no invented value. Learned-recipe checks, alt access,
  binding, disabled-action and explicit tooltip-hide preferences still apply.
- Reconcile consecutive successful Recycling receipts against one aggregate bag
  change when updates cross cast boundaries. Preserve individual output counts
  and skill contexts. Never distribute a bag total among casts by assumption.
- Validate distinct result-operation IDs, nominal five-item targets and explicit
  refunds; allow returned inputs to fund later casts. Preserve actual completion
  time separately from inventory reconciliation time. Duplicates, cancelled next
  casts and long CreateAll requests are handled without duplicating outcomes.
- Preserve diagnostics and censor coverage when targets/receipts are missing,
  duplicates conflict, inventories are changed, or aggregate counts disagree.
- Export version3 target/reconciliation evidence through the existing copy
  popup. The Python validator requires all sequence members, consistent shared
  evidence, per-cast receipt totals and aggregate inventory totals.

The public API contract was checked against Blizzard's generated
[TradeSkill UI documentation](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_APIDocumentationGenerated/TradeSkillUIDocumentation.lua).
It defines `GetSalvagableItemIDs(recipeID)` and the item-target argument to
`CraftSalvage`. The five-item quantity is also shown by the owner's live recipe
window. These facts establish operation identity and inputs, not output rates.

## Verification

The new event fixture reads all20 original diagnostic receipts. Its worst delayed
ordering holds inventory changes until cast20 and still records exactly20
complete operations and44 Evercores. Separate cases exercise both quality IDs,
unowned inputs, stale/linked/unlearned/disabled scans, verified alt access,
nominal/net refunds including reuse, long batches, cancellation, duplicate and
unmapped typed results, missing targets/receipts and unrelated inventory changes.

The native popup fixture copies those records without altering their evidence.
The Python export validator stages the complete records in their actual skill
contexts; it rejects missing reconciliation members and fabricated counts.
The full `tests/run.sh` suite passes locally under Lua5.1. The official compiler
regenerates a byte-identical ItemDB; existing numerical mechanics and processing
baselines are unchanged. GitHub CI and its downloadable addon artifact are
checked against the published PR head before delivery.

Live-client event ordering remains to be confirmed with a fresh pilot after
installation. Open Engineering to scan its inputs, enable Record crafting and
processing results, click Start new batch, and export after results settle.
No recorded-results reset or typed command is required.
