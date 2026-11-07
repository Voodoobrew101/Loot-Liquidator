# Recorder work during repeated casts

The owner reported poor FPS and frozen bag icons while using a 1250 ms macro,
then smooth behavior with recording both enabled and disabled after changing
the interval to 3000 ms. BetterBags/ElvUI execution-time warnings were also
reported. This does not establish which addon caused the slowdown. No addon
was disabled, process closed or SavedVariables reset for this change.

Two avoidable costs were reproduced against the preserved 483-record,
73-context export:

- Appending a cast copied and JSON-serialized existing profession contexts
  until it found an identity match. An in-memory identity index now builds once
  for each immutable context table. New skill/input/equipment profiles still
  get distinct contexts; resets and replacement ledgers get independent indexes.
- Exact-item valuation queried live profession equipment, traits and operation
  context before checking whether coverage permitted a baseline. Coverage now
  rejects blocked cohorts first. Usable cohorts still read and match the live
  profile on each lookup; no profession state is cached by this change.

An offline Lua 5.1 replay on this machine measured median cast appends of about
5.9 ms before and 0.22 ms after, over 50 appends. The first index construction
took about 12.5 ms. Thirty repeated blocked-item lookups fell from about
4.6 ms to 0.49 ms each, with live-context reads dropping from one to zero.
These timings use stubbed game APIs and exclude real UI/API costs. They measure
the local code changes, not WoW FPS or proof of the original slowdown's cause.

`tests/test_recorder_lookup.lua` replays the actual 483-, 514- and 575-record exports.
It checks zero live reads for rejected cohorts, the clean 31-cast batch's exact
30/31 R1 and 1/31 R2 means, the combined 92-cast/88 R1/four R2 clean batches,
rejection after live skill changes, stable existing
context IDs, distinct changed profiles, snapshot isolation, duplicate rejection
and a fresh index after reset with the old ledger preserved in its backup.
The full `tests/run.sh` suite passes under Lua 5.1 with a fresh byte-identical
ItemDB compilation. This change leaves shipped numeric rates unchanged.
