# Research context integrity review — October 30, 2026

Base: implementation/five-agent-completion at 8954d2402e29e3053812558a73c6b56453223436.

## Reproduced problems and correction

P1: Midnight anytime bounds retained nested specialization, gear and unlock
objects by reference. Later caller mutations changed the returned context without
changing its already serialized identity. Nonfinite/unsupported nested values
also collapsed or disappeared in JSON. The original snapshot fixture passed 5/13.

P1: Dragonflight joint-cast validation examined enumerable array keys rather than
all property descriptors. Symbols, hidden metadata, sparse arrays and custom
serialization hooks could be discarded or execute during JSON serialization.
The unchanged independent array fixture passed 3/13.

Both models now use a detached recursive snapshot that admits only finite JSON
primitives, plain objects and dense ordinary arrays with enumerable data properties.
It rejects cycles, custom prototypes, accessors, hidden/symbol properties and
unsupported nested values. Shared acyclic input objects are copied independently.
Model manifests pin both their own source and the shared implementation. The
array fixture now runs as a mandatory source-pinned native pipeline gate.

One snapshot fixture was internally contradictory: preceding cases required
NaN/Infinity rejection, while another tried to analyze those same invalid inputs
and compare resulting keys. That case now requires rejection of both inputs.
Its hash is explicitly re-pinned. This is a documented test-contract correction,
not an independent review or permission to accept invalid values. The fixture
author/maintainer should review this change before merging.

## Validation and limits

Native Node: unchanged array fixture 13/13, corrected nested snapshot fixture
13/13, unchanged Midnight context/lineage fixture 12/12, unchanged Dragonflight
adversarial fixture 23/23. Model self-tests pass 61 and 49 assertions. Added
snapshot tests cover cycles, shared references, sparse arrays, invalid nested
types, non-executed getters and literal __proto__ keys.

The full completion pipeline --check passes locally, including deterministic
artifacts, existing independent fixtures, JSON Schema and Lua 5.1 roundtrips.
On Windows, the Lua CLI uses Lupa's actual Lua 5.1 runtime and the Python CLI uses
the pinned jsonschema 4.26.0 dependency; Linux CI remains the canonical runner.

Both models remain PROPOSED, confidence zero, PREVIEW_ONLY and unverified. No raw
measurements, admitted mappings, coefficients, economic eligibility or production
addon values are promoted. Real Retail cohorts, independent scientific review,
output-universe validation and live-client QA remain outstanding.

## Reconciliation of PR #11 with the moving research base

A trial merge reproduced conflicts in the generated build report and native
pipeline. This branch reconciles integration/research-current (aca72a4) with the
current PR #7 base: retain every newer source-isolation fixture, restore the
reviewed mechanics compiler and mandatory mechanics tests, then regenerate the
candidate/build report from the combined sources. Both paths run in the full
passing pipeline. The real registry still exports zero approved numeric rules.
This replaces the overlapping changes in PRs #9 and #11 without merging either
the research branch or the production addon automatically.
