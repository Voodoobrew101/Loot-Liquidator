# Source-original Black Mageweave Headband / Nightscape Pants unit-and-zero audit

Checked UTC: 2026-11-18T20:10:40.418Z
Branch: `implementation/five-agent-completion`. Scope: **research-only historical original-source validation**. This is not a current Retail baseline, addon snapshot import, actual priced valuation or live-character/tooltip test.

## Newly reported original cohorts, one count per source operation

Read the Legacy worker's append-only [18 evidence rows](../legacy/2026-11-18T1943-mageweave-headband-nightscape-primary.jsonl) from exact blob `a53cb4da36753b04a05d0f1172581babdf345634`. Independently cross-checked the numeric assertions with the original author comments on [Black Mageweave Headband](https://www.wowhead.com/item=10024/black-mageweave-headband), [Greater Nether Essence](https://www.wowhead.com/item=11175/greater-nether-essence) and its [historical MoP Classic mirror](https://www.wowhead.com/mop-classic/item=11175/greater-nether-essence). These mirrored postings are not new studies and are **not evidence of Retail Midnight yields**.

| Original source author / independent subcohort | Input | Source-stated completed disenchants | Explicit output totals, in units | Explicit per-material zero observations |
| --- | --- | ---: | --- | --- |
| Headband commenter 324456 | 10024 | 40 | Dream Dust 11176=40; Greater Nether Essence 11175=15; Large Radiant Shard 11178=3 | none |
| Headband commenter 500383 | 10024 | 15 | Dust=16; Greater essence=4; shard=2 | none |
| Greater-essence commenter Meowie | 10024 | 30 | Dust=40; greater essence=5 | none |
| Greater-essence commenter 874940 | 10024 | 30 | Dust=38; greater essence=8 | none |
| Greater-essence commenter 539433 | 10024 | 9 | Dust=10; greater essence=6 | none |
| Greater-essence commenter 405835 | 10024 | 27 | Lesser Nether Essence 11174=0; Greater Nether Essence 11175=0 | 27 for each named essence, **not** 27 globally empty DE casts |
| Archived Thottbot Nightscape Pants commenter | 8193 | 10 | Greater essence=10; Dust=4 | none |
| Greater-essence commenter Fanderay, first subgroup | 10024 | 20 | Dust-only report, no exact dust total | 20 Greater Nether Essence absences |
| Same Fanderay, final *disjoint* subgroup | 10024 | 10 | Greater essence=7 | none |

**Unit separation:** 18 output rows represent **nine distinct source cohorts/subcohorts** and **191 total reported completed operations counted once by source cohort** (40+15+30+30+9+27+10+20+10), not 18 independent studies or a per-output sum of disenchants. Across those operations, **47 explicit Greater Nether Essence zero observations** (27+20) and **27 explicit Lesser Nether Essence zero observations** are distinct *material-specific* statements, not 74 empty-result operations. Positive output quantities are material *units*, not `castsWithDrop` or a chance; leave hit counts and positive-stack 0-N histograms unknown. Explicit all-zero material observations justify only `histogram={"0":N}` for the *named material*; do not set total disenchant zero yield or infer other outputs.

**Version and eligibility gate:** Historical comments predate the current source context; the same item ID 10024 has scaled modern item variants. Neither contemporaneous bonus/item links, disenchant-time build/patch, profession skill/spec, nor new Retail live yields were established. Do not pool these historical quantities into a current Retail gold recommendation without an independently supported compatibility/eligibility decision. Avoid conflating [MoP Classic mirrors](https://www.wowhead.com/mop-classic/item=11175/greater-nether-essence) with current Retail data.

**Bounded validation actually executed:** 159/159 in-process JavaScript assertions **passed**, matching all 18 original-record identities, nine study keys, source-stated completed quantities, input/output item IDs, source totals, unknown hit/rank/percentage values, material-specific zero histograms and 191-operation once-only tally. The initial assertion harness incorrectly treated explicit all-zero material bins as unknown histograms; corrected the harness and reran successfully, without editing worker originals. No native Lua, Python estimator, compiled ItemDB, synthetic-price valuation/renderer, game client or GitHub CI was run by this audit. No new current-Retail EV/chance or verified actionable gold decision.

**Original-source deduplication follow-up:** A separate old Thottbot remark about six Nightscape Pants (3 dust, 6 essence, 2 radiant shards) is **only a candidate lead**. Check original contributor/source identity and existing complete research originals before any new row: it may be an overlapping or already transcribed comment. Do not treat as independent today.

**Adjacent newly reported source-identity blockers:** [Wanderer's Projectile Accelerator 238002 PTR](https://www.wowhead.com/ptr/item=238002/wanderers-projectile-accelerator) has one pooled 37-operation Looter table with three same-name Refulgent Crystal rows (15/13/5 occurrences) of unresolved **per-row item links and quality ranks**, plus Gleaming Shard (3). Do not guess R1/R2/R3 mappings, material stack totals, probabilities or globally zero casts. [Fleeting Arcane Manifestation 227659](https://www.wowhead.com/item=227659/fleeting-arcane-manifestation) is a knowledge consumable with “Cannot be destroyed” metadata but an ambiguous item-side Looter disenchant table. This contradiction requires input/source-direction resolution, **not** a new 14-cast yield sample. Both findings were recorded independently by the War Within worker; this manager audit does not duplicate those originals.

**Priority:** seek a new *current Retail* source-original full item/bonus-link, patch, skill/spec and completed per-cast 0–N outcome ledger for high-impact Midnight Umbral Tin 237362 (five-ore prospect) and Tranquility Bloom 236761 (ten-herb mill). Verify TWW 238002 exact output item hrefs/ranks if original HTML/event export becomes available. Keep unknown chance/quality, refunds, conditional output eligibility and input savings separate.
