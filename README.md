# Loot Liquidator

**What should I do with this item?** Loot Liquidator answers that for every item in your bags, bank, Warband bank, guild bank and BetterBags. It puts a small letter on the item's icon, and hovering the item shows the gold value behind the advice.

It only gives advice. It never sells, mails, crafts or destroys anything for you.

> **Release:** 1.0.0. Back up your `WTF/Account/<name>/SavedVariables/LootLiquidator.lua` before installing.

## The letters

| Letter | What to do |
| --- | --- |
| **A** | Sell it on the Auction House |
| **V** | Sell it to a vendor |
| **D** | Disenchant it |
| **M** | Mill it (herbs) |
| **P** | Prospect it (ore) |
| **S** | Smelt it (ore) |
| **T** | Keep it: you or one of your alts is still missing its appearance |
| **?** | Not enough information to give an answer (rare) |

Gold recommendations compare the available options, including the Auction House's cut. The **T** appearance recommendation takes priority when you or an eligible alt can learn a missing appearance. Crafting, recycling and documented exchanges also appear as processing options in the tooltip; the generic **C** badge is retired.

## The tooltip

Hover an item to see the recommendation, then each processing method and its materials. The layout is:

```
Loot Liquidator: Vendor
Disenchant — Character (Confidence …%)                 total value
  100% [item icon] [quality icon] Dawn Crystal [1]      material value
Vendor                                                vendor value
```

The header contains the action, with no price appended to it. Each processing row shows the method, selected character and confidence, with its total value on the right. Each material row shows the drop percentage, item icon, native quality icon when applicable, colored item name, `[quantity]` or `[minimum-maximum]`, and value on the right. The same layout is used across processing methods.

**Confidence** reflects the evidence and assumptions behind an estimate. Existing reference estimates and low-confidence display estimates can complete missing tooltip percentages and ranges. These display fields never replace the expected quantities or prices used for gold calculations, and they do not rewrite recorded evidence. There is no `x` quantity fallback.

Every actual material row remains visible. An output prevented by a known skill, specialization or buff requirement shows `0%` and `[0]`; changing the relevant profile can activate it. Separate quality grades remain distinct. Rows can be sorted by value, drop chance, quantity, name, or database order.

**Reference tables and calculators** can be enabled or disabled under **Database & Accuracy**. Source selections still govern the processing estimates.

Choose how much you see under **Settings → AddOns → Loot Liquidator → Tooltips → Tooltip**:

- **Off** – no tooltip lines (the letters still show)
- **Recommendation** – one line
- **Alternatives** – every option with its gold value
- **Breakdown** – adds every material in the shared percentage, icon, name, quantity-range and price format.

## Settings worth knowing

Open them with **/ll** or from the game's Settings → AddOns.

- **Professions (Simulated)**: choose your character, a verified alt, or a manual skill/buff profile for processing. There are no arbitrary benchmark multipliers or world-drop previews.
- **Professions (Simulated) → choose a profession → Advanced**: controls are limited to supported item processing and its material quantities, quality or input savings. Editing a slider selects Simulated. **Reset to minimum** clears the simulation. World-gathering projections and unrelated profession controls are removed. See the [processing model notes](docs/PROFESSION-BASELINE-PIPELINE.md).
- **Researched skill effects**: Midnight prospecting and supported milling pigment families can select output quality from the exact recipe threshold, changing auction value. Open the profession with the input in your bags to capture that threshold; the hypothetical effective-skill slider can then cross it. Pigment totals use a labeled calculator estimate. Disenchanting research, personal observations and classified imports apply to matching expansion, rarity and armor/weapon groups. [Sources and research pipeline](docs/SKILL-YIELD-RESEARCH.md), [Midnight material yields](docs/MIDNIGHT-MATERIAL-YIELDS.md).
- **Badges & Colors**: turn letters on or off, move them, change size and colors, and **Include alts** (count alts who could use or process an item you can send them).
- **Tooltips**: the tooltip level above and material output sorting. The row layout is fixed.
- **Pricing & Actions**: the Auction House cut, and how much extra profit an auction or processing option needs before it is recommended.
- **Processing Research**: record your own disenchant/mill/prospect/smelt results so the numbers become yours. Buttons: **Export recorded results**, **Start new batch**, **Reset recorded results**, **Import** (results a friend exported) and **Remove imported results**.

## What it needs

- **TradeSkillMaster (TSM)** supplies Auction House prices. The addon still loads and uses available vendor values without it.
- **Optional:** BetterBags (letters in BetterBags).
- Retail World of Warcraft: Midnight (12.1).

## Install

Copy only the **LootLiquidator** folder into `World of Warcraft/_retail_/Interface/AddOns/`. Don't copy the rest of this repository.

## Your alts

Log in on each character once so the addon learns its professions and class. An alt is only counted for an item when that exact item can actually be sent to them (not soulbound or quest items).

## Reporting a problem

Please say which item, what letter and tooltip you saw, and what you expected. `/ll debug` lists troubleshooting commands if someone asks you for more detail.

---

## For developers

- Published source is on `main`. Build from a pinned source and research snapshot.
- After a WoW patch: [`AFTER_PATCH.md`](AFTER_PATCH.md) (a ready prompt for an AI helper, then step by step).
- Older notes (up to 0.10.0-alpha10) are in [`docs/DEVELOPER-NOTES.md`](docs/DEVELOPER-NOTES.md).
- Build and test (Lua 5.1 and Python 3):

  ```
  python3 tools/prepare_build_research.py
  bash tests/run.sh
  python3 tools/package_addon.py dist/LootLiquidator-test.zip
  python3 tools/verify_distribution.py dist/LootLiquidator-test.zip
  ```

- Third-party notices: [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
