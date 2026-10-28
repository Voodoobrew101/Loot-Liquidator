# Loot Liquidator — War Within Batch012 (material-first P0/P1/P2)

2026-10-28; research-only branch `research/processing-confidence`; queue revision 14; initial SHA `1962e00fb6721c02ff24913419c78774992335ba`; GameData blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`. **35/35 exact master-assigned stable keys audited**. Per-key four-field data in the companion JSONL; `null` means unknown, not zero.

## P0: actionable compiler and identity corrections

**Eight real smelting recipes remain quarantined** by the research-stage single-input compiler. Their source `GameData.lua:675–682` contains exact reagent vectors and deterministic output counts. Seven recipes use multiple reagent types; **Fel Iron spell 29356 uses one reagent, 23424×2**, so the master mapping-gap label “multi-reagent” is incorrect for that one. A future recipe-aware schema should represent `{spellID, inputs:[{itemID,quantity},...], outputItemID, outputCount, learned/forge/skillEligibility}` as one recipe. Never assign all output value to a single reagent. These are eight **previously known valid recipes**, not eight newly discovered measurements.

**Thirteen assigned TWW prospecting outputs** from Bismuth R2 `210931`, Aqirite R2 `210934` and Ironclaw R2 `210937` trace to one PeaEsk author/source family: **100 ore per input**, not 100 completed casts. The source's 20 five-ore equivalents are derived; actual casts, saved ore and zero-inclusive distributions were not recorded. `GameData.lua` stores `samples=100` and a Poisson-derived `chance=1-exp(-E)`; neither is a measured 100-cast P(hit). Preserve 13 source-labelled historical E references, but **13 P fields and 26 conditional min/max fields stay unknown**. See [original archived study](../../evidence/observations/2026-10-28-tww-peaesk-three-r2-100ore-cohorts-batch003.jsonl).

**Two Crumbled Stone rows `192880→192849/192866`** assign specific gem quality IDs without the Mgnta original reporting output quality. Retain family totals (564 Eternity Amber, 65 Nozdorite from 3125 stones) and derived 0.9024/0.104 per nominal five-stone equivalent, but do not promote rank-specific expected yields. Actual casts and refund handling are unknown.

**Six Dragonflight TSM diamond rank rows** copy historical rank-family estimates with no original denominator. Source P=.0142, per-five-input E=.014, positive min=1, which fails the necessary bound if taken as exact same-operation values (possibly rounding/units). Do not “fix” by inventing yields. **Five Dragonflight pigment rank alternatives** (191460/191461 to 198421–198423) have copied P=1 and E=3.5 per five inputs; they cannot be treated as simultaneous guaranteed rank drops. Source bounds 2–5 are preserved as low-confidence TSM references.

**Prismatic Leaper `200061` is a genuinely millable fish**, not an invalid input. The original Wowhead commenter Primer milled 15 fish in 3 operations and reported 3 Serene Pigment R2, 5 Flourishing Pigment R2, 2 Flourishing Pigment R3. That source does not establish assigned output ID `190322` or per-cast P/min/max. TSM's `matRate=.002, amountOfMats=.001, min=max1` is incompatible if P=.002 and E=.005 per five fish describe the same operation. Keep this mapping flagged pending exact ID/source-unit verification.

## P1 numeric fields and QA

- 8 smelt recipe outputs retain **32 already documented fixed-result fields** (Bronze P=1, positive 2–2, E=2; other seven P=1, 1–1, E=1) *conditional on successfully performing each recipe*. Evidence confidence 80/100 for static result; exact 2026 learned/forge eligibility not tested.
- 13 historical PeaEsk E reference cells retain 48/100 confidence; **zero newly measured current-Retail P, bounds or E**. All other unproven fields are null. Historical TSM rank alternatives are stored as reference data, not a verified unskilled baseline.
- **57 deterministic assertions passed**, including 35 unique queue keys, GameData exact line identities, fixed recipe probability/yield bounds, no fabricated cast denominators, no Poisson P or TSM P promotion. Full Node, Lua and in-game tests were not executed.

## P2 material gold-decision risk

An [Oct 14, 2024 original 10,000 rank-2 Aqirite study](https://www.reddit.com/r/woweconomy/comments/1g350pq) gives 27.5 Glittering Glass and 72.5 Handful of Pebbles per 1000 ore, or **0.1375 glass and 0.3625 pebbles per five-ore equivalent**. Undated PeaEsk's 100-ore rank-2 Aqirite cohort gives **0.65 glass and 1.75 pebbles per five-ore equivalent**—differences of **4.73× and 4.83×**. These are NOT measured hotfix multipliers; profession conditions and observation date differ. They could flip Prospect versus Auction, but no contemporaneous prices or actual action flip were calculated.

[Blizzard's Oct 25, 2024 hotfix](https://worldofwarcraft.blizzard.com/en-us/news/24148555/hotfixes-october-25-2024) changed byproducts to appear on every prospecting action and slightly reduced gem drops. It does not supply per-output rates or establish that both pebbles and glass individually occur in every cast. Do not apply a universal multiplier.

## Source memory, remaining gaps, master action

Reused PeaEsk (one study/three cohorts), Oct14 Aqirite (one cohort), Mgnta/Laving (two original sources already archived), Primer fish (one historical 3-cast source), eight previously reviewed smelt spell sources and historical TSM (unknown ancestry). **Zero newly discovered independent experiments**, no duplicate original observations archived; four source-review events document meaningful revisits and patch context. Eight spell-page re-fetches avoided.

**Master next IDs:** smelt spells 2659,3569,29356,29360,46353,55208,74537,102167 with reagent-vector schema; TWW 210931/210934/210937 → 212498,212505,212508,212495,212511,213398,213399 zero-inclusive post-hotfix cast logs; Crumbled Stone 192880→192849/192866 output rank; Dragonflight 188658/189143/190311→192870/192871 TSM rank ancestry; 200061→190322 exact identity; 191460/191461→198421/198422/198423 rank alternatives.

Master baseline before acceptance: **975 staged provisional mappings, 229 unknown numeric source cells**, not exhaustive Retail coverage. No production, main, queue, shared ledger, registry, source-memory or schedule changes. Evidence confidence is strength of support, not probability of correctness.
