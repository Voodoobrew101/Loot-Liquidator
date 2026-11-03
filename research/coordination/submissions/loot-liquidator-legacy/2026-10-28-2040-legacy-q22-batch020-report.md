# Loot Liquidator Legacy — Batch020, queue revision 22
**2026-10-28 20:40 America/Los_Angeles · worker loot-liquidator-legacy · research-only branch**

## Outcome
- Audited **40/40 exact master-owned keys** (9 BfA mass-milling, 1 Titanium Powder, 6 Legion Felslate, 12 WotLK Cobalt/Titanium, 12 MoP Trillium), 40 unique; **30/30** assigned GameData source lines checked against main, 0 mismatches.
- Four-field audit: **160 slots** = **75 historical references** (9 already documented BfA historical completed mass-cast E; 60 TSM source-range references; **6 newly sourced 2009 PTR Titanium common-gem completed-cast E**) + **85 unknown**. These are NOT 75 current-Retail validated fields.
- **Zero new legitimate output mappings, zero new verified current-Retail numeric fields, zero current-Retail unskilled baselines.** Two newly indexed independent historical author cohorts (one 2009 Retail predecessor PTR with actual cast denominator; one 2023 WotLK Classic PTR gross-input-only), not two current-Retail experiments.

## P0/P1 — high-value new historical cast denominator
The original 2009 PTR commenter **kuraiummei** reports 720 Titanium Ore and **144 actual prospects**. Six assigned common-gem output totals support historical unconditional E (units /144) without treating ore consumption as the cast denominator: `36917` 43/144=0.298611; `36920` 27/144=0.187500; `36923` 31/144=0.215278; `36926` 33/144=0.229167; `36929` 41/144=0.284722; `36932` 39/144=0.270833. Source: https://www.wowhead.com/item=36910/titanium-ore (search-indexed original comment; direct page render blocked by JavaScript challenge). These six fields are historical-only at 55/100 evidence confidence, and remain unverified in Retail 12.1.

For Titanium Powder `36910→46849`, the same author reports 94 powder and 12 two-powder events. Assuming no unreported yields above two, inferred histogram 62 zero /70 single /12 double yields **historical P(hit)=82/144=56.9444%, positive min=1, max=2, E=94/144=0.652778**. The histogram is inferred from a partial aggregate, not independently logged. It is preserved as a **separate historical comparator**, while the exact 2026 Retail four fields remain null. The source did not specify skill or modern profession mechanics. See the immutable observation file.

Independent 2023 Classic PTR author **Strath** reports 5,000 ore and 736 powder (nominal-five proxy 0.736) but no actual completed cast denominator; Classic is a separate game branch. Source: https://www.wowhead.com/wotlk/item=36910/titanium-ore. This is not a current Retail replication. The previously admitted 12.0.5 globalmenace 143/1000 gross-ore 0.715 proxy remains quarantined from candidate per-cast E after master v0.6.1 correction.

## P0 — BfA, Legion, WotLK, MoP coverage
- Nine BfA Jiyao output rows have original **20-herb mass** completed-cast rounded E (177 Star Moss, 106 Sea Stalk, 103 Siren's Pollen casts). Reused one author and one source, not nine new studies; P(hit) and positive bounds remain unknown. No five-herb cast E transfer.
- Legion Felslate `123919→130178–130183`: six TSM source-range 2–5 references, but raw `matRate=0.01` and `amountOfMats=0.002` are not independent same-cast P/E; original actual cast histograms missing.
- WotLK Cobalt/Titanium: 12 source-range 1–2 references. Six Titanium output E newly sourced historically; Cobalt current and historical exact cast E still unknown. The raw TSM 0.235 and 0.5 cannot be assigned P and E simultaneously under 1–2 bounds, since E=0.5 exceeds P×2=0.47.
- MoP Black/White Trillium: 12 source-range 1–1 references, `matRate=0.16` versus `amountOfMats=0.0341` cannot be interpreted as same-cast P and E (E<P). Indexed Retail [White Trillium item page](https://www.wowhead.com/item=72103/white-trillium-ore) lists Pandaria Jewelcrafting (75); older comments cite 600 pre-profession-squish. Treat as a current-eligibility research lead, not proof that Black Trillium shares the same modern gate.

## P2 — Gold decision risks
The 2009 actual-cast gem E is materially different from the ambiguous TSM source columns; do not use the historical values as automatic 2026 replacements. Titanium Powder must be included as a separate legitimate output when prospecting Titanium, but the 0.715 gross-input-normalized 12.0.5 estimate must not be presented as observed per-completed-cast E. Avoid false auction-versus-prospect flips without current skill/patch and AH prices. Distinguish output materials from Resourcefulness savings.

## QA and source learning
- **40/40 unique exact keys; 30/30 source-line IDs verified; 0 cross-worker key claims; 0 invalid negative values; 0 inverted positive source ranges; 85 unknown fields remain null**.
- New/reused source statuses persisted in 5 worker-owned source-review events; master source-memory cache and reward scoring untouched. Original authors on one Wowhead page are separate cohorts, translated copies are not. 2009 PTR and 2023 Classic are not current-Retail studies.
- No current-Retail client tests, Node or Lua interpreter, AH snapshots, or independently accessible original Wowhead comment renderer. This is source and arithmetic QA only.

## Exact next IDs for master
1. `36910→46849`: Retail 12.1 zero-inclusive completed-cast histogram, skill/patch/operation count; verify whether powder can exceed 2 today.
2. `36910→36917/36920/36923/36926/36929/36932`: 2026 matched per-output zero-inclusive cast histograms to replace 2009 PTR historical E.
3. `36909→36917/36920/36923/36926/36929/36932`: current Retail Cobalt actual-cast E/P.
4. `123919→130178/130179/130180/130181/130182/130183`: Legion rare-gem current recipe/skill and full output histogram.
5. `72094/72103→76130/76133/76134/76135/76136/76137`: verify 2026 Pandaria JC eligibility, rare rank and per-cast values.
6. `152506/152507/152508→153635/153636/153669`: 2026 20-herb mass-mill histogram, not standard five-herb recipe.

**Assignment examined and ready for master reassignment.** No production Lua/TOC, main, shared master ledger, canonical registry, assignments, source-memory cache or schedule edits.
