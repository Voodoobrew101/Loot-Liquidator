# Magma Thresher (199344): confirmed Prospecting reagent association, unresolved fish-specific input unit

**Checked:** 2026-11-17T13:02:20.453Z. **Scope:** new independent source-to-ingredient verification and review of already-stored actual offline runtime probes. This is NOT a new experiment, a new numerical yield, a confirmed 2026 Retail prospect action, or a live-WoW test.

## Verified source identity and lineage

- [Warcraft Wiki's Magma Thresher entry](https://warcraft.wiki.gg/wiki/Magma_Thresher) identifies the Dragon Isles rare fish **Magma Thresher** and explicitly lists **Dragon Isles Prospecting** under **Jewelcrafting → Reagent for**. It also lists the cooking use separately. This supplies a specific item-to-profession processing association rather than only the item's suggestive flavor text.
- [Wowhead item 199344](https://www.wowhead.com/item=199344/magma-thresher) identifies the same fish with item ID **199344**. Its flavor text says it *looks* prospectable; flavor text by itself would not establish a runnable recipe.
- [Goldcap's Retail item listing](https://goldcap.gg/retail/us/items/199344) independently corroborates the same item ID, name and Dragonflight commodity identity. Its AH pricing is neither measured material yield nor a fixed conversion input.
- [Dragon Isles Prospecting spell 374627](https://www.wowhead.com/spell=374627/dragon-isles-prospecting) generally refers to **five Dragon Isles ores**. That ordinary-ore quantity is NOT a verified fish batch and must not be transferred to Magma Thresher as a fish-specific requirement.

## Existing owner runtime evidence, unchanged

The owner implementation already calls this item **Magma Thresher** and intentionally retains reference-only *per input* rates, while leaving the actual fish recipe/batch eligibility unresolved ([PASS-2 checkpoint](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/usable-data-tooltips/docs/usable-data-audit/PASS-2.md)). Do not describe the item-name discovery as a new outcome or create an extra reference table.

The stored, actual-engine **offline** synthetic [runtime probe ledger](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/usable-data-tooltips/docs/usable-data-audit/runtime-probes.jsonl) includes the model keys `Prospect:199344:x1` and `Prospect:199344:x5` with **14 fallback output pools** each. For representative output pool **192837 / rank alternatives [192837,192838,192839]**, the stored reference model gives:

| Offline key | Reference unconditional expected units for 192837-family pool | Artificial net value at exactly 100 copper per output | Method legal in client? |
|---|---:|---:|---|
| `Prospect:199344:x1` | 0.0281 per one fish input | 2.81 copper | **Not tested** |
| `Prospect:199344:x5` | 0.1405 per five nominal fish inputs | 14.05 copper | **Not tested** |

The fivefold quantity and copper difference is deterministic source normalization, **not evidence that five fish are consumed in a craft**, not a measured output count, not P(hit), not a real-character gold recommendation. Both original probes explicitly state `"eligibility": "Not tested; source audit only"`. The source's output rank alternatives remain alternatives; do not add them together or assign a made-up actual rank.

**Newly resolved field:** the source item **199344** is explicitly associated with **Dragon Isles Prospecting** in a dedicated reagent-for listing. This narrows *source ingredient identity*. It does NOT independently resolve a current-build recipe spell/batch/character legality, nor guarantee these 14 per-input calculator pools reflect current Retail fish outcome tables.

## Exact remaining gate and next check

1. Obtain item-specific, current Retail spell/reagent requirements or a reproducible in-client prospect action for item **199344** with **quantity consumed, skill/unlock, build and output identities**. The general ore recipe is not sufficient.
2. Only after that, run a new isolated exact-input actual resolver/valuation/formatter test with correctly priced fish input and output ranks; keep the existing per-input fallback explicitly reference-labeled, compare cost/eligibility, and do not assert live profitability from a synthetic 100-copper output fixture.
3. Preserve separate unknowns: *input legality and consumed batch* versus *expected output units* versus *P(hit), conditional stack size, output quality and current patch*. No new casts, per-output zero/hit histograms, resourcefulness record, measured coefficient, or 2026 Retail gold action was established here. Worker-owned numeric gaps remain assigned as before.

**Bounded validation performed in this manager run:** **11/11 in-process JSON assertions passed** against the stored `runtime-probes.jsonl` and `summary.json`: both keyed profiles, their expected units, source-type identity, fivefold arithmetic, 100-copper arithmetic, explicit untested eligibility, and summary inventory presence. These read preexisting offline-engine outputs; manager did not execute Python compilation, native Lua tests, a new formatter/decision model, GitHub CI or WoW client.

**Review boundary:** manager original-source note only. Do not mutate owner `implementation/usable-data-tooltips`, the frozen `4df9ae8` source pin, worker evidence, imported rates, output eligibility or addon UI. Other still-open, higher-priority Midnight T0005/T0039 per-output cast/hit/zero/rank refund gaps remain unchanged.
