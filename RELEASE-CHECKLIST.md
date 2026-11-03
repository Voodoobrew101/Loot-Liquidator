# Before you upload Loot Liquidator to CurseForge

This list is for the owner. It takes about 20 minutes in game. Nothing here needs code.
Automated tests pass on every change; none of this has been checked in game yet.

## 1. Get the zip

- Each Claude session can hand you a ready zip (`LootLiquidator-<version>.zip`).
  It is also built automatically on GitHub every time the Claude branch changes
  (Actions tab, latest run, "Artifacts").
- The zip holds one folder, `LootLiquidator`. That folder goes into
  `World of Warcraft/_retail_/Interface/AddOns/`. Delete the old `LootLiquidator`
  folder first so no old files are left behind.

## 2. Check in game (tick each one)

**Loading**

- [ ] The game starts with no red error pop-up. (If you use BugSack or BugGrabber,
      look there too.)
- [ ] Type `/ll`: the settings open. The menu entry reads "Loot Liquidator v…" with the
      version number from the zip's name.
- [ ] Your old settings are still there (badge position, colors, tooltip level).

**Badges and tooltips**

- [ ] Open your bags: items have letters. Most have A, V, D, M, P or S; few have "?".
- [ ] Hover an ore or herb you can process: the first tooltip line says what to do and,
      if "price in the header" is on, a gold amount.
- [ ] Hover a piece of gear you could disenchant: it shows a disenchant value.
- [ ] Hover gear that can't be disenchanted (for example a holiday ring or a Delver's
      piece from The War Within): it never suggests disenchanting.
- [ ] Hover a raid tier token: it shows V or D with a gold value, or T if you're missing
      the look. **AllTheThings is no longer used** — this should work the same whether
      or not you have it installed.
- [ ] Turn the tooltip level to Off: the lines disappear, the badges stay.

**Other places**

- [ ] Bank, Warband bank and (if you use them) BetterBags and guild bank show badges.
- [ ] Settings → Processing Research: Export, Start new batch, Reset and Import buttons
      open without errors.

**With and without other addons**

- [ ] Works with TradeSkillMaster installed (auction prices show).
- [ ] Without TSM, the addon still loads and shows vendor values (no auction prices).

## 3. If something is wrong

Don't upload. Write what you saw (item name, what the tooltip said, any error text)
in `claude/HANDOFF.md` under "Owner feedback from the game", or tell the next Claude
chat. A screenshot of an error pop-up is the most useful thing you can send.

## 4. Upload

- Use the text in `CURSEFORGE.md` for the project description.
- Game version: Retail, the patch named in the TOC (`## Interface:` line in
  `LootLiquidator/LootLiquidator.toc`).
- Release type: start with **Alpha** or **Beta** until a few players have tried it.
- After a WoW patch, follow `AFTER_PATCH.md`.
