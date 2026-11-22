# Frozen research for tests

A fixed copy of the research snapshot (research commit `4df9ae8`, Nov 1 2026) and the
`ItemDBRuntime.lua` compiled from it.

Tests that check exact numbers or pick a real item as an example read these files, so the
live research in `database/research/v3-snapshot/` can be refreshed automatically
(the explicit build pipeline) without breaking them. Checks that the shipped
files are current still use the live snapshot.

Never edit these files by hand. Replace them only if a code change makes the frozen data
unreadable, and record why in the commit message.
