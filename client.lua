local display = false
local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('YarramiYedi:ChemTR', function(players, language, translations)
    if display then return end
    
    display = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "open",
        players = players,
        language = language,
        translations = translations
    })
end)

RegisterNUICallback('closeMenu', function()
    display = false
    SetNuiFocus(false, false)
end)

RegisterNUICallback('ZorlaCKAt', function(data)
    TriggerServerEvent('beqeend:KarakteriOldur', data.playerId)
end)

CreateThread(function()
    while true do
        Wait(0)
        if display and IsControlJustPressed(0, 177) then
            display = false
            SetNuiFocus(false, false)
            SendNUIMessage({
                type = "close"
            })
        end
    end
end) 