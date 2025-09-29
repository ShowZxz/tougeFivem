function message(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    ThefeedSetNextPostBackgroundColor(140)
    EndTextCommandThefeedPostTicker(false, true)

end
function playCheckpointSound()
    PlaySoundFrontend(-1, "CHECKPOINT_NORMAL", "HUD_MINI_GAME_SOUNDSET", true)
    
end
function drawCheckpoint(trackCheckpoint)
    print("Dessin des checkpoints pour la course: " .. trackCheckpoint.name)
    local player = PlayerPedId()
    local radius = 10.0
    local checkpointType = 6 
    local currentCheckpointIndex = 1
    local checkpoints = trackCheckpoint.checkpoints
    local timeoutRace = trackCheckpoint.meta.timeLimit or 100000
    local raceActive = true
    local startTime = GetGameTimer()
    local timeLeft = timeoutRace
    print("Timeout de la course: " .. timeoutRace .. " ms")
    -- Timer limite et affichage
    if timeoutRace > 0 then
        Citizen.CreateThread(function()
            while raceActive and timeLeft > 0 do
                Citizen.Wait(0)
                local now = GetGameTimer()
                timeLeft = timeoutRace - (now - startTime)
                -- Affiche le temps restant en haut à gauche
                local sec = math.max(0, math.floor(timeLeft / 1000))
                DrawTxt("Temps restant: " .. sec .. "s", 0.02, 0.02)
                
            end
            if raceActive and timeLeft <= 0 then
                message("Temps écoulé !")
                TriggerServerEvent("mon_script:server:raceTimeout")
                raceActive = false
            end
        end)
    end

    Citizen.CreateThread(function()
        while currentCheckpointIndex <= #checkpoints and raceActive do
            Citizen.Wait(0)
            local cp = checkpoints[currentCheckpointIndex]
            DrawMarker(checkpointType, cp.pos.x, cp.pos.y, cp.pos.z+3, 0, 0, 0, 0, 0, 0, cp.radius, cp.radius, cp.radius, 0, 0, 255, 100, false, true, 2, nil, nil, false)
            local distance = #(GetEntityCoords(player) - vector3(cp.pos.x, cp.pos.y, cp.pos.z))
            if distance < cp.radius then
                message("Checkpoint " .. currentCheckpointIndex .. " atteint !")
                playCheckpointSound()
                TriggerServerEvent("mon_script:server:checkpointPassed", currentCheckpointIndex)
                currentCheckpointIndex = currentCheckpointIndex + 1
                Wait(1000)
            end
        end
        if raceActive then
            message("Course terminée !")
        end
        raceActive = false
    end)
end

-- Affichage texte simple en haut à gauche
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