-- client.lua

local controlsBlocked = false
local blockThread = nil

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


RegisterNetEvent("tougue:client:prepareRound")
AddEventHandler("tougue:client:prepareRound", function(matchId, role, modelName, coordsTable)
    local player = PlayerPedId()
    message("Préparation du round (" .. tostring(role) .. ") ...")

    -- spawnCar (ta fonction existante) : on laisse la voiture freeze pour le countdown serveur
    local veh = spawnCar(player, modelName, coordsTable)

    -- Bloquer les contrôles pendant la phase de préparation
    blockPlayerControls(true)

    -- Quand le véhicule est prêt et freeze, on avertit le serveur en envoyant matchId
    TriggerServerEvent("tougue:server:playerReady", matchId)
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

    -- Débloquer le véhicule et les contrôles
    local player = PlayerPedId()
    local veh = GetVehiclePedIsIn(player, false)
    if veh and veh ~= 0 then
        FreezeEntityPosition(veh, false)
    end
    blockPlayerControls(false)
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

    -- ⚠️ Ici on freeze, mais pour le mode Touge on NE DÉFREEZE PAS directement.
    -- Le serveur va gérer le countdown et débloquer après.
    FreezeEntityPosition(vehicle, true)

    -- Libération du modèle
    SetModelAsNoLongerNeeded(modelHash)

    print("Véhicule " .. tostring(modelName) .. " créé et vous êtes monté dedans.")
    return vehicle
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

function blockPlayerControls(enable)
    controlsBlocked = enable
    if enable then
        if blockThread then return end
        blockThread = Citizen.CreateThread(function()
            while controlsBlocked do
                -- désactiver mouvements et actions utiles (tu peux ajuster)
                DisableControlAction(0, 30, true) -- mouvement gauche/droite
                DisableControlAction(0, 31, true) -- mouvement avant/arrière
                DisableControlAction(0, 21, true) -- sprint
                DisableControlAction(0, 24, true) -- tir
                DisableControlAction(0, 75, true) -- quitter véhicule
                DisableControlAction(0, 23, true) -- entrée menu
                Wait(0)
            end
            blockThread = nil
        end)
    else
        controlsBlocked = false
    end
end