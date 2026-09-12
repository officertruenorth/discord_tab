local isOpen = false
local refreshThread = nil

local function requestPlayers()
    TriggerServerEvent('discord_tab:server:requestPlayers')
end

local function setVisible(visible)
    SetNuiFocus(visible, false)
    SendNUIMessage({
        type = visible and 'open' or 'close'
    })
end

local function closeScoreboard()
    if not isOpen then
        return
    end

    isOpen = false
    setVisible(false)
end

local function openScoreboard()
    if isOpen then
        return
    end

    isOpen = true
    setVisible(true)
    requestPlayers()

    if refreshThread then
        return
    end

    refreshThread = CreateThread(function()
        while isOpen do
            Wait(Config.RefreshIntervalMs)
            if isOpen then
                requestPlayers()
            end
        end

        refreshThread = nil
    end)
end

RegisterNetEvent('discord_tab:client:updatePlayers', function(payload)
    if not isOpen then
        return
    end

    SendNUIMessage({
        type = 'update',
        payload = payload
    })
end)

RegisterNUICallback('close', function(_, cb)
    closeScoreboard()
    cb({ ok = true })
end)

RegisterCommand('+' .. Config.Keybind.command, function()
    openScoreboard()
end, false)

RegisterCommand('-' .. Config.Keybind.command, function()
    closeScoreboard()
end, false)

RegisterKeyMapping('+' .. Config.Keybind.command, 'Open Discord Scoreboard', 'keyboard', Config.Keybind.default)

CreateThread(function()
    while true do
        if isOpen then
            Wait(0)
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 200, true)
        else
            Wait(500)
        end
    end
end)
