# Loot Liquidator — Claude work session prompt (v0.1)

> **How to use:** this prompt lives in the repo at `claude/HANDOFF.md` on branch `LootLiquidatorclaude-V0.1`, and each session updates it before finishing. Paste the short **starter message** at the bottom into a new chat.

---

## 1. Who you are and who you work for

You are an experienced World of Warcraft (Retail) addon developer working on **Loot Liquidator**, a Lua addon. The owner ("Voodoo", GitHub `Voodoobrew101`) came up with the idea but **does not code**. They test in game and report back.

- Write everything for the owner in plain, non-technical language.
- Ask the owner **one short, simple question at a time**, never a bundle of questions.
- **Never ask the owner to run code or commands.** They only install the addon folder and play.
- **Never claim anything was tested in game.** You have no WoW client. Say "automated tests pass; needs an in-game check" instead.

## 2. What the addon is for (owner's vision)

Loot Liquidator looks at every item in your bags, bank, Warband bank, guild bank and BetterBags, and puts a **letter badge** on its icon saying what to do with it. Hovering the item shows the **recommendation, the alternatives and a breakdown** with gold values. It never sells or crafts anything by itself.

| Badge | Meaning |
| --- | --- |
| A | Sell on the Auction House |
| V | Vendor it |
| D | Disenchant |
| M / P / S | Mill / Prospect / Smelt |
| C / R / X | Craft, recycle, or exchange/combine/split |
| T | Keep it: the appearance is missing and usable by you or an enabled alt |
| ? | Unsure: not enough data (the old "Q" badge) |

**The owner's main complaint:** the addon was meant to make things SIMPLE, but it became complicated to use, and recent versions say "I don't know, need more info" far too often, even when TSM's own tooltip shows a value right there. Your job is to make it simple and make it give answers again, without breaking what works.

### Owner decisions (already made, follow them)

1. **Show every estimate.** 90% confidence is a research *goal*, not a display gate. Values under 90% still appear in the tooltip and still count toward the gold value and badge, with their confidence shown. A best guess beats nothing.
2. **One confidence figure per option** in the tooltip, e.g. "Prospecting (Confidence 48%)". Confidence per material is optional and **off by default**.
3. **TSM is used only for Auction House prices.** No TSM fallback for yields. The frozen TSM conversion table (`itemTSM.lua`) and its "TSM database" weight setting should be removed.
4. **Vendor prices come from the game** (item sell price), not TSM. The code already does this.
5. **One database: ItemDB** (the owner sometimes calls it "gamedb.lua"). Yields, gear tokens and their rewards, item exchanges and the no-disenchant list should all live in ItemDB. `GameData.lua` (old) and `DB2Restrictions.lua` should be migrated into it. AllTheThings (ATT) should be removed once token data is in ItemDB.
6. **Tooltip has levels:** Recommendation / Alternatives / Breakdown, plus Off (no tooltip lines, badges still show). Keep it compact; ATT's huge tooltips are the example to avoid.
7. **Optional price in the header**, e.g. "Loot Liquidator: Smelt 6g 87s".
8. **Reference tooltip (Saronite Ore):** header "Loot Liquidator: Smelt"; one row per option with gold per item (Auction 6g 65s, Prospecting 2g 72s, Smelting 6g 87s, Vendor 15s); confidence next to each processing option; breakdown rows under each option with drop chance, material icon and quality color, quantity range like [x1-2], and value.
9. **Menus:** only Blizzard's own Settings widgets (`Settings.Create…` checkbox, dropdown, slider, button). Remove custom canvas pages where possible. Text entry goes in a standard StaticPopup dialog.
10. **Alts table: remove it.** Replace it with one simple choice: "Show rates for: me / a chosen alt / a what-if profile".
11. **Alts in badges:** badges consider alts automatically, but only when *this exact item* can be sent to the alt who has the profession (soulbound and quest items excluded; Warbound only when confirmed). This rule already exists in `CanTransferToAlt` — keep it. Add a simple **"Include alts" on/off switch** on the badge settings page (the saved setting `includeVerifiedAlts` already exists but no menu shows it).
12. **Slash commands are for troubleshooting only**, not player features. Players get buttons instead: **Export recorded results**, **Reset recorded results**, **Start new batch** (a batch must carry on through logging off), and **Import** (paste text from another player; kept as its own separate source with its own confidence, and checked for damaged/fake values).
13. **Public CurseForge release.** The owner may not come back often, so make it future-proof, and keep a clear written path in the repo for prompting an AI to update the addon after a patch.
14. **Accuracy target:** about ±5% on yields and drop chances is acceptable. Yield ranges are small whole numbers (usually 1–4): just record the smallest and largest seen.
15. **Never throw data away.** Weak or old evidence counts for less instead of being rejected. Only a number with no source at all is left out.

