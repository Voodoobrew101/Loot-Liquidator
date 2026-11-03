# Immutable erratum — Legacy q25 Jiyao source URL

**2026-10-28 · research-only · no original file overwritten**

In `research/coordination/source-reviews/loot-liquidator-legacy-2026-10-28-2337-legacy-q25-batch023-wowhead-retail-tooltip.jsonl`, the sixth source-review event (the reused BfA Jiyao mass-milling source) mistakenly cited `https://www.reddit.com/r/woweconomy/comments/t8lubc`. That Reddit post is a **Shadowlands First Flower** study, not the original BfA Jiyao source.

**Correct original source:** https://www.wowhead.com/item=153669/viridescent-pigment — the existing source-memory entry for `bfa-jiyao-2018-seven-herb-massmill`. This correction applies to all nine assigned Jiyao BfA mass-milling stable keys:

- `historical:bfa:mass-mill:152506:153635:256218:jiyao`
- `historical:bfa:mass-mill:152506:153636:256218:jiyao`
- `historical:bfa:mass-mill:152506:153669:256218:jiyao`
- `historical:bfa:mass-mill:152507:153635:256223:jiyao`
- `historical:bfa:mass-mill:152507:153636:256223:jiyao`
- `historical:bfa:mass-mill:152507:153669:256223:jiyao`
- `historical:bfa:mass-mill:152508:153635:256221:jiyao`
- `historical:bfa:mass-mill:152508:153636:256221:jiyao`
- `historical:bfa:mass-mill:152508:153669:256221:jiyao`

No numerical fields, cast denominators, tooltip probabilities, yield bounds, economic expected quantities, or conversion mappings are changed. The original review event remains immutable and must be superseded for source-memory replay by this erratum. The Shadowlands First Flower study remains valid only for its separate original context.
