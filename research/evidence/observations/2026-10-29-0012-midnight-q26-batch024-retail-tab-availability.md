# Midnight q26 — Retail Wowhead tooltip-source availability audit
**2026-10-29 00:12 PDT · queue26 · research only**

## Fresh page checks
Four assigned Retail ore pages were inspected in raw HTML for a `new Listview` with `id: 'prospecting'`. All four contain item identity and other related lists, but **no prospecting loot tab** and therefore no `count/outof`, `stack`, or `pctstack` data for gems:
- [Umbral Tin R2 (237363)](https://www.wowhead.com/item=237363)
- [Brilliant Silver R1 (237364)](https://www.wowhead.com/item=237364)
- [Brilliant Silver R2 (237365)](https://www.wowhead.com/item=237365)
- [Dazzling Thorium (237366)](https://www.wowhead.com/item=237366)

Eight reciprocal gem/material pages were checked and had no `prospected-from` loot listview:
- https://www.wowhead.com/item=242606
- https://www.wowhead.com/item=242607
- https://www.wowhead.com/item=242610
- https://www.wowhead.com/item=242611
- https://www.wowhead.com/item=242553
- https://www.wowhead.com/item=242612
- https://www.wowhead.com/item=242786
- https://www.wowhead.com/item=242788

Eight Retail herb pages confirmed identities but exposed no milling-output loot listview:
- [Tranquility Bloom R1 (236761)](https://www.wowhead.com/item=236761)
- [Tranquility Bloom R2 (236767)](https://www.wowhead.com/item=236767)
- [Sanguithorn R1 (236770)](https://www.wowhead.com/item=236770)
- [Sanguithorn R2 (236771)](https://www.wowhead.com/item=236771)
- [Argentleaf R1 (236776)](https://www.wowhead.com/item=236776)
- [Argentleaf R2 (236777)](https://www.wowhead.com/item=236777)
- [Mana Lily R1 (236778)](https://www.wowhead.com/item=236778)
- [Mana Lily R2 (236779)](https://www.wowhead.com/item=236779)

Four pigment pages confirmed item identities but exposed no `milled-from` loot listview or exact herb-rank eligibility:
- [Argentleaf Pigment R1 (245803)](https://www.wowhead.com/item=245803)
- [Powder Pigment R2 (245808)](https://www.wowhead.com/item=245808)
- [Sanguithorn Pigment R2 (245865)](https://www.wowhead.com/item=245865)
- [Mana Lily Pigment R2 (245867)](https://www.wowhead.com/item=245867)

**Negative evidence is limited to these 24 specific Retail item HTML snapshots**, not proof that any conversion is impossible or that Wowhead never has such tabs. Do not mistake ore's `dropped-by` loot count for prospecting gem chance.

## Source ancestry and invariants
- Reused [kyzenbka original Wowhead milling comment](https://www.wowhead.com/ru/item=245807/powder-pigment), previously archived q24. Family totals: Tranquility Bloom 1000 herbs→1305 Powder Pigment; Sanguithorn 1000→1286 Sanguithorn Pigment; Mana Lily→1336 and Argentleaf→1335 pigment, last two input counts not explicitly given. No output rank, completed cast count, zero-inclusive histogram or observation patch. One author, no new independent study.
- Reused [Method Midnight Inscription guide](https://www.method.gg/guides/midnight-inscription-profession-guide): ten-herb operation, Perfect Milling rank gating. Qualitative secondary source, not rank-specific measured data.
- Reused [Midnight Prospecting spell](https://www.wowhead.com/spell=1231127/midnight-prospecting): five ore per operation. JD3K and Cardinalai player cohorts already archived; no new independent numerical evidence in this run.
- **24/24** GameData output lines match exact parent ore and output item IDs, blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`. Eight milling pairs are UNADMITTED and not compiled mapping records.
- **72** assigned compiler-missing cells (24 each P, positive min, positive max) remain unknown; **0** source-backed tooltip numeric values and **0** verified current-Retail economic E values added.
- Do not infer P from existing GameData low/high E proxies; do not infer positive yield range from aggregate output totals; do not copy herb rank to pigment rank. Unknown is not zero.

## Next evidence targets
1. Actual rank-separated completed-cast logs for Tin R2 237363, Silver R1/R2 237364/237365, and Thorium 237366; capture output item IDs, per-cast positive stacks, zero counts, client patch, skill and spec.
2. Exact selector/skill threshold evidence for eight leads, starting 236761/236767→245808 and 236770/236771→245865.
3. Revisit these specific Wowhead Retail tabs only after a source-change trigger. Preserve current source-only family aggregates without duplicate cohort credit.
