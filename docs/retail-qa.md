# Pending WoW Retail QA

Back up account SavedVariables and install only the `LootLiquidator/` folder. Enable Lua errors. These checks have not been executed in a real WoW client.

1. Load with and without TSM/ATT/BetterBags; run `/ll status`, `/ll settings` and existing research/export commands. Confirm no load/XML/template errors.
2. Check Database & Accuracy: all four rows, native theme/ElvUI skin, weight display, zero/disabled equivalence, reset, persistence across `/reload`, and personal-only policy.
3. Verify the compact Professions & Alts table retains header dropdowns and per-character Manual checkboxes. Confirm each profession page is nested beneath it. Save distinct manual values for two characters/expansions; verify only the selected Manual context uses them.
4. Open each expansion profession, change equipment/spec/skill and learn a recipe. Confirm live snapshots refresh, offline alts retain their own stale/incomplete labels, and unknown gear/stat values never appear as zero bonuses.
5. Inspect milling, prospecting, smelting and disenchanting. Compare material EV × displayed net prices against per-original-input value. Unknown probability/ranges must stay `?`/absent. Check all-sources-off, missing prices, known zero and incomplete-output cases; incomplete models must not win recommendations.
6. Confirm tooltip source shares reflect actual eligible normalized evidence, not configured sliders. Check bounds-source attribution, confidence/provisional/baseline labels and personal-only histograms. No skill improvement is expected from a coefficient that has not been verified and shipped.
7. Record genuine disenchant/mill/prospect operations; ensure unrelated bag changes/trades do not record. Compare sample counts and CSV exports. Confirm characters, recipes and builds remain separate; retain older records for inspection.
8. Test Blizzard separate/combined bags, regular bank, Warband bank, BetterBags and guild bank. Open, sort, move and remove items; confirm shared colors/font/position, ignored methods and badge cleanup. Verify no Lua errors or UI stalls with a large bank.
9. Test soulbound, warbound, account-bound and quest items, insufficient batches and additional smelting reagents. Force On must not bypass real recipe/binding gates; Force Off must exclude the action.
10. Verify TSM assigned/selected auction operation quotes and fee toggles; ensure TSM saved profiles/operations never change. Test missing/disabled TSM data and vendor-output fallback.
11. Test ATT armor tokens, transmog ownership/unique appearances, alt class eligibility and direct-token observations with and without cached data. Confirm no heavy ATT lookup repeats per redraw.
12. Compare frame-time and memory during repeated large-bank redraws with the baseline. The offline lookup benchmark is not a substitute for this check.
