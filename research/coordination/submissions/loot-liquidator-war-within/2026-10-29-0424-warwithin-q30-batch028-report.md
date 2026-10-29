# Loot Liquidator War Within worker — queue30 batch028 (Midnight milling overflow)
**2026-10-29 · branch `research/processing-confidence` · RESEARCH ONLY**

## Assignment and provenance
Read LIVE queue revision **30** (`2026-10-29-batch028-war_within`): eight disjoint Midnight Milling alternate-rank tuples, master-assigned to War Within worker. Read master batch027 verdict, source-memory snapshot, research lessons, uncompiled-lead CSV, itemdb schema and pinned main `GameData.lua` parent blocks. This is overflow only; no TWW keys self-claimed. **No first-pass credit.** The existing branch source-memory snapshot (224 sources/391 review events/104 QA events) is incremental/stale; newly reviewed URLs are not assumed to have been merged by master.

## P0 — item identity independently confirmed; output eligibility still missing
All eight input herb IDs and four distinct output pigment IDs were checked against their exact current Retail Wowhead item pages on 2026-10-29. `GameData.lua` lines 283–298 identify the eight input parents with `batch=10` and **empty materials arrays**; they do not prove any output rank. Warcraft Wiki's Midnight Milling spell page states ten Midnight herbs per operation. Method and Icy Veins confirm herb→pigment *families*, not the eight exact quality-rank selectors. The Wowhead item pages distinguish +5 versus +15 **recipe difficulty** but that modifier alone is not proof of the claimed quality-rank mapping or a positive yield range.

| Exact input | Proposed alternate output | Rank eligibility |
|---|---|---|
| Tranquility Bloom R1 `236761` | Powder Pigment candidate R2 `245808` | Unverified |
| Tranquility Bloom R2 `236767` | Powder Pigment candidate R2 `245808` | Unverified |
| Argentleaf R1 `236776` | Argentleaf Pigment candidate R1 `245803` | Unverified |
| Argentleaf R2 `236777` | Argentleaf Pigment candidate R1 `245803` | Unverified |
| Mana Lily R1 `236778` | Mana Lily Pigment candidate R1 `245867` | Unverified |
| Mana Lily R2 `236779` | Mana Lily Pigment candidate R1 `245867` | Unverified |
| Sanguithorn R1 `236770` | Sanguithorn Pigment candidate R2 `245865` | Unverified |
| Sanguithorn R2 `236771` | Sanguithorn Pigment candidate R2 `245865` | Unverified |

All eight leads remain **UNADMITTED_EXACT_SELECTOR_AND_RANK_UNVERIFIED**. In particular, the 2026 source comments do not prove which output quality rank occurs from a specific herb quality and skill/spec profile.

## New 2026 original-source findings (source-only)
1. **2026-03-03 original Reddit commenter** in the Engineering discussion states a herb for Powder Pigment yields **between 11 and 15 pigments per milling** and says Sanguithorn has approximately the same rate. The commenter does **not** identify input/output quality ranks, per-cast histogram, actual number of casts, skill, gear, or patch build. The report is an original player anecdote, not eight rank-specific positive bounds and not a current October 2026 measured cohort: https://www.reddit.com/r/woweconomy/comments/1rju9nm/engineering_bugged/.
2. **2026-03-14 independent original Reddit commenter** reports about **5,000 gold profit per 1,000 herbs** from milling with blue tools. This is an economic outcome without herb/pigment ranks, AH price basis, reagent refunds, outputs or cast counts; it cannot validate E or a recommendation flip: https://www.reddit.com/r/woweconomy/comments/1rteoqr/no_money_gain_possible_with_inscription_mats/.
3. The independent Warcraft Wiki spell page confirms the **ten-herb recipe**, while Method/Icy Veins corroborate the four family identities: https://warcraft.wiki.gg/wiki/Midnight_Milling; https://www.method.gg/guides/midnight-inscription-profession-guide; https://www.icy-veins.com/wow/professions-inscription. These are recipe/context references, not independent drop-rate studies.

The 2026-03-03 family-level 11–15 statement must **not** be transferred to any of the eight exact tuple tooltip ranges. Do not divide a 1,000-herb economic report by ten and call it observed completed operations. Original March sources are independent *comment authors*; they are not two independent cast-level studies. Reused item/guide pages receive zero new observation credit.

## P1 four-field review and tooltip isolation
**8/8 exact keys audited.** Each of **32/32 economic fields** (P(hit), positive min, positive max, unconditional E) is explicitly `null`; **24/24 optional tooltip-only P/min/max fields** are `null`. No invented zero, no rank-shared probabilities, no unsupported conservative min/max. No 2026 source supplies actual zero-inclusive completed-cast denominators or exact output ranks. Provisional <90 confidence is allowed, but source absence cannot be solved by assigning an arbitrary number. Source identity is independently verified; conversion rank eligibility is not.

## P2 decision risk and QA
- The 2026 source confirms potential milling value, but without exact rank-specific E, input costs, output prices, stat/refund context and source rate units, **no priced TSM mismatch or gold-optimal recommendation flip** can be established.
- Output ranks are alternatives conditioned on quality/skill; do not sum two mutually exclusive quality ranks as simultaneous guaranteed outputs. Resourcefulness affects input costs, not direct pigment yield.
- No economic or tooltip-only numeric fields were promoted. No `itemdb.lua`, production Lua/TOC, main, shared ledgers, assignments, canonical registry, source-memory or schedules changed.
- Validation: 8 unique assigned keys = 8 audit rows; all 8 parent inputs present in GameData; 8 exact item identities verified; 4 distinct pigment item identities verified; 10 input units from independent recipe page; 0 new admitted mappings, 0 new economic values, 0 tooltip numeric fallbacks, 2 new original 2026 qualitative author reports, 0 new actual-cast cohorts.
- Master handoff: **source-triggered pause/reassignment requested** for these eight unadmitted leads unless a new exact-rank selector capture or cast log appears. Keep their keys unadmitted. Next exact IDs: `236761→245808`, `236767→245808`, `236776→245803`, `236777→245803`, `236778→245867`, `236779→245867`, `236770→245865`, `236771→245865`. A useful capture must include actual completed ten-herb operations, zero-hit outcomes, both item IDs/ranks, effective skill, Perfect Milling node, gear, Resourcefulness, refunds and build/patch.

## Worker-owned artifacts
- `research/coordination/submissions/loot-liquidator-war-within/2026-10-29-0424-warwithin-q30-batch028-8key-fourfield-audit.jsonl`
- `research/evidence/observations/2026-10-29-0424-warwithin-q30-batch028-midnight-milling-2026-source-only.md`
- `research/coordination/source-reviews/loot-liquidator-war-within-2026-10-29-0424-warwithin-q30-batch028.jsonl`
