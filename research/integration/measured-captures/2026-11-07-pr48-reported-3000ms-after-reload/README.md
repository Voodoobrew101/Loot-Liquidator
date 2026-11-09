# Owner-reported PR 48 / 3000 ms follow-up after reload

The original export is preserved byte-for-byte with its SHA256 and new operation
identities in intake-review.json. It retains 575 records without dropping any;
514 repeat the prior upload, leaving 61 new Disenchant operations. The new batch
has no recorded coverage gaps or diagnostics. It produces 58 R1 Radiant Shards
and three R2 shards from Evercore Shade, at measured Enchanting skill 64, bonus
skill 0 and no specialization. Together with the preceding clean 31-cast batch,
there are 92 clean observations producing 88 R1 and four R2 shards.

The owner reports no interrupted casts or UI errors, minimal frame drop while
remaining above approximately 70 FPS, and about the same throughput as at
1250 ms. Bags did not lock up, but the bag window was visible only at the last
cast. These are reported observations, not measured frame timings or proof that
bag refreshes cannot cause problems. Actual capture durations span 2.651–3.071
seconds, consistent with the shorter macro interval retrying before completion.
The export does not identify its addon commit or recorder revision; PR 48 and
3000 ms are owner-reported conditions.

The strict validator's staged-baselines.json retains exact-context empirical
baselines for research. Earlier incomplete studies remain excluded. This intake
does not change shipped rates or supply a guessed skill/specialization rule.
