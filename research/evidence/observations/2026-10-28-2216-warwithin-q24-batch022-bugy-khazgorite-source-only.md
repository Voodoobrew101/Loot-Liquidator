# Source-only reconciliation — Dragon Isles prospecting / Bugy Khaz'gorite subgroups

Date reviewed: 2026-10-28. This is an archival source note, **not** a schema observation and not an independently verified completed-cast dataset.

Primary original commenter: **Bugy**, on [Dragon Isles Prospecting spell 374627](https://www.wowhead.com/spell=374627/dragon-isles-prospecting). This URL and author already appear in the master source-memory for **two Draconium cohorts**. The two **Khaz'gorite rows** are a newly inspected subgroup of the **same author**, not a new independent author or study. No new source-cohort credit should be awarded.

The author describes 122 Dragon Isles Jewelcrafting skill, 15 Enterprising points, and 25 Prospecting points, with inspiration-dependent quality and a rank-three claim conditional on skill. **Actual sampling date, input quality rank, output quality rank, client build, number of completed operations, and a zero-inclusive cast histogram are not independently documented.** The table labels values as average yield per ore; the Khaz'gorite amount column says 100 in each row.

| Original output label | Khaz row A (100) | Khaz row B (100) |
|---|---:|---:|
| Crumbled Stone | 0.058 | 0.066 |
| Fractured Glass | 0.052 | 0.042 |
| Prismatic Ore | 0.002 | 0.002 |
| Illimited Diamond | 0 | 0 |
| Nozdorite | 0.016 | 0.018 |
| Neltharite | 0.004 | 0.018 |
| Ysemerald | 0.012 | 0.012 |
| Malygite | 0.002 | 0.010 |
| Alexstraszite | 0.010 | 0.012 |
| Eternity Amber | 0.014 | 0.016 |
| Sundered Onyx | 0.002 | 0.004 |
| Vibrant Emerald | 0.004 | 0.006 |
| Zen Mystic Sapphire | 0.010 | 0.002 |
| Queen's Ruby | 0.008 | 0.004 |

**Denominator guard:** 100 × 0.058 = 5.8 units, impossible as an exact integer aggregate if 100 means 100 ore and 0.058 is exact. In contrast 500 × 0.058 = 29 and 500 × 0.002 = 1; every reported Khaz'gorite average is arithmetically compatible with 500 ore (100 nominal five-ore casts). This is a **plausible interpretation, not proof**: author may have used a different denominator or rounding. Preserve reported 100 and raw decimals, leave actual completed casts **null**; do not derive P, positive bounds, or unconditional per-cast E. The source lacks a reliable rank mapping for the q24 Khaz'gorite R1/R2/R3 assignments.

The spell's present [Wowhead entry](https://www.wowhead.com/spell=374627/dragon-isles-prospecting) explicitly consumes five ores. For Hochenblume, [Dragon Isles Milling spell 382981](https://www.wowhead.com/spell=382981/dragon-isles-milling) consumes five herbs; [Shimmering Pigment](https://www.wowhead.com/item=198422/shimmering-pigment) comments support the herb/pigment family, but do not establish the three rank-conditioned 2026 rates.

**New research value:** subgroup and denominator ambiguity identified without duplicate author credit. **New verified current Retail numeric fields:** zero. **Next evidence:** source-author clarification of Khaz'gorite amount=100, quality-rank-specific raw counts, zero-inclusive cast histograms and skill/patch context.