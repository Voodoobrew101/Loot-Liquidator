# Research Manager — Empyrium original-source output units vs frozen fallback

Checked UTC: 2026-11-18T01:00:25.391Z. Scope: research-only numeric/identity reconciliation of Legacy T0042 standing-source evidence. **No addon, owner-integration, main, worker original, research compiler, schedule or PR modification.** This is not a current-character or exhaustive Retail measurement.

## New firsthand source evidence, independent reported-ore cohorts

The [Apphrodite Empyrium comment](https://www.wowhead.com/item=151564/empyrium) reports **2,000 ore prospected**, six epic gem totals **6 Florid Malachite / 6 Hesselian / 17 Labradorite / 11 Lightsphene / 12 Argulite / 9 Chemirine**, plus **400 Gem Chips**. It does **not** specify regular vs mass prospecting, successful operation count, stack-level histograms, ore refunds, chance denominators, or current Retail epoch.

The separately authored [Xeforolan Chemirine comment](https://www.wowhead.com/item=151720/chemirine) reports **mass prospecting 1,000 Empyrium**, six epic totals **6 Florid / 1 Hesselian / 10 Labradorite / 5 Lightsphene / 1 Argulite / 10 Chemirine**, plus **285 Gem Chips**. These are **two separate author observations**, not copies of one study. [Mass Prospect Empyrium spell 247761](https://www.wowhead.com/spell=247761/mass-prospect-empyrium) is a 20-ore recipe, but 1,000/20 = 50 is *nominal recipe equivalents*, **not independently observed completed casts**. Gem Chip **129100** is the ordinary colorless bag reagent, distinct from the colored preview-only chip identifiers (see [Warcraft Wiki](https://warcraft.wiki.gg/wiki/Gem_Chip) and [Wowhead](https://www.wowhead.com/item=129100/gem-chip)).

The [worker's source-specific 14 Empyrium drop rows](../legacy/2026-11-18T0053-empyrium-two-original-cohorts-feliron.jsonl) retain both distinct study keys and original per-material totals; exact worker blob **4855e9783fb7372366d7f001561a7d7eb8c65bd4**, source commit [06d8f19](https://github.com/Voodoobrew101/Loot-Liquidator/commit/06d8f19f12476a556f9faff810da13fe4e2005a9). The same worker file has one additional Fel Iron anecdote, **not** part of this Empyrium analysis. No new third-party empirical cohort is asserted.

## Per-*reported input ore* rate, never invented P(hit)

Every rate below is exactly **source-reported total material units / source-reported ore**. It is not a verified per-completed-cast yield, independent occurrence probability, current Retail expected quantity or calibrated confidence. Source authors do not state net ore consumption/refunds, which is why the denominator remains labeled **reported ore**.

| Exact output identity | Apphrodite units / 2,000 ore | Per reported ore | Xeforolan units / 1,000 ore | Per reported ore |
| --- | ---: | ---: | ---: | ---: |
| Florid Malachite 151722 | 6 | 0.003 | 6 | 0.006 |
| Hesselian 151721 | 6 | 0.003 | 1 | 0.001 |
| Labradorite 151579 | 17 | 0.0085 | 10 | 0.010 |
| Lightsphene 151719 | 11 | 0.0055 | 5 | 0.005 |
| Argulite 151718 | 12 | 0.006 | 1 | 0.001 |
| Chemirine 151720 | 9 | 0.0045 | 10 | 0.010 |
| **Gem Chip 129100** | **400** | **0.200** | **285** | **0.285** |
| Six epic gems together | **61** | **0.0305** | **33** | **0.0330** |
| All seven *reported* materials | **461** | **0.2305** | **318** | **0.3180** |

For an **illustration only**, assigning the same synthetic **100 copper per *unit*** to every reported material, the apparent gross source-reported output per ore would be **23.05c** (Apphrodite) and **31.80c** (Xeforolan), of which respectively **20.00c** and **28.50c** derives from Gem Chips. This is **arithmetic on original inventory totals**, not the addon's actual-engine audit, not profit (input cost/fees excluded), not live price and not confirmation of current processing eligibility. It demonstrates why ignoring a material identity can matter more than a small epic-gem rate difference.

## Frozen data field comparison and high-value disposition

The untouched [research/v3/output/estimates.json](../../output/estimates.json) blob **15ae8c5b7f7b2587ceff1dcd3e8b9d13d4351d1e** has exactly six `Prospect:151564` epic-output entries, each with `average=0.03`, `chance=0.03`, both source labels `starting guess`, and `studyCasts=0`. It **does not have an Empyrium→Gem Chip 129100 estimate entry**. Consequently, the **historical original source provides seven identified quantity observations for each of two distinct processing contexts, versus six unmeasured frozen epic guesses and no chip entry**. No claim is made that the owner's existing ItemDB or runtime is missing Gem Chip: this inspection is confined to the frozen v3 output, not the current compiled addon/tooltip.

**Disposition:** `usable original historical gross-ore output quantities, not yet shown as newly admitted numeric estimates`; output identity for 129100 independently corroborated. **Do not treat the frozen six guesses as empirical rates, infer 100%-or-3% observed P from source totals, invent 400/50 physical casts, blend regular and mass methods, or count multiple language mirrors as additional samples.** Under the owner's Nov 2 policy, these correctly normalized *per reported input ore* totals are candidates for **labeled historical provisional output-value modeling** only if target game flavour/current recipe, input-unit basis, co-output handling and no-overlap with better data are independently verified. Keep non-priced uncertainty visible rather than deleting the original totals.

This is a genuine frozen `missing empirical quantity / missing material identity` candidate—not a missing-market-price issue. Next priority: original at-cast Retail data for Midnight Umbral Tin 237362 T0005/T0039 and Tranquility Bloom 236761 T0045; for Empyrium specifically, confirm regular/mass spell identity and any current Retail applicability, then compare against owner's already populated runtime source ledger **without altering the owner branch**. Preserve both worker studies append-only.

## Bounded validation / forbidden claims

Executed **74/74 in-memory JS assertions**: two distinct seven-material worker cohorts, all exact output IDs and source inventory totals, no invented operation counts or histograms, epic/chip aggregations, six existing frozen starting guesses and absent Gem Chip estimate. Independent primary Wowhead comments and the Gem Chip identity page were read. **No new Python estimator, importer, native Lua, actual addon valuation engine, tooltip render, latest GitHub CI execution, client session, or live-WoW eligibility test was performed here.** No newly accepted Retail EV, supported tooltip field or live gold recommendation is claimed.
