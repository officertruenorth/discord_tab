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

- `/home/runner/work/discord_tab/discord_tab/fxmanifest.lua`
- `/home/runner/work/discord_tab/discord_tab/config.lua`
- `/home/runner/work/discord_tab/discord_tab/server/main.lua`
- `/home/runner/work/discord_tab/discord_tab/client/main.lua`
- `/home/runner/work/discord_tab/discord_tab/html/index.html`
- `/home/runner/work/discord_tab/discord_tab/html/style.css`
- `/home/runner/work/discord_tab/discord_tab/html/script.js`

## Configuration

Edit `/home/runner/work/discord_tab/discord_tab/config.lua`.

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
2. Ensure dependency/resource for Nights API is available for your setup.
3. Configure endpoint, auth, and role mappings in `config.lua`.
4. Add to your server config:

```cfg
ensure discord_tab
```

## Usage

- Hold `TAB` (or your configured keybind) to open scoreboard.
- Release to close.
- Press `ESC` while open to close manually.

## Notes

- Players without a Discord identifier will show `Not Linked` and no roles.
- API response parsing supports common role/name payload layouts (`roles`, `data.roles`, `user.roles`).
