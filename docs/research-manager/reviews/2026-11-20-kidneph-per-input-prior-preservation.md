# Reviewed Kidneph milling means

The main build now retains the eighteen Kidneph reference rows as six complete
three-pigment vectors, one per herb. Each expected quantity is the reported
pigment total divided by 1,000 consumed herbs. The stored input count of one is
a normalization unit, not a claim about a physical milling operation.

| Herb item ID | 153635 per herb | 153636 per herb | 153669 per herb |
| --- | ---: | ---: | ---: |
| 152505 | 0.814 | 0.303 | 0.136 |
| 152506 | 0.808 | 0.279 | 0.091 |
| 152507 | 0.832 | 0.313 | 0.150 |
| 152508 | 0.814 | 0.332 | 0.128 |
| 152509 | 0.799 | 0.311 | 0.115 |
| 152511 | 0.833 | 0.268 | 0.118 |

The historical archive's batch of twenty remains provenance only. Actual casts,
occurrences, probabilities, ranges, quality ranks, recipe identity and source
profession profile remain unknown. Neither 1,000 / 20 nor 1,000 / 5 becomes a
sample count. The archived confidence of 68 is retained as provenance; active
reference support is capped at 20, and modeled applicability and displayed
value confidence are zero. The existing two Mycobloom priors retain their
existing support of 20 and zero profile confidence.

Admission requires the exact eighteen canonical target-row hashes, source path,
identities, totals, units and actual immutable archive bytes. The generated
file's historical fingerprint is review provenance; unrelated appended or
changed rows do not exclude unchanged reviewed rows. The current physical
snapshot fingerprint is recorded separately and each loaded target row must
match its physical counterpart. Three source rows are admitted atomically per
herb, with distinct source IDs retained in build review and compiled provenance.

The reviewed generated file is
`research/v3/evidence/imported/legacy-milling-cohorts.jsonl`, SHA-256
`d6b5827613a092938f4d32978f8dc5cd3933d981f39ed9d0a28d6db2f4f38d74`.
The immutable original archive is
`research/evidence/observations/2026-10-28-legacy-milling-batch01.jsonl`, SHA-256
`209db16ca170deca50923e98db2b6e6820edd82b8150df20eb71518d663840d6`.
The prepared snapshot is research commit
`d86de9d8792fd5c498346c4ad3f5f8ae20217bc4`.

The resolver rescales these means to requested input units, preserves source
preferences and personal-only mode, and does not let one-input normalization
gain a false exact-operation preference over measured cohorts. Confidence caps
apply only to accepted reviewed-prior quantity contributions; other outputs and
sources retain their own confidence. The informational tooltip is reachable
with confidence zero and normalized input units, while the operation remains
unavailable and cannot win a conversion recommendation. Partial valuation,
conflict and missing-data warnings remain visible.

Tests cover actual prepared vectors, numerical quotes and tooltip rendering,
stronger measured cohorts, source isolation, no source mutation, stale identity
and archive rejection, grouped build-review provenance, and unchanged Mycobloom
behavior. Probability-only TBC guide references do not acquire quantity or gold
estimates through this bridge.

The compatible Star Moss, Akunda's Bite and Sea Stalk mass-milling checks retain
their original Jiyao vectors separately. With the Kidneph prior enabled, each
Ultramarine result accepts exactly one
`published:wowhead-kidneph-<herb>-1000herbs` source and one
`historical:bfa:mass-mill:<herb>:153635:<recipe>:jiyao` source. Existing v3 and
compiled-reference aliases of Jiyao do not add a third contribution. They share
the Wowhead pigment page but identify different authored cohorts. The actual
snapshot contains no counted alias of the Kidneph archive; all eighteen exact
rows remain references. Removing the new priors restores the old asserted
Jiyao endpoints; enabling them produces a compatible blend between those
endpoints and the independent per-input prior.
