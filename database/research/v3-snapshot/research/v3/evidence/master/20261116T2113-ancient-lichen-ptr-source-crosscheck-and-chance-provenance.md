# Research Manager audit — original Ancient Lichen cohorts, PTR scope and field provenance

Reviewed 2026-11-16 UTC. **Research-only source/field audit; not a new current-Retail cohort, compiled import, addon change or live-client validation.**

## Original evidence and independence

- **rollocola**, [original Wowhead Ebon Pigment comment](https://www.wowhead.com/cata/item=43108/ebon-pigment), preserved by the Legacy worker at `research/v3/evidence/legacy/2026-11-16T2049-ancientlichen-verdant-ruby-original-logs.jsonl`, IDs `legacy-20261116-204901..204902`: **22,000 Ancient Lichen (22790) inputs; 13,289 Nether Pigment (39342) and 2,337 Ebon Pigment (43108) total output units.** Exact completed mills, actual consumed net herbs, saved/reused reagents, hit operations, zero bins, output stacks, recipe/client build and specialization are **not** reported. The author's “about 10% chance per herb” is an unverified interpretation; **2337/22000 = 0.1062273 material units per listed herb, not an observed chance per completed mill.** Do not set `casts=4400` from 22,000/5.
- **Kaliope**, [original 2008-10-09 article and author clarification](https://kaliope.wordpress.com/2008/10/09/inscription-a-look-at-pigment-drop-rates-for-milling/), already separately retained as `ww-b009-kaliope-2008-ancient-lichen` (not new evidence): **120 Ancient Lichen inputs; 72 Nether + 14 Ebon total units.** The article explicitly says the test used herbs from the **Test Realm**, and its author says all measurements were taken one day, *probably* **2008-10-07**. Exact client build and operation count remain unstated. This strengthens **historical PTR scope**; do **not** treat the record as an identified live-build or 2026 Retail cohort. It is an independently named original author, but the two cohorts are **not proven patch/condition compatible**.

| Field per five *nominal* herb inputs | rollocola / 22,000 inputs | Kaliope / 120 inputs | Historical TSM comparator |
| --- | ---: | ---: | ---: |
| Nether Pigment expected *units equivalent* | 3.020227273 | 3.000000000 | 3.0000 |
| Ebon Pigment expected *units equivalent* | 0.531136364 | 0.583333333 | 0.5375 |

These are arithmetic input-normalized **projections**, not source-observed completed-cast expected values, percentages, or hit probabilities. Ebon differs by **−8.95%** between the two original cohorts; Nether by **+0.67%**. The rollocola Ebon projection differs from the historical TSM 0.5375 by **−1.18%**, but TSM's upstream independence is unverified: **do not count TSM as a third sample or sum original cohorts across patch conditions**. Kaliope's historical comparison was already reported in `research/evidence/observations/2026-10-28-1040-legacy-batch010-original-source-reconciliation-SOURCE-ONLY.md`.

## Actual offline source-to-tooltip spot-check (read existing artifact, did not re-run addon)

At the protected owner's integration head `3d667d053db587c91401cfed7ecc56862b8340c9`, `docs/usable-data-audit/runtime-probes.jsonl` contains `Mill:22790:x5`: research-family **Ebon expectedQuantity 0.5833** is priced at the fixed synthetic 100 copper/output unit, with displayed `~29.2%` occurrence and 20% overall confidence. The `0.29165` chance equals `0.5833 / 2` (midpoint of displayed positive yield range 1–3); **the original Kaliope totals did not measure P(hit)**. The existing display's tilde/provisional label may intentionally identify a heuristic; whether its field-level provenance is sufficiently explicit is a **review question**, not a verified bug. The mean/value can remain supported provisionally even while the true hit chance is unknown. Existing `Mill:22790:x5` already has a synthetic offline value in the owner's baseline; **no new supported profile or validated live gold decision** is claimed here. Do not touch integration addon/tooltip code during three-pass owner work.

## New source lead, not an import

Kaliope article comment by Tony (2008-10-10) quotes an **unlinked earlier Blizzard forum original**: 20 stacks Felweed -> 19 Ebon units; 7 stacks Mana Thistle -> 18 Ebon units. The original author, batch size/stack size, exact process counts, patch, and whether numbers overlap other studies cannot be established from this secondhand quote. Exact-phrase web searches did not locate the original. **Hold this as an exhausted source-identity lead; no study rows, ratios or cast probabilities to ingest.**

## Bounded verification and next step

21/21 current-turn JavaScript assertions passed against current Legacy worker JSONL and existing Kaliope original transcription: identifiers, two-output totals, no `casts`/`castsWithDrop`, separate cohort keys, rank unknowns, derived per-five units, and `0.5833/2` synthetic chance relation. Read both original public source pages and the owner's stored offline probe. **No** Python/compiler, full native Lua tests, build, real prices or live-WoW run performed.

**Next source-specific action:** obtain dated Retail-era 22790 cast/refund-aware logs and source patch/version to decide whether the old 22,000-input rate is portable; otherwise leave as separately labeled historical reference. Preserve all original evidence and source identities. Immediate higher-impact queue priority remains Midnight T0039/T0005 exact rank/unlock/hit histograms, not another historical reimport.
