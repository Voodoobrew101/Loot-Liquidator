# Cloud release requests

The owner explicitly approved the persistent bridge's tag-creation and workflow-dispatch authority on November 24, 2026. The enabled daily ChatGPT task can request publication with its existing GitHub file/branch tools; no PC, local credentials, extra long-lived token or new CurseForge secret is needed.

## Trust and execution

`community-release-request.yml` receives a push to `automation/community-release-request-*` with **read-only** permissions and runs no branch code. Its successful completion triggers `community-release-bridge.yml` via `workflow_run`. That privileged workflow lives on default main, checks out **main**, and executes only trusted main code. It never downloads request-run artifacts or executes request-branch scripts. It accepts requests only from repository owner ID 28468053, in this repository, including the re-run actor. The request commit must add/change only `research/community/release-request.json` in one commit above the selected production source.

The bridge has `contents: write` for new tags and the publication ledger, and `actions: write` for the existing publisher dispatch. Only ledger metadata may have advanced on main after the selected production SHA; newer code, data or policy stops an outdated request. The CurseForge token remains exclusively in the existing publisher. GitHub Actions-created tag events do not recursively trigger another build; the bridge explicitly dispatches the publisher instead.

## Publish protocol

1. Integrate reviewed new community data into latest main, including the next unused stable patch version in TOC/Core/changelog and freshly compiled database. Record its exact production commit SHA. Wait for **Validate consolidated addon** on that exact main commit to succeed.
2. Read current `research/community/daily-state.json`. Resolve previous uploads first. Add one publication intent to main in a **separate metadata commit after** the production commit is known. Do not put a commit's own SHA into that same commit. The intent is:

```json
{
  "tag": "v1.0.2",
  "sourceSHA": "EXACT_40_CHARACTER_PRODUCTION_COMMIT",
  "previousTag": "v1.0.1",
  "bridgeRequestID": "community-20261125-001",
  "status": "ready-for-bridge",
  "reviews": [
    {
      "submissionKey": "issue-123-0123456789abcdef",
      "submissionSHA256": "EXACT_64_CHARACTER_SUBMISSION_HASH",
      "reviewSHA256": "EXACT_64_CHARACTER_CANONICAL_REVIEW_HASH"
    }
  ]
}
```

3. Using the GitHub connector, create branch `automation/community-release-request-community-20261125-001` **from that exact production SHA**, not the later metadata commit. Create only `research/community/release-request.json` in a single commit on that branch:

```json
{
  "schemaVersion": "loot-liquidator.community-release-request/1",
  "requestID": "community-20261125-001",
  "mode": "publish",
  "sourceSHA": "EXACT_40_CHARACTER_PRODUCTION_COMMIT",
  "version": "v1.0.2",
  "previousTag": "v1.0.1",
  "reviews": [
    {
      "submissionKey": "issue-123-0123456789abcdef",
      "submissionSHA256": "EXACT_64_CHARACTER_SUBMISSION_HASH",
      "reviewSHA256": "EXACT_64_CHARACTER_CANONICAL_REVIEW_HASH"
    }
  ]
}
```

Examples illustrate shape only; copy actual submission/review hashes and use the actual next patch. `reviews` must exactly equal the durable intent's inventory. Hash review JSON with `tools/community_research.py`'s canonical `hashed()` helper. The bridge rechecks raw source bytes and reviews through the trusted intake compiler, requires the committed community database to reproduce, new reviewed cohorts absent from the previous release, and a changed compiled runtime. Metadata-only changes cannot publish.

4. Inspect **Community release request**, then **Community release bridge**. The bridge reserves the intent as `bridge-dispatching` before any POST, creates the new tag once, and dispatches `curseforge.yml` from that tag with `version` equal to tag and `publish=true`. The publisher redoes its full fresh compile/tests/ZIP checks before exposing its upload secret.
5. Read the bridge receipt artifact and exact publisher run. After the publisher succeeds, record the publisher run ID, ZIP SHA-256 and **actual final upload-step** CurseForge file ID in the ledger, setting status `uploaded`. Test logs contain a mocked file ID 123; that is never the real receipt.

## Dry run

Use a new request ID, `mode: "dry-run"`, and `reviews: []`. Both `version` and `previousTag` name the latest already uploaded tag. `sourceSHA` is a trusted main commit with matching source version and successful full main validation; the request branch still contains only one JSON change above it. No publication intent is added. The bridge creates **no tag**, records a one-time `bridgeDryRuns` entry and explicitly dispatches the existing publisher tag with **publish=false**. Inspect the resulting real build/package run and confirm its upload step is skipped. The dry run proves contents permission through ledger writes and actions permission through actual dispatch without making another release.

## Retry and race rules

POSTs are never automatically retried. Any request whose intent is already `bridge-dispatching` or `bridge-dispatched` is rejected on replay; a timed-out POST is not proof it failed. Inspect the exact tag, bridge receipt, publisher runs and CurseForge files. Keep unresolved attempts visible and reconcile before another request. Never move or recreate an existing tag, reset a reservation just to retry, or invent a new version to hide an uncertain upload. Main ledger writes use blob-SHA compare-and-swap; conflicting concurrent edits fail instead of overwriting another worker's state. The earlier reservation and receipt remain available even if a later status write conflicts.

Dry runs are similarly reserved by request ID before dispatch. Run a new dry-run request only when a new check is needed, not as an automatic retry of an unknown outcome.
