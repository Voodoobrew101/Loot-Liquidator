# November 7 measured capture intake

All 13 native export pages are preserved byte-for-byte, with SHA256 hashes in
intake-review.json. The strict export validator accepts all 301 distinct records.
Deduplication against prior uploads identifies 254 new records: 199 Recycling
and 55 Disenchant. The Recycling total includes the previously uploaded single
live cast; it is 200, not 201.

The 200 complete Recycling captures consumed 1,000 R1 Powder Pigment (245807)
and reported 421 R1 Evercores (243581), at recorded skill 21–35, bonus skill 0,
and specialization none. The descriptive mean is 2.105 Evercores per cast.
Skill changed during collection; this is not a constant-skill experiment or a
verified no-skill baseline.

The study was later censored by a different Craft operation (recipe 1229866,
Inputs have not settled). Another study has unknown-reagent-allocation Craft
diagnostics. The existing validator rejects every cohort because of study-wide
coverage flags. Original flags are preserved. No numerical baseline or mechanic
is promoted. validated-baseline-review.json records the exclusions. Reviewing
method-specific coverage is a separate implementation decision; this intake
does not silently erase the coverage gaps.

For further controlled Recycling collection, use Start new batch before the
session and export it before other crafting. Existing results should be kept.
