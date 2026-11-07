# Disenchant targeting events and real item casts

The owner's November 7 batch contains 75 complete disenchants and 19 diagnostics
with `Inputs have not settled`. Each diagnostic lasted 1–2 seconds, retained no
input/output bag deltas and no loot slots. The completed casts lasted about
2.2–2.6 seconds and consumed an identified item. The batch uses coverage version
2, introduced by PR 49 commit 953bb1d, and the installed BuildInfo identifies that
same recent build. These are not merely diagnostic leftovers from an old addon.

The existing collector started Disenchant tracking on UNIT_SPELLCAST_SENT. A
successful activation can open an item-targeting cursor before an actual item
cast starts. The collector could then count it as a successful operation and
finalize it as an unresolved consumption gap when the next request arrived.
This is a current reproducible failure path consistent with the 19 signatures.
The old export did not store START/cursor flags, so it cannot prove the exact
event sequence for each historical diagnostic. Those diagnostics remain intact.

Recorder revision 4 starts native Disenchant snapshots at UNIT_SPELLCAST_START.
SENT records a bounded short-lived intent and never finalizes a previous cast.
A corresponding success with a positively active SpellIsTargeting cursor and no
matching actual cast is counted as a cursor activation, not a processed item.
A real START is still captured even if the cursor flag is active. Unknown
successes without start/targeting evidence remain coverage gaps. All accepted
casts still require exact input removal, loot evidence and matching bag output.

New observations and diagnostics identify their recorder revision and addon
commit. Diagnostics also retain whether START was seen and the cursor state.
The export includes its recorder revision and count of targeting activations.
Recording-disabled preferences are honored. On the first real disenchant after
upgrade, a blocked pre-fix active batch rolls over to a new batch; old records
and diagnostics are preserved. New genuine gaps in revision-4 batches remain
blocked normally.

The regression replays all 75 original output receipts interleaved with 19
synthetic cursor activations having the old failure signatures: all 75 records,
70 R1 and 5 R2 shards, and no false coverage gap. It also covers cursor activation
during unsettled genuine loot, actual starts with an active cursor, unknown
missing-start successes and automatic upgrade rollover. This is a reproduction
and repair test, not a retrospective reconstruction of the 19 unknown outcomes.

Blizzard's current SecureTemplates implementation uses SpellIsTargeting to
distinguish the targeting state from ordinary actions:
https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua
