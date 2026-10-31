# Proposal: simpler prompts for the five research agents (task D1)

**Status: revised after the owner's answer (2026-10-31, session 9).** Nothing here changes the research branches or the agents yet.

**Owner's answer, in their words:** "the addon should receive a baseline number which is roughly what a person with minimum required skill would have drop. The addon should calculate up as the player increases in relevant metrics. These metrics and baselines should be determined through the research process before ItemDB is compiled."

So the plan is:

1. **Research produces two things per item/method before ItemDB is compiled:**
   - a **baseline**: drop chance, average amount and min/max for a player with the *minimum skill needed to do it* and no optional bonuses;
   - **scaling rules**: which player numbers raise the result (skill above the minimum, Resourcefulness, Multicraft, specialization points, profession gear, etc.) and by how much.
2. **The addon** reads the player's own numbers from Blizzard's profession API and calculates up from the baseline using those rules. This uses the existing scaling layer (`mechanicRules` in ItemDB, gated by `approved()` in `ProfessionModels.lua`), which today ships zero rules.
3. **Agents collect real counts with a link *and the context of whoever did the casts*** (skill, stats, gear). A research script then works the baseline and the scaling rules out from those counts. Agents still never type a final number.
4. The player's own recorded casts still feed in on top (recorded with their skill and stats, so they are compared with the right scaled number).

## 1. In plain words

Right now the five agents follow about 3,000 words of rules (in `research/prompts/five-agent/` on the `implementation/five-agent-completion` branch). They write their own final numbers and their own 0–100 "confidence" scores, and keep three separate channels (evidence / working estimates / economic use) behind a "90 or nothing" gate.

The addon no longer works that way. Since sessions 1–7 on this branch it:

- shows every estimate with its confidence (owner decision 1), so there is no "preview only" channel any more;
- works out drop chances and confidence **itself** from counts of casts and drops (`LL:CountsEstimate`, `LL:RateConfidence` in `Database.lua`), weighting weak or old sources down instead of throwing them away (decision 15).

So the agents only need to do one thing well: **find real counts and write them down with a link.** A script turns counts into the numbers the addon ships. Nobody types a final rate or a confidence score by hand.

What this gives the owner: shorter prompts, less time spent on paperwork, every number traceable to a link, and agents that work on the items where the addon is least sure.

## 2. The one rule set (replaces `common.md`)

1. **Submit evidence records, not numbers.** One record = one source's raw counts for one item and method (format in section 3). Never write a final drop chance, average or confidence.
2. **Lowest confidence first.** Work from the queue in section 5, top down.
3. **Every record has a link.** No link, no record. Reposts and copies of the same data are the same source: give them the same `lineage`.
4. **Write down who did the casts.** Skill, specialization points, Resourcefulness, Multicraft, profession gear and patch, as far as the source says. A sample at a known skill is worth much more than one at an unknown skill, because it is what lets the script separate the baseline from the scaling.
5. **Write down what you don't know.** Unknown skill, patch or date is `null`, not a guess. Old or pre-hotfix data is still useful: submit it and set `stale: true`. The script counts it at a quarter weight.
6. **Small whole numbers for amounts.** Record the smallest and largest amount seen; don't model a range.
7. **One file per run**, never edit another agent's files or the addon branch (`LootLiquidatorclaude-V0.1`). Never force-push.
8. **If two searches in a row find nothing new for an item, move to the next item.** Say so once in the run report.
9. **Stop and report** instead of guessing an item ID, recipe or output.
10. **Mechanics evidence counts too.** Blizzard patch notes, profession talent text ("+X% Resourcefulness"), and controlled comparisons (same item, two skill levels) are evidence for scaling rules. Record them as mechanics records (section 3b).

## 3. Evidence record format

One JSON object per source per item/method. Put a run's records in `research/evidence/v3/<agent>/<UTC-date>-<short-name>.json` as a list. (The `//` comments below only explain the fields; leave them out of real files.)

