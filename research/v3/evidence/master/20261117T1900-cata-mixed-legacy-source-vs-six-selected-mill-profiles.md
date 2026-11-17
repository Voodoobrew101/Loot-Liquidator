# Cataclysm mixed-herb milling: source-unit gate versus six stored offline tooltip profiles

**Research Manager source-to-selected-field audit — 2026-11-17T19:07:01.389Z UTC.** This is a research-only comparison of one *new worker-owned original mixed-herb source* and twelve older model projections against the owner's **previously executed** actual-engine synthetic-price fixture. It is not a new experiment, an import, a newly rerun valuation engine, or current Retail eligibility proof.

## New verified source-to-field dispositions

The Legacy worker's [November 17 original-source records](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/five-agent-completion/research/v3/evidence/legacy/2026-11-17T1841-cata-mill-mixed-original-and-historic-reference.jsonl), source blob `46fe752cfae7b0172584b7874a16c24502f6b364`, accurately retain **one** firsthand [Wowhead commenter 775895](https://www.wowhead.com/item=61980/burning-embers) mixed-herb observation as **two outputs**: 19 stacks Whiptail (52988), 3 stacks Azshara's Veil (52985), 2 stacks Cinderbloom (52983) produced **266 Ashen Pigment (61979)** plus **41 Burning Embers (61980)**. This is **one source cohort**, not two experiments. Neither stack fullness, exact herb units consumed, completed mill operations, allocation by herb, patch, profession, per-output hit/zero counts, nor histograms is reported. The worker's `inputItemID=null`, `casts=null`, `castsWithDrop=null`, and shared `studyKey` correctly preserve that uncertainty. **No single-input item-level E or P is derivable** from the mixed total.

**Arithmetic only under an UNVERIFIED full-20-herb-stack assumption:** 24 stacks would equal 480 herbs, i.e. 96 nominal 5-herb equivalents, giving 266/96 = **2.770833 Ashen** and 41/96 = **0.427083 Embers** per nominal mixed mill. This is **NOT 96 observed completed casts**, and it does not identify which herb made which output; it must not be treated as direct per-cast evidence. At an artificial 100 copper per pigment and zero item cost, the same conditional arithmetic produces 30,700c/480 = **63.95833c per nominal herb**.

A separate [blackdrako3000 historical Wowhead reference comment](https://www.wowhead.com/item=61980/burning-embers) supplies 12 *model projections*, not 12 independent studies, for six herbs and the same two outputs. It calls Ashen values **250%/270%/300%**, and Ember values **25%/50%**. Since 250–300% cannot be an ordinary 0–100% hit chance, these are ambiguous rate/expected-unit notations. It is plausible that 250% represents a 2.5-unit-per-mill model, but the author has not supplied the observation denominators, units, positive-yield stack distributions, or model method. **Do not rename them observed E=2.5/2.7/3.0 or P(hit), derive empirical confidence, or multiply independently by a presumed hit chance.** Keep `percentShown` and `percentMeaning=unclear` intact until source meaning is independently established.

## Exact saved offline resolver/formatter comparison

The owner's frozen [367-profile actual-engine offline fixture](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/usable-data-tooltips/docs/usable-data-audit/runtime-probes.jsonl), blob `534b970d475d75e54b1d5bc4777e807384814372`, already selects and *renders* **both** Ashen and Ember output expected quantities for all six individual five-herb mill profiles. These are synthetic conditions with all sources enabled and **100c net per output**, not present Retail prices/character legality. Values below are the saved selected unconditional E per **five-herb mill** and computed copper per **input herb**, not this run's engine execution:

| Input | Ashen 61979 E | Ember 61980 E | Stored 100c synthetic net copper/herb | Source note |
|---|---:|---:|---:|---|
| Cinderbloom 52983 | 2.6929 | 0.3011 | 59.88 | Selected research |
| Stormvine 52984 | 2.4395 | 0.2480 | 53.75 | Selected research |
| Azshara's Veil 52985 | 2.8000 | 0.1500 | 59.00 | Ashen reference fallback, Ember research |
| Heartblossom 52986 | 2.9275 | 0.4775 | 68.10 | Both reference fallback |
| Twilight Jasmine 52987 | 2.9652 | 0.5572 | 70.448 | Selected research |
| Whiptail 52988 | 2.9640 | 1.0800 | 80.88 | Ember explicitly midpoint-derived from its selected chance/range |

With 19:3:2 source stack counts, merely reweighting those **existing, unmatched** synthetic model values yields **76.395c per herb**, which differs from the conditional 63.95833c/source-mixed arithmetic by **12.43667c/herb**. **This is a contextual comparison only, not a demonstrated valuation error or missing model.** The first figure is a mixture of other evidence/models under the audit's artificial assumptions; the second lacks verified actual herb input units, operation count, composition-specific returns and collection conditions. Neither can be represented as a live auction decision. The fact that both material fields are already populated in all six selected profiles also means this source **does not establish a new missing tooltip-field closure**.

## Gate and prioritized next evidence

- **Absent source evidence:** original individual-herb completed mill receipts, per-output hit/zero/stack distributions, exact stacks-to-herbs conversion, dated patch and character skill. Record actual source quantities without filling these unknowns.
- **Not an importer defect:** six selected offline profiles already have expected quantities and two displayed materials. No missing-price assessment is possible from synthetic 100c. Owner implementation branch and pinned snapshot `4df9ae8` remain unchanged.
- **Invalid units/rank risk:** 250–300% cannot be P(hit); interpret as a reference *only* after original rate-definition confirmation. Ink totals are downstream and may not be double counted as pigment outputs. The mixture cannot be promoted to any of its three member items.
- **Worker ownership:** Legacy T0047/T0042/T0022/T0044/T0052/T0053 continues to seek source-level operations and identities; no worker record or queue is changed. Higher-priority Midnight T0005/T0039 (real completed prospects, quality/rank, refunds and zeros) and T0045 (true ten-herb mills) remain first if an original per-event ledger becomes available.

**Checks actually executed:** **105/105 bounded in-process JavaScript assertions** against the 14 worker source rows and six stored profiles (source units/identity, mixed study dedupe, five-herb price normalization, two selected output fields, per-field E-to-100c relation); 0 failed. The original HTML excerpt was independently located by web search. No new compiler/native Lua/addon engine/formatter run, no live WoW test, no new independent cohort, no researcher-owned source modification and no current Retail gold decision.
