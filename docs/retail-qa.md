# Pending WoW Retail QA

Back up account SavedVariables and install only the `LootLiquidator/` folder. Enable Lua errors. These checks have not been executed in a real WoW client.

1. Load with and without TSM/ATT/BetterBags; run `/ll status`, `/ll settings` and existing research/export commands. Confirm no load/XML/template errors.
2. Check Database & Accuracy: all four rows, native theme/ElvUI skin, weight display, zero/disabled equivalence, reset, persistence across `/reload`, and personal-only policy.
3. Verify the compact Professions & Alts table retains header dropdowns and per-character Manual checkboxes. Confirm each profession page is nested beneath it. Save distinct manual values for two characters/expansions; verify only the selected Manual context uses them.
4. Open each expansion profession, change equipment/spec/skill and learn a recipe. Confirm live snapshots refresh, offline alts retain their own stale/incomplete labels, and unknown gear/stat values never appear as zero bonuses.
5. Inspect milling, prospecting, smelting and disenchanting. Compare material EV × displayed net prices against per-original-input value. Unknown probability/ranges must stay `?`/absent. Check all-sources-off, missing prices, known zero and incomplete-output cases; incomplete models must not win recommendations.
6. Confirm tooltip source shares reflect actual eligible normalized evidence, not configured sliders. Check bounds-source attribution, confidence/provisional/baseline labels and personal-only histograms. No skill improvement is expected from a coefficient that has not been verified and shipped.
7. Follow the [measured recording checklist](#measured-recording-checklist) below for crafts/disenchant/mill/prospect. Confirm legacy CSV and counts remain inspectable while only complete new logs feed personal valuation.
8. Test Blizzard separate/combined bags, regular bank, Warband bank, BetterBags and guild bank. Open, sort, move and remove items; confirm shared colors/font/position, ignored methods and badge cleanup. Verify no Lua errors or UI stalls with a large bank.
9. Test soulbound, warbound, account-bound and quest items, insufficient batches and additional smelting reagents. Force On must not bypass real recipe/binding gates; Force Off must exclude the action.
10. Verify TSM assigned/selected auction operation quotes and fee toggles; ensure TSM saved profiles/operations never change. Test missing/disabled TSM data and vendor-output fallback.
11. Test ATT armor tokens, transmog ownership/unique appearances, alt class eligibility and direct-token observations with and without cached data. Confirm no heavy ATT lookup repeats per redraw.
12. Compare frame-time and memory during repeated large-bank redraws with the baseline. The offline lookup benchmark is not a substitute for this check.

## Measured recording checklist

Back up SavedVariables and use a new `/ll craftstudy LABEL` for each controlled test. No live-client validation has been performed.

- Capture each BFA mass-milling recipe (256218/256223/256221) and confirm method Mill with twenty nominal herbs, then capture single successful disenchant, mill and prospect casts and a learned multi-reagent craft. Compare the GUID, recipe, original batch, net inputs, output rank/quantity, build and current skill/spec/equipment against raw `/ll craftexport` JSON. Compare real recipe-operation stats with actual selected allocation/concentration.
- Test resource returns and multiple outputs: repeated metadata must not count the same return twice. Nominal batch must remain unchanged while expected net consumption and saved-input value agree. Test full input refund if supported.
- Verify that a timeout/no loot is unresolved; `/ll craftzero` must refuse pending results or an inventory change. Only explicitly confirm a genuinely empty isolated result. Check that this zero enters every material's denominator/histogram without inventing output IDs. Delay looting and confirm that missing loot never becomes an automatic zero.
- Test failure/interruption, duplicate results, result-before-success, success-before-bag-update, long casts and multiple queued casts. Ambiguous attribution must produce a diagnostic/coverage gap instead of a positive-only baseline. Test trade/mail/vendor/bank interaction during capture.
- Change equipment, spec and skill between casts, then test temporarily nil APIs. Manual values and another character's snapshot must not enter measured context. Personal valuation must reject mismatched or unavailable current context.
- Verify unsupported orders, recrafts, enchant-only outputs, reagent-bank inputs and unknown optional allocations cannot create complete baselines. Start a new study after any censored gap.
- Disable/re-enable each recording preference and reload/switch character. Confirm opt-out stops capture, a new study is used, and an unclosed interrupted session cannot resume as a complete study.
- Export every JSON page with recording paused, validate using `tools/validate_craft_export.py`, and compare all raw operations with staged counts, histograms and source IDs. Confirm no database/registry is modified and personal tooltips show unscored confidence, actual effective source shares, and the same quantities/value as the engine.
