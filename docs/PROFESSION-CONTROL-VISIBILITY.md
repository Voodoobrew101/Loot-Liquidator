# Profession control visibility

The Simulated editor shows inputs that can reach an executable output calculation
for the selected profession, expansion and game build. Storing a value in a
context or catalog does not make it a working output modifier.

`GetProfessionSimulationControlSupport` derives support from the same compiled
ItemDB rule families used by the resolver. It does not use a hardcoded list of
visible specializations. The editor refreshes that support when it opens or
refreshes, so a newly supported rule can restore a previously hidden control.

## What qualifies

- A sourced specialization replacement or quantity effect with a compatible
  usable baseline.
- A specialization allocation that selects an existing measured reference.
- A skill control, or a per-point skill bonus, connected to a compatible quality
  threshold model or executable varying quantity model. A skill bonus by itself
  does not establish a yield effect.
- An actual executable mechanic consuming a typed stat, percentage or buff and
  changing a quantity, probability, supported input saving or valuation. Fixed
  reference-context fields and operation duration alone do not qualify.
- A structured point or skill prerequisite needed to unlock a supported control.

Disabled, unsourced, malformed, mismatched-build or incompatible rules do not
advertise working controls. Source preferences and profession access remain
separate choices. A supported quality model stays visible before its live exact
operation threshold is captured; the user can capture that information later.

## Current effects

Midnight Enchanting retains Disenchanting Delegate and Shard Supplier because
their full allocation selects the separately measured rare-armor reference.
Dust Deliverer, Crystal Collector and base skill currently have no executable
disenchant output model, so their controls are hidden.

Midnight Jewelcrafting and Inscription retain the supported skill/point inputs
that can change output quality. TWW Jewelcrafting retains the four Gem Finding
replacement branches. Context-only crafting and gathering stats and buffs stay
hidden until a supported numeric effect consumes them.

## Preserved data and layout

Filtering does not rewrite manual profiles or scanned character data. Hidden
point, skill, rating, percentage and buff values remain stored. If the effect
returns, its control loads the saved value. Reset to minimum remains the explicit
action that clears the simulation.

The full profession catalog remains intact for research and future controls.
Only headings needed for a visible descendant are displayed; an ancestor does
not get an inactive slider simply because it exists in the tree. Known numeric
prerequisites remain controls when they enable a working modifier. Existing
native slider behavior, drag continuity and profile selection are unchanged.

Validation covers current compiled data, inactive controls, compatible future
rules, field-specific stats, prerequisite dependencies, saved-value retention and
native editor refresh. In-game layout verification remains pending.
