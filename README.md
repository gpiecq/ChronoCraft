# ChronoCraft

Track profession cooldowns across all your characters in World of Warcraft Classic TBC Anniversary.

## Features

- **Multi-character tracking** - See cooldowns from all characters on your account
- **Minimap button** - Hover to see all active cooldowns at a glance
- **Automatic detection** - Cooldowns are captured when you craft or from your tradeskill window
- **Bilingual** - English and French (auto-detected)
- **Account-wide storage** - Data persists across all characters via SavedVariables

## Supported Cooldowns

| Cooldown | Profession | Duration |
|----------|------------|----------|
| Shadowcloth | Tailoring | 4 days |
| Spellcloth | Tailoring | 4 days |
| Primal Mooncloth | Tailoring | 4 days |
| Transmute | Alchemy | 20 hours |
| Brilliant Glass | Jewelcrafting | 20 hours |
| Salt Shaker | Leatherworking | 3 days |

## Installation

1. Download the latest release from the [Releases](../../releases) page
2. Extract the `ChronoCraft` folder into your WoW addons directory:
   ```
   World of Warcraft/_anniversary_/Interface/AddOns/ChronoCraft/
   ```
3. Restart WoW or reload your UI (`/reload`)

## Usage

- **Minimap button** - Hover over the pocket watch icon near your minimap to see all tracked cooldowns
- **Drag** - Left-click and drag the minimap button to reposition it
- **Slash commands** - Type `/chronocraft` or `/cc` to print cooldowns in chat

## File Structure

| File | Description |
|------|-------------|
| `ChronoCraft.toc` | Addon manifest (Interface 20505) |
| `Locales.lua` | English and French localization strings |
| `Core.lua` | Namespace, event bus, database init, slash commands |
| `Cooldowns.lua` | Spell registry, cooldown detection and tracking |
| `UI.lua` | Minimap button and tooltip rendering |

## Localization

ChronoCraft automatically detects your WoW client language. French (`frFR`) clients will see translated UI strings. All other locales default to English.

## Compatibility

- **Interface version**: 20505
- **Game version**: WoW Classic TBC Anniversary
- **Dependencies**: None

## Credits

Built for the WoW Classic TBC Anniversary community.
