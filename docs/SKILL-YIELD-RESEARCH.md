# Skill, output quality and the addon research pipeline

Reviewed 2026-11-06. This investigation separates **how many materials an operation
produces** from **which quality rank those materials have**. The available
numerical rules support quality selection much more strongly than a universal
increase in material count per point of skill.

## What was found

Current [CraftSim quality calculation](https://github.com/derfloh205/CraftSim/blob/e15fb18c1004b2f373ee3247b2ade0b917fbea69/Modules/RecipeInfo/RecipeInfo.lua#L58-L69)
uses skill thresholds. For a two-quality recipe, the high-quality threshold is
the recipe difficulty; quality is 1 below that threshold and 2 at or above it.
Its optional breakpoint offset is a workaround, not a universal extra point of
required skill. Three- and five-quality recipes have different thresholds; they
are not silently treated as Midnight's two-quality recipes.

The primary [Midnight prospecting report](https://us.forums.blizzard.com/en/wow/t/ever-gonna-fix-horrible-gemdust-drop-rate/2316717)
describes silver outputs below the displayed requirement and gold gems, glass and
stone after equipping gear and reaching 366 skill against a displayed 365
requirement. It does not identify every input rank or provide a controlled output
count comparison. **365 is not a hardcoded rule for every ore.**

[Blizzard's profession API definitions](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_APIDocumentationGenerated/TradeSkillUITypesDocumentation.lua#L170-L190)
expose operation skill, quality and quality boundaries. Its own profession UI
queries a salvage operation with the selected input item's GUID. An operation
query with an empty allocation and no target cannot establish the result for a
particular herb or ore quality.

For milling, published historical TWW observations include output-quality bands
0–252, 253–504 and 505+, and quantity estimates that differ by both herb rank and
pigment rank. Those observations cannot be substituted for current Midnight
quantity rules. The current [Midnight milling discussion](https://www.reddit.com/r/woweconomy/comments/1roocmn/)
also reports a quality threshold rather than a measured linear pigment increase.

For disenchanting, the [TWW three-batch comparison](https://www.reddit.com/r/woweconomy/comments/1f1l4i2/)
reports roughly the same total dust per item across setups, with a changing
rank distribution. Gear, race and skill differ together, and the reported rank
"rates" do not provide a complete probability model. The investigation retains
those observations, rather than inventing a per-skill quantity coefficient.

Detailed source records, numerical observations and limitations are retained in
`research/mechanics/skill-yield-*-2026-11-06.json`.

## How the findings reach the addon

`database/research/skill-quality-rules.json` is the reviewed source export.
`tools/skill_quality_to_rules.py` validates it and produces
`database/skill-quality-rules.lua`. The normal ItemDB compiler embeds the usable
rules, their sources and held findings in `LootLiquidator/ItemDBRuntime.lua`.
The generated-file check runs with the full test suite.

The executable scope starts with Midnight prospecting and milling and explicitly
identified two-quality output families. Ordered output ranks are recorded with
sources; the older `rankIDs` arrays are unordered sets, not rank mappings.
For example, Crystalline Glass has the reverse numeric order: its primary
[refining recipe](https://www.wowhead.com/spell=1307462/refine-crystalline-glass)
identifies 242787 as rank 1 and 242786 as rank 2.

The client obtains the exact input's operation information while the player's
profession is available. A qualified snapshot includes the recipe, input item
and quality, expansion, build, observation time, no-concentration state and
operation quality boundary. A hypothetical profile can compare its effective
skill with that measured boundary. Stored information is character-specific;
wrong-input, wrong-build, stale or incomplete snapshots do not select a rank.

Quality selection runs after evidence blending and before any manual benchmark
bonus. It changes an aggregate family's output item ID and its auction price,
while retaining the study's expected total units. It does not sum unrelated
rank-specific studies, add unlocked diamonds, fill unknown yields, or turn a
quality rule into more produced materials. Rule confidence caps the derived
estimate; those caps are provisional source-review judgments, not measured
probabilities of accuracy.

Historical quantity formulas and unquantified specialization procs are retained
with reasons they cannot currently execute. Disenchanting does not inherit the
prospecting or milling quality model.

The compiled data contains usable aggregate expectations for seven prospecting
inputs and now includes a sourced calculator total for eight Midnight herb/rank
inputs. Powder, Argentleaf and Sanguithorn can use their exact-input quality
thresholds; Mana Lily retains a family estimate while its rank order remains
disputed. These pigment totals are low-confidence model estimates, with no
measured sample size. See [the pigment and enchanting follow-up](MIDNIGHT-MATERIAL-YIELDS.md).

## Checking it in game

Open the relevant Midnight profession with a matching ore or herb in the bags so
the addon can read its exact operation. Choose Simulated and open Advanced.
Use Reset to minimum, then vary Skill before specialization around the captured
threshold with the named specialization points at zero. A supported aggregate output
family should switch quality and price while its expected total quantity stays
the same. The tooltip labels the result **skill-based quality**. Then add a point
to a matching researched specialization and check that its skill bonus can cross
the same threshold without changing total material units.
