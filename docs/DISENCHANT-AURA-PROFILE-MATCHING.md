# Disenchant profile matching and combat auras

The matching personal source contains 200 existing rare-armor observations at 104 effective Enchanting skill and known zero specialization. Their source build is 70783; the current target is 70961. They remain historical source observations, with no new casts or patch-equivalence claim.

`ProfessionAuraState` captures all helpful auras. Comparing every captured ID made an ordinary combat/form change reject an otherwise matching material quantity/quality profile. Conversely, using only compiled profession conditions as an allowlist would discard unknown auras: the current `Enchanting:11` profile has no active-buff condition, which does not prove that every unknown aura is irrelevant.

The correction changes only the disenchant profile-equivalence key. On client 12.1.5, build 70961, it excludes this finite reviewed set:

| Spell ID | Native name | Reviewed scope |
| --- | --- | --- |
| 1126 | Mark of the Wild | Combat Versatility and its highlight |
| 5487 | Bear Form | Form, armor/health, combat protection and class-spell modifiers |
| 22812 | Barkskin | Damage/healing/health and pushback protection |
| 22842 | Frenzied Regeneration | Health recovery |
| 61336 | Survival Instincts | Combat defensive configuration |
| 192081 | Ironfur | Armor and linked combat Mastery |
| 1251877 | Gift of an Ancient Guardian | Linked combat Mastery |
| 1261872 | Heart of the Wild | Linked maximum health |
| 1271910 | Mark of the Wild Highlight | Linked zero-valued UI marker |

The [native proof](../database/research/disenchant-nonoutput-auras-70961.json) retains all 31 effect rows, spell texts, source checksums and every nonzero `EffectTriggerSpell` edge from the six root abilities. It does not generalize by spell name, class, or aura type. In particular, it makes no blanket claim that an unknown dummy aura is harmless.

Unknown IDs remain profile constraints. An explicit Enchanting condition or disenchant mechanic-rule buff overrides an exclusion, including a rule's `conditions.buffs` map. Both `buffs` and `activeBuffs` are checked. Full source aura capture, recorded observations, skill and specialization, source controls, eligibility and all other profession calculations remain intact. Known-condition scans are cached by database identity and expansion scope, with profile/rule-reference and revision invalidation.

A new client/build disables this finite exclusion until its native effects are reviewed again. The original source build and current-patch uncertainty stay separate when an unchanged skill/specialization profile is reused.

Validation includes the original source/coverage/immutability regressions; actual live/manual quote routes for rare item 244752 under every reviewed ID, in combined and personal-only modes; retained 90%/10% material means and occurrence; unknown-aura, build-mismatch and known-profession-condition negative controls; and native-proof mutation checks. These target contexts are synthetic. No game actions or new observations were performed.

The exact currently active live aura list was not available as a persisted receipt. This fix establishes the behavior for the reviewed IDs; it does not establish that every active aura on the current character is covered or that the entire live fallback symptom has been verified after installation.
