# Coordinator T0027 — Season 3 Fate Weaver original reward outcomes and retained input gate
Research-only source identity/field audit, checked 2026-11-14 UTC. Not a client test or independent controlled drop-rate cohort.

## Original item/version and observed outcomes

Worker source record `war-within-20261114-fw03` in `research/v3/evidence/war-within/20261114T0426-fate-weaver-season-token-identities.jsonl` already establishes Season 3 **Fate Weaver input item 246086**, one-charge ritual, and two possible historical weapon identities **Fateweaved Needle 219382** / **Fateweaved Mallet 219941**; it explicitly leaves Season 3 item-specific redemption and completeness unresolved. Independent review of the [original Season 3 item page](https://www.wowhead.com/item=246086/fate-weaver) finds **item-specific first-person successful examples**:

- Commenter **Trevia** says their Mistweaver Monk used the 246086 ritual and received a **Fateweaved Mallet**, **Adventurer 1/8 ilvl 655**; the source directly links the Mallet `219941` and Needle `219382` names. Also explicitly says the original offhand **was not consumed**.
- **jennywocky** says a Windwalker Monk with Windwalker loot spec received a **Fateweaved Mallet**, Champion 1/8, while the original offhand was retained; its Leech tertiary did **not** transfer. This contradicts a simplistic "all DPS get daggers" routing shortcut.
- **WillowufGood** says an offhand upgraded from **ilvl 684 to 694** generated a **Fateweaved Needle ilvl 681**. This supports a Season 3 Needle outcome **and** shows that a selected upgraded offhand item level cannot be blindly copied to the created weapon.
- **FoxyOwl** independently reports a **Champion 2/8 ilvl 684** input produced **Champion 1/8 ilvl 681 Mallet**, and the offhand remained. **Flynne** reports a **Hero 694** input with a **Hero 694** mace, so the above examples do not establish a universal numerical downgrade rule.

These are dated only by the item/season context in indexed comments, not at-cast patch, character build or verified 2026-client logs. Treat as **direct source-reported successes, not measured probability samples**. Do not assign arbitrary conditional probabilities, fixed item-level conversion formulas, specific class/spec eligibility matrices or a guaranteed redeem action.

## Conflicting eligibility / valuation treatment

The [August 21, 2025 original bug report](https://us.forums.blizzard.com/en/wow/t/fate-weaver-season-3-ilvl-350/2154715) says a Season 3 **ilvl 350** input at the ritual site completed its cast bar but did not award a weapon, even after changing spec. This failure does not invalidate other item-specific successes; item bonus/level, item version, spell state or timing remain unresolved. [WoW spell 1240695](https://www.wowhead.com/spell=1240695/fate-weaver) is marked as ritual-site restricted, server-side script, and identifies Season 3 item input; do not assume a generic right-click in bags succeeds anywhere.

Potential supported tooltip fields for an eligible character: conditionally show **ritual-site + one remaining charge**, two historically observed reward identities, **retained offhand (charge consumed, item not consumed)**, and reward-level/tertiary uncertainty. Do not treat the whole offhand value as a destroyed processing cost or count retained offhand as a newly created reward. Keep the current redemption claim conditional, since one original source reports a failed Season 3 state. Awarded weapons are bound; no AH conversion can be assumed. Any vendor/disenchant alternative still requires exact output variant, character eligibility and prices.

## Validation and boundaries

Original source text directly inspected at `https://www.wowhead.com/item=246086/fate-weaver`; original Blizzard report checked. Worker evidence compared for nonduplication. No new observed casts, independently logged complete denominators, chance, output quantity distribution, sourced universal item-level coefficient or new current Retail gold EV. No estimator, addon, tooltip, synthetic-price fixture or live WoW-client run. All worker evidence files and protected branches left unchanged.

**Next highest-value action:** obtain a genuine current-client `246086` ritual receipt with exact itemLink/bonuses, class, loot spec, zone, charge before/after and awarded itemLink/quality/level; otherwise retain conditional labels. Do not divert worker schedules from Midnight T0005/T0039/T0045 refund-aware zero-inclusive source logs.
