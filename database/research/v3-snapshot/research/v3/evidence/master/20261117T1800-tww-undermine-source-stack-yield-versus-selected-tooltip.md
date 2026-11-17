# Two TWW Undermine gear Looter reference profiles: observed stack yield versus frozen selected tooltip

**Manager research-only, source-to-tooltip reconciliation — 2026-11-17T18:03:15.669Z.** Original worker evidence and its underlying two Wowhead item-side cumulative Looter groups remain untouched. No new player cohort, rerun of Lua, addon implementation, or live WoW proof.

## Newly established selected-value mismatch

The owner branch's **already stored actual-engine offline** [runtime probe](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/usable-data-tooltips/docs/usable-data-audit/runtime-probes.jsonl) (blob `534b970d475d75e54b1d5bc4777e807384814372`) contains `Disenchant:232739:x1`, eligibility **"Not tested; source audit only"** and **only one** selected material: **219947, Storm Dust quality 2**. It displays P(hit) **0.3694915254**, E **0.3694915254 units per input**, and **36.94915 copper** at a synthetic 100c net output price, consistent with implicit yield **one** when this output occurs.

The War Within worker's independently read [new source transcription](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/five-agent-completion/research/v3/evidence/war-within/2026-11-17T1721-two-unique-live-undermine-de-histograms.jsonl) (blob `0ed51591684e50bb4d4b833868543a6ebba0bd8b`) is a **same-original-source enriched cumulative table, not an independent 295-cast experiment**. Its Sash of Lost Inspiration item-side Looter record reports **109 of 295** material hits for the *same* material **219947**, with positive stack histogram **1×26, 2×35, 3×48**. That gives **240 reported material units / 295 reported disenchants = 0.8135593220 unconditional units**, not 0.3694915254. The hit probability **109/295** matches the frozen selection *exactly*, isolating the newly available **per-hit stack quantity** as the reason for the difference; this is not a change to the chance denominator. The 219947-only hypothetical new value is **81.35593c** at the same synthetic 100c assumption, **+44.40678c** per reported input versus the old saved selection, *if the new cumulative source context is accepted*. It is not a live bid/offer or an eligible-character recommendation.

The same latest worker record also contains four **other ranked** source-listed outputs (219946, 219948, 219949, 219950) not selected by the saved Sash probe. These cannot be treated as missing in all client contexts until rank, gear, patch, source preferences, market prices, eligibility and any stronger candidate precedence are evaluated. The equally newly documented Chainmail 232755 is **not** a member of the saved 367-profile census; no current-runtime claim is made about it.

## Two source cohorts — bounded arithmetic, not scientific independence

| Source input | Reported DE attempts (cumulative) | Sum of per-material hits | Total source units, five ranked outputs | Sum E units / attempt | Gross 100c/output, illustrative |
|---|---:|---:|---:|---:|---:|
| 232739 (Sash of Lost Inspiration) | 295 | 295 | 582 | 1.972881 | 197.2881c |
| 232755 (Chainmail of Lost Inspiration) | 65 | 65 | 129 | 1.984615 | 198.4615c |

The five per-material hit totals exactly equal each cohort's reported denominator, but this **does not prove one mutually exclusive output per operation** without original event logs; simultaneous material hits and no-material attempts could cancel in an aggregate sum. Each output's per-material zero bin can be calculated as reported attempts minus that material's hits, but that does **not** establish all-material-zero disenchants. Histogram totals and count-weighted quantities agree on all **10** worker rows. Every original player patch, skill/spec, bonus variant, overlap with PTR/outcome-side exports, and current-Retail disenchant eligibility remains unknown; both are **reference-only**. The distinct outputs are not to be double-priced if future same-source higher-quality alternatives overlap.

## Disposition and next accepted work

- **Usable but not imported/selected in frozen probe:** reference-backed stack-weighted expected quantity for Sash 219947 and other source-listed ranked cooutputs; do not equate E and P or silently discard stacks of 2/3.
- **Eligibility/context unresolved:** no proof same patch, item version, Enchanting conditions or non-overlap with cumulative other sources; no automatic current-Retail recommendation or live confidence promotion.
- **Price issue separate:** real item-specific AH prices and costs are not part of this synthetic equal-100c fixture. Re-run actual source-preference, candidate competition, rank, costs/fees and tooltip selection tests in the owner-controlled three-pass branch after an authorized source-context review; do not edit that branch here.
- **Research next:** obtain individual dated itemLink/version+profession source events for 232739/232755; compare original URL tables and cumulative overlap before any independent-study counting; keep worker T0048/T0040 ownership. Continue higher-priority Midnight T0005/T0039 and T0045 true-operation/identity work in parallel.

**Checks actually executed:** **85/85 bounded in-process JavaScript assertions** on the actual worker JSONL and owner's saved actual-engine JSONL, including source-kind/units, 10 histogram totals, 10 hit totals, 10 weighted material totals, 10 zero complements, and exact Sash frozen chance/E reconciliation. No rebuild, no compiler execution, no native Lua, no new engine/render run, no live character tests. Source records, owner integration branch, snapshot `4df9ae8`, other PRs and workers unchanged.
