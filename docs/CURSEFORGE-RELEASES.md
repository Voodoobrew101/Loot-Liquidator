# CurseForge version-tag releases

Destination: [Loot Liquidator by Voodoobrew](https://www.curseforge.com/wow/addons/loot-liquidator), project **1760478**.

## One-time credential setup

1. Open **API Tokens** in your [CurseForge Authors account](https://authors.curseforge.com/) and generate an upload API token using the account that can upload to project 1760478.
2. Open [repository Actions secrets](https://github.com/Voodoobrew101/Loot-Liquidator/settings/secrets/actions) and add a repository secret named `CURSEFORGE_API_TOKEN` with that token. Do not put the token in source files or chat.
3. Merge the publishing workflow before creating a release tag. The tag must point to a commit containing `.github/workflows/curseforge.yml`.

## Publishing

After owner review and the existing Retail QA/release gates, push a version tag on the approved commit, for example `git push origin v0.12.42` after creating that tag locally. Creating a tag only on your computer does not trigger GitHub Actions.

Supported tags: `v0.12.42` or `0.12.42` (release), `v0.12.42-alpha.1` (alpha), `v0.12.42-beta.1` (beta), and `v0.12.42-rc.1` (beta). Other suffixes fail validation. Choose a new version for every upload.

The workflow compiles the committed research snapshot, runs the full addon suite, stamps the TOC and runtime version from the tag in the build workspace, packages only manifest-declared files, verifies ZIP checksums, saves a build artifact, and uploads that ZIP. It does not refresh research or commit generated files/version changes back to GitHub. Existing PR version bumps and manual distribution builds continue independently.

Supported WoW versions are resolved from the tagged TOC's Retail `## Interface` numbers against CurseForge's versions API; a missing or ambiguous match stops the upload. Keep the tagged TOC current for the client versions you have tested. The upload uses `CHANGELOG.md` from that tag if present, otherwise a short version/tag note. CurseForge approval still controls when the file becomes available.

## Validation and recovery

Pull requests changing the release workflow/helper/tests run the complete build without uploading. In Actions, manually run **Publish version tag to CurseForge** with a version to perform the same validation without uploading; manual runs never publish. The artifact includes `LootLiquidator.zip`, its SHA256 checksum, and upload metadata. No CurseForge token is needed for either validation path.

Only a tag push reaches the upload step. Missing credentials, failed tests, packaging errors, or an unknown game version stop publishing. A successful upload prints the returned CurseForge file ID and file URL in the job summary. The upload POST is never automatically retried. If an upload fails after being sent, inspect the project's files before rerunning the job to avoid a duplicate. Recreating or force-pushing an existing tag can also duplicate an upload; use a new version instead.

GitHub Actions does not normally start another workflow for tags created using a workflow's default `GITHUB_TOKEN`. Push the tag yourself using normal Git credentials. Existing `build-*` prerelease tags are excluded.

API reference: [CurseForge Upload API](https://support.curseforge.com/support/solutions/articles/9000197321-curseforge-upload-api).
