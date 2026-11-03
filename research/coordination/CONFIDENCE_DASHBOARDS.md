# Research confidence dashboards (mandatory for audits and progress; 2026-10-28)

**Coverage-first reporting addition (2026-10-28):** Include a database-readiness chart/metric showing (1) known legitimate input/recipe/output mappings represented in the generated candidate, (2) eligible output rows with all four numeric fields, (3) provisional field estimates below 90, (4) missing/unknown field count, and (5) separately marked completeness of independent exhaustive Retail-universe audit. Plot only grounded values; if the compiler or numerator is absent explicitly state NOT IMPLEMENTED or UNKNOWN. Preserve the existing confidence charts below as secondary QA visuals, not the primary progress milestone.


When returning an audit/progress report to the user, include **visual charts** in the ChatGPT response, not just tables. Use the available native chart visualization when supported; if a tool/report cannot embed one, provide a legible Mermaid bar/line chart in its markdown report and a small machine-readable chart-data JSON alongside the report. Do not pretend a chart was rendered when only data was generated.

## Charts required
1. **Confidence by expansion:** Midnight, The War Within, Dragonflight, Legacy: number of output **fields** in 0–69, 70–89, 90–100, and unknown/unscored. Plot as stacked bars if supported or as adjacent series. Exact denominators printed under chart.
2. **Confidence by field:** `dropChance`, `yieldMin`, `yieldMax`, `expectedQuantity`, each with same score bands. Show separately from record-wide weakest-field evidence.
3. **Progress over time:** timestamped snapshots for cumulative distinct reviewed records, record-wide >=90, expectedQuantity >=90, and known numeric mechanics; plot as series with actual observed runs only. Do not interpolate missing runs, mistake review counts for verification, or imply 90 points means 90% statistical certainty.
4. **Useful studies and source reuse (optional fourth):** new independent studies, reused primary cohorts, duplicate links suppressed, useful accepted vs rejected QA claims. Reward points are not evidence quality.

## Numeric source of truth
Derive snapshot from existing master evidence/coverage ledgers and actual QA-reviewed worker submissions; do not synthesize coverage from narrative output or recalculate scores optimistically. Save append-only daily/run snapshots under `research/coordination/confidence-snapshots/<timestamp>-master.json` containing `asOf`, `commitSHA`, `totalRecordUniverse`, `totalFields`, `perExpansion`, `perField`, `cumulativeFirstPass`, `recordsAllFourGe90`, `expectedQuantityGe90`, `numericMechanicsVerified`, `caveats`. If a breakdown is missing/unreliable, explicitly display unavailable and say which ledger is needed; never fill chart with guessed zeros. Previous snapshots are immutable. For comparable charts, track changes to total inventory/denominator separately.

## User-facing explanation
Give one concise paragraph translating what the charts show into what improved, what remains blocked, and whether source reuse is saving time. Always state: evidence confidence is 0–100 *strength of support*, NOT a measured probability the number is correct. Distinguish fully verified records from first-pass examined records and separately label historical-only and current-applicable values. Source-memory reward trend never increases confidence by itself.

Master QA owns snapshot creation and produces user-facing charts; workers supply field-level deltas and source/QA event stats. Keep research branch only. Do not change addon production files or task schedules.
