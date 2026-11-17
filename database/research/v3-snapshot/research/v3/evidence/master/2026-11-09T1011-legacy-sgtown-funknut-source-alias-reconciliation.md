# Coordinator original-source lineage audit — 2026-11-09T10:11Z

**Scope:** Research-only provenance/deduplication check. No new empirical cohort, rates, current Retail valuation or addon code change.

## Four Sgtown material rows: same two October 28 source cohorts

The Legacy worker's [2026-11-09T0956 evidence](../legacy/2026-11-09T0956-northrend-outland-classic-milling-cohorts.jsonl) rows `legacy-20261109-95501..95504` quote **Sgtown** on the [WotLK Azure Pigment page](https://www.wowhead.com/wotlk/item=39343/azure-pigment). I independently checked the original comment text on 2026-11-09. It explicitly reports **Adder's Tongue 128 mills/640 herbs** with **383 Azure (39343)** and **61 Icy (43109)**; **Icethorn 256 mills/1280 herbs** with **774 Azure** and **141 Icy**. The source is an old patch 3.2.2 account, not an observation of November 2026 Retail.

**These exact four output totals and two cohorts were previously transcribed and imported:**
- [October 28 original-source observations](../../../evidence/observations/2026-10-28-0923-warwithin-batch009-original-milling-cohorts.jsonl): `ww-b009-sgtown-2009-adders-tongue` and `ww-b009-sgtown-2009-icethorn`, same original source and the same operations, herbs, output IDs, and totals.
- [Pinned original migration fixture](../../migration/tests/fixtures/pre-m03-study-ids.jsonl): `import-study-00233..00236` reproduce the exact four input/output/operation/quantity vectors. The October 28 report already identified two herb cohorts as one original author's study.

Therefore **do not count Nov 9 rows as fresh independent 128+256 milling operations** and do not augment the compiled estimate's sample size as if replicated.

### Risk in the present estimator, not an executed regression

The October 28 observation uses `https://www.wowhead.com/item=39343/azure-pigment`, while the Nov 9 new study uses `https://www.wowhead.com/wotlk/item=39343/azure-pigment`. Existing [source_keys.py](../../tools/source_keys.py) preserves Wowhead game-flavour suffixes; [build_estimates.py](../../tools/build_estimates.py) `same_page()` removes language/PTR suffixes but **not** `@wotlk`. The new `studyKey` values also differ from the existing imported IDs. Without an explicit canonical original cohort, these records have a **potential duplicate-source identity** if the new file is compiled. This conclusion is source/code inspection **only**; no research estimator or compiled ItemDB was run. Keep game flavour/patch metadata; resolve original comment/study identity without indiscriminately collapsing distinct Classic-vs-Retail observations.

## Felweed: same previously archived historical source, denominator absent

Nov 9 Legacy rows `legacy-20261109-95507..95508` record **funknut's** post-3.0.2 Felweed-only totals of **94 Nether Pigment (39342)** and **4 Ebon Pigment (43108)** at [WoWhead MoP Classic page](https://www.wowhead.com/mop-classic/item=43108/ebon-pigment). I checked the [original retail item page comment](https://www.wowhead.com/item=43108/ebon-pigment) with the exact same author, wording and totals. The October 28 [archived original-source observation](../../../evidence/observations/2026-10-28-0837-legacy-batch008-felweed-original-player-aggregate.jsonl) already contains this source and exact two output totals. Again **one historical cohort**, not a new independent experiment. Neither recording states actual completed casts, input-herb quantity, output-specific hits, rank, or histogram. In particular, `4/94` is not a drop probability.

## Handoff/disposition

Retain all immutable evidence and original author/source URLs. Reconcile worker records to the canonical October 28 source identities via append-only review/corrections in worker-owned scope before any estimator promotion. Preserve historical build and flavour as context, not as independent evidence. Verify any proposed compiler deduplication with a focused test on actual combined records; no tests were executed for this note.

**This checkpoint:** 6 Nov-9 evidence rows matched to 3 previously archived original-source cohorts (2 Sgtown herb batches + 1 funknut Felweed batch); **0 newly independent cohorts, 0 newly measured operations, 0 verified current Retail gold decisions, 0 rendered tooltip fields**. The other four Nov-9 Legacy rows were not adjudicated here. High-priority separate work remains current Midnight T0005/T0039/T0045 original event/rank/refund/skill gaps.
