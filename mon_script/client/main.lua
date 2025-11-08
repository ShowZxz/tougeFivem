local tracks = {
    {
        id = "vinewood_antenna",
        name = "Montée l'antenne de Vinewood",
        description = "Course courte et technique jusqu'à l'antenne de Vinewood.",
        start = { x = 472.0, y = 884.0, z = 197.6, heading = 345.21 },
        finish = { x = 805.91003417969, y = 1275.5114746094, z = 359.8896789550 },
        blip = {
            sprite = 1,
            color = 5,
            coords = {
                { pos = { x = 495.57968139648, y = 975.55279541016, z = 206.3720703125 },  scale = 1.0 },
                { pos = { x = 475.71682739258, y = 1100.7467041016, z = 230.4866790771 },  scale = 1.0 },
                { pos = { x = 493.63165283203, y = 1310.4053955078, z = 281.3562011718 },  scale = 1.0 },
                { pos = { x = 667.21203613281, y = 1369.6392822266, z = 325.96502685547 }, scale = 1.0 },
                { pos = { x = 853.21496582031, y = 1332.9610595703, z = 353.5494995117 },  scale = 1.0 },
                { pos = { x = 805.91003417969, y = 1275.5114746094, z = 359.8896789550 },  scale = 1.5 } -- finish
            }
        },
        checkpoints = {
            { pos = { x = 495.57968139648, y = 975.55279541016, z = 206.3720703125 },  radius = 6.0 },
            { pos = { x = 475.71682739258, y = 1100.7467041016, z = 230.4866790771 },  radius = 6.0 },
            { pos = { x = 493.63165283203, y = 1310.4053955078, z = 281.3562011718 },  radius = 6.0 },
            { pos = { x = 667.21203613281, y = 1369.6392822266, z = 325.96502685547 }, radius = 6.0 },
            { pos = { x = 853.21496582031, y = 1332.9610595703, z = 353.5494995117 },  radius = 6.0 },
            { pos = { x = 805.91003417969, y = 1275.5114746094, z = 359.8896789550 },  radius = 8.0 } -- finish
        },
        meta = {
            maxPlayers = 2,
            minPlayers = 1,
            laps = 1,
            timeLimit = 100000,
            allowedVehicles = { "adder", "zentorno" }, -- empty = any
            reward = { money = 500, points = 10 }
        }
    },

    -- Add more tracks as needed
}
local blipsThread = nil

function createBlipsForTracks()
    for _, track in ipairs(tracks) do
        if track.blip and track.blip.coords then
            track._clientBlips = track._clientBlips or {}
            for i, binfo in ipairs(track.blip.coords) do
                if not track._clientBlips[i] or not DoesBlipExist(track._clientBlips[i]) then
                    local bl = AddBlipForCoord(binfo.pos.x, binfo.pos.y, binfo.pos.z)
                    SetBlipSprite(bl, track.blip.sprite or 1)
                    SetBlipColour(bl, track.blip.color or 5)
                    SetBlipScale(bl, binfo.scale or 1.0)
                    SetBlipAsShortRange(bl, true)
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentString(track.name or "Track Blip")
                    EndTextCommandSetBlipName(bl)
                    SetBlipRoute(bl, false)
                    track._clientBlips[i] = bl
                end
            end
        end
    end
end

-- safe remove helper (ne pas écraser la native RemoveBlip)
local function removeBlipSafe(b)
    if b and DoesBlipExist(b) then
        RemoveBlip(b)
    end
end

function removeAllBlips(track)
    if not track then
        print("removeAllBlips: aucune track fournie")
        return
    end

    -- supprime les blips créés pour la track
    if track._clientBlips then
        for i, b in ipairs(track._clientBlips) do
            removeBlipSafe(b)
            track._clientBlips[i] = nil
        end
        track._clientBlips = nil
    end

    -- supprime le blip actif (si utilisé séparément)
    if track._activeBlip then
        removeBlipSafe(track._activeBlip)
        track._activeBlip = nil
    end

    track._nextIndex = nil
    print(("removeAllBlips: tous les blips supprimés pour track '%s'"):format(tostring(track.name)))
end

