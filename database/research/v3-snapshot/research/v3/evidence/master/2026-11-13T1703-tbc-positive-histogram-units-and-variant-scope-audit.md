# Research Manager: T0042/T0047 positive-stack source math and variant applicability hold

Checked at 2026-11-13T17:03:17.881Z UTC on research head `adcf44e9b6ebeafc5883d7a8426a1995603658d9`.

**Nature of work:** independent arithmetic verification of **existing worker-collected** historical Wowhead Looter positive-stack tables, not new original casts, not an independent check of the JavaScript-only Looter tables, and not current Retail character evidence. Original evidence remains immutable: [legacy worker JSONL](../../evidence/legacy/2026-11-13T1646-tbc-looter-positive-stack-quantities.jsonl). Original source links are retained per row.

## Numeric checksum

All **14/14** source-record histograms satisfy both `sum(stackCount)=castsWithDrop` and `sum(stackSize × stackCount)=totalQuantity`; there are **4** source-reported cumulative gear cohorts. These values imply unconditional material units per *reported item-side observation*, computed as `totalQuantity/casts`, not P(hit) and not conditional units per positive stack.

| Input item | Reported operations N | Sum positive-output hits | At least operations with no listed material hit* | Material expected units / reported operation |
| --- | ---: | ---: | ---: | --- |
| 24672 | 11,960 | 11,878 | 82 | 22445: 2.859532; 22446: 0.296656; 22447: 0.008946; 22449: 0.024164 |
| 25025 | 5,136 | 5,089 | 47 | 22445: 2.708917; 22446: 0.285436; 22449: 0.028427 |
| 25055 | 21,830 | 21,681 | 149 | 22445: 2.683280; 22446: 0.313972; 22447: 0.009070; 22449: 0.028630 |
| 25057 | 14,083 | 13,987 | 96 | 22445: 2.703685; 22446: 0.324363; 22449: 0.025066 |

**Totals:** 53,009 source-reported cumulative item operations across distinct item IDs, 52,635 positive material hit rows, minimum 374 operations without a hit in the **listed** materials. *These lower bounds assume the table counts distinct positive events per output within the common reported denominator. If multiple materials can occur in one operation, the number without listed material is larger, not smaller. In no case does that prove zero-output DE or missing operations: unlisted outputs, version/bonus mixtures, scraping and original data semantics may explain the residual. Do not turn a missing material row into a measured zero. Do not double-count earlier cumulative snapshots.*

## Original-source context issue newly checked

The current indexed **Retail** item catalog shows base item level **14** for each input, while some entries also show a distinct **item level 74** item version; historical classic sources may show higher base levels. This is evidence of *item-level/version context*, not a proof that any one recorded Looter result occurred at level 14, 74 or its historical equivalent. The archived `bonus=6654` query in three source URLs is a display/request argument, **not** a per-operation bonus receipt.

| Input | Current Retail item catalog | Source collection/at-cast facts missing |
| --- | --- | --- |
| 24672 Eldr'naan Gloves | https://www.wowhead.com/item=24672/eldrnaan-gloves | actual player itemLink/bonus, item level, build, enchanting skill/spec, time |
| 25025 Warlord's Iron-Gauntlets | https://www.wowhead.com/item=25025/warlords-iron-gauntlets | same; page shows selectable/current item-version context |
| 25055 Alexandrite Ring | https://www.wowhead.com/item=25055/alexandrite-ring | same; current base 14 is not a recorded-at-cast level |
| 25057 Amber Band | https://www.wowhead.com/item=25057/amber-band | same; page shows selectable/current item-version context |

These source-reported old-family conversion means are numeric/reference evidence with potentially priceable material identifiers if matching applicability is independently validated; they are **not certified current Retail character-level gold decisions**, nor a complete current disenchant distribution. The estimator presently treats `sourceKind=study` + `totalQuantity/casts` as a measured historical row even without a verified itemLink/epoch. Preserve provenance and leave applicability unconfirmed, rather than changing fields, assigning source confidence or suppressing all historical evidence by fiat.

## Reproducible checks and disposition

- Read original worker file `research/v3/evidence/legacy/2026-11-13T1646-tbc-looter-positive-stack-quantities.jsonl`; computed integer histogram counts and weighted totals for all 14 rows, then means from source-reported denominators. **No estimator, Lua suite, synthetic-price actual decision engine, tooltip renderer or live WoW test was run.**
- Source variant pages were independently checked by current web search/cached page retrieval; JavaScript-only original Looter row HTML and exact at-cast versions could not be retrieved, so **row numerators/quantities were not independently website-verified**.
- New true gap: character itemLink/bonus/build/skill and positive-event joint outputs/other outcomes; until then classify as **usable historical numeric rows with an applicability/context hold**, not missing price and not proven current coverage. Task T0042/T0047, and integration owner should add synthetic-price and variant-gate fixtures on the protected three-pass branch only.
- Do not replace original observations, merge worker samples, populate unknown zero counts, or reinterpret spell scaling from these pooled tables. No addon snapshots, workers, schedules, PRs, production branch, merges or releases touched.

**Next concrete priority:** Obtain a first-party current Retail per-itemLink DE export for one of 24672/25025/25055/25057 (success or rejection plus exact material units and character conditions), or independently recover the original Looter at-cast bonus/version metadata. If unavailable, leave these as historical source-provenance data; spend the next separate research cycle on independent T0005/T0039/T0045 current Midnight ranks/hits/zeros/refunds rather than revisiting this exhausted Looter site mirror.