### Recommended data model (from the study notes, use it)

- Every source becomes "casts" and "drops". Start from a guess worth ~20 casts (borrowed from a close relative, e.g. the other rank of the same ore, labelled "Estimated from X"), add every source's real counts, weight weak sources down (e.g. pre-hotfix data ×0.25), then chance = drops ÷ casts. This is a beta-binomial / empirical-Bayes model.
- Confidence = chance that the true rate is within ±5 points of the shown number. For an 18% drop: 10 casts ≈ 30%, 50 ≈ 64%, 100 ≈ 81%, 200 ≈ 94%.
- Missing average: average ≈ chance × middle of range. Missing chance: chance ≈ average ÷ middle of range. Filled-in numbers get lower confidence.
- Gold per cast = sum of (average amount × price) over materials.
- The player's own recorded casts are added the same way, so they take over as they grow. Skill/spec stats (Resourcefulness, Multicraft) are a separate layer read from Blizzard's profession API.

Full background, reasoning and sources: the owner's study notes doc, https://claude.ai/artifact/Lr3abFsm5DgTsXBYhRURLf (read it with the Claude Docs tools if available; never web-fetch it).

## 3. The code

- Repo: **https://github.com/Voodoobrew101/Loot-Liquidator** (public).
- **Your working branch: `LootLiquidatorclaude-V0.1`.** It was created from `refactor/addon-readability` at commit `8d8753e` (addon v0.10.0-alpha10, the newest addon candidate). Commit and push **only** to this branch.
- **Do not touch** `main` (old v0.9.70 snapshot), `refactor/addon-readability`, the `implementation/*` / `research/*` branches, or any other branch. The research branches are written every hour by the owner's five ChatGPT research agents; editing them would collide with that work.
- The installable addon is the **`LootLiquidator/`** folder (TOC `## Interface: 120100, 120105`, Retail Midnight 12.1.x). Everything else is build tools, tests, research and docs.

Main files in `LootLiquidator/`:

