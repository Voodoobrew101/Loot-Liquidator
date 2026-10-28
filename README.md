# Loot Liquidator

World of Warcraft Retail addon for liquidation advice, profession processing, appearance/token recommendations, and optional TSM, ATT and BetterBags integration. It does not automatically sell, craft, disenchant or mail items.

Copy the **`LootLiquidator/` directory** into your WoW Retail `Interface/AddOns/` directory. That directory contains all runtime files and `LootLiquidator.toc`; the repository root is not the addon directory. Development sources and tests are not needed in the game installation.

During development, multiple databases are retained. `LootLiquidator/itemdb.lua` is the latest byte-for-byte **research-only** snapshot (976 records, schema 0.1.0). It is intentionally absent from the TOC because it returns a table rather than assigning the runtime namespace. The compatible active database remains `LootLiquidator/ItemDBRuntime.lua` (267 records, schema 1). The compiler targets the active database and does not overwrite the research snapshot. See [copy provenance and scaling audit](docs/profession-scaling-audit.md).

This branch is **0.10.0-alpha2**. In-game validation is pending. Back up `LootLiquidatorDB` before testing.

* `/ll settings`: source controls in **Database & Accuracy**; per-profession profiles below **Professions & Alts**. The compact roster retains its method dropdowns and character checkboxes.
* `/ll status`: version and integration status. Existing slash commands remain available.
* Source sliders express preferences, not confidence. Personal-only policy is available under Database & Accuracy → Observation policy.
* `/ll craftstats`: measured craft recording status. Start controlled studies with `/ll craftstudy LABEL`, export raw JSON with `/ll craftexport [page]`, and inspect empirical baselines with `/ll craftbaseline`. See [recording workflow and validation](docs/craft-recording.md) before collecting evidence or confirming an empty result.

Development (Lua 5.1 and Python 3):

```bash
lua5.1 tools/compile_itemdb.lua
bash tests/run.sh
```

The compiler needs no network or external packages. Reviewed records and executable mechanics can be added in `database/records.lua`. Historical input snapshots live under `database/sources/`; they are build inputs, never loaded in WoW. Research branches and their staged candidates are not automatically imported.

See [architecture, evidence policy and migration](docs/modernization.md) and [Retail QA checklist](docs/retail-qa.md).
