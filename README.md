# Loot Liquidator

The usable-data tooltip work is tracked in [PR #24](https://github.com/Voodoobrew101/Loot-Liquidator/pull/24), with [pass-2 findings](docs/usable-data-audit/PASS-2.md) and [actual offline token tooltip proofs](docs/usable-data-audit/token-tooltip-proofs.md). Pinned AllTheThings Retail references now supply exchange relationships and explicit costs through the compiler; ATT does not need to be installed. Attribution is retained in [ATT-LICENSE.txt](database/research/ATT-LICENSE.txt).

**What should I do with this item?** Loot Liquidator answers that for every item in your bags, bank, Warband bank, guild bank and BetterBags. It puts a small letter on the item's icon, and hovering the item shows the gold value behind the advice.

It only gives advice. It never sells, mails, crafts or destroys anything for you.

> **Status:** test version (0.11.0-claude). Back up your `WTF/Account/<name>/SavedVariables/LootLiquidator.lua` before installing.

## The letters

| Letter | What to do |
| --- | --- |
| **A** | Sell it on the Auction House |
| **V** | Sell it to a vendor |
| **D** | Disenchant it |
| **M** | Mill it (herbs) |
| **P** | Prospect it (ore) |
| **S** | Smelt it (ore) |
| **C** | Craft something with it |
| **R** | Recycle it |
| **X** | Exchange, combine or split it |
| **T** | Keep it: you or one of your alts is still missing its appearance |
| **?** | Not enough information to give an answer (rare) |

The letter is the option worth the most gold for you (with the Auction House's 5% cut taken off, unless you switch that off).

## The tooltip

Hover any item to see a short Loot Liquidator section, for example:

```
Loot Liquidator: Smelt 6g 87s
  Auction       6g 65s
  Prospecting   2g 72s   (Confidence 48%)
  Smelting      6g 87s   (Confidence 81%)
  Vendor          15s
```

**Confidence** is how sure the addon is about a disenchant, mill, prospect or smelt value. It goes up as more real results are known, including your own. Low-confidence values are still shown, because a best guess is more useful than nothing.

**Reference estimates** fill gaps from stored Retail conversion tables and sourced calculators. They are labeled provisional and do not replace usable research or recorded results. Turn them on or off under **Database & Accuracy → Reference tables and calculators**.

Under **Tooltips**, average output quantities are optional and off by default. Yield ranges read `[1-2]`. Material rows can be sorted by value, drop chance, average quantity, name, or database order.

Choose how much you see under **Settings → AddOns → Loot Liquidator → Tooltips → Tooltip**:

- **Off** – no tooltip lines (the letters still show)
- **Recommendation** – one line
- **Alternatives** – every option with its gold value
- **Breakdown** – also lists the materials behind each option, with drop chance and amount

## Settings worth knowing

Open them with **/ll** or from the game's Settings → AddOns.

- **General → Show rates for**: whose profession skill sets the numbers: you, one of your alts, or a made-up "what-if" profile.
- **Badges & Colors**: turn letters on or off, move them, change size and colors, and **Include alts** (count alts who could use or process an item you can send them).
- **Tooltips**: the tooltip level above, plus **Show price in the header**.
- **Pricing & Actions**: the Auction House cut, and how much extra profit an auction or processing option needs before it is recommended.
- **Processing Research**: record your own disenchant/mill/prospect/smelt results so the numbers become yours. Buttons: **Export recorded results**, **Start new batch**, **Reset recorded results**, **Import** (results a friend exported) and **Remove imported results**.

## What it needs

- **TradeSkillMaster (TSM)** is needed for Auction House prices. Without it, the addon still works, but it can only compare vendor values.
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

- Work happens on branch `LootLiquidatorclaude-V0.1`. The plan, decisions and session log are in [`claude/HANDOFF.md`](claude/HANDOFF.md).
- After a WoW patch: [`AFTER_PATCH.md`](AFTER_PATCH.md) (a ready prompt for an AI helper, then step by step).
- Older notes (up to 0.10.0-alpha10) are in [`docs/DEVELOPER-NOTES.md`](docs/DEVELOPER-NOTES.md).
- Build and test (Lua 5.1 and Python 3):

  ```
  lua5.1 tools/compile_itemdb.lua LootLiquidator/ItemDBRuntime.lua
  bash tests/run.sh
  python3 tools/package_addon.py dist/LootLiquidator-test.zip
  ```

- Third-party notices: [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
