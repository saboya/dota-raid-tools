# Working on DotaRaid

DotaRaid is the install folder and addon ID; **Dota raid tools** is the in-game title. This checkout is a source-only WoW addon: Lua files and `Media/` assets loaded directly by the client. There is no build, dependency install, or automated test runner in this checkout. `DotaRaid.toc` declares interface `16001`, the `PogRaidDB` SavedVariables table, and the exact Lua load order. The legacy `PogRaid` comms prefix remains unchanged for compatibility.

## Where to make changes

| Area | Start here |
| --- | --- |
| Startup, events, SavedVariables, slash commands | `Core.lua`; diagnostics in `Bug.lua` |
| Main window, tabs, themes, settings | `Editor.lua`, `UI.lua`, `Settings.lua`, `Minimap.lua` |
| Raid plan editing, drawing, viewing, serialization | `Editor.lua`, `Canvas.lua`, `Viewer.lua`, `Codec.lua` |
| Raid management | `Roster.lua`, `Attendance.lua`, `Loot.lua` |
| Guild dashboard, posts, and group finder | `Home.lua`, `Social.lua`, `Dungeons.lua`, `JoinPopup.lua` |
| Guild member features | `Profiles.lua`, `Gear.lua`, `Crafting.lua`, `Wishlist.lua`, `Chat.lua`, `Kos.lua`, `GuildMap.lua` |
| Games and leaderboards | `Games.lua` and the game-specific modules (`Gems.lua`, `Wowdle.lua`, `Lode.lua`, `Siege.lua`, `Angler.lua`, `Duels.lua`) |
| Addon messages, guild replication, version discovery | `Comm.lua`, `Sync.lua`, `Version.lua` |

## Code conventions and client constraints

- Match the surrounding Lua style: four-space indentation, local helpers, `local _, ns = ...` (or `local ADDON, ns = ...` when the addon name is needed), and module tables exposed as `ns.Feature`. Keep new globals limited to WoW-required entry points. Add new Lua files to `DotaRaid.toc` after their load-time dependencies; do not use `require`.
- Use `ns.On(event, handler)` for normal events. It tolerates unsupported event registrations and isolates handler errors. `ns.db` is initialized for this addon in `ADDON_LOADED`; player and guild information can arrive later. Preserve existing API guards and fallbacks: the code has client-specific behavior for Forever, including APIs that are absent or return different values.
- For player identity, use `ns.PlayerName()` for self, `ns.SameName()` for comparisons, and follow the feature's existing normalization (e.g. `ns.Attendance:Key()` for roster-backed keys, `ns.Sync:Me()` for sync). A bare `UnitName()` can omit a Forever surname; do not split names on spaces or invent a new key format.
- Reuse `ns.UI` helpers for themed widgets, menus, sounds, and frame positions. Feature tabs register with `ns.Editor:RegisterTab(...)`; the build callback runs on first show, and `onShow` handles refreshes. Follow neighboring pages' sizing (`ns.PAGE_H` or `ns.RAID_H` for grouped pages) and check both the plain and themed layouts if changing shared UI.

## Persistence and guild messaging

- Keep existing saves readable. Add defaults and schema migrations alongside `Core.lua`'s `DB_VERSION` logic as needed, preserving explicit `false` settings. `ns.db.guild` is the active guild's runtime pointer into `ns.db.guilds` once selected and is cleared at logout; do not cache it across guild switches. Use `ns.OnGuildChanged()` for derived state that needs invalidation. Do not treat an unknown guild at login as confirmed unguilded.
- For replicated collections, follow existing `Sync:Register` definitions and write through `ns.Sync:Write()` rather than mutating `Sync:Store()` in place. Preserve collection codes, field order, revision/author rules, tombstones (`deleted`), and per-collection validation and permissions. The sync store is separate from `ns.db.guild` and can be unavailable outside a guild.
- Use `ns.Comm.Send` / `ns.Comm.SendChunked` instead of calling the client send API directly. `Comm.lua` handles throttling and lockdown and keeps background guild sync behind interactive traffic. Preserve sender/channel checks and compatibility with older clients when changing the wire format. For plans, consult `Codec.lua` before changing serialized item formats or the numeric color/style indices in `Core.lua`.
- For a requested release bump, keep `## Version` in `DotaRaid.toc` and `ns.VERSION` in `Core.lua` in sync. Avoid broadcasting work-in-progress changes to a live guild; use an isolated test setup for guild traffic.

## Verification

1. Parse changed Lua files with `luac -p path/to/file.lua`, if available. To check the whole addon from this directory: `for f in ./*.lua; do luac -p "$f" || exit 1; done`. A host parser only checks syntax; it does not validate WoW APIs or UI behavior.
2. For an in-game smoke test, run `./install-addon.sh` or install the addon as `Interface/AddOns/DotaRaid` in the target client. Enable errors with `/console scriptErrors 1`, then `/reload` and open `/dota` (`/dotaraid` also works). Restart the client after adding or reordering TOC entries rather than relying on `/reload` alone.
3. Exercise the changed feature. `/dota bug` shows captured errors, `/dota probe` reports client API support, and `/dota sync` shows sync diagnostics. `/dota demo` populates local sample attendance and loot (`/dota demo clear` removes them); `/dota test` sends the selected raid plan to yourself through the real comms path.
4. For save changes, test both a fresh profile and a backed-up existing save, including reload and guild switching where relevant. For protocol changes, test with isolated peers, including an older addon version where relevant. If you cannot run the client, state which checks were not performed.
