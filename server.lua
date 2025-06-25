local QBCore = exports['qb-core']:GetCoreObject()
local Avatars = {}
RiseCore = exports['Rise-Core']:RiseCore()

function GetLocale(key)
    return RiseDev.Locales[RiseDev.Language][key]
end

local function HasPermission(source)
    local discordId = nil
    for _, identifier in pairs(GetPlayerIdentifiers(source)) do
        if string.find(identifier, "discord:") then
            discordId = string.sub(identifier, 9)
            break
        end
    end

    return discordId and RiseDev.AuthorizedDiscords[discordId] or false
end

function getPlayerAvatar(src)
    if not Avatars[src] then
        local identifiers = {}
        local discord = nil

        for i = 0, GetNumPlayerIdentifiers(src) - 1 do
            local id = GetPlayerIdentifier(src, i)
            if string.find(id, "discord:") then
                discord = string.sub(id, 9)
                break
            end
        end

        local avatar = nil

        if discord then
            local p = promise.new()
            PerformHttpRequest("https://discordapp.com/api/users/" .. discord, function(statusCode, data)
                if statusCode == 200 then
                    data = json.decode(data or "{}")
                    if data.avatar then
                        local animated = data.avatar:gsub(1, 2) == "a_"
                        avatar = "https://cdn.discordapp.com/avatars/" ..
                            discord .. "/" .. data.avatar .. (animated and ".gif" or ".png")
                    end
                end
                p:resolve()
            end, "GET", "", {
                Authorization = "Bot " .. ServerConfig.DiscordBot.Token
            })
            Citizen.Await(p)
        end

        Avatars[src] = avatar or 'https://cdn.discordapp.com/avatars/1274994399511711794/a_648097c0f5324f37a1cd73621d7567bd.gif?size=1024'
    end

    return Avatars[src]
end

RiseCore.Komut.Ekle(RiseDev.INFO.Commands, GetLocale('command_desc'), {}, false, function(source)
    local src = source
    if not HasPermission(src) then
        TriggerClientEvent('RiseDevelopment:Notify', src, GetLocale('no_discord_permission'), 'error', 3000, GetLocale('notify_title_error'))
        return
    end

    local players = {}
    for _, player in pairs(RiseCore.Functions.GetPlayers()) do
        local Player = RiseCore.Functions.GetPlayer(tonumber(player))
        if Player then
            players[#players + 1] = {
                id = player,
                name = string.format("%s %s", Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname),
                online = true,
                avatar = getPlayerAvatar(player)
            }
        end
    end

    MySQL.query('SELECT citizenid, charinfo FROM players', {}, function(result)
        if result then
            for _, player in pairs(result) do
                local found = false
                local charinfo = json.decode(player.charinfo)
                
                for _, activePlayer in pairs(players) do
                    if activePlayer.citizenid == player.citizenid then
                        found = true
                        break
                    end
                end
                
                if not found then
                    players[#players + 1] = {
                        id = player.citizenid,
                        name = string.format("%s %s", charinfo.firstname, charinfo.lastname),
                        online = false,
                        avatar = nil
                    }
                end
            end
        end
        TriggerClientEvent('YarramiYedi:ChemTR', src, players, RiseDev.Language, RiseDev.Locales)
    end)
end)

RegisterNetEvent('beqeend:KarakteriOldur')
AddEventHandler('beqeend:KarakteriOldur', function(playerId)
    local src = source
    if not HasPermission(src) then
        TriggerClientEvent('RiseDevelopment:Notify', src, GetLocale('no_discord_permission_action'), 'error', 3000, GetLocale('notify_title_error'))
        return
    end

    local Player = RiseCore.Functions.GetPlayer(tonumber(playerId))
    if Player then
        local citizenid = Player.PlayerData.citizenid
        SendToDiscord(playerId, src)
        DropPlayer(playerId, GetLocale('kick_message'))
        DeleteCharacterData(citizenid, src)
    else
        SendToDiscord(playerId, src)
        DeleteCharacterData(playerId, src)
    end
end)

function DeleteCharacterData(citizenid, src)
    CreateThread(function()
        Wait(100)
        for _, table in pairs(RiseDev.DeleteTables) do
            MySQL.query('DELETE FROM ?? WHERE citizenid = ?', {table, citizenid})
        end
        TriggerClientEvent('RiseDevelopment:Notify', src, GetLocale('character_deleted'), 'success', 3000, GetLocale('notify_title_success'))
    end)
end 

function SendToDiscord(playerId, adminId, reason)
    local player = GetPlayerInfo(playerId)
    local admin = GetPlayerInfo(adminId)
    
    local embed = {
        {
            ["title"] = GetLocale('log_title'),
            ["color"] = ServerConfig.Colors.Red,
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            ["fields"] = {
                {
                    ["name"] = GetLocale('log_deleted_char'),
                    ["value"] = string.format(
                        "%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: %s",
                        GetLocale('log_name'), player.name,
                        GetLocale('log_discord'), player.discord,
                        GetLocale('log_steam'), player.steam,
                        GetLocale('log_ip'), player.ip,
                        GetLocale('log_citizenid'), player.citizenid
                    ),
                    ["inline"] = false
                },
                {
                    ["name"] = GetLocale('log_admin_info'),
                    ["value"] = string.format(
                        "%s: %s\n%s: %s\n%s: %s\n%s: %s",
                        GetLocale('log_name'), admin.name,
                        GetLocale('log_discord'), admin.discord,
                        GetLocale('log_steam'), admin.steam,
                        GetLocale('log_ip'), admin.ip
                    ),
                    ["inline"] = false
                }
            },
            ["footer"] = {
                ["text"] = 'Rise Development'
            }
        }
    }

    PerformHttpRequest(ServerConfig.Webhooks.CharacterDelete, function(err, text, headers) end, 'POST', json.encode({
        username = 'Rise Dev CK',
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end


function GetPlayerInfo(id)
    local info = {
        name = "Bilinmiyor",
        discord = "Bilinmiyor",
        steam = "Bilinmiyor",
        ip = "Bilinmiyor",
        citizenid = "Bilinmiyor"
    }
    
    if not id then return info end

    local Player = RiseCore.Functions.GetPlayer(tonumber(id))
    if Player then
        info.name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        info.citizenid = Player.PlayerData.citizenid
    end

    for _, identifier in pairs(GetPlayerIdentifiers(id)) do
        if string.find(identifier, "discord:") then
            info.discord = string.sub(identifier, 9)
        elseif string.find(identifier, "steam:") then
            info.steam = identifier
        end
    end
    
    info.ip = GetPlayerEndpoint(id)
    
    return info
end 