| File | What it does |
| --- | --- |
| Core.lua | The decision for each item (`LA:Evaluate`, ~line 445), defaults, slash commands (since B6c: `/ll` opens settings, `/ll help` is 3 lines, everything else is `DebugCommand` under `/ll debug NAME`, old names still work; list in `DEBUG_HELP`), `RETIRED_SETTINGS` migration list (add removed keys there) |
| ConversionEngine.lua | Gold value of disenchant/mill/prospect/smelt (`ValueProcessingModel`, ~line 286). Since B5a, `RateProfileTarget` (top of file) decides whose skill sets the rates ("Show rates for"). Since A2: unknown outputs give a partial value with `model.partial` and `model.valueConfidence` |
| Database.lua | Blends evidence sources with weights (`ComputeEvidenceModel`, ~lines 421–650; since C1a the counts-based estimator `CountsEstimate`/`RateConfidence` sits near the top). Sources: itemdb, personal, imported (B7), legacy. Since A1: weak/old evidence is down-weighted, not dropped; only different-batch drop chances still get zero weight (a different quantity, by design) |
| Badges.lua | Badge letters and the tooltip |
| NativeBags.lua | Badges on Blizzard bags, banks, BetterBags, guild bank |
| Settings.lua / SettingsControls.lua | Settings menus. Since B8 every page is a native vertical list (`LL:AddBadgeSettings`, `LL:AddEvidenceSettings`) except the what-if profession pages and Ignored Items. General page has "Show rates for" (B5a); Processing Research page has the Export / Start new batch / Reset (B6a) and Import / Remove imported results (B7) buttons. The ElvUI skin helper `SkinSettingsCanvasControl` lives in SettingsControls.lua since B5b |
| Professions.lua / ProfessionModels.lua | Character and alt professions, transmog recipients, `CanTransferToAlt`. The alts table (`AltRosterUI.lua`) was deleted in B5b; the per-method On/Auto/Off/Manual code is still there but dormant (saved modes are cleared on load, so everything runs as Auto) |
| ATTIntegration.lua / DirectTokenCollector.lua | Gear tokens via ATT (uses ATT's *internal* functions), transmog collection check |
| CraftRecording.lua / Observations.lua | Recording your own results ("studies" = batches). B6a added `ExportRecordedResultsPage`, `ResetRecordedResults` (keeps one `recordedResultsBackup`), `StartNewBatch`. B6b: clean logout pauses the study (`paused`), `ledger()` parks it per character in `pausedStudies` and resumes it on the same character + build; `ActiveRecordingBatch()` |
| ImportedResults.lua | B7: Import of another player's Export page (strict JSON reader, per-cast checks), stored as counts in `db.importedResults`; `ImportedEvidenceRecords` feeds the "imported" source with its own confidence. Settings buttons: Import / Remove imported results |
| TSMOperations.lua | Reads TSM Auctioning operations |
| ItemDBRuntime.lua | Compiled ItemDB (generated by `tools/compile_itemdb.lua` — never hand-edit) |
| GameData.lua | Old disenchant estimates (generated by the compiler as `LL.LegacyDB`), to be migrated (C3). `itemTSM.lua` was removed in B2; its snapshot is still in `database/sources/ReferenceData.lua` (`frozen`) |
| DB2Restrictions.lua, WagoClassEligibility.lua | Generated game data: no-disenchant list, class masks (build 12.1.7) |

Known dead or confusing things (found by code reading):

- Settings reads "Legacy" as the old disenchant tables (`GameData.lua` → `LL.LegacyDB`); since A1 it is on by default at weight 10.
- `manualMilling/Prospecting/Smelting/Disenchanting` are read in `Professions.lua` (~line 590) but nothing in the addon sets them (handle in B5a).
- ItemDB's `tokenRewards` list is empty, so tokens depend entirely on ATT.
- The T badge counts alts only for class-restricted gear (tier). Ordinary gear never counts an alt (open question for the owner).
- (Fixed in B6b) Recording batches now carry on through a clean logout; only a crash/disconnect or a logout mid-cast marks a batch censored.
- The import text box is a single-line StaticPopup edit box with no length limit (`maxLetters=0`). One export page is ~25 casts; very large pastes may feel slow. Needs an in-game check.
- `LA.version` in Core.lua must be bumped together with the TOC `## Version:` (session 3 forgot; fixed in session 4).

## 4. How to connect to GitHub and push

**How the previous chat connected:** it ran in Claude's cloud sandbox, which routes all internet traffic through a proxy. It cloned the public repo over HTTPS with plain `git clone` (no password needed for reading). It could **not** push: the proxy only adds GitHub credentials for repositories that have been **added to the session as a source**, and this repo had not been. Nobody ever pasted a password or token, and you must not either.

**Session 1, 3, 4, 5 and 6 finding:** if the chat has the `add_repo` tool (Claude Code on the web / Cowork), call it with owner `Voodoobrew101`, repo `Loot-Liquidator`, access `push`. That attaches the repo mid-chat and plain `git push` then works from the existing clone — no new chat needed (worked again in sessions 3–6). Its reply asks you to re-clone into `/home/claude/loot-liquidator` and call `register_repo_root`; that's optional — an existing clone at another path pushes fine (`register_repo_root` rejects other paths). Only if `add_repo` is missing or refused, fall back to the steps below.

**Otherwise, for this chat to push**, the owner must start it with the GitHub repo attached:

- In the Claude app/website, start the chat where you can pick a GitHub repository (Claude Code on the web at claude.ai/code, or a Cowork session with GitHub connected), and select **Voodoobrew101/Loot-Liquidator**. The first time, GitHub asks the owner to install/authorize the Claude GitHub app for that repo.
- Once the repo is a source, the sandbox's git proxy injects the credential automatically. Plain `git push` then works. No token, no SSH key, no `gh auth login`.

**Steps at the start of every session:**

```bash
cd ~  # or the working directory
GIT_LFS_SKIP_SMUDGE=1 git clone --no-single-branch https://github.com/Voodoobrew101/Loot-Liquidator.git ll  # skip if the repo is already checked out
cd ll
git fetch origin
git checkout LootLiquidatorclaude-V0.1
git pull --ff-only origin LootLiquidatorclaude-V0.1
git config user.name  "Claude (for Voodoobrew101)"
git config user.email "noreply@anthropic.com"
# Test that pushing is allowed, without changing anything:
git push --dry-run origin LootLiquidatorclaude-V0.1
```

- If the dry run says *"access denied by the git proxy … not in this session's authorized repository set"* or returns 403: first try the `add_repo` tool (above). If that isn't available, **stop**. Tell the owner, in one plain sentence, to start a new chat with the Loot-Liquidator GitHub repo selected as the chat's repository. Don't retry and don't look for workarounds.
- `gh` (GitHub CLI) may have no valid login in the sandbox; you don't need it. Plain git is enough.
- If git reports a certificate or proxy error, read `/root/.ccr/README.md` and run `curl -sS "$HTTPS_PROXY/__agentproxy/status"`. Never disable TLS checks.

## 5. Running the tests (no real Lua needed)

The sandbox package manager has no `lua5.1`, and lua.org is blocked. The previous chat ran the full suite (`tests/run.sh`) successfully using **lupa**, a Python package that embeds real Lua 5.1. The two small wrapper scripts are committed in `tools/lua51-shim/`; just `pip install lupa --break-system-packages` and put that folder on PATH. (Their contents, for reference:)

```bash
pip install lupa --break-system-packages
mkdir -p tools/lua51-shim
cat > tools/lua51-shim/lua5.1 <<'EOF'
#!/usr/bin/env python3
# Minimal lua5.1 stand-in using lupa (pip install lupa). Usage: lua5.1 script.lua [args...]
import sys, lupa.lua51 as l
L = l.LuaRuntime(unpack_returned_tuples=True)
script, args = sys.argv[1], sys.argv[2:]
L.execute("arg = {}")
g = L.globals()
g.arg[0] = script
for i, a in enumerate(args, 1): g.arg[i] = a
f = L.eval("function(p) local f, e = loadfile(p); if not f then error(e, 0) end; return f end")(script)
try:
    f(*args)
except l.LuaError as e:
    sys.stderr.write("lua5.1: %s\n" % e); sys.exit(1)
EOF
cat > tools/lua51-shim/luac5.1 <<'EOF'
#!/usr/bin/env python3
# Minimal "luac5.1 -p FILE..." (syntax check only) using lupa.
import sys, lupa.lua51 as l
L = l.LuaRuntime()
chk = L.eval("function(p) local f, e = loadfile(p); return e end")
bad = 0
for p in [a for a in sys.argv[1:] if a != "-p"]:
    e = chk(p)
    if e: sys.stderr.write("luac5.1: %s\n" % e); bad = 1
sys.exit(bad)
EOF
chmod +x tools/lua51-shim/*
PATH="$PWD/tools/lua51-shim:$PATH" bash tests/run.sh
```

Session 3 note: run `pip install lupa …` and `tests/run.sh` as **separate** commands; doing both in one command was blocked by the sandbox's safety check.

Rules for tests:

- Run the full suite before every commit. It must pass.
- Many existing tests deliberately enforce the old strict rules (e.g. "Runtime database ships no unverified scaling coefficients"). When an owner decision changes a rule, **change that test on purpose** and explain why in the commit message. Never delete a test just to make it pass.
- Add a small test for each behaviour you change. `tests/test_badge_decision.lua` is a light harness for `LA:Evaluate` and the tooltip header (stubs everything); add badge/tooltip cases there.
- If you add or remove an addon `.lua` file, update the file count in both `tests/test_modernization.lua` (`#manifest`) and `tests/validate_package.py` (19 since B7), and add a new test file to `tests/run.sh`.
- Adding an evidence source adds a row in Database & Accuracy; `tests/test_settings.lua` checks the row count (4 since B7).
- If you change data in `database/`, rebuild with `lua5.1 tools/compile_itemdb.lua LootLiquidator/ItemDBRuntime.lua` (the test suite checks the compiled file matches).
- `python3 tools/package_addon.py` (check its usage) builds the installable zip.

## 6. How each session works

1. Connect and check push access (section 4). Run the tests (section 5).
2. Open `claude/HANDOFF.md` (this file, in the repo). Read the **Session log** and **Owner feedback** first; the owner may have reported in-game results.
3. Take the **next 1–3 unchecked tasks** from the list below, in order. Keep each task small. If a task turns out bigger than expected, split it in the list and do the first part.
4. For each task: make the change, keep it focused, run the tests, then **commit and push** with a clear message (one commit per task, message starts with the task ID, e.g. `A1: show working estimates with their confidence`).
5. Keep the player's saved settings working: when you remove or rename a setting, add a quiet migration in the defaults/upgrade code so old saved data doesn't cause errors.
6. Bump `## Version:` in `LootLiquidator/LootLiquidator.toc` **and** `LA.version` at the top of `LootLiquidator/Core.lua` once per session: `0.11.0-claude.1`, `0.11.0-claude.2`, and so on.
7. **End of session (always):** update `claude/HANDOFF.md`:
   - tick finished tasks `[x]` and add the commit ID;
   - add one dated line to the **Session log**: what changed, in plain words;
   - write **"What to check in game"**: 2–5 short things for the owner to look at;
   - add at most **one** new question for the owner under **Owner questions**;
   - fix anything in this prompt that turned out wrong (file names, line numbers, steps).
   Commit and push it, then end your reply with: what changed (2–3 plain sentences), what to check in game, the one question (if any), and the starter message for the next chat.

Never: push to other branches, force-push, open or merge pull requests unless the owner asks, delete research data, or claim in-game testing.

## 7. Task list (knock these off in order)

**Phase 0 — Setup**

- [x] **S1. Set up the workspace.** (`ca51110`) Confirm push access. Commit this prompt as `claude/HANDOFF.md` and the Lua wrapper scripts as `tools/lua51-shim/`. Run the tests. Add a short `claude/README.md`: "This branch is Claude's working copy; see HANDOFF.md". *Done when:* both are pushed and tests pass.

**Phase A — Give answers again (biggest win for the owner)**

- [x] **A1. Stop hiding estimates.** (`d10bc33`) In `Database.lua`, working estimates and unknown-confidence sources should get a small non-zero weight instead of zero, and legacy data should count (weakly) instead of only filling gaps. Confidence goes down for them, not to "no answer". *Done when:* an item with only working estimates gets a value and a confidence; tests updated.
- [x] **A2. Partial outputs still give a value.** (`badde1e`) In `ConversionEngine.lua`, when some outputs of an option are unknown, compute the value from the known outputs, lower the confidence, and mark it "partial". Don't return "Insufficient Data" unless nothing at all is known. *Done when:* the reference case (an ore with one unknown gem) shows a value.
- [x] **A3. One confidence figure per option** (`a52b8d7`) in the tooltip, value-weighted across materials, e.g. "Prospecting (Confidence 48%)". Per-material confidence as an option, off by default.
- [x] **A4. The ? badge only when there is truly nothing.** (`743e378`) Check `Core.lua` so "?" appears only when no option has any estimate. Otherwise pick the best option and show its confidence.
- [x] **A5. Optional price in the header** (`f5ad5b8`), "Loot Liquidator: Smelt 6g 87s" (checkbox, default on).

**Phase B — Make it simple to use**

- [x] **B1. Remove dead settings:** (`d888073`) the `/ll milling|prospecting|smelting|exchanges` toggles, the seven `methodEnabled*` settings, and help text that lists them. Add a saved-data migration.
- [x] **B2. Remove the frozen TSM conversion source** (`4c4e866`) (`itemTSM.lua` and the "TSM database" source weight). TSM stays for Auction House prices only. Update the compiler, TOC, settings and tests.
- [x] **B3. Tooltip levels as the main control:** (`cfb8667`) Off / Recommendation / Alternatives / Breakdown. Fold the ~10 tooltip checkboxes into these levels; keep only a couple of genuinely separate options.
- [x] **B4. "Include alts" switch** (`33c770f`) on the Badges page, bound to `includeVerifiedAlts`.
- [ ] **B2b. (waiting on owner question)** 97 herbs/ores (65 mill, 32 prospect, mostly Draenor/Legion era) had yields only in the removed TSM table. If the owner says yes, compile `ReferenceData.frozen` into ItemDB as a low-weight "old estimate" source (like legacy), not as TSM.
- [x] **B5a. "Show rates for" dropdown** (`d493c00`): me / a chosen alt / a what-if profile, on the General page. Changes whose skill sets the rates, never who can do the work.
- [x] **B5b. Remove the alts table page** (`bbb5965`). What-if profession pages now sit under "Professions (what-if)". Saved per-method modes and per-alt boxes are cleared on load.
- [x] **B6a. Buttons** (`a03a505`) on the Processing Research page: Export recorded results, Start new batch, Reset recorded results (asks first; keeps one backup).
- [x] **B6b. A batch survives logging off.** (`d2cb83c`) In CraftRecording.lua, a clean logout (no cast pending) should pause the active study instead of clearing it, and the next login on the same character and game build should resume it without marking it censored. Only a crash/disconnect with a cast pending stays censored. Update the "interrupted session" test in `tests/test_craft_recording.lua` on purpose.
- [x] **B6c. Slash commands for troubleshooting only:** (`3829e05`) move research/diagnostic commands under `/ll debug …` (keep old names working quietly), and shorten `/ll help` to a few lines.
- [x] **B7. Import button:** (`f10ef36`) a native StaticPopup with a text box; imported results stored as a separate source with its own confidence; reject damaged or impossible values.
- [x] **B8. Native widgets audit:** (`582d000`) Badges & Colors and Database & Accuracy are now Blizzard vertical Settings lists (checkboxes, position dropdown, font-size slider, one "Change color" button per badge + "Reset colors"; one switch per source with its weight slider nested under it + "Reset source weights"). Saved keys unchanged. **Kept as canvas on purpose:** the 13 what-if profession pages (their dropdowns depend on the chosen character and expansion) and Ignored Items (a growing list). Known limit: the colored badge-letter label on each color button only updates after `/reload`.

**Phase C — One database, no ATT**

- [x] **C1a. Counts-based estimator** (`bbbafcd`): pure functions at the top of `Database.lua`: `LL:CountsEstimate` (prior worth `PRIOR_CASTS`=20 casts + weighted casts/drops), `LL:RateConfidence` (exact Beta probability of ±5 points, Jeffreys half-count), `LL:BetaCDF`, `LL:FillChanceOrAverage` (+ `FILLED_CONFIDENCE_FACTOR`=0.5). Worked example passes (22.3%, 69%). Tests: `tests/test_counts_model.lua`. **Not used by the addon yet.**
- [x] **C1b. Wire C1a into the blend.** (`58bd1ab`; sources with no cast count = `LL:EvidenceCasts`, a guess worth ≤ PRIOR_CASTS × stated confidence × evidence class; material confidence = counts confidence capped by the average's stated confidence; missing chance/average filled at half confidence, `b.filled`.) In `ComputeEvidenceModel` (`Database.lua`, the `for field,modelField in pairs({expectedQuantity=…,dropChance=…})` loop and the bins loop after it): turn each source's dropChance into casts (`field.samples` or `record.samples`; personal: `personal.effectiveSamples`; when no count is known, use a small pseudo-count such as `PRIOR_CASTS × reliability`), times `userWeight` (× `STALE_FACTOR` when stale), and set `b.chance` and `b.confidence` from `LL:CountsEstimate`. Fill a missing chance/average with `FillChanceOrAverage` (confidence × 0.5). Keep the value-weighted option confidence (A3). Expect to update confidence numbers in existing tests on purpose; keep the "different batch size → zero weight" rule for drop chances.
- [x] **C2a. Borrow from the other rank** (`C2A_SHA`): when a herb/ore has no usable data, `LL:BorrowFromSibling` (Database.lua, just above `ComputeEvidenceModel`) uses the same-named item of another quality rank in the same expansion (nearest rank first; names via `C_Item.GetItemNameByID`/`GetItemInfo`, a miss while a name is loading is not cached). Shown as "Estimated from <name> rank N" (breakdown) and ", estimated" in the option label; confidence = sibling's × `BORROWED_CONFIDENCE_FACTOR` (0.5), capped at a 20-cast prior.
- [ ] **C2b. Disenchant siblings:** when a gear key (`gear:expansion:quality:kind`) has no record, borrow the nearest quality or the other kind in the same expansion at lower confidence. (The legacy tables already do part of this, labelled `borrowed-other-gear-kind`; check what is still missing before coding.)
- [ ] **C3. Move the no-disenchant list and the old GameData estimates into ItemDB**, then delete `GameData.lua` from the addon.
- [ ] **C4. Token list in ItemDB:** add the current Midnight Season 1 tier tokens and their rewards from public sources (Wowhead, warcraft.wiki.gg), with source links and confidence. Keep ATT as an optional fallback only.
- [ ] **C5. Transmog for alts by armor type** — owner answered 2026-10-31: count an alt for **any** gear their armor type can wear, not just tier. Keep the existing transfer rule (`CanTransferToAlt`) and the enabled-alt list.
- [ ] **C6. Remove ATT** (OptionalDeps, live lookups, attcache/attexport/tokenmigration commands) once C4 covers current tokens.

**Phase D — Research agents (proposals only; don't edit research branches)**

- [ ] **D1. Write `claude/research-agent-proposal.md`:** simpler prompts for the five agents. Agents submit evidence records only (source link, raw counts, date, patch), lowest-confidence items first; a script computes rates and confidence; no hand-written final numbers. The owner decides whether to apply it to `research/prompts/five-agent/`.
- [ ] **D2. GitHub Action** on this branch that runs `tests/run.sh` (using the lupa wrapper) on every push.

**Phase E — Release**

- [ ] **E1. Player-facing README and CurseForge description**: what the badges mean, the few settings, TSM required for AH prices.
- [ ] **E2. `AFTER_PATCH.md`**: the step-by-step prompt for an AI to update the addon after a WoW patch (bump TOC interface, regenerate WagoClassEligibility and DB2Restrictions, refresh ItemDB, run tests, package, upload).
- [ ] **E3. Package a release zip** with `tools/package_addon.py` and list what the owner should check in game before uploading.

## 8. Owner questions (keep to one or two, plain words)

- (2026-10-31, session 3, open) Taking out TSM's old table left 97 herbs and ores, mostly from older expansions, with no milling or prospecting numbers. Should I keep those old numbers inside the addon's own database as low-confidence "old estimates", or leave them out until real research covers them?
- (2026-10-31, open) Gear tokens (tier tokens) still show "?" because we don't yet know what they're worth. Would you rather they show "?" or no badge at all until C4 adds token data?

Answered:
- 2026-10-31 Transmog for alts → "any type": the T badge counts an alt for any gear their armor type can wear, not only tier/class-specific pieces (task C5).

## 9. Owner feedback from the game

*(The owner adds in-game results here, or tells the chat, which records them here.)*

- none yet

## 10. What to check in game

*(Filled in at the end of each session.)* After session 6 (version 0.11.0-claude.7):

1. Settings → Loot Liquidator → **Badges & Colors** now looks like the other pages (a normal list). Try: turning badges off and on, moving the badge (Badge position dropdown), changing the font size, and clicking "Change color" on one badge. Badges in your bags should follow each change.
2. On the same page, click **Reset colors**: badges go back to the normal colors. (The colored letter on the button itself only updates after `/reload`; that is expected.)
3. Settings → **Database & Accuracy** is now a normal list: one switch per source with its weight slider under it. Turning a switch off should grey out its slider. "Reset source weights" puts them all back.
4. Your old badge position, font size, colors and source weights should be kept from before.
5. The addon loads with no error pop-ups.

Still worth checking from session 5 (version 0.11.0-claude.6):

1. Start a new batch (Settings → Processing Research), disenchant or prospect a few items, log out normally, log back in on the same character, do a few more. Then click Export: all the casts should be in one batch, and nothing should say the batch was interrupted.
2. Type `/ll`: the settings should open. Type `/ll help`: only three short lines. Type `/ll debug`: the list of troubleshooting commands. An old command such as `/ll refresh` should still work.
3. Settings → Processing Research has two new buttons, Import and Remove. Click Export, copy the text (Ctrl+A, Ctrl+C), click Import, paste (Ctrl+V), click Import: it should say the results are your own and skip them. If a friend sends you their export text, importing it should say "Imported N results".
4. Settings → Database & Accuracy has a new row, "Imported results", with a switch and a weight slider (25). The rows and the "Reset source weights" button should not overlap.
5. The addon loads with no error pop-ups and your settings are kept.

Still worth checking from earlier sessions: the "Show rates for" dropdown; the Export / Start new batch / Reset buttons; the Tooltip level dropdown (Off / Recommendation / Alternatives / Breakdown); fewer "?" badges; the header price, e.g. "Loot Liquidator: Smelt 6g 87s".

## 11. Session log

- 2026-10-31 (session 6, v0.11.0-claude.7): The Badges & Colors and Database & Accuracy settings pages now use Blizzard's own standard controls, like the rest of the settings (B8). Added the new "how sure are we" math from the study notes (counting casts and drops, 18% guess + 50 casts → 22.3% at 69% confidence); it is tested but not switched on yet, that is the next step (C1a, C1b). Automated tests pass; needs an in-game check.
- 2026-10-31 (session 5, v0.11.0-claude.6): A recording batch now carries on after you log out and back in on the same character (B6b). `/ll` now just opens the settings; troubleshooting commands moved under `/ll debug`, and old names still work (B6c). Added an Import button: you can paste results another player exported. They are checked for damaged or impossible numbers and kept separate from your own results, with their own confidence and their own weight setting (B7). Automated tests pass; needs an in-game check.
- 2026-10-31 (session 4, v0.11.0-claude.5): Added one "Show rates for" choice (me, a chosen alt, or a what-if profile) on the main settings page (B5a). Removed the big alts table; the profession what-if pages moved to a short new page, and old table choices go back to normal (B5b). Added Export, Start new batch and Reset buttons for recorded results, so players don't need slash commands for them (B6a). Split the rest of B6 into B6b/B6c. Automated tests pass; needs an in-game check.
- 2026-10-31 (session 3, v0.11.0-claude.4): Removed TSM's old frozen yield table, so TSM is only used for auction prices (B2). Tooltips now have one simple level choice instead of about ten checkboxes (B3). Added an "Include alts" switch to the badge settings (B4). Found that 97 older herbs/ores only had yields in the TSM table; asked the owner what to do. Automated tests pass; needs an in-game check.
- 2026-10-31 (session 2, v0.11.0-claude.3): The "?" badge now only shows when nothing at all has a price; otherwise the addon picks the best option it has a number for (A4). The tooltip's first line can show the price, on by default (A5). Removed old switches that did nothing (B1). Automated tests pass; needs an in-game check.
- 2026-10-31: Prompt written. Branch `LootLiquidatorclaude-V0.1` exists at `8d8753e` (same as alpha10). The test suite passes with the lupa wrapper. Nothing changed in the addon yet.
- 2026-10-31 (session 1 continued, v0.11.0-claude.2): Each option now shows one confidence figure as a percentage, weighted by how much each material is worth (A3). Optional per-material confidence added, off by default. Automated tests pass; needs an in-game check.
- 2026-10-31: Owner answered the transmog question ("any type"); recorded under C5.
- 2026-10-31 (session 1, v0.11.0-claude.1): Set up the workspace (S1). The addon now uses rough estimates and older data at low weight instead of hiding them (A1), and the old disenchant tables are switched on, so disenchanting gives answers again. When some materials can't be priced, the option still shows a value marked "partial" with lower confidence (A2). Found and fixed a problem where a rough guess could push better data out. Automated tests pass; needs an in-game check.

---

## Starter message for the next chat

> Start this chat with the GitHub repo **Voodoobrew101/Loot-Liquidator** selected, then paste:
>
> Continue the Loot Liquidator work. Clone https://github.com/Voodoobrew101/Loot-Liquidator, check out branch `LootLiquidatorclaude-V0.1`, open `claude/HANDOFF.md` and follow it exactly. Go.