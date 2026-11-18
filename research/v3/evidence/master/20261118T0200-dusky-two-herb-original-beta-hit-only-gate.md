# Original Dusky Pigment six-event source: historical hit-only field gate (2026-11-18)

## Scope / exact source

Reviewed the new Legacy original [20261118T0153-dusky-briarthorn-swiftthistle-firsthand.jsonl](../legacy/20261118T0153-dusky-briarthorn-swiftthistle-firsthand.jsonl) at blob `4e4ccc27089e79256ff01aa3ad49bca37dcca688` against the original [Wowhead WotLK Dusky Pigment comment by 171157](https://www.wowhead.com/wotlk/item=39334/dusky-pigment), and the separately pinned generated [v3 estimates](../../output/estimates.json), blob `15ae8c5b7f7b2587ceff1dcd3e8b9d13d4351d1e`. This is a **source identity and supported-field audit**, not an addon runtime verification or permission to regenerate the immutable integration snapshot.

The original comment reports four groups of Briarthorn (2450) and two groups of Swiftthistle (2452), every group yielding **2–3 Dusky Pomace**, historically associated with Dusky Pigment (39334). The worker kept the two inputs distinct within one author's original study; five herbs per historical milling group. The two new rows have actual source-reported completed operations and per-material positive events, but no exact per-event quantity histogram, total pigment units, source build/patch, skill/spec, refund ledger or cooutput list.

| Source input | Original-author completed mills | Original-author Dusky-positive mills | Observed stack bounds | **Possible** total across observations (not measured total) |
| --- | ---: | ---: | --- | --- |
| Briarthorn 2450 | 4 | 4 | 2–3 per mill | 8–12 units |
| Swiftthistle 2452 | 2 | 2 | 2–3 per mill | 4–6 units |

**Do not substitute midpoint 2.5 as a measured average, infer the mix of two-versus-three, or extrapolate 4/4 and 2/2 into current Retail drop probabilities.** An output appearing in all six of these historical operations is a source-specific observation only.

## Original beta-era change warning

The same Wowhead comment chain independently describes markedly different **beta** yields: comment by 204361 cites build 8885 at 3–4 units, build 8905 at 2–3, and build 8962 at 2–4. Those are qualitative release/epoch context, **not** additional observed casts, totals or rank changes for the 171157 study. The latter study has no exact dated build; it must remain historical pre-release context. Do not pool with current Retail 12.x or label this source current Retail eligibility. Mirrors of these language/PTR pages are not independent studies.

## Already compiled; new numeric rows are not yet a gold improvement

The **immutable prior** v3 estimate already contains `Mill 2450 -> 39334` with 26 effective historical study casts, one study, P=1.0, E=2.6663 and observed range 2–3, and `Mill 2452 -> 39334` with 20 effective study casts, one study, P=1.0, E=2.6388 and observed range 2–3. These are **preexisting** estimates; their source lineage and epoch must remain separate from the new author's six events, and the new six are not a second copy of the existing 26/20 merely because the same item/stack bounds recur. Their independence from earlier source vectors cannot be fully certified without original cohort lineage review. The six newly transcribed events provide positive-hit denominators but **no new observed average, range extrema beyond 2–3, current-Retail evidence, runtime value or tooltip field.** Do not invent a fresh 2.5-unit average from the new rows or count these as additional current-Retail recommendations.

The existing Verdant Pigment (43103) estimates for both herbs cannot be reassessed from the 171157 comment: no Verdant quantity, occurrence or zero is reported for those six operations.

## Validation, limitations and next step

Read exact two new source rows and full frozen estimate objects; independently verified original comment phrasing and distinct beta build range reports in publicly accessible Wowhead mirrors. Executed **24/24 bounded JavaScript assertions** on row identity, units, exact casts/hits, absent average/histogram/epoch, shared-author studyKey, existing frozen casts/mean/range and no current-runtime evidence. No Python estimate rebuild, provenance-wide dedupe analysis, Lua test, tooltip rendering, CI run initiated by manager, or live WoW client test. The research branch's last prewrite workflow success is not verification of this note.

Keep workers on their assigned current **T0005/T0039** Umbral Tin 237362 event-level item/rank, zeros, per-output 0/1/2+, specialisation and refunds; then **T0045** Tranquility Bloom 236761 true ten-herb events. For this legacy source, an actual 2-vs-3 histogram and original build would improve historical fidelity, but prioritize genuinely new current Retail decision coverage over repeated 2–3 anecdotes. Do not touch the owner integration branch, original evidence, queue or production code.
