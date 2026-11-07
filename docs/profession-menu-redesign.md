# Profession menu redesign

Keep the individual profession pages. Choose a character, Simulated, Automatic,
or Don't show, then an expansion. The saved `@hypothetical` key remains compatible;
visible labels use Simulated.

Only controls with an executable researched output effect are displayed. This
includes working quality modifiers and structured prerequisites for those
modifiers. Other point, skill, stat and buff controls remain hidden, with their
catalogs and saved values retained. New compatible calculation rules restore the
controls automatically; see [control visibility](PROFESSION-CONTROL-VISIBILITY.md).

Simulated starts at editor-minimum skill with no optional specialization or buffs.
This is not a claim that zero skill meets a particular recipe's requirements.
Reset to minimum clears skill, points, stats and selected buffs. Scanned character
records remain separate. Selecting a real character shows its saved profession
and last captured base-recipe statistics in an expandable read-only section.

Expand profession/crafting stats, individual specialization trees, nested branches,
or buffs only when needed. Node sliders use Blizzard's point bounds, excluding
the separate unlock-entry rank. Crafting stats include Resourcefulness, Multicraft,
Ingenuity and Crafting speed; gathering pages offer Finesse, Perception and Deftness.
Ratings and percentages are independent simulated inputs, not a guessed conversion.
No stat is assumed relevant to every recipe or expansion.

Node hover tooltips show descriptions, recorded requirements, point limits and
Blizzard-supplied perk milestones. Structured known node/skill requirements are
enforced, and reducing a prerequisite clears invalid dependent points recursively.
The generic Blizzard condition APIs do not supply a complete stateless evaluator
for arbitrary simulated allocations. Scanned requirement text is retained and
unresolved requirements are visibly marked unknown; the real character's unlock
boolean is never reused to certify simulated access. This is an explicit remaining
data limitation, not a claim that all game prerequisites have been modeled.

Item tooltips can show the next approved researched skill breakpoint for their
exact recipe, input, expansion, quality and build. The option can be disabled on
the Tooltips page. Breakpoints from skill-factor tables identify model segment
boundaries, not a promised sudden yield jump. Missing formulas never create an
invented threshold or yield bonus. Base-recipe quality thresholds captured from
Blizzard are labeled separately from simulated results, and do not include optional
reagent choices.

Selected skill, points, buffs and typed stat values flow through the existing
manual profile and ProcessingPlayerConditions to the actual resolver. New research
can consume that context without rebuilding the controls. No yield coefficients
are introduced here. Unsupported profiles still use labeled unadjusted references.

## API provenance

Blizzard UI/API source references inspected:

- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ProfessionSpecUIDocumentation.lua
- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SharedTraitsDocumentation.lua
- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/TradeSkillUITypesDocumentation.lua
- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Professions/Blizzard_ProfessionsSpecializationsTemplates.lua
- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Professions/Blizzard_ProfessionsCrafting.lua

## Validation

Native Settings fixtures exercise expanding/collapsing trees, nested branches,
point thresholds and cascading reductions, stats, reset and scan isolation.
The actual database/engine/formatter fixture shows skill 0 versus 100 changing a
synthetic quote from 40 to 80 copper, with scoped breakpoint text. Synthetic
coefficients are test fixtures only. Stats, invalid inputs, capture of API
milestones and unlock-rank exclusion are tested separately. Full official addon
suite passes using actual Lua 5.1 via the existing Windows validation adapters.
No in-game visual or gameplay verification is claimed.
