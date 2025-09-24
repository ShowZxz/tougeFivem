function spawnCar(player,model, coords)
    -- Charger le modèle du véhicule
    print("Spawn car for player " .. player .. " with model " .. model .. " at coords " .. coords.x .. ", " .. coords.y .. ", " .. coords.z)
    local lastVeh = GetLastDrivenVehicle()
    if lastVeh and lastVeh ~= 0 then
        DeleteEntity(lastVeh)
    end

    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end

    local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, coords.heading or 0.0, true, false)
    fullCustom(player, vehicle)
    -- Mettre le joueur dans le véhicule
    SetPedIntoVehicle(player, vehicle, -1) -- -1 pour le siège conducteur

    --freeze le vehicle pendant 5 secondes
    FreezeEntityPosition(vehicle, true)
    Citizen.SetTimeout(5000, function()
        FreezeEntityPosition(vehicle, false)
        message("Le véhicule est maintenant déverrouillé. Bonne chance !")
    end)

    -- Libérer le modèle
    SetModelAsNoLongerNeeded(model)

    print("Véhicule " .. model .. " créé et vous êtes monté dedans.")

    
end

function fullCustom(player, veh)
    --local veh = GetVehiclePedIsIn(player, false)
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
            -- Couleur rouge
            SetVehicleColours(veh, 27, 27) -- 27 = rouge
            print("Véhicule full custom rouge !")
        else
            print("Vous n'êtes pas dans un véhicule.")
    end
end

function message(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    ThefeedSetNextPostBackgroundColor(140)
    EndTextCommandThefeedPostTicker(false, true)
end

