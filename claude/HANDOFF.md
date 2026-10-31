# Loot Liquidator — Claude work session prompt (v0.1, session 1)

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
| Core.lua | The decision for each item (`LA:Evaluate`), defaults, ~40 slash commands |
| ConversionEngine.lua | Gold value of disenchant/mill/prospect/smelt (`ValueProcessingModel`, ~line 268). Since A2: unknown outputs give a partial value with `model.partial` and `model.valueConfidence` |
| Database.lua | Blends evidence sources with weights (`ComputeEvidenceModel`, ~lines 330–545). Since A1: weak/old evidence is down-weighted, not dropped; only different-batch drop chances still get zero weight (a different quantity, by design) |
| Badges.lua | Badge letters and the tooltip |
| NativeBags.lua | Badges on Blizzard bags, banks, BetterBags, guild bank |
| Settings.lua / SettingsControls.lua | Settings menus |
| Professions.lua / AltRosterUI.lua / ProfessionModels.lua | Character and alt professions, On/Auto/Off/Manual modes, alts table, transmog recipients |
| ATTIntegration.lua / DirectTokenCollector.lua | Gear tokens via ATT (uses ATT's *internal* functions), transmog collection check |
| CraftRecording.lua / Observations.lua | Recording your own results ("studies") |
| TSMOperations.lua | Reads TSM Auctioning operations |
| ItemDBRuntime.lua | Compiled ItemDB (generated by `tools/compile_itemdb.lua` — never hand-edit) |
| itemTSM.lua, GameData.lua | Frozen/old data, to be removed or migrated |
| DB2Restrictions.lua, WagoClassEligibility.lua | Generated game data: no-disenchant list, class masks (build 12.1.7) |

Known dead or confusing things (found by code reading):

- `/ll milling on|off`, `/ll prospecting`, `/ll smelting`, `/ll exchanges` change saved settings the code never reads.
- Settings reads "Legacy" as the old disenchant tables (`GameData.lua` → `LL.LegacyDB`); since A1 it is on by default at weight 10.
- Seven `methodEnabledD/M/P/S/C/R/X` settings are saved but never used.
- About ten separate tooltip checkboxes overlap the Minimal/Summary/Detailed level (`tooltipDetail`).
- ItemDB's `tokenRewards` list is empty, so tokens depend entirely on ATT.
- The T badge counts alts only for class-restricted gear (tier). Ordinary gear never counts an alt (open question for the owner).
- An interrupted recording "study" (e.g. logging off) can't be continued.

## 4. How to connect to GitHub and push

**How the previous chat connected:** it ran in Claude's cloud sandbox, which routes all internet traffic through a proxy. It cloned the public repo over HTTPS with plain `git clone` (no password needed for reading). It could **not** push: the proxy only adds GitHub credentials for repositories that have been **added to the session as a source**, and this repo had not been. Nobody ever pasted a password or token, and you must not either.

**Session 1 finding:** if the chat has the `add_repo` tool (Claude Code on the web / Cowork), call it with owner `Voodoobrew101`, repo `Loot-Liquidator`, access `push`. That attaches the repo mid-chat and plain `git push` then works from the existing clone — no new chat needed. Only if that tool is missing or refused, fall back to the steps below.

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

Rules for tests:

- Run the full suite before every commit. It must pass.
- Many existing tests deliberately enforce the old strict rules (e.g. "Runtime database ships no unverified scaling coefficients"). When an owner decision changes a rule, **change that test on purpose** and explain why in the commit message. Never delete a test just to make it pass.
- Add a small test for each behaviour you change.
- If you change data in `database/`, rebuild with `lua5.1 tools/compile_itemdb.lua LootLiquidator/ItemDBRuntime.lua` (the test suite checks the compiled file matches).
- `python3 tools/package_addon.py` (check its usage) builds the installable zip.

## 6. How each session works

1. Connect and check push access (section 4). Run the tests (section 5).
2. Open `claude/HANDOFF.md` (this file, in the repo). Read the **Session log** and **Owner feedback** first; the owner may have reported in-game results.
3. Take the **next 1–3 unchecked tasks** from the list below, in order. Keep each task small. If a task turns out bigger than expected, split it in the list and do the first part.
4. For each task: make the change, keep it focused, run the tests, then **commit and push** with a clear message (one commit per task, message starts with the task ID, e.g. `A1: show working estimates with their confidence`).
5. Keep the player's saved settings working: when you remove or rename a setting, add a quiet migration in the defaults/upgrade code so old saved data doesn't cause errors.
6. Bump `## Version:` in `LootLiquidator/LootLiquidator.toc` once per session: `0.11.0-claude.1`, `0.11.0-claude.2`, and so on.
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
- [ ] **A4. The ? badge only when there is truly nothing.** Check `Core.lua` so "?" appears only when no option has any estimate. Otherwise pick the best option and show its confidence.
- [ ] **A5. Optional price in the header**, "Loot Liquidator: Smelt 6g 87s" (checkbox, default on).

**Phase B — Make it simple to use**

- [ ] **B1. Remove dead settings:** the `/ll milling|prospecting|smelting|exchanges` toggles, the seven `methodEnabled*` settings, and help text that lists them. Add a saved-data migration.
- [ ] **B2. Remove the frozen TSM conversion source** (`itemTSM.lua` and the "TSM database" source weight). TSM stays for Auction House prices only. Update the compiler, TOC, settings and tests.
- [ ] **B3. Tooltip levels as the main control:** Off / Recommendation / Alternatives / Breakdown. Fold the ~10 tooltip checkboxes into these levels; keep only a couple of genuinely separate options.
- [ ] **B4. "Include alts" switch** on the Badges page, bound to `includeVerifiedAlts`.
- [ ] **B5a. "Show rates for" dropdown:** me / a chosen alt / a what-if profile, mapping onto the existing On/Auto/Off/Manual and profile code.
- [ ] **B5b. Remove the alts table page** (`AltRosterUI.lua` grid) once B5a works; keep the transferability rule.
- [ ] **B6. Buttons instead of slash commands:** Export recorded results, Reset recorded results, Start new batch (batch survives logout). Move research/diagnostic commands under `/ll debug …` and shorten `/ll help`.
- [ ] **B7. Import button:** a native StaticPopup with a text box; imported results stored as a separate source with its own confidence; reject damaged or impossible values.
- [ ] **B8. Native widgets audit:** list the remaining custom canvas pages (Badges & Colors, Database & Accuracy) and replace what can be replaced with `Settings.Create…` controls.

**Phase C — One database, no ATT**

- [ ] **C1. Implement the counts-based confidence model** (section 2, "Recommended data model") in the ItemDB compiler or `Database.lua`, with tests using the worked example (18% guess worth 20 casts + 50 casts/12 drops → 22.3%, about 69% confidence).
- [ ] **C2. Borrow from a sibling** when an item has no data (other rank of the same ore; same expansion and item level band for disenchanting), shown as "Estimated from X" with low confidence.
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

*(none open)*

Answered:
- 2026-10-31 Transmog for alts → "any type": the T badge counts an alt for any gear their armor type can wear, not only tier/class-specific pieces (task C5).

## 9. Owner feedback from the game

*(The owner adds in-game results here, or tells the chat, which records them here.)*

- none yet

## 10. What to check in game

*(Filled in at the end of each session.)* After session 1 (version 0.11.0-claude.2):

1. Hover a few ores and herbs that used to say "Insufficient Data": they should now show a gold value and a confidence. Values marked "partial" only count the materials that have a price.
2. Hover some old green/blue gear you could disenchant: the Disenchant line should now show a value (it was usually blank before).
3. In the breakdown, numbers with a "~" in front are estimates. Check they look sensible (no huge or silly amounts).
4. Each option line now shows one figure like "Prospecting (Confidence 48%)". In Settings → Tooltips there's a new box "Show confidence per material" (off by default): turning it on adds a small (N%) to each material row.
5. Check the addon loads with no error pop-ups, and that your old settings are still there.

## 11. Session log

- 2026-10-31: Prompt written. Branch `LootLiquidatorclaude-V0.1` exists at `8d8753e` (same as alpha10). The test suite passes with the lupa wrapper. Nothing changed in the addon yet.
- 2026-10-31 (session 1 continued, v0.11.0-claude.2): Each option now shows one confidence figure as a percentage, weighted by how much each material is worth (A3). Optional per-material confidence added, off by default. Automated tests pass; needs an in-game check.
- 2026-10-31: Owner answered the transmog question ("any type"); recorded under C5.
- 2026-10-31 (session 1, v0.11.0-claude.1): Set up the workspace (S1). The addon now uses rough estimates and older data at low weight instead of hiding them (A1), and the old disenchant tables are switched on, so disenchanting gives answers again. When some materials can't be priced, the option still shows a value marked "partial" with lower confidence (A2). Found and fixed a problem where a rough guess could push better data out. Automated tests pass; needs an in-game check.

---

## Starter message for the next chat

> Start this chat with the GitHub repo **Voodoobrew101/Loot-Liquidator** selected, then paste:
>
> Continue the Loot Liquidator work. Clone https://github.com/Voodoobrew101/Loot-Liquidator, check out branch `LootLiquidatorclaude-V0.1`, open `claude/HANDOFF.md` and follow it exactly. Go.