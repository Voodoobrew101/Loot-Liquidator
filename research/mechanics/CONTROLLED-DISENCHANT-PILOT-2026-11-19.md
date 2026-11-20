# Controlled disenchant pilot — November 19, 2026

**Superseded during drafting:** the owner's latest constraint is to use existing
and published data only. Do not carry out or request new batches, knowledge
spending, purchases or inventory destruction from this historical draft. The
current assessment is [existing and published data](EXISTING-DISENCHANT-DATA-ASSESSMENT-2026-11-19.md).

Status: proposed collection protocol and estimation contract. No test casts,
knowledge spending, purchases or item destruction are authorized by this file.
The owner has approved developing estimates from controlled tests. Exact items,
quantities and any irreversible allocation changes still require their selection
and approval before collection.

## Start with measured cells, not a universal formula

A cell is one exact tested input and character setup: client build, input item ID
and relevant variant, rarity, item level, armor/weapon/tool class and subclass,
base profession skill, equipment, race, root allocation, matching child
allocation and learned state. The character is recorded under a local stable
identifier; exported research should not need its display name.

Estimate each cell's complete output vector directly. A new numerical tooltip
may use that cell when its scope matches. Two cells demonstrate two tested
setups; they do not establish a line covering every allocation. Untested setups
retain the ordinary reference and an explicit missing-model label. Do not pool
the old specialized positive-only records with new complete batches: their
denominators failed the prior coverage audit.

## Minimal practical first pilot

Prioritize **one branch**, preferably Dust if an inexpensive identical green
armor input and an appropriate unspent allocation are available. Do not buy or
disenchant all three rarities merely to satisfy a predetermined test count.

| Phase | Cells | Complete consumed-item casts | Purpose |
| --- | --- | ---: | --- |
| Current-setup pilot | One available setup | 100 | Validate collection and estimate this exact setup |
| Controlled comparison | A second approved setup, same input | 100 | Estimate a bounded setup difference |
| Fresh validation | The same two setups | 50 per cell | Check replication before fitting a curve |

The two-cell training pilot costs 200 items; the later validation costs another
100. These are proposed caps, not authorization. If only one allocation is
available, stop after its 100-item cell and publish only that cell's estimate.
An already-maxed path cannot supply its own lower-point control by pretending
that a simulation slider changes the real character.

Use five 20-cast collection blocks per training cell and separate 25-cast
validation blocks. Keep each block intact in exports. A short preflight of
5–10 owner-approved items can check the recorder, but those observations should
remain explicitly marked preflight unless their entire setup and stopping rule
were already fixed before any outcomes were inspected.

## Allocation and skill design

Keep Delegate fixed while testing a child. Prefer nearby **19 versus 20** points
for the first bonus-material boundary, then **29 versus 30** for the later perk.
These pairs are choices for a character that has not already passed them. They
must not cause irreversible knowledge spending without approval. A different
available pair can estimate its own bounded effect, but cannot identify an
untested perk threshold.

The child point change also changes effective skill. At 29→30 the researched
skill change is larger because another milestone is reached. Consequently:

- A fixed-gear before/after comparison estimates the **combined allocation
  effect**, including its skill change. Do not call it an isolated proc bonus.
- To isolate the perk from quality skill, match total researched skill across
  the two allocations using a verified reversible equipment-skill adjustment,
  if one is actually available. Record both equipment variants. Do not assume
  that a convenient +1 or +21 adjustment can be equipped.
- To learn the skill-to-quality relationship independently, keep specialization
  fixed and vary equipment skill reversibly. Use at least three observed skill
  levels before considering interpolation. If skill-matched setups are
  unavailable, retain cell estimates and acknowledge the confounding.
- A single-character allocation increase is chronological, so a hotfix or
  time-dependent change is confounded with it. Collect in the same short window,
  record timestamps and build, and label the limitation. If genuinely matched
  characters exist, interleave their blocks and randomize block order; do not
  conceal character differences under a pooled mean.

For each branch, test only the matching rarity: Dust/Uncommon, Supplier/Rare,
Crystal/Epic. Armor, weapons and profession tools remain separate until data
support combining them. The previously observed rare item 244752 at level 165
may be a Supplier candidate **only if the owner has approved identical variants**;
it supplies no green or epic control. Do not substitute unrelated item IDs.

## Record every denominator and output

Before the first cast, save a signed or hashed study manifest containing:

- Study ID, protocol version, branch, cell ID, fixed sample target, local
  character ID, client version/build and start time.
- Full input identity: item ID, rarity, item level, class/subclass, inventory type,
  crafted/reagent quality if relevant, bonus IDs and suffix/upgrade information.
  A unique item GUID identifies a cast's consumed instance but is not itself a
  cohort variant; do not split equivalent copies solely by unique GUID.
- Base skill, equipment skill and exact equipment variants; race; invested node
  points; learned-node states; the versioned arithmetic used to derive total
  skill. Preserve raw API ranks separately from normalized invested points.
- Authorized item count and stock. Store prices separately from the measured
  quantities so market changes cannot rewrite the observations.

Each attempt needs a unique operation ID and timestamps. Each successful,
consumed-input cast needs the entire settled output vector, including material
item IDs, quality ranks and stack counts. Zero of an output is recorded as zero
for that cast; an absent receipt or incomplete inventory observation is unknown,
not zero. A failed cast that consumes no item is not a completed trial, but its
failure remains in the attempt ledger. If a cast consumes the input and settles
with no output, it is a completed zero-output trial.

