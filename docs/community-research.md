# Share your processing results

Help improve Loot Liquidator's low-confidence estimates with recorded results from your own play. Disenchanting, milling, prospecting, smelting, crafting and Recycling are welcome. Small, complete batches help too. You do not need to calculate averages, percentages or confidence.

**[Submit a processing export](https://github.com/Voodoobrew101/Loot-Liquidator/issues/new?template=processing-export.yml)** · **[View submissions](https://github.com/Voodoobrew101/Loot-Liquidator/issues?q=is%3Aissue+label%3Acommunity-research)**

## Record a batch

1. Install the latest release. Open **/ll**, then **Processing Research**. Enable **Record disenchant results** for disenchanting and **Record crafting and processing results** for the other methods.
2. Open your own profession window so the addon can read your actual skill, specialization, equipment and recipe information. Leave unavailable values unknown; do not replace them with a simulation or guess.
3. On the first Loot Liquidator settings tab, under **Community research**, click **Start new batch** before starting a controlled session. This starts a new group without deleting older results. Keep required materials in your character's bags.
4. Process items normally. Allow results to settle; avoid unrelated looting, trading, selling, mailing or bank transfers during capture. Note interruptions, equipment changes, respecs or unusual conditions in your submission.
5. Stop processing and check **Recording status** in Processing Research. Missing or delayed results are not zero results. Use `/ll craftzero` only for an isolated empty result you personally verified, following the [recording guide](craft-recording.md).

Submit Retail results as Retail. Clearly label Classic, PTR, beta or private-server observations; they cannot be treated as current Retail measurements. Screenshots and remembered totals can supply context, but cannot replace the raw export.

## Export and submit

1. Under **Community research** on the first tab, click **Export all**. Copy the entire text from the copy window into a plain text editor and save it as `processing-export.txt` or `processing-export.json`. A compact export is supported; copy it unchanged. For only your newest batch, use **Export** in Processing Research instead.
2. If the addon uses pages, or you choose **Export pages**, save **every page from the same export snapshot**, for example `processing-export-page-1.txt`, `processing-export-page-2.txt`. Do not record more results between copying pages. If anything changes, start the export again and replace the whole set.
3. Open the [submission form](https://github.com/Voodoobrew101/Loot-Liquidator/issues/new?template=processing-export.yml), sign in to GitHub, and attach the file(s) in **Export files**. `.txt` is the fallback if GitHub will not accept a `.json` attachment. For a short export, paste the complete JSON in a fenced code block instead. Do not paste screenshots of JSON.
4. State the method and input items, addon version, game mode, approximate capture date and any unusual conditions. Most technical context is already recorded; unknown information should stay unknown.
5. Submit the issue, then check that the attachment opens and all pages are present. Keep your local copy. If you already submitted these operations, link that issue rather than submitting them as new measurements. A later full-history export can overlap an earlier one; tell us so it can be deduplicated.

## Before posting publicly

The export can contain **character names and realms**, cast and item GUIDs, timestamps, client build, item links and qualities, profession skill, specialization selections, equipment links, input/output quantities and diagnostic inventory vectors. A compact export is compressed, not anonymized. It contains measured research data rather than your entire account settings, but it is still identifiable gameplay data.

GitHub issues and attached files are public. Share only your own data that you are comfortable publishing and allowing Loot Liquidator to use for research and shipped shared statistics. Do not upload the whole `SavedVariables/LootLiquidator.lua` file, account folders, credentials or another player's private data. Do not silently edit identities or operation IDs: they are used to match context and prevent double counting. If you do not want the export public, keep it local and do not submit it.

## Exporting and resetting are separate

**Export all** and **Export pages** copy results and do not clear them. **Start new batch** keeps older history. **Reset recordings** asks for confirmation and clears recorded research, including older personal processing/disenchant learning, while keeping one previous set as a local backup until the next reset. Settings and imported results are separate.

Save and check your export before resetting. A backup in SavedVariables is not a substitute for a checked export, and the next reset replaces that backup. Wait until any active cast has finished recording. If you only want a fresh session, use **Start new batch**.

## What happens next

A scheduled review checks submissions once a day. It validates complete exports/pages, identifies duplicate operations and overlapping studies, and checks item identities, output qualities, measured profession context and client applicability. Partial records remain research; unknowns do not become zeros. No minimum batch size alone grants approval or establishes a skill formula.

Usable independent records are reviewed through the existing capture and database pipeline against the latest production source. When they make a supported change to shared statistics, the addon is rebuilt, tested and versioned before publishing an update to CurseForge. No-change reviews do not create a release. Held submissions may need a follow-up question or another recording session; they are not automatically added to gold calculations.

The addon does not upload data or download new research automatically. Install published updates to receive new shared statistics. Your personal history remains separate from the compiled shared database.

For detailed capture behavior, limits and unsupported cases, see [Recording crafting evidence](craft-recording.md).
