# Source-to-recipe identity audit — Magma Thresher (199344)

Checked 2026-11-14 UTC. This is a research-only **recipe identity** follow-up to the independent January 2023 500-fish outcome report in `20261114T1004-df-magma-thresher-original-500-fish-prospect-aggregate.md`. It does not add another observation or a current Retail valuation.

## New cross-source finding

- The existing Dragonflight worker record `dragonflight-20261031-20010`, in `research/v3/evidence/dragonflight/2026-10-31T2027-magma-thresher-prospecting-cohorts.jsonl`, correctly identifies item **199344 Magma Thresher** as a *listed Jewelcrafting reagent for* the recipe named **Dragon Isles Prospecting**, but had `recipeSpellID=null` and `inputsPerCast=null`. Its source is [Warcraft Wiki, Magma Thresher](https://warcraft.wiki.gg/wiki/Magma_Thresher); the wiki lists this fish under **Reagent for → Jewelcrafting → Dragon Isles Prospecting**.
- Independently checked [Wowhead's named Dragon Isles Prospecting spell](https://www.wowhead.com/spell=374627/dragon-isles-prospecting). The **named standard Dragon Isles Prospecting spell ID is 374627**; it is a Jewelcrafting spell, with Salvage Item Crafting Data (2), value **5**, and description specifying *five Dragon Isles ores* destroyed. This establishes the named spell identity, **not** that it accepts any particular fish under current client conditions.
- [Wowhead's Magma Thresher item 199344](https://www.wowhead.com/item=199344/magma-thresher) retains the historical tooltip saying this fish looks prospectable. The source-backed fish-to-**named profession method** association plus the specific **named method's spell ID** are narrower findings than source-confirmed current client eligibility or a fish-specific batch count.
- Distinguish [Wowhead spell 393067, “Magma Thresherl”](https://www.wowhead.com/spell=393067/magma-thresherl): this is a fishing-pool interaction description, **not** Dragon Isles Prospecting. Never import 393067 as a processing recipe.

## Field-level disposition (against existing worker recipe record)

| Field | Disposition | Provenance / limit |
| --- | --- | --- |
| `inputItemID` | 199344, previously verified | Wowhead item and earlier worker recipe |
| `method` | Prospect, previously verified historical association | Warcraft Wiki item reagent-for list |
| `recipeName` | Dragon Isles Prospecting, previously verified | Warcraft Wiki |
| `recipeSpellID` | **374627 is the ID of the named standard Dragon Isles Prospecting spell** | Wowhead spell page; **candidate linkage for this special fish**, not source-verified live fish-targeted cast |
| `inputsPerCast` | **unknown for fish (null)** | Spell 374627 explicitly says five *ore*; do not silently apply this to a fish |
| `completedCasts`, `castsWithDrop`, `histograms`, `inputRefunds`, `outputRankItemLinks` | **unknown** | 500 nominal fish in independent January 2023 source is not 500 casts |
| Current 2026 Retail fish eligibility, proficiencies, source cohort compatibility | **unverified** | No actual-client receipt or current supported fish-specific processing rule tested |

## Worker/engineering handoff

The Dragonflight worker owns any append-only recipe correction: link `dragonflight-20261031-20010` and the two sources, but only encode `recipeSpellID=374627` for fish after checking the actual spell-input applicability. Keep `inputsPerCast` null until a fish-specific client recipe/receipt or primary spell-input table proves it. Do not edit the original worker JSONL or create an unrelated source cohort. Add a held `Prospect:199344` identity/eligibility assertion to the existing pass-2 ledger for the integration owner; do not move addon state or count new priceable profiles from this note.

No new observed numerical rows, independent cohorts, probabilities, input savings, cast counts, current eligible profiles, supported gold decisions or tested tooltip fields. No scripts, synthetic-price probes, Lua suites or live WoW client tests were executed for this note.
