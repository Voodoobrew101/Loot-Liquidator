# Eoghals Enchantrix local observations — independent source-to-v3 verification (2026-11-20)

## Scientific scope and source provenance
- Native source: [eoghals_log.lua](https://github.com/alex-berliner/wow_classic_de_table/blob/5918ca3e44f6e4bba9071731ab28be3189498001/dbfiles/eoghals_log.lua), pinned Git blob `f1ad158e7fda46178406a5fa4df2a03e14820cea`. Verified name lookup: [item_names.csv](https://github.com/alex-berliner/wow_classic_de_table/blob/5918ca3e44f6e4bba9071731ab28be3189498001/item_names.csv), blob `2d87410f7b0153fc59eef833f0f14542701ee66d`.
- Worker transcription: `research/v3/evidence/legacy/2026-11-20T0846-eoghals-source-native-item-material.jsonl`, blob `691e4125f83320d6e9db67c3564454e1e2f66d58`. Preserve this original worker-owned file; no corrections required by this source-to-row check.
- The source's `EnchantedLocal` table maps keys `itemID:enchantID:suffixID` to output tuples `outputItemID:positiveSightings:materialUnits:0`. The trailing zero is **not** an observed failed disenchanted item. `EnchantedItemTypes` is a grouped view, not independent casts; the historical pooled CSV must not supply a second sample.

## Independent cross-check performed
Directly parsed the pinned original `EnchantedLocal` section and all 821 GitHub worker JSONL rows in one comparison, and independently compared item names to the pinned CSV:
- **792 distinct local variant keys**, **821 output tuples**, **821 worker material rows**, **583 distinct input item IDs**, **16 output item IDs**.
- Source and transcription both total **1,092 positive material sightings** and **2,128 material units**.
- All 821 original `variant|outputID|positiveSightings|units|trailingZero` tuples matched exactly once to worker material rows; entire per-variant source quotes matched; all 821 stated input item IDs and names matched the pinned item-name CSV; **zero unmatched, extra, duplicate, or name-mismatched output tuples**.
- Every worker `casts` and `inputsPerCast` remains `null`. Positive output sightings are not the complete finished-disentchant denominator, zero outcomes, joint 0..N histogram or independent cohort count. Neither 821 material rows nor 792 variants represent 821 or 792 completed processing operations.

## Baseline admission decision and scope
**Preserve as exact-ID, positive-only historical source evidence; hold empirical occurrence probabilities and per-operation expected quantities.** Source game client build/patch, gear quality/item level at processing, skill/specialization, all-operation denominator and current Retail applicability are unknown. These counts cannot be substituted for contemporary Retail disenchants, used to infer zeros, or priced as a validated new gold action. Retain names/IDs and source provenance for future review.

Static code-path inspection only: current `research/v3/tools/build_estimates.py` `row_use` requires a completed-cast denominator (or qualifying processed-input basis) to use `castsWithDrop` as occurrence or `totalQuantity` as expected quantity. With both `casts` and `inputsProcessed` absent, these original positive-only rows have no observed rate denominator; current-main `tools/research_build_review.py` preserves unresolved scope/fields for rows without compiled support. **No exact-SHA build review, compiled ItemDB, valuation engine, Lua or live-WoW test was executed for this memo**, so no specific generated disposition is asserted.

## Backlog triage
- **Verified original raw evidence:** 821 native source tuples and identity/name links above.
- **Held for baseline rates:** complete original finished-operation ledger (including zeros), source-client build, character/gear applicability and ideally per-cast output stacks.
- **Duplicate, do not reimport:** grouped EnchantedItemTypes and derived CSV copies of the same original counters.
- **Next high-impact independent data:** task T0047 Warmaul Legplates 24995 Retail eligibility/full Looter operation/quantity history and T0042/T0022 Cobalt 36909 / Fel Iron 23424 original completed-prospect + 0..N events; no duplicate eoghals studies requested.
- **Owner policy:** all research stays on `implementation/five-agent-completion`; build-time admission in main may consume these rows when an exact revision is pinned, but runtime/schema work is separate. No routine PR or generated DB commit.
