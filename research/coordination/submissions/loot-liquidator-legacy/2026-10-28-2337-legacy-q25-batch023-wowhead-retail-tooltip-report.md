# Legacy batch023 — Wowhead Retail Prospecting tab conservative tooltip fallback audit
**2026-10-28 23:37 PDT · queue25 · research/processing-confidence · worker loot-liquidator-legacy**

## Scope and outcome
Read live master queue revision 25, latest master QA batch022, source-memory, research-lessons and q24 Legacy findings; matched **45/45** exact assigned stable keys and **35/35** numbered GameData.lua rows against pinned SHA `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`. Missing-field ledger has **71** assigned unresolved cells. Audited 9 historical BfA mass-milling keys, 1 Titanium Powder key, 30 imported TSM prospecting keys and 5 explicitly assigned DF milling overflow keys. No other worker keys claimed.

**New defensible TOOLTIP-ONLY candidate values: 19 conservative P(hit) displays and 2 positive yield endpoints for Titanium Powder.** Wowhead additionally corroborates **36 already source-stated** positive bounds for 18 TSM gem rows. **No current-Retail gold/EV numeric fields verified or promoted; 0 new legitimate mappings; 0 new independent cast-level studies.** All `fields` in the machine audit remain unknown for current economic use. These 19 P displays are not an independently validated 2026 skill-matched distribution.

## Important new original table inspection
Fetched raw HTML from Wowhead's **Retail** ore pages and extracted the actual embedded `new Listview({id:'prospecting',...})` loot-table data, not the rendered icon text. Each row contains `count`, `outof`, `stack` and often `pctstack`. `outof` matches `WH.TERMS.oreprospected_format`. These are aggregated **crowdsourced loot-tab observations**, with **no original cast-by-cast logs, patch, skill, specialization or independence guarantee**. For display only, a source-anchored hit-ratio proxy `count/outof` is rounded DOWN to whole percentage points at >=5%, or 0.1 percentage points below 5%. It must NEVER enter economic calculations.

### Cobalt Ore 36909 — Retail Wowhead, 91,628 pooled loot-tab observations
Source: https://www.wowhead.com/item=36909/cobalt-ore
| Output ID / item | Loot-tab hits | Raw ratio | Conservative tooltip P | Positive yield |
|---|---:|---:|---:|---:|
| 36917 Bloodstone | 21,139 / 91,628 | 23.07% | 23% | 1–2 |
| 36920 Sun Crystal | 21,132 / 91,628 | 23.06% | 23% | 1–2 |
| 36923 Chalcedony | 21,435 / 91,628 | 23.39% | 23% | 1–2 |
| 36926 Shadow Crystal | 21,799 / 91,628 | 23.79% | 23% | 1–2 |
| 36929 Huge Citrine | 21,847 / 91,628 | 23.84% | 23% | 1–2 |
| 36932 Dark Jade | 21,188 / 91,628 | 23.12% | 23% | 1–2 |

### Titanium Ore 36910 — Retail Wowhead, 58,769 pooled loot-tab observations
Source: https://www.wowhead.com/item=36910/titanium-ore
| Output ID / item | Loot-tab hits | Raw ratio | Conservative tooltip P | Positive yield |
|---|---:|---:|---:|---:|
| 46849 Titanium Powder | 33,239 / 58,769 | 56.56% | 56% | 1–2 (raw max 5) |
| 36917 Bloodstone | 13,712 / 58,769 | 23.33% | 23% | 1–2 |
| 36920 Sun Crystal | 13,372 / 58,769 | 22.75% | 22% | 1–2 |
| 36923 Chalcedony | 13,766 / 58,769 | 23.42% | 23% | 1–2 |
| 36926 Shadow Crystal | 13,663 / 58,769 | 23.25% | 23% | 1–2 |
| 36929 Huge Citrine | 13,703 / 58,769 | 23.32% | 23% | 1–2 |
| 36932 Dark Jade | 13,473 / 58,769 | 22.93% | 22% | 1–2 |

**Titanium Powder 46849 safeguard:** Wowhead's actual observed positive stack range is **1–5**; conditional stack mix `{1: 74.9872,2: 24.1072,3: 0.72806,4: 0.129366,5: 0.0481362}`. Only about **0.906%** of positive powder observations are >2. Under the user's conservative quality-of-life preference, the proposed **tooltip display fallback is 1–2**, with raw observed max 5 preserved in provenance. Do NOT mislabel 2 as the observed/possible maximum. The user's accepted happy-bonus principle permits a higher actual proc. No gold E is inferred.

