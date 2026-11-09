# Preserve current token semantics during research refresh

This is a narrow source-admission guard, not a research snapshot refresh or a
claim of live Retail eligibility. Main base is
`b6610848604f68f8f3b40834397b79ce53eb8fb5`; the reviewed research revision is
`790686e5b7efbb9b6b56bec91179b5dc28084550`.

## Evidence and failure

Three research rows explicitly identify **historical** vendor relationships and
say the modern tooltip instead describes Use / loot-specialization creation:

- `legacy-20261107-234113`, token 45661, in
  `legacy/2026-11-07T2341-saronite-30stack-wayward-token.jsonl`.
- `legacy-20261109-94008`, token 45658, and `legacy-20261109-94009`, token
  45643, in `legacy/2026-11-09T1651-missing-smelts-and-wayward-25-rewards.jsonl`.

Paths above are relative to `research/v3/evidence`. The unmodified files,
original current-use row `legacy-20261101-216`, and the research coordinator's
45661 identity review are retained in `tests/fixtures/token-source-applicability`.
Its manifest records immutable same-repository URLs, Git blob IDs, SHA-256 and
byte counts. No third-party source was newly collected or rewritten.

The generator previously treated any surviving `howRedeemed=vendor` claim as a
current exchange. For 45661 this changed the existing independent v3 opening
record into an unknown-cost choice. For 45658 and 45643 the new v3 exchange
records precede and shadow PR50's ATT opening/class records in the compiler,
losing their reward class masks. The seven reward IDs match in each case; this
is an applicability and precedence defect, not a request for new destinations.

## Admission boundary

`database/research/token-admission.json` holds only those three exact source
file / record ID pairs. `token_admission` runs before replacement resolution,
grouping, names, completeness, source URLs, reward claims and redemption-mode
selection. Held claims cannot replace a valid row or leak into its metadata.
Raw evidence and all pinned research/runtime files remain unchanged.

This follows the identity-admission approach of numeric research guards without
introducing a dependency on their processing-cohort policies. Policy structure
is validated and malformed or missing policy files fail the build. Evidence
URLs are attributed review references, not automatically verified approvals.
An explicit empty exclusion list is valid.

There is no global vendor rejection, item blacklist, date inference, URL or
notes-text classifier. Independently identified same-token vendor evidence
still produces an informational exchange with unknown full costs. Reused IDs
in other files are not the reviewed identity and remain subject to ordinary
source rules. Renamed/copied sources or new record identities require further
review; this is not comprehensive historical-evidence detection. Existing
correction/replacement behavior outside the held identities is unchanged.

## Validation

- 13 focused Python tests cover exact immutable bytes, original failure,
  independent vendors, reused IDs, held-only input, replacement/metadata
  contamination, existing exclusions, missing/malformed policies and equality
  of every pinned token record, note and conflict.
- Compiler fixture adds all three real historical rows to current pinned input.
  Guarded compilation is byte-identical to the shipped database, including all
  307 token entries and ATT class masks. The original counterfactual reproduces
  all three regressions through actual `TokenRedemptionCost`: known one-token
  opening becomes unknown-cost/unavailable exchange. API values are synthetic
  test inputs, not live-client evidence.
- Complete research 790686e5 replay: original 239 v3 token records becomes 237,
  removing only the historical-only 45643/45658 candidates so ATT remains the
  compiler fallback. 45661 retains its independent current-use row. All other
  generated records and conflicts are identical. Notes report three holds and
  three fewer unknown-cost vendor rows.
- Integration with immutable PR56 head
  `1a6522db7f4a3aa3027c841a949c898064cdd95a` preserves pinned output; on full
  research the only additional difference is its intended 270909 direct list
  of 20 intermediate tokens. Candidate/review/full-cost holds remain intact.
  Neither PR56 nor the shared compiler is changed by this patch.

Current generated baseline checks and compiled-file equality must pass without
regeneration. Local full-suite validation uses Lupa 2.8's actual embedded Lua 5.1
with the reviewed PR58 wrappers; it is not a native executable or live game.
Exact published-head native CI is required separately.

## Remaining limits

Current Retail class/use-level/bonus/availability still needs live validation.
The guard neither supplies exchange costs nor promotes eligibility, review,
confidence or probabilities. The seven curio full-cost holds and 237602's
conflicting source lists remain separate. Research task T0053 remains owned by
the legacy source researcher; its stale queue wording is not changed here.
No snapshot refresh, PR50 rewrite, merge, release or auto-merge is authorized.
