# Manaforge Omega curio — ten new final-gear exchanges require a stage-identity HOLD

Reviewed: 2026-11-19 03:02 UTC. Task: T0027, source-to-action review. **Research-only**; no worker original edited, no addon or owner implementation branch edited.

## New conflict and gold-action impact

The newest War Within [worker evidence](../war-within/20261119T0222-manaforge-curio-druid-warlock-fixed-exchanges.jsonl) asserts ten *direct* 1 Hungering Void Curio (237602) → 1 finished Druid or Warlock armor exchanges at Acquirer Ba'theom, citing item pages whose "can be obtained" sections list that vendor and price. These ten finished armor IDs are **not direct vendor SKUs in the original staged token catalog**. That source describes where a player ultimately gets gear, not proof that the vendor bypasses the intermediate-token stage.

The [Acquirer Ba'theom Warcraft Wiki vendor catalog](https://warcraft.wiki.gg/wiki/Acquirer_Ba%27theom) explicitly states he sells tier *equipment tokens* and shows the **Dreadful Voidglass Contaminant** intermediate, at one curio each, as a vendor SKU. The [original Wowhead Manaforge curator account (June 23, 2025)](https://www.wowhead.com/news/roll-for-tertiary-stats-with-dimensius-omni-tokens-in-manaforge-omega-377408) states this season differs from the earlier directly formed-gear curio system: the vendor gives a token which is subsequently used to create a tier piece. The [Dreadful Voidglass Contaminant item page](https://warcraft.wiki.gg/wiki/Dreadful_Voidglass_Contaminant) describes a separate class-appropriate **Use** action. The [Vest of the Mother Eagle item page](https://warcraft.wiki.gg/wiki/Vest_of_the_Mother_Eagle) gives an *acquisition summary*, and is not a vendor-inventory SKU listing. Current live game behavior, class restrictions, bonus IDs, stock and difficulty variants still require client confirmation; this is a research-stage discrepancy, not live verification.

**All ten worker edges are real transitive reachability claims but are not verified direct one-step purchases.** Importing them as direct fixed exchanges would falsely skip the intermediate use action, potentially expose incorrect class/actions or double-count the same curio route alongside the existing curio → token → gear graph. Preserve each worker original as reference evidence and mark its *direct exchange* interpretation held; do not delete, silently rewrite, or claim ten new independent gold-relevant processing observations.

| Finished armor (destination ID) | Existing one-curio vendor token (intermediate ID) | Class | Verified graph interpretation |
| --- | ---: | --- | --- |
| 237685 | 237582 | Druid | 237602 → Mystic Voidglass Contaminant → 237685 |
| 237683 | 237586 | Druid | 237602 → Mystic Binding Agent → 237683 |
| 237682 | 237590 | Druid | 237602 → Mystic Foreboding Beaker → 237682 |
| 237681 | 237594 | Druid | 237602 → Mystic Silken Offering → 237681 |
| 237680 | 237598 | Druid | 237602 → Mystic Yearning Cursemark → 237680 |
| 237703 | 237581 | Warlock | 237602 → Dreadful Voidglass Contaminant → 237703 |
| 237701 | 237585 | Warlock | 237602 → Dreadful Binding Agent → 237701 |
| 237700 | 237589 | Warlock | 237602 → Dreadful Foreboding Beaker → 237700 |
| 237699 | 237593 | Warlock | 237602 → Dreadful Silken Offering → 237699 |
| 237698 | 237597 | Warlock | 237602 → Dreadful Yearning Cursemark → 237698 |

## Actual bounded verification

Fetched and directly compared **four immutable existing blobs**:
- Worker ten-edge JSONL `e0c28ba3ab8d454d81fac274ae2e64cdd9f1c4f9`.
- [October 31 original 20-token staged research catalog](../war-within/2026-10-31T2323-manaforge-omega-tier-tokens.jsonl) `278bfc1577b83147aed481927ff61576f45b695d`.
- [Owner's integration token ledger](../../../..//docs/usable-data-audit/token-ledger.json) `758f3d5e6ec3328827f2f654f53963eb8a6184a0` at `implementation/usable-data-tooltips`, head `3d667d053db587c91401cfed7ecc56862b8340c9`.
- [Earlier five Dreadful direct fixed vendor edges](../war-within/20261119T0026-tier-curio-exact-exchanges.jsonl) `64e8cf24343816c130d800b8e3fa71e1152ae449`.

**238/238 bounded JavaScript assertions passed** on the exact fetched data: worker row uniqueness/count/units, twenty unique immediate curio-to-token IDs (`237581..237600`), twenty token-to-class-gears, 65 unique downstream armor IDs, the owner's 85 total reachable IDs, `costsComplete:false`, and ten unique worker gear edges absent from direct SKUs but present at exactly one class-correct intermediate path each. Independent source text was compared as described above. The ten gear identities/paths were already in the October 31 catalog and owner ledger: **zero newly measured casts, probabilities, units per proc or new transitive gear destinations**.

No Python research estimator, actual Loot Liquidator synthetic-price ItemDB/tooltip renderer, Lua suite, GitHub final-head CI or live WoW test was run for this audit. This check cannot certify the vendor's current client behavior or universal Retail coverage.

## Scoped disposition

1. **HOLD** importing the ten new `type:exchange` rows as *direct curio→finished gear* runtime steps; preserve original files and label them alternative *acquisition summaries / indirect paths* pending source correction.
2. Deduplicated, source-verified **direct** 237602 → `237581..237600` one-curio fixed cost edges are the correct next evidence work, including the 15 already known intermediate SKUs not transcribed in the earlier five-edge file. War Within worker/reviewer owns any append-only correction; manager does not rewrite their files.
3. Keep the existing owner ledger `costsComplete:false` until per-difficulty/class access and cost graph are actually verified; then exercise exact multi-stage token valuation and tooltip at **synthetic** prices. No one-step fee duplication or selection of multiple alternatives.
4. Numeric research priority unchanged: current-release Umbral Tin 237362 (five-ore ranked prospect) and Tranquility Bloom 236761 (ten-herb mill), completed operations + material hits/0–N and skill/refund context. Existing RR conditional 222833 gap persists separately. PR Director alone handles integration.

