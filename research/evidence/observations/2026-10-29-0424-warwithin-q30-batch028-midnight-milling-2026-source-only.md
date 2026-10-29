# Midnight Milling q30 source-only evidence — 2026-10-29
**Not a canonical numeric observation. Do not use for tooltip P/min/max or gold E.**

## Original 2026-03-03 player report
URL: https://www.reddit.com/r/woweconomy/comments/1rju9nm/engineering_bugged/
A commenter responding to engineering pigment recycling says the herb used for Powder Pigment costs around 40g and milling yields **11–15 pigment**, and describes Sanguithorn as giving a comparable rate. Context is an informal March 2026 Retail comment; no exact herb or pigment quality rank, character skill, Perfect Milling specialization, actual completed casts, output distribution, Resourcefulness or patch build is provided. This is a family-level first-hand *reported range*, **not** a measured exact input/output rank positive-yield interval. Publication date is not the cast date. No mapping or numerical field is promoted.

## Independent 2026-03-14 player report
URL: https://www.reddit.com/r/woweconomy/comments/1rteoqr/no_money_gain_possible_with_inscription_mats/
Another commenter says milling with blue tools yields roughly 5k gold profit per 1,000 herbs. This is an economic self-report, not a measured pigment output dataset; it lacks ore/herb rank, output IDs, auction prices, actual completed operations, refunded herbs and patch build. Treat as economic context only.

## Recipe and identity corroboration
- Warcraft Wiki Midnight Milling: https://warcraft.wiki.gg/wiki/Midnight_Milling — 10 Midnight herbs per recipe; recipe identity only.
- Method Midnight Inscription: https://www.method.gg/guides/midnight-inscription-profession-guide — four herb/pigment families, no exact rank outcomes.
- Icy Veins Inscription (updated Aug 6 2026): https://www.icy-veins.com/wow/professions-inscription — skill/quality influences pigment quality; no cast-level outcomes.
- Wowhead output IDs: https://www.wowhead.com/item=245808, https://www.wowhead.com/item=245803, https://www.wowhead.com/item=245867, https://www.wowhead.com/item=245865 — item names, +5/+15 recipe-difficulty distinctions; these **are not output rank selectors**.
- Wowhead exact input IDs checked: https://www.wowhead.com/item=236761, https://www.wowhead.com/item=236767, https://www.wowhead.com/item=236776, https://www.wowhead.com/item=236777, https://www.wowhead.com/item=236778, https://www.wowhead.com/item=236779, https://www.wowhead.com/item=236770, https://www.wowhead.com/item=236771.
- Main `GameData.lua` source block (lines 283–298): https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/GameData.lua — `batch=10`, `materials={}`, no output eligibility.

## Lineage and limits
Two distinct Reddit thread commenters (independence of their actual samples not proven), multiple derivative guides, and item identity pages. The earlier kyzenbka 1,000-herb aggregate is a **reused** historical cohort and not re-counted. None of the new sources report exact rank-specific zero-inclusive cast histograms. No sample operations are claimed; no schema-shaped numeric observation is fabricated. New exact tuples admitted: **0**. Unresolved exact keys: universe-audit:midnight:mill:236761:245808:alternate-pigment-rank-eligibility; universe-audit:midnight:mill:236767:245808:alternate-pigment-rank-eligibility; universe-audit:midnight:mill:236776:245803:alternate-pigment-rank-eligibility; universe-audit:midnight:mill:236777:245803:alternate-pigment-rank-eligibility; universe-audit:midnight:mill:236778:245867:alternate-pigment-rank-eligibility; universe-audit:midnight:mill:236779:245867:alternate-pigment-rank-eligibility; universe-audit:midnight:mill:236770:245865:alternate-pigment-rank-eligibility; universe-audit:midnight:mill:236771:245865:alternate-pigment-rank-eligibility.