```json
{
  "method": "Prospect",              // Disenchant | Mill | Prospect | Smelt | Craft | Exchange | Open
  "input": 36912,                    // input item ID (or a gear key like "gear:9:4:armor" for disenchanting)
  "inputPerCast": 5,                 // how many inputs one cast uses
  "casts": 412,                      // completed casts actually counted (include casts with no output)
  "outputs": [
    { "item": 36917, "castsWithDrop": 74, "totalQuantity": 81, "min": 1, "max": 2 }
  ],
  "source": "https://...",           // the page / log / spreadsheet the counts come from
  "lineage": "wowhead-comments-2024-user123", // same value for reposts of the same data
  "observedDate": "2025-08",         // when the casts were done, if known, else null
  "patch": "11.2.0",                 // game patch of the casts, if known, else null
  "stale": false,                    // true for pre-hotfix or clearly outdated data
  "skill": null,                     // profession skill if stated, else null
  "minimumSkill": null,              // skill needed to do this at all, if known
  "stats": {                         // whatever the source states, else null / leave out
    "resourcefulness": null, "multicraft": null,
    "specPoints": null, "gearBonusSkill": null
  },
  "notes": "Counts read from the 'Prospected from' tab, 412 samples."
}
```

### 3b. Mechanics records (for scaling rules)

```json
{
  "kind": "mechanic",
  "profession": "Jewelcrafting",
  "metric": "resourcefulness",       // skill | resourcefulness | multicraft | specPoints | gear | other
  "effect": "Chance to refund part of the input; refunded amount ~30% on proc",
  "appliesTo": "Prospect, Midnight ores",
  "numbers": { "procPerPoint": null, "refundShare": 0.3 },  // only numbers the source states
  "source": "https://...",
  "patch": "12.0.5",
  "notes": "Talent tooltip text, quoted in our own words."
}
```

Rules the script checks (a record that fails is set aside with a reason, not deleted):

- `casts` > 0; `castsWithDrop` ≤ `casts`; `totalQuantity` ≥ `castsWithDrop`; `min` ≤ `max`.
- `source` starts with `https://`.
- Item IDs are positive whole numbers.
- If only a percentage is published, give it with the sample size: `"chance": 0.18, "casts": 50`. Without a sample size, set `casts` to `null`; the script then treats it as a weak guess (about 20 casts or fewer), exactly like the addon does today (`LL:EvidenceCasts`).

## 4. The five roles (same five automations, new short texts)

Keep the existing schedules and names. Replace each prompt with the shared rules (section 2) plus one paragraph:

| Automation | New role | Paragraph to paste |
| --- | --- | --- |
| Master | **Coordinator** | "Each run: read the new evidence files since your last run, run the evidence checks, and update `research/evidence/v3/QUEUE.md` (section 5) so the lowest-confidence items are on top. Write a five-line status: records added, records set aside and why, items whose confidence went up, the top five queue items, blockers." |
| War Within (alternative) | **Mechanics researcher** (use this instead of a second item researcher if the owner prefers) | "Find how player numbers change results: minimum skill per method, and what skill above minimum, Resourcefulness, Multicraft, specialization points and profession gear do. Submit mechanics records (section 3b) and samples at known skill levels." |
| Midnight | **Current-expansion researcher** | "Collect evidence records for Midnight items from the queue: herbs, ores, disenchanting of Midnight gear, tier tokens. Prefer large public samples with a stated sample size (for example Wowhead item tabs that list how many times something was seen) and players' exported results." |
| War Within | **Recent-expansion researcher** | "Same as the Midnight researcher, for The War Within and Dragonflight items in the queue." |
| Dragonflight | **Old-expansion researcher** | "Same, for Classic through Shadowlands items in the queue. Start with the disenchanting gaps in `database/research/disenchant-gaps.lua`, then the 97 old herbs/ores that only had TSM numbers. Old data is fine: mark it `stale` when it predates a known change." |
| Legacy | **Checker** | "Pick five records added by other agents since your last run. Open each link and confirm the counts match the page. Add a short check record (record ID, `confirmed` or `mismatch`, what you saw). Never fix another agent's record yourself; report it." |

## 5. The queue (what to research, in order)

The coordinator keeps `research/evidence/v3/QUEUE.md`, sorted lowest confidence first. Starting list:

