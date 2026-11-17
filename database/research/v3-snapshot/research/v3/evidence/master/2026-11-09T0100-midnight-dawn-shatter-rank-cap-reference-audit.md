# Research Manager — Midnight Dawn Shatter quality/identity reference audit
Checked UTC: 2026-11-09T00:59:55.244Z

## Existing research and new independent catalog check
The immutable worker record `midnight-20261102-051821` in `research/v3/evidence/midnight/2026-11-02T0518-prospecting-guide-priors-and-enchanting-shatters.jsonl` already describes spell 1280401, **Dawn Shatter**. This is **NOT** a new spell, recipe, collected cast, independent sample, or added raw drop study. Its original identity fields `inputItemID`/`outputItemID` were unknown. The original spell source at https://www.wowhead.com/spell=1280401/dawn-shatter explicitly says one Dawn Crystal is reduced to **3 Radiant Shards**, requires Midnight Enchanting skill **25**, with output quality limited by input quality and otherwise conditioned by Enchanting skill and **Shard Supplier** specialization.

Independent current Retail catalog pages resolve the **quality-to-item-ID candidate identities** (catalog mapping, NOT a player-observed itemLink or actual recipe outcome):
- Dawn Crystal rank 1 of 2 = **243605** — https://goldcap.gg/retail/us/items/243605
- Dawn Crystal rank 2 of 2 = **243606** — https://goldcap.gg/retail/us/items/243606
- Radiant Shard rank 1 of 2 = **243602** — https://goldcap.gg/retail/us/items/243602
- Radiant Shard rank 2 of 2 = **243603** — https://goldcap.gg/retail/us/items/243603

## Quality-conditional implication (deduction; not observed output rate)
- Input rank 1 (`243605`): highest permitted output rank 1, so *if the spell is successfully available and the wording applies*, the candidate output is three rank-1 Shards (`243602`); no new outcome sample.
- Input rank 2 (`243606`): rank-1 or rank-2 output is possible under the quality cap. Total Shards per successful cast is three, but **the rank-2 fraction is unknown** and skill/specialization-dependent. Do not mark either output as 100% observed or assign P(rank 2), a beta denominator, average stack probability or a universal gold EV.
- Formula for rank-2 input, if split qualities are possible: `3 * ((1-q)*price(243602) + q*price(243603))`; `q` remains unknown and is **not** an inferred skill coefficient. The source may imply homogeneous output quality per cast, but no source-verified split histogram or actual character context has been collected.

## Import/valuation cautions and next action
This is an **identity/conditional fixed-yield clarification** for a preexisting historical reference recipe. It is not proof that the addon knows the character's recipe, satisfies skill 25 or unlock conditions, has current item prices, or renders the correct tooltip. Do not wire this into addon code on protected `implementation/usable-data-tooltips`; the three-pass owner controls integration. No duplicate original record, source overwrite, new worker task, policy change, PR, merge or release. When integrating, preserve both explicit quality alternatives and validate an actual spell/tooltip/eligibility fixture at synthetic prices with rank-price divergence. Existing raw Dawn Crystal disenchant Looter rows with two same-name outputs **remain rank-unresolved**: catalog IDs cannot retroactively identify those source-row labels without direct source hyperlinks.

Record class: independent catalog identity check + logic deduced from sourced recipe description; measured casts: **0**; measured P(hit): **unknown**; current client test: **not performed**; supported new gold recommendations: **0**.
