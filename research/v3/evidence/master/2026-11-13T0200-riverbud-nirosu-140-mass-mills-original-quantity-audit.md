# Original-source BfA Riverbud 140-mass-mill material totals — 2026-11-13 UTC

## New source-lineage check (research only; not current Retail odds)
- **Primary historical first-person source:** Nirosu, comment of 2019-07-29 on [We need a Mass Ink option](https://us.forums.blizzard.com/en/wow/t/we-need-a-mass-ink-option/226400). Source literally reports “140 mass milling (river bud)” yielding **2,272 Ultramarine, 918 Crimson, 376 Viridescent**. These are separate pigment material-unit totals, NOT counts of casts with each output.
- **Input identity:** Riverbud item **152505**; exact historical recipe [Mass Mill Riverbud spell 256217](https://www.wowhead.com/spell=256217/mass-mill-riverbud), which states **20 Riverbud per mass craft**.
- **Output identities:** Ultramarine Pigment **153635**, Crimson Pigment **153636**, Viridescent Pigment **153669**. [Original material table and distinct Jiyao source](https://www.wowhead.com/item=153669/viridescent-pigment).
- **Context:** 2019 Battle for Azeroth forum observation; current Retail game build, in-game eligibility, profession skill, specialization and other modifiers were not stated. The author reported 140 mass crafts; individual 0/1/2 per-output operation logs were not provided and no new manager gameplay observations were made.

## Exact derived rates, maintaining separate units

Assume the source's “140 mass milling” means 140 completed **20-herb** Riverbud mass-mill operations; this is a reported count, not a separately audited client export. At recipe-listed 20 herbs/craft this is **2,800 nominal herb inputs** or **560 five-herb input equivalents**, *not* 560 observed five-herb casts. Actual net inputs/refunds are unknown.

| Output | Reported total units | Units per 140 reported mass casts | Units per 560 nominal five-herb equivalents |
|---|---:|---:|---:|
| Ultramarine Pigment 153635 | 2,272 | 16.228571 | 4.057143 |
| Crimson Pigment 153636 | 918 | 6.557143 | 1.639286 |
| Viridescent Pigment 153669 | 376 | 2.685714 | 0.671429 |

All means here are **derived aggregate quantities** conditional on the source-reported batch count/basis. They do **not** give a P(hit), conditional positive stack average, minimum/maximum, zero count, per-output 0-N histogram, client-verified character eligibility, current patch yield or current market price. No Resourcefulness saving coefficient is inferred. Any per-five normalization must retain the original 20-herb source operation and assumption.

## Independence and comparison guard
- No prior exact **Nirosu 140-cast / 2,272–918–376** original study was located in the checked repository code-search results; this is a source-inventory finding, **not** proof the complete repository has no equivalent migrated record.
- Distinct earlier author **Jiyao** published a Riverbud table on the [Mass Mill Riverbud page](https://www.wowhead.com/spell=256217/mass-mill-riverbud) and revised it to 44 reported mass mills averaging 16.16 / 6.91 / 2.05 per mass craft. Do **not** pool author cohorts without checking the original sourceKey, units and overlapping table revisions. Nirosu's separate forum totals are 16.23 / 6.56 / 2.69 per mass craft; they support a plausibility cross-check but not a modern rate.
- Other Riverbud source families Baadkitty (200 herbs) and Kidneph (1,000 herbs) were already archived in [legacy batch012](../../../coordination/submissions/loot-liquidator-legacy/2026-10-28-1242-legacy-batch012-report.md). Different reported input/operation definitions must be retained. Nirosu's record is a **new research source identity**, not a claim of an independently manager-observed cohort or a measured zero-inclusive sample.

## Decisions, gaps and next operation
1. Preserve this original 2019 first-person 140-mass-craft aggregate as **provisional historical evidence only**; if normalized later, use 20-herb mass-craft as the source basis and clearly labeled five-herb-equivalent yields. Maintain all three original pigment totals.
2. Before compiled/runtime use, compare exact original/source keys and any previous workbook/legacy rows; check BfA skill/recipe context and eligibility. Do not overwrite current usable conversion values; import only through authorized scoped review.
3. Continue to prioritize **current Midnight T0005/T0039/T0045** ore/herb rank-linked physical cast outputs with zeros, skill/spec and refunds. This 2019 original is secondary source completeness, **not** a current Retail gold-coverage increase.
4. This run did **not** execute compiler, valuation engine, synthetic-price tooltip, Lua/client QA, gameplay observations or production changes. No source JSONL originals, worker files, queue, integration branch, PR or schedules changed.

Evidence sources accessed 2026-11-13 UTC; evidence note is a reproducible arithmetic/source audit, not an importer-ready raw dataset.