At block end reconcile attempted, failed, interrupted, input-consumed, complete
and incomplete counts, plus inventory deltas. Any unscoped missing-receipt,
overlap or collection gap prevents numerical admission of the affected block.
Do not rescue only its successful positives. After a skill, equipment, talent,
item-variant or build change, close the block and start another cell. Preserve
the raw export and its checksum; corrections append provenance rather than
rewriting original observations.

## Estimate quantities, qualities and bonuses separately

For output item/quality `j` and complete cast `i`, let `x[i,j]` be its unit count.
With `n` complete consumed-item casts:

- Mean units per cast: `mu[j] = sum_i x[i,j] / n`, including zero outputs.
- Hit probability: `p[j] = count_i(x[i,j] > 0) / n`.
- Conditional positive stack mean: `sum_i x[i,j] / count_i(x[i,j] > 0)`, only when
  at least one hit exists. This is different from unconditional units per cast.
- Pooled main-material mean: sum the quality-specific `mu[j]` for that family.
- Rank-two unit share: total R2 units divided by total family units, when the
  denominator is positive. A unit share is not a per-cast probability. If both
  ranks can occur in one cast, do not force their hit probabilities to sum to one.

Do not infer a main-material proc solely because a stack looks large: the
unmodified stack distribution is unknown. Report observable quantities and
allocation differences. A distinct additional material can have an observable
hit rate, but zero hits in a low-investment sample does not itself prove a
structural zero. Use the researched perk eligibility separately from the sample.

Price the vector using current eligible prices:
`estimated output value = sum_j mu[j] * current net unit price[j]`.
Any expected profit additionally subtracts the exact input's opportunity cost.
Missing prices produce a partial valuation; they do not make units disappear.
Changing prices must change the valuation, not the fitted material distribution.

## Uncertainty and what the pilot can establish

Use Wilson or exact binomial intervals for observable hit probabilities, rather
than a symmetric normal interval near zero or one. For zero hits, the exact
one-sided 95% upper bound is `1 - 0.05^(1/n)`. Thus zero hits among 100 casts is
compatible with a true chance up to about **2.95%**; at 400 casts the bound is
about **0.75%**, and at 1,000 it is **0.30%**. These limits describe uncertainty,
not invented bonus quantities. [NIST confidence-interval methods](https://www.itl.nist.gov/div898/handbook/prc/section2/prc241.htm)

At a true probability near 50%, a Wilson 95% interval has a half-width of roughly
9.6 percentage points at 100 casts and 4.9 at 400. A 100-cast pilot therefore
cannot reliably resolve a small difference between two cells. Counts should be
expanded based on the required precision and observed variance, not on a claim
that 100 is intrinsically enough.

For means, unit-share ratios, cell differences and value at fixed prices,
resample **whole per-cast output vectors with common indices** so co-occurring
materials and quality totals stay linked. A paired/BCa bootstrap is suitable
when the data support it; degenerate all-zero or constant samples need an
explicit fallback/limitation, not an apparently certain [0,0] rare-output mean.
Keep the random seed and resample count for reproducibility. If block dependence
or drift is evident, use block-level replication or qualify intervals rather
than assuming all casts are independent. [SciPy's documented paired resampling
and bootstrap methods](https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.bootstrap.html)

Predeclare fixed sample targets and review points (for example 100, then 400,
then 1,000 per cell if authorized). Do not stop as soon as an attractive profit
or statistically convenient difference appears. Repeated ordinary intervals
under optional stopping are exploratory; formal sequential claims need an
appropriate sequential method or an untouched fixed-size validation set.

## Promotion to a tooltip model

1. Admit complete, immutable, correctly scoped cells. Render their means and
   uncertainty as **experimental estimates**, with counts and context.
2. Replicate the same cells on fresh blocks. Keep validation data out of model
   choice; report discrepancies rather than silently refitting them away.
3. Fit an allocation or skill curve only after at least three relevant training
   checkpoints and fresh interior validation setups exist. Reserve additional
   validation cells when a curve is proposed; two endpoint holdouts validate
   endpoints, not an interior interpolation rule.
4. Compare the candidate with the simple exact-cell reference on held-out output
   vectors using a declared proper distribution score or squared-error metric.
   Report quality, pooled quantity and bonus outputs separately. Failure means
   the curve remains research-only; it does not mean measured cells are erased.
5. Use interpolation only within the tested skill range, matching item scope,
   build and perk regime. Never interpolate across the known 20- or 30-point
   perk boundary without observations on both sides and an explicit model for
   the jump. Do not force monotonicity unless the relevant mechanic supports it
   and the constraint is declared and validated.

A fitted curve remains an empirical estimate, not Blizzard's exact formula.
Small samples are displayed with their uncertainty rather than assigned a
fabricated universal confidence percentage. Existing source preferences,
eligibility and recording-coverage checks still apply. An experimental model
must not multiply a mixed historical reference that may already contain the
same specialization bonus; use its directly measured scoped vector or a
separately justified source-to-target transformation exactly once.

## Next concrete approval package

Before collection, prepare one reviewable manifest naming the proposed branch,
character, exact input/variant, current and target real allocations, item count,
available reversible skill levels and any purchase/knowledge cost. If the
required stock or lower allocation does not exist, revise the design before
requesting approval. Approval to develop estimates does not authorize destroying
unspecified inventory or spending irreversible knowledge points.
