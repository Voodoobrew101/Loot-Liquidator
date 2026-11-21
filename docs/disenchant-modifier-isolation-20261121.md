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


## All-profession check

All thirteen profession panels are covered: Alchemy, Blacksmithing, Enchanting, Engineering, Herbalism, Inscription, Jewelcrafting, Leatherworking, Mining, Skinning, Tailoring, Cooking and Fishing. Explicit non-output/cosmetic effects no longer reveal otherwise inert nodes. The runtime calculator continues to use the matching profession/expansion profile; foreign talent IDs are not resolved through another profession's tree.

The scanner also records these reviewed consumable aura identities without adding any stat amounts: Shattered Essence1235733 (Midnight Enchanting crafting), Haranir Phial of Ingenuity1239755 (Midnight crafting professions, including milling/prospecting duration), and gathering buffs185562 (Darkmoon Firewater),432265 (Phial of Truesight),1236763/1236767 (Haranir Perception/Finesse),1269152/1269170/1269171 (Relaxed Perception/Finesse/Deftness). These gathering-stat auras are scoped to Herbalism, Mining and Skinning, not disenchanting, milling, prospecting, Cooking or Fishing. The stat-free Relaxed movement aura1269168 is excluded. Native effect rows and cache checksums are archived in `database/research/known-profession-auras-70961.json`.

Published descriptions: [profession stats and gathering phials](https://www.wowhead.com/guide/midnight/professions/secondary-stats-and-concentration), [Darkmoon Firewater](https://www.wowhead.com/item=124671/darkmoon-firewater), [Argentleaf Tea](https://www.wowhead.com/item=242298/argentleaf-tea). Recipe1230873 is not the resulting Perception aura1236763; native spell-effect rows identify the actual aura. No profession-crafted consumable transfers the maker's specialization points to its consumer.
