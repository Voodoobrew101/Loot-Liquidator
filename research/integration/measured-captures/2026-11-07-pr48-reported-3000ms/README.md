# Owner-reported PR 48 / 3000 ms macro capture

The original single-copy export is preserved byte-for-byte. Its SHA256 and the
31 new operation IDs are recorded in intake-review.json. Of 514 retained casts,
483 repeat the previous export and are not new observations.

The new batch contains 31 complete Disenchant operations: 30 R1 Radiant Shards
(243602), one R2 shard (243603), from Evercore Shade (244752). All use measured
Enchanting skill 64, bonus skill 0 and no specialization. This batch has no
coverage gaps in this export. Earlier recipe gaps remain intact. Captures span
2.682–3.037 seconds; the macro interval is the owner's reported 3000 ms setting,
not inferred from recorder duration.

The owner reports PR 48 and no observed errors before a planned UI reload.
The export has no addon commit or recorder revision, so build identity and FPS
recovery are not independently verified. Recording on/off had both appeared
smooth after slowing the macro. This does not isolate Loot Liquidator as the
cause of the earlier slowdown or establish an interval guarantee.

staged-baselines.json is the strict validator's research output. These exact
profiles are retained for comparison; this intake does not promote numeric
mechanics or update shipped rates. Older incomplete cohorts remain excluded.
