# Numeric QA delta — 2026-11-01 16:59 PST (Master)

Research head inspected before write: `e23ee6f53f93941634a51d7fc4e35cebbe40b0c6`. This is a **research-only coordination delta**, not a freshly executed estimator, compiler or offline tooltip fixture. Source evidence file `research/v3/evidence/legacy/2026-11-01T1644-matching-tbc-armor-weapon-looter.jsonl`, Git blob SHA-1 `b64b7d65ab8736164cefa0c7af9f4cfdeb70c801` (16 records, five item cohorts). Candidate compiled runtime: `LootLiquidatorclaude-V0.1` blob `63f8259572ee17ec6829ee35a1d05d0c6ca0d29f` is **populated** (1,527,713 characters), older research source `9a22e2787ec133419bad9bce66d036219e2439a4`; installed player build remains unidentified. Current v3 committed estimates Git blob `15ae8c5b7f7b2587ceff1dcd3e8b9d13d4351d1e`, 1,180 estimates, still older than new evidence.

## Newly documented source fields (not yet runtime-closed)

All five are historical TBC cumulative Wowhead Looter snapshots with `casts` reported as completed disenchant operations, `castsWithDrop` reported for each material, `totalQuantity=null`, and no complete 0/1/2/... histogram. They do **not** supply measured unconditional expected units.

| Input | Operations | Output ID: hits (reported range) | Listed hits vs operations |
| --- | ---: | --- | --- |
| 25003 Bloodfist Legplates | 5,419 | 22445:3920 (2–8); 22446:1190 (1–3); 22449:157 (1–2); 22447:100 (2–3) | 5,367 vs 5,419 |
| 30364 Resonating Axe | 188 | 22446:132 (1–2); 22445:26 (2–5); 22449:1 (unknown) | 159 vs 188 |
| 24880 Der'izu Chestpiece | 2,117 | 22445:1632 (2–6); 22446:375 (1–3); 22449:52 (unknown); 22447:14 (2–3) | 2,073 vs 2,117 |
| 25206 Berserker Axe | 934 | 22446:690 (1–3); 22445:202 (2–5); 22449:27 (unknown) | 919 vs 934 |
| 30363 Warp-Shielded Hauberk | 24 | 22445:10 (2–5); 22449:1 (unknown) | 11 vs 24 |

These are **listed hit counts**, not a complete outcome partition: missing entries are not zero-result disenchants, and possible joint outputs must not be assumed mutually exclusive. Do not sum repeated cumulative snapshots as independent cohorts. The source date, actual item level/bonus ID, current eligibility and skill are unknown. No P(hit) or expected-unit number was calculated in this Master report; the existing estimator must use compatible denominators and provenance after reviewed mapping.

## Two source checks and version conflict

1. `25003 -> 22445`: original https://www.wowhead.com/item=25003#disenchanting was blocked by automated JS/robot protection; exact 5,419/3,920 **not independently verified**. https://warcraft.wiki.gg/wiki/Bloodfist_Legplates shows current item level 32, whereas worker notes historical TBC level 111. Historical https://wotlk.evowow.com/?item=25003 gives Arcane Dust context; current https://wowpedia.fandom.com/wiki/Bloodfist_Legplates shows Soul Dust / Lesser Mystic Essence / Small Glowing Shard. This is an epoch/mapping warning, not proof worker transcription is wrong.
2. `30364 -> 22446`: original https://www.wowhead.com/item=30364#disenchanting returned JS/robot protection; exact 188/132 **not independently verified**. https://wowwiki-archive.fandom.com/wiki/Resonating_Axe shows historical item level 108 and different old TBC material proportions; https://wowpedia.fandom.com/wiki/Resonating_Axe shows item level 31 and newer outputs. Require source build/eligibility confirmation.

## Current four-way gap classification

- **Absent adequate numeric evidence:** 236761 -> 245807 is 4.5/10-herb mill starting guess, 0 measured study casts; 24995 -> 22445/22446/22449 remains historical-version ambiguous. New 25003/30364 have hits but no total units/histogram or verified current Retail version.
- **Usable evidence not imported:** New 25003,30364,24880,25206,30363 hit-only evidence has no entries in the older 1,180-row committed estimates; candidate runtime has no exact input keys for these five. Do not import as current Retail until build is resolved.
- **Bad/ambiguous mappings:** 237362 Umbral Tin has 800-cast measured family outputs but rank-specific 242606/242607/242610/242611/242786/242788 remain 0-study-cast starting guesses; Serevite 190394/190395/190396 rank disagreement; historical TBC disenchant output and item-level versions require validation.
- **Import/display-only:** 237362 measured family expected quantities have heuristic `chanceSource=estimated` without per-output hit counts; 45661 appears only as research candidate, not verified token reward mapping; actual tooltip fixture and deployed addon version are not verified.

## Closure gate and handoff

Research-only delta: 16 records now expose raw hit denominators/ranges, with 0 new verified runtime closures. Before any reviewed PR/import, pin evidence blob above, `estimates.json` blob, candidate runtime blob and current addon branch; run `research/v3/tools/build_estimates.py`, validator, compiler and **actual offline tooltip fixture** in a checked-out runner; record immutable SHA-256 checksums, source revision, input/output rank/skill/batch/patch, and measured-vs-prior status. Validate `E[units]=P(hit)*E[units|hit]` only when same process/output has compatible hits and unit totals. GitHub read-only connector and local DNS failure prevented running estimator/fixture here. No production merge, release, gold EV or disabling validation.
