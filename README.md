# discord_tab

Modern FiveM in-game scoreboard/playerlist that integrates with the Nights Discord API and only displays Discord roles mapped to in-game ACE permissions.

## Features

- Dark modern scoreboard with gradient accents and smooth open/close animation
- Displays:
  - Server ID
  - In-game player name
  - Discord name (from Nights API)
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

### 2) Nights API

Set your Nights Discord API endpoint and auth header. `{discordId}` is replaced automatically.

```lua
Config.NightsApi = {
    endpoint = 'https://YOUR_NIGHTS_ENDPOINT/users/{discordId}',
    method = 'GET',
    timeoutMs = 5000,
    cacheTtlMs = 15000,
    headers = {
        ['Content-Type'] = 'application/json',
        ['Authorization'] = '******'
    }
}
```

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
2. Configure a reachable Nights Discord API HTTP endpoint and valid auth headers in `config.lua`.
3. Configure endpoint, auth, and role mappings in `config.lua`.
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
