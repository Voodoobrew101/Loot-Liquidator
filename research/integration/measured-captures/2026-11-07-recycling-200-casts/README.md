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
diagnostics. The initial validator rejected every cohort because of study-wide
coverage flags; validated-baseline-review.json preserves that original decision.

The owner subsequently requested recipe-scoped coverage and use of the 200 valid
Recycling casts. coverage-review.json is the explicit, hash-bound review of
exactly those observations. restored-baselines.json contains the 14 admitted
measured contexts. The official compiler now ships these empirical rates, scoped
to their measured skill, bonus, specialization, stats, quality and game build.
No skill transform is inferred. Original raw flags remain unchanged; other
legacy censored observations remain excluded. See
docs/RECIPE-COVERAGE-AND-BUILD-INFO.md for the forward coverage policy.

For further controlled Recycling collection, use Start new batch before the
session and export it before other crafting. Existing results should be kept.
