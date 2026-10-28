# First-pass source research — 34 distinct records (2026-10-28)

## Source-of-truth checkpoint
- `main/GameData.lua` blob SHA `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`, `main/StatYieldProfiles.lua` SHA `1d80df8304acaa75a5b507089ef163696381b2ff`, current `main/LootLiquidator.toc` still ships GameData. Original v0.9.70 ZIP at the old main path gives GitHub 404; extracted source was read. No addon changes.
- Re-read live `research/PROGRESS.md`, full `ITEMDB_CREATION_PROMPT.md` v1.1, mechanics/API registries, evidence schema and observation(s), old confidence and anomaly ledgers, previous tests and Issue #2. Future file name is **lowercase itemdb.lua**, one evidence-backed condition-specific baseline, not mandatory low/high tables.
- Previous 12 Northrend TSM anomalies and eight Midnight milling overlays were already audited. **This run first-pass examined 28 OTHER anomaly output rows and six additional previously unexamined Felslate uncommon gem rows = 34 unique record keys**.

## Record review and external sources

### Pandaria: 12 Trillium rare-gem rows — IDs 72094/72103, six outputs per ore
- Main raw TSM each: P proxy 0.16, conditional 1..1, E=(0.0341 per ore x5)=0.1705 per five ore. Consistency bound if p is measured occurrence would be 0.16, so deviation +0.0105 (+6.5625% vs 0.16).
- Historical Wowhead item comment for White Trillium describes **approximately 17% rare gem drop rate for EACH of six gems**, and explicitly prefers Black/White Trillium to Ghost Iron; see https://www.wowhead.com/item=72103/white-trillium-ore and https://www.wowhead.com/item=72094/black-trillium-ore . It does not provide individual five-ore cast outcomes, raw sample n, or game build. Pandaria guide establishes six gem families and that Black/White Trillium are prospectable: https://www.wowhead.com/guide/mists-of-pandaria-jewelcrafting-overview-1638 .
- A source ~17% is broadly closer to TSM E=0.1705 than to p=0.16, but is NOT independent proof the E equals the occurrence rate (p and E are separate definitions). Preserve all raw fields and a **labelled ~17% historical display proxy**; no 2026 Retail numeric substitution and no precise conditional min/max claim.

### Legion: 12 Felslate rows — input 123919, rare 130178..130183 and uncommon 130172..130177
- Source: https://www.wowhead.com/guide/legion-jewelcrafting , historical player comment by Deckven, **3,200 Felslate Ore Mass Prospected**. The commenter states quantities but no exact number of actual Mass Prospect recipe casts. Normalize only to comparable `3200/5=640` five-ore **equivalents**, not “640 observed individual casts.” Unknown patch/skill/gear, no per-cast histogram.
- **Rare gem totals and historical E per five ore-equivalent**: Furystone 130178 (17, 0.0265625), Eye of Prophecy 130179 (19, 0.0296875), Dawnlight 130180 (15, 0.0234375), Pandemonite 130181 (16, 0.025), Maelstrom Sapphire 130182 (24, 0.0375), Shadowruby 130183 (25, 0.0390625).
- **Uncommon totals and E**: Sangrite 130172 (90, 0.140625), Deep Amber 130173 (105, 0.1640625), Azsunite 130174 (168, 0.2625), Chaotic Spinel 130175 (67, 0.1046875), Skystone 130176 (137, 0.2140625), Queen's Opal 130177 (123, 0.1921875). The comment additionally reports **742 Gem Chips** without colored chip item IDs; archived as an unmapped aggregate, no fictitious output ID.
- Six rare old TSM rows `matRate=.01,min=2,max=5,amountOfMats=.002` imply E=.010 per five ore, below .01*2=.020. Historical independent rare E range .0234375–.0390625 **is not current-patch proof** but supplies much better historical comparator.
- Six uncommon old TSM rows imply E=.175 each per five ore; independent historical totals show output-specific differences; do not force uniform .175, apply one uniform slider or infer occurrences from totals.
- Archived source in `research/evidence/observations/legion-felslate-3200ore-community.jsonl`; separate numerator, inferred denominator, unknown actual cast count, source date unknown. The observation schema was amended **only for aggregate source studies** so `completedOperations=null` is honest.

### Dragonflight: nine Draconium diamond-quality source rows — IDs 189143/188658/190311 x 192869/192870/192871
- Retail client-derived quality identity reference: https://thewowdb.com/item/draconium-ore-189143/ (Draconium input ranks 1=189143, 2=188658, 3=190311). The output IDs refer to Illimited Diamond quality variants (https://www.wowhead.com/item=192870/illimited-diamond).
- Legacy TSM: p=.0142; per-input amount=.0028, E=.014 per five ore; conditional min 1 max2. The difference `p*min - E = .0002`, only **1.40845% of p**; this is a **minor precision/semantics flag**, not proof the item is impossible or should be economically quarantined.
- Same Wowhead page includes commenter Bugy's *two separate 2,000-ore Draconium cohort rows*, Illimited Diamond family rates 0.0015 and 0.004 units per ore => independently **3 and 8 family diamonds** over 400 five-ore equivalents each, means 0.0075 and 0.02 family units per five ore. **No explicit input rank or output-quality ID split per cohort**. Do not distribute those totals to three quality-ranked outputs or merge cohorts into a current Retail rank-specific E.
- Stored raw lead with blocked fields in `research/evidence/leads/dragonflight-draconium-illimited-diamond-two-2000ore-cohorts.json`. Do not treat a family aggregate as nine independent sample results.

