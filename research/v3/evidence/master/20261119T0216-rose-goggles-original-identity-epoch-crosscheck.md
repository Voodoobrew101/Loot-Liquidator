# Seven historical "rose colored glasses" disenchants — exact-input identity remains unproven

**2026-11-19 UTC, manager research-only original-source/identity follow-up, legacy T0047/standing.** No new casts, no contemporary Retail processing result, no addon/estimator change and no import decision.

## Direct sources read

- Migrated original Allakhazam comment on [Classic Greater Nether Essence 11175](https://www.wowhead.com/classic/item=11175/greater-nether-essence) reports "rose colored glasses or whatever" with seven disenchant results; **three yielded Nether Essence and the other four Dream Dust**. The informal source provides no exact input link or item ID, date/build, character skill, per-hit stack size, item level or bonus variant.
- Worker preserves this one original study in [20261119T0148Z-rose-goggles-and-priority-source-audit.jsonl](../legacy/20261119T0148Z-rose-goggles-and-priority-source-audit.jsonl), rows `legacy-20261119-81001` and `81002`, with output IDs 11175/11176, completed operations 7 in each material row, and **material-specific occurrence hits** 3/4. One cohort = seven operations, **not fourteen**. `totalQuantity`, `histogram`, input item ID, patch and original event date remain null.
- Candidate [Rose Colored Goggles 10503, Classic](https://www.wowhead.com/classic/item=10503/rose-colored-goggles) is a green Engineering cloth head item, historically **item level 46**. The separate [Classic reference item model](https://legacyofwarcraft.com/db/classic/item/10503.html) lists Dream Dust **75%**, Greater Nether Essence **20%**, Large Radiant Shard **5%**, with **conditional 1–2** units for the first two. These are *reference model values*, **not source-measured rates for the seven-cast comment**; their fit does not identify the user's item. A separate [Deprecated Rose Colored Goggles 10596](https://www.wowhead.com/classic/item=10596/deprecated-rose-colored-goggles) also exists as an old named variant (unavailable to players), so string similarity is not a unique item identity test.
- [Current Retail 10503 item page](https://www.wowhead.com/item=10503/rose-colored-goggles) now presents item level **13**, not the Classic 46. No current Retail disenchant operation or eligibility for this variant was checked.

## Reproducible bounded check

Fetched exact research-worker file at blob `86dd6786f3199b4150a18cf379006c875de88baf`, JSON-parsed its lines and checked **16/16** scoped assertions: two rows share one original studyKey and seven completed disenchants; input ID, observed stack quantity, histogram and date are unknown; exact output IDs and material-specific occurrence-hit counts are 11175=3 and 11176=4. The observed **material occurrence fractions** are 3/7 and 4/7 *conditional on this unnamed original source's input*. They are **not measured quantities per cast**, and not a current Retail drop table.

As a sanity check only, the Classic reference categorical rates would produce **exactly** a 3-essence / 4-dust / zero-shard seven-cast sequence in any order with probability `C(7,3)*0.20^3*0.75^4 = 0.08859375`. This neither independently verifies the source's input item nor establishes the reference rates as observed. Do **not** use this calculated likelihood as addon chance/confidence.

## Disposition / next task

**Identity unknown, source event counts usable as historical evidence but not yet anchored to an exact Retail input.** Preserve worker rows append-only with `inputItemID:null`; do not fill 10503 or 10596 by name alone, do not convert the three/four *hit counts* into *output-unit totals*, do not multiply unknown per-hit yield by an assumed one, and do not present a present-character disenchant recommendation. If original account/post metadata or itemLink is recovered, then examine historical game mode/bonus and whether material totals/ranges were measured. Continue higher-impact current-release Midnight 237362 five-ore 0-inclusive output logs and 236761 ten-herb mill logs through their assigned workers; manager's separate 222833 Rare Resourcing selection gate remains higher priority for engineering.

**Validation boundary:** primary source text and item-page metadata independently reviewed; 16 in-process JSON assertions executed. No Python estimator, compiled ItemDB, Lua resolver/tooltip, CI-on-this-document, or live WoW test was run.
