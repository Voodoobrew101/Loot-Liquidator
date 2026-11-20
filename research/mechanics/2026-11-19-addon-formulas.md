# Current addon audit: Midnight disenchant output formulas

Read on November 19, 2026. This is a fresh source audit, not a claim that absence
from these addons proves that Blizzard has no formula. No application code or
original observation evidence was changed by this audit.

The inspected current sources do **not** establish a numerical function from
Dust Deliverer/Crystal Collector points or effective disenchant skill to the
expected units of each quality. Their numerical output models are either fixed
estimates or personal-observation averages. They cannot substantiate a new
Loot Liquidator skill-to-quality slope or extra-material multiplier.

## Source pins and findings

### Disenchanting Advisor

- Current main resolves to `4a7903820d45262994ecd689dc4edbcf0235f8c8`, February 23,
  2026. It is the same revision already audited on November 6, not a newer model.
- [DisenchantData.lua](https://github.com/brandanq2/disenchanting-advisor/blob/4a7903820d45262994ecd689dc4edbcf0235f8c8/Data/DisenchantData.lua),
  Git blob `447080e47a780f8ea9ae80ccac1befbc45aec17c`.
- [Tracking.lua](https://github.com/brandanq2/disenchanting-advisor/blob/4a7903820d45262994ecd689dc4edbcf0235f8c8/Data/Tracking.lua),
  Git blob `d8f9bee1a1a4b10819bc872b689506ba05106ad9`.

The fixed fallback tables are marked approximate, from prelaunch community
testing. They do not vary with skill or points. The implementation bins personal
Midnight results into 25-skill storage bands; those bands are not game quality
thresholds. Skill calculation uses raw `currentRank` plus hardcoded flat bonuses,
without resolving the separate free-unlock rank. Root learning/milestone and
child learning/milestone skill amounts are useful leads, not independent proof
of the invested-point boundary or a yield curve. The 20-point comments mention
extra dust/shards/essences but supply neither proc probability nor bonus stack
distribution. Crystal's assumed per-point contribution is not independently
established by this implementation.

### CraftSim

- Current main resolves to `e15fb18c1004b2f373ee3247b2ade0b917fbea69`, October 21,
  2026; again the same previously pinned revision.
- [Midnight Enchanting specialization data](https://github.com/derfloh205/CraftSim/blob/e15fb18c1004b2f373ee3247b2ade0b917fbea69/Data/SpecializationData/Midnight/Enchanting.lua),
  Git blob `177e4a787ca5f8645143970e5a005324de780174`.
- [Disenchant module](https://github.com/derfloh205/CraftSim/blob/e15fb18c1004b2f373ee3247b2ade0b917fbea69/Modules/Disenchant/Disenchant.lua),
  Git blob `870d2c336ad7250dced55507cf05455a0b678074`.

Delegate, Dust and Supplier specialization rows use a DNT trait-rank modifier
label for their per-point and auxiliary skill values. Crystal Collector 107646
does not appear in this specialization recipe-stat table. The Disenchant module
loads, filters and queues inventory; it does not calculate disenchant material
probabilities or specialization-dependent quantities. Crafting recipe-quality
threshold logic elsewhere in CraftSim therefore cannot be transplanted into
randomized gear disenchanting as if it were a documented disenchant formula.

### TradeSkillMaster and Auctionator installed distributions

Read the actual installed primary distributions without modifying them:

- TradeSkillMaster **v4.15.8**, `LibTSMData/Destroy/Disenchant.lua`, SHA-256
  `63c71f49b229de8dee424356537462280e814882fe8c2acc4f27d76f5c596c42`.
  The retail table ends at Dragonflight expansion 9; no Midnight material IDs,
  specialization controls or skill-dependent distribution code are present.
- Auctionator **349**, `Source_Retail/Enchant/Constants.lua`, SHA-256
  `b38202ae91be584f817efb2289adddb86c25ee1fb2a1645040b62e67cc283a02`.
  Its retail tables cover Warlords through Shadowlands, not Midnight.
  `Source_Retail/Enchant/Main.lua` sums static stack probabilities times stack
  counts times material price. It contains no profession-skill or specialization
  parameter. The provider interface does not add a missing Midnight formula.

Public `TradeSkillMaster/LibTSMData` repository requests returned 404; the
installed file is the evidence here, not a claim of having read a current public
GitHub revision. Author sites: [TradeSkillMaster](https://tradeskillmaster.com/),
[Auctionator](https://www.curseforge.com/wow/addons/auctionator).

### GoldCap

- Current main `723e9198085fdf94b1c433f1b73781d562c5635c`, November 17, 2026.
- [Core/Disenchant.lua](https://github.com/goldcap-gg/goldcap-addon/blob/723e9198085fdf94b1c433f1b73781d562c5635c/GoldCap/Core/Disenchant.lua),
  Git blob `acfac58d15549f0effccc2e36117d090b83200bc`.
- [Public changelog](https://goldcap.gg/changelog).

Retail has no shipped yield table. It learns average units from the player's
casts, indexed by expansion, rarity and armor/weapon/profession-tool class (plus
item-level bands before Dragonflight). It does not index skill or specialization
points. Beyond 50 casts it discounts prior sums before adding a new cast.
This is a moving empirical average, not an intervenable profession simulation.
The new quantified chance tooltip in the November 17 release notes is explicitly
for Classic/Forever; it is not a new Midnight formula.

GoldCap is source-available under a restrictive license. No code was copied into
Loot Liquidator. This note records mathematical behavior and source provenance.

### Disenchanty 1.0.0

- [Official file 9277263](https://www.curseforge.com/wow/addons/disenchanty/files/9277263),
  October 21, 2026, `Disenchanty 1.0.0.zip`.
- Archive SHA-256
  `d6b40b24f5b445534cf185cd54da22b3da6c04537c0374c78df7bfe69e17a7b1`.
- Inspected `Disenchanty/Data.lua` from the unexecuted release archive.

The Midnight table records a base-rank item ID as a stand-in for all qualities
combined. Its green row is dust with range 1–3; blue is one shard; epic is one
crystal. Its own comment says chances combine the quality ranks. There is no
allocation/skill-dependent quality redistribution. Treating the base-rank ID as
an exact rank-specific distribution would be an error. Personal learning adds
observed output IDs but no specialization intervention model.

### ProfitProphet 2.10.22

- [Official file 9513300](https://www.curseforge.com/wow/addons/profitprophet/files/9513300),
  November 8, 2026, `ProfitProphet-v2.10.22.zip`.
- Archive SHA-256
  `e8a7546925b9e97353f895621178288ae893c3aeb1f55fb6665269ae13938d78`.
- Inspected `PP_Disenchant_Retail.lua` and `PP_DestroyLearn.lua` from the
  unexecuted release archive.

Midnight expected quantities are explicitly marked estimated and shaped from
Dragonflight weights. Its provenance note says the public client table supplies
band structure rather than yields. TWW/Midnight quality families are represented
by tier-1 item IDs; no skill-to-rank curve is present. Its personal learning
combines the seeded mean and observed units with a 20-source prior weight. That
is an estimation policy for an observation stream, not a Blizzard game rule and
not evidence for how Dust/Crystal point changes affect outputs.

The archives remain only in the workspace's `.validation/addon-formula-research-20261119`
research directory. Neither addon was installed or executed, and no application
code was copied from their all-rights-reserved distributions.

### Alternatives excluded by game scope

[DisenchanterPlus](https://github.com/osilvay/DisenchanterPlus) current
`cfdb57fc677183e73410a2b48e0d25b259467d1e` targets Classic/TBC/Forever.
Auction Detonator's newer release mentions Retail, but its publicly described
classic material tables do not establish a Midnight specialization curve.

## What remains necessary for a numerical disenchant simulation

Known per-point or milestone skill arithmetic is only one input. A numerical
material-value calculation additionally needs, for the stated patch and item
rarity/class/category:

1. A calibrated mapping from effective skill to output-quality distribution.
2. The activation boundary and numerical probability for each extra-material
   perk, or directly measured expected bonus units at that allocation.
3. The bonus quantity and material/quality routing, with ordinary and perk
   outputs separated sufficiently to avoid double counting.
4. A source baseline with known skill, tool and point context. A mixed or
   max-specialization cohort cannot be silently called a zero-point baseline.

These inspected addons do not close those terms. Controlled casts with matching
item category, skill and allocation, or primary game-data records exposing the
missing distributions, are needed. Exact salvage/shatter recipe-quality models
are a separate operation and must not be presented as a gear-disenchant curve.

## Independent review of newly linked client data

The subsequent build-70961 DB2 joins in the workspace's
`.validation/de-formula-data` provide stronger evidence for Crystal Collector's
per-point skill than the inspected addons. This is primary client data, not an
addon coefficient:

| Base node | Trait definition | Entry | Profession trait | Label | Effect | Amount |
| --- | --- | --- | --- | --- | --- | --- |
| Crystal Collector 107646 | 137724 | 132938 | 18867 | 5052 | 146 | 1 |
| Shard Supplier 107647 | 137732 | 132946 | 18875 | 5051 | 146 | 1 |
| Dust Deliverer 107648 | 137740 | 132954 | 18883 | 5050 | 146 | 1 |
| Disenchanting Delegate 107649 | 137748 | 132962 | 18891 | 5049 | 146 | 1 |

All four entries have `MaxRanks=30` and `NodeEntryType=7`. The join is
`TraitDefinitionID` to `ProfessionTrait`, followed by `ProfessionTraitXEffect`
and `ProfessionTraitXLabel`. Effect 146 has
`ProfessionEffectTypeEnumID=25`, named
`Trait Ranks By Points-Modifier Label (DNT)`, and `Amount=1`.
The other three base descriptions explicitly identify this effect as skill per
specialization point. Crystal's base description omits the number, but its
explicitly described Epic-skill milestones use the same label 5052 and effect
type, with effects 147/148/150 supplying 5/10/20 skill.

The shared effect, matching Epic-specific label, and milestone descriptions
strongly support the interpretation **Crystal Collector adds one Epic
disenchant skill per invested point**, in addition to its 50 milestone skill.
That interpretation is inferred from directly linked client records; it must
not be attributed to a numeric statement in Crystal's base description. Raw
client entry rank versus invested points must still follow the separately
validated client rank convention rather than assuming they are interchangeable.
These records do not supply any material-quality probability curve or essence
proc rate.

For learned-at-zero simulation state, a separate learned-node map is required.
Existing zero point entries alone are ambiguous: lowering a slider and clearing
an invalid dependent node can both write zero. Legacy positive points establish
learning; legacy zero points do not. A new explicit learned selection can retain
the learning milestone at zero invested points, and resetting to minimum clears
that selection. Captured profiles likewise need the unlock-entry state in
addition to normalized invested rank to represent learned-at-zero faithfully.
