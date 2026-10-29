# Loot Liquidator

This is the consolidated **0.10.0-alpha3 test candidate**, not an approved production release. It retains PR #10's mechanics integration. In-game QA is still required; back up LootLiquidatorDB before installation.

Install only the `LootLiquidator/` folder into the Retail client's `Interface/AddOns/`. Do not copy the repository root or developer files into the addon folder. CI produces a manifest-only test ZIP.

The build-time research snapshot is `database/research/itemdb.lua` (schema 0.2.0, 1,018 admitted mappings). It contains original evidence, complete labelled working estimates and reviewed mechanics exports. Its exact source revision and checksum are recorded in `database/research-itemdb-source.json`.

The addon loads the generated `LootLiquidator/ItemDBRuntime.lua`, plus immutable frozen TSM and optional legacy references. Source weights are preferences, not scientific confidence. Unknown or assumed working values cannot supply live economic estimates. The reviewed registry currently supplies zero real numeric mechanics; no skill/bonus scaling is invented.

Executable profession and personal patch rules require verified numeric status, explicit execution approval, independent review, distinct source claims, evidence confidence of at least 90, and existing identity/build/context checks. Partial output adjustments cannot qualify as a complete character valuation.

Commands: `/ll settings`, `/ll status`; recording: `/ll craftstats`, `/ll craftstudy LABEL`, `/ll craftexport`, `/ll craftbaseline`. See docs/craft-recording.md before capturing studies.

Build and validate with Lua 5.1 and Python 3:

```
lua5.1 tools/compile_itemdb.lua LootLiquidator/ItemDBRuntime.lua
bash tests/run.sh
python3 tools/package_addon.py dist/LootLiquidator-test.zip
```

Research continues on its own branch. Its accepted estimator repairs and the reviewed registry export are reconciled into a pinned snapshot before the addon is rebuilt. Research data and test tools remain outside the distributed package.

See RELEASE-STATUS.md for the integration sources and remaining client checks.
