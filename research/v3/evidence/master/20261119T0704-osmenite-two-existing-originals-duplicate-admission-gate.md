# Manager gate — 2019 Osmenite original cohorts already imported; 14-row duplicate HOLD

Verified 2026-11-19T07:03:33Z against **exact GitHub blobs**, before any manager edits. This is a research-only source-identity / denominator QA result, **not newly discovered independent experiments** or newly covered current-Retail gold recommendations.

## Finding and source ancestry

The worker's 2026-11-19 06:41Z file `research/v3/evidence/legacy/20261119T0641-two-original-osmenite-mass-prospects.jsonl` contains **14 material output totals** (7 per source) from:
- [2019-07-03 Reddit c8lcye](https://www.reddit.com/r/woweconomy/comments/c8lcye): 16,760 nominal/reportable Osmenite Ore (168185); 7 output totals.
- [2019-07-29 Reddit cj6ju4](https://www.reddit.com/r/woweconomy/comments/cj6ju4): 6,800 nominal/reportable Osmenite Ore; 7 output totals.

**Both source-original cohort vectors and all 14 exact output IDs/quantities already exist** in the 2026-10-28 append-only [legacy source-reconciliation observations](../../../../research/evidence/observations/2026-10-28-1838-legacy-q20-batch018-two-osmenite-original-cohorts.jsonl), via the earlier `ww-b008-osmenite-live-mass-16760` and `ww-b008-osmenite-live-mass-6800` study IDs. This prior [October 28 report](../../../../research/coordination/submissions/loot-liquidator-legacy/2026-10-28-1838-legacy-q20-batch018-report.md) explicitly calls them *already indexed*. The [current v3 study-audit](../../output/study-audit.json) also contains BOTH under imported source-specific keys `legacy-q20-b018-osmenite-2019-original-cohort-{1,2}-source-reconciliation`, seven records each (agent `import`). Reformatting these as fresh 2026-11-19 IDs does **not** make two new independent studies and must **not** increase evidence or confidence weighting.

No original Reddit text was independently refetched during this run (direct source fetch failed); exact numerical agreement was independently checked against the prior source-preserving repository observations.

## Exact numerical gate

Source-specific output IDs and totals in the new file match the October archive **14/14**, including the distinct source inputs (16,760 and 6,800). The combined 23,560 ore / seven-output historical raw totals are:

| Output ID | July 3 total | July 29 total | Combined | Nominal units per five reported input ore |
|---|---:|---:|---:|---:|
| 168188 Sage Agate | 181 | 84 | 265 | 0.056239 |
| 168189 Dark Opal | 782 | 320 | 1102 | 0.233871 |
| 168190 Lava Lazuli | 715 | 337 | 1052 | 0.223260 |
| 168191 Sea Currant | 757 | 332 | 1089 | 0.231112 |
| 168192 Sand Spinel | 738 | 331 | 1069 | 0.226868 |
| 168193 Azsharine | 179 | 85 | 264 | 0.056027 |
| 168635 Leviathan's Eye | 515 | 207 | 722 | 0.153226 |

**Critical units:** Both sources used historical **20-ore mass prospecting** (spell 300619). The earlier archive labels `838` / `340` as **derived nominal mass-operation equivalents** and `3352` / `1360` as **five-ore input equivalents**; it explicitly sets `completedOperations:null`, `actualOperationCountKnown:false`. The latest worker likewise sets `casts:null`, `castsWithDrop:null`, `histogram:null`, `outputRank:null`. None of the above per-five-input ratios is a measured mean *per physical five-ore cast*, occurrence probability or conditional yield. The v3 `study-audit.json` lists imported `maxCasts:3352` and `1360` for those sources — exactly the **nominal five-ore equivalents**, *not observed completed operations*. **Reviewer must check castsBasis and weight semantics before any recompile or confidence uplift.**

Current generated `research/v3/output/estimates.json` (blob `15ae8c5b7f7b2587ceff1dcd3e8b9d13d4351d1e`) already contains seven 168185 output models, each with 12,992 displayed effective study casts; six show 5 studies, 168635 shows 6, and `chanceSource:"measured"` is present. **This inspection does not establish which individual studies determine the chance numerator**, nor prove a measured hit numerator for these two source cohorts. Treat their input-only equivalents as a denominator/provenance review risk, not proof that any particular compiled probability is wrong.

## Validation, impact and disposition

- **158/158 bounded JavaScript assertions passed** in the GitHub connector runtime, comparing the exact 14 new rows to both archived independent source vectors, original study IDs, null observed-cast fields, 20-ore mass recipe, audit index and seven existing estimate identities. This is source-field cross-validation, **not** a Python estimate rebuild, Lua test, offline synthetic-price ItemDB/tooltip render or live WoW.
- Worker file blob `cee48296a6e65d4fa737086e66deb132aa29b0e8`; historical archive blob `d14e74cdafd8d7bc05bacff9746c0a40375e14a6`; study audit `eb95c9d5e1861c3dbb5fdaa7135264c7d38d7057`.
- **HOLD** all 14 new worker rows from fresh independent-study admission or additive estimator counts pending append-only source-lineage dedupe; preserve the worker originals and already imported historic records unchanged. Avoid any "7 new output coverage" claims. Current-Retail applicability, character eligibility, actual auction prices and tooltip correctness remain unverified.
- Reviewer/worker next: map the latest 14 IDs to existing original `ww-b008`/`legacy-q20-b018` study family; use a correction / identity ledger in an isolated approved research branch if needed; audit older importer `maxCasts` `castsBasis` handling without replacing measured other cohorts. Higher current-gold priority remains TWW 222833 RR true-state and independent Midnight 237362/236761 per-operation zero-inclusive events.

No addon/owner three-pass worktree, frozen snapshot, production branch, worker file, queue or schedules were modified here. PR Director retains integration authority.
