# 2026-11-24 — Potion recycling identity follow-up (source scope only)

Parent review: `20261124T1002-goldsmith-extra-salvage-and-potion-recycle-source-review.md`. New verification is of item-rank alternatives and a specific previously archived row's unsupported rank, not another independent operation cohort.

## Retail item identities

| Named input | Rank 1 | Rank 2 |
|---|---:|---:|
| Silvermoon Health Potion | 241305 | 241304 |
| Enlightenment Tonic | 241339 | 241338 |

Retail rank labels and linked sibling pages: https://goldcap.gg/retail/us/items/241305 and https://goldcap.gg/retail/us/items/241304 ; https://goldcap.gg/retail/us/items/241339 and https://goldcap.gg/retail/us/items/241338 . Both pairs have descending ID order from rank 1 to rank 2. Do not infer rank from the numeric ordering. Independent item-name/effect/level corroboration: https://www.wowhead.com/item=241305/silvermoon-health-potion and https://www.wowhead.com/item=241304/silvermoon-health-potion (278 versus 295 ilvl); https://www.wowhead.com/item=241338/enlightenment-tonic (rank 2 identity); direct 241339 Wowhead page bot-blocked, rank 1 supported by the linked Retail listing. No prices retained. This is catalog identity evidence, not proof of historical input rank.

The existing worker record `midnight-20261031-1007` in `research/v3/evidence/midnight/2026-10-31T1012-alchemy-transmutes-recycling-and-exclusions.jsonl` assigns giveItemID 241304 to the alipica 123-potion/79-output report. Original https://www.wowhead.com/item=242651/stabilized-derivate#comments gives the potion name only. Its 1.93 per-craft figure is a reported approximate average, not proof of 41 independently recorded completed casts. Keep exact rank unknown; alternatives [241305,241304], do not duplicate the cohort across ranks or imply rank 2 from its prior ID. The prior record remains immutable; this is a source-scope correction review, not an assertion of a runtime defect or an automatic exchange override.

For davenrothz's May 13 2026 named groups (https://www.wowhead.com/item=242637/recycle-potions#comments), use candidate sets above, with null actual input ID and rank. Previously preserved quantities/operation counts unchanged, no additional cohort, and no inferred cast-level hits. The Goldsmith TourData inputs 241305 and 241339 in the previous manager review can now be identified as rank 1, but this does not reconcile bag-delta capture or turn those counters into operation yields.

Recipe 1233129 https://www.wowhead.com/spell=1233129/recycle-potions confirms nominal 3 potions plus 2 Oil of Heartwood per operation (oil item 247811 https://www.wowhead.com/item=247811/oil-of-heartwood). Wiki https://warcraft.wiki.gg/wiki/Recycle_Potions corroborates required oil, input batch, Alchemy skill and output binding. Stabilized Derivate 242651 is BoP; do not fabricate an AH price or ignore additional reagent cost. Neither historical source proves actual refunds or rank-dependent rates. Current main `3e814929ecffc2c2a282fddaead2012e5b44e9a9` tools/research_methods.py still associates Recycle with Engineering. No runtime/schema alteration. Current default-branch code search for davenrothz returned no match, and cutoff receipt source keys did not match the named author/item; complete durable-branch duplicate check is not established. No independent new numerical cohort or current actionable gold recommendation claimed.

Do not reopen the original 731-source verified catalogue or repeat unchanged pages. Next priority: exact event-linked current DE variant or published operation receipts, rather than further potion catalog lookups.
