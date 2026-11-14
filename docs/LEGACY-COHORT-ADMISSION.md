# Reviewed legacy original-cohort admission

This future-refresh guard holds three reviewed transcriptions at the Retail v3
adapter boundary. It does not correct raw research, alter estimator mathematics,
certify historical/current Retail applicability, or refresh the shipped snapshot.

## Exact scope

`legacy-20261110-24701` with studyKey
`wowhead-gee-comment-930224-14-headband-8-units` repeats the author930224 original
`legacy-20261106-004101`. The quotation says fourteen headbands **made**, not
fourteen independently enumerated completed disenchants. The new casts=14 creates
an unsupported expected-quantity denominator. Eight reported essence units remain
preserved in both raw files; the original's unknown casts remain unknown.

`legacy-20261110-24703` and `legacy-20261110-24704` with shared studyKey
`wowhead-looter-186057-7-cumulative-tbc-wotlk-mirror` repeat canonical
`legacy-20261106-601` and `legacy-20261106-602`: one cumulative seven-operation
Communal Warmaul cohort, six essence hits and one Dream Dust hit. TBC/WotLK mirrors
are not fourteen independent operations. Both materials already exist in the
canonical evidence. New dust totalQuantity=3/histogram={3:1} are display deductions,
not a newly observed per-operation unit ledger.

The policy matches global exact **record ID OR studyKey**, not a file, item, URL,
expansion, author or text pattern. A renamed/moved record retaining either reviewed
identifier remains held. A copy changing both identifiers needs another review.
Independent studies and all existing policy rules remain unchanged.

**Preserve `legacy-20261110-24702`.** Its separate key
`thottbot-gee-approx25-runecloth-one-positive-two-units` does not match this hold.
The source explicitly reports one positive disenchant yielding two units. New
machine-readable min/max2 enrich the earlier original `legacy-20261106-004102`;
casts remain unknown and add no denominator. This valid range must not be removed
by a blanket four-row hold. `legacy-20261110-24705` also remains untouched: two
historical Illusion Dust units without a completed-cast denominator, not usable
numeric counts. Its full source overlap has not been established here.

The Nov8 Warmaul copies already deduplicate counts; Nov9 copies also deduplicate
counts but retain displayed ranges. This narrow fix does not certify those ranges
as independently observed event extrema or solve their wider semantics.

## Evidence and ownership

[Master's source audit](https://github.com/Voodoobrew101/Loot-Liquidator/blob/b1d16dfc859907fbe8ce7615169f2d630ee22d58/research/v3/evidence/master/2026-11-10T0303-legacy-original-cohort-dedupe-and-denominator-guard.md)
identifies the repeated originals and false denominator. The original source files
are copied byte-for-byte into `tests/fixtures/legacy-cohort-admission/`; SOURCES.json
pins their research paths, SHA256 hashes and revision c835cedee983b4347b87621d366b9a5900582b17.
Source fixture validation fails on byte changes.

Legacy's append-only source correction remains separate. At the reviewed research
revision the exact source/corrections/conditions remained unchanged. Recent Legacy
work on other items does not establish execution of this correction. T0050's queue
entry concerns older400/43-cast Headband studies, not explicit assignment of these
three exact row corrections. No source-owner status or shared research file is
changed by this guard. A future corrected source retaining held identities needs
review before this exact-identity hold is lifted.

## Ordering and limits

`calculator.load()` first applies replacements and corrections. The existing
adapter then resolves output identities and applies this admission policy before
both its published-range and real-study count passes. No pre-load gate or
replacement restoration is introduced. A held replacement could already suppress
an unrelated row; the policy cannot restore it. All retained real source rows have
replaces=null. Tests exercise correction-before-gate and replacement semantics.
Reference/TSM/compiled-research source-kind changes cannot bypass the hold or leak
held ranges into the published pass. Policy order does not affect admission.

## Reproduction and acceptance

Focused tests cover exact source identity, original-policy failure, false quantity
denominator, duplicate within-estimate chance weights, unsupported measured dust
quantity, preservation of24702/24705/canonical sources, independent controls, global
ID/key aliases, both estimator passes, source kinds, policy permutations and loader
ordering. Tests also run under Python -O.

Complete diagnostic comparisons against frozen research c835cedee, on standalone
PR52 and published-only PR51–64 bases, preserve ordered record IDs and every other
complete record. Only `evidence:v3:Disenchant:13866:x1` and
`evidence:v3:Disenchant:186057:x1` change; no records/materials are dropped.
Headband essence quantity EV0.5402 becomes0.5393 and weighted quantity denominator
267.5 becomes260.5; its complete range/chance fields, including minimum2, stay
identical. Warmaul per-material chance weights7 become3.5, confidence32 becomes24;
Dream Dust expectedQuantity stays3/7 but changes measured to provisional. These
are future-refresh diagnostics, not claims of shipped or live-game regressions.

Compiler comparisons execute actual Lua5.1 through Lupa2.8 and reviewed PR58 test
wrappers. Diagnostic inputs use current research processing with unchanged pinned
tokens/restrictions; fixture category omission is consistent between comparisons.
They are not a production snapshot update or live WoW validation. The shipped
pin4df9ae8, generated database, addon runtime and version remain byte-identical.
No confidence coefficients, rates, new actual casts, price/gold forecasts, broad
Classic blacklist, pending cohort admission, merge or release is introduced.
