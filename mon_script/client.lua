RegisterCommand("hello", function()
    print("Hello world!")
end)

RegisterCommand("gps", function()
    local player = PlayerPedId()
    local playerCoords = GetEntityCoords(player)
    local heading = GetEntityHeading(player)
    print("Position: " .. playerCoords.x .. ", " .. playerCoords.y .. ", " .. playerCoords.z .. " | Heading: " .. heading)
end)

RegisterCommand("wp", function(command, args)
    local player = PlayerPedId()
    local blip = GetFirstBlipInfoId(8) -- 8 = waypoint

    if DoesBlipExist(blip) then
        local coords = GetBlipInfoIdCoord(blip)

        if IsPedInAnyVehicle(player, false) then
            -- Le joueur est dans un véhicule
            local veh = GetVehiclePedIsIn(player, false)
            SetEntityCoords(veh, coords.x, coords.y, coords.z)
            print("Téléporté au waypoint avec le véhicule")
        else
            -- Le joueur est à pied
            SetEntityCoords(player, coords.x, coords.y, coords.z)
            print("Téléporté au waypoint à pied")
        end
    else
        print("Aucun waypoint trouvé")
    end
end)

RegisterCommand("damage", function()
    local player = PlayerPedId()
    local health = GetEntityHealth(player)
    local newHealth = health - 10
    SetEntityHealth(player, newHealth)
    print("Vous avez perdu 10 points de vie. Santé actuelle : " .. newHealth)
end)

RegisterCommand("heal", function()
    local player = PlayerPedId()
    SetEntityHealth(player, 200)
    print("Vous avez été soigné. Santé actuelle : 200")
end)

RegisterCommand("car", function(source, args, rawCommand)
    local player = PlayerPedId()
    -- supprimer le dernier vehicule si le joueur en a un
    local veh = GetVehiclePedIsIn(player, false)
    local lastVeh = GetLastDrivenVehicle()
    veh = lastVeh
    if veh and veh ~= 0 then
        DeleteEntity(veh)
    end
   

    local model = args[1] or "futo" -- Si aucun modèle n'est fourni, utilise "futo" par défaut

    -- Charger le modèle du véhicule
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end

    -- Obtenir la position du joueur
    local playerCoords = GetEntityCoords(player)

    -- Créer le véhicule à la position du joueur
    local vehicle = CreateVehicle(model, playerCoords.x, playerCoords.y, playerCoords.z, GetEntityHeading(player), true, false)

    -- Mettre le joueur dans le véhicule
    SetPedIntoVehicle(player, vehicle, -1) -- -1 pour le siège conducteur

    -- Libérer le modèle
    SetModelAsNoLongerNeeded(model)

    print("Véhicule " .. model .. " créé et vous êtes monté dedans.")

end)


RegisterCommand("fix", function()
    local player = PlayerPedId()
    local veh = GetVehiclePedIsIn(player, false)

    if veh and veh ~= 0 then
        SetVehicleFixed(veh)
        SetVehicleDeformationFixed(veh)
        SetVehicleUndriveable(veh, false)
        SetVehicleEngineOn(veh, true, true, false)
        print("Véhicule réparé.")
    else
        print("Vous n'êtes pas dans un véhicule.")
    end
end)

RegisterCommand("fullc", function()
    local player = PlayerPedId()
    local veh = GetVehiclePedIsIn(player, false)
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
end)
