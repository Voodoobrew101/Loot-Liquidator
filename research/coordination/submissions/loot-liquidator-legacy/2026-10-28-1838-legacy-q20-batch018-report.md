# Loot Liquidator Legacy — Batch018, queue revision 20
**2026-10-28 · worker loot-liquidator-legacy · research/processing-confidence · research-only**

## Actual output and scope
- Audited **40/40 exact master-assigned keys**: 9 BfA historical 20-herb mass-mill outputs and 31 TSM prospecting rows (7 Osmenite, 24 Shadowlands).
- Verified **31/31** assigned TSM source-line output identities against main `GameData.lua` blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`. Reconciled **9/9** BfA recipe/input/output identities with the master batch017 accepted compilation.
- Four-field audit: **160 slots** = **9** historical mass-cast expectedQuantity, **31** TSM historical provisional positive minima, **31** provisional positive maxima, **89 unknown**. All 40 P(hit) remain unknown; 31 prospecting E remain unknown. No current-Retail measured fields.
- **0 new legitimate mappings, 0 newly verified current-Retail numeric fields, 0 new independently verified studies.** Two already indexed original Osmenite cohorts were re-encoded as schema-conformant source-only observations. One previously unindexed **unparsed chart lead** was recorded without numbers.
- All 40 assigned keys are unique. No other worker's keys were claimed. No production Lua/TOC, main, master assignments, canonical registry, source-memory cache, shared ledgers or schedules modified.

## P0/P1 — BfA mass milling already compiler-admitted
Master batch017 added nine distinct historical BfA mass-milling rows to proposed itemdb v0.6.0. They are **not new mappings this run**. Original Jiyao's revised report gives rounded per actual **20-herb mass operation** means:

| Herb / spell | Reported actual mass casts | Ultramarine `153635` | Crimson `153636` | Viridescent `153669` |
|---|---:|---:|---:|---:|
| Star Moss `152506` / `256218` | 177 | 15.48 | 5.89 | 2.87 |
| Sea Stalk `152507` / `256223` | 106 | 16.39 | 5.96 | 2.57 |
| Siren's Pollen `152508` / `256221` | 103 | 15.89 | 5.85 | 2.12 |

Original source: https://www.wowhead.com/item=153669/viridescent-pigment ; recipes https://www.wowhead.com/spell=256218 , https://www.wowhead.com/spell=256223 , https://www.wowhead.com/spell=256221 . These rounded historical means are supported only as mass-cast E at **62/100 historical-source confidence**, not as current Retail accuracy. P(hit), positive min/max, precise skill/patch and standard-five operation equivalence remain unknown.

## P2 — Two independent original Osmenite studies corroborate a source discrepancy
A July 3, 2019 original author reported 16,760 Osmenite Ore mass prospected; a **different** July 29, 2019 author reported 6,800. Together these are **23,560 gross ore** with seven named outputs. The exact item IDs were cross-checked with their item pages. Mass Prospect Osmenite spell `300619` consumes **20 ore**; neither study provides actual completed-cast counts or zero-inclusive per-cast histograms. Their gross-input-normalized numbers must NOT be promoted as per-cast E.

Original studies: https://www.reddit.com/r/woweconomy/comments/c8lcye and https://www.reddit.com/r/woweconomy/comments/cj6ju4 . Recipe: https://www.wowhead.com/spell=300619 .

| Output | July 3 units / nominal 5 ore | July 29 units / nominal 5 ore | Pooled units / nominal 5 ore | TSM raw `matRate` | TSM versus pooled |
|---|---:|---:|---:|---:|---:|
| Sage Agate `168188` | 0.05400 | 0.06176 | 0.05624 | 0.16500 | +193.4% |
| Dark Opal `168189` | 0.23329 | 0.23529 | 0.23387 | 0.16500 | -29.4% |
| Lava Lazuli `168190` | 0.21331 | 0.24779 | 0.22326 | 0.16500 | -26.1% |
| Sea Currant `168191` | 0.22584 | 0.24412 | 0.23111 | 0.16500 | -28.6% |
| Sand Spinel `168192` | 0.22017 | 0.24338 | 0.22687 | 0.16500 | -27.3% |
| Azsharine `168193` | 0.05340 | 0.06250 | 0.05603 | 0.16500 | +194.5% |
| Leviathan's Eye `168635` | 0.15364 | 0.15221 | 0.15323 | 0.15000 | -2.1% |

**Material decision risk:** `168185→168188` Sage Agate and `168185→168193` Azsharine TSM raw `matRate` are approximately **2.93–2.95×** the pooled historical gross-ore means. For Dark Opal/Lava Lazuli/Sea Currant/Sand Spinel, TSM raw rates are **26–29% below** historical means. Leviathan's Eye differs by only **2.1%**. These are important conditional valuation risks, not proof of an incorrect current Retail rate or of an AH action flip. No live AH price was used. Source semantics and operation units must be established before changing gold-optimal recommendations.

## Shadowlands exact-output source reconciliation
The already indexed December 4, 2020 10,000-Laestrite original report contains Oriblase `173108` 994, Angerseye `173109` 999, Umbryl `173110` 1014, Essence of Rebirth `173170` 82, Torment `173171` 99, Servitude `173172` 76 and Valor `173173` 55. These are gross-ore totals, not zero-inclusive cast data. Source: https://www.reddit.com/r/woweconomy/comments/k6fuik .

The already indexed Osulivan table on https://www.wowhead.com/spell=311949/mass-prospect-solenium gives per-ore rates for Laestrite, Solenium, Oxxein, Phaedrum, Sinvyr (1,000 ore each) and Elethium (500 ore). This is **one author with six cohorts**, not six independent studies. All 24 assigned Shadowlands outputs preserve descriptive gross-input equivalents separately from the independent four-field per-cast record.

A TSM field-semantics issue remains: `matRate / amountOfMats` is 5 for the assigned Osmenite rows, approximately 3.333 for Laestrite common outputs and approximately 1.667 for Elethium Oriblase. These cannot be treated as a universal profession multiplier or directly labeled measured P(hit) and E.

**New unparsed source lead:** a December 2020 Reddit commenter references a chart from 3,300 Laestrite mass prospects at https://www.reddit.com/r/woweconomy/comments/k6d0qk . Its actual chart outputs and denominator interpretation have not been independently verified. The source-review event records it as NEEDS_RECHECK; **zero numerical credit**.

## Numeric QA and source learning
- The 31 TSM min/max pairs are retained as **20/100 provisional historical source-range references**, with operation basis unverified; none are asserted as measured current-Retail positive bounds.
- No negative supplied numbers, min > max or duplicate keys. Full invariant `P × positiveMin ≤ E ≤ P × positiveMax` is **not testable** for any of the 40 records because P is unknown. No unsupported full-tuple pass claimed.
- Distinct original source ancestry preserved: Jiyao one study, two separate Osmenite original authors, one Laestrite 10k original author, Osulivan one author across six ore cohorts. Reused studies are not newly discovered independent experiments.
- Seven source-review events were written, including one new unparsed lead; source cache itself was not modified. Historical comparison and useful negative conclusions do not inflate confidence.
- No Lua runtime, Node CLI compiler, or in-game client testing in this worker batch.

## Exact next IDs for master
1. **P0:** `168185→168188` and `168185→168193` first, then `168189/168190/168191/168192`, to resolve rare-gem TSM valuation discrepancy using current-Retail spell `300619`, skill context and zero-inclusive actual casts.
2. **P0:** `171828→173108/173109/173110/173170/173171/173172/173173`; obtain 2026 completed casts and establish original 10k Laestrite operation mode.
3. **P1:** `171829/171830/171831/171832/171833` exact Shadowlands recipe/skill context; especially `171833→173108` historical TSM range 2–4 versus original gross-ore mean, without inferring a probability.
4. **P1:** `152506/152507/152508→153635/153636/153669` under mass spells `256218/256223/256221`, with current Retail and matched standard-five controls.
5. Retrieve the original chart in https://www.reddit.com/r/woweconomy/comments/k6d0qk and verify its source units before promoting any numeric fields.

**Assignment exhausted:** all 40 q20 keys reviewed; master owns next assignment. Hourly schedule unchanged.