### Felslate 123919 — Retail Wowhead, 2,194 pooled loot-tab observations
Source: https://www.wowhead.com/item=123919/felslate
| Output ID / item | Loot-tab hits | Raw ratio | Conservative tooltip P | Positive yield |
|---|---:|---:|---:|---:|
| 130178 Furystone | 20 / 2,194 | 0.91% | 0.9% | 2–5 |
| 130179 Eye of Prophecy | 22 / 2,194 | 1.00% | 1% | 2–5 |
| 130180 Dawnlight | 18 / 2,194 | 0.82% | 0.8% | 2–5 |
| 130181 Pandemonite | 17 / 2,194 | 0.77% | 0.7% | 2–5 |
| 130182 Maelstrom Sapphire | 14 / 2,194 | 0.64% | 0.6% | 2–5 |
| 130183 Shadowruby | 17 / 2,194 | 0.77% | 0.7% | 2–5 |

Felslate rare-gem individual hit counts are only 14–22; pooled unstratified skill and Legion color-selection mechanics are unknown. These percentages are **low-confidence display suggestions only**, not verified current-Retail probabilities.

## Strict classic-vs-retail quarantine
Requested **Retail** URLs for Black Trillium 72094 and White Trillium 72103 were automatically redirected to **MoP Classic** pages:
- https://www.wowhead.com/mop-classic/item=72094/black-trillium-ore — 4,586 Classic loot-tab observations.
- https://www.wowhead.com/mop-classic/item=72103/white-trillium-ore — 4,851 Classic loot-tab observations.

The 12 assigned MoP gem rows have apparent Classic `stack=[1,1]` and count/outof values, archived in evidence, **but are NOT promoted as Retail tooltip or economic fallbacks** without a Retail patch/eligibility bridge. A separate 2026 Retail source is needed.

## Remaining assigned gaps and gold-risk
- **9 BfA Jiyao mass-milling** rows: reused existing original source; no zero-inclusive completed-cast histogram, and 20-herb mass mills cannot be silently normalized to actual five-herb casts. No new source fetch.
- **5 Dragonflight Bubble Poppy rank** rows: Wowhead Retail item pages 191467/191468 expose no analogous milling loot tab. Preserve rank-specific P and E unknown; do not reuse family-wide TSM values across mutually exclusive quality ranks.
- **18 legacy TSM gem rows**: Wowhead raw P for Cobalt/Titanium is near 23%, while TSM `matRate=0.235` is near 23.5%; Legion rare-gem raw hit ratios vary ~0.64–1.00% against TSM `matRate=0.01`. Similarity is NOT evidence of independent ancestry or current applicability. The original TSM `amountOfMats` and imported chance/expected-value conflicts remain unresolved; **no gold-optimal flip is claimed**.
- **Titanium Powder**: historical PTR 720 ore/144 casts/94 powder is a separate old cohort; this new Wowhead pooled loot tab is neither 2026 cast-level proof nor an independent original experiment. Source memory already contains the historical author. No E promotion.

## Quality controls and master handoff
19/19 tooltip P in (0,1], 19/19 conservative positive min<=max, 19/19 source count<=outof, 19/19 no economic field substitution; 12/12 Classic quarantined; 35/35 GameData source identities matched; 45/45 disjoint queue25 keys; no source-author inflation. The proposed `maxstat/skill` is a **fallback profile label only**, NOT a claim the pooled observations were at max skill. No midpoint EV, chance-times-E, invented zero or recipe selector.

**Master next exact IDs:** stage display-only `36910→46849` positive yield 1–2 (raw 1–5) and conservative P; `36909→36917/36920/36923/36926/36929/36932`; `36910→36917/36920/36923/36926/36929/36932`; `123919→130178/130179/130180/130181/130182/130183`. Keep all gold-side fields unknown pending current-Retail completed-cast evidence. Request a separate Retail MoP source for `72094/72103` before considering their Classic rates. Master QA must enforce display/economic isolation in staged itemdb and tooltip renderer.

**Files:** this report, 45-key four-field + tooltip audit JSONL, source-review events JSONL, and raw provenance observation Markdown. Research-only branch; no production Lua, TOC, shared ledgers, master assignments or source-memory cache edited.
