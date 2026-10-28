# Proposed research corrections — do NOT apply blindly to released addon

Checked: 2026-10-27. Canonical main source: `GameData.lua` blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`.

## 1. Correct Midnight prospecting hotfix date (high-confidence factual correction)

**Existing:** `gd.mechanicVersionNotes.midnightProspectingGemHotfix="2026-04-17"` at GameData.lua line 715.

**Corrected proposed value (master-reviewed 2026-10-28):** `"2026-03-31"` (date of the *specific profession hotfix subsection*; the cumulative Blizzard article was updated April 17). The earlier April 1 proposal was incorrect.

Evidence: Blizzard's cumulative hotfix article and the archived official Blizzard Blue Tracker copy place the gem-frequency note under **March 31, 2026 > Professions**. The April 1 subsection appears above the March 31 subsection and does not contain this change. The article title reflects its latest April 17 update, not the gem change.

- https://worldofwarcraft.blizzard.com/en-us/news/24266320
- https://www.bluetracker.gg/wow/topic/us-en/2260898-world-of-warcraft-midnight-hotfixes-april-17/
- https://us.forums.blizzard.com/en/wow/t/world-of-warcraft-midnight-hotfixes-april-17/2260898
- https://www.reddit.com/r/woweconomy/comments/1sfds1u/did_prospecting_change/
- https://www.buffed.de/World-of-Warcraft-Spiel-42971/News/wow-midnight-hotfixes-1524190/

The change's **numerical gem-rate multiplier remains unknown**. Do not assume it was a uniform factor for every ore/gem. Confidence in event/date attribution: 94/100 (March 31 subsection verified). Confidence in numeric effect: 0 (not quantified). This research correction has NOT been applied to main.

## 2. Cobalt Ore (36909) and Titanium Ore (36910): 12 economically dangerous expected-value conflicts

In `gd.tsmRetail.prospect[36909]` (GameData lines 886–899) and `[36910]` (900–919), the six uncommon gems each have `matRate=0.235`, `minAmount=1`, `maxAmount=2`, **but `amountOfMats=0.5` per input ore**.

The current engine treats the last field as **0.5 gem per ore = 2.5 gems per 5-ore cast** for EACH gem. If the recorded 23.5% occurrence and conditional [1–2] range refer to the same five-ore cast, each gem must instead have an expected count between `0.235` and `0.470` per cast, i.e. `0.047–0.094` per ore. The stored `2.5` per cast exceeds even the conditional maximum `0.470` by **5.32×**.

Independent evidence for output families and *approximate* occurrence/conditional ranges:
- https://warcraft.wiki.gg/wiki/Cobalt_Ore — 1–2 uncommon gems with roughly 25% individual chances
- https://warcraft.wiki.gg/wiki/Titanium_Ore — roughly 25% for each uncommon; additional rare/epic possibilities
- https://www.wow-professions.com/wotlk/prospecting-table-wotlk-classic — approximately 23% Cobalt per uncommon (historical Classic, not verified live Retail)
- https://www.wowhead.com/item=36909/cobalt-ore — current Retail item and prospectability

**Action:** Preserve the original TSM source row as evidence but flag these 12 `amountOfMats` values as **not reliable for gold valuation** until the original TSM denominator/units are recovered or measured per-cast means exist. Do NOT silently replace `0.5` with `0.05`, `0.075`, or a midpoint: the true unconditional mean and exact condition-matched Retail rate remain unverified. If an explicit *lower-bound scenario* is needed, label it as such, never as the measured expected quantity. Also inspect the six rare/epic outcomes and Titanium Powder eligibility independently.

## 3. Other probability–range–mean contradictions

The full list of **40** mismatches in 903 TSM output rows is in `research/ledger/tsm-invariant-anomalies.csv`. Apart from the 12 Cobalt/Titanium rows, there are 12 small Pandaria overages, six Legion underages, nine Dragonflight small precision discrepancies, and one Dragonflight milling outlier. Severity and exact row/ID are in the CSV.

A contradiction is **not automatically proof that the unconditional mean is wrong**: the chance may be a historical estimate, the min/max may be incorrect, the denominator may differ, or rounding may explain the mismatch. Investigate rather than force all values to agree.

## 4. Actual profession skill vs slider simulation — not resolved

- `Professions.lua` already scans expansion-specific profession information and specialization snapshots.
- `ConversionEngine.lua` lines 43–115 constructs a character context and can use `C_TradeSkillUI.GetCraftingOperationInfo` where recipe context is available, but **the existing low/high yield functions still read manual upgrade sliders** rather than deriving those percentages from measured real skill/spec effects.
- `Settings.lua` lines 542 onward exposes upgrade sliders, output-rank settings and unlock toggles. These are **not yet a full simulated character profession profile** with explicit expansion skill, equipment and specialization.
- `StatYieldProfiles.lua` lines 14–29 and 147–179 construct tooltip-only probability/range proxies from expected units; do not treat these as empirical drop frequencies. Its current linear interpolation is a provisional implementation, **not the approved final design**.
- `C_TradeSkillUI.GetProfessionInfoBySkillLineID` reports `skillLevel` and `skillModifier`; `GetCraftingOperationInfo` reports operation skill, quality and bonus stats when a valid current recipe context exists. Neither API by itself establishes a universal prospecting drop-rate formula.
- API documentation: https://warcraft.wiki.gg/wiki/API_C_TradeSkillUI.GetProfessionInfoBySkillLineID and https://wowpedia.fandom.com/wiki/API_C_TradeSkillUI.GetCraftingOperationInfo

**Next implementation design, pending user review:** read current profession skill/spec/stats when available, select an eligible character/alt, use explicit simulated values only when necessary, and use the conservative low profile otherwise. Determine skill-to-yield effects empirically or via known discrete unlocks; do not hardcode a global linear slider.

## Safety / verification

No production Lua files or releases were modified. No in-game tests performed. The source snapshot and all numeric anomalies are independently traceable to GitHub main and the source line numbers. This is a research proposal, not a tested addon patch.

## 5. New source-backed Titanium expected yields (research evidence; not released)

Found two independent ore-to-gem material-total studies and normalized them correctly **per five-ore prospect**, without multiplying by tooltip probability:

- **Retail player report, 2022-01-17:** 1,000 Titanium Ore / 5 = **200 operations**. Six uncommon gem totals: Bloodstone 53, Sun Crystal 44, Chalcedony 49, Shadow Crystal 53, Huge Citrine 47, Dark Jade 59. Source: https://www.reddit.com/r/woweconomy/comments/s6bfrl/
- **WotLK Classic PTR player report, 2023-05-18:** 5,000 Titanium Ore / 5 = **1,000 operations**. Totals: Bloodstone 250, Sun Crystal 263, Chalcedony 253, Shadow Crystal 255, Huge Citrine 227, Dark Jade 250. Source: https://www.wowhead.com/wotlk/item=36910/titanium-ore (comment by Strath).

| Material | Item ID | 2022 Retail E[units]/5 ore | 2023 Classic E[units]/5 ore | Bad stored TSM E[units]/5 ore |
|---|---:|---:|---:|---:|
| Bloodstone | 36917 | 0.265 | 0.250 | 2.500 |
| Sun Crystal | 36920 | 0.220 | 0.263 | 2.500 |
| Chalcedony | 36923 | 0.245 | 0.253 | 2.500 |
| Shadow Crystal | 36926 | 0.265 | 0.255 | 2.500 |
| Huge Citrine | 36929 | 0.235 | 0.227 | 2.500 |
| Dark Jade | 36932 | 0.295 | 0.250 | 2.500 |

These are **observed unconditional decimal means**, not occurrence probabilities. Neither source reports per-cast hit counts, so probability remains independently estimated/historical; conditional integer bounds still require separate evidence. The 2022 study is Retail but predates Midnight by four years; the 2023 study is Classic PTR. **Do not pool them as though they were same-version cohorts.**

The original TSM 2.5-per-cast values are about 8–11× the measured per-cast means. This is substantial evidence of a conversion-rate unit/data problem. Suggested research fallback for the six Titanium entries is the **separate 2022 Retail per-cast mean** (score 60/100 for expected quantity because patch and skill conditions are not verified), with explicit historical/provisional status. Do not promote to 90 or silently alter main.

Full 12 evidence rows with exact numerator/denominator, source and caveats: `research/ledger/titanium-observed-yields.csv`.
