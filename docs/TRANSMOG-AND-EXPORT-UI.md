# Appearance recommendations and recorded-result export

Updated 2026-11-06 (America/Los_Angeles), addon 0.12.18.

## Appearance ownership

A visual can be learned from several different item sources. The shared
`AppearanceCollectionState` resolver now checks alternate sources of the exact
appearance before deciding it is missing. An affirmative collected source wins
over a negative result for the hovered item. Source lists filtered by the current
class can confirm ownership; their empty or unavailable results do not establish
that an appearance is missing. Wardrobe filters are never changed.

This applies to ordinary equipment and token rewards. Source IDs and appearance
IDs remain separate; another difficulty or visual cannot satisfy the lookup.
Unknown/loading data remains unknown. Collection/source update events refresh
bag decisions and token snapshots, and appearance state is part of the decision
cache key. The Warmaul Legplates report (24995) is covered as a normal equipment
fixture without an item-specific runtime exception.

Blizzard's generated API contracts were checked in
[TransmogItemsDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/TransmogItemsDocumentation.lua),
including `GetItemInfo`, `GetAppearanceSources`, `GetAllAppearanceSources`,
`GetAppearanceSourceInfo` and `GetAppearanceInfoBySource`.

## Tokens saved for an alt

A token can be worth keeping for an eligible alt's missing appearance even when
the alt does not yet own the other exchange items or currency. Collection
eligibility now has its own helper, separate from immediate redemption costs.
Known reward relationships, class/level requirements, transfer rules, Include
alts and saved T/X exclusions still apply. Candidate-only reward relationships
do not assert a collectible reward.

Vendor and disenchant quotes still enforce actual quantities, costs and
availability. Keeping a token for future collection does not make a currently
unaffordable exchange available for profit. Compact class-set rows retain the
full token's class masks, requirements, exact reward links and candidate flags.
The shipped Protector's Mark of Sanctification (52026) is tested with an eligible
Hunter alt, missing appearances and unavailable extra exchange equipment.

## Export window

Export opens a native dialog above Settings, with an inset scrolling text area,
Select all, Close and Previous/Next buttons. It is clamped to the screen and can
use the installed ElvUI frame/button/scrollbar skin. Native Blizzard styling
works independently of other addons. Escape closes it and releases input focus.

The recorded-result pages encode literal pipes as JSON Unicode escapes, so
hyperlinks, colors and texture markers stay plain text in the copy field. The
decoded JSON is unchanged, including item links and existing backslashes; the
strict importer accepts the copied text. Other copy-dialog uses retain their
original payload bytes. The field restores the export if an accidental edit
would change it.

Opening the export freezes a bounded snapshot of the recorded data. Page
navigation stays consistent while new casts arrive or the live ledger changes.
Reopening Export captures the current records. The legacy no-argument exporter
still supports its existing cycling behavior.

## Validation

The focused fixtures cover alternate appearance sources, cached T decisions,
collection refresh events, token 52026 and recipient/economic boundaries,
class-row metadata, copy selection, paging, stable snapshots and decoded JSON
round trips. The full addon suite remains the release check.

In-game checks remain necessary: compare the export window with Settings under
the installed skin; hover an appearance learned from another item; and hover a
Warbound tier token with an eligible alt's missing reward. No in-game validation
is claimed by the automated fixtures.
