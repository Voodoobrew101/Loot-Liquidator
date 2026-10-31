# Research queue (lowest confidence first)

> **Not read by the agents (session 14).** The research agents were switched to their own v3 workflow in
> `research/v3/` on `implementation/five-agent-completion` (rules there: `research/v3/README.md`).
> This branch takes their results through `tools/research_v3_to_baselines.py` (task D1c). Kept for the record.

The **Coordinator** keeps this file up to date each run (see `claude/research-agent-proposal.md`, sections 4–5).
Work from the top down. When two searches in a row find nothing new for an item, move on and say so in your run report.
Submit evidence records only (`research/evidence/v3/<agent>/<UTC-date>-<short-name>.json`), never final numbers.

Starting list written by Claude, session 12 (2026-10-31). Nothing has been researched under v3 yet.

## 1. Tier tokens: independent check

Both lists are complete (session 13): Season 1 and Season 2, 20 tokens + 1 curio + 65 tier pieces each, every ID
with the page it came from. **Follow `research/evidence/v3/TOKEN-CHECK.md`** (steps and the exact export format).

- **Checker:** confirm every ID in `database/research/tokens-midnight-s1.json`. Start with **249960**
  (Luminant Verdict's Greaves): its name was cut off in the snippet it came from.
- **Checker:** confirm every ID in `database/research/tokens-midnight-s2.json`. Weakest: the 52 piece IDs from
  MythicDrake item URLs only. The evoker head/hands question is settled (Magmashapers = head); confirm anyway.
- Each confirmed token goes into your ItemDB export (`research/proposed/itemdb.lua`, list `tokenRewards`).
  A mismatch gets a `check` record with `"result": "mismatch"` instead.
- **Owner decision (2026-10-31):** the research team double-checks these token lists and puts the checked
  result into its ItemDB export; Claude never marks them approved.

## 2. Disenchanting groups with no data at all

From `database/research/disenchant-gaps.lua` (35 groups; the test there fails when the list drifts).
Use gear keys like `"input": "gear:9:4:armor"` and always end them in `:armor` or `:weapon`.

1. `gear:9:4:armor` — Dragonflight epic armor (the weapon version already has data: confirm the materials match).
2. `gear:9:3` — Dragonflight rare (blue) armor and weapons.
3. Battle for Azeroth to Shadowlands: `gear:7:3`, `gear:7:4`, `gear:8:3`, `gear:8:4` (armor and weapon).
4. Cataclysm to Legion: `gear:3:4`, `gear:4:3`, `gear:4:4`, `gear:5:3`, `gear:5:4`, `gear:6:3` (armor and weapon).
5. Classic and The Burning Crusade (`gear:0:*`, `gear:1:*`): materials change with item level, so one record per
   item-level band; say the band in `notes`.

## 3. Midnight herbs and ores shown as ", estimated"

These borrow their numbers from the other quality rank of the same herb/ore. Real Mill / Prospect / Smelt counts for
each rank replace the borrowing. Record the skill and stats of whoever did the casts; a sample at the **minimum skill
with no bonuses** counts double compared with one at unknown skill.

## 4. The 97 Draenor/Legion-era herbs and ores with no milling/prospecting numbers

They only had TSM's old table, which the addon no longer uses (task B2b, waiting on the owner). Old data is fine:
mark it `"stale": true` when it predates a known change.

## 5. Everything else, by lowest confidence

## Status

| Run | Records added | Set aside | Items whose confidence went up | Blockers |
| --- | --- | --- | --- | --- |
| (none yet) | | | | |
