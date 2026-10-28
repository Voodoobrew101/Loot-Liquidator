# Loot Liquidator Legacy — Batch015, queue revision 17
2026-10-28 15:40 America/Los_Angeles · research/processing-confidence · worker-owned additive evidence only

## Assignment and decision-value results
- Exact live assignment: `2026-10-28-batch015-legacy`, revision **17**, **40/40 unique stable keys**; 31 legacy/home keys and 9 master-directed Dragonflight overflow keys. No self-claimed keys.
- **0 new legitimate mappings; 0 measured 2026 Retail per-cast numerical fields; 0 new exact rank-specific P/E fields.** Existing source-backed provisional E values retained for 25/40 assigned records; 135 unknown field slots across all 40, 25 populated provisional slots. The audit includes all four independent field objects per record.
- **Newly indexed source findings:** one **secondary Classic PTR** Titanium Powder study (~800/6000, not Retail) and one **original qualitative** Prismatic Leaper discussion (five fish per mill, family outputs; no numeric cohort). Reused one original 2022 Retail Titanium Powder study already in source-memory; do not double-count it.
- All 31 historical home keys reused and rechecked from immutable batch014 four-field audit, rather than repeated web fetches. The 9 DF overflow keys are explicitly separated and remain numeric-unknown when source rank/cast context is insufficient.

## P0: Titanium Powder independent historical comparisons — important denominator guard
| Study | Game / evidence | Powder / gross ore | Derived nominal 5-ore E | Actual completed casts |
|---|---|---:|---:|---|
| Reddit 2022 original (already archived) | Retail 2022 | 152/1000 | **0.7600** | Unknown |
| globalmenace original (master accepted) | Retail 12.0.5 | 143/1000 | **0.7150** | Unknown |
| NGA lr199444 via 17173 (newly indexed repost) | **Wrath Classic PTR 2023**, approximate | ~800/6000 | **~0.6667** | Unknown |

2022 versus 12.0.5 gross-ore equivalent difference is **+6.29%** relative to the 12.0.5 reference; this is historical cross-patch comparison, not a validated current Retail rate. The Classic PTR estimate is derivative of an unretrieved NGA original and not comparable to Retail for a numeric transform. All three **P(hit), positive yieldMin/yieldMax and true per-cast E remain unknown**. Preserve 0.715 only as previously master-accepted low-confidence *gross-ore* provisional E reference; do not claim it as a current completed-cast expectation.

Sources: [2022 original Reddit](https://www.reddit.com/r/woweconomy/comments/s6bfrl), [2023 secondary Classic PTR article](https://wow.17173.com/content/06132023/152852948.shtml), [globalmenace item comment](https://www.wowhead.com/item=46849/titanium-powder). The 17173 article is explicitly labeled an AI-generated summary and quotes NGA user lr199444; original data and precise powder count are not available. This source is **derivative**, not an independent verified Retail study.

## P0: Prismatic Leaper eligibility / resourcefulness — qualitative, not numerical
Original [Jan 1, 2023 player discussion](https://www.reddit.com/r/woweconomy/comments/100anp2) says **5 fish per milling operation** and mentions Flourishing, Serene, and Blazing pigment families. A commenter claims Resourcefulness does not proc on fish; no cast log or skill/patch stratification supports a universal exclusion. [Warcraft Wiki](https://warcraft.wiki.gg/wiki/Prismatic_Leaper) lists Serene and Flourishing but not Blazing. This **family-level discrepancy** is retained as a research question, not a new output ID. Assigned 198412/198413/198414 (Serene ranks) and 198415 (Flourishing rank) retain P/E **UNKNOWN**. TSM source family P=.2462 and E=.8615 are copied to multiple output ranks and must not be summed as simultaneous outputs. Fish input 200061 has **no item quality rank**, despite legacy GameData sourceQuality=1.

## P1: Exact assigned family review
| Family | Exact keys | Outcome |
|---|---:|---|
| Titanium Powder 36910→46849 | 1 | Existing accepted mapping; three historical gross-input references, no actual casts |
| Felslate 123919→130178–130183 | 6 | Reused Deckven 3200 mass + Traziz 100 and pre/post original; no new measurements |
| Cobalt/Titanium 36909/36910→six uncommon gems each | 12 | Source P=.235, E=2.5, [1,2] contradiction retained as historical source; P unknown |
| Black/White Trillium 72094/72103→six gems each | 12 | Source P=.16, E=.1705, [1,1] contradiction retained; P unknown |
| DF Crumbled Stone 192880→192849/192866 | 2 | Exact output-rank gross-input denominator unverified; all four numeric fields unknown |
| DF Draconium 188658/189143→192870/192871 | 3 | Historical rank E duplicated in TSM; original 30k ore gross-input study is context only |
| DF Prismatic Leaper 200061→198412–198415 | 4 | Five-fish recipe context, rank-specific P/E unknown; no Resourcefulness assumption |

The original TSM tuples for Felslate, WotLK, MoP and diamonds have known P×min ≤ E ≤ P×max violations, previously documented. Do not repair by widening min/max or inventing P from E. Historical source family totals do not become current Retail cast-level data.

## P2: Gold decision-risk and source lineage
Highest risk remains **duplicated Dragonflight output quality-rank E** and omitted/incorrect profession resource savings. A nominal 5-input rate cannot be treated as a completed operation without actual cast counts. No AH prices were fetched; no live gold-optimal flip is asserted. Direct input cost (5 fish, 5 ore) must be distinguished from Resourcefulness refunds and returned input items.

Independent original cohorts already known: globalmenace (Retail 12.0.5), 2022 Reddit powder, Deckven/Traziz Felslate and 2023 DF Draenei. New 17173 is a *secondary derivative* of NGA, not a new independent measured cohort. The Jan 2023 fish discussion is a **newly indexed original qualitative source**, not a new quantitative cohort. The 2023 three-cast fish experiment remains a separate preexisting cohort, not re-counted here.

## Master handoff and exact next IDs
- **P0** 36910→46849: obtain current Retail 12.1 actual completed casts, per-cast powder histogram including zeros, skill/gear and direct Resourcefulness record; the 2022 and 2023 comparisons are only gross-input cross-checks.
- **P0** 200061→198412/198413/198414/198415: confirm live output ranks and whether Blazing pigment can actually drop; collect per-cast 5-fish outcomes and Resourcefulness events.
- **P1** 188658→192870/192871 and 189143→192870: obtain rank-specific gem output totals with actual cast denominator, skill/Inspiration, and current client patch.
- **P1** 192880→192849/192866: verify that any returned Crumbled Stone is input saving versus an actual output.
- **P2** 36909/36910→36917/36920/36923/36926/36929/36932 and 72094/72103→76130/76133/76134/76135/76136/76137: collect matched Retail cast histograms to replace inconsistent TSM P/E source claims.

**Pre-review master baseline:** 984 provisional mappings, 799 four-field-complete, 403 unknown numeric cells, 0 verified unskilled current Retail baselines. Independent exhaustive Retail coverage not established. No production Lua/TOC, shared ledgers, master assignment, canonical registry, source-memory cache or schedule modified.
