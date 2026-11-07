# Direct disenchant capture repair

The November 6 owner export contains all 46 retained casts across two pages:
42 complete outputs, four unresolved operations (two older), and 50 retained
diagnostics. The new sessions comprise 44 casts: 42 complete and two unresolved.
All represented studies are censored. The original pages, contexts, studies,
diagnostics and operation IDs remain under
`research/integration/measured-captures/2026-11-06-disenchants/`.

## Why the batches were censored

The recorder marks a study censored after a successful cast cannot be attributed
cleanly. That protects rate denominators from selectively missing outcomes.
However, its attribution checks were also rejecting legitimate observations:

- 36 retained diagnostics say **Unmapped or unrelated output**. Collection
  depended on existing ItemDB conversion mappings and overlooked the separate
  expansion candidate catalog. Examples include Blackwater Helm -> Draenic Dust,
  and legacy gear -> Spirit Dust or Greater Cosmic Essence. Other diagnostics
  include extra outputs alongside crystals; an old whitelist cannot establish
  whether those extras are legitimate bonuses or unrelated bag changes.
- 11 say **Input item variants are ambiguous**. Having two different links for
  an item ID anywhere in bags rejected a cast, without checking which link's
  quantity actually decreased.
- Three say **Unverified disenchant input**. The collector reused the valuation
  eligibility gate. Ignore settings, stale external restrictions or missing
  equip-slot metadata could reject gear after the game had disenchanted it.

One such diagnostic censored the whole sampling frame. The export did not retain
each study's specific first reason, so it cannot establish the exact first cause
of every old flag. The diagnostic list is capped at 50 entries.

The clean-login path also used **Game build changed** as a generic closure reason
when a paused study was already censored or truncated. The supplied studies show
this message even on build 70783. This misleading message is corrected; actual
build changes still close a study without inventing a coverage gap.

## Recorder changes

The recorder reads actual item slots on LOOT_READY / LOOT_OPENED before autoloot
clears them and retains those slot observations. Repeated events describe one
window, not additional loot. A successful isolated disenchant must consume one
gear item, and all observed loot item quantities must match bag changes exactly.
This admits a previously unknown output or bonus without relying on an existing
yield model. A second loot window, altered slot contents, unrelated item gain,
missing expected loot, mixed input or inventory interaction still prevents a
complete sample. When a loot snapshot is unavailable, the compatibility path
also recognizes already catalogued expansion-wide disenchant material identities.

Bag snapshots retain counts and facts for each full hyperlink. A uniquely
decreased variant supplies the consumed item's level and identity; bag sorting
does not alter that comparison. A genuinely ambiguous variant remains flagged.
The successful game cast and actual consumed gear establish observed eligibility;
valuation preferences no longer veto the capture.

New diagnostics retain study ID, timing, success evidence, loot slots and the
first coverage reason. A one-time message points to **Processing Research >
Recording status**, which shows current-batch counts and any coverage issue.
The existing **Start new batch** button remains the normal workflow; no command
or data reset is required.

Expansion profession identity is selected using the input's expansion, not the
generic parent Disenchant spell. API skill placeholders of 0/0 stay unknown and
cannot overwrite a real skill cache. A real zero skill with a positive maximum
remains a valid measurement. No stale cached skill is relabeled live.

## Sharing the existing observations

`tools/capture_observations.py` validates both pages and deduplicates operation
IDs before generating `database/capture-observations.lua`. The official ItemDB
compiler includes these records. The current export contributes 38 exact-input
records from 42 unique complete casts. Every record retains build, source hashes,
operation references and observed positive stack histograms.

These are **observed output identities**. A censored study can still document
that a specific captured item produced a material; it cannot establish an
unbiased rate denominator. All probability, expected-quantity and guaranteed
bound fields therefore remain unknown. Positive stack histograms do not become
guaranteed ranges or numerical priors. Compiler assertions enforce that boundary.
Diagnostics and unresolved casts are preserved, never converted to zero yields.
Historical study flags and raw export bytes are unchanged.

For fresh full-page exports, the existing `tools/validate_craft_export.py`
continues to stage complete uncensored cohorts for numerical review with their
measured contexts. The recording fix does not authorize universal skill scaling,
raise confidence because of authorship, or retroactively clear old gaps.

## Validation

Event replay tests cover ordinary legacy materials, newly observed bonus outputs,
repeated loot events, per-link variant identity, sorting, snapshot fallback,
unrelated gains, missing outputs, inventory interactions, closure reporting, and
zero-skill API placeholders. Import tests cover complete-page requirements,
duplicate exports and contradictory operation identities. The full tests/run.sh
suite passes under Lua 5.1 with the current main-branch research and UI changes.
World of Warcraft event timing still requires a fresh in-game capture.

The native export popup from main commit `93068d2` is retained. A combined test
feeds five actual event-replay captures through that dialog's displayed copy
field, then checks the exact copied JSON with the existing Python validator and
baseline stager. All five complete uncensored test cohorts remain eligible;
loot slots, capture version, consumed variant level/link and diagnostic study
references survive unchanged. The 51-record popup fixture separately covers
literal link pipes in the new loot-slot evidence, Previous/Next navigation,
snapshot isolation, selection, Escape and optional ElvUI styling. No game renderer
or operating-system clipboard access is claimed by these deterministic tests.

The updated main-branch calculator generator also needed POSIX paths for source
archive identities and hashes on Windows. That portability correction reproduces
the existing generated calculator baseline byte-for-byte; it changes no values.

API references: Blizzard's shipped [loot frame implementation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/LootFrame.lua)
and [loot event documentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/LootDocumentation.lua).
