# Loot Liquidator — War Within worker Batch 008, 2026-10-28 08:18 PDT

**Branch:** `research/processing-confidence`; **master queue:** revision 10; **assignment:** `2026-10-28-batch008-war_within`; **home scope superseded by explicit BfA/Shadowlands overflow.** Current released `GameData.lua` source blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`. Read canonical ITEMDB creation, v1.4 synthesis, numeric protocols, mechanics/API registries, evidence schema, issue #2, PROGRESS, current GameData and coverage ledger before work. **Only worker-owned additive research files changed.**

## Assigned first-pass: 35/35 exact keys

- 5 Platinum Ore (152513) outputs, 13 Storm Silver Ore (152579), 7 Osmenite Ore (168185), 7 Laestrite Ore (171828), 3 Solenium Ore (171829). All 35 source-line/output-ID pairs match GameData and are `NEVER_EXAMINED` in the master ledger at audit time. All 35 historical TSM tuples pass the necessary `matRate*min <= 5*amountOfMats <= matRate*max` check **under the explicitly unverified assumption that amountOfMats is per ore**.
- Historical TSM `matRate` is a **proxy**, not a proven per-operation P(at least one); historical positive min/max are not direct observed extrema. Source `amountOfMats` native unit has not been independently established. Do not promote any of these to current-Retail probabilities, yield bounds, or expected quantities.
- Current-Retail four-field evidence scores, separately per output: P=25, positive min=30, positive max=30, E=30; weakest-field record score=25. **140/140 scored fields below 70, 0 at 70–89, 0 at >=90; 0 complete >=90 records.** First-pass proposal is 35 `EXAMINED_INSUFFICIENT` records, not 35 verified conversion rows. Master owns coverage acceptance. The last accepted baseline was 1078/1737 examined, 659 never; this worker does not advance that central ledger.

## HIGH-PRIORITY SOURCE ID CORRECTION: Platinum / Storm Silver swapped in prior archive

Original player table (Tontons): https://www.wowhead.com/cn/spell=31252/%E9%80%89%E7%9F%BF (lines 387–409) explicitly lists **Platinum Ore 1,610 ore / 322 casts** and **Storm Silver Ore 2,775 ore / 555 casts**. In the previous `legacy-batch007-tontons-bfa-three-cohorts.jsonl`, the 322-cast output vector was incorrectly attached to **152579 (Storm Silver)**, while the 555-cast vector was attached to **152513 (Platinum)**. The original primary table confirms the opposite association. This affects 26 original output associations (13 per ore); it also contaminates previous comparisons, including 8 previously first-pass-reviewed 152513 rows (L1084–L1091). Do not treat the two wrongly attributed archives as independent replicates of the corrected evidence.

New **immutable corrective observations** preserve original integer output totals and the actual 5-ore operation counts:
- Platinum 152513: 1610 ore / 322 reported casts; uncommon 627, rare 229, Kraken's Eye 13, all 13 mapped output IDs.
- Storm Silver 152579: 2775 ore / 555 reported casts; uncommon 983, rare 234, Kraken's Eye 18, all 13 mapped output IDs.
- Example assigned outputs: Platinum Scarlet Diamond 154121 = 43/322 = 0.133540 historical units/cast vs TSM hypothetical 0.1185; Storm Silver Scarlet Diamond = 34/555 = 0.061261 vs TSM hypothetical 0.076. These are **historical source discrepancies**, not 2026 Retail correction rates. Tontons also reports a later Kraken's Eye rate increase without a controlled patch bridge: https://www.wowhead.com/item=153706/krakens-eye .

**Master action:** quarantine the two swapped input associations in the prior archive; accept or reject these two corrective observations; recheck prior BfA audits and source-dependent synthesis. Do not overwrite the original archive or auto-correct GameData.

## Eight original-source cohorts / 53 reported output cells archived

| Independent original source | Input and conditions | Raw input | Actual completed casts | Usable scope |
|---|---|---:|---:|---|
| Snurp Wowhead PTR, https://www.wowhead.com/item=168185/osmenite-ore | Osmenite standard, PTR build 30329, JC 150/175, no tool | 40,000 | 8,000 explicitly reported | Historical PTR 5-ore standard |
| Live Reddit https://www.reddit.com/r/woweconomy/comments/c8lcye | Osmenite mass, July 3 2019 | 16,760 | Unknown | Historical mass ore-equivalent only |
| Live Reddit https://www.reddit.com/r/woweconomy/comments/cj6ju4 | Osmenite mass, July 29 2019 | 6,800 | Unknown | Historical mass ore-equivalent only |
| close0ne Wowhead https://www.wowhead.com/item=168185/osmenite-ore | Osmenite mass, patch 8.2.5, JC 175/175, tool yes | 4,000 | 200 explicitly reported | Historical 20-ore mass, not standard |
| Original Reddit poster https://www.reddit.com/r/woweconomy/comments/k6fuik | Laestrite, Dec 4 2020 | 10,000 | Unknown | Five-ore equivalent only |
| Separate Reddit commenter, same thread | Laestrite, Dec 4 2020 | 10,000 | Unknown | Independent reported cohort; same discussion, no unique permalink |
| Osulivan Wowhead https://www.wowhead.com/spell=311949/mass-prospect-solenium | Laestrite original per-ore table | 1,000 | Unknown | Five-ore equivalent only |
| Same Osulivan table | Solenium original per-ore table | 1,000 | Unknown | Mass Solenium spell uses 20 ore; original performed recipe unknown |

**Total:** 89,560 reported ore across eight cohorts, 8,200 explicitly reported actual operations (8,000 standard PTR + 200 mass); **do not treat 89,560/5 as measured operations**. The Tontons corrected BfA observations are **reused original evidence**, not two additional independent source discoveries.

### Osmenite source arithmetic and an outlier

The six coloured outputs in Snurp's 8,000-cast standard PTR sample sum to **8,000 exactly**, consistent with the author's explicit one-coloured-gem-per-standard-cast statement. Under that **historical PTR-only one-gem partition condition**, each of those six outputs has a reconstructable historical P(at least one) = original count/8,000, and positive yield = 1; this is **logically inferred from an aggregate plus the source's per-cast rule, not an independently archived hit histogram**. Do not promote it to 2026 Retail or to mass prospecting. Leviathan's Eye 1,166 is an additional gem and must not be part of the six-colour partition.

Mass-prospecting sources must remain separate by patch/gear/recipe: 16,760 ore produced exactly 3,352 coloured gems (one per five-ore equivalent), and the 4,000-ore/200-mass-cast study produced 800. However, the **6,800-ore** source reports **1,489 coloured gems**, exceeding 6,800/5 = 1,360 by **129 (9.485%)**. This contradicts the one-colour-per-five-ore extrapolation *if* the same rule applied; it is not proof the source is false, because mass variant, bonuses and patch differ. Flag as an outlier; **do not pool or overwrite**. Historical TSM proxy 168188 has E5=0.165 whereas the PTR Sage Agate count 467/8000=0.058375; the sources are not matched.

### Shadowlands independent study synthesis: quantity only, conditional

Three original Laestrite reports total **21,000 ore**. Their source-normalized **per five-ore equivalents**, not proven actual-cast E, are:

| Output | Original units across sources | Units / 5 ore equivalent |
|---|---:|---:|
| Oriblase (173108) | 2106 | 0.501429 |
| Angerseye (173109) | 2100 | 0.500000 |
| Umbryl (173110) | 2058 | 0.490000 |
| Essence of Rebirth (173170) | 147 | 0.035000 |
| Essence of Torment (173171) | 183 | 0.043571 |
| Essence of Servitude (173172) | 161 | 0.038333 |
| Essence of Valor (173173) | 143 | 0.034048 |

These three cohorts are plausibly different original players, but the first two share a Reddit thread, and original exact recipe, skill, build, refunds and cast count are unverified. The `synthesize_studies.js` strict-context pooling gate should **reject** them; the table is a descriptive **ore-normalized historical synthesis**, not an approved per-cast baseline or a confidence interval. A true 95% interval cannot be derived from missing zero-inclusive per-cast variance. The TSM values may derive from these same published studies, so **TSM is not counted as a fourth independent experiment**. The Solenium 1,000-ore source independently reports Oriblase 95, Angerseye 114, Umbryl 100; its 20-ore mass recipe context must not be silently compared as a 5-ore cast.

## Disjoint numerical-mechanics hypothesis: tww-prospect-resourcefulness-savings

**BLOCKED / UNVERIFIED; confidence 0; zero VERIFIED_NUMERIC; no coefficient or formula.** The 2024 original Aqirite study https://www.reddit.com/r/woweconomy/comments/1f83cnd reports 1,040 clicks and 5,200 purchased ore but no actual saved-ore tally. The October 2024 discussion https://www.reddit.com/r/woweconomy/comments/1g8kbaq confirms that Resourcefulness may leave leftover ore after a queued 200-cast 1,000-ore stack, but does not measure refunds. Dragonflight 2023 savings of 0.33125 ore per reported operation at 22% Resourcefulness are **not** a TWW coefficient.

**Required experiment:** same Retail build, exact Algari Prospecting spell 434018 and Aqirite R2 (210934), >=500 actual completed five-ore casts in each of two matched Resourcefulness settings, known skill/specialization nodes/gear/rating/percent, saved ore integer per cast including zeros, initial and ending inventory and reprocessed refunds separately reconciled, independent replication. Target **EXPECTED_INPUT_CONSUMPTION only**, not material output P/E/quality.

## QA, provenance and exact next targets

- 35 exact source-line/ID and ledger NEVER_EXAMINED checks; 35 necessary TSM inequalities; eight original observation cohorts (53 output totals); two corrective BfA observations (26 output totals); schema-shaped recursive checks and arithmetic in the validation supplement. **No full AJV JSON Schema, repository Node suite or in-game tests** were executed. No validated current-Retail numerical transforms or current-Retail output corrections.
- Source-dependence: BfA Tontons original three cohorts share one author/table; previous wrong-ID archive is a copy, not an independent study. Osmenite PTR GameData compiled means originate from Snurp, not a second source. Laestrite first two are separate player cohorts in one thread. Osulivan Laestrite and Solenium are same author's table but different inputs. Do not count reposts, translations or TSM-derived compilations as replications.
- Next assigned-key experiments: (1) 152513:154121–154125 and 152579:153700–154125 with **corrected input identity** and source patch; (2) 168185:168188–168635 with same-build 5-vs-20 ore recipe and profession tool context, investigate 6,800-ore anomaly; (3) 171828:173108–173173 and 171829:173108–173110 with exact recipe/batch, zero-inclusive per-cast output and refunds. All remain **EXAMINED_INSUFFICIENT** pending master review.
- Field-level labels: BfA Tontons and PTR means = historical DIRECT_REPORTED_AGGREGATE, Laestrite = HISTORICAL_ORE_NORMALIZED, PTR six-colour occurrence = RULE_CONDITIONAL_INFERENCE, TSM = HISTORICAL_PROXY, current Retail = BLOCKED. **No inferred formula or numeric mechanic approved.**
- Future static bundled database remains exact lowercase `itemdb.lua` only after separate master QA and user-approved migration. No production Lua, TOC, main, central ledger, queue, PROGRESS, or schedule changes.

### Worker-owned deliverables

- [35-key synthesis audit](https://github.com/Voodoobrew101/Loot-Liquidator/blob/research/processing-confidence/research/coordination/submissions/loot-liquidator-war-within/2026-10-28-0818-warwithin-batch008-35key-synthesis-audit.csv)
- [Eight original-source observations](https://github.com/Voodoobrew101/Loot-Liquidator/blob/research/processing-confidence/research/evidence/observations/2026-10-28-0818-warwithin-batch008-eight-original-primary-cohorts.jsonl)
- [Corrected BfA source observations](https://github.com/Voodoobrew101/Loot-Liquidator/blob/research/processing-confidence/research/evidence/observations/2026-10-28-0818-warwithin-batch008-tontons-bfa-two-corrected-cohorts.jsonl)
- [TWW numeric candidate](https://github.com/Voodoobrew101/Loot-Liquidator/blob/research/processing-confidence/research/coordination/submissions/loot-liquidator-war-within/2026-10-28-0818-warwithin-batch008-tww-resourcefulness-numeric-candidate.json)
- [Validation supplement](https://github.com/Voodoobrew101/Loot-Liquidator/blob/research/processing-confidence/research/coordination/submissions/loot-liquidator-war-within/2026-10-28-0818-warwithin-batch008-validation.json)

**Handoff:** master must independently review the source-ID swap before accepting these 35 first-pass records; no new 90+ fields or verified rules were self-approved.
