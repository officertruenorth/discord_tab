Config = {}

Config.Keybind = {
    command = 'discordtab',
    default = 'TAB'
}

Config.RefreshIntervalMs = 2000

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

Config.RoleMappings = {
    {
        discordRoleId = '000000000000000000',
        discordRoleName = 'superadmin',
        acePermission = 'superadmin',
        label = 'Super Admin',
        icon = '🛡️',
        color = '#ef4444'
    },
    {
        discordRoleId = '000000000000000001',
        discordRoleName = 'police',
        acePermission = 'group.police',
        label = 'Police',
        icon = '👮',
        color = '#3b82f6'
    },
    {
        discordRoleId = '000000000000000002',
        discordRoleName = 'fire',
        acePermission = 'group.fire',
        label = 'Fire',
        icon = '🚒',
        color = '#f97316'
    }
}

Config.Ui = {
    title = 'City Scoreboard',
    subtitle = 'Discord Synced Player List'
}
