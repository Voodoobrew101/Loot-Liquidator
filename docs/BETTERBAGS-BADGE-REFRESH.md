# BetterBags D badge briefly disappears after each recorded cast

The owner reports this on PR 48: Loot Liquidator's D disappears and returns on
an unchanged cloak, while other addons' badges stay visible. A read-only game
window screenshot and the owner's close-up identify the affected badge. The
available screen controls provide point-in-time screenshots, not live video;
the transient blink itself was reported by the owner, then reproduced in code.

Recording a cast calls Invalidate, which requests a refresh of displayed badges.
The original BetterBags assignment fingerprints the hyperlink, GUID, bag/slot,
stack count and binding fields from its item data. The forced refresh rebuilt
those fields from the previous decision's context, which omits the GUID and can
contain derived native binding flags. The fingerprint therefore changed for the
same physical item, causing ClearButton to hide its D until the timer repainted
it. A subsequent host redraw could change the fingerprint back and hide it again.

Retain the latest BetterBags source data on the button and use that data for
forced refreshes. An unchanged item keeps its current badge until its new
decision is ready. Real GUID, hyperlink, count or binding changes still clear
the previous badge immediately. Recheck queued identities before painting in
case BetterBags mutates a pooled data table while the job is waiting. Free/clear
events cancel pending work and release retained data.

The deterministic regression exercises the real Core Invalidate and BetterBags
hook path, a native-derived Warbound flag and slow deferred evaluations. It
fails on the original code because the unchanged D becomes hidden. The repair
passes 45 assertions for repeated refreshes and host redraws, changed decisions,
replacement GUIDs, counts, free slots, in-place identity mutation and recovery.
Other addons' badges are untouched. Collection records, coverage rules, rates
and refresh scheduling/budgets are unchanged. This is a reproduced visual repair;
it does not establish that this path caused the earlier live FPS drops. The
updated PR 49 code still requires installation for a live-client check.
