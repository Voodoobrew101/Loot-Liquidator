# Dragonflight batch014 — queue revision 16

2026-10-28 14:32 PDT. Worker: loot-liquidator-dragonflight. Research-only branch research/processing-confidence.

## Exact assignment and QA
All 40 assigned keys inspected: 31 Dragonflight ranked milling outputs, three supplemental Illimited Diamond inputs, two Crumbled Stone gem outputs, one Prismatic Leaper output, and three TSM Illimited Diamond rank outputs. All 35 assigned keys with GameData.lua source lines matched exact input/output IDs. Five supplemental rows have no GameData per-output source line. No newly discovered conversion mapping, no new independent 2026 Retail cast cohort, and no newly measured four-field numeric value.

## P0: Seven retained E cells need master review
The research candidate v0.3.0 still contains seven numeric expectedQuantity values whose basis is unsafe for a rank-specific per-completed-cast valuation:
- Crumbled Stone 192880 -> Eternity Amber 192849, E=0.9024; 192880 -> Nozdorite 192866, E=0.104. Original Mgnta report gives 3125 stones, 564 Amber, 65 Nozdorite, 160 stones returned, and 16% Resourcefulness. The denominator 3125/5=625 is nominal five-stone input equivalents, NOT verified completed casts; output ranks were not recorded. Preserve as historical gross-equivalent ratios, not confirmed exact-rank per-cast E. The self-return could be Resourcefulness, not produced output.
- Illimited Diamond: supplemental 189143->192869 and 190311->192869, plus TSM 188658->192870, 188658->192871, 189143->192870. Historical TSM P=.0142 and E=5*.0028=.014 contradict P<=E for positive integer output. The compiler already quarantines P but retains E=.014 on these five rank-specific records. Rank-specific E is not independently established. The sixth assigned supplemental diamond 188658->192869 is already E-unknown; do not double-count.

Recommend master quarantine these seven E values for valuation while retaining original TSM/Mgnta source proxies and lineage. This is a proposed correction, not a compiler change.

## Existing protections confirmed
All 31 assigned milling pigment rank rows already have rank-specific P and E unknown in master v0.3.0. Historical TSM P=1 and E=3.5 refer to the pigment family, not each rank simultaneously. Historical positive 2–5 bounds remain provisional. No new quarantine credit for these 62 already corrected fields.

Prismatic Leaper 200061->190322 historical TSM P=.002, E=.005, max=1 fails E<=P*max=.002. Candidate already quarantines P. Its E=.005 remains TSM-only provisional; original Primer three-cast fish sample does not establish this output's identity or absence. Do not fabricate zero.

## Evidence lineage and decision risk
Reused source memory and original archived Mgnta, LavingRunatic, Primer, 2022 Dragonflight beta milling guide and TSM/GameData. No new independent experiment. Mgnta 3125 stone report is not the same cohort as LavingRunatic 60 actual casts (55 Amber, 5 Nozdorite, 11 stones). Historical sources cannot establish 2026 Retail skill-neutral baseline or rank-specific rates.

Gold risk: ranking outputs can overstate prospect value if historical family E is duplicated or nominal gross-input yields are treated as cast E. No live AH prices or matched character conditions, so no actual auction-versus-prospect flip asserted.

Sources: https://www.wowhead.com/item=192880/crumbled-stone ; https://www.wowhead.com/item=200061/prismatic-leaper ; https://www.wowhead.com/news/crafting-work-orders-are-here-wowhead-economy-weekly-wrap-up-251-329620 .

## Exact next IDs
192880->192849/192866: capture actual casts, resource refunds, output quality ranks and zero-inclusive histograms. 189143/190311->192869 and 188658->192870/192871 and 189143->192870: rank-specific diamond outcomes. 200061->190322: original client-confirmed eligibility. 191461->198423 and 191462->198421/198422/198423: skill-matched current patch milling casts. No production, master ledger, assignment, canonical registry, cache, Lua/TOC or schedule edits. Node/Lua/in-game tests not run.
