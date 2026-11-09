# Wrath tier-token coverage — November 8, 2026

The eight reported tokens had no reward entry in the shipped catalog, so the
native decision and tooltip paths fell back to Vendor. Only the final screenshot's
45661 (Spaulders of the Wayward Vanquisher) had a catalog mapping. The collection
resolver and tooltip formatter already handled mapped tokens correctly.

| Family | Before | After | Added |
|---|---:|---:|---:|
| Ulduar Wayward, 45632–45661 | 1/30 | 30/30 | 29 |
| Naxxramas/Obsidian Sanctum/Eye of Eternity Lost, 40610–40639 | 0/30 | 30/30 | 30 |
| Trial of the Crusader Trophy, 47242 | 1/1 | 1/1 | 0 |
| Icecrown Marks, 52025–52030 | 6/6 | 6/6 | 0 |

All eight reported gaps are included: 45642, 45657, 45644, 45648, 45647,
45638, 45634 and 45659. This also repairs 21 further Wayward siblings and all
30 related Lost tokens. The catalog grows from 248 to 307 tokens.

## Evidence and implementation

The pinned AllTheThings shared [Tier 8 structure](https://github.com/ATTWoWAddon/AllTheThings/blob/4a95eab7696e74a929996eefd2f6890890e26efe/.contrib/.db/shared/lib/Structures/Tier%20Sets/Tier%208.lua)
and [Tier 7 structure](https://github.com/ATTWoWAddon/AllTheThings/blob/4a95eab7696e74a929996eefd2f6890890e26efe/.contrib/.db/shared/lib/Structures/Tier%20Sets/Tier%207.lua)
each establish 190 exact reward relationships for 30 tokens. Their literal
enclosing class groups identify rewards; reward IDs are never inferred from a
numeric pattern. All 380 reward class masks and 60 token masks independently
match the bundled Wago class restrictions.

Retail native tooltips in the owner's screenshots show Use: create a class set
item appropriate to the loot specialization. Published examples also show that
wording for [Wayward Gauntlets](https://warcraft.wiki.gg/wiki/Gauntlets_of_the_Wayward_Protector)
and [Lost Gloves](https://warcraft.wiki.gg/wiki/Gloves_of_the_Lost_Conqueror).
The importer treats these as class/spec outcomes, retaining the conservative
existing runtime handling for multiple same-class possibilities. It does not
claim a freely selectable reward, an output probability, or several simultaneous
outputs. The ATT structures establish the identities via one-token costs;
they do not establish modern loot-spec selection probabilities.

The existing importer now reads both archived structures as strict data,
checks SHA-256 and Git blob hashes, compares every staged row with the raw
source, and rejects expressions, extra costs, missing family members and repeated
reward identities. It rebuilds database/att-token-baselines.lua and then the
normal ItemDB compiler rebuilds LootLiquidator/ItemDBRuntime.lua. No installed
AllTheThings dependency returns. MIT attribution and unreviewed/60 confidence
labels remain. Existing 45661 wins the compiler's overlap check and is unchanged.

The native token use-level is checked before opening economics, including
offline alts and unknown alt levels. Existing catalog reward requirements also
apply to open tokens. Missing appearances can still be kept for later leveling.

## Validation

- Six Python importer tests pass, including source corruption, expression/extra
  cost rejection and class tampering.
- 1,186 new Lua 5.1 assertions pass across all 60 token catalogs, class groups,
  inventory type variants and 15 native decision/tooltip cases.
- Existing catalog, token valuation, transmog priority, appearance collection
  and alt eligibility regressions pass. Known missing appearances trigger T;
  collected or unknown appearances do not become a false missing appearance.
- A second independent source audit checked all 380 rows against the archived
  source and Wago class restrictions.
- Fresh ItemDB compilation is byte-identical to the generated artifact; package
  manifest, research checksum and frozen reference checks pass.

Base: PR 49 head d565d98b2254c79f49c99a77dca177b6d95e1374. This is a local source
repair, not an installed or published build. No in-client verification is claimed.

## Complete token IDs

### Ulduar Wayward

| Token name | Conqueror | Protector | Vanquisher |
|---|---:|---:|---:|
| Breastplate | 45632 | 45633 | 45634 |
| Chestguard | 45635 | 45636 | 45637 |
| Crown | 45638 | 45639 | 45640 |
| Gauntlets | 45641 | 45642 | 45643 |
| Gloves | 45644 | 45645 | 45646 |
| Helm | 45647 | 45648 | 45649 |
| Leggings | 45650 | 45651 | 45652 |
| Legplates | 45653 | 45654 | 45655 |
| Mantle | 45656 | 45657 | 45658 |
| Spaulders | 45659 | 45660 | 45661 |

### Naxxramas Lost

| Token name | Conqueror | Protector | Vanquisher |
|---|---:|---:|---:|
| Chestguard | 40610 | 40611 | 40612 |
| Gloves | 40613 | 40614 | 40615 |
| Helm | 40616 | 40617 | 40618 |
| Leggings | 40619 | 40620 | 40621 |
| Spaulders | 40622 | 40623 | 40624 |
| Breastplate | 40625 | 40626 | 40627 |
| Gauntlets | 40628 | 40629 | 40630 |
| Crown | 40631 | 40632 | 40633 |
| Legplates | 40634 | 40635 | 40636 |
| Mantle | 40637 | 40638 | 40639 |
