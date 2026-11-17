# New TBC scaled-gear disenchant eligibility: original source versus frozen runtime flags

Research-manager-only source-to-runtime identity gate 2026-11-17T00:03:55.541Z. Task T0047 and legacy scaling eligibility. **No new numeric rates, gold decisions, or live WoW verification.**

## Exact new worker identities and original-source context

The [new legacy original worker file](https://github.com/Voodoobrew101/Loot-Liquidator/blob/f328f990ee96ed2e92e8014b7561fb52153f36bf/research/v3/evidence/legacy/2026-11-16T2351-tbc-scaled-gear-no-de-identity.jsonl) reports eleven distinct scaled old-Outland item IDs from WoWDB quick-info, each with "Cannot be disenchanted". It does **not** report an actual player disenchant attempt, character context, bonus/variant, game build, measured output, casts, hits, or a current Retail client API eligibility result. No earlier Looter cohort is made a new study.

WoWDB is presented in a LIVE tab. This manager independently reopened the source page and confirmed the title/item-level 31/32 and quick-info wording for **24647 Astralaan Robe**, **32473 Tankatronic Goggles** and **37749 Shocking Claws**. The other eight remain worker-sourced, not freshly independently page-verified by the manager.

## Frozen source-to-runtime crosscheck, not a client test

Static text reads on production `main` **5dd5aa2f7f05656e7580ea744f657209db59a195**:
- `database/sources/DB2Restrictions.lua` blob `e03c7b0c302b1ef718b62b7de9c364e2c0b6ea03`, declared Retail DB2 build **12.1.7.70493**: **21061** distinct NO_DISENCHANT item IDs in its generated list.
- `database/research-v3-baselines.lua` blob `06cf888f4abf4419d3ee7f95ab96b04a902c414d`: **229** distinct source-pinned `noDisenchant` item IDs, compiled from the immutable earlier research snapshot, not the current worker branch.
- `LootLiquidator/Core.lua` blob `cb859674ed2d86b02214d9aca5673b72af31cc7e`: dynamic native, item-database and displayed-tooltip restriction checks are implemented. This static check cannot determine whether any particular in-client tooltip/flag loads or an action recommendation is made.

| Exact item ID | Name | Evidence gate | In pinned DB2 NO_DE | In pinned v3 noDE |
| --- | --- | --- | --- | --- |
| 24647 | Astralaan Robe | Reopened WoWDB LIVE quick-info | Absent | Absent |
| 32662 | Flaming Quartz Staff | Worker source row (not independently reopened) | Absent | Absent |
| 32473 | Tankatronic Goggles | Reopened WoWDB LIVE quick-info | Absent | Absent |
| 29371 | Nexus-Claw | Worker source row (not independently reopened) | Absent | Absent |
| 31204 | The Gunblade | Worker source row (not independently reopened) | Absent | Absent |
| 32479 | Wonderheal XT40 Shades | Worker source row (not independently reopened) | Absent | Absent |
| 25656 | Felscale Pants | Worker source row (not independently reopened) | Absent | Absent |
| 29506 | Gloves of the Living Touch | Worker source row (not independently reopened) | Absent | Absent |
| 31190 | The Dreamer's Shoulderpads | Worker source row (not independently reopened) | Absent | Absent |
| 31308 | The Bringer of Death | Worker source row (not independently reopened) | Absent | Absent |
| 37749 | Shocking Claws | Reopened WoWDB LIVE quick-info | Absent | Absent |

All **11/11** exact worker IDs are absent from **both** frozen no-DE lists. This means the newly sourced **eligibility flags are usable-but-not-imported at the two static flag layers**, not that a live-game disenchant is offered, or that the historical-model value is safe. The current native tooltip restriction can still block an item. The DB2 snapshot and contemporary WoWDB may differ by build/bonus/representation; neither a database quick-info label nor old Looter is an observed current-game failure/success. In particular, old **24995 Warmaul Legplates** is an *existing* S23 historic-model-versus-catalog conflict and is **not** counted as one of these eleven new discoveries.

The manager executed **34/34 bounded static JS assertions** (11 original item-ID/source-form checks, 11 exact DB2 exclusions, 11 exact pinned v3 exclusions, one runtime-gate presence check), with zero failures, plus **3/3 manually reopened WoWDB page wordings**. This was **not** a full Lua compiler/build, synthetic-price economic decision/tooltip render, GitHub Actions test, or live client test. No conditional/yield/chance/numeric columns were invented.

## Admission/decision and next action

**Disposition:** preserve the eleven worker original classifications verbatim and flag this as a *source-epoch/eligibility conflict with a known static import gap*. A reviewed future snapshot may transport correctly scoped no-DE records, but a broad auto-block without reconciling the current Retail item variant/build would change gold behavior on imperfect evidence. Request exact `itemLink` with bonus/real ilvl, in-client `C_Item` or visible tooltip restriction and successful/blocked Enchanting attempt where legal. Confirm source patch before allowing historical TBC group-value modeling to compete with vendor. Keep current Midnight T0039/T0005 original per-operation rank/refund/histogram evidence as highest numerical priority; do not redirect workers to duplicate old studies.

Protected owner three-pass branch, `main`, worker originals, `queue`, `flags`, schedules, PRs, merges and releases were not modified. Research source commit verified prewrite: `f328f990ee96ed2e92e8014b7561fb52153f36bf`.
