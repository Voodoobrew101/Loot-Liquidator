# Coordinator evidence audit — newly archived Legion milling direct-stage outputs (2026-11-16T18:11:41.174Z)

**Research-only; no addon code, source mutation, new current Retail rate, estimated hit probability, gold valuation or live-client proof.** This is a fresh audit of Legacy's **17:56Z** original-source evidence, not the earlier 16:44Z MoP/Cata review. Worker evidence: [12 rows](../../evidence/legacy/2026-11-16T1756-legion-primary-mill-output-cohorts.jsonl) at source blob `a748bafa22e61d85ea37781c38faa69e0f2cee5b` on research head `37d96409201363b6c655995a3345e68feb7d1fb8`. Original pages were independently re-opened through indexed Wowhead source views:
- [Mass Mill Aethril — Queendom](https://www.wowhead.com/spell=209658/mass-mill-aethril)
- [Mass Mill Dreamleaf — jabbers](https://www.wowhead.com/spell=209659/mass-mill-dreamleaf)
- [Sallow Pigment — Ysosrslawl and danicadb1](https://www.wowhead.com/item=129034/sallow-pigment)

## Source-to-field crosswalk, without invented operations

Each number below is **source-reported output material units**. Right-hand rates are an *arithmetic input normalization*, `5 × material units / stated herbs`, i.e. material units **per five reported input herbs**, **NOT measured expected units per completed 5-herb mill**. No `castsWithDrop`, `P(hit)`, zero bins, stack histograms, source build or character profile is known. `inputsPerCast=20` for the first batch is a documented mass recipe, not a measured 200-operation log.

| Independent source/cohort | Herbs reported | Direct milling outputs (item ID, material units) | Per five stated herbs, same order |
| --- | ---: | --- | --- |
| Queendom Aethril **mass milling** | 4,000 | Roseate 129032 ×1,676; Sallow 129034 ×198; Yseralline Seed 128304 ×166; Gem Chip 129100 ×72 | 2.095; 0.2475; 0.2075; 0.09 |
| jabbers Dreamleaf **first batch before opening pods** | 1,020 | Roseate 129032 ×438; Sallow 129034 ×44; Seed 128304 ×30; Nightmare Pod 136926 ×23 | 2.147059; 0.215686; 0.147059; 0.112745 |
| jabbers Dreamleaf **independent follow-up before opening pods** | 1,005 | Nightmare Pod 136926 ×18 (only direct output separated in source) | 0.089552 |
| Ysosrslawl Aethril **normal non-mass milling** | 440 | Sallow 129034 ×21 | 0.238636 |
| danicadb1 Fjarnskaggl | 45 | Sallow 129034 ×6 | 0.666667 |
| danicadb1 Foxflower | 121 | Sallow 129034 ×6 | 0.247934 |

**Six independent author+input+batch cohorts, twelve output rows**, not twelve studies, and **zero newly confirmed completed-operation denominators**. Queendom's author states conditional average per *mass* mill (8.38 Roseate, 0.99 Sallow, 0.83 Seeds, 0.36 Chips), but `4,000 / 20 = 200` is at most a source-input batch equivalent absent an execution/refund ledger. Ysosrslawl specifically says **not mass-milled**; don't pool its rates as 20-herb mass results. Foxflower's 121 stated herbs aren't a multiple of five, independently preventing reconstruction of an exact 5-herb cast count from this source alone.

## Newly isolated output and recursion gates

1. **Direct cooutputs missing from pre-existing compiled evidence snapshot:** `research/v3/output/estimates.json` has exactly **eight** Mill entries across input IDs **124101/124102/124103/124104** — two each (Roseate 129032, Sallow 129034), all `studyCasts=0` and `averageSource="starting guess"`. There are **no** compiled Seed 128304, Gem Chip 129100 or Pod 136926 entries for those four inputs. This file predates the new worker evidence. Its omission is a **source-to-compiled candidate gap**, *not proof* the owner integration branch or live tooltip presently values them incorrectly.
2. **Nightmare Pod has a second processing stage.** Jabbers first reports **23 pods** from the 1,020 Dreamleaf milling, and **another 22 pods** while opening them, yet later reports having opened **55 pods**. `23+22=45`, so at least **10 additional pod openings or a source arithmetic/transcription ambiguity** are unaccounted for. The direct first-stage 23 is supported; neither 45 nor 55 is a safely reconstructable complete event histogram. The after-opening **745 Roseate/71 Sallow/51 Seeds** are *combined* outputs, not extra direct milling outputs. Follow-up 1,005-Dreamleaf batch similarly provides 18 direct pods, 24 secondary pods, but **773/73/85 pigments/seeds are combined after opening**.
3. **No double pricing of transformation stages.** Only if the actual game supports an automatically executable, separately documented Pod-opening conversion may an explicit multi-stage option price its output rather than simultaneously count the Pod sale and its contents. No additional current Retail eligibility or mass-mill unlock has been verified here.
4. **Historical epoch gate:** These comments originate in Legion-era activity without current 12.1.5 Retail build, skill, specializations, recipe unlock or eligibility receipts. Their material identities and raw quantities are useful as labeled historical evidence, *not current measured rates*. They cannot override compatible measured modern rates and cannot be promoted as full Retail coverage merely because the shared Wowhead pages remain visible.

## Independent bounded checks executed (not a compiler or addon run)

**65/65 in-memory JavaScript assertions passed**, zero failures, against the exact worker JSONL blob and checked compiled estimates. Verified 12 unique records, six distinct cohort input/method identities, all twelve original quantity/ID pairs, unknown cast/hit/histogram fields, eight compiled starting-guess rows, absence of three non-pigment cooutputs, and the pod arithmetic and 121-herb batch issue. Reviewed the three original source pages cited above. No Python research compiler, synthetic-price actual valuation, Lua formatter/tooltip, connected character, or live WoW test was executed. GitHub CI on the manager's *new commit* must be checked separately.

**Integration handoff, not addon modification:** Prioritize correctly scoped Pod/Seed/Chip cooutputs through the owner's protected three-pass ingestion/valuation/tooltip ledger *after* modern Retail processing legality is confirmed. Require actual 5-vs-20 input batch context and stage-aware output accounting, plus first-person 0-inclusive per-operation logs for any P(hit) or calibrated uncertainty. Do not ask Legacy to recollect these originals. Highest-value current-content task remains Midnight **T0039/T0005** complete rank/build/skill/refund+output-event ledger. Keep all original worker files, research compiler and worker schedules unchanged.
