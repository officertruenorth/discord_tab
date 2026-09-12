local discordCache = {}

local function getNowMs()
    return os.time() * 1000
end

local function getDiscordId(source)
    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        if identifier:sub(1, 8) == 'discord:' then
            return identifier:sub(9)
        end
    end

    return nil
end

local function normalizeDiscordRoles(payload)
    if type(payload) ~= 'table' then
        return {}
    end

    if type(payload.roles) == 'table' then
        return payload.roles
    end

    if type(payload.data) == 'table' and type(payload.data.roles) == 'table' then
        return payload.data.roles
    end

    if type(payload.user) == 'table' and type(payload.user.roles) == 'table' then
        return payload.user.roles
    end

    return {}
end

local function normalizeDiscordName(payload)
    if type(payload) ~= 'table' then
        return nil
    end

    if type(payload.username) == 'string' and payload.username ~= '' then
        return payload.username
    end

    if type(payload.global_name) == 'string' and payload.global_name ~= '' then
        return payload.global_name
    end

    if type(payload.displayName) == 'string' and payload.displayName ~= '' then
        return payload.displayName
    end

    if type(payload.user) == 'table' then
        return payload.user.global_name or payload.user.username or payload.user.displayName
    end

    if type(payload.data) == 'table' then
        return payload.data.global_name or payload.data.username or payload.data.displayName
    end

    return nil
end

local function rolesContain(roles, mapping)
    for _, role in ipairs(roles) do
        if type(role) == 'table' then
            local id = tostring(role.id or role.role_id or '')
            local name = tostring(role.name or role.role_name or ''):lower()

            if mapping.discordRoleId ~= '' and id ~= '' and id == tostring(mapping.discordRoleId) then
                return true
            end

            if mapping.discordRoleName ~= '' and name ~= '' and name == tostring(mapping.discordRoleName):lower() then
                return true
            end
        elseif type(role) == 'string' then
            local value = role:lower()

            if mapping.discordRoleId ~= '' and value == tostring(mapping.discordRoleId):lower() then
                return true
            end

            if mapping.discordRoleName ~= '' and value == tostring(mapping.discordRoleName):lower() then
                return true
            end
        end
    end

    return false
end

local function buildMappedRoles(source, discordRoles)
    local mapped = {}

    for _, mapping in ipairs(Config.RoleMappings) do
        local hasAce = IsPlayerAceAllowed(source, mapping.acePermission)
        local hasDiscordRole = rolesContain(discordRoles, mapping)

        if hasAce and hasDiscordRole then
            mapped[#mapped + 1] = {
                label = mapping.label,
                icon = mapping.icon,
                color = mapping.color,
                acePermission = mapping.acePermission
            }
        end
    end

    return mapped
end

local function buildApiUrl(discordId)
    return (Config.NightsApi.endpoint:gsub('{discordId}', discordId))
end

local function fetchDiscordDataPromise(discordId)
    local requestPromise = promise.new()
    if not discordId or discordId == '' then
        requestPromise:resolve(nil)
        return requestPromise
    end

    local ttl = tonumber(Config.NightsApi.cacheTtlMs) or 0
    local now = getNowMs()
    local cached = discordCache[discordId]

    if ttl > 0 and cached and cached.expiresAt > now then
        requestPromise:resolve(cached.data)
        return requestPromise
    end

    PerformHttpRequest(buildApiUrl(discordId), function(statusCode, body)
        if statusCode < 200 or statusCode >= 300 or not body or body == '' then
            requestPromise:resolve(nil)
            return
        end

        local ok, decoded = pcall(json.decode, body)

        if not ok or not decoded then
            requestPromise:resolve(nil)
            return
        end

        if ttl > 0 then
            discordCache[discordId] = {
                data = decoded,
                expiresAt = getNowMs() + ttl
            }
        end

        requestPromise:resolve(decoded)
    end, Config.NightsApi.method, '', Config.NightsApi.headers, { timeout = Config.NightsApi.timeoutMs })

    return requestPromise
end

local function buildPlayerEntry(source, discordId, discordPayload)
    local discordRoles = normalizeDiscordRoles(discordPayload)

    return {
        id = source,
        name = GetPlayerName(source) or ('Player ' .. tostring(source)),
        discordName = normalizeDiscordName(discordPayload) or 'Not Linked',
        discordId = discordId,
        ping = GetPlayerPing(source),
        roles = buildMappedRoles(source, discordRoles)
    }
end

local function collectPlayers()
    local players = {}
    local jobs = {}

    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        local discordId = getDiscordId(source)
        jobs[#jobs + 1] = {
            source = source,
            discordId = discordId,
            request = fetchDiscordDataPromise(discordId)
        }
    end

    for _, job in ipairs(jobs) do
        local discordPayload = Citizen.Await(job.request)
        players[#players + 1] = buildPlayerEntry(job.source, job.discordId, discordPayload)
    end

    return players
end

RegisterNetEvent('discord_tab:server:requestPlayers', function()
    local source = source
    local players = collectPlayers()

    TriggerClientEvent('discord_tab:client:updatePlayers', source, {
        title = Config.Ui.title,
        subtitle = Config.Ui.subtitle,
        players = players,
        total = #players
    })
end)
