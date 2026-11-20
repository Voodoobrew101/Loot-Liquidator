# Disenchanting formula research — November 19, 2026

Dust Deliverer, Shard Supplier, Crystal Collector and Disenchanting Delegate now
feed material and gold calculations through a separate compiled baseline model.
The same forward calculation accepts simulated inputs and verified scanned
profession inputs. Exact researched skill arithmetic and assumed material curves
remain separate internally. Confidence scores express their uncertainty in the
tooltip; profession details show the selected skill and points.

## Implemented skill terms

For invested points `p` and a learned path `L`, the current client data supports:

| Path | Skill contribution |
| --- | --- |
| Delegate | `p + 5L + 5[p>=10] + 10[p>=20] + 20[p>=30]` |
| Dust Deliverer / Shard Supplier | `p + 5L + 5[p>=5] + 5[p>=10] + 5[p>=15] + 10[p>=25] + 20[p>=30]` |
| Crystal Collector | The same child formula, with its `p` term derived from the primary DB2 effect/label join |

These give 70 root skill and 80 matching-child skill at 30 invested points.
Child contributions remain restricted to their equipment rarity. Learned paths
with zero invested points require an explicit `learnedSpecializations` entry;
legacy zero-point signatures are not evidence of learning. Positive invested
points imply learning. The current slider UI does not add a learned-at-zero
selector; its zero default continues to assume no optional learning bonus.

New learning/milestone terms and the new Crystal rule begin at build 70961.
Existing older-build per-point behavior remains intact. Live measured effective
skill is not boosted again. A simulated context is recomputed from its original
base once, rather than compounding previous calculated bonuses.

Crystal's +1 is a sourced provisional inference, not a claim found in its base
tooltip and not an independently measured in-game differential. All four spend
entries use Effect 146, Amount 1, type 25. Crystal's rarity label 5052 also carries
the explicitly described Epic Skill milestones with amounts 5, 10 and 20. This
identifies the shared units and scope. Its confidence is capped at 60.

Primary evidence and independent review:

