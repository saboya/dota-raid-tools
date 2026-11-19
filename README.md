# Dota raid tools

Guild and raid tools for World of Warcraft: Forever.

## Install

Download `DotaRaid-v<version>.zip` from [GitHub Releases](https://github.com/saboya/dota-raid-tools/releases). Use that asset, not GitHub's automatic **Source code (zip)**. Extract it into WoW Forever's `_forever_/Interface/AddOns/` folder so that `AddOns/DotaRaid/DotaRaid.toc` exists. Restart WoW and type `/dota` or `/dotaraid`.

## Publish a release

1. Set the same version in `DotaRaid.toc` (`## Version`) and `Core.lua` (`ns.VERSION`). Commit and push the changes, including the workflow for the first release.
2. Tag the release commit and push the tag. For the first release, `0.1.0`:

   ```sh
   git tag -a v0.1.0 -m "Release v0.1.0"
   git push origin v0.1.0
   ```

GitHub Actions checks that both version fields match the tag, builds the addon ZIP, and attaches it to a GitHub Release. Branch pushes alone do not publish a release. To try packaging locally without publishing, run `python3 tools/package.py v0.1.0`.
