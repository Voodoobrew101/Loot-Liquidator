# Dragonflight latest epic-gear Looter cohort numerical integrity check

**Checked at UTC:** 2026-11-08T23:01:22.420Z

**Source:** Worker-owned original transcription `research/v3/evidence/dragonflight/2026-11-08T2239-five-original-looter-item-cohorts.jsonl` (records dragonflight-20261108-223001 through -223010). This is a **manager arithmetic consistency/source readback**, not five new independently collected studies. Do not alter or re-count the worker's original files.

Directly inspected the **Retail** Wowhead item-side Looter output tables for all five linked base items, and matched each current indexed row to the worker transcription:
- https://www.wowhead.com/item=207195/shroud-of-the-risen-nightmare
- https://www.wowhead.com/item=207196/vambraces-of-the-risen-nightmare
- https://www.wowhead.com/item=207197/seal-of-the-risen-nightmare
- https://www.wowhead.com/item=207202/graveboots-of-the-risen-nightmare
- https://www.wowhead.com/item=207283/poulaines-of-lunar-communion

| Base input item | Looter reported disenchants N | Vibrant Shard 194124 occurrence hits A | Resonant Crystal 200113 occurrence hits B | A+B | Excess A+B-N |
| --- | ---: | ---: | ---: | ---: | ---: |
| 207195 | 27 | 14 | 15 | 29 | 2 |
| 207196 | 21 | 14 | 13 | 27 | 6 |
| 207197 | 28 | 15 | 14 | 29 | 1 |
| 207202 | 36 | 21 | 19 | 40 | 4 |
| 207283 | 62 | 44 | 36 | 80 | 18 |
| **Across different input items (descriptive totals only)** | **174** | **108** | **97** | **205** | **31** |

**Exact new numerical diagnostic:** Each of the five item-side tables has a sum of two output-occurrence row counts **greater than** the reported operation denominator. If *and only if* both rows count unique operations within the same fully enumerated N-operation cohort, basic inclusion-exclusion requires at least `max(0,A+B-N)` operations with both material types, i.e. respective lower bounds **2, 6, 1, 4, 18**; sum **31** across five **different** inputs. These are **conditional mathematical bounds**, NOT observed joint outcomes, material unit totals, or independent cast observations. If the Looter site mixes sampling snapshots or denominator definitions, even the same-operation inference is not reliable. Never treat A and B as mutually exclusive outcomes or sum their counts as independent casts.

Verified source readback of the five item-side tables and 10 numerator/denominator tuples; these were already transcribed by the worker, so **net-new original numerical studies = 0**. Their display of Vibrant Shard `1–2` is **not** a measured per-cast histogram; quantity totals remain unknown. No current patch/bonus/skill/specialization, original collection epoch, item variant, output rank, or current real-character DE eligibility was verified. These historical pooled Looter tables do not validate present Retail gold EV.

**Classification:** Original-source numerical consistency / potentially multi-output result model, not missing market prices, missing source coverage or a confirmed current-game runtime bug. If a future estimator assumes a single mutually exclusive shard-or-crystal outcome, that assumption conflicts with the row-count structure under a shared denominator. Keep co-output/overlap unknown pending an original cast-level export or published source semantics. A synthetic-price actual-engine check would be required by the protected integration owner before declaring any tooltip defect.

**Next priority:** Ask the Dragonflight worker, within existing T0041/T0046/T0020 research scope and ownership, to seek independent cast-level co-output joint observations or original epoch/bonus/skill information, not another cumulative scrape of these five pages. Separately test whether historical pooled Looter input cohorts enter any current-character recommendations when eligibility or patch is unknown; integration owner only. Preserve PR Director authority, research-only branch, and immutable originals.
