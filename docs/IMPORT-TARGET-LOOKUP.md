# Imported salvage target lookup

Imported salvage studies independently retain their measured context, receipts,
quantities and lineage. Before using them, the live query still requires matching
recipe, input batch/rank/build, current owner and measured native context.

Within one `ImportedEvidenceRecords` call, every candidate receives identical item
facts. The first candidate passing the coarse guards now searches for its inventory
target once. Other candidates reuse that result, including a missing target. A later
call always searches again: there is no persistent target cache or new invalidation
contract. Per-allocation native context capture and full-profile comparison remain
unchanged. `CaptureCraftContext` can additionally reverify its exact target GUID;
that separate verification is not removed.

## Offline regression

`tests/test_import_target_lookup.lua` imports the preserved 200-cast Recycling
export plus seven clearly synthetic independent-study copies, with disjoint IDs.
They are stress fixtures, not additional empirical measurements or shipped yields.
The actual public `ConversionOptions` -> `ResolveEvidenceModel` -> importer path
uses the real `FindSkillQualityTarget` inventory search with mocked WoW APIs.

Coverage includes exact returned evidence objects/order, quantities, net consumption
and public price; cold/warm calls; lazy guards; incompatible first study; missing
then present inventory; changed bag/location/GUID; changed skill/equipment; separate
allocation capture; source toggles; duplicate/index/clear lifecycle. No client APIs
are claimed tested by the mocks. The optional first argument loads an original
importer for a failing counterfactual; normal suite runs use the current code.

The original PR51 importer performs eight inventory searches for eight compatible
studies in a single call. With the target at the last of 120 mocked bag slots this
is 960 item-ID reads. The fixed importer performs one search / 120 reads. Missing
targets receive the same reduction. Public calls still revalidate inventory and
measured context even when an economic model is warm. No wall-time threshold is
introduced, and reduced operation counts are not a live WoW frame-rate claim.

The fix stacks on published PR51 and does not depend on PR62's numeric-profile
migration changes. Integration with PR62 must retain its `legacyProfileConflict`
guard and exact profile identity behavior. No source data, yield, confidence,
reference identity, version, pending cohort admission, merge or release changes.