### Dragonflight legacy milling: one unresolved source row — 200061 -> 190322
- In old TSM table, p=.002 and on-hit [1,1], per-input amount=.001, derived E=.005 for an **assumed** five-herb operation. E exceeds p*max=.002 by 2.5x. **Exact 200061 input item identity, eligibility and source operation batch were not corroborated in available indexed WoW sources**. Cannot safely assert it is a valid current milling input. Retain source tuple, mark the conversion eligibility and numeric model BLOCKED until checked using a client item database and recipe eligibility plus raw output evidence.
- Other raw output IDs from this same unverified input must not be invented or promoted. No output changes or deletions to production.

## Independent per-field evidence and test disposition
- `research/ledger/first-pass-tsm-other-28-field-evidence-2026-10-28.csv` preserves original 28 source records, literal p,min,max,E, original field evidence scores, raw TSM units, independent historical comparisons and blockers.
- `research/ledger/first-pass-felslate-uncommon-six-2026-10-28.csv` adds six output-level historical means with the exact source link and denominator.
- `research/ledger/first-pass-34-critical-field-scores-2026-10-28.csv` adds current-Retail-applicability scores for **all four fields independently** (chance,min,max,E), plus ID/condition and min-record score. Scores in this new ledger are provisional and do **NOT** overwrite or inflate original source ledgers. A 90 evidence score is not a 90% statistical accuracy claim.
- **34/34 new reviews below 70**, score 0 on 13 and 12 on 21 (weakest material field). 13 means 12 Felslate sample-backed outputs with no occurrence histogram plus one unresolved milling input; lower numeric score reflects insufficient current-field evidence, not a negative finding about valid item identity.
- **Original 1,256 output source rows**: >=90=0, 70–89=0, below70=1,256, minimum=0. No numeric GameData edit, and no existing confidence score was promoted; this batch added historical documented E values, not verified modern replacement quantities.

## Reproducible QA / known failures
- `research/tests/test_first_pass_tsm_other28.js` was executed against live-fetched `main/GameData.lua`, current coverage/field ledgers, and saved JSONL; 27 checks passed / 0 failed after fixing an initial test newline parser. Earlier 23 checks passed, then the test was expanded to include all 12 Felslate gems. The one transient parser regression was fixed and read-back verified.
- Checks include source ID and batch invariants, distinct input quality IDs, 28+6 unique keys, 1,737-row coverage uniqueness, six-batch math, preservation of unknown actual Mass Prospect cast count, unknown per-cast probability/ranges, and retention of 742 chip units with no invented ID.
- This is **STATIC SOURCE QA**, not a game-client test, not a complete Lua AST inventory, and not a verified current 2026 Retail drop table. The entire `GameData.lua` field universe beyond known input/output/profile/overlay rows is still not fully independently inventoried.
- No numerical patch/stat/quality transforms proved. Felslate historical -> 2026 Retail: BLOCKED. Dragonflight two family cohorts -> individual quality IDs: BLOCKED. Legacy 200061 source -> valid modern mill: BLOCKED. No generic slider formula accepted.

## Deduplicated first-pass coverage and throughput
- `research/ledger/first-pass-coverage-2026-10-28.csv` inventories **1,737 stable source-row/profile keys** without duplicate keys: 1,001 main processing output source rows +255 supplemental output rows +92 runtime overlays +389 input/condition source profiles. This is an explicitly incomplete inventory of EVERY nonprocessing field in `GameData.lua`, and includes distinct source rows with overlapping unique live relationships.
- Cumulative strictly material first-pass: **54**: previous Midnight milling 8, previous Cobalt/Titanium 12, this run 34. **1,683 never examined**, 41 examined but insufficient, 13 blocked, 0 independently corrected current-Patch, 0 >=90.
- Three recent record-review runs: 8,12,34 NEW distinct; mean `(8+12+34)/3=18` distinct per run. At *one hourly run* per session, the known remaining 1683 source keys would require about **94 hourly runs (~3.9 days)** *at the same sustained rate*, solely for FIRST PASS of the **current partial source-row universe**. Actual extra nonprocessing records and data-source constraints can extend that substantially. ALL-FIELDS >=90 ETA cannot be estimated from these results.
- Exact next research batch in `research/next-batch-39-tww-prospect-keys-2026-10-28.txt`: 39 never-examined TWW Prospecting overlay record IDs across nine rank-specific ore inputs 210930..210938, verified to exist in coverage ledger. Follow with Dragonflight output rank, MoP p normalization, and unresolved milling 200061 original item identity.

## Safety
Research evidence, CSV ledgers, tests and report only on `research/processing-confidence`. No production addon ZIP / main edits / release; no unsourced 90-score promotions.
