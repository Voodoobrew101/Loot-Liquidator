# 2026-10-29 q27 Midnight Crushing — exact selector, quality and original-source evidence
Scope: `2026-10-29-batch025-midnight`, queue revision 27, 32 assigned input/output rank leads, Retail. Source review date 2026-10-29. This is a **source-only note**, not an in-game measurement or a newly compiled mapping.

## Recipe primary game record
- Retail spell: https://www.wowhead.com/spell=1231132/midnight-crushing ; spell ID 1231132; 2-second cast; Midnight Jewelcrafting (5) spell details; Salvage Item Crafting Data (105), value 3; text says 3 Midnight gems, displayed reagent **Dusk-Shrouded Stone ×1**.
- Exact selected gem whitelist is not exposed in the text; neither stone quality alternative is enumerated as a selectable reagent on the spell page. Cannot claim per-item recipe acceptance or full quality substitution.
- Gemdust item IDs: https://www.wowhead.com/item=242620/glimmering-gemdust and https://www.wowhead.com/item=242621/glimmering-gemdust ; output R1/R2 identities only, not rank-specific cast yields.
- Source ledger: `research/ledger/itemdb-uncompiled-output-leads.csv`; 32 source leads are *unadmitted*, not existing 32 conversions.

## Firsthand original qualitative observations, independently authored
1. **Blizzard forum, March 21 2026**, https://us.forums.blizzard.com/en/wow/t/why-is-jewelcrafting-so-incredibly-expensive/2277117, commenter Reikah: rare blue gems can yield as little as **one dust from three gems**; argues rarity should yield more. This supports a family lower positive bound **1**, not a quality-rank or output-rank P/E. No cast denominator, exact item IDs or skill.
2. **Reddit /r/woweconomy, March 23 2026**, https://www.reddit.com/r/woweconomy/comments/1s1dtuh/jc_prospecting_is_atrocious/: different commenters report **one**, **two** and **three** Gemdust from Crushing; qualitative observations without per-item input IDs or denominator. These are commenters on one thread, not one cast histogram; do not multiply independent cohorts.
3. **Reddit /r/wow, April 18 2026**, https://www.reddit.com/r/wow/comments/1sp0dax/jewelcrafting/: first-person player says crushing three Eversong Diamonds can give one powder. Diamonds are *outside* assigned 16 inputs; no higher dust guarantee from rarity, no current patch proof.
4. **Reddit /r/woweconomy March 12 thread, March 18 follow-up**, https://www.reddit.com/r/woweconomy/comments/1rrn6of/resourcefulness_in_crushingprospecting/: Megahshortfuse reports UI effective Crushing skill 255, quality target 440 and realizes **R2 gems and R2 stone** affect reaching R2. Previously indexed URL; newly extracted subcomment, same source URL lineage. It is a contextual recipe-quality observation, not verified universal cutoff or rank-specific output measurement.

## Previously indexed secondary/context sources, reused without independent credit
- Method guide, March 5 2026, https://www.method.gg/guides/midnight-jewelcrafting-profession-guide: claims positive family yield **1–3** and no variety/rarity advantage. The guide's “individually crushed for stone” phrasing is *not* proof that the Midnight Crushing spell produces free stone; spell actually **consumes** stone. Guide is not an original zero-inclusive experiment.
- Wowhead Glimmering Gemdust R1 page https://www.wowhead.com/item=242620/glimmering-gemdust: Cardinalai's already archived mixed 480-gem/160-stone/330-dust cohort (40.7% Resourcefulness) is one historical author aggregate; cannot assign exact R1/R2 outcome or a per-input E.
- 2026-09-29 build 12.1.0.69933 game-record listing https://www.wowdayday.com/wiki/entry/profession:jewelcrafting:recipe:1230462: identifies Sanguine Garnet item ranks `242553/242723` and Gemdust `242620/242621` as crafting-quality choices in **spell 1230462 gem-cutting**; **not** evidence they are selectable in **spell 1231132**.

## Numeric eligibility and field audit
- 32 exact keys, 16 gem IDs × 2 Gemdust output quality ranks; all remain **UNADMITTED_SELECTOR_AND_OUTPUT_RANK_NOT_VERIFIED**.
- Each key: `P(>=1)=null`, `positiveMin=null`, `positiveMax=null`, `unconditionalE=null`; no inferred zero, no midpoint, no borrowed 0.67/gem to fill E.
- Family-level candidate positive yield **1–3** (tooltip-only, confidence 45/100 *for family context*, not exact output-rank). Never promote to 32 per-rank fields without selector/rank eligibility and rank-specific outcome support. `economicUse=PROHIBITED`.
- Gold model must price 3 selected gems + 1 Dusk-Shrouded Stone, track actual refunds separately, gate by recipe learned and skill, and treat output qualities as alternatives.

## Needed next in-client capture
For each of 16 IDs: selector accepts? 3 identical gems or mixed gems? stone rank R1/R2 accepted? quality threshold displayed and effective skill? actual completed cast, output Gemdust item ID/rank/count and input/stone Resourcefulness refund? timestamp/build? Until then no source supports 32 new legitimate exact conversions or gold valuation.
