# Research queue (lowest confidence first)

The **Coordinator** keeps this file up to date each run (see `claude/research-agent-proposal.md`, sections 4–5).
Work from the top down. When two searches in a row find nothing new for an item, move on and say so in your run report.
Submit evidence records only (`research/evidence/v3/<agent>/<UTC-date>-<short-name>.json`), never final numbers.

Starting list written by Claude, session 12 (2026-10-31). Nothing has been researched under v3 yet.

## 1. Tier tokens: independent check and the last IDs

- **Checker:** confirm every item ID in `database/research/tokens-midnight-s1.json` against its link (task C4b).
  Start with **249960** (Luminant Verdict's Greaves): its name was cut off in the snippet it came from.
- **Checker:** confirm the 20 Season 2 token IDs (270910–270929) and the Slumbering Coil Curio (270909) in
  `database/research/tokens-midnight-s2.json`.
- **Midnight researcher:** the Season 2 file still needs all 65 tier-piece item IDs and 31 missing piece names (task C4a5).
  First settle the evoker conflict: is "Calamitous Echo's Ebon Greathorns" the hands or the head piece, and
  "Calamitous Echo's Magmashapers" the other one?
- Token records are not evidence records: report IDs in the research files above, with the page each one came from.

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
