# Loot Liquidator

This is the consolidated **0.10.0-alpha5 test candidate**, not an approved production release. It retains PR #10's mechanics integration. In-game QA is still required; back up LootLiquidatorDB before installation.

Install only the `LootLiquidator/` folder into the Retail client's `Interface/AddOns/`. Do not copy the repository root or developer files into the addon folder. CI produces a manifest-only test ZIP.

The build-time research snapshot is `database/research/itemdb.lua` (schema 0.2.0, 1,018 admitted mappings). It contains original evidence, complete labelled working estimates and reviewed mechanics exports. Its exact source revision and checksum are recorded in `database/research-itemdb-source.json`.

The addon loads the generated `LootLiquidator/ItemDBRuntime.lua`, plus immutable frozen TSM and optional legacy references. Source weights are preferences, not scientific confidence. Unknown or assumed working values cannot supply live economic estimates. The reviewed registry currently supplies zero real numeric mechanics; no skill/bonus scaling is invented.

Executable profession and personal patch rules require verified numeric status, explicit execution approval, independent review, distinct source claims, evidence confidence of at least 90, and existing identity/build/context checks. Partial output adjustments cannot qualify as a complete character valuation.

Commands: `/ll settings`, `/ll status`; recording: `/ll craftstats`, `/ll craftstudy LABEL`, `/ll craftexport`, `/ll craftbaseline`. See docs/craft-recording.md before capturing studies.

LootLiquidator pages hide and block Blizzard's shared Defaults button because its dialog offers a game-wide reset. The separate **Reset source weights** action changes only LootLiquidator's four evidence-source preferences. Game Settings and other addons retain their own Defaults behavior.

Alpha5 fixes the alpha4 Settings slider callback recursion. Dropdowns open their normal menus without left/right cycling arrows, including after page and selection refreshes. Existing preferences are preserved.

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
