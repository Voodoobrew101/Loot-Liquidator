# T0041/T0046 — five newly indexed Dragonflight Looter cohorts: output stack-display intervals, source identity and overlap gate

**Coordinator source check (UTC):** 2026-11-14 01:04. **Research-only evidence audit; no new player casts, measured material means, gold decisions, synthetic-price renderer, or live-WoW verification.**

## Input records, independent source readback and original interpretation

Parsed all 10 rows from the Dragonflight worker's append-only [2026-11-14 00:43Z file](../dragonflight/20261114T0043-five-unindexed-df-gear-looter-counts.jsonl) (blob `561d67a2469ae7eb0fbb3de1c769139772cf931a`). Five different **item-side cumulative source tables** report **120 item operations total**, not ten independent studies. Re-read the following original Wowhead indexed item tables and confirmed their displayed counts. Exact reagent ID/name mappings are separately supported by [Chromatic Dust 194123](https://www.wowhead.com/item=194123/chromatic-dust), [Vibrant Shard 194124](https://www.wowhead.com/item=194124/vibrant-shard) and [Resonant Crystal 200113](https://www.wowhead.com/item=200113/resonant-crystal); the output link IDs inside each dynamic Looter table have **not** been recovered from raw HTML.

| Source item (exact ID) | Displayed operations | Material occurrence rows | Additional **source-listed stack interval** (new field-level context, NOT observed histogram) |
| --- | ---: | --- | --- |
| [Keratin-Reinforced Boots 200272](https://www.wowhead.com/item=200272/keratin-reinforced-boots) | 63 | 194123 dust 59/63; 194124 shard 4/63 | Chromatic Dust **1–3**; Vibrant Shard **1–2** |
| [Palms of the Waking Fist 200362](https://www.wowhead.com/item=200362/palms-of-the-waking-fist) | 20 | 200113 crystal 14/20; 194124 shard 10/20 | Vibrant Shard **1–2**; crystal no displayed interval |
| [Girdle of the Waking Fist 200366](https://www.wowhead.com/ptr/item=200366/girdle-of-the-waking-fist) | 13 | 194124 shard 8/13; 200113 crystal 7/13 | Vibrant Shard **1–2**; crystal no displayed interval |
| [Cuffs of the Waking Fist 200367](https://www.wowhead.com/item=200367/cuffs-of-the-waking-fist) | 14 | 194124 shard 10/14; 200113 crystal 5/14 | Vibrant Shard **1–2**; crystal no displayed interval |
| [Drape of the Waking Fist 200368](https://www.wowhead.com/ptr/item=200368/drape-of-the-waking-fist) | 10 | 200113 crystal 7/10; 194124 shard 3/10 | Vibrant Shard **1–2**; crystal no displayed interval |

**Newly corroborated supported display context:** six source-listed intervals for these ten already recorded occurrence rows (dust once, shard five times). The worker's `minSeen/maxSeen` and `histogram` are null; do **not** mutate them into observed extrema, histogram bins, or measured means. These source intervals may be carried as explicitly labeled *reference display ranges* via an authorized reviewed importer if applicable. No newly discovered sample, cast, or independently verified zero-inclusive histogram.

## Proven lower-bound arithmetic, NOT a proposed measured valuation

For a valid source population and an output occurring in `h` of `n` operations, each *positive* result gives at least one unit, so `h/n` is an arithmetic lower bound for **source-reported unconditional units per operation**. It is neither a measured average nor a current-Retail estimate; patch, gear variant, skill, joint output events and independent cohort provenance remain unknown. For the six source-listed positive intervals, the corresponding *conditional* source-arithmetic bounds are:

- Boots dust **59/63 to 177/63** units per reported operation, boots shard **4/63 to 8/63**.
- Palms shard **10/20 to 20/20**; Girdle shard **8/13 to 16/13**; Cuffs shard **10/14 to 20/14**; Drape shard **3/10 to 6/10**.

These are **bounds**, not a midpoint, probability distribution, calibrated confidence score or importable estimated E without eligibility, source scope and evidence-policy admission. The four crystal rows have no source-stated upper stack limit. The six valid-looking ranges are display information even if an independent estimator cannot yet price a current character.

Across the **three** Waking Fist inputs 200362, 200366 and 200367, per-material hit sums are respectively **24 > 20**, **15 > 13**, and **15 > 14**; if the original item-side denominator really measures the same 20/13/14 operations, there must have been **at least 4, 2 and 1** two-material co-appearances (at least **7** combined), rather than mutually exclusive outcomes. This is the inclusion–exclusion *lower bound*, **not** raw observed joint casts. The remaining two sources have hit sums equal to the denominator, which does not establish that every reported event yielded exactly one material or prove no zero-output event. Never infer zeros from a sum-to-denominator coincidence.

## Source-lineage and version warning

[200366 on PTR 12.1.5](https://www.wowhead.com/ptr-2/item=200366/girdle-of-the-waking-fist) and [PTR 12.1.7](https://www.wowhead.com/ptr/item=200366/girdle-of-the-waking-fist) both show the same **13** source operations and **8/7** counts. [200368 PTR](https://www.wowhead.com/ptr/item=200368/drape-of-the-waking-fist) and its [item page with selected ilvl395 bonus URL](https://www.wowhead.com/item=200368/drape-of-the-waking-fist?bonus=6652%3A8943%3A9344%3A1478%3A8767&class=10&ilvl=395&spec=269) show the same **10** operations and **7/3** counts. A page labeled PTR or a user-selected bonus/ilvl preview is **not** a dated original PTR experimental cohort or an authenticated at-disenchant itemLink. Do **not** duplicate these rows by page URL, treat chosen ilvl395 as the event version, or merge the output appearances into exclusive probabilities.

## Owner-policy disposition and next action

**Source status:** existing usable-but-unadmitted original reference *display interval* context, linked to 10 already worker-recorded source lines; not new independent numerical cohorts. **Missing:** actual positive-stack histograms/totals, full per-operation joint ledger, original date/build, actual gear bonus and eligibility, skill/spec and a current character. **Price/context status:** not examined; source-dependent historical bounded context must not be reported as present-character gold EV. The owner permits defensible provisional yield-1 estimates in restricted cases, but this audit does not certify that condition for any of the five item profiles.

**Next:** Have the Dragonflight worker continue original-event and rank/skill/patch searches within its own file ownership; show the three-pass addon/import maintainer the six source-display intervals and same-cohort mirrored pages for optional *disjoint* integration review. Do not overwrite its integration branch, append-only originals, worker statuses, queue, or existing research-only PRs. Current Midnight T0005/T0039/T0045 true-rank completed operation and refund ledgers still outrank these legacy tooltip-only fields for new supported gold decisions.
