-- client.lua

RegisterCommand("tjoin", function()
    message("Vous entrez dans la queue de test.")
    
    -- On envoie le nom (pour affichage) ; l'identifiant serveur est fourni automatiquement (source côté serveur)
    local playerName = GetPlayerName(PlayerId())
    TriggerServerEvent("tougue:server:joinQueue", playerName)
end)

RegisterNetEvent("tougue:client:notify")
AddEventHandler("tougue:client:notify", function(msg)
    message(msg)
end)

RegisterNetEvent("tougue:client:startMatch")
AddEventHandler("tougue:client:startMatch", function(lead, chaser, matchInfo)
    message("Le jeu commence maintenant !")
    -- log ou préparation côté client si besoin
end)

RegisterNetEvent("tougue:client:spawnCarLead")
AddEventHandler("tougue:client:spawnCarLead", function(model, coords)
    print("Event spawnCarLead received " .. tostring(model) .. " at " .. tostring(coords.x) .. "," .. tostring(coords.y) .. "," .. tostring(coords.z))
    spawnCar(PlayerPedId(), model, coords)
end)

RegisterNetEvent("tougue:client:spawnCarChaser")
AddEventHandler("tougue:client:spawnCarChaser", function(model, coords)
    spawnCar(PlayerPedId(), model, coords)
end)

-- Affichage simple en HUD
function message(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    ThefeedSetNextPostBackgroundColor(140)
    EndTextCommandThefeedPostTicker(false, true)
end

-- Spawn safe d'un vehicle et mise dedans
function spawnCar(playerPed, modelName, coords)
    if not modelName or not coords then
        print("spawnCar: modelName ou coords manquant")
        return
    end

    local modelHash = GetHashKey(modelName)

    -- Charger le modèle
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

    -- Créer le véhicule
    local heading = coords.heading or 0.0
    local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, false)

    if not vehicle or vehicle == 0 then
        print("Erreur: véhicule non créé.")
        SetModelAsNoLongerNeeded(modelHash)
        return
    end

    -- Personnalisation basique
    fullCustom(playerPed, vehicle)

    -- Mettre le joueur dans le véhicule
    SetPedIntoVehicle(playerPed, vehicle, -1)

    -- Freeze le véhicule pendant 5s
    FreezeEntityPosition(vehicle, true)
    Citizen.SetTimeout(5000, function()
        FreezeEntityPosition(vehicle, false)
        message("Le véhicule est maintenant déverrouillé. Bonne chance !")
    end)

    -- Libération du modèle
    SetModelAsNoLongerNeeded(modelHash)

    print("Véhicule " .. tostring(modelName) .. " créé et vous êtes monté dedans.")
end

function fullCustom(player, veh)
    if veh and veh ~= 0 then
        SetVehicleModKit(veh, 0)

        -- Moteur max (modType 11)
        local engineMods = GetNumVehicleMods(veh, 11)
        if engineMods > 0 then
            SetVehicleMod(veh, 11, engineMods - 1, false)
        end

        -- Transmission max (modType 13)
        local transMods = GetNumVehicleMods(veh, 13)
        if transMods > 0 then
            SetVehicleMod(veh, 13, transMods - 1, false)
        end

        -- Suspension max (modType 15)
        local suspMods = GetNumVehicleMods(veh, 15)
        if suspMods > 0 then
            SetVehicleMod(veh, 15, suspMods - 1, false)
        end

        -- Turbo
        ToggleVehicleMod(veh, 18, true)

        -- Couleur rouge (primary, secondary)
        SetVehicleColours(veh, 27, 27)
        print("Véhicule full custom rouge !")
    else
        print("fullCustom: véhicule invalide.")
    end
end
