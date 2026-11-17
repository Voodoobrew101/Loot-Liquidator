# Coordinator source-identity and seven-operation yield implication: Frostwoven Belt 41522

Verified UTC: 2026-11-08T04:06Z. Research-only original-source review. This is **not a new study, newly performed disenchant, live Retail rate, or ItemDB/tooltip test**.

## Provenance and original cohorts

1. Newly recorded Legacy worker record `legacy-20261108-3311` in [20261108T0356-wotlk-classic-looter-disencasts.jsonl](../legacy/20261108T0356-wotlk-classic-looter-disencasts.jsonl) transcribes [Wowhead Infinite Dust comment by 854192](https://www.wowhead.com/item=34054/infinite-dust): the author says seven crafted **Frostwoven Belts (41522)** gave **21 Infinite Dust (34054)** in total and that each belt yielded **at least three**. Source is historical (no stated collection date/patch, skill, bonus, rank, or current Retail processing eligibility). This is one player cohort, distinct from the next source.
2. Independent [Frostwoven Belt comment by 244234](https://www.wowhead.com/item=41522/frostwoven-belt) reports **six belts**, each yielding **one or two Infinite Dust**. No exact total, per-operation sequence, patch/build, or character details. Do not combine with the seven-belt cohort as a single epoch.
3. The [archived Frostwoven Belt item table](https://worldofwarcraft.fandom.com/et/wiki/Frostwoven_Belt) gives **Infinite Dust 1–2 (22%)**, **Lesser Cosmic Essence 1–2 (75%)**, and **Small Dream Shard 1 (3%)** for the historical item-level 138 version. This table is reference data, not a measured 100-cast study, and its sourcing/patch applicability is unknown. The same 22/75 ordering was previously flagged for a different item, Duskweave Belt (41543); agreement of table patterns does **not** establish rates for either item.

## New field-level mathematical conclusion (conditional, not an observed raw histogram)

Let `x_i` be dust units obtained from each of the **seven** disenchants. Taking both statements about that same seven-belt sample literally, `x_i >= 3` for each `i=1..7` and `sum(x_i)=21`. Therefore `sum(x_i-3)=0` with seven nonnegative integer summands, so **every `x_i=3`**.

- **Source-implied seven-sample quantity distribution**: seven at 3 dust each, **if** the universal-minimum wording describes each of those specific seven operations. It is a *logical reconstruction*, not a per-event histogram the author published.
- **Sample dust-specific P(hit)**: 7/7 from the source's every-belt claim; **sample unconditional E(dust units per disenchant)**: 21/7 = **3**. **Sample positive yield range**: 3–3 *under the same conditional interpretation*.
- The separate six-belt source bounds its sample dust quantity to **1–2 on each of six outcomes** (source text), not a measured seven-belt contradiction resolvable by averaging or selecting a preferred source.
- **Historical-cohort conflict**: the seven-belt implied range **[3,3]** and six-belt reported range **[1,2]** are disjoint; the archived table's 1–2 positive range and 22% dust occurrence are additionally incompatible with literal 7/7 dust outcomes. Do not infer a change date, patch, hotfix cause, or a general Retail result from this alone.
- Unknown: other materials and their joint outcomes, live version/bonus/skill context, cross-cohort independence beyond distinct commenter IDs, table provenance, 2026 Retail eligibility, prices and supported gold recommendations.

## Disposition and targeted handoff

**Identity/units/source-version conflict, not a missing-price/display bug.** Retain both original source comments and the archive separately; **do not overwrite Legacy worker evidence or fabricate new observed casts**. Legacy T0047 can check source comment timestamps, original post versions and current exact Frostwoven Belt eligibility, and attach a *reviewed correction/derived note* if its schema supports source-implied rather than raw histograms. Any implemented tooltip mean must be conditionally scoped and evaluated by the protected three-pass owner through actual offline engine/rendering; **no runtime integration or 2026 Retail gold improvement is claimed here**.

## Checks actually performed

Reopened original two Wowhead comments and historical archived item table through web search; fetched current Legacy worker source line `legacy-20261108-3311` from the research branch; validated the seven-integer lower-bound arithmetic by direct calculation. No native Lua/addon tests, compiler, spreadsheet modification, live client, or new cohort collection was performed.
