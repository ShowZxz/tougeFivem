-- client.lua (version complète, compatible avec le server.lua fourni)

-- état global client
local controlsBlocked = false
local blockThread = nil
local checkpointThread = nil
local raceTimerThread = nil
local activeMatch = nil
local POS_SEND_INTERVAL = 800 -- ms (client side)

local posThread = nil

-- COMMANDES -------------------------------------------------------
RegisterCommand("tjoin", function()
    message("Vous entrez dans la queue de test.")
    local playerName = GetPlayerName(PlayerId())
    TriggerServerEvent("tougue:server:joinQueue", playerName)
end)

-- EVENTS ---------------------------------------------------------
RegisterNetEvent("tougue:client:notify")
AddEventHandler("tougue:client:notify", function(msg)
    message(msg)
end)

RegisterNetEvent("tougue:client:notifyCatch")
AddEventHandler("tougue:client:notifyCatch", function(matchId, info)
    message("Vous êtes collé au lead ! Restez derrière ou dépassez-le.")
    PlaySoundFrontend(-1, "CHECKPOINT_NORMAL", "HUD_MINI_GAME_SOUNDSET", true)
end)

RegisterNetEvent("tougue:client:notifyCaughtBy")
AddEventHandler("tougue:client:notifyCaughtBy", function(matchId, info)
    message("Attention : le chaser vous a rattrapé !")
    PlaySoundFrontend(-1, "ALARM_CLOCK_WARNING", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
end)

RegisterNetEvent("tougue:client:notifyCatchLost")
AddEventHandler("tougue:client:notifyCatchLost", function(matchId, info)
    message("Vous n'êtes plus collé.")
    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
end)

RegisterNetEvent("tougue:client:notifyNoLongerCaught")
AddEventHandler("tougue:client:notifyNoLongerCaught", function(matchId, info)
    message("Le chaser s'est éloigné.")
    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
end)

-- overtake notifications (optionnel)
RegisterNetEvent("tougue:client:notifyOvertake")
AddEventHandler("tougue:client:notifyOvertake", function(matchId, info)
    message("Dépassement validé ! Vous avez pris l'avantage.")
    PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
end)

RegisterNetEvent("tougue:client:notifyOvertaken")
AddEventHandler("tougue:client:notifyOvertaken", function(matchId, info)
    message("Vous venez d'être dépassé ! Reprenez la position.")
    PlaySoundFrontend(-1, "MP_LI", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
end)


RegisterNetEvent("tougue:client:prepareRound")
AddEventHandler("tougue:client:prepareRound", function(matchId, role, modelName, coordsTable, track)
    -- stoppe proprement l'ancien round si besoin
    if activeMatch and activeMatch.running then
        activeMatch.running = false
        Citizen.Wait(150)
    end

    local player = PlayerPedId()
    message("Préparation du round (" .. tostring(role) .. ") ...")

    -- spawn vehicle (freeze inside)
    local veh = spawnCar(player, modelName, coordsTable)

    -- bloquer controls pendant préparation
    blockPlayerControls(true)

    -- initialiser activeMatch
    activeMatch = {
        id = matchId,
        role = role,
        track = track,
        nextIndex = 1,          -- index attendu côté client (avancé à la confirmation serveur)
        running = true,
        sentFor = {},           -- table pour éviter d'envoyer plusieurs fois le même checkpoint
    }

    -- debug print des checkpoints (utile au dev)
    for i, cp in ipairs(track.checkpoints) do
        print(("CP %d : x=%.2f y=%.2f z=%.2f r=%.2f"):format(i, cp.pos.x, cp.pos.y, cp.pos.z, cp.radius or 0))
    end

    -- notifier serveur qu'on est prêt
    TriggerServerEvent("tougue:server:playerReady", matchId)

    -- lancer la boucle des checkpoints (non bloquant)
    startCheckpointLoop()
end)

RegisterNetEvent("tougue:client:startCountdown")
AddEventHandler("tougue:client:startCountdown", function(seconds)
    seconds = tonumber(seconds) or 3
    for i = seconds, 1, -1 do
        message(tostring(i))
        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
        Wait(1000)
    end
    message("Go !")

    -- debloquer véhicule + controls
    local player = PlayerPedId()
    local veh = GetVehiclePedIsIn(player, false)
    if veh and veh ~= 0 then
        FreezeEntityPosition(veh, false)
        startPosLoop()
    end
    blockPlayerControls(false)
end)

RegisterNetEvent("tougue:client:startRaceTimer")
AddEventHandler("tougue:client:startRaceTimer", function(timeout)
    -- lance la UI timer
    if not activeMatch then return end
    timeout = tonumber(timeout) or 0
    if timeout <= 0 then return end

    -- stop ancien timer si présent (drapeau activeMatch.running gère l'arrêt)
    local startTime = GetGameTimer()
    local timeLeft = timeout

    if raceTimerThread then
        -- on laisse l'ancien thread se terminer (flag), on démarre un nouveau
        raceTimerThread = nil
    end

    raceTimerThread = Citizen.CreateThread(function()
        while activeMatch and activeMatch.running and timeLeft > 0 do
            Citizen.Wait(250)
            local now = GetGameTimer()
            timeLeft = timeout - (now - startTime)
            local sec = math.max(0, math.floor(timeLeft / 1000))
            DrawTxt("Temps restant: " .. sec .. "s", 0.02, 0.02)
        end

        if activeMatch and activeMatch.running and timeLeft <= 0 then
            message("Temps écoulé !")
            if activeMatch and activeMatch.id then
                TriggerServerEvent("tougue:server:raceTimeout", activeMatch.id)
            else
                TriggerServerEvent("tougue:server:raceTimeout", nil)
            end
            if activeMatch then activeMatch.running = false end
        end

        raceTimerThread = nil
    end)
end)

-- confirmation serveur d'un checkpoint validé
RegisterNetEvent("tougue:client:checkpointValidated")
AddEventHandler("tougue:client:checkpointValidated", function(matchId, index)
    if not activeMatch or activeMatch.id ~= matchId then
        -- peut arriver si on a changé de round; ignore proprement
        print(("Client: checkpointValidated reçu pour match %s mais activeMatch=%s"):format(tostring(matchId), tostring(activeMatch and activeMatch.id or "nil")))
        return
    end
    activeMatch.nextIndex = math.max(activeMatch.nextIndex, index + 1)
    if activeMatch.sentFor then activeMatch.sentFor[index] = nil end
    print(("Client: checkpoint confirmé par serveur (%s) index=%d -> next=%d"):format(matchId, index, activeMatch.nextIndex))
end)

-- fin de round (server notifie)
RegisterNetEvent("tougue:client:roundEnd")
AddEventHandler("tougue:client:roundEnd", function(matchId, result)
    -- vérifier que c'est bien le match en cours
    if not activeMatch or activeMatch.id ~= matchId then
        print(("Client: roundEnd reçu pour match %s mais activeMatch=%s"):format(tostring(matchId), tostring(activeMatch and activeMatch.id or "nil")))
        return
    end

    -- arrêter proprement les threads
    activeMatch.running = false
    blockPlayerControls(false)

    message("Round terminé ! Gagnant : " .. tostring(result.winner))

    -- attendre un court délai pour permettre au serveur d'envoyer nextRound
    Citizen.CreateThread(function()
        Wait(200)
        -- cleanup local ; si le serveur démarre le prochain round il enverra prepareRound qui recréera activeMatch
        activeMatch = nil
        checkpointThread = nil
    end)
end)

-- fin du match
RegisterNetEvent("tougue:client:matchEnd")
AddEventHandler("tougue:client:matchEnd", function(matchId, result)
    message("Match terminé ! Vainqueur : " .. tostring(result.winner))
    -- cleanup local
    if activeMatch and activeMatch.id == matchId then
        activeMatch.running = false
        activeMatch = nil
    end
end)

-- UI / Utils -----------------------------------------------------
function message(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    ThefeedSetNextPostBackgroundColor(140)
    EndTextCommandThefeedPostTicker(false, true)
end

function DrawTxt(text, x, y)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.35, 0.35)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

function playCheckpointSound()
    PlaySoundFrontend(-1, "CHECKPOINT_NORMAL", "HUD_MINI_GAME_SOUNDSET", true)
end

-- SPAWN VEHICLE --------------------------------------------------
function spawnCar(playerPed, modelName, coords)
        local veh = GetVehiclePedIsIn(player, false)
    local lastVeh = GetLastDrivenVehicle()
    veh = lastVeh
    if veh and veh ~= 0 then
        DeleteEntity(veh)
    end
    if not modelName or not coords then
        print("spawnCar: modelName ou coords manquant")
        return
    end

    local modelHash = GetHashKey(modelName)
    RequestModel(modelHash)
    local timeout = 5000
    local tStart = GetGameTimer()
    while not HasModelLoaded(modelHash) and (GetGameTimer() - tStart) < timeout do
        Wait(10)
    end

    if not HasModelLoaded(modelHash) then
        print("Impossible de charger le modèle: " .. tostring(modelName))
        return
    end

    local heading = coords.heading or 0.0
    local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, false)
    if not vehicle or vehicle == 0 then
        print("Erreur: véhicule non créé.")
        SetModelAsNoLongerNeeded(modelHash)
        return
    end

    fullCustom(playerPed, vehicle)

    SetPedIntoVehicle(playerPed, vehicle, -1)
    FreezeEntityPosition(vehicle, true)
    SetModelAsNoLongerNeeded(modelHash)

    print("Véhicule " .. tostring(modelName) .. " créé et vous êtes monté dedans.")
    return vehicle
end

function fullCustom(player, veh)
    if not veh or veh == 0 then return end
    SetVehicleModKit(veh, 0)
    local engineMods = GetNumVehicleMods(veh, 11)
    if engineMods > 0 then SetVehicleMod(veh, 11, engineMods - 1, false) end
    local transMods = GetNumVehicleMods(veh, 13)
    if transMods > 0 then SetVehicleMod(veh, 13, transMods - 1, false) end
    local suspMods = GetNumVehicleMods(veh, 15)
    if suspMods > 0 then SetVehicleMod(veh, 15, suspMods - 1, false) end
    ToggleVehicleMod(veh, 18, true)
    SetVehicleColours(veh, 27, 27)
end

-- CONTROLS BLOCK -------------------------------------------------
function blockPlayerControls(enable)
    controlsBlocked = enable
    if enable then
        if blockThread then return end
        blockThread = Citizen.CreateThread(function()
            while controlsBlocked do
                DisableControlAction(0, 30, true) -- left/right
                DisableControlAction(0, 31, true) -- forward/back
                DisableControlAction(0, 21, true) -- sprint
                DisableControlAction(0, 24, true) -- fire
                DisableControlAction(0, 75, true) -- leave vehicle
                DisableControlAction(0, 23, true) -- enter
                Wait(0)
            end
            blockThread = nil
        end)
    else
        controlsBlocked = false
    end
end

-- CHECKPOINT LOOP ------------------------------------------------
function startCheckpointLoop()
    -- signaler à l'ancienne boucle de s'arrêter et attendre sa fin
    if checkpointThread then
        if activeMatch then activeMatch.running = false end
        Wait(150)
        -- on ne kill pas la thread, on attend qu'elle termine proprement
    end

    -- si activeMatch est déjà nil, on ne lance rien
    if not activeMatch then return end

    -- capture de la référence locale pour éviter les races si activeMatch est remplacée
    local match = activeMatch

    checkpointThread = Citizen.CreateThread(function()
        while match and match.running and match.nextIndex <= #match.track.checkpoints do
            Wait(100)
            -- double-guard si match a été nulled ailleurs
            if not match or not match.running then break end

            local playerPed = PlayerPedId()
            local playerPos = GetEntityCoords(playerPed)
            local idx = match.nextIndex
            local cp = match.track.checkpoints[idx]
            if not cp then break end

            -- draw marker
            DrawMarker(6, cp.pos.x, cp.pos.y, cp.pos.z + 1.0, 0,0,0, 0,0,0, cp.radius*2.0, cp.radius*2.0, 1.0, 0,100,255, 90, false, true, 2, nil, nil, false)

            local dist = #(playerPos - vector3(cp.pos.x, cp.pos.y, cp.pos.z))
            if dist <= (cp.radius or 5.0) then
                -- anti-spam local
                if match.sentFor and match.sentFor[idx] then
                    -- déjà envoyé, on attend confirmation
                else
                    -- joue son + notif locale
                    playCheckpointSound()
                    message("Checkpoint " .. idx .. " atteint (envoi serveur)...")
                    TriggerServerEvent("tougue:server:checkpointPassed", match.id, idx, { x = playerPos.x, y = playerPos.y, z = playerPos.z }, GetGameTimer())
                    match.sentFor = match.sentFor or {}
                    match.sentFor[idx] = true
                end
            end
        end
        -- assure la nullification du thread local
        checkpointThread = nil
    end)
end

function startPosLoop()
    -- si déjà lancé, on lève
    if posThread then return end
    if not activeMatch or not activeMatch.running then return end

    posThread = Citizen.CreateThread(function()
        while activeMatch and activeMatch.running do
            local player = PlayerPedId()
            local inVeh = IsPedInAnyVehicle(player, false)
            local pos = GetEntityCoords(player)
            local ts = GetGameTimer()

            -- si tu veux envoyer la position du véhicule au lieu du ped, fais:
            if inVeh then
                local veh = GetVehiclePedIsIn(player, false)
                if veh and veh ~= 0 then
                    pos = GetEntityCoords(veh)
                end
            end

            -- envoi vers le serveur : matchId, pos, ts
            if activeMatch and activeMatch.id then
                TriggerServerEvent("tougue:server:posUpdate", activeMatch.id, { x = pos.x, y = pos.y, z = pos.z }, ts)
            end

            print(("Client: posUpdate envoyé (x=%.2f y=%.2f z=%.2f)"):format(pos.x, pos.y, pos.z))

            Citizen.Wait(POS_SEND_INTERVAL)
        end
        posThread = nil
    end)
end

-- Clean up on resource stop / manual cleanup (optional)
AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if activeMatch then activeMatch.running = false end
    controlsBlocked = false
end)

-- End of client.lua
