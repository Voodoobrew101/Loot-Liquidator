# Loot Liquidator — Quiet Research Dashboard

Coordinator-owned on-demand index. **Not an automation-health monitor.** A requested/resumed research session is not evidence that a worker has started or finished. Entries are updated only from each role's verified status report. Do not infer acknowledgement from the owner's authorization.

| Role / status file | Task | Last update (UTC) | Verified new evidence | Remaining gaps | Blockers | Next action |
|---|---|---|---|---|---|---|
| [Legacy](quiet-status/legacy.json) | Awaiting worker report | Not reported | None reported | Await worker's exact IDs and source links | No status file verified | Worker writes own status |
| [Dragonflight](quiet-status/dragonflight.json) | Awaiting worker report | Not reported | None reported | Await worker's exact IDs and source links | No status file verified | Worker writes own status |
| [War Within](quiet-status/war-within.json) | Awaiting worker report | Not reported | None reported | Await worker's exact IDs and source links | No status file verified | Worker writes own status |
| [Midnight](quiet-status/midnight.json) | Awaiting worker report | Not reported | None reported | Await worker's exact IDs and source links | No status file verified | Worker writes own status |
| [Coordinator](quiet-status/coordinator.json) | Establish quiet reporting; triage cross-expansion gaps | 2026-11-05 UTC (session; exact time not independently recorded) | Reporting contract established; **no new measured cohort claimed** | Source identity, denominators, unimported usable evidence, actual tooltip coverage | Original source validation and engine fixture pending | Check highest-value ready queue gap; update own status |

## Evidence freshness and interpretation

- **Verified new evidence** requires original source identity, exact recorded fields, and a repository evidence file or commit. A search-only record, repeated audit or copied cohort is **not** a new measured cohort.
- A status file's absence means **awaiting report**, not paused, inactive, failed, or completed. An owner's resume instruction authorizes work but does not verify an active hosted schedule.
- Input savings, total output units, per-operation hit probability, conditional yield, output rank, and current character eligibility are separate fields. Unknown values stay unknown.
- Historical Retail reference values may fill gaps with explicit provenance/uncertainty; MoP Classic examples are not Retail measurements. Unverified Multicraft stays off.
- Actual coverage requires compiled ItemDB + offline engine/tooltip checks with **synthetic prices**, and is not live-game verification.

## Ownership

Coordinator alone updates this aggregate dashboard and [coordinator status](quiet-status/coordinator.json). Each worker owns only its named quiet-status file and authorized evidence area. Do not overwrite another role's report, the protected implementation branch, or the immutable research snapshot. PR Director alone merges/closes PRs. No routine outbound notifications.
