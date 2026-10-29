# Master QA batch027 — queue29 and queue30 evidence-first reassignment
**2026-10-29 · research/processing-confidence · RESEARCH ONLY**

## P0 deterministic candidate compiler
Fetched the live `research/tools/compile_itemdb.js`, tooltip channel, fallback validator and all 15 canonical inputs from GitHub. Executed the actual compiler **twice** in isolated V8 with in-memory Node-module adapters. Both builds returned the same 748,411-character Lua and identical report. `validate(records)` returned no errors, 1,202 source identities passed, 1,015 mapping records generated, and tooltip fallback economic isolation reported true. GitHub read-back of the existing committed Lua confirmed 748,411 characters and matching beginning/end, but **full byte equality of the new output to the committed Lua was not independently established**. The research-stage candidate is unchanged because no numeric promotion or new mapping passed QA. The repository's actual `research/tests/test_compile_itemdb.js` regression source was also executed in isolated V8 with mocked Node `fs/path/assert` adapters: **590/590 assertions passed**. The test's committed-file read fixtures were supplied from the freshly compiled output, so those particular self-comparison assertions do not establish independent GitHub byte equality. Native Node CLI, standalone Lua interpreter and WoW client were not run. Do not claim these tests passed.

## P1 independently audited worker queue29
Read LIVE queue revision 29, four worker q29 reports and JSONL submissions, previous master verdict, source-memory and research lessons. **36/36 exact stable keys matched** the assignment, with 36 distinct keys, 144/144 exact-current-context numeric fields explicitly null, zero invented zeros and no new admitted mappings. By worker: Midnight 6, War Within 6, Dragonflight 12, Legacy 12.
- **24/24** applicable TSM `GameData.lua` output lines independently checked against the main blob: Dragonflight 1975–1977, 1980–1982, 1985–1987, 1990–1992; Legacy 1998–2009.
- **6/6** TWW input parent blocks checked at main lines 265, 267, 269, 271, 273, 275. Their materials are empty: the source blocks do **not** independently establish the output IDs; curated pairs remain provisional. The two Mycobloom historical cross-rank pairs have no GameData output-line credit.
- Original September 2024 Mycobloom R1→Nacreous R2 evidence clarifies an earlier incomplete source review; original 2024 per-herb ratios do not establish 2026 completed-cast E.
- Dragonflight three quality-rank source rows repeat 0.7; summing them as guaranteed independent outputs risks rank triple-counting. Prismatic Leaper four families repeat 0.1723 across three quality ranks; hypothetical gross-input interpretation gives 10.338 versus 3.446 if rank alternatives are collapsed. These are risk illustrations, not validated yields or a proven live recommendation flip.

## New original evidence and explicit rejection
A Wowhead Glimmering Gemdust commenter reports **480 silver-quality gems, 160 Dusk-Shrouded Stones, 330 dust**, 40.7% Resourcefulness and max knowledge. Original source: https://www.wowhead.com/item=242620/glimmering-gemdust (accessed 2026-10-29; individual comment date not independently established). Dividing 480 gems by three gives 160 **nominal gross-input equivalents**, not verified completed operations. Exact gem item/rank output cohorts and per-cast zero-hit counts are missing. **Reject numeric promotion to E, P(hit) or tooltip positive min/max.** A separate original April 1–2 2026 Blizzard forum thread reports one or occasionally three dust, but no exact tuple histogram: https://us.forums.blizzard.com/en/wow/t/is-jc-prospectingcrushing-broken/2284616 . Keep as source-only, not a conservative exact pair fallback.

## Coverage and confidence (separate denominators)
| Measure | Result | Meaning |
|---|---:|---|
| A compiler-admitted mapping representation | 1,015 / 1,015 | Not an exhaustive universe audit |
| Distinct admitted input/output IDs | 179 / 236 | Counts, not percentages of all Retail |
| B all-four-field numeric completeness | 801 / 1,015 (78.92%) | Includes historical and modeled provisional values |
| Unknown numeric cells | 511 / 4,060 | P 201, min 97, max 97, E 116 |
| Confidence ≥90 | 0 / 4,060 | 40 at 70–89; 4,020 below 70 including unknown |
| C exhaustive independently audited Retail universe | NOT COMPLETE | True denominator unknown |
| Separate historical first-pass examined | 1,643 / 1,737 | Includes profiles, not proof of C |

All 1,015 admitted records are provisional. Zero independently verified current Retail minimum-eligible unskilled baselines.

## P2 gold and tooltip safety
No source-backed current Retail unconditional expectedQuantity was accepted. Never multiply unconditional E by P; positive yield min/max and provisional tooltip-only P remain **display-only**, never EV inputs. The 19 staged crowdsourced Wowhead hit ratios still lack verified zero-inclusive completed-cast denominators; only Titanium Powder's conservative 1–2 positive display range is active. Do not use gross input/recipe size as completed casts, sum mutually exclusive output ranks, omit Crushing's 3 gems + 1 stone, or infer patch scaling from anecdotes.

## P1/P3 next assignments — queue30
The 36 q29 E-gap keys have now all been examined, but **116 candidate E cells remain unknown**. To avoid an identical repeated TSM-source audit, queue30 pivots to the 40 unadmitted output leads in `research/ledger/itemdb-uncompiled-output-leads.csv`: 24 distinct stable lead keys representing 40 distinct input/output tuples (16 Crushing inputs × two Gemdust ranks, plus 8 Midnight milling alternate-rank pairs).
- Midnight: 8 Crushing input families / 16 exact tuples.
- War Within: 8 Midnight milling alternate-rank inputs / 8 exact tuples (master-assigned overflow).
- Dragonflight: 4 Crushing input families / 8 exact tuples (master-assigned overflow).
- Legacy: 4 Crushing input families / 8 exact tuples (master-assigned overflow).
The queue is source-triggered. Workers must seek genuinely new 2026 Retail selector/recipe/rank evidence or completed-cast logs; repeated previously indexed source pages earn no novel credit. No candidate is admitted without exact eligibility proof. These are not new first-pass items or guaranteed conversions.

## Source memory and lessons
Source memory is still the last committed incremental snapshot: 224 canonical sources, 391 review events, 104 QA events. The q28 17 and q29 19 worker review events, plus this run's two master source reviews, await a full deterministic Node directory rebuild. Original observations are immutable. This cycle's 36-key audit yielded 0 newly admitted mappings and 0 new current numeric fields; switch from repeated TSM lines to original completed-cast evidence and independent universe selectors. No reward score changes numerical confidence.

## Protection
All authored paths are within `research/` on `research/processing-confidence`. No main, production addon Lua/TOC, release artifacts, PR #3 merge or schedule modifications.
