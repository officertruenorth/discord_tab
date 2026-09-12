Config = {}

Config.Keybind = {
    command = 'discordtab',
    default = 'TAB'
}

Config.RefreshIntervalMs = 2000

Config.DiscordApi = {
    cacheTtlMs = 15000,
    methods = {
        'GetUser',
        'getUser',
        'GetDiscordUser',
        'getDiscordUser'
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
