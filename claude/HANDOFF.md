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
16. **Baseline + scaling (owner, 2026-10-31):** ItemDB ships a *baseline* per item/method = roughly what a player with the **minimum required skill** (no optional bonuses) gets. The addon *calculates up* from it with the player's relevant numbers (skill above minimum, Resourcefulness, Multicraft, spec points, profession gear). Both the baselines and the scaling rules are worked out **by research before ItemDB is compiled** (script in D1b), never hand-typed. Research rules run with their confidence shown, like estimates (C7).

### Recommended data model (from the study notes, use it)

- Every source becomes "casts" and "drops". Start from a guess worth ~20 casts (borrowed from a close relative, e.g. the other rank of the same ore, labelled "Estimated from X"), add every source's real counts, weight weak sources down (e.g. pre-hotfix data ×0.25), then chance = drops ÷ casts. This is a beta-binomial / empirical-Bayes model.
- Confidence = chance that the true rate is within ±5 points of the shown number. For an 18% drop: 10 casts ≈ 30%, 50 ≈ 64%, 100 ≈ 81%, 200 ≈ 94% (exact values from `LL:RateConfidence`: 33, 65, 81, 94).
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
| ConversionEngine.lua | Gold value of disenchant/mill/prospect/smelt (`ValueProcessingModel`, ~line 300). Since C7b, `ApplyVerifiedMechanics` (~line 142) runs any usable research mechanic (same gate as C7), caps material confidence by the rule's and sets `unreviewedRule`. Since B5a, `RateProfileTarget` (top of file) decides whose skill sets the rates ("Show rates for"). Since A2: unknown outputs give a partial value with `model.partial` and `model.valueConfidence` |
| Database.lua | Since C3, `LL:UnpackItemDBTables()` (just above `InitializeItemDB`) unpacks `ItemDB.legacy` → `LL.LegacyDB` and `ItemDB.restrictions` → `LL.ItemRestrictions` (game-file `noDisenchant` + research `researchNoDisenchant`, D1c4) / `LL.DB2Processable` at load. Blends evidence sources with weights (`ComputeEvidenceModel`, ~lines 505–770; the counts-based estimator `CountsEstimate`/`RateConfidence` sits near the top and is used for drop chances since C1b; `EvidenceCasts` turns a source into casts; `FindRankSiblings`/`BorrowFromSibling` (C2a) sit just above `ComputeEvidenceModel`). Sources: itemdb, personal, imported (B7), legacy. Since A1: weak/old evidence is down-weighted, not dropped; only different-batch drop chances still get zero weight (a different quantity, by design) |
| Badges.lua | Badge letters and the tooltip |
| NativeBags.lua | Badges on Blizzard bags, banks, BetterBags, guild bank |
| Settings.lua / SettingsControls.lua | Settings menus. Since B8 every page is a native vertical list (`LL:AddBadgeSettings`, `LL:AddEvidenceSettings`) except the what-if profession pages and Ignored Items. General page has "Show rates for" (B5a); Processing Research page has the Export / Start new batch / Reset (B6a) and Import / Remove imported results (B7) buttons. The ElvUI skin helper `SkinSettingsCanvasControl` lives in SettingsControls.lua since B5b |
| Professions.lua / ProfessionModels.lua | Character and alt professions, transmog recipients (`DirectTransmogRecipient`; since C5 it uses `AltCanWearAppearance` = class mask + `ArmorTypePermitsClass`), `CanTransferToAlt`. The alts table (`AltRosterUI.lua`) was deleted in B5b; the per-method On/Auto/Off/Manual code is still there but dormant (saved modes are cleared on load, so everything runs as Auto) |
| Tokens.lua / DirectTokenCollector.lua | Since C6 (session 16) `Tokens.lua` replaces ATTIntegration.lua: gear tokens only from ItemDB's catalog (`LL:TokenInfo` → `StandaloneTokenInfo`), transmog collection check (`AppearanceCollectionState`), class-set tooltip summary (`TokenClassSummary`), token valuation (`TokenPieceQuote`), `InvalidateTokenCache`. No ATT code anywhere (guarded by `tests/validate_package.py`). DirectTokenCollector records vendor offers / opened rewards as research only |
| CraftRecording.lua / Observations.lua | Recording your own results ("studies" = batches). B6a added `ExportRecordedResultsPage`, `ResetRecordedResults` (keeps one `recordedResultsBackup`), `StartNewBatch`. B6b: clean logout pauses the study (`paused`), `ledger()` parks it per character in `pausedStudies` and resumes it on the same character + build; `ActiveRecordingBatch()` |
| ImportedResults.lua | B7: Import of another player's Export page (strict JSON reader, per-cast checks), stored as counts in `db.importedResults`; `ImportedEvidenceRecords` feeds the "imported" source with its own confidence. Settings buttons: Import / Remove imported results |
| TSMOperations.lua | Reads TSM Auctioning operations |
| ItemDBRuntime.lua | Compiled ItemDB (generated by `tools/compile_itemdb.lua` — never hand-edit). Since D1b step 2 the compiler also appends `database/evidence-baselines.lua` (generated by `tools/evidence_to_baselines.py` from `research/evidence/v3`; empty until agents submit evidence; record IDs `evidence:<Method>:<input>:x<perCast>`) and, since D1c (session 14), `database/research-v3-baselines.lua` (generated by `tools/research_v3_to_baselines.py` from the research team's v3 snapshot; record IDs `evidence:v3:<Method>:<input>:x<perCast>`; each replaces older `research:` rows for the same method + input + material, listed in `ItemDB.buildReport.researchSuperseded`; since D1c4 the same file's `noDisenchant` list is added to `ItemDB.restrictions.researchNoDisenchant`, only for items the game-file list lacks). Since C3 it is the one database: line `LL.ItemDB=` (yields, rules, tokens), line `LL.ItemDB.legacy=` (old disenchant estimates, formerly GameData.lua) and line `LL.ItemDB.restrictions=` (no-disenchant list + mill/prospect hints, formerly DB2Restrictions.lua, whose source now sits in `database/sources/DB2Restrictions.lua`). `itemTSM.lua` was removed in B2; its snapshot is still in `database/sources/ReferenceData.lua` (`frozen`) |
| WagoClassEligibility.lua | Generated game data: class masks (build 12.1.7) |

Known dead or confusing things (found by code reading):

