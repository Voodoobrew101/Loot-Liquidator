# Final closure and review handoff

PR: https://github.com/Voodoobrew101/Loot-Liquidator/pull/24

Main reviewed: `c5930a796e92d7236217ccd672bdbd7bcdf90f31`, unchanged from the implementation base. Functional head reviewed: `51f2b29d9a05b5e4a73fbcc13325b0b198d3c00f`; GitHub addon validation passed at https://github.com/Voodoobrew101/Loot-Liquidator/actions/runs/41456524883. Pass 3 reran the full native Lua 5.1 suite successfully and reproduced all four generated audit artifacts byte-for-byte. The final documentation commit must also pass GitHub validation before handoff.

## Result

For the same 365 processing profiles, complete listed values increased from 307 to 358, partial values changed from eight to seven, and absent models decreased from 50 to zero. No numerical-profile regressions or runtime errors were found. Two additional per-input normalization profiles bring the current census to 367. This is controlled source-to-tooltip coverage, not exhaustive Retail inventory or real-character actionable coverage.

The 3,593-row ledger has 3,412 transcriptions attached to fully valued profiles, 179 attached to partial profiles, and two outside the supported processing-method census. Transcriptions are alternatives/copies/source fields, not independent experiments. The token inventory contains 248 catalog records and 1,497 direct reward relationships; actual eligibility, prices and balances are evaluated at runtime. Representative real-engine token proofs are saved in `token-tooltip-proofs.md`.

## Explicit remaining dispositions

| Source/condition | Disposition |
| --- | --- |
| Seven Midnight ore profiles | Ordinary outputs priced. Diamond calculator figures visible as conditional; excluded from the current total until ore-specific unlock applicability is established. |
| Seven curio catalogs | Reward information retained, including ATT tier membership and intermediate token links. Full exchange costs are not established by a symlink; no free redemption or collection action is promised. |
| ATT inherited requirements | Of 415 archived equipment cost leaves, 225 have only supported fields and 190 contain the additional `r` restriction. Their numerical costs are retained. Faction/inherited requirements remain explicitly unverified for action selection rather than being assumed satisfied. |
| 94 discovery hints | No validated catalog relationship. Includes currencies/reagents; not 94 confirmed gear tokens. |
| Two BfA calculator rates | Exact input herb unspecified; source preserved, no arbitrary herb mapping. |
| Two Refine source rows | Spells 1307462 (10 Crystalline Glass -> one higher-rank Glass) and 1307466 (18 Duskshrouded Stone -> one higher-rank Stone) are outside the four-method processing adapter/census. Sources specify trained Midnight Jewelcrafting 50, learned recipes, tools and bench, with client-untested nominal returns. They remain explicit unsupported recipe adapters, not missing prospecting data or proven current-character actions. |
| Exact reward variants | Exact supplied links now survive price, appearance, collection-summary and recipient checks. Otherwise base-item/difficulty estimates are labeled; bonus IDs are not guessed. |
| Per-input historical references | Numeric unit values retained without inventing actual recipe batches or character eligibility. |

The defined processing/token paths are ready for code review. These explicit limits remain; this PR does not claim every possible Retail transformation, current character condition or live price is known. Live WoW client QA remains outstanding. Do not relabel simulated tests as client verification.

## Research pipeline dependency review

PRs #22 and #23 remain draft changes targeting `implementation/five-agent-completion`, not main. #22 corrects research estimator output identity; #23 adds reconciliation tooling and documents six pre-existing migration failures. Neither has been merged or imported wholesale here. The addon retains the immutable numerical snapshot `4df9ae8b1359d934828e4d0e6d39a9a4dba26fae`; its generated checks and runtime tests pass independently. This PR does not claim to repair or green the separate research migration workflow.

## Review and rollback

### Post-pin research handoffs reviewed

PR comments through 2026-11-02 were reviewed after readiness. No code review requested changes, main remained unchanged, and the functional checks stayed green. Research-only PR #25 identifies defective EXPECTED projections in the Dragonflight workbook: retain raw yields and their original context, do not import those projections or interpret units/nominal ore as P(hit). The pinned corpus distinguishes reconstructed nominal casts (`castsBasis=countedFromInputs`) from reported operations; the estimator explicitly discounts equivalent denominators. Historical estimates remain provisional, not current-Retail validation or a causal skill model.

The post-pin Dawn Shatter (1280401) and Radiant Shatter (1280394) handoff states three total outputs per legal craft. These recipes are held outside this pinned four-method adapter: per-rank quantities/probabilities and live character skill/unlock applicability are unresolved. Dawn Crystal 243605/243606, Radiant Shard 243602/243603 and Eversinging Dust 243599/243600 are material identities, not proof of a three-highest-rank outcome. Their absence from this adapter must not be described as a missing AH price. No blanket research refresh, invented quality distribution, Multicraft multiplier or duplicate disenchant valuation was added.

Additional historical spot-checks of Prismatic Ore and Vibrant Emulsion are corroboration, not new current-context guarantees. Prismatic Ore as an output of Serevite and as a prospecting input are separate paths. Carnelian Spikes source arithmetic must use raw totals/hit counts rather than the comment's inconsistent prose conditional averages. These are retained research/live-eligibility follow-ups, not blockers requiring a new addon snapshot in this PR.

Sources: PR #24 comments [calculator audit](https://github.com/Voodoobrew101/Loot-Liquidator/pull/24#issuecomment-6577754491), [Shatter/Carnelian handoff](https://github.com/Voodoobrew101/Loot-Liquidator/pull/24#issuecomment-6579203649), and [Prismatic/Emulsion QA](https://github.com/Voodoobrew101/Loot-Liquidator/pull/24#issuecomment-6580978326). External handoffs are source material; they do not replace the owner's instructions or authorize a merge.

The implementation keeps one ItemDB and its original evidence. Average quantities default off; compact ranges and all five native tooltip sort modes are tested. ATT's pinned Retail data and MIT notice are preserved without requiring the installed addon. Fixed-price fixtures check actual resolver, valuation, decision and formatter behavior, including consumed gear opportunity costs and exact-variant appearances.

Reference fallback rates can be disabled through their native source control. Reverting this PR removes its compiler/runtime/display changes; no observation-history deletion or main merge was performed. Review the final PR head/checks and perform live-client smoke testing when a WoW client is available. PR Director owns merge/release.