1. **Midnight tier token item IDs and reward IDs** (`database/research/tokens-midnight-s1.json`, task C4a2): 17 token IDs, the Chiming Void Curio ID, and about 65 reward IDs. Two links each.
2. **Disenchanting groups with no data at all** (`database/research/disenchant-gaps.lua`, 35 groups). Start with `gear:9:4:armor` (Dragonflight purple armor; the weapon version already has data), then Battle for Azeroth to Shadowlands, then Cataclysm to Legion, then Classic/TBC by item-level band.
3. **Midnight herbs and ores whose numbers are only "estimated from" the other rank** (shown in the addon's tooltip as ", estimated").
4. **The 97 Draenor/Legion-era herbs and ores** that only had TSM's old numbers (waiting on the owner's answer to B2b; research can start anyway).
5. Everything else, by lowest confidence.

## 6. What the script does (to be built, task D1b)

A small tool on this branch (`tools/evidence_to_itemdb.py` or `.lua`), run **before** `tools/compile_itemdb.lua`, that:

1. reads every `research/evidence/v3/**/*.json` record and applies the checks in section 3; **built (D1b step 1, session 11): `tools/evidence_check.py`, tests in `tests/test_evidence_check.py`.** It also accepts Checker verdicts as `{"kind": "check", "recordId": "<file>#<position>", "result": "confirmed"|"mismatch", "saw": "..."}` and rejects unknown field names (to catch typos);
2. groups records by method, input and output; adds casts and drops per lineage (copies count once);
3. **works out the scaling rules** per profession/method from the mechanics records and from samples at different known skill/stat levels (simple fits only: e.g. "yield +x% per 10 skill above minimum", "Resourcefulness refunds y% on proc"); each rule keeps its sources and a confidence from how much data supports it;
4. **turns every sample back into a baseline-equivalent count** (what a minimum-skill player would have got) using those rules; samples at unknown skill count at reduced weight, the same way the addon already down-weights weak sources;
5. writes into the ItemDB source: the baseline counts per item (so the addon's counting math sets the baseline rate and confidence) and the scaling rules into `mechanicRules`; nothing is typed by hand;
6. prints a short report: records used, set aside (with reasons), rules found, and the confidence change per item.

In the addon, the result is: baseline from ItemDB → scaled up with the player's own skill and stats (Blizzard profession API) → the player's own recorded casts added on top.

Already in place: the counting math (`tests/test_counts_model.lua`: 20-cast starting guess, real counts on top, stale data ×0.25, confidence = chance the true rate is within ±5 points), the minimum-skill check (`minimumRecipeSkill` in `Database.lua`), and a guarded scaling adapter with 13 passing synthetic tests (`tools/audit_profession_scaling.lua`). **Missing:** any real rules, and the gate that only runs "approved" rules needs the same treatment owner decision 1 gave estimates: run research rules with their confidence shown, instead of not at all (task C7).

## 7. What is dropped from the current prompts, and why

| Current rule | Why it can go |
| --- | --- |
| Agents assign a 0–100 confidence score | The addon computes confidence from counts; hand scores can't be checked. |
| Three channels and `PREVIEW_ONLY` / 90 gate | Owner decision 1: show every estimate with its confidence. |
| Agents compile and fill "working estimates" (confidence 0 fallbacks) | The addon already fills a missing chance/average from the other one and borrows from the other rank, with lower confidence. |
| Long context/typing contract, model families, holdouts | Replaced by a short required context (skill, minimum skill, stats, patch) and the script's simple fits. The idea of a minimum-skill reference baseline is **kept**: the owner asked for exactly that. |
| Scorecards with many counters | One five-line status per coordinator run. |

What is **kept**: never invent IDs or outputs, keep history, honest nulls, an independent checker, never force-push, one file per run.

## 8. Next steps (owner agreed to the direction, with the baseline + scaling change)

1. Claude builds the script (D1b) and the starting `QUEUE.md` on this branch, and lets the addon run research scaling rules with their confidence (C7).
2. Claude prepares paste-ready text, one block per automation; the owner pastes them in.
3. Agents write to `research/evidence/v3/`, a new folder, so nothing they did before is overwritten.
