# Recipe coverage, Recycling evidence and build information

The old recorder set one `censored` flag on the entire study after an unmatched
successful craft. That also blocked complete observations of unrelated recipes.

New studies use coverage version 2. A persistent `coverageGaps` map keys failures
by `method:recipeID`, independently of the bounded diagnostic buffer. Missing
Recycling results still block that recipe's denominator. Other recipes remain
usable. The study's summary `censored` flag can stay true while unaffected
recipes are usable. Clean logouts resume the study with its recipe gaps intact.
Unclosed sessions, unsettled logout coverage and truncated records remain global
blockers. Lua baselines and the Python export validator apply the same policy.

Legacy studies lack a complete scoped gap ledger. They remain blocked except
for explicitly reviewed observations. The owner's requested review of the 200
Recycling casts is `coverage-review.json` beside the preserved 13 export pages.
It admits only those exact operations in their original contexts and original
first-gap metadata. Python checks source page hashes and resolved observation
signatures. A partial old diagnostic buffer is not treated as proof of arbitrary
legacy coverage. Original pages, flags and excluded observations remain intact.

`tools/recycling_capture_baselines.py` feeds 14 measured cohorts into the official
ItemDB compiler: 200 casts, 1,000 R1 Powder Pigment, 421 R1 Evercores, skill 21–35,
zero bonus skill and no specialization. Rows retain skill, bonus, specialization,
operation stats, input quality, game build and source IDs. Runtime matching
rejects unmeasured skill or changed bonuses. No interpolation, specialization
multiplier, guaranteed bounds or numerical confidence percentage is invented.
Shared and personal observations retain their study identity for deduplication.
`restored-baselines.json` records the new result; the initial all-excluded
`validated-baseline-review.json` remains as historical review evidence.

## Export

Processing Research > Export opens every retained cast in one JSON document,
selected for one Ctrl+C and one paste. Contexts, studies and diagnostics appear
once, rather than repeating across pages. A frozen snapshot and literal JSON
Unicode escapes preserve item links and measured evidence. Export pages remains
a fallback for destinations with smaller size limits. The regression copies all
301 records from the owner's 13 pages through the native popup and validates
that one document, restoring the same 200 Recycling observations.

## Main settings and provenance

PRs & build replaces the redundant Rates section on the main settings page.
View details shows branch, source commit, PR head when relevant, identified PRs
and Actions build URL. Main builds explicitly say no PRs beyond main. Combined
branch merge/squash commits can identify additional PRs beyond main. Unknown
metadata is labeled unavailable, never main-only. The game client makes no
GitHub requests. Every official package command stamps BuildInfo.lua; source
copies that bypass packaging remain explicitly unstamped/local.

Old global rate overrides are retired on load so a hidden setting cannot remain
active. Existing profession-specific character/Simulated/Don't show selections
and saved simulation profiles survive. Their display projections remain isolated
from actual profession access and recommendations.

The full tests/run.sh suite covers actual source data through native baselines,
compiled ItemDB and gold valuation, recipe gaps after diagnostic eviction,
same-recipe/global blockers, settings migration, one-copy export and build kinds.
