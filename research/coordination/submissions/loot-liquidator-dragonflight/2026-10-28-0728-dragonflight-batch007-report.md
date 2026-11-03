# Dragonflight worker batch007 — 2026-10-28 07:28 PDT

## Assignment and contract
Read live master queue revision 9, PROGRESS, canonical ITEMDB creation prompt, numeric research protocol and candidate schema, profession mechanics and runtime API registries, observation schema, original evidence, Issue #2, actual GameData.lua and StatYieldProfiles.lua / ConversionEngine.lua. Assignment `2026-10-28-batch007-dragonflight`, **40 exact Dragonflight output keys** (input 190394: 12, input 190395: 1, input 190396: 1, input 199344: 26). No overflow self-claim or production edits.

## First-pass audit
- **40/40** exact assigned source-line/input/output IDs matched to GameData.lua blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`, source ledger `3e2bb784dc832d90584eebd8620148caf2133fbd`; **40/40** passed necessary historical TSM proxy arithmetic `p*min <= 5*amountOfMats <= p*max`.
- All 40 have historical ledger record confidence 30; **zero >=90** and **zero verified current Retail corrections**. The `matRate` is an inherited chance proxy, not observed P(at least one). The `amountOfMats` interpretation as per-ore is not proven from original TSM implementation; keep its native value separately.
- The 40 keys span four input IDs (190394, 190395, 190396, 199344). **6 complete three-quality TSM proxy groups** repeat the same rate for each gem rank, so adding all three ranks as independent outcomes would overvalue yields without a condition-specific rank selection model. Other groups are partial because this is a disjoint assignment slice.
- Output identities are exact as **source IDs** but real 2026 Retail recipe eligibility, patch applicability, per-rank probabilities, positive conditional min/max, unconditional per-cast E, and skill/gear conditions remain unresolved. Per-field confidence in the CSV is preserved from central source ledger, not upgraded.

## Newly recovered original 2022 beta spreadsheet — SIX COHORTS, 222 raw output totals
- [Original public spreadsheet](https://docs.google.com/spreadsheets/d/1B_CjPU0AUlJkbogauPTdo0W4dUZiP1hxZ8KMZX7qp3Q/edit?usp=sharing) and [contemporaneous October 16, 2022 explanation](https://www.wowhead.com/news/dragonflight-jewelcrafting-analysis-wowhead-economy-weekly-wrap-up-249-329385) state **5,000 quality-3 ore per cohort** for three Serevite and three Draconium cohorts, on a beta build described as **October 12, 2022**.
- Original author reports effective skill **68 / 113 / 228**, with changing base skill, knowledge specializations and gear/stats. Original sheet rows 19–55 give 37 material name/quality aggregate totals for each cohort; all **222 cells including zeros** are preserved exactly in six schema-shaped, source-only JSONL observations. Input IDs Q3 Serevite `190394`, Q3 Draconium `190311` have external item identity support.
- **5,000/5 = 1,000 nominal five-ore equivalents**, but actual completed cast counts, refund amounts, per-cast hit/zero counts and proc flags are **not reported**. Never call 1,000 confirmed casts, infer P(at least one), conditional [min,max], or 2026 EV from the aggregate.
- The spreadsheet reports Q3 Sundered Onyx **70** in the low-skill Draconium cohort despite the author's claimed 250-skill Q3 threshold. This is an internal historical contradiction / possible source-row issue, **not evidence for a new formula**. Retain the raw 70 and flag for verification.
- Example exact source aggregates: Serevite Fractured Glass **790 / 1106 / 1162** across three cohorts; Draconium **769 / 1079 / 1225**. These are totals per reported 5,000 ore, not per-cast chances. See original JSONL for all 222 raw counts.

## Parallel numeric mechanics: dragonflight-inspiration-quality-transition
- Historical author describes Inspiration +83 skill on beta build and rank thresholds, but no per-cast Inspiration proc labels or matched skill/spec/gear controls. Even six 5,000-ore cohorts cannot isolate a numeric Inspiration effect.
- Blizzard's official [2024 pre-expansion update](https://worldofwarcraft.blizzard.com/en-gb/news/24119590) explicitly **removed Inspiration**. Do not port 2022 coefficients into 2026 Retail.
- Candidate status **VERIFIED_QUALITATIVE / BLOCKED**, no numeric parameter, no compile eligibility, no verified numeric rules. Next experiment: identical recipe, ore quality, build, skill, specializations and gear, record actual consumed ore, each cast's gem IDs/quality and zeros, and relevant proc flags; separate historical Inspiration test from current-Retail quality selection.

## Independent checks and next exact targets
- See validation JSON for 40 source/ledger checks, 40 necessary bound checks, 40 distinct IDs, 222 raw nonnegative integers, six schema-shaped observations and required-field checks. Full external JSON Schema validation, repository Node suites and WoW client tests **not executed**.
- Master should independently QA these exact 40 keys, source 2022 spreadsheet transcription and per-field confidence; resolve **199344 recipe/input identity** and `194545` prospectability, original TSM native rate units, and gem rank exclusivity.
- **New first-pass candidate submissions: 40; historical cohort observations: 6 (not first-pass records); verified numeric rules: 0; remaining first-pass known queue: master-controlled, cannot decrement until master accepts.**
- No edits to master-owned queue, PROGRESS, central ledger, research mechanics registry, GameData.lua, addon source, TOC or main; no merge or schedule change.
