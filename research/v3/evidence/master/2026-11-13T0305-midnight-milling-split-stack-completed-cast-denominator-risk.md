# Midnight milling: split stacks and interrupted queue are a completed-cast denominator risk (source audit)

**UTC checkpoint:** 2026-11-13T03:05Z  
**Manager scope:** research only; T0045 primary; T0039/T0005 analogous prospecting/event-count acceptance.  
**Evidence class:** firsthand player reports of crafting-queue interruption, **not** new ingredient/output observations, not proven current 2026-11-13 game behavior. No independent in-client reproduction.

## Newly traced original reports

1. [Blizzard Gameplay Professions thread, *Milling Tranquility Bloom Bug*, March 28, 2026](https://us.forums.blizzard.com/en/wow/t/milling-tranquility-bloom-bug/2281630): Dakkon reports repeated one-at-a-time milling interruptions. Almandris reports queue stopping after one combine when inputs are split between bag and Warband Bank. Reikah advises re-stacking; Draggoth reports a 1,000-herb stack plus a second stack can halt a requested sequence when the smaller stack exhausts. These are authors' contemporaneous experiences and hypotheses, not a controlled test or precise completion tally. The phrase about a stack below 20 is **not** proof that Midnight milling consumes 20 per recipe; do not convert it into a batch-size change.
2. [Blizzard Bug Report, *Create All button frequently fails to work*, September 17–October 2024](https://us.forums.blizzard.com/en/wow/t/create-all-button-frequently-fails-to-work/1958838): multiple users describe auto-selected first-stack and Warband Bank behavior for milling/prospecting/crafting; some posters disagree about exact cause and workaround. Earlier expansion context demonstrates a plausible mechanism; it is **not** direct current-patch reproduction.
3. [Blizzard housing/inventory feedback, December 4, 2025](https://us.forums.blizzard.com/en/wow/t/feedback-housing-dyes-and-inventory-management/2209314): one firsthand writer says odd herb stacks can block milling until reorganized. This concerns Retail housing dye-processing and does not establish Midnight Inscription material yields.

These sources have distinct original post authors and dates. They support a **risk of planned/requested operations exceeding actually completed operations**, not a numerical probability of interruption, measured failure rate, material refund coefficient, or current game build guarantee.

## Impact on currently queued numeric records

- T0045 already references a Powder Pigment 245807 total **1,305** for an original report mentioning **1,000 Tranquility Bloom 236761** herbs. Arithmetic **1,000 / 10 = 100 nominal ten-herb batch equivalents** and **1,305 / 100 = 13.05 pigment units per nominal batch** is only a *conditional normalization*. The original's completed mill count, whether 1,000 denotes starting/consumed herbs, queue interruptions, Warband Bank splits, saved/reprocessed herbs, tool, skill, and raw 0..N histogram remain unknown. No evidence says that source actually experienced an interruption. Do not relabel 100 as observed casts or 13.05 as a measured, conditions-matched mean; do not replace existing labeled 4.5 prior using this check alone.
- T0005/T0039 Umbral Tin similarly require **completed Prospect events** rather than number selected under Prospect All or nominal ore divided by five. Stack selection and refunds could matter; these specific sources do **not** establish that Cardinalai's explicitly reported 800 completed prospects were interrupted or miscounted.
- A direct source containing **completed-operation logs** can establish a denominator even without a bank/inventory ledger. When only inputs and outputs exist, retain a clearly labeled per-nominal-input reference rate and its provenance; do not manufacture castsWithDrop, zero histograms, P(hit), item ranks or savings.

## Exact requested evidence from original researchers

For any high-priority current-patch rerun/export, capture: **recipe ID and actual batch units; per-operation success/completion event; input itemLink and quality; per-output linked item ID, rank and exact 0..N quantity; observed completed total; UI-requested queue length separately; before/after bag and Warband Bank stacks if a stop occurs; Resourcefulness savings and any reprocessed refunds; profession skill/spec/unlocks; live build/date**. Source-reported starting stock and intended queued jobs must not silently become completed casts. A worker or tester may reproduce the interruption in a controlled native client, but this manager did **not**.

## Disposition / validation

**Newly verified:** original source identity, chronology and the existence of multiple independently described interruption reports, plus the distinction between nominal/queued/completed operations. **Not verified:** interrupted operation count in either original data cohort, probability of interruption, extra outputs, current-patch persistence, any numerical correction to existing rates, additive Multicraft or present Retail gold/tooltip impact.

Checked current T0045/T0005/T0039 queue, prior coordinator dashboard/strategy for this specific source and split-stack failure mode (no prior mention of Blizzard forum thread 2281630, Dakkon or the split-stack denominator issue), and current worker status ownership before adding this source-only audit. No researcher source JSONL, queue, strategy, mechanics, main, addon, implementation branch, PR or schedules changed. No estimator, compiler, Lua, synthetic-price runtime/tooltip, client or WoW tests executed.

**Next:** worker-owned original T0045/T0005/T0039 at-cast logs with exact output rank and actual completions; rank/order/refunds before valuation. Do not turn these interruption anecdotes into a new yield cohort.
