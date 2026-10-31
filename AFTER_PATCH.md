# After a WoW patch: how to update Loot Liquidator

This file is for the owner and for whichever AI helps them. The owner doesn't need to code: copy the prompt in part 1 into a new AI chat, and the AI follows part 2.

---

## Part 1 — What the owner does

1. Start a new Claude chat **with the GitHub repo Voodoobrew101/Loot-Liquidator selected** (so it can save its work).
2. If the patch changed items (new expansion, new season, new gear), download Blizzard's item table from Wago and attach it to the chat (step 2.3 explains why):
   - Open https://wago.tools/db2/ItemSparse, make sure the build at the top is the new live Retail build, and use its CSV download button.
3. Paste this prompt:

> A new World of Warcraft patch is out. Update Loot Liquidator for it. Clone https://github.com/Voodoobrew101/Loot-Liquidator, check out branch `LootLiquidatorclaude-V0.1`, and follow `AFTER_PATCH.md` part 2 step by step. Read `claude/HANDOFF.md` sections 1–6 first for the rules (plain language, one question at a time, never claim in-game testing, push only to that branch). You may open pages on https://www.wowhead.com/ and https://warcraft.wiki.gg/ for research. If I attached an ItemSparse CSV, use it for step 2.3. Go.

4. When the AI says it's done, it gives you a ZIP file. Install it, play a bit, check the list it gives you, and if all is well upload the ZIP to CurseForge (part 3).

---

## Part 2 — What the AI does (in this order)

Work on branch `LootLiquidatorclaude-V0.1` only. One commit per step, message starting with `PATCH <version>:`. Run the full test suite before every commit (`claude/HANDOFF.md` section 5 explains how to run it without a real Lua install).

### 2.1 Set up

Follow `claude/HANDOFF.md` sections 4 and 5: clone, check push access, install the Lua stand-in, and run `tests/run.sh` once **before changing anything** so you know it passed to begin with.

### 2.2 Find the new game version

- Look up the new Retail interface number (6 digits, e.g. `120105` for 12.1.5) and build number. Good sources: WebSearch `warcraft.wiki.gg TOC interface <patch>` and `warcraft.wiki.gg Public client builds`.
- In `LootLiquidator/LootLiquidator.toc`, put the new number on the `## Interface:` line. Keep the previous number too if the old client is still live (comma-separated), otherwise replace it.
- In `LootLiquidator/Core.lua`, set `LA.targetInterface` to the new number.
- Bump `## Version:` in the TOC **and** `LA.version` in `Core.lua` together (they must match; `tests/validate_package.py` checks).

### 2.3 Refresh Blizzard item data (only if the owner attached an ItemSparse CSV)

Two files come from Blizzard's ItemSparse table. The sandbox normally can't download from wago.tools, which is why the owner attaches the CSV. **No generator script exists in the repo yet**: the first time, write `tools/generate_from_itemsparse.py` and commit it, so later patches only need to run it.

| File | What it holds | Exact format to keep |
| --- | --- | --- |
| `LootLiquidator/WagoClassEligibility.lua` | Which classes can use each item (class mask) | Header comment naming the build; `LL.ItemClassMasks = { [itemID]=mask, ... }` sorted by ID; `LL.ItemClassMasksBuild = "<build>"`. Only items whose mask isn't "all classes" |
| `database/sources/DB2Restrictions.lua` | Items that can't be disenchanted, plus "millable"/"prospectable" hints | Header comment with build, row counts and the bit values; `LL.ItemRestrictionsBuild`; ID lists for NO_DISENCHANT (`Flags_0` bit `0x8000`), Mill (`0x20000000`) and Prospect (`0x40000`). Copy the current file's layout exactly |

