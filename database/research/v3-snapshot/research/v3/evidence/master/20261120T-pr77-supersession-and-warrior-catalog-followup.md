# PR 77 supersession and retained catalog follow-up

Owner-requested backlog review, 2026-11-20. [PR 77](https://github.com/Voodoobrew101/Loot-Liquidator/pull/77) proposed blanket Courtly exclusions and S33. Merged [PR 81](https://github.com/Voodoobrew101/Loot-Liquidator/pull/81) instead preserves source-profile baselines, full-investment Shard Supplier endpoints, and confidence-scored projection. The blanket exclusions and S33 proposal are superseded and are not applied by this follow-up.

The separate eligibility concern remains unresolved: `midnight-20261114-1717-009`, ItemID **271457**, cites [one WoWDB base-item catalog page](https://www.wowdb.com/items/271457-jeweled-gauntlets-of-the-jade-warlord). Its `noDisenchant` statement is catalog metadata, without a player attempt, exact itemLink/bonus, observed client build, or independent corroboration. The original record remains unchanged in `research/v3/evidence/midnight/2026-11-14T1718-live-wowdb-de-identity-guards.jsonl`.

The current source file also has other class catalog flags. The older claim that only Warrior has such a flag is therefore not retained as established fact. Comparisons with Paladin 271466 or Death Knight 271475 neither establish nor refute uniform class-set eligibility. Existing or published independent sources should resolve the exact item/variant claim before any wider conclusion.

A scoped unresolved entry is appended to `research/v3/flags.jsonl`. This follow-up adds no source exclusion, class-wide restriction, fabricated failed disenchant, sample count, output zero, or new game-collection requirement. No addon runtime, raw source, PR state, main branch, automation schedule, or release is changed here.