- Settings reads "Legacy" as the old disenchant tables (`ItemDB.legacy` → `LL.LegacyDB` since C3); since A1 it is on by default at weight 10.
- `manualMilling/Prospecting/Smelting/Disenchanting` are read in `Professions.lua` (~line 590) but nothing in the addon sets them (handle in B5a).
- **(Session 14) The research agents use their own v3 workflow**, not the proposal on this branch: rules in `research/v3/README.md` on `implementation/five-agent-completion`, evidence in `research/v3/evidence/<agent>/*.jsonl` (format `research/v3/evidence-format.md`), their calculator `research/v3/tools/build_estimates.py`, results `research/v3/output/`. A scheduled "Claude reviewer" (not this chat) and the Master agent discuss changes in `research/v3/strategy.md`. Our `research/evidence/v3/` files (QUEUE, TOKEN-CHECK, README) and `claude/research-agent-proposal.md` are not read by them; they are marked so and kept for the record.
- (Fixed in C4b3, session 15) ItemDB's `tokenRewards` now holds 228 tokens built from the research team's v3 notes on every refresh, so tokens no longer depend on ATT. Older note: ItemDB's `tokenRewards` list was empty, so tokens depended entirely on ATT. **C4b2 as written won't happen:** v3 agents only write inside `research/v3/` and record tokens as v3 `token` records (e.g. `midnight/2026-10-30T2117-season1-tier-token-class-rewards.jsonl`, `…T2208-tier36-token-rewards.jsonl`), never into `research/proposed/itemdb.lua`. See C4b3 and the owner question. Both seasons' lists are complete in research (C4a3, C4a5); the compiler path is ready (C4b1). Without ATT, a token the addon doesn't recognise shows no badge (not "?").
- (Fixed in C5) The T badge now counts an alt for any armor their armor type can wear. Weapons, rings, trinkets and off-hands still use the class mask only.
- (Fixed in B6b) Recording batches now carry on through a clean logout; only a crash/disconnect or a logout mid-cast marks a batch censored.
- The import text box is a single-line StaticPopup edit box with no length limit (`maxLetters=0`). One export page is ~25 casts; very large pastes may feel slow. Needs an in-game check.
- `LA.version` in Core.lua must be bumped together with the TOC `## Version:` (session 3 forgot; fixed in session 4).

## 4. How to connect to GitHub and push

**How the previous chat connected:** it ran in Claude's cloud sandbox, which routes all internet traffic through a proxy. It cloned the public repo over HTTPS with plain `git clone` (no password needed for reading). It could **not** push: the proxy only adds GitHub credentials for repositories that have been **added to the session as a source**, and this repo had not been. Nobody ever pasted a password or token, and you must not either.

**Session 1, 3–16 finding:** if the chat has the `add_repo` tool (Claude Code on the web / Cowork), call it with owner `Voodoobrew101`, repo `Loot-Liquidator`, access `push`. That attaches the repo mid-chat and plain `git push` then works from the existing clone — no new chat needed (worked again in sessions 3–16). Its reply asks you to re-clone into `/home/claude/loot-liquidator` and call `register_repo_root`; that's optional — an existing clone at another path pushes fine (`register_repo_root` rejects other paths). Only if `add_repo` is missing or refused, fall back to the steps below.

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

