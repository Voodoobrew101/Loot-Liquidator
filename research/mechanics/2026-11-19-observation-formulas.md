# Disenchanting observation and resolved-perk audit — November 19, 2026

Research only. No recorded observations, application code or generated database
were changed by this audit. Numeric API facts and the coverage audit are in
`2026-11-19-observation-formulas.json`.

## Newly resolved numerical skill terms

The on-disk profession option snapshot contains Blizzard-resolved perk text for
all four Midnight paths. Its recorded observation time is November 19, 2026,
17:54:44 UTC. The collector records ranks using
`C_ProfSpecs.GetUnlockRankForPerk` and text using
`C_ProfSpecs.GetDescriptionForPerk`; these are invested-point boundaries, rather
than the older third-party addon's unresolved raw-rank table.

Let `p` be invested points and `L` mean the node is actually learned. The
following skill terms are supported by the saved API values:

* Delegate: `p + 5L + 5[p>=10] + 10[p>=20] + 20[p>=30]`.
* Dust Deliverer and Shard Supplier:
  `p + 5L + 5[p>=5] + 5[p>=10] + 5[p>=15] + 10[p>=25] + 20[p>=30]`.
* Crystal Collector: the same flat milestone terms as the child paths, **without
  a `+p` term supported by this API description alone**. Its retrieved base
  description does not state a numerical per-point amount. The separate
  `2026-11-19-game-data-formulas.json` DB2 join review subsequently supports a
  provisional `+p` inference at confidence 60, rather than asserting that it was
  explicitly stated by this captured base description.

The `+5` at rank zero is a learning bonus. A static option existing at zero
points does not establish that the simulated node is learned. Rank-20 and
rank-30 additional-material descriptions still contain no numerical proc rate
or bonus-stack distribution. Skill bonuses do not by themselves supply a
quality-probability or total-quantity curve.

## Local observations and numerical admission

The current saved raw history contains 1,971 craft records and 152 context
records. The anonymized `.validation/formula-observation-aggregate-20261119.json`
retains 111 Midnight item/level/class/skill/allocation groups with source hash,
counts, timestamps and variant hashes. That file is an inventory of positives,
**not an admitted rate table**.

Applying the existing numerical coverage rules to current saved study/context
cohorts rejects all specialized Midnight positives because the legacy studies
have unscoped coverage gaps. In particular, the three uncommon and twenty epic
positives at recorded skill 104 cannot become Dust or Crystal yield references.
Their raw allocation signature contains path ranks 31/11; any conversion to
invested 30/10 also requires the separate unlock-entry mapping.

The only exact item/level/class with both known nonzero-skill specialized and
unspecialized records is epic item 272257, level 292, armor: one cast in each
setup, both yielding rank-one Crystal. This is insufficient to fit an effect.

For rare armor item 244752, level 165, the current numerical admission rules
retain the following zero-specialization cohorts:

| Recorded skill | Casts | R1 Shard units | R2 Shard units |
|---|---:|---:|---:|
| 64 | 31 | 30 | 1 |
| 82 | 405 | 368 | 37 |
| Unknown | 12 | 11 | 1 |

Recorded skill here is base skill plus equipment modifier, not an explicit
specialization-inclusive operation skill. Other larger raw groups are censored.
Existing hash-bound, separately reviewed pinned exports keep their own admission
decisions; this audit does not revoke or silently replace them. These limited
anchors do not establish a universal slope or Dust/Crystal point curve.

## Public primary observations re-read

* [RaziarEdge uncommon discussion](https://www.reddit.com/r/woweconomy/comments/1rke21a/eversinging_dust_rank_2_is_almost_certainly_way/):
  approximately 2.9 total dust per cast with the uncommon path fully invested,
  reported maximum six. No exact denominator, allocation, skill, input IDs,
  quality split or matched lower-investment sample. Suitable only as a
  provisional pooled full-investment reference, not a point multiplier.
* [MrNoobyy epic discussion](https://www.reddit.com/r/woweconomy/comments/1ryolii/swimming_in_dawn_crystals_an_experienced_goblin/):
  approximately 66% rank-two Crystal chance with base skill 100, rare equipment
  and a maxed tree. No denominator, item cohort, complete mutually exclusive
  outcome coverage or lower-point comparator. This is an approximate claim, not
  a measured distribution or an expected-quantity field.
* [Aspalar rare study](https://www.reddit.com/r/woweconomy/comments/1rpwov0/disenchantingshard_help/):
  roughly 5,000 casts at a stated maximum setup, with 0.42 R1 and 0.97 R2 units
  per cast; their sum is 1.39 rather than the separately claimed 1.45 total.
  The spreadsheet is mentioned but not publicly linked. No new counted cohort
  or rank probability was manufactured from it.
* [Profession tool discussion](https://www.reddit.com/r/woweconomy/comments/1ryvu67/does_profession_level_and_tools_matter_for/):
  independently explains the +40 equipment skill setup and quality influence,
  but explicitly asks whether the percentage is public and supplies no formula.
* The [Penguinr2gt shuffle description](https://zolotube.com/watch?v=IVmi3tHy-dM)
  points to `bit.ly/PenguMidnight`; its spreadsheet destination remains
  inaccessible through this retrieval. Profit-per-hour claims were not turned
  into drop rates.

The existing counted Courtly Wrists 1,000-cast maximum Delegate/Supplier cohort
remains the exact full-allocation reference already integrated by the project.
It supplies no lower-investment Dust or Crystal curve.

## Result

The resolved milestone skill terms are a real new implementation candidate.
No admissible new Dust/Crystal numerical yield curve was found in local
observations or these current public primary reports. Additional-material proc
chance and amount, and the random skill-to-quality function, remain independent
missing terms. They must not be synthesized by multiplying an unrelated pooled
mean by an approximate quality share from another author or setup.
