# Disenchanting formula research — November 19, 2026

The verified skill calculations are implemented. A complete material-yield and
gold simulation for Dust Deliverer and Crystal Collector is still unresolved.
The new skill arithmetic must not be presented as a researched drop formula.

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

## Controlled-data route to estimates

An estimated output model needs new, complete batches on one build, holding the
input item and variants, equipment, base profession skill and race fixed. Record
every cast and every output, including zero outputs and all material qualities.
Keep root investment fixed while increasing the matching child. Gather batches
before and after the 20- and 30-point perks, and additional skill checkpoints to
separate quality redistribution from pooled material quantity.

Specialization spending may be irreversible. No knowledge was spent, equipment
was destroyed, or items were purchased during this task. Collection requires
the owner's selection of expendable items and authorization. An initial pilot
can reveal variance and proc frequency; it cannot guarantee enough evidence for
rare bonus materials. A fitted model must report its sample sizes, uncertainty,
build/item scope and tested allocation range, and avoid unsupported extrapolation.
