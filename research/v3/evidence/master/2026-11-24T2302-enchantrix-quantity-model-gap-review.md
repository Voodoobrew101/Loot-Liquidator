# Historical Enchantrix model attribution and prospecting gap follow-up

Reviewed 2026-11-24T23:01:56.582Z at research 4656038e532e9b82d0464dddc05534a2ccf82fc8 and main 2db9929050b8532645149dea5a3c5fa8aa0a035a. This is a post-cutoff source lead and scoped comparison, not a second catalogue of the 731 cutoff sources.

## New historical reference lead

[EnxConstantsJewelcrafting.lua, pzb, July 7 2014](https://gist.github.com/pzb/af1df9cbdf0791a6018e), displayed raw revision 7624ff85846611d159eea884ed48be7d38b64ac5. Public HTML source lines 89–129, 191–250, 275–289, 377–460 and 466–539 were inspected; raw download was restricted, so no byte hash is claimed. Source explicitly attributes coefficients to Wowhead quantity-probability data (line 213). This is historical original-era Retail code, not modern Classic data. The source aggregates and equally allocates grouped gem quantities; that allocation is a model, not a measured item-specific distribution. The author supplies neither original Wowhead snapshot nor measured N, histograms, hit counts, exact collection patch, refunds or skill profile. Five-ore prospecting unit is corroborated by https://warcraft.wiki.gg/wiki/Prospecting; the source model is a per-operation coefficient, not per-ore. Existing ReagentMaker credits Enchantrix, so source dependence is plausible; no new independent study weight. Gist name/ID not present in cutoff receipt; absence by name is not evidence of independence.

## Exact 12-key comparison

Previous manager source note identified 12 keys absent from frozen TSM reference. Current research output/estimates.json (blob 15ae8c5b7f7b2587ceff1dcd3e8b9d13d4351d1e) was parsed for exact method, input ID and output ID; all 12 keys checked. Main ReferenceData.lua (blob e47143ee72be8e9fd3128ebad62e364774608c4f) legacy.processing was parsed as 137 top-level records, including 29 Prospect records; none of the eight target ore IDs occurs in those 29. This is not a full compiled-runtime census: the main runtime and large catalogue models were not returned as readable bytes. The committed build snapshot pin 858b6c1bda7994c0d29f6f3d93df30f0a9b9674f and the current research estimates are distinct; do not equate them.

| Input ID | Output ID | Existing research estimate per operation | 2014 model coefficient (original expression) |
|---|---|---|---|
|2772|7910|not present|0.097508/2|
|3858|7910|0.55|1.096977/3|
|3858|12361|0.05|0.099877/4|
|3858|12364|not present|0.099877/4|
|3858|12799|0.05|0.099877/4|
|3858|12800|not present|0.099877/4|
|23425|24243|1|0.993391|
|52183|52327|2.0074|2.0|
|72092|90407|1.1829|1.198490|
|72093|90407|1.525|1.505320|
|72094|90407|not present|1.503700|
|72103|90407|not present|1.503700|

Seven have a research estimate: protect existing values. Five lack a row in this older estimator output and frozen TSM, with no legacy processing record; they remain candidate gap-only historical coefficients (0.048754 Star Ruby per Iron prospect; 0.02496925 each Huge Emerald and Azerothian Diamond per Mithril prospect; 1.503700 Sparkling Shard per each Black/White Trillium prospect). Existing 2012 model differs, especially Trillium shard quantity 1 versus 1.503700 in 2014 and 1.65 in rounded 2015 ReagentMaker. Do not blend these as samples. The current wiki confirms shard source eligibility for all four Pandaria ores, not current quantity: https://warcraft.wiki.gg/wiki/Sparkling_Shard. Original cohort overlap, historical-to-current applicability and scoped catalogue/actual consumer support must be verified before adding any model. No new measured casts, chances, ranges, confidence score or live price. Current compiler source reviewed; no addon or offline runtime tests executed.

Next: use exact five pairs as consumer audit targets, not as proven current gaps. Locate existing scoped admission or build output before introducing fallback. Seek genuinely new original evidence or original Wowhead quantity snapshot; do not re-transcribe these unchanged historical tables.
