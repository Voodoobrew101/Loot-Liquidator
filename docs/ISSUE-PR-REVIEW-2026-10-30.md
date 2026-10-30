# Issue and pull request review — October 30, 2026

## Outcome and verified plan

The repository initially had two open issues and nine open PRs. Most addon PRs
were earlier stages of the consolidated alpha10 candidate in PR #12. Production
main is still 051f582 (v0.9.70). Review did not authorize a scientific-confidence
promotion or establish actual Retail compatibility.

The initial plan was to prove inclusion, validate the consolidated addon, compare
research changes, and close only superseded work. Review changed the plan in two
ways: importing the newest research wholesale would lose the mechanics export,
and nominally green research CI did not require a newly added failing array test.
The effective plan therefore repairs context integrity, reconciles both research
paths, requires the missing test, and refreshes the addon from that tested pin.

Completed steps:

1. Inspect all nine PR diffs/heads, descriptions, CI and review discussions, both
   issue specifications, branch ancestry and current source. No submitted reviews
   or inline PR comments were present during the initial inventory.
2. Prove PRs #4, #6 and #8 are ancestors of PR #12 (7a540b0). Confirm PR #1's
   validation purpose is replaced by package-aware checks; retain its non-empty
   TOC version check. Do not merge its obsolete root-layout workflow.
3. Reproduce research failures on 8954d24: nested snapshot 5/13 and array
   attestation 3/13. Repair both with detached lossless JSON snapshots and a
   mandatory source-pinned array gate. Document correction of one contradictory
   nonfinite-input fixture rather than admitting invalid contexts.
4. Trial-merge PR #11 with the moving research base; reproduce conflicts in the
   pipeline and generated report. Reconcile them, retaining every newer fixture
   and mechanics export test. Publish the combined candidate as draft PR #13.
5. Refresh alpha10's research snapshot to that candidate, regenerate all data,
   compare economic inputs, and rerun the addon checks. Add LF checkout policy
   because stock Windows autocrlf changed checksum-protected file bytes.
6. Close superseded PRs with a preserved-history explanation and successor link.
   Treat issue #5 as delivered implementation, with release acceptance tracked
   separately in PR #12 and the broader remaining research in issue #2.

## Disposition of every original item

| Item | Decision and evidence |
| --- | --- |
| #1 | Superseded by #12's package/load-order/XML, syntax and version checks. Its root-only TOC workflow is incompatible with the consolidated package. |
| #4 | Superseded by #12. Head 4053640 is an ancestor; the retained adapter regression passes. |
| #6 | Superseded by #12. Head 4599f8b is an ancestor; fixed-source and reversible-projection checks pass. |
| #8 | Superseded by #12. Head 42d86ae is an ancestor; co-output/partial-model and research-profile checks pass. |
| #9 | Superseded by #13's reconciled mechanics export and mandatory compiler tests. |
| #11 | Superseded by #13, which includes aca72a4 as a parent and resolves conflicts with the newer base. |
| #3 | Keep open. It has unique unmerged chronology, latent-context and forward-validation contracts/tools. Both Python suites (9 + 7 tests) and five Node suites pass; this does not establish coefficients or compatibility of the proposed schema with today's registry. |
| #7 | Keep open. Active research integration; 4,072 filled preview metrics are not verified evidence or exhaustive Retail coverage. Review #13 into this branch first. |
| #12 | Keep draft. Consolidated addon candidate passes automated checks, but Retail load/UI/event/addon integration, SavedVariables and large-bank checks remain mandatory. |
| #5 | Implementation delivered in #12, with source migration, weights, context isolation, recording, generated data and reviewable tests. Closing delivery does not approve release or assert science completeness. |
| #2 | Keep open, narrowed to remaining evidence, schema/API review and release gates; older one-GameData wording is historical and superseded by the later fixed-source design. |

## Findings and fixes

