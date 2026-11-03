# War Within worker — Batch 004 (2026-10-28)

**Master assignment:** `2026-10-28-batch004-war_within`, queue revision 6. The master assigned 6 TWW disenchant brackets followed by 29 Dragonflight overflow rows; all 35 were NEVER_EXAMINED at read time. Source branch head `0b166a107e0bb9f1e763a9e3025a42159eef54ae`; GameData blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`; coverage ledger `5b9f45544d9af7ac3dddbb4fde290abcf58bb99b`.

## Item/output review — 35/35 distinct

**TWW disenchant (6):** GameData.lua lines 613/618/623/628/633/638 contain pooled or borrowed estimates for Storm Dust (219946), Gleaming Shard (219949), Refulgent Crystal (219952). Sample claims are 12, 4, 3, 3, 1 and 1; blue and epic weapon rows explicitly borrow armor. Raw individual disenchant events, exact input gear IDs/ilvl, patch, skill and specialization are missing. `chance=1` and listed ranges cannot be independently treated as population probabilities or guaranteed hard bounds. The historical rarity-to-material families are qualitatively supported by [TWW enchanting overview](https://www.goldgoblin.net/berufe/verzauberkunst/verzauberkunst-von-khaz-algar/), but that does not verify the quantities.

**Dragonflight Khaz'gorite R3 (14):** GameData.lua line 2017 supplies 14 family anchors for input 190314, not independently measured rank-specific outputs. Low quantities derive from TSM; high quantities are inferred/modelled and cannot be promoted. The special Prismatic Ore (194545) row has low=0/high=0.03 with claimed specialization gating, not a universal measured zero. [Bugy's original prospecting report](https://www.wowhead.com/spell=374627/dragon-isles-prospecting) was already archived by the Midnight worker; its 100-ore versus 100-cast denominator remains unresolved, so no duplicate observation or fabricated output rank was added.

**Dragonflight Draconium R1 (15):** GameData.lua lines 1212–1226. Historical TSM `amountOfMats` is per input ore in the existing provenance and normalizes to per-five-ore expected units by multiplying by 5. If raw `matRate` and raw `amountOfMats` are incorrectly compared on one denominator, 15/15 violate E≥P×positiveMin. After converting E to five-ore equivalents, 0/15 violate the necessary bound. This is a **denominator warning**, not proof that TSM `matRate` is measured P(at least one). Original source patch, rank selection, skill, sample count and per-cast histograms remain unavailable. No output-quality rank can be valued three times.

Every row has independent P/min/max/E confidence in the attached 35-key CSV. All 35 have worst-field confidence 0, status **EXAMINED_INSUFFICIENT**. No numeric correction, ≥90 promotion, or current-Retail source substitution.

## Parallel numerical mechanics hypothesis (separate from 35 records)

**`tww-prospect-resourcefulness-savings`: UNVERIFIED, BLOCKED, numeric confidence 0.** [September 3 2024 Aqirite study](https://www.reddit.com/r/woweconomy/comments/1f83cnd) reports 1040 clicks, 5200 ore purchased, and reprocessing of Resourcefulness returns, but no exact saved ore count or measured stat. [October 14 2024 ranked Aqirite study](https://www.reddit.com/r/woweconomy/comments/1g350pq) reports 11000 R1 and 10000 R2 ore with refunded ore *not reprocessed*, but still no saved ore counts. [September 11 community explanation](https://www.reddit.com/r/woweconomy/comments/1fdvkmy) proposes a 30% base-return model; it is **not a controlled recipe-specific measurement**. [Algari Prospecting spell 434018](https://www.wowhead.com/spell=434018/algari-prospecting) verifies the nominal five-ore recipe.

No refund coefficient, universal stat slope, patch multiplier or output adjustment is approved. The proposed exact test uses R2 Aqirite 210934 on the same build, at least 500 actual casts per matched Resourcefulness cohort, full skill/spec/gear and recipe stat snapshots, zero-inclusive integer saved-ore histograms and inventory before/after each cast, then independent replication. Input cost is **5 minus observed mean ore saved per cast**, not extra gem output. The source-only archive preserves original reported values without inventing refunds.

## QA / handoff

- PASS: 35 distinct assigned keys
- PASS: 35 NEVER_EXAMINED at read
- PASS: 6 DE exact line matches
- PASS: 14 rank3 Khazgorite family rows
- PASS: 15 Draconium original TSM rows
- PASS: 15 TSM normalized necessary bounds
- PASS: Prismatic conditional gating not approved
- PASS: all 35 weakest field below 90
- PASS: numeric model fails closed
- PASS: no output EV double probability multiplication

Not run: full external JSON Schema validation, repository Node suites or in-game tests. No main, production Lua/TOC, shared master ledger, assignments or PROGRESS edits. Future shipped data remains single `itemdb.lua` only after independent master QA.

**Next exact targets:** Master review these 35 stable keys and update coverage only after acceptance. Obtain original per-cast TWW disenchant records with input IDs, confirm Khaz'gorite rank3 output ranks/talent gating, reconcile TSM matRate semantics and source build, and run matched TWW Resourcefulness refund trials. Master baseline 1259 never-examined records predates pending batch004 submissions; remaining count must be recomputed centrally. First-pass completion is not all-fields ≥90.
