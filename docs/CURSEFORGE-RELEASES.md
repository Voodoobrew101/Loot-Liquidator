# CurseForge builds and explicit publishing

Destination: [Loot Liquidator by Voodoobrew](https://www.curseforge.com/wow/addons/loot-liquidator), project **1760478**.

Normal builds do not upload to CurseForge. A version-tag push, pull-request validation, or default manual run builds and verifies an artifact only. The existing public release and installed CurseForge copy remain unchanged until an explicit publishing run succeeds.

## One-time credential setup

1. Generate an upload API token in your [CurseForge Authors account](https://authors.curseforge.com/) using an account permitted to upload to project 1760478.
2. Add it to [repository Actions secrets](https://github.com/Voodoobrew101/Loot-Liquidator/settings/secrets/actions) as `CURSEFORGE_API_TOKEN`. Do not put the token in source or chat.
3. The selected release tag must contain the workflow with the explicit `publish` input. Older tags are not changed or recreated to add that option.

## Build and test without publishing

Push a supported version tag, or manually run the CurseForge build workflow with a valid `version` and leave **publish unchecked** (the default is false). Pull requests changing the workflow or its release tests also validate without uploading. No CurseForge token is passed to these build-only runs.

The workflow compiles the committed research snapshot without refreshing it, runs the full addon suite, stamps the build-workspace version, packages only manifest-declared addon files, verifies ZIP checksums, and saves an artifact. It does not commit generated data or version changes. The artifact includes `LootLiquidator.zip`, its SHA256 checksum and release metadata; tests and raw research are excluded from the installable ZIP.

## Publish deliberately

After owner approval and the existing QA/release gates:

The owner's community-research request supplies standing approval for the scoped
daily task in [the maintainer runbook](community-research-maintainer.md): reviewed
player evidence may be integrated into the newest production addon and published
as a new tested patch when shared data changes. That task still makes the explicit
matching-tag `publish=true` dispatch below. Ordinary builds and tag pushes remain
build-only, and unrelated changes do not inherit this approval.

1. Create and push a **new version tag** on the exact approved commit. The tag must already exist remotely, point to a commit on main, and contain this opt-in workflow. Its push builds/tests an artifact; it does not publish.
2. Manually run the workflow **from that tag**, using the same exact text in the `version` input. For a future approved tag `v1.0.1`, select `v1.0.1` as the workflow ref and enter `v1.0.1` as the version. GitHub's workflow-dispatch API/CLI can select a tag if the UI ref picker does not show it.
3. Explicitly check **publish**. A checked request from a branch, or a version that differs from the selected tag, fails before the build/upload proceeds.

Only a manual dispatch with `publish=true` on the matching tagged ref can reach the upload step, after all mandatory build/tests/package checks pass. Checkout remains on the dispatch tag, so the actual source commit, version, pinned research and build provenance agree. No source branch or alternate checkout is substituted for that tag.

Supported versions include `v1.0.1` or `1.0.1` (release), `v1.0.1-alpha.1` (alpha), `v1.0.1-beta.1` (beta), and `v1.0.1-rc.1` (beta). Other suffixes fail validation. Use a new version for every upload; the examples do not authorize creating a release.

Supported WoW versions are resolved from the tagged TOC's Retail `## Interface` values against CurseForge's versions API. A missing or ambiguous match stops upload. The changelog comes from that tag's `CHANGELOG.md` when present. CurseForge approval controls when an uploaded file becomes available.

## Failure and recovery

Missing credentials, failed tests, packaging/checksum errors or an unknown game version stop publishing. A successful upload prints the returned CurseForge file ID and URL in the job summary. The upload POST is sent once and is never automatically retried. If a request fails after being sent, inspect the project's files before another explicit publishing run to avoid duplicate uploads. Do not force-push/recreate a released tag.

References: [GitHub workflow dispatch and inputs](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onworkflow_dispatch), [CurseForge Upload API](https://support.curseforge.com/support/solutions/articles/9000197321-curseforge-upload-api).