P1 — Research context provenance could mutate after analysis or lose array
metadata. See PR #13 and its research/reviews/2026-10-30-context-integrity-review.md.
Both models remain proposed confidence-zero previews. The unchanged array test
now passes 13/13; the corrected snapshot test passes 13/13. Existing lineage and
joint-cast suites pass 12/12 and 23/23; model self-tests pass 49 and 61 checks.

P1 — Research integration paths had diverged. Newer research had no normal-build
mechanics export; the reviewed export branch lacked newer isolation checks.
PR #13 retains both paths and runs their full validation. No real rule is added.

P2 — Documentation described incompatible historical states as current: old
source paths/counts and an 80-confidence/no-approval policy. Those documents now
carry historical-scope banners pointing here and to RELEASE-STATUS.md. Current
execution requires verified status, at least 90 confidence, two claims,
independent approval, validated transforms and exact applicability.

P2 — Windows newline conversion broke raw SHA-256 checks on an unchanged clone.
The .gitattributes policy fixes checkout bytes; the checks retain exact hashes.

## Source and economic validation

Research pin: d7bece6a30c411125e47c44a1b9932f505924e55 on
fix/research-context-integrity, source research/proposed/itemdb.lua. Exact checksum
is in database/research-itemdb-source.json. This immutable reviewed candidate is
used even while independent research continues on moving branches.

Counts remain 1,018 research mappings, 106 adapted primary records, 903
TSM-derived mappings deduplicated, nine rejected mappings, 130 grouped frozen TSM
records and 137 grouped legacy records (373 total grouped source records).
These units are different; none establishes exhaustive current Retail coverage.

Deep comparison against alpha10 confirms every primary record is unchanged
except researchRecord.workingEstimate metadata. Eight unsupported preview rows
now have confidence-zero policy-prior labels/assumptions. Their working numbers
cannot feed live EV. Actual material means, probabilities, bounds, applicability,
source evidence and frozen TSM/legacy bytes remain unchanged. The registry still
exports zero real numeric rules. Missing evidence remains unknown.

Local addon verification executes every tests/run.sh check using actual Lua 5.1
(Lupa on Windows), Python 3 and unchanged fixtures. Only Linux /tmp fixture paths
are redirected into workspace scratch files and text writes use LF bytes.
Results: 37 Lua syntax checks, all three reproducible databases, package/XML/load
order/version and source hashes, 453 modernization assertions, 49 projection,
57 research-profile, 87 recorder, 82 operation-capture, 13 Python export tests,
13 scaling checks, and the native Settings/metrics/token/import fixtures pass.
The standalone manifest-only ZIP contains exactly 22 files.

PR #13's full research pipeline --check passes locally and native Linux GitHub
CI passes. It includes deterministic artifacts, all mandatory independent
fixtures, JSON Schema with jsonschema 4.26.0 and Lua 5.1 roundtrips. This is
structural/synthetic validation, not independent scientific acceptance.

## Remaining actions and acceptance criteria

1. Review PR #13's snapshot implementation and corrected fixture. Accept only
   with all native CI gates green and preview-only policy unchanged. Merge into
   the active #7 branch only after review; recheck branch heads before merging.
2. Review #3's unique proposal against the current registry. Preserve useful
   chronology/replay contracts, adapt mismatches, and add CI before any schema
   adoption. Its passing static tests are not authority to ship a coefficient.
3. For issue #2, obtain independent, zero-inclusive current-build cast cohorts,
   exact recipe/batch/rank/skill/spec context, output-universe evidence and scoped
   numeric mechanics. Retain unknowns/conflicts until supported; confidence and
   economic eligibility cannot be raised merely to fill cells.
4. Execute docs/retail-qa.md on the actual client and record build, install hash,
   SavedVariables migration, Manual/Auto profiles, tooltips/EV, recording/refunds,
   bags/banks, ATT/TSM/BetterBags and performance results. No such run is claimed.
5. Recheck PR #12's head, CI and QA evidence, then request explicit promotion
   approval. Until then preserve main, the optional ATT dependency, and the zero
   approved-token/zero numeric-rule state. Do not merge the PR #10 revert.
