# T0027 — new Priest / Warrior curio vendor-stage gate (2026-11-19 05:04 UTC)

## Decision
**HOLD proposed direct `237602 Hungering Void Curio → finished Priest/Warrior Tier 34 gear` vendor edges.** The latest ten War Within worker `exchange` rows identify plausible final class gear and a one-curio acquisition path, but their item-side vendor acquisition descriptions do not independently establish that the *finished gear* appears as a direct NPC inventory SKU. In the existing original token catalog, `237602` buys one of **20** `237581–237600` intermediate tokens, and each intermediate token is **used** to create eligible class-specific finished gear. **A second direct-vendor path is not logically impossible, but requires independent exact SKU proof before admission.** Do not silently replace the already-supported two-step path with an unverified one-step action, nor count either as new numeric processing/drop evidence.

## Exact source and immutable crosschecks
- New worker original: [2026-11-19 04:26 Priest/Warrior exchanges](../war-within/2026-11-19T0426-priest-warrior-curio-fixed-exchanges.jsonl), blob `f1e4602e49b8a136db68e3883156d4b5838a6026`. Ten records claim `giveItemID:237602,giveCount:1` and `getCount:1` for finished gear.
- Original intermediate-token catalog: [Manaforge Omega 20-token catalog](../war-within/2026-10-31T2323-manaforge-omega-tier-tokens.jsonl), blob `278bfc1577b83147aed481927ff61576f45b695d`. The token `237602` vendor list contains 20 intermediate options. Each has `howRedeemed:use` and class-specific reward IDs.
- Owner's three-pass read-only [token ledger](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/usable-data-tooltips/docs/usable-data-audit/token-ledger.json), blob `758f3d5e6ec3328827f2f654f53963eb8a6184a0`: `237602` record `redemption:exchange`, `costsComplete:false`, 85 distinct reachable reward IDs (20 first-stage intermediates plus 65 final gear). Ledger was **not modified**.

| Finished item ID | Class | Already cataloged intermediate token ID |
| --- | --- | --- |
| 237712 | Priest | 237583 |
| 237710 | Priest | 237587 |
| 237709 | Priest | 237591 |
| 237708 | Priest | 237595 |
| 237707 | Priest | 237599 |
| 237613 | Warrior | 237584 |
| 237611 | Warrior | 237588 |
| 237610 | Warrior | 237592 |
| 237609 | Warrior | 237596 |
| 237608 | Warrior | 237600 |

**Completed bounded validation:** 75/75 synchronous JavaScript assertions passed against the three exact GitHub blobs fetched through the connected GitHub reader. Asserted new source record count=10, first-stage catalog count=20, curio catalog exists, each new record is an exchange of one curio for one claimed finished item, exactly one matching earlier intermediate-token reward path per finished item, expected class on that path, intermediate included in curio catalog, each finished item already in owner's reward ledger, exactly one `237602` ledger entry, and its `costsComplete:false`. There are 65 unique original downstream finished gear IDs. Checks establish **existing catalog coverage and source-stage ambiguity only**; no independent real-vendor catalog inspection, trade execution, Python estimator, priced synthetic ItemDB/tooltip evaluation, native Lua, live WoW or new gold decision was performed.

## Next review, ownership and release guard
1. **War Within worker / isolated reviewer branch:** obtain exact original Acquirer Ba'theom NPC `sells` SKU listing and distinguish vendor-sold intermediate token IDs from item-page acquisition summaries. Correct or annotate only the new worker's ten rows with an append-only correction if warranted. Preserve all ten original records and original URLs; do not fabricate vendor paths, prices, bonus IDs or alternative rank.
2. **Existing three-pass owner implementation:** keep the immutable `4df9ae8` reference snapshot and current `237602` two-stage rewards, `costsComplete:false`, class restrictions and any separate source-backed intermediate-token costs. No addon snapshot/import PR and no branch overwrite by research manager.
3. **Other workers:** continue independently on current Midnight per-output complete-operation 237362/236761 sample logs and TWW 222833 Rare Resourcing true-state prerequisite; source identity, output quantity, occurrence chance and resource input savings must remain separate.

This is a **new validation of 2026-11-19 04:26 Priest/Warrior records**, not a repeat/acknowledgment of the earlier Mage/Paladin or Druid/Warlock holds. Research branch before manager write: `02d1d3daba15492ffa1389d9ecdf805d2c2bf0fb`; existing exact-head [Verify five-agent completion workflow](https://github.com/Voodoobrew101/Loot-Liquidator/actions/runs/44460380870) succeeded on that pre-manager commit. No claim about CI after this evidence/manager checkpoint. `main` `bddd2c160f9f361647c4846bb42f57135045659c`, owner's `implementation/usable-data-tooltips` `3d667d053db587c91401cfed7ecc56862b8340c9` were read only. PR #22/#23 are closed unmerged, #77/#75/#74 open. No merge, release or new schedules.
