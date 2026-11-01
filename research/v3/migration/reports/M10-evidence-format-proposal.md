# Proposed changes to `research/v3/evidence-format.md` (M10)

Status: **proposal only.** `evidence-format.md` is owner-only and was not edited. Two choices below are marked **undecided**; the owner has to make
them before the wording is final. Everything else follows what the estimator and the importers already do (`SCHEMA-EXTENSION.md` has the full field
list and the reasons). Counts are from the merged evidence, 5,632 effective records, measured in MIG-011.

## 1. Fields agents should start writing

The format says unknown values are `null` and no field is left out, so each new field is optional for readers but, once adopted, written by agents as
`null` when unknown. **Exception: `unlockState` (section 3).**

| Field (on `drop`) | Proposed wording | Why, measured |
| --- | --- | --- |
| `castsBasis` | Set whenever you write `casts`: `reported` (the source states completed operations), `countedFromInputs` (casts = ore ÷ `inputsPerCast`, as README rule 2 allows), `derived` (any other computation, with a `derivations` entry), else `null`. | The estimator weights counted casts at 0.5 in the chance and 1.0 in the average (M06). Agents wrote counted casts without a basis on 398 rows (`M06-units-data.json`), so identical evidence is weighted differently from the imported copies. |
| `inputsProcessed` | The ore, herbs or items the source says went through the process, as stated. Never computed. | 434 agent totals state their input count only in `notes` ("10,000 ore, not casts") and are used at half weight or not at all. |
| `inputsPurchased`, `inputsRefunded` | Only when the source separates them from inputs processed. | They never change a count; they keep refunds out of the denominator. |
| `dataDateText` | Free-text period that is not an ISO date; keep `dataDate` ISO-only. | The estimator reads dates ISO-only since M08; prose in `dataDate` is ignored and the study is treated as undated (25% weight where a rate change applies). |
| `rawOutputName`, `rawInputName` | The item exactly as the source names it, when you cannot give an ID or a name that matches an item. | Name-only rows are stored but never placed by name (PLAN section 3 rule 4); the extractor already writes these. |

Not proposed for agents: `migratedFrom` (importers only), `observedOn` (importers set it from old files; agents use `dataDate`), `cohortKey`
(section 4), `derivations` is proposed only together with `castsBasis: derived` (`[{"field","formula","assumption"}]`).

## 2. Rules to state

1. `percentMeaning` must be `perCast` for a percentage to be used as a chance. 23 agent rows say `perInput`; they are stored and not used as chances.
2. `dataDate` is `YYYY-MM-DD`, `YYYY-MM` or a range. Anything else goes in `dataDateText`.
3. Search `research/v3/evidence/` for a source URL or thread before recording it (S17). `duplicateStudy` records went 148 → 363 between M08 and
   M10 because agents keep re-recording stored studies; the estimator absorbs exact copies and not partial ones.
4. **Record IDs (S18).** The reviewer's proposal, restated: `<agent>-<YYYYMMDD>T<HHMM>-<n>` (e.g. `midnight-20261101T0915-01`), no backfill. The
   validator counts 204 IDs reused across files (120 at M09). Today's rule, `<agent>-<YYYYMMDD>-<n>`, allows the clash.
5. **METHODS (M07).** Three `rateChange` records carry a method the format does not list (`Prospect and Mill`, `Dye Crafting`). **Undecided**,
   either: (a) add `Dye Crafting` and say a `rateChange` may name two methods in one string; or (b) say a `rateChange` takes `method: null` when it
   covers a method outside the four, and send the three records back for a correcting `replaces` record. Both clear the validator's 5 errors; the
   two ItemDB rows in that queue are unrelated and need `exclude` corrections.

## 3. `unlockState` — undecided

`unlockState` (`true`, `false`, or absent) would replace the estimator's search of `specialization`, `notes` and `stats` for phrases such as "max
knowledge". The estimator reads it first. The problem is the format's own rule, "write unknowns as `null`":

- **Option A, recommended: omit unless stated.** "Write `unlockState` only when the source states the unlock (`true` or `false`). Leave it out otherwise;
  never write `null`." The text fallback stays on for records without the field. Matches what the code does today (an explicit `null` means "source
  does not say" and turns the fallback off), at the price of one exception to the "never leave fields out" sentence.
- **Option B: treat `null` as absent.** Change `unlock_state()` (one line) so `null` falls back to the text, then the format can say "`null` when
  unknown" like every other field. Costs a small estimator change and a test; nothing in the data moves (no record sets the field).

Until one is chosen, **do not add `unlockState` to `evidence-format.md`.** If it is added with the "write unknowns as null" rule and the code is
unchanged, every new conditional study whose unlock is only in `notes` is left out of its estimate (`reports/M08-estimator.md` section 1).

## 4. What not to adopt yet

`cohortKey`: the estimator lets a key beat the fingerprint, so a keyed study never merges with an unkeyed copy and importers setting keys alone
would double-count agents' copies (`M05-identity.md`, proposal 4). Adopt it only if agents and importers set it together. Nothing writes it today.

## 5. How to apply

If the owner accepts section 1 and the rules in section 2 (items 1 to 4), the edit to `evidence-format.md` is: the five rows added to the `drop`
table, one line each for rules 1 to 3, and the ID rule changed. The estimator needs no change for any of it (all are already read). Nothing in this
file changes the format for existing records.
