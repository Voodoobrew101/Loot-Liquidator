# Original Enchantrix prospect: normalized source-quantity audit (2026-11-15 21:00Z)

**Manager task:** T0042, T0022, T0044. **Type:** independently checked historical original-source quantities, not current-build Retail cast evidence or addon changes. **Research head before this audit:** `0822e8d94c25c60cf0df3fe9d9da482eecbc20d6`. Source evidence: [48 unchanged worker transcriptions](../../evidence/legacy/2026-11-15T2055-original-prospect-event-logs.jsonl); `32` prospect/material rows; `16` disenchant material-positive rows, the latter having **no completed-operation denominators**.

## Original source and units

- [ozzieem original SavedVariables](https://github.com/ozzieem/WoW_3.3.5_Addons/blob/0337b2b7be836229254771a9e573059dbf5e51b4/WTF/Account/OZZIEEM/SavedVariables/Enchantrix.lua), and [riku6 original SavedVariables](https://github.com/Daniel-D-Salas/wowInterface/blob/bc54cd8ea7f83e21f84d146975259c18a653c944/WTF/Account/RIKU6/SavedVariables/Enchantrix.lua) were read at immutable Git commit IDs. The **ProspectedLocal** arrays at the source files show the actual ore keyed `total` values and all 32 listed per-material cumulative units. The two accounts must remain separately identified; different archives do not prove independent players or Retail build equivalence.
- [Enchantrix 2008 storage implementation](https://github.com/TrinityCore/wow_335a_addons/blob/4c551c5cdb8937ddc8f7c87d936549b3e7dc0b7a/Enchantrix/Enchantrix/EnxStorage.lua) implements `saveProspect` as **one `ProspectedLocal[id].total += 1` per detected callback**, and **`ProspectedLocal[id][reagentID] += quantity`** per material. This is an audited format contract from an archived version, not proof of exact identical runtime version/complete detection in every capture. A `total` is **not** 5 ore consumed, and reagent units are **not** hits/occurrence probabilities.
- `inputsPerCast=5` is a nominal mechanic. Actual net ore input, Resourcefulness, client patch, build, profession skill, spec and completion/zero-outcome receipts are absent. **ozzieem's repository path explicitly indicates 3.3.5 addons**; riku6's historical captured game flavor/build remains unresolved. Neither is verified current Retail data.

## Four original operation groups — source-reported listed output units

| Original saved-variable contributor | Ore | Recorded prospect callbacks | Output rows | Listed material units | Sum of listed units per callback |
|---|---|---:|---:|---:|---:|
| ozzieem | Cobalt Ore (36909) | 40 | 7 | 57 | 1.425000 |
| riku6 | Cobalt Ore (36909) | 29 | 7 | 41 | 1.413793 |
| riku6 | Fel Iron Ore (23424) | 48 | 8 | 55 | 1.145833 |
| riku6 | Adamantite Ore (23425) | 20 | 10 | 44 | 2.200000 |

The two separately sourced Cobalt Ore rows total **69 recorder callbacks and 98 listed material units** (98/69 = **1.420290** listed units per callback), but they are *not* one verified homogeneous/independent study. No absent output ID was filled with zero. The four source groups together have **137 callbacks and 197 listed output units**; mixing ores into one valuation rate would be invalid.

## Per-material quantity-only fields normalized from original arrays

Each quotient below is **observed summed units / detected callbacks** within that contributor/ore record. This is a candidate historical unconditional average *of the listed output units* if every successful callback was recorded consistently; it is **not** `P(hit)` or a conditional stack yield. Source absent outputs remain unknown, not verified zero.

| Source | Input | Output ID | Cumulative units | Detected operations | Listed units/operation |
|---|---:|---:|---:|---:|---:|
| ozzieem | 36909 | 36923 | 6 | 40 | 0.150000 |
| ozzieem | 36909 | 36920 | 14 | 40 | 0.350000 |
| ozzieem | 36909 | 36929 | 13 | 40 | 0.325000 |
| ozzieem | 36909 | 36917 | 10 | 40 | 0.250000 |
| ozzieem | 36909 | 36926 | 10 | 40 | 0.250000 |
| ozzieem | 36909 | 36918 | 2 | 40 | 0.050000 |
| ozzieem | 36909 | 36932 | 2 | 40 | 0.050000 |
| riku6 | 36909 | 36917 | 7 | 29 | 0.241379 |
| riku6 | 36909 | 36926 | 2 | 29 | 0.068966 |
| riku6 | 36909 | 36923 | 11 | 29 | 0.379310 |
| riku6 | 36909 | 36932 | 7 | 29 | 0.241379 |
| riku6 | 36909 | 36927 | 1 | 29 | 0.034483 |
| riku6 | 36909 | 36929 | 9 | 29 | 0.310345 |
| riku6 | 36909 | 36920 | 4 | 29 | 0.137931 |
| riku6 | 23424 | 23438 | 1 | 48 | 0.020833 |
| riku6 | 23424 | 23112 | 10 | 48 | 0.208333 |
| riku6 | 23424 | 23079 | 6 | 48 | 0.125000 |
| riku6 | 23424 | 23117 | 8 | 48 | 0.166667 |
| riku6 | 23424 | 23440 | 2 | 48 | 0.041667 |
| riku6 | 23424 | 21929 | 5 | 48 | 0.104167 |
| riku6 | 23424 | 23077 | 13 | 48 | 0.270833 |
| riku6 | 23424 | 23107 | 10 | 48 | 0.208333 |
| riku6 | 23425 | 23441 | 1 | 20 | 0.050000 |
| riku6 | 23425 | 23112 | 4 | 20 | 0.200000 |
| riku6 | 23425 | 23439 | 1 | 20 | 0.050000 |
| riku6 | 23425 | 23117 | 2 | 20 | 0.100000 |
| riku6 | 23425 | 23079 | 2 | 20 | 0.100000 |
| riku6 | 23425 | 23107 | 4 | 20 | 0.200000 |
| riku6 | 23425 | 21929 | 3 | 20 | 0.150000 |
| riku6 | 23425 | 24243 | 20 | 20 | 1.000000 |
| riku6 | 23425 | 23077 | 5 | 20 | 0.250000 |
| riku6 | 23425 | 23437 | 2 | 20 | 0.100000 |

## Numerical/identity implications and disposition

1. **Adamantite Powder 24243:** riku6 records **20 powder units over 20 prospect callbacks**, giving **1.000000 listed units per callback**. It does **not** establish 100% occurrence probability, one powder on every operation, a 1–1 range or a zero-inclusive histogram.
2. **Cobalt cross-source comparability:** ozzieem (40 callbacks, 57 listed units) and riku6 (29, 41) both have complete *listed material/unit sums*, not per-material hit counts or all-event receipt logs. Their similar listed total/unit means (1.425000 vs 1.413793) do not establish matching patch, mechanics or independence. ozzieem uniquely lists Scarlet Ruby 36918; riku6 uniquely lists Twilight Opal 36927; this is not evidence of a zero rate for the absent material in either source.
3. **Disenchant source rows:** 16 additional `EnchantedLocal` original material-positive entries preserve hit counts and positive units but have `casts=null`. Exact-item and group aggregation may overlap; no per-operation gold EV, probability or no-result frequency can be derived.
4. **Retail admission:** Owner policy permits all *usable Retail* sources, including historical references, with provenance and uncertainty. This audit does not prove a current Retail recipe/item/result mapping or an in-game tooltip valuation. Keep these source-context records available for field-level review; do not silently overwrite working reference, research, personal or legacy fields in the owner-owned three-pass integration branch. A reviewer can price a source-supported expected quantity once identity/applicability is established, while leaving chance/range null.
5. **No synthetic pricing, compiler, Lua addon, live-client or character-eligibility test** was performed. No new verified current Retail gold decisions are claimed.

## Checks executed

**292/292 in-memory JavaScript checks passed, 0 failed** against the **two pinned original SavedVariables** and the committed worker JSONL: every one of the 32 prospect rows was compared with the original input ore `total` and exact output cumulative unit count, checked for same study/contributor namespace, nominal batch size and explicit null hit/histogram/build fields; verified four source groups; checked 16 disenchant rows retain null completed casts and positive-only quantities. Source storage routine reviewed directly. No Python compiler or Lua test executed.

## Next concrete gap

For T0042/T0022/T0044, secure an original version/build-tagged recorder or player operation ledger for **Cobalt Ore 36909** and **Fel Iron Ore 23424** with per-operation output IDs, stack quantities (including zeros), item rank, exact input consumption/refunds and skill/spec. Compare to these immutable source arrays and historical context before any Retail fallback admission or actual offline synthetic-price tooltip check. **Do not seek redundant copies of these two already verified SavedVariables.**
