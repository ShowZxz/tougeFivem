local words = {}
local guessed = {}
local isPlaying = false
local isInLobby = false

local gameZone = {
    center = vector3(683.53, 581.43, 130.46),
    radius = 30.0,
    centerLobby = vector3(689.21887207031, 578.84558105469, 130.46127319336),
    radiusLobby = 30.0
}




function message(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    ThefeedSetNextPostBackgroundColor(184)
    EndTextCommandThefeedPostTicker(false, true)
end

function errorMsg(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    ThefeedSetNextPostBackgroundColor(6)
    EndTextCommandThefeedPostTicker(true, true)
end

function DrawText3D(coords, text)
    local camCoords = GetGameplayCamCoords()
    local dist = #(coords - camCoords)

    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    SetTextScale(0.0 * scale, 0.55 * scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(true)

    SetDrawOrigin(coords.x, coords.y, coords.z, 0)

    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)

    ClearDrawOrigin()
end

local function lookAt(center)
    local ped = PlayerPedId()
    TaskLookAtCoord(ped, center.x, center.y, center.z, -1, 0, 2)
end

local function resetClient()
    words = {}
    guessed = {}
    isPlaying = false
    isInLobby = false
end

CreateThread(function()
    while true do
        Wait(5)

        if not isPlaying then
            goto continue
        end

        local myCoords = GetEntityCoords(PlayerPedId())

        for _, player in ipairs(GetActivePlayers()) do

            local serverId = GetPlayerServerId(player)

            if words[serverId] then

                if player ~= PlayerId() then

                    local ped = GetPlayerPed(player)
                    local coords = GetEntityCoords(ped)

                    local distance = #(myCoords - coords)

                    if distance < 10.0 then

                        local text = ""

                        if guessed[serverId] then
                            text = "~g~✔ " .. guessed[serverId]
                        else
                            text = "~y~* " .. words[serverId] .. " *"
                        end

                        DrawText3D(
                            vector3(coords.x, coords.y, coords.z + 1.2),
                            text
                        )

                    end

                end

            end

        end
        ::continue::
    end
end)

--OutOfZone game = playing
CreateThread(function()

    while true do
        Wait(1000)

        if not isPlaying then
            goto continue
        end

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        local dist = #(coords - gameZone.center)

        if dist > gameZone.radius then

            TriggerServerEvent("whoiam:outOfZone")
            isPlaying = false
            Wait(3000)
        end

        ::continue::
    end

end)

--OutOfZoneLobby game = waiting
CreateThread(function()

    while true do
        Wait(1000)

        if not isInLobby then
            goto continue
        end

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        local dist = #(coords - gameZone.centerLobby)

        if dist > gameZone.radiusLobby then

            TriggerServerEvent("whoiam:outOfZoneLobby")
            isInLobby = false

            
            Wait(3000)
        end

        ::continue::
    end

end)


RegisterNetEvent("whoiam:startGame")
AddEventHandler("whoiam:startGame", function(serverWords)
    words = serverWords
    isPlaying = true
    guessed = {}
    message("Le jeu WhoIAm commence ! Devinez votre mot.")
end)

RegisterNetEvent("whoiam:addMessage", function(msg)
    message(msg)
end)

RegisterNetEvent("whoiam:addErrorMessage", function(msg)
    errorMsg(msg)
end)

RegisterNetEvent("whoiam:teleportPlayers")
AddEventHandler("whoiam:teleportPlayers", function(coords,isJoin)
    local ped = PlayerPedId()

    SetEntityCoords(ped, coords.x, coords.y, coords.z)

    Wait(100)

    lookAt(coords)

    if isJoin then
        message("Bienvenue dans le lobby ! Attendez que le jeu commence.")
        isInLobby = true
    end
end)

RegisterNetEvent("whoiam:playerGuessed")
AddEventHandler("whoiam:playerGuessed", function(playerId, word)
    guessed[playerId] = word
end)

RegisterNetEvent("whoiam:resetPlayer")
AddEventHandler("whoiam:resetPlayer", function()
    message("Reset")
    resetClient()
end)

RegisterNetEvent("whoiam:removePlayer")
AddEventHandler("whoiam:removePlayer", function(playerId)

    words[playerId] = nil
    guessed[playerId] = nil

end)

RegisterNetEvent("whoiam:playAnimation")
AddEventHandler("whoiam:playAnimation", function(animation)
    local ped = PlayerPedId()

    if animation == "valid" then
        RequestAnimDict("anim@mp_player_intcelebrationfemale@uncle_disco")
        while not HasAnimDictLoaded("anim@mp_player_intcelebrationfemale@uncle_disco") do
            Wait(10)
        end
        TaskPlayAnim(ped, "anim@mp_player_intcelebrationfemale@uncle_disco", "uncle_disco", 8.0, -8.0, -1, 0, 0, false, false, false)
    end

    if animation == "invalid" then
        RequestAnimDict("anim@mp_player_intcelebrationfemale@face_palm")
        while not HasAnimDictLoaded("anim@mp_player_intcelebrationfemale@face_palm") do
            Wait(10)
        end
        TaskPlayAnim(ped, "anim@mp_player_intcelebrationfemale@face_palm", "face_palm", 8.0, -8.0, -1, 0, 0, false, false, false)
    end
end)