- [Current Wago ProfessionEffect data](https://wago.tools/db2/ProfessionEffect?build=12.1.5.70961)
- [Trait-to-effect links](https://wago.tools/db2/ProfessionTraitXEffect?build=12.1.5.70961)
- [Resolved live calculator data](https://nether.wowhead.com/data/profession-tree-calc?dv=7&db=1794041972)
- [Reduced source rows, checksums and routing audit](../research/mechanics/2026-11-19-game-data-formulas.json)
- [Resolved Blizzard API evidence and recording audit](../research/mechanics/2026-11-19-observation-formulas.json)
- [Independent addon and DB2 review](../research/mechanics/2026-11-19-addon-formulas.md)

## Missing numerical output terms

The client identifies bonus-material perks at 20 points and further effects at
30, but the checked tables do not publish their probabilities or bonus stack
distributions. They also do not establish `P(output quality | skill, item,
specialization, build)` for disenchanting.

Disenchant spell 13262 uses Effect 99 without a crafting-data pointer or skill
curve. Radiant and Dawn Shatter route through ItemSalvage into server Treasure
distributions; their checked CraftingData rows have zero difficulty and no
quality-family rows. Deterministic milling/prospecting thresholds therefore
cannot be borrowed for either disenchanting or shattering.

The fresh addon audit found no replacement formula in current CraftSim, TSM,
Auctionator, GoldCap, Disenchanty, Disenchanting Advisor or ProfitProphet.
Approximate fixed tables and moving averages without specialization context
cannot establish this relationship.

The old three-green/twenty-epic specialized positive captures cannot supply a
new empirical curve: the existing coverage validator rejects their denominators
for unscoped legacy gaps. The one exact item/variant with both specialized and
unspecialized observations has one cast per setup. No new output coefficient
or experimental reference has been generated from those records.

## Existing and published data only

The owner clarified that estimates must use **existing and published data
only**. This supersedes the earlier proposal to collect new controlled batches.
No new in-game tests, knowledge spending, item destruction or purchases were
performed. Missing evidence remains unknown rather than becoming a request for
new collection.

The fresh published-data search and its source limitations are recorded in
[the November 19 evidence inventory](../research/mechanics/2026-11-19-published-dust-crystal.json).
The statistical assessment is in
[the existing-data review](../research/mechanics/EXISTING-DISENCHANT-DATA-ASSESSMENT-2026-11-19.md).

## Published Dust and Crystal numerical references

Two firsthand comments supply useful numbers, with incomplete experimental
setups. They are published references, not controlled calibrations:

| Reference | Reported number | What remains unknown |
| --- | --- | --- |
| [RaziarEdge on Dust Deliverer](https://www.reddit.com/r/woweconomy/comments/1rke21a/eversinging_dust_rank_2_is_almost_certainly_way/) | Approximately **2.9 Eversinging Dust per disenchant**, pooled across qualities, when fully invested in green disenchanting | Sample count, raw totals, exact root allocation, profession skill, equipment, item variants, quality split, other material outcomes and build |
| [MrNoobyy on Dawn Crystals](https://www.reddit.com/r/woweconomy/comments/1ryolii/swimming_in_dawn_crystals_an_experienced_goblin/) | Approximately **66% chance of a rank-2 crystal**, with 100 Enchanting, all rare equipment and a maxed tree | Sample count, raw outcomes, exact item variants, complete allocation, equipment names, racial bonus, stack sizes and build |

The Dust author also reports up to six Dust, but supplies no stack histogram or
measured minimum. That maximum does not identify a probability distribution.
The pooled mean does not establish observed rank-specific means. The working
model below makes an explicit separate rank-mix assumption. Missing
other-material rows do not establish zero drops.

Crystal's reported chance is not a material-unit mean. Converting it to 0.66
rank-2 units per operation would additionally require verified one-unit stacks
on every rank-2 hit. Assigning the remaining 34% to rank 1 would also require
verified mutually exclusive, exhaustive one-crystal outcomes. Those conditions
are not supplied by the comment. Its equipment description does not explicitly
state a +40 Skill total; the separate rare-shard workbook's 100+40 label cannot
be imported as this author's measured setup.

Those distinctions remain in source metadata. The owner subsequently authorized
working numerical models from the existing evidence, with confidence as the
user-facing uncertainty signal. The assumptions below supply numerical
transitions; they are not new observations, counted samples, confidence
intervals or published game formulas. No historical source is backdated to the
current model build.

## Additional published rare-shard data

[Penguinr2gt's public workbook](https://docs.google.com/spreadsheets/d/1OiEL8gl3v0ccxl-NZjRudOPCO9tcEWryK6ScX4PNnu8/edit)
contains nine raw batches totaling **720 input items**, with 368 rank-1 and 559
rank-2 Radiant Shards. Its linked calculator labels those means **93 Skill
(75+18)**. All ten workbook tabs, including the hidden data tabs, were checked;
no Dust Deliverer or Crystal Collector output cohort table was found.

The workbook's separate **140 Skill (100+40)** expectation vector has no raw
denominator or counts in the checked workbook. The calculator's 1,000-craft
projection is not a measured sample count. Exact input variants, root and
Supplier allocation, race and build are also missing. These are partly scoped
rare-shard references, not a controlled skill comparison and not evidence for
a Dust or Crystal coefficient. They remain separate from the previously
reviewed 1,000-operation max-Delegate/max-Supplier rare-armor reference.

## Compiled baseline and forward calculation

The existing category baselines, evidence normalizers, raw observations and
their sample counts remain unchanged. The build pipeline creates an independent
`modeledDisenchantBaselines` view from those records and the reviewed
`modeledDisenchantRules` contract. Source record IDs, source build when known,
endpoint lineage and the assumed reference profile remain attached to that
derived view. The model's build is 70961, client version 12.1.5; this identifies
the reviewed calculation, not the publication build of historical observations.

Ordinary source cohorts have unknown character setups. Treating their means as
a zero-total-skill reference is an explicit synthetic benchmark assumption.
It does not convert them into measured minimum-skill or zero-point experiments.
The separate baseline view allows future source normalization to be improved
without changing the preserved original observations.

`LL:DisenchantCurveQuantities` supplies the shared forward arithmetic.
`LL:NormalizeDisenchantQuantities` inverts the same pool/share calculation when
the declared source profile identifies an inverse. At a saturated endpoint the
prior is not identifiable; the inverse retains its declared prior only if the
endpoint agrees. The build's unknown-source, zero-skill anchor is an identity
normalization under the stated assumption.

For primary rank means `e1`, `e2`, let `Q0=e1+e2` and `R0=e2/Q0`. Quality progress
is `s=clamp(effectiveSkill/290,0,1)`. The upper anchor assumes 140 native skill
and equipment skill plus 70 Delegate and 80 matching-child skill. Child quantity
progress is `q=0.5[points>=20]+0.5[points>=30]`. These progress choices are working
assumptions; the actual bonus proc rates and stack distributions remain unknown.

| Rarity | Primary quantity endpoint | Rank-2 share endpoint | Confidence armor / weapon |
| --- | --- | --- | --- |
| Uncommon / Dust Deliverer | 2.9 pooled Dust | 0.65 | 10 / 5 |
| Rare / Shard Supplier | 1.289 pooled Shards | `0.660/1.289` | 30 / 15 |
| Epic / Crystal Collector | Preserve the category's existing pooled Crystal mean | 0.66 | 20 / 20 |

For Dust and Shards, `Q=Q0+(Q1-Q0)q`; for Crystals, `Q=Q0`. All use
`R=R0+(R1-R0)s`, then `E[rank1]=Q(1-R)` and `E[rank2]=QR`. This keeps quality
changes within the chosen primary pool and gives native skill, Delegate and the
matching child a route to output quality and gold value. Output prices are
applied after material projection.

Dust's 0.65 endpoint is a deliberately weak prior transferred from
[Nearby-Operation5543's unscoped ratio](https://www.reddit.com/r/woweconomy/comments/1rhtrm6/worried_about_enchanting_concentration/).
Its material family, rarity, ratio denominator and sample size are unknown.
Combining it with the separate 2.9 Dust report is a synthetic modeling choice,
not a newly measured Dust quality distribution. Dust weapons use the armor
reference only because an ordinary weapon reference is absent; the confidence
cap falls to 5. Other material families remain unchanged.

Supplier uses the existing Courtly Wrists full-specialization vector. Its
629/660 shard counts establish pooled units and unit share, not hit probability.
Other material means blend toward that endpoint at the quantity milestones.
An unlisted endpoint material is treated as zero for this modeled transition;
that is not empirical proof of absence. The armor-to-weapon transfer lowers
confidence to 15. The independent Penguin cohort supports a similar pooled
shard quantity, but its undocumented specialization setup prevents treating its
quality differences as a controlled skill curve.

Crystal's 0.66 report is interpreted as a conditional quality mix under an
assumed one-primary-crystal relationship. The existing pooled expectation stays
unchanged for each class. This does not invent a measured rank-1 complement or
fill unreported outcomes to force one crystal per cast. Armor's preserved pool
is 0.965409; weapon's is 0.983607. At the upper quality anchor their modeled
rank-1/rank-2 means are respectively 0.32823906/0.63716994 and
0.33442638/0.64918062.

Crystal's additional-material milestones are modeled separately from its primary
quality mix. Captured DB2 text explicitly unlocks native magical essences at
20 points and increases that chance at 30. The checked data supplies no loot
IDs, probability or stack quantity for that perk. The working identity pool is
Mote of Light (236949), Mote of Primal Energy (236950), Mote of Wild Magic
(236951), and Mote of Pure Void (236952). Those are existing Midnight native
elemental essence identities; the specific connection from the Crystal perk to
all four IDs remains an explicit possibility assumption, rather than a verified
disenchant loot-table join.

The additional-output model transfers the existing full-Supplier bonus-unit
budget of 0.289 to that pool and assumes an equal four-way allocation. Each Mote
therefore has mean 0.07225 at 30 points, half that mean at 20, and zero in the
canonical baseline before the unlock. These are additive expected quantities,
with confidence capped at 5 for identity, transfer and allocation uncertainty.
They neither consume Crystals nor assert a proc probability or conditional
stack size. The inverse removes the same additive expected mean, preserving
forward/inverse consistency. The source details and limitations are recorded
in `database/research/crystal-collector-extra-materials.json`.

## Runtime behavior and validation

The resolver consumes the independent compiled baseline, then applies the
selected scanned or manual profile once. Current snapshots must carry verified
invested-point mappings and learned-node state. Raw trait `currentRank`
signatures are not silently interpreted as invested points. The profession's
skill plus tool/equipment modifier supplies the native anchor; a generic
operation's already boosted skill is not added again. Offline snapshots retain
their own freshness and verification requirements.

The old full-Supplier reference path is bypassed after this projection to avoid
applying the same endpoint twice. A synthetic benchmark is applied after the
profile calculation and also remains idempotent. Evidence source toggles,
zero-weight sources and personal-only mode retain their normal boundaries.
Projected means receive the model confidence cap; no hit probabilities, stack
bounds, histograms or observation counts are manufactured from the new means.
Cached gold values are calculated from the final quantities.

Validation is covered by the specialization schema rejection tests, the
build-time baseline tests, exact skill-formula tests, and
`tests/test_disenchant_baseline_runtime.lua`. The runtime regression loads the
real compiled ItemDB and exercises all six rarity/class combinations, native
skill changes, Supplier 9-to-10 skill changes, the 20/30 quantity milestones,
full endpoints, Crystal pool conservation, scanned/manual parity, source
policies, confidence caps, caching and benchmark ordering. A separate in-memory
audit checked 252 forward/inverse combinations, including saturated endpoints,
with nonnegative quantities and conserved Crystal pools.
The real compiled runtime regression passed 347 assertions under Lua 5.1.
Additional metadata tests verify Crystal's actual perk boundaries, existing
Mote identities, transferred unit budget and absence of invented sample counts.
`tests/test_crystal_collector_extras.lua` passed 209 assertions for both physical
classes through the unlock/increase boundaries, per-output confidence and
additive inverse. Its four metadata/compiler tests also passed.

## Gleaming Shatter is a separate recipe

Gleaming Shatter (470726) consumes a ranked Gleaming Shard and produces three
Storm Dust. It uses a dedicated recipe quality model rather than the gear
disenchant category model or ordinary deterministic crafting thresholds.
The current native labels 3404 and 3436 route Skill from Designated Disenchanter
and Uncommon Utilitarian: 65 and 80 Skill at full investment. Rare Resourcing
and Epic Escalations do not match the recipe. The consumed shard's Rare item
rarity therefore cannot select the child path. These native label exceptions
apply to Skill; the gear-only extra-Dust proc prose is not transferred.

The published September 11, 2024 cohorts report 1,064 completed rank-two-input
crafts yielding 2,157 rank-one and 1,035 rank-two Dust, and 1,066 rank-three-input
crafts yielding 1,314 rank-one, 1,275 rank-two and 609 rank-three Dust. Each pool
is exactly three units per completed craft. The player reported 105+28 Skill,
a maxed disenchanting tree and 18% Resourcefulness. These unit totals establish
means, without establishing output-hit probabilities or histograms.

The working curve treats 133 as the native source Skill and adds the current
145 specialization Skill for an assumed effective endpoint of 278. It linearly
blends a three-rank-one baseline with the matching published vector, caps output
rank by input rank, and conserves the pool. This intermediate curve and its
historical-to-current transfer have confidence zero. A saturated source can
invert to the declared baseline only when it matches the published endpoint;
incompatible or negative implied baselines are rejected. Resourcefulness changes
expected shard consumption separately, and Multicraft does not multiply Dust.
The source records and assumptions are in
`database/research/shatter-quality-models.json`; the original observations remain
unchanged. Four metadata tests verify native routing, exact denominators, unit
totals, quality caps and absence of invented probability evidence.
`tests/test_shatter_profession_runtime.lua` passed 209 checks against the real
compiled sources, including exact source normalization, manual/native Skill,
matching and mismatched child paths, unit and gold changes, ConversionOptions,
tooltip confidence, source policies, unrelated-source preservation and benchmark
ordering. It also rejects incompatible saturated and negative implied sources.

## Validation across the other profession profiles

`tests/test_profession_calculations.lua` exercises all 39 profession/expansion
profiles, every specialization node and milestone, matching recipe and target
scopes, actual input/output identities, and separate output, input-saving, time,
concentration, unlock and discovery metrics. Conditional buffs can be selected
by their source entry without inventing missing Spell IDs, and their stack caps
are enforced. Skinning species and Majestic material pools require legal target
identities; unspecified targets retain named outcomes rather than asserting all
species materials. A mixed-target prior must be explicitly selected.

`tests/test_profession_baseline_pipeline.lua` deep-compares every original source
field and count before and after building derived baselines and resolving
quotes. It checks independent profile normalization before weighted fusion,
user source weights, personal-only policy and confidence, source toggles,
material identity/order, and non-actionable gathering target previews.
The current matrix passed 30,177 assertions; the real baseline pipeline passed
625. The matrix dispatches 7,338 scoped handlers and checks 12 dedicated routes;
this is execution coverage rather than a claim that all historical coefficients
were measured. Internal priors retain their declared confidence, including zero.
The native Settings regression also verifies zero-point learning grants exactly
once, clearing that state removes the grant, and positive investment disables
the already-checked learning control. Final audit regressions cover bound
byproduct deduplication after personal projection, weighted aggregation of
multiple studies from the same source before quality routing, and inactive
conditional effects when target/event flags are absent.
Fixed native crafts and all four gathering target types also test final-stage
benchmark scaling once, confidence zero, unchanged source models, and replay
idempotence. Fixed craft benchmarks replace the Resourcefulness supply-cost
factor; gathering remains non-actionable and does not inherit that saving.
Named expected quantities scale without creating probabilities or observations.