function printNextBlip(nextIndex,track)
    --removeBlipSafe(nextIndex - 1)
    -- Logic to handle next blips
    message("Passage au blip suivant: " .. tostring(nextIndex))
    local idx = nextIndex
    print("Index actuel du blip: " .. tostring(idx))
    if not track then
        print("setBlipsForTracks: aucune track trouvée")
        return
    end
    if not track.blip or not track.blip.coords then
        print("setBlipsForTracks: track sans blip.coords")
        return
    end
    local bp = track.blip.coords[idx]
    print("Blip position: " .. tostring(bp.pos.x) .. ", " .. tostring(bp.pos.y) .. ", " .. tostring(bp.pos.z))
    if not bp then return end
    local blip = AddBlipForCoord(bp.pos.x, bp.pos.y, bp.pos.z)
            SetBlipSprite(blip, track.blip.sprite)
            SetBlipColour(blip, track.blip.color)
            SetBlipScale(blip, bp.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Track Blip")
            EndTextCommandSetBlipName(blip)


    
end

RegisterNetEvent("mon_script:client:blipValidated", function(blipIndex,track)
    local playerName = GetPlayerName(PlayerId())
    message(playerName .. " a validé le blip n°" .. blipIndex)
    blipIndex = blipIndex + 1
    printNextBlip(blipIndex,track)
    playCheckpointSound()
end)
function blipsLoopForTracks()
    local track = tracks[1]
    if not track then
        print("blipsLoopForTracks: aucune track trouvée")
        return
    end
    if not track.blip or not track.blip.coords then
        print("blipsLoopForTracks: track sans blip.coords")
        return
    end

    -- crée ou réutilise les blips
    createBlipsForTracks()
    track._nextIndex = 1
    local blips = track._clientBlips or {}

    message("Début de la gestion des blips pour la track: " .. (track.name or "unknown"))
    if blipsThread then return end

    -- active les routes initiales
    if blips[track._nextIndex] and DoesBlipExist(blips[track._nextIndex]) then
        SetBlipRoute(blips[track._nextIndex], true)
    end

    blipsThread = Citizen.CreateThread(function()
        while track._nextIndex and track._nextIndex <= #track.blip.coords do
            Wait(1000)
            local idx = track._nextIndex
            local bp = track.blip.coords[idx]
            if not bp then break end

            local playerPed = PlayerPedId()
            local playerPos = GetEntityCoords(playerPed)
            local dist = #(playerPos - vector3(bp.pos.x, bp.pos.y, bp.pos.z))

            -- debug
            -- print(("blipsLoop: idx=%d dist=%.2f radius=%.2f"):format(idx, dist, bp.radius or 10.0))

            if dist <= (bp.radius or 10.0) then
                message("Checkpoint atteint!")
                -- supprime le blip courant
                if blips[idx] then
                    removeBlipSafe(blips[idx])
                    blips[idx] = nil
                end

                -- notifie le serveur / autres (optionnel)
                TriggerServerEvent("mon_script:server:validatedBlip", idx, track)

                -- passe au suivant
                track._nextIndex = idx + 1

                -- met à jour la route : active la suivante
                if blips[track._nextIndex] and DoesBlipExist(blips[track._nextIndex]) then
                    SetBlipRoute(blips[track._nextIndex], true)
                end

                Wait(500) -- anti-spam local
            end
        end

        -- cleanup final
        removeAllBlips(track)
        blipsThread = nil
    end)
end

function message(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    ThefeedSetNextPostBackgroundColor(140)
    EndTextCommandThefeedPostTicker(false, true)
end

function playCheckpointSound()
    PlaySoundFrontend(-1, "CHECKPOINT_NORMAL", "HUD_MINI_GAME_SOUNDSET", true)
end


function DrawTxt(text, x, y)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.35, 0.35)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

RegisterNetEvent("mon_script:client:clientPrint", function()
    local playerName = GetPlayerName(PlayerId())
    message(playerName .. " a utilisé la commande tuto")
end)

RegisterCommand("testserver", function()
    print("Commande testserver utilisée")
    TriggerServerEvent("mon_script:server:serverPrint")
end)

RegisterNetEvent("mon_script:client:startRace", function(track)
    message("Course démarrée: " .. track.name)
    drawCheckpoint(track)
end)

RegisterCommand("testBp", function()
    blipsLoopForTracks()
end)



RegisterCommand("weather", function(weatherTypes)
    local weatherSelected = weatherTypes or
    { "CLEAR", "EXTRASUNNY", "CLOUDS", "OVERCAST", "RAIN", "THUNDER", "SMOG", "FOGGY", "XMAS", "SNOWLIGHT" }
    SetWeatherTypeOverTime(weatherSelected, 15.0)
    message("Météo changée en: " .. weatherTypes)
end)

RegisterCommand("time", function(hour, minute)
    local h = tonumber(hour) or 12
    local m = tonumber(minute) or 0
    NetworkOverrideClockTime(h, m, 0)
    message("Heure changée en: " .. h .. "h" .. m)
end)
