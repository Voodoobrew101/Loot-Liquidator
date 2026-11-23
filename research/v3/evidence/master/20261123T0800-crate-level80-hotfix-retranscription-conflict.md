# Crate of Battlefield Goods: level-80 hotfix retranscription discrepancy (research-manager, 2026-11-23)

## Source reconciliation, not a processing sample

- **Primary Blizzard post**: Kaivax, March 13, 2026 Items hotfix, https://us.forums.blizzard.com/en/wow/t/world-of-warcraft-midnight-hotfixes-april-17/2260898 . For gear from **newly created Crate of Battlefield Goods**, acquisition levels **10–79** are stated to yield **The War Within** disenchant materials; levels **80–90** are stated to yield **Midnight** materials. The crate creation context is essential.
- **Secondary Wowhead retranscription**: Jaydaa, published March 13, 2026, https://www.wowhead.com/news/midnight-hotfixes-for-march-13th-marl-decor-cost-reduction-class-bugfixes-and-380785 . It repeats the 10–79 statement but gives **81–90** (not 80–90) for Midnight materials, leaving level 80 unstated in that copy.
- **Independent corroboration of primary wording**: https://warcraft.wiki.gg/wiki/Crate_of_Battlefield_Goods also transcribes the March 13 hotfix as **80–90**. The primary Blizzard statement is the correct textual citation for the recorded scope. There is no evidence that the secondary discrepancy represents a distinct gameplay patch or observed result.
- **Already-preserved worker evidence**: `research/v3/evidence/war-within/2026-11-23T0718-battlefield-crate-disenchant-material-epoch.jsonl` (`war-within-20261123-071801`) correctly uses Blizzard's **80–90**, not the contradictory copy. Do **not** rewrite or duplicate that worker observation.

## Disposition and fixture handoff

Classify this as **source retranscription / eligibility context**, not new observed output quantity, frequency, recipe, rate, class rule or complete item identity. When testing the build's future crate-specific eligibility, explicitly include **level 80** and the **newly created** acquisition condition. Preserve the primary source's 80–90 policy text, but treat actual input item/bonus, client build, skill, rank, eligibility and output totals as unverified until supported source-specific data exists. Do not apply the crate rule to unrelated gear merely because it has a similar level; do not assign item IDs, casts, zeros or gold value. No in-game operation or synthetic-valuation fixture was executed in this research review.

This note is an independently checked secondary-source conflict encountered **after** the owner's catalogue cutoff. It is not an instruction to redo the Codex team’s 731-source catalogue or alter their branches, source decisions or runtime.