Rules:
- Read the CSV's column names first (`ID`, `Flags_0`, `AllowableClass` or similar). Don't guess them.
- Sanity check: almost every ID in the old files should still be in the new ones. If more than a few percent vanish, stop and tell the owner in one sentence; the CSV is probably the wrong build or table.
- `tests/test_client_regressions.lua` pins the build string (`12.1.7.70493`) and a few known items. Update the build string on purpose and say why in the commit; the known items (765 = Mill, 2770 = Prospect) should still pass.
- Then rebuild ItemDB (2.4), because `DB2Restrictions.lua` is compiled into it.

If no CSV was attached, skip this step and mention in your final reply that the "can't disenchant" list and class data are still from the old build.

### 2.4 Refresh the research data and rebuild ItemDB

```bash
git fetch origin implementation/five-agent-completion
python3 tools/research_v3_to_baselines.py --refresh
python3 tools/evidence_to_baselines.py
PATH="$PWD/tools/lua51-shim:$PATH" lua5.1 tools/compile_itemdb.lua LootLiquidator/ItemDBRuntime.lua
```

The research refresh also rebuilds the gear-token reward lists (C4b3), so new tier tokens the research team has recorded arrive with the same command. Read what each command prints (what it used, what it left out and why). Never hand-edit `ItemDBRuntime.lua` or the snapshot. If `tests/test_research_v3_baselines.py` fails only because a pinned number (Saronite, Aqirite) moved, update the pin and say so in the commit.

### 2.5 Check Blizzard API changes

- Search `warcraft.wiki.gg API change summaries <patch>` (also `Patch <patch>/API changes`).
- Compare against the APIs the addon uses: `grep -ohE "\bC_[A-Za-z]+\.[A-Za-z]+" LootLiquidator/*.lua | sort -u`. The ones that matter most: `C_Container`, `C_Item`, `C_TooltipInfo`, `C_TransmogCollection`, `C_TradeSkillUI`, `C_ProfSpecs`, `C_Traits`, and the Settings API (`Settings.Create…`, `Settings.Register…`).
- For each removed or renamed function the addon calls: fix it, keeping the old call as a fallback if both clients may be live. Add a small test with a stub where possible.
- Tooltip changes (`TooltipDataProcessor`) and bag frame changes (`NativeBags.lua`, BetterBags) break most often. Read their notes carefully.

### 2.6 New season or expansion content

- New tier tokens: follow tasks C4a–C4b in `claude/HANDOFF.md` (research lists in `database/research/tokens-*.json`, reached through the research team's export). Don't type token rewards straight into the addon.
- New herbs, ores or gear item levels with no data: they show a lower-confidence value or "?". That's expected. Add them to the research queue for the research team; don't invent numbers.
- New expansion: also check `Professions.lua` / `ProfessionModels.lua` for expansion lists (skill line IDs) and add the new one.

### 2.7 Test, package, hand over

```bash
PATH="$PWD/tools/lua51-shim:$PATH" bash tests/run.sh
python3 tools/package_addon.py dist/LootLiquidator-<version>.zip
```

- Push. GitHub runs the tests again (`.github/workflows/claude-branch-tests.yml`); check with `gh run list --repo Voodoobrew101/Loot-Liquidator --branch LootLiquidatorclaude-V0.1`. If GitHub warns about outdated actions (Node versions), bump `actions/checkout`, `setup-python` and `upload-artifact` to their newest major version.
- Send the owner the ZIP.
- Update `claude/HANDOFF.md` as section 6 step 7 says (session log, what to check in game, at most one question).
- **Never** say it was tested in game. Say "automated tests pass; needs an in-game check".

---

## Part 3 — In-game check and CurseForge upload (owner)

Before uploading, check in game:

1. The addon loads with no error pop-ups and isn't marked "out of date" in the AddOns list.
2. Letters show in your bags, bank and (if you use it) BetterBags.
3. Hover an ore, a herb and a green piece of gear: each shows a Loot Liquidator line with a value.
4. `/ll` opens the settings and the pages open without errors.

Then on CurseForge: your project → **Files** → **Upload File** → choose the ZIP, set the game version to the new patch, release type **Beta** (or Release once you're happy), paste a short changelog (the AI's "what changed" sentences are fine) → **Submit**.