- Run the full suite before every commit. It must pass. Since D2 GitHub also runs it on every push (see D2 for how to read the result).
- Many existing tests deliberately enforce the old strict rules (e.g. "Runtime database ships no unverified scaling coefficients"). When an owner decision changes a rule, **change that test on purpose** and explain why in the commit message. Never delete a test just to make it pass.
- Add a small test for each behaviour you change. `tests/test_badge_decision.lua` is a light harness for `LA:Evaluate` and the tooltip header (stubs everything); add badge/tooltip cases there.
- If you add or remove an addon `.lua` file, update the file count in both `tests/test_modernization.lua` (`#manifest`) and `tests/validate_package.py` (17 since C3), and add a new test file to `tests/run.sh`.
- `tests/validate_package.py` guards the old disenchant estimates with a sha256 of the `LL.ItemDB.legacy=` line in ItemDBRuntime.lua. If you ever change legacy data on purpose, update that hash and say why.
- Adding an evidence source adds a row in Database & Accuracy; `tests/test_settings.lua` checks the row count (4 since B7).
- If you change data in `database/`, rebuild with `lua5.1 tools/compile_itemdb.lua LootLiquidator/ItemDBRuntime.lua` (the test suite checks the compiled file matches).
- If evidence under `research/evidence/v3/` changes (e.g. after merging agents' files), first run `python3 tools/evidence_to_baselines.py` (rewrites `database/evidence-baselines.lua`, prints what it used and skipped), then rebuild ItemDB as above. `tests/run.sh` fails if either is out of date. Fixture evidence for tests lives in `tests/fixtures/evidence-v3/`; the compiler's optional 2nd argument compiles a different baselines file (used by the tests).
- **Research v3 (D1c):** to take in the research team's newest results, `git fetch origin implementation/five-agent-completion`, then `python3 tools/research_v3_to_baselines.py --refresh` (new pinned snapshot in `database/research/v3-snapshot/`, prints what was used and left out), then rebuild ItemDB. `tests/run.sh` fails if the baselines file is out of date. Never edit the snapshot. `tests/test_research_v3_baselines.py` pins a few published numbers (Saronite, Aqirite); after a refresh they may move on purpose, so update them and say why in the commit.
- `python3 tools/package_addon.py dist/LootLiquidator-<version>.zip` builds the installable zip (the argument is the output path; with `--help` it writes a file called `--help`).
- D1c4: research no-disenchant flags come through the same refresh; `tests/test_research_v3_no_disenchant.py` checks the game-file list ships unchanged and research only adds.
- Research files under `database/research/` (except `itemdb.lua`) are not compiled. Two tests guard them: `tests/test_disenchant_gaps.lua` (the gap list must match ItemDB exactly) and `tests/test_token_research.py` (token research stays NOT_REVIEWED and out of `database/records.lua`).
- Web pages (session 10): WebFetch of a wowhead.com item URL that appeared in search results works but returns an empty page; a URL you build yourself needs the owner's approval. Older note: WebFetch of wowhead.com and some warcraft.wiki.gg pages asks the owner for approval; if nobody answers, don't retry in that session. Since session 9 the starter message names both sites and gives permission, so pages on those sites should open; if the app still shows an approval prompt, the owner just clicks allow. WebSearch works without approval, and result URLs often contain item IDs. Session 11: a direct `wowhead.com/item=N` fetch still showed an approval prompt nobody answered, but searches alone were enough. Session 12: same for a warcraft.wiki.gg page; don't bother fetching, go straight to searches. `wowhead.com item "<exact name>"` (WebSearch mode `extended`) returned the `wowhead.com/item=NNN/...` URL as the first hit for all 21 Season 2 tokens; `warcraft.wiki.gg <token name> creates for <classes>` returns the token page's "Creates … for <class>" list (reward names). Searching `u.gg <spec> <class> gear raid "<item name>"` returns `static.bigbrain.gg/wow/item/assets/NNN.webp` next to item names; `"<name>" wowhead item=NNN` returns Wowhead URLs. **Session 13 (best so far):** WebFetch of `https://www.mythicdrake.com/items/` (it appeared in search results) returns ~290 item links whose URLs end in `-<itemID>/`, covering most Season 2 gear; WebSearch `mythicdrake.com items "<set words>"` and `wowhead item "<exact name>"` (mode `extended`) fill the rest. `wownexus.gg/item-sets/<id>` shows Blizzard-API set JSON with IDs, but a set URL you build yourself needs approval. Wowhead and WoWDB set pages fetch empty. keystoneloot.io JSON-LD in search snippets also carries `wowhead-item-id`.

## 6. How each session works

1. Connect and check push access (section 4). Run the tests (section 5).
2. Open `claude/HANDOFF.md` (this file, in the repo). Read the **Session log** and **Owner feedback** first; the owner may have reported in-game results.
3. Take the **next 1–3 unchecked tasks** from the list below, in order. (After session 16: refresh the v3 snapshot first if the agents' branch has moved (section 5), then D1c2, then D1c3 or C4b4 if the owner's answer arrived. Note the agents' work is also moving to `migration/v3-historical-research`; keep reading `implementation/five-agent-completion` unless the owner says otherwise.) Keep each task small. If a task turns out bigger than expected, split it in the list and do the first part.
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
- [x] **B2b. Closed, not built** (owner, session 12: "covered by the research team, not here"). The 97 herbs/ores (65 mill, 32 prospect, mostly Draenor/Legion era) that only had TSM yields stay out of the addon; they are item 4 in `research/evidence/v3/QUEUE.md`, and research evidence fills them through `tools/evidence_to_baselines.py`. `ReferenceData.frozen` stays in the source data for the record only.
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
- [x] **C2a. Borrow from the other rank** (`1f291d5`): when a herb/ore has no usable data, `LL:BorrowFromSibling` (Database.lua, just above `ComputeEvidenceModel`) uses the same-named item of another quality rank in the same expansion (nearest rank first; names via `C_Item.GetItemNameByID`/`GetItemInfo`, a miss while a name is loading is not cached). Shown as "Estimated from <name> rank N" (breakdown) and ", estimated" in the option label; confidence = sibling's × `BORROWED_CONFIDENCE_FACTOR` (0.5), capped at a 20-cast prior.
- [x] **C2b. Disenchant gaps need data, not borrowing** (`c8839ad`; re-scoped in session 7). Done as research targets: `database/research/disenchant-gaps.lua` (research only, not compiled) lists all 35 groups; `tests/test_disenchant_gaps.lua` recomputes the gaps from ItemDBRuntime.lua and fails if the list drifts, so remove an entry when data arrives. Original note: Borrowing another *quality* is wrong: green, blue and purple gear give different materials (dust / shards / crystals). Armor↔weapon borrowing already exists in the legacy tables (`borrowed-other-gear-kind`). Still missing entirely (no record of either kind), 35 keys: all of expansions 0 and 1 (Classic, TBC; these also vary by item level inside the expansion), `gear:3:4`, `gear:4:3/4`, `gear:5:3/4`, `gear:6:3`, `gear:7:3/4`, `gear:8:3/4`, `gear:9:3`, `gear:9:4:armor`. Add these as research targets (D1) or as documented public tables in ItemDB during C3; don't invent numbers.
- [x] **C3. Move the no-disenchant list and the old GameData estimates into ItemDB** (`0aff910`). `GameData.lua` and `DB2Restrictions.lua` no longer ship; both are lines inside ItemDBRuntime.lua (see the file table). Legacy data is byte-identical (checked by hash).
- [x] **C4a. Token layout staged** (`5c3ca09`): `database/research/tokens-midnight-s1.json` has all 20 Tier 35 tokens (name, slot, armor group, classes, boss, raid; Head = "Void<group> Fanatical Nullcore", Shoulders = Unraveled, Chest = "Aln<group> Riftbloom", Hands = Hungering, Legs = Corrupted; groups woven/cured/cast/forged = cloth/leather/mail/plate) plus the Chiming Void Curio exchange at Kirana, each with ≥2 https sources and the source conflicts written down. Marked NOT_REVIEWED; `tests/test_token_research.py` keeps it out of `database/records.lua` and requires every item ID to come with the Wowhead page it was read from. Only 3 token IDs known (249351, 249363, 249366).
- [x] **C4a2. IDs filled** (`f671abd`): 18/20 token IDs (249349–249366), Chiming Void Curio 249367, 53/65 tier-piece IDs with name/class/slot, each with its source. IDs follow a strict pattern (4 tokens per slot; 9 items per class in the order cloak, wrist, waist, shoulder, legs, head, hands, feet, chest), written up in the file's `idPattern`; the 2 chest tokens (Alnwoven/Alncured Riftbloom) and 13 pieces not seen next to their name are stored only as `tokenIDByPattern` / `itemIDByPattern` hints. **How IDs were found:** WebFetch of wowhead.com returns an empty page (it's built by scripts in the browser), and constructed URLs need approval; WebSearch `wowhead item "<name>"` returns result URLs `wowhead.com/item=NNN/...` that give the ID, and u.gg gear pages show `static.bigbrain.gg/wow/item/assets/NNN.webp` next to item names.
- [x] **C4a3. Confirm the 14 pattern hints** (`10c0a63`): all 14 found on public pages next to the item name (12 pieces from u.gg gear-page image names, the 2 chest tokens 249347/249348 from Wowhead URLs in search results). Season 1 is now 20/20 tokens, 65/65 pieces; the numbering pattern held every time. Weakest: 249960 (Luminant Verdict's Greaves), whose name was cut off after "Luminant" in the snippet; C4b should recheck it first.
- [x] **C4a4. Season 2 (Tier 36) tokens** (`6ab36b5`): `database/research/tokens-midnight-s2.json` has all 20 tokens (270910–270929; Idol=hands 10–13, Effigy=head 14–17, Relic=legs 18–21, Remnant=shoulders 22–25, Icon=chest 26–29, each block woven/cured/cast/forged) and the Slumbering Coil Curio 270909, every ID read from its own Wowhead URL (no pattern guesses). Bosses: Entombed Sentinels (hands), The Twin Fangs (head), Sszorak (legs), The Lost Explorers (shoulders), Vashnik the Malignant (chest), curio from Ula'tek, exchanged at Kirana next to the Catalyst in Silvermoon. Reward names for 34/65 pieces (from wiki "Creates" lists and tier-piece pages); the rest are `null`, never guessed. Conflicts written down; biggest: evoker "Ebon Greathorns" (wiki says hands) vs "Magmashapers" (wiki says head) look swapped. Test: `tests/test_token_research_s2.py` (no pattern hints allowed, no ID shared with Season 1, nothing in `database/records.lua`).
- [x] **C4a5. Season 2 reward IDs and missing names** (`5886b42`): all 65 names and IDs, each with its page; evoker settled (Magmashapers = head 271501, Ebon Greathorns = hands 271502, per the wiki item tooltips). IDs 271451–271567, 9 per class in the Season 1 order, class order Warrior, Paladin, DK, Shaman, Hunter, Evoker, Rogue, Monk, Druid, DH, Warlock, Priest, Mage (observation only). Where they came from: `tools/fill_s2_reward_ids.py`. Original task: fill the 65 tier-piece item IDs and the 31 `null` names in `tokens-midnight-s2.json`, each with its source (Wowhead URL or u.gg image asset name, as in Season 1). Settle the evoker hands/head conflict first. When a token's rewards are all filled, set `rewardIDs` and `status: "ids-complete-unreviewed"` (the test then requires every ID).
- (Original C4a2 note:) Fill in the missing IDs in that file: 17 token IDs, the Chiming Void Curio ID, and all reward IDs (~65; reward names known only for leather hands/legs). Needs Wowhead (or warcraft.wiki.gg item pages), which need the owner's approval to open; both sessions 8 and 9 asked while the owner was away. Trick that works without approval: WebSearch results whose URL is `wowhead.com/item=NNN/...` give the ID. Also note Season 2 (Tier 36, Slumbering Coil Curio from Ula'tek, Venomous Abyss) has started and will need the same treatment. Original C4a note: For each Midnight Season 1 tier token (4 armor groups × 5 slots: head/shoulders/chest/hands/legs; plus the Chiming Void Curio omni token from March on Quel'Danas, kind `exchange`) record: token item ID, slot, armor group, and the complete list of tier reward item IDs (one per class in the group), each with **two** public source links (Wowhead + warcraft.wiki.gg). Session 8 found: search snippets disagree on token names and none list item IDs, and Wowhead pages need the owner's approval to fetch (the request went unanswered while the owner was away). Stage the result as research (e.g. `database/research/tokens-midnight-s1.json`), not in `database/records.lua` yet. Rewards are soulbound tier pieces, so the main use is the T badge (missing appearance) rather than gold.
- [ ] **C4b. Token lists: research team checks them and puts them in itemdb.lua** (owner, session 12). Split:
  - [x] **C4b1** (`0db33b8`): done. `tools/compile_itemdb.lua` reads `tokenRewards` only from the research export (`database/research/itemdb.lua`), checks each record with the addon's own `LL:ValidateTokenCatalog` (alone, then against the ones kept), skips bad ones with a reason (`ItemDB.buildReport.tokenRewardsSkipped` + build output), and fails the build if `database/records.lua` carries tokens. Checker steps and exact record format: `research/evidence/v3/TOKEN-CHECK.md` (QUEUE.md item 1 and the proposal's Checker text point to it). Original task: hand the staged lists (`database/research/tokens-midnight-s1.json`, `-s2.json`) to the research team: a Checker step in `research/evidence/v3/QUEUE.md` and in the paste-ready agent texts (D1b step 5) that says how to confirm each ID against its link and how to write the confirmed result into their ItemDB export (`research/proposed/itemdb.lua` on their branch, which this branch snapshots as `database/research/itemdb.lua`). Define the token section of that export (a `tokenRewards` list in the shape `LL:ValidateTokenCatalog` wants: `independentReview='APPROVED'`, `reviewedBy`, confidence ≥ 90, ≥ 2 https sources, build windows) and make `tools/compile_itemdb.lua` read it from there instead of `database/records.lua`. Never write "APPROVED" ourselves.
  - **C4b2 (waits for the research team):** once a checked export arrives, refresh the snapshot, rebuild ItemDB, and confirm the T badge uses it. (ATT is gone since C6, so there is no fallback.)
- [x] **C5. Transmog for alts by armor type** (`46d6893`) — owner answered 2026-10-31: count an alt for **any** gear their armor type can wear, not just tier. Cloaks/cosmetics count for everyone, shields for warrior/paladin/shaman. A class-mask "no" still wins. Transfer rule and "Include alts" unchanged. Test: `tests/test_transmog_alts.lua`.
- [x] **C4c. Tokens never show "?"** (`955ba1b`): `LL:TokenPieceQuote` (ATTIntegration.lua) values a token by the piece it opens into for this character (class mask; cheapest piece if the class can't be matched) — its game sell price and its disenchant value; `LA:Evaluate` gives D / V instead of Q; tokens are exempt from the hide-V-on-soulbound rule; tooltip rows "Open, then vendor <piece>" / "Open, then disenchant (Confidence N%)". Research: Midnight tokens show **no** sell price on the wiki tooltip; tier pieces sell for ~28–61g. Only works for tokens the addon recognises (ATT or the reviewed catalog, i.e. after C4b2). Original task: (owner, session 12: "they have vendor prices, or possibly a disenchant value on the trade-in"). In `LA:Evaluate` (Core.lua), a tier token should get a real answer: at least **V** with the game's vendor price of the token itself, and when the token data says what piece it opens into, the disenchant value of that piece as an alternative (tier pieces are soulbound but can be disenchanted). The **T** badge still wins when the piece's appearance is missing. Check first whether tokens actually have a sell price in game (Wowhead lists them as "Junk"; the sell price wasn't in the search snippets). Add cases to `tests/test_badge_decision.lua`.
- [x] **C6. Remove ATT** (`84958c0`, session 16): OptionalDeps, live lookups, saved-cache reader, cache update, research export/status, `attdiag`/`attcache`/`attexport`/`tokenmigration`, the Settings switch and three buttons, and the legacy-cache import are gone; `ATTIntegration.lua` → `Tokens.lua`. Retired settings: `enableATTIntegration`, `showATTTooltipDetails`, `showATTTokenDEQuotes`. The old saved caches (`attRewardCache`, `attResearchScans`, `attItemResearch`) are left in saved data untouched and unread. `tools/import_token_research.py` still stages old ATT export files; its test uses a frozen copy (`tests/fixtures/att-runtime-export.json`). The curios (C4b4) now show no token data at all until their costs are recorded.

**Phase D — Research agents (proposals only; don't edit research branches)**

- [x] **D1.** (`6909470`) Proposal written. Note: the five-agent prompts live on `implementation/five-agent-completion` (also `integration/research-current`), not on the research branches. Original task:
- [ ] **D1b. Evidence script** (owner agreed 2026-10-31, with decision 16). Split into small steps: (1) ✅ `5ac0c07` record format checker `tools/evidence_check.py` (`python3 tools/evidence_check.py [folder] [--json] [--strict]`; record ID = `<file>#<position>`; adds a `check` record kind for the Checker agent; tests `tests/test_evidence_check.py`; agent notes in `research/evidence/v3/README.md`); (2) ✅ `adacb3a` counts → baseline records: `tools/evidence_to_baselines.py` → `database/evidence-baselines.lua` → appended by `tools/compile_itemdb.lua` (one copy per lineage, stale ×0.25, not-at-minimum-skill ×0.5 until step 3, bare percentage = 20-cast guess, Checker "mismatch" skipped, confidence = exact port of `LL:RateConfidence`; Disenchant/Mill/Prospect/Smelt only, Craft/Exchange/Open kept but not built; tests `tests/test_evidence_baselines.py` + `.lua` with fixture `tests/fixtures/evidence-v3/`); (4) ✅ `8f70825` `research/evidence/v3/QUEUE.md`; (5) **superseded** (session 14): the agents' prompts were already switched to their own v3 workflow (`research/v3/SWITCHOVER-PROMPT.md` on their branch), so no second set of prompts was written; next: (3) simple scaling-rule fits into rules (needs real mechanics records and samples at known skill; replace the ×0.5 with a conversion).
- [x] **D1c. Research v3 results reach ItemDB** (`b273fac`, session 14): `tools/research_v3_to_baselines.py` pins a snapshot of the agents' v3 files and runs *their* calculator unchanged on real studies only (TSM/reference starting guesses and the re-imported copy of the addon's old disenchant tables are left out of the counts, still used to match names), turns the results into count-based itemdb records (unknown skill ×0.5 as in D1b), and the compiler replaces older `research:` rows for the same material (35). 72 inputs (37 mill, 31 prospect, 4 disenchant), 371 materials; Saronite and Aqirite match the agents' published numbers. Left out with a reason: unlock-only drops (9), rank-unknown "family" items (181 outputs, 35 inputs), 17 inputs whose studies mix batch sizes (mostly BFA/Shadowlands milling vs mass milling, which their calculator blends: tell the research team).
  - [ ] **D1c2. Family items** (181 estimates, e.g. Cardinalai's 800-cast Midnight Tin/Silver gems): the source didn't say the gem's quality rank. Option: value a family at its cheapest rank's price, labelled "rank unknown". Ask the owner only if it changes what they see.
  - [ ] **D1c3. Unlock-only drops** (9): add them only for characters with the unlock (needs the profession spec API).
  - [x] **D1c4. Research no-disenchant flags** (`f51ad24`, session 16: `tools/research_v3_no_disenchant.py`, run by `research_v3_to_baselines.py`; 219 sourced items, 137 added as `ItemDB.restrictions.researchNoDisenchant`, 82 already in the game-file list; skips corrections.jsonl exclusions, replaced, `imported/`, no ID, no https source; test `tests/test_research_v3_no_disenchant.py`). Original task (session 15): the agents now record items that can't be disenchanted (e.g. `war-within/2026-10-31T1520-delver-gear-no-disenchant.jsonl`, 25 Delver items, record kinds `armor`/`weapon`). `tools/research_v3_to_baselines.py` ignores them. Merge them into `ItemDB.restrictions` (NO_DISENCHANT) at compile time, only adding, never removing a game-file entry.
- [x] **C4b3. Tokens from v3 `token` records** (`07cad1a`, session 15). Owner: "the rewards should be part of the compiler system for updating the itemdb, so when item db is updated so are the [token] rewards"; and the addon should follow what the research reviewer and the Master agreed (their `strategy.md` has **no** token thread; their general rules are followed). `tools/research_v3_tokens.py`, called by `tools/research_v3_to_baselines.py`, writes `tokenRewards` into `database/research-v3-baselines.lua` (IDs `v3token:<tokenID>`, `NOT_REVIEWED`, confidence 90 two pages per reward / 60 one page / −20 list not complete; missing IDs filled by name from `database/research/tokens-midnight-s*.json`; a reward with conflicting IDs is left out). The compiler adds them after any reviewed export records (reviewed wins). `LL:ValidateTokenCatalog` accepts unreviewed lists with ≥1 https source; `TokenPieceQuote` caps disenchant confidence at the list's. 228 tokens, 643 rewards, no conflicts.
  - [ ] **C4b4. Curio exchanges** (7 omni tokens: Chiming Void, Slumbering Coil, Hungering Void, Excessively Bejeweled, Web-Wrapped, Void-Touched, Flame-Warped): the v3 notes don't record the cost, and an exchange catalog record needs costs. Ask the research team (strategy thread) to record the cost, then build them as `kind='exchange'`.
  - Original C4b3 text: convert the agents' v3 token records to `tokenRewards` in the compiler, checked by `LL:ValidateTokenCatalog`, with ≥2 sources and our staged lists (`database/research/tokens-midnight-s*.json`) as the second source.
- [x] **C7. professionRules path done** (`26f9829`): `usable()` / `LL:IsUsableProfessionRule` in ProfessionModels.lua (≥1 unique source, confidence 0–100, not DISABLED/REJECTED) replaces `approved()` for profession and personal patch rules; scaled numbers carry `transformConfidence` = rule confidence, which `ComputeEvidenceModel` already uses to cap material confidence; `result.unreviewedRule` adds "research rule, not yet reviewed" to the adjustment text. Tests: `tests/test_profession_projection.lua` (66 checks, incl. end to end).
- [x] **C7b. Same for the `mechanicRules` path** (`3246cae`, session 15: kept the path and gave it the C7 gate rather than retiring it; research v3 produces no mechanics records yet, so nothing ships. Compiler skips switched-off/unsourced/duplicate-source rules with a reason in `ItemDB.buildReport.mechanicRulesSkipped`, writes `APPROVED` only when the research export carries the full review, else `NOT_REVIEWED`; `NO_NUMERIC_TRANSFORM` now counts as off for both rule paths.) Original task: (fixed ratio per exact target context): compile-time asserts in `tools/compile_itemdb.lua` (~line 178 and ~272, `IsApprovedNumericRule`) and runtime `LL:ApplyVerifiedMechanics` in ConversionEngine.lua (~line 159). Or decide to retire it in favour of professionRules (simpler, fits decision 16) — ask the owner only if it changes what they see.
- [ ] **C7c. Per-stat rules** (Resourcefulness returns inputs, Multicraft adds outputs) so `LL:ProfessionFactor` stops refusing when operation stats differ from the baseline (`'Unmodeled gear, buffs or operation stats'`). Needs research input (D1b) first.
- (Original C7 note:) Let research scaling rules run. The scaling adapter (rules in ItemDB `mechanicRules`, gate `approved()` at the top of `ProfessionModels.lua` (~line 17), applied via ConversionEngine/Database; audit `tools/audit_profession_scaling.lua`, docs/profession-scaling-audit.md) only runs "approved" rules and ships zero. **Correction (session 9):** there are two scaling paths, both gated at "approved, confidence ≥ 90": (a) `ItemDB.mechanicRules`: fixed ratio for one exact target context, compiled from `research.mechanicRules` by `tools/compile_itemdb.lua` (~line 178, asserts the gate at compile time), read in `ConversionEngine.lua` (~line 132) and `Database.lua` (~line 553); (b) `ItemDB.professionRules`: piecewise skill curves plus specialization/equipment factors, from `database/profession-models.lua`, gate `approved()` and `LL:ProfessionFactor` / `LL:ApplyProfessionModel` in `ProfessionModels.lua`. Path (b) matches decision 16 (baseline at minimum skill, scale up with skill); it refuses to run when Resourcefulness/Multicraft/gear/buffs differ from the baseline (`'Unmodeled gear, buffs or operation stats'`), so per-stat rules are a follow-up. Per decisions 1 and 16, run research rules with their confidence (lower the option's confidence), keep the "no double scaling" and "fresh skill beats old gear bonus" guards. Change the strict tests on purpose and say why. Needs at least one real rule from D1b to be useful, but the gate change can come first with a synthetic test.
  - (D1 original task text, done:) Write `claude/research-agent-proposal.md`: simpler prompts for the five agents. Agents submit evidence records only (source link, raw counts, date, patch), lowest-confidence items first; a script computes rates and confidence; no hand-written final numbers. The owner decides whether to apply it to `research/prompts/five-agent/`.
- [x] **D2. GitHub Action** (`6d6ed99`): `.github/workflows/claude-branch-tests.yml` runs `tests/run.sh` with the lupa wrapper on every push to this branch and keeps the test ZIP as a download. First run green. `gh run list --repo Voodoobrew101/Loot-Liquidator --branch LootLiquidatorclaude-V0.1` shows results from the sandbox; downloading the log is blocked (403). GitHub warns the actions (checkout@v4, setup-python@v5, upload-artifact@v4) use Node 20; bump them during E2/E3 if a newer major exists.

**Phase E — Release**

- [x] **E1. Player-facing README and CurseForge description** (`f3ad2ee`: `README.md` for players + short developer section; old README moved to `docs/DEVELOPER-NOTES.md`; paste-ready `CURSEFORGE.md`): what the badges mean, the few settings, TSM required for AH prices.
- [x] **E2. `AFTER_PATCH.md`** (`cb31eab`, repo root. Gap found: no script regenerates WagoClassEligibility.lua / DB2Restrictions.lua from ItemSparse; the guide has the first patch session write `tools/generate_from_itemsparse.py` from an owner-attached Wago CSV): the step-by-step prompt for an AI to update the addon after a WoW patch (bump TOC interface, regenerate WagoClassEligibility and DB2Restrictions, refresh ItemDB, run tests, package, upload).
- [x] **E3. Package a release zip** (`4766c0b`, session 16): `RELEASE-CHECKLIST.md` (install, in-game checks before upload, how to upload); zip built with `python3 tools/package_addon.py dist/LootLiquidator-<version>.zip` (`dist/` is git-ignored; the GitHub Action builds one too). Repeat the zip at the end of any session that changes the addon and send it to the owner.

## 8. Owner questions (keep to one or two, plain words)

- 2026-11-01 (session 16) Could you ask your research helpers to write down what each of the 7 "curio" omni tokens costs at the vendor (for example the Chiming Void Curio at Kirana)? Until they do, the addon shows nothing special for curios (task C4b4).

Answered:
- 2026-10-31 (session 15) Token lists from the research notes → "the rewards should be part of the compiler system for updating the itemdb. so when item db is updated so are the quest rewards", and the addon should follow what the ChatGPT/Claude research discussion agreed (it never covered tokens or token exchanges, the owner noted). Done as C4b3. The session 13 ATT question was dropped: tokens no longer need ATT, and decision 5 already says remove it.
- 2026-10-31 (session 12) Old herbs/ores without numbers → "this is covered by the research team, not here." Don't compile the old TSM numbers; the 97 items stay on the research queue (B2b closed).
- 2026-10-31 (session 12) Confidence display → keep the **percentage** (no "rough / fair / good" words).
- 2026-10-31 (session 12) Who checks the token lists → **the research team**: "somehow they need to be placed so the research team double checks them and places them in itemdb.lua". So the checked token lists come back through the research team's ItemDB export, not hand-approved here (C4b rewritten).
- 2026-10-31 (session 12) Tokens showing "?" → "they have vendor prices, or possibly a disenchant value on the trade-in, depending on what you're talking about." So a token should never be "?": it has at least a vendor price, and the piece it opens into may be disenchantable (task C4c).
- 2026-10-31 Simpler research helpers → yes, with a change: ItemDB gets a minimum-skill baseline and the addon calculates up with the player's skill/stats; research works out baselines and scaling rules before compiling (decision 16; proposal revised; tasks D1b, C7).
- 2026-10-31 Transmog for alts → "any type": the T badge counts an alt for any gear their armor type can wear, not only tier/class-specific pieces (task C5).

## 9. Owner feedback from the game

*(The owner adds in-game results here, or tells the chat, which records them here.)*

- none yet

## 10. What to check in game

*(Filled in at the end of each session.)* After session 16 (version 0.11.0-claude.18). The full before-upload list is in `RELEASE-CHECKLIST.md`.

1. The addon loads with no error pop-ups; the settings menu says "Loot Liquidator v0.11.0-claude.18".
2. Settings → Integrations no longer has an "ATT research fallback" switch or any ATT buttons.
3. Hover a raid tier token with AllTheThings **on**, then **off**: it should look the same both times (V, D or T with a value).
4. Hover a War Within Delver's piece (e.g. Moth-Ridden Slippers) or a Midnight PvP piece (e.g. a Galactic Gladiator's item): it should never suggest disenchanting.
5. Normal disenchantable green and blue gear still shows a disenchant value.

After session 15 (version 0.11.0-claude.17):

1. The addon loads with no error pop-ups and shows version 0.11.0-claude.17.
2. **Turn AllTheThings off** (if you have it), then hover a raid tier token from Midnight, The War Within or Dragonflight that you can't use for transmog. It should show **V** or **D** with a gold value, naming your class's piece.
3. A token whose piece's look you're missing should show **T**, also with AllTheThings off.
4. The "Open, then disenchant" row shows a confidence; for most tokens it's at most 60% for now (only one page backs most lists).
5. If you have Dragonflight **Draconium Ore** (the rank 2 kind) and Jewelcrafting, hover it: Prospecting should still show a value; the numbers may have shifted slightly because a new study arrived.
6. Read the new `README.md` on GitHub (the front page of the repo): tell us if anything in it doesn't match what you see in game.

After session 14 (version 0.11.0-claude.15):

1. The addon loads with no error pop-ups and shows version 0.11.0-claude.15.
2. Hover **Saronite Ore** (or another Wrath ore) with a Jewelcrafter: Prospecting should show a value and a confidence around 50%, and the Breakdown level should list the gems.
3. Hover a War Within or Dragonflight ore/herb you have, e.g. **Aqirite**: it should show a Prospecting/Milling value; some numbers will differ from before because bigger studies now count.
4. Tell us if any herb or ore that had a value before now shows nothing or "?".

After session 13 (version 0.11.0-claude.14):

1. The addon loads with no error pop-ups and shows version 0.11.0-claude.14.
2. Only if you use AllTheThings: hover a raid tier token (for example a Venomforged Idol) that your character can't use for transmog. It should now show **V** ("Open it, then vendor …") or **D** ("Open it, then disenchant …") with a gold value in the first line, instead of "?".
3. On the Alternatives tooltip level, the same token shows the rows "Open, then vendor <piece name>" and, if your character has Enchanting, "Open, then disenchant (Confidence N%)".
4. A token whose piece's look you're missing should still show **T**.
5. Tell us if the piece named is not your class's piece (it should be).

After session 12 (version 0.11.0-claude.13): no addon behaviour changed. The new research-to-database step adds nothing to the addon until your research helpers submit counts, so the shipped database is byte-for-byte the same.

1. The addon loads with no error pop-ups and shows version 0.11.0-claude.13.
2. The session 8 checks below are still the ones that matter.

After session 11 (version 0.11.0-claude.12): no addon behaviour changed (research data, a research checking tool and an automatic test run on GitHub).

1. The addon loads with no error pop-ups and shows version 0.11.0-claude.12.
2. The session 8 checks below are still the ones that matter.

After session 10 (version 0.11.0-claude.11): the scaling switch-on only matters once research supplies scaling rules (none ship yet), so nothing should look different.

1. The addon loads with no error pop-ups and shows version 0.11.0-claude.11.
2. Herbs, ores and disenchantable gear show the same values and confidence as in 0.11.0-claude.10.

After session 9 (version 0.11.0-claude.10): this session only added research lists and a plan; the addon itself is unchanged apart from its version number.

1. The addon loads with no error pop-ups and shows version 0.11.0-claude.10.
2. The session 8 checks below are still the ones that matter.

After session 8 (version 0.11.0-claude.9):

1. The addon loads with no error pop-ups. (Two data files were merged into the main database; nothing should look different.)
2. Hover a piece of gear that can't be disenchanted (for example a holiday ring): the addon should still not suggest disenchanting it.
3. Hover a disenchantable green or blue item: it should still show a disenchant value like before.
4. On a cloth character, hover a tradable (not soulbound) plate, mail or leather piece whose look you haven't collected: it should show the **T** badge and say "Send to <your alt> for transmog", naming an alt who wears that armor type. Turning "Include alts" off should remove that.
5. A soulbound piece your character can't wear should **not** suggest sending it to an alt.

Still worth checking from session 7 (version 0.11.0-claude.8):

1. Hover a few herbs and ores you can mill or prospect. The confidence numbers will look **different** from before (often lower): they now come from how many real casts are behind each number, as in the study notes. Values should still show; nothing should turn into "?" that had a value before.
2. Find a herb or ore where one rank had no answer before (for example, the lower rank of a new Midnight ore). It should now show a value with ", estimated" next to the confidence, and the Breakdown level should say "Estimated from <name> rank N".
3. The first time you hover such an item after logging in, it may take a second hover for the estimate to appear (the game is still loading the item's name). Tell us if it never appears.
4. The addon loads with no error pop-ups.

Still worth checking from session 6 (version 0.11.0-claude.7):

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

- 2026-11-01 (session 16, v0.11.0-claude.18): Took in your research helpers' newest results (now 86 herbs, ores and gear groups instead of 72, and 229 gear tokens). Removed AllTheThings completely: gear tokens now come only from the addon's own database, the ATT switch and buttons are gone from the settings, and your old saved ATT data is left alone but no longer read (C6). Items your research helpers found "cannot be disenchanted" (137 new ones, such as Delver's and PvP gear) now stop the addon from suggesting disenchanting them; nothing was removed from the game's own list (D1c4). Wrote a before-upload checklist and built the release zip (E3). Automated tests pass; needs an in-game check.
- 2026-10-31 (session 15, v0.11.0-claude.16): Took in your research helpers' newest results (a new rank-2 Draconium prospecting study). Made the second kind of "calculate up from your skill" rule work like the first: research rules now run with their confidence shown instead of waiting for a review, and a broken one is skipped instead of stopping the build; none exist yet, so nothing changes in game (C7b). Wrote a player-friendly README and a ready CurseForge description (E1), and a step-by-step guide plus a ready prompt for updating the addon after a WoW patch (E2). Automated tests pass; needs an in-game check. Later the same session (v0.11.0-claude.17): you said token rewards belong in the database build, so now every database update also rebuilds the gear-token lists from your research helpers' notes: 228 tokens across Midnight, The War Within and Dragonflight, each with its confidence, none hand-approved. Tokens no longer need AllTheThings (C4b3). The 7 "curio" omni tokens wait until the research notes record their cost (C4b4).
- 2026-10-31 (session 14, v0.11.0-claude.15): Found that your five research helpers already run on a new, simpler workflow of their own and have collected about 4,000 records, but none of it reached the addon. Built the bridge: the addon's database now takes their results for 72 herbs, ores and gear groups (371 materials), using only real player studies, never TSM's old table or a copy of the addon's own old numbers, and without counting any study twice (D1c). Things it couldn't place safely (gems whose quality wasn't stated, unlock-only gems, herbs where milling and mass milling got mixed) are listed for later, not guessed. Automated tests pass; needs an in-game check.
- 2026-10-31 (session 13, v0.11.0-claude.14): Found the item numbers and names of all 65 Season 2 tier pieces, each from a public page, and settled the evoker question (the "Magmashapers" are the helm, the "Greathorns" are the gloves) (C4a5). Wrote the research team's checking steps for the token lists and made the database builder take the checked lists only from the research team's file, skipping any bad entry instead of breaking (C4b1). Tier tokens no longer show "?": the addon now values them by the piece they turn into, its vendor price or its disenchant value, and a missing look still wins (C4c). Automated tests pass; needs an in-game check.
- 2026-10-31 (session 12, after the work): You answered all four open questions: the old herbs/ores are the research team's job (B2b closed), confidence stays a percentage, the research team checks the token lists and puts them in their itemdb.lua (C4b split into C4b1/C4b2), and tokens should show their vendor price or the trade-in piece's disenchant value instead of "?" (new task C4c).
- 2026-10-31 (session 12, v0.11.0-claude.13): Found the item numbers for all 20 Season 2 tier tokens and the Slumbering Coil Curio, each from its own Wowhead page, plus the names of about half of the tier pieces they turn into; the piece numbers are the next research job (C4a4, C4a5). Built the step that turns your research helpers' counts into the addon's database numbers automatically, with old or uncertain data counting for less and nothing typed by hand (D1b step 2), and wrote their starting to-do list, least-sure items first (D1b step 4). The addon itself is unchanged. Automated tests pass; needs an in-game check.

- 2026-10-31 (session 11, v0.11.0-claude.12): Found the last 14 item numbers for the Midnight Season 1 tier tokens, so the list is complete: all 20 tokens and all 65 tier pieces, each with the page it came from. It still needs someone else to double-check it before the addon uses it (C4a3). Built the first part of the research tool: it checks the research helpers' records and sets bad ones aside with a reason, without deleting anything (D1b step 1). GitHub now runs all the automated tests by itself every time this branch changes (D2). Season 2 tokens are the next research job (C4a4). The addon itself is unchanged. Automated tests pass; needs an in-game check.

- 2026-10-31 (session 10, v0.11.0-claude.11): Filled in the item numbers for the Midnight Season 1 tier tokens and the tier pieces they turn into, with your permission to use Wowhead: 18 of 20 tokens, the omni-token, and 53 of 65 tier pieces. The rest fit the numbering pattern but are kept as unconfirmed hints, not used (C4a2). Switched on the "calculate up from the starting number" part of the addon: research scaling rules now run even before they're reviewed, and their numbers show with lower confidence instead of being ignored. None ship yet, so nothing changes in game until research provides them (C7). Automated tests pass; needs an in-game check.

- 2026-10-31 (session 9, continued): You answered the research-helpers question: the database should hold what a minimum-skill player gets, and the addon should calculate up from your skill and stats, with both worked out by research first. Recorded as decision 16; the plan and tasks (D1b, C7) now follow it.
- 2026-10-31 (session 9, v0.11.0-claude.10): No addon behaviour changed. Wrote down the 35 kinds of old gear the addon has no disenchant numbers for, as a to-do list for research, with a check that keeps the list up to date (C2b). Collected the layout of all 20 Midnight Season 1 tier tokens and the omni-token from public pages; most item IDs still need Wowhead pages that need your approval to open, so they're left blank rather than guessed (C4a, rest is C4a2). Wrote a plan to simplify your five research helpers (D1). Automated tests pass; needs an in-game check.

- 2026-10-31 (session 8, v0.11.0-claude.9): The addon now has one database: the old disenchant estimates and the "can't be disenchanted" list moved inside it, and two separate data files are gone; the numbers are exactly the same (C3). The transmog badge now counts an alt for any armor their armor type can wear, not only tier pieces, as you asked (C5). Gear token data (C4) needs Wowhead pages I couldn't open without your approval, so it's split into collecting the data (C4a) and checking it before it goes in (C4b). Automated tests pass; needs an in-game check.

- 2026-10-31 (session 7, v0.11.0-claude.8): Switched on the new "how sure are we" math: drop chances and confidence now come from counting real casts and drops, weak or old data counts for less, and a missing figure is worked out from the other one at half confidence (C1b). When one rank of a herb or ore has no data, the addon now borrows the other rank's numbers, labelled "Estimated from …", with lower confidence (C2a). Found that borrowing between gear qualities for disenchanting would give wrong materials, so C2b now asks for real data instead. Automated tests pass; needs an in-game check.
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
> Continue the Loot Liquidator work. Clone https://github.com/Voodoobrew101/Loot-Liquidator, check out branch `LootLiquidatorclaude-V0.1`, open `claude/HANDOFF.md` and follow it exactly. You have my permission to open pages on https://www.wowhead.com/ and https://warcraft.wiki.gg/ for research (item IDs, token rewards, drop data). Go.