# Research-only source/valuation audit: Lesser and Greater Eternal Essence reciprocal item use
**Checked:** 2026-11-17 15:01 UTC. **Role:** research coordinator. **Scope:** new exact deterministic Retail-source exchange identity, compared to the owner's saved offline ItemDB valuation fixtures; *not* new drop experiments or game-client eligibility verification.

## Independent source identity and conversion quantities

- [Retail Lesser Eternal Essence, item 16202](https://www.wowhead.com/item=16202/lesser-eternal-essence) explicitly states **Use: Turn three lesser eternal essences into a greater one**. [Retail spell 20039](https://www.wowhead.com/spell=20039/greater-eternal-essence) has **Greater Eternal Essence 16203** as its created item. Its spell reagent display misleadingly lists two lesser units; the original Wowhead spell comment explicitly explains a third Lesser is *first consumed by the on-use item*, then the effect consumes the other two. **Actual described total input: 3 × 16202; fixed result: 1 × 16203.** The displayed two-reagent spell requirement is **not** the entire item-use cost.
- [Retail Greater Eternal Essence, item 16203](https://www.wowhead.com/item=16203/greater-eternal-essence) states the opposite **Use: Turn a greater eternal essence into three lesser ones**. [Retail spell 20040](https://www.wowhead.com/spell=20040/lesser-eternal-essence) explicitly **creates 3 × 16202**. **Actual described input: 1 × 16203; fixed result: 3 × 16202.** Keep conversions as two *alternative* directed actions; no material is created for free by looping.
- These are source-described deterministic **item-use** actions, not DE output probabilities, observed casts, profession stat coefficients, or a free cross-character entitlement. Source details do not establish whether the exact item/spell version is currently usable by a particular Retail character, held in sufficient inventory, subject to cooldown, tradability or any conversion policy already represented in addon code.

## Cross-stage owner snapshot comparison (previously executed fixture only)

The owner-controlled [offline synthetic resolver/formatter fixture](https://github.com/Voodoobrew101/Loot-Liquidator/blob/3d667d053db587c91401cfed7ecc56862b8340c9/docs/usable-data-audit/runtime-probes.jsonl), blob `534b970d475d75e54b1d5bc4777e807384814372`, contains **367** controlled source method/input profiles and uses **100 copper net per output material**. We parsed all 367 pre-existing records and confirmed:

| Existing saved method profile | Current single material in DE outputs | Saved unconditional E per DE | Conditional exchange valuation question |
| --- | --- | ---: | --- |
| `Disenchant:13856:x1` | **16202 Lesser Eternal Essence** | **0.3648** | Selling 16202 as itself versus consuming exact batches of 3 for one 16203; do not divide actual inventory by three without sufficient items and price/cost context |
| `Disenchant:13866:x1` | **16203 Greater Eternal Essence** | **0.5686** | One Greater may instead create three Lessers, if accessible |
| `Disenchant:14128:x1` | **16203 Greater Eternal Essence** | **0.8095** | Same distinct alternative, not an extra enchantment drop |

The original saved material lines are independently valued and should remain so. They **do not list the converted partner item as a simultaneous DE material**: the synthetic fixture prices the original DE drops, not an explicit post-DE reciprocal conversion quote. The saved `eligibility` value on each is **"Not tested; source audit only"**. We did **not execute** a new estimator, compiler, native Lua suite, resolver or live client. A search against the owner's saved token/exchange ledger found no catalog item keyed 16202 or 16203; this narrow negative is *not* proof no other addon exchange adapter exists. Some raw `20039` text occurrences in generated files are substrings of **unrelated larger item IDs**, not demonstrated spell mappings.

## Synthetic illustration, not an actual-market or best-action finding

At the owner's artificial prices P(Lesser)=P(Greater)=100 copper and assuming a character can use the item:
- `13866`: the recorded Greater contribution is **56.86c** (0.5686 × 100); *if* each is converted to three Lessers, equivalent output contribution becomes **170.58c**, difference **+113.72c** per source DE expectation.
- `14128`: original contribution **80.95c**; conditional conversion contribution **242.85c**, difference **+161.90c** per DE.
- `13856`: 0.3648 lesser units contribute **36.48c** directly; hypothetical bulk conversion to Greater at 3-to-1 is **12.16c** per DE long-run equivalent under these same prices, so the correct synthetic choice would **not** be to convert in that direction. Single-item inventory granularity still matters.

These prices deliberately ignore any real auction market, fees, inventory and eligibility. This establishes a **potential missing downstream pricing alternative** affecting three *stored* material profiles, **not a corrected gold recommendation** or measured current Retail opportunity.

## Disposition, ownership and verification

**Gap class:** independently source-described fixed conversion identities, with **saved direct source outputs already priced**, but an unverified separate post-processing exchange/pricing path. Not absent DE evidence, not missing AH prices, not proof the addon silently dropped an import. Future owner-reviewed, isolated implementation must gate current item-use legality, compare net direct-sale versus converted-sale prices for each direction, subtract costs and AH fees, handle inventory multiples, avoid repeated mutual loops, keep the original output identity and explicitly label estimated downstream quotes. Do not modify the protected owner integration branch or pinned 4df9ae8 snapshot.

**Actual checks:** 18/18 bounded JavaScript assertions against every saved fixture record: the 367-profile count; exact keys; output IDs and E quantities; opposite output not added to the DE material list; all three synthetic eligibility disclaimers; both 3x spread arithmetic differences and the inverse 3:1 value calculation. Online Retail item/spell descriptions checked separately. **Zero** newly observed processing casts, independently measured probabilities or qualified live-gold actions; no new tests of the addon code or WoW client. No original records altered.

**Worker boundary:** Leave Legacy's current original-source T0047/T0051/T0053 and T0050 history work untouched. Retain high-priority Midnight **T0005/T0039** (237362 exact rank/hit/zero/refunds) and **T0045** (10-herb milling source denominators). This note is a separate manager-side source-to-valuation finding rather than a duplicate experiment request.
