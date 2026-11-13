# Dragonflight 200339 Looter occurrence cross-check — identity, denominator and gold-valuation gate

**Coordinator check (UTC):** 2026-11-13T14:06:04.096Z  
**Scope:** research-only independent review of the Dragonflight worker's already-recorded one original cumulative item-side source; not a new study, source export, current-game client test, or addon change. Queue T0041, with eligibility/context handoff.

## Recovered original numerical source and source identity

The Dragonflight worker added source records `dragonflight-20261113-1341-001` and `-002` in [its worker-owned evidence](../dragonflight/20261113T1341-looter-200339-and-material-side-crosschecks.jsonl). An **independent web-indexed read of the original [Scalesworn Cultist's Girdle item page](https://www.wowhead.com/item=200339/scalesworn-cultists-girdle)** confirmed these exact **same source-cumulative** claims:

| Input and output | Looter-reported sample | Reported material occurrences | Exact sample fraction | Displayed percentage |
| --- | ---: | ---: | ---: | ---: |
| Disenchant gear **200339** → Vibrant Shard **194124** | 55 item disenchants | 34 | 34/55 = 61.81818…% | 62% |
| Disenchant gear **200339** → Resonant Crystal **200113** | **the same** 55 item disenchants | 28 | 28/55 = 50.90909…% | 51% |

The original displays the heading "This item has been disenchanted 55 times." The [German localized item page](https://www.wowhead.com/de/item=200339/kultistengurt-der-eidschuppen) independently exposes the same 55 / 34 / 28 text **but is the same Wowhead Looter dataset, not a second sample**. The displayed item is a Warlock bound-on-pickup cloth waist piece added in Dragonflight patch 10.0.0, presently shown as scaled item-level **72**; **this does not identify the original Looter clients' build, exact bonus/itemLevel, profession skills or sampling dates**. [Vibrant Shard 194124 identity](https://www.wowhead.com/item=194124/vibrant-shard) and [Resonant Crystal 200113 identity](https://www.wowhead.com/item=200113/resonant-crystal) were compared against their material pages. No quality rank, enchantment modifier or alternative reward was inferred.

**Source interpretation:** The two fractions are sample **per-output occurrence** counts, neither conditional stack quantities nor unconditional mean material units per disenchant. In particular, 34 + 28 > 55, so the outputs **must not be treated as exclusive categories** in a mutually exclusive probability table; the source has no linked per-operation joint records. It cannot establish a completely empty disenchant, and the missing table rows cannot be interpreted as zero-output rolls. The item-side "1–2" rendering for Vibrant Shard is a displayed range/reference descriptor, not an extracted stack histogram or measured min/max. The worker correctly left `totalQuantity`, `histogram`, `minSeen`, `maxSeen` and profile fields null. **Do not turn occurrences into output units.**

## Research-to-gold disposition

- **Source-validated worker occurrence fields:** exactly one cumulative original source with 55 reported item operations and two per-material hit numerators, for this item/version-unknown context; not 110 independent casts. Do not append a copy in the manager evidence, do not aggregate the nine material-side Resonant Crystal indexed snapshots into it, and do not count English and German item pages twice.
- **Potentially usable but needs controlled admission:** 34/55 and 28/55 can support *sample-labeled occurrence fields* for a compatible source context, while expected stack units, positive-yield histograms, source epoch, enchant skill/specialization and exact 2026 Retail gear/itemLink eligibility remain unverified. A labeled conditional-yield-1 **assumption**, where allowed by the owner's explicit gap-only table policy, is not a measured conditional quantity and is never allowed to overwrite a usable measured expected output or become an observed cast.
- **Current gold decision remains unverified:** cannot compute measured mean output gold from these two hit counts alone; no real-character prices/eligibility or synthetic-price actual-addon valuation/rendering tests performed here. The item is BOP; input auction availability must not be presumed. More accessible indexed data does not, by itself, prove the production compiled ItemDB or tooltip consumes it.
- **High-value follow-up:** request original item-side stack quantities/0..N bins and captured build/bonuses/profession settings for **200339**; then let the separate three-pass implementation owner test one same-denominator, two-material fixture through actual offline economic engine + rendered tooltip at synthetic prices. Preserve uncertainty and source hash/cumulative date. Do not modify `implementation/usable-data-tooltips`.

## What was actually checked, and what was not

**Checked:** primary source item-side indexed table; German localization as **same-source** control; worker's two JSONL rows; two named material-ID pages; default-branch GitHub code search for item 200339 (no search hit, **not an exhaustive contents audit**); current research queue T0041 and coordinator/worker status. The independent lookup **confirms existing worker observations**, not new raw Looter receipts.  
**Not checked:** original Wowhead client per-cast logs, source temporal cohort boundaries, live WoW eligibility, statistical calibration, addon code execution, synthetic-price valuation, tooltip renderer, merge/PR/release. No new manager-collected completed casts, output quantities, 0-outcome observations, verified current gold recommendation, or other agent's evidence file was created or altered.
