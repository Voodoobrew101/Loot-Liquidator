# Loot Liquidator

This is the consolidated **0.10.0-alpha10 test candidate**, not an approved production release. It retains PR #10's mechanics integration. In-game QA is still required; back up LootLiquidatorDB before installation.

Install only the `LootLiquidator/` folder into the Retail client's `Interface/AddOns/`. Do not copy the repository root or developer files into the addon folder. CI produces a manifest-only test ZIP.

The build-time research snapshot is `database/research/itemdb.lua` (schema 0.2.0, 1,018 admitted mappings). It contains original evidence, complete labelled working estimates and reviewed mechanics exports. Its exact source revision and checksum are recorded in `database/research-itemdb-source.json`.

The addon loads the generated `LootLiquidator/ItemDBRuntime.lua`, plus immutable frozen TSM and optional legacy references. Source weights are preferences, not scientific confidence. Unknown or assumed working values cannot supply live economic estimates. The reviewed registry currently supplies zero real numeric mechanics; no skill/bonus scaling is invented.

Executable profession and personal patch rules require verified numeric status, explicit execution approval, independent review, distinct source claims, evidence confidence of at least 90, and existing identity/build/context checks. Partial output adjustments cannot qualify as a complete character valuation.

Processing metrics are per the displayed recipe operation: probability means at least one of that material, min/max are positive quantities when it drops, and EV is average material units including zero-result casts. Gold comparisons divide the expected total by the operation's input count and use EV once. Alpha8 selects explicit ItemDB recipes/batches (including 20-herb mass milling), labels those units, preserves unknown ranges and marks provisional probabilities. Filled working estimates remain research previews; selecting ItemDB alone does not make missing evidence known or enable disabled legacy/TSM sources.

Alpha9 retires the old nearby-skill observation pooling, positive-only estimate writers, duplicate tooltip statistics and unused upgrade/rank/inspiration modifier settings. Complete cast logs supply personal estimates; tooltip samples come only from personal evidence that contributed to the final model. Reviewed mechanics execute directly from ItemDB under one approval gate. Frozen TSM/legacy references retain their exact values as opt-in static data; their old build-time formula generators are removed. Existing saved observations and preferences are preserved.

Alpha10 makes the recorder resolve explicit ItemDB recipes before generic craft classification. Capture validates the recipe's own input batch/quality/expansion, so BFA mass milling records twenty herbs as Mill even when old compatibility hints say five. Separate recipes remain separate; conflicting batches and bag-only outputs belonging to another recipe are rejected. Nominal inputs remain unchanged by reported refunds. Recording is independent of yield-source preferences; valuation still respects them. The pinned research integration branch was checked and remains at aca72a4.

Commands: `/ll settings`, `/ll status`; recording: `/ll craftstats`, `/ll craftstudy LABEL`, `/ll craftexport`, `/ll craftbaseline`. See docs/craft-recording.md before capturing studies.

LootLiquidator pages hide and block Blizzard's shared Defaults button because its dialog offers a game-wide reset. The separate **Reset source weights** action changes only LootLiquidator's four evidence-source preferences. Game Settings and other addons retain their own Defaults behavior.

Alpha5 fixes the alpha4 Settings slider callback recursion. Every slider uses Settings.CreateSlider, standard Blizzard step-slider dimensions, and the same optional ElvUI HandleStepSlider path as native Settings pages. Dropdowns open their normal menus without left/right cycling arrows, including after page and selection refreshes. Existing preferences are preserved.

Settings canvas controls use Blizzard Settings initializers and native widgets, with the existing optional ElvUI skin integration. **Show ?** sits beside **Show V on soulbound gear** below the color table. Profession pages use named expansion selectors, an effective-skill slider, Blizzard specialization/rank choices and captured character buff choices. Log into each character and open the relevant expansion's profession to cache its names; offline alts use only their own saved catalog. Buff choices are explicit simulations of captured helpful auras, not a complete profession-buff database. They do not cast spells or supply unverified yield bonuses. Simulations still require Manual participation to affect character context.

Profession **On** does not enable disabled evidence sources or fabricate missing quantities. Disenchant lookup includes exact-item research and compatible gear-pool records. When no numeric record qualifies, possible material identities can be displayed with unknown quantities and no economic value. Known Smelt options retain an unavailable/unknown-data explanation. Per-item no-disenchant exceptions remain authoritative; a separate **TSM General Info** breakdown is controlled by TSM.

Build and validate with Lua 5.1 and Python 3:

```
lua5.1 tools/compile_itemdb.lua LootLiquidator/ItemDBRuntime.lua
bash tests/run.sh
python3 tools/package_addon.py dist/LootLiquidator-test.zip
```

Research continues on its own branch. Its accepted estimator repairs and the reviewed registry export are reconciled into a pinned snapshot before the addon is rebuilt. Research data and test tools remain outside the distributed package.

See RELEASE-STATUS.md for the integration sources and remaining client checks.

ATT retirement is staged in alpha6: reviewed standalone token relationships compile into ItemDB, legacy cached relationships work without ATT installed, and manual ATT exports now retain reward/source metadata and coverage limitations. Run `/ll attcache`, `/ll tokenmigration`, then `/ll attexport PAGE`; direct observations remain `/ll tokenexport PAGE`. See [the migration workflow](docs/att-migration.md). ATT remains optional until reviewed coverage and real-client equivalence are complete.
