# Enchantrix 3.3.5 saved-counter instrumentation and reference-channel gate

**Research Manager verification:** 2026-11-16T05:05Z. **Scope:** freshly committed Legacy Cobalt/Saronite source counters (not a new independent study), with the original instrument's code, saved variables and worker record vector. No changes to workers' append-only evidence, research estimator, addon or owner implementation branch.

## Primary source pins (code and raw counters, same upstream revision)

- [Original addon EnxMain.lua](https://github.com/ozzieem/WoW_3.3.5_Addons/blob/0337b2b7be836229254771a9e573059dbf5e51b4/Interface/AddOns/Enchantrix/EnxMain.lua), blob `49dd9f99a1b605b9a046c94f1a9b4f8e80f7ca8f`: `UNIT_SPELLCAST_SUCCEEDED` captures a recent target, but `SaveProspect`/`SaveMilling` are **only called in the subsequent LOOT_OPENED handler**, after looping over item loot slots. `SaveDisenchant` runs separately *inside* that slot loop (one call per reported reagent slot, not a standalone proof of one complete disenchant).
- [Original addon EnxStorage.lua](https://github.com/ozzieem/WoW_3.3.5_Addons/blob/0337b2b7be836229254771a9e573059dbf5e51b4/Interface/AddOns/Enchantrix/EnxStorage.lua), blob `ca0cad53107cc23666840677c6d83058d0f608ce`: `ProspectedLocal[id].total += 1` per `SaveProspect` call and `ProspectedLocal[id][reagentID] += quantity` per captured material. Milling counters follow the same contract. These are **detected loot-window capture counts and summed output units**, respectively; output units are **not** castsWithDrop. No positive-stack histogram or independent spell-attempt counter is saved.
- **Separate static-data channel:** `getItemProspects(link)` returns `Enchantrix.Constants.ProspectableItems[itemID]`, *not* `ProspectedLocal`. Its tooltip value and the saved observed account counters are different sources; neither is an independent replication of the other, and static reference numbers must not be labeled measured.
- [Pinned OZZIEEM Enchantrix.lua](https://github.com/ozzieem/WoW_3.3.5_Addons/blob/0337b2b7be836229254771a9e573059dbf5e51b4/WTF/Account/OZZIEEM/SavedVariables/Enchantrix.lua), blob `237c16bb26b63edbeb6cc8f733ffd149e0d514fb`, compared with [Legacy worker's 17 evidence rows](../legacy/20261116T0446-ozzieem-cobalt-saronite-verified-local-counters.jsonl), blob `e2307852dce619489d65d7af1dcc534705e24f72`. The EVIAN/HASKINA matching account snapshots were already correctly held by the worker as duplicates; this review does not add them.

## Bounded reconciled numbers

| Historical input | Detected SaveProspect calls | Distinct output IDs | Sum of output units | Units per **detected** call |
| --- | ---: | ---: | ---: | ---: |
| Cobalt Ore `36909` | 40 | 7 | 57 | 57/40 = **1.425** |
| Saronite Ore `36912` | 56 | 10 | 145 | 145/56 = **2.5892857** |

All 17 individual material ID/unit totals were checked exactly against the original SavedVariables; worker `castsWithDrop` and `histogram` correctly remain null. A separate `MillingLocal[36903]` has **703 detected calls**, 2,027 units of 39343 and 1,086 units of 43109; it was already recorded in an earlier Legacy file, so **no duplicate study was added**.

**Denominator caveat not previously explicit in worker checkpoint:** `total` increments only after the addon observes the relevant LOOT_OPENED path. If a completed cast has no captured loot window, these counters do not observe that event; the saved aggregate alone cannot establish a **complete zero-inclusive count of every successful cast**. A loot window with zero item slots could still increment `total` if triggered. No loss rate, missing-zero count or output P(hit) can be reconstructed. The totals/denominators are defensible historical **captured-operation** means, not verified all-attempt probabilities or current Retail calibrated expectations. Do not infer 5x or per-ore units from `total`: the 5-ore recipe batch is separate input metadata.

## Validation and decision

**15/15 targeted in-memory JavaScript assertions passed; zero failures.** They inspected the upstream spell/loot/save call graph, separated the static lookup channel, matched the 17 current worker rows to their exact original source key/value totals, checked one studyKey per input and null hit fields, and explicitly recognized the already-present 703-mill cohort. This is a **source/instrumentation contract audit**, not executed Lua addon, Python estimator, synthetic-price runtime/tooltip or live WoW validation.

**Disposition:** preserve original 17 worker records unchanged and keep historical measurement units and capture limitations in downstream provenance. Treat static Enchantrix constants as labeled reference data only, never as new independent observed casts. For gold action improvement, acquire a current-Retail per-event export that logs *each* completed prospect/mill with input/output ranks, all material quantities including zeros, refunded inputs, skill/spec/unlocks and game build (Midnight T0039 is highest priority). No addon, owner three-pass, main or PR writes made.
