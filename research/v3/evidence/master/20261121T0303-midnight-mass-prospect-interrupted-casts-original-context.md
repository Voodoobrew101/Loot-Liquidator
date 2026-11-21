# Original-source context: interrupted Midnight mass prospecting is not a completed-cast ledger

Verified source-context review: 2026-11-21 03:03 UTC. Owner's separate 725-source catalogue (cutoff `0cd0bad8867e7a8d909b4ecae74f6136a3e23d42`) is assigned to the active Codex reviewer team; the two linked operational reports below are *not* in that manifest, and this note does not recatalogue the assigned backlog.

## Primary firsthand report (Midnight; historical, not November live QA)
- Reddit r/woweconomy, 2026-03-24, "Mass prospecting issues": https://www.reddit.com/r/woweconomy/comments/1s20lq4/mass_prospecting_issues/
- Original reporter: Refulgent Copper mass prospecting frequently stops with "requires 5 refulgent copper" even when other ore is present; initial quantities of many stacks do not imply the planned number of prospect operations completed.
- A separate commenter describes the sequence: one selected-stack craft, then subsequent consumption from the earliest eligible bag stack. A stray stack with fewer than five ore can interrupt the job; a 1,000-ore selection corresponds to **200 planned five-ore operations**, not 200 verified successful operations. This is **firsthand user troubleshooting**, not independently reproduced system behavior, and its November 2026 persistence is unknown.
- Item scope: named Refulgent Copper Ore only; quality-specific item ID, selected quality, skill, build, successful casts and output rolls not documented. A direct connection to `237359` versus its other quality alternatives is not source-established.

## Independent earlier corroboration (TWW era, not proof of Midnight build)
- Blizzard bug-forum thread, 2024-09-12/13: https://us.forums.blizzard.com/en/wow/t/jewelcrafting-failed-prospecting/1953095
- Multiple players describe the "requires 5 ore" stop after a single cast when a bag contains 1,000 ore and a second stack of 4, and describe the after-first-cast inventory priority. Also https://us.forums.blizzard.com/en/wow/t/prospecting-bug/1929785 (2024-08-26 through 2024-09-12) reports analogous Aqirite interruptions.
- Similar TWW original-operation limitations were already identified by the TWW worker (e.g. 2025 Ironclaw Create All interrupted after two operations). This is source-context corroboration, not a separate study or reason to duplicate that worker's review.

## Scientific/implementation disposition
- **Classification:** original qualitative workflow/denominator-confounder evidence; no new measured yield, cast count, hit probability, conditional output amount, output rank or supported gold decision. Do not import as a numeric baseline or infer a bug frequency.
- In T0003/T0039, separate **requested operations** (nominal ore divided by five), **successful server-completed operations**, **gross ore consumed**, **net ore consumed after Resourcefulness refunds**, and **material output totals**. A queued "Craft All" count and available inventory are insufficient to certify measured N.
- Do **not** reject an otherwise legitimate source-reported per-input or per-operation average merely because completed casts were not recorded. Keep units and uncertainty explicit.
- Source follow-up: seek a *new independent* original processing ledger/export containing timestamps/confirmed completed casts, per-cast 0/1/2+ material histograms, item/rank IDs, actual skill/Prospecting Pro unlocks, build, ore stacks/refunds and interruptions. Avoid requesting copies of the assigned 725-source catalogue. No crafting/ore purchases/character experiments.
- No main, addon, generated database, model, automation, PR or schedule changed, and no build/tooltip/live-client test performed in this source review.
