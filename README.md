# discord_tab

Modern FiveM in-game scoreboard/playerlist that integrates with a `discordapi` bridge export and only displays Discord roles mapped to in-game ACE permissions.

## Features

- Dark modern scoreboard with gradient accents and smooth open/close animation
- Displays:
  - Server ID
  - In-game player name
  - Discord name (from discordapi bridge)
  - Ping
  - Mapped game roles (icon + color badge)
- Role filtering logic:
  - Only roles configured in `Config.RoleMappings` are considered
  - Player must both:
    - Have the mapped Discord role
    - Have the mapped ACE permission
- Sortable columns (ID, name, Discord name, ping, roles)
- Configurable keybind (default `TAB`)
- Live refresh while scoreboard is open

## File Structure

- `fxmanifest.lua`
- `config.lua`
- `server/main.lua`
- `client/main.lua`
- `html/index.html`
- `html/style.css`
- `html/script.js`

## Configuration

Edit `config.lua`.

### 1) Keybind

```lua
Config.Keybind = {
    command = 'discordtab',
    default = 'TAB'
}
```

### 2) Discord bridge

```lua
Config.DiscordApi = {
    cacheTtlMs = 15000,
    methods = {
        'GetUser',
        'getUser',
        'GetDiscordUser',
        'getDiscordUser'
    }
}
```

The scoreboard reads bridge exports from `exports.discordapi` and calls methods in the configured order until one returns a non-error payload.

Expected success payload (any of these shapes):
- `username` / `global_name` / `displayName` / `name`
- or nested under `user`, `member.user`, or `data`
- `roles` can be at root, `data.roles`, `user.roles`, or `member.roles`

Expected error payload markers (ignored and treated as miss):
- `success = false` or `ok = false`
- non-empty `error` string
- non-empty `errors` table
- `status`/`statusCode` >= 400

### 3) Role Mapping (Discord -> ACE)

```lua
Config.RoleMappings = {
    {
        discordRoleId = '123456789012345678',
        discordRoleName = 'superadmin',
        acePermission = 'superadmin',
        label = 'Super Admin',
        icon = '🛡️',
        color = '#ef4444'
    }
}
```

Use your own Discord role IDs/names and ACE permissions.

## Installation

1. Place folder in your server resources.
2. Ensure your Discord bridge resource is running as `discordapi` (the current integration target is fixed to `exports.discordapi`).
3. Configure bridge method names and role mappings in `config.lua`.
4. Add to your server config:

```cfg
ensure discord_tab
```

## Usage

- Hold `TAB` (or your configured keybind) to open scoreboard.
- Release to close.

## Notes

- Players without a Discord identifier will show `Not Linked` and no roles.
- API response parsing supports common role/name payload layouts (`roles`, `data.roles`, `user.roles`).
