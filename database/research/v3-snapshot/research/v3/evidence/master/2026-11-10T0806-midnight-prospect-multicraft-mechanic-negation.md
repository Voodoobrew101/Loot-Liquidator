# Midnight Prospecting Multicraft — direct negative mechanic check (2026-11-10)

## Research objective
Task **T0033** (queued): resolve the contradiction in `research/v3/mechanics.md` M11, which currently says "Multicraft applies to prospecting" with status **likely**, based on an imprecise early Jewelcrafting talent build and an owner recollection. This is a **research-only mechanic/valuation safety correction**, not a processing-output study, new measured yield, or actual-client test.

## Original, scoped sources inspected
1. **WoW-Professions**, "Midnight Jewelcrafting Specialization Guide & Best Builds": https://www.wow-professions.com/midnight/jewelcrafting-specialization-guide-and-builds (live guide inspected 2026-11-10). Under **Best Profession Gear and Stats**, the author explicitly distinguishes gem/reagent crafting from **Prospecting and Crushing** and states those two processes **cannot Multicraft**; use Resourcefulness gear instead. This is about the Midnight profession, not Classic or earlier expansions. Its `Thoughtful Throughput` table lists broad crafting bonuses, but that list does **not** establish applicability to individual recipes.
2. **Icy Veins**, "Stats Guide for Jewelcrafting in Midnight": https://www.icy-veins.com/wow/professions-jewelcrafting-stats (page says **Last Updated May 19, 2026**; accessed 2026-11-10). The author specifically says **Prospecting and Crushing cannot Multicraft** and recommends Resourcefulness for those activities. The page distinguishes them from Multicraft-eligible gem/reagent **crafting**.
3. **Player corroboration, not controlled testing:** r/woweconomy Oct 3, 2026 discussion https://www.reddit.com/r/woweconomy/comments/1wwd0w0/should_i_use_my_1_time_swap_for_jc_to_go_from_gem/ : multiple commenters explicitly corrected "multicraft tool" to **Resourcefulness**, and a commenter states that Multicraft does not affect prospecting. The post provides no proc log and carries **zero** empirical denominator or numeric multiplier.
4. **Resourcefulness distinction:** https://www.reddit.com/r/woweconomy/comments/1rrn6of/resourcefulness_in_crushingprospecting/ (Mar 12, 2026): player reports ore saving on Midnight prospecting despite the crafting panel's temporary non-display. Anecdotal and not sufficient to infer an input-saving coefficient or whether UI behavior remained unchanged.

## Field-level disposition
| Field | Finding | Allowed interpretation |
| --- | --- | --- |
| `M11: Prospecting can Multicraft` | **Contradicted** by two explicit independent Midnight profession guide statements, plus user corroboration | Correct the registry's positive "likely" claim to "Midnight Prospecting **does not Multicraft**" with **guide-corroborated** source status. No output multiplier; keep Multicraft off. |
| `Crushing can Multicraft` | **Contradicted** by the same two guides | Record only as a scoped mechanic; Crushing is not automatically part of the existing four-method valuation adapter. |
| `M10: Prospecting Resourcefulness` | Two guides recommend Resourcefulness; firsthand anecdote corroborates ore refunds | **Input savings only**, never automatic output boost; exact refund chance, returned quantity and skill-specific function remain unknown. |
| Profession talents | A talent tree's general "Multicraft" boost describes other eligible JC recipes | Do not promote the generic tree description into prospecting-specific eligibility. |
| P(hit), conditional yield, mean, range, recipe rank | No per-operation logs, histograms, calibration or cast counts in these sources | **Unknown**, unchanged. No price or valuation/tooltip fixture executed. |

**Impact:** M11 as currently written could lead a future estimator or tooltip to apply an invented output multiplier to Prospecting. The owner already requires **unverified Multicraft off**; this note supplies explicit negative evidence for that safeguard. No claim that an active addon calculation was defective. The issue is not solved by a numeric sample, and source guide wording is not direct WoW-client QA.

## Next step
Manager-owned mechanics registry should replace M11's positive "likely" claim with the two negative guide sources and the constrained scope. Preserve the T0033 worker assignment until worker/report reconciliation or manager-owned queue checkpoint; no new worker schedule is needed. For **T0005/T0039/T0045**, continue seeking genuinely new post-hotfix, quality-separated per-operation 0/1/2+ output logs and actual ore/herb refund events. Never infer a probability, output quantity or resource-saving coefficient from these guides.

**Operations performed:** direct independent web-page reads of both guides and both Reddit threads; checked the current registry and queue; no formula test, estimate recompute, Lua tests, live client, PR, merge, release or source mutation.
