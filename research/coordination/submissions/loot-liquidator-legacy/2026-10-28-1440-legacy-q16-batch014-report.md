# Loot Liquidator Legacy — Batch014, queue revision 16
2026-10-28 · research/processing-confidence · worker-only additive evidence and submissions

## Assignment and actual results
**40/40 exact assigned stable keys audited**, queue `2026-10-28-batch014-legacy`, revision 16; **33/33** assigned GameData source-line/output identities matched pinned production source blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`. Categories: 1 already-accepted Titanium Powder, 6 Legion Felslate rare, 12 WotLK Cobalt/Titanium, 12 MoP Trillium, 3 Dragonflight overflow, 6 master-directed Midnight Crushing recipe candidates. **0 new valid input/output mappings**, **0 current-Retail measured cast-level fields**, **0 full current-neutral four-field tuples**, **1 newly distinguished independent historical source cohort (Traziz)**. Four canonical source-only observations capture 3 original author families, with pre/post Reddit reports as one author study. No production or master-owned changes.

## P0: Six Legion Felslate rare outputs — original per-output reconciliation
Original Deckven comment on [Legion Jewelcrafting Guide](https://www.wowhead.com/guide/legion-jewelcrafting) reports **3,200 Felslate** processed using **Mass Prospect**, with original output totals below. It is already known in source memory; this is a new exact assigned-key reconciliation, **not a new study**. Actual completed mass crafts, zero-inclusive histograms, skill and patch/build unknown. The derived 640 five-ore equivalents are **not 640 measured standard casts**. GameData TSM imports six 0.0100 expected units per nominal five ore each and source P=0.01, positive range [2,5]. That tuple violates E≥P×min (0.01<0.02). Keep original TSM claims separately, not as measured fields.

| Rare output ID | Deckven units / 3200 ore | Historical E / nominal 5 ore | TSM E5 | Independent Traziz E5 |
|---|---:|---:|---:|---:|
| 130178 | 17 | 0.026562 | 0.010000 | — |
| 130179 | 19 | 0.029687 | 0.010000 | 0.300 |
| 130180 | 15 | 0.023438 | 0.010000 | — |
| 130181 | 16 | 0.025000 | 0.010000 | — |
| 130182 | 24 | 0.037500 | 0.010000 | 0.250 |
| 130183 | 25 | 0.039063 | 0.010000 | — |

The newly separated **Traziz** original comment on the same guide reports **100 Felslate at Jewelcrafting skill 752**, including **6 Eye of Prophecy (130179)** and **5 Maelstrom Sapphire (130182)**. Derived E5 = 0.300 and 0.250, respectively; these are much higher than Deckven's 0.029688 and 0.037500. This is an independent author/cohort, **not** a matched profession/patch comparison, and it has no per-cast histogram. Source: https://www.wowhead.com/guide/legion-jewelcrafting.

The already archived [September 8, 2016 original Reddit study](https://www.reddit.com/r/woweconomy/comments/51ovfk/possible_prospecting_nerf/) provides **25 separate 1,000-ore batch totals from one author**, with a reported hotfix break: first 15 batches 560 rare gems / 15,000 ore (E5=0.186667), last 10 batches 97 / 10,000 ore (E5=0.048500). Historical family yield falls 74.0% in this reported window. Deckven's six-rare family E5=0.181250 is close to the earlier 0.186667, but Mass Prospect versus manual, skill, hotfix and date are unmatched. **No universal 0.26 profession multiplier or per-output chance can be inferred.** Reddit family totals have unknown gem IDs; no allocation to individual gem outputs.

## P0/P2: All 33 historical TSM numeric tuples fail a necessary invariant
At each of the 33 exact assigned GameData source lines, the imported P, positive min/max and E (5×amountOfMats) cannot simultaneously hold. For nonnegative integer output X with positive range [a,b], **P×a ≤ E ≤ P×b**. Disjoint groups:
- **12 WotLK Cobalt/Titanium uncommon:** P=.235, E=2.5, [1,2]; upper bound .47. Six Titanium original ZeRoTaCtIcS gross-ore historical E5 references are preserved; six Cobalt E remain unknown.
- **12 MoP Black/White Trillium rare:** P=.16, E=.1705, [1,1]; upper bound .16. E=.1705 is retained as a low-confidence TSM-only provisional reference, not measured current-Retail E.
- **6 Legion Felslate rare:** P=.01, E=.01, [2,5]; lower bound .02; historical Deckven gross-ore E5 supplied as separate contextual alternative.
- **3 Dragonflight overflow diamonds:** P=.0142, E=.014, [1,2], so P>E even before rank-specific alternative duplication. The compiler may already quarantine some of these; **do not double count compiler corrections**.

These are **33 source contradictions**, not 33 newly discovered mappings, and not a license to silently change P, E or min/max. Current Retail source-appropriate probabilities and positive bounds remain unknown.

## Titanium Powder and original Titanium uncommon evidence
The exact assigned powder key `retail12.0.5:prospect:36910:46849:globalmenace` is **already master-accepted**: 143 powder/1,000 gross ore, E5=0.715, current patch and actual casts unknown. ZeRoTaCtIcS' historical 66-stack Titanium experiment gives six uncommon gem totals 69,60,77,64,59,71 over 1,320 gross ore; their derived E5 are in the audit. Both are reused source lineages, not new measurements. Historical pricing can reverse liquidation decisions, but **no live AH prices or current Retail gold flip were checked**.

## Six master-directed Midnight Crushing overflow keys
Spell [1231132](https://www.wowhead.com/spell=1231132/midnight-crushing) describes **3 selected Midnight gems** and **1 Dusk-Shrouded Stone** as an additional reagent, not one-input prospecting. Six assigned gem item IDs (242553,242723,242554,242722,242607,242720) are only candidate eligible inputs. Spell text supports the family and recipe structure, **not per-ID eligibility or rank-specific Gemdust outputs** (242620/242621). No unassigned worker keys claimed; no new mapping created. Verify exact selected gem ID/rank, stone ID/rank, learned skill, and per-cast Gemdust outcomes before master admission.

## Source lineage, QA, and next exact IDs
- Reused source families: Deckven 3,200 mass Felslate, Reddit 25,000 pre/post Felslate, ZeRoTaCtIcS Titanium, globalmenace Titanium Powder, historical GameData TSM. **One newly separated independent author cohort:** Traziz 100 Felslate with skill 752. Same Wowhead URL is not independent by itself; authors/cohorts distinguish evidence.
- Avoided refetching known translated/derivative copies; reused canonical source-memory and archived master batch012/013 QA. MoP Wowhead comments' 17% rare estimate has no original denominator and is not promoted to assigned numeric P.
- Original source evidence remains source-only where actual casts, skill, build or zero/hit outcomes are missing. All 40 audit records retain separate four fields with null unknowns and original source claims; no fabricated zero or midpoint, no double P×E.
- **Next IDs:** Felslate 123919→130179/130182 (independent skill-stratified observations), Titanium Powder 36910→46849, Cobalt 36909→36917/36920/36923/36926/36929/36932, Trillium 72094/72103→76130/76133/76134/76135/76136/76137, DF diamonds 189143→192871 and 190311→192870/192871, Crushing 242553/242723/242554/242722/242607/242720 → exact verified Gemdust ranks.
- Master baseline (pre-review): **976 provisional staged mappings**, 791 four-field numeric complete, 396 unknown numeric cells, 0 current unskilled verified; independent exhaustive Retail universe audit remains incomplete. This worker does not update central counts.

**QA:** 40 unique exact assignment keys; 33/33 source lines verified; 33/33 source tuple contradictions detected; 6 Felslate original output IDs and totals; 2 independent historical author cohorts on one Wowhead guide; pre/post batch totals 560 and 97; no unverified new mapping or current Retail numeric promotion. Node, Lua and WoW client tests not executed. Evidence confidence scores reflect support, not statistical accuracy.
