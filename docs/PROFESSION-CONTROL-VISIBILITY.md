# Profession control visibility

The Simulated editor shows researched controls for the selected profession,
expansion and game build. This includes sourced skill contributions and described
output effects whose exact yield curve is still unknown. Visibility does not
claim that every displayed point allocation has a numerical yield model.

`GetProfessionSimulationControlSupport` derives support from the same compiled
ItemDB rule and descriptive-effect families used by the resolver and tooltip.
It does not use a hardcoded list of visible specializations. The editor refreshes
that support when it opens or refreshes. Catalog membership alone does not
establish a researched skill or output effect.

## What qualifies

- A sourced specialization replacement or quantity effect with a compatible
  usable baseline.
- A specialization allocation that selects an existing measured reference.
- A sourced per-point skill bonus, including when its downstream yield curve is
  unquantified. The base-skill control remains editable for that simulated skill
  context. A skill bonus by itself does not establish a yield multiplier.
- A sourced description of a quantity or quality effect. Selected points and
  the unquantified effect are reflected in tooltip context; descriptive entries
  cannot execute numerical transforms.
- A skill control connected to a compatible quality threshold model or
  executable varying quantity model.
- An actual executable mechanic consuming a typed stat, percentage or buff and
  changing a quantity, probability, supported input saving or valuation. Fixed
  reference-context fields and operation duration alone do not qualify.
- A structured point or skill prerequisite needed to unlock a supported control.

Disabled, unsourced, malformed, mismatched-build or incompatible rules do not
advertise supported controls. Source preferences and profession access remain
separate choices. A supported quality model stays visible before its live exact
operation threshold is captured; the user can capture that information later.

Static specialization, descriptive-effect and quality entries explicitly scoped to client version
`12.1.5` remain usable on that version's hotfix builds at or above their evidence
build, `70783`. The evidence build remains recorded; it is not rewritten to the
running build. Both the control filter and the actual tooltip calculation use
the same scope check. Rules without this explicit version scope retain their
existing exact-build behavior. Earlier builds and other client versions do not
inherit these effects. Captured operation thresholds still require the exact
running build, character, recipe and input, and their existing freshness limit.

## Current effects

Midnight Enchanting shows **Skill before specialization**, **Disenchanting
Delegate**, **Dust Deliverer**, **Shard Supplier** and **Crystal Collector**.
Delegate contributes the sourced +1 skill per invested point to Midnight
equipment. Dust Deliverer adds its sourced +1 per point only to Uncommon
equipment, and Shard Supplier only to Rare equipment. Crystal Collector's +1
Epic-skill coefficient is a provisional inference from the primary DB2
effect/rarity-label linkage, not a number stated by its base tooltip. Build
70961 adds the resolved learning and milestone skill bonuses for these paths.
The [formula research report](DISENCHANT-FORMULA-RESEARCH-2026-11-19.md) records
the exact arithmetic and the still-unresolved material distribution formulas.

The three child branches have separate descriptive-only entries: increased dust
from Uncommon equipment, increased shards/additional materials from Rare
equipment, and improved crystal quality/additional materials from Epic equipment.
Tooltip notes/status distinguish these unquantified effects from calculated
yield changes. No proc chances, bonus quantities or unverified milestone
activation are invented. The existing full Delegate + Supplier allocation still
selects the separately measured rare-armor reference once, without another bonus
multiplier.

These descriptions come from the reviewed [Enchanting specialization guide](https://www.wowhead.com/guide/midnight/professions/enchanting-specializations)
and trait pages for [Disenchanting Delegate](https://www.wowhead.com/profession-trait/disenchanting-delegate-107649),
[Dust Deliverer](https://www.wowhead.com/profession-trait/dust-deliverer-107648),
[Shard Supplier](https://www.wowhead.com/profession-trait/shard-supplier-107647)
and [Crystal Collector](https://www.wowhead.com/profession-trait/crystal-collector-107646).

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
not get a slider simply because it exists in the tree. Known numeric
prerequisites remain controls when they enable a supported modifier. Existing
native slider behavior, drag continuity and profile selection are unchanged.

Validation covers current compiled data, inactive controls, compatible future
rules, field-specific stats, prerequisite dependencies, saved-value retention and
native editor refresh. Descriptive controls require scope, source lineage and
catalog-bound point caps, but cannot carry coefficients or execution fields.

The hotfix regression reproduces the missing specialization controls on the
installed `12.1.5.70961` client, then checks control visibility and actual
disenchant-reference, gem-replacement and skill-to-quality calculations on that
build. Native Settings tests exercise the same build, including point editing,
saved-value retention and the Advanced toggle. Stat and buff inputs remain
hidden where the compiled database has no executable formula consuming them.
