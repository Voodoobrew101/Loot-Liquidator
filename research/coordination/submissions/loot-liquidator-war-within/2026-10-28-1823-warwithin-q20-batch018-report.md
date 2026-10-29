# Loot Liquidator — War Within worker, queue20 / batch018
**2026-10-28 · research-only · master-assigned Dragonflight/Shadowlands overflow**

## Assignment and outcome
Read LIVE `research/coordination/assignments.json` revision **20**, assignment `2026-10-28-batch018-war_within`, plus batch017 master verdict, source-memory, research-lessons and prior War Within submission/source reviews. The War Within native scope was exhausted; the master explicitly assigned **35 overflow source-alternative keys** (34 Dragonflight, one Shadowlands). All **35/35** were audited; all **35 GameData.lua source-line/output IDs matched** blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`. No self-claimed keys. Base branch HEAD at start: `2ad202077f9b5b11c22f014bc7b5c9d1776f6b1c`.

**New legitimate conversion mappings: 0. New current-Retail measured numeric fields: 0. New independent cast cohorts: 0.** Historical source-reference positive bounds reused: **70/140 field slots** (35 min + 35 max at 20/100 source-reference confidence); remaining **70/140** exact-context fields (35 occurrence probabilities and 35 unconditional expected quantities) remain unknown. These are *not* 70 newly measured numeric fields.

## P0: Source-field semantics can create impossible probability/EV tuples
For **35/35** assigned rows, raw `matRate > amountOfMats` (for example Serevite R1 `190395 → 192837`: 0.125 versus 0.0252; First Flower `187699 → 175788`: 1.0 versus 0.5). If `matRate` were independently treated as P(at least one unit) and `amountOfMats` as unconditional E in the same completed-operation units, this would violate **E >= P** for positive integer outputs. Therefore **neither source field was promoted to independently observed P or E**. This is a **semantic/basis mismatch warning**, not proof that TSM's source fields themselves are wrong; exact TSM derivation and units are not documented in the pinned GameData row.

## P2: Dragonflight quality-rank triple-counting
**28/28** assigned target-rank-one prospecting rows have adjacent rank-two and rank-three alternatives with identical `matRate` and `amountOfMats`. The remaining seven rows are six unranked prospecting byproducts and one Shadowlands pigment. Treat the repeated family references as **rank alternatives**, not three simultaneous independent material drops. Unconditional E by exact output rank remains unknown without a skill/ore-rank-matched cast histogram. The 2022 Jallfo beta study (R3 ore) and December 2022 R2 Serevite 1,000-cast original do not justify assigning their rank-specific results to all 2026 ore-rank contexts.

## P0: First Flower mass-milling operation is not the five-herb TSM row
The **reused** original March 7, 2022 BullDozzer report records **4,000 First Flower, 200 completed Mass Mill First Flower operations**, and **1,984 Tranquil Pigment**: historical **9.92 per 20-herb mass operation**, plus 972 Umbral and 1,031 Luminous. Original: https://www.reddit.com/r/woweconomy/comments/t8lubc ; independent recipe confirmation: https://www.wowhead.com/spell=359490/mass-mill-first-flower (20 herbs, Shadowlands Inscription). The assigned `GameData.lua:L1932` row is a generic TSM milling reference with `minAmount=2,maxAmount=3`; it is not a measured 20-herb mass-operation tuple. **No numerical replacement or cross-operation scaling** was made. Actual current-client standard-five-herb and mass-20-herb eligibility and their separate histograms remain unverified.

## P1: Four-field discipline and evidence provenance
Each assigned key has separate `dropChance`, `yieldMin`, `yieldMax`, and `expectedQuantity`, with value/status/confidence/source/patch/denominator. All unknowns remain null; no absent output was converted to zero. The 70 numeric bounds are low-confidence **TSM-derived historical positive-outcome references**, not observed 2026 bounds. No `matRate` was mistaken for P(hit); no `amountOfMats` was mistaken for E. Input Resourcefulness savings must not be counted as output, and a price comparison requires a full current TSM snapshot.

## Source novelty and continuous improvement
Sources **reused**, not newly counted: pinned `GameData.lua`, original BullDozzer mass-mill report, December 2022 R2 Serevite cohort, Jallfo beta, and Wowhead Dragon Isles Prospecting spell 374627 (five ore). Derivative Wowhead reposts of the BullDozzer numbers are not additional independent studies. Five source-review events capture missing fields and deliberate no-refetch decisions. Novel accepted-value yield **0**, new independently measured data **0**, useful negative findings **35 source-semantic conflicts + 28 rank-copy safeguards**. No reward points altered evidence confidence.

## Master handoff — exact next IDs
1. `190395 → 192837/192840/192843/192846` (Serevite R1), then `190396 → 192837/192840/192843/192846` (R2): actual zero-inclusive per-cast rank histograms with skill, gear, Inspiration, Resourcefulness and current patch.
2. `190394 → 192849/192852` (Serevite R3): confirm output-rank eligibility, compare against the beta Jallfo study without reusing beta rates as 2026 truth.
3. `187699 → 175788`: distinguish standard five-herb milling from Mass Mill First Flower spell 359490 (20 herbs), and test exact 2026 eligibility/conditional yield.
4. Master compiler QA: reject any candidate where raw TSM `matRate` and `amountOfMats` were independently promoted as same-basis P and E, and prevent triple-counting target-rank alternatives.

## Validation and boundaries
35/35 assigned stable keys unique, 35/35 source-line identities, 28/28 ranked triplet repeats, 35/35 raw semantic mismatch flags; 140/140 field slots classified. Static checks only; Node CLI, Lua interpreter and in-client Retail testing not performed. All writes restricted to unique worker-owned files under `research/processing-confidence`. No main, production Lua/TOC, shared master ledgers, assignments, canonical registry, source-memory or schedule changes.
