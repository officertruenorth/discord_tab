local discordCache = {}
local discordRequests = {}

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

    if type(payload.member) == 'table' and type(payload.member.roles) == 'table' then
        return payload.member.roles
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

    if type(payload.name) == 'string' and payload.name ~= '' then
        return payload.name
    end

    if type(payload.user) == 'table' then
        return payload.user.global_name or payload.user.username or payload.user.displayName or payload.user.name
    end

    if type(payload.member) == 'table' and type(payload.member.name) == 'string' and payload.member.name ~= '' then
        return payload.member.name
    end

    if type(payload.member) == 'table' and type(payload.member.user) == 'table' then
        return payload.member.user.global_name or payload.member.user.username or payload.member.user.displayName or payload.member.user.name
    end

    if type(payload.data) == 'table' then
        return payload.data.global_name or payload.data.username or payload.data.displayName or payload.data.name
    end

    return nil
end

local function isBridgeErrorPayload(payload)
    if type(payload) ~= 'table' then
        return false
    end

    if payload.success == false or payload.ok == false then
        return true
    end

    if type(payload.error) == 'string' and payload.error ~= '' then
        return true
    end

    if type(payload.errors) == 'table' and next(payload.errors) ~= nil then
        return true
    end

    local status = tonumber(payload.status or payload.statusCode)
    if status and status >= 400 then
        return true
    end

    return false
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

local function normalizeDiscordIdentifier(discordId)
    local normalized = tostring(discordId or '')
    if normalized:sub(1, 8) == 'discord:' then
        normalized = normalized:sub(9)
    end

    if normalized == '' then
        return nil
    end

    return normalized
end

local function getCachedDiscordData(discordId)
    local cacheKey = normalizeDiscordIdentifier(discordId)
    if not cacheKey then
        return nil
    end

    local ttl = tonumber(Config.DiscordApi and Config.DiscordApi.cacheTtlMs) or 0
    if ttl <= 0 then
        return nil
    end

    local now = getNowMs()
    local cached = discordCache[cacheKey]

    if ttl > 0 and cached and cached.expiresAt > now then
        return cached.data
    end

    return nil
end

local function getBridgeMethods()
    local methods = {}
    local configMethods = (Config.DiscordApi and Config.DiscordApi.methods) or {}

    for _, method in ipairs(configMethods) do
        if type(method) == 'string' and method ~= '' then
            methods[#methods + 1] = method
        end
    end

    return methods
end

local function buildLookupIdentifiers(discordId)
    local normalized = normalizeDiscordIdentifier(discordId)
    if not normalized then
        return {}
    end

    return { normalized, ('discord:' .. normalized) }
end

local function fetchDiscordData(discordId)
    local cacheKey = normalizeDiscordIdentifier(discordId)
    if not cacheKey then
        return
    end

    local okBridge, bridge = pcall(function()
        return exports.discordapi
    end)
    if not okBridge or not bridge then
        return
    end

    local methods = getBridgeMethods()
    if #methods == 0 then
        return
    end

    local ttl = tonumber(Config.DiscordApi and Config.DiscordApi.cacheTtlMs) or 0
    local identifiers = buildLookupIdentifiers(discordId)
    if #identifiers == 0 then
        return
    end
    local fetched = nil

    for _, methodName in ipairs(methods) do
        local bridgeMethod = bridge[methodName]

        if type(bridgeMethod) == 'function' then
            for _, identifier in ipairs(identifiers) do
                local ok, payload = pcall(function()
                    return bridgeMethod(identifier)
                end)

                if ok and payload then
                    if type(payload) == 'string' and payload ~= '' then
                        local decodedOk, decodedPayload = pcall(json.decode, payload)
                        if decodedOk and decodedPayload then
                            payload = decodedPayload
                        else
                            payload = nil
                        end
                    end

                    if type(payload) == 'table' and not isBridgeErrorPayload(payload) then
                        fetched = payload
                        break
                    end
                end
            end
        end

        if fetched then
            break
        end
    end

    if fetched and ttl > 0 then
        discordCache[cacheKey] = {
            data = fetched,
            expiresAt = getNowMs() + ttl
        }
    end

    return fetched
end

local function queueDiscordFetch(discordId)
    local cacheKey = normalizeDiscordIdentifier(discordId)
    if not cacheKey then
        return
    end

    local existingRequestStartedAt = discordRequests[cacheKey]
    if existingRequestStartedAt and (getNowMs() - existingRequestStartedAt) < 5000 then
        return
    end

    local requestToken = getNowMs()
    discordRequests[cacheKey] = requestToken

    CreateThread(function()
        pcall(fetchDiscordData, cacheKey)
        if discordRequests[cacheKey] == requestToken then
            discordRequests[cacheKey] = nil
        end
    end)
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

    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        local discordId = getDiscordId(source)
        local discordPayload = getCachedDiscordData(discordId)

        if not discordPayload and discordId then
            queueDiscordFetch(discordId)
        end

        players[#players + 1] = buildPlayerEntry(source, discordId, discordPayload)
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
