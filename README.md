# Dota raid tools

Guild and raid tools for World of Warcraft: Forever.

## Install

In WoWUp, select **WoW Forever → Get Addons → Install from URL** and paste `https://github.com/saboya/dota-raid-tools`. WoWUp looks for the published release asset ending in `-forever.zip`.

To install manually, download `DotaRaid-v<version>-forever.zip` from [GitHub Releases](https://github.com/saboya/dota-raid-tools/releases). Use that asset, not GitHub's automatic **Source code (zip)**. Extract it into WoW Forever's `_forever_/Interface/AddOns/` folder so that `AddOns/DotaRaid/DotaRaid.toc` exists. Restart WoW and type `/dota` or `/dotaraid`.

DotaRaid and the original PogRaid use separate settings, minimap buttons, and guild messaging. Guildmates need DotaRaid to receive DotaRaid roster shares.

To keep settings from a pre-release DotaRaid build, fully quit WoW, back up `WTF/Account/<account>/SavedVariables/DotaRaid.lua`, and rename its top-level `PogRaidDB =` assignment to `DotaRaidDB =` before restarting. To import original PogRaid settings into a fresh install, make a copy of `PogRaid.lua` named `DotaRaid.lua` in the same folder and edit only the copy. Do not overwrite an existing DotaRaid save.

## Publish a release

1. Set the same version in `DotaRaid.toc` (`## Version`) and `Core.lua` (`ns.VERSION`). Commit and push the changes, including the workflow for the first release.
2. Tag the release commit and push the tag. For the first release, `0.1.0`:

   ```sh
   git tag -a v0.1.0 -m "Release v0.1.0"
   git push origin v0.1.0
   ```

Pushes to `master` build a ZIP and upload it as an Actions artifact for testing. Only tag pushes publish to GitHub Releases: Actions checks that both version fields match the tag and attaches the `-forever.zip` asset. To try packaging locally without publishing, run `python3 tools/package.py`.
