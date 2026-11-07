# Owner-reported PR 48 / 1250 ms macro capture

Original all-in-one export preserved byte-for-byte, SHA256 in intake-review.json.
The owner reports PR 48 and a 1,250 ms macro interval. The export does not identify
its addon commit or recorder revision; preserve that report without pretending
it independently verifies the installed/running build.

The 483 retained records include 107 new identities: 39 Craft operations producing
Evercore Shade (244752), and 68 Disenchant operations producing 65 R1 Radiant
Shards (243602) and 3 R2 shards (243603). Earlier 376 records are not counted again.
The study retains separate Craft:1229863 and Disenchant:13262 coverage gaps. Its
50-entry diagnostic buffer now contains only crafting failures; that does not
mean the persistent Disenchant gap was resolved. No new numerical rate is
promoted. The same 200 previously reviewed Recycling casts remain admitted.

Low FPS, frozen bag icons, interruptions and BetterBags/ElvUI execution-time
warnings were reported alongside this capture. These are uncontrolled collection
conditions. The observed failures cannot be attributed solely to click timing,
addon version or the cursor-activation path. Retain the evidence for diagnosis.
