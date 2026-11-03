# War Within q25 Batch 023 — 35 assigned numeric-gap records and spreadsheet formula audit
**Date:** 2026-10-28 23:22 PDT. **Branch:** research/processing-confidence. **Assignment:** `2026-10-28-batch023-war_within`; **queue revision:** 25. Read live assignments, source-memory, research-lessons, latest master batch022 verdict, previous worker source reviews, relevant GameData source lines and missing-field ledger before research.

## Authorized scope and four-field result
- **35/35 exact master-owned stable keys reviewed**: 21 native The War Within prospecting/Gem Finding records (8 unadmitted conditional output leads + 13 compiled outputs) and 14 explicitly assigned Dragonflight overflow records (5 existing candidate records + 9 TSM-derived source lines).
- **96 compiler missing field cells**: 32 conditional TWW, 26 compiled TWW, 20 DF candidates, 18 DF TSM. For all 35 rows, exact-current-context P(hit), positive-only min/max and zero-inclusive E remain unverified. The audit JSONL records all 140 field review slots as unknown for exact current context, while separately flagging only the 96 compiler missing cells. Historical provisional values are not overwritten or misrepresented as verified.
- **New legitimate mappings: 0. New measured completed-cast cohorts: 0. New verified current-Retail numeric fields: 0. New provisional numeric promotions: 0.**
- All 13 TWW compiled rows match GameData source lines 419–443; GameData `chance` is explicitly tagged `POISSON_EVENT_COUNT_PROXY` and is **not measured P(hit)**, despite `provisional=false` in the source. Existing E numbers are reported batch means; original raw zero-inclusive histograms and patch-matched cohort contexts were not recovered. Treat the boolean as a legacy source-labeling risk, not a reason to grant high confidence.
- The 8 Gem Finding candidates are conditional on specialization; guide family eligibility is not proof of current per-rank P or E. No unadmitted candidate promoted.
- The 9 DF TSM source lines 1174–1182 for `188658` each repeat `matRate=.19, amountOfMats=.0401, min=1, max=3` across multiple gem identities and ranks. Hypothetical E=5×.0401=.2005 passes a single-row invariant but **nine-fold addition would give 1.8045**, an unsupported simultaneous-rank sum. Original TSM units and actual rank selection remain unknown; no P/E imported.

## Novel source/formula result
Inspected previously unindexed historical TWW `Kalimdor Hold Em.xlsm` calculator directly from the author's Google Drive link, without running macros. Its 29 worksheets include Shuffles and source data. `Shuffles!B19` explicitly excludes skill, Inspiration and Multicraft from its prospecting model; `R34` and `R36` implement hardcoded talent shift and capstone coefficients; `E27` applies Resourcefulness as an **input-cost discount**, not extra output. `F41=1.13` pebbles and `G41=.38` glass are static modeled quantities without an exposed original cast denominator. Internal `FINAL 2024-11-02` means workbook is not verified for 2026. This is a **new calculator lineage and useful negative source audit**, not an original measured cohort. Detailed cell/formula evidence is in the accompanying immutable observation file.

## Source lineage, QA, and decision risk
- [Original spreadsheet author thread](https://www.reddit.com/r/woweconomy/comments/1foca2r/tww_crafting_spreadsheet_using_blizzard_and_tsm/) and [original workbook](https://drive.google.com/file/d/1nM7SJGUGyCz7KeL72xm7vorkH_gNrrLl): one new **derivative calculator** lineage, not independent measured data.
- [Method TWW prospecting guide](https://www.method.gg/guides/the-war-within-ore-prospecting-guide): reused secondary family/specialization eligibility; no numeric field proof.
- [Original two-commenter historical samples](https://www.reddit.com/r/woweconomy/comments/1fisfkn): already in source-memory; re-fetch avoided for duplicate numeric credit.
- [GameData.lua](https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/GameData.lua): source identity and provisional imported values; not independent original sampling.
- **P2 risk:** Poisson proxies can misstate occurrence chances; additive alternative gem ranks can inflate output EV; resource refunds must reduce input cost, not create additional gems. These risks can change liquidation recommendations but no 2026 AH price/decision flip was established.
- **QA:** 35 unique assigned keys, 35 immutable JSONL audit rows, 140 independent field statuses, no numeric values invented; master batch022 rejection reasons applied. No unrelated mechanics study, no duplicate author credit, no production or shared-state changes.

## Next exact IDs for master
1. Gem Finding selector/zero-inclusive cast histograms for `210931→212495/212505/212508/212511`, `210934→212495/212511`, `210937→212505/212508` under known specialization nodes.
2. Missing positive bounds for `210931→212498/213398/213399`, `210934→212498/212505/212508/213398/213399`, `210937→212495/212498/212511/213398/213399`; verify source means independently before promoting.
3. Dragonflight `188658→192869`, `189143→192869`, `190311→192869`, `192880→192849/192866`; TSM `188658→192837–192845`. Require actual cast count, quality-rank eligibility, patch and output histogram; no TSM unit guessing.

All 35 assigned q25 gaps reviewed; scope awaiting master QA/reassignment. Hourly schedule remains unchanged.
