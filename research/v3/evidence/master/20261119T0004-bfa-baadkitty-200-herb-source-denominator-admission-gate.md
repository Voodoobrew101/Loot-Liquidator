# Baadkitty BfA seven-herb milling: original per-input mean and admission gate — 2026-11-19 00:04 UTC

**Scope:** research-only original-source/field-admission audit; no addon or migration edits, no present-Retail valuation claim. Reviewed the latest [Legacy worker originals](../legacy/2026-11-18T2345-bfa-baadkitty-original-seven-herb-milling.jsonl) (21 rows) on `implementation/five-agent-completion` against **Baadkitty's first-person comment** on [Viridescent Pigment](https://www.wowhead.com/item=153669/viridescent-pigment). Independently read the original page's seven lines and compared the listed three pigment totals for every herb; separate Kidneph 1,000-herb cohorts are different originals, not copies or a reason to suppress Baadkitty.

## Verified original fields

The author says they purchased **200 units of each herb and milled them all**. Each of the following triplets is **total material units from that herb's reported 200 inputs**, in output order Ultramarine Pigment `153635`, Crimson Pigment `153636`, Viridescent Pigment `153669`. They are not per-material occurrence hits, nominal cast counts, or observed 0–N histograms.

| Input herb (item ID) | Source totals U/C/V | Derived empirical means per one reported herb U/C/V | Gross per herb at **synthetic** 100 copper per pigment |
| --- | --- | --- | ---: |
| Akunda's Bite (152507) | 153 / 62 / 26 | 0.765 / 0.310 / 0.130 | 120.5 c |
| Anchor Weed (152510) | 157 / 71 / 64 | 0.785 / 0.355 / 0.320 | 146 c |
| Riverbud (152505) | 151 / 59 / 20 | 0.755 / 0.295 / 0.100 | 115 c |
| Sea Stalk (152511) | 158 / 65 / 18 | 0.790 / 0.325 / 0.090 | 120.5 c |
| Siren's Pollen (152509) | 159 / 72 / 30 | 0.795 / 0.360 / 0.150 | 130.5 c |
| Star Moss (152506) | 155 / 60 / 17 | 0.775 / 0.300 / 0.085 | 116 c |
| Winter's Kiss (152508) | 160 / 66 / 26 | 0.800 / 0.330 / 0.130 | 126 c |

**Arithmetic:** for each material `reportedTotal/200` outputs per herb; synthetic gross per herb `100 copper * sum(three totals)/200`. This is a static arithmetic fixture, **not** AH price, actual net profit, eligibility proof, or an execution of the addon's valuation engine. Total source material rows = 21; total initially processed herbs as described = 1,400 across seven separate herb types, not 1,400 shared casts.

The author does **not** report actual completed physical milling actions, use of mass milling, resource refunds/reprocessing, per-material castsWithDrop, zeros, stack histograms, skill, patch, or current client eligibility. The [BfA Inscription recipe catalog](https://warcraft.wiki.gg/wiki/Zandalari_Inscription) lists five herbs for an ordinary mill, while [the profession guide](https://www.wow-professions.com/guides/zandalari-kul-tiran-bfa-inscription-leveling-guide) distinguishes Mass Mill. **Do not assert that the author completed 40 physical five-herb casts per type**: 40 is only a nominal five-input equivalent useful for a clearly labeled average normalization. The original's 200-herb denominator supports the displayed per-input empirical means independent of whether batches were ordinary or mass; avoid a fabricated chance or cast count.

## New concrete admission gap, checked in code

All 21 new worker records preserve `totalQuantity`, but put `casts=null`, `inputsPerCast=null`, `inputsProcessed` absent, and `averageShown=null`/`averagePer=null`. Static examination of current `research/v3/tools/build_estimates.py` shows `row_use` lines 266–328 accepts totals only when `casts` or structured `inputsProcessed` plus a group unit yield `n_u`. With the current fields, these rows follow **`totalWithoutCasts`**, so their numerical totals cannot enter the estimator's mean via this path. This is a source-record-to-estimator gap, **not** a reproduced current ItemDB/tooltip failure or proof they are absent from other independently curated fallback models.

Safe scoped next implementation: a reviewer on an isolated research-only branch should append **correction-layer** `inputsProcessed=200` for the exact 21 record IDs, with explicit original-link explanation (the account says all 200 were milled), and supply source-backed `inputsPerCast=5` only as a **normalization unit for the five-herb recipe**; preserve actual casts unknown. Check the alternative mass-mill unit, provenance, historical skill and refund uncertainty, plus dedupe versus legacy/TSM source copies. `CORRECTABLE` currently permits both fields; never mutate the worker original. The owner-selected combined addon/tooltip branch remains protected. Test with real Python estimator and audit output to prove seven existing missing/partial means become usable without replacing stronger rates or declaring present-Retail skill/eligibility, then run synthetic-price actual ItemDB/resolver/formatter and native addon tests before any PR Director integration.

**Separate current estimator risk:** lines 904–908 derive `chance = min(1, expectedMean/rangeMidpoint)` whenever chance is absent. Such a provisional derived chance must not be passed off as 21 observed probabilities or verified 0–N extrema; owner permits mean valuation while chance/range remain unknown. Review field-level representation on the owner integration path rather than changing its implementation here.

## Checks and boundaries

- Independently read original public Wowhead author comment and existing exact worker JSONL; used an in-process JavaScript fixture with original author triplets and asserted all 21 exact input/output IDs, 21 totals, seven study keys, source identity, null unknown fields and 200-herb note. **168/168 bounded JS assertions passed.** Those assertions include code-path string checks for `inputsProcessed`, `totalWithoutCasts`, and `chance_derived`; **they are static**, not actual Python/runtime execution.
- No new independent present-Retail operation, physical cast, probability, histogram, skill rule or current-market price was established.
- **Not executed:** `build_estimates.py`, compiled ItemDB, actual offline synthetic-price valuation/tooltip, native Lua tests, or in-game WoW. No changes to worker evidence, queue, corrections, `main`, the owner three-pass branch, PRs or automations.

**Next priority:** qualified correction and real estimator/tooltip regression for these 21 historical means (alongside unresolved Bountiful Bags and Courtly Wrists context gates), with workers still seeking truly new current-build Umbral Tin `237362` ranked 0–N/refund/skill logs and Tranquility Bloom `236761` mill logs rather than re-searching exhausted sources.
