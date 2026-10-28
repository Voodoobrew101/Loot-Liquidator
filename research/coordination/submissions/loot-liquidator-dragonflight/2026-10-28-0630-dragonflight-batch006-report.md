# Dragonflight Batch 006 — 2026-10-28 06:30 PDT

Master queue revision 8, assignment 2026-10-28-batch006-dragonflight; 40/40 disjoint assigned source-output keys reviewed (35 input 194545, 5 input 199344). Actual main GameData.lua blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e` and source lines 1516–1557 read. Read canonical progress, creation prompt, numeric protocol/schema, mechanics and API registries, evidence schema/observations, Issue #2 and existing overlays. No unassigned scope claimed.

## Output findings
- All 40 source line/output IDs match; all 40 historical TSM proxy tuples pass the necessary `P*min <= E <= P*max` bound using `E = 5*amountOfMats`. This is a conditional **assumption** about native TSM units, not verified probability or 2026 Retail drop rates. No chance double multiplication.
- 12 complete three-rank gem groups repeat the same TSM proxy and mean across all quality IDs. For input 194545, outputs 192837/192838/192839 each have p proxy .25 and E .356 per five input units. They cannot be independently summed without an observed rank-selection model.
- Input item IDs 194545 and 199344, exact recipeSpellIDs and prospect eligibility remain **unverified externally**; do not invent their names or batch validity. Full 40-row audit with four independent scores: P 25, min 30, max 30, E 30; weakest 25. All EXAMINED_INSUFFICIENT. No >=90 records or verified current-Retail correction.

## Separate numerical mechanics hypothesis
`dragonflight-inspiration-quality-transition` remains **VERIFIED_QUALITATIVE / BLOCKED**. Original Dec 12 2022 source https://www.reddit.com/r/woweconomy/comments/zkay8v reports 1000 Serevite R2 prospects, skill 171, Inspiration 18%, Resourcefulness 3%, 1255 Fractured Glass and 1427 Crumbled Stone; historical means 1.255 and 1.427 per actual cast. The same thread contains a Dec 13 50,000-ore study at skill 210, Inspiration 23.7%, Resourcefulness 4.1%; its 10,000 five-ore equivalents are **not confirmed actual casts**. Both cohorts have rank-specific gem totals preserved by original names, not guessed item IDs. No per-cast Inspiration flags or zeros, and cohorts are confounded. Blizzard's July 2024 update removed Inspiration (https://worldofwarcraft.blizzard.com/en-gb/news/24119590). No 2022 Inspiration formula can be applied to 2026 Retail. Two source-only observations archived; not counted as first-pass assigned outputs.

## Blockers and exact next targets
1. Verify 194545 and 199344 item identities, exact current Retail Dragon Isles prospect recipe ID, eligibility, nominal batch and output item-rank mapping with recipe schematic and in-game salvage candidate APIs.
2. Retrieve original TSM native rate units; `matRate` is a historical proxy, not a measured hit fraction.
3. Capture >=200 real same-build casts per eligible input/skill condition, with exact zero-inclusive per-cast output IDs/ranks, saved inputs, actual skill, gear, specializations, recipe operation stats and client build. Repeat controlled second skill condition. For old Inspiration, require actual 2022 per-cast proc flags and matched controls.
4. Master independently review these 40 submitted keys before advancing central first-pass ledger. Await next explicit assignment.

## Validation and boundaries
40/40 ID and arithmetic assertions, 12 quality triplets, zero forbidden promotions; structural presence checks only. Full JSON Schema, repository Node tests and in-game tests NOT RUN. No main, production GameData.lua, TOC, addon Lua, central ledgers, master assignments/PROGRESS or mechanics registry changed. Future single database is itemdb.lua only after approved QA/migration.
