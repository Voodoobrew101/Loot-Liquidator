# Disenchant modifier isolation

The baseline regression was caused by treating every specialization allocation as a disenchant dependency. Elevating Equipment and its branches grant permanent-enchantment recipe skill through labels 5022, 5028, 5029, 5030 and 5031. They do not grant disenchant skill. The Enchanting results controls now expose the material-affecting Disenchanting Delegate, Dust Deliverer, Shard Supplier and Crystal Collector nodes. All saved allocations remain intact.

The actual N=200 goggles fixture at effective skill104 retains its two shard outputs, 90%/10% probabilities and85% confidence with those crafting nodes maxed. Foreign-profession allocation106982 is also excluded from this baseline dependency. Known non-output nodes can be excluded; unknown IDs and actual disenchant allocations cannot be classified as the zero-specialization reference.

## Buff research and scanning policy

Reviewed2026-11-21 against published spell descriptions and the already compiled native profession effect scopes:

- [Shattered Essence1235733](https://www.wowhead.com/spell=1235733/shattered-essence): Resourcefulness, Ingenuity and Multicraft while practicing Midnight Enchanting. This is not evidence for a disenchant material multiplier.
- [Shatter Essence1235731](https://www.wowhead.com/spell=1235731/shatter-essence): the activation spell must not be confused with its resulting aura.
- [Profession tree](https://www.wowhead.com/profession-tree-calc/enchanting): separate permanent enchantment recipe bonuses from the disenchanting tree.
- [Herbalism consumables](https://www.wow-professions.com/guides/wow-herbalism-leveling-guide): perception/deftness consumables concern gathering. Their being made by another profession does not make that profession's specialization a disenchant modifier.

The runtime aura allowlist is derived from known spell-ID conditions in the selected profession/expansion's compiled models and matching profession rules. Live conversion reads additionally select the operation. Unrelated combat, mount, reputation and other-profession conditions are excluded. The direct player-aura-by-spell-ID API is preferred; older clients enumerate and retain only allowlisted IDs. Spell names and activation-spell guesses never create numerical effects. Conditions with no known aura ID retain their explicit model/manual-condition treatment. Native captured totals remain source receipts; this change does not add consumable bonuses twice or manufacture missing formulas.

No game actions, new casts, rewritten observations, increased sample counts or new multiplier assumptions were used for this fix. Regression tests cover real source rates, control visibility, unknown/relevant-node rejection, foreign-profession aura exclusion, direct-ID reads, legacy filtering and native stat receipts